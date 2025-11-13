#!/bin/bash

##############################################################################
# Script: cert-monitor.sh
# Description: Monitor Kubernetes certificate expiration and send alerts
# Usage: ./cert-monitor.sh [options]
# Example: ./cert-monitor.sh --alert-days 30
##############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
ALERT_THRESHOLD_DAYS=90
LOG_FILE="/var/log/k8s-cert-monitor.log"
ALERT_EMAIL=""

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

usage() {
    cat << EOF
Usage: $0 [options]

Options:
  -d, --alert-days <days>     Alert threshold in days (default: 90)
  -e, --email <address>       Send alerts to email
  -r, --renew                 Auto-renew certificates if needed
  -c, --check-only            Only check, don't take action
  -h, --help                  Show this help

Examples:
  $0                          # Check certificates
  $0 --alert-days 30          # Alert if cert expires in <30 days
  $0 --renew                  # Check and auto-renew if needed
  $0 --email admin@example.com --alert-days 60
EOF
    exit 0
}

check_cert_expiration() {
    log "Checking certificate expiration..."
    
    if ! command -v kubeadm &>/dev/null; then
        error "kubeadm not found"
        return 1
    fi
    
    # Get expiration info
    local cert_output=$(sudo kubeadm certs check-expiration 2>&1)
    
    echo "$cert_output" | tee -a "$LOG_FILE"
    
    return 0
}

parse_cert_days() {
    local cert_name=$1
    
    # Extract remaining days from kubeadm output
    local cert_line=$(sudo kubeadm certs check-expiration 2>/dev/null | grep "^$cert_name")
    
    if [[ -z "$cert_line" ]]; then
        return -1
    fi
    
    # Parse "364d" format
    local days_str=$(echo "$cert_line" | awk '{print $3}' | grep -oP '\d+(?=d)')
    
    if [[ -z "$days_str" ]]; then
        # Maybe it's hours format "23h"
        local hours_str=$(echo "$cert_line" | awk '{print $3}' | grep -oP '\d+(?=h)')
        if [[ -n "$hours_str" ]]; then
            days_str=$(( hours_str / 24 ))
        else
            return -1
        fi
    fi
    
    echo "$days_str"
}

check_individual_certs() {
    local certs=(
        "admin.conf"
        "apiserver"
        "apiserver-etcd-client"
        "apiserver-kubelet-client"
        "controller-manager.conf"
        "etcd-healthcheck-client"
        "etcd-peer"
        "etcd-server"
        "front-proxy-client"
        "scheduler.conf"
    )
    
    local expired_certs=()
    local warning_certs=()
    
    log "Analyzing individual certificates..."
    
    for cert in "${certs[@]}"; do
        local days=$(parse_cert_days "$cert")
        
        if [[ $days -eq -1 ]]; then
            continue
        fi
        
        if [[ $days -le 0 ]]; then
            error "EXPIRED: $cert"
            expired_certs+=("$cert")
        elif [[ $days -le $ALERT_THRESHOLD_DAYS ]]; then
            warn "EXPIRING SOON ($days days): $cert"
            warning_certs+=("$cert")
        else
            log "✓ OK ($days days): $cert"
        fi
    done
    
    # Check CAs (typically 10 years)
    local ca_certs=("ca" "etcd-ca" "front-proxy-ca")
    
    log ""
    log "Certificate Authorities:"
    for ca in "${ca_certs[@]}"; do
        local ca_line=$(sudo kubeadm certs check-expiration 2>/dev/null | grep "^$ca " | grep -v "CERTIFICATE")
        if [[ -n "$ca_line" ]]; then
            local ca_days=$(echo "$ca_line" | awk '{print $3}')
            log "  $ca: $ca_days"
        fi
    done
    
    # Summary
    echo ""
    if [[ ${#expired_certs[@]} -gt 0 ]]; then
        error "CRITICAL: ${#expired_certs[@]} certificate(s) EXPIRED!"
        return 2
    elif [[ ${#warning_certs[@]} -gt 0 ]]; then
        warn "WARNING: ${#warning_certs[@]} certificate(s) expiring within $ALERT_THRESHOLD_DAYS days"
        return 1
    else
        log "✓ All certificates are valid"
        return 0
    fi
}

renew_certificates() {
    log "Renewing all certificates..."
    
    if ! sudo kubeadm certs renew all; then
        error "Certificate renewal failed"
        return 1
    fi
    
    log "✓ Certificates renewed successfully"
    
    # Update admin kubeconfig
    if [[ -f /etc/kubernetes/admin.conf ]]; then
        log "Updating admin kubeconfig..."
        sudo cp /etc/kubernetes/admin.conf ~/.kube/config
        sudo chown $(id -u):$(id -g) ~/.kube/config
    fi
    
    # Restart kubelet to pick up new certs
    log "Restarting kubelet..."
    sudo systemctl restart kubelet
    
    log "Waiting for kubelet to be ready..."
    sleep 10
    
    if systemctl is-active --quiet kubelet; then
        log "✓ kubelet restarted successfully"
    else
        error "kubelet failed to restart"
        return 1
    fi
    
    return 0
}

send_alert() {
    local subject=$1
    local message=$2
    
    if [[ -z "$ALERT_EMAIL" ]]; then
        return 0
    fi
    
    if command -v mail &>/dev/null; then
        echo "$message" | mail -s "$subject" "$ALERT_EMAIL"
        log "Alert email sent to $ALERT_EMAIL"
    else
        warn "mail command not found, cannot send email"
    fi
}

generate_report() {
    local report_file="/tmp/k8s-cert-report-$(date +%Y%m%d).txt"
    
    log "Generating certificate report..."
    
    {
        echo "Kubernetes Certificate Report"
        echo "=============================="
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo ""
        echo "Certificate Expiration Details:"
        echo "------------------------------"
        sudo kubeadm certs check-expiration
        echo ""
        echo "------------------------------"
        echo "Alert Threshold: $ALERT_THRESHOLD_DAYS days"
    } > "$report_file"
    
    log "Report saved to: $report_file"
    
    echo "$report_file"
}

# Parse arguments
AUTO_RENEW=false
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--alert-days)
            ALERT_THRESHOLD_DAYS="$2"
            shift 2
            ;;
        -e|--email)
            ALERT_EMAIL="$2"
            shift 2
            ;;
        -r|--renew)
            AUTO_RENEW=true
            shift
            ;;
        -c|--check-only)
            CHECK_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            error "Unknown option: $1"
            usage
            ;;
    esac
done

# Main execution
main() {
    log "=== Kubernetes Certificate Monitor ==="
    log "Alert threshold: $ALERT_THRESHOLD_DAYS days"
    
    # Check expiration
    check_cert_expiration
    
    echo ""
    check_individual_certs
    local status=$?
    
    echo ""
    
    # Generate report
    local report_file=$(generate_report)
    
    # Handle based on status
    if [[ $status -eq 2 ]]; then
        # Expired certificates
        send_alert "CRITICAL: Kubernetes Certificates EXPIRED" "$(cat $report_file)"
        
        if [[ "$AUTO_RENEW" == true ]] && [[ "$CHECK_ONLY" == false ]]; then
            log "Auto-renew enabled, attempting renewal..."
            renew_certificates
        else
            error "Manual intervention required"
            exit 2
        fi
        
    elif [[ $status -eq 1 ]]; then
        # Expiring soon
        send_alert "WARNING: Kubernetes Certificates Expiring Soon" "$(cat $report_file)"
        
        if [[ "$AUTO_RENEW" == true ]] && [[ "$CHECK_ONLY" == false ]]; then
            log "Auto-renew enabled, renewing certificates..."
            renew_certificates
        else
            warn "Consider renewing certificates soon"
        fi
        
    else
        # All OK
        log "All certificates are healthy"
        
        if [[ -n "$ALERT_EMAIL" ]]; then
            send_alert "INFO: Kubernetes Certificates OK" "$(cat $report_file)"
        fi
    fi
    
    log "=== Certificate Check Complete ==="
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root"
fi

main
