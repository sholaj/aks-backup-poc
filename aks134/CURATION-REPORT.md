# AKS 1.34 Curation Report

**Date:** 2026-02-05
**Curation Target:** AKS 1.34 (GA: 2026-01-04)
**Repository:** aks-backup-poc

---

## Executive Summary

The aks-backup-poc repository has been assessed for AKS 1.34 compatibility. **The codebase is clean** with no deprecated APIs or annotations requiring remediation. ARM templates have been updated to target K8s 1.34.

---

## Curation Results

### API Compatibility Scan

| Resource | File | API Version | Status |
|----------|------|-------------|--------|
| Namespace | `kubernetes/namespaces.yaml` | `v1` | ✅ GA |
| Deployment (nginx) | `kubernetes/AT-app1/deployment.yaml` | `apps/v1` | ✅ GA |
| Service (nginx) | `kubernetes/AT-app1/service.yaml` | `v1` | ✅ GA |
| Deployment (mysql) | `kubernetes/AT-app2/mysql-deployment.yaml` | `apps/v1` | ✅ GA |
| Service (mysql) | `kubernetes/AT-app2/mysql-service.yaml` | `v1` | ✅ GA |
| PVC | `kubernetes/AT-app2/mysql-pvc.yaml` | `v1` | ✅ GA |
| Secret | `kubernetes/AT-app2/mysql-secret.yaml` | `v1` | ✅ GA |
| BackupHook | `kubernetes/hooks/backup-hooks.yaml` | `clusterbackup.dataprotection.microsoft.com/v1alpha1` | Azure CRD |
| RestoreHook | `kubernetes/hooks/restore-hooks.yaml` | `clusterbackup.dataprotection.microsoft.com/v1alpha1` | Azure CRD |

**Result:** No deprecated or removed APIs found. All resources use stable GA versions.

---

### Deprecation Checks

#### AppArmor Annotations
```
Scan: kubernetes/**/*.yaml
Found: 0 occurrences
Action: None required
```

#### Service Topology Annotations
```
Scan: kubernetes/**/*.yaml
Found: 0 occurrences
Action: None required
```

#### Cgroup Driver Configuration
```
Scan: arm-templates/*.json
Found: 0 explicit configurations
Action: None required (auto-detection is the default)
```

---

### ARM Template Updates

#### Changes Made

| File | Change | Before | After |
|------|--------|--------|-------|
| `02-aks-cluster.json` | Default K8s version | `1.29` | `1.34` |
| `02-aks-cluster.json` | ARM API version | `2024-01-01` | `2025-01-01` |
| `02-aks-cluster.parameters.json` | K8s version param | `1.33` | `1.34` |

#### Template Configuration Review

| Setting | Value | K8s 1.34 Impact |
|---------|-------|-----------------|
| `osSKU` | `Ubuntu` | Will use Ubuntu 24.04 (1.34 default) |
| `networkPlugin` | `azure` | Compatible |
| `networkPluginMode` | `overlay` | Compatible |
| No explicit `cgroupDriver` | N/A | Auto-detection (correct for 1.34) |

---

## Ticket Status Summary

| # | Ticket | Status | Notes |
|---|--------|--------|-------|
| 01 | Release Notes Review | ✅ Complete | Spike completed |
| 02 | AppArmor Migration | ✅ Complete | No AppArmor usage in repo |
| 03 | Cgroup Driver Cleanup | ✅ Complete | No manual configs found |
| 04 | Service Topology Annotations | ✅ Complete | No annotations found |
| 05 | Containerd Version Assessment | ✅ Complete | ARM templates updated |
| 06 | DRA Evaluation | 🔲 Pending | Evaluate if GPU workloads needed |
| 07 | VolumeAttributesClass Testing | 🔲 Pending | Test with CSI driver |
| 08 | ServiceAccount Image Pull | 🔲 Pending | Review for container registries |
| 09 | Non-Production Upgrade Testing | 🔲 Pending | Deploy and validate |
| 10 | API Compatibility Validation | ✅ Complete | Clean scan |
| 11 | Runbook Updates | 🔲 Pending | |
| 12 | Developer Migration Guide | 🔲 Pending | |
| 13 | OpenTelemetry Evaluation | 🔲 Pending | Optional |
| 14 | Cattle Cluster Daily Rebuild | 🔲 Pending | Pipeline updates needed |

---

## Next Steps

### Immediate Actions
1. **Deploy test cluster** on K8s 1.34 using updated ARM templates
2. **Validate** all workloads deploy successfully
3. **Verify** Azure Backup hooks work with 1.34

### Phase 2: Feature Evaluation
- Evaluate DRA if GPU workloads are planned
- Test VolumeAttributesClass for dynamic volume modifications
- Review ServiceAccount token image pull for private registries

### Phase 3: Documentation
- Update runbooks with 1.34-specific procedures
- Create developer migration guide (minimal changes needed)

---

## Risk Assessment

| Risk | Level | Rationale |
|------|-------|-----------|
| API Breaking Changes | **Low** | No deprecated APIs in use |
| OS Image Compatibility | **Low** | Ubuntu 24.04 is well-tested |
| Containerd Compatibility | **Low** | Using OS defaults (containerd 2.x) |
| Workload Disruption | **Low** | No changes required to manifests |

---

## Validation Commands

```bash
# Deploy cluster with updated templates
az deployment group create \
  --resource-group rg-aks-backup-poc \
  --template-file arm-templates/02-aks-cluster.json \
  --parameters arm-templates/02-aks-cluster.parameters.json

# Verify K8s version
kubectl version --short

# Verify node OS
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.osImage}'

# Verify containerd version
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'

# Deploy workloads
kubectl apply -f kubernetes/namespaces.yaml
kubectl apply -f kubernetes/AT-app1/
kubectl apply -f kubernetes/AT-app2/

# Verify all pods running
kubectl get pods -A
```

---

**Curation completed by:** Claude Code
**Review date:** 2026-02-05
