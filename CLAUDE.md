# Claude.md — AKS Platform Engineering Home Lab

## Who I Am

I am a Platform Engineer focused on Azure Kubernetes Service (AKS). My strength is infrastructure provisioning — ARM templates, GitLab CI/CD pipelines, Azure CLI scripting, and monitoring architecture. I am actively growing my knowledge in AKS **operations**, particularly networking (Istio, NGINX Ingress, external-dns, cert-manager), GitOps (Flux), and cluster lifecycle automation.

This repo is my **home lab** — it replicates the patterns and challenges I face at work so I can experiment safely and build deeper understanding.

---

## Core Philosophy: Cattle, Not Pets

Engineering and development clusters are **ephemeral**. They should be stood up from the dev branch and destroyed daily. Production clusters follow strict change management. Every script, template, and pipeline in this repo should reinforce this:

- Dev/eng clusters: **build and destroy at will**, automated daily teardown
- Pipelines must be **idempotent** — safe to run repeatedly without side effects
- Monitoring infrastructure (AMW, DCE, Grafana) is **persistent** and lives at the environment level, not the cluster level
- Cluster identity and state should never be assumed to survive between runs

---

## What Claude Should Know About This Repo

### Tech Stack
- **Infrastructure as Code:** ARM templates (JSON), parameter files generated from YAML via Python scripts
- **CI/CD:** GitLab CI/CD with multi-stage pipelines (build → validate → deploy → setup → test → hardening → publish → teardown → maintenance)
- **Scripting:** Primarily Bash. Python for parameter generation (`updateParams.py`)
- **Cloud:** Azure (AKS, Azure Monitor, Managed Prometheus, Managed Grafana, Key Vault, Workload Identity, Defender, Azure Policy)
- **Kubernetes:** AKS with Cilium CNI (eBPF dataplane), CNI Overlay networking, KEDA, Flux GitOps
- **Networking:** Istio service mesh (AKS-managed), NGINX Ingress (learning), external-dns (learning), cert-manager (learning)
- **Monitoring:** Azure Monitor Workspace, Data Collection Rules/Endpoints, ama-metrics, Grafana dashboards, Prometheus alert rules
- **Secrets:** HashiCorp Vault (EVA) integrated with GitLab CI/CD via JWT auth
- **Testing:** Goss (infrastructure validation), Go tests, JUnit reporting

### Repo Structure (Typical)
```
├── env/                          # Environment-specific YAML config files
│   ├── dev-cluster-name.yml
│   ├── preprod-cluster-name.yml
│   └── prod-cluster-name.yml
├── src/
│   ├── main/
│   │   ├── arm/                  # ARM templates
│   │   │   ├── aks/              # AKS cluster templates + param templates
│   │   │   ├── flux-extension/
│   │   │   ├── flux-configuration/
│   │   │   └── azure-monitor/    # Action groups, metric alerts, scheduled queries
│   │   └── python-scripts/       # updateParams.py, validateClusterName.py
│   └── test/
│       ├── gotests/
│       └── gossTests/
├── pipelines/
│   ├── scripts/                  # Numbered bash scripts (10_*, 20_*, etc.)
│   └── day2/                     # Day-2 operations (start/stop)
├── .gitlab-ci.yml
└── version.txt
```

### Script Numbering Convention
Scripts follow a numbered convention indicating pipeline stage:
- `10_*` — Resource group setup, validation
- `11_*` — ARM template validation and what-if
- `20_*` — AKS deployment
- `30_*` — GitOps / Flux setup
- `40_*` — Workload identity, configmaps, Key Vault, Istio, node upgrades, AKS updates
- `50_*` — Monitoring deployment (AKS monitoring, OMS agent, Grafana, Prometheus, DCR)
- `60_*` — Tests
- `70_*` — Cluster and nodepool hardening
- `80_*` — Teardown / destroy
- `90_*` — Artifact publishing
- `100_*` — Day-2 operations (stop/start)

---

## How Claude Should Help Me

### DO:
- Provide clear, practical explanations of AKS networking concepts — especially Istio, NGINX Ingress, external-dns, and cert-manager
- Help me write and debug Bash scripts, ARM templates, and GitLab CI/CD pipelines
- Help me build automated daily teardown/recreation pipelines for dev clusters
- Explain Kubernetes concepts in the context of AKS (not generic K8s — be aware of AKS-specific behaviors)
- Help me design idempotent scripts that handle re-runs gracefully
- Suggest validation patterns (pre-deploy checks, post-deploy verification)
- Help me understand monitoring pipelines: cluster → ama-metrics → DCR → DCE → AMW → Grafana
- Help with Azure CLI commands and `az aks` operations
- Help me understand Flux GitOps configuration and troubleshooting
- When I ask about networking, break it down from first principles — I'm building this knowledge area

### DO NOT:
- **Do NOT assume every question is a request to convert Bash to Ansible.** I will explicitly ask if I want Ansible.
- Do not over-abstract. I work in a regulated enterprise environment — solutions need to be auditable and explainable.
- Do not suggest Terraform unless I ask. We use ARM templates.
- Do not suggest Bicep unless I ask. We use ARM JSON templates.
- Do not hallucinate Azure CLI flags — verify syntax is correct for the resource type.

---

## Key Learning Areas — Help Me Build Depth Here

### 1. Istio on AKS (Service Mesh)
I use the **AKS-managed Istio add-on** (not standalone Istio). Help me understand:
- How Istio sidecar injection works and how to control it per namespace
- VirtualService and DestinationRule configuration
- Istio IngressGateway (Internal mode) — how traffic flows from Azure Load Balancer → Istio Gateway → VirtualService → Pod
- mTLS between services (STRICT vs PERMISSIVE mode)
- How Istio revision-based upgrades work (canary upgrades via `istio.revisions`)
- Troubleshooting: `istioctl analyze`, proxy status, envoy logs
- How Istio interacts with Cilium CNI (both do network policy — how do they coexist?)

### 2. NGINX Ingress Controller on AKS
Help me understand as an alternative/complement to Istio:
- Deploying NGINX Ingress Controller via Helm on AKS
- Internal vs external load balancer annotations (`service.beta.kubernetes.io/azure-load-balancer-internal: "true"`)
- Ingress resource configuration: host-based routing, path-based routing, TLS termination
- How NGINX Ingress differs from Istio Gateway for traffic management
- When to use NGINX Ingress vs Istio Gateway vs Azure Application Gateway Ingress Controller (AGIC)

### 3. external-dns on AKS
Help me understand automated DNS management:
- What external-dns does: watches Ingress/Service resources and creates DNS records automatically
- How to configure external-dns with Azure DNS zones (both public and private)
- Authentication: using Workload Identity to grant external-dns permission to manage DNS records
- How it works with Istio Gateway and NGINX Ingress resources
- Annotations to control DNS record creation (`external-dns.alpha.kubernetes.io/hostname`)
- Troubleshooting: why records aren't being created, RBAC issues, zone delegation

### 4. cert-manager on AKS
Help me understand automated TLS certificate management:
- What cert-manager solves: automated issuance and renewal of TLS certificates
- ClusterIssuer vs Issuer — when to use each
- ACME protocol with Let's Encrypt (HTTP-01 vs DNS-01 challenge types)
- Using cert-manager with Azure DNS for DNS-01 challenges (Workload Identity auth)
- Certificate resource → cert-manager creates Secret → Ingress/Gateway uses Secret
- How cert-manager integrates with both NGINX Ingress and Istio Gateway
- Troubleshooting: certificate not ready, challenge failures, order status

### 5. How These Components Work Together
The full traffic flow I want to understand end-to-end:
```
Internet/Internal Client
  → Azure Load Balancer
    → NGINX Ingress Controller / Istio IngressGateway
      → (TLS terminated using cert-manager certificate)
      → Routing rules (Ingress / VirtualService)
        → Kubernetes Service
          → Pod
Meanwhile:
  - external-dns creates/updates DNS records pointing to the LB
  - cert-manager provisions and renews TLS certificates
  - Istio sidecars handle mTLS between services
```

### 6. Monitoring Pipeline (Deepening Existing Knowledge)
I understand this well but want to go deeper:
- How to write custom DCR transformations
- Recording rules and alerting rules in Azure Managed Prometheus
- Grafana dashboard-as-code patterns
- PromQL query optimization for large multi-cluster environments

### 7. Flux GitOps
- Flux Kustomization and HelmRelease patterns
- How Flux reconciliation works and how to troubleshoot stuck reconciliations
- Multi-tenancy with Flux: per-tenant Kustomizations scoped to namespaces
- Flux image automation for automatic deployments

---

## Environment Context

| Aspect | Detail |
|--------|--------|
| Environments | dev, preprod, prod |
| Regions | westeurope, southeastasia, switzerlandnorth |
| Multi-tenancy | Namespace-as-a-service (AT-* namespaces) |
| CNI | Cilium (eBPF dataplane) with CNI Overlay |
| Service Mesh | AKS-managed Istio (Internal IngressGateway) |
| Identity | Workload Identity + OIDC Issuer |
| Upgrades | Patch auto-upgrade channel, NodeImage OS upgrade |
| Node OS | Azure Linux (CBL-Mariner) |
| Security | Secure Boot, vTPM, SSH Disabled, Defender enabled, Image Cleaner |
| GitOps | Flux v2 (extension + configurations) |
| Autoscaling | Cluster autoscaler on nodepools, KEDA for workload scaling |

---

## Pipeline Design Principles

1. **Idempotent:** Every script must handle being run twice without error or unexpected changes
2. **Fail-fast:** `set -euo pipefail` in every Bash script
3. **Discoverable:** Use `az aks list` to find cluster names dynamically — never hardcode
4. **Validated:** ARM template `validate` and `what-if` before any deployment
5. **Gated:** Manual gates for deploy/setup stages; automated for build/validate
6. **Auditable:** All actions logged with `[INFO]`, `[DEBUG]`, `[ERROR]`, `[SUCCESS]` prefixes
7. **Ephemeral-friendly:** Dev pipelines should support scheduled daily destroy + recreate cycles

---

## Common Tasks I'll Ask For Help With

- Writing or debugging Bash scripts for AKS operations
- ARM template modifications and troubleshooting deployment errors
- GitLab CI/CD pipeline configuration (`.gitlab-ci.yml`)
- Understanding Azure CLI output and crafting JMESPath queries
- Building validation scripts that verify end-to-end monitoring pipelines
- Creating scheduled pipeline jobs for daily cluster teardown/recreation
- Learning networking concepts with practical AKS examples
- Designing Goss test suites for post-provisioning validation
- Troubleshooting AKS-specific issues (node readiness, pod scheduling, DNS resolution, identity)

---

## Style Preferences

- Be direct and practical. I prefer working examples over theory-only explanations.
- When explaining networking concepts, use diagrams (ASCII or Mermaid) showing traffic flow.
- For Bash scripts, include error handling and logging consistent with my existing patterns.
- When suggesting Azure CLI commands, show the full command with realistic parameter values.
- If something is an AKS-specific behavior (differs from upstream K8s), call it out explicitly.
- When I ask "how does X work", give me the mental model first, then the implementation details.