#!/bin/bash

#==============================================================================
# Script: cleanup.sh
# Descripción: Limpia cluster etcd externo + control planes Kubernetes
# Uso: ./cleanup.sh [--force]
#==============================================================================

set -euo pipefail

#------------------------------------------------------------------------------
# CONFIGURACIÓN
#------------------------------------------------------------------------------

ETCD_NODES=(
  "etcd-01:192.168.1.201"
  "etcd-02:192.168.1.202"
  "etcd-03:192.168.1.203"
)

CONTROL_PLANES=(
  "master-01:192.168.1.11"
  "master-02:192.168.1.12"
  "master-03:192.168.1.13"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FORCE=false
[[ "${1:-}" == "--force" ]] && FORCE=true

#------------------------------------------------------------------------------
# FUNCIONES
#------------------------------------------------------------------------------

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

confirm_cleanup() {
    if ! $FORCE; then
        echo
        log_warn "Esta operación eliminará:"
        echo "  - Cluster Kubernetes (${#CONTROL_PLANES[@]} control planes)"
        echo "  - Cluster etcd (${#ETCD_NODES[@]} nodos)"
        echo "  - Todos los datos y configuraciones"
        echo
        read -p "¿Continuar? (yes/no): " response
        
        if [[ ! "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Cleanup cancelado"
            exit 0
        fi
    fi
}

cleanup_kubernetes() {
    log_info "Limpiando cluster Kubernetes..."
    
    local first_cp_ip="${CONTROL_PLANES[0]##*:}"
    
    # Drain y delete workers (si existen)
    local workers=$(ssh root@${first_cp_ip} "kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o name 2>/dev/null" || true)
    
    if [ -n "$workers" ]; then
        log_info "  Drenando workers..."
        for worker in $workers; do
            ssh root@${first_cp_ip} "kubectl drain $worker --ignore-daemonsets --delete-emptydir-data --force" 2>/dev/null || true
            ssh root@${first_cp_ip} "kubectl delete $worker" 2>/dev/null || true
        done
    fi
    
    log_info "✓ Workers limpiados"
}

reset_control_planes() {
    log_info "Reseteando control planes..."
    
    for node in "${CONTROL_PLANES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        
        log_info "  Reseteando ${name}..."
        ssh root@${ip} "kubeadm reset -f" 2>/dev/null || true
        ssh root@${ip} "rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /root/.kube" 2>/dev/null || true
        ssh root@${ip} "iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X" 2>/dev/null || true
    done
    
    log_info "✓ Control planes reseteados"
}

stop_etcd_cluster() {
    log_info "Deteniendo cluster etcd..."
    
    for node in "${ETCD_NODES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        
        log_info "  Deteniendo ${name}..."
        ssh root@${ip} "systemctl stop etcd" 2>/dev/null || true
        ssh root@${ip} "systemctl disable etcd" 2>/dev/null || true
    done
    
    log_info "✓ Cluster etcd detenido"
}

cleanup_etcd_data() {
    log_info "Eliminando datos etcd..."
    
    for node in "${ETCD_NODES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        
        log_info "  Limpiando ${name}..."
        ssh root@${ip} "rm -rf /var/lib/etcd /etc/etcd /etc/systemd/system/etcd.service" 2>/dev/null || true
        ssh root@${ip} "systemctl daemon-reload" 2>/dev/null || true
    done
    
    log_info "✓ Datos etcd eliminados"
}

cleanup_local_files() {
    log_info "Limpiando archivos locales..."
    
    if [ -d "./certs" ]; then
        rm -rf ./certs
        log_info "  Certificados locales eliminados"
    fi
    
    log_info "✓ Archivos locales limpiados"
}

verify_cleanup() {
    log_info "Verificando cleanup..."
    
    local issues=0
    
    # Verificar etcd detenido
    for node in "${ETCD_NODES[@]}"; do
        local ip="${node##*:}"
        if ssh root@${ip} "systemctl is-active etcd" 2>/dev/null | grep -q "active"; then
            log_warn "etcd aún activo en ${ip}"
            ((issues++))
        fi
    done
    
    # Verificar kubelet detenido
    for node in "${CONTROL_PLANES[@]}"; do
        local ip="${node##*:}"
        if ssh root@${ip} "systemctl is-active kubelet" 2>/dev/null | grep -q "active"; then
            log_warn "kubelet aún activo en ${ip}"
            ((issues++))
        fi
    done
    
    if [ $issues -eq 0 ]; then
        log_info "✓ Cleanup verificado - sin problemas"
    else
        log_warn "${issues} problemas detectados durante verificación"
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo "=========================================="
    echo "  External etcd Cluster Cleanup"
    echo "=========================================="
    echo
    
    confirm_cleanup
    
    cleanup_kubernetes
    reset_control_planes
    stop_etcd_cluster
    cleanup_etcd_data
    cleanup_local_files
    verify_cleanup
    
    echo
    log_info "=========================================="
    log_info "Cleanup completado exitosamente"
    log_info "=========================================="
}

main "$@"
