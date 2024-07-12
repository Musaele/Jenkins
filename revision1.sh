#!/bin/bash

ORG=$1
PROXY_NAME=$2
ENV=$3

echo "ORG: ${ORG}"
echo "ProxyName: ${PROXY_NAME}"
echo "ENV: ${ENV}"

SERVICE_ACCOUNT_KEY_FILE=".secure_files/service-account.json"

if [ ! -f "${SERVICE_ACCOUNT_KEY_FILE}" ]; then
  echo "Service account key file '${SERVICE_ACCOUNT_KEY_FILE}' not found."
  exit 1
fi

# Activate the service account
gcloud auth activate-service-account --key-file="${SERVICE_ACCOUNT_KEY_FILE}"

# Set the project
gcloud config set project ${ORG}

# Example of listing APIs, you can replace this with your custom commands
echo "Listing APIs in project ${ORG} for environment ${ENV}..."

# Replace the following line with your actual script logic
# This is just an example command, modify as per your requirements
gcloud apigee apis list --organization=${ORG} --environment=${ENV}

# Additional script logic can be added below
# Example of deploying a proxy
# Replace the following lines with your actual deployment commands
echo "Deploying API proxy ${PROXY_NAME} to environment ${ENV}..."

# Example command to deploy an API proxy
# Modify according to your deployment requirements
gcloud apigee apis deploy ${PROXY_NAME} --environment=${ENV} --organization=${ORG}

echo "Deployment completed."
