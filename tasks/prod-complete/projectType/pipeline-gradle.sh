#!/bin/bash
set -e

function retrieveAppName() {
    local result=$( ./gradlew artifactId -q )
    result=$( echo "${result}" | tail -1 )
    echo "${result}"
}

function outputFolder() {
    echo "build/libs"
}

function testResultsAntPattern() {
    echo "**/test-results/*.xml"
}
