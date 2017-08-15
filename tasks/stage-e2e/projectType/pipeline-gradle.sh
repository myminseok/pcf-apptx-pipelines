#!/bin/bash
set -e

function retrieveAppName() {
    local result=$( ./gradlew artifactId -q )
    result=$( echo "${result}" | tail -1 )
    echo "${result}"
}

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

function outputFolder() {
    echo "build/libs"
}

function testResultsAntPattern() {
    echo "**/test-results/*.xml"
}

export -f runE2eTests
export -f outputFolder
export -f testResultsAntPattern
