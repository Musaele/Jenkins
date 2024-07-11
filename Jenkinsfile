pipeline {
    agent any

    environment {
        ORG = 'abacus-apigee-demo'
        PROXY_NAME = 'test-call'
        APIGEE_ENVIRONMENT = 'dev2'
    }

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'maven:3.8.4-jdk-11'
                    args '-u root:root'
                }
            }
            steps {
                script {
                    // Install required dependencies
                    sh '''
                        apt-get update -qy
                        apt-get install -y curl jq npm gnupg
                        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
                        echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                        apt-get update && apt-get install -y google-cloud-sdk
                    '''
                    // SECURE_FILES_DOWNLOAD
                    sh 'curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash'

                    // Executing bash script to get access token & stable_revision_number
                    def output = sh(script: 'source ./revision1.sh ${ORG} ${PROXY_NAME} ${APIGEE_ENVIRONMENT} && echo access_token=$access_token && echo stable_revision_number=$stable_revision_number', returnStdout: true).trim()
                    def envVars = output.split("\n")
                    envVars.each { envVar ->
                        def keyValue = envVar.split("=")
                        if (keyValue.length == 2) {
                            env[keyValue[0]] = keyValue[1]
                        }
                    }

                    // Save environment variables as artifacts for later stages
                    writeFile file: 'build.env', text: "access_token=${env.access_token}\nstable_revision_number=${env.stable_revision_number}"
                    archiveArtifacts artifacts: 'build.env', allowEmptyArchive: true
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    echo "stable revision at stage deploy: ${env.stable_revision_number}"
                    sh 'mvn clean install -f $WORKSPACE/$PROXY_NAME/pom.xml -P$APIGEE_ENVIRONMENT -Dorg=$ORG -Dbearer=$access_token'
                }
            }
        }

        // Uncomment and update the following stages as needed

        // stage('Integration Test') {
        //     steps {
        //         script {
        //             echo "stable revision at stage integration_test: ${env.stable_revision_number}"
        //             sh './integration.sh $ORG $base64encoded $NEWMAN_TARGET_URL'
        //         }
        //         junit 'junitReport.xml'
        //     }
        // }

        // stage('Undeploy') {
        //     when {
        //         failure()
        //     }
        //     steps {
        //         script {
        //             echo "stable revision at stage undeploy: ${env.stable_revision_number}"
        //             sh 'cd $WORKSPACE && ./undeploy.sh $ORG $base64encoded $PROXY_NAME $stable_revision_number $APIGEE_ENVIRONMENT'
        //         }
        //     }
        // }
    }

    post {
        always {
            archiveArtifacts artifacts: 'build.env', allowEmptyArchive: true
        }
    }
}
