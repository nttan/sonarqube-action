#!/bin/bash

set -e

if [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then
	EVENT_ACTION=$(jq -r ".action" "${GITHUB_EVENT_PATH}")
	if [[ "${EVENT_ACTION}" != "opened" ]]; then
		echo "No need to run analysis. It is already triggered by the push event."
		exit 78
	fi
fi

if [[ -z "${INPUT_PASSWORD}" ]]; then
	SONAR_PASSWORD=""
else
	SONAR_PASSWORD="${INPUT_PASSWORD}"
fi

if [[ -z "${INPUT_SONARSOURCES}" ]]; then
	SONAR_SOURCES="."
else
	SONAR_SOURCES="${INPUT_SONARSOURCES}"
fi

sonar-scanner \
	-Dsonar.host.url=${INPUT_HOST} \
	-Dsonar.projectKey=${INPUT_PROJECTKEY} \
	-Dsonar.projectBaseDir=${INPUT_PROJECTBASEDIR} \
	-Dsonar.login=${INPUT_LOGIN} \
	-Dsonar.password=${INPUT_PASSWORD} \
	-Dsonar.sources=${SONAR_SOURCES} \
	-Dsonar.sourceEncoding=UTF-8 \
	${SONAR_PASSWORD}
pwd
ls -la .

#if [[ "${SONAR_SOURCES}" == "public_html_src/model" ]]; then
#  echo "Failed! Please check the sonar server"
#  exit 1
#fi
echo "Finish scan" > $GITHUB_WORKSPACE/test.log
