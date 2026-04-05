# [TEST] Non-Production Upgrade Testing

## Summary
Validate AKS 1.35 upgrade in non-production environments before production rollout.

## Background
Before rolling out K8s 1.35 to production, the upgrade path must be tested in dev/engineering clusters. This includes ARM template deployment, workload compatibility, and new validation checks.

## Curation Results (2026-04-02)

### Scripts Created
| Script | Purpose |
|--------|---------|
| `scripts/deploy-135.sh` | Deploy AKS 1.35 cluster |
| `scripts/validate-135.sh` | Validate cluster health |
| `scripts/destroy-cluster.sh` | Teardown (reused) |

### Test Procedure
```bash
# 1. Deploy
./scripts/deploy-135.sh

# 2. Validate
./scripts/validate-135.sh

# 3. Deploy workloads
kubectl apply -f kubernetes/namespaces.yaml
kubectl apply -f kubernetes/AT-app1/
kubectl apply -f kubernetes/AT-app2/

# 4. Verify workloads
kubectl get pods -A

# 5. Destroy
./scripts/destroy-cluster.sh
```

### Validation Checks
| Check | Expected | New for 1.35? |
|-------|----------|---------------|
| K8s version | 1.35.x | Updated |
| Node status | All Ready | No |
| Node OS | Ubuntu 24.04 / AL3 | No |
| Containerd | 2.x | No |
| cgroup | v2 | **Yes** |
| CoreDNS | Running | No |
| CSI drivers | Installed | No |
| Workloads | Running | No |
| DNS | Resolving | No |
| PVCs | Bound | No |
| Pluto scan | Clean | Updated target |

### Status: ✅ SCRIPTS READY

## Acceptance Criteria
- [x] Deploy script created and tested
- [x] Validation script created with 1.35-specific checks
- [x] Destroy script verified (reused from 1.34)
- [x] Test procedure documented

---
**Labels:** `test`, `upgrade`, `aks-upgrade`, `version-1.35`
