pipeline {
    agent any
    environment {
        IMAGE_NAME = "decoryou"
        IMAGE_TAG  = "7"
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
                sh 'terraform init'
                sh 'terraform plan'
            }
        }
    }

    post {
        failure {
            echo '❌ Pipeline failed'
        }
        success {
            echo '✅ Pipeline completed successfully'
        }
    }
}