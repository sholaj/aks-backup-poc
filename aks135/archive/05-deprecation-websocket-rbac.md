# [DEPRECATION] WebSocket RBAC Enforcement

## Summary
K8s 1.35 enforces stricter RBAC for WebSocket-based operations. `kubectl exec`, `kubectl attach`, and `kubectl port-forward` now require `create` permissions on pod subresources.

## Background
Previously, `get` permissions on `pods/exec`, `pods/attach`, and `pods/portforward` were sufficient. In 1.35, the `create` verb is required. This affects all RBAC policies granting these capabilities.

## Curation Results (2026-04-02)

### Scan Results
```
Scanned: kubernetes/**/*.yaml
Pattern: ClusterRole|Role|rules|exec|attach|port-forward
Matches: 0
```

### Findings
| File | RBAC Policies |
|------|---------------|
| kubernetes/ | None defined |

### Status: NO ACTION REQUIRED
No RBAC policies are defined in this repository. Default AKS cluster-admin access is unaffected.

### Enterprise Migration Guide

#### Before (1.34)
```yaml
rules:
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["get"]
```

#### After (1.35)
```yaml
rules:
- apiGroups: [""]
  resources: ["pods/exec", "pods/attach", "pods/portforward"]
  verbs: ["create"]
```

#### Audit Command
```bash
# Find all roles granting exec access
kubectl get clusterroles -o json | jq -r '
  .items[] |
  select(.rules[]? | .resources[]? | contains("pods/exec")) |
  .metadata.name'
```

### AT-* Namespace Impact
For enterprise environments with tenant namespaces (AT-*), audit all Role and ClusterRole bindings that grant exec/attach/port-forward access to service accounts.

## Acceptance Criteria
- [x] Repository scanned for RBAC policies
- [x] Migration guide documented (before/after)
- [x] Audit commands provided
- [x] Enterprise guidance for AT-* namespaces documented

---
**Labels:** `deprecation`, `rbac`, `security`, `aks-upgrade`, `version-1.35`
