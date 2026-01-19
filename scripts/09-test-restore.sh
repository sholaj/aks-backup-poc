#!/bin/bash
# AKS Backup PoC - Step 9: Test Restore

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-set-variables.sh"

echo "=============================================="
echo "Step 9: Test Restore"
echo "=============================================="

# Load required variables
LATEST_RP=$(load_from_env "LATEST_RECOVERY_POINT")
AKS_ID=$(load_from_env "AKS_ID")

if [[ -z "$LATEST_RP" ]]; then
    log_error "LATEST_RECOVERY_POINT not found. Please run step 8 first."
    exit 1
fi

# Get backup instance name
BACKUP_INSTANCE_NAME=$(az dataprotection backup-instance list \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --query "[?contains(name, '${AKS_CLUSTER_NAME}')].name" \
    -o tsv)

log_info "Using recovery point: $LATEST_RP"
log_info "Backup instance: $BACKUP_INSTANCE_NAME"

# Record current state before disaster simulation
log_info "Recording current state before disaster simulation..."
echo ""
echo "=== Current AT-app2 State ==="
kubectl get all -n at-app2

echo ""
echo "=== Current MySQL Data ==="
MYSQL_POD=$(kubectl get pods -n at-app2 -l app.kubernetes.io/name=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n at-app2 "$MYSQL_POD" -- mysql -u root -p"${MYSQL_PASSWORD}" -e "SELECT * FROM testdb.backup_test;"

echo ""
log_warn "=== SIMULATING DISASTER: Deleting AT-app2 namespace ==="
read -p "Press Enter to continue with deletion (Ctrl+C to abort)..."

# Delete the at-app2 namespace
kubectl delete namespace at-app2 --wait=true

log_info "Namespace at-app2 deleted"

# Verify namespace is gone
log_info "Verifying namespace is deleted..."
sleep 5
if kubectl get namespace at-app2 &>/dev/null; then
    log_error "Namespace at-app2 still exists"
    exit 1
fi
log_info "Namespace at-app2 confirmed deleted"

# Initialize restore request
log_info "Initializing restore request..."

az dataprotection backup-instance initialize-restoreconfig \
    --datasource-type AzureKubernetesService \
    --restore-location "$LOCATION" \
    --include-cluster-scope-resources false \
    --included-namespaces at-app2 \
    --conflict-policy Skip \
    --persistent-volume-restore-mode RestoreWithVolumeData \
    > /tmp/restore-config.json

log_info "Restore configuration created"

# Create restore request
log_info "Creating restore request..."

# Get recovery point ID (full resource ID)
RECOVERY_POINT_ID="${BACKUP_INSTANCE_NAME}/recoveryPoints/${LATEST_RP}"

az dataprotection backup-instance restore initialize-for-item-recovery \
    --datasource-type AzureKubernetesService \
    --restore-location "$LOCATION" \
    --source-datastore OperationalStore \
    --backup-instance-id "$BACKUP_INSTANCE_NAME" \
    --recovery-point-id "$LATEST_RP" \
    --restore-configuration /tmp/restore-config.json \
    --target-resource-id "$AKS_ID" \
    > /tmp/restore-request.json

log_info "Restore request created"

# Trigger restore
log_info "Triggering restore..."

az dataprotection backup-instance restore trigger \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --backup-instance-name "$BACKUP_INSTANCE_NAME" \
    --restore-request-object /tmp/restore-request.json \
    --output none

log_info "Restore triggered"

# Poll for restore job completion
log_info "Waiting for restore job to complete..."
log_info "This may take several minutes..."

MAX_RETRIES=60
RETRY_COUNT=0
RESTORE_JOB_ID=""

while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    # Get the latest restore job
    JOBS=$(az dataprotection job list \
        --resource-group "$RESOURCE_GROUP" \
        --vault-name "$BACKUP_VAULT_NAME" \
        --query "[?contains(properties.dataSourceId, '${AKS_CLUSTER_NAME}') && properties.operationCategory=='Restore'] | sort_by(@, &properties.startTime) | [-1]" \
        -o json)

    if [[ "$JOBS" != "null" ]] && [[ -n "$JOBS" ]]; then
        JOB_STATUS=$(echo "$JOBS" | jq -r '.properties.status // "Unknown"')
        RESTORE_JOB_ID=$(echo "$JOBS" | jq -r '.name // ""')

        case "$JOB_STATUS" in
            "Completed")
                log_info "Restore completed successfully!"
                break
                ;;
            "Failed")
                log_error "Restore failed!"
                echo "$JOBS" | jq '.properties.errorInformation'
                exit 1
                ;;
            "Cancelled")
                log_error "Restore was cancelled"
                exit 1
                ;;
            *)
                log_info "Restore status: $JOB_STATUS (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
                ;;
        esac
    else
        log_info "Waiting for restore job to appear..."
    fi

    sleep 30
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
    log_error "Timeout waiting for restore to complete"
    exit 1
fi

save_to_env "RESTORE_JOB_ID" "$RESTORE_JOB_ID"

echo ""
log_info "Step 9 completed successfully!"
echo "  Restore Job ID: $RESTORE_JOB_ID"
echo "  Restored namespace: at-app2"
echo "  Status: Completed"
echo ""
log_info "Proceed to step 10 to validate the restore"
