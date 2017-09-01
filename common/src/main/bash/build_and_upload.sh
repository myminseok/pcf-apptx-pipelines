#!/bin/bash

set -o errexit

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export ENVIRONMENT=BUILD

[[ -f "${__DIR}/pipeline.sh" ]] && source "${__DIR}/pipeline.sh" || \
    echo "No pipeline.sh found"

CUSTOM_SCRIPT="$(basename "${BASH_SOURCE}" | sed 's/.sh/_custom.sh/g')"

echo "Custom script name is [${CUSTOM_SCRIPT}]"

[[ -f "${__DIR}/${CUSTOM_SCRIPT}" ]] && source "${__DIR}/${CUSTOM_SCRIPT}" || \
    echo "No ${CUSTOM_SCRIPT} found"

build
