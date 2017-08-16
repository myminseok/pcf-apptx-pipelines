#!/bin/bash
set -e

function retrieveGroupId() {
    local result=$( ./gradlew groupId -q )
    result=$( echo "${result}" | tail -1 )
    echo "${result}"
}

function retrieveAppName() {
    local result=$( ./gradlew artifactId -q )
    result=$( echo "${result}" | tail -1 )
    echo "${result}"
}

function retrieveStubRunnerIds() {
    echo "$( ./gradlew stubIds -q | tail -1 )"
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

export -f outputFolder
export -f testResultsAntPattern
