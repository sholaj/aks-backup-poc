# [TEST] API Compatibility Validation

## Summary
Scan all Kubernetes manifests and live cluster resources for deprecated or removed APIs in K8s 1.35.

## Background
K8s 1.35 does not remove any previously GA API versions, but forward-looking scans help prepare for future upgrades.

## Curation Results (2026-04-02)

### Static Scan Results
```
Tool: grep + manual review
Scanned: kubernetes/**/*.yaml (9 files)
Target: K8s 1.35
Deprecated APIs: 0
Removed APIs: 0
```

### Resources Reviewed
| Resource | File | API Version | Status |
|----------|------|-------------|--------|
| Namespace | `kubernetes/namespaces.yaml` | `v1` | ✅ GA |
| Deployment (nginx) | `kubernetes/AT-app1/deployment.yaml` | `apps/v1` | ✅ GA |
| Service (nginx) | `kubernetes/AT-app1/service.yaml` | `v1` | ✅ GA |
| Deployment (mysql) | `kubernetes/AT-app2/mysql-deployment.yaml` | `apps/v1` | ✅ GA |
| Service (mysql) | `kubernetes/AT-app2/mysql-service.yaml` | `v1` | ✅ GA |
| PVC | `kubernetes/AT-app2/mysql-pvc.yaml` | `v1` | ✅ GA |
| Secret | `kubernetes/AT-app2/mysql-secret.yaml` | `v1` | ✅ GA |
| BackupHook | `kubernetes/hooks/backup-hooks.yaml` | `clusterbackup...v1alpha1` | Azure CRD |
| RestoreHook | `kubernetes/hooks/restore-hooks.yaml` | `clusterbackup...v1alpha1` | Azure CRD |

### Pluto Scan Command
```bash
# Static scan
pluto detect-files -d kubernetes/ --target-versions k8s=v1.35.0 -o wide

# Live cluster scan
pluto detect-api-resources --target-versions k8s=v1.35.0 -o wide

# Forward-looking (1.36)
pluto detect-files -d kubernetes/ --target-versions k8s=v1.36.0 -o wide
```

### Status: ✅ CLEAN — No deprecated or removed APIs found

## Acceptance Criteria
- [x] All manifest files scanned
- [x] API versions verified against 1.35 deprecation guide
- [x] Pluto scan commands documented
- [x] Forward-looking scan documented

---
**Labels:** `test`, `api-compatibility`, `aks-upgrade`, `version-1.35`
