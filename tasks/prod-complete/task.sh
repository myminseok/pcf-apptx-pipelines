#!/bin/bash

set -o errexit

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export ROOT_FOLDER=$( pwd )
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export VERSION_RESOURCE=version
export OUTPUT_RESOURCE=out

echo "Root folder is [${ROOT_FOLDER}]"
echo "Repo resource folder is [${REPO_RESOURCE}]"
echo "Tools resource folder is [${TOOLS_RESOURCE}]"
echo "Version resource folder is [${VERSION_RESOURCE}]"
echo "Current working directory is [${cwd}]"

echo "Retrieving version"
export PIPELINE_VERSION=$( cat ${ROOT_FOLDER}/${VERSION_RESOURCE}/version )
echo "Retrieved version is [${PIPELINE_VERSION}]"

export CI="CONCOURSE"
export ENVIRONMENT=PROD

source ${ROOT_FOLDER}/${TOOLS_RESOURCE}/tasks/common.sh

cd ${ROOT_FOLDER}/${REPO_RESOURCE}

# CURRENTLY WE ONLY SUPPORT JVM BASED PROJECTS OUT OF THE BOX
[[ -f "${cwd}/projectType/pipeline-jvm.sh" ]] && source "${cwd}/projectType/pipeline-jvm.sh" || \
    echo "No ${cwd}/projectType/pipeline-jvm.sh found"

export TERM=dumb

echo "Deploying the built application on test environment"

[[ -f "${cwd}/pipeline.sh" ]] && source "${cwd}/pipeline.sh" || \
    echo "No ${cwd}/pipeline.sh found"

deleteBlueInstance