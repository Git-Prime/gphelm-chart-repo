#!/usr/bin/env bash

COMPONENT="${1}"
COMMIT="${GIT_COMMIT}"

function get_master_lookup_commit(){
    local lookup_commit="${GIT_PREVIOUS_COMMIT}"
    local commit_parent_count=$(git log --pretty=%P -n 1 ${lookup_commit} | wc -l)

    if [ $commit_parent_count -gt 1 ]; then
        lookup_commit=$(git branch --contains ${COMMIT} | grep -v master)
    fi

    COMMIT="${lookup_commit}"
}

if [ "${BRANCH_NAME}" == "master" ]; then
    get_master_lookup_commit
fi

MODIFIED=$(git diff --name-only ${COMMIT} origin/master | cut -d'/' -f1 | grep -q ${COMPONENT} && echo 'true' || echo 'false')

echo ${MODIFIED}
