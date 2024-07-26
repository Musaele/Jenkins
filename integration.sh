#!/bin/bash

ORG=$1
base64encoded=$2
NEWMAN_TARGET_URL=$3

# Fetch client ID
client_id_response=$(curl -s -H "Authorization: Basic $base64encoded" "https://api.enterprise.apigee.com/v1/organizations/$ORG/apiproducts/Cicd-Prod-Product?query=list&entity=keys")
client_id=$(echo "$client_id_response" | jq -r '.[0]')

echo "client_id at script: '$client_id'"

# Fetch client secret
client_secret_response=$(curl -s -H "Authorization: Basic $base64encoded" "https://api.enterprise.apigee.com/v1/organizations/$ORG/developers/hr@api.com/apps/hrapp/keys/$client_id")
client_secret=$(echo "$client_secret_response" | jq -r '.consumerSecret')

echo "client_secret at script: '$client_secret'"

# Install newman
npm install -g newman

# Run Newman tests
newman run "$NEWMAN_TARGET_URL" --reporters cli,junit --reporter-junit-export junitReport.xml --env-var client_id="$client_id" --env-var client_secret="$client_secret"
