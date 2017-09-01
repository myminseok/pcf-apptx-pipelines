#!/bin/bash

export ROOT_FOLDER=$( pwd )
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export APPTX_RESOURCE=apptx
export VERSION_RESOURCE=version
export OUTPUT_RESOURCE=out

echo "Root folder is [${ROOT_FOLDER}]"
echo "Repo resource folder is [${REPO_RESOURCE}]"
echo "Tools resource folder is [${TOOLS_RESOURCE}]"
echo "AppTx resource folder is [${APPTX_RESOURCE}]"
echo "Version resource folder is [${VERSION_RESOURCE}]"

source ${ROOT_FOLDER}/${SC_PIPELINES_RESOURCE}/concourse/tasks/pipeline.sh

echo "Building and uploading the projects artifacts"
cd ${ROOT_FOLDER}/${REPO_RESOURCE}

cp -r ${ROOT_FOLDER}/${APPTX_RESOURCE}/common/src/main/bash/* ${SCRIPTS_OUTPUT_FOLDER}/

. ${SCRIPTS_OUTPUT_FOLDER}/build_and_upload.sh

# echo "Tagging the project with dev tag"
# echo "dev/${PIPELINE_VERSION}" > ${ROOT_FOLDER}/${REPO_RESOURCE}/tag
# cp -r ${ROOT_FOLDER}/${REPO_RESOURCE}/. ${ROOT_FOLDER}/${OUTPUT_RESOURCE}/
