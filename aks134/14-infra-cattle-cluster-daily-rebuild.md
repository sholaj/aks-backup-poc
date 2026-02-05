# [INFRA] Cattle Cluster Daily Rebuild Verification for AKS 1.34

## Summary

Verify that our cattle-style infrastructure (daily destroy/recreate of dev/engineering clusters) works correctly with AKS 1.34. The dev branch should steadily provision 1.34 clusters with automated daily teardown and recreation.

## Background

Our platform philosophy treats engineering and development clusters as cattle, not pets:
- Clusters are ephemeral and disposable
- Daily destruction prevents configuration drift
- Recreation from dev branch ensures consistency
- Production clusters follow strict change management

## Objectives

1. **Dev branch deploys 1.34:** Default Kubernetes version in dev pipeline is 1.34
2. **Automated daily teardown:** Engineering clusters destroyed every day
3. **Automated recreation:** Fresh clusters built from latest dev branch
4. **Idempotent pipelines:** Support repeated runs without conflicts

## Current Pipeline Structure

```yaml
# From .gitlab-ci.yml
stages:
  - build
  - validate
  - deploy
  - setup
  - test
  - hardening
  - publish
  - teardown
  - maintenance
```

### Existing Jobs
- `Deploy AKS` - Manual trigger
- `Delete Cluster` - Manual teardown
- `Start AKS` / `Stop AKS` - Scheduled operations

## Required Changes

### 1. Update Default Kubernetes Version
```yaml
# env/dev-*.yml
kubernetesVersion: "1.34.x"  # Update from current version
```

### 2. Add Scheduled Destroy Pipeline
```yaml
# Add to .gitlab-ci.yml or create scheduled-teardown.yml

.scheduled-destroy:
  stage: teardown
  script:
    - |
      echo "[INFO] Destroying engineering cluster for daily refresh"
      clusterName=$(az aks list --resource-group ${resourceGroupName} --query "[].name" --output tsv)
      if [ -n "$clusterName" ]; then
        az aks delete \
          --resource-group $resourceGroupName \
          --name $clusterName \
          --yes \
          --no-wait
        echo "[SUCCESS] Cluster $clusterName deletion initiated"
      else
        echo "[INFO] No cluster found in $resourceGroupName"
      fi
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule" && $ACTION_FLAG == "destroy"
      when: always
  extends:
    - .get-vault-secrets

Scheduled Destroy Engineering:
  extends:
    - .scheduled-destroy
  variables:
    resourceGroupName: "rg-eng-dev-westeurope"
  needs:
    - job: 2. Build variables
      artifacts: true
```

### 3. Add Scheduled Create Pipeline
```yaml
.scheduled-create:
  stage: deploy
  script:
    - |
      echo "[INFO] Creating daily engineering cluster"
      # Ensure RG exists
      sh pipelines/scripts/10_ensure_rg_exists.sh
      # Deploy cluster
      sh pipelines/scripts/20_aks_deployment.sh
      # Run setup
      sh pipelines/scripts/30_gitops_setup.sh
      sh pipelines/scripts/31_gitops_setup.sh
      sh pipelines/scripts/40_workload_identity_setup.sh
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule" && $ACTION_FLAG == "create"
      when: always
  extends:
    - .get-vault-secrets

Scheduled Create Engineering:
  extends:
    - .scheduled-create
  variables:
    resourceGroupName: "rg-eng-dev-westeurope"
    kubernetesVersion: "1.34"
  needs:
    - job: 2. Build variables
      artifacts: true
```

### 4. GitLab Schedule Configuration

Create two schedules in GitLab CI/CD > Schedules:

**Schedule 1: Daily Destroy**
- Description: "Destroy engineering clusters"
- Interval: `0 22 * * 1-5` (10 PM Mon-Fri)
- Target branch: `dev`
- Variables:
  - `ACTION_FLAG`: `destroy`
  - `ENV`: `dev`

**Schedule 2: Daily Create**
- Description: "Create engineering clusters"
- Interval: `0 6 * * 1-5` (6 AM Mon-Fri)
- Target branch: `dev`
- Variables:
  - `ACTION_FLAG`: `create`
  - `ENV`: `dev`

## Validation Checklist

### Pre-Implementation
- [ ] Identify all engineering cluster resource groups
- [ ] Confirm no production workloads on target clusters
- [ ] Verify dev branch ARM templates use 1.34
- [ ] Test manual destroy/create cycle

### Implementation
- [ ] Update pipeline with scheduled jobs
- [ ] Configure GitLab schedules
- [ ] Test scheduled destroy (manual trigger first)
- [ ] Test scheduled create (manual trigger first)

### Post-Implementation
- [ ] Monitor first automated cycle
- [ ] Verify cluster comes up healthy
- [ ] Confirm GitOps sync completes
- [ ] Validate monitoring reconnects

## Monitoring Dashboard

Track cattle cluster health:

```promql
# Cluster age (should be < 24h)
time() - kube_node_created

# Successful daily provisions
count(aks_cluster_provision_success{environment="dev"}) by (day)

# Failed provisions
count(aks_cluster_provision_failed{environment="dev"}) by (day)
```

## Idempotency Verification

Ensure pipelines handle edge cases:

### Scenario 1: Cluster Already Deleted
```bash
# Should handle gracefully
clusterName=$(az aks list --resource-group ${resourceGroupName} --query "[].name" --output tsv)
if [ -z "$clusterName" ]; then
  echo "[INFO] No cluster to delete"
  exit 0
fi
```

### Scenario 2: Cluster Already Exists
```bash
# Create should be idempotent (incremental deployment)
az deployment group create \
  --mode Incremental \
  --resource-group $resourceGroupName \
  --template-file $TEMPLATE
```

### Scenario 3: Partial State
```bash
# Destroy should clean up completely
az group deployment delete-rg-content \
  --resource-group $resourceGroupName \
  --confirm-deletion true
```

## Success Criteria

- [ ] Dev branch defaults to K8s 1.34
- [ ] Daily destroy runs at scheduled time
- [ ] Daily create runs after destroy completes
- [ ] Clusters are healthy after creation
- [ ] GitOps reconciles correctly
- [ ] Monitoring pipeline reconnects
- [ ] No manual intervention required
- [ ] Pipeline handles failures gracefully

## Rollback Plan

If daily recreation fails:
1. Disable scheduled pipeline
2. Manual cluster creation
3. Debug and fix pipeline
4. Re-enable when stable

---
**Labels:** `infrastructure`, `cattle-clusters`, `automation`, `aks-upgrade`, `version-1.34`  
**Priority:** High  
**Milestone:** Q2 2025 - Cluster Provisioning Stability Initiative
