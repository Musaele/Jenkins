pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
        //MICROSOFT_TEAMS_WEBHOOK_URL = 'https://abacusglobal.webhook.office.com/webhookb2/560704ee-2f2d-463d-9ba4-1302c93ced65@51f97e66-3fe9-450d-88ac-7a2380c3f3c6/IncomingWebhook/01173ce910434faa8422545a107ec368/60ec973a-03f8-40b3-884e-0ae804b3ddab'
        //NEWMAN_TARGET_URL = 'NoTargetProxy_GET_Req_Pass.postman_collection.json'
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
                script {
                    // Install required dependencies
                    sh '''
                        sudo apt-get install -y gnupg
                        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                        echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                        sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                        # SECURE_FILES_DOWNLOAD
                        curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
                        # Executing bash script to get access token & stable_revision_number
                        source ./revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT
                        # Set the access token & stable_revision_number as environment variables for later use in the pipeline
                        echo "access_token=$access_token" >> build.env
                        echo "stable_revision_number=$stable_revision_number" >> build.env
                    '''
                }
                script {
                    // Load the environment variables from build.env
                    def props = readProperties file: 'build.env'
                    env.access_token = props.access_token
                    env.stable_revision_number = props.stable_revision_number
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
