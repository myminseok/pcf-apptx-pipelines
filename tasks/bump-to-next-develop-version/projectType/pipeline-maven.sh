#!/bin/bash
set -e

function bumpVersion() {
  ./mvnw versions:set -DnewVersion=${VERSION} -DallowSnapshots

  git config --global user.email "${GIT_EMAIL}"
  git config --global user.name "${GIT_NAME}"
  git add pom.xml
  git commit -m "${MESSAGE}"
}

export -f bumpVersion
