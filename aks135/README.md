# AKS 1.35 Curation

## Overview

Consolidated curation package for AKS version 1.35 upgrade planning.

**AKS 1.35 GA Date:** March 2026
**Target Environments:** Dev, Pre-Production, Production
**Curation Status:** ✅ ALL PHASES COMPLETE

---

## Tickets (5 Phases)

| Phase | Ticket | Status | Description |
|-------|--------|--------|-------------|
| 1 | [Research & Planning](phase-1-research-planning.md) | ✅ Complete | Release notes, API scan, containerd |
| 2 | [Deprecation Work](phase-2-deprecation-work.md) | ✅ Complete | cgroup v1, containerd 1.x, IPVS, WebSocket RBAC |
| 3 | [Feature Evaluation](phase-3-feature-evaluation.md) | ✅ Complete | All deferred - not needed for PoC |
| 4 | [Testing](phase-4-testing.md) | ✅ Complete | Scripts ready: deploy, validate, destroy |
| 5 | [Documentation](phase-5-documentation.md) | ✅ Complete | Runbook, migration guide created |

---

## Quick Status

### Completed
- ✅ Release notes reviewed
- ✅ API compatibility scan (CLEAN)
- ✅ ARM templates updated to K8s 1.35
- ✅ All deprecations assessed (none affect this repo)

### Scripts Ready
- `scripts/deploy-135.sh` - Deploy K8s 1.35 cluster
- `scripts/validate-135.sh` - Validate cluster health
- `scripts/destroy-cluster.sh` - Destroy cluster (cattle pattern)

### Documentation
- `docs/aks-135-runbook.md` - Operations runbook
- `docs/aks-135-migration-guide.md` - Developer migration guide

---

## Key Findings

### This Repository is Clean
| Check | Result |
|-------|--------|
| Deprecated APIs | None found |
| cgroup v1 dependencies | Not in use |
| containerd 1.x pinning | Not configured |
| IPVS proxy mode | Not in use (Cilium CNI) |
| WebSocket RBAC impact | No RBAC policies to update |
| imagePullSecrets | Not in use (public images) |

### ARM Template Changes Made
| File | Change |
|------|--------|
| `02-aks-cluster.json` | K8s version default → 1.35, API version → 2025-04-01 |
| `02-aks-cluster.parameters.json` | K8s version → 1.35 |

---

## Key Changes in AKS 1.35

### GA Features
- In-Place Pod Resource Updates (resize CPU/memory without restart)
- Image Volumes (mount OCI images as read-only volumes)
- PreferSameNode Traffic Distribution
- Fine-Grained Supplemental Groups
- Kubelet Config Drop-In

### Deprecations / Removals
- cgroup v1 REMOVED (kubelet refuses to start)
- containerd 1.x final warning (must be on 2.x before 1.36)
- IPVS proxy mode deprecated
- WebSocket RBAC enforcement (kubectl exec/attach needs `create` perms)
- Image pull credential re-validation

### AKS-Specific
- Azure Linux 2.0 end of life (March 31, 2026)
- Component bumps: Cilium v1.18.6, CoreDNS v1.13.1, KEDA 2.17.2
- Ingress NGINX retired upstream (no further security patches)

---

## Files

```
aks135/
├── README.md                      # This file
├── CURATION-REPORT.md             # Detailed findings
├── 00-epic-aks-135-upgrade-planning.md  # Epic overview
├── phase-1-research-planning.md   # ✅ Complete
├── phase-2-deprecation-work.md    # ✅ Complete
├── phase-3-feature-evaluation.md  # ✅ Complete
├── phase-4-testing.md             # ✅ Complete
├── phase-5-documentation.md       # ✅ Complete
└── archive/                       # Original granular tickets
```

---

## References

- [Kubernetes 1.35 Release Blog](https://kubernetes.io/blog/2025/12/17/kubernetes-v1-35-release/)
- [AKS Release Notes](https://github.com/Azure/AKS/releases)
- [K8s 1.35 Changelog](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.35.md)
