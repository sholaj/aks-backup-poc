# AKS 1.34 Curation - GitLab Issues Package

## Overview

This package contains GitLab issues for curating AKS version 1.34 across the platform. The issues cover upgrade planning, deprecation remediation, feature evaluation, testing, documentation, and infrastructure automation.

**Generated:** February 3, 2026  
**AKS 1.34 GA Date:** January 4, 2026  
**Target Environments:** Dev, Pre-Production, Production

---

## Issue Summary

| # | Issue | Type | Priority | Labels |
|---|-------|------|----------|--------|
| 00 | [Epic] AKS 1.34 Upgrade Planning | Epic | High | `epic`, `aks-upgrade` |
| 01 | [SPIKE] Release Notes Review | Spike | High | `spike`, `research` |
| 02 | [DEPRECATION] AppArmor Migration | Deprecation | Medium | `deprecation`, `security` |
| 03 | [DEPRECATION] Cgroup Driver Cleanup | Deprecation | Low | `deprecation`, `kubelet` |
| 04 | [DEPRECATION] Service Topology Annotations | Deprecation | Low | `deprecation`, `networking` |
| 05 | [DEPRECATION] Containerd Version Assessment | Deprecation | Medium | `deprecation`, `containerd` |
| 06 | [FEATURE] DRA Evaluation | Feature | Medium | `feature`, `gpu`, `dra` |
| 07 | [FEATURE] VolumeAttributesClass Testing | Feature | Medium | `feature`, `storage` |
| 08 | [FEATURE] ServiceAccount Image Pull | Feature | Low | `feature`, `security` |
| 09 | [TEST] Non-Production Upgrade Testing | Testing | High | `testing`, `validation` |
| 10 | [TEST] API Compatibility Validation | Testing | High | `testing`, `api-compatibility` |
| 11 | [DOCS] Runbook Updates | Documentation | Medium | `documentation`, `runbooks` |
| 12 | [DOCS] Developer Migration Guide | Documentation | High | `documentation`, `migration-guide` |
| 13 | [MONITOR] OpenTelemetry Evaluation | Monitoring | Low | `monitoring`, `opentelemetry` |
| 14 | [INFRA] Cattle Cluster Daily Rebuild | Infrastructure | High | `infrastructure`, `cattle-clusters` |

---

## Recommended Execution Order

### Phase 1: Research & Planning (Week 1-2)
1. ✅ 01 - Complete spike on release notes
2. 10 - Run API compatibility scans
3. 05 - Assess containerd versions

### Phase 2: Deprecation Work (Week 3-4)
4. 02 - Begin AppArmor migration planning
5. 03 - Clean up cgroup configurations
6. 04 - Update service topology annotations

### Phase 3: Feature Evaluation (Week 5-6)
7. 06 - Evaluate DRA (if GPU workloads exist)
8. 07 - Test VolumeAttributesClass
9. 08 - Review SA token image pull

### Phase 4: Testing (Week 7-10)
10. 09 - Execute non-production testing
11. 14 - Verify cattle cluster automation

### Phase 5: Documentation & Rollout (Week 11-12)
12. 11 - Update runbooks
13. 12 - Publish developer migration guide
14. 13 - Evaluate OpenTelemetry (optional)

---

## Key Changes in AKS 1.34

### GA Features
- Dynamic Resource Allocation (DRA)
- VolumeAttributesClass
- Job Pod Replacement Policy
- Structured Authentication Configuration
- Finer-Grained Authorization
- Scheduler Queueing Hints
- Ordered Namespace Deletion

### Deprecations
- AppArmor (migrate to seccomp)
- Cgroup driver manual configuration
- Service topology annotations
- Containerd 1.6/1.7

### AKS-Specific
- Ubuntu 24.04 default for K8s 1.34+
- Azure Linux 3.0 default
- VPA 1.4.2 with InPlaceOrRecreate
- OpenTelemetry preview support

---

## Files in This Package

```
aks-134-issues/
├── 00-epic-aks-134-upgrade-planning.md
├── 01-spike-release-notes-review.md
├── 02-deprecation-apparmor-migration.md
├── 03-deprecation-cgroup-driver-cleanup.md
├── 04-deprecation-service-topology-annotations.md
├── 05-deprecation-containerd-version-assessment.md
├── 06-feature-dra-evaluation.md
├── 07-feature-volumeattributesclass-testing.md
├── 08-feature-serviceaccount-image-pull.md
├── 09-test-non-production-upgrade.md
├── 10-test-api-compatibility.md
├── 11-docs-runbook-updates.md
├── 12-docs-developer-migration-guide.md
├── 13-monitor-opentelemetry-evaluation.md
├── 14-infra-cattle-cluster-daily-rebuild.md
└── README.md (this file)
```

---

## Importing to GitLab

### Option 1: Manual Creation
Copy the content of each markdown file into GitLab Issues.

### Option 2: GitLab API
```bash
# Example using GitLab API
for file in *.md; do
  title=$(head -1 "$file" | sed 's/^# //')
  body=$(cat "$file")
  curl --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --data-urlencode "title=$title" \
    --data-urlencode "description=$body" \
    "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/issues"
done
```

### Option 3: GitLab Issue Templates
Convert these files to `.gitlab/issue_templates/` format.

---

## References

- [Kubernetes 1.34 Release Blog](https://kubernetes.io/blog/2025/08/27/kubernetes-v1-34-release/)
- [AKS Release Notes](https://github.com/Azure/AKS/releases/tag/2026-01-04)
- [Fairwinds 1.34 Analysis](https://www.fairwinds.com/blog/kubernetes-1.34-released-whats-new-upgrade)
- [AKS Release Tracker](https://releases.aks.azure.com/webpage/index.html)
- [K8s 1.34 Changelog](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.34.md)
