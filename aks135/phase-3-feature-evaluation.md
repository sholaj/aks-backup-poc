# Phase 3: Feature Evaluation

**Status:** ✅ COMPLETE
**Completed:** 2026-04-02

---

## Scope

Evaluate new K8s 1.35 GA features for potential adoption.

| Feature | Priority | Decision |
|---------|----------|----------|
| In-Place Pod Resource Updates | Medium | ⏸️ DEFER - Not needed for PoC |
| Image Volumes | Low | ⏸️ DEFER - No OCI volume use case |
| PreferSameNode Traffic Distribution | Low | ⏸️ DEFER - Simple services |
| Native Pod Certificates (beta) | Medium | ⏸️ DEFER - Not GA yet |

---

## 1. In-Place Pod Resource Updates (KEP-1287)

### Overview
In-Place Pod Resource Updates (KEP-1287) allows resizing CPU and memory requests/limits on running pods without restarting them. This is a major production feature reaching GA in 1.35.

### How It Works
```yaml
# Before: must delete and recreate pod to change resources
# After: patch resources on a running pod

kubectl patch pod my-pod --subresource resize --patch '
{
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

### Evaluation Criteria
| Question | This Repo |
|----------|-----------|
| Are pods sensitive to restarts? | ❌ No - PoC workloads |
| Need dynamic resource tuning? | ❌ No - static workloads |
| Running autoscaling (VPA)? | ❌ No - KEDA not configured here |
| Production workloads? | ❌ No - backup PoC only |

### Decision: ⏸️ DEFER

**Rationale:** This is a backup PoC with simple nginx and mysql workloads. In-place resize is most valuable for production workloads where restarts are costly. The feature adds no benefit to the current use case.

**Revisit when:**
- Production workloads are deployed to this cluster
- VPA (Vertical Pod Autoscaler) is configured
- Workloads are sensitive to restarts (databases, stateful apps)
- Cost optimization requires dynamic resource tuning

### Status
- [x] Feature capabilities assessed
- [x] Use case evaluated - **Not applicable for PoC**
- [x] Recommendation documented - **DEFER**

---

## 2. Image Volumes (KEP-4639)

### Overview
Image Volumes allows mounting OCI images as read-only volumes in pods. This is useful for distributing configuration, binaries, or data as container images without running them.

### Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: config-vol
      mountPath: /config
  volumes:
  - name: config-vol
    image:
      reference: myregistry/config-data:v1
      pullPolicy: IfNotPresent
```

### Evaluation
| Question | This Repo |
|----------|-----------|
| Need to distribute config as images? | ❌ No - using ConfigMaps/Secrets |
| Need shared binaries across pods? | ❌ No |
| Using OCI artifacts for non-container data? | ❌ No |

### Decision: ⏸️ DEFER

**Rationale:** The PoC uses standard ConfigMaps and Secrets for configuration. Image Volumes is designed for advanced distribution patterns not needed here.

**Potential future use:**
- Distributing security scanning tools as OCI images
- Sharing large ML model files across pods
- Configuration-as-code patterns with versioned OCI artifacts

### Status
- [x] Feature capabilities assessed
- [x] Use case evaluated - **Not applicable for PoC**
- [x] Recommendation documented - **DEFER**

---

## 3. PreferSameNode Traffic Distribution

### Overview
K8s 1.35 adds `PreferSameNode` as a new `trafficDistribution` option for Services. This routes traffic to endpoints on the same node as the client, reducing network latency and cross-node traffic.

### Example
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  trafficDistribution: PreferSameNode  # NEW in 1.35
  selector:
    app: my-app
  ports:
  - port: 80
```

### Traffic Distribution Options (K8s 1.35)
| Value | Behavior | Since |
|-------|----------|-------|
| `PreferClose` | Topologically close endpoints | 1.34 |
| `PreferSameZone` | Prefer same availability zone | 1.34 |
| `PreferSameNode` | Prefer same node | **1.35** |

### Evaluation
| Question | This Repo |
|----------|-----------|
| Multiple replicas per service? | ❌ No - single replica deployments |
| Cross-node traffic a concern? | ❌ No - single node cluster |
| Need node-local routing? | ❌ No |

### Decision: ⏸️ DEFER

**Rationale:** The PoC runs single-replica deployments on a single-node cluster. Node-local traffic routing provides no benefit. Relevant for multi-node, multi-replica production deployments.

**Revisit when:**
- Multi-node clusters with multiple replicas
- Latency-sensitive services needing node-local routing
- Cost optimization for cross-AZ traffic charges

### Status
- [x] Feature capabilities assessed
- [x] Use case evaluated - **Not applicable for PoC**
- [x] Recommendation documented - **DEFER**

---

## 4. Native Pod Certificates (Beta - KEP-4193)

### Overview
Native Pod Certificates allows the kubelet to issue and automatically rotate TLS certificates for pods. This could serve as an alternative to cert-manager for workload-level certificates.

### How It Works
```
Pod requests cert → Kubelet issues cert via CSR → Auto-renewal before expiry
```

### Evaluation
| Question | This Repo |
|----------|-----------|
| Currently using cert-manager? | ❌ No - learning area |
| Need workload TLS? | ❌ No - PoC services are HTTP |
| Using Istio mTLS? | ✅ Yes (AKS-managed Istio handles mesh mTLS) |

### Decision: ⏸️ DEFER

**Rationale:** This feature is still in **beta** (not GA). The PoC relies on AKS-managed Istio for mTLS between services. Native Pod Certificates may become relevant when cert-manager is integrated or for non-mesh TLS needs.

**Revisit when:**
- Feature reaches GA (expected K8s 1.36 or 1.37)
- cert-manager integration is planned
- Non-Istio services need TLS certificates
- Considering reducing dependency on external cert providers

### Status
- [x] Feature maturity assessed - **Beta (not GA)**
- [x] Use case evaluated - **Not applicable yet**
- [x] Recommendation documented - **DEFER until GA**

---

## Summary

| Feature | Decision | Rationale |
|---------|----------|-----------|
| In-Place Pod Resize | ⏸️ DEFER | No production workloads |
| Image Volumes | ⏸️ DEFER | No OCI volume use case |
| PreferSameNode | ⏸️ DEFER | Single-node, single-replica PoC |
| Native Pod Certs | ⏸️ DEFER | Beta only, Istio handles mTLS |

### Key Insight
This is a **backup PoC repository** — the new K8s 1.35 features target production-grade scenarios. **In-Place Pod Resource Updates** is the most significant GA feature in 1.35 and should be prioritized when production workloads are deployed. All features are documented for future reference.

---

## Acceptance Criteria

- [x] Each feature evaluated for relevance
- [x] Technical feasibility documented
- [x] Adoption decisions recorded
- [x] Future adoption paths documented

---
**Labels:** `phase-3`, `features`, `aks-upgrade`, `version-1.35`
**Decision:** All features deferred - not applicable to backup PoC
