# HIE ML analysis

## Source code

```sh
git clone git@github.com:MRCIEU/hie-ml.git
cd hie-ml
```

## Build Docker image

```sh
docker build -t hie-ml .
```

## Prepare data

See ```prepare_data.stata```

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

## Features

Select features

```sh
for data in "antenatal" "antenatal_growth" "antenatal_intrapartum"; do
    for model in "ElasticNet" "Lasso"; do
        docker run -it -d -v `pwd`:/app hie-ml \
        python feature_selection.py \
        --data "$data" \
        --outcome "_hie" \
        --model "$model"
    done
done
```

Plot method correlation

```sh
Rscript feature_selection_plot.R
```

## Models

```sh
# pool jobs
for data in "antenatal" "antenatal_growth" "antenatal_intrapartum"; do
    for model in "LR" "RF" "NB" "NN" "SVC"; do
        for fmodel in "RFE" "Lasso" "SVC" "ElasticNet" "Tree"; do
            for nfeatures in 20 40 60; do
                f=data/"$data"_hie_"$fmodel"_n"$nfeatures"_"$model"_prob.csv
                if [ ! -f "$f" ]; then
                    echo docker run -it --cpus 1 -d -v `pwd`:/app hie-ml \
                    python models.py \
                    --data "$data" \
                    --outcome "_hie" \
                    --model "$model" \
                    --fmodel "$fmodel" \
                    --nfeatures "$nfeatures"
                fi
            done
        done
    done
done > todo.sh

# run n jobs concurrently
head -n 20 todo.sh | bash
```

## ROC

```sh
Rscript roc-forest.R
```