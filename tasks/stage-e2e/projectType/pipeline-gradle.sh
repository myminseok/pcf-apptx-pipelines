#!/bin/bash
set -e

function runE2eTests() {
    # Retrieves Application URL
    retrieveApplicationUrl
    local applicationHost="${APPLICATION_URL}"
    echo "Running e2e tests"

    if [[ "${CI}" == "CONCOURSE" ]]; then
        ./gradlew e2e -PnewVersion=${PIPELINE_VERSION} -Dapplication.url="${applicationHost}" ${BUILD_OPTIONS} || ( $( printTestResults ) && return 1)
    else
        ./gradlew e2e -PnewVersion=${PIPELINE_VERSION} -Dapplication.url="${applicationHost}" ${BUILD_OPTIONS}
    fi
}

export -f runE2eTests
