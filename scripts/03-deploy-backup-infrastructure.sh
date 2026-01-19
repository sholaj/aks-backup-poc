#!/bin/bash
# AKS Backup PoC - Step 3: Deploy Backup Infrastructure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-set-variables.sh"

echo "=============================================="
echo "Step 3: Deploy Backup Infrastructure"
echo "=============================================="

# Deploy backup infrastructure using ARM template
log_info "Deploying backup infrastructure..."
log_info "This includes: Storage Account, Backup Vault, Backup Policy"

az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "${PROJECT_DIR}/arm-templates/03-backup-infrastructure.json" \
    --parameters "${PROJECT_DIR}/arm-templates/03-backup-infrastructure.parameters.json" \
    --name "backup-infra-deployment-$(date +%Y%m%d%H%M%S)" \
    --output none

log_info "Backup infrastructure deployment completed"

# Get deployment outputs
log_info "Retrieving deployment outputs..."

BACKUP_VAULT_ID=$(az dataprotection backup-vault show \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --query id -o tsv)

BACKUP_VAULT_PRINCIPAL_ID=$(az dataprotection backup-vault show \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --query identity.principalId -o tsv)

STORAGE_ACCOUNT_ID=$(az storage account show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BACKUP_STORAGE_ACCOUNT" \
    --query id -o tsv)

BACKUP_POLICY_ID=$(az dataprotection backup-policy show \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --name "$BACKUP_POLICY_NAME" \
    --query id -o tsv)

# Save outputs
save_to_env "BACKUP_VAULT_ID" "$BACKUP_VAULT_ID"
save_to_env "BACKUP_VAULT_PRINCIPAL_ID" "$BACKUP_VAULT_PRINCIPAL_ID"
save_to_env "STORAGE_ACCOUNT_ID" "$STORAGE_ACCOUNT_ID"
save_to_env "BACKUP_POLICY_ID" "$BACKUP_POLICY_ID"

echo ""
log_info "Step 3 completed successfully!"
echo "  Backup Vault: $BACKUP_VAULT_NAME"
echo "  Storage Account: $BACKUP_STORAGE_ACCOUNT"
echo "  Backup Policy: $BACKUP_POLICY_NAME"
echo "  Backup Vault Principal ID: $BACKUP_VAULT_PRINCIPAL_ID"
echo ""
