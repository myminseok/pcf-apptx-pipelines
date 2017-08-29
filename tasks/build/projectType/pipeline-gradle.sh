#!/bin/bash
set -e

function build() {
    echo "Additional Build Options [${BUILD_OPTIONS}]"

    if [[ "${CI}" == "CONCOURSE" ]]; then
        ./gradlew clean build -PnewVersion=${PIPELINE_VERSION} --stacktrace ${BUILD_OPTIONS} || ( $( printTestResults ) && return 1)
    else
        ./gradlew clean build -PnewVersion=${PIPELINE_VERSION} --stacktrace ${BUILD_OPTIONS}
    fi

    local artifactId="sample-spring-cloud-svc"
    local groupId="org.bk"
    local changedGroupId="$( echo "${groupId}" | tr . / )"
    local artifactVersion=${PIPELINE_VERSION}

    echo "Copying artifacts from build/libs to ../out"
    mkdir -p ../out/${changedGroupId}/${artifactId}/${artifactVersion}/
    cp -p build/libs/${artifactId}-${artifactVersion}.jar ../out/${changedGroupId}/${artifactId}/${artifactVersion}/${artifactId}-${artifactVersion}.jar
}

export -f build
