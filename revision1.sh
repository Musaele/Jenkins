#!/bin/bash

ORG=$1
ProxyName=$2
ENV=$3

echo "ORG: $ORG"
echo "ProxyName: $ProxyName"
echo "ENV: $ENV"

# Set the path to your service account JSON key file
KEY_FILE=".secure_files/service-account.json"

echo "$KEY_FILE"

# Check if the key file exists
if [ ! -f "$KEY_FILE" ]; then
  echo "Service account key file '$KEY_FILE' not found."
  exit 1
fi

# Get the access token from Apigee
gcloud auth activate-service-account --key-file="$KEY_FILE"
access_token=$(gcloud auth print-access-token)

# Check if access token retrieval was successful
if [ -z "$access_token" ]; then
  echo "Failed to obtain access token. Check your Apigee credentials and try again."
  exit 1
fi

# Print the access token
echo "Access Token: $access_token"

# Save the access token in the environment file
echo "access_token=$access_token" >> $GITHUB_ENV

# Set output for GitHub Actions
echo "::set-output name=access_token::$access_token"

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
