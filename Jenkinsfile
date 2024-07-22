pipeline {
  agent any

  environment {
    ORG = 'abacus-apigee-demo'
    PROXY_NAME = 'test-call'
    APIGEE_ENVIRONMENT = 'dev2'
  }

  stages {
    stage('build') {
      steps {
        withCredentials([file(credentialsId: 'service_file', variable: 'SERVICE_FILE')]) {
          script {
            // Install required dependencies
            sh 'sudo apt-get update -qy'
            sh 'sudo apt-get install -y curl jq maven npm gnupg'

            // Clean up
            sh 'sudo apt autoremove -y'

            // Install Google Cloud SDK
            sh 'sudo curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -'
            sh 'echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list'
            sh 'sudo apt-get update && sudo apt-get install -y google-cloud-sdk'

            // Download secure files and execute revision1.sh
            sh 'sudo curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | sudo bash'
            sh 'sudo download-secure-files --auth-token=${AUTH_TOKEN}'
            sh 'sudo ./revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'

            // Set Google Cloud credentials using the service account file
            withEnv(["GOOGLE_APPLICATION_CREDENTIALS=${SERVICE_FILE}"]) {
              // Write environment variables to build.env artifact
              writeFile file: 'build.env', text: "access_token=${access_token}\nstable_revision_number=${stable_revision_number}\n"
            }
          }
        }
      }
      post {
        success {
          archiveArtifacts artifacts: 'build.env'
        }
      }
    }

    stage('deploy') {
      steps {
        script {
          // Read stable revision from previous stage
          def stable_revision_number = readFile 'build.env'

          // Deploy using Maven
          sh "echo 'stable revision at stage deploy: ${stable_revision_number}'"
          sh "sudo mvn clean install -f \$CI_PROJECT_DIR/\$PROXY_NAME/pom.xml -P\$APIGEE_ENVIRONMENT -Dorg=\$ORG -Dbearer=\$access_token"
        }
      }
    }
  }
}
