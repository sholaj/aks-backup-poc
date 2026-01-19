#!/bin/bash
# AKS Backup PoC - Cleanup: Destroy All Resources

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-set-variables.sh"

echo "=============================================="
echo "CLEANUP: Destroy All Resources"
echo "=============================================="

log_warn "This will DELETE ALL resources created by this PoC:"
echo "  - Backup Instance"
echo "  - Trusted Access Role Binding"
echo "  - Backup Extension"
echo "  - AKS Cluster: $AKS_CLUSTER_NAME"
echo "  - Backup Vault: $BACKUP_VAULT_NAME"
echo "  - Storage Account: $BACKUP_STORAGE_ACCOUNT"
echo "  - Resource Group: $RESOURCE_GROUP"
echo "  - Snapshot Resource Group: $SNAPSHOT_RG"
echo ""
log_warn "This action is IRREVERSIBLE!"
echo ""

read -p "Type 'yes' to confirm deletion: " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    log_info "Cleanup cancelled"
    exit 0
fi

echo ""
log_info "Starting cleanup..."

# Step 1: Delete Backup Instance
log_info "Step 1/8: Deleting Backup Instance..."
BACKUP_INSTANCE_NAME=$(az dataprotection backup-instance list \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --query "[?contains(name, '${AKS_CLUSTER_NAME}')].name" \
    -o tsv 2>/dev/null || echo "")

if [[ -n "$BACKUP_INSTANCE_NAME" ]]; then
    az dataprotection backup-instance delete \
        --resource-group "$RESOURCE_GROUP" \
        --vault-name "$BACKUP_VAULT_NAME" \
        --backup-instance-name "$BACKUP_INSTANCE_NAME" \
        --yes \
        --output none 2>/dev/null || log_warn "Could not delete backup instance"
    log_info "Backup instance deleted"
else
    log_info "No backup instance found"
fi

# Step 2: Delete Trusted Access Role Binding
log_info "Step 2/8: Deleting Trusted Access Role Binding..."
az aks trustedaccess rolebinding delete \
    --resource-group "$RESOURCE_GROUP" \
    --cluster-name "$AKS_CLUSTER_NAME" \
    --name "backup-vault-binding" \
    --yes \
    --output none 2>/dev/null || log_warn "Could not delete trusted access binding (may not exist)"

# Step 3: Remove Backup Extension
log_info "Step 3/8: Removing Backup Extension..."
az k8s-extension delete \
    --name "$BACKUP_EXTENSION_NAME" \
    --cluster-name "$AKS_CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --cluster-type managedClusters \
    --yes \
    --output none 2>/dev/null || log_warn "Could not remove backup extension (may not exist)"

# Wait for extension to be removed
sleep 30

# Step 4: Delete AKS Cluster
log_info "Step 4/8: Deleting AKS Cluster..."
az aks delete \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER_NAME" \
    --yes \
    --no-wait \
    --output none 2>/dev/null || log_warn "Could not delete AKS cluster (may not exist)"

# Step 5: Delete Backup Vault
log_info "Step 5/8: Deleting Backup Vault..."
# First check if there are any remaining backup instances
REMAINING=$(az dataprotection backup-instance list \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --query "length(@)" \
    -o tsv 2>/dev/null || echo "0")

if [[ "$REMAINING" -gt "0" ]]; then
    log_warn "There are still $REMAINING backup instances in the vault"
fi

az dataprotection backup-vault delete \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --yes \
    --output none 2>/dev/null || log_warn "Could not delete backup vault (may not exist or still has items)"

# Step 6: Delete Storage Account
log_info "Step 6/8: Deleting Storage Account..."
az storage account delete \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BACKUP_STORAGE_ACCOUNT" \
    --yes \
    --output none 2>/dev/null || log_warn "Could not delete storage account (may not exist)"

# Step 7: Delete Snapshot Resource Group
log_info "Step 7/8: Deleting Snapshot Resource Group..."
az group delete \
    --name "$SNAPSHOT_RG" \
    --yes \
    --no-wait \
    --output none 2>/dev/null || log_warn "Could not delete snapshot resource group (may not exist)"

# Step 8: Delete Main Resource Group
log_info "Step 8/8: Deleting Main Resource Group..."
log_info "Waiting for AKS deletion to complete before deleting resource group..."
sleep 60

az group delete \
    --name "$RESOURCE_GROUP" \
    --yes \
    --no-wait \
    --output none 2>/dev/null || log_warn "Could not delete main resource group (may not exist)"

# Clean up local files
log_info "Cleaning up local environment file..."
rm -f "$ENV_FILE"
rm -f /tmp/backup-config.json
rm -f /tmp/backup-instance.json
rm -f /tmp/restore-config.json
rm -f /tmp/restore-request.json

# Clean up kubeconfig context
log_info "Removing kubeconfig context..."
kubectl config delete-context "${AKS_CLUSTER_NAME}" 2>/dev/null || true
kubectl config delete-cluster "${AKS_CLUSTER_NAME}" 2>/dev/null || true

echo ""
echo "=============================================="
log_info "Cleanup initiated!"
echo "=============================================="
echo ""
echo "Resource groups are being deleted in the background."
echo "This may take 10-15 minutes to complete."
echo ""
echo "To verify cleanup is complete, run:"
echo "  az group show --name $RESOURCE_GROUP 2>/dev/null || echo 'Resource group deleted'"
echo "  az group show --name $SNAPSHOT_RG 2>/dev/null || echo 'Snapshot RG deleted'"
echo ""
log_info "Thank you for using the AKS Backup PoC!"
