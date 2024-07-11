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
                    checkout scm
                    
                    // Set up JDK 11
                    tool name: 'JDK 11', type: 'jdk'
                    
                    // Install dependencies
                    sh '''
                    sudo apt-get update -qy
                    sudo apt-get install -y curl jq maven npm gnupg
                    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                    echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                    sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                    '''
                    
                    // Verify base64-encoded service account key
                    sh "echo 'Base64-encoded service account key ${env.GCP_SA_KEY_BASE64}'"
                    
                    // Decode and write service account key to file
                    sh '''
                    mkdir -p .secure_files
                    echo "${env.GCP_SA_KEY_BASE64}" | base64 --decode > .secure_files/service-account.json
                    '''
                    
                    // Check service account key file
                    sh '''
                    echo "Service account key file content:"
                    cat .secure_files/service-account.json
                    '''
                    
                    // Make revision1.sh executable
                    sh "chmod +x ./revision1.sh"
                    
                    // Execute custom script to get token
                    def getAccessToken = sh(script: "./revision1.sh ${env.ORG} ${env.PROXY_NAME} ${env.APIGEE_ENVIRONMENT}", returnStdout: true).trim()
                    env.ACCESS_TOKEN = getAccessToken
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    // Checkout code
                    checkout scm
                    
                    // Echo access token
                    echo "Access token before Maven build and deploy ${env.ACCESS_TOKEN}"
                    
                    // Debug environment variables
                    sh '''
                    echo "ORG: ${env.ORG}"
                    echo "PROXY_NAME: ${env.PROXY_NAME}"
                    echo "APIGEE_ENVIRONMENT: ${env.APIGEE_ENVIRONMENT}"
                    echo "Access token: ${env.ACCESS_TOKEN}"
                    '''
                    
                    // Maven build and deploy
                    sh '''
                    mvn clean install -f ${env.WORKSPACE}/${env.PROXY_NAME}/pom.xml \
                      -Dorg=${env.ORG} \
                      -P${env.APIGEE_ENVIRONMENT} \
                      -Dbearer=${env.ACCESS_TOKEN} -e -X
                    '''
                }
            }
        }
    }
}
