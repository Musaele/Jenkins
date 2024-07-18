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
                    // Checkout code
                    checkout()

                    // Set up JDK 11
                    tool 'jdk11'

                    // Install dependencies
                    sh '''
                        sudo apt-get update -qy
                        sudo apt-get install -y curl jq maven npm gnupg
                        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                        echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                        sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                    '''

                    // Write service account JSON to file
                    withCredentials([file(credentialsId: 'service_file', variable: 'SERVICE_ACCOUNT_FILE')]) {
                        sh "echo '$SERVICE_ACCOUNT_FILE' > .secure_files/service-account.json"
                    }

                    // Verify service account key file content
                    sh 'cat .secure_files/service-account.json'

                    // Make revision1.sh executable
                    sh 'chmod +x ./revision1.sh'

                    // Execute custom script
                    def token = sh(script: './revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT', returnStdout: true).trim()
                    currentBuild.description = "Access token: $token"
                    echo "Access token: $token"
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    // Checkout code again if necessary
                    checkout()

                    // Echo access token
                    echo "Access token before Maven build and deploy $token"

                    // Debug environment variables
                    echo "ORG: $ORG"
                    echo "PROXY_NAME: $PROXY_NAME"
                    echo "APIGEE_ENVIRONMENT: $APIGEE_ENVIRONMENT"
                    echo "Access token: $token"

                    // Maven build and deploy
                    sh '''
                        mvn clean install -f ${env.WORKSPACE}/${PROXY_NAME}/pom.xml \
                            -Dorg=$ORG \
                            -P$APIGEE_ENVIRONMENT \
                            -Dbearer=$token -e -X
                    '''
                }
            }
        }
    }
}
