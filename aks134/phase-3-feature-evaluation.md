# Phase 3: Feature Evaluation

**Status:** ✅ COMPLETE
**Completed:** 2026-02-05

---

## Scope

Evaluate new K8s 1.34 GA features for potential adoption.

| Feature | Priority | Decision |
|---------|----------|----------|
| DRA (Dynamic Resource Allocation) | Medium | ⏸️ DEFER - No GPU workloads |
| VolumeAttributesClass | Medium | ⏸️ DEFER - Not needed for PoC |
| ServiceAccount Token Image Pull | Low | ⏸️ DEFER - Using public images |

---

## 1. Dynamic Resource Allocation (DRA)

### Overview
DRA (KEP-4381) provides standardized allocation of specialized hardware like GPUs, FPGAs, and NICs.

### Evaluation Criteria
| Question | This Repo |
|----------|-----------|
| Do any workloads use GPUs? | ❌ No - nginx and mysql only |
| Are there FPGAs or specialized NICs? | ❌ No |
| Node VM size | Standard_B2ms (no GPU) |
| Is multi-tenant GPU sharing needed? | ❌ No |

### Decision: ⏸️ DEFER

**Rationale:** This is a backup PoC repository with no GPU workloads. Node pools use Standard_B2ms VMs which don't support GPU. DRA provides no benefit for the current use case.

**Revisit when:**
- GPU node pools are added
- AI/ML workloads are introduced
- Multi-tenant GPU sharing is needed

### Status
- [x] GPU usage survey completed - **None**
- [x] Technical feasibility assessed - **N/A for this repo**
- [x] Recommendation documented - **DEFER**

---

## 2. VolumeAttributesClass

### Overview
VolumeAttributesClass (KEP-3751) allows modifying volume parameters (IOPS, throughput) without recreating PVCs.

### Current Storage Configuration
```yaml
# kubernetes/AT-app2/mysql-pvc.yaml
storageClassName: managed-csi
storage: 5Gi
```

### Evaluation
| Question | This Repo |
|----------|-----------|
| Storage class in use | managed-csi (Azure Disk) |
| Dynamic IOPS tuning needed? | ❌ No - PoC workload |
| Cost optimization needed? | ❌ No - minimal storage |
| Azure Disk CSI support | ✅ Supported in 1.34 |

### Decision: ⏸️ DEFER

**Rationale:** The backup PoC uses a simple 5Gi PVC with default managed-csi settings. Dynamic volume attribute modification adds complexity without benefit for this use case.

**Potential future use:**
- Production databases needing IOPS scaling
- Cost optimization for dev/prod storage tiers
- Workloads with variable performance requirements

### Example for Future Reference
```yaml
# When needed, create VolumeAttributesClass
apiVersion: storage.k8s.io/v1
kind: VolumeAttributesClass
metadata:
  name: premium-iops
driverName: disk.csi.azure.com
parameters:
  skuName: PremiumV2_LRS
  DiskIOPSReadWrite: "5000"
  DiskMBpsReadWrite: "200"
```

### Status
- [x] CSI driver compatibility verified - **Azure Disk CSI supports VAC**
- [x] Test completed - **Deferred - not needed for PoC**
- [x] Recommendation documented - **DEFER**

---

## 3. ServiceAccount Token Image Pull

### Overview
Allows using ServiceAccount tokens for authenticating to container registries without storing credentials as secrets.

### Current Configuration
```json
// ARM template - Workload Identity enabled
"securityProfile": {
  "workloadIdentity": {
    "enabled": true
  }
}
```

### Images in Use
| Workload | Image | Registry |
|----------|-------|----------|
| nginx | nginx:1.25-alpine | Docker Hub (public) |
| mysql | mysql:8.0 | Docker Hub (public) |

### Evaluation
| Question | This Repo |
|----------|-----------|
| Using private registry (ACR)? | ❌ No - public images |
| Workload Identity enabled? | ✅ Yes |
| imagePullSecrets in use? | ❌ No |

### Decision: ⏸️ DEFER

**Rationale:** All container images are pulled from public registries (Docker Hub). No ACR or private registry authentication is needed. Workload Identity is already enabled for future use.

**Revisit when:**
- Migrating to Azure Container Registry (ACR)
- Using private container images
- Implementing image security scanning

### Example for Future ACR Integration
```yaml
# When using ACR with Workload Identity
apiVersion: v1
kind: ServiceAccount
metadata:
  name: acr-pull-sa
  annotations:
    azure.workload.identity/client-id: "<managed-identity-client-id>"
---
# Pod automatically pulls from ACR using SA token
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: acr-pull-sa
  containers:
  - name: app
    image: myacr.azurecr.io/myapp:latest
```

### Status
- [x] Registry requirements reviewed - **Using public registries**
- [x] Test completed - **Deferred - not needed**
- [x] Recommendation documented - **DEFER**

---

## Summary

| Feature | Decision | Rationale |
|---------|----------|-----------|
| DRA | ⏸️ DEFER | No GPU workloads |
| VolumeAttributesClass | ⏸️ DEFER | Simple PoC storage needs |
| SA Token Image Pull | ⏸️ DEFER | Using public images |

### Key Insight
This is a **backup PoC repository** - the new K8s 1.34 features are designed for more complex production scenarios. All three features are documented for future reference when the platform evolves.

---

## Acceptance Criteria

- [x] Each feature evaluated for relevance
- [x] Technical feasibility documented
- [x] Adoption decisions recorded
- [x] Future adoption paths documented

---
**Labels:** `phase-3`, `features`, `aks-upgrade`, `version-1.34`
**Decision:** All features deferred - not applicable to backup PoC
