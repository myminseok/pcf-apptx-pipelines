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

function deleteBlueInstance() {
    local appName=$( retrieveAppName )
    # Log in to CF to start deployment
    logInToPaas
    local oldName="${appName}-venerable"
    echo "Deleting the app [${oldName}]"
    cf app "${oldName}" && appPresent="yes"
    if [[ "${appPresent}" == "yes" ]]; then
        cf delete "${oldName}" -f
    else
        echo "Will not remove the old application cause it's not there"
    fi
}
