#!/bin/bash

set -o errexit

export ROOT_FOLDER=$( pwd )
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export VERSION_RESOURCE=version
export OUTPUT_RESOURCE=out

echo "Root folder is [${ROOT_FOLDER}]"
echo "Repo resource folder is [${REPO_RESOURCE}]"
echo "Tools resource folder is [${TOOLS_RESOURCE}]"
echo "Version resource folder is [${VERSION_RESOURCE}]"

export PIPELINE_VERSION=$( cat ${ROOT_FOLDER}/${VERSION_RESOURCE}/version )
echo "Retrieved version is [${PIPELINE_VERSION}]"

echo "Tagging the project with ${TAG_PREFIX} tag"
echo "${TAG_PREFIX}/${PIPELINE_VERSION}" > ${ROOT_FOLDER}/${REPO_RESOURCE}/tag
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE}/. ${ROOT_FOLDER}/${OUTPUT_RESOURCE}/
