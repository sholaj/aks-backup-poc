# [SPIKE] Release Notes Review — K8s 1.35

## Summary
Review Kubernetes 1.35 and AKS 1.35 release notes to identify all changes, deprecations, and new features relevant to the platform.

## Background
Kubernetes 1.35 "Timbernetes" was released upstream on December 17, 2025. AKS 1.35 reached GA in March 2026. This spike reviews all changes for impact assessment.

## Curation Results (2026-04-02)

### Release Overview
- **Version:** 1.35 "Timbernetes"
- **Enhancements:** 60 total (17 stable, 19 beta, 22 alpha)
- **Theme:** Major stability and runtime improvements

### Key Stable (GA) Features
| Feature | KEP | Description |
|---------|-----|-------------|
| In-Place Pod Resource Updates | 1287 | Resize CPU/memory without restart |
| Image Volumes | 4639 | Mount OCI images as read-only volumes |
| PreferSameNode Traffic | 4444 | Node-local endpoint priority |
| Fine-Grained Supplemental Groups | 3619 | Better group ID control |
| Kubelet Config Drop-In | 4480 | Modular kubelet configuration |
| Job Managed-By | 4368 | External job controller support |
| kubectl Command Headers | 859 | Command metadata in API requests |

### Key Beta Features
| Feature | KEP | Description |
|---------|-----|-------------|
| Native Pod Certificates | 4193 | Kubelet-issued pod certs |
| StatefulSet MaxUnavailable | 961 | Parallel stateful pod updates |
| Constrained Node Impersonation | 4592 | Node identity security |

### Breaking Changes
| Change | Severity | Impact |
|--------|----------|--------|
| cgroup v1 removed | BLOCKER | Kubelet refuses to start on v1 |
| WebSocket RBAC enforcement | HIGH | exec/attach need `create` verb |
| Image pull re-validation | MEDIUM | Expired secrets cause failures |
| IPVS deprecated | LOW | Only if using kube-proxy IPVS |
| Ingress NGINX retired | LOW | No further security patches |

### AKS Component Updates
| Component | Version |
|-----------|---------|
| Cilium | v1.18.6 |
| CoreDNS | v1.13.1 |
| KEDA | 2.17.2 |
| Cluster Autoscaler | v1.35.0 |
| Karpenter | 1.7.0-aks |

## Status: ✅ COMPLETE

---
**Labels:** `spike`, `research`, `aks-upgrade`, `version-1.35`
