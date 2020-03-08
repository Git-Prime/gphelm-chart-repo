#!/usr/bin/env bash

DIRECTION="${1}"

function up(){
    helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
    kubectl create namespace spark-operator
    helm install spark-operator incubator/sparkoperator --namespace spark-operator --set sparkJobNamespace=default --set operatorVersion=v1beta2-1.1.0-2.4.5 --wait
    exit 0
}

function down(){
    kubectl delete namespace spark-operator
    helm uninstall spark-operator -n spark-operator
    exit 0
}

if [ "${DIRECTION}" == "up" ]; then
    up
elif [ "${DIRECTION}" == "down" ]; then
    down
else
    echo "Unknown function ${DIRECTION}. Exiting."
    exit 1
fi

