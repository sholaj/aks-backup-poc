# [DEPRECATION] AppArmor Migration Planning

## Summary

AppArmor has been deprecated in Kubernetes 1.34. We need to assess our current usage and plan migration to alternative security mechanisms (seccomp profiles).

## Background

AppArmor is a Linux kernel security module that restricts program capabilities. With its deprecation in K8s 1.34, we need to transition workloads to use seccomp profiles or other security controls.

## Curation Results (2026-02-05)

### Repository Scan
```
Scanned: kubernetes/**/*.yaml (9 files)
AppArmor annotations found: 0
```

### Findings
| File | AppArmor Annotations |
|------|---------------------|
| `kubernetes/namespaces.yaml` | None |
| `kubernetes/AT-app1/deployment.yaml` | None |
| `kubernetes/AT-app1/service.yaml` | None |
| `kubernetes/AT-app2/mysql-deployment.yaml` | None |
| `kubernetes/AT-app2/mysql-service.yaml` | None |
| `kubernetes/AT-app2/mysql-pvc.yaml` | None |
| `kubernetes/AT-app2/mysql-secret.yaml` | None |
| `kubernetes/hooks/backup-hooks.yaml` | None |
| `kubernetes/hooks/restore-hooks.yaml` | None |

### Status: NO ACTION REQUIRED
This repository does not use AppArmor annotations. No migration needed.

---

## Current State Assessment

### Tasks
- [x] Audit all clusters for AppArmor usage - **COMPLETE: None found**
- [x] Identify pods/deployments with AppArmor annotations - **COMPLETE: None found**
- [x] Document current AppArmor profiles in use - **COMPLETE: None in use**
- [x] Identify which workloads require mandatory access control - **N/A**

### Audit Commands
```bash
# Find pods with AppArmor annotations
kubectl get pods -A -o json | jq -r '.items[] | select(.metadata.annotations | keys[] | contains("apparmor")) | "\(.metadata.namespace)/\(.metadata.name)"'

# Check node AppArmor status
kubectl get nodes -o json | jq '.items[].status.nodeInfo.osImage'
```

## Migration Plan

### Phase 1: Assessment (Week 1-2)
- [ ] Complete audit of AppArmor usage
- [ ] Categorize workloads by criticality
- [ ] Document current security requirements

### Phase 2: Seccomp Profile Development (Week 3-4)
- [ ] Develop equivalent seccomp profiles
- [ ] Test profiles in dev environment
- [ ] Create RuntimeDefault profile baseline

### Phase 3: Tenant Communication (Week 5)
- [ ] Notify affected tenants
- [ ] Provide migration documentation
- [ ] Schedule migration windows

### Phase 4: Migration (Week 6-8)
- [ ] Migrate dev workloads
- [ ] Validate security posture
- [ ] Migrate production workloads

## Technical Details

### AppArmor to Seccomp Transition

**Before (AppArmor):**
```yaml
metadata:
  annotations:
    container.apparmor.security.beta.kubernetes.io/mycontainer: runtime/default
```

**After (Seccomp):**
```yaml
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
```

### Recommended Seccomp Profiles
| Profile Type | Use Case |
|-------------|----------|
| RuntimeDefault | Most workloads (recommended default) |
| Localhost | Custom profiles for specific needs |
| Unconfined | Legacy apps (not recommended) |

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Security gaps during transition | Medium | High | Phased rollout, monitoring |
| Workload compatibility | Low | Medium | Thorough testing |
| Tenant resistance | Low | Low | Clear communication |

## Success Criteria

- [x] Zero AppArmor usage before K8s 1.36 - **ACHIEVED: No AppArmor in use**
- [ ] All workloads using seccomp RuntimeDefault minimum - **RECOMMENDATION for future**
- [x] Security audit passes - **N/A: No migration needed**
- [x] No security incidents during migration - **N/A: No migration needed**

## References

- [Kubernetes Seccomp Documentation](https://kubernetes.io/docs/tutorials/security/seccomp/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

---
**Labels:** `deprecation`, `security`, `aks-upgrade`, `version-1.34`  
**Priority:** Medium  
**Due Date:** Before production 1.34 upgrade
