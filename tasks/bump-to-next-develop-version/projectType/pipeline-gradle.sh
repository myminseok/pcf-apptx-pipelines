#!/bin/bash
set -e

function bumpVersion() {
  rm gradle.properties
  touch gradle.properties
  echo version=$VERSION > gradle.properties

  git config --global user.email "${GIT_EMAIL}"
  git config --global user.name "${GIT_NAME}"
  git add gradle.properties
  git commit -m "${MESSAGE}"
}

export -f bumpVersion
