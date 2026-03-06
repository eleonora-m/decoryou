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
                    // Проверяем наличие Docker CLI
                    def dockerExists = sh(script: 'which docker', returnStatus: true)
                    if (dockerExists != 0) {
                        error "❌ Docker CLI не найден! Проверь установку в кастомном образе."
                    } else {
                        echo "✅ Docker CLI найден"
                    }

                    // Проверяем доступ к сокету Docker
                    def dockerPing = sh(script: 'docker info > /dev/null 2>&1', returnStatus: true)
                    if (dockerPing != 0) {
                        error "❌ Нет доступа к Docker daemon! Проверь монтирование /var/run/docker.sock"
                    } else {
                        echo "✅ Docker daemon доступен"
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                // Сборка образа из Dockerfile, который лежит в корне репозитория
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Terraform Plan') {
            steps {
                // Используем dir('terraform'), так как твои .tf файлы лежат в этой папке
                dir('terraform') {
                    // -upgrade нужен, чтобы перекачать плагины с Mac на Linux
                    sh 'terraform init -upgrade'
                    sh "terraform plan -var='docker_image_tag=${IMAGE_TAG}' -out=tfplan"
                }
            }
        }
    }

    post {
        always {
            // Очистка рабочего пространства после сборки
            cleanWs()
        }
        success {
            echo '✅ Пайплайн успешно завершен!'
        }
        failure {
            echo '❌ Ошибка в пайплайне'
        }
    }
}