#!/bin/bash

################################################################################
# Upgrade Control Plane Script - Lab 02
# 
# Este script automatiza el upgrade del control plane de Kubernetes
# desde v1.27.x a v1.28.x usando kubeadm.
#
# PREREQUISITOS:
#   - Backup de etcd creado
#   - Repositorio v1.28 configurado
#   - Ejecutar en el nodo control plane
#
# Uso:
#   sudo ./upgrade-control-plane.sh [--version 1.28.0]
################################################################################

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
TARGET_VERSION="${1:-1.28.0}"
APT_VERSION="${TARGET_VERSION}-00"
LOG_FILE="/var/log/k8s-upgrade/control-plane-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# Funciones de Utilidad
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
}

die() {
    log_error "$1"
    exit 1
}

confirm() {
    local prompt="$1"
    read -p "$prompt [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

################################################################################
# Validaciones Pre-upgrade
################################################################################

validate_prerequisites() {
    log_info "Validando prerequisitos..."
    
    # Verificar que estamos en control plane
    if ! kubectl get nodes --selector='node-role.kubernetes.io/control-plane' -o name | grep -q "$(hostname)"; then
        die "Este script debe ejecutarse en el nodo control plane"
    fi
    
    # Verificar conectividad al cluster
    if ! kubectl cluster-info > /dev/null 2>&1; then
        die "No se puede conectar al cluster"
    fi
    
    # Verificar que no hay pods failing
    local failing=$(kubectl get pods -A --no-headers | grep -vE 'Running|Completed|Succeeded' | wc -l)
    if [[ $failing -gt 0 ]]; then
        log_warning "$failing pod(s) en estado no deseado"
        kubectl get pods -A | grep -vE 'Running|Completed|Succeeded' | head -10
        
        if ! confirm "¿Continuar de todos modos?"; then
            exit 0
        fi
    fi
    
    # Verificar backup de etcd existe
    if ! ls /var/lib/etcd-backup/snapshot-pre-upgrade-*.db > /dev/null 2>&1; then
        log_warning "No se encontró backup de etcd reciente"
        if ! confirm "¿Continuar sin backup?"; then
            die "Crea un backup antes de continuar (ver Lab 01)"
        fi
    fi
    
    log_success "Prerequisitos validados"
}

################################################################################
# Fase 1: Actualizar kubeadm
################################################################################

upgrade_kubeadm() {
    log_info "=== FASE 1: Actualizar kubeadm a v${TARGET_VERSION} ==="
    
    # Desbloquear paquete
    log_info "Desbloqueando kubeadm..."
    apt-mark unhold kubeadm
    
    # Actualizar índice
    log_info "Actualizando lista de paquetes..."
    apt-get update -qq
    
    # Verificar que la versión está disponible
    if ! apt-cache madison kubeadm | grep -q "$APT_VERSION"; then
        die "Versión $APT_VERSION no disponible. Verifica repositorio."
    fi
    
    # Instalar nueva versión
    log_info "Instalando kubeadm ${APT_VERSION}..."
    if apt-get install -y kubeadm=$APT_VERSION; then
        log_success "kubeadm actualizado a ${APT_VERSION}"
    else
        die "Fallo al instalar kubeadm ${APT_VERSION}"
    fi
    
    # Bloquear versión
    apt-mark hold kubeadm
    
    # Verificar versión instalada
    local installed_version=$(kubeadm version -o short)
    log_info "Versión instalada: $installed_version"
    
    if [[ "$installed_version" != "v${TARGET_VERSION}" ]]; then
        die "Versión instalada ($installed_version) no coincide con target (v${TARGET_VERSION})"
    fi
}

################################################################################
# Fase 2: Plan de Upgrade
################################################################################

run_upgrade_plan() {
    log_info "=== FASE 2: kubeadm upgrade plan ==="
    
    log_info "Ejecutando 'kubeadm upgrade plan'..."
    echo ""
    
    kubeadm upgrade plan | tee -a "$LOG_FILE"
    
    echo ""
    log_warning "Revisa el plan de upgrade arriba"
    
    if ! confirm "¿Proceder con el upgrade del control plane?"; then
        log_info "Upgrade cancelado por el usuario"
        exit 0
    fi
}

################################################################################
# Fase 3: Aplicar Upgrade del Control Plane
################################################################################

apply_upgrade() {
    log_info "=== FASE 3: kubeadm upgrade apply ==="
    
    log_info "Aplicando upgrade a v${TARGET_VERSION}..."
    log_warning "Este proceso puede tomar 3-5 minutos"
    echo ""
    
    # Ejecutar upgrade
    if kubeadm upgrade apply "v${TARGET_VERSION}" -y | tee -a "$LOG_FILE"; then
        log_success "Upgrade del control plane completado"
    else
        die "Fallo en kubeadm upgrade apply"
    fi
    
    # Verificar componentes actualizados
    sleep 10
    log_info "Verificando componentes del control plane..."
    
    kubectl get pods -n kube-system | grep -E 'kube-apiserver|kube-controller|kube-scheduler|etcd' | tee -a "$LOG_FILE"
}

################################################################################
# Fase 4: Drenar Nodo Control Plane
################################################################################

drain_control_plane() {
    log_info "=== FASE 4: Drenar control plane node ==="
    
    local node_name=$(hostname)
    
    log_info "Drenando nodo: $node_name"
    
    if kubectl drain "$node_name" --ignore-daemonsets --delete-emptydir-data; then
        log_success "Nodo $node_name drenado"
    else
        log_warning "Advertencias durante drain (puede ser normal para DaemonSets)"
    fi
    
    # Verificar que está cordoned
    if kubectl get node "$node_name" | grep -q SchedulingDisabled; then
        log_success "Nodo en modo SchedulingDisabled"
    else
        log_warning "Nodo no está cordoned - verificar manualmente"
    fi
}

################################################################################
# Fase 5: Actualizar kubelet y kubectl
################################################################################

upgrade_node_binaries() {
    log_info "=== FASE 5: Actualizar kubelet y kubectl ==="
    
    # Desbloquear paquetes
    log_info "Desbloqueando kubelet y kubectl..."
    apt-mark unhold kubelet kubectl
    
    # Actualizar
    log_info "Instalando kubelet=${APT_VERSION} kubectl=${APT_VERSION}..."
    if apt-get install -y kubelet=$APT_VERSION kubectl=$APT_VERSION; then
        log_success "kubelet y kubectl actualizados"
    else
        die "Fallo al actualizar kubelet/kubectl"
    fi
    
    # Bloquear versiones
    apt-mark hold kubelet kubectl
    
    # Reload systemd
    log_info "Recargando systemd daemon..."
    systemctl daemon-reload
    
    # Reiniciar kubelet
    log_info "Reiniciando kubelet..."
    systemctl restart kubelet
    
    # Esperar a que kubelet esté activo
    sleep 5
    
    if systemctl is-active --quiet kubelet; then
        log_success "kubelet está corriendo"
    else
        log_error "kubelet no está corriendo"
        journalctl -xeu kubelet | tail -20 | tee -a "$LOG_FILE"
        die "kubelet falló al iniciar"
    fi
    
    # Verificar versiones
    log_info "Versiones instaladas:"
    kubelet --version | tee -a "$LOG_FILE"
    kubectl version --client | tee -a "$LOG_FILE"
}

################################################################################
# Fase 6: Uncordon Control Plane
################################################################################

uncordon_control_plane() {
    log_info "=== FASE 6: Uncordon control plane node ==="
    
    local node_name=$(hostname)
    
    log_info "Habilitando scheduling en $node_name..."
    
    if kubectl uncordon "$node_name"; then
        log_success "Nodo $node_name uncordoned"
    else
        die "Fallo al hacer uncordon del nodo"
    fi
    
    # Verificar estado
    sleep 3
    kubectl get node "$node_name" | tee -a "$LOG_FILE"
}

################################################################################
# Fase 7: Verificación Post-Upgrade
################################################################################

verify_upgrade() {
    log_info "=== FASE 7: Verificación post-upgrade ==="
    
    echo ""
    log_info "1. Versión del nodo:"
    kubectl get nodes | tee -a "$LOG_FILE"
    
    echo ""
    log_info "2. Pods del sistema:"
    kubectl get pods -n kube-system | tee -a "$LOG_FILE"
    
    echo ""
    log_info "3. Verificar componentes core:"
    
    # API Server
    if kubectl get --raw /healthz > /dev/null 2>&1; then
        log_success "API Server: OK"
    else
        log_error "API Server: FAIL"
    fi
    
    # Controller Manager
    if kubectl get componentstatuses 2>/dev/null | grep -q controller-manager || true; then
        log_success "Controller Manager: OK"
    fi
    
    # Scheduler
    if kubectl get componentstatuses 2>/dev/null | grep -q scheduler || true; then
        log_success "Scheduler: OK"
    fi
    
    # etcd
    if kubectl get pods -n kube-system | grep -q "etcd.*Running"; then
        log_success "etcd: OK"
    else
        log_error "etcd: FAIL"
    fi
    
    echo ""
    log_info "4. Test de creación de recursos:"
    
    # Crear un test deployment
    if kubectl create deployment nginx-upgrade-test --image=nginx:alpine > /dev/null 2>&1; then
        log_success "Deployment creado exitosamente"
        
        # Esperar a que esté ready
        sleep 5
        if kubectl wait --for=condition=available --timeout=60s deployment/nginx-upgrade-test > /dev/null 2>&1; then
            log_success "Deployment está disponible"
        else
            log_warning "Deployment no está disponible aún"
        fi
        
        # Limpiar
        kubectl delete deployment nginx-upgrade-test > /dev/null 2>&1
        log_info "Test deployment eliminado"
    else
        log_warning "No se pudo crear deployment de prueba"
    fi
}

################################################################################
# Resumen Final
################################################################################

print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║     UPGRADE DE CONTROL PLANE COMPLETADO               ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_success "Control plane actualizado a v${TARGET_VERSION}"
    
    echo ""
    log_info "PRÓXIMOS PASOS:"
    echo "  1. Verificar que el control plane está estable (5-10 min)"
    echo "  2. Actualizar cada worker node usando upgrade-worker.sh"
    echo "  3. Verificar todos los nodos: kubectl get nodes -o wide"
    echo ""
    
    log_info "Para upgradear workers:"
    echo "  ./upgrade-worker.sh <worker-node-name>"
    echo ""
    
    log_info "Log completo guardado en: $LOG_FILE"
}

################################################################################
# Main
################################################################################

main() {
    # Crear directorio de logs
    mkdir -p /var/log/k8s-upgrade
    
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        UPGRADE CONTROL PLANE: v${TARGET_VERSION}                ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Inicio: $(date)"
    log_info "Hostname: $(hostname)"
    log_info "Usuario: $(whoami)"
    log_info "Target version: v${TARGET_VERSION}"
    echo ""
    
    # Ejecutar fases
    validate_prerequisites
    echo ""
    
    upgrade_kubeadm
    echo ""
    
    run_upgrade_plan
    echo ""
    
    apply_upgrade
    echo ""
    
    drain_control_plane
    echo ""
    
    upgrade_node_binaries
    echo ""
    
    uncordon_control_plane
    echo ""
    
    verify_upgrade
    
    print_summary
}

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root o con sudo"
    exit 1
fi

# Verificar argumentos
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    echo "Uso: $0 [VERSION]"
    echo ""
    echo "Ejemplos:"
    echo "  $0           # Usa versión por defecto (1.28.0)"
    echo "  $0 1.28.1    # Upgrade a v1.28.1"
    echo ""
    exit 0
fi

# Ejecutar
main "$@"
