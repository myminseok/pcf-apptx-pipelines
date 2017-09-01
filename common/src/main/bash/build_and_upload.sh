#!/bin/bash

set -o errexit

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export ENVIRONMENT=BUILD

[[ -f "${__DIR}/pipeline.sh" ]] && source "${__DIR}/pipeline.sh" || \
    echo "No pipeline.sh found"

__SCRIPT_NAME="$(dirname "${BASH_SOURCE[0]}")"

[[ -f "${__DIR}/${__SCRIPT_NAME}_custom.sh" ]] && source "${__DIR}/${__SCRIPT_NAME}_custom.sh" || \
    echo "No ${__SCRIPT_NAME}_custom.sh found"

build
