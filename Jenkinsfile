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

        stage('Build') {
            steps {
                script {
                    // Authenticate with the service account key
                    withCredentials([file(credentialsId: 'service_file', variable: 'SERVICE_ACCOUNT_KEY')]) {
                        sh '''
                            gcloud auth activate-service-account --key-file=$SERVICE_ACCOUNT_KEY
                        '''

                        // Download additional secure files or execute necessary setup scripts
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
