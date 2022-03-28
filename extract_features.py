import pandas as pd
import numpy as np

def split_data(df, x_cols, y_col):
    x = df[x_cols + [y_col]]
    x = x.dropna(axis='index')
    y = x.pop(y_col)
    return x, y 

def standardize(df, features, means, stds):
    # create new data frame for standardised data
    result = pd.DataFrame()
    for f in df.columns:
        if f in features:
            i = features.index(f)
            result[f] = (df[f] - means[i]) / stds[i]
        else:
            result[f] = df[f]
    return result

# read in data from DO
dat = pd.read_stata("data/1_2_3_4A._Done.dta")
dat = dat.set_index('_id') 

# collect cat cols
categorical = []
for col in dat.columns:
    if col[0] == "_":
        continue
    if col[1] == "c":
        categorical.append(col)

# convert unordered categorical to dummy
for c in categorical:
    one_hot = pd.get_dummies(dat[c], prefix=c)
    dat = pd.concat([dat, one_hot], axis=1)
    dat = dat.drop(c, axis=1) 

# drop features with SD==0 in training data
desc = dat[dat['_cohort'] == 1].describe()
stds = np.array(desc.T['std'])
keep = desc.columns[stds!=0].tolist()
keep.append("_cohort")
dat = dat[keep]

# sep cols
antenatal = []
antenatal_growth = []
antenatal_intrapartum = []
categorical = []
ordinal = []
linear = []
x = []

for col in dat.columns:
    if col[0] == "_":
        continue
    if col[0] == "a":
        antenatal.append(col)
        antenatal_growth.append(col)
        antenatal_intrapartum.append(col)
        x.append(col)
    if col[0] == "g":
        antenatal_growth.append(col)
        x.append(col)
    if col[0] == "i":
        antenatal_intrapartum.append(col)
        antenatal_growth.append(col)
        x.append(col)
    if col[1] == "c":
        categorical.append(col)
    if col[1] == "o":
        ordinal.append(col)
    if col[1] == "l":
        linear.append(col) 

# split test and train
test = dat[dat['_cohort'] == 0]
train = dat[dat['_cohort'] == 1] 

# estimate mean and SD using training dataset
desc = train[x].describe()
means = np.array(desc.T['mean'])
stds = np.array(desc.T['std'])

# convert to Z score
train = standardize(train, x, means, stds)
test = standardize(test, x, means, stds)

for name, variable_list in {"antenatal" : antenatal, "antenatal_growth" : antenatal_growth, "antenatal_intrapartum" : antenatal_intrapartum}.items():
    for outcome in ['_hie']:
        print("Working on {} for {}".format(name, outcome))
        
        # select variables for this analysis
        train_x, train_y = split_data(train, variable_list, outcome)
        test_x, test_y = split_data(test, variable_list, outcome)

        # write to csv
        pd.concat([train_x, train_y], axis=1).to_csv("data/{}{}_train.csv".format(name, outcome), header=True)
        pd.concat([test_x, test_y], axis=1).to_csv("data/{}{}_test.csv".format(name, outcome), header=True)