#!/usr/bin/env bash

MODIFIED=$(test/bin/git_diff.sh)
echo "${MODIFIED}"

for c in "${MODIFIED[@]}"; do
  ct lint --config test/ct.yaml --charts charts/"${c}"
done
