#!/usr/bin/env bash
# https://github.com/helm/chart-testing/blob/master/examples/kind/test/e2e-kind.sh

set -o errexit
set -o nounset
set -o pipefail

readonly CT_VERSION=v3.0.0-beta.2
readonly KIND_VERSION=v0.7.0
readonly CLUSTER_NAME=chart-testing
readonly K8S_VERSION=v1.17.0

run_ct_container() {
    echo 'Running ct container...'
    docker run --rm --interactive --detach --network host --name ct \
        --volume "$(pwd)/test/ct.yaml:/etc/ct/ct.yaml" \
        --volume "$(pwd):/workdir" \
        --workdir /workdir \
        "gp-docker.gitprime-ops.com/flow-ci/helmpack:latest" \
        cat
    echo
}

cleanup() {
    echo 'Removing ct container...'
    docker kill ct > /dev/null 2>&1

    echo 'Done!'
}

docker_exec() {
    docker exec --interactive ct "$@"
}

create_kind_cluster() {
    echo 'Installing kind...'

    curl -sSLo kind "https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-amd64"
    chmod +x kind
    sudo mv kind /usr/local/bin/kind

    kind create cluster -v 2 --name "$CLUSTER_NAME" --config test/kind-config.yaml --image "kindest/node:$K8S_VERSION" --wait 60s

    echo 'Copying kubeconfig to container...'
    docker cp /root/.kube/config ct:/root/.kube/config

    docker_exec kubectl cluster-info
    echo

    docker_exec kubectl get nodes
    echo

    echo 'Cluster ready!'
    echo
}

install_charts() {
    docker_exec ct install
    echo
}

main() {
    run_ct_container
    trap cleanup EXIT

    create_kind_cluster
    install_charts
}

main