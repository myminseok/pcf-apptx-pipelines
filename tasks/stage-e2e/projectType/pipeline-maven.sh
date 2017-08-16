#!/bin/bash
set -e

function runE2eTests() {
    # Retrieves Application URL
    retrieveApplicationUrl
    local applicationHost="${APPLICATION_URL}"
    echo "Running e2e tests"

    if [[ "${CI}" == "CONCOURSE" ]]; then
        ./mvnw clean install -Pe2e -Dapplication.url="${applicationHost}" ${BUILD_OPTIONS} || ( $( printTestResults ) && return 1)
    else
        ./mvnw clean install -Pe2e -Dapplication.url="${applicationHost}" ${BUILD_OPTIONS}
    fi
}

export -f runE2eTests
