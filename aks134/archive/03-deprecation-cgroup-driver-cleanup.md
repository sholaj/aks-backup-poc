# [DEPRECATION] Cgroup Driver Configuration Cleanup

## Summary

The manual `--cgroup-driver` kubelet flag has been deprecated in Kubernetes 1.34 as cgroup driver auto-detection is now stable. We need to remove any manual cgroup driver configurations from our cluster configurations.

## Background

Kubernetes now automatically detects and configures the appropriate cgroup driver (systemd or cgroupfs) based on the container runtime configuration. Manual configuration is deprecated in 1.34 and will be removed in 1.36.

## Curation Results (2026-02-05)

### ARM Template Scan
```
Scanned: arm-templates/*.json (4 files)
Explicit cgroup driver configs: 0
kubeletConfig sections: 0
```

### Findings
| File | Cgroup Config |
|------|---------------|
| `arm-templates/01-resource-group.json` | N/A (resource group) |
| `arm-templates/02-aks-cluster.json` | None - uses AKS defaults |
| `arm-templates/02-aks-cluster.parameters.json` | None |
| `arm-templates/03-backup-infrastructure.json` | N/A (backup vault) |

### Status: NO ACTION REQUIRED
ARM templates do not specify explicit cgroup driver configuration. AKS auto-detection will be used (systemd cgroup driver).

---

## Current State

### Assessment Tasks
- [x] Review ARM templates for cgroup configurations - **COMPLETE: None found**
- [x] Check kubelet configuration in node pools - **COMPLETE: Using defaults**
- [ ] Verify current cgroup driver in use across clusters - **Verify after deployment**
- [x] Document any custom cgroup configurations - **COMPLETE: None exist**

### Verification Commands
```bash
# Check kubelet cgroup driver on nodes
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'

# Via node shell (if SSH access available)
cat /var/lib/kubelet/config.yaml | grep cgroupDriver
```

## Required Changes

### ARM Template Updates
Review and remove any explicit cgroup driver settings:

```json
// BEFORE - Remove if present
"kubeletConfig": {
  "cgroupDriver": "systemd"  // REMOVE THIS
}

// AFTER - Let AKS auto-detect
"kubeletConfig": {
  // No cgroup driver specified
}
```

### Cluster Configuration Review
- [ ] Check `env/*.yml` files for cgroup settings
- [ ] Review nodepool configurations
- [ ] Update parameter templates

## AKS Default Behavior

AKS automatically configures:
- **systemd** cgroup driver for all supported versions
- Aligns with container runtime (containerd) settings
- No manual intervention required

## Migration Steps

### Phase 1: Audit (Week 1)
- [ ] Scan all ARM templates
- [ ] Check cluster configuration files
- [ ] Document any explicit cgroup settings

### Phase 2: Update Templates (Week 2)
- [ ] Remove deprecated configurations
- [ ] Test in dev environment
- [ ] Verify cluster stability

### Phase 3: Rollout (Week 3-4)
- [ ] Apply to new cluster deployments
- [ ] Update existing clusters during next maintenance
- [ ] Verify auto-detection working correctly

## Validation

```bash
# Verify cgroup driver after upgrade
kubectl get --raw "/api/v1/nodes/<node-name>/proxy/configz" | jq '.kubeletconfig.cgroupDriver'
```

Expected output: `"systemd"`

## Timeline

| Version | Status |
|---------|--------|
| K8s 1.34 | Deprecated - auto-detection stable |
| K8s 1.35 | Warning on use |
| K8s 1.36 | Configuration option removed |

## Acceptance Criteria

- [x] No explicit cgroup driver flags in ARM templates - **VERIFIED: None present**
- [ ] All clusters using auto-detected cgroup driver - **Verify after deployment**
- [ ] Pipeline validation passes - **Pending deployment**
- [x] Documentation updated - **COMPLETE**

---
**Labels:** `deprecation`, `kubelet`, `aks-upgrade`, `version-1.34`  
**Priority:** Low  
**Effort:** Small (1-2 days)
