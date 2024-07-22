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
                script {
                    // Install required dependencies
                    sh 'apt-get update -qy && apt-get install -y curl jq maven npm gnupg'

                    // Install Google Cloud SDK as needed (uncomment if required)
                    // sh '''
                    //     curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
                    //     echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                    //     apt-get update && apt-get install -y google-cloud-sdk
                    // '''

                    // Download secure files (assuming no authentication required)
                    // Consider alternative secure download methods if needed (e.g., encrypted file download)
                    sh 'curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash'

                    // Executing bash script to get access token & stable_revision_number (modify/replace as needed)
                    sh 'source ./revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'

                    // Access service account credentials securely using Jenkins credentials
                    withCredentials([file: credentialsId: 'service_file', variable: 'SERVICE_ACCOUNT_FILE_CONTENT']) {
                        sh '''
                            # Decode the base64 encoded service account JSON content
                            echo $SERVICE_ACCOUNT_FILE_CONTENT | base64 -d > service_account.json
                            export GOOGLE_APPLICATION_CREDENTIALS=service_account.json
                        '''
                    }

                    // Write environment variables to build.env artifact
                    writeFile file: 'build.env', text: "access_token=\$access_token\nstable_revision_number=\$stable_revision_number\n"
                }
            }
            artifacts {
                dotenv 'build.env'
            }
        }

        stage('Deploy') {
            needs {
                success anyOf {
                    build job: 'build-job-1' // Remove if single stage pipeline
                }
            }
            steps {
                script {
                    // Read stable revision from previous stage
                    def stable_revision_number = readFile 'build.env'

                    // Deploy using Maven
                    sh "echo 'Stable revision at stage deploy: ${stable_revision_number}'"
                    sh "mvn clean install -f \$CI_PROJECT_DIR/\$PROXY_NAME/pom.xml -P\$APIGEE_ENVIRONMENT -Dorg=\$ORG -Dbearer=\$access_token"
                }
            }
        }
    }
}
