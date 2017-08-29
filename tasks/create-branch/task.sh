#!/bin/bash

set -o errexit

export ROOT_FOLDER=$( pwd )
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export OUTPUT_RESOURCE=out

echo "Root folder is [${ROOT_FOLDER}]"
echo "Repo resource folder is [${REPO_RESOURCE}]"
echo "Tools resource folder is [${TOOLS_RESOURCE}]"

git clone ${REPO_RESOURCE} ${OUTPUT_RESOURCE}
pushd ${OUTPUT_RESOURCE}
  git config --local user.email "${GIT_EMAIL}"
  git config --local user.name "${GIT_NAME}"

  echo "Create branch ${BRANCH_NAME}"

  git checkout -B "${BRANCH_NAME}"
popd
