# Provisioned Cluster — Handover & Acceptance Checklist

> For the internal engineering team handing OpenShift clusters to the platform team.
> Verify every item below **before** handover. The platform team will customise from a known-good baseline; gaps caught here save a reinstall later.

**Scope:** OpenShift Container Platform 4.20 · 3-node compact (schedulable masters) · Agent-Based Installer on Dell PowerEdge / iDRAC9.

---

## Cluster-specific expectations (read first)

Two cluster roles ship with **deliberately different** network and integration profiles. Confirm which role you are accepting before ticking anything else.

| Item | ACM Hub Cluster | Virtualization Cluster |
|---|---|---|
| Primary CNI (`networkType`) | **OVNKubernetes** | **Cilium** |
| Workloads | None (management only) | Migrated VMs + apps |
| ACI integration | Standard EPG + BD | EPG (mgmt) + floating L3Out (data) |
| OpenShift Virtualization | Not required | Required |

> **The CNI cannot be hot-swapped.** If the `networkType` is wrong for the role, the cluster must be reinstalled. This is the single most important check in this document — do it first (Section 0).

---

## 0. Gating checks — do these first

These four are the reinstall / blocking risks. If any fails, stop and flag before continuing.

- [ ] **`networkType` matches the cluster role** — `Cilium` for the virt cluster, `OVNKubernetes` for the hub
  `oc get network.config/cluster -o jsonpath='{.status.networkType}{"\n"}'`
- [ ] **DNS forward + reverse complete** for `api`, `api-int`, `*.apps`, and every node (A **and** PTR) — DNS is the documented #1 ABI install failure cause
- [ ] **Install completed within the 24-hour ignition certificate window** (ISO generation → cluster up). If the window was blown, certs will be expiring/expired
- [ ] **Time sync healthy on all nodes** — skewed clocks break etcd and certificate validation
  `oc debug node/<node> -- chroot /host chronyc tracking`

---

## 1. Cluster identity & install integrity

- [ ] OCP version is the agreed 4.20.x build (record exact Z-stream)
  `oc get clusterversion`
- [ ] Topology is 3-node compact with **schedulable masters**
  `oc get nodes` (3 nodes, all `master` roles, none cordoned)
- [ ] Kubelet version consistent across nodes
  `oc get nodes -o wide`
- [ ] `cluster` ClusterVersion is `Available=True`, not `Progressing`/`Degraded`
- [ ] Sanitised `install-config.yaml` / `agent-config.yaml` archived for the as-built record (no live secrets)

---

## 2. Control-plane & node health

- [ ] All cluster operators `Available=True`, `Progressing=False`, `Degraded=False`
  `oc get co`
- [ ] All nodes `Ready`
  `oc get nodes`
- [ ] etcd quorum confirmed — 3 healthy members, no learner stuck
  `oc get pods -n openshift-etcd` then `oc rsh -n openshift-etcd <etcd-pod> etcdctl endpoint health --cluster`
- [ ] MachineConfigPools `UPDATED=True`, `UPDATING=False`, `DEGRADED=False`
  `oc get mcp`
- [ ] **No unexpected pending CSRs** — review before approving; do not blanket-approve
  `oc get csr | grep -i pending`
- [ ] No pods in `CrashLoopBackOff` / `Error` in core namespaces
  `oc get pods -A | grep -Ev 'Running|Completed'`

---

## 3. Networking foundation

- [ ] `networkType` correct (re-confirm from Section 0)
- [ ] Pod CIDR and Service CIDR recorded and **non-overlapping** with the fabric / machine network
  `oc get network.config/cluster -o jsonpath='{.spec.clusterNetwork}{"\n"}{.spec.serviceNetwork}{"\n"}'`
- [ ] MTU correct end-to-end (account for overlay/encap headroom on the Cilium cluster)
- [ ] API VIP and Ingress VIP reachable and resolving
- [ ] Node bonding present and correct per the dual-bond design (reachability bond + Cilium TEP/EVPN bond on the virt cluster)
- [ ] BGP peering interfaces present and up on the virt cluster nodes (peering itself is platform-team customisation, but the underlying L2/bonds must be ready)

---

## 4. DNS & time (detail)

- [ ] `api.<cluster>.<base-domain>` → API VIP (A + PTR)
- [ ] `api-int.<cluster>.<base-domain>` → API VIP (A + PTR)
- [ ] `*.apps.<cluster>.<base-domain>` → Ingress VIP
- [ ] Each node hostname resolves forward **and** reverse
- [ ] NTP source reachable from every node; offset within tolerance
  `oc debug node/<node> -- chroot /host chronyc sources`

---

## 5. Image registry / Nexus integration

- [ ] Global pull secret configured and valid (includes Nexus credentials)
  `oc get secret/pull-secret -n openshift-config`
- [ ] `ImageDigestMirrorSet` / `ImageTagMirrorSet` point release + operator images at the Nexus mirror
  `oc get imagedigestmirrorset,imagetagmirrorset`
- [ ] Nexus CA trusted cluster-wide (additional trusted CA bundle wired in)
  `oc get image.config.openshift.io/cluster -o yaml` (check `spec.additionalTrustedCA`)
- [ ] **Live pull test from Nexus succeeds** — spin a throwaway pod from a mirrored image and confirm it pulls without reaching the internet
- [ ] Operator catalog source resolves against the mirrored catalog (Phase 3 / air-gapped) or upstream (Phase 2 / connected) as appropriate
  `oc get catalogsource -A` then `oc get packagemanifests | head`
- [ ] Internal image registry `managementState` and backing store decided and applied (Managed + PVC, or intentionally Removed) — **flag if left at installer default**
  `oc get configs.imageregistry.operator.openshift.io/cluster -o jsonpath='{.spec.managementState}{"\n"}{.spec.storage}{"\n"}'`

---

## 6. Identity & access / AD integration

- [ ] AD/LDAP identity provider configured on the OAuth stack
  `oc get oauth cluster -o yaml` (check `spec.identityProviders`)
- [ ] Console + `oc login` succeed with a real AD user (not kubeadmin)
- [ ] AD group → RBAC mapping defined and applied (cluster-admin group, platform-team group, read-only group) — **confirm group sync source with the platform team**
- [ ] A break-glass / emergency-access account documented and tested
- [ ] `kubeadmin` retained **only** until AD login is verified, then planned for removal — record the decision
- [ ] Default `self-provisioner` and overly-broad bindings reviewed against policy

---

## 7. Certificates, security & compliance

- [ ] API + Ingress serving certificates as agreed (custom CA vs installer-generated) and not near expiry
- [ ] etcd encryption-at-rest enabled if mandated
  `oc get apiserver cluster -o jsonpath='{.spec.encryption.type}{"\n"}'`
- [ ] **FIPS mode** set per requirement (financial-sector workloads frequently mandate it; cannot be toggled post-install) — **confirm the requirement explicitly**
  `oc debug node/<node> -- chroot /host fips-mode-setup --check`
- [ ] Cluster-wide proxy + trusted CA bundle correct for the phase (connected Phase 2 vs air-gapped Phase 3)
  `oc get proxy/cluster -o yaml`
- [ ] **No credentials in the handover package** — kubeconfig and kubeadmin password delivered via a secrets channel, never in screenshots or chat. Rotate anything that has been exposed.

---

## 8. Storage

- [ ] Default `StorageClass` set and appropriate
  `oc get sc`
- [ ] CSI driver(s) healthy
  `oc get csidrivers` / `oc get pods -n openshift-cluster-csi-drivers`
- [ ] Virt cluster: storage profile supports `ReadWriteMany` / block for KubeVirt **live migration** (confirm with the platform team before sign-off)
- [ ] Image registry persistent volume bound (if registry is Managed — see Section 5)

---

## 9. Observability baseline

- [ ] Cluster monitoring stack healthy
  `oc get pods -n openshift-monitoring`
- [ ] Prometheus has persistent storage if retention is required (default is ephemeral)
- [ ] Alertmanager routing target agreed (or explicitly deferred to platform team)

---

## 10. Hardware / firmware baseline (Dell / iDRAC9)

- [ ] iDRAC9 firmware at the agreed Enterprise baseline (target: **7.20.60.50**)
- [ ] Virtualization extensions enabled in BIOS (Intel VT-x / VT-d) — **required on the virt cluster** for OpenShift Virtualization
- [ ] Boot order + Virtual Media (Remote File Share) confirmed working — this is the ABI/iDRAC install path
- [ ] Out-of-band (iDRAC) management reachable and credentials handed over securely

---

## 11. OpenShift Virtualization readiness (virtualization cluster only)

- [ ] CPU virtualization flags present on every node
  `oc debug node/<node> -- chroot /host lscpu | grep -iE 'vmx|svm'`
- [ ] Node resources headroom sufficient for the planned VM footprint (~30 migrating VMs)
- [ ] No conflicting kernel/security policy blocking KVM
- [ ] (Operator install itself is platform-team work — this section only confirms the cluster is *capable*)

---

## 12. Handover artifacts & hygiene

- [ ] As-built record: version, node inventory, CIDRs, VIPs, `networkType`, FIPS state, storage class
- [ ] Sanitised install configs archived (placeholders for ASNs/IPs/hostnames/base domain)
- [ ] kubeconfig + kubeadmin password delivered via secrets channel
- [ ] Any exposed token/credential rotated and the leak path corrected
- [ ] Open questions / deviations listed explicitly so nothing is assumed at handover

---

### Sign-off

| Field | Value |
|---|---|
| Cluster role | ACM Hub / Virtualization |
| OCP build | 4.20.____ |
| `networkType` verified | ☐ |
| Handed over by | |
| Accepted by | |
| Date | |
| Open deviations | |
