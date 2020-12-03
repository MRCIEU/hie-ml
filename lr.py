import pandas as pd
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import brier_score_loss, roc_curve, auc
from sklearn.feature_selection import RFECV
import argparse

# parse args
parser = argparse.ArgumentParser(description='LR model')
parser.add_argument('--data', dest='data', required=True, help='Dataset to analyse')
parser.add_argument('--outcome', dest='outcome', required=True, help='Outcome to analyse')
args = parser.parse_args()

print("Running LR on {} for {}".format(args.data, args.outcome))

# read in data
train = pd.read_csv("data/{}{}_train.csv".format(args.data, args.outcome), index_col=0).astype('float32')
test = pd.read_csv("data/{}{}_test.csv".format(args.data, args.outcome), index_col=0).astype('float32')

### downsample for testing ###
#train = train.sample(n=5000, random_state=1)
#test = test.sample(n=5000, random_state=1)
#cols = train.columns.tolist()[0:10]
#cols.append(args.outcome)
#train = train[cols]
#test = test[cols]
###

# split outcome from predictors
train_y = train.pop(args.outcome)
test_y = test.pop(args.outcome)

# evaluate model
clf = LogisticRegression(random_state=0, penalty='none', max_iter=1000000)
selector = RFECV(clf, step=1, cv=5, n_jobs=-1, scoring="roc_auc")
selector = selector.fit(train, train_y)

# predictors to keep
keep = train.columns[selector.support_]

# train final model
train = train[keep]
test = test[keep]
clf = LogisticRegression(random_state=0, penalty='none', max_iter=1000000)
clf.fit(train, train_y)

# calculate probabilities for test data
y_test_pred = clf.predict_proba(test)[:, 1]

# write out probs for downstream analysis
pd.DataFrame({"feature": keep.tolist(), "coef": clf.coef_.ravel()}).to_csv("data/{}{}.LR-coef.csv".format(args.data, args.outcome))
pd.DataFrame({"Prob" : y_test_pred, "{}{}".format(args.data, args.outcome): test_y}, index=test.index).to_csv("data/{}{}.LR.csv".format(args.data, args.outcome))