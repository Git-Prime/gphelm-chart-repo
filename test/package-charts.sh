#!/usr/bin/env bash

log_error() {
    printf '\e[31mERROR: %s\n\e[39m' "$1" >&2
}

for dir in charts/*; do
    if helm dependency build "$dir"; then
        #chart=$(printf '%s\n' "${dir//charts\//}")
        helm package --destination "dist" "$dir"
    else
        log_error "Problem building dependencies. Skipping packaging of '$dir'."
        exit_code=1
    fi
done

helm repo index dist/

aws s3 sync dist/ s3://gitprime-helm-charts/ --content-type "application/x-gzip" --acl public-read --exclude '*' --include '*.tgz'
aws s3 cp dist/index.yaml s3://gitprime-helm-charts/index.yaml --acl public-read
