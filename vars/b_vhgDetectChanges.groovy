def call() {
    stage('Detect Changes') {
        script {
            def changedFiles = sh(
                script: 'git diff --name-only HEAD~1 HEAD 2>/dev/null || echo ALL',
                returnStdout: true
            ).trim()

            // Analyze paths
            def flags = [frontend: false, plant: false, auth: false, ai: false]
            if (changedFiles == 'ALL') {
                flags.frontend = true; flags.plant = true; flags.auth = true; flags.ai = true
            } else {
                changedFiles.split('\n').each { file ->
                    if (file.startsWith('client/')) flags.frontend = true
                    if (file.startsWith('server/plant_service/') || file.startsWith('server/common/')) flags.plant = true
                    if (file.startsWith('server/auth_service/') || file.startsWith('server/common/')) flags.auth = true
                    if (file.startsWith('server/ai_service/') || file.startsWith('server/common/')) flags.ai = true
                }
              }

            def coreAppChanged = flags.frontend || flags.plant || flags.auth || flags.ai

            if (!coreAppChanged) {
                echo "=========================================================================="
                echo "🛑 Skipping Trigger: No modifications found inside client/ or server/ directories."
                echo "=========================================================================="
                currentBuild.result = 'SUCCESS'
                currentBuild.description = 'Skipped: Changes outside microservice folders'
                error("STOP_PIPELINE") // Clean early signal to stop downstream execution
            }

            // Bind values to the global env map for subsequent stages
            env.FRONTEND_CHANGED = flags.frontend.toString()
            env.PLANT_CHANGED    = flags.plant.toString()
            env.AUTH_CHANGED     = flags.auth.toString()
            env.AI_CHANGED       = flags.ai.toString()
        }
    }
}