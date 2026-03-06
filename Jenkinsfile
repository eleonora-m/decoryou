pipeline {
    // Best practice: restrict to an agent with the required tools installed
    agent any
    
    environment {
        IMAGE_NAME = "decoryou"
        IMAGE_TAG  = "7"
        // Example: Preparing to use AWS credentials for Terraform
        // AWS_CREDENTIALS = credentials('my-aws-credentials-id') 
    }
    
    stages {
        stage('Check Docker') {
            steps {
                script {
                    // Проверяем доступность Docker CLI
                    def dockerExists = sh(script: 'which docker', returnStatus: true)
                    if (dockerExists != 0) {
                        error """
                        ❌ Docker CLI not found on this agent!
                        Make sure Docker is installed and accessible.
                        If Jenkins runs in a container, mount /var/run/docker.sock
                        and install docker CLI inside container.
                        """
                    } else {
                        echo "✅ Docker CLI found"
                    }

                    // Проверяем доступ к Docker daemon
                    def dockerPing = sh(script: 'docker info > /dev/null 2>&1', returnStatus: true)
                    if (dockerPing != 0) {
                        error """
                        ❌ Cannot connect to Docker daemon!
                        Make sure the user has permissions or /var/run/docker.sock is mounted.
                        """
                    } else {
                        echo "✅ Docker daemon accessible"
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Terraform Plan') {
            steps {
                // Example of wrapping Terraform in credentials
                // withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'my-aws-credentials-id']]) {
                    sh 'terraform init'
                    
                    // Passing the newly built image tag to Terraform as a variable
                    sh 'terraform plan -var="docker_image_tag=${IMAGE_TAG}" -out=tfplan'
                // }
            }
        }
    }

    post {
        always {
            // Good practice: Clean up the workspace to prevent disk space issues on the agent
            cleanWs()
        }
        failure {
            echo '❌ Pipeline failed'
        }
        success {
            echo '✅ Pipeline completed successfully'
        }
    }
}