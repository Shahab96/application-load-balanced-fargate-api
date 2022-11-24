#!/bin/bash

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr get-login-password --region us-west-2 | sudo docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com
sudo docker build --rm -t nestjs .
DOCKER_IMAGE=$(sudo docker images -q nestjs:latest)
sudo docker tag $DOCKER_IMAGE $ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/fargate-api-dev:latest
sudo docker push $ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/fargate-api-dev:latest
