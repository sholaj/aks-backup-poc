# [DOCS] Runbook Updates

## Summary
Update operational runbooks with K8s 1.35 procedures, diagnostics, and version-specific information.

## Background
The operations runbook must reflect 1.35-specific changes: cgroup v2 verification, WebSocket RBAC, containerd 2.x requirements, and the upgrade path from 1.34.

## Curation Results (2026-04-02)

### Created: `docs/aks-135-runbook.md`

### Sections Updated
| Section | Changes |
|---------|---------|
| Quick Reference | Added cgroup v2, updated containerd info |
| Provisioning | Updated to 1.35 scripts |
| Node Pool Management | Added Azure Linux 2.0 EOL guidance |
| Troubleshooting | Added 1.35-specific diagnostics |
| Upgrade Procedures | 1.34 → 1.35 path with cgroup v2 pre-check |
| Cattle Cluster | Updated script references |

### Key Additions for 1.35
- cgroup v2 verification command
- WebSocket RBAC audit command
- Azure Linux 2.0 EOL migration steps
- Enhanced pre-upgrade checklist (cgroup + containerd + AL2 checks)

### Status: ✅ COMPLETE

## Acceptance Criteria
- [x] Runbook created with 1.35-specific content
- [x] cgroup v2 verification documented
- [x] Upgrade procedures from 1.34 → 1.35 documented
- [x] Azure Linux 2.0 EOL guidance included

---
**Labels:** `documentation`, `runbook`, `aks-upgrade`, `version-1.35`
