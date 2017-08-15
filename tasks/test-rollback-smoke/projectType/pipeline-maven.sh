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

function retrieveAppName() {
    local result=$( ruby -r rexml/document -e 'puts REXML::Document.new(File.new(ARGV.shift)).elements["/project/artifactId"].text' pom.xml || ./mvnw ${BUILD_OPTIONS} org.apache.maven.plugins:maven-help-plugin:2.2:evaluate -Dexpression=project.artifactId |grep -Ev '(^\[|Download\w+:)' )
    result=$( echo "${result}" | tail -1 )
    echo "${result}"
}

function printTestResults() {
    echo -e "\n\nBuild failed!!! - will print all test results to the console (it's the easiest way to debug anything later)\n\n" && tail -n +1 "$( testResultsAntPattern )"
}

function outputFolder() {
    echo "target"
}

function testResultsAntPattern() {
    echo "**/surefire-reports/*"
}

export -f runSmokeTests
export -f outputFolder
export -f testResultsAntPattern
