import pandas as pd
import numpy as np
from sklearn.linear_model import LogisticRegressionCV, LogisticRegression
from sklearn.svm import LinearSVC
from sklearn.feature_selection import RFECV
import argparse

# parse args
parser = argparse.ArgumentParser(description='Classifier models')
parser.add_argument('--data', dest='data', required=True, help='Dataset to analyse')
parser.add_argument('--outcome', dest='outcome', required=True, help='Outcome to analyse')
parser.add_argument('--model', dest='model', required=True, help='Model')
parser.add_argument('--test', dest='test', required=True, help='Quick test')
args = parser.parse_args()

# read in data
train = pd.read_csv("data/{}{}_train.csv".format(args.data, args.outcome), index_col=0).astype('float32')
test = pd.read_csv("data/{}{}_test.csv".format(args.data, args.outcome), index_col=0).astype('float32')

### downsample for testing ###
if args.test:
    train = train.sample(n=5000, random_state=1)
    test = test.sample(n=5000, random_state=1)
    cols = train.columns.tolist()[0:10]
    cols.append(args.outcome)
    train = train[cols]
    test = test[cols]

# split outcome from predictors
train_y = train.pop(args.outcome)
test_y = test.pop(args.outcome)

# evaluate models
if args.model is "RFE":
    # RFE using LR
    clf = LogisticRegression(random_state=0, penalty='none', max_iter=1000000)
    selector = RFECV(clf, step=1, cv=5, n_jobs=-1, scoring="roc_auc")
    selector = selector.fit(train, train_y)

    # predictors to keep
    features = train.columns[selector.support_]

    # train final LR model using only selected predictors
    train = train[features]
    test = test[features]
    
    # define model
    clf = LogisticRegression(random_state=0, penalty='none', max_iter=1000000)

    # fit model
    clf.fit(train, train_y)

    # save
    y_test_pred = clf.predict_proba(test)[:, 1]
    values = clf.coef_.ravel()
elif args.model is "ElasticNet":
    # define model
    clf = LogisticRegressionCV(random_state=0, penalty='elasticnet', max_iter=1000000, solver="saga", cv=5, scoring="roc_auc", n_jobs=-1, l1_ratios=[args.alpha])
    
    # fit model
    clf.fit(train, train_y)

    # save
    y_test_pred = clf.predict_proba(test)[:, 1]
    feautures = train.columns.tolist()
    values = clf.coef_.ravel()
elif args.model is "Lasso":
    # define model
    clf = LogisticRegressionCV(random_state=0, penalty='l1', max_iter=1000000, solver="saga", cv=5, scoring="roc_auc", n_jobs=-1)
    
    # fit model
    clf.fit(train, train_y)

    # save
    y_test_pred = clf.predict_proba(test)[:, 1]
    feautures = train.columns.tolist()
    values = clf.coef_.ravel()
elif args.model is "SVC":
    # define model
    clf = LinearSVC(random_state=0, penalty='l1', max_iter=1000000)
    
    # fit model
    clf.fit(train, train_y)

    # save
    y_test_pred = clf.predict_proba(test)[:, 1]
    feautures = train.columns.tolist()
    values = clf.coef_.ravel()
elif args.model is "Tree":
    # define model
    clf = None
else:
    raise NotImplementedError

# write out probs and features for downstream analysis
pd.DataFrame({"feature": feautures, "values": values}).to_csv("data/{}{}.".format(args.data, args.outcome) + args.model + "_features.csv")
pd.DataFrame({"Prob" : y_test_pred, "{}{}".format(args.data, args.outcome): test_y}, index=test.index).to_csv("data/{}{}.".format(args.data, args.outcome) + args.model + "_probs.csv")