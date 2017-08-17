#!/bin/bash
set -e

[[ -f "${FUNCTIONS_FOLDER}/pipeline-cf.sh" ]] && source "${FUNCTIONS_FOLDER}/pipeline-cf.sh" || \
    echo "No ${FUNCTIONS_FOLDER}/pipeline-cf.sh found"

function testDeploy() {
    # TODO: Consider making it less JVM specific
    projectGroupId=$( retrieveGroupId )
    appName=$( retrieveAppName )
    # Log in to PaaS to start deployment
    logInToPaas

    # First delete the app instance to remove all bindings
    deleteAppInstance "${appName}"

    deployServices

    # deploy app
    if isSnapshot; then
        downloadAppBinary ${REPO_WITH_SNAPSHOT_BINARIES} ${projectGroupId} ${appName} ${PIPELINE_VERSION}
    else
        downloadAppBinary ${REPO_WITH_BINARIES} ${projectGroupId} ${appName} ${PIPELINE_VERSION}
    fi
    deployAndRestartAppWithNameForSmokeTests ${appName} "${appName}-${PIPELINE_VERSION}" "${UNIQUE_RABBIT_NAME}" "${UNIQUE_EUREKA_NAME}" "${UNIQUE_MYSQL_NAME}"
    propagatePropertiesForTests ${appName}
}
