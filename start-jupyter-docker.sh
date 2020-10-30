# start jupyter notebook
docker run \
--rm \
--user $UID \
--group-add users \
-e JUPYTER_ENABLE_LAB=yes \
-p 8890:8888 \
-v `pwd`:/home/jovyan/work \
--name hie-ml-jupyter \
jupyter/tensorflow-notebook:7a0c7325e470
