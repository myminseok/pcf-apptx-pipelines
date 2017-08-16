#!/bin/bash
set -e

function apiCompatibilityCheck() {
    echo "Running retrieval of group and artifactid to download all dependencies. It might take a while..."
    projectGroupId=$( retrieveGroupId )
    appName=$( retrieveAppName )

    # Find latest prod version
    LATEST_PROD_TAG=$( findLatestProdTag )
    echo "Last prod tag equals ${LATEST_PROD_TAG}"
    if [[ -z "${LATEST_PROD_TAG}" ]]; then
        echo "No prod release took place - skipping this step"
    else
        # Downloading latest jar
        LATEST_PROD_VERSION=${LATEST_PROD_TAG#prod/}
        echo "Last prod version equals ${LATEST_PROD_VERSION}"
        echo "Additional Build Options [${BUILD_OPTIONS}]"
        if [[ "${CI}" == "CONCOURSE" ]]; then
            ./mvnw clean verify -Papicompatibility -Dlatest.production.version=${LATEST_PROD_VERSION} -Drepo.with.binaries=${REPO_WITH_BINARIES} ${BUILD_OPTIONS} || ( $( printTestResults ) && return 1)
        else
            ./mvnw clean verify -Papicompatibility -Dlatest.production.version=${LATEST_PROD_VERSION} -Drepo.with.binaries=${REPO_WITH_BINARIES} ${BUILD_OPTIONS}
        fi
    fi
}

export -f apiCompatibilityCheck
