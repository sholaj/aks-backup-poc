# AKS 1.35 Developer Migration Guide

## Overview

This guide helps developers prepare their workloads for Kubernetes 1.35 on AKS.

**Target Audience:** Application teams deploying workloads to AKS
**K8s Version:** 1.35.x "Timbernetes" (GA March 2026)

---

## TL;DR - Quick Checklist

For most workloads, **no changes are required** if you were already compatible with 1.34. Run these checks to verify:

```bash
# Check cgroup version on nodes (CRITICAL — cgroup v1 removed in 1.35)
kubectl debug node/<node-name> -it --image=busybox -- stat -fc %T /sys/fs/cgroup
# Must output: cgroup2fs

# Check RBAC for WebSocket operations (exec/attach/port-forward now need 'create' verb)
kubectl get clusterroles -o json | jq -r '.items[] | select(.rules[]?.resources[]? | contains("pods/exec")) | .metadata.name'

# Scan manifests for deprecated APIs
pluto detect-files -d ./manifests/ --target-versions k8s=v1.35.0 -o wide

# Check for imagePullSecrets (credentials are now re-validated on every pull)
kubectl get secrets -A -o json | jq -r '.items[] | select(.type == "kubernetes.io/dockerconfigjson") | "\(.metadata.namespace)/\(.metadata.name)"'
```

If cgroup is v2, no deprecated APIs are found, and RBAC is updated — your workloads are ready for 1.35.

---

## What's New in K8s 1.35

### GA Features (Generally Available)

| Feature | Description | Relevant For |
|---------|-------------|--------------|
| **In-Place Pod Resource Updates** | Resize CPU/memory without restarting pods | Production workloads |
| **Image Volumes** | Mount OCI images as read-only volumes | Config distribution |
| **PreferSameNode** | Route service traffic to same-node endpoints | Latency-sensitive apps |
| **Fine-Grained Supplemental Groups** | Better control of group IDs in pods | Security-conscious apps |
| **Kubelet Config Drop-In** | Modular kubelet configuration files | Platform ops |

### Platform Changes

| Change | Impact |
|--------|--------|
| cgroup v1 removed | Kubelet will not start on cgroup v1 nodes |
| containerd 1.x final warning | Last K8s version supporting containerd 1.x |
| Azure Linux 2.0 EOL | Node images removed March 31, 2026 |
| Ingress NGINX retired | No further security patches upstream |

---

## Breaking Changes

### 1. cgroup v1 Removed (BLOCKER)

**Status:** Removed in 1.35
**Action:** Verify all nodes use cgroup v2

The kubelet will **refuse to start** on cgroup v1 nodes. This is a hard failure.

#### How to Check
```bash
# Via kubectl debug
kubectl debug node/<node-name> -it --image=busybox -- stat -fc %T /sys/fs/cgroup

# Output:
# cgroup2fs → cgroup v2 (SAFE)
# tmpfs     → cgroup v1 (BLOCKER — must upgrade node OS)
```

#### Safe Node OS Versions
| OS | cgroup Version | Status |
|----|---------------|--------|
| Ubuntu 24.04 | v2 | ✅ Safe |
| Ubuntu 22.04 | v2 | ✅ Safe (but should upgrade for LTS) |
| Azure Linux 3.0 | v2 | ✅ Safe |
| Azure Linux 2.0 | v2 | ⚠️ EOL March 2026, must migrate |

### 2. WebSocket RBAC Enforcement

**Status:** Enforced in 1.35
**Action:** Update RBAC roles granting exec/attach/port-forward access

`kubectl exec`, `kubectl attach`, and `kubectl port-forward` now require `create` permissions on pod subresources, not just `get`.

#### Before (worked in 1.34)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-exec
rules:
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["get"]  # ← no longer sufficient
```

#### After (required in 1.35)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-exec
rules:
- apiGroups: [""]
  resources: ["pods/exec", "pods/attach", "pods/portforward"]
  verbs: ["create"]  # ← required in 1.35
```

#### How to Audit
```bash
# Find all roles granting exec access
kubectl get clusterroles -o json | jq -r '
  .items[] |
  select(.rules[]? | .resources[]? | contains("pods/exec")) |
  .metadata.name'

# Check if a specific role has the right verbs
kubectl get clusterrole <role-name> -o json | jq '.rules[] | select(.resources[]? | contains("pods/exec"))'
```

### 3. Image Pull Credential Re-validation

**Status:** Enforced in 1.35
**Action:** Ensure imagePullSecrets are not expired

Cached images now re-check pull secrets on every pod creation. Expired or rotated secrets will cause `ImagePullBackOff` on pods that previously worked with cached images.

#### How to Check
```bash
# Find all imagePullSecrets
kubectl get secrets -A -o json | jq -r '
  .items[] |
  select(.type == "kubernetes.io/dockerconfigjson") |
  "\(.metadata.namespace)/\(.metadata.name)"'

# Verify a secret is valid
kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq .
```

### 4. IPVS Proxy Mode Deprecated

**Status:** Deprecated in 1.35
**Action:** Plan migration to nftables or eBPF (Cilium)

Only affects clusters using kube-proxy with IPVS mode. Clusters using Cilium (eBPF dataplane) are not affected.

---

## Self-Service Compatibility Check

### 1. Scan Your Manifests

```bash
# Check for deprecated API versions
grep -r "apiVersion.*v1beta1" ./manifests/

# Check for RBAC policies with exec access
grep -r "pods/exec\|pods/attach\|pods/portforward" ./manifests/

# Check for imagePullSecrets usage
grep -r "imagePullSecrets" ./manifests/
```

### 2. Scan Running Workloads

```bash
# Check RBAC for exec
kubectl get clusterroles -o json | jq -r '.items[] | select(.rules[]?.resources[]? | contains("pods/exec")) | .metadata.name'

# Check imagePullSecrets in pods
kubectl get pods -A -o json | jq -r '.items[] | select(.spec.imagePullSecrets != null) | "\(.metadata.namespace)/\(.metadata.name)"'
```

### 3. Use API Deprecation Tools

#### Pluto (Fairwinds)

```bash
# Install
brew install FairwindsOps/tap/pluto

# Scan your namespace manifests against K8s 1.35
pluto detect-files -d ./manifests/ --target-versions k8s=v1.35.0 -o wide

# Scan a running cluster
pluto detect-api-resources --target-versions k8s=v1.35.0 -o wide

# Scan Helm releases
pluto detect-helm --target-versions k8s=v1.35.0 -o wide

# Forward-looking: check if your manifests are ready for K8s 1.36
pluto detect-files -d ./manifests/ --target-versions k8s=v1.36.0 -o wide
```

**Exit codes** — useful for CI/CD integration:

| Exit Code | Meaning | Action |
|-----------|---------|--------|
| 0 | No deprecated APIs | Clean — safe to proceed |
| 1 | Error | Pluto encountered an error — investigate |
| 2 | Deprecated APIs found | Warning — still functional, plan migration |
| 3 | Removed APIs found | Blocker — will break on target version |

**Automated scanning** — use the included scan script:

```bash
# Scan manifest files only (no cluster needed)
SCAN_MODE=static ./scripts/scan-deprecated-apis.sh

# Scan a running cluster
SCAN_MODE=live ./scripts/scan-deprecated-apis.sh

# Override target version for forward-looking scans
TARGET_K8S_VERSION=1.36 SCAN_MODE=static ./scripts/scan-deprecated-apis.sh
```

---

## Recommended Best Practices

### Security Context

Add seccomp profile to all deployments:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      securityContext:
        seccompProfile:
          type: RuntimeDefault
        runAsNonRoot: true
      containers:
      - name: my-app
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
```

### Resource Requests/Limits

Ensure all containers have resource definitions (especially relevant now that In-Place Pod Resource Updates is GA):

```yaml
containers:
- name: my-app
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

### Health Probes

Include readiness and liveness probes:

```yaml
containers:
- name: my-app
  readinessProbe:
    httpGet:
      path: /health
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 10
  livenessProbe:
    httpGet:
      path: /health
      port: 8080
    initialDelaySeconds: 15
    periodSeconds: 20
```

---

## New Features to Consider

### In-Place Pod Resource Updates (GA in 1.35)

Resize CPU/memory on running pods without restart:

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

### Image Volumes (GA in 1.35)

Mount OCI images as read-only volumes:

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

### PreferSameNode Traffic Distribution (GA in 1.35)

Route service traffic to endpoints on the same node:

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

---

## Timeline

| Milestone | Date | Action |
|-----------|------|--------|
| K8s 1.35 GA on AKS | Mar 2026 | Begin testing |
| Azure Linux 2.0 EOL | Mar 2026 | Migrate AL2 node pools |
| Dev clusters on 1.35 | Q2 2026 | Migrate dev workloads |
| Pre-prod on 1.35 | Q2 2026 | Validation testing |
| Production on 1.35 | Q3 2026 | Full rollout |
| Containerd 1.x removal | 1.36 (~Jun 2026) | Verify containerd 2.x |
| IPVS removal | ~1.37 | Migrate to nftables/eBPF |

---

## Getting Help

- **Platform Team:** Contact for upgrade questions
- **Documentation:** See `docs/aks-135-runbook.md`
- **Validation:** Run `./scripts/validate-135.sh`

---

## References

- [Kubernetes 1.35 Release Notes](https://kubernetes.io/blog/2025/12/17/kubernetes-v1-35-release/)
- [AKS Release Notes](https://github.com/Azure/AKS/releases)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Kubernetes Deprecated API Migration Guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)
