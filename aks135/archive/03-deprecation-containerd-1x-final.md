# [DEPRECATION] Containerd 1.x Final Warning

## Summary
K8s 1.35 is the last Kubernetes version supporting containerd 1.x. Starting with K8s 1.36, containerd 2.x is mandatory. Verify all nodes run containerd 2.x.

## Background
containerd 2.x was introduced as default in AKS for K8s 1.34+. Key changes in containerd 2.x:
- Docker Schema 1 image support dropped
- `config.toml` structure changed
- Improved performance and security

## Curation Results (2026-04-02)

### Scan Results
```
Scanned: arm-templates/*.json
Pattern: containerd|containerRuntime
Matches: 0 explicit version pins
```

### Findings
| File | Containerd Config |
|------|-------------------|
| arm-templates/02-aks-cluster.json | None (uses AKS defaults) |

### Image Schema Compatibility
| Image | Schema | Status |
|-------|--------|--------|
| nginx:1.25-alpine | v2 | ✅ Compatible |
| mysql:8.0 | v2 | ✅ Compatible |
| busybox:1.36 | v2 | ✅ Compatible |

### Verification Command
```bash
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
# Expected: containerd://2.x.x
```

### Status: NO ACTION REQUIRED
ARM templates use OS defaults. AKS automatically provides containerd 2.x for K8s 1.34+ nodes.

## Acceptance Criteria
- [x] No explicit containerd version pins found
- [x] All images verified for Schema 2 compatibility
- [x] Verification command documented

---
**Labels:** `deprecation`, `containerd`, `aks-upgrade`, `version-1.35`
