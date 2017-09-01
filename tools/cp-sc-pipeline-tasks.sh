#!/bin/bash

# The script will clone the sc-pipelines repo and copy over tasks in the
# supported structure we have.
# You can provide a destination directory to which project should be cloned.
# If not provided will use a temporary directory.
#
# Examples:
#   $ ./tools/cp-sc-pipeline-tasks.sh
#   $ ./cp-sc-pipeline-tasks.sh master ../repos/pivotal/
#

set -o errexit


CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BRANCH=${1:-master}
SRC_DIR="$2"

function cleanup {
	local srcdir="$1"
  rm -rf ${srcdir}
}

function copy_pipelines {
	local project_repo="$1"
	local project_name

	project_name="$( basename "${project_repo}" )"

	if [ ! -d "$SRC_DIR" ]; then
		echo "Cloning ${project_name} to ${SRC_DIR}"

		SRC_DIR="$( mktemp -d )"
		pushd "${SRC_DIR}"
			rm -rf "${project_name}"
			git clone "${project_repo}" "${project_name}" && cd "${project_name}"/concourse
			git checkout ${BRANCH}
		popd
		trap 'cleanup "${SRC_DIR}"' EXIT
	fi

	pushd "${SRC_DIR}"
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
}

echo "Spring Cloud Pipelines directory is [${SRC_DIR}]"

copy_pipelines "https://github.com/spring-cloud/spring-cloud-pipelines"

echo "DONE!"
