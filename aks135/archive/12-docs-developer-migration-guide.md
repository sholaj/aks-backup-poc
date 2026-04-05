# [DOCS] Developer Migration Guide

## Summary
Create a developer-facing migration guide for K8s 1.35 with self-service compatibility checks and breaking change remediation.

## Background
Application teams need clear guidance on what changes in K8s 1.35 and what actions they must take. The guide should be self-service, allowing teams to verify compatibility independently.

## Curation Results (2026-04-02)

### Created: `docs/aks-135-migration-guide.md`

### Sections Included
| Section | Content |
|---------|---------|
| TL;DR Quick Checklist | 4 key commands to verify compatibility |
| What's New | GA features, platform changes |
| Breaking Changes | cgroup v1, WebSocket RBAC, image pull, IPVS |
| Self-Service Checks | Manifest scanning, workload scanning, Pluto |
| Best Practices | Security context, resources, health probes |
| New Features | In-place resize, image volumes, PreferSameNode |
| Timeline | Rollout schedule with key dates |

### Key Migration Examples
| Change | Before | After |
|--------|--------|-------|
| WebSocket RBAC | `verbs: ["get"]` on pods/exec | `verbs: ["create"]` on pods/exec |
| cgroup | Manual driver config | Remove (auto-detection) |

### Status: ✅ COMPLETE

## Acceptance Criteria
- [x] Migration guide created
- [x] Self-service checks documented
- [x] Breaking change examples included (before/after)
- [x] Timeline with key dates provided

---
**Labels:** `documentation`, `migration-guide`, `aks-upgrade`, `version-1.35`
