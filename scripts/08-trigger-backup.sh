#!/bin/bash
# AKS Backup PoC - Step 8: Trigger Backup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-set-variables.sh"

echo "=============================================="
echo "Step 8: Trigger On-Demand Backup"
echo "=============================================="

# Load required variables
BACKUP_INSTANCE_ID=$(load_from_env "BACKUP_INSTANCE_ID")

if [[ -z "$BACKUP_INSTANCE_ID" ]]; then
    log_error "BACKUP_INSTANCE_ID not found. Please run step 7 first."
    exit 1
fi

# Get backup instance name from the list
log_info "Getting backup instance details..."
BACKUP_INSTANCE_NAME=$(az dataprotection backup-instance list \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --query "[?contains(name, '${AKS_CLUSTER_NAME}')].name" \
    -o tsv)

if [[ -z "$BACKUP_INSTANCE_NAME" ]]; then
    log_error "Could not find backup instance"
    exit 1
fi

log_info "Backup instance: $BACKUP_INSTANCE_NAME"

# Verify MySQL data before backup
log_info "Verifying MySQL data before backup..."
MYSQL_POD=$(kubectl get pods -n at-app2 -l app.kubernetes.io/name=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n at-app2 "$MYSQL_POD" -- mysql -u root -p"${MYSQL_PASSWORD}" -e "SELECT * FROM testdb.backup_test;"

# Trigger on-demand backup
log_info "Triggering on-demand backup..."
BACKUP_RULE_NAME="BackupDaily"

az dataprotection backup-instance adhoc-backup \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --backup-instance-name "$BACKUP_INSTANCE_NAME" \
    --rule-name "$BACKUP_RULE_NAME" \
    --retention-tag-override Default \
    --output none

log_info "On-demand backup triggered"

# Poll for backup job completion
log_info "Waiting for backup job to complete..."
log_info "This may take several minutes..."

MAX_RETRIES=60
RETRY_COUNT=0
BACKUP_JOB_ID=""

while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    # Get the latest backup job
    JOBS=$(az dataprotection job list \
        --resource-group "$RESOURCE_GROUP" \
        --vault-name "$BACKUP_VAULT_NAME" \
        --query "[?contains(properties.dataSourceId, '${AKS_CLUSTER_NAME}') && properties.operationCategory=='Backup'] | sort_by(@, &properties.startTime) | [-1]" \
        -o json)

    if [[ "$JOBS" != "null" ]] && [[ -n "$JOBS" ]]; then
        JOB_STATUS=$(echo "$JOBS" | jq -r '.properties.status // "Unknown"')
        BACKUP_JOB_ID=$(echo "$JOBS" | jq -r '.name // ""')

        case "$JOB_STATUS" in
            "Completed")
                log_info "Backup completed successfully!"
                break
                ;;
            "Failed")
                log_error "Backup failed!"
                echo "$JOBS" | jq '.properties.errorInformation'
                exit 1
                ;;
            "Cancelled")
                log_error "Backup was cancelled"
                exit 1
                ;;
            *)
                log_info "Backup status: $JOB_STATUS (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
                ;;
        esac
    else
        log_info "Waiting for backup job to appear..."
    fi

    sleep 30
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
    log_error "Timeout waiting for backup to complete"
    exit 1
fi

# List recovery points
log_info "Listing recovery points..."
sleep 10

az dataprotection recovery-point list \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --backup-instance-name "$BACKUP_INSTANCE_NAME" \
    --query "[].{Name:name, Time:properties.recoveryPointTime, Type:properties.recoveryPointType}" \
    -o table

# Get the latest recovery point
LATEST_RP=$(az dataprotection recovery-point list \
    --resource-group "$RESOURCE_GROUP" \
    --vault-name "$BACKUP_VAULT_NAME" \
    --backup-instance-name "$BACKUP_INSTANCE_NAME" \
    --query "[0].name" \
    -o tsv)

save_to_env "LATEST_RECOVERY_POINT" "$LATEST_RP"
save_to_env "BACKUP_JOB_ID" "$BACKUP_JOB_ID"

echo ""
log_info "Step 8 completed successfully!"
echo "  Backup Job ID: $BACKUP_JOB_ID"
echo "  Latest Recovery Point: $LATEST_RP"
echo "  Status: Completed"
echo ""
