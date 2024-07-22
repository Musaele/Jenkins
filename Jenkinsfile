pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
    }
        stage('build') {
            steps {
                withCredentials([file(credentialsId: 'service_file', variable: 'SERVICE_FILE')]) {
                    script {
                        // Install required dependencies
                        sh 'apt-get update -qy'
                        sh 'apt-get install -y curl jq maven npm gnupg'

                        // Install Google Cloud SDK
                        sh 'curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -'
                        sh 'echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list'
                        sh 'apt-get update && apt-get install -y google-cloud-sdk'

                        // Download secure files and execute revision1.sh
                        sh 'curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash'
                        sh './revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'

                        // Set Google Cloud credentials using the service account file
                        withEnv(["GOOGLE_APPLICATION_CREDENTIALS=${SERVICE_FILE}"]) {
                            // Write environment variables to build.env artifact
                            writeFile file: 'build.env', text: "access_token=${access_token}\nstable_revision_number=${stable_revision_number}\n"
                        }
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build.env'
                }
            }
        }

        stage('deploy') {
            steps {
                script {
                    // Read stable revision from previous stage
                    def stable_revision_number = readFile 'build.env'

                    // Deploy using Maven
                    sh "echo 'stable revision at stage deploy: ${stable_revision_number}'"
                    sh "mvn clean install -f \$CI_PROJECT_DIR/\$PROXY_NAME/pom.xml -P\$APIGEE_ENVIRONMENT -Dorg=\$ORG -Dbearer=\$access_token"
                }
            }
        }
    }

    post {
        success {
            // Sending Microsoft Teams Notifications about Pipeline/Job Success!
            // office365ConnectorSend webhookUrl: MICROSOFT_TEAMS_WEBHOOK_URL, message: "Pipeline/Job: ${env.JOB_NAME} Build Number: ${env.BUILD_NUMBER} completed successfully!", status: 'Success'
        }
        failure {
            // Sending Microsoft Teams Notifications about Pipeline/Job Failure!
            // office365ConnectorSend webhookUrl: MICROSOFT_TEAMS_WEBHOOK_URL, message: "Pipeline/Job: ${env.JOB_NAME} Build Number: ${env.BUILD_NUMBER} failed!", status: 'Failure'
        }
    }
}

