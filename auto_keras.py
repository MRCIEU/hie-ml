import subprocess
import sys
import autokeras as ak

subprocess.call([sys.executable, "-m", "pip", "install", "pandas"])
import pandas as pd

data = "antenatal"
outcome = "_hie"

# load processed data
train = pd.read_csv("/app/data/{}{}_train.csv".format(data, outcome), index_col=0).astype('float32')
test = pd.read_csv("/app/data/{}{}_test.csv".format(data, outcome), index_col=0).astype('float32')
train_y = train.pop(outcome)
test_y = test.pop(outcome)

# run model
clf = ak.StructuredDataClassifier()
clf.fit(train, train_y)
results = clf.predict(test)

print(results)