#!/bin/bash
set -e

[[ -f "${FUNCTIONS_FOLDER}/pipeline-cf.sh" ]] && source "${FUNCTIONS_FOLDER}/pipeline-cf.sh" || \
    echo "No ${FUNCTIONS_FOLDER}/pipeline-cf.sh found"

function performGreenDeployment() {
    projectGroupId=$( retrieveGroupId )
    appName=$( retrieveAppName )

    # download app
    downloadAppBinary ${REPO_WITH_BINARIES} ${projectGroupId} ${appName} ${PIPELINE_VERSION}
    # Log in to CF to start deployment
    logInToPaas

    # deploy app
    performGreenDeploymentOfTestedApplication "${appName}"
}

function performGreenDeploymentOfTestedApplication() {
    local appName="${1}"
    local newName="${appName}-venerable"
    echo "Renaming the app from [${appName}] -> [${newName}]"
    local appPresent="no"
    cf app "${appName}" && appPresent="yes"
    if [[ "${appPresent}" == "yes" ]]; then
        cf rename "${appName}" "${newName}"
    else
        echo "Will not rename the application cause it's not there"
    fi
    deployAndRestartAppWithName "${appName}" "${appName}-${PIPELINE_VERSION}"
}
