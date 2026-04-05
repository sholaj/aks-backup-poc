# Phase 5: Documentation

**Status:** ✅ COMPLETE
**Completed:** 2026-04-02

---

## Scope

Update documentation and evaluate new monitoring capabilities.

| Original Ticket | Description | Status |
|-----------------|-------------|--------|
| 11 - Runbook Updates | Update operational runbooks for 1.35 | ✅ Complete |
| 12 - Developer Migration Guide | Guide for tenant teams | ✅ Complete |
| 13 - Native Pod Certificates | Evaluate native cert support (beta) | ✅ Deferred |

---

## Documents Created

| Document | Path | Description |
|----------|------|-------------|
| Operations Runbook | `docs/aks-135-runbook.md` | Cluster operations, troubleshooting, upgrades |
| Migration Guide | `docs/aks-135-migration-guide.md` | Developer guide for workload compatibility |

---

## 1. Runbook Updates ✅

### Created: `docs/aks-135-runbook.md`

Contents:
- Quick reference for 1.35 defaults
- Cluster provisioning procedures
- Node pool management
- Troubleshooting guide with 1.35-specific diagnostics
- Upgrade procedures (1.34 → 1.35)
- Cattle cluster operations
- Monitoring guidance

### Key Sections

| Section | Coverage |
|---------|----------|
| Version Defaults | Ubuntu 24.04, Azure Linux 3.0, Containerd 2.x, cgroup v2 |
| Provisioning | ARM templates, Azure CLI, validation |
| Troubleshooting | Node, pod, DNS, storage issues |
| 1.35 Diagnostics | cgroup v2 verification, WebSocket RBAC, containerd 2.x |
| Upgrade Path | Pre-checks, upgrade commands, validation |

### Checklist
- [x] Provisioning runbook updated
- [x] Troubleshooting guide updated
- [x] Upgrade procedures documented
- [x] Cattle cluster operations documented

---

## 2. Developer Migration Guide ✅

### Created: `docs/aks-135-migration-guide.md`

Contents:
- TL;DR quick checklist
- New features in K8s 1.35
- Breaking changes and migration paths
- Self-service compatibility checks
- Best practices recommendations
- Timeline for migrations

### Migration Examples Included

| Breaking Change | Before | After |
|-----------------|--------|-------|
| WebSocket RBAC | `verbs: ["get"]` on pods/exec | `verbs: ["create"]` on pods/exec |
| cgroup v1 | Manual cgroup driver config | Remove config (auto-detection) |

### Self-Service Checks

```bash
# Check cgroup version on nodes
kubectl debug node/<node-name> -it --image=busybox -- stat -fc %T /sys/fs/cgroup

# Check RBAC policies for WebSocket operations
kubectl get clusterroles -o json | jq -r '.items[] | select(.rules[]?.resources[]? | contains("pods/exec")) | .metadata.name'

# Scan with Pluto against 1.35
pluto detect-files -d ./manifests/ --target-versions k8s=v1.35.0 -o wide

# Forward-looking scan for 1.36
TARGET_K8S_VERSION=1.36 SCAN_MODE=static ./scripts/scan-deprecated-apis.sh
```

### Checklist
- [x] Migration guide drafted
- [x] Examples included
- [x] Self-service checks documented
- [x] Best practices added

---

## 3. Native Pod Certificates Evaluation ✅

### Decision: ⏸️ DEFER

**Rationale:** Native Pod Certificates is in **beta** in K8s 1.35. The current TLS strategy relies on AKS-managed Istio for mTLS. cert-manager is a learning area but not yet deployed.

### Current Stack
```
Service A → Istio sidecar → mTLS → Istio sidecar → Service B
```

### Native Pod Certs Alternative (Future)
```
Pod requests cert → Kubelet issues cert via CSR → Auto-renewal
```

### Evaluation

| Factor | Assessment |
|--------|------------|
| Maturity | Beta (not GA) |
| Current stack | Istio mTLS working |
| Migration effort | Medium |
| Benefit for PoC | Low |

### Recommendation

**Defer Native Pod Certificates** until:
- Feature reaches GA (expected K8s 1.36 or 1.37)
- cert-manager integration is planned
- Non-mesh services need TLS certificates

### Checklist
- [x] Native Pod Certs beta documentation reviewed
- [x] Current TLS stack assessed
- [x] Decision documented
- [x] Recommendation: DEFER

---

## Summary

| Deliverable | Status | Location |
|-------------|--------|----------|
| Operations Runbook | ✅ Created | `docs/aks-135-runbook.md` |
| Migration Guide | ✅ Created | `docs/aks-135-migration-guide.md` |
| Native Pod Certs | ✅ Deferred | Documented above |

---

## Acceptance Criteria

- [x] Runbooks updated for 1.35
- [x] Developer migration guide published
- [x] Native Pod Certificates evaluation completed (decision: defer)
- [x] Documentation ready for team review

---
**Labels:** `phase-5`, `documentation`, `aks-upgrade`, `version-1.35`
