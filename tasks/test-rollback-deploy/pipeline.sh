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

function deployAndRestartAppWithNameForSmokeTests() {
    local appName="${1}"
    local jarName="${2}"
    local rabbitName="${3}"
    local eurekaName="${4}"
    local mysqlName="${5}"
    local profiles="cloud,smoke"
    local lowerCaseAppName=$( toLowerCase "${appName}" )
    deleteAppInstance "${appName}"
    echo "Deploying and restarting app with name [${appName}] and jar name [${jarName}] and env [${env}]"
    deployAppWithName "${appName}" "${jarName}" "${ENVIRONMENT}" 'false'
    if [[ "${rabbitName}" != "" ]]; then
        bindService "${rabbitName}" "${appName}"
    fi
    if [[ "${eurekaName}" != "" ]]; then
        bindService "${eurekaName}" "${appName}"
    fi
    if [[ "${mysqlName}" != "" ]]; then
        bindService "${mysqlName}" "${appName}"
    fi
    setEnvVar "${lowerCaseAppName}" 'spring.profiles.active' "${profiles}"
    restartApp "${appName}"
}

function appHost() {
    local appName="${1}"
    local lowerCase="$( toLowerCase "${appName}" )"
    local APP_HOST=`cf apps | awk -v "app=${lowerCase}" '$1 == app {print($0)}' | tr -s ' ' | cut -d' ' -f 6 | cut -d, -f1`
    echo "${APP_HOST}" | tail -1
}

function deployAppWithName() {
    local appName="${1}"
    local jarName="${2}"
    local env="${3}"
    local useManifest="${4:-false}"
    local manifestOption=$( if [[ "${useManifest}" == "false" ]] ; then echo "--no-manifest"; else echo "" ; fi )
    local lowerCaseAppName=$( toLowerCase "${appName}" )
    local hostname="${lowerCaseAppName}"
    local memory="${APP_MEMORY_LIMIT:-256m}"
    local buildPackUrl="${JAVA_BUILDPACK_URL:-https://github.com/cloudfoundry/java-buildpack.git#v3.8.1}"
    if [[ "${PAAS_HOSTNAME_UUID}" != "" ]]; then
        hostname="${hostname}-${PAAS_HOSTNAME_UUID}"
    fi
    if [[ ${env} != "PROD" ]]; then
        hostname="${hostname}-${env}"
    fi
    echo "Deploying app with name [${lowerCaseAppName}], env [${env}] with manifest [${useManifest}] and host [${hostname}]"
    if [[ ! -z "${manifestOption}" ]]; then
        cf push "${lowerCaseAppName}" -m "${memory}" -i 1 -p "${OUTPUT_FOLDER}/${jarName}.jar" -n "${hostname}" --no-start -b "${buildPackUrl}" ${manifestOption}
    else
        cf push "${lowerCaseAppName}" -p "${OUTPUT_FOLDER}/${jarName}.jar" -n "${hostname}" --no-start -b "${buildPackUrl}"
    fi
    APPLICATION_DOMAIN="$( appHost ${lowerCaseAppName} )"
    echo "Determined that application_domain for [${lowerCaseAppName}] is [${APPLICATION_DOMAIN}]"
    setEnvVar "${lowerCaseAppName}" 'APPLICATION_DOMAIN' "${APPLICATION_DOMAIN}"
    setEnvVar "${lowerCaseAppName}" 'JAVA_OPTS' '-Djava.security.egd=file:///dev/urandom'
}

function deleteAppInstance() {
    local serviceName="${1}"
    local lowerCaseAppName=$( toLowerCase "${serviceName}" )
    local APP_NAME="${lowerCaseAppName}"
    echo "Deleting application [${APP_NAME}]"
    cf delete -f ${APP_NAME} || echo "Failed to delete the app. Continuing with the script"
}

function setEnvVar() {
    local appName="${1}"
    local key="${2}"
    local value="${3}"
    echo "Setting env var [${key}] -> [${value}] for app [${appName}]"
    cf set-env "${appName}" "${key}" "${value}"
}

function restartApp() {
    local appName="${1}"
    echo "Restarting app with name [${appName}]"
    cf restart "${appName}"
}

function bindService() {
    local serviceName="${1}"
    local appName="${2}"
    echo "Binding service [${serviceName}] to app [${appName}]"
    cf bind-service "${appName}" "${serviceName}"
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

function testRollbackDeploy() {
    rm -rf ${OUTPUT_FOLDER}/test.properties
    local latestProdTag="${1}"
    projectGroupId=$( retrieveGroupId )
    appName=$( retrieveAppName )
    # Downloading latest jar
    LATEST_PROD_VERSION=${latestProdTag#prod/}
    echo "Last prod version equals ${LATEST_PROD_VERSION}"
    downloadAppBinary ${REPO_WITH_BINARIES} ${projectGroupId} ${appName} ${LATEST_PROD_VERSION}
    logInToPaas
    deployAndRestartAppWithNameForSmokeTests ${appName} "${appName}-${LATEST_PROD_VERSION}"
    propagatePropertiesForTests ${appName}
    # Adding latest prod tag
    echo "LATEST_PROD_TAG=${latestProdTag}" >> ${OUTPUT_FOLDER}/test.properties
}