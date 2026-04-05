# [MONITOR] Native Pod Certificates Evaluation

## Summary
Evaluate Native Pod Certificates (KEP-4193, beta in 1.35) as a potential alternative to cert-manager for workload-level TLS.

## Background
Native Pod Certificates allows the kubelet to issue and auto-rotate TLS certificates for pods without external tooling. This could reduce dependency on cert-manager for workload certificates.

## Curation Results (2026-04-02)

### How It Works
```
Pod requests cert → Kubelet issues cert via CSR → Auto-renewal before expiry
```

### Current TLS Stack
```
Service A → Istio sidecar → mTLS → Istio sidecar → Service B
```

### Evaluation
| Factor | Assessment |
|--------|------------|
| Maturity | Beta (not GA) |
| Current stack | Istio mTLS working |
| cert-manager in use? | No (learning area) |
| Migration effort | Medium |
| Benefit for PoC | Low |

### Decision: ⏸️ DEFER

**Rationale:** Feature is still in beta. The PoC uses AKS-managed Istio for mTLS between services. cert-manager is a learning area but not yet deployed.

**Revisit when:**
- Feature reaches GA (expected K8s 1.36 or 1.37)
- cert-manager integration is planned
- Non-mesh services need TLS certificates
- Reducing dependency on external cert providers

### Comparison: cert-manager vs Native Pod Certs

| Aspect | cert-manager | Native Pod Certs |
|--------|-------------|------------------|
| Maturity | GA, widely used | Beta |
| Scope | Cluster-wide | Per-pod |
| ACME support | Yes | No |
| External CAs | Yes | No |
| Auto-rotation | Yes | Yes |
| Dependency | External controller | Built into kubelet |

## Acceptance Criteria
- [x] Feature maturity assessed
- [x] Current TLS stack evaluated
- [x] Comparison with cert-manager documented
- [x] Decision documented: DEFER

---
**Labels:** `monitoring`, `certificates`, `aks-upgrade`, `version-1.35`
