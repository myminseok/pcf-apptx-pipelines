#!/bin/bash
set -e

function retrieveAppName() {
    local result=$( ruby -r rexml/document -e 'puts REXML::Document.new(File.new(ARGV.shift)).elements["/project/artifactId"].text' pom.xml || ./mvnw ${BUILD_OPTIONS} org.apache.maven.plugins:maven-help-plugin:2.2:evaluate -Dexpression=project.artifactId |grep -Ev '(^\[|Download\w+:)' )
    result=$( echo "${result}" | tail -1 )
    echo "${result}"
}

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

function outputFolder() {
    echo "target"
}

function testResultsAntPattern() {
    echo "**/surefire-reports/*"
}

export -f runE2eTests
export -f outputFolder
export -f testResultsAntPattern