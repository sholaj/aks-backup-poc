# [DEPRECATION] Containerd Version Assessment and Upgrade Planning

## Summary

Containerd 1.6 and 1.7 are deprecated in Kubernetes 1.34. Containerd 2.0+ will be required starting with Kubernetes 1.36. We need to assess our current node images and plan for the transition.

## Background

AKS manages containerd versions through node images. With K8s 1.34, AKS has updated to Containerd 2.1. We need to verify all clusters are using compatible versions.

## Deprecation Timeline

| Containerd Version | K8s 1.34 | K8s 1.35 | K8s 1.36 |
|-------------------|----------|----------|----------|
| 1.6 | Deprecated | Unsupported | Removed |
| 1.7 | Deprecated | Final Support | Removed |
| 2.0+ | Supported | Supported | Required |

## Current State Assessment

### Audit Tasks
- [ ] Check containerd versions across all node pools
- [ ] Identify any clusters on older node images
- [ ] Verify Azure Linux 3.0 containerd version
- [ ] Check Ubuntu 24.04 containerd version

### Verification Commands
```bash
# Check containerd version on nodes (requires node access)
kubectl debug node/<node-name> -it --image=busybox -- cat /etc/containerd/config.toml | grep version

# Via AKS portal/CLI - check node image version
az aks nodepool show -g <rg> --cluster-name <cluster> -n <nodepool> --query nodeImageVersion
```

## AKS Node Image Versions

### Current Defaults (K8s 1.34+)
| OS | Default Version | Containerd |
|-----|-----------------|------------|
| Ubuntu 24.04 | Default for 1.34+ | 2.x |
| Ubuntu 22.04 | Legacy (<1.34) | 1.7 → 2.x |
| Azure Linux 3.0 | Default for AzureLinux | 2.x |
| Azure Linux 2.0 | Retired Nov 2025 | N/A |

## Required Actions

### Phase 1: Inventory (Week 1)
- [ ] List all node pools and image versions
- [ ] Identify pools needing upgrades
- [ ] Document containerd versions per pool

### Phase 2: Planning (Week 2)
- [ ] Schedule node image upgrades
- [ ] Plan for cattle cluster daily rebuilds
- [ ] Update ARM templates for new defaults

### Phase 3: Execution (Week 3-4)
- [ ] Upgrade dev/engineering clusters
- [ ] Upgrade pre-production clusters
- [ ] Plan production maintenance window

## Node Image Upgrade Process

For AKS, containerd is upgraded through node image updates:

```bash
# Check available node image versions
az aks nodepool get-upgrades -g <rg> --cluster-name <cluster> -n <nodepool>

# Upgrade node image
az aks nodepool upgrade \
  --resource-group <rg> \
  --cluster-name <cluster> \
  --name <nodepool> \
  --node-image-only
```

## Cattle Cluster Considerations

For daily build/destroy clusters:
- ARM templates should use latest node images
- No manual intervention needed for new clusters
- Verify pipeline uses correct OS SKU defaults

```json
// ARM template - ensure OS defaults are current
{
  "osSku": "AzureLinux",  // Will use Azure Linux 3.0
  // or
  "osSku": "Ubuntu"       // Will use Ubuntu 24.04 for K8s 1.34+
}
```

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Workload compatibility | Low | Medium | Test in dev first |
| Image pull issues | Low | Low | Verify registry config |
| CRI changes | Low | Medium | Review runtime class usage |

## Acceptance Criteria

- [ ] All clusters on containerd 2.x
- [ ] No Azure Linux 2.0 node pools remaining
- [ ] ARM templates updated for current defaults
- [ ] Pipeline creates clusters with compliant versions

---
**Labels:** `deprecation`, `containerd`, `node-image`, `aks-upgrade`, `version-1.34`  
**Priority:** Medium  
**Due Date:** Before K8s 1.35 upgrade
