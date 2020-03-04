#!/usr/bin/env bash

CHARTS=$(test/bin/git_diff.sh | tr ' ' ',')

echo "****************************"
echo "Modified charts: ${CHARTS}"
echo "****************************"

cd charts || exit
ct lint --config ../test/ct.yaml --charts "${CHARTS}"
