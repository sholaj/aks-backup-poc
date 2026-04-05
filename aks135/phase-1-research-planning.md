# Phase 1: Research & Planning

**Status:** ✅ COMPLETE
**Completed:** 2026-04-02

---

## Scope

This phase covers initial research and compatibility assessment for AKS 1.35 upgrade.

| Original Ticket | Description | Status |
|-----------------|-------------|--------|
| 01 - Release Notes Review | Review K8s 1.35 and AKS release notes | ✅ Complete |
| 03 - Containerd Assessment | Verify containerd 2.x (1.x final warning) | ✅ Complete |
| 10 - API Compatibility | Scan for deprecated/removed APIs | ✅ Complete |

---

## 1. Release Notes Review

### Kubernetes 1.35 "Timbernetes"
- **Upstream Release:** December 17, 2025
- **AKS GA:** March 2026
- **End of Life:** March 2027
- **LTS Available:** Yes (2 years)
- **Enhancements:** 60 total (17 stable, 19 beta, 22 alpha)

### GA Features
| Feature | KEP | Impact | This Repo |
|---------|-----|--------|-----------|
| In-Place Pod Resource Updates | 1287 | High for production | Evaluate for future |
| Image Volumes | 4639 | Medium | Evaluate if OCI image mounting needed |
| PreferSameNode Traffic Distribution | 4444 | Medium for services | Evaluate for service routing |
| Fine-Grained Supplemental Groups | 3619 | Low | Document |
| Kubelet Config Drop-In | 4480 | Medium for ops | Document |
| Job Managed-By | 4368 | Low | Document |
| kubectl Command Headers | 859 | Low | Already transparent |

### Beta Features (Notable)
| Feature | KEP | Impact | This Repo |
|---------|-----|--------|-----------|
| Native Pod Certificates | 4193 | High for cert management | Evaluate as cert-manager alternative |
| StatefulSet MaxUnavailable | 961 | Medium for stateful apps | Not applicable (no StatefulSets) |
| Constrained Node Impersonation | 4592 | Medium for security | Document |

### Breaking Changes Assessed
| Item | Severity | This Repo |
|------|----------|-----------|
| cgroup v1 removed | **BLOCKER** | ✅ Using cgroup v2 (Azure Linux / Ubuntu 24.04) |
| containerd 1.x final warning | HIGH | ✅ Already on containerd 2.x |
| WebSocket RBAC enforcement | HIGH | ✅ No RBAC policies affected |
| Image pull credential re-validation | MEDIUM | ✅ Using public images only |
| IPVS proxy mode deprecated | LOW | ✅ Using Cilium CNI (eBPF) |
| Azure Linux 2.0 EOL | MEDIUM | ✅ Using Ubuntu SKU |

### Deprecations Timeline
| Item | K8s 1.34 | K8s 1.35 | K8s 1.36 | Action |
|------|----------|----------|----------|--------|
| cgroup v1 | Deprecated | **Removed** | N/A | Ensure cgroup v2 |
| Containerd 1.x | Deprecated | Final warning | Unsupported | Ensure 2.x |
| IPVS proxy mode | Supported | Deprecated | Deprecated | N/A (using Cilium) |
| AppArmor annotations | Deprecated | Warning | TBD | Not in use |
| Service topology annotations | Deprecated | Warning | Warning | Not in use |

---

## 2. Containerd Assessment

### Findings
ARM templates use OS defaults — no explicit containerd configuration.

| OS SKU | K8s 1.35 Default | Containerd | cgroup |
|--------|------------------|------------|--------|
| Ubuntu | Ubuntu 24.04 | 2.x | v2 |
| AzureLinux | Azure Linux 3.0 | 2.x | v2 |

### Critical: containerd 1.x Final Warning
K8s 1.35 is the **last version** supporting containerd 1.x. Starting with K8s 1.36, containerd 2.x is required. Since this repo uses OS defaults (Ubuntu 24.04 → containerd 2.x), no action is needed.

### Docker Schema 1 Images
containerd 2.x drops Docker Schema 1 image support. All images in this repo use modern schemas:
- `nginx:1.25-alpine` → Schema 2
- `mysql:8.0` → Schema 2

### ARM Template Status
- `osSKU: Ubuntu` — Ubuntu 24.04 (same as 1.34)
- No explicit containerd version pinned
- **Result:** Compatible with K8s 1.35

---

## 3. API Compatibility Scan

### Scan Results
```
Scanned: kubernetes/**/*.yaml (9 files)
Deprecated APIs: 0
Removed APIs: 0
```

### Resources Reviewed
| Resource | API Version | Status |
|----------|-------------|--------|
| Namespace | v1 | ✅ GA |
| Deployment | apps/v1 | ✅ GA |
| Service | v1 | ✅ GA |
| PVC | v1 | ✅ GA |
| Secret | v1 | ✅ GA |
| BackupHook | clusterbackup.dataprotection.microsoft.com/v1alpha1 | Azure CRD |

**Result:** All manifests use stable GA APIs. No migration required.

### Additional Scans
```
Pattern: imagePullSecrets     → 0 matches
Pattern: cgroup|cgroupDriver  → 0 matches
Pattern: ipvs|proxyMode       → 0 matches
Pattern: apparmor              → 0 matches
Pattern: topology-mode         → 0 matches
```

---

## AKS Component Version Changes (1.34 → 1.35)

| Component | K8s 1.34 | K8s 1.35 |
|-----------|----------|----------|
| Cilium | v1.17.x | v1.18.6 |
| CoreDNS | v1.12.x | v1.13.1 |
| KEDA | 2.16.x | 2.17.2 |
| Cluster Autoscaler | v1.34.x | v1.35.0 |
| Karpenter | N/A | 1.7.0-aks |
| Defender Collector | 2.0 | 2.1 |

---

## Deliverables

- [x] Release notes reviewed and documented
- [x] Deprecation impact assessed (60 enhancements, 6 breaking changes)
- [x] ARM templates verified for 1.35 compatibility
- [x] API compatibility scan completed
- [x] ARM templates updated to target K8s 1.35
- [x] Component version changes documented

---

## References

- [Kubernetes 1.35 Release Blog](https://kubernetes.io/blog/2025/12/17/kubernetes-v1-35-release/)
- [AKS Release Notes](https://github.com/Azure/AKS/releases)
- [K8s 1.35 Changelog](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.35.md)
- [Kubernetes Deprecated API Migration Guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)

---
**Labels:** `phase-1`, `research`, `aks-upgrade`, `version-1.35`
