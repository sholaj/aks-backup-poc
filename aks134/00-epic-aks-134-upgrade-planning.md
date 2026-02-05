# [EPIC] AKS 1.34 Upgrade Planning and Curation

## Overview

**Kubernetes Version:** 1.34 "Of Wind & Will (O' WaW)"  
**AKS GA Date:** January 2026 (2026-01-04 release)  
**Upstream Release:** August 27, 2025  
**End of Life:** October 27, 2026  
**LTS Available:** Yes (2 years from GA)

This epic tracks all activities required to curate, test, and roll out AKS version 1.34 across our platform environments.

## Release Highlights

### Key GA Features
- **Dynamic Resource Allocation (DRA)** - Standardized GPU/FPGA allocation
- **VolumeAttributesClass** - Modify volume parameters on-the-fly
- **Job Pod Replacement Policy** - Prevents simultaneous pod execution
- **Structured Authentication Configuration** - Multiple JWT authenticators
- **Finer-Grained Authorization** - Field/label selector support
- **Anonymous Auth Restrictions** - Configurable endpoint allowlist
- **Scheduler Queueing Hints** - Improved scheduling throughput
- **Ordered Namespace Deletion** - Addresses CVE-2024-7598

### Breaking Changes Assessment
| Change | Risk | Action Required |
|--------|------|-----------------|
| AppArmor deprecated | Medium | Plan migration to seccomp |
| Cgroup driver auto-detection | Low | Remove manual configs |
| Containerd 1.6/1.7 deprecated | Medium | Verify node image versions |
| Service topology annotations | Low | Update to `.spec.trafficDistribution` |

### AKS-Specific Changes
- Ubuntu 24.04 default for K8s 1.34+
- Azure Linux 3.0 default for AzureLinux SKU
- VPA 1.4.2 with InPlaceOrRecreate mode
- New features: Identity bindings, Static Egress Gateway private IP

## Upgrade Timeline

| Environment | Target Date | Status |
|-------------|-------------|--------|
| Dev/Engineering | Q1 2026 | 🔲 Not Started |
| Pre-Production | Q2 2026 | 🔲 Not Started |
| Production | Q2 2026 | 🔲 Not Started |

## Related Issues

- [ ] #001 - [SPIKE] Review Kubernetes 1.34 Release Notes
- [ ] #002 - [DEPRECATION] AppArmor Migration Planning
- [ ] #003 - [DEPRECATION] Cgroup Driver Configuration Cleanup
- [ ] #004 - [DEPRECATION] Service Topology Annotation Updates
- [ ] #005 - [DEPRECATION] Containerd Version Assessment
- [ ] #006 - [FEATURE] DRA Evaluation for GPU Workloads
- [ ] #007 - [FEATURE] VolumeAttributesClass Testing
- [ ] #008 - [FEATURE] ServiceAccount Token Image Pull
- [ ] #009 - [TEST] Non-Production Upgrade Testing
- [ ] #010 - [TEST] API Compatibility Validation
- [ ] #011 - [DOCS] Internal Runbook Updates
- [ ] #012 - [DOCS] Developer Migration Guide
- [ ] #013 - [MONITOR] OpenTelemetry Integration
- [ ] #014 - [INFRA] Cattle Cluster Daily Rebuild Verification

## Success Criteria

- [ ] Zero production incidents during upgrade
- [ ] All deprecated APIs migrated before 1.36
- [ ] Performance regression < 5%
- [ ] All validation tests passing
- [ ] Documentation updated

## References

- [Kubernetes 1.34 Release Blog](https://kubernetes.io/blog/2025/08/27/kubernetes-v1-34-release/)
- [AKS Release Notes](https://github.com/Azure/AKS/releases/tag/2026-01-04)
- [Fairwinds Analysis](https://www.fairwinds.com/blog/kubernetes-1.34-released-whats-new-upgrade)
- [AKS Release Tracker](https://releases.aks.azure.com/webpage/index.html)

---
**Labels:** `epic`, `aks-upgrade`, `version-1.34`, `Q1-2026`  
**Assignee:** Platform Engineering Team  
**Milestone:** Q2 2025 - Cluster Provisioning Stability Initiative
