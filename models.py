import pandas as pd
import numpy as np
import logging
from sklearn.linear_model import LogisticRegressionCV, LogisticRegression
from sklearn.ensemble import ExtraTreesClassifier
from sklearn.svm import LinearSVC
from sklearn.feature_selection import RFECV
from sklearn.preprocessing import StandardScaler
import argparse

def standardize_continuous_values(df, continuous_features, means, stds):
    for i, f in enumerate(continuous_features):
        if f in df.columns:
            df[f] = (df[f] - means[i]) / stds[i]
    return df 

# parse args
parser = argparse.ArgumentParser(description='Classifier models')
parser.add_argument('--data', dest='data', required=True, help='Dataset to analyse')
parser.add_argument('--outcome', dest='outcome', required=True, help='Outcome to analyse')
parser.add_argument('--model', dest='model', required=True, help='Model')
parser.add_argument('--test', dest='test', action='store_true', help='Quick test')
args = parser.parse_args()

# read in data
train = pd.read_csv("data/{}{}_train.csv".format(args.data, args.outcome), index_col=0).astype('float32')
test = pd.read_csv("data/{}{}_test.csv".format(args.data, args.outcome), index_col=0).astype('float32')

### downsample for testing ###
if args.test:
    logging.info("Running with reduced samplesize")
    train = train.sample(n=5000, random_state=1234)
    test = test.sample(n=5000, random_state=1234)
    cols = train.columns.tolist()[0:10]
    cols.append(args.outcome)
    train = train[cols]
    test = test[cols]

# split outcome from predictors
train_y = train.pop(args.outcome)
test_y = test.pop(args.outcome)

# record which variables are continuous
ordinal = []
linear = []
for col in train.columns:
    if col[0] == "_":
        continue
    if col[1] == "o":
        ordinal.append(col)
    if col[1] == "l":
        linear.append(col)

## get mean and SD for **training** dataset to standardise variables
desc = train[linear + ordinal].describe()
means = np.array(desc.T['mean'])
stds = np.array(desc.T['std']) 

# evaluate models
if args.model == "RFE":
    # RFE using LR
    clf = LogisticRegression(random_state=1234, penalty='none', max_iter=1e+8, verbose=1)
    selector = RFECV(clf, step=1, cv=5, n_jobs=-1, scoring="roc_auc", verbose=1)
    selector = selector.fit(train, train_y)

    # predictors to keep
    features = train.columns[selector.support_]

    # train final LR model using only selected predictors
    train = train[features]
    test = test[features]
    
    # define model
    clf = LogisticRegression(random_state=1234, penalty='none', max_iter=1e+8, verbose=1)

    # fit model
    clf.fit(train, train_y)

    # save
    y_test_pred = clf.predict_proba(test)[:, 1]
    features = test.columns.tolist()
    values = clf.coef_.ravel()
elif args.model == "ElasticNet":
    # define model
    clf = LogisticRegressionCV(random_state=1234, penalty='elasticnet', max_iter=1e+8, solver="saga", cv=5, scoring="roc_auc", n_jobs=-1, verbose=1)
    
    # fit model
    clf.fit(train, train_y)

    # save
    y_test_pred = clf.predict_proba(test)[:, 1]
    features = test.columns.tolist()
    values = clf.coef_.ravel()
elif args.model == "Lasso":
    # define model
    clf = LogisticRegressionCV(random_state=1234, penalty='l1', max_iter=1e+8, solver="liblinear", cv=5, scoring="roc_auc", n_jobs=-1, verbose=1)
    
    # fit model
    clf.fit(train, train_y)

    # save
    y_test_pred = clf.predict_proba(test)[:, 1]
    features = test.columns.tolist()
    values = clf.coef_.ravel()
elif args.model == "SVC":
    # define model
    clf = LinearSVC(random_state=1234, penalty='l1', max_iter=1e+8, dual=False, verbose=1)
    
    # fit model
    clf.fit(train, train_y)

    # save
    y_test_pred = clf.predict(test)
    features = test.columns.tolist()
    values = clf.coef_.ravel()
elif args.model == "Tree":
    # define model
    clf = ExtraTreesClassifier(n_jobs=-1, random_state=1234, verbose=1)
    
    # fit model
    clf.fit(train, train_y)

    # save
    y_test_pred = clf.predict_proba(test)[:, 1]
    features = test.columns.tolist()
    values = clf.feature_importances_  
else:
    raise NotImplementedError

# write out probs and features for downstream analysis
pd.DataFrame({"feature": features, "values": values}).to_csv("data/{}{}.".format(args.data, args.outcome) + args.model + "_features.csv")
pd.DataFrame({"Prob" : y_test_pred, "{}{}".format(args.data, args.outcome): test_y}, index=test.index).to_csv("data/{}{}.".format(args.data, args.outcome) + args.model + "_probs.csv")
