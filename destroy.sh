#!/usr/bin/env bash
set -euo pipefail

# Configurations
REPO_NAME="Dharshan122001/Virtual_Herbal_Garden_Navi"

echo "🛑 Starting Automated Environment Teardown..."

# 1. Kill the background ngrok proxy process
echo "🌐 Stopping the background ngrok network proxy tunnel..."
if pkill ngrok; then
  echo "✅ Ngrok proxy process terminated successfully."
else
  echo "ℹ️  No running ngrok process found."
fi

# 2. Ask for GitHub PAT to automatically delete the webhook from your repository
echo "📡 Please enter your GitHub Personal Access Token (PAT) to clean up GitHub Webhooks:"
read -rs GITHUB_TOKEN

echo "🔍 Fetching webhook IDs from GitHub..."
# Find any hook matching our local ngrok context and delete it
HOOKS=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${REPO_NAME}/hooks")

HOOK_ID=$(echo "$HOOKS" | grep -B 1 "github-webhook" | grep '"id":' | head -n 1 | awk '{print $2}' | tr -d ',')

if [ -not -z "$HOOK_ID" ]; then
  echo "🗑️  Removing Webhook ID ${HOOK_ID} from GitHub repository settings..."
  curl -s -X DELETE -H "Authorization: token ${GITHUB_TOKEN}" \
       -H "Accept: application/vnd.github.v3+json" \
       "https://api.github.com/repos/${REPO_NAME}/hooks/${HOOK_ID}"
  echo "✅ GitHub webhook removed successfully."
else
  echo "ℹ️  No active Jenkins webhooks found in this repository."
fi

# 3. Destroy all cloud architecture assets via Terraform
echo "💥 Destroying Azure AKS Cluster, Database, and Helm releases via Terraform..."
if [ -d "K8s" ]; then
  cd K8s
  terraform destroy -var-file="secrets.tfvars" -auto-approve
  cd ..
  echo "✅ All Azure infrastructure wiped cleanly."
else
  echo "❌ Error: 'K8s' directory not found. Cannot run terraform destroy."
  exit 1
fi

echo "=========================================================="
echo "🎯 TEARDOWN COMPLETE! Azure cost tracking dropped to 0."
echo "=========================================================="