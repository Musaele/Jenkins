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
        SECRET_FILE_PATH = '/var/lib/jenkins/workspace/Jenkins/.secure_files'
        TARGET_FILE = 'NoTargetProxy_GET_Req_Pass.postman_collection.json' // Adjust if the target file is in a different location
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

        stage('Integration') {
            steps {
                script {
                    def secretFile = env.SECRET_FILE_PATH
                    def targetFile = env.TARGET_FILE

                    // Check if the secret file exists
                    if (!fileExists(secretFile)) {
                        error "Secret file does not exist at ${secretFile}"
                    }

                    // Run the integration script with the path to the secret file and target file
                    sh "bash ./integration.sh abacus-apigee-demo ${secretFile} ${targetFile}"
                }
            }
            post {
                always {
                    // Archive artifacts or perform any other post-build actions
                    archiveArtifacts artifacts: 'junitReport.xml', allowEmptyArchive: true
                }
                unstable {
                    // Mark the build as unstable if needed
                    unstable "Integration tests failed"
                }
                failure {
                    // Handle failure
                    error "Integration stage failed"
                }
            }
        }
    }
}
