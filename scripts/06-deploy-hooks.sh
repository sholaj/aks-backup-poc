#!/bin/bash
# AKS Backup PoC - Step 6: Deploy Backup/Restore Hooks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-set-variables.sh"

echo "=============================================="
echo "Step 6: Deploy Backup/Restore Hooks"
echo "=============================================="

# Wait for CRDs to be available
log_info "Waiting for backup hook CRDs to be available..."
MAX_RETRIES=30
RETRY_COUNT=0

while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    if kubectl get crd backuphooks.clusterbackup.dataprotection.microsoft.com &>/dev/null; then
        log_info "BackupHook CRD is available"
        break
    fi
    log_info "Waiting for BackupHook CRD... (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
    sleep 10
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
    log_warn "BackupHook CRD not found. This might be okay if hooks are managed differently."
    log_info "Proceeding without deploying hooks..."
    echo ""
    log_info "Step 6 skipped - CRDs not available"
    exit 0
fi

# Check for RestoreHook CRD
if kubectl get crd restorehooks.clusterbackup.dataprotection.microsoft.com &>/dev/null; then
    log_info "RestoreHook CRD is available"
else
    log_warn "RestoreHook CRD not found"
fi

# Deploy backup hooks
log_info "Deploying backup hooks..."
kubectl apply -f "${PROJECT_DIR}/kubernetes/hooks/backup-hooks.yaml"

# Deploy restore hooks
log_info "Deploying restore hooks..."
kubectl apply -f "${PROJECT_DIR}/kubernetes/hooks/restore-hooks.yaml"

# Verify hooks are created
log_info "Verifying hooks are created..."
echo ""
echo "Backup Hooks:"
kubectl get backuphooks -n at-app2 2>/dev/null || echo "No backup hooks found or CRD not available"

echo ""
echo "Restore Hooks:"
kubectl get restorehooks -n at-app2 2>/dev/null || echo "No restore hooks found or CRD not available"

echo ""
log_info "Step 6 completed successfully!"
echo "  Backup hooks deployed for MySQL"
echo "  Restore hooks deployed for MySQL"
echo ""
