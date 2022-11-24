#!/bin/bash

REPO_NAME=$1
ACCOUNT_ID=$2
REGION=$3

aws ecr get-login-password --region $3 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$3.amazonaws.com
docker build --rm -t $1 .
DOCKER_IMAGE=$(docker images -q $1:latest)
docker tag $DOCKER_IMAGE $ACCOUNT_ID.dkr.ecr.$3.amazonaws.com/$1:latest
docker push $ACCOUNT_ID.dkr.ecr.$3.amazonaws.com/$1:latest
