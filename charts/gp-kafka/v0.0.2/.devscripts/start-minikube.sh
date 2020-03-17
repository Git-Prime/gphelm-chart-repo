#!/bin/bash

echo "Starting minikube"
minikube start --memory=8192 --cpus=6

echo "Installing Tiller"
helm init