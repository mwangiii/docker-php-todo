pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_IMAGE = "citatech/php-todo-app"
        COMPOSE_FILE = "php-todo.yml"
    }

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Git branch to build')
    }

    stages {
        stage('Initial cleanup') {
            steps {
                dir("${WORKSPACE}") {
                    deleteDir()
                }
            }
        }

        stage('SCM Checkout') {
            steps {
                script {
                    // Dynamically select the branch based on the parameter
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "${params.BRANCH_NAME}"]],
                        userRemoteConfigs: [[url: 'https://github.com/citadelict/php-todo-containerization.git']]
                    ])
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def branchName = params.BRANCH_NAME
                    env.TAG_NAME = branchName == 'main' ? 'latest' : "${branchName}-0.0.${env.BUILD_NUMBER}"

                    // Build Docker image with a dynamic tag based on branch name
                    sh """
                    docker-compose -f ${COMPOSE_FILE} build
                    """
                }
            }
        }

        stage('Run Docker Compose') {
            steps {
                script {
                    // Start services using Docker Compose
                    sh """
                    docker-compose -f ${COMPOSE_FILE} up -d
                    """
                }
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    def response
                    retry(5) {
                        sleep(time: 30, unit: 'SECONDS')  // Increase sleep duration to allow services more time to start
                        response = sh(script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080", returnStdout: true).trim()
                        echo "HTTP Status Code: ${response}"
                        if (response == '200') {
                            echo "Smoke test passed with status code 200"
                        } else {
                            error "Smoke test failed with status code ${response}"
                        }
                    }
                }
            }
        }

        stage('Tag and Push Docker Image') {
            steps {
                script {
                    // Tag and push Docker image
                    withCredentials([usernamePassword(credentialsId: 'docker-credentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh """
                        echo "\$PASSWORD" | docker login -u "\$USERNAME" --password-stdin ${DOCKER_REGISTRY}
                        docker tag php-todo-app ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${env.TAG_NAME}
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${env.TAG_NAME}
                        """
                    }
                }
            }
        }

        stage('Stop and Remove Containers') {
            steps {
                script {
                    // Stop and remove Docker containers
                    sh """
                    docker-compose -f ${COMPOSE_FILE} down
                    """
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    // Clean up Docker images to save space
                    sh """
                    docker rmi ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${env.TAG_NAME} || true
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                // Logout from Docker
                sh 'docker logout'
            }
        }
    }
}
