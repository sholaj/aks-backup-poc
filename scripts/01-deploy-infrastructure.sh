#!/bin/bash
# AKS Backup PoC - Step 1: Deploy Infrastructure (Resource Groups)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-set-variables.sh"

echo "=============================================="
echo "Step 1: Deploy Infrastructure (Resource Groups)"
echo "=============================================="

# Check Azure CLI is authenticated
log_info "Checking Azure CLI authentication..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
log_info "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Create main resource group
log_info "Creating resource group: $RESOURCE_GROUP"
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags $TAGS \
    --output none

log_info "Resource group $RESOURCE_GROUP created successfully"

# Create snapshot resource group for disk snapshots
log_info "Creating snapshot resource group: $SNAPSHOT_RG"
az group create \
    --name "$SNAPSHOT_RG" \
    --location "$LOCATION" \
    --tags $TAGS \
    --output none

log_info "Snapshot resource group $SNAPSHOT_RG created successfully"

# Save outputs
save_to_env "SUBSCRIPTION_ID" "$SUBSCRIPTION_ID"
save_to_env "RESOURCE_GROUP_ID" "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}"
save_to_env "SNAPSHOT_RG_ID" "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${SNAPSHOT_RG}"

echo ""
log_info "Step 1 completed successfully!"
echo "  Main Resource Group: $RESOURCE_GROUP"
echo "  Snapshot Resource Group: $SNAPSHOT_RG"
echo ""
