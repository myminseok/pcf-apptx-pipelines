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

function deployAndRestartAppWithName() {
    local appName="${1}"
    local jarName="${2}"
    local env="${ENVIRONMENT}"
    echo "Deploying and restarting app with name [${appName}] and jar name [${jarName}]"
    deployAppWithName "${appName}" "${jarName}" "${env}" 'true'
    restartApp "${appName}"
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

function deployService() {
    local serviceType=$( toLowerCase "${1}" )
    local serviceName="${2}"
    local serviceCoordinates=$( if [[ "${3}" == "null" ]] ; then echo ""; else echo "${3}" ; fi )
    case ${serviceType} in
    rabbitmq)
      deployRabbitMq "${serviceName}"
      ;;
    mysql)
      deployMySql "${serviceName}"
      ;;
    eureka)
      PREVIOUS_IFS="${IFS}"
      IFS=: read -r EUREKA_GROUP_ID EUREKA_ARTIFACT_ID EUREKA_VERSION <<< "${serviceCoordinates}"
      IFS="${PREVIOUS_IFS}"
      downloadAppBinary ${REPO_WITH_BINARIES} ${EUREKA_GROUP_ID} ${EUREKA_ARTIFACT_ID} ${EUREKA_VERSION}
      deployEureka "${EUREKA_ARTIFACT_ID}-${EUREKA_VERSION}" "${serviceName}" "${ENVIRONMENT}"
      ;;
    stubrunner)
      UNIQUE_EUREKA_NAME="$( echo ${PARSED_YAML} | jq --arg x ${LOWER_CASE_ENV} '.[$x].services[] | select(.type == "eureka") | .name' | sed 's/^"\(.*\)"$/\1/' )"
      UNIQUE_RABBIT_NAME="$( echo ${PARSED_YAML} | jq --arg x ${LOWER_CASE_ENV} '.[$x].services[] | select(.type == "rabbitmq") | .name' | sed 's/^"\(.*\)"$/\1/' )"
      PREVIOUS_IFS="${IFS}"
      IFS=: read -r STUBRUNNER_GROUP_ID STUBRUNNER_ARTIFACT_ID STUBRUNNER_VERSION <<< "${serviceCoordinates}"
      IFS="${PREVIOUS_IFS}"
      PARSED_STUBRUNNER_USE_CLASSPATH="$( echo ${PARSED_YAML} | jq --arg x ${LOWER_CASE_ENV} '.[$x].services[] | select(.type == "stubrunner") | .useClasspath' | sed 's/^"\(.*\)"$/\1/' )"
      STUBRUNNER_USE_CLASSPATH=$( if [[ "${PARSED_STUBRUNNER_USE_CLASSPATH}" == "null" ]] ; then echo "false"; else echo "${PARSED_STUBRUNNER_USE_CLASSPATH}" ; fi )
      downloadAppBinary ${REPO_WITH_BINARIES} ${STUBRUNNER_GROUP_ID} ${STUBRUNNER_ARTIFACT_ID} ${STUBRUNNER_VERSION}
      deployStubRunnerBoot "${STUBRUNNER_ARTIFACT_ID}-${STUBRUNNER_VERSION}" "${REPO_WITH_BINARIES}" "${UNIQUE_RABBIT_NAME}" "${UNIQUE_EUREKA_NAME}" "${ENVIRONMENT}" "${serviceName}"
      ;;
    *)
      echo "Unknown service with type [${serviceType}] and name [${serviceName}]"
      return 1
      ;;
    esac
}

function deleteService() {
    local serviceType=$( toLowerCase "${1}" )
    local serviceName="${2}"
    case ${serviceType} in
    mysql)
      deleteMySql "${serviceName}"
      ;;
    rabbitmq)
      deleteRabbitMq "${serviceName}"
      ;;
    *)
      deleteServiceWithName "${serviceName}" || echo "Failed to delete service with type [${serviceType}] and name [${serviceName}]"
      ;;
    esac
}

function deployRabbitMq() {
    local serviceName="${1:-rabbitmq-github}"
    echo "Waiting for RabbitMQ to start"
    local foundApp=$( serviceExists "rabbitmq" "${serviceName}" )
    if [[ "${foundApp}" == "false" ]]; then
        hostname="${hostname}-${PAAS_HOSTNAME_UUID}"
        (cf cs cloudamqp lemur "${serviceName}" && echo "Started RabbitMQ") ||
        (cf cs p-rabbitmq standard "${serviceName}" && echo "Started RabbitMQ for PCF Dev")
    else
        echo "Service [${serviceName}] already started"
    fi
}

function findAppByName() {
    local serviceName="${1}"
    echo $( cf s | awk -v "app=${serviceName}" '$1 == app {print($0)}' )
}

function serviceExists() {
    local serviceType="${1}"
    local serviceName="${2}"
    local foundApp=$( findAppByName "${serviceName}" )
    if [[ "${foundApp}" == "" ]]; then
        echo "false"
    else
        echo "true"
    fi
}

function deleteMySql() {
    local serviceName="${1:-mysql-github}"
    deleteServiceWithName ${serviceName}
}

function deleteRabbitMq() {
    local serviceName="${1:-rabbitmq-github}"
    deleteServiceWithName ${serviceName}
}

function deleteServiceWithName() {
    local serviceName="${1}"
    cf delete -f ${serviceName} || echo "Failed to delete app [${serviceName}]"
    cf delete-service -f ${serviceName} || echo "Failed to delete service [${serviceName}]"
}

function deployMySql() {
    local serviceName="${1:-mysql-github}"
    echo "Waiting for MySQL to start"
    local foundApp=$( serviceExists "mysql" "${serviceName}" )
    if [[ "${foundApp}" == "false" ]]; then
        hostname="${hostname}-${PAAS_HOSTNAME_UUID}"
        (cf cs p-mysql 100mb-dev "${serviceName}" && echo "Started MySQL") ||
        (cf cs p-mysql 512mb "${serviceName}" && echo "Started MySQL for PCF Dev") ||
        (cf cs cleardb spark "${serviceName}" && echo "Started MySQL for PWS")
    else
        echo "Service [${serviceName}] already started"
    fi
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

function stageDeploy() {
    # TODO: Consider making it less JVM specific
    projectGroupId=$( retrieveGroupId )
    appName=$( retrieveAppName )
    # Log in to PaaS to start deployment
    logInToPaas

    deployServices

    downloadAppBinary ${REPO_WITH_BINARIES} ${projectGroupId} ${appName} ${PIPELINE_VERSION}

    # deploy app
    deployAndRestartAppWithName ${appName} "${appName}-${PIPELINE_VERSION}"
    propagatePropertiesForTests ${appName}
}
