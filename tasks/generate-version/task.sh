#!/bin/bash

set -e -u

SEMVER=${SEMVER:-1.0.0.M1}
VERSION=${VERSION:-${SEMVER}-`date +%Y%m%d_%H%M%S`-VERSION}
MESSAGE="[Concourse CI] Bump to Next Version ($VERSION)"

git clone version updated-version
pushd updated-version
  git config --local user.email "${GIT_EMAIL}"
  git config --local user.name "${GIT_NAME}"

  echo "Bump to ${VERSION}"
  echo "${VERSION}" > version

  git add version
  git commit -m "${MESSAGE}"
popd
