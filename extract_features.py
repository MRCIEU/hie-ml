import pandas as pd
import numpy as np
from imblearn.over_sampling import SMOTE

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

# split test and train
test = dat[dat['_cohort'] == 0]
train = dat[dat['_cohort'] == 1]

# estimate mean and SD using training dataset
desc = train.describe()
means = np.array(desc.T['mean'])
stds = np.array(desc.T['std'])

# drop features with SD==0 in training data & all NaN
keep = desc.columns[stds!=0].tolist()
train = train[keep]
test = test[keep]

# sep cols
antenatal = []
antenatal_growth = []
antenatal_intrapartum = []

for col in train.columns:
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
        antenatal_growth.append(col)

for name, variable_list in {"antenatal" : antenatal, "antenatal_growth" : antenatal_growth, "antenatal_intrapartum" : antenatal_intrapartum}.items():
    for outcome in ['_hie']:
        print("Working on {} for {}".format(name, outcome))

        # drop features with high covariance; ranked from low to high missingness
        sorted_features = train[variable_list].isnull().sum().sort_values(ascending=True).index.to_list()
        to_drop = set()
        for feature in sorted_features:
            if feature in to_drop:
                continue
            variable_list_tmp = [x for x in variable_list if x not in to_drop and x != feature]
            cor = train[variable_list_tmp].corrwith(train[feature]).abs()
            to_drop.update(cor[cor > 0.95].index.to_list())
        to_keep = [x for x in variable_list if x not in to_drop]
        train_x = train[to_keep]
        test_x = test[to_keep]

        # estimate mean and SD using training dataset
        desc = train_x.describe()
        means = np.array(desc.T['mean'])
        stds = np.array(desc.T['std'])

        # convert to Z score
        train_x = (train_x - means) / stds
        test_x = (test_x - means) / stds

        # drop missing data
        train_x = train_x.join(train[outcome])
        train_x = train_x.dropna(axis='index')
        train_y = train_x.pop(outcome)

        test_x = test_x.join(test[outcome])
        test_x = test_x.dropna(axis='index')
        test_y = test_x.pop(outcome)

        # oversample training dataset using SMOTE
        X_resampled, y_resampled = SMOTE().fit_resample(train_x, train_y)

        # write to csv
        pd.concat([X_resampled, y_resampled], axis=1).to_csv("data/{}{}_train.csv".format(name, outcome), header=True)
        pd.concat([test_x, test_y], axis=1).to_csv("data/{}{}_test.csv".format(name, outcome), header=True)