# [EPIC] AKS 1.35 Upgrade Planning and Curation

## Overview

**Kubernetes Version:** 1.35 "Timbernetes"
**AKS GA Date:** March 2026
**Upstream Release:** December 17, 2025
**End of Life:** March 2027
**LTS Available:** Yes (2 years from GA)

This epic tracks all activities required to curate, test, and roll out AKS version 1.35.

---

## Curation Status

| Phase | Ticket | Status |
|-------|--------|--------|
| 1 | [Research & Planning](phase-1-research-planning.md) | ✅ Complete |
| 2 | [Deprecation Work](phase-2-deprecation-work.md) | ✅ Complete |
| 3 | [Feature Evaluation](phase-3-feature-evaluation.md) | ✅ Complete (all deferred) |
| 4 | [Testing](phase-4-testing.md) | ✅ Complete |
| 5 | [Documentation](phase-5-documentation.md) | ✅ Complete |

---

## Key Findings

### Repository Assessment: CLEAN
This repository has **zero compatibility issues** with K8s 1.35:
- No deprecated APIs in use
- No cgroup v1 dependencies
- No containerd 1.x pinning
- No IPVS proxy mode configuration
- No RBAC policies affected by WebSocket enforcement
- No imagePullSecrets in use

### Changes Made
| File | Change |
|------|--------|
| `arm-templates/02-aks-cluster.json` | K8s 1.35, API 2025-04-01 |
| `arm-templates/02-aks-cluster.parameters.json` | K8s 1.35 |

---

## Release Highlights

### Key GA Features
| Feature | Impact |
|---------|--------|
| In-Place Pod Resource Updates (KEP-1287) | Resize CPU/memory without pod restart |
| Image Volumes | Mount OCI images as read-only volumes |
| PreferSameNode Traffic Distribution | Node-local endpoint priority for services |
| Fine-Grained Supplemental Groups | Better group ID control |
| Kubelet Config Drop-In | Modular kubelet configuration |

### Breaking Changes Assessment
| Change | Risk | This Repo |
|--------|------|-----------|
| cgroup v1 removed | **HIGH** | ✅ Using cgroup v2 (Azure Linux) |
| containerd 1.x final warning | Medium | ✅ Already on 2.x |
| WebSocket RBAC enforcement | Medium | ✅ No RBAC policies affected |
| Image pull credential re-validation | Medium | ✅ Using public images only |
| IPVS proxy mode deprecated | Low | ✅ Using Cilium CNI (eBPF) |
| Ingress NGINX retired (upstream) | Low | ✅ Using Istio service mesh |

### AKS-Specific Changes
- Ubuntu 24.04 continues as default (already migrated in 1.34)
- Azure Linux 2.0 end of life (March 31, 2026) — must use Azure Linux 3.0
- Component bumps: Cilium v1.18.6, CoreDNS v1.13.1, KEDA 2.17.2

---

## Upgrade Timeline

| Environment | Target Date | Status |
|-------------|-------------|--------|
| Dev/Engineering | Q2 2026 | 🟡 Ready to deploy |
| Pre-Production | Q2 2026 | 🔲 Not Started |
| Production | Q3 2026 | 🔲 Not Started |

---

## Success Criteria

- [x] Release notes reviewed
- [x] API compatibility validated
- [x] Deprecations assessed
- [x] ARM templates updated
- [x] Test scripts created (deploy, validate, destroy)
- [x] Documentation updated (runbook, migration guide)

---

## References

- [Kubernetes 1.35 Release Blog](https://kubernetes.io/blog/2025/12/17/kubernetes-v1-35-release/)
- [AKS Release Notes](https://github.com/Azure/AKS/releases)
- [K8s 1.35 Changelog](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.35.md)

---
**Labels:** `epic`, `aks-upgrade`, `version-1.35`
**Assignee:** Platform Engineering
