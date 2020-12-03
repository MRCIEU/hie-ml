# HIE ML analysis

## Source code

```sh
git clone git@ieugit-scmv-d0.epi.bris.ac.uk:ml18692/hie-ml.git
cd hie-ml
```

## Build Docker image

```sh
docker build -t hie-ml .
```

## Extract data

The first(A) is one with all variables with >5% missing values removed, the second(B) is imputed form the most recent complete data-point prior to that birth and the third(C) is imputed using mode values

Derived variables are:

_cohort – Either 1 (born in the first deriving cohort) or 0 (in the second, testing cohort)
_hie – 1 for HIE, 0 for not
_id
_lapgar – 1 for a low Apgar score, 0 for not
_ne – Another measure of brain injury (not used at present)
_neonataldeath – Not used at present
_perinataldeath – 1 for perinatal death; 0 for not
_resus – 1 for resus at birth, and 0 for not
_stillborn – Not used at present
_yearofbirth -  Year of birth

First letter is either a (antenatal), g (growth) or I (intrapartum) variable
Second letter is type of entry; c (categorical), o(ordinal) or l(linear)
Then _NAME (most have one given)
Then _#### - number of were extraction was performed on the Variable File


```sh
docker run -it -v `pwd`:/app hie-ml python extract_features.py
```

## Models

```sh
for data in "antenatal" "antenatal_growth" "antenatal_intrapartum"; do
    for outcome in "_hie"; do
        docker run -it -d -v `pwd`:/app hie-ml python models.py --data "$data" --outcome "$outcome" --model "RFE"
        docker run -it -d -v `pwd`:/app hie-ml python models.py --data "$data" --outcome "$outcome" --model "ElasticNet"
        docker run -it -d -v `pwd`:/app hie-ml python models.py --data "$data" --outcome "$outcome" --model "Lasso"
        docker run -it -d -v `pwd`:/app hie-ml python models.py --data "$data" --outcome "$outcome" --model "SVC"
        docker run -it -d -v `pwd`:/app hie-ml python models.py --data "$data" --outcome "$outcome" --model "Tree"
    done
done
```
