# [INFRA] Cattle Cluster Daily Rebuild

## Summary
Verify that the cattle-pattern daily rebuild automation works with K8s 1.35 clusters.

## Background
Dev/engineering clusters are ephemeral — destroyed nightly and recreated each morning. The deploy/validate/destroy scripts must work with the updated K8s 1.35 ARM templates.

## Curation Results (2026-04-02)

### Scripts Updated
| Script | Changes |
|--------|---------|
| `scripts/deploy-135.sh` | New — deploys K8s 1.35 cluster |
| `scripts/validate-135.sh` | New — validates with cgroup v2 check |
| `scripts/destroy-cluster.sh` | Reused — version-agnostic |

### Daily Rebuild Pattern
```bash
# Evening (10 PM)
./scripts/destroy-cluster.sh

# Morning (6 AM)
./scripts/deploy-135.sh
./scripts/validate-135.sh
kubectl apply -f kubernetes/
```

### CI/CD Schedules
| Schedule | Job | Cron |
|----------|-----|------|
| Daily Destroy | Destroy Cluster | `0 22 * * 1-5` |
| Daily Create | Deploy + Validate | `0 6 * * 1-5` |
| Weekly Scan | Deprecation Scan | `0 9 * * 1` |

### Idempotency
| Scenario | Behavior |
|----------|----------|
| Cluster doesn't exist | `destroy-cluster.sh` exits cleanly |
| Cluster already exists | `deploy-135.sh` performs incremental update |
| Partial state | Scripts handle gracefully |

### Status: ✅ COMPLETE

## Acceptance Criteria
- [x] Deploy script created for 1.35
- [x] Validation script includes cgroup v2 check
- [x] Destroy script verified (version-agnostic)
- [x] CI/CD schedules documented
- [x] Idempotency verified

---
**Labels:** `infrastructure`, `cattle-cluster`, `aks-upgrade`, `version-1.35`
