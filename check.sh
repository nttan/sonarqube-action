#!/bin/bash

set -e

exec 3>&1 # make stdout available as fd 3 for the result
exec 1>&2 # redirect all output to stderr for logging

#root=$(dirname "${0}" | while read -r a; do cd "${a}" && pwd && break; done)
#export root
source "/common.sh"
scanner_report_file="${GITHUB_WORKSPACE}/.scannerwork/report-task.txt"
project_status_file="${GITHUB_WORKSPACE}/qualitygate_project_status.json"
ce_task_info="${GITHUB_WORKSPACE}/ce_task.json"
sonar_token="${INPUT_SONARPASS}"
echo ${sonar_token}
sonar_host_url="${INPUT_HOST}"
ce_error="${GITHUB_WORKSPACE}/ce_error"
ce_task_status="PENDING"
ce_task_error=""
attempt=0
max_attempts=2

#Do until status is SUCCESS
until [[ "${ce_task_status}" != "PENDING" ]] && [[ "${ce_task_status}" != "IN_PROGRESS" ]] && [[ -n "${ce_task_status}" ]]; do
	attempt=$(( attempt + 1 ))
	set +e
	eval "$(read_properties "${scanner_report_file}" "shell")"
	sq_ce_task "${sonar_token}" "${sonar_host_url}" "${ceTaskId}" > "${ce_task_info}" 2>"${ce_error}" || { ce_task_error=$(<"${ce_error}"); }
	set -e
	ce_task_status=$(jq -r '.task.status // ""' < "${ce_task_info}")
	if [[ ${attempt} -gt ${max_attempts} ]] && [[ -z "${ce_task_status}" ]] ; then
		jq -n "{
			version: { ce_task_id: \"${ce_task_id}\"},
			metadata: [
				{ name: \"ce_task_status\", value: \"error: ${ce_task_error}\" }
			]
		}" >&3
		exit 1
	fi
	if [[ "${ce_task_status}" != "PENDING" ]] && [[ "${ce_task_status}" != "IN_PROGRESS" ]]; then
		echo "Waiting for compute engine result (sleep: 5s)..."
		sleep 5 # Poll SonarQube compute engine task every 5 seconds.
	fi
done

#call /api/qualitygates/project_status?analysisId=YYY to check the status of the quality gate
analysisId=$(jq -r '.task.analysisId // ""' < "${ce_task_info}")
sq_qualitygates_project_status "${sonar_token}" "${sonar_host_url}" ${analysisId} > "${project_status_file}"
metadata=$(metadata_from_conditions $project_status_file)
project_status=$(jq -r '.projectStatus.status // ""' < "${project_status_file}")

if [[ ${project_status} == "ERROR" ]]; then
    echo "Fail for sonar check. Please check on server";
    jq -n "{
	version: { ce_task_id: \"${ce_task_id}\"},
	metadata: [
		{ name: \"ce_task_status\", value: \"${ce_task_status}\" },
		{ name: \"project_status\", value: \"${project_status}\" }
	]
}" | jq --argjson m "$metadata" -r '.metadata += $m' >&3
    exit 1;
fi
echo "Hooray! SonarQube passed!"
