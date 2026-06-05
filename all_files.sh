#!/bin/bash

for f in \
client/Dockerfile \
client/entrypoint.sh \
client/index.html \
client/src/apiConfig.js \
client/src/main.jsx \
client/src/observability.js \
server/requirements.txt \
server/pyproject.toml \
server/common/database.py \
server/common/gmail_service.py \
server/common/observability.py \
server/common/schemas.py \
server/common/utils.py \
server/Dockerfile \
server/ai_service/main.py \
server/auth_service/main.py \
server/plant_service/main.py \
vhg-chart/Chart.yaml \
vhg-chart/1a-namespace.yaml \
vhg-chart/values.yaml \
vhg-chart/templates/1-frontend-deployment.yaml \
vhg-chart/templates/2-plant-deployment.yaml \
vhg-chart/templates/3-ai-deployment.yaml \
vhg-chart/templates/4-auth-deployment.yaml \
vhg-chart/templates/5-backend-service.yaml \
vhg-chart/templates/6-frontend-service.yaml \
vhg-chart/templates/7-ingress.yaml \
vhg-chart/templates/8-servicemonitor.yaml \
vhg-chart/templates/9-hpa-ai.yaml \
vhg-chart/templates/10-hpa-auth.yaml \
vhg-chart/templates/11-hpa-frontend.yaml \
vhg-chart/templates/12-hpa-plant.yaml \
vhg-chart/templates/_helpers.tpl \
vhg-chart/templates/NOTES.txt \
vhg-chart/templates/secret.yaml \
K8s/1-aks.tf \
K8s/1a-main.tf \
K8s/2-helm-app.tf \
K8s/4-helm-nginx.tf \
K8s/5-helm-otel.tf \
K8s/6-helm-prometheus.tf \
K8s/7-ingress-tools.tf \
K8s/outputs.tf \
K8s/providers.tf \
K8s/secrets.tfvars \
K8s/variables.tf \
VHG-pipelines.yml \
Jenkinsfile \
docker-compose.yml \
jenkins/agent/Dockerfile \
jenkins/controller/Dockerfile \
jenkins/controller/plugins.txt \
jenkins/controller/casc/jenkins.yaml \
jenkins/controller/entrypoint.sh \
jenkins/shared-library/vars/vhgPipeline.groovy \
vars/vhgPipeline.groovy \
README.md

do
  echo "\n\n==================== $f ====================\n"
  cat "$f"
done > all_project_files_output.txt

echo "Output written to all_project_files_output.txt"
