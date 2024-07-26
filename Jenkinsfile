pipeline {
    agent any

    tools {
        maven 'M3'
        nodejs 'nodejs-update'
    }

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
        NEWMAN_TARGET_URL = 'NoTargetProxy_GET_Req_Pass.postman_collection.json'
    }

    stages {
        stage('Prepare Environment') {
            steps {
                script {
                    sh 'sudo apt-get update -qy && sudo apt-get install -y curl jq gnupg'
                    sh '''
                        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                        echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                        sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                    '''
                    sh 'mkdir -p .secure_files'
                }
            }
        }

        stage('Get Access Token and Stable Revision Number') {
            steps {
                script {
                    sh 'chmod +x revision1.sh'
                    withCredentials([file(credentialsId: "service_file", variable: "SECRET_FILE")]) {
                        sh 'cp "$SECRET_FILE" .secure_files/service-account.json'
                    }
                    sh './revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'
                    def buildEnv = readFile '.secure_files/build.env'
                    def envVars = readProperties text: buildEnv
                    env.stable_revision = envVars['stable_revision_number']
                    env.access_token = envVars['access_token']
                    echo "Stable revision number: ${env.stable_revision}"
                    echo "Access token: ${env.access_token}"
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: '.secure_files/build.env', allowEmptyArchive: false
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    sh "mvn clean install -f /var/lib/jenkins/workspace/Jenkins/test-call/pom.xml -P${APIGEE_ENVIRONMENT} -Dorg=${ORG} -Dbearer=${env.access_token} -Dstable_revision_number=${env.stable_revision}"
                }
            }
        }

        stage('Integration Test') {
            steps {
                script {
                    sh 'chmod +x integration.sh'
                    def serviceAccount = readJSON file: '.secure_files/service-account.json'
                    def client_id = serviceAccount.client_id
                    def client_secret = serviceAccount.private_key
                    def base64encoded = sh(script: "echo -n '${client_id}:${client_secret}' | base64", returnStdout: true).trim()
                    if (!fileExists(env.NEWMAN_TARGET_URL)) {
                        error "Postman collection file ${env.NEWMAN_TARGET_URL} not found"
                    }
                    sh "bash ./integration.sh $ORG ${base64encoded} ${env.NEWMAN_TARGET_URL}"
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'junitReport.xml', allowEmptyArchive: true
                    junit 'junitReport.xml'
                }
                failure {
                    archiveArtifacts artifacts: 'junitReport.xml', allowEmptyArchive: true
                    unstable('Integration tests failed')
                }
            }
        }
    }
}
