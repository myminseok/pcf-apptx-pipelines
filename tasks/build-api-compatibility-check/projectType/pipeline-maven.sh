#!/bin/bash
set -e

# It takes ages on Docker to run the app without this
if [[ ${BUILD_OPTIONS} != *"java.security.egd"* ]]; then
    if [[ ! -z ${BUILD_OPTIONS} && ${BUILD_OPTIONS} != "null" ]]; then
        export BUILD_OPTIONS="${BUILD_OPTIONS} -Djava.security.egd=file:///dev/urandom"
    else
        export BUILD_OPTIONS="-Djava.security.egd=file:///dev/urandom"
    fi
fi

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

function retrieveGroupId() {
    local result=$( ruby -r rexml/document -e 'puts REXML::Document.new(File.new(ARGV.shift)).elements["/project/groupId"].text' pom.xml || ./mvnw ${BUILD_OPTIONS} org.apache.maven.plugins:maven-help-plugin:2.2:evaluate -Dexpression=project.groupId |grep -Ev '(^\[|Download\w+:)' )
    result=$( echo "${result}" | tail -1 )
    echo "${result}"
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

export -f apiCompatibilityCheck
export -f testResultsAntPattern