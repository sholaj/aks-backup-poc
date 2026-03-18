#!/bin/bash
#
# Pre-Upgrade API Deprecation Gate
# Runs BEFORE ARM template deployment to block upgrades if deprecated/removed APIs exist.
#
# This script:
#   1. Detects the CURRENT cluster K8s version (from live cluster)
#   2. Detects the TARGET K8s version (from ARM parameters)
#   3. Runs Pluto detect-all-in-cluster against the target version
#   4. Blocks the upgrade if removed APIs are found (exit code 3)
#   5. Optionally creates a GitLab issue for the team to remediate
#
# Usage:
#   ./scripts/11-pre-upgrade-api-gate.sh                    # Auto-detect everything
#   TARGET_K8S_VERSION=1.35 ./scripts/11-pre-upgrade-api-gate.sh  # Override target
#   CREATE_GITLAB_ISSUE=true ./scripts/11-pre-upgrade-api-gate.sh  # Create issue on failure
#
# Environment variables:
#   TARGET_K8S_VERSION    - Override target K8s version (default: from ARM parameters)
#   CREATE_GITLAB_ISSUE   - Create GitLab issue on failure (default: false)
#   GITLAB_PROJECT_ID     - GitLab project ID for issue creation
#   GITLAB_API_URL        - GitLab API URL (default: https://gitlab.com/api/v4)
#   GITLAB_TOKEN          - GitLab personal/project access token (CI_JOB_TOKEN in pipelines)
#   SKIP_HELM_SCAN        - Skip Helm release scan (default: false)
#   FAIL_ON_DEPRECATION   - Also fail on deprecated (not just removed) APIs (default: false)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
source "${SCRIPT_DIR}/00-set-variables.sh"

# --- Configuration ---
PARAMS_FILE="$PROJECT_DIR/arm-templates/02-aks-cluster.parameters.json"
CREATE_GITLAB_ISSUE="${CREATE_GITLAB_ISSUE:-false}"
GITLAB_API_URL="${GITLAB_API_URL:-https://gitlab.com/api/v4}"
GITLAB_PROJECT_ID="${GITLAB_PROJECT_ID:-}"
GITLAB_TOKEN="${GITLAB_TOKEN:-${CI_JOB_TOKEN:-}}"
SKIP_HELM_SCAN="${SKIP_HELM_SCAN:-false}"
FAIL_ON_DEPRECATION="${FAIL_ON_DEPRECATION:-false}"
PLUTO_REPORT_FILE="${PROJECT_DIR}/pluto-report.txt"

# Counters
DEPRECATED_COUNT=0
REMOVED_COUNT=0
GATE_FAILED=false

echo "=============================================="
echo "Pre-Upgrade API Deprecation Gate"
echo "=============================================="
echo ""

# --- Step 1: Check prerequisites ---
log_info "Checking prerequisites..."

if ! command -v pluto &>/dev/null; then
    log_error "Pluto is not installed"
    echo "  Install: curl -fsSL https://github.com/FairwindsOps/pluto/releases/latest/download/pluto_linux_amd64.tar.gz | tar xz -C /usr/local/bin"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    log_error "jq is not installed"
    exit 1
fi

if ! kubectl cluster-info &>/dev/null; then
    log_error "kubectl cannot connect to cluster"
    echo "  Run: az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME"
    exit 1
fi

# --- Step 2: Detect CURRENT cluster version ---
log_info "Detecting current cluster Kubernetes version..."

CURRENT_K8S_VERSION=$(az aks show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER_NAME" \
    --query "kubernetesVersion" \
    --output tsv 2>/dev/null) || {
    log_error "Failed to query current cluster version"
    log_error "Ensure cluster '$AKS_CLUSTER_NAME' exists in resource group '$RESOURCE_GROUP'"
    exit 1
}

log_info "Current cluster version: $CURRENT_K8S_VERSION"

# --- Step 3: Detect TARGET version from ARM parameters ---
if [[ -z "${TARGET_K8S_VERSION:-}" ]]; then
    if [[ -f "$PARAMS_FILE" ]]; then
        TARGET_K8S_VERSION=$(jq -r '.parameters.kubernetesVersion.value' "$PARAMS_FILE")
        log_info "Target version from ARM parameters: $TARGET_K8S_VERSION"
    else
        log_error "No TARGET_K8S_VERSION set and parameters file not found: $PARAMS_FILE"
        exit 1
    fi
else
    log_info "Target version from environment: $TARGET_K8S_VERSION"
fi

# --- Step 4: Compare versions ---
echo ""
echo "  Current version: $CURRENT_K8S_VERSION"
echo "  Target version:  $TARGET_K8S_VERSION"
echo ""

if [[ "$CURRENT_K8S_VERSION" == "$TARGET_K8S_VERSION" ]]; then
    log_info "Current and target versions are the same — no upgrade pending"
    log_info "Running scan anyway to validate current state..."
fi

# Normalize for Pluto (needs v prefix and patch version)
PLUTO_TARGET="k8s=v${TARGET_K8S_VERSION#v}.0"
log_info "Pluto target: $PLUTO_TARGET"
echo ""

# --- Step 5: Run Pluto detect-all-in-cluster ---
echo "=============================================="
echo "Running Pluto: detect-all-in-cluster"
echo "=============================================="
echo ""

# Capture output for GitLab issue body
> "$PLUTO_REPORT_FILE"

# --- 5a: API Resources ---
echo "--- API Resources ---" | tee -a "$PLUTO_REPORT_FILE"
API_EXIT=0
pluto detect-api-resources --target-versions "$PLUTO_TARGET" -o wide 2>&1 | tee -a "$PLUTO_REPORT_FILE" || API_EXIT=$?
echo "" | tee -a "$PLUTO_REPORT_FILE"

case $API_EXIT in
    0)
        log_info "[PASS] API resources: No deprecated APIs found"
        ;;
    2)
        log_warn "[WARN] API resources: Deprecated APIs found (still functional)"
        ((DEPRECATED_COUNT++))
        ;;
    3)
        log_error "[FAIL] API resources: Removed APIs found — upgrade will break workloads"
        ((REMOVED_COUNT++))
        GATE_FAILED=true
        ;;
    *)
        log_error "[FAIL] API resources: Pluto error (exit code: $API_EXIT)"
        GATE_FAILED=true
        ;;
esac

echo ""

# --- 5b: Helm Releases ---
if [[ "$SKIP_HELM_SCAN" != "true" ]]; then
    echo "--- Helm Releases ---" | tee -a "$PLUTO_REPORT_FILE"
    HELM_EXIT=0
    pluto detect-helm --target-versions "$PLUTO_TARGET" -o wide 2>&1 | tee -a "$PLUTO_REPORT_FILE" || HELM_EXIT=$?
    echo "" | tee -a "$PLUTO_REPORT_FILE"

    case $HELM_EXIT in
        0)
            log_info "[PASS] Helm releases: No deprecated APIs found"
            ;;
        2)
            log_warn "[WARN] Helm releases: Deprecated APIs found (still functional)"
            ((DEPRECATED_COUNT++))
            ;;
        3)
            log_error "[FAIL] Helm releases: Removed APIs found — upgrade will break Helm charts"
            ((REMOVED_COUNT++))
            GATE_FAILED=true
            ;;
        *)
            log_error "[FAIL] Helm releases: Pluto error (exit code: $HELM_EXIT)"
            GATE_FAILED=true
            ;;
    esac
else
    log_info "Helm scan skipped (SKIP_HELM_SCAN=true)"
fi

# --- Step 5c: Also fail on deprecation warnings if strict mode ---
if [[ "$FAIL_ON_DEPRECATION" == "true" && "$DEPRECATED_COUNT" -gt 0 ]]; then
    log_error "FAIL_ON_DEPRECATION is enabled and deprecated APIs were found"
    GATE_FAILED=true
fi

# --- Step 6: Summary ---
echo ""
echo "=============================================="
echo "Pre-Upgrade Gate Summary"
echo "=============================================="
echo "  Current version:      $CURRENT_K8S_VERSION"
echo "  Target version:       $TARGET_K8S_VERSION"
echo "  Removed APIs found:   $REMOVED_COUNT"
echo "  Deprecated warnings:  $DEPRECATED_COUNT"
echo ""

# --- Step 7: Create GitLab issue if gate failed ---
if [[ "$GATE_FAILED" == "true" && "$CREATE_GITLAB_ISSUE" == "true" ]]; then
    log_info "Creating GitLab issue for remediation..."

    if [[ -z "$GITLAB_PROJECT_ID" ]]; then
        log_error "GITLAB_PROJECT_ID not set — cannot create issue"
    elif [[ -z "$GITLAB_TOKEN" ]]; then
        log_error "GITLAB_TOKEN not set — cannot create issue"
    else
        PLUTO_OUTPUT=$(cat "$PLUTO_REPORT_FILE")
        CLUSTER_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "unknown")
        ISSUE_TITLE="[AKS Upgrade Blocked] Deprecated APIs detected — ${AKS_CLUSTER_NAME} (${CURRENT_K8S_VERSION} → ${TARGET_K8S_VERSION})"

        ISSUE_BODY=$(cat <<ISSUEEOF
## AKS Upgrade Blocked — Deprecated API Gate Failure

| Detail | Value |
|--------|-------|
| **Cluster** | \`${AKS_CLUSTER_NAME}\` |
| **Resource Group** | \`${RESOURCE_GROUP}\` |
| **Current Version** | \`${CURRENT_K8S_VERSION}\` |
| **Target Version** | \`${TARGET_K8S_VERSION}\` |
| **Cluster Context** | \`${CLUSTER_CONTEXT}\` |
| **Scan Date** | \`$(date -u '+%Y-%m-%d %H:%M:%S UTC')\` |
| **Pipeline** | \`${CI_PIPELINE_URL:-local run}\` |

## Pluto Scan Results

\`\`\`
${PLUTO_OUTPUT}
\`\`\`

## Required Actions

1. Review the deprecated/removed APIs listed above
2. Update manifests to use supported API versions:
   - \`extensions/v1beta1/Ingress\` → \`networking.k8s.io/v1/Ingress\`
   - \`networking.k8s.io/v1beta1/Ingress\` → \`networking.k8s.io/v1/Ingress\`
   - \`policy/v1beta1/PodSecurityPolicy\` → Removed (use Pod Security Admission)
   - \`rbac.authorization.k8s.io/v1beta1\` → \`rbac.authorization.k8s.io/v1\`
3. Redeploy updated manifests to the cluster
4. Re-run the pre-upgrade gate: \`./scripts/11-pre-upgrade-api-gate.sh\`
5. Once clean, proceed with the AKS upgrade

## References

- [AKS Kubernetes version support](https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions)
- [Kubernetes API deprecation guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)
- [Pluto documentation](https://pluto.docs.fairwinds.com/)

/label ~"aks-upgrade" ~"blocked" ~"api-deprecation"
/assign @platform-engineering
ISSUEEOF
        )

        # Create the GitLab issue
        HTTP_STATUS=$(curl -s -o /tmp/gitlab-issue-response.json -w "%{http_code}" \
            --request POST \
            "${GITLAB_API_URL}/projects/${GITLAB_PROJECT_ID}/issues" \
            --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
            --header "Content-Type: application/json" \
            --data "$(jq -n \
                --arg title "$ISSUE_TITLE" \
                --arg description "$ISSUE_BODY" \
                '{title: $title, description: $description, labels: "aks-upgrade,blocked,api-deprecation"}'
            )")

        if [[ "$HTTP_STATUS" -ge 200 && "$HTTP_STATUS" -lt 300 ]]; then
            ISSUE_URL=$(jq -r '.web_url' /tmp/gitlab-issue-response.json)
            log_info "GitLab issue created: $ISSUE_URL"
        else
            log_error "Failed to create GitLab issue (HTTP $HTTP_STATUS)"
            cat /tmp/gitlab-issue-response.json 2>/dev/null || true
        fi

        rm -f /tmp/gitlab-issue-response.json
    fi
fi

# Cleanup report file
rm -f "$PLUTO_REPORT_FILE"

# --- Step 8: Gate decision ---
echo ""
if [[ "$GATE_FAILED" == "true" ]]; then
    echo -e "${RED}=============================================="
    echo "UPGRADE BLOCKED"
    echo "==============================================${NC}"
    echo ""
    echo "Deprecated or removed APIs were detected in cluster '$AKS_CLUSTER_NAME'."
    echo "The AKS upgrade from $CURRENT_K8S_VERSION to $TARGET_K8S_VERSION has been blocked."
    echo ""
    echo "Remediate the issues above, then re-run this gate."
    exit 1
else
    echo -e "${GREEN}=============================================="
    echo "UPGRADE APPROVED"
    echo "==============================================${NC}"
    echo ""
    echo "No blocking API deprecations found. Safe to proceed with upgrade."
    echo "  $AKS_CLUSTER_NAME: $CURRENT_K8S_VERSION → $TARGET_K8S_VERSION"
    exit 0
fi
