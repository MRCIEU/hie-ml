import pandas as pd
import numpy as np
import logging
import argparse
import tensorflow as tf
from sklearn.linear_model import LogisticRegression
from sklearn.naive_bayes import GaussianNB
from sklearn.ensemble import RandomForestClassifier
from sklearn import svm
np.random.seed(1234)
tf.set_random_seed(1234)

parser = argparse.ArgumentParser(description='Logistic regression model')
parser.add_argument('--data', dest='data', required=True, help='Dataset to analyse')
parser.add_argument('--outcome', dest='outcome', required=True, help='Outcome to analyse')
parser.add_argument('--model', dest='model', required=True, help='Model')
parser.add_argument('--fmodel', dest='fmodel', required=True, help='Feature selection model')
parser.add_argument('--nfeatures', dest='nfeatures', type=int, required=True, help='Number of features to include in model')
args = parser.parse_args()

# read in data
train = pd.read_csv("data/{}{}_train.csv".format(args.data, args.outcome), index_col='_id').astype('float32')
test = pd.read_csv("data/{}{}_test.csv".format(args.data, args.outcome), index_col='_id').astype('float32')

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

# prediction models
if args.model == "LR":
    clf = LogisticRegression(random_state=1234, penalty='none', max_iter=1e+200, solver="lbfgs")
    clf.fit(train, train_y)
    y = clf.predict_proba(test)[:, 1]
elif args.model == "RF":
    clf = RandomForestClassifier(random_state=1234)
    clf.fit(train, train_y)
    y = clf.predict_proba(test)[:, 1]
elif args.model == "SVC":
    clf = svm.SVC(probability=True)
    clf.fit(train, train_y)
    y = clf.predict_proba(test)[:, 1]
elif args.model == "NB":
    clf = GaussianNB()
    clf.fit(train, train_y)
    y = clf.predict_proba(test)[:, 1]
elif args.model == "NN":
    model = tf.keras.Sequential()
    model.add(tf.keras.layers.Dense(args.nfeatures, activation='relu'))
    model.add(tf.keras.layers.Dense(1, activation='sigmoid'))
    model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['AUC'])
    model.fit(train.values, train_y.values, verbose=0)
    y = model.predict(test.values).ravel()
else:
    raise NotImplementedError

# write out results
prob = pd.DataFrame({"prob": y}, index=test.index)
prob = prob.join(test_y)
prob.columns = ['prob', 'outcome']
prob.to_csv("data/{}{}_{}_n{}_{}".format(args.data, args.outcome, args.fmodel, args.nfeatures, args.model) + "_prob.csv")