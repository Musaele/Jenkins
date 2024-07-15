#!/bin/bash

ORG=$1
ProxyName=$2
ENV=$3

echo "ORG: $ORG"
echo "ProxyName: $ProxyName"
echo "ENV: $ENV"

# Set the path where Jenkins mounts the secret file
SECRET_FILE_PATH="/var/lib/jenkins/workspace/Jenkins@tmp/secretFiles/service_file"

# Ensure the file exists (note: Jenkins manages file permissions itself)
if [ ! -f "$SECRET_FILE_PATH" ]; then
  echo "Service account key file '$SECRET_FILE_PATH' not found."
  exit 1
fi

# Copy the secret file to a location accessible to your script
cp "$SECRET_FILE_PATH" ./secure_files/service-account.json

# Get the access token from Apigee
gcloud auth activate-service-account --key-file="./secure_files/service-account.json"
access_token=$(gcloud auth print-access-token)

# Check if access token retrieval was successful
if [ -z "$access_token" ]; then
  echo "Failed to obtain access token. Check your Apigee credentials and try again."
  exit 1
fi

# Print the access token
echo "Access Token: $access_token"

# Save the access token in the environment file
echo "access_token=$access_token" >> .secure_files/build.env

# Set output for Jenkins pipeline
echo "access_token=$access_token"

# Get stable_revision_number using access_token
revision_info=$(curl -H "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$ORG/environments/$ENV/apis/$ProxyName/deployments")

# Check if the curl command was successful
if [ $? -eq 0 ]; then
    # Extract the revision number using jq, handling the case where .deployments is null or empty
    stable_revision_number=$(echo "$revision_info" | jq -r ".deployments[0]?.revision // null")
    echo "Stable Revision: $stable_revision_number"
    # Save the stable revision number in the environment file
    echo "stable_revision_number=$stable_revision_number" >> .secure_files/build.env
else
    # Handle the case where the curl command failed
    echo "Error: Failed to retrieve API deployments."
fi
