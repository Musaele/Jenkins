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
                // Install necessary tools
                sh '''
                    sudo apt-get update -qy
                    sudo apt-get install -y curl jq maven npm gnupg
                    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                    echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                    sudo apt-get update
                    sudo apt-get install -y google-cloud-sdk
                '''
            }
        }

        stage('Build') {
            steps {
                script {
                    // Load service account key from Jenkins credentials
                    withCredentials([file(credentialsId: 'service_file', variable: 'SERVICE_ACCOUNT_KEY_PATH')]) {
                        // Execute your revision1.sh script passing required parameters
                        sh "./revision1.sh '$ORG' '$PROXY_NAME' '$APIGEE_ENVIRONMENT'"
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: '.secure_files/build.env', allowEmptyArchive: true
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    // Access stable_revision_number from build.env
                    def stableRevisionNumber = readFile('.secure_files/build.env').trim().split('=')[1]
                    echo "Stable Revision: $stableRevisionNumber"

                    // Example deploy command (replace with your actual deploy script)
                    sh '''
                        mvn clean install -f $WORKSPACE/$PROXY_NAME/pom.xml \
                            -P$APIGEE_ENVIRONMENT \
                            -Dorg=$ORG \
                            -Dbearer=$access_token
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
