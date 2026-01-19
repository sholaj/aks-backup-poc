#!/bin/bash
# AKS Backup PoC - Configuration Variables
# Source this file in other scripts: source ./00-set-variables.sh

set -euo pipefail

# Base configuration
export LOCATION="uksouth"
export PREFIX="aksbkppoc"

# Resource names
export RESOURCE_GROUP="rg-${PREFIX}"
export AKS_CLUSTER_NAME="aks-${PREFIX}"
export BACKUP_VAULT_NAME="bvault-${PREFIX}"
export BACKUP_STORAGE_ACCOUNT="st${PREFIX}backup"
export SNAPSHOT_RG="rg-${PREFIX}-snapshots"
export BACKUP_POLICY_NAME="policy-daily"

# AKS configuration
export KUBERNETES_VERSION="1.29"
export NODE_SIZE="Standard_B2ms"
export NODE_COUNT=1

# Kubernetes namespaces
export APP1_NAMESPACE="at-app1"
export APP2_NAMESPACE="at-app2"

# MySQL configuration
export MYSQL_PASSWORD="P@ssw0rd123!"

# Backup extension
export BACKUP_EXTENSION_NAME="azure-aks-backup"

# Tags
export TAGS="project=aks-backup-poc environment=poc"

# Script directory
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Environment file for storing deployment outputs
export ENV_FILE="${PROJECT_DIR}/.env"

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

wait_for_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-}
    local timeout=${4:-300}

    log_info "Waiting for $resource_type/$resource_name to be ready..."

    if [[ -n "$namespace" ]]; then
        kubectl wait --for=condition=ready "$resource_type/$resource_name" -n "$namespace" --timeout="${timeout}s"
    else
        kubectl wait --for=condition=ready "$resource_type/$resource_name" --timeout="${timeout}s"
    fi
}

save_to_env() {
    local key=$1
    local value=$2

    # Create env file if it doesn't exist
    touch "$ENV_FILE"

    # Remove existing key if present
    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
        sed -i.bak "/^${key}=/d" "$ENV_FILE" && rm -f "${ENV_FILE}.bak"
    fi

    # Add new key-value pair
    echo "${key}=${value}" >> "$ENV_FILE"
    log_info "Saved ${key} to environment file"
}

load_from_env() {
    local key=$1

    if [[ -f "$ENV_FILE" ]]; then
        grep "^${key}=" "$ENV_FILE" | cut -d'=' -f2-
    fi
}

echo "Configuration loaded successfully"
echo "  Location: $LOCATION"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  AKS Cluster: $AKS_CLUSTER_NAME"
echo "  Backup Vault: $BACKUP_VAULT_NAME"
