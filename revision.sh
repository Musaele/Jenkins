#!/bin/bash

ORG=$1
ProxyName=$2
ENV=$3

echo "ORG: $ORG"
echo "ProxyName: $ProxyName"
echo "ENV: $ENV"

# Get the access token from Apigee
      access_token=$(curl -H "Authorization: Basic QVZxZ1I4Yk9vV24wcHRBOVZDYmNhSk11aVpzVFlkNFpGa0x0bHducTRpbE9tOFV5OjZBaW5pT3U2QXJGMUNuOGZHcVFzUXozRjFqbTZrRVhtMExZUGhJeDFBT3BlRURkVzB0OUtQRlFZRURpWHhsajA=" "https://api.abacus-apigeee.com/v1/management/token" | jq -r ".access_token")
	  #access_token="ya29.a0AfB_byBAmGRHLKFVs6uPGlFyc3eMaiqvW0NGs-gpg69ONkloQYWLYsQKookQSI1symZbvqXqc1HtMLT8Lw0tVRFVqZR3XeJMBQa4psCg6flFPBxqJcrecXRDSXYIeP_iCEtBPBIuBQOw5bCyOytZtxTwRUB-fJu7rAz7_qyh6zetq4A53_wJ6jz5s4wrJQLzWHtRAO1ZpKrLNsh0y6c8cejaK1M2TCEUoN3ihorw_HZl58csZwnyiQp9ao7-81d6brNTeDav8RLUhboKrgduVW4JS-enSYudM8sF9D9YsIUJRNuCCiGoGYSXx5ECRTlzgI4W1mzSkpC3dPKK8YbRH5JDhZsL4Fu1JD3P3QN0-IpGpaS96Ot4MoSnhZO-iRhuYEJz_2NoEFhdghaZ3zsrWqyjGyFfTskaCgYKAUYSARMSFQHGX2Mi7PykE8QtxErY3gY8arUDXg0422"

      if [ -z "$access_token" ]; then
        echo "Failed to obtain access token. Check your Apigee credentials and try again."
        exit 1
      fi

echo "access_token: $access_token"

# Get stable_revision_number using access_token
revision_info=$(curl -H "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$ORG/environments/$ENV/apis/$ProxyName/deployments")

# Check if the curl command was successful
if [ $? -eq 0 ]; then
    # Extract the revision number using jq, handling the case where .deployments is null or empty
    stable_revision_number=$(echo "$revision_info" | jq -r ".deployments[0]?.revision // null")

    echo "Stable Revision: $stable_revision_number"
else
    # Handle the case where the curl command failed
    echo "Error: Failed to retrieve API deployments."
fi
