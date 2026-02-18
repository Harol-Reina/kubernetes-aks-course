#!/bin/bash

##############################################################################
# Script: upgrade-cluster.sh
# Description: Automated Kubernetes cluster upgrade using kubeadm
# Usage: ./upgrade-cluster.sh <target-version>
# Example: ./upgrade-cluster.sh 1.28.4
##############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="/backup/k8s-upgrade-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/var/log/k8s-upgrade-$(date +%Y%m%d-%H%M%S).log"

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

usage() {
    cat << EOF
Usage: $0 <target-version>

Example:
  $0 1.28.4         # Upgrade to 1.28.4
  
Options:
  -h, --help        Show this help message
  -d, --dry-run     Run upgrade plan only (no changes)
  -s, --skip-backup Skip backup step (NOT recommended)
EOF
    exit 1
}

# Parse arguments
TARGET_VERSION=""
DRY_RUN=false
SKIP_BACKUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -s|--skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        *)
            TARGET_VERSION="$1"
            shift
            ;;
    esac
done

if [[ -z "$TARGET_VERSION" ]]; then
    error "Target version is required"
fi

# Main script
main() {
    check_root
    
    log "=== Kubernetes Cluster Upgrade to v${TARGET_VERSION} ==="
    
    # Step 1: Pre-upgrade checks
    log "Step 1/8: Running pre-upgrade checks..."
    
    # Check current version
    CURRENT_VERSION=$(kubectl version --short | grep Server | awk '{print $3}' | sed 's/v//')
    log "Current version: ${CURRENT_VERSION}"
    log "Target version: ${TARGET_VERSION}"
    
    # Verify cluster health
    log "Checking cluster health..."
    kubectl get nodes || error "Cannot connect to cluster"
    
    NOTREADY=$(kubectl get nodes --no-headers | grep -v Ready | wc -l)
    if [[ $NOTREADY -gt 0 ]]; then
        warn "Found ${NOTREADY} nodes not in Ready state"
        kubectl get nodes
        read -p "Continue anyway? (yes/no): " CONTINUE
        [[ "$CONTINUE" != "yes" ]] && exit 1
    fi
    
    # Check for problematic pods
    PROBLEM_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers | wc -l)
    if [[ $PROBLEM_PODS -gt 0 ]]; then
        warn "Found ${PROBLEM_PODS} pods not in Running/Succeeded state"
        kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded
        read -p "Continue anyway? (yes/no): " CONTINUE
        [[ "$CONTINUE" != "yes" ]] && exit 1
    fi
    
    # Step 2: Backup
    if [[ "$SKIP_BACKUP" == false ]]; then
        log "Step 2/8: Creating backups..."
        mkdir -p "$BACKUP_DIR"
        
        # etcd backup
        log "Backing up etcd..."
        ETCDCTL_API=3 etcdctl snapshot save "${BACKUP_DIR}/etcd-snapshot.db" \
            --endpoints=https://127.0.0.1:2379 \
            --cacert=/etc/kubernetes/pki/etcd/ca.crt \
            --cert=/etc/kubernetes/pki/etcd/server.crt \
            --key=/etc/kubernetes/pki/etcd/server.key || warn "etcd backup failed"
        
        # Kubernetes configs
        log "Backing up /etc/kubernetes..."
        tar -czf "${BACKUP_DIR}/kubernetes-configs.tar.gz" /etc/kubernetes || warn "Config backup failed"
        
        # All resources
        log "Backing up all resources..."
        kubectl get all --all-namespaces -o yaml > "${BACKUP_DIR}/all-resources.yaml" || warn "Resource backup failed"
        
        log "Backups saved to: ${BACKUP_DIR}"
    else
        log "Step 2/8: Skipping backup (--skip-backup flag)"
    fi
    
    # Step 3: Upgrade kubeadm
    log "Step 3/8: Upgrading kubeadm..."
    apt-mark unhold kubeadm
    apt-get update
    apt-get install -y kubeadm="${TARGET_VERSION}-00" || error "kubeadm upgrade failed"
    apt-mark hold kubeadm
    
    KUBEADM_VERSION=$(kubeadm version -o short | sed 's/v//')
    log "kubeadm upgraded to: ${KUBEADM_VERSION}"
    
    # Step 4: Upgrade plan
    log "Step 4/8: Running upgrade plan..."
    kubeadm upgrade plan || error "Upgrade plan failed"
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Dry-run mode: Stopping here"
        exit 0
    fi
    
    # Confirmation
    echo ""
    read -p "Proceed with upgrade? This will upgrade the control plane. (yes/no): " PROCEED
    if [[ "$PROCEED" != "yes" ]]; then
        log "Upgrade cancelled by user"
        exit 0
    fi
    
    # Step 5: Upgrade control plane
    log "Step 5/8: Upgrading control plane..."
    kubeadm upgrade apply "v${TARGET_VERSION}" -y || error "Control plane upgrade failed"
    
    # Step 6: Drain control plane node (if schedulable)
    CONTROL_PLANE_NODE=$(kubectl get nodes --selector=node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')
    log "Step 6/8: Draining control plane node: ${CONTROL_PLANE_NODE}"
    
    kubectl drain "$CONTROL_PLANE_NODE" --ignore-daemonsets --delete-emptydir-data || warn "Drain failed"
    
    # Step 7: Upgrade kubelet and kubectl
    log "Step 7/8: Upgrading kubelet and kubectl..."
    apt-mark unhold kubelet kubectl
    apt-get update
    apt-get install -y kubelet="${TARGET_VERSION}-00" kubectl="${TARGET_VERSION}-00" || error "kubelet/kubectl upgrade failed"
    apt-mark hold kubelet kubectl
    
    # Restart kubelet
    log "Restarting kubelet..."
    systemctl daemon-reload
    systemctl restart kubelet
    
    # Wait for kubelet to be ready
    sleep 10
    
    # Step 8: Uncordon control plane node
    log "Step 8/8: Uncordoning control plane node..."
    kubectl uncordon "$CONTROL_PLANE_NODE"
    
    # Final verification
    log "=== Upgrade Complete ==="
    log "Verifying cluster state..."
    
    kubectl get nodes
    kubectl get pods -n kube-system
    
    log "Current node versions:"
    kubectl get nodes -o wide
    
    log ""
    log "NEXT STEPS:"
    log "1. Verify all control plane pods are running: kubectl get pods -n kube-system"
    log "2. If HA cluster, upgrade additional control plane nodes with: kubeadm upgrade node"
    log "3. Upgrade worker nodes one by one (see safe-drain.sh)"
    log "4. Verify cluster health: kubectl get nodes"
    log ""
    log "Backup location: ${BACKUP_DIR}"
    log "Log file: ${LOG_FILE}"
}

# Run main
main
