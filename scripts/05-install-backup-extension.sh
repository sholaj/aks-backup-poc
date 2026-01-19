#!/bin/bash
# AKS Backup PoC - Step 5: Install Backup Extension

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-set-variables.sh"

echo "=============================================="
echo "Step 5: Install Backup Extension"
echo "=============================================="

# Load required variables from env
STORAGE_ACCOUNT_ID=$(load_from_env "STORAGE_ACCOUNT_ID")

if [[ -z "$STORAGE_ACCOUNT_ID" ]]; then
    log_error "STORAGE_ACCOUNT_ID not found. Please run step 3 first."
    exit 1
fi

# Register required providers (if not already registered)
log_info "Ensuring required Azure providers are registered..."
az provider register --namespace Microsoft.KubernetesConfiguration --wait 2>/dev/null || true
az provider register --namespace Microsoft.DataProtection --wait 2>/dev/null || true

# Install the backup extension
log_info "Installing Azure Backup extension on AKS cluster..."
log_info "This may take a few minutes..."

az k8s-extension create \
    --name "$BACKUP_EXTENSION_NAME" \
    --extension-type Microsoft.DataProtection.Kubernetes \
    --scope cluster \
    --cluster-name "$AKS_CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --cluster-type managedClusters \
    --configuration-settings \
        blobContainer=aks-backups \
        storageAccount="$BACKUP_STORAGE_ACCOUNT" \
        storageAccountResourceGroup="$RESOURCE_GROUP" \
        storageAccountSubscriptionId="$(load_from_env 'SUBSCRIPTION_ID')" \
    --release-train stable \
    --output none

log_info "Backup extension installation initiated"

# Wait for extension to be ready
log_info "Waiting for backup extension to be installed..."
az k8s-extension show \
    --name "$BACKUP_EXTENSION_NAME" \
    --cluster-name "$AKS_CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --cluster-type managedClusters \
    --query "provisioningState" -o tsv

# Poll for extension readiness
MAX_RETRIES=30
RETRY_COUNT=0
while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    STATE=$(az k8s-extension show \
        --name "$BACKUP_EXTENSION_NAME" \
        --cluster-name "$AKS_CLUSTER_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --cluster-type managedClusters \
        --query "provisioningState" -o tsv)

    if [[ "$STATE" == "Succeeded" ]]; then
        log_info "Extension installed successfully"
        break
    elif [[ "$STATE" == "Failed" ]]; then
        log_error "Extension installation failed"
        exit 1
    fi

    log_info "Extension state: $STATE. Waiting..."
    sleep 20
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
    log_error "Timeout waiting for extension to be ready"
    exit 1
fi

# Verify extension pods are running
log_info "Verifying backup extension pods..."
sleep 10
kubectl get pods -n dataprotection-microsoft --show-labels 2>/dev/null || \
    kubectl get pods -A | grep -i dataprotection || \
    log_warn "Could not find backup extension pods immediately - they may still be starting"

# Get extension identity
EXTENSION_IDENTITY=$(az k8s-extension show \
    --name "$BACKUP_EXTENSION_NAME" \
    --cluster-name "$AKS_CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --cluster-type managedClusters \
    --query "aksAssignedIdentity.principalId" -o tsv 2>/dev/null || echo "")

if [[ -n "$EXTENSION_IDENTITY" ]]; then
    save_to_env "EXTENSION_IDENTITY" "$EXTENSION_IDENTITY"
    log_info "Extension identity: $EXTENSION_IDENTITY"
fi

echo ""
log_info "Step 5 completed successfully!"
echo "  Backup Extension: $BACKUP_EXTENSION_NAME installed"
echo "  Storage Account: $BACKUP_STORAGE_ACCOUNT"
echo ""
