# [FEATURE] ServiceAccount Token-Based Image Pull Authentication

## Summary

Kubernetes 1.34 promotes ServiceAccount tokens for image pulls to beta (KEP-4412). This enables short-lived, audience-bound tokens for container registry authentication, eliminating the need for long-lived imagePullSecrets.

## Background

Currently, image pull authentication typically uses:
- Long-lived Secrets (imagePullSecrets)
- Service principal credentials
- Managed identity (AKS-specific)

The new feature allows pods to authenticate to registries using their ServiceAccount identity with short-lived tokens.

## Benefits

| Current State | New Capability |
|--------------|----------------|
| Long-lived secrets | Short-lived tokens (hours) |
| Manual rotation | Automatic token refresh |
| Broad permissions | Audience-bound (registry-specific) |
| Pod-agnostic | Pod identity-based |

## Current AKS Image Pull Methods

### Review Current Setup
- [ ] Document current imagePullSecret usage
- [ ] Check managed identity integration with ACR
- [ ] Identify registries requiring authentication
- [ ] Review workload identity configurations

### Current Configuration Audit
```bash
# Find pods with imagePullSecrets
kubectl get pods -A -o json | jq -r '.items[] | select(.spec.imagePullSecrets) | "\(.metadata.namespace)/\(.metadata.name)"'

# Check ServiceAccount imagePullSecrets
kubectl get serviceaccounts -A -o json | jq -r '.items[] | select(.imagePullSecrets) | "\(.metadata.namespace)/\(.metadata.name)"'
```

## Feature Configuration

### Enable on ServiceAccount
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: default
imagePullPolicy:
  - audience: "https://myregistry.azurecr.io"
    serviceAccountTokenSpec:
      audience: "https://myregistry.azurecr.io"
      expirationSeconds: 3600
```

### Pod Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  serviceAccountName: my-app
  containers:
  - name: app
    image: myregistry.azurecr.io/myapp:latest
```

## AKS + ACR Considerations

### Current Integration
AKS already supports:
- ACR integration via managed identity
- Workload identity for ACR

### Evaluate Overlap
- [ ] Compare with existing AKS ACR integration
- [ ] Determine if SA tokens provide additional value
- [ ] Check Azure AD federated credential compatibility

## Evaluation Plan

### Phase 1: Research (Week 1)
- [ ] Review K8s 1.34 documentation
- [ ] Check ACR support for SA tokens
- [ ] Compare with AKS managed identity
- [ ] Identify use cases where SA tokens are better

### Phase 2: Testing (Week 2)
- [ ] Set up test scenario in dev
- [ ] Configure SA with token-based pull
- [ ] Test with ACR
- [ ] Test with external registries

### Phase 3: Recommendation (Week 3)
- [ ] Document findings
- [ ] Create comparison matrix
- [ ] Recommend adoption strategy

## Comparison Matrix

| Feature | imagePullSecrets | Managed Identity | SA Tokens |
|---------|------------------|------------------|-----------|
| Token lifetime | Long-lived | Short-lived | Short-lived |
| Rotation | Manual | Automatic | Automatic |
| Multi-registry | Easy | Complex | Easy |
| AKS native | Yes | Yes | Beta |
| External registries | Yes | Limited | Yes |

## Use Cases to Evaluate

1. **Multi-cloud registries** - SA tokens may simplify auth
2. **Cross-tenant registries** - Could reduce credential management
3. **Third-party registries** - DockerHub, GCR, etc.
4. **Security-sensitive workloads** - Short-lived tokens preferred

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Beta stability | Low | Medium | Wait for GA |
| Registry support | Medium | High | Test thoroughly |
| AKS compatibility | Low | Medium | Test with ACR |

## Acceptance Criteria

- [ ] Feature documentation reviewed
- [ ] Comparison with existing methods complete
- [ ] Test scenarios executed
- [ ] Recommendation documented
- [ ] Decision on adoption recorded

---
**Labels:** `feature`, `security`, `registry`, `aks-upgrade`, `version-1.34`  
**Priority:** Low (beta feature, existing alternatives work)  
**Effort:** Medium
