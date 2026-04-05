# [FEATURE] PreferSameNode Traffic Distribution Evaluation

## Summary
K8s 1.35 adds `PreferSameNode` as a new `trafficDistribution` option for Services, routing traffic to endpoints on the same node.

## Background
K8s 1.34 introduced `trafficDistribution` with `PreferClose` and `PreferSameZone`. K8s 1.35 adds `PreferSameNode` for node-local endpoint priority, reducing network latency and cross-node traffic.

## Curation Results (2026-04-02)

### Example
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  trafficDistribution: PreferSameNode
  selector:
    app: my-app
  ports:
  - port: 80
```

### Traffic Distribution Options
| Value | Behavior | Since |
|-------|----------|-------|
| `PreferClose` | Topologically close endpoints | 1.34 |
| `PreferSameZone` | Same availability zone | 1.34 |
| `PreferSameNode` | Same node | **1.35** |

### Evaluation
| Question | This Repo |
|----------|-----------|
| Multiple replicas? | ❌ No - single replica |
| Multi-node cluster? | ❌ No - single node |
| Cross-node traffic concern? | ❌ No |

### Decision: ⏸️ DEFER

**Rationale:** Single-replica deployments on a single-node cluster. Node-local routing provides no benefit.

**Revisit when:**
- Multi-node clusters with multiple replicas
- Latency-sensitive services
- Cost optimization for cross-AZ traffic

## Acceptance Criteria
- [x] Feature capabilities assessed
- [x] Use case evaluated
- [x] Recommendation documented

---
**Labels:** `feature`, `networking`, `aks-upgrade`, `version-1.35`
