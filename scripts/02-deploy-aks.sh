#!/bin/bash
# AKS Backup PoC - Step 2: Deploy AKS Cluster

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-set-variables.sh"

echo "=============================================="
echo "Step 2: Deploy AKS Cluster"
echo "=============================================="

# Deploy AKS cluster using ARM template
log_info "Deploying AKS cluster: $AKS_CLUSTER_NAME"
log_info "This may take 5-10 minutes..."

az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "${PROJECT_DIR}/arm-templates/02-aks-cluster.json" \
    --parameters "${PROJECT_DIR}/arm-templates/02-aks-cluster.parameters.json" \
    --name "aks-deployment-$(date +%Y%m%d%H%M%S)" \
    --output none

log_info "AKS deployment completed"

# Get cluster details
log_info "Retrieving cluster details..."
AKS_ID=$(az aks show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER_NAME" \
    --query id -o tsv)

AKS_PRINCIPAL_ID=$(az aks show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER_NAME" \
    --query identity.principalId -o tsv)

OIDC_ISSUER=$(az aks show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER_NAME" \
    --query oidcIssuerProfile.issuerUrl -o tsv)

# Get AKS credentials
log_info "Getting AKS credentials..."
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER_NAME" \
    --overwrite-existing

# Verify cluster is accessible
log_info "Verifying cluster access..."
kubectl get nodes

# Verify storage classes
log_info "Checking storage classes..."
kubectl get storageclass

# Save outputs
save_to_env "AKS_ID" "$AKS_ID"
save_to_env "AKS_PRINCIPAL_ID" "$AKS_PRINCIPAL_ID"
save_to_env "OIDC_ISSUER" "$OIDC_ISSUER"

echo ""
log_info "Step 2 completed successfully!"
echo "  AKS Cluster: $AKS_CLUSTER_NAME"
echo "  AKS ID: $AKS_ID"
echo "  Kubernetes context configured"
echo ""
