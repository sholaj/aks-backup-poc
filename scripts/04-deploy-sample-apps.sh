#!/bin/bash
# AKS Backup PoC - Step 4: Deploy Sample Applications

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-set-variables.sh"

echo "=============================================="
echo "Step 4: Deploy Sample Applications"
echo "=============================================="

# Apply namespaces
log_info "Creating namespaces..."
kubectl apply -f "${PROJECT_DIR}/kubernetes/namespaces.yaml"

# Deploy AT-app1 (nginx)
log_info "Deploying AT-app1 (nginx stateless application)..."
kubectl apply -f "${PROJECT_DIR}/kubernetes/AT-app1/"

# Deploy AT-app2 (MySQL)
log_info "Deploying AT-app2 (MySQL stateful application)..."
kubectl apply -f "${PROJECT_DIR}/kubernetes/AT-app2/"

# Wait for nginx pods to be ready
log_info "Waiting for nginx pods to be ready..."
kubectl rollout status deployment/nginx -n at-app1 --timeout=120s

# Wait for MySQL pod to be ready
log_info "Waiting for MySQL pod to be ready (this may take a few minutes)..."
kubectl rollout status deployment/mysql -n at-app2 --timeout=300s

# Verify pods are running
log_info "Verifying all pods are running..."
echo ""
echo "AT-app1 (nginx):"
kubectl get pods -n at-app1
echo ""
echo "AT-app2 (MySQL):"
kubectl get pods -n at-app2

# Verify PVC is bound
log_info "Verifying PVC is bound..."
kubectl get pvc -n at-app2

# Wait a bit more for MySQL to fully initialize
log_info "Waiting for MySQL to initialize..."
sleep 30

# Insert sample data into MySQL
log_info "Inserting sample data into MySQL..."
MYSQL_POD=$(kubectl get pods -n at-app2 -l app.kubernetes.io/name=mysql -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n at-app2 "$MYSQL_POD" -- mysql -u root -p"${MYSQL_PASSWORD}" -e "
    CREATE DATABASE IF NOT EXISTS testdb;
    USE testdb;
    CREATE TABLE IF NOT EXISTS backup_test (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        backup_marker VARCHAR(255)
    );
    INSERT INTO backup_test (name, backup_marker) VALUES
        ('Record 1', 'ORIGINAL_DATA'),
        ('Record 2', 'ORIGINAL_DATA'),
        ('Record 3', 'ORIGINAL_DATA');
    SELECT * FROM backup_test;
"

log_info "Sample data inserted successfully"

# Verify MySQL is accessible and data exists
log_info "Verifying MySQL data..."
kubectl exec -n at-app2 "$MYSQL_POD" -- mysql -u root -p"${MYSQL_PASSWORD}" -e "SELECT COUNT(*) as record_count FROM testdb.backup_test;"

# Save pod name for later use
save_to_env "MYSQL_POD" "$MYSQL_POD"

echo ""
log_info "Step 4 completed successfully!"
echo "  Nginx deployment: 2 replicas running in at-app1"
echo "  MySQL deployment: 1 replica with PVC in at-app2"
echo "  Sample data: 3 records in testdb.backup_test"
echo ""
