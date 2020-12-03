FROM python:3.8

WORKDIR /app

# install python dependencies
RUN pip install --upgrade pip
RUN pip install -r requirements.txt