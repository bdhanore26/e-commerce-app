@Library('Shared') _

pipeline {

    agent any

    environment {

        DOCKER_IMAGE_NAME = 'bdhanore26/easyshop-app'
        DOCKER_MIGRATION_IMAGE_NAME = 'bdhanore26/easyshop-migration'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"

        GIT_BRANCH = "master"
    }

    stages {

        stage('Cleanup Workspace') {

            steps {
                script {
                    clean_ws()
                }
            }

        }


        stage('Clone Repository') {

            steps {

                script {

                    clone(
                        "https://github.com/bdhanore26/e-commerce-app.git",
                        env.GIT_BRANCH
                    )

                }

            }

        }


        stage('Prevent Build Loop') {

            steps {

                script {

                    def commitMsg = sh(
                        script: "git log -1 --pretty=%B",
                        returnStdout: true
                    ).trim()

                    echo "Latest commit: ${commitMsg}"

                    if (
                        commitMsg.contains("[skip ci]") ||
                        commitMsg.startsWith("Update image tags")
                    ) {

                        currentBuild.result = 'NOT_BUILT'

                        error(
                            "Stopping self-triggered Jenkins build"
                        )

                    }

                }

            }

        }


        stage('Build Docker Images') {

            parallel {

                stage('Build Main') {

                    steps {

                        script {

                            docker_build(
                                imageName: env.DOCKER_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                dockerfile: 'Dockerfile',
                                context: '.'
                            )

                        }

                    }

                }


                stage('Build Migration') {

                    steps {

                        script {

                            docker_build(
                                imageName:
                                env.DOCKER_MIGRATION_IMAGE_NAME,

                                imageTag:
                                env.DOCKER_IMAGE_TAG,

                                dockerfile:
                                'scripts/Dockerfile.migration',

                                context: '.'
                            )

                        }

                    }

                }

            }

        }


        stage('Run Tests') {

            steps {

                script {

                    run_tests()

                }

            }

        }


        stage('Trivy Scan') {

            steps {

                script {

                    trivy_scan()

                }

            }

        }


        stage('Push Images') {

            parallel {

                stage('Push Main') {

                    steps {

                        script {

                            docker_push(
                                imageName:
                                env.DOCKER_IMAGE_NAME,

                                imageTag:
                                env.DOCKER_IMAGE_TAG,

                                credentials:
                                'dockerhub-credentials'
                            )

                        }

                    }

                }


                stage('Push Migration') {

                    steps {

                        script {

                            docker_push(
                                imageName:
                                env.DOCKER_MIGRATION_IMAGE_NAME,

                                imageTag:
                                env.DOCKER_IMAGE_TAG,

                                credentials:
                                'dockerhub-credentials'
                            )

                        }

                    }

                }

            }

        }


        stage('Update Kubernetes') {

            steps {

                script {

                    update_k8s_manifests(

                        imageTag:
                        env.DOCKER_IMAGE_TAG,

                        manifestsPath:
                        'kubernetes',

                        gitCredentials:
                        'github-credentials',

                        gitUserName:
                        'Jenkins CI',

                        gitUserEmail:
                        'bdhanore26@gmail.com'

                    )

                }

            }

        }

    }


    post {

        success {

            echo "SUCCESS"

        }

        failure {

            echo "FAILED"

        }

        always {

            cleanWs()

        }

    }

}
