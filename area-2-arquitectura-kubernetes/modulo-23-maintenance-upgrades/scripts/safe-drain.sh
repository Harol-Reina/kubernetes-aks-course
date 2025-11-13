#!/bin/bash

##############################################################################
# Script: safe-drain.sh
# Description: Safely drain Kubernetes nodes with checks and retries
# Usage: ./safe-drain.sh <node-name>
# Example: ./safe-drain.sh worker-01
##############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default configuration
GRACE_PERIOD=300
TIMEOUT=600
MAX_RETRIES=3
DELETE_EMPTYDIR=true
IGNORE_DAEMONSETS=true
FORCE=false

# Functions
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 <node-name> [options]

Options:
  -g, --grace-period <seconds>   Grace period for pod termination (default: 300)
  -t, --timeout <seconds>        Timeout for drain operation (default: 600)
  -r, --retries <number>         Max retries on failure (default: 3)
  -f, --force                    Force drain (delete standalone pods)
  --no-delete-emptydir           Don't delete pods with emptyDir volumes
  --no-ignore-daemonsets         Don't ignore DaemonSets (will fail)
  -h, --help                     Show this help

Examples:
  $0 worker-01                   # Basic drain
  $0 worker-01 -f                # Force drain
  $0 worker-01 -g 600 -t 900     # Custom timeouts
EOF
    exit 0
}

check_node_exists() {
    local node=$1
    if ! kubectl get node "$node" &>/dev/null; then
        error "Node '$node' not found in cluster"
    fi
}

check_node_role() {
    local node=$1
    local role=$(kubectl get node "$node" -o jsonpath='{.metadata.labels.node-role\.kubernetes\.io/control-plane}')
    
    if [[ -n "$role" ]]; then
        warn "Node '$node' is a control-plane node"
        read -p "Are you sure you want to drain a control-plane node? (yes/no): " CONFIRM
        [[ "$CONFIRM" != "yes" ]] && exit 1
    fi
}

show_node_info() {
    local node=$1
    
    info "Node Information:"
    kubectl get node "$node" -o wide
    
    echo ""
    info "Pods running on node (excluding kube-system DaemonSets):"
    kubectl get pods --all-namespaces --field-selector spec.nodeName="$node" \
        -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase \
        | grep -v "kube-" || echo "No pods found"
    
    echo ""
    local pod_count=$(kubectl get pods --all-namespaces --field-selector spec.nodeName="$node" --no-headers | wc -l)
    info "Total pods on node: $pod_count"
}

check_pdbs() {
    local node=$1
    
    info "Checking PodDisruptionBudgets..."
    local pdbs=$(kubectl get pdb --all-namespaces --no-headers 2>/dev/null | wc -l)
    
    if [[ $pdbs -gt 0 ]]; then
        warn "Found $pdbs PodDisruptionBudget(s) in cluster"
        echo ""
        kubectl get pdb --all-namespaces
        echo ""
        info "Drain will respect these PDBs (may take longer or fail)"
    else
        info "No PodDisruptionBudgets found"
    fi
}

check_stateful_workloads() {
    local node=$1
    
    info "Checking for StatefulSets on node..."
    local statefulsets=$(kubectl get pods --all-namespaces --field-selector spec.nodeName="$node" \
        -o jsonpath='{range .items[?(@.metadata.ownerReferences[0].kind=="StatefulSet")]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' \
        | wc -l)
    
    if [[ $statefulsets -gt 0 ]]; then
        warn "Found StatefulSet pods on node:"
        kubectl get pods --all-namespaces --field-selector spec.nodeName="$node" \
            -o jsonpath='{range .items[?(@.metadata.ownerReferences[0].kind=="StatefulSet")]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}'
        echo ""
        warn "StatefulSet pods may take longer to reschedule"
    fi
}

perform_drain() {
    local node=$1
    local attempt=$2
    
    log "Drain attempt $attempt of $MAX_RETRIES..."
    
    # Build drain command
    local drain_cmd="kubectl drain $node --grace-period=$GRACE_PERIOD --timeout=${TIMEOUT}s"
    
    if [[ "$IGNORE_DAEMONSETS" == true ]]; then
        drain_cmd="$drain_cmd --ignore-daemonsets"
    fi
    
    if [[ "$DELETE_EMPTYDIR" == true ]]; then
        drain_cmd="$drain_cmd --delete-emptydir-data"
    fi
    
    if [[ "$FORCE" == true ]]; then
        drain_cmd="$drain_cmd --force"
    fi
    
    info "Executing: $drain_cmd"
    
    if $drain_cmd; then
        return 0
    else
        return 1
    fi
}

verify_drain() {
    local node=$1
    
    log "Verifying drain..."
    
    # Check node is cordoned
    local schedulable=$(kubectl get node "$node" -o jsonpath='{.spec.unschedulable}')
    if [[ "$schedulable" != "true" ]]; then
        error "Node is not cordoned!"
    fi
    
    # Check pods (excluding DaemonSets)
    local remaining_pods=$(kubectl get pods --all-namespaces --field-selector spec.nodeName="$node" \
        -o json | jq '[.items[] | select(.metadata.ownerReferences[0].kind != "DaemonSet")] | length')
    
    if [[ $remaining_pods -gt 0 ]]; then
        warn "Found $remaining_pods non-DaemonSet pods still on node:"
        kubectl get pods --all-namespaces --field-selector spec.nodeName="$node" \
            | grep -v "DaemonSet"
        return 1
    fi
    
    log "✓ Node successfully drained"
    return 0
}

# Parse arguments
NODE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--grace-period)
            GRACE_PERIOD="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -r|--retries)
            MAX_RETRIES="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        --no-delete-emptydir)
            DELETE_EMPTYDIR=false
            shift
            ;;
        --no-ignore-daemonsets)
            IGNORE_DAEMONSETS=false
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            NODE="$1"
            shift
            ;;
    esac
done

if [[ -z "$NODE" ]]; then
    error "Node name is required. Use -h for help."
fi

# Main execution
main() {
    log "=== Safe Node Drain: $NODE ==="
    
    # Pre-drain checks
    check_node_exists "$NODE"
    check_node_role "$NODE"
    
    echo ""
    show_node_info "$NODE"
    
    echo ""
    check_pdbs "$NODE"
    
    echo ""
    check_stateful_workloads "$NODE"
    
    echo ""
    info "Drain Configuration:"
    echo "  Grace Period: ${GRACE_PERIOD}s"
    echo "  Timeout: ${TIMEOUT}s"
    echo "  Max Retries: $MAX_RETRIES"
    echo "  Delete emptyDir: $DELETE_EMPTYDIR"
    echo "  Ignore DaemonSets: $IGNORE_DAEMONSETS"
    echo "  Force: $FORCE"
    
    echo ""
    read -p "Proceed with drain? (yes/no): " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        log "Drain cancelled by user"
        exit 0
    fi
    
    # Perform drain with retries
    local success=false
    for attempt in $(seq 1 $MAX_RETRIES); do
        if perform_drain "$NODE" "$attempt"; then
            success=true
            break
        else
            if [[ $attempt -lt $MAX_RETRIES ]]; then
                warn "Drain failed, retrying in 10 seconds..."
                sleep 10
            fi
        fi
    done
    
    if [[ "$success" != true ]]; then
        error "Drain failed after $MAX_RETRIES attempts"
    fi
    
    echo ""
    verify_drain "$NODE"
    
    echo ""
    log "=== Drain Complete ==="
    info "Node '$NODE' is now cordoned and drained"
    info ""
    info "NEXT STEPS:"
    info "1. Perform maintenance on node"
    info "2. When ready, uncordon node: kubectl uncordon $NODE"
    info "3. Verify node status: kubectl get nodes"
}

# Check dependencies
if ! command -v jq &>/dev/null; then
    error "jq is required but not installed. Install with: apt-get install jq"
fi

main
