# start autokeras
docker run \
--rm \
-v `pwd`:/app \
--name hie-ml-autokeras \
--shm-size 2G \
garawalid/autokeras \
python auto_keras.py
