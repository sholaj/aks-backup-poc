# [DEPRECATION] IPVS Proxy Mode

## Summary
IPVS proxy mode is deprecated in K8s 1.35 in favor of nftables. Assess impact on cluster networking configuration.

## Background
kube-proxy supports three modes: iptables, IPVS, and nftables. IPVS mode is deprecated in 1.35 and will be removed in a future version. The recommended migration path is to nftables or eBPF-based networking (Cilium).

## Curation Results (2026-04-02)

### Scan Results
```
Scanned: arm-templates/*.json
Pattern: ipvs|proxyMode|kube-proxy
Matches: 0
```

### Findings
| Setting | This Repo |
|---------|-----------|
| Network plugin | `azure` (CNI Overlay) |
| Network policy | `azure` |
| Proxy mode | N/A |

### Status: NO ACTION REQUIRED
This repo uses Azure CNI with Overlay networking. In the enterprise environment, Cilium CNI with eBPF dataplane is used, which bypasses kube-proxy entirely. IPVS deprecation has zero impact.

### Enterprise Note
For clusters using kube-proxy with IPVS mode:
1. Migrate to nftables mode: set `--proxy-mode=nftables`
2. Or migrate to Cilium CNI with eBPF dataplane (recommended)
3. Timeline: plan migration before K8s ~1.37

## Acceptance Criteria
- [x] Proxy mode configuration checked
- [x] Network plugin verified (Azure CNI / Cilium)
- [x] Enterprise guidance documented

---
**Labels:** `deprecation`, `networking`, `aks-upgrade`, `version-1.35`
