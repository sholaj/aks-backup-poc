# [DOCS] Update Internal Runbooks for AKS 1.34

## Summary

Update all internal platform runbooks and operational documentation to reflect changes in Kubernetes 1.34 and AKS-specific updates.

## Runbooks to Update

### Cluster Operations
- [ ] **Cluster Provisioning Runbook**
  - Update default Kubernetes version
  - Document new OS image defaults (Ubuntu 24.04, Azure Linux 3.0)
  - Update ARM template parameters
  
- [ ] **Cluster Upgrade Runbook**
  - Add 1.34 upgrade path (1.32 → 1.33 → 1.34)
  - Document containerd version requirements
  - Update pre-upgrade checklist

- [ ] **Cluster Troubleshooting Runbook**
  - Add new 1.34-specific diagnostics
  - Update component version references
  - Add DRA troubleshooting (if adopted)

### Monitoring & Observability
- [ ] **Monitoring Setup Runbook**
  - Update Azure Monitor Workspace configuration
  - Document new metrics available in 1.34
  - Add OpenTelemetry integration (if enabled)

- [ ] **Alerting Runbook**
  - Review alert thresholds for new version
  - Update Prometheus rule references
  - Add scheduler queueing hints metrics

### Security
- [ ] **Security Hardening Runbook**
  - Update seccomp profile guidance (AppArmor deprecation)
  - Document anonymous auth restrictions
  - Add workload identity best practices

- [ ] **RBAC Management Runbook**
  - Document finer-grained authorization options
  - Update role binding examples
  - Add field selector authorization examples

### Networking
- [ ] **Networking Runbook**
  - Update service topology configuration
  - Document CNI Overlay Pod CIDR expansion
  - Add Cilium azure-iptables-monitor notes

### Storage
- [ ] **Storage Runbook**
  - Add VolumeAttributesClass documentation
  - Update CSI driver versions
  - Document volume expansion recovery

## Documentation Standards

### Version References
```markdown
<!-- Update all version references -->
| Component | Version |
|-----------|---------|
| Kubernetes | 1.34.x |
| Containerd | 2.x |
| Azure Disk CSI | v1.31.x |
| VPA | 1.4.2 |
```

### Command Updates
```bash
# Ensure all kubectl commands work with 1.34
# Update any version-specific flags
```

## Review Checklist

For each runbook:
- [ ] Version numbers updated
- [ ] Deprecated commands removed
- [ ] New features documented
- [ ] Screenshots updated (if applicable)
- [ ] Links verified
- [ ] Peer reviewed

## New Runbook Sections

### Add to Cluster Operations
```markdown
## Kubernetes 1.34 Specifics

### OS Image Defaults
- K8s 1.34+: Ubuntu 24.04 (previously 22.04)
- AzureLinux: Azure Linux 3.0 (Azure Linux 2.0 retired)

### Containerd Version
- 1.34 includes Containerd 2.1
- Containerd 1.6/1.7 deprecated

### Node Auto-Provisioner
- Compatible with 1.34
- No breaking changes
```

### Add to Security Runbook
```markdown
## AppArmor Deprecation

AppArmor is deprecated in 1.34. Migrate to seccomp profiles.

### Migration Steps
1. Identify workloads using AppArmor
2. Create equivalent seccomp profiles
3. Test in dev environment
4. Roll out to production
```

## Success Criteria

- [ ] All runbooks updated for 1.34
- [ ] Version references correct
- [ ] Deprecated content removed/flagged
- [ ] New features documented
- [ ] Peer review completed
- [ ] Published to documentation system

---
**Labels:** `documentation`, `runbooks`, `aks-upgrade`, `version-1.34`  
**Priority:** Medium  
**Effort:** Medium (1 week)
