pipeline {
  // ... (rest of your pipeline)

  stages {
    stage('Build') {
      steps {
        script {
          // Install using sudo
          sh 'sudo apt update -qy && sudo apt install -y curl jq maven npm gnupg'

          // Optional: Install Google Cloud SDK using sudo (if required)
          // sh '''
          //   sudo curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
          //   echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
          //   sudo apt update && sudo apt install -y google-cloud-sdk
          // '''

          // Download secure files (no sudo needed)
          sh 'curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash'

          // Replace with your script or commands to get access token and revision number (no sudo needed)
          sh 'source ./revision1.sh $ORG $PROXY_NAME $APIGEE_ENVIRONMENT'

          // Access service account credentials securely using Jenkins credentials (no sudo)
          // ... (same as before)

          // Write environment variables to build.env artifact (no sudo)
          writeFile file: 'build.env', text: "access_token=\$access_token\nstable_revision_number=\$stable_revision_number\n"
        }
      }
      // ... (rest of build artifacts)
    }

    stage('Deploy') {
      // ... (needs section)

      steps {
        script {
          // Read stable revision from previous stage
          def stable_revision_number = readFile 'build.env'

          // Deploy using Maven with sudo
          sh "sudo echo 'Stable revision at stage deploy: ${stable_revision_number}'"
          sh "sudo mvn clean install -f \$CI_PROJECT_DIR/\$PROXY_NAME/pom.xml -P\$APIGEE_ENVIRONMENT -Dorg=\$ORG -Dbearer=\$access_token"
        }
      }
    }
  }
}
