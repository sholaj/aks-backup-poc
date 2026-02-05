# Phase 3: Feature Evaluation

**Status:** 🔲 PENDING
**Priority:** Medium (optional features)

---

## Scope

Evaluate new K8s 1.34 GA features for potential adoption.

| Original Ticket | Description | Priority |
|-----------------|-------------|----------|
| 06 - DRA Evaluation | Dynamic Resource Allocation for GPU/FPGA | Medium |
| 07 - VolumeAttributesClass | Modify volume parameters on-the-fly | Medium |
| 08 - ServiceAccount Image Pull | SA tokens for image pull authentication | Low |

---

## 1. Dynamic Resource Allocation (DRA)

### Overview
DRA (KEP-4381) provides standardized allocation of specialized hardware like GPUs, FPGAs, and NICs.

### Key Capabilities
| Capability | Benefit |
|------------|---------|
| ResourceClaim API | Request specific device attributes |
| Multi-pod sharing | Share GPU between pods |
| Consumable capacity | Allocate fractions of devices |
| Scheduler integration | Better placement decisions |

### Evaluation Criteria
- [ ] Do any workloads use GPUs?
- [ ] Are there FPGAs or specialized NICs?
- [ ] Is GPU utilization < 60%?
- [ ] Is multi-tenant GPU sharing needed?

### Sample ResourceClaim
```yaml
apiVersion: resource.k8s.io/v1
kind: ResourceClaim
metadata:
  name: gpu-claim
spec:
  devices:
    requests:
    - name: gpu
      deviceClassName: gpu.nvidia.com
      count: 1
```

### Decision
- **Adopt if:** Significant GPU workloads, low utilization, multi-tenancy needs
- **Defer if:** No GPU workloads, device plugins working well

### Status
- [ ] GPU usage survey completed
- [ ] Technical feasibility assessed
- [ ] Recommendation documented

---

## 2. VolumeAttributesClass

### Overview
VolumeAttributesClass (KEP-3751) allows modifying volume parameters (IOPS, throughput) without recreating PVCs.

### Use Cases
| Scenario | Benefit |
|----------|---------|
| Performance tuning | Adjust IOPS on-the-fly |
| Cost optimization | Scale down during off-peak |
| Workload migration | Match storage to workload needs |

### Sample VolumeAttributesClass
```yaml
apiVersion: storage.k8s.io/v1
kind: VolumeAttributesClass
metadata:
  name: high-iops
driverName: disk.csi.azure.com
parameters:
  iops: "5000"
  throughput: "200"
```

### Evaluation Tasks
- [ ] Review Azure Disk CSI driver support
- [ ] Test in dev environment
- [ ] Document cost implications

### Status
- [ ] CSI driver compatibility verified
- [ ] Test completed
- [ ] Recommendation documented

---

## 3. ServiceAccount Token Image Pull

### Overview
Allows using ServiceAccount tokens for authenticating to container registries without storing credentials as secrets.

### Benefits
| Benefit | Description |
|---------|-------------|
| No static secrets | Tokens are short-lived |
| Automatic rotation | No manual credential management |
| Workload identity | Leverages existing SA infrastructure |

### Configuration
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
imagePullSecrets: []  # Not needed with token-based auth
---
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: my-app
  # Token automatically used for image pull
```

### Evaluation Tasks
- [ ] Review ACR integration with Workload Identity
- [ ] Test with private registry
- [ ] Document configuration steps

### Status
- [ ] Registry requirements reviewed
- [ ] Test completed
- [ ] Recommendation documented

---

## Acceptance Criteria

- [ ] Each feature evaluated for relevance
- [ ] Technical feasibility documented
- [ ] Adoption decisions recorded
- [ ] Implementation roadmap created (if adopting)

---
**Labels:** `phase-3`, `features`, `aks-upgrade`, `version-1.34`
