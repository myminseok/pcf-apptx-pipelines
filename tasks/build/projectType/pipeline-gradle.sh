#!/bin/bash
set -e

function build() {
    echo "Additional Build Options [${BUILD_OPTIONS}]"

    if [[ "${CI}" == "CONCOURSE" ]]; then
        ./gradlew clean build -PnewVersion=${PIPELINE_VERSION} --stacktrace ${BUILD_OPTIONS} || ( $( printTestResults ) && return 1)
    else
        ./gradlew clean build -PnewVersion=${PIPELINE_VERSION} --stacktrace ${BUILD_OPTIONS}
    fi
}

export -f build
