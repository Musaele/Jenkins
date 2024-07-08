#!/bin/bash

ORG=$1
base64encoded=$2
NEWMAN_TARGET_URL=$3

client_id=$(curl -H "Authorization: Basic $base64encoded" "https://api.enterprise.apigee.com/v1/organizations/$ORG/apiproducts/Cicd-Prod-Product?query=list&entity=keys")

id=$(jq -r .[0] <<< "${client_id}" )
echo "client_id at script: '$id'"

client_secret=$(curl -H "Authorization: Basic $base64encoded" "https://api.enterprise.apigee.com/v1/organizations/$ORG/developers/hr@api.com/apps/hrapp/keys/$id")

secret=$(jq -r .consumerSecret <<< "${client_secret}" )
echo "client_secret at script: '$secret'"

npm install -g newman
#newman run $NEWMAN_TARGET_URL --reporters cli,junit --reporter-junit-export junitReport.xml --env-var client_id=$id --env-var client_secret=$secret
newman run $CI_PROJECT_DIR/$NEWMAN_TARGET_URL --reporters cli,junit --reporter-junit-export $CI_PROJECT_DIR/junitReport.xml --env-var client_id=$id --env-var client_secret=$secret
