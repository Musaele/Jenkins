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
                    sh 'sudo apt-get update -qy && sudo apt-get install -y curl jq maven npm gnupg'

                    // Install Google Cloud SDK if needed
                    sh '''
                        sudo curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                        echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                        sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                    '''

                    // Create a temporary directory for download
                    sh 'mkdir -p /tmp/download'

                    // Download secure files within the temporary directory
                    sh '''
                        sudo curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | sudo bash -c "cat > /tmp/download/installer"
                    '''

                    withCredentials([file(credentialsId: "service_file", variable: "SECRET_FILE")]) {
                        sh 'mkdir -p .secure_files && cp "$SECRET_FILE" .secure_files/service-account.json'
                    }

                    // Change permissions of the .secure_files directory
                    sh 'sudo chmod -R 777 .secure_files'

                    sh 'sudo chmod +x revision1.sh'

                    // Execute the script with necessary parameters
                    sh 'sudo ./revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'

                    // Write environment variables to build.env artifact within .secure_files directory
                    writeFile file: '.secure_files/build.env', text: "access_token=\$access_token\nstable_revision_number=\$stable_revision_number\n"
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
                    // Read stable revision and access token from previous stage
                    def buildEnv = readFile '.secure_files/build.env'
                    def envVars = readProperties text: buildEnv
                    def stable_revision_number = envVars['stable_revision_number']
                    def access_token = envVars['access_token']

                    // Debugging log
                    echo "Stable revision number: ${stable_revision_number}"
                    echo "Access token: ${access_token}"

                    // Deploy using Maven (replace with your deployment commands)
                    sh "mvn clean install -f ${env.WORKSPACE}/${PROXY_NAME}/pom.xml -P${APIGEE_ENVIRONMENT} -Dorg=${ORG} -Dbearer=${access_token}"
                }
            }
        }
    }
}
