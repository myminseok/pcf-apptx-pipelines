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
export ENVIRONMENT=BUILD

source ${ROOT_FOLDER}/${TOOLS_RESOURCE}/tasks/common.sh

cd ${ROOT_FOLDER}/${REPO_RESOURCE}

# CURRENTLY WE ONLY SUPPORT JVM BASED PROJECTS OUT OF THE BOX
[[ -f "${cwd}/projectType/pipeline-jvm.sh" ]] && source "${cwd}/projectType/pipeline-jvm.sh" || \
    echo "No ${cwd}/projectType/pipeline-jvm.sh found"

export OUTPUT_FOLDER=$( outputFolder )
export TEST_REPORTS_FOLDER=$( testResultsAntPattern )

echo "Output folder [${OUTPUT_FOLDER}]"

echo "Generating settings.xml / gradle properties for Maven in local m2"
source ${cwd}/generate-settings.sh

export TERM=dumb

echo "Building and uploading the projects artifacts"
cd ${ROOT_FOLDER}/${REPO_RESOURCE}

build

echo "Tagging the project with dev tag"
echo "dev/${PIPELINE_VERSION}" > ${ROOT_FOLDER}/${REPO_RESOURCE}/tag
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE}/. ${ROOT_FOLDER}/${OUTPUT_RESOURCE}/
