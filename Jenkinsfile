pipeline {
    agent any

    tools {
        maven 'M3'  // Using the configured Maven name
        nodejs 'nodejs-update'  // Using the configured NodeJS name
    }

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
        NEWMAN_TARGET_URL = 'NoTargetProxy_GET_Req_Pass.postman_collection.json' // Ensure this file exists in your project directory
    }

    stages {
        stage('Prepare Environment') {
            steps {
                script {
                    // Install required dependencies
                    sh 'sudo apt-get update -qy && sudo apt-get install -y curl jq gnupg'
                    // Install Google Cloud SDK if needed
                    sh '''
                        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                        echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                        sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                    '''
                    // Prepare secure files directory
                    sh 'mkdir -p .secure_files'
                }
            }
        }

        stage('Get Access Token and Stable Revision Number') {
            steps {
                script {
                    // Ensure revision1.sh is executable
                    sh 'chmod +x revision1.sh'

                    // Get the service account file from Jenkins credentials
                    withCredentials([file(credentialsId: "service_file", variable: "SECRET_FILE")]) {
                        sh 'cp "$SECRET_FILE" .secure_files/service-account.json'
                    }

                    // Execute the script with necessary parameters
                    sh './revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'

                    // Read the build.env file
                    def buildEnv = readFile '.secure_files/build.env'
                    def envVars = readProperties text: buildEnv

                    // Set the Jenkins environment variables
                    env.stable_revision = envVars['stable_revision_number']
                    env.access_token = envVars['access_token']

                    // Debugging log
                    echo "Stable revision number: ${env.stable_revision}"
                    echo "Access token: ${env.access_token}"
                }
            }
            post {
                success {
                    // Archive the build.env file from the correct path
                    archiveArtifacts artifacts: '.secure_files/build.env', allowEmptyArchive: false
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    // Use the environment variables
                    sh "mvn clean install -f /var/lib/jenkins/workspace/Jenkins/test-call/pom.xml -P${APIGEE_ENVIRONMENT} -Dorg=${ORG} -Dbearer=${env.access_token} -Dstable_revision_number=${env.stable_revision}"
                }
            }
        }

        stage('Integration Test') {
            steps {
                script {
                    // Make integration.sh executable
                    sh 'chmod +x integration.sh'

                    // Get the client_id and client_secret from the service account file
                    def serviceAccount = readJSON file: '.secure_files/service-account.json'
                    def client_id = serviceAccount.client_id
                    def client_secret = serviceAccount.private_key

                    // Encode client_id and client_secret to base64
                    def base64encoded = "${client_id}:${client_secret}".bytes.encodeBase64().toString()

                    // Execute integration tests
                    sh "bash ./integration.sh $ORG ${base64encoded} ${NEWMAN_TARGET_URL}"
                }
            }
            post {
                success {
                    // Archive the integration test results
                    archiveArtifacts artifacts: 'junitReport.xml', allowEmptyArchive: true

                    // Publish test results
                    junit 'junitReport.xml'
                }
                failure {
                    // Archive the integration test results even if the tests fail
                    archiveArtifacts artifacts: 'junitReport.xml', allowEmptyArchive: true

                    // Mark the build as unstable if the integration tests fail
                    unstable('Integration tests failed')
                }
            }
        }
    }
}
