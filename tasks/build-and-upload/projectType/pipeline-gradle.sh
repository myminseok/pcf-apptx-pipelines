#!/bin/bash
set -e

function build() {
    echo "Additional Build Options [${BUILD_OPTIONS}]"

    if [[ "${CI}" == "CONCOURSE" ]]; then
        ./gradlew clean build deploy -PnewVersion=${PIPELINE_VERSION} -DREPO_WITH_BINARIES=${REPO_WITH_BINARIES} --stacktrace ${BUILD_OPTIONS} || ( $( printTestResults ) && return 1)
    else
        ./gradlew clean build deploy -PnewVersion=${PIPELINE_VERSION} -DREPO_WITH_BINARIES=${REPO_WITH_BINARIES} --stacktrace ${BUILD_OPTIONS}
    fi
}

export -f build
