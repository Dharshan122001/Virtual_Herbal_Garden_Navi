@Library('vhg-shared-library') _

pipeline {
    agent { label 'vhg' }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        REPO_NAME = 'dharshan3690'
        NAMESPACE = 'vhg-1'
        RELEASE   = 'vhg'
        CHART_DIR = 'vhg-chart'
        BUILD_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Initialize Stack') {
            steps {
                // 1. Call custom checkout function
                1vhgCheckout()
                
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    // 2. Call change detection function (exits early if non-core files change)
                    2vhgDetectChanges()
                }
            }
        }

        stage('Compile Application') {
            when {
                expression { return currentBuild.description != 'Skipped: Changes outside microservice folders' }
            }
            steps {
                // 3. Call parameterized Docker Compilation step function
                3vhgBuildImages(
                    repo: env.REPO_NAME,
                    tag: env.BUILD_TAG,
                    credentialsId: 'dockerhub-creds'
                )
            }
        }

        stage('Deliver to Infrastructure') {
            when {
                expression { return currentBuild.description != 'Skipped: Changes outside microservice folders' }
            }
            steps {
                // 4. Call parameterized Kubernetes Deployment step function
                4vhgDeployKubernetes(
                    repo: env.REPO_NAME,
                    tag: env.BUILD_TAG,
                    namespace: env.NAMESPACE,
                    release: env.RELEASE,
                    chartDir: env.CHART_DIR,
                    kubeconfigId: 'aks-kubeconfig'
                )
            }
        }
    }

    post {
        success {
            echo "Pipeline Run Finished Successfully!"
        }
        failure {
            echo "Pipeline Failed on a specific functional step block."
        }
    }
}