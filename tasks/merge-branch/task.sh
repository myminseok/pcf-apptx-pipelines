#!/bin/bash

set -o errexit

export ROOT_FOLDER=$( pwd )
export FROM_REPO_RESOURCE=from-repo
export TO_REPO_RESOURCE=to-repo
export TOOLS_RESOURCE=tools
export OUTPUT_RESOURCE=out

echo "Root folder is [${ROOT_FOLDER}]"
echo "From repo resource folder is [${FROM_REPO_RESOURCE}]"
echo "To repo resource folder is [${TO_REPO_RESOURCE}]"
echo "Tools resource folder is [${TOOLS_RESOURCE}]"
echo "Version resource folder is [${VERSION_RESOURCE}]"

cd ${ROOT_FOLDER}/${OUTPUT_RESOURCE}
shopt -s dotglob
mv -f ${ROOT_FOLDER}/${TO_REPO_RESOURCE}/* ./
git config --global user.email "${GIT_EMAIL}"
git config --global user.name "${GIT_NAME}"
git remote add -f ${SOURCE_BRANCH_NAME} ${ROOT_FOLDER}/${FROM_REPO_RESOURCE}
git merge --no-edit ${SOURCE_BRANCH_NAME}/${SOURCE_BRANCH_NAME}
