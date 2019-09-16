#!/bin/bash

## This is a minor hack to expose internal Kubernetes service to local network, rather tan deal with lots of configuration issues.
cluster_ip=$(kubectl get endpoints | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")

# mkdir -p ~/.gitprime/helm-kafka/

# sed "s/kafka.cluster.local/${cluster_ip}/" values_template.yaml > ~/.gitprime/helm-kafka/values.yaml

kubectl create namespace kafka

# helm install --name my-kafka -f ~/.gitprime/helm-kafka/values.yaml --namespace kafka

# helm install --name gp-kafka --dry-run --debug --namespace kafka ../

helm install --name gp-kafka --namespace kafka ../

echo "*****************************************************************************************************************"
echo "spring-boot configuration instructions: Please make sure your spring.kafka.bootstrap-servers value is set to ${cluster_ip}:31090"
echo "*****************************************************************************************************************"