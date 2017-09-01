#!/bin/bash

# The script will clone the sc-pipelines repo and copy over tasks in the
# supported structure we have.
# You can provide a destination directory to which project should be cloned.
# If not provided will use a temporary directory.
#
# Examples:
#   $ ./tools/cp-sc-pipeline-tasks.sh
#   $ ./tools/deploy-infra.sh ../repos/pivotal/
#

set -o errexit


CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -lt 1 ]]; then
	DEST_DIR="$( mktemp -d )"
else
	DEST_DIR="$1"
fi

function copy_pipelines {
	local project_repo="$1"
	local project_name

	project_name="$( basename "${project_repo}" )"

	echo "Cloning ${project_name} to ${DEST_DIR}"

	pushd "${DEST_DIR}"
	rm -rf "${project_name}"
	git clone "${project_repo}" "${project_name}" && cd "${project_name}"/concourse
	local tasks=$(ls tasks/*.yml | awk '{ print $1 }')

	for task in ${tasks}; do
		local task_folder=$(echo ${task} | sed 's/\.yml/\/task.yml/g')
		local script_folder=$(echo ${task} | sed 's/\.yml/\/task.sh/g')
		local script=$(echo ${task} | sed 's/\.yml/\.sh/g')
	  echo "Copy ${task} ${CWD}/../${task_folder}"
		cp ${task} ${CWD}/../${task_folder}
		echo "Copy ${script} ${CWD}/../${script_folder}"
		cp ${script} ${CWD}/../${script_folder}
	done
	popd
	rm -rf ${DEST_DIR}
}

echo "Destination directory to clone the apps is [${DEST_DIR}]"

copy_pipelines "https://github.com/spring-cloud/spring-cloud-pipelines"

echo "DONE!"
