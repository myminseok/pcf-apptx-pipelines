#!/bin/bash

set -o errexit

CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FUNCTIONS_FOLDER=${ROOT_FOLDER}/${APPTX_RESOURCE}/functions
TASKS_FOLDER=${ROOT_FOLDER}/${APPTX_RESOURCE}/tasks

echo "AppTx Functions folder is [${FUNCTIONS_FOLDER}]"
echo "AppTx Tasks folder is [${TASKS_FOLDER}]"

source ${TASKS_FOLDER}/common.sh

# CURRENTLY WE ONLY SUPPORT JVM BASED PROJECTS OUT OF THE BOX
[[ -f "${FUNCTIONS_FOLDER}/projectType/pipeline-jvm.sh" ]] && source "${FUNCTIONS_FOLDER}/projectType/pipeline-jvm.sh" || \
    echo "No ${FUNCTIONS_FOLDER}/projectType/pipeline-jvm.sh found"

lowerCaseProjectType=$( echo "${PROJECT_TYPE}" | tr '[:upper:]' '[:lower:]' )
[[ -f "${CWD}/projectType/pipeline-${lowerCaseProjectType}.sh" ]] && source "${CWD}/projectType/pipeline-${lowerCaseProjectType}.sh" || \
    echo "No ${CWD}/projectType/pipeline-${lowerCaseProjectType}.sh found"
