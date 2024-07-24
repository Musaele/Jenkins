pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
    }

    stages {
        stage('Prepare Environment') {
            steps {
                script {
                    // Install required dependencies
                    sh 'sudo apt-get update -qy && sudo apt-get install -y curl jq maven gnupg'

                    // Install Google Cloud SDK if needed
                    sh '''
                        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                        echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                        sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                    '''

                    // Prepare secure files directory
                    sh 'mkdir -p .secure_files'

                    // Get the service account file from Jenkins credentials
                    withCredentials([file(credentialsId: "service_file", variable: "SECRET_FILE")]) {
                        sh 'cp "$SECRET_FILE" .secure_files/service-account.json'
                    }

                    // Ensure the secure files directory has appropriate permissions
                    sh 'chmod +rwx .secure_files'
                }
            }
        }

        stage('Get Access Token and Stable Revision Number') {
            steps {
                script {
                    // Ensure revision1.sh is executable
                    sh 'chmod +x revision1.sh'

                    // Execute the script with necessary parameters
                    sh './revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'
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
                    sh "mvn clean install -f /var/lib/jenkins/workspace/Jenkins/test-call/pom.xml -P${APIGEE_ENVIRONMENT} -Dorg=${ORG} -Dbearer=${access_token} -Dstable_revision_number=${stable_revision_number}"
                }
            }
        }
    }
}
