import pandas as pd

def split_data(df, x_cols, y_col):
    x = df[x_cols + [y_col]]
    x = x.dropna(axis='index')
    y = x.pop(y_col)
    return x, y 

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

# sep cols
antenatal = []
antenatal_growth = []
antenatal_intrapartum = []
categorical = []
ordinal = []
linear = []

for col in dat.columns:
    if col[0] == "_":
        continue
    if col[0] == "a":
        antenatal.append(col)
        antenatal_growth.append(col)
        antenatal_intrapartum.append(col)
    if col[0] == "g":
        antenatal_growth.append(col)
    if col[0] == "i":
        antenatal_intrapartum.append(col)
    if col[1] == "c":
        categorical.append(col)
    if col[1] == "o":
        ordinal.append(col)
    if col[1] == "l":
        linear.append(col) 

# split test and train
test = dat[dat['_cohort'] == 0]
train = dat[dat['_cohort'] == 1] 

for name, variable_list in {"antenatal" : antenatal, "antenatal_growth" : antenatal_growth, "antenatal_intrapartum" : antenatal_intrapartum}.items():
    for outcome in ['_hie', '_lapgar', '_perinataldeath', '_resus']:
        print("Working on {} for {}".format(name, outcome))
        
        # select variables for this analysis
        train_x, train_y = split_data(train, variable_list, outcome)
        test_x, test_y = split_data(test, variable_list, outcome)

        # write to csv
        pd.concat([train_x, train_y], axis=1).to_csv("data/{}{}_train.csv".format(name, outcome), header=True)
        pd.concat([test_x, test_y], axis=1).to_csv("data/{}{}_test.csv".format(name, outcome), header=True)