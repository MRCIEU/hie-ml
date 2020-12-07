import pandas as pd
import numpy as np
import logging
from sklearn.linear_model import LogisticRegression
import argparse

parser = argparse.ArgumentParser(description='Logistic regression model')
parser.add_argument('--data', dest='data', required=True, help='Dataset to analyse')
parser.add_argument('--outcome', dest='outcome', required=True, help='Outcome to analyse')
parser.add_argument('--model', dest='model', required=True, help='Model')
parser.add_argument('--fmodel', dest='fmodel', required=True, help='Feature selection model')
parser.add_argument('--nfeatures', dest='nfeatures', required=True, help='Number of features to include in model')
args = parser.parse_args()

# read in data
train = pd.read_csv("data/{}{}_train.csv".format(args.data, args.outcome), index_col=0).astype('float32')
test = pd.read_csv("data/{}{}_test.csv".format(args.data, args.outcome), index_col=0).astype('float32')

# split outcome from predictors
train_y = train.pop(args.outcome)
test_y = test.pop(args.outcome)

# select predictors
features = pd.read_csv("data/{}{}.{}_features.csv".format(args.data, args.outcome, args.fmodel), usecols = ['feature','values'], index_col="feature").astype('float32')
if args.fmodel == "RFE":
    predictors = features.sort_values(by='values', ascending=True).head(n=args.nfeatures).index.tolist()
else:
    features["values"] = features["values"].abs()
    predictors = features.sort_values(by='values', ascending=False).head(n=args.nfeatures).index.tolist()

# subset features
train = train[predictors]
test = test[predictors]

# prediction models
if args.model == "LR":
    clf = LogisticRegression(random_state=1234, penalty='none', max_iter=1e+8)
    clf.fit(train, train_y)
    y = clf.predict_proba(test)[:, 1]
else:
    raise NotImplementedError

# write out results
prob = pd.DataFrame({"prob": y}, index=test.index)
prob = prob.join(test_y)
prob.to_csv("data/{}{}_{}_n{}_{}".format(args.data, args.outcome, args.fmodel, args.nfeatures, args.model) + "_prob.csv")