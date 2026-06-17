def call(String repo, String tag, String namespace, String release, String chartDir, String kubeconfigId = 'aks-kubeconfig') {
    stage('Deploy to Kubernetes') {
        withCredentials([string(credentialsId: kubeconfigId, variable: 'KUBECONFIG_BASE64')]) {
            script {
                def kubePath = "${WORKSPACE}/.kubeconfig"
                sh "umask 077 && echo '${KUBECONFIG_BASE64}' | base64 -d > '${kubePath}'"

                withEnv(["KUBECONFIG=${kubePath}"]) {
                    def releaseExists = sh(script: "helm list -n ${namespace} -q | grep -qx ${release} && echo true || echo false", returnStdout: true).trim()
                    def helmCmd = "helm upgrade --install ${release} ./${chartDir} --namespace ${namespace} --create-namespace --wait --timeout 10m"

                    if (releaseExists == "true") helmCmd += " --reuse-values"
                    if (env.FRONTEND_CHANGED == 'true' || releaseExists == "false") helmCmd += " --set frontend.image=${repo}/frontend --set frontend.tag=${tag}"
                    if (env.PLANT_CHANGED == 'true' || releaseExists == "false")    helmCmd += " --set plant.image=${repo}/plant-service --set plant.tag=${tag}"
                    if (env.AUTH_CHANGED == 'true' || releaseExists == "false")     helmCmd += " --set auth.image=${repo}/auth-service --set auth.tag=${tag}"
                    if (env.AI_CHANGED == 'true' || releaseExists == "false")       helmCmd += " --set ai.image=${repo}/ai-service --set ai.tag=${tag}"

                    sh """#!/usr/bin/env bash
                        set -euo pipefail
                        ${helmCmd}
                        kubectl rollout status deployment/frontend -n ${namespace} --timeout=300s
                        kubectl rollout status deployment/plant-service -n ${namespace} --timeout=300s
                        kubectl rollout status deployment/auth-service -n ${namespace} --timeout=300s
                        kubectl rollout status deployment/ai-service -n ${namespace} --timeout=300s
                    """
                }
                sh "rm -f ${kubePath}"
            }
        }
    }
}