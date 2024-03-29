#!/bin/bash
set -e

# It takes ages on Docker to run the app without this
export MAVEN_OPTS="${MAVEN_OPTS} -Djava.security.egd=file:///dev/urandom"

function downloadAppBinary() {
    local repoWithJars="${1}"
    local groupId="${2}"
    local artifactId="${3}"
    local version="${4}"
    local destination="`pwd`/${OUTPUT_FOLDER}/${artifactId}-${version}.jar"
    local changedGroupId="$( echo "${groupId}" | tr . / )"
    local pathToJar="${repoWithJars}/${changedGroupId}/${artifactId}/${version}/${artifactId}-${version}.jar"
    if [[ ! -e ${destination} ]]; then
        mkdir -p "${OUTPUT_FOLDER}"
        echo "Current folder is [`pwd`]; Downloading [${pathToJar}] to [${destination}]"
        (curl "${pathToJar}" -o "${destination}" --fail && echo "File downloaded successfully!") || (echo "Failed to download file!" && return 1)
    else
        echo "File [${destination}] exists. Will not download it again"
    fi
}

function copyArtifactToOutputFolder {
  local artifactId=$( retrieveAppName )
  local groupId=$( retrieveGroupId )
  local changedGroupId="$( echo "${groupId}" | tr . / )"
  local artifactVersion=${PIPELINE_VERSION}

  echo "Copying artifacts from [${ROOT_FOLDER}/${REPO_RESOURCE}/${OUTPUT_FOLDER}] to [${ROOT_FOLDER}/${OUTPUT_RESOURCE}]"
  mkdir -p ${ROOT_FOLDER}/${OUTPUT_RESOURCE}/${changedGroupId}/${artifactId}/${artifactVersion}/
  cp -p ${ROOT_FOLDER}/${REPO_RESOURCE}/${OUTPUT_FOLDER}/${artifactId}-${artifactVersion}.jar ${ROOT_FOLDER}/${OUTPUT_RESOURCE}/${changedGroupId}/${artifactId}/${artifactVersion}/${artifactId}-${artifactVersion}.jar
}

function isMavenProject() {
    [ -f "mvnw" ]
}

function isGradleProject() {
    [ -f "gradlew" ]
}

# TODO: consider also a project descriptor file
# that could override these values
function projectType() {
    if isMavenProject; then
        echo "MAVEN"
    elif isGradleProject; then
        echo "GRADLE"
    else
        echo "UNKNOWN"
    fi
}

export -f projectType
export PROJECT_TYPE=$( projectType )
echo "Project type [${PROJECT_TYPE}]"

lowerCaseProjectType=$( echo "${PROJECT_TYPE}" | tr '[:upper:]' '[:lower:]' )
__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${__DIR}/pipeline-${lowerCaseProjectType}.sh" ]] && source "${__DIR}/pipeline-${lowerCaseProjectType}.sh" || \
    echo "No pipeline-${lowerCaseProjectType}.sh found"

export OUTPUT_FOLDER=$( outputFolder )
export TEST_REPORTS_FOLDER=$( testResultsAntPattern )

echo "Output folder [${OUTPUT_FOLDER}]"
echo "Test reports folder [${TEST_REPORTS_FOLDER}]"
