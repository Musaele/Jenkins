#!/bin/bash

ORG=$1
SECRET_FILE=$2
NEWMAN_TARGET_URL=$3

# Read client ID and client secret from the secret file
client_id=$(grep -E "^client_id=" "$SECRET_FILE" | cut -d'=' -f2)
client_secret=$(grep -E "^client_secret=" "$SECRET_FILE" | cut -d'=' -f2)

# Check if the client ID and client secret are not empty
if [[ -z "$client_id" ]]; then
  echo "Error: client_id is empty"
  exit 1
fi

if [[ -z "$client_secret" ]]; then
  echo "Error: client_secret is empty"
  exit 1
fi

echo "client_id at script: '$client_id'"
echo "client_secret at script: '$client_secret'"

# Install newman
npm install -g newman

# Run Newman tests
newman run "$NEWMAN_TARGET_URL" --reporters cli,junit --reporter-junit-export junitReport.xml --env-var client_id="$client_id" --env-var client_secret="$client_secret"
