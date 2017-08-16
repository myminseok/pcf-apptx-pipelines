#!/bin/bash
set -e

[[ -f "${FUNCTIONS_FOLDER}/pipeline-cf.sh" ]] && source "${FUNCTIONS_FOLDER}/pipeline-cf.sh" || \
    echo "No ${FUNCTIONS_FOLDER}/pipeline-cf.sh found"

function testRollbackDeploy() {
    rm -rf ${OUTPUT_FOLDER}/test.properties
    local latestProdTag="${1}"
    projectGroupId=$( retrieveGroupId )
    appName=$( retrieveAppName )
    # Downloading latest jar
    LATEST_PROD_VERSION=${latestProdTag#prod/}
    echo "Last prod version equals ${LATEST_PROD_VERSION}"
    downloadAppBinary ${REPO_WITH_BINARIES} ${projectGroupId} ${appName} ${LATEST_PROD_VERSION}
    logInToPaas
    deployAndRestartAppWithNameForSmokeTests ${appName} "${appName}-${LATEST_PROD_VERSION}"
    propagatePropertiesForTests ${appName}
    # Adding latest prod tag
    echo "LATEST_PROD_TAG=${latestProdTag}" >> ${OUTPUT_FOLDER}/test.properties
}