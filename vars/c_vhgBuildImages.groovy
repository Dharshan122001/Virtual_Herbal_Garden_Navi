def call(String repo, String tag, String credentialsId = 'dockerhub-creds') {
    stage('Build and Push Images') {
        withCredentials([usernamePassword(
            credentialsId: credentialsId,
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
        )]) {
            script {
                // Initialize Buildx using safe single-quotes to protect credentials from Groovy compilation tracking
                sh '#!/usr/bin/env bash\n' +
                   'set -euo pipefail\n' +
                   'if ! docker buildx version &>/dev/null; then\n' +
                   '    mkdir -p ~/.docker/cli-plugins\n' +
                   '    curl -SL "https://github.com/docker/buildx/releases/download/v0.14.1/buildx-v0.14.1.linux-arm64" -o ~/.docker/cli-plugins/docker-buildx\n' +
                   '    chmod +x ~/.docker/cli-plugins/docker-buildx\n' +
                   'fi\n' +
                   'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin\n' +
                   'docker buildx create --name vhg-builder --use --driver docker-container 2>/dev/null || docker buildx use vhg-builder\n' +
                   'docker buildx inspect --bootstrap'

                // Parameterized compilation engine logic block
                def buildBlock = { serviceDir, imageName ->
                    def ws = "server/build_${serviceDir}"
                    sh "rm -rf ${ws} && mkdir -p ${ws} && cp server/requirements.txt ${ws}/ && cp server/Dockerfile ${ws}/ && cp -r server/common ${ws}/common && mkdir -p ${ws}/${serviceDir} && cp -r server/${serviceDir}/* ${ws}/${serviceDir}/"
                    dir(ws) {
                        sh "docker buildx build --platform linux/amd64 -t ${repo}/${imageName}:${tag} --push ."
                    }
                    sh "rm -rf ${ws}"
                }

                if (env.PLANT_CHANGED == 'true') buildBlock("plant_service", "plant-service")
                if (env.AUTH_CHANGED == 'true')  buildBlock("auth_service", "auth-service")
                if (env.AI_CHANGED == 'true')    buildBlock("ai_service", "ai-service")
                
                if (env.FRONTEND_CHANGED == 'true') {
                    dir('client') {
                        sh "docker buildx build --platform linux/amd64 -t ${repo}/frontend:${tag} --push ."
                    }
                }
            }
        }
    }
}