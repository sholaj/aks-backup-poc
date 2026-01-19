# AKS Backup Proof of Concept

A complete proof of concept demonstrating Azure Backup for AKS, including infrastructure provisioning, sample application deployment, backup configuration with hooks, and backup/restore testing.

## Overview

This PoC demonstrates:
- Deploying a minimal, cost-optimized AKS cluster
- Deploying stateless (nginx) and stateful (MySQL with PVC) applications
- Configuring Azure Backup for AKS with backup hooks
- Performing on-demand backup with MySQL consistency (FLUSH TABLES WITH READ LOCK)
- Testing disaster recovery by deleting and restoring a namespace
- Validating data integrity after restore

## Prerequisites

- Azure CLI authenticated (`az account show` works)
- GitHub CLI authenticated (`gh auth status` works)
- kubectl available
- Sufficient Azure subscription permissions (Contributor at subscription level recommended)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/sholaj/aks-backup-poc.git
cd aks-backup-poc

# Run scripts in order
./scripts/01-deploy-infrastructure.sh
./scripts/02-deploy-aks.sh
./scripts/03-deploy-backup-infrastructure.sh
./scripts/04-deploy-sample-apps.sh
./scripts/05-install-backup-extension.sh
./scripts/06-deploy-hooks.sh
./scripts/07-configure-backup-instance.sh
./scripts/08-trigger-backup.sh
./scripts/09-test-restore.sh
./scripts/10-validate-restore.sh

# Cleanup when done
./scripts/99-destroy-all.sh
```

## Project Structure

```
aks-backup-poc/
├── README.md                    # This file
├── .gitignore
├── arm-templates/
│   ├── 01-resource-group.json           # Resource group template
│   ├── 02-aks-cluster.json              # AKS cluster template
│   ├── 02-aks-cluster.parameters.json   # AKS parameters
│   ├── 03-backup-infrastructure.json     # Backup vault, storage, policy
│   └── 03-backup-infrastructure.parameters.json
├── kubernetes/
│   ├── namespaces.yaml                  # at-app1, at-app2 namespaces
│   ├── AT-app1/                         # Stateless nginx app
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── AT-app2/                         # Stateful MySQL app
│   │   ├── mysql-secret.yaml
│   │   ├── mysql-pvc.yaml
│   │   ├── mysql-deployment.yaml
│   │   └── mysql-service.yaml
│   └── hooks/                           # Backup/restore hooks
│       ├── backup-hooks.yaml
│       └── restore-hooks.yaml
├── scripts/
│   ├── 00-set-variables.sh              # Configuration variables
│   ├── 01-deploy-infrastructure.sh      # Create resource groups
│   ├── 02-deploy-aks.sh                 # Deploy AKS cluster
│   ├── 03-deploy-backup-infrastructure.sh # Deploy backup vault
│   ├── 04-deploy-sample-apps.sh         # Deploy nginx & MySQL
│   ├── 05-install-backup-extension.sh   # Install backup extension
│   ├── 06-deploy-hooks.sh               # Deploy backup hooks
│   ├── 07-configure-backup-instance.sh  # Configure backup
│   ├── 08-trigger-backup.sh             # Run on-demand backup
│   ├── 09-test-restore.sh               # Test restore
│   ├── 10-validate-restore.sh           # Validate restored data
│   └── 99-destroy-all.sh                # Cleanup all resources
└── docs/
    └── architecture.md                  # Architecture documentation
```

## Configuration

Default values (can be modified in `scripts/00-set-variables.sh`):

| Variable | Value | Description |
|----------|-------|-------------|
| LOCATION | uksouth | Azure region |
| PREFIX | aksbkppoc | Resource naming prefix |
| KUBERNETES_VERSION | 1.29 | Kubernetes version |
| NODE_SIZE | Standard_B2ms | VM size for nodes |
| NODE_COUNT | 1 | Number of nodes |

## Cost Estimate

This PoC is designed to be cost-optimized:

| Resource | Configuration | Est. Monthly Cost |
|----------|--------------|-------------------|
| AKS Cluster | Free tier, 1 node | $0 (AKS) + ~$40 (VM) |
| Storage Account | Standard_LRS | ~$2-5 |
| Backup Vault | Locally Redundant | ~$5-10 |
| Managed Disks | 5Gi Premium | ~$1-2 |
| **Total** | | **~$50-60/month** |

*Run the cleanup script when not in use to minimize costs.*

## Step-by-Step Guide

### Phase 1: Infrastructure (Steps 1-3)

1. **Deploy Infrastructure** - Creates resource groups for main resources and snapshots
2. **Deploy AKS** - Provisions the AKS cluster with Azure CNI Overlay networking
3. **Deploy Backup Infrastructure** - Creates Storage Account, Backup Vault, and Backup Policy

### Phase 2: Applications (Steps 4-6)

4. **Deploy Sample Apps** - Deploys nginx (stateless) and MySQL (stateful with PVC)
5. **Install Backup Extension** - Installs the Azure Backup extension on the AKS cluster
6. **Deploy Hooks** - Deploys backup/restore hooks for MySQL consistency

### Phase 3: Backup & Restore (Steps 7-10)

7. **Configure Backup Instance** - Configures the backup instance with namespace filters
8. **Trigger Backup** - Runs an on-demand backup and waits for completion
9. **Test Restore** - Deletes at-app2 namespace and restores from backup
10. **Validate Restore** - Verifies all resources and data are restored correctly

### Phase 4: Cleanup (Step 99)

99. **Destroy All** - Removes all Azure resources and local configuration

## Troubleshooting

### Backup Extension Installation Fails

```bash
# Check extension status
az k8s-extension show \
    --name azure-aks-backup \
    --cluster-name aks-aksbkppoc \
    --resource-group rg-aksbkppoc \
    --cluster-type managedClusters

# Check extension pods
kubectl get pods -n dataprotection-microsoft
```

### Backup Instance Configuration Fails

```bash
# Verify RBAC assignments
az role assignment list --assignee <backup-vault-principal-id> --all

# Check trusted access binding
az aks trustedaccess rolebinding list \
    --resource-group rg-aksbkppoc \
    --cluster-name aks-aksbkppoc
```

### Restore Fails

```bash
# Check restore job status
az dataprotection job list \
    --resource-group rg-aksbkppoc \
    --vault-name bvault-aksbkppoc \
    --query "[?properties.operationCategory=='Restore']"
```

### MySQL Pod Not Starting After Restore

```bash
# Check PVC status
kubectl get pvc -n at-app2

# Check pod events
kubectl describe pod -n at-app2 -l app.kubernetes.io/name=mysql

# Check persistent volume
kubectl get pv
```

## Success Criteria

The PoC is successful when:

- [x] AKS cluster is running with sample apps
- [x] MySQL has sample data inserted
- [x] Backup Extension is installed
- [x] Backup hooks are deployed
- [x] Backup Instance is configured for AT-* namespaces
- [x] On-demand backup completes successfully
- [x] AT-app2 namespace can be deleted and restored
- [x] MySQL data survives the restore
- [x] All resources are cleaned up at the end

## References

- [Azure Backup for AKS Documentation](https://learn.microsoft.com/azure/backup/azure-kubernetes-service-backup-overview)
- [Backup Hooks Documentation](https://learn.microsoft.com/azure/backup/azure-kubernetes-service-cluster-backup#backup-hooks)
- [AKS Trusted Access](https://learn.microsoft.com/azure/aks/trusted-access-feature)
