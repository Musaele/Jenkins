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
        stage('Prepare Environment') {
            steps {
                sh '''
                    sudo apt-get update -qy
                    sudo apt-get install -y curl jq maven npm
                    sudo apt-get install -y gnupg
                    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                    echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                    sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                '''
            }
        }

        stage('Build') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'secure.file', variable: 'SERVICE_ACCOUNT_KEY')]) {
                        // Authenticate with the service account key
                        sh '''
                            gcloud auth activate-service-account --key-file=$SERVICE_ACCOUNT_KEY
                        '''

                        // SECURE_FILES_DOWNLOAD
                        sh 'curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash'
                        
                        // Execute bash script to get access token & stable_revision_number
                        sh 'source ./revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'
                        
                        // Set the access token & stable_revision_number as environment variables for later use in the pipeline
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
                    echo "stable revision at stage deploy: ${env.stable_revision_number}"
                    sh '''
                        mvn clean install -f $WORKSPACE/$PROXY_NAME/pom.xml \
                            -P$APIGEE_ENVIRONMENT \
                            -Dorg=$ORG \
                            -Dbearer=$access_token
                    '''
                }
            }
        }

        // Uncomment and complete the following stages if needed:

        /*
        stage('Integration Test') {
            steps {
                script {
                    echo "stable revision at stage integration_test: ${env.stable_revision_number}"
                    sh '''
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
                    echo "stable revision at stage integration_test: ${env.stable_revision_number}"
                    sh '''
                        cd $WORKSPACE  // Set the working directory to the project root
                        bash ./undeploy.sh $ORG $base64encoded $PROXY_NAME $stable_revision_number $APIGEE_ENVIRONMENT
                    '''
                }
            }
            when {
                failed()
            }
        }
        */
    }

    post {
        always {
            cleanWs()
        }
    }
}
