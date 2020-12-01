# HIE ML analysis

1. [Feature selection](feature_selection.ipynb)
2. [Logistic regression](logistic_regression.ipynb)
3. [Random forest](random_forest.ipynb)
4. [neural net](neural_net.ipynb)
5. [Ensembl](adanet.ipynb)

## source code

```sh
git clone git@ieugit-scmv-d0.epi.bris.ac.uk:ml18692/hie-ml.git
cd hie-ml.git
```

## run jupyter interactively

```sh
bash start-jupyter-docker.sh
```

Browse to ```http://<server>:8890``` and copy token from command line to login

## run single notebook non-interactively

```sh
docker run -it -d \
--user $UID \
--group-add users \
-v `pwd`:/home/jovyan/work \
--name hie-ml-jupyter-noninteractive \
jupyter/tensorflow-notebook \
jupyter \
nbconvert \
--to notebook \
--inplace \
--execute notebook.ipynb
```
