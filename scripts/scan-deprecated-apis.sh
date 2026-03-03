#!/bin/bash
#
# Kubernetes API Deprecation Scanner (Pluto)
# Scans manifest files and/or live clusters for deprecated/removed API versions.
#
# Usage:
#   SCAN_MODE=static ./scripts/scan-deprecated-apis.sh   # Scan manifest files only (no cluster needed)
#   SCAN_MODE=live   ./scripts/scan-deprecated-apis.sh   # Scan live cluster only
#   SCAN_MODE=all    ./scripts/scan-deprecated-apis.sh   # Both (default)
#
# Environment variables:
#   TARGET_K8S_VERSION  - K8s version to check against (default: from parameters file)
#   SCAN_MODE           - static, live, or all (default: all)
#   MANIFEST_DIR        - Path to manifest files (default: $PROJECT_DIR/kubernetes)
#   OUTPUT_FORMAT       - Pluto output format (default: wide)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN_COUNT++))
}

log_info() {
    echo -e "[INFO] $1"
}

# Configuration with defaults
PARAMS_FILE="$PROJECT_DIR/arm-templates/02-aks-cluster.parameters.json"
if [[ -z "${TARGET_K8S_VERSION:-}" ]]; then
    if [[ -f "$PARAMS_FILE" ]]; then
        TARGET_K8S_VERSION=$(jq -r '.parameters.kubernetesVersion.value' "$PARAMS_FILE")
        log_info "Auto-detected K8s version from parameters: $TARGET_K8S_VERSION"
    else
        TARGET_K8S_VERSION="1.34"
        log_info "Parameters file not found, defaulting to K8s $TARGET_K8S_VERSION"
    fi
fi

SCAN_MODE="${SCAN_MODE:-all}"
MANIFEST_DIR="${MANIFEST_DIR:-$PROJECT_DIR/kubernetes}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-wide}"

# Normalize version format for Pluto (needs v prefix and patch version)
PLUTO_TARGET="k8s=v${TARGET_K8S_VERSION#v}.0"

echo "=============================================="
echo "Kubernetes API Deprecation Scanner"
echo "=============================================="
echo ""
echo "Configuration:"
echo "  Target K8s Version: $TARGET_K8S_VERSION ($PLUTO_TARGET)"
echo "  Scan Mode:          $SCAN_MODE"
echo "  Manifest Directory: $MANIFEST_DIR"
echo "  Output Format:      $OUTPUT_FORMAT"
echo ""

# Check Pluto is installed
if ! command -v pluto &>/dev/null; then
    log_fail "Pluto is not installed"
    echo ""
    echo "Install Pluto:"
    echo "  macOS:  brew install FairwindsOps/tap/pluto"
    echo "  Linux:  curl -fsSL https://github.com/FairwindsOps/pluto/releases/latest/download/pluto_linux_amd64.tar.gz | tar xz -C /usr/local/bin"
    echo "  Docker: docker run us-docker.pkg.dev/fairwinds-ops/oss/pluto:v5 <command>"
    echo ""
    exit 1
fi

PLUTO_VERSION=$(pluto version --short 2>/dev/null || pluto version 2>/dev/null | head -1 || echo "unknown")
log_info "Pluto version: $PLUTO_VERSION"
echo ""

# Handle Pluto exit codes:
#   0 = clean (no deprecated APIs)
#   1 = error
#   2 = deprecated APIs found (still functional)
#   3 = removed APIs found (will break)
handle_pluto_exit() {
    local exit_code=$1
    local scan_type=$2

    case $exit_code in
        0)
            log_pass "$scan_type: No deprecated Kubernetes APIs found"
            ;;
        2)
            log_warn "$scan_type: Deprecated APIs found (still functional, plan migration)"
            ;;
        3)
            log_fail "$scan_type: Removed APIs found (will break on K8s $TARGET_K8S_VERSION)"
            ;;
        *)
            log_fail "$scan_type: Pluto encountered an error (exit code: $exit_code)"
            ;;
    esac
}

# --- Static Scan: Manifest Files ---
run_static_scan() {
    echo "=== Static Scan: Manifest Files ==="
    echo ""

    if [[ ! -d "$MANIFEST_DIR" ]]; then
        log_warn "Manifest directory not found: $MANIFEST_DIR"
        return
    fi

    local file_count
    file_count=$(find "$MANIFEST_DIR" -name "*.yaml" -o -name "*.yml" | wc -l | tr -d ' ')
    log_info "Scanning $file_count manifest files in $MANIFEST_DIR"
    echo ""

    local exit_code=0
    pluto detect-files -d "$MANIFEST_DIR" --target-versions "$PLUTO_TARGET" -o "$OUTPUT_FORMAT" || exit_code=$?
    echo ""
    handle_pluto_exit $exit_code "Static scan"
}

# --- Live Scan: In-Cluster API Resources ---
run_live_scan() {
    echo "=== Live Scan: In-Cluster Resources ==="
    echo ""

    # Check kubectl connectivity
    if ! kubectl cluster-info &>/dev/null; then
        log_fail "kubectl cannot connect to cluster — skipping live scan"
        return
    fi

    local cluster_context
    cluster_context=$(kubectl config current-context 2>/dev/null || echo "unknown")
    log_info "Scanning cluster: $cluster_context"
    echo ""

    # Scan API resources
    echo "--- API Resources ---"
    local exit_code=0
    pluto detect-api-resources --target-versions "$PLUTO_TARGET" -o "$OUTPUT_FORMAT" || exit_code=$?
    echo ""
    handle_pluto_exit $exit_code "API resources scan"

    echo ""

    # Scan Helm releases (if any)
    echo "--- Helm Releases ---"
    local helm_exit=0
    pluto detect-helm --target-versions "$PLUTO_TARGET" -o "$OUTPUT_FORMAT" || helm_exit=$?
    echo ""
    handle_pluto_exit $helm_exit "Helm releases scan"
}

# --- Run scans based on mode ---
case "$SCAN_MODE" in
    static)
        run_static_scan
        ;;
    live)
        run_live_scan
        ;;
    all)
        run_static_scan
        echo ""
        run_live_scan
        ;;
    *)
        log_fail "Invalid SCAN_MODE: $SCAN_MODE (expected: static, live, or all)"
        exit 1
        ;;
esac

# --- Summary ---
echo ""
echo "=============================================="
echo "Deprecation Scan Summary"
echo "=============================================="
echo -e "${GREEN}PASSED:${NC}   $PASS_COUNT"
echo -e "${RED}FAILED:${NC}   $FAIL_COUNT"
echo -e "${YELLOW}WARNINGS:${NC} $WARN_COUNT"
echo ""

if [[ "$FAIL_COUNT" -eq 0 ]]; then
    echo -e "${GREEN}API deprecation scan PASSED${NC}"
    exit 0
else
    echo -e "${RED}API deprecation scan has FAILURES${NC}"
    exit 1
fi
