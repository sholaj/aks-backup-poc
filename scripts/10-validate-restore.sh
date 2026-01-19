#!/bin/bash
# AKS Backup PoC - Step 10: Validate Restore

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-set-variables.sh"

echo "=============================================="
echo "Step 10: Validate Restore"
echo "=============================================="

VALIDATION_PASSED=true

# Check 1: Verify AT-app2 namespace exists
log_info "Checking if at-app2 namespace exists..."
if kubectl get namespace at-app2 &>/dev/null; then
    echo "  ✅ Namespace at-app2 exists"
else
    echo "  ❌ Namespace at-app2 does not exist"
    VALIDATION_PASSED=false
fi

# Check 2: Verify PVC is bound
log_info "Checking if PVC is bound..."
PVC_STATUS=$(kubectl get pvc mysql-pvc -n at-app2 -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
if [[ "$PVC_STATUS" == "Bound" ]]; then
    echo "  ✅ PVC mysql-pvc is Bound"
else
    echo "  ❌ PVC status: $PVC_STATUS"
    VALIDATION_PASSED=false
fi

# Check 3: Verify MySQL pod is running
log_info "Checking if MySQL pod is running..."
sleep 30  # Give pods time to start

MYSQL_POD=$(kubectl get pods -n at-app2 -l app.kubernetes.io/name=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [[ -n "$MYSQL_POD" ]]; then
    POD_STATUS=$(kubectl get pod "$MYSQL_POD" -n at-app2 -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    if [[ "$POD_STATUS" == "Running" ]]; then
        echo "  ✅ MySQL pod $MYSQL_POD is Running"
    else
        echo "  ⏳ MySQL pod status: $POD_STATUS (may still be starting)"
        log_info "Waiting for MySQL pod to be ready..."
        kubectl wait --for=condition=ready pod/"$MYSQL_POD" -n at-app2 --timeout=300s || VALIDATION_PASSED=false
    fi
else
    echo "  ❌ MySQL pod not found"
    VALIDATION_PASSED=false
fi

# Check 4: Verify MySQL is accessible
if [[ -n "$MYSQL_POD" ]] && [[ "$VALIDATION_PASSED" == "true" ]]; then
    log_info "Checking MySQL accessibility..."
    sleep 30  # Extra time for MySQL to initialize

    if kubectl exec -n at-app2 "$MYSQL_POD" -- mysqladmin ping -h localhost -u root -p"${MYSQL_PASSWORD}" &>/dev/null; then
        echo "  ✅ MySQL is accessible"
    else
        echo "  ⏳ MySQL not ready yet, waiting..."
        sleep 60
        if kubectl exec -n at-app2 "$MYSQL_POD" -- mysqladmin ping -h localhost -u root -p"${MYSQL_PASSWORD}" &>/dev/null; then
            echo "  ✅ MySQL is now accessible"
        else
            echo "  ❌ MySQL is not accessible"
            VALIDATION_PASSED=false
        fi
    fi
fi

# Check 5: Verify sample data exists
if [[ -n "$MYSQL_POD" ]] && [[ "$VALIDATION_PASSED" == "true" ]]; then
    log_info "Checking if sample data was restored..."

    DATA_COUNT=$(kubectl exec -n at-app2 "$MYSQL_POD" -- mysql -u root -p"${MYSQL_PASSWORD}" -N -e "SELECT COUNT(*) FROM testdb.backup_test WHERE backup_marker='ORIGINAL_DATA';" 2>/dev/null || echo "0")

    if [[ "$DATA_COUNT" -eq "3" ]]; then
        echo "  ✅ All 3 original records found"
    elif [[ "$DATA_COUNT" -gt "0" ]]; then
        echo "  ⚠️  Found $DATA_COUNT records (expected 3)"
    else
        echo "  ❌ No original records found"
        VALIDATION_PASSED=false
    fi

    # Display the restored data
    echo ""
    echo "=== Restored MySQL Data ==="
    kubectl exec -n at-app2 "$MYSQL_POD" -- mysql -u root -p"${MYSQL_PASSWORD}" -e "SELECT * FROM testdb.backup_test;" 2>/dev/null || true
fi

# Check 6: Verify all resources in namespace
log_info "Listing all restored resources in at-app2..."
echo ""
kubectl get all -n at-app2

# Summary
echo ""
echo "=============================================="
echo "VALIDATION SUMMARY"
echo "=============================================="

if [[ "$VALIDATION_PASSED" == "true" ]]; then
    echo ""
    log_info "🎉 ALL VALIDATION CHECKS PASSED!"
    echo ""
    echo "  ✅ Namespace: at-app2 restored"
    echo "  ✅ PVC: mysql-pvc bound with data"
    echo "  ✅ MySQL: Running and accessible"
    echo "  ✅ Data: Original records preserved"
    echo ""
    echo "The AKS Backup PoC was successful!"
    echo ""
else
    echo ""
    log_error "❌ SOME VALIDATION CHECKS FAILED"
    echo ""
    echo "Please review the output above to identify issues."
    echo ""
    exit 1
fi
