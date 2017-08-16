#!/bin/bash
set -e

[[ -f "${FUNCTIONS_FOLDER}/pipeline-cf.sh" ]] && source "${FUNCTIONS_FOLDER}/pipeline-cf.sh" || \
    echo "No ${FUNCTIONS_FOLDER}/pipeline-cf.sh found"

function retrieveApplicationUrl() {
    echo "Retrieving artifact id - it can take a while..."
    appName=$( retrieveAppName )
    echo "Project artifactId is ${appName}"
    mkdir -p "${OUTPUT_FOLDER}"
    logInToPaas
    propagatePropertiesForTests ${appName}
    readTestPropertiesFromFile
    echo "Application URL [${APPLICATION_URL}]"
}
