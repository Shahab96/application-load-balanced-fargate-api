#!/bin/bash

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com
docker build --rm -t nestjs .
DOCKER_IMAGE=$(sudo docker images -q nestjs:latest)
docker tag $DOCKER_IMAGE $ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/fargate-api-test:latest
docker push $ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/fargate-api-test:latest
