# AKS Backup PoC Architecture

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Azure Subscription                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────┐  ┌─────────────────────────────────┐  │
│  │    rg-aksbkppoc (Main RG)       │  │  rg-aksbkppoc-snapshots         │  │
│  │                                 │  │                                 │  │
│  │  ┌───────────────────────────┐  │  │  ┌───────────────────────────┐  │  │
│  │  │    AKS Cluster            │  │  │  │   Disk Snapshots          │  │  │
│  │  │    (aks-aksbkppoc)        │  │  │  │                           │  │  │
│  │  │                           │  │  │  │   - mysql-pvc snapshot    │  │  │
│  │  │  ┌─────────────────────┐  │  │  │  │                           │  │  │
│  │  │  │  at-app1 namespace  │  │  │  │  └───────────────────────────┘  │  │
│  │  │  │  ┌───────────────┐  │  │  │  │                                 │  │
│  │  │  │  │ nginx (x2)    │  │  │  │  └─────────────────────────────────┘  │
│  │  │  │  └───────────────┘  │  │  │                                       │
│  │  │  └─────────────────────┘  │  │                                       │
│  │  │                           │  │                                       │
│  │  │  ┌─────────────────────┐  │  │                                       │
│  │  │  │  at-app2 namespace  │  │  │                                       │
│  │  │  │  ┌───────────────┐  │  │  │                                       │
│  │  │  │  │ MySQL + PVC   │  │  │  │                                       │
│  │  │  │  │ (5Gi)         │  │  │  │                                       │
│  │  │  │  └───────────────┘  │  │  │                                       │
│  │  │  │  ┌───────────────┐  │  │  │                                       │
│  │  │  │  │ BackupHook    │  │  │  │                                       │
│  │  │  │  │ RestoreHook   │  │  │  │                                       │
│  │  │  │  └───────────────┘  │  │  │                                       │
│  │  │  └─────────────────────┘  │  │                                       │
│  │  │                           │  │                                       │
│  │  │  ┌─────────────────────┐  │  │                                       │
│  │  │  │ Backup Extension    │  │  │                                       │
│  │  │  │ (dataprotection-    │  │  │                                       │
│  │  │  │  microsoft ns)      │──────────────┐                              │
│  │  │  └─────────────────────┘  │  │        │                              │
│  │  └───────────────────────────┘  │        │                              │
│  │                                 │        │                              │
│  │  ┌───────────────────────────┐  │        │                              │
│  │  │   Backup Vault            │  │        │                              │
│  │  │   (bvault-aksbkppoc)      │◄─────────┘                              │
│  │  │                           │  │                                       │
│  │  │   - Backup Policy         │  │                                       │
│  │  │   - Backup Instance       │  │                                       │
│  │  │   - Recovery Points       │  │                                       │
│  │  └───────────────────────────┘  │                                       │
│  │                │                │                                       │
│  │                │ stores metadata│                                       │
│  │                ▼                │                                       │
│  │  ┌───────────────────────────┐  │                                       │
│  │  │   Storage Account         │  │                                       │
│  │  │   (staksbkppocbackup)     │  │                                       │
│  │  │                           │  │                                       │
│  │  │   └── aks-backups/        │  │                                       │
│  │  │       (blob container)    │  │                                       │
│  │  └───────────────────────────┘  │                                       │
│  │                                 │                                       │
│  └─────────────────────────────────┘                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Descriptions

### AKS Cluster (aks-aksbkppoc)

- **Purpose**: Kubernetes cluster hosting the sample applications
- **Configuration**:
  - Single node pool (1x Standard_B2ms)
  - Azure CNI Overlay networking
  - System-assigned managed identity
  - OIDC issuer enabled (for workload identity)
  - Azure Disk CSI driver enabled
  - Snapshot controller enabled

### Sample Applications

#### AT-app1 (Stateless)

- **Purpose**: Demonstrate backup of stateless workloads
- **Components**:
  - nginx deployment (2 replicas)
  - ClusterIP service
- **Backup Behavior**: Kubernetes manifests are backed up

#### AT-app2 (Stateful)

- **Purpose**: Demonstrate backup of stateful workloads with persistent storage
- **Components**:
  - MySQL deployment (1 replica)
  - PersistentVolumeClaim (5Gi, managed-csi)
  - Secret (MySQL root password)
  - ClusterIP service
  - BackupHook and RestoreHook CRDs
- **Backup Behavior**: Kubernetes manifests AND disk snapshots are backed up

### Backup Infrastructure

#### Backup Vault (bvault-aksbkppoc)

- **Purpose**: Central management plane for backup operations
- **Configuration**:
  - Locally redundant storage (cost optimization)
  - System-assigned managed identity
  - Soft delete disabled (for easy cleanup)
- **Contains**:
  - Backup policies
  - Backup instances
  - Recovery points (metadata)

#### Storage Account (staksbkppocbackup)

- **Purpose**: Store backup metadata and manifests
- **Configuration**:
  - Standard_LRS (cost optimization)
  - Blob container: aks-backups

#### Backup Policy (policy-daily)

- **Purpose**: Define backup schedule and retention
- **Configuration**:
  - Daily backup at 02:00 UTC
  - Operational tier retention: 1 day
  - Vault tier: disabled (cost optimization)

### Snapshot Resource Group (rg-aksbkppoc-snapshots)

- **Purpose**: Store Azure Disk snapshots for PVC backup
- **Contains**: Incremental snapshots of persistent volumes

## Data Flow

### Backup Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Trigger   │     │  Pre-Hook   │     │   Backup    │     │  Post-Hook  │
│   Backup    │────►│  Execution  │────►│  Operation  │────►│  Execution  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                           │                   │
                           ▼                   ▼
                    ┌─────────────┐     ┌─────────────┐
                    │ MySQL FLUSH │     │  Snapshot   │
                    │ TABLES WITH │     │  PVC Disk   │
                    │ READ LOCK   │     │             │
                    └─────────────┘     │  Store K8s  │
                                        │  Manifests  │
                                        └─────────────┘
```

1. **Trigger**: Backup is triggered (on-demand or scheduled)
2. **Pre-Hook**: MySQL executes `FLUSH TABLES WITH READ LOCK`
3. **Backup**:
   - Kubernetes manifests are stored in blob storage
   - Azure Disk snapshots are created in snapshot resource group
4. **Post-Hook**: MySQL executes `UNLOCK TABLES`

### Restore Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Trigger   │     │   Restore   │     │  Resource   │     │  Post-Hook  │
│   Restore   │────►│   PVCs/     │────►│  Recreation │────►│  Execution  │
└─────────────┘     │   Disks     │     └─────────────┘     └─────────────┘
                    └─────────────┘                                │
                           │                                       ▼
                           ▼                                ┌─────────────┐
                    ┌─────────────┐                         │   MySQL     │
                    │ Create Disk │                         │   Health    │
                    │ from        │                         │   Check     │
                    │ Snapshot    │                         └─────────────┘
                    └─────────────┘
```

1. **Trigger**: Restore is triggered from a recovery point
2. **Restore PVCs**: Create new disks from snapshots
3. **Resource Recreation**: Apply Kubernetes manifests
4. **Post-Hook**: Verify MySQL is healthy and responsive

## Hook Execution Flow

### Backup Hook

```yaml
Pre-Hook (mysql-flush-lock):
├── Container: mysql
├── Command: mysql -u root -p$PASSWORD -e "FLUSH TABLES WITH READ LOCK; SELECT SLEEP(30);"
├── Timeout: 60s
└── OnError: Continue

Post-Hook (mysql-unlock):
├── Container: mysql
├── Command: mysql -u root -p$PASSWORD -e "UNLOCK TABLES;"
├── Timeout: 30s
└── OnError: Continue
```

### Restore Hook

```yaml
Post-Hook (mysql-health-check):
├── Container: mysql
├── Command: Loop checking mysqladmin ping until ready
├── Timeout: 300s
├── WaitTimeout: 5m
└── OnError: Continue
```

## Security Considerations

### RBAC Assignments

| Principal | Role | Scope |
|-----------|------|-------|
| Backup Vault MSI | Reader | AKS Cluster |
| Backup Vault MSI | Contributor | AKS Cluster |
| Backup Vault MSI | Contributor | Snapshot Resource Group |
| Backup Vault MSI | Storage Account Contributor | Storage Account |
| Backup Vault MSI | Storage Blob Data Contributor | Storage Account |

### Trusted Access

The Backup Vault uses Azure Trusted Access to communicate with the AKS cluster:
- Role: `Microsoft.DataProtection/backupVaults/backup-operator`
- Binding: `backup-vault-binding`

## Network Flow

```
┌────────────┐          ┌────────────┐          ┌────────────┐
│  Azure     │◄────────►│  Backup    │◄────────►│  AKS       │
│  Portal/   │  REST    │  Vault     │  Trusted │  Cluster   │
│  CLI       │  API     │            │  Access  │            │
└────────────┘          └────────────┘          └────────────┘
                              │
                              │ Blob Storage
                              ▼
                        ┌────────────┐
                        │  Storage   │
                        │  Account   │
                        └────────────┘
```

## Failure Modes and Recovery

| Failure | Detection | Recovery |
|---------|-----------|----------|
| Hook timeout | Job shows warning | Backup continues (onError: Continue) |
| Snapshot failure | Job fails | Retry backup or check disk state |
| Extension pod crash | Pods not running | Reinstall extension |
| Restore conflict | Validation error | Use Skip conflict policy |
| MySQL crash loop | Pod CrashLoopBackOff | Check PVC binding, debug MySQL |
