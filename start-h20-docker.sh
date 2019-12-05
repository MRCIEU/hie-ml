# build image
cd h20-master
docker build -t "h2o.ai/master:v5" .
cd ..

# start h20
docker run \
-ti \
-p 54321:54321 \
--rm \
-v `pwd`:/app \
--name hie-ml-h20 \
h2o.ai/master:v5 /bin/bash