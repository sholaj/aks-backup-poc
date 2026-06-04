# Copilot prompt — initial scaffolding for `eco-eos-lab`

> Paste this entire prompt into GitHub Copilot Chat (or Copilot Workspace) at the root of the freshly-provisioned, empty `eco-eos-lab` repository. Copilot will produce a plan, wait for your approval, then create the foundation files.

---

You are scaffolding a freshly-provisioned, currently-empty platform engineering repository for the team's VMware ESXi → OpenShift Virtualization migration. This repo is the team's primary working surface for the build and will be the primary surface for Copilot itself going forward.

Your job is to lay the foundation in one pass. The foundation must be opinionated, must encode the engineering discipline below, and must be ready for the team to start meaningful work today.

## Project objective

Deliver a production-ready migration path from the existing VMware ESXi estate onto OpenShift Virtualization. The platform is two compact 3-node bare-metal OpenShift 4.20 clusters — an ACM hub for multi-cluster lifecycle and policy, and a workload cluster running OpenShift Virtualization for the migrated guests. The Migration Toolkit for Virtualization (MTV) moves the guest VMs. Isovalent Cilium 1.19 provides the CNI on the workload cluster with EVPN/BGP integration into the existing Cisco ACI underlay. This repository is the durable engineering artifact — install configurations, manifests, ADRs, runbooks, tests — that anchors the build and that the team works in day-to-day.

The PoC has already been run by a vendor partner; the patterns proven there are the starting point for our work. The team's existing setup-patterns repository codifies the engineering conventions this build must follow. Both are reference repositories you must read before scaffolding (see next section).

## Operating mode

1. Read this entire prompt before acting.
2. **Deeply analyse the two reference repositories listed in the next section.** Use your full repo-reading capability — file listing, content fetch, recursive search across both. Spend genuine effort here; a superficial skim is worse than no read at all, because it produces a scaffold that *looks* aligned to team conventions but isn't.
3. Produce a **plan**: a single-page summary covering (a) the directory structure you'll create, (b) the files you'll generate, (c) any conventions you've adopted or adapted from the internal patterns repo with a one-line justification per adoption, (d) any technical content you've extracted from the WWT PoC repo that you'll fold into the prompt library or instruction files, and (e) any decisions you've inferred from this prompt or the reference repos that you want me to confirm.
4. Wait for me to say "proceed" (or to send corrections).
5. Then create all files in a single pass. Use the conventions specified below, refined by what you found in the reference repos. Where this prompt and the internal patterns repo agree, defer to either. Where they disagree, defer to the internal patterns repo and flag the conflict in the plan.

## Reference repositories to analyse first

These two repositories in the org contain prior art that this scaffold must build on, not duplicate or contradict. Analyse both before producing the plan.

### 1. Internal setup-patterns repository

**Repo**: `<ORG>/<INTERNAL_PATTERNS_REPO>`  *(fill in actual name/path before pasting)*

The team's established patterns for AI-assisted platform engineering: Copilot instruction file formats, path-scoped instruction conventions, prompt-file structures, ADR templates, pre-commit configs, linter setups, CI workflow patterns, commit-message conventions, branch-naming conventions.

What to extract:

- The `.github/copilot-instructions.md` style and tone — match it for `eco-eos-lab`. If the team's house style differs from what this prompt suggests for that file, follow the house style.
- Path-scoped instruction conventions — `applyTo` glob patterns, frontmatter shape, body structure.
- Prompt-file conventions — frontmatter `description` style, body layout, how procedures are documented.
- ADR template — if the team uses something other than the MADR template described later in this prompt, use the team's variant.
- Linter configs (`.yamllint`, `.markdownlint`, `.editorconfig`, `ansible-lint` config) — copy the team's pinned versions and rule sets where present.
- Pre-commit config and CI workflow patterns — note them for the follow-up PR, do NOT replicate them in this scaffold pass. The scaffold deliberately defers pre-commit and CI.
- Commit-message conventions if they differ from the Conventional Commits types listed later in this prompt.
- Branch-naming conventions if they differ from `<type>/<short-slug>`.

If anything in the internal patterns repo contradicts a rule in this prompt, raise it in the plan. The team's actual conventions take precedence over my suggestions.

### 2. WWT PoC reference repository

**Repo**: `<ORG>/wwt-poc-lab`  *(confirm exact name in the org — the visible name in the dashboard may be `wwt-pocdoc-phase2` or similar; use the actual repo holding the Phase 1 PoC documentation and reference manifests)*

The vendor partner's PoC documentation and reference manifests from Phase 1 of the migration. This is the source of technical truth for what has been proven on this stack on this hardware.

What to extract:

- ABI install configurations — `install-config.yaml`, `agent-config.yaml` shape, NMState policy patterns per host, the rendezvous-IP convention.
- Cilium 1.19 configurations validated on bare-metal OpenShift — `CiliumConfig` CR, Isovalent OLM operator manifests, the cluster-network manifests sequence, the exact VXLAN port and clusterHealthPort values that survived install.
- ACI integration specifics — EPG, bridge-domain, VRF design as actually implemented in Phase 1. Note where Phase 2's two-VRF (WORKLOAD-VRF, SEGMENTATION-VRF) design extends or supersedes the Phase 1 setup.
- DNS patterns that survived install validation — record formats, PTR record requirements, validation steps. (DNS misconfiguration is the documented #1 install failure cause; the WWT patterns are battle-tested.)
- Image dependency lists, mirror registry choices, IDMS / ITMS / ImageSet patterns. The Phase 1 image dependency chain was documented as undocumented-and-painful; extract anything that addresses that.
- Documented gotchas, near-misses, workarounds, image-pull times — these go into the prompt library (`cilium-openshift`, `openshift-virt-migration`) as project-specific guidance.

Do NOT copy WWT manifests verbatim into `eco-eos-lab`. The team owns and adapts. But understand the manifests deeply enough that the prompt-library prompts and the path-scoped instruction files carry the project-specific gotchas the team has already paid for in Phase 1.

## Project context

| Aspect | Value |
|---|---|
| Mission | Migrate ~30 virtualised workloads from VMware ESXi to OpenShift Virtualization (KubeVirt-based) via the Migration Toolkit for Virtualization (MTV) |
| Container platform | OpenShift Container Platform 4.20 |
| Install method | Agent-Based Installer (ABI) on Dell PowerEdge R760 bare-metal, ISO mounted via iDRAC9 Virtual Media (Remote File Share) |
| CNI — workload cluster | Isovalent Cilium 1.19 (Isovalent OLM operator) |
| CNI — ACM hub | OVN-Kubernetes (OpenShift default) |
| Network underlay | Cisco ACI |
| Multi-cluster | Red Hat Advanced Cluster Management (ACM) |
| Virtualization | OpenShift Virtualization (KubeVirt-based) |
| Migration tooling | Migration Toolkit for Virtualization (MTV) |
| GitOps | ArgoCD via the OpenShift GitOps Operator |
| Provisioning | Ansible 9+ (RHEL 9.6 bastion); roles tested with Molecule |
| Tests | Go 1.22+ with Ginkgo v2 + Gomega for e2e against live clusters; Molecule for Ansible role tests (colocated with roles under `infra/ansible/roles/<role>/molecule/`) |
| AI coding tool | GitHub Copilot, with model routing to Claude as the underlying LLM |

### Topology

Two compact 3-node bare-metal clusters, both with schedulable masters, both integrated with the same Cisco ACI fabric on dual-leaf redundancy.

- **ACM Hub** — 3-node compact, OVN-Kubernetes CNI, standard EPG + bridge domain (management only — no workloads, no Cilium, no floating L3Out).
- **Workload (Virtualization) Cluster** — 3-node compact, Cilium 1.19 CNI, EVPN/BGP peering with the ACI fabric, two VRFs (WORKLOAD-VRF and SEGMENTATION-VRF with route leak for VIPs only), dual-bond per node (Bond0 reachability bridge domain; Bond1 Cilium TEP and EVPN BGP peering), only summary routes advertised upward, pod CIDR not advertised on the fabric.

Multi-DC scope: primary site plus a second NX-OS-fronted DC connected via inter-DC EVPN extension. Target capacity 500 nodes per site. An existing NSX environment reaches the new fabric via a VLAN-backed port group into the heritage machine CIDR bridge domain — this is the carry-over point for non-migrated workloads.

### Phasing

1. Local kind cluster — walking skeleton, developer-laptop scope.
2. On-prem target lab — fully air-gapped, the final destination.

There is no cloud middle phase.

### Critical operational realities

- **DNS misconfiguration is the documented #1 ABI install failure cause.** Validate DNS aggressively before any install run.
- **ABI ignition certificates expire 24 hours after ISO generation.** Plan install windows so the full install completes inside that window.
- **`nmstatectl gc` only understands NMState policy documents** (the inner `networkConfig:` block per host), not the full `agent-config.yaml`. Use `yq` extraction or `openshift-install agent create cluster-manifests --log-level=debug` for end-to-end validation.

## Engineering principles (non-negotiable, encode in every file you create)

1. **Documentation-first.** For OpenShift, Cilium, ACM, MTV, KubeVirt, ArgoCD, and any tool with a fast-moving API, fetch the current upstream documentation before generating configuration. Do not generate manifests from memory — training data lag silently produces wrong API versions that lint clean and fail at apply time.

2. **Test-first.** Every architecturally meaningful deliverable carries a runnable test. Ginkgo v2 + Gomega for Kubernetes / OpenShift e2e against live clusters; Molecule for Ansible role tests, colocated with the role under `infra/ansible/roles/<role>/molecule/`. A change that lacks tests is incomplete.

3. **GitOps-first.** Past initial cluster install, ArgoCD drives everything. Manifests applied imperatively are debt to be paid down with an Application.

4. **ADR-first.** Every architecturally significant decision lands an Architecture Decision Record in `docs/adr/NNNN-<slug>.md` using the MADR template. Bias toward more ADRs, not fewer. They are the durable artifact of this project.

5. **Conventional Commits**, enforced via commitlint. Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`, `infra`, `gitops`, `policy`, `adr`.

6. **No `Co-Authored-By:` trailers** on commits. Each commit reads as a single human author.

7. **Stack pinning.** Pin `apiVersion` precisely in every manifest. Pin container image references by tag at minimum; prefer SHA digests for production-bound manifests. Pin tool versions in workflow definitions. `latest` and unspecified versions are unacceptable.

8. **Required Kubernetes labels** on every resource: `app.kubernetes.io/name`, `app.kubernetes.io/part-of: eco-eos-lab`, `app.kubernetes.io/managed-by: argocd` (where applicable).

9. **Resource requests AND limits** on every Pod/Container spec. Readiness AND liveness probes unless explicitly justified.

10. **OpenShift specifics**: prefer `Route` over `Ingress`; target the `restricted-v2` SCC unless an ADR justifies otherwise.

11. **Secret hygiene.** Never commit `.env*`, `*.kubeconfig`, `pull-secret*.txt`, `*.tfstate`, SSH keys, ansible-vault password files, or anything credential-bearing. The `.gitignore` enforces this; engineers do not bypass it.

12. **Repository-as-spec.** The repository specifies how to work in this codebase. Files like `.github/copilot-instructions.md` and the path-scoped `.github/instructions/*.instructions.md` are read by Copilot on every interaction and brief future engineers as effectively as they brief Copilot. Treat them as production code: PR-reviewed, versioned, maintained.

## Repository structure to produce

```text
eco-eos-lab/
├── .editorconfig
├── .github/
│   ├── copilot-instructions.md
│   ├── instructions/
│   │   ├── manifests.instructions.md
│   │   ├── ansible.instructions.md
│   │   └── go-tests.instructions.md
│   ├── prompts/
│   │   ├── fetch-live-docs.prompt.md
│   │   ├── yaml-validate.prompt.md
│   │   ├── draft-adr.prompt.md
│   │   ├── cilium-openshift.prompt.md
│   │   └── openshift-virt-migration.prompt.md
│   └── workflows/          # CI workflows land in a follow-up PR — placeholder for now
├── .gitignore
├── .markdownlint.json
├── .yamllint.yaml
├── CONTRIBUTING.md
├── README.md
├── Taskfile.yml
├── clusters/
│   ├── README.md
│   ├── acm-hub/            # ABI install config + manifests for the hub
│   ├── virt/               # ABI install config + manifests for the workload cluster
│   └── kind/               # Local kind cluster scaffolding
├── docs/
│   ├── README.md
│   ├── adr/
│   │   ├── 0000-template.md
│   │   ├── 0001-ai-coding-pattern.md
│   │   └── 0002-engineering-principles.md
│   └── runbooks/
├── gitops/
│   ├── README.md
│   ├── bootstrap/          # ArgoCD operator + root Application
│   ├── apps/               # ArgoCD Applications sourced from the root
│   └── overlays/           # Kustomize overlays per environment
├── infra/
│   ├── README.md
│   └── ansible/            # Roles, playbooks, inventories; Molecule tests live under roles/<role>/molecule/
├── policies/
│   ├── README.md
│   ├── acm/                # ACM Policy patterns
│   └── kyverno/            # Kyverno baseline policies
└── tests/
    ├── README.md
    └── e2e/                # Go + Ginkgo v2 + Gomega against live clusters
```

Each top-level seam directory is intentionally a future-repo boundary. Keep cross-directory imports minimal so a polyrepo split later is a `git filter-repo` away.

## File-specific guidance

### `README.md`

Project landing page. Cover: what this repo is for, what it is not, the stack and versions table, the topology summary, the phasing, the repo layout, a reading order for new joiners (this README → `copilot-instructions.md` → `CONTRIBUTING.md` → foundational ADRs in order), and a brief note on working with Copilot in this repo.

### `.github/copilot-instructions.md`

The single most important file in the foundation. Copilot reads this on every interaction. It must declare:

- Project context (mission, stack table, topology, phasing).
- The 12 engineering principles above, written as rules Copilot must follow when generating output.
- The documentation-freshness requirement with a canonical URL list (OpenShift 4.20 docs, OpenShift Virtualization, ABI, Cilium 1.19, Isovalent OLM, ACM, MTV, ArgoCD, KubeVirt).
- The CiliumNetworkPolicy-vs-NetworkPolicy split between clusters (Cilium policies only under `clusters/virt/` and `clusters/kind/`; standard `networking.k8s.io/v1 NetworkPolicy` for the hub).
- Authoring rules for manifests (the labels, requests/limits, OpenShift specifics).
- A refusal posture: refuse to generate YAML from memory for the documentation-first stacks; refuse to commit secrets; refuse to bypass pre-commit or CI; refuse to make an architecturally significant change without an accompanying ADR.
- A pointer to the prompt library and what each prompt does.

### `.github/instructions/manifests.instructions.md`

Frontmatter: `applyTo: "**/*.yaml,**/*.yml"`. Covers manifest authoring rules in depth — pinning, labels, requests/limits, namespace handling, NetworkPolicy split, the validation pipeline order (yamllint → kubeconform → kube-linter → kustomize build → server-side dry-run), and a per-file output checklist.

### `.github/instructions/ansible.instructions.md`

Frontmatter: `applyTo: "infra/ansible/**/*.yaml,infra/ansible/**/*.yml"`. Covers FQCN module names, idempotency, secrets via ansible-vault (or external store), inventory abstraction, ansible-lint, role structure (`infra/ansible/roles/<role>/{tasks,handlers,defaults,vars,templates,files,meta}/`), Molecule test scenarios (`infra/ansible/roles/<role>/molecule/<scenario>/`) with at minimum a `default` scenario per role, collection pinning via `infra/ansible/requirements.yml`, and the bare-metal install context (DNS gate, iDRAC9 Virtual Media, 24-hour ignition window). State explicitly that the Kubernetes-manifest rules in `manifests.instructions.md` do NOT apply to Ansible YAML — Molecule and playbook YAML follows Ansible conventions, not k8s API-version pinning.

### `.github/instructions/go-tests.instructions.md`

Frontmatter: `applyTo: "tests/**/*.go"`. Covers Ginkgo v2 + Gomega structure, build tags for e2e/integration gating, cluster connection via `KUBECONFIG`, `t.Parallel()` discipline, resource cleanup in `AfterEach` / `defer`, no hard-coded endpoints.

### `.github/prompts/fetch-live-docs.prompt.md`

A prompt invoked from Copilot Chat as `/fetch-live-docs`. Documents the canonical URL list, the workflow (identify stack → fetch version-pinned page → quote the URL in the PR/ADR → pin specific versions in output), and a refusal posture if the fetch step is skipped or fails.

### `.github/prompts/yaml-validate.prompt.md`

Walks through the full lint pipeline (the five-step order above) with exact commands and a structured output format.

### `.github/prompts/draft-adr.prompt.md`

Walks through creating a new ADR from `docs/adr/0000-template.md`: incrementing the number, choosing a kebab-case slug, filling the MADR sections, anonymisation reminder (omit for this internal repo — instead, anti-leak hygiene around credentials and tokens), commit with `adr: <slug>`.

### `.github/prompts/cilium-openshift.prompt.md`

Bare-metal Cilium-on-OpenShift install patterns. The ABI flow (manifests → set `networkType: Cilium` → copy `manifests/cilium.v1.19.x/*` from `isovalent/olm-for-cilium` → tune `CiliumConfig` clusterNetwork, VXLAN port, clusterHealthPort 9940 → create-image → ISO via iDRAC9 → complete within 24h). The kind path (Helm chart, not OLM). The networking design terms (WORKLOAD-VRF, SEGMENTATION-VRF, dual-bond, summary routes upward). The forward-looking 1.19 → 1.20 transition note.

### `.github/prompts/openshift-virt-migration.prompt.md`

MTV manifest patterns. Required context to gather before generating (source provider type, VDDK init image location, cold vs warm, StorageMap, NetworkMap). CR order (Provider source → Provider target → NetworkMap → StorageMap → Plan → Migration). Known gotchas (lowercase DNS-compliant VM names, N VMDKs needs N PVCs, CBT for warm migration, VDDK reachability, MAC preservation but not IP).

### `docs/adr/0000-template.md`

MADR template with frontmatter (`status`, `date`, `deciders`, `consulted`, `informed`) and the standard sections: context and problem statement, decision drivers, considered options, decision outcome, consequences (Good and Bad both — an ADR with no Bad consequences is suspect), validation, links.

### `docs/adr/0001-ai-coding-pattern.md`

Records the decision to adopt the Copilot-with-instructions+prompts layered pattern: `.github/copilot-instructions.md` as repo-wide context, `.github/instructions/*.instructions.md` as path-scoped rules, `.github/prompts/*.prompt.md` as reusable Chat procedures. Status `Accepted`. Justify with the three drivers: Copilot is the live AI tool; stack is fast-moving so documentation-first must be encoded; per-engineer agent configuration would drift.

### `docs/adr/0002-engineering-principles.md`

Records the 12 engineering principles listed above as the codified engineering discipline for the repo. Status `Accepted`. The body explains *why* each principle is non-negotiable (e.g. test-first because the cost of late-stage discovery in an air-gapped bare-metal environment is hours-to-days; GitOps-first because manual apply on a multi-cluster topology is unmaintainable; ADR-first because the team will lose context between phases without it).

### `CONTRIBUTING.md`

Conventional Commits format with the allowed types listed. Branch naming (`<type>/<short-slug>`). ADR-first reminder. Pointers to the key prompts (`/fetch-live-docs`, `/yaml-validate`, `/draft-adr`). The no-Co-Authored-By rule. Note that pre-commit hooks and CI workflows are deferred to a follow-up PR with their own ADR.

### `Taskfile.yml`

Stub Taskfile with `default` (list tasks), `bootstrap` (verify tools), `check-tools` (CLI presence check for `gh`, `git`, `oc`, `kubectl`, `helm`, `kustomize`, `jq`, `ansible`, `ansible-lint`, `molecule`, `pre-commit`, `yamllint`, `kubeconform`, `kube-linter`, `task`), and stub `lint` / `validate` targets that print TODO messages. Real implementations land with the pre-commit + CI follow-up.

### Supporting files

- `.gitignore` — standard plus secret-bearing patterns (`*.kubeconfig`, `pull-secret*`, `*.tfstate`, `.env*`, ansible-vault password files, IDE caches).
- `.editorconfig` — LF line endings, UTF-8, 2-space indent, tab for Go and Makefiles.
- `.yamllint.yaml` — extends default; line-length 160 warning; 2-space indentation; document-start required.
- `.markdownlint.json` — disable MD013 (line length), MD034 (bare URLs), MD041 (first-line heading); enable siblings-only for MD024.

### Directory READMEs

Each of `clusters/`, `clusters/acm-hub/`, `clusters/virt/`, `clusters/kind/`, `gitops/`, `infra/`, `policies/`, `tests/`, `docs/`, `docs/adr/`, `docs/runbooks/` gets a brief README (under 200 words) explaining what lives there and any per-directory rules.

Drop `.gitkeep` files in any subdirectory that has no other files yet (`gitops/bootstrap/`, `gitops/apps/`, `gitops/overlays/`, `policies/acm/`, `policies/kyverno/`, `tests/e2e/`, `infra/ansible/`, `.github/workflows/`).

## What you must NOT do

- **Do not generate manifests for OpenShift, Cilium, ACM, MTV, KubeVirt, or ArgoCD without fetching the current upstream docs first.** This is the canonical failure mode on this project. If you cannot fetch, say so and stop — do not fall back to training data.
- **Do not invent file structure beyond the tree above.** If you think a directory or file is missing, raise it in the plan, not in the produced output.
- **Do not append `Co-Authored-By:` trailers to the commit you make for this scaffold.**
- **Do not add tooling not listed in the project context** (e.g. don't add Helm if I haven't called for Helm; don't introduce Terraform, Pulumi, CloudFormation, or any other IaC tool — Ansible is the chosen provisioning surface) without raising it in the plan first.
- **Do not write CI workflows or pre-commit hooks in this pass.** Both land in a separate PR with their own ADR — the team needs to make tooling decisions first.
- **Do not over-elaborate.** The foundation is meant to be lived in and extended. Each file should be as short as it can be while still doing its job.

## Working commit

After producing the files, propose a single commit with the message:

```
chore: scaffold repo foundation for AI-assisted platform engineering

Lays the foundation files for the eco-eos-lab repo: Copilot
instruction layer, prompt library, MADR ADR template, two
foundational ADRs, supporting lint configs, directory skeleton
with per-directory READMEs, and a stub Taskfile.

CI workflows and pre-commit hooks deferred to a follow-up PR.
```

(Adjust the type from `chore` to `feat` or `infra` if the team's commitlint policy treats scaffolding differently — flag this in the plan.)

## Now produce the plan

Output the plan first. Wait for "proceed" before generating files.

The plan should include:

- The full file list you intend to create (paths only).
- **From the internal setup-patterns repo**: which conventions you've adopted (Copilot instruction style, path-scoped instruction format, prompt-file format, ADR template, linter configs) with a one-line justification each. Flag any contradictions between the patterns repo and this prompt — defer to the patterns repo and explain.
- **From the WWT PoC repo**: what you've extracted that you'll fold into the prompt library and instruction files (specific Cilium config values, NMState patterns, DNS validation steps, image-sync gotchas, etc.). Cite the source file in the WWT repo for each extraction.
- Any decisions you've inferred that you want me to confirm before producing (e.g. the collection-pinning strategy for `infra/ansible/requirements.yml` — Galaxy versions or git refs? — should the instruction file express a preference?).
- Anything in this prompt or the reference repos that's ambiguous or under-specified.
- An estimate of how many files the foundation will land (sanity check against my expectation of ~40).
