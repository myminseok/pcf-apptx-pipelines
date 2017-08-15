#!/bin/bash
set -e

function logInToPaas() {
    local user="PAAS_${ENVIRONMENT}_USERNAME"
    local cfUsername="${!user}"
    local pass="PAAS_${ENVIRONMENT}_PASSWORD"
    local cfPassword="${!pass}"
    local org="PAAS_${ENVIRONMENT}_ORG"
    local cfOrg="${!org}"
    local space="PAAS_${ENVIRONMENT}_SPACE"
    local cfSpace="${!space}"
    local api="PAAS_${ENVIRONMENT}_API_URL"
    local apiUrl="${!api:-api.run.pivotal.io}"
    CF_INSTALLED="$( cf --version || echo "false" )"
    CF_DOWNLOADED="$( test -r cf && echo "true" || echo "false" )"
    echo "CF Installed? [${CF_INSTALLED}], CF Downloaded? [${CF_DOWNLOADED}]"
    if [[ ${CF_INSTALLED} == "false" && ${CF_DOWNLOADED} == "false" ]]; then
        echo "Downloading Cloud Foundry"
        curl -L "https://cli.run.pivotal.io/stable?release=linux64-binary&source=github" --fail | tar -zx
        CF_DOWNLOADED="true"
    else
        echo "CF is already installed"
    fi

    if [[ ${CF_DOWNLOADED} == "true" ]]; then
        echo "Adding CF to PATH"
        PATH=${PATH}:`pwd`
        chmod +x cf
    fi

    echo "Cloud foundry version"
    cf --version

    echo "Logging in to CF to org [${cfOrg}], space [${cfSpace}]"
    cf api --skip-ssl-validation "${apiUrl}"
    cf login -u "${cfUsername}" -p "${cfPassword}" -o "${cfOrg}" -s "${cfSpace}"
}

function appHost() {
    local appName="${1}"
    local lowerCase="$( toLowerCase "${appName}" )"
    local APP_HOST=`cf apps | awk -v "app=${lowerCase}" '$1 == app {print($0)}' | tr -s ' ' | cut -d' ' -f 6 | cut -d, -f1`
    echo "${APP_HOST}" | tail -1
}

function propagatePropertiesForTests() {
    local projectArtifactId="${1}"
    local stubRunnerHost="${2:-stubrunner-${projectArtifactId}}"
    local fileLocation="${3:-${OUTPUT_FOLDER}/test.properties}"
    echo "Propagating properties for tests. Project [${projectArtifactId}] stub runner host [${stubRunnerHost}] properties location [${fileLocation}]"
    # retrieve host of the app / stubrunner
    # we have to store them in a file that will be picked as properties
    rm -rf "${fileLocation}"
    local host=$( appHost "${projectArtifactId}" )
    export APPLICATION_URL="${host}"
    echo "APPLICATION_URL=${host}" >> ${fileLocation}
    host=$( appHost "${stubRunnerHost}" )
    export STUBRUNNER_URL="${host}"
    echo "STUBRUNNER_URL=${host}" >> ${fileLocation}
    echo "Resolved properties"
    cat ${fileLocation}
}

function toLowerCase() {
    local string=${1}
    local result=$( echo "${string}" | tr '[:upper:]' '[:lower:]' )
    echo "${result}"
}

function retrieveApplicationUrl() {
    echo "Retrieving artifact id - it can take a while..."
    appName=$( retrieveAppName )
    echo "Project artifactId is ${appName}"
    mkdir -p "${OUTPUT_FOLDER}"
    logInToPaas
    propagatePropertiesForTests ${appName}
    readTestPropertiesFromFile
    echo "Application URL [${APPLICATION_URL}]"
}

function readTestPropertiesFromFile() {
    local fileLocation="${1:-${OUTPUT_FOLDER}/test.properties}"
    if [ -f "${fileLocation}" ]
    then
      echo "${fileLocation} found."
      while IFS='=' read -r key value
      do
        key=$(echo ${key} | tr '.' '_')
        eval "${key}='${value}'"
      done < "${fileLocation}"
    else
      echo "${fileLocation} not found."
    fi
}
