#!/bin/bash
set -e

function runSmokeTests() {
    local applicationHost="${APPLICATION_URL}"
    local stubrunnerHost="${STUBRUNNER_URL}"
    echo "Running smoke tests"

    if [[ "${CI}" == "CONCOURSE" ]]; then
        ./mvnw clean install -Psmoke -Dapplication.url="${applicationHost}" -Dstubrunner.url="${stubrunnerHost}" ${BUILD_OPTIONS} || ( echo "$( printTestResults )" && return 1)
    else
        ./mvnw clean install -Psmoke -Dapplication.url="${applicationHost}" -Dstubrunner.url="${stubrunnerHost}" ${BUILD_OPTIONS}
    fi
}

export -f runSmokeTests
