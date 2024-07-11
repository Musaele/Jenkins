pipeline {
    agent any
    
    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
        SERVICE_ACCOUNT_KEY_FILE = '.secure_files/abacus-apigee-demo-a9fffc7cc15c.json'
    }
    
    stages {
        stage('Build') {
            steps {
                script {
                    // Ensure the .secure_files directory exists and set proper permissions
                    sh '''
                    mkdir -p .secure_files
                    chmod 700 .secure_files
                    '''
                    
                    // Decode base64-encoded service account key and save to file
                    sh '''
                    echo "${GCP_SA_KEY_BASE64}" | base64 --decode > ${SERVICE_ACCOUNT_KEY_FILE}
                    '''
                    
                    // Check if the file exists and has correct permissions
                    sh '''
                    ls -l ${SERVICE_ACCOUNT_KEY_FILE}
                    ls -l .secure_files
                    '''
                    
                    // Verify the contents of the key file (optional)
                    sh "cat ${SERVICE_ACCOUNT_KEY_FILE}"
                    
                    // Execute revision1.sh with environment variables
                    def scriptOutput = sh(script: "./revision1.sh ${ORG} ${PROXY_NAME} ${APIGEE_ENVIRONMENT}", returnStdout: true).trim()
                    echo "Script Output: ${scriptOutput}"
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    // Ensure service account key file is available with proper permissions
                    sh "ls -l ${SERVICE_ACCOUNT_KEY_FILE}"
                    
                    // Use the decoded service account key file in deploy stage
                    // Example: mvn clean install -f ${WORKSPACE}/${PROXY_NAME}/pom.xml -Dorg=${ORG} -P${APIGEE_ENVIRONMENT} -Dbearer=$(cat ${SERVICE_ACCOUNT_KEY_FILE}) -e -X
                }
            }
        }
    }
}
