#!/usr/bin/env bash
REPO_ROOT=$(git rev-parse --show-toplevel)
CHART_VERSION="v0.0.1"

function usage() {
    echo "Usage: ./new_chart.sh <chart name> '<chart description>'"
}

if [ -z $1 ]; then
    echo "Chart name is unset. Please specify chart name"
    usage
    exit 1
elif [ -z $2 ]; then
    echo "Chart description is unset. Please specify a chart description"
    usage
    exit 1
else
    CHART_NAME=$1
    CHART_DESCRIPTION=$2
fi

CHART_ROOT="${REPO_ROOT}/charts/${CHART_NAME}/${CHART_VERSION}"

echo "Creating chart ${CHART_NAME} from bootstrap template"
if [ -d "${CHART_ROOT}" ]; then
    echo "${CHART_ROOT} exists already. Will not overwrite"
else
    mkdir -p "${CHART_ROOT}"
    cp -aR "${REPO_ROOT}"/tools/boilerplate_chart/* "${CHART_ROOT}"/
fi

find ${CHART_ROOT} -type f -print0 | xargs -0 sed -i '' -e "s/APP_NAME/${CHART_NAME}/g"
find ${CHART_ROOT} -type f -print0 | xargs -0 sed -i '' -e "s/APP_DESCRIPTION/${CHART_DESCRIPTION}/g"

if [ $? -eq 0 ]; then
    echo "Successfully created new chart ${CHART_NAME} in ${CHART_ROOT}"
else
    echo "There was a problem creating your chart! Removing ${CHART_ROOT}"
    rm -rf "${CHART_ROOT}"
fi
