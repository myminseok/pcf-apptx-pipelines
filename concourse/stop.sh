#!/bin/bash
ROOT_ADDRESS=${1:-`./whats_my_ip.sh`}

echo "Provided external address is [${ROOT_ADDRESS}]"

export CONCOURSE_EXTERNAL_URL=http://${ROOT_ADDRESS}:8080
export CONCOURSE_USER=${2:-concourse}
export CONCOURSE_PASSWORD=${3:-changeme}

docker-compose stop