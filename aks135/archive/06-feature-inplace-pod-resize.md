# [FEATURE] In-Place Pod Resource Updates Evaluation

## Summary
In-Place Pod Resource Updates (KEP-1287) reaches GA in K8s 1.35, allowing CPU and memory resize on running pods without restart.

## Background
This is one of the most anticipated Kubernetes features. Previously, changing resource requests/limits required pod deletion and recreation. Now, resources can be patched on running pods.

## Curation Results (2026-04-02)

### How It Works
```bash
kubectl patch pod my-pod --subresource resize --patch '{
  "spec": {
    "containers": [{
      "name": "my-container",
      "resources": {
        "requests": {"cpu": "200m", "memory": "256Mi"},
        "limits": {"cpu": "1", "memory": "512Mi"}
      }
    }]
  }
}'
```

### Evaluation
| Question | This Repo |
|----------|-----------|
| Are pods sensitive to restarts? | ❌ No - PoC workloads |
| Need dynamic resource tuning? | ❌ No - static workloads |
| Running VPA? | ❌ No |
| Production workloads? | ❌ No - backup PoC |

### Decision: ⏸️ DEFER

**Rationale:** Backup PoC with simple nginx and mysql workloads. In-place resize is most valuable for production workloads where restarts are costly.

**Revisit when:**
- Production workloads deployed
- VPA (Vertical Pod Autoscaler) configured
- Cost optimization requires dynamic resource tuning

## Acceptance Criteria
- [x] Feature capabilities assessed
- [x] Use case evaluated
- [x] Recommendation documented

---
**Labels:** `feature`, `resources`, `aks-upgrade`, `version-1.35`
