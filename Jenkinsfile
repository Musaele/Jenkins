/*
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

        stage('Make revision1.sh executable') {
            steps {
                sh 'chmod +x ./revision1.sh'
            }
        }

       /* stage('Execute custom script') {
            steps {
                script {
                    def access_token = sh(script: "./revision1.sh ${ORG} ${PROXY_NAME} ${APIGEE_ENVIRONMENT}", returnStdout: true).trim()
                    env.access_token = access_token
                }
            }
        }   */

      /*
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
*/
#!groovy

pipeline {
    agent any
    tools {
        maven 'M3'
        nodejs 'nodejs-update'
    }
    environment {
        ProxyName = 'apigee-standard-template-v2'
        ENV = 'apistg-fs-generic'
        org = 'sfc-kenya-hybrid-non-prod'
        developer = 'umairhanif@test.com'
        app = 'UmairApp'
        Newman_Target_Collection = 'test-call-integration-sfc-kenya.postman_collection.json'
        base64encoded_apikey = credentials('base64encoded_apikey')
        KEY_FILE_NonProd = credentials('KEY_FILE_NonProd')
        KEY_FILE_Prod = credentials('KEY_FILE_Prod')
        stable_revision = ''
        access_token = ''
    }

    stages {
            stage('Main') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'develop' || env.BRANCH_NAME == 'preprod' || env.BRANCH_NAME == 'feature') {
                        stage('Initial-Checks') {
                                office365ConnectorSend webhookUrl: 'https://safaricomo365.webhook.office.com/webhookb2/1f198d4b-1b75-49e8-8032-d4441104de46@19a4db07-607d-475f-a518-0e3b699ac7d0/JenkinsCI/57b04be56f004ad8936b7859ab072e67/dfc7bf82-7b0d-4e0a-b2ff-9b9d4eee8548',
                                message: "Started Pipeline/Job: ${env.JOB_NAME} Build Number: ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"

                                sh 'node -v'
                                sh 'npm -v'
                                sh 'mvn -v'

                                script {
                                if (env.org == 'sfc-kenya-hybrid-prod') {
                                    sh "cd $WORKSPACE/scripts && sh revision.sh $org $ProxyName $ENV $KEY_FILE_Prod $WORKSPACE" // Capture and set the output variables
                                    sh "cat $WORKSPACE/scripts/access_token.txt"
                                    sh "cat $WORKSPACE/scripts/stable_revision.txt"
                                    access_token = readFile 'scripts/access_token.txt'
                                    stable_revision = readFile 'scripts/stable_revision.txt'
                                    // Print the values to verify
                                    echo "access_token: ${access_token}"
                                    echo "stable_revision: ${stable_revision}"
                                }

                                else if (env.org == 'sfc-kenya-hybrid-non-prod') {
                                    sh "cd $WORKSPACE/scripts && sh revision.sh $org $ProxyName $ENV $KEY_FILE_NonProd $WORKSPACE" // Capture and set the output variables
                                    sh "cat $WORKSPACE/scripts/access_token.txt"
                                    sh "cat $WORKSPACE/scripts/stable_revision.txt"
                                    access_token = readFile 'scripts/access_token.txt'
                                    stable_revision = readFile 'scripts/stable_revision.txt'
                                    // Print the values to verify
                                    echo "access_token: ${access_token}"
                                    echo "stable_revision: ${stable_revision}"
                                }
                                }

                                echo "access_token: ${access_token}"
                                echo "Stable Revision: ${stable_revision}"
                        }

                        stage('Veracode SCA scan') {
                            withCredentials([string(credentialsId: 'SRCCLR_API_TOKEN', variable: 'SRCCLR_API_TOKEN')]) {
                                        sh 'curl -sSL https://download.sourceclear.com/ci.sh | sh'
                            }
                        }

                        stage('Policy-Code Analysis') {
                            script {
                                try {
                                            sh "cd $WORKSPACE && npm install -g apigeelint && apigeelint -V"
                                            sh "cd $WORKSPACE && apigeelint -s $ProxyName/apiproxy -f html.js --excluded BN003  > ./reports/index.html"
                                            } catch (e) {
                                    throw e
                                            } finally {
                                            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './reports', reportFiles: 'index.html', reportName: 'Apigee Lint Report', reportTitles: 'Apigee Lint Report'])
                                }
                            }
                        }

                        stage('Deploy to Apigee') {
                                //deploy using maven plugin
                                echo "Deploy TOKEN: ${access_token}"

                                sh "mvn clean install -f $WORKSPACE/${ProxyName}/pom.xml -P$ENV -Dorg=${env.org} -Dbearer=${access_token}"
                        }

                    /*    stage('Integration Test Newman') {

                                script {
                                    try {
                                        sh "cd $WORKSPACE/scripts && sh && sh integration.sh"
                                    } catch (e) {
                                        //if tests fail, I have used an shell script which has 3 APIs to undeploy, delete current revision & deploy previous stable revision

                                        rev_num = sh(script: 'curl -k -H "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/environments/$ENV/apis/$ProxyName/deployments" | jq -r ".deployments[].revision"', returnStdout: true).trim()

                                        env_name = sh(script: 'curl -k -H "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/environments/$ENV/apis/$ProxyName/deployments" | jq -r ".deployments[].environment"', returnStdout: true).trim()

                                        echo "rev_num: $rev_num"
                                        echo "env_name: $env_name"

                                        sh "cd $WORKSPACE/scripts && sh && sh undeploy.sh $stable_revision $rev_num $env_name"

                                        throw e
                                    }
                                    finally {

                                publishHTML([allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: './test/integration/reports',
                                reportFiles: 'Newman_Integration_Tests_Report_$BUILD_NUMBER.html',
                                reportName: 'Newman_Integration_Tests_Report',
                                reportTitles: ''])
                                    }
                                }
                        }    */
                    }  else {
                        stage('Initial-Checks') {
                                office365ConnectorSend webhookUrl: 'https://safaricomo365.webhook.office.com/webhookb2/1f198d4b-1b75-49e8-8032-d4441104de46@19a4db07-607d-475f-a518-0e3b699ac7d0/JenkinsCI/57b04be56f004ad8936b7859ab072e67/dfc7bf82-7b0d-4e0a-b2ff-9b9d4eee8548',
                                message: "Started Pipeline/Job: ${env.JOB_NAME} Build Number: ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"

                                sh 'node -v'
                                sh 'npm -v'
                                sh 'mvn -v'
                        //sh "cd $WORKSPACE && npm install -g force-resolutions && npm install"
                        }

                        stage('Veracode SCA scan') {
                            withCredentials([string(credentialsId: 'SRCCLR_API_TOKEN', variable: 'SRCCLR_API_TOKEN')]) {
                                        sh 'curl -sSL https://download.sourceclear.com/ci.sh | sh'
                            }
                        }

                        stage('Policy-Code Analysis') {
                            script {
                                try {
                                            sh "cd $WORKSPACE && npm install -g apigeelint && apigeelint -V"
                                            sh "cd $WORKSPACE && apigeelint -s $ProxyName/apiproxy -f html.js --excluded BN003  > ./reports/index.html"
                                            } catch (e) {
                                    throw e
                                            } finally {
                                            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './reports', reportFiles: 'index.html', reportName: 'Apigee Lint Report', reportTitles: 'Apigee Lint Report'])
                                }
                            }
                        }
                    }
                }
            }
            }
    }

    post {
                success {
                    //Sending MS Teams Notifications about Pipeline/Job Success!
                    office365ConnectorSend webhookUrl: 'https://safaricomo365.webhook.office.com/webhookb2/1f198d4b-1b75-49e8-8032-d4441104de46@19a4db07-607d-475f-a518-0e3b699ac7d0/JenkinsCI/57b04be56f004ad8936b7859ab072e67/dfc7bf82-7b0d-4e0a-b2ff-9b9d4eee8548',
                    message: "Pipeline/Job: ${env.JOB_NAME} Build Number: ${env.BUILD_NUMBER} completed successfully!",
                    status: 'Success'
                }
                failure {
                    //Sending MS Teams Notifications about Pipeline/Job Failure!
                    office365ConnectorSend webhookUrl: 'https://safaricomo365.webhook.office.com/webhookb2/1f198d4b-1b75-49e8-8032-d4441104de46@19a4db07-607d-475f-a518-0e3b699ac7d0/JenkinsCI/57b04be56f004ad8936b7859ab072e67/dfc7bf82-7b0d-4e0a-b2ff-9b9d4eee8548',
                    message: "Pipeline/Job: ${env.JOB_NAME} Build Number: ${env.BUILD_NUMBER} failed!",
                    status: 'Failure'
                }
    }
}
