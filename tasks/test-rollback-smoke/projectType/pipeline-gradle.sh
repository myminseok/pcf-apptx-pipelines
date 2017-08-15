#!/bin/bash
set -e

function runSmokeTests() {
    local applicationHost="${APPLICATION_URL}"
    local stubrunnerHost="${STUBRUNNER_URL}"
    echo "Running smoke tests"

    if [[ "${CI}" == "CONCOURSE" ]]; then
        ./gradlew smoke -PnewVersion=${PIPELINE_VERSION} -Dapplication.url="${applicationHost}" -Dstubrunner.url="${stubrunnerHost}" || ( echo "$( printTestResults )" && return 1)
    else
        ./gradlew smoke -PnewVersion=${PIPELINE_VERSION} -Dapplication.url="${applicationHost}" -Dstubrunner.url="${stubrunnerHost}"
    fi
}

function retrieveAppName() {
    local result=$( ./gradlew artifactId -q )
    result=$( echo "${result}" | tail -1 )
    echo "${result}"
}

function printTestResults() {
    echo -e "\n\nBuild failed!!! - will print all test results to the console (it's the easiest way to debug anything later)\n\n" && tail -n +1 "$( testResultsAntPattern )"
}

function outputFolder() {
    echo "build/libs"
}

function testResultsAntPattern() {
    echo "**/test-results/*.xml"
}

export -f runSmokeTests
export -f outputFolder
export -f testResultsAntPattern
