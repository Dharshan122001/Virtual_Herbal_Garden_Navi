@Library('vhg-shared-library') _

pipeline {
    agent { label 'vhg' }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    triggers {
        pollSCM('* * * * *')
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
                a_vhgCheckout()
                
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    b_vhgDetectChanges('aks-kubeconfig', env.NAMESPACE, env.RELEASE)
                }
            }
        }

        stage('Compile Application') {
            when {
                expression { return currentBuild.description != 'Skipped: Changes outside microservice folders' }
            }
            steps {
                // Call passing straight variables in exact order to bypass sandbox restrictions
                c_vhgBuildImages(
                    env.REPO_NAME,
                    env.BUILD_TAG,
                    'dockerhub-creds'
                )
            }
        }

        stage('Deliver to Infrastructure') {
            when {
                expression { return currentBuild.description != 'Skipped: Changes outside microservice folders' }
            }
            steps {
                // Call passing straight variables in exact order to bypass sandbox restrictions
                d_vhgDeployKubernetes(
                    env.REPO_NAME,
                    env.BUILD_TAG,
                    env.NAMESPACE,
                    env.RELEASE,
                    env.CHART_DIR,
                    'aks-kubeconfig'
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