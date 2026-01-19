#!/bin/bash
# AKS Backup PoC - Step 7: Configure Backup Instance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-set-variables.sh"

echo "=============================================="
echo "Step 7: Configure Backup Instance"
echo "=============================================="

# Load required variables
SUBSCRIPTION_ID=$(load_from_env "SUBSCRIPTION_ID")
AKS_ID=$(load_from_env "AKS_ID")
BACKUP_VAULT_PRINCIPAL_ID=$(load_from_env "BACKUP_VAULT_PRINCIPAL_ID")
BACKUP_POLICY_ID=$(load_from_env "BACKUP_POLICY_ID")
SNAPSHOT_RG_ID=$(load_from_env "SNAPSHOT_RG_ID")

if [[ -z "$AKS_ID" ]] || [[ -z "$BACKUP_VAULT_PRINCIPAL_ID" ]]; then
    log_error "Required variables not found. Please run steps 2 and 3 first."
    exit 1
fi

# Assign required roles to Backup Vault MSI
log_info "Assigning RBAC roles to Backup Vault managed identity..."

# Reader role on AKS cluster
log_info "Assigning Reader role on AKS cluster..."
az role assignment create \
    --assignee "$BACKUP_VAULT_PRINCIPAL_ID" \
    --role "Reader" \
    --scope "$AKS_ID" \
    --output none 2>/dev/null || log_warn "Reader role may already exist"

# Contributor role on AKS cluster (for restore)
log_info "Assigning Contributor role on AKS cluster..."
az role assignment create \
    --assignee "$BACKUP_VAULT_PRINCIPAL_ID" \
    --role "Contributor" \
    --scope "$AKS_ID" \
    --output none 2>/dev/null || log_warn "Contributor role may already exist"

# Contributor role on snapshot resource group
log_info "Assigning Contributor role on snapshot resource group..."
az role assignment create \
    --assignee "$BACKUP_VAULT_PRINCIPAL_ID" \
    --role "Contributor" \
    --scope "$SNAPSHOT_RG_ID" \
    --output none 2>/dev/null || log_warn "Contributor role may already exist"

# Wait for role propagation
log_info "Waiting for role assignments to propagate..."
sleep 30

# Create Trusted Access role binding
log_info "Creating Trusted Access role binding..."
az aks trustedaccess rolebinding create \
    --resource-group "$RESOURCE_GROUP" \
    --cluster-name "$AKS_CLUSTER_NAME" \
    --name "backup-vault-binding" \
    --source-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.DataProtection/backupVaults/${BACKUP_VAULT_NAME}" \
    --roles "Microsoft.DataProtection/backupVaults/backup-operator" \
    --output none 2>/dev/null || log_warn "Trusted access binding may already exist"

log_info "Trusted Access role binding created"

# Create backup instance configuration
BACKUP_INSTANCE_NAME="${AKS_CLUSTER_NAME}-backup"

# Generate backup configuration
log_info "Initializing backup configuration..."

az dataprotection backup-instance initialize-backupconfig \
    --datasource-type AzureKubernetesService \
    --include-cluster-scope-resources false \
    --included-namespaces at-app1 at-app2 \
    --snapshot-volumes true \
    --label-selectors "backup=true" \
    > /tmp/backup-config.json

log_info "Backup configuration created"

# Initialize backup instance
log_info "Initializing backup instance..."

az dataprotection backup-instance initialize \
    --datasource-id "$AKS_ID" \
    --datasource-location "$LOCATION" \
    --datasource-type AzureKubernetesService \
    --policy-id "$BACKUP_POLICY_ID" \
    --backup-configuration /tmp/backup-config.json \
    --friendly-name "$BACKUP_INSTANCE_NAME" \
    --snapshot-resource-group-name "$SNAPSHOT_RG" \
    > /tmp/backup-instance.json

log_info "Backup instance initialized"

# Validate backup instance
log_info "Validating backup instance..."

az dataprotection backup-instance validate-for-backup \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --backup-instance /tmp/backup-instance.json \
    --output none || {
        log_warn "Validation produced warnings, proceeding with creation..."
    }

# Create backup instance
log_info "Creating backup instance..."

az dataprotection backup-instance create \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --backup-instance /tmp/backup-instance.json \
    --output none

log_info "Backup instance creation initiated"

# Wait for backup instance to be ready
log_info "Waiting for backup instance to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    STATE=$(az dataprotection backup-instance list \
        --resource-group "$RESOURCE_GROUP" \
        --vault-name "$BACKUP_VAULT_NAME" \
        --query "[?contains(name, '${AKS_CLUSTER_NAME}')].properties.protectionStatus.status" \
        -o tsv 2>/dev/null || echo "Pending")

    if [[ "$STATE" == "ProtectionConfigured" ]] || [[ "$STATE" == "ConfiguringProtection" ]]; then
        log_info "Backup instance state: $STATE"
        break
    fi

    log_info "Current state: $STATE. Waiting..."
    sleep 20
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

# Get backup instance ID
BACKUP_INSTANCE_ID=$(az dataprotection backup-instance list \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --query "[?contains(name, '${AKS_CLUSTER_NAME}')].id" \
    -o tsv)

save_to_env "BACKUP_INSTANCE_ID" "$BACKUP_INSTANCE_ID"
save_to_env "BACKUP_INSTANCE_NAME" "$BACKUP_INSTANCE_NAME"

echo ""
log_info "Step 7 completed successfully!"
echo "  Backup Instance: $BACKUP_INSTANCE_NAME"
echo "  Protected namespaces: at-app1, at-app2"
echo "  Snapshot volume backup: enabled"
echo ""
