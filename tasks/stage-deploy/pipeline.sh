#!/bin/bash
set -e

[[ -f "${FUNCTIONS_FOLDER}/pipeline-cf.sh" ]] && source "${FUNCTIONS_FOLDER}/pipeline-cf.sh" || \
    echo "No ${FUNCTIONS_FOLDER}/pipeline-cf.sh found"

function stageDeploy() {
    # TODO: Consider making it less JVM specific
    projectGroupId=$( retrieveGroupId )
    appName=$( retrieveAppName )
    # Log in to PaaS to start deployment
    logInToPaas

    deployServices

    downloadAppBinary ${REPO_WITH_BINARIES} ${projectGroupId} ${appName} ${PIPELINE_VERSION}

    # deploy app
    deployAndRestartAppWithName ${appName} "${appName}-${PIPELINE_VERSION}"
    propagatePropertiesForTests ${appName}
}
