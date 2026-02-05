# [EPIC] AKS 1.34 Upgrade Planning and Curation

## Overview

**Kubernetes Version:** 1.34 "Of Wind & Will (O' WaW)"
**AKS GA Date:** January 2026 (2026-01-04 release)
**Upstream Release:** August 27, 2025
**End of Life:** October 27, 2026
**LTS Available:** Yes (2 years from GA)

This epic tracks all activities required to curate, test, and roll out AKS version 1.34.

---

## Curation Status

| Phase | Ticket | Status |
|-------|--------|--------|
| 1 | [Research & Planning](phase-1-research-planning.md) | ✅ Complete |
| 2 | [Deprecation Work](phase-2-deprecation-work.md) | ✅ Complete |
| 3 | [Feature Evaluation](phase-3-feature-evaluation.md) | 🔲 Pending |
| 4 | [Testing](phase-4-testing.md) | 🔲 Pending |
| 5 | [Documentation](phase-5-documentation.md) | 🔲 Pending |

---

## Key Findings

### Repository Assessment: CLEAN
This repository has **zero compatibility issues** with K8s 1.34:
- No deprecated APIs in use
- No AppArmor annotations
- No explicit cgroup driver configs
- No service topology annotations

### Changes Made
| File | Change |
|------|--------|
| `arm-templates/02-aks-cluster.json` | K8s 1.34, API 2025-01-01 |
| `arm-templates/02-aks-cluster.parameters.json` | K8s 1.34 |

---

## Release Highlights

### Key GA Features
| Feature | Impact |
|---------|--------|
| Dynamic Resource Allocation (DRA) | GPU/FPGA allocation |
| VolumeAttributesClass | Modify volume params on-the-fly |
| Job Pod Replacement Policy | Prevents simultaneous pod execution |
| Structured Authentication | Multiple JWT authenticators |

### Breaking Changes Assessment
| Change | Risk | This Repo |
|--------|------|-----------|
| AppArmor deprecated | Medium | ✅ Not in use |
| Cgroup driver auto-detection | Low | ✅ Not configured |
| Containerd 1.6/1.7 deprecated | Medium | ✅ Using defaults |
| Service topology annotations | Low | ✅ Not in use |

### AKS-Specific Changes
- Ubuntu 24.04 default for K8s 1.34+
- Azure Linux 3.0 default for AzureLinux SKU
- Containerd 2.x

---

## Upgrade Timeline

| Environment | Target Date | Status |
|-------------|-------------|--------|
| Dev/Engineering | Q1 2026 | 🟡 Ready to deploy |
| Pre-Production | Q2 2026 | 🔲 Not Started |
| Production | Q2 2026 | 🔲 Not Started |

---

## Success Criteria

- [x] Release notes reviewed
- [x] API compatibility validated
- [x] Deprecations assessed
- [x] ARM templates updated
- [ ] Test cluster deployed
- [ ] Workloads validated
- [ ] Documentation updated

---

## References

- [Kubernetes 1.34 Release Blog](https://kubernetes.io/blog/2025/08/27/kubernetes-v1-34-release/)
- [AKS Release Notes](https://github.com/Azure/AKS/releases/tag/2026-01-04)
- [K8s 1.34 Changelog](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.34.md)

---
**Labels:** `epic`, `aks-upgrade`, `version-1.34`
**Assignee:** Platform Engineering
