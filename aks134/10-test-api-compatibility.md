# [TEST] API Compatibility Validation for AKS 1.34

## Summary

Before upgrading to AKS 1.34, we must validate that all workloads, Helm charts, and Kubernetes manifests are compatible with the new API versions and don't use deprecated or removed APIs.

## Background

Kubernetes 1.34 has **no critical API removals**, making this a relatively smooth upgrade from an API perspective. However, we should still validate all resources and prepare for future deprecations.

## API Changes in 1.34

### GA Promotions
| API | From | To |
|-----|------|-----|
| VolumeAttributesClass | `storage.k8s.io/v1beta1` | `storage.k8s.io/v1` |
| DRA ResourceClaim | `resource.k8s.io/v1alpha3` | `resource.k8s.io/v1` |

### Upcoming Removals (Prepare Now)
| API | Deprecated | Removal Target |
|-----|------------|----------------|
| Service topology annotations | 1.34 | 1.38 |
| FlowSchema (specific) | 1.34 | Future |

## Scanning Tools

### Install kubent (kube-no-trouble)
```bash
# Install kubent
curl -sfL https://raw.githubusercontent.com/doitintl/kube-no-trouble/master/scripts/install.sh | sh

# Run scan
kubent
```

### Install pluto
```bash
# Install pluto
brew install FairwindsOps/tap/pluto

# Or via curl
curl -sfL https://raw.githubusercontent.com/FairwindsOps/pluto/master/scripts/install.sh | sh

# Run scan
pluto detect-files -d ./manifests/
pluto detect-helm -owide
```

## Validation Tasks

### Phase 1: Static Analysis (Week 1)
- [ ] Scan all Helm charts with pluto
- [ ] Scan ARM templates for API versions
- [ ] Check Flux Kustomizations
- [ ] Review GitOps manifests

### Phase 2: Cluster Scanning (Week 2)
- [ ] Run kubent against dev clusters
- [ ] Generate deprecation report
- [ ] Identify resources needing updates
- [ ] Create remediation plan

### Phase 3: Remediation (Week 3-4)
- [ ] Update deprecated APIs
- [ ] Test changes in dev
- [ ] Roll out to pre-prod
- [ ] Document changes

## Scanning Commands

### Scan Helm Charts
```bash
# Scan all Helm releases
pluto detect-helm --all-namespaces -owide

# Scan specific namespace
pluto detect-helm -n kube-system -owide
```

### Scan Manifests
```bash
# Scan directory
pluto detect-files -d ./src/main/arm/

# Scan specific file
pluto detect-files -f manifest.yaml
```

### Scan Running Cluster
```bash
# Full cluster scan
kubent

# Output to file
kubent -o text > deprecation-report.txt

# JSON output for parsing
kubent -o json > deprecation-report.json
```

## Common Issues to Check

### 1. Deprecated Annotations
```yaml
# Check for deprecated service annotations
kubectl get services -A -o yaml | grep -E "topology-mode|traffic-policy"
```

### 2. Old API Versions
```yaml
# Check for old API versions in manifests
grep -r "apiVersion.*v1beta1" ./manifests/
```

### 3. Removed FlowSchemas
```bash
# Check for deprecated FlowSchemas
kubectl get flowschemas -o json | jq '.items[] | select(.metadata.name | test("endpoint-controller|workload-leader-election"))'
```

## Validation Report Template

```markdown
# API Compatibility Report
**Date:** YYYY-MM-DD
**Target Version:** 1.34
**Scanned:** [Cluster/Manifests/Charts]

## Summary
- Total Resources Scanned: X
- Deprecated APIs Found: X
- Removed APIs Found: X
- Action Required: Yes/No

## Deprecated APIs
| Kind | Name | Namespace | Current API | Replacement | Target Removal |
|------|------|-----------|-------------|-------------|----------------|
| ... | ... | ... | ... | ... | ... |

## Removed APIs
| Kind | Name | Namespace | Issue |
|------|------|-----------|-------|
| None | N/A | N/A | K8s 1.34 has no removals |

## Recommendations
1. ...
2. ...
```

## Remediation Priority

| Priority | Criteria | Action |
|----------|----------|--------|
| P1 - Critical | Removed APIs | Immediate fix |
| P2 - High | Deprecated (removal < 2 versions) | Fix before upgrade |
| P3 - Medium | Deprecated (removal > 2 versions) | Schedule fix |
| P4 - Low | Warnings only | Track for future |

## Success Criteria

- [ ] Zero removed APIs in workloads
- [ ] Deprecated APIs documented
- [ ] Remediation plan for all P2+ issues
- [ ] kubent returns clean scan
- [ ] All Helm charts validated

---
**Labels:** `testing`, `api-compatibility`, `aks-upgrade`, `version-1.34`  
**Priority:** High  
**Effort:** Medium (1-2 weeks)
