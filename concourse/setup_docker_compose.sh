#!/bin/bash

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p ${__DIR}/keys/web ${__DIR}/keys/worker

ssh-keygen -t rsa -f ${__DIR}/keys/web/tsa_host_key -N ''
ssh-keygen -t rsa -f ${__DIR}/keys/web/session_signing_key -N ''
ssh-keygen -t rsa -f ${__DIR}/keys/worker/worker_key -N ''

cp ${__DIR}/keys/worker/worker_key.pub ${__DIR}/keys/web/authorized_worker_keys
cp ${__DIR}/keys/web/tsa_host_key.pub ${__DIR}/keys/worker
