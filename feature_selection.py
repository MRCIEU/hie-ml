import pandas as pd
import numpy as np
import logging
from sklearn.linear_model import LogisticRegressionCV, LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import LinearSVC
from sklearn.feature_selection import RFECV
from sklearn.preprocessing import StandardScaler
import argparse

# parse args
parser = argparse.ArgumentParser(description='Classifier models')
parser.add_argument('--data', dest='data', required=True, help='Dataset to analyse')
parser.add_argument('--outcome', dest='outcome', required=True, help='Outcome to analyse')
parser.add_argument('--model', dest='model', required=True, help='Model')
parser.add_argument('--test', dest='test', action='store_true', help='Quick test')
args = parser.parse_args()

# read in data
train = pd.read_csv("data/{}{}_train.csv".format(args.data, args.outcome), index_col=0).astype('float32')

### downsample for testing ###
if args.test:
    logging.info("Running with reduced samplesize")
    train = train.sample(n=5000, random_state=1234)
    cols = train.columns.tolist()[0:10]
    cols.append(args.outcome)
    train = train[cols]

# split outcome from predictors
train_y = train.pop(args.outcome)

# feature selection models
if args.model == "RFE":
    # define model
    clf = LogisticRegression(random_state=1234, penalty='none', max_iter=1e+200, solver="lbfgs")

    # fit model
    selector = RFECV(clf, step=5, cv=5, n_jobs=-1, scoring="roc_auc")
    selector = selector.fit(train, train_y)

    # save
    features = train.columns.tolist()
    values = selector.ranking_
elif args.model == "ElasticNet":
    # define model
    clf = LogisticRegressionCV(random_state=1234, penalty='elasticnet', max_iter=1e+200, solver="saga", cv=5, scoring="roc_auc", n_jobs=-1, l1_ratios=[0.5])
    
    # fit model
    clf.fit(train, train_y)

    # save
    features = train.columns.tolist()
    values = clf.coef_.ravel()
elif args.model == "Lasso":
    # define model
    clf = LogisticRegressionCV(random_state=1234, penalty='l1', max_iter=1e+200, solver="liblinear", cv=5, scoring="roc_auc", n_jobs=-1)
    
    # fit model
    clf.fit(train, train_y)

    # save
    features = train.columns.tolist()
    values = clf.coef_.ravel()
elif args.model == "SVC":
    # define model
    clf = LinearSVC(random_state=1234, penalty='l1', max_iter=1e+200, dual=False)
    
    # fit model
    clf.fit(train, train_y)

    # save
    features = train.columns.tolist()
    values = clf.coef_.ravel()
elif args.model == "Tree":
    # define model
    clf = RandomForestClassifier(n_jobs=-1, random_state=1234)
    
    # fit model
    clf.fit(train, train_y)

    # save
    features = train.columns.tolist()
    values = clf.feature_importances_
else:
    raise NotImplementedError

# write out features for downstream analysis
pd.DataFrame({"feature": features, "values": values}).to_csv("data/{}{}.".format(args.data, args.outcome) + args.model + "_features.csv")