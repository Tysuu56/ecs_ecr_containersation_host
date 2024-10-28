pipeline {
    agent any

    environment {
        ECR_REPO_NAME = 'my-app-repo' // ECR repository name
        IMAGE_TAG = 'latest' // Tag for your image
        ECR_REPO_URI = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
        AWS_CREDENTIALS_ID = 'aws-credentials' // Your Jenkins AWS credentials ID
        DOCKER_IMAGE_LINK = 'nginx:latest' // Specify your Docker image link
    }

    stages {
        stage('Initialize') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        // Get the AWS region dynamically
                        env.AWS_REGION = sh(script: "aws configure get region", returnStdout: true).trim()
                        
                        // Get the AWS account ID dynamically
                        env.AWS_ACCOUNT_ID = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                        
                        // Logging the retrieved values (optional)
                        echo "AWS Region: ${env.AWS_REGION}"
                        echo "AWS Account ID: ${env.AWS_ACCOUNT_ID}"
                    }
                }
            }
        }

        stage('Setup AWS ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        // Create ECR repository if it doesn't exist
                        def repoCheck = sh(script: "aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${env.AWS_REGION}", returnStatus: true)
                        if (repoCheck != 0) {
                            sh "aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${env.AWS_REGION}"
                        }
                    }
                }
            }
        }

        stage('Pull Docker Image') {
            steps {
                script {
                    // Pull the specified Docker image from Docker Hub
                    sh "docker pull ${DOCKER_IMAGE_LINK}"
                }
            }
        }

        stage('Tag Docker Image for ECR') {
            steps {
                script {
                    // Tag the pulled image with ECR URI
                    sh "docker tag ${DOCKER_IMAGE_LINK} ${ECR_REPO_URI}:${IMAGE_TAG}"
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        // Authenticate Docker with ECR
                        sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URI}"
                    }
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    // Push the tagged image to ECR
                    sh "docker push ${ECR_REPO_URI}:${IMAGE_TAG}"
                }
            }
        }

        stage('Create ECS Task Definition') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        // Define ECS task definition JSON (you can customize this)
                        def taskDefinition = """
                        {
                            "family": "my-app-task",
                            "containerDefinitions": [
                                {
                                    "name": "my-app",
                                    "image": "${ECR_REPO_URI}:${IMAGE_TAG}",
                                    "memory": 512,
                                    "cpu": 256,
                                    "essential": true,
                                    "portMappings": [
                                        {
                                            "containerPort": 80,
                                            "hostPort": 80
                                        }
                                    ]
                                }
                            ]
                        }
                        """
                        // Register the task definition with ECS
                        sh "aws ecs register-task-definition --cli-input-json '${taskDefinition}' --region ${env.AWS_REGION}"
                    }
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        // Example to update or run a service in ECS
                        sh "aws ecs update-service --cluster my-cluster --service my-service --force-new-deployment --region ${env.AWS_REGION}"
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
