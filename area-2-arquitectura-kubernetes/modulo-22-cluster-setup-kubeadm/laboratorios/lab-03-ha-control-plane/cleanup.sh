#!/bin/bash
#
# cleanup.sh - Limpieza completa de cluster HA
#
# Propósito:
#   Elimina completamente un cluster HA incluyendo:
#   - Todos los control planes
#   - Configuración del Load Balancer
#   - Archivos de Kubernetes
#   - Configuraciones de red
#   - Datos de etcd
#
# Uso:
#   ./cleanup.sh [--master1-ip IP] [--master2-ip IP] [--master3-ip IP] [--lb-ip IP]
#   ./cleanup.sh --all-ips "IP1 IP2 IP3 LB_IP"
#
# ⚠️ ADVERTENCIA: Esta operación es IRREVERSIBLE
#
# Author: Kubernetes Course
# Version: 1.0
#

set -euo pipefail

#---------------------------------------------------------------------
# Variables globales
#---------------------------------------------------------------------

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

MASTER1_IP=""
MASTER2_IP=""
MASTER3_IP=""
LB_IP=""
FORCE=false

#---------------------------------------------------------------------
# Funciones de utilidad
#---------------------------------------------------------------------

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $*"
}

log_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $*"
}

usage() {
    cat <<EOF
Uso: $0 [OPTIONS]

Opciones:
  --master1-ip IP    IP del primer control plane
  --master2-ip IP    IP del segundo control plane
  --master3-ip IP    IP del tercer control plane
  --lb-ip IP         IP del Load Balancer
  --all-ips "IPs"    Todas las IPs separadas por espacio (master1 master2 master3 lb)
  --force            No pedir confirmación
  --help             Mostrar esta ayuda

Ejemplos:
  $0 --master1-ip 192.168.1.101 --master2-ip 192.168.1.102 \\
     --master3-ip 192.168.1.103 --lb-ip 192.168.1.100

  $0 --all-ips "192.168.1.101 192.168.1.102 192.168.1.103 192.168.1.100"

  $0 --force  # Detecta IPs automáticamente

EOF
    exit 1
}

#---------------------------------------------------------------------
# Parse argumentos
#---------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --master1-ip)
                MASTER1_IP="$2"
                shift 2
                ;;
            --master2-ip)
                MASTER2_IP="$2"
                shift 2
                ;;
            --master3-ip)
                MASTER3_IP="$2"
                shift 2
                ;;
            --lb-ip)
                LB_IP="$2"
                shift 2
                ;;
            --all-ips)
                IPS=($2)
                MASTER1_IP="${IPS[0]:-}"
                MASTER2_IP="${IPS[1]:-}"
                MASTER3_IP="${IPS[2]:-}"
                LB_IP="${IPS[3]:-}"
                shift 2
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --help)
                usage
                ;;
            *)
                log_error "Opción desconocida: $1"
                usage
                ;;
        esac
    done
}

#---------------------------------------------------------------------
# Confirmación de usuario
#---------------------------------------------------------------------

confirm_cleanup() {
    if [[ "$FORCE" == true ]]; then
        return 0
    fi

    echo ""
    echo "========================================"
    echo "⚠️  ADVERTENCIA: OPERACIÓN DESTRUCTIVA"
    echo "========================================"
    echo ""
    echo "Esta operación eliminará COMPLETAMENTE el cluster HA:"
    echo ""
    [[ -n "$MASTER1_IP" ]] && echo "  - Control Plane 1: $MASTER1_IP"
    [[ -n "$MASTER2_IP" ]] && echo "  - Control Plane 2: $MASTER2_IP"
    [[ -n "$MASTER3_IP" ]] && echo "  - Control Plane 3: $MASTER3_IP"
    [[ -n "$LB_IP" ]] && echo "  - Load Balancer: $LB_IP"
    echo ""
    echo "Esto incluye:"
    echo "  • Todos los workloads y datos"
    echo "  • Configuración de Kubernetes"
    echo "  • Datos de etcd"
    echo "  • Certificados"
    echo "  • Configuración de red"
    echo ""
    echo -e "${RED}Esta operación es IRREVERSIBLE${NC}"
    echo ""
    read -p "¿Estás seguro de continuar? (escribe 'yes' para confirmar): " confirmation

    if [[ "$confirmation" != "yes" ]]; then
        log_warn "Operación cancelada por el usuario"
        exit 0
    fi

    echo ""
    log_warn "Iniciando limpieza en 5 segundos... (Ctrl+C para cancelar)"
    sleep 5
}

#---------------------------------------------------------------------
# Paso 1: Drain y delete nodes
#---------------------------------------------------------------------

drain_and_delete_nodes() {
    echo ""
    echo "========================================"
    echo "Paso 1: Drain y Delete Nodes"
    echo "========================================"
    echo ""

    if ! kubectl get nodes &>/dev/null; then
        log_warn "No se puede conectar al cluster, saltando drain"
        return
    fi

    # Obtener lista de nodos
    NODES=$(kubectl get nodes --no-headers -o custom-columns=NAME:.metadata.name)

    for node in $NODES; do
        log "Draining node: $node"
        kubectl drain "$node" \
            --ignore-daemonsets \
            --delete-emptydir-data \
            --force \
            --timeout=60s 2>/dev/null || log_warn "Drain falló para $node (continuando)"

        log "Deleting node: $node"
        kubectl delete node "$node" --wait=false 2>/dev/null || log_warn "Delete falló para $node"
    done

    log "✅ Nodes drained y deleted"
}

#---------------------------------------------------------------------
# Paso 2: Reset control planes
#---------------------------------------------------------------------

reset_control_planes() {
    echo ""
    echo "========================================"
    echo "Paso 2: Reset Control Planes"
    echo "========================================"
    echo ""

    for ip in "$MASTER1_IP" "$MASTER2_IP" "$MASTER3_IP"; do
        if [[ -z "$ip" ]]; then
            continue
        fi

        log "Reseteando control plane: $ip"

        # Ejecutar kubeadm reset
        ssh "$ip" "sudo kubeadm reset -f" 2>/dev/null || log_warn "kubeadm reset falló en $ip"

        # Eliminar directorios de Kubernetes
        log_info "Eliminando directorios de Kubernetes en $ip..."
        ssh "$ip" "
            sudo rm -rf /etc/kubernetes
            sudo rm -rf /var/lib/kubelet
            sudo rm -rf /var/lib/etcd
            sudo rm -rf ~/.kube
        " 2>/dev/null || log_warn "Limpieza de directorios falló en $ip"

        # Limpiar iptables
        log_info "Limpiando reglas iptables en $ip..."
        ssh "$ip" "
            sudo iptables -F
            sudo iptables -t nat -F
            sudo iptables -t mangle -F
            sudo iptables -X
        " 2>/dev/null || log_warn "Limpieza de iptables falló en $ip"

        # Limpiar interfaces CNI
        log_info "Limpiando interfaces CNI en $ip..."
        ssh "$ip" "
            sudo ip link delete cni0 2>/dev/null || true
            sudo ip link delete flannel.1 2>/dev/null || true
            sudo ip link delete tunl0 2>/dev/null || true
            sudo rm -rf /var/lib/cni/
            sudo rm -rf /etc/cni/net.d/
        " 2>/dev/null || log_warn "Limpieza de CNI falló en $ip"

        # Reiniciar servicios
        log_info "Reiniciando servicios en $ip..."
        ssh "$ip" "
            sudo systemctl restart containerd
            sudo systemctl restart kubelet 2>/dev/null || true
        " 2>/dev/null || log_warn "Reinicio de servicios falló en $ip"

        log "✅ Control plane $ip reseteado"
    done

    log "✅ Todos los control planes reseteados"
}

#---------------------------------------------------------------------
# Paso 3: Limpiar Load Balancer
#---------------------------------------------------------------------

cleanup_load_balancer() {
    echo ""
    echo "========================================"
    echo "Paso 3: Limpiar Load Balancer"
    echo "========================================"
    echo ""

    if [[ -z "$LB_IP" ]]; then
        log_warn "No se proporcionó IP del Load Balancer, saltando limpieza"
        return
    fi

    log "Limpiando Load Balancer: $LB_IP"

    # Detener HAProxy
    log_info "Deteniendo HAProxy..."
    ssh "$LB_IP" "sudo systemctl stop haproxy" 2>/dev/null || log_warn "Stop HAProxy falló"

    # Restaurar configuración original (si existe backup)
    log_info "Restaurando configuración original de HAProxy..."
    ssh "$LB_IP" "
        if [ -f /etc/haproxy/haproxy.cfg.backup ]; then
            sudo cp /etc/haproxy/haproxy.cfg.backup /etc/haproxy/haproxy.cfg
            echo 'Configuración restaurada desde backup'
        else
            echo 'No se encontró backup de configuración'
        fi
    " 2>/dev/null || log_warn "Restauración de config falló"

    # Opcional: Desinstalar HAProxy
    read -p "¿Desinstalar HAProxy del Load Balancer? (y/N): " uninstall_haproxy
    if [[ "$uninstall_haproxy" == "y" || "$uninstall_haproxy" == "Y" ]]; then
        log_info "Desinstalando HAProxy..."
        ssh "$LB_IP" "sudo apt-get remove -y haproxy" 2>/dev/null || \
        ssh "$LB_IP" "sudo yum remove -y haproxy" 2>/dev/null || \
        log_warn "Desinstalación de HAProxy falló"
    else
        # Solo reiniciar con config limpia
        ssh "$LB_IP" "sudo systemctl start haproxy" 2>/dev/null || true
    fi

    log "✅ Load Balancer limpiado"
}

#---------------------------------------------------------------------
# Paso 4: Limpiar archivos locales
#---------------------------------------------------------------------

cleanup_local_files() {
    echo ""
    echo "========================================"
    echo "Paso 4: Limpiar Archivos Locales"
    echo "========================================"
    echo ""

    # Limpiar kubeconfig local
    if [[ -f ~/.kube/config ]]; then
        log "Haciendo backup de kubeconfig local..."
        cp ~/.kube/config ~/.kube/config.backup-$(date +%Y%m%d-%H%M%S)
        
        read -p "¿Eliminar kubeconfig local (~/.kube/config)? (y/N): " delete_kubeconfig
        if [[ "$delete_kubeconfig" == "y" || "$delete_kubeconfig" == "Y" ]]; then
            rm -f ~/.kube/config
            log "✅ kubeconfig local eliminado"
        else
            log_info "kubeconfig local preservado"
        fi
    fi

    # Limpiar archivos temporales del script
    log "Limpiando archivos temporales..."
    rm -f /tmp/haproxy.cfg
    rm -f /tmp/kubeadm-config.yaml
    rm -f /tmp/kubeadm-init-output.log

    log "✅ Archivos locales limpiados"
}

#---------------------------------------------------------------------
# Paso 5: Verificación final
#---------------------------------------------------------------------

verify_cleanup() {
    echo ""
    echo "========================================"
    echo "Paso 5: Verificación Final"
    echo "========================================"
    echo ""

    log "Verificando limpieza de control planes..."

    for ip in "$MASTER1_IP" "$MASTER2_IP" "$MASTER3_IP"; do
        if [[ -z "$ip" ]]; then
            continue
        fi

        # Verificar que no haya procesos de Kubernetes corriendo
        K8S_PROCS=$(ssh "$ip" "ps aux | grep -E 'kube|etcd' | grep -v grep | wc -l" 2>/dev/null || echo "0")
        
        if [[ $K8S_PROCS -eq 0 ]]; then
            log "✅ $ip: Sin procesos de Kubernetes"
        else
            log_warn "$ip: Todavía hay $K8S_PROCS procesos de Kubernetes corriendo"
        fi

        # Verificar directorios eliminados
        DIRS_EXIST=$(ssh "$ip" "ls -d /etc/kubernetes /var/lib/kubelet /var/lib/etcd 2>/dev/null | wc -l" 2>/dev/null || echo "0")
        
        if [[ $DIRS_EXIST -eq 0 ]]; then
            log "✅ $ip: Directorios eliminados correctamente"
        else
            log_warn "$ip: Algunos directorios todavía existen"
        fi
    done

    # Verificar Load Balancer
    if [[ -n "$LB_IP" ]]; then
        if ssh "$LB_IP" "sudo netstat -tulpn | grep -q :6443"; then
            log_warn "Load Balancer todavía escucha en puerto 6443"
        else
            log "✅ Load Balancer: Puerto 6443 cerrado"
        fi
    fi

    log "✅ Verificación final completada"
}

#---------------------------------------------------------------------
# Resumen final
#---------------------------------------------------------------------

print_summary() {
    echo ""
    echo "========================================"
    echo "✅ Limpieza Completada"
    echo "========================================"
    echo ""
    echo "El cluster HA ha sido eliminado completamente."
    echo ""
    echo "Nodos limpiados:"
    [[ -n "$MASTER1_IP" ]] && echo "  ✅ Control Plane 1: $MASTER1_IP"
    [[ -n "$MASTER2_IP" ]] && echo "  ✅ Control Plane 2: $MASTER2_IP"
    [[ -n "$MASTER3_IP" ]] && echo "  ✅ Control Plane 3: $MASTER3_IP"
    [[ -n "$LB_IP" ]] && echo "  ✅ Load Balancer: $LB_IP"
    echo ""
    echo "Para crear un nuevo cluster:"
    echo "  ./setup-ha.sh --lb-ip <LB> --master1-ip <M1> --master2-ip <M2> --master3-ip <M3>"
    echo ""
}

#---------------------------------------------------------------------
# Main
#---------------------------------------------------------------------

main() {
    echo "========================================"
    echo "🧹 Cleanup de Cluster HA"
    echo "========================================"
    echo ""

    parse_args "$@"

    # Intentar detectar IPs si no se proporcionaron
    if [[ -z "$MASTER1_IP" ]] && kubectl get nodes &>/dev/null; then
        log_info "Detectando IPs automáticamente..."
        
        CONTROL_PLANES=($(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'))
        MASTER1_IP="${CONTROL_PLANES[0]:-}"
        MASTER2_IP="${CONTROL_PLANES[1]:-}"
        MASTER3_IP="${CONTROL_PLANES[2]:-}"
        
        LB_IP=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}' | grep -oP '//\K[^:]+' || echo "")
        
        log_info "IPs detectadas: M1=$MASTER1_IP M2=$MASTER2_IP M3=$MASTER3_IP LB=$LB_IP"
    fi

    # Confirmar antes de proceder
    confirm_cleanup

    # Ejecutar limpieza
    drain_and_delete_nodes
    reset_control_planes
    cleanup_load_balancer
    cleanup_local_files
    verify_cleanup

    # Resumen
    print_summary
}

# Ejecutar
main "$@"
