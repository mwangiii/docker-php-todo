pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_IMAGE = "mwangiii/php-todo-app"
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

        stage('Checkout') {
            steps {
                withCredentials([string(credentialsId: 'github-token-id', variable: 'GITHUB_TOKEN')]) {
                    script {
                        def commitSha = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()

                        // Update GitHub commit status to 'pending'
                        sh """
                        curl -X POST -H "Authorization: token ${GITHUB_TOKEN}" \
                             -H "Accept: application/vnd.github.v3+json" \
                             -d '{"state": "pending", "context": "jenkins", "description": "Build started", "target_url": "${env.BUILD_URL}"}' \
                             https://api.github.com/repos/mwangiii/docker-php-todo/statuses/${commitSha}
                        """

                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: "${params.BRANCH_NAME}"]],
                            userRemoteConfigs: [[
                                url: 'https://github.com/mwangiii/docker-php-todo.git',
                                credentialsId: 'github-token-id'
                            ]],
                            extensions: [[$class: 'DisableRemotePoll']]
                        ])
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def branchName = params.BRANCH_NAME
                    env.TAG_NAME = branchName == 'main' ? 'latest' : "${branchName}-0.0.${env.BUILD_NUMBER}"
                    
                    sh """
                    docker build -t ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${env.TAG_NAME} .
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-logins', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh """
                        echo ${PASSWORD} | docker login -u ${USERNAME} --password-stdin ${DOCKER_REGISTRY}
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${env.TAG_NAME}
                        """
                    }
                }
            }
        }

        stage('Cleanup Docker Images') {
            steps {
                script {
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
                sh 'docker logout'
            }
        }

        success {
            withCredentials([string(credentialsId: 'github-token-id', variable: 'GITHUB_TOKEN')]) {
                script {
                    def commitSha = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()

                    // Update GitHub commit status to 'success'
                    sh """
                    curl -X POST -H "Authorization: token ${GITHUB_TOKEN}" \
                         -H "Accept: application/vnd.github.v3+json" \
                         -d '{"state": "success", "context": "jenkins", "description": "Build succeeded", "target_url": "${env.BUILD_URL}"}' \
                         https://api.github.com/repos/mwangiii/docker-php-todo/statuses/${commitSha}
                    """
                }
            }
        }

        failure {
            withCredentials([string(credentialsId: 'github-token-id', variable: 'GITHUB_TOKEN')]) {
                script {
                    def commitSha = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()

                    // Update GitHub commit status to 'failure'
                    sh """
                    curl -X POST -H "Authorization: token ${GITHUB_TOKEN}" \
                         -H "Accept: application/vnd.github.v3+json" \
                         -d '{"state": "failure", "context": "jenkins", "description": "Build failed", "target_url": "${env.BUILD_URL}"}' \
                         https://api.github.com/repos/mwangiii/docker-php-todo/statuses/${commitSha}
                    """
                }
            }
        }
    }
}
