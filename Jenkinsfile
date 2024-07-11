pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
        GCP_SA_KEY_BASE64 = credentials('GCP_SA_KEY_BASE64') // You need to add your secret to Jenkins credentials
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -al ${WORKSPACE}'
            }
        }
        
        stage('Set up JDK 11') {
            steps {
                sh 'sudo apt-get update -qy'
                sh 'sudo apt-get install -y openjdk-11-jdk'
                sh 'java -version'
            }
        }

        stage('Install dependencies') {
            steps {
                sh '''
                sudo apt-get update -qy
                sudo apt-get install -y curl jq maven npm gnupg
                curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                '''
            }
        }

        stage('Verify and decode service account key') {
            steps {
                sh 'echo "Base64-encoded service account key ${GCP_SA_KEY_BASE64}"'
                sh '''
                mkdir -p .secure_files
                echo "${GCP_SA_KEY_BASE64}" | base64 --decode > .secure_files/service-account.json
                echo "Service account key file content:"
                cat .secure_files/service-account.json
                '''
            }
        }

        stage('Execute custom script') {
            steps {
                script {
                    def access_token = sh(script: "./revision1.sh ${ORG} ${PROXY_NAME} ${APIGEE_ENVIRONMENT}", returnStdout: true).trim()
                    env.access_token = access_token
                }
            }
        }

        stage('Deploy') {
            steps {
                checkout scm
                sh 'echo "Access token before Maven build and deploy ${access_token}"'
                sh '''
                echo "ORG: ${ORG}"
                echo "PROXY_NAME: ${PROXY_NAME}"
                echo "APIGEE_ENVIRONMENT: ${APIGEE_ENVIRONMENT}"
                echo "Access token: ${access_token}"
                '''
                sh '''
                mvn clean install -f ${WORKSPACE}/${PROXY_NAME}/pom.xml \
                -Dorg=${ORG} \
                -P${APIGEE_ENVIRONMENT} \
                -Dbearer=${access_token} -e -X
                '''
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
