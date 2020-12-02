# HIE ML analysis

1. [Feature extraction](extract_features.ipynb)
2. [Logistic regression](logistic_regression.ipynb)
3. [Random forest](random_forest.ipynb)
4. [Neural net](neural_net.ipynb)
5. [Ensembl](adanet.ipynb)

## Source code

```sh
git clone git@ieugit-scmv-d0.epi.bris.ac.uk:ml18692/hie-ml.git
cd hie-ml.git
```

## Run notebook interactively

```sh
bash start-jupyter-docker.sh
```

Browse to ```http://<server>:8890``` and copy token from command line to login

## Run notebook non-interactively

```sh
docker run -it -d \
--user $UID \
--group-add users \
-v `pwd`:/home/jovyan/work \
--name hie-ml-jupyter-noninteractive \
jupyter/datascience-notebook:notebook-6.1.4 \
jupyter \
nbconvert \
--to notebook \
--inplace \
--execute notebook.ipynb
```
