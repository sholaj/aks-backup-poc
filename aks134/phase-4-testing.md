# Phase 4: Testing

**Status:** 🔲 PENDING
**Priority:** High

---

## Scope

Validate AKS 1.34 in non-production environments before rollout.

| Original Ticket | Description | Priority |
|-----------------|-------------|----------|
| 09 - Non-Production Upgrade | Test upgrade path and workload compatibility | High |
| 14 - Cattle Cluster Verification | Verify daily rebuild automation works | High |

---

## 1. Non-Production Upgrade Testing

### Test Strategy

| Cluster Type | Approach |
|--------------|----------|
| Dev clusters | Daily creation on 1.34 |
| Engineering clusters | Ephemeral 1.34 testing |
| Pre-prod | Upgrade existing cluster |

### Test Categories

#### Cluster Provisioning
- [ ] ARM template deployment succeeds
- [ ] All node pools healthy
- [ ] System components running
- [ ] Networking configured correctly

#### Core Functionality
- [ ] Pod scheduling works
- [ ] Service discovery functional
- [ ] DNS resolution working
- [ ] Storage provisioning successful
- [ ] Ingress routing operational

#### Platform Components
- [ ] Azure Backup extension functional
- [ ] Backup hooks execute correctly
- [ ] Restore operations work
- [ ] Monitoring data flowing

#### Workload Validation
- [ ] Sample apps deploy (nginx, mysql)
- [ ] PVCs bind correctly
- [ ] Secrets accessible
- [ ] Network policies enforced

### Validation Commands
```bash
# Deploy cluster
az deployment group create \
  --resource-group rg-aks-backup-poc \
  --template-file arm-templates/02-aks-cluster.json \
  --parameters arm-templates/02-aks-cluster.parameters.json

# Verify K8s version
kubectl version --short

# Verify node OS
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.osImage}'

# Verify containerd
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'

# Deploy workloads
kubectl apply -f kubernetes/namespaces.yaml
kubectl apply -f kubernetes/AT-app1/
kubectl apply -f kubernetes/AT-app2/

# Verify pods
kubectl get pods -A
```

### Performance Baseline
| Metric | Target |
|--------|--------|
| API latency | < 100ms p99 |
| Pod startup | < 30s |
| Scheduling latency | < 5s |
| Resource overhead | < 5% increase |

---

## 2. Cattle Cluster Daily Rebuild

### Objective
Verify dev/engineering clusters can be automatically destroyed and recreated daily on K8s 1.34.

### Prerequisites
- [x] ARM templates updated to K8s 1.34
- [x] API version updated to 2025-01-01
- [ ] Pipeline schedules configured

### Pipeline Configuration

#### Scheduled Destroy (10 PM Mon-Fri)
```yaml
Scheduled Destroy:
  stage: teardown
  script:
    - |
      clusterName=$(az aks list -g $RG --query "[].name" -o tsv)
      if [ -n "$clusterName" ]; then
        az aks delete -g $RG -n $clusterName --yes --no-wait
      fi
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule" && $ACTION == "destroy"
```

#### Scheduled Create (6 AM Mon-Fri)
```yaml
Scheduled Create:
  stage: deploy
  script:
    - az deployment group create \
        --resource-group $RG \
        --template-file arm-templates/02-aks-cluster.json \
        --parameters arm-templates/02-aks-cluster.parameters.json
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule" && $ACTION == "create"
```

### Verification Checklist
- [ ] Manual destroy/create cycle works
- [ ] Scheduled destroy triggers correctly
- [ ] Scheduled create triggers correctly
- [ ] Cluster healthy after recreation
- [ ] Workloads deploy successfully
- [ ] Backup extension reconnects

### Idempotency Tests
| Scenario | Expected Behavior |
|----------|-------------------|
| Cluster already deleted | Script exits cleanly |
| Cluster already exists | Incremental deployment |
| Partial state | Full cleanup and recreate |

---

## Success Criteria

- [ ] Cluster provisions successfully on K8s 1.34
- [ ] All workloads deploy and run
- [ ] Backup/restore operations work
- [ ] Performance within baseline
- [ ] Daily rebuild automation verified
- [ ] No critical issues in testing

---

## Rollback Plan

If critical issues found:
1. Stop 1.34 deployments
2. Document issues
3. Revert to K8s 1.33
4. Engage Azure support if needed

```bash
# Revert parameters
"kubernetesVersion": "1.33"
```

---
**Labels:** `phase-4`, `testing`, `aks-upgrade`, `version-1.34`
