# AKS Backup Implementation Guide

A concise reference for implementing Azure Backup for AKS. Contains critical version information, implementation logic, and gotchas discovered during implementation.

## API and CRD Versions

### ARM Template API Versions

| Resource | API Version | Notes |
|----------|-------------|-------|
| Microsoft.ContainerService/managedClusters | 2024-01-01 | AKS cluster |
| Microsoft.DataProtection/backupVaults | 2023-11-01 | Backup vault |
| Microsoft.DataProtection/backupVaults/backupPolicies | 2023-11-01 | Backup policy |
| Microsoft.Storage/storageAccounts | 2023-01-01 | Storage for backup blobs |
| Microsoft.Authorization/roleAssignments | 2022-04-01 | RBAC assignments |

### Kubernetes CRD API Groups

| CRD | API Group | Version |
|-----|-----------|---------|
| BackupHook | clusterbackup.dataprotection.microsoft.com | v1alpha1 |
| RestoreHook | clusterbackup.dataprotection.microsoft.com | v1alpha1 |
| Backup | clusterbackup.dataprotection.microsoft.com | v1alpha1 |
| Restore | clusterbackup.dataprotection.microsoft.com | v1alpha1 |

**IMPORTANT:** The API group is `clusterbackup.dataprotection.microsoft.com`, NOT `dataprotection.microsoft.com`.

### Azure CLI Extension Versions

```bash
# Required extensions (auto-installed)
az extension add --name k8s-extension
az extension add --name dataprotection
```

## Implementation Logic Flow

### Phase 1: Infrastructure Setup

```
1. Create Resource Groups
   ├── Main RG: rg-{prefix}
   └── Snapshot RG: rg-{prefix}-snapshots  # Required for disk snapshots

2. Deploy AKS Cluster
   ├── Enable CSI disk driver (required for PV backup)
   ├── Enable snapshot controller (required for PV backup)
   ├── System-assigned managed identity
   └── Use supported K8s version (check with `az aks get-versions`)

3. Deploy Backup Infrastructure
   ├── Storage Account (for backup metadata)
   │   └── Container: aks-backups
   ├── Backup Vault (LocallyRedundant for PoC)
   │   └── Soft-delete: Off (for easy cleanup)
   └── Backup Policy (daily schedule)
```

### Phase 2: Extension and RBAC Setup

```
4. Install Backup Extension
   ├── Extension type: Microsoft.DataProtection.Kubernetes
   ├── Config: blobContainer, storageAccount, storageAccountResourceGroup
   └── Get extension identity for RBAC

5. Configure RBAC (CRITICAL - Multiple Identities!)

   Backup Vault MSI needs:
   ├── Reader on AKS cluster
   ├── Contributor on AKS cluster (for restore)
   ├── Reader on Snapshot RG
   ├── Storage Account Contributor on Storage Account
   └── Storage Blob Data Contributor on Storage Account

   AKS Cluster MSI needs:
   └── Contributor on Snapshot RG

   Extension MSI needs:
   └── Storage Blob Data Contributor on Storage Account  ← Often missed!

6. Create Trusted Access Binding
   └── Role: Microsoft.DataProtection/backupVaults/backup-operator
```

### Phase 3: Backup Configuration

```
7. Deploy Backup/Restore Hooks (optional)
   ├── Use correct CRD API group
   ├── BackupHook: preHooks + postHooks
   │   └── exec.timeout (not just timeout)
   └── RestoreHook: postHooks only
       └── exec.execTimeout and exec.waitTimeout

8. Configure Backup Instance
   ├── Initialize backup config (--include-cluster-scope-resources)
   ├── Initialize backup instance
   ├── Validate for backup
   └── Create backup instance
```

## Critical Gotchas

### 1. Kubernetes Version Compatibility

```
GOTCHA: Versions 1.29 and 1.30 are LTS-only as of 2026
FIX: Use az aks get-versions to check available non-LTS versions
```

### 2. Node Pool Sizing

```
GOTCHA: Backup extension pods need ~500m CPU minimum
FIX: Single Standard_B2ms node is insufficient
     Scale to 2 nodes OR use Standard_D2s_v3
```

### 3. Extension Identity vs Backup Vault Identity

```
GOTCHA: Extension has its OWN managed identity, separate from Backup Vault
FIX: Get extension identity with:
     az k8s-extension show --query "aksAssignedIdentity.principalId"

     Assign Storage Blob Data Contributor to extension MSI
```

### 4. Snapshot Resource Group Permissions

```
GOTCHA: Error "UserErrorMissingMSIPermissionsOnSnapshotResourceGroup"
FIX:
  - AKS MSI needs Contributor on snapshot RG
  - Backup Vault MSI needs Reader on snapshot RG
```

### 5. BackupHook CRD Schema

```yaml
# WRONG (old/incorrect API group)
apiVersion: dataprotection.microsoft.com/v1alpha1

# CORRECT
apiVersion: clusterbackup.dataprotection.microsoft.com/v1alpha1

# BackupHook structure
spec:
  backupHook:           # Array of hooks
    - name: string
      includedNamespaces:  # Not applicationPodSelector!
        - namespace
      preHooks:
        - exec:
            command: []
            container: string
            timeout: string    # For backup hooks
            onError: Continue
      postHooks:
        - exec:
            command: []
            container: string
            timeout: string
            onError: Continue

# RestoreHook structure (different timeout fields!)
spec:
  restoreHook:
    - name: string
      includedNamespaces:
        - namespace
      postHooks:
        - exec:
            command: []
            container: string
            execTimeout: string    # Different from BackupHook!
            waitTimeout: string    # Additional field
            onError: Continue
```

### 6. Restore Configuration

```
GOTCHA: include_cluster_scope_resources affects namespace restoration
        Setting to false may not restore the namespace itself

GOTCHA: Restore completes instantly with 0 resources if namespace doesn't exist

FIX: Set include_cluster_scope_resources: true
     OR create namespace before restore
```

### 7. Azure CLI JSON Output with Warnings

```
GOTCHA: az commands output warnings to stdout, corrupting JSON
FIX: Use 2>/dev/null when piping JSON output

# Example
az dataprotection ... 2>/dev/null > file.json
```

## Backup Instance Configuration Parameters

```json
{
  "conflict_policy": "Skip",
  "include_cluster_scope_resources": true,
  "included_namespaces": ["ns1", "ns2"],
  "persistent_volume_restore_mode": "RestoreWithVolumeData",
  "object_type": "KubernetesClusterRestoreCriteria"
}
```

## Required Azure Provider Registrations

```bash
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.DataProtection
```

## Useful Commands Reference

```bash
# Check extension status
az k8s-extension show --name azure-aks-backup --cluster-name CLUSTER \
  --resource-group RG --cluster-type managedClusters

# Get extension identity
az k8s-extension show --name azure-aks-backup --cluster-name CLUSTER \
  --resource-group RG --cluster-type managedClusters \
  --query "aksAssignedIdentity.principalId" -o tsv

# List backup instances
az dataprotection backup-instance list --resource-group RG --vault-name VAULT

# List recovery points
az dataprotection recovery-point list --resource-group RG \
  --vault-name VAULT --backup-instance-name INSTANCE

# Monitor job status
az dataprotection job list --resource-group RG --vault-name VAULT \
  --query "[?properties.operationCategory=='Backup']"

# Check cluster CRDs
kubectl get crd | grep dataprotection

# Check backup extension pods
kubectl get pods -n dataprotection-microsoft

# View backup/restore resources
kubectl get backups,restores -n dataprotection-microsoft
```

## Cost Optimization Tips

| Resource | PoC Config | Production Config |
|----------|-----------|-------------------|
| AKS Tier | Free | Standard |
| Storage | Standard_LRS | Standard_GRS |
| Backup Vault | LocallyRedundant | GeoRedundant |
| Retention | 1 day | Per policy requirements |
| Soft Delete | Off | On |

## Estimated Timeline

| Phase | Duration |
|-------|----------|
| Infrastructure deployment | 15-20 min |
| AKS cluster creation | 8-12 min |
| Extension installation | 5-10 min |
| First backup | 3-5 min |
| Restore operation | 3-5 min |
| Role propagation | 1-2 min |

## Known Issues (as of Jan 2026)

1. **Restore may not recreate namespaces** - Even with `include_cluster_scope_resources: true`, namespaces may not be restored. Create namespace manually before restore.

2. **Extension timeout on small nodes** - Helm installation times out if insufficient CPU. Scale node pool before installing extension.

3. **CLI extension auto-install warnings** - First run of dataprotection commands may fail while extension installs. Retry the command.

4. **Role propagation delays** - RBAC assignments may take 1-2 minutes to propagate. Add delays in automation scripts.
