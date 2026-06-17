// Accept standard positional parameters instead of a map object
def call(String repo, String tag, String credentialsId = 'dockerhub-creds') {
    stage('Build and Push Images') {
        withCredentials([usernamePassword(
            credentialsId: credentialsId,
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
        )]) {
            script {
                // Initialize Buildx
                sh """#!/usr/bin/env bash
                    set -euo pipefail
                    if ! docker buildx version &>/dev/null; then
                        mkdir -p ~/.docker/cli-plugins
                        curl -SL "https://github.com/docker/buildx/releases/download/v0.14.1/buildx-v0.14.1.linux-arm64" -o ~/.docker/cli-plugins/docker-buildx
                        chmod +x ~/.docker/cli-plugins/docker-buildx
                    fi
                    echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                    docker buildx create --name vhg-builder --use --driver docker-container 2>/dev/null || docker buildx use vhg-builder
                    docker buildx inspect --bootstrap
                """

                // Inline compilation helper
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