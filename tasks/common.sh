#!/bin/bash
set -e

# Finds the latest prod tag from git
function findLatestProdTag() {
    local LAST_PROD_TAG=$(git for-each-ref --sort=taggerdate --format '%(refname)' refs/tags/prod | head -n 1)
    LAST_PROD_TAG=${LAST_PROD_TAG#refs/tags/}
    echo "${LAST_PROD_TAG}"
}

# Deploys services assuming that pipeline descriptor exists
# For TEST environment first deletes, then deploys services
# For other environments only deploys a service if it wasn't there.
# Uses ruby and jq
function deployServices() {
  if [[ "$( pipelineDescriptorExists )" == "true" ]]; then
    export PARSED_YAML=$( yaml2json "pipeline.yml" )
    while read -r line; do
      for service in "${line}"
      do
        set ${service}
        serviceType=${1}
        serviceName=${2}
        serviceCoordinates=${3}
        if [[ "${ENVIRONMENT}" == "TEST" ]]; then
          deleteService "${serviceType}" "${serviceName}"
          deployService "${serviceType}" "${serviceName}" "${serviceCoordinates}"
        else
          if [[ "$( serviceExists ${serviceName} )" == "true" ]]; then
            echo "Skipping deployment since service is already deployed"
          else
            deployService "${serviceType}" "${serviceName}" "${serviceCoordinates}"
          fi
        fi
      done
    # Removes quotes from the result and retrieve the space separated type, name and coordinates
    done <<< "$( echo "${PARSED_YAML}" | jq --arg x ${LOWER_CASE_ENV} '.[$x].services[] | "\(.type) \(.name) \(.coordinates)"' | sed 's/^"\(.*\)"$/\1/' )"
  else
    echo "No pipeline descriptor found - will not deploy any services"
  fi
}

# Checks for existence of pipeline.yaml file that contains types and names of the
# services required to be deployed for the given environment
function pipelineDescriptorExists() {
    if [ -f "pipeline.yml" ]
    then
        echo "true"
    else
        echo "false"
    fi
}

function deleteService() {
    local serviceType="${1}"
    local serviceName="${2}"
    echo "Should delete a service of type [${serviceType}] and name [${serviceName}]
    Example: deleteService mysql foo-mysql"
    exit 1
}

function deployService() {
    local serviceType="${1}"
    local serviceName="${2}"
    local serviceCoordinates="${3}"
    echo "Should deploy a service of type [${serviceType}], name [${serviceName}] and coordinates [${serviceCoordinates}]
    Example: deployService eureka foo-eureka groupid:artifactid:1.0.0.RELEASE"
    exit 1
}

function serviceExists() {
    local serviceType="${1}"
    local serviceName="${2}"
    echo "Should check if a service of type [${serviceType}] and name [${serviceName}] exists
    Example: serviceExists mysql foo-mysql
    Returns: 'true' if service exists and 'false' if it doesn't"
    exit 1
}

# Converts YAML to JSON - uses ruby
function yaml2json() {
    ruby -ryaml -rjson -e \
         'puts JSON.pretty_generate(YAML.load(ARGF))' $*
}

function lowerCaseEnv() {
    local string=${1}
    echo "${ENVIRONMENT}" | tr '[:upper:]' '[:lower:]'
}

function isSnapshot() {
    echo "${PIPELINE_VERSION}" | grep -ioq "SNAPSHOT"
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

echo "Current environment is [${ENVIRONMENT}]"
export LOWER_CASE_ENV=$( lowerCaseEnv )
