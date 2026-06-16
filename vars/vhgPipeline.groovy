def call() {
  pipeline {
    // Target the custom binary-ready inbound agent node
    agent { label 'vhg' }

    options {
      timestamps()
      disableConcurrentBuilds()
    }

    environment {
      DOCKERHUB_REPO = 'dharshan3690'
      KUBE_NAMESPACE = 'vhg-1'
      HELM_RELEASE = 'vhg'
      HELM_CHART_DIR = 'vhg-chart'
      IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
      stage('Checkout') {
        steps {
          checkout scm
        }
      }

      stage('Detect Changes') {
        steps {
          script {
            def changedFiles = sh(
              script: 'git diff --name-only HEAD~1 HEAD 2>/dev/null || echo ALL',
              returnStdout: true
            ).trim()

            def flags = [
              frontend: false,
              plant    : false,
              auth     : false,
              ai       : false,
              chart    : false
            ]

            if (changedFiles == 'ALL') {
              flags.frontend = true
              flags.plant = true
              flags.auth = true
              flags.ai = true
              flags.chart = true
            } else {
              changedFiles.split('\n').each { file ->
                if (file.startsWith('client/')) {
                  flags.frontend = true
                }
                if (file.startsWith('server/plant_service/') || file == 'server/plantmain.py' || file.startsWith('server/common/') || file == 'server/requirements.txt') {
                  flags.plant = true
                }
                if (file.startsWith('server/auth_service/') || file == 'server/authmain.py' || file.startsWith('server/common/') || file == 'server/requirements.txt') {
                  flags.auth = true
                }
                if (file.startsWith('server/ai_service/') || file == 'server/aimain.py' || file.startsWith('server/common/') || file == 'server/requirements.txt') {
                  flags.ai = true
                }
                if (file.startsWith('vhg-chart/')) {
                  flags.chart = true
                }
              }
            }

            def noDeployableChanges = !flags.frontend && !flags.plant && !flags.auth && !flags.ai && !flags.chart

            env.FRONTEND_CHANGED = flags.frontend.toString()
            env.PLANT_CHANGED = flags.plant.toString()
            env.AUTH_CHANGED = flags.auth.toString()
            env.AI_CHANGED = flags.ai.toString()
            env.CHART_CHANGED = flags.chart.toString()
            env.NO_DEPLOYABLE_CHANGES = noDeployableChanges.toString()

            echo "Changed files: ${changedFiles}"
            echo "Frontend Changed: ${env.FRONTEND_CHANGED}"
            echo "Plant Changed: ${env.PLANT_CHANGED}"
            echo "Auth Changed: ${env.AUTH_CHANGED}"
            echo "AI Changed: ${env.AI_CHANGED}"
            echo "Chart Changed: ${env.CHART_CHANGED}"
            echo "No Deployable Changes: ${env.NO_DEPLOYABLE_CHANGES}"
          }
        }
      }

      stage('No Changes Summary') {
        when {
          expression {
            return env.NO_DEPLOYABLE_CHANGES == 'true'
          }
        }
        steps {
          echo 'No deployable changes detected. Skipping build and deploy.'
          script {
            currentBuild.description = 'No deployable changes'
          }
        }
      }

      stage('Build and Push Images') {
        when {
          expression {
            return env.NO_DEPLOYABLE_CHANGES != 'true'
          }
        }
        steps {
          withCredentials([usernamePassword(
            credentialsId: 'dockerhub-creds',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )]) {
            sh '''#!/usr/bin/env bash
              set -euo pipefail

              echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

              build_backend_service() {
                local service_dir="$1"
                local image_name="$2"
                local workspace="server/build_${service_dir}"

                echo "Building ${image_name}:${IMAGE_TAG}"

                rm -rf "$workspace"
                mkdir -p "$workspace"

                cp server/requirements.txt "$workspace/"
                cp server/Dockerfile "$workspace/"
                cp -r server/common "$workspace/common"
                mkdir -p "$workspace/$service_dir"
                cp -r "server/$service_dir"/* "$workspace/$service_dir/"

                pushd "$workspace" >/dev/null
                docker build \
                  -t "${DOCKERHUB_REPO}/${image_name}:${IMAGE_TAG}" \
                  .
                popd >/dev/null

                docker push "${DOCKERHUB_REPO}/${image_name}:${IMAGE_TAG}"
                rm -rf "$workspace"
              }

              if [ "$PLANT_CHANGED" = "true" ]; then
                build_backend_service "plant_service" "plant-service"
              fi

              if [ "$AUTH_CHANGED" = "true" ]; then
                build_backend_service "auth_service" "auth-service"
              fi

              if [ "$AI_CHANGED" = "true" ]; then
                build_backend_service "ai_service" "ai-service"
              fi

              if [ "$FRONTEND_CHANGED" = "true" ]; then
                echo "Building frontend:${IMAGE_TAG}"
                docker build \
                  -t "${DOCKERHUB_REPO}/frontend:${IMAGE_TAG}" \
                  client
                docker push "${DOCKERHUB_REPO}/frontend:${IMAGE_TAG}"
              fi
            '''
          }
        }
      }

      stage('Deploy to Kubernetes') {
        when {
          expression {
            return env.NO_DEPLOYABLE_CHANGES != 'true'
          }
        }
        steps {
          withCredentials([string(credentialsId: 'aks-kubeconfig', variable: 'KUBECONFIG_CONTENT')]) {
            sh '''#!/usr/bin/env bash
              set -euo pipefail

              KUBECONFIG_PATH="$WORKSPACE/.kubeconfig"
              umask 077
              
              # ✅ Fixed: Use printf '%s\n' to output the string cleanly without line compression
              printf '%s\n' "$KUBECONFIG_CONTENT" > "$KUBECONFIG_PATH"

              export KUBECONFIG="$KUBECONFIG_PATH"

              RELEASE_EXISTS=false
              if helm list -n "$KUBE_NAMESPACE" -q | grep -qx "$HELM_RELEASE"; then
                RELEASE_EXISTS=true
              fi

              HELM_ARGS=(helm upgrade --install "$HELM_RELEASE" "./$HELM_CHART_DIR" --namespace "$KUBE_NAMESPACE" --create-namespace --wait --timeout 10m)

              if [ "$RELEASE_EXISTS" = "true" ]; then
                HELM_ARGS+=(--reuse-values)
              fi

              if [ "$FRONTEND_CHANGED" = "true" ] || [ "$RELEASE_EXISTS" = "false" ]; then
                HELM_ARGS+=(--set "frontend.image=${DOCKERHUB_REPO}/frontend" --set "frontend.tag=${IMAGE_TAG}")
              fi

              if [ "$PLANT_CHANGED" = "true" ] || [ "$RELEASE_EXISTS" = "false" ]; then
                HELM_ARGS+=(--set "plant.image=${DOCKERHUB_REPO}/plant-service" --set "plant.tag=${IMAGE_TAG}")
              fi

              if [ "$AUTH_CHANGED" = "true" ] || [ "$RELEASE_EXISTS" = "false" ]; then
                HELM_ARGS+=(--set "auth.image=${DOCKERHUB_REPO}/auth-service" --set "auth.tag=${IMAGE_TAG}")
              fi

              if [ "$AI_CHANGED" = "true" ] || [ "$RELEASE_EXISTS" = "false" ]; then
                HELM_ARGS+=(--set "ai.image=${DOCKERHUB_REPO}/ai-service" --set "ai.tag=${IMAGE_TAG}")
              fi

              if [ "$CHART_CHANGED" = "true" ] && [ "$FRONTEND_CHANGED" = "false" ] && [ "$PLANT_CHANGED" = "false" ] && [ "$AUTH_CHANGED" = "false" ] && [ "$AI_CHANGED" = "false" ]; then
                echo "Chart-only change detected. Re-deploying Helm release without new image tags."
              fi

              "${HELM_ARGS[@]}"

              kubectl rollout status deployment/frontend -n "$KUBE_NAMESPACE" --timeout=300s
              kubectl rollout status deployment/plant-service -n "$KUBE_NAMESPACE" --timeout=300s
              kubectl rollout status deployment/auth-service -n "$KUBE_NAMESPACE" --timeout=300s
              kubectl rollout status deployment/ai-service -n "$KUBE_NAMESPACE" --timeout=300s

              rm -f "$KUBECONFIG_PATH"
            '''
          }
        }
      }
    }

    post {
      success {
        echo "Jenkins pipeline completed successfully."
      }
      failure {
        echo "Jenkins pipeline failed. Check the console log for the exact step."
      }
    }
  }
}