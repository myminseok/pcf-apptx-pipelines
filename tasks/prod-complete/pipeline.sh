#!/bin/bash
set -e

[[ -f "${FUNCTIONS_FOLDER}/pipeline-cf.sh" ]] && source "${FUNCTIONS_FOLDER}/pipeline-cf.sh" || \
    echo "No ${FUNCTIONS_FOLDER}/pipeline-cf.sh found"

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
