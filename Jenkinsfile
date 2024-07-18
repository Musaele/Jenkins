pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
        GCP_SA_KEY = credentials('service_file') // Ensure your GCP service account key is stored as a Jenkins credential
    }

    stages {
        stage('Build') {
            steps {
                script {
                    // Installing required dependencies
                    sh '''
                    sudo apt-get update -qy
                    sudo apt-get install -y curl jq maven npm gnupg
                    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                    echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
                    sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                    curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
                    '''
                }
                script {
                    // Copy the service account key to a secure location
                    withCredentials([file(credentialsId: 'service_file', variable: 'SERVICE_ACCOUNT_KEY')]) {
                        sh '''
                        mkdir -p .secure_files
                        cp $SERVICE_ACCOUNT_KEY .secure_files/service-account.json
                        '''
                    }
                }
                script {
                    // Executing revision1.sh script to get access token & stable_revision_number
                    sh '''
                    #!/bin/bash

                    ORG=${ORG}
                    ProxyName=${PROXY_NAME}
                    ENV=${APIGEE_ENVIRONMENT}

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
                    echo "access_token=$access_token" >> build.env

                    # Get stable_revision_number using access_token
                    revision_info=$(curl -H "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$ORG/environments/$ENV/apis/$ProxyName/deployments")

                    # Check if the curl command was successful
                    if [ $? -eq 0 ]; then
                        # Extract the revision number using jq, handling the case where .deployments is null or empty
                        stable_revision_number=$(echo "$revision_info" | jq -r ".deployments[0]?.revision // null")
                        echo "Stable Revision: $stable_revision_number"
                        # Save the stable revision number in the environment file
                        echo "stable_revision_number=$stable_revision_number" >> build.env
                    else
                        # Handle the case where the curl command failed
                        echo "Error: Failed to retrieve API deployments."
                    fi
                    '''
                }
                script {
                    // Loading environment variables from build.env
                    def props = readProperties file: 'build.env'
                    env.access_token = props['access_token']
                    env.stable_revision_number = props['stable_revision_number']
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build.env', allowEmptyArchive: true
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    sh '''
                    echo "stable revision at stage deploy: $stable_revision_number"
                    mvn clean install -f $WORKSPACE/${PROXY_NAME}/pom.xml \
                        -P${APIGEE_ENVIRONMENT} \
                        -Dorg=${ORG} \
                        -Dbearer=${access_token}
                    '''
                }
            }
        }

        // Uncomment and configure the following stages as needed

        // stage('Integration Test') {
        //     steps {
        //         script {
        //             sh '''
        //             echo "stable revision at stage integration_test: $stable_revision_number"
        //             bash ./integration.sh ${ORG} $base64encoded $NEWMAN_TARGET_URL
        //             '''
        //         }
        //     }
        //     post {
        //         success {
        //             junit 'junitReport.xml'
        //         }
        //     }
        // }

        // stage('Undeploy') {
        //     when {
        //         expression {
        //             return currentBuild.currentResult == 'FAILURE'
        //         }
        //     }
        //     steps {
        //         script {
        //             sh '''
        //             echo "stable revision at stage undeploy: $stable_revision_number"
        //             cd $WORKSPACE
        //             bash ./undeploy.sh ${ORG} $base64encoded ${PROXY_NAME} ${stable_revision_number} ${APIGEE_ENVIRONMENT}
        //             '''
        //         }
        //     }
        // }
    }
}
