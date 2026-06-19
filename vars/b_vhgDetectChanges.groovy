def call(String kubeconfigId = 'aks-kubeconfig', String namespace = 'vhg-1', String release = 'vhg') {
    stage('Detect Changes') {
        script {
            // Fresh-deploy guard: if no Helm release exists, skip diff and deploy everything
            def freshDeploy = false
            withCredentials([string(credentialsId: kubeconfigId, variable: 'KUBECONFIG_BASE64')]) {
                def kubePath = "${WORKSPACE}/.kubeconfig"
                sh(script: 'umask 077 && echo "$KUBECONFIG_BASE64" | base64 -d > "' + kubePath + '"')
                withEnv(["KUBECONFIG=${kubePath}"]) {
                    def found = sh(
                        script: "helm list -n ${namespace} -q | grep -cx '${release}' || true",
                        returnStdout: true
                    ).trim()
                    freshDeploy = (found == '0')
                }
                sh(script: "rm -f ${kubePath}")
            }

            if (freshDeploy) {
                echo "=========================================================================="
                echo "Fresh deployment: no '${release}' release found in ${namespace}. Deploying all services."
                echo "=========================================================================="
                env.FRONTEND_CHANGED = 'true'
                env.PLANT_CHANGED    = 'true'
                env.AUTH_CHANGED     = 'true'
                env.AI_CHANGED       = 'true'
                return
            }

            // Incremental deploy: only rebuild services whose source changed
            def changedFiles = sh(
                script: 'git diff --name-only HEAD~1 HEAD 2>/dev/null || echo ALL',
                returnStdout: true
            ).trim()

            def flags = [frontend: false, plant: false, auth: false, ai: false]
            if (changedFiles == 'ALL') {
                flags.frontend = true; flags.plant = true; flags.auth = true; flags.ai = true
            } else {
                changedFiles.split('\n').each { file ->
                    if (file.startsWith('client/'))                                                      flags.frontend = true
                    if (file.startsWith('server/plant_service/') || file.startsWith('server/common/'))  flags.plant    = true
                    if (file.startsWith('server/auth_service/')  || file.startsWith('server/common/'))  flags.auth     = true
                    if (file.startsWith('server/ai_service/')    || file.startsWith('server/common/'))  flags.ai       = true
                    // root server/ files (requirements.txt, Dockerfile) affect all services
                    if (file == 'server/requirements.txt' || file == 'server/Dockerfile') {
                        flags.plant = true; flags.auth = true; flags.ai = true; flags.frontend = true
                    }
                }
            }

            def coreAppChanged = flags.frontend || flags.plant || flags.auth || flags.ai

            if (!coreAppChanged) {
                echo "=========================================================================="
                echo "Skipping Trigger: No modifications found inside client/ or server/ directories."
                echo "=========================================================================="
                currentBuild.result      = 'SUCCESS'
                currentBuild.description = 'Skipped: Changes outside microservice folders'
                error("STOP_PIPELINE")
            }

            env.FRONTEND_CHANGED = flags.frontend.toString()
            env.PLANT_CHANGED    = flags.plant.toString()
            env.AUTH_CHANGED     = flags.auth.toString()
            env.AI_CHANGED       = flags.ai.toString()
        }
    }
}
