#!/bin/bash
#
# AKS Cluster Destroy Script
# Destroys the AKS cluster (cattle cluster pattern)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PARAMS_FILE="${PARAMS_FILE:-$PROJECT_DIR/arm-templates/02-aks-cluster.parameters.json}"

# Get values from parameters file
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-aks-backup-poc}"
CLUSTER_NAME=$(jq -r '.parameters.clusterName.value' "$PARAMS_FILE" 2>/dev/null || echo "")

echo "=============================================="
echo "AKS Cluster Destroy Script"
echo "=============================================="
echo ""
echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Cluster Name: $CLUSTER_NAME"
echo ""

# Check if cluster exists
echo "[INFO] Checking for existing cluster..."
EXISTING_CLUSTER=$(az aks list -g "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null || echo "")

if [[ -z "$EXISTING_CLUSTER" ]]; then
    echo "[INFO] No cluster found in resource group $RESOURCE_GROUP"
    echo "[INFO] Nothing to delete."
    exit 0
fi

echo "[INFO] Found cluster: $EXISTING_CLUSTER"
echo ""

# Confirm before proceeding (skip if CI environment)
if [[ -z "${CI:-}" ]]; then
    read -p "Are you sure you want to DELETE this cluster? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "[INFO] Deletion cancelled."
        exit 0
    fi
fi

# Delete cluster
echo ""
echo "[INFO] Deleting AKS cluster: $EXISTING_CLUSTER"
echo "[INFO] This may take several minutes..."

az aks delete \
    --resource-group "$RESOURCE_GROUP" \
    --name "$EXISTING_CLUSTER" \
    --yes \
    --no-wait

echo ""
echo "[SUCCESS] Cluster deletion initiated (running in background)"
echo ""
echo "To check deletion status:"
echo "  az aks list -g $RESOURCE_GROUP -o table"
echo ""
