# [DOCS] Create Developer Migration Guide for AKS 1.34

## Summary

Create a comprehensive migration guide for tenant developers deploying workloads on our AKS platform, explaining what changes in Kubernetes 1.34 may affect their applications.

## Target Audience

- Application developers
- DevOps engineers
- Platform tenants

## Guide Structure

### 1. Executive Summary
- What's changing in 1.34
- Timeline for rollout
- Actions required by tenants

### 2. Breaking Changes
- AppArmor deprecation
- Service topology annotations
- API version changes

### 3. New Features Available
- VolumeAttributesClass
- Job Pod Replacement Policy
- ServiceAccount token image pulls

### 4. Recommended Actions
- Pre-upgrade checklist
- Manifest updates
- Testing recommendations

## Content to Include

### Deprecation Notices
```markdown
## Deprecated Features

### AppArmor (Deprecated in 1.34)

**Impact:** Medium  
**Action Required:** Before production 1.34 upgrade

If your pods use AppArmor annotations:
```yaml
# DEPRECATED - Remove this
metadata:
  annotations:
    container.apparmor.security.beta.kubernetes.io/mycontainer: runtime/default
```

Replace with seccomp:
```yaml
# RECOMMENDED - Use this instead
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
```

### Service Topology Annotations (Deprecated in 1.34)

**Impact:** Low  
**Action Required:** Before K8s 1.38

If you use topology annotations:
```yaml
# DEPRECATED
metadata:
  annotations:
    service.kubernetes.io/topology-mode: "Auto"
```

Replace with trafficDistribution:
```yaml
# RECOMMENDED
spec:
  trafficDistribution: PreferClose
```
```

### New Features
```markdown
## New Features Available

### VolumeAttributesClass (GA in 1.34)

Modify volume IOPS/throughput without recreation:
```yaml
apiVersion: storage.k8s.io/v1
kind: VolumeAttributesClass
metadata:
  name: high-iops
driverName: disk.csi.azure.com
parameters:
  DiskIOPSReadWrite: "5000"
```

### Job Pod Replacement Policy (GA in 1.34)

Prevent simultaneous pod execution for ML jobs:
```yaml
apiVersion: batch/v1
kind: Job
spec:
  podReplacementPolicy: Failed
```
```

### Pre-Upgrade Checklist
```markdown
## Pre-Upgrade Checklist

Before your namespace is upgraded to 1.34:

- [ ] Review AppArmor usage
- [ ] Check for deprecated annotations
- [ ] Update Helm charts to latest versions
- [ ] Run `pluto detect-files` on manifests
- [ ] Test in dev cluster first
- [ ] Review release notes
```

## Guide Sections

### Section 1: Overview
- [ ] Write executive summary
- [ ] Create upgrade timeline
- [ ] List key changes

### Section 2: Breaking Changes
- [ ] Document AppArmor deprecation
- [ ] Document topology annotations
- [ ] Provide migration examples

### Section 3: New Features
- [ ] Explain VolumeAttributesClass
- [ ] Explain Job replacement policy
- [ ] Explain SA token image pulls

### Section 4: Testing
- [ ] Dev environment access
- [ ] Testing procedures
- [ ] Validation steps

### Section 5: FAQ
- [ ] Common questions
- [ ] Troubleshooting tips
- [ ] Support contacts

## Distribution Plan

- [ ] Publish to internal wiki
- [ ] Send email notification to tenants
- [ ] Present in platform office hours
- [ ] Add to onboarding documentation

## Review Process

- [ ] Technical review by platform team
- [ ] Review by sample tenant team
- [ ] Approval from documentation owner

## Success Criteria

- [ ] Guide covers all deprecations
- [ ] Clear migration examples provided
- [ ] Tested by sample tenant
- [ ] Published and distributed
- [ ] Feedback mechanism in place

---
**Labels:** `documentation`, `migration-guide`, `tenant-facing`, `aks-upgrade`, `version-1.34`  
**Priority:** High  
**Due Date:** 2 weeks before production upgrade
