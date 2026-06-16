#!/usr/bin/env bash
set -euo pipefail

# Configurations
REPO_NAME="Dharshan122001/Virtual_Herbal_Garden_Navi"
JENKINS_URL="http://localhost:8080"

echo "🏁 Initializing Automated Architecture Recreation Loop..."

# 1. Spin up Azure Resources via Terraform
echo "🚀 Provisioning AKS Cluster and associated Add-ons..."
cd K8s
terraform init
terraform apply -var-file="secrets.tfvars" -auto-approve

# 2. Grab the live Kubeconfig
echo "🔐 Extraction of newly constructed cluster Kubeconfig..."
RAW_KUBECONFIG=$(terraform output -raw cluster_name >/dev/null && az aks get-credentials --resource-group Darshan.k_lean_rg --name vhg-aks --file -)
KUBECONFIG_B64=$(echo "$RAW_KUBECONFIG" | base64 | tr -d '\n')
cd ..

# 3. Spin up an independent ngrok background process
echo "🌐 Launching fresh public network proxy tunnel..."
if pkill ngrok; then echo "Purged existing hanging proxies..."; fi
ngrok http 8080 > /dev/null 2>&1 &
sleep 5

# 4. Extract the active webhook location endpoint
NGROK_URL=$(curl --silent http://127.0.0.1:4040/api/tunnels | grep -o '"public_url":"[^"]*' | grep -o 'https://[^"]*')
WEBHOOK_TARGET="${NGROK_URL}/github-webhook/"

echo "=========================================================="
echo "🎯 RECONSTRUCTION COMPLETE!"
echo "=========================================================="
echo "1️⃣  Copy this string and update 'aks-kubeconfig' in Jenkins:"
echo ""
echo "${KUBECONFIG_B64}"
echo ""
echo "2️⃣  Your new GitHub Webhook endpoint is active at:"
echo "${WEBHOOK_TARGET}"
echo "=========================================================="