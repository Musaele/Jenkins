pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
    }

    stages {
        stage('Before Script') {
            steps {
                sh '''
                    sudo apt-get update -qy
                    sudo apt-get install -y curl jq maven npm
                '''
            }
        }

        stage('Build') {
            steps {
                withCredentials([file(credentialsId: 'service_file', variable: 'SERVICE_ACCOUNT_JSON'), string(credentialsId: 'SECURE_FILES_TOKEN', variable: 'AUTH_TOKEN')]) {
                    script {
                        sh '''
                            sudo apt-get install -y gnupg
                            curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                            echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                            sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                            # SECURE_FILES_DOWNLOAD
                            curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
                            export AUTH_TOKEN=$AUTH_TOKEN
                            export SECURE_FILES_TOKEN=$AUTH_TOKEN
                            # Executing bash script to get access token & stable_revision_number
                            chmod +x ./revision1.sh
                            ./revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT
                            # Set the access token & stable_revision_number as environment variables for later use in the pipeline
                            source .secure_files/build.env
                        '''
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
                    sh '''
                        echo "stable revision at stage deploy: $stable_revision_number"
                        mvn clean install -f $CI_PROJECT_DIR/$PROXY_NAME/pom.xml \
                            -P$APIGEE_ENVIRONMENT \
                            -Dorg=$ORG \
                            -Dbearer=$access_token
                    '''
                }
            }
        }

        /*
        stage('Integration Test') {
            steps {
                script {
                    sh '''
                        echo "stable revision at stage integration_test: $stable_revision_number"
                        bash ./integration.sh $ORG $base64encoded $NEWMAN_TARGET_URL
                    '''
                }
            }

            post {
                success {
                    junit 'junitReport.xml'
                }
            }
        }

        stage('Undeploy') {
            steps {
                script {
                    sh '''
                        echo "stable revision at stage undeploy: $stable_revision_number"
                        cd $CI_PROJECT_DIR  // Set the working directory to the project root
                        bash ./undeploy.sh $ORG $base64encoded $PROXY_NAME $stable_revision_number $APIGEE_ENVIRONMENT
                    '''
                }
            }
        }
        */
    }
}
