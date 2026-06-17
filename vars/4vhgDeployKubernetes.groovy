def call(Map config = [:]) {
    stage('Deploy to Kubernetes') {
        withCredentials([string(credentialsId: config.kubeconfigId ?: 'aks-kubeconfig', variable: 'KUBECONFIG_BASE64')]) {
            script {
                def kubePath = "${WORKSPACE}/.kubeconfig"
                sh "umask 077 && echo '${KUBECONFIG_BASE64}' | base64 -d > '${kubePath}'"

                withEnv(["KUBECONFIG=${kubePath}"]) {
                    def releaseExists = sh(script: "helm list -n ${config.namespace} -q | grep -qx ${config.release} && echo true || echo false", returnStdout: true).trim()
                    def helmCmd = "helm upgrade --install ${config.release} ./${config.chartDir} --namespace ${config.namespace} --create-namespace --wait --timeout 10m"

                    if (releaseExists == "true") helmCmd += " --reuse-values"
                    if (env.FRONTEND_CHANGED == 'true' || releaseExists == "false") helmCmd += " --set frontend.image=${config.repo}/frontend --set frontend.tag=${config.tag}"
                    if (env.PLANT_CHANGED == 'true' || releaseExists == "false")    helmCmd += " --set plant.image=${config.repo}/plant-service --set plant.tag=${tag}"
                    if (env.AUTH_CHANGED == 'true' || releaseExists == "false")     helmCmd += " --set auth.image=${repo}/auth-service --set auth.tag=${tag}"
                    if (env.AI_CHANGED == 'true' || releaseExists == "false")       helmCmd += " --set ai.image=${repo}/ai-service --set ai.tag=${tag}"

                    sh """#!/usr/bin/env bash
                        set -euo pipefail
                        ${helmCmd}
                        kubectl rollout status deployment/frontend -n ${config.namespace} --timeout=300s
                        kubectl rollout status deployment/plant-service -n ${config.namespace} --timeout=300s
                        kubectl rollout status deployment/auth-service -n ${config.namespace} --timeout=300s
                        kubectl rollout status deployment/ai-service -n ${config.namespace} --timeout=300s
                    """
                }
                sh "rm -f ${kubePath}"
            }
        }
    }
}