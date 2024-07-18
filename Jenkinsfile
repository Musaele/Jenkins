pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
        GCP_SA_KEY = credentials('service_file') // Assuming you have stored your GCP service account key as a Jenkins credential
    }

    stages {
        stage('Build') {
            steps {
                script {
                    // Installing required dependencies
                    sh '''
                    sudo apt-get update -qy
                    sudo apt-get install -y curl jq maven npm gnupg
                    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                    echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                    sudo apt-get update && sudo apt-get install -y google-cloud-sdk
                    curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
                    source ./revision1.sh ${ORG} ${PROXY_NAME} ${APIGEE_ENVIRONMENT}
                    echo "access_token=$access_token" >> build.env
                    echo "stable_revision_number=$stable_revision_number" >> build.env
                    '''
                }
                script {
                    // Loading environment variables from build.env
                    def props = readProperties file: 'build.env'
                    env.access_token = props['access_token']
                    env.stable_revision_number = props['stable_revision_number']
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
                    mvn clean install -f $WORKSPACE/${PROXY_NAME}/pom.xml \
                        -P${APIGEE_ENVIRONMENT} \
                        -Dorg=${ORG} \
                        -Dbearer=${access_token}
                    '''
                }
            }
        }

        // Uncomment and configure the following stages as needed

        // stage('Integration Test') {
        //     steps {
        //         script {
        //             sh '''
        //             echo "stable revision at stage integration_test: $stable_revision_number"
        //             bash ./integration.sh ${ORG} $base64encoded $NEWMAN_TARGET_URL
        //             '''
        //         }
        //     }
        //     post {
        //         success {
        //             junit 'junitReport.xml'
        //         }
        //     }
        // }

        // stage('Undeploy') {
        //     when {
        //         expression {
        //             return currentBuild.currentResult == 'FAILURE'
        //         }
        //     }
        //     steps {
        //         script {
        //             sh '''
        //             echo "stable revision at stage undeploy: $stable_revision_number"
        //             cd $WORKSPACE
        //             bash ./undeploy.sh ${ORG} $base64encoded ${PROXY_NAME} ${stable_revision_number} ${APIGEE_ENVIRONMENT}
        //             '''
        //         }
        //     }
        // }
    }
}
