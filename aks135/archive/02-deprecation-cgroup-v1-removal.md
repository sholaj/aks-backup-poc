# [DEPRECATION] cgroup v1 Removal Assessment

## Summary
K8s 1.35 removes cgroup v1 support entirely. The kubelet will refuse to start on nodes running cgroup v1. Assess impact on all cluster node pools.

## Background
cgroup v1 was deprecated in K8s 1.31 and progressively restricted. In 1.35, it is fully removed — this is a **hard failure**, not a warning.

## Curation Results (2026-04-02)

### Scan Results
```
Scanned: arm-templates/*.json, kubernetes/**/*.yaml
Pattern: cgroup|cgroupDriver|cgroup-driver
Matches: 0
```

### Findings
| Component | cgroup Version | Status |
|-----------|---------------|--------|
| Ubuntu 24.04 (default) | cgroup v2 | ✅ Safe |
| Azure Linux 3.0 | cgroup v2 | ✅ Safe |
| ARM template | No explicit config | ✅ Uses OS default (v2) |

### Verification Command
```bash
kubectl debug node/<node-name> -it --image=busybox -- stat -fc %T /sys/fs/cgroup
# Expected: cgroup2fs (v2)
# Blocker: tmpfs (v1)
```

### Status: NO ACTION REQUIRED
All supported AKS node OS images (Ubuntu 24.04, Azure Linux 3.0) use cgroup v2 by default.

## Acceptance Criteria
- [x] All node OS images verified for cgroup v2
- [x] ARM templates checked for explicit cgroup configuration
- [x] Verification command documented

---
**Labels:** `deprecation`, `cgroup`, `aks-upgrade`, `version-1.35`
