#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <org> <secret_file> <newman_target_url>"
    exit 1
fi

# Assign arguments to variables
ORG=$1
SECRET_FILE=$2
NEWMAN_TARGET_URL=$3

# Check if the secret file exists
if [ ! -f "$SECRET_FILE" ]; then
    echo "Error: Secret file does not exist at $SECRET_FILE"
    exit 1
fi

# Check if the Newman target URL file exists
if [ ! -f "$NEWMAN_TARGET_URL" ]; then
    echo "Error: Newman target URL file does not exist at $NEWMAN_TARGET_URL"
    exit 1
fi

# Extract values from the JSON file using jq
CLIENT_ID=$(jq -r '.client_id' "$SECRET_FILE")
CLIENT_SECRET=$(jq -r '.private_key' "$SECRET_FILE")  # Assuming private_key is used as client_secret

# Check if the extracted values are non-empty
if [ -z "$CLIENT_ID" ]; then
    echo "Error: client_id is empty"
    exit 1
fi

if [ -z "$CLIENT_SECRET" ]; then
    echo "Error: client_secret is empty"
    exit 1
fi

# Log extracted values (avoid logging sensitive information in real-world scenarios)
echo "client_id at script: '$CLIENT_ID'"
echo "client_secret at script: '$(echo "$CLIENT_SECRET" | head -n 1)'"  # Only show part of the secret for security reasons

# Install Newman if not already installed
if ! command -v newman &> /dev/null; then
    echo "Newman not found, installing..."
    npm install -g newman
fi

# Run Newman tests
newman run "$NEWMAN_TARGET_URL" --reporters cli,junit --reporter-junit-export junitReport.xml --env-var client_id="$CLIENT_ID" --env-var client_secret="$CLIENT_SECRET"

# Check if Newman command succeeded
if [ $? -ne 0 ]; then
    echo "Newman tests failed"
    exit 1
fi

echo "Newman tests succeeded"
exit 0
