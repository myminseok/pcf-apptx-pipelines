#!/bin/bash

set -o errexit

CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export ROOT_FOLDER=$( pwd )
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export VERSION_RESOURCE=version
export FUNCTIONS_FOLDER=${ROOT_FOLDER}/${TOOLS_RESOURCE}/functions

echo "Root folder is [${ROOT_FOLDER}]"
echo "Repo resource folder is [${REPO_RESOURCE}]"
echo "Tools resource folder is [${TOOLS_RESOURCE}]"
echo "Version resource folder is [${VERSION_RESOURCE}]"
echo "Functions folder is [${FUNCTIONS_FOLDER}]"

PIPELINE_VERSION=$( cat ${ROOT_FOLDER}/${VERSION_RESOURCE}/version )
echo "Current version is [${PIPELINE_VERSION}]"

cd ${ROOT_FOLDER}/${REPO_RESOURCE}

[[ -f "${FUNCTIONS_FOLDER}/projectType/pipeline-jvm.sh" ]] && source "${FUNCTIONS_FOLDER}/projectType/pipeline-jvm.sh" || \
    echo "No ${FUNCTIONS_FOLDER}/projectType/pipeline-jvm.sh found"

export USE_PIPELINE_VERSION=false
PROJECT_VERSION=$( retrieveVersion )
echo "Project version is [${PROJECT_VERSION}]"
MESSAGE="[Concourse CI] Development Version (${PROJECT_VERSION})"

cd ${ROOT_FOLDER}
git clone version updated-version
pushd updated-version
  git config --local user.email "${GIT_EMAIL}"
  git config --local user.name "${GIT_NAME}"

  echo "${PROJECT_VERSION}" > version

  if [[ "${PROJECT_VERSION}" != "${PIPELINE_VERSION}" ]]; then
    echo "Set version to ${PROJECT_VERSION}"
    git add version
    git commit -m "${MESSAGE}"
  fi

popd
