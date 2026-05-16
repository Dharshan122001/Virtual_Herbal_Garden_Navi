#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ ! -f "secrets.tfvars" ]]; then
  echo "ERROR: secrets.tfvars not found in $SCRIPT_DIR"
  echo "Copy K8s/secrets.tfvars from your secure location before running this script."
  exit 1
fi

# Robust Cleanup Engine for Failed/Stuck Helm States
if command -v helm >/dev/null 2>&1; then
  echo "==> Verifying datadog-otel Helm release status..."
  
  # Fetch status safely. If the release doesn't exist, helm returns an error, handled gracefully by '|| true'
  raw_status="$(helm status datadog-otel -n datadog 2>/dev/null | grep -i "status:" || echo "")"
  
  # If a release exists, check if it's healthy. If it is NOT "deployed", purge it to unlock Terraform.
  if [[ -n "$raw_status" ]]; then
    if [[ "$raw_status" != *"deployed"* ]]; then
      echo "==> Found non-healthy/stuck Helm release datadog-otel (Raw: $raw_status)."
      echo "==> Purging corrupted release state before running Terraform..."
      helm uninstall datadog-otel -n datadog --wait || true
      
      # Optional: Double-check and delete remaining hanging pods if necessary
      kubectl delete pods -l app.kubernetes.io/name=opentelemetry-collector -n datadog --force --grace-period=0 2>/dev/null || true
    else
      echo "==> Existing datadog-otel release is healthy and deployed. Proceeding cleanly."
    fi
  fi
fi

echo "==> Initializing Terraform in ${SCRIPT_DIR}"
terraform init

echo "==> Formatting Terraform files"
terraform fmt

echo "==> Planning Terraform apply"
terraform plan -var-file=secrets.tfvars -out=tfplan

echo "==> Applying Terraform plan"
terraform apply -auto-approve tfplan

echo "==> Terraform apply finished successfully"