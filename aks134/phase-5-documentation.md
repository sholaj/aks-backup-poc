# Phase 5: Documentation

**Status:** 🔲 PENDING
**Priority:** Medium

---

## Scope

Update documentation and evaluate monitoring improvements.

| Original Ticket | Description | Priority |
|-----------------|-------------|----------|
| 11 - Runbook Updates | Update operational runbooks for 1.34 | Medium |
| 12 - Developer Migration Guide | Guide for tenant teams | High |
| 13 - OpenTelemetry Evaluation | Evaluate OTel preview support | Low |

---

## 1. Runbook Updates

### Runbooks to Update

| Runbook | Changes Needed |
|---------|----------------|
| Cluster Provisioning | Update K8s version references |
| Node Pool Management | Document Ubuntu 24.04 / Azure Linux 3.0 |
| Troubleshooting | Add 1.34-specific diagnostics |
| Upgrade Procedures | Document 1.33 → 1.34 path |

### Key Changes to Document

#### OS Image Changes
```
K8s 1.34+ defaults:
- Ubuntu: 24.04 LTS
- AzureLinux: 3.0
- Containerd: 2.x
```

#### Deprecated Commands
| Old | New/Note |
|-----|----------|
| AppArmor annotations | Use seccomp profiles |
| Cgroup driver flag | Auto-detection (remove flag) |
| Topology annotations | Use .spec.trafficDistribution |

#### New Diagnostics
```bash
# Verify 1.34 components
kubectl version
kubectl get nodes -o wide
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo}'
```

### Checklist
- [ ] Provisioning runbook updated
- [ ] Troubleshooting guide updated
- [ ] Upgrade procedures documented
- [ ] Team notified of changes

---

## 2. Developer Migration Guide

### Target Audience
Tenant teams deploying workloads to the platform.

### Guide Outline

#### What's New in K8s 1.34
- Dynamic Resource Allocation (DRA) for GPU workloads
- VolumeAttributesClass for storage tuning
- trafficDistribution field for service routing

#### What's Deprecated
| Item | Action | Timeline |
|------|--------|----------|
| AppArmor annotations | Migrate to seccomp | Before 1.36 |
| Topology annotations | Use trafficDistribution | Before 1.38 |

#### Migration Examples

**Service Topology (if used)**
```yaml
# Before
metadata:
  annotations:
    service.kubernetes.io/topology-mode: "Auto"

# After
spec:
  trafficDistribution: PreferClose
```

**Security Context (recommended)**
```yaml
# Add to deployments
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
```

#### Self-Service Checks
```bash
# Check for deprecated APIs
kubectl get pods -A -o json | jq '.items[].metadata.annotations | select(. != null) | keys[]' | grep -i apparmor

# Check for topology annotations
kubectl get svc -A -o json | jq '.items[].metadata.annotations | select(. != null) | keys[]' | grep -i topology
```

### Checklist
- [ ] Migration guide drafted
- [ ] Examples tested
- [ ] Guide reviewed
- [ ] Published to internal docs

---

## 3. OpenTelemetry Evaluation

### Background
AKS 1.34 includes preview support for OpenTelemetry-based monitoring as an alternative to Azure Monitor.

### Evaluation Criteria
| Factor | Consideration |
|--------|---------------|
| Maturity | Preview vs GA |
| Integration | Azure Monitor compatibility |
| Cost | Additional infrastructure |
| Complexity | Operational overhead |

### Current Stack
```
Cluster → ama-metrics → DCR → DCE → AMW → Grafana
```

### OTel Alternative
```
Cluster → OTel Collector → OTLP → Azure Monitor / Grafana
```

### Tasks
- [ ] Review OTel preview documentation
- [ ] Assess integration with existing Grafana
- [ ] Evaluate migration complexity
- [ ] Document recommendation

### Decision Framework
- **Adopt if:** Significant benefits, production-ready
- **Defer if:** Preview status, current stack working well

---

## Acceptance Criteria

- [ ] Runbooks updated for 1.34
- [ ] Developer migration guide published
- [ ] OpenTelemetry evaluation completed
- [ ] Team briefed on changes

---
**Labels:** `phase-5`, `documentation`, `aks-upgrade`, `version-1.34`
