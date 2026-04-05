# [FEATURE] Image Volumes Evaluation

## Summary
Image Volumes (KEP-4639) reaches GA in K8s 1.35, allowing OCI images to be mounted as read-only volumes in pods.

## Background
Image Volumes enable pods to mount OCI images as volumes without running them as containers. Useful for distributing configuration, binaries, or data packaged as OCI artifacts.

## Curation Results (2026-04-02)

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
| Need config as OCI images? | ❌ No - using ConfigMaps/Secrets |
| Need shared binaries? | ❌ No |
| Using OCI artifacts? | ❌ No |

### Decision: ⏸️ DEFER

**Rationale:** The PoC uses standard ConfigMaps and Secrets. Image Volumes is for advanced distribution patterns not needed here.

**Potential future use:**
- Security scanning tools as OCI images
- ML model distribution
- Configuration-as-code with versioned OCI artifacts

## Acceptance Criteria
- [x] Feature capabilities assessed
- [x] Use case evaluated
- [x] Recommendation documented

---
**Labels:** `feature`, `storage`, `aks-upgrade`, `version-1.35`
