pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
        SERVICE_ACCOUNT_KEY_CONTENT = "" // Define an environment variable to store the file content
    }

    stages {
        stage('Prepare Environment') {
            steps {
                script {
                    // Update and install necessary packages
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

        stage('Read Service Account Key') {
            steps {
                script {
                    // Read the content of the service account key into an environment variable
                    withCredentials([file(credentialsId: 'service_file', variable: 'SERVICE_ACCOUNT_KEY_PATH')]) {
                        SERVICE_ACCOUNT_KEY_CONTENT = sh(script: "cat \$SERVICE_ACCOUNT_KEY_PATH", returnStdout: true).trim()
                    }
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    // Authenticate with the service account key using the environment variable
                    sh '''
                        echo "$SERVICE_ACCOUNT_KEY_CONTENT" > /tmp/service_account_key.json  // Write content to a temporary file
                        gcloud auth activate-service-account --key-file=/tmp/service_account_key.json
                    '''

                    // Proceed with other build steps using the authenticated credentials
                    // Example: Download additional secure files or execute necessary setup scripts
                    sh 'curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash'
                    
                    // Execute bash script to retrieve necessary environment variables
                    sh 'source ./revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'
                    
                    // Capture and set environment variables for later stages
                    script {
                        def accessToken = sh(script: 'echo $access_token', returnStdout: true).trim()
                        def stableRevisionNumber = sh(script: 'echo $stable_revision_number', returnStdout: true).trim()
                        env.access_token = accessToken
                        env.stable_revision_number = stableRevisionNumber
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build.env', allowEmptyArchive: true
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    echo "Stable revision at stage deploy: ${env.stable_revision_number}"
                    // Example: Maven build and deployment commands
                    sh '''
                        mvn clean install -f $WORKSPACE/$PROXY_NAME/pom.xml \
                            -P$APIGEE_ENVIRONMENT \
                            -Dorg=$ORG \
                            -Dbearer=$access_token
                    '''
                }
            }
        }

        // Add more stages as needed, such as Integration Test, Undeploy, etc.
    }

    post {
        always {
            cleanWs()
        }
    }
}
