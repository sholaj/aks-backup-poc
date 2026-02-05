#!/bin/bash
#
# AKS 1.34 Deployment Script
# Deploys the AKS cluster using ARM templates
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default values (can be overridden with environment variables)
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-aks-backup-poc}"
LOCATION="${LOCATION:-uksouth}"
TEMPLATE_FILE="${TEMPLATE_FILE:-$PROJECT_DIR/arm-templates/02-aks-cluster.json}"
PARAMS_FILE="${PARAMS_FILE:-$PROJECT_DIR/arm-templates/02-aks-cluster.parameters.json}"

echo "=============================================="
echo "AKS 1.34 Deployment Script"
echo "=============================================="
echo ""
echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  Template: $TEMPLATE_FILE"
echo "  Parameters: $PARAMS_FILE"
echo ""

# Check Azure CLI login
echo "[INFO] Checking Azure CLI login..."
if ! az account show &>/dev/null; then
    echo "[ERROR] Not logged in to Azure CLI. Run 'az login' first."
    exit 1
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
echo "[INFO] Using subscription: $SUBSCRIPTION"
echo ""

# Confirm before proceeding
read -p "Proceed with deployment? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "[INFO] Deployment cancelled."
    exit 0
fi

# Create resource group if it doesn't exist
echo ""
echo "[INFO] Ensuring resource group exists..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none

echo "[SUCCESS] Resource group ready: $RESOURCE_GROUP"

# Validate template
echo ""
echo "[INFO] Validating ARM template..."
az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$PARAMS_FILE" \
    --output none

echo "[SUCCESS] Template validation passed"

# Deploy
echo ""
echo "[INFO] Deploying AKS cluster (this may take 5-10 minutes)..."
az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$PARAMS_FILE" \
    --output table

echo ""
echo "[SUCCESS] Deployment complete!"

# Get cluster name from parameters
CLUSTER_NAME=$(jq -r '.parameters.clusterName.value' "$PARAMS_FILE")

# Get credentials
echo ""
echo "[INFO] Getting cluster credentials..."
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CLUSTER_NAME" \
    --overwrite-existing

echo "[SUCCESS] kubectl configured for cluster: $CLUSTER_NAME"

# Show cluster info
echo ""
echo "=============================================="
echo "Cluster Info"
echo "=============================================="
kubectl cluster-info
echo ""
kubectl get nodes -o wide

echo ""
echo "=============================================="
echo "Next Steps"
echo "=============================================="
echo "1. Run validation: ./scripts/validate-134.sh"
echo "2. Deploy workloads: kubectl apply -f kubernetes/"
echo "3. Configure backup: ./scripts/setup-backup.sh (if exists)"
echo ""
