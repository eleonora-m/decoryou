pipeline {
  agent any
  stages {
    stage('Docker Build') {
      steps {
        sh '''
          docker build -t decoryou:${BUILD_NUMBER} .
          echo "Docker build success!"
        '''
      }
    }
    stage('Terraform Plan') {
      steps {
        sh '''
          terraform init
          terraform plan
        '''
      }
    }
  }
}
