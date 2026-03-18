# Deprecated API Test Manifests

**Purpose:** These manifests intentionally use deprecated/removed Kubernetes API versions
to demonstrate Pluto's ability to detect them during static scans.

**WARNING:** These manifests will NOT apply to a Kubernetes 1.34 cluster — the API server
will reject them. They are for **static scanning only**.

## How to scan

```bash
# Scan just these test files
SCAN_MODE=static MANIFEST_DIR=./kubernetes/deprecated-api-tests ./scripts/scan-deprecated-apis.sh

# Scan all manifests (includes production + test)
SCAN_MODE=static ./scripts/scan-deprecated-apis.sh
```

## Deprecated APIs included

| File | API Version | Kind | Removed In |
|------|------------|------|------------|
| 01-ingress-extensions-v1beta1.yaml | extensions/v1beta1 | Ingress | 1.22 |
| 02-ingress-networking-v1beta1.yaml | networking.k8s.io/v1beta1 | Ingress | 1.22 |
| 03-pdb-policy-v1beta1.yaml | policy/v1beta1 | PodDisruptionBudget | 1.25 |
| 04-cronjob-batch-v1beta1.yaml | batch/v1beta1 | CronJob | 1.25 |
| 05-hpa-autoscaling-v2beta1.yaml | autoscaling/v2beta1 | HorizontalPodAutoscaler | 1.26 |
| 06-csidriver-storage-v1beta1.yaml | storage.k8s.io/v1beta1 | CSIDriver | 1.22 |
| 07-flowschema-v1beta2.yaml | flowcontrol.apiserver.k8s.io/v1beta2 | FlowSchema | 1.29 |
| 08-flowschema-v1beta3.yaml | flowcontrol.apiserver.k8s.io/v1beta3 | FlowSchema | 1.32 |
| 09-endpointslice-v1beta1.yaml | discovery.k8s.io/v1beta1 | EndpointSlice | 1.25 |
