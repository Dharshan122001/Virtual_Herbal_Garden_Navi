#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ ! -f "secrets.tfvars" ]]; then
  echo "ERROR: secrets.tfvars not found in $SCRIPT_DIR"
  echo "Copy K8s/secrets.tfvars from your secure location before running this script."
  exit 1
fi

# Cleanup failed Helm release to avoid name reuse conflicts
if command -v helm >/dev/null 2>&1; then
  release_status="$(helm status datadog-otel -n datadog 2>/dev/null | grep -E '^STATUS:' | awk '{print $2}' || true)"
  if [[ "$release_status" == "failed" ]]; then
    echo "==> Found failed Helm release datadog-otel in namespace datadog. Uninstalling it before Terraform apply."
    helm uninstall datadog-otel -n datadog || true
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
