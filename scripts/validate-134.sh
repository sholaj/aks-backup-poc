#!/bin/bash
#
# AKS 1.34 Validation Script
# Run this after deploying a K8s 1.34 cluster to validate compatibility
#
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN_COUNT++))
}

log_info() {
    echo -e "[INFO] $1"
}

echo "=============================================="
echo "AKS 1.34 Validation Script"
echo "=============================================="
echo ""

# Check kubectl connectivity
log_info "Checking kubectl connectivity..."
if kubectl cluster-info &>/dev/null; then
    log_pass "kubectl connected to cluster"
else
    log_fail "kubectl cannot connect to cluster"
    exit 1
fi

echo ""
echo "=== 1. Kubernetes Version ==="

# Check K8s version
K8S_VERSION=$(kubectl version -o json 2>/dev/null | jq -r '.serverVersion.gitVersion' || echo "unknown")
log_info "Server version: $K8S_VERSION"

if [[ "$K8S_VERSION" == *"1.34"* ]]; then
    log_pass "Kubernetes version is 1.34.x"
else
    log_warn "Kubernetes version is not 1.34.x (found: $K8S_VERSION)"
fi

echo ""
echo "=== 2. Node Status ==="

# Check node status
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || echo "0")

log_info "Total nodes: $NODE_COUNT"
log_info "Ready nodes: $READY_NODES"

if [[ "$NODE_COUNT" -eq "$READY_NODES" ]] && [[ "$NODE_COUNT" -gt 0 ]]; then
    log_pass "All nodes are Ready"
else
    log_fail "Not all nodes are Ready"
fi

# Check node OS and containerd
log_info "Node details:"
kubectl get nodes -o custom-columns=NAME:.metadata.name,OS:.status.nodeInfo.osImage,RUNTIME:.status.nodeInfo.containerRuntimeVersion,KUBELET:.status.nodeInfo.kubeletVersion

OS_IMAGE=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.osImage}' 2>/dev/null || echo "unknown")
CONTAINERD=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.containerRuntimeVersion}' 2>/dev/null || echo "unknown")

if [[ "$OS_IMAGE" == *"Ubuntu 24.04"* ]] || [[ "$OS_IMAGE" == *"Azure Linux"* ]] || [[ "$OS_IMAGE" == *"CBL-Mariner"* ]]; then
    log_pass "Node OS is compatible ($OS_IMAGE)"
else
    log_warn "Node OS may not be the 1.34 default ($OS_IMAGE)"
fi

if [[ "$CONTAINERD" == *"containerd://2."* ]]; then
    log_pass "Containerd version is 2.x ($CONTAINERD)"
else
    log_warn "Containerd version may not be 2.x ($CONTAINERD)"
fi

echo ""
echo "=== 3. System Components ==="

# Check system pods
SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l | tr -d ' ')
RUNNING_SYSTEM=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c "Running" || echo "0")

log_info "System pods: $SYSTEM_PODS total, $RUNNING_SYSTEM running"

if [[ "$RUNNING_SYSTEM" -gt 0 ]]; then
    log_pass "System pods are running"
else
    log_fail "No system pods running"
fi

# Check CoreDNS
if kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep -q "Running"; then
    log_pass "CoreDNS is running"
else
    log_fail "CoreDNS is not running"
fi

echo ""
echo "=== 4. Storage ==="

# Check CSI drivers
if kubectl get csidrivers disk.csi.azure.com &>/dev/null; then
    log_pass "Azure Disk CSI driver installed"
else
    log_warn "Azure Disk CSI driver not found"
fi

if kubectl get storageclass managed-csi &>/dev/null; then
    log_pass "managed-csi StorageClass available"
else
    log_warn "managed-csi StorageClass not found"
fi

echo ""
echo "=== 5. Workload Deployment Test ==="

# Deploy test workloads if manifests exist
MANIFEST_DIR="$(dirname "$0")/../kubernetes"

if [[ -d "$MANIFEST_DIR" ]]; then
    log_info "Deploying test workloads from $MANIFEST_DIR..."

    # Apply namespaces
    if [[ -f "$MANIFEST_DIR/namespaces.yaml" ]]; then
        kubectl apply -f "$MANIFEST_DIR/namespaces.yaml" &>/dev/null && log_pass "Namespaces created" || log_fail "Failed to create namespaces"
    fi

    # Apply AT-app1 (nginx)
    if [[ -d "$MANIFEST_DIR/AT-app1" ]]; then
        kubectl apply -f "$MANIFEST_DIR/AT-app1/" &>/dev/null && log_pass "AT-app1 (nginx) deployed" || log_fail "Failed to deploy AT-app1"
    fi

    # Apply AT-app2 (mysql)
    if [[ -d "$MANIFEST_DIR/AT-app2" ]]; then
        kubectl apply -f "$MANIFEST_DIR/AT-app2/" &>/dev/null && log_pass "AT-app2 (mysql) deployed" || log_fail "Failed to deploy AT-app2"
    fi

    # Wait for pods
    log_info "Waiting for pods to be ready (60s timeout)..."
    sleep 10

    # Check nginx
    if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=nginx -n at-app1 --timeout=60s &>/dev/null; then
        log_pass "nginx pod is ready"
    else
        log_warn "nginx pod not ready within timeout"
    fi

    # Check mysql (takes longer)
    if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mysql -n at-app2 --timeout=120s &>/dev/null; then
        log_pass "mysql pod is ready"
    else
        log_warn "mysql pod not ready within timeout"
    fi
else
    log_warn "Manifest directory not found, skipping workload deployment"
fi

echo ""
echo "=== 6. DNS Resolution Test ==="

# Test DNS resolution
if kubectl run dns-test --image=busybox:1.36 --rm -it --restart=Never --command -- nslookup kubernetes.default &>/dev/null; then
    log_pass "DNS resolution working"
else
    log_warn "DNS resolution test inconclusive"
fi

echo ""
echo "=== 7. PVC Test ==="

# Check if PVCs are bound
PVC_COUNT=$(kubectl get pvc -A --no-headers 2>/dev/null | wc -l | tr -d ' ')
BOUND_PVC=$(kubectl get pvc -A --no-headers 2>/dev/null | grep -c "Bound" || echo "0")

if [[ "$PVC_COUNT" -gt 0 ]]; then
    log_info "PVCs: $PVC_COUNT total, $BOUND_PVC bound"
    if [[ "$BOUND_PVC" -eq "$PVC_COUNT" ]]; then
        log_pass "All PVCs are bound"
    else
        log_warn "Not all PVCs are bound"
    fi
else
    log_info "No PVCs found (expected if workloads not deployed)"
fi

echo ""
echo "=============================================="
echo "Validation Summary"
echo "=============================================="
echo -e "${GREEN}PASSED:${NC} $PASS_COUNT"
echo -e "${RED}FAILED:${NC} $FAIL_COUNT"
echo -e "${YELLOW}WARNINGS:${NC} $WARN_COUNT"
echo ""

if [[ "$FAIL_COUNT" -eq 0 ]]; then
    echo -e "${GREEN}AKS 1.34 validation PASSED${NC}"
    exit 0
else
    echo -e "${RED}AKS 1.34 validation has FAILURES${NC}"
    exit 1
fi
