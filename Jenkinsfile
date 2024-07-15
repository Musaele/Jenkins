pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
    }

    stages {
        stage('Build') {
            steps {
                checkout scm
                
                script {
                    // List root directory contents after checkout
                    sh 'ls -al ${WORKSPACE}'
                }
                
                // Set up JDK 11
                tools {
                    jdk 'jdk11'
                }

                // Install dependencies
                steps {
                    script {
                        sh 'sudo apt-get update -qy'
                        sh 'sudo apt-get install -y curl jq maven npm gnupg'
                        sh 'curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -'
                        sh 'echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list'
                        sh 'sudo apt-get update && sudo apt-get install -y google-cloud-sdk'
                    }
                }

                // Verify base64-encoded service account key
                steps {
                    script {
                        sh 'echo "Base64-encoded service account key ${GCP_SA_KEY_BASE64}"'
                    }
                }

                // Decode and write service account key to file
                steps {
                    script {
                        sh 'mkdir -p .secure_files'
                        // Use the secret file stored in Jenkins
                        withCredentials([file(credentialsId: 'service_file', variable: 'SERVICE_ACCOUNT_FILE')]) {
                            sh 'cp $SERVICE_ACCOUNT_FILE .secure_files/service-account.json'
                        }
                    }
                }

                // Check service account key file
                steps {
                    script {
                        sh 'echo "Service account key file content:"'
                        sh 'cat .secure_files/service-account.json'
                    }
                }

                // Make revision1.sh executable
                steps {
                    script {
                        sh 'chmod +x ./revision1.sh'
                    }
                }

                // Execute custom script to get token
                steps {
                    script {
                        def getAccessToken = sh(script: './revision1.sh ${ORG} ${PROXY_NAME} ${APIGEE_ENVIRONMENT}', returnStdout: true).trim()
                        currentBuild.description = "Access token: ${getAccessToken}"
                        echo "Access token obtained: ${getAccessToken}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                // Checkout code again (if needed)
                checkout scm
                
                // Echo access token
                script {
                    echo "Access token before Maven build and deploy ${currentBuild.description}"
                }

                // Debug environment variables
                script {
                    echo "ORG: ${ORG}"
                    echo "PROXY_NAME: ${PROXY_NAME}"
                    echo "APIGEE_ENVIRONMENT: ${APIGEE_ENVIRONMENT}"
                    echo "Access token: ${currentBuild.description}"
                }

                // Maven build and deploy
                script {
                    sh 'mvn clean install -f ${WORKSPACE}/${PROXY_NAME}/pom.xml -Dorg=${ORG} -P${APIGEE_ENVIRONMENT} -Dbearer=${currentBuild.description} -e -X'
                }
            }
        }
    }
}
