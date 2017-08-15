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


function build() {
    echo "Additional Build Options [${BUILD_OPTIONS}]"

    ./mvnw versions:set -DnewVersion=${PIPELINE_VERSION} ${BUILD_OPTIONS}
    if [[ "${CI}" == "CONCOURSE" ]]; then
        ./mvnw clean verify deploy -Ddistribution.management.release.id=${M2_SETTINGS_REPO_ID} -Ddistribution.management.release.url=${REPO_WITH_BINARIES} -Drepo.with.binaries=${REPO_WITH_BINARIES} ${BUILD_OPTIONS} || ( $( printTestResults ) && return 1)
    else
        ./mvnw clean verify deploy -Ddistribution.management.release.id=${M2_SETTINGS_REPO_ID} -Ddistribution.management.release.url=${REPO_WITH_BINARIES} -Drepo.with.binaries=${REPO_WITH_BINARIES} ${BUILD_OPTIONS}
    fi
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

export -f build
export -f testResultsAntPattern