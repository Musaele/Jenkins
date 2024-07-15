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
                    // Update package repositories and install necessary tools
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
        }

        stage('Build') {
            steps {
                script {
                    // Ensure revision1.sh has execute permissions
                    sh 'chmod +x ./revision1.sh'

                    // Execute revision1.sh passing parameters
                    sh './revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'
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
                    echo "Deploying..."
                    // Add deployment steps here, e.g., deploying using Maven
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
