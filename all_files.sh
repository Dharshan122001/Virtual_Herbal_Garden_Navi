#!/bin/bash

for f in \
client/Dockerfile \
client/entrypoint.sh \
client/index.html \
client/src/main.jsx \
client/src/observability.js \
server/requirements.txt \
server/ai_service/Dockerfile \
server/ai_service/main.py \
server/auth_service/main.py \
server/auth_service/Dockerfile \
server/plant_service/Dockerfile \
server/plant_service/main.py \
vhg-chart/Chart.yaml \
vhg-chart/1a-namespace.yaml \
vhg-chart/values.yaml \
vhg-chart/templates/1-frontend-deployment.yaml \
vhg-chart/templates/2-plant-deployment.yaml \
vhg-chart/templates/3-ai-deployment.yaml \
vhg-chart/templates/4-auth-deployment.yaml \
vhg-chart/templates/backend-service.yaml \
vhg-chart/templates/frontend-service.yaml \
vhg-chart/templates/hpa-ai.yaml \
vhg-chart/templates/hpa-auth.yaml \
vhg-chart/templates/hpa-frontend.yaml \
vhg-chart/templates/hpa-plant.yaml \
vhg-chart/templates/ingress.yaml \
vhg-chart/templates/secret.yaml \
K8s/aks.tf \
K8s/helm-app.tf \
K8s/helm-argocd.tf \
K8s/helm-datadog.tf \
K8s/helm-nginx.tf \
K8s/main.tf \
K8s/outputs.tf \
K8s/providers.tf \
K8s/secrets.tfvars \
K8s/variables.tf \
K8s/argocd-app-chart/templates/application.yaml \
K8s/argocd-app-chart/templates/ingress.yaml \
K8s/argocd-app-chart/Chart.yaml \
VHG-pipelines.yml

do
  echo "\n\n==================== $f ====================\n"
  cat "$f"
done > all_project_files_output.txt

echo "Output written to all_project_files_output.txt"
