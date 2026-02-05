# AKS 1.34 Developer Migration Guide

## Overview

This guide helps developers prepare their workloads for Kubernetes 1.34 on AKS.

**Target Audience:** Application teams deploying workloads to AKS
**K8s Version:** 1.34.x (GA January 2026)

---

## TL;DR - Quick Checklist

For most workloads, **no changes are required**. Run these checks to verify:

```bash
# Check for AppArmor annotations (deprecated)
kubectl get pods -A -o json | jq -r '.items[] | select(.metadata.annotations != null) | select(.metadata.annotations | keys[] | contains("apparmor")) | "\(.metadata.namespace)/\(.metadata.name)"'

# Check for topology annotations (deprecated)
kubectl get svc -A -o json | jq -r '.items[] | select(.metadata.annotations != null) | select(.metadata.annotations | keys[] | test("topology|traffic-policy")) | "\(.metadata.namespace)/\(.metadata.name)"'
```

If both return empty results, your workloads are ready for 1.34.

---

## What's New in K8s 1.34

### GA Features (Generally Available)

| Feature | Description | Relevant For |
|---------|-------------|--------------|
| **Dynamic Resource Allocation** | Standardized GPU/FPGA allocation | AI/ML workloads |
| **VolumeAttributesClass** | Modify volume IOPS/throughput on-the-fly | Storage-intensive apps |
| **Job Pod Replacement Policy** | Prevent simultaneous pod execution | Batch jobs |
| **trafficDistribution** | First-class service traffic routing | All services |

### Platform Changes

| Change | Impact |
|--------|--------|
| Ubuntu 24.04 default | New node OS for K8s 1.34+ |
| Azure Linux 3.0 | New AzureLinux default |
| Containerd 2.x | Container runtime upgrade |

---

## What's Deprecated

### 1. AppArmor Annotations

**Status:** Deprecated in 1.34, removal TBD
**Action:** Migrate to seccomp profiles

#### Before (Deprecated)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  annotations:
    container.apparmor.security.beta.kubernetes.io/my-container: runtime/default
spec:
  containers:
  - name: my-container
    image: nginx
```

#### After (Recommended)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: my-container
    image: nginx
```

### 2. Service Topology Annotations

**Status:** Deprecated in 1.34, removal in 1.38
**Action:** Use `.spec.trafficDistribution`

#### Before (Deprecated)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    service.kubernetes.io/topology-mode: "Auto"
spec:
  selector:
    app: my-app
  ports:
  - port: 80
```

#### After (Recommended)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  trafficDistribution: PreferClose  # or PreferSameZone, PreferSameNode
  selector:
    app: my-app
  ports:
  - port: 80
```

#### Traffic Distribution Options

| Value | Behavior |
|-------|----------|
| `PreferClose` | Route to topologically close endpoints |
| `PreferSameZone` | Prefer same availability zone |
| `PreferSameNode` | Prefer same node |

---

## Self-Service Compatibility Check

### 1. Scan Your Manifests

```bash
# Check for deprecated AppArmor annotations
grep -r "apparmor.security.beta.kubernetes.io" ./manifests/

# Check for deprecated topology annotations
grep -r "topology-mode\|traffic-policy" ./manifests/

# Check for old API versions
grep -r "apiVersion.*v1beta1" ./manifests/
```

### 2. Scan Running Workloads

```bash
# AppArmor usage
kubectl get pods -n <your-namespace> -o json | jq '.items[].metadata.annotations | select(. != null) | keys[]' | grep -i apparmor

# Topology annotations
kubectl get svc -n <your-namespace> -o json | jq '.items[].metadata.annotations | select(. != null) | keys[]' | grep -i topology
```

### 3. Use API Deprecation Tools

```bash
# Install kubent
curl -sfL https://raw.githubusercontent.com/doitintl/kube-no-trouble/master/scripts/install.sh | sh

# Scan cluster
kubent

# Install pluto
brew install FairwindsOps/tap/pluto

# Scan manifests
pluto detect-files -d ./manifests/
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

Ensure all containers have resource definitions:

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

### VolumeAttributesClass (Storage Tuning)

If you need dynamic storage performance adjustment:

```yaml
apiVersion: storage.k8s.io/v1
kind: VolumeAttributesClass
metadata:
  name: high-performance
driverName: disk.csi.azure.com
parameters:
  skuName: PremiumV2_LRS
  DiskIOPSReadWrite: "5000"
  DiskMBpsReadWrite: "200"
```

### Dynamic Resource Allocation (GPU)

For GPU workloads:

```yaml
apiVersion: resource.k8s.io/v1
kind: ResourceClaim
metadata:
  name: gpu-claim
spec:
  devices:
    requests:
    - name: gpu
      deviceClassName: gpu.nvidia.com
      count: 1
```

---

## Timeline

| Milestone | Date | Action |
|-----------|------|--------|
| K8s 1.34 GA on AKS | Jan 2026 | Begin testing |
| Dev clusters on 1.34 | Q1 2026 | Migrate dev workloads |
| Pre-prod on 1.34 | Q2 2026 | Validation testing |
| Production on 1.34 | Q2 2026 | Full rollout |
| AppArmor removal | ~1.36 | Complete migration |
| Topology annotations removal | 1.38 | Complete migration |

---

## Getting Help

- **Platform Team:** Contact for upgrade questions
- **Documentation:** See `docs/aks-134-runbook.md`
- **Validation:** Run `./scripts/validate-134.sh`

---

## References

- [Kubernetes 1.34 Release Notes](https://kubernetes.io/blog/2025/08/27/kubernetes-v1-34-release/)
- [AKS Release Notes](https://github.com/Azure/AKS/releases)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Seccomp Profiles](https://kubernetes.io/docs/tutorials/security/seccomp/)
