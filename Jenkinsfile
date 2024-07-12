pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
        GCP_SA_KEY_FILE = credentials('service_file')
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

        stage('Verify service account key') {
            steps {
                withCredentials([file(credentialsId: 'service_file', variable: 'GCP_SA_KEY_FILE')]) {
                    sh '''
                    echo "Debug: GCP_SA_KEY_FILE is ${GCP_SA_KEY_FILE}"
                    mkdir -p .secure_files
                    ls -al .secure_files
                    cp ${GCP_SA_KEY_FILE} .secure_files/service-account.json
                    echo "Service account key file content:"
                    cat .secure_files/service-account.json
                    '''
                }
            }
        }

        stage('Execute custom script') {
            steps {
                script {
                    sh './revision1.sh ${ORG} ${PROXY_NAME} ${APIGEE_ENVIRONMENT}'
                }
            }
        }

        stage('Deploy') {
            steps {
                checkout scm
                script {
                    def accessToken = sh(script: './revision1.sh ${ORG} ${PROXY_NAME} ${APIGEE_ENVIRONMENT}', returnStdout: true).trim()
                    sh '''
                    echo "ORG: ${ORG}"
                    echo "PROXY_NAME: ${PROXY_NAME}"
                    echo "APIGEE_ENVIRONMENT: ${APIGEE_ENVIRONMENT}"
                    echo "Access token: ${accessToken}"
                    '''
                    sh '''
                    mvn clean install -f ${WORKSPACE}/${PROXY_NAME}/pom.xml \
                    -Dorg=${ORG} \
                    -P${APIGEE_ENVIRONMENT} \
                    -Dbearer=${accessToken} -e -X
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
