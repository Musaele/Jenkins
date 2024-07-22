pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'  // Replace with your values
        PROXY_NAME = 'test-call'  // Replace with your values
        APIGEE_ENVIRONMENT = 'dev2'  // Replace with your values
    }

    stages {
        stage('Build') {
            steps {
                script {
                    // Install required dependencies
                    sh 'apt-get update -qy && apt-get install -y curl jq maven npm gnupg'

                    // Optional: Install Google Cloud SDK if needed
                    // sh '''
                    //     curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
                    //     echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                    //     apt-get update && apt-get install -y google-cloud-sdk
                    // '''

                    // Download secure files (consider alternative secure download methods if required)
                    sh 'curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash'

                    // Replace with your script or commands to get access token and revision number
                    sh 'source ./revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'

                    // Access service account credentials securely using Jenkins credentials
                    withCredentials([file(credentialsId: 'service_file', variable: 'SERVICE_ACCOUNT_FILE_CONTENT')]) {
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
            post {
                success {
                    archiveArtifacts artifacts: 'build.env', allowEmptyArchive: false
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    // Read stable revision from previous stage
                    def buildEnv = readFile 'build.env'
                    def envVars = readProperties text: buildEnv
                    def stable_revision_number = envVars['stable_revision_number']
                    def access_token = envVars['access_token']

                    // Deploy using Maven (replace with your deployment commands)
                    sh "echo 'Stable revision at stage deploy: ${stable_revision_number}'"
                    sh "mvn clean install -f \$CI_PROJECT_DIR/\$PROXY_NAME/pom.xml -P\$APIGEE_ENVIRONMENT -Dorg=\$ORG -Dbearer=${access_token}"
                }
            }
        }
    }
}
