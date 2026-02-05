# [FEATURE] VolumeAttributesClass Testing with Azure CSI Drivers

## Summary

VolumeAttributesClass has graduated to GA in Kubernetes 1.34 (KEP-3751), enabling modification of volume parameters like IOPS and throughput on-the-fly without volume recreation. We need to test this with Azure CSI drivers.

## Background

Previously, changing volume performance characteristics required creating a new volume and migrating data. VolumeAttributesClass allows dynamic modification through the ModifyVolume API.

## Feature Overview

### Capabilities
- Modify IOPS limits dynamically
- Adjust throughput settings
- Change storage tier without data migration
- No pod restart required (for some changes)

### API Migration
| Version | Status |
|---------|--------|
| `storage.k8s.io/v1beta1` | Deprecated |
| `storage.k8s.io/v1` | GA in 1.34 |

## Prerequisites

### CSI Driver Requirements
- Driver must implement ModifyVolume API
- Azure Disk CSI driver support status: **To Be Verified**
- Azure File CSI driver support status: **To Be Verified**

### Check CSI Driver Versions
```bash
# Check Azure Disk CSI driver version
kubectl get pods -n kube-system -l app=csi-azuredisk-controller -o jsonpath='{.items[0].spec.containers[0].image}'

# Check Azure File CSI driver version
kubectl get pods -n kube-system -l app=csi-azurefile-controller -o jsonpath='{.items[0].spec.containers[0].image}'
```

## Testing Plan

### Phase 1: Verify Support (Week 1)
- [ ] Check Azure Disk CSI driver ModifyVolume support
- [ ] Check Azure File CSI driver ModifyVolume support
- [ ] Review Azure documentation for volume modification
- [ ] Identify supported modification parameters

### Phase 2: Dev Testing (Week 2)
- [ ] Create test VolumeAttributesClass
- [ ] Provision test PVC
- [ ] Modify volume attributes
- [ ] Verify changes applied
- [ ] Test workload continuity during modification

### Phase 3: Documentation (Week 3)
- [ ] Document supported parameters
- [ ] Create usage guide for tenants
- [ ] Update internal runbooks

## Test Scenarios

### Test 1: Create VolumeAttributesClass
```yaml
apiVersion: storage.k8s.io/v1
kind: VolumeAttributesClass
metadata:
  name: azure-premium-iops
driverName: disk.csi.azure.com
parameters:
  DiskIOPSReadWrite: "5000"
  DiskMBpsReadWrite: "200"
```

### Test 2: Apply to Existing PVC
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  volumeAttributesClassName: azure-premium-iops
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: managed-csi-premium
```

### Test 3: Modify Attributes
```bash
# Patch PVC to use different VolumeAttributesClass
kubectl patch pvc test-pvc -p '{"spec":{"volumeAttributesClassName":"azure-premium-high-iops"}}'
```

## Validation Steps

```bash
# Check PVC status
kubectl get pvc test-pvc -o yaml | grep -A5 volumeAttributesClass

# Verify volume modification status
kubectl get pvc test-pvc -o jsonpath='{.status.modifyVolumeStatus}'

# Check events
kubectl describe pvc test-pvc
```

## Azure-Specific Considerations

### Supported Parameters (Pending Verification)
| Parameter | Azure Disk | Azure File |
|-----------|-----------|------------|
| IOPS | Premium SSD v2 | TBD |
| Throughput | Premium SSD v2 | Premium |
| Tier change | Limited | Yes |

### Limitations
- Some modifications may require pod restart
- Premium SSD v2 has most flexibility
- Standard tiers may not support modification

## Success Criteria

- [ ] CSI driver support verified
- [ ] Successful volume modification in dev
- [ ] No data loss during modification
- [ ] Workload continuity verified
- [ ] Documentation created

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| CSI driver doesn't support | Medium | High | Check before testing |
| Data corruption | Low | High | Test with non-critical data |
| Service disruption | Low | Medium | Test in dev first |

---
**Labels:** `feature`, `storage`, `csi`, `aks-upgrade`, `version-1.34`  
**Priority:** Medium  
**Effort:** Medium (2-3 weeks)
