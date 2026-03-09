pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1' 
        APP_NAME   = 'decoryou'
    }

    stages {
        stage('Initialize & AWS Identity') {
            steps {
                // Используем твои ключи, которые мы создали в Jenkins
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'my-aws-key',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo "🔍 Проверка доступа к AWS..."
                        env.AWS_ACCOUNT_ID = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                        env.DOCKER_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                        env.DOCKER_IMAGE_NAME = "${env.DOCKER_REGISTRY}/${env.APP_NAME}"
                        echo "✅ Работаем в аккаунте: ${env.AWS_ACCOUNT_ID}"
                    }
                }
            }
        }

        stage('Build & Push to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'my-aws-key']]) {
                    script {
                        echo "🐳 Собираем Docker образ..."
                        // Логин в реестр AWS ECR
                        sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.DOCKER_REGISTRY}"
                        
                        // Сборка образа (Dockerfile должен быть в корне проекта)
                        sh "docker build -t ${env.DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} -t ${env.DOCKER_IMAGE_NAME}:latest ."
                        
                        // Отправка в облако
                        sh "docker push ${env.DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
                        sh "docker push ${env.DOCKER_IMAGE_NAME}:latest"
                    }
                }
            }
        }

        stage('Terraform Plan & Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'my-aws-key']]) {
                    // Переходим в папку terraform и запускаем деплой
                    sh '''
                        cd terraform
                        terraform init
                        terraform plan -out=tfplan
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            echo "🧹 Очистка завершена."
        }
        success {
            echo "🚀 УРА! Деплой decoryou завершен успешно."
        }
    }
}