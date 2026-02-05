# [DEPRECATION] Service Topology Annotation Updates

## Summary

Service topology annotations are deprecated and scheduled for removal in Kubernetes 1.38. We need to migrate to the new `.spec.trafficDistribution` field in Service specifications.

## Background

The annotations `service.kubernetes.io/topology-mode` and `service.kubernetes.io/traffic-policy` are being replaced by a first-class API field to better control traffic routing.

## Deprecated Annotations

| Deprecated Annotation | Replacement |
|----------------------|-------------|
| `service.kubernetes.io/topology-mode: Auto` | `.spec.trafficDistribution: PreferClose` |
| `service.kubernetes.io/topology-mode: Hostname` | `.spec.trafficDistribution: PreferSameNode` |
| `service.kubernetes.io/traffic-policy: PreferZone` | `.spec.trafficDistribution: PreferSameZone` |

## Current Usage Assessment

### Audit Tasks
- [ ] Scan all namespaces for services with topology annotations
- [ ] Document services using traffic routing annotations
- [ ] Identify impacted tenants

### Audit Script
```bash
#!/bin/bash
# Find services with deprecated topology annotations

kubectl get services -A -o json | jq -r '
  .items[] | 
  select(.metadata.annotations | keys[] | test("topology|traffic-policy")) |
  "\(.metadata.namespace)/\(.metadata.name): \(.metadata.annotations)"
'
```

## Migration Guide

### Before (Deprecated)
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

### After (New API)
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

## Traffic Distribution Options

| Value | Behavior |
|-------|----------|
| `PreferClose` | Route to topologically close endpoints |
| `PreferSameZone` | Prefer endpoints in same availability zone |
| `PreferSameNode` | Prefer endpoints on same node |

## Migration Plan

### Phase 1: Discovery (Week 1)
- [ ] Run audit across all clusters
- [ ] Create inventory of affected services
- [ ] Notify tenant teams

### Phase 2: Documentation (Week 2)
- [ ] Update internal Service templates
- [ ] Create migration guide for tenants
- [ ] Update Helm charts if applicable

### Phase 3: Migration (Week 3-4)
- [ ] Update platform services
- [ ] Support tenant migrations
- [ ] Validate traffic routing behavior

## Timeline

| Version | Status |
|---------|--------|
| K8s 1.34 | Deprecated |
| K8s 1.35-1.37 | Warnings on use |
| K8s 1.38 | Annotations removed |

## Testing

After migration, verify traffic routing:
```bash
# Check service configuration
kubectl get service my-service -o yaml | grep trafficDistribution

# Verify endpoint slices
kubectl get endpointslices -l kubernetes.io/service-name=my-service -o yaml
```

## Acceptance Criteria

- [ ] All platform services migrated
- [ ] No deprecated annotations in platform namespaces
- [ ] Tenant migration guide published
- [ ] Validation tests passing

---
**Labels:** `deprecation`, `networking`, `aks-upgrade`, `version-1.34`  
**Priority:** Low (removal in 1.38)  
**Effort:** Medium
