# Copilot Instructions — AKS Pre-Upgrade API Deprecation Gate

## Context

This repository manages AKS (Azure Kubernetes Service) clusters using ARM templates, Bash scripts, and GitLab CI/CD pipelines. Before any Kubernetes version upgrade, we run a **pre-upgrade API deprecation gate** that scans the live cluster for deprecated or removed API versions using [Pluto](https://pluto.docs.fairwinds.com/).

The gate script is `scripts/11-pre-upgrade-api-gate.sh`. It MUST pass before the ARM template deployment (`scripts/02-deploy-aks.sh`) executes.

---

## Pre-Upgrade Gate — How It Works

```
ARM parameters define target K8s version
  → Gate script reads target version from arm-templates/02-aks-cluster.parameters.json
  → Queries live cluster for current version via: az aks show --query "kubernetesVersion"
  → Runs: pluto detect-api-resources --target-versions k8s=v<target>.0
  → Runs: pluto detect-helm --target-versions k8s=v<target>.0
  → If removed APIs found (Pluto exit code 3) → BLOCK upgrade, create GitLab issue
  → If clean (exit code 0) → APPROVE upgrade, proceed to deploy stage
```

### Pluto Exit Codes
| Code | Meaning | Gate Action |
|------|---------|-------------|
| 0 | No deprecated APIs | PASS — proceed with upgrade |
| 2 | Deprecated APIs found (still functional) | WARN — proceed (unless FAIL_ON_DEPRECATION=true) |
| 3 | Removed APIs found (will break) | FAIL — block upgrade |

---

## Rules for Copilot When Working in This Repo

### When modifying Kubernetes manifests:
1. Always use the **latest stable API version** for the target K8s version in `arm-templates/02-aks-cluster.parameters.json`
2. Never use deprecated API versions. Common replacements:
   - `extensions/v1beta1/Ingress` → `networking.k8s.io/v1/Ingress`
   - `networking.k8s.io/v1beta1/Ingress` → `networking.k8s.io/v1/Ingress`
   - `policy/v1beta1/PodDisruptionBudget` → `policy/v1/PodDisruptionBudget`
   - `policy/v1beta1/PodSecurityPolicy` → Removed (use Pod Security Admission)
   - `rbac.authorization.k8s.io/v1beta1/*` → `rbac.authorization.k8s.io/v1/*`
   - `admissionregistration.k8s.io/v1beta1/*` → `admissionregistration.k8s.io/v1/*`
   - `apiextensions.k8s.io/v1beta1/CustomResourceDefinition` → `apiextensions.k8s.io/v1/CustomResourceDefinition`
   - `storage.k8s.io/v1beta1/CSIDriver` → `storage.k8s.io/v1/CSIDriver`
3. When creating Ingress resources, always include `spec.ingressClassName` (required in `networking.k8s.io/v1`)
4. When creating Ingress `pathType`, always specify it (`Prefix`, `Exact`, or `ImplementationSpecific`)

### When modifying ARM templates:
1. Check `kubernetesVersion` in `arm-templates/02-aks-cluster.parameters.json` before suggesting API versions
2. If changing the `kubernetesVersion` parameter, remind the user to run the pre-upgrade gate first:
   ```bash
   ./scripts/11-pre-upgrade-api-gate.sh
   ```
3. Use the latest AKS ARM API version (`2025-01-01` or newer)

### When modifying Helm charts or values:
1. Be aware that Helm stores the API version used at install time in the release metadata
2. If a Helm chart uses deprecated APIs, it must be upgraded BEFORE the cluster upgrade
3. Suggest running `pluto detect-helm --target-versions k8s=v<version>.0` to check Helm releases

### When modifying pipeline scripts:
1. Follow existing patterns: `set -euo pipefail`, source `00-set-variables.sh`, use `log_info`/`log_error`/`log_warn`
2. The pre-upgrade gate (`11-pre-upgrade-api-gate.sh`) must always run BEFORE `02-deploy-aks.sh`
3. Never skip or bypass the gate — if it fails, the correct action is to fix the deprecated APIs
4. Gate script environment variables:
   - `CREATE_GITLAB_ISSUE=true` — auto-create a GitLab issue on failure
   - `FAIL_ON_DEPRECATION=true` — strict mode, also blocks on deprecated (not just removed) APIs
   - `SKIP_HELM_SCAN=true` — skip Helm release scanning
   - `TARGET_K8S_VERSION` — override target version detection

### When modifying GitLab CI/CD:
1. The `pluto-api-gate` job in `pipelines/pre-upgrade-api-gate.gitlab-ci.yml` must remain in the `pre-upgrade-gate` stage
2. The `deploy-aks` job must declare `needs: ["pluto-api-gate"]` to enforce ordering
3. The gate job must have `allow_failure: false` — it is a hard gate

---

## Common API Version Reference (K8s 1.29+)

| Resource | Correct API Version | Removed Version |
|----------|-------------------|-----------------|
| Ingress | `networking.k8s.io/v1` | `extensions/v1beta1` (removed 1.22) |
| IngressClass | `networking.k8s.io/v1` | `networking.k8s.io/v1beta1` (removed 1.22) |
| PodDisruptionBudget | `policy/v1` | `policy/v1beta1` (removed 1.25) |
| PodSecurityPolicy | Removed entirely | `policy/v1beta1` (removed 1.25) |
| ClusterRole/ClusterRoleBinding | `rbac.authorization.k8s.io/v1` | `v1beta1` (removed 1.22) |
| Role/RoleBinding | `rbac.authorization.k8s.io/v1` | `v1beta1` (removed 1.22) |
| CronJob | `batch/v1` | `batch/v1beta1` (removed 1.25) |
| CSIDriver | `storage.k8s.io/v1` | `storage.k8s.io/v1beta1` (removed 1.22) |
| CSINode | `storage.k8s.io/v1` | `storage.k8s.io/v1beta1` (removed 1.22) |
| CustomResourceDefinition | `apiextensions.k8s.io/v1` | `v1beta1` (removed 1.22) |
| ValidatingWebhookConfiguration | `admissionregistration.k8s.io/v1` | `v1beta1` (removed 1.22) |
| MutatingWebhookConfiguration | `admissionregistration.k8s.io/v1` | `v1beta1` (removed 1.22) |
| FlowSchema | `flowcontrol.apiserver.k8s.io/v1` | `v1beta3` (removed 1.32) |
| PriorityLevelConfiguration | `flowcontrol.apiserver.k8s.io/v1` | `v1beta3` (removed 1.32) |

---

## Validation Commands

```bash
# Run the pre-upgrade gate locally
./scripts/11-pre-upgrade-api-gate.sh

# Scan manifests only (no cluster needed)
SCAN_MODE=static ./scripts/scan-deprecated-apis.sh

# Scan with a specific target version
TARGET_K8S_VERSION=1.35 ./scripts/11-pre-upgrade-api-gate.sh

# Strict mode — also block on deprecated APIs
FAIL_ON_DEPRECATION=true ./scripts/11-pre-upgrade-api-gate.sh

# Quick Pluto check from CLI
pluto detect-all-in-cluster --target-versions k8s=v1.35.0 -o wide
```
