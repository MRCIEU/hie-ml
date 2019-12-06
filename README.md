# Run HIE ML analysis

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