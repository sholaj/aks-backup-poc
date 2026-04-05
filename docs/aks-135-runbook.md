# AKS 1.35 Operations Runbook

## Overview

This runbook covers operational procedures for AKS clusters running Kubernetes 1.35.

**K8s Version:** 1.35.x "Timbernetes"
**AKS GA Date:** March 2026
**End of Life:** March 2027

---

## Quick Reference

### Version Defaults (K8s 1.35)

| Component | Default |
|-----------|---------|
| Ubuntu | 24.04 LTS |
| Azure Linux | 3.0 |
| Containerd | 2.x (1.x no longer supported after 1.35) |
| Cgroup | v2 (v1 removed) |
| Cgroup Driver | systemd (auto-detected) |

### Key Commands

```bash
# Check cluster version
kubectl version

# Check node details
kubectl get nodes -o wide

# Detailed node info
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.osImage}{"\t"}{.status.nodeInfo.containerRuntimeVersion}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'

# Check system pods
kubectl get pods -n kube-system

# Verify cgroup v2 (critical for 1.35)
kubectl debug node/<node-name> -it --image=busybox -- stat -fc %T /sys/fs/cgroup
# Expected: cgroup2fs
```

---

## Cluster Provisioning

### Deploy New Cluster

```bash
# Using provided scripts
./scripts/deploy-135.sh

# Or manually with Azure CLI
az aks create \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --kubernetes-version 1.35 \
  --node-vm-size Standard_B2ms \
  --node-count 1 \
  --enable-oidc-issuer \
  --enable-workload-identity
```

### Validate Deployment

```bash
# Run validation script
./scripts/validate-135.sh

# Manual checks
kubectl version --short
kubectl get nodes
kubectl get pods -A
```

### ARM Template Parameters

```json
{
  "kubernetesVersion": "1.35",
  "osSKU": "Ubuntu"
}
```

---

## Node Pool Management

### Check Node Image Version

```bash
az aks nodepool show \
  -g $RG \
  --cluster-name $CLUSTER \
  -n $NODEPOOL \
  --query nodeImageVersion
```

### Upgrade Node Image

```bash
az aks nodepool upgrade \
  -g $RG \
  --cluster-name $CLUSTER \
  -n $NODEPOOL \
  --node-image-only
```

### Node OS Details

| OS SKU | K8s 1.35 Default | Containerd | cgroup |
|--------|------------------|------------|--------|
| Ubuntu | Ubuntu 24.04 | 2.x | v2 |
| AzureLinux | Azure Linux 3.0 | 2.x | v2 |

### Azure Linux 2.0 End of Life
Azure Linux 2.0 node images were removed March 31, 2026. Any remaining AL2 node pools must migrate to AzureLinux 3.0:

```bash
# Check node OS
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.osImage}{"\n"}{end}'

# If Azure Linux 2.0 found, migrate node pool
az aks nodepool upgrade \
  -g $RG \
  --cluster-name $CLUSTER \
  -n $NODEPOOL \
  --os-sku AzureLinux
```

---

## Troubleshooting

### Common Issues

#### 1. Node Not Ready

```bash
# Check node conditions
kubectl describe node <node-name>

# Check kubelet logs (via node debug)
kubectl debug node/<node-name> -it --image=busybox

# Check for resource pressure
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

#### 2. Pod Scheduling Issues

```bash
# Check pending pods
kubectl get pods -A --field-selector=status.phase=Pending

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check scheduler logs
kubectl logs -n kube-system -l component=kube-scheduler
```

#### 3. DNS Resolution

```bash
# Test DNS
kubectl run dns-test --image=busybox:1.36 --rm -it --restart=Never -- nslookup kubernetes.default

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

#### 4. Storage Issues

```bash
# Check PVC status
kubectl get pvc -A

# Check CSI driver
kubectl get csidrivers

# Check storage classes
kubectl get storageclass
```

### 1.35-Specific Diagnostics

```bash
# Verify cgroup v2 (CRITICAL — cgroup v1 removed in 1.35)
kubectl debug node/<node-name> -it --image=busybox -- stat -fc %T /sys/fs/cgroup
# Expected: cgroup2fs
# If tmpfs → cgroup v1 → node will NOT work with K8s 1.35

# Verify containerd 2.x
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
# Expected: containerd://2.x.x

# Verify Ubuntu 24.04 or Azure Linux 3.0
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.osImage}'

# Check for deprecated API usage
kubectl get --raw /metrics | grep apiserver_requested_deprecated_apis

# Check WebSocket RBAC (kubectl exec should work with proper perms)
kubectl auth can-i create pods/exec --as=system:serviceaccount:default:default
```

---

## Upgrade Procedures

### Pre-Upgrade Checklist

- [ ] Review [AKS 1.35 release notes](https://github.com/Azure/AKS/releases)
- [ ] Run API compatibility scan (pluto)
- [ ] Verify all nodes are on cgroup v2
- [ ] Verify containerd 2.x on all nodes
- [ ] Verify no Azure Linux 2.0 node pools remain
- [ ] Audit RBAC for WebSocket operations (exec/attach/port-forward)
- [ ] Backup critical workloads
- [ ] Test upgrade in non-prod first
- [ ] Schedule maintenance window

### Upgrade from 1.34 to 1.35

```bash
# Check available upgrades
az aks get-upgrades -g $RG -n $CLUSTER -o table

# Upgrade control plane
az aks upgrade \
  -g $RG \
  -n $CLUSTER \
  --kubernetes-version 1.35

# Upgrade node pools
az aks nodepool upgrade \
  -g $RG \
  --cluster-name $CLUSTER \
  -n $NODEPOOL \
  --kubernetes-version 1.35
```

### Post-Upgrade Validation

```bash
# Verify version
kubectl version

# Check all nodes upgraded
kubectl get nodes

# Verify cgroup v2 on all nodes
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  echo -n "$node: "
  kubectl debug "node/$node" -it --image=busybox -- stat -fc %T /sys/fs/cgroup 2>/dev/null
done

# Verify workloads
kubectl get pods -A

# Run validation script
./scripts/validate-135.sh
```

### Rollback (if needed)

AKS does not support direct version rollback. Options:
1. Restore from backup
2. Recreate cluster on previous version
3. Contact Azure support for assistance

---

## Cattle Cluster Operations

### Daily Rebuild Pattern

```bash
# Destroy cluster (evening)
./scripts/destroy-cluster.sh

# Create cluster (morning)
./scripts/deploy-135.sh

# Validate
./scripts/validate-135.sh
```

### CI/CD Schedule

| Job | Cron | Description |
|-----|------|-------------|
| Destroy | `0 22 * * 1-5` | 10 PM Mon-Fri |
| Create | `0 6 * * 1-5` | 6 AM Mon-Fri |

---

## Monitoring

### Key Metrics to Watch

| Metric | Source | Alert Threshold |
|--------|--------|-----------------|
| Node CPU | Azure Monitor | > 80% |
| Node Memory | Azure Monitor | > 85% |
| Pod restarts | Prometheus | > 5/hour |
| API latency | kube-apiserver | > 500ms p99 |

### Health Check Commands

```bash
# Cluster health
kubectl get componentstatuses

# Node health
kubectl top nodes

# Pod health
kubectl top pods -A

# Events
kubectl get events -A --sort-by='.lastTimestamp'
```

---

## References

- [AKS Release Notes](https://github.com/Azure/AKS/releases)
- [Kubernetes 1.35 Changelog](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.35.md)
- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
