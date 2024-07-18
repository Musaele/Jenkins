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
                    sh '''
                        apt-get update -qy
                        apt-get install -y curl jq maven npm gnupg
                        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
                        echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                        apt-get update && apt-get install -y google-cloud-sdk
                        
                        # SECURE_FILES_DOWNLOAD
                        curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
                        
                        # Executing bash script to get access token & stable_revision_number
                        source ./revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT
                        
                        # Set the access token & stable_revision_number as environment variables for later use in the pipeline
                        echo "access_token=$access_token" >> build.env
                        echo "stable_revision_number=$stable_revision_number" >> build.env
                    '''
                    archiveArtifacts artifacts: 'build.env', fingerprint: true
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    def buildEnv = readFile 'build.env'
                    def access_token = buildEnv.split('\n').find { it.startsWith('access_token=') }?.split('=')[1]?.trim()
                    def stable_revision_number = buildEnv.split('\n').find { it.startsWith('stable_revision_number=') }?.split('=')[1]?.trim()

                    echo "stable revision at stage deploy: ${stable_revision_number}"

                    sh """
                        mvn clean install -f ${env.WORKSPACE}/${PROXY_NAME}/pom.xml \
                            -P${APIGEE_ENVIRONMENT} \
                            -Dorg=${ORG} \
                            -Dbearer=${access_token}
                    """
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
