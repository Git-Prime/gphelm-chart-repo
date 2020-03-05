#!/usr/bin/env bash

SYNC="${1}"
# Can be one or more space separated charts
CHARTS="${2}"
exit_code=0

log_error() {
    printf '\e[31mERROR: %s\n\e[39m' "$1" >&2
}

package() {
  local chart="${1}"
  if helm dependency build "$chart"; then
      echo "Packaging ${chart}"
      helm package --destination "dist" "$chart"
  else
      log_error "Problem building dependencies. Skipping packaging of '$chart'."
      exit_code=1
  fi
}

# Package all charts if chart is not specified
if [ "${CHARTS}" == "" ]; then
    for c in charts/*; do
        package "${c}"
    done
else
    # Package more than one chart
    if [ "${#CHARTS[@]}" -gt 1 ]; then
        for c in "${CHARTS[@]}"; do
            package charts/"${c}"
        done
    # Package a single chart
    else
        package charts/"${CHARTS}"
    fi
fi

if [ "${SYNC}" != "" ]; then
    echo "Syncing charts to s3"
    helm repo index dist/ --merge dist/index.yaml --url https://gitprime-helm-charts.s3-us-west-2.amazonaws.com/
    aws s3 sync dist/ s3://gitprime-helm-charts/ --content-type "application/x-gzip" --acl public-read --exclude '*' --include '*.tgz'
    aws s3 cp dist/index.yaml s3://gitprime-helm-charts/index.yaml --acl public-read
fi

exit exit_code
