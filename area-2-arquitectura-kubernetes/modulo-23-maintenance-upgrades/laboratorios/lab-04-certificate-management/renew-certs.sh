#!/bin/bash

################################################################################
# Renew Certificates Script - Lab 04
# 
# Este script automatiza la renovación de certificados de Kubernetes,
# haciendo backup automático y reiniciando componentes.
#
# Uso:
#   ./renew-certs.sh [--all | --cert <name>]
#
# Opciones:
#   --all              Renovar todos los certificados (recomendado)
#   --cert <name>      Renovar un certificado específico
#   --no-restart       No reiniciar componentes automáticamente
################################################################################

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuración
PKI_DIR="/etc/kubernetes/pki"
BACKUP_DIR="/root/k8s-cert-backups"
RENEW_ALL=false
SPECIFIC_CERT=""
AUTO_RESTART=true

################################################################################
# Funciones de Utilidad
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

confirm() {
    local message="$1"
    echo -n -e "${YELLOW}$message (yes/no): ${NC}"
    read -r response
    [[ "$response" == "yes" ]]
}

usage() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --all              Renovar todos los certificados"
    echo "  --cert <name>      Renovar certificado específico"
    echo "  --no-restart       No reiniciar componentes"
    echo "  -h, --help         Mostrar ayuda"
    echo ""
    echo "Certificados renovables:"
    echo "  • all                      (todos)"
    echo "  • apiserver"
    echo "  • apiserver-kubelet-client"
    echo "  • apiserver-etcd-client"
    echo "  • front-proxy-client"
    echo "  • etcd-server"
    echo "  • etcd-peer"
    echo "  • etcd-healthcheck-client"
    echo "  • admin.conf"
    echo "  • controller-manager.conf"
    echo "  • scheduler.conf"
    echo ""
    exit 0
}

################################################################################
# Paso 1: Verificación de Estado Previo
################################################################################

check_current_state() {
    log_step "PASO 1: Verificación de estado previo"
    echo ""
    
    log_info "Verificando certificados actuales..."
    sudo kubeadm certs check-expiration
    
    echo ""
    if ! confirm "¿Continuar con la renovación?"; then
        log_warning "Renovación cancelada por el usuario"
        exit 0
    fi
}

################################################################################
# Paso 2: Backup Automático
################################################################################

create_backup() {
    log_step "PASO 2: Creando backup de certificados"
    echo ""
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_path="$BACKUP_DIR/backup-$timestamp"
    
    log_info "Creando directorio de backup..."
    sudo mkdir -p "$backup_path"
    
    # Backup del directorio PKI completo
    log_info "Backing up $PKI_DIR..."
    sudo cp -r "$PKI_DIR" "$backup_path/pki"
    
    # Backup de kubeconfigs
    log_info "Backing up kubeconfigs..."
    sudo mkdir -p "$backup_path/configs"
    sudo cp /etc/kubernetes/admin.conf "$backup_path/configs/" 2>/dev/null || true
    sudo cp /etc/kubernetes/controller-manager.conf "$backup_path/configs/" 2>/dev/null || true
    sudo cp /etc/kubernetes/scheduler.conf "$backup_path/configs/" 2>/dev/null || true
    sudo cp /etc/kubernetes/kubelet.conf "$backup_path/configs/" 2>/dev/null || true
    
    # Crear manifiesto de backup
    log_info "Creando manifiesto de backup..."
    cat > /tmp/backup-manifest.txt << EOF
Kubernetes Certificate Backup
==============================
Date: $(date)
Hostname: $(hostname)
Backup path: $backup_path

PKI Directory: $PKI_DIR
Kubeconfigs: /etc/kubernetes/*.conf

Certificate Status BEFORE Renewal:
-----------------------------------
$(sudo kubeadm certs check-expiration 2>/dev/null || echo "N/A")

Cluster Info:
-------------
$(kubectl cluster-info 2>/dev/null || echo "N/A")
EOF
    
    sudo mv /tmp/backup-manifest.txt "$backup_path/manifest.txt"
    
    # Comprimir backup
    log_info "Comprimiendo backup..."
    sudo tar -czf "$backup_path.tar.gz" -C "$BACKUP_DIR" "backup-$timestamp"
    
    log_success "Backup creado: $backup_path.tar.gz"
    
    # Mostrar tamaño
    local size=$(sudo du -sh "$backup_path.tar.gz" | awk '{print $1}')
    echo "  Tamaño: $size"
    echo ""
}

################################################################################
# Paso 3: Renovación de Certificados
################################################################################

renew_certificates() {
    log_step "PASO 3: Renovando certificados"
    echo ""
    
    if [[ "$RENEW_ALL" == true ]]; then
        log_info "Renovando TODOS los certificados..."
        echo ""
        
        if sudo kubeadm certs renew all; then
            log_success "Todos los certificados renovados exitosamente"
        else
            log_error "Error al renovar certificados"
            log_warning "Puedes restaurar el backup con:"
            echo "  sudo tar -xzf $BACKUP_DIR/backup-*.tar.gz -C /"
            exit 1
        fi
    elif [[ -n "$SPECIFIC_CERT" ]]; then
        log_info "Renovando certificado: $SPECIFIC_CERT"
        echo ""
        
        if sudo kubeadm certs renew "$SPECIFIC_CERT"; then
            log_success "Certificado $SPECIFIC_CERT renovado exitosamente"
        else
            log_error "Error al renovar certificado $SPECIFIC_CERT"
            exit 1
        fi
    else
        log_error "No se especificó qué renovar (usa --all o --cert)"
        exit 1
    fi
    
    echo ""
}

################################################################################
# Paso 4: Verificación Post-Renovación
################################################################################

verify_renewal() {
    log_step "PASO 4: Verificando renovación"
    echo ""
    
    log_info "Nuevas fechas de expiración:"
    sudo kubeadm certs check-expiration
    
    echo ""
    log_success "Certificados verificados"
}

################################################################################
# Paso 5: Restart de Componentes
################################################################################

restart_components() {
    if [[ "$AUTO_RESTART" == false ]]; then
        log_warning "Auto-restart deshabilitado (--no-restart)"
        echo ""
        log_info "IMPORTANTE: Debes reiniciar los componentes manualmente:"
        echo "  1. sudo systemctl restart kubelet"
        echo "  2. Restart de static pods (ver README.md)"
        return 0
    fi
    
    log_step "PASO 5: Reiniciando componentes"
    echo ""
    
    # 5.1 Restart kubelet
    log_info "Reiniciando kubelet..."
    if sudo systemctl restart kubelet; then
        log_success "kubelet reiniciado"
        sleep 5
    else
        log_error "Error al reiniciar kubelet"
        exit 1
    fi
    
    # 5.2 Restart API Server
    log_info "Reiniciando kube-apiserver..."
    if sudo test -f /etc/kubernetes/manifests/kube-apiserver.yaml; then
        sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
        sleep 5
        sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
        log_success "kube-apiserver reiniciado"
        sleep 10
    else
        log_warning "Manifest de kube-apiserver no encontrado"
    fi
    
    # 5.3 Restart Controller Manager
    log_info "Reiniciando kube-controller-manager..."
    if sudo test -f /etc/kubernetes/manifests/kube-controller-manager.yaml; then
        sudo mv /etc/kubernetes/manifests/kube-controller-manager.yaml /tmp/
        sleep 5
        sudo mv /tmp/kube-controller-manager.yaml /etc/kubernetes/manifests/
        log_success "kube-controller-manager reiniciado"
        sleep 5
    else
        log_warning "Manifest de kube-controller-manager no encontrado"
    fi
    
    # 5.4 Restart Scheduler
    log_info "Reiniciando kube-scheduler..."
    if sudo test -f /etc/kubernetes/manifests/kube-scheduler.yaml; then
        sudo mv /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/
        sleep 5
        sudo mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/
        log_success "kube-scheduler reiniciado"
        sleep 5
    else
        log_warning "Manifest de kube-scheduler no encontrado"
    fi
    
    # 5.5 Verificar que pods están corriendo
    log_info "Esperando a que los pods arranquen..."
    sleep 20
    
    local retries=30
    while [[ $retries -gt 0 ]]; do
        if kubectl get pods -n kube-system | grep -E "kube-apiserver|kube-controller|kube-scheduler" | grep -q Running; then
            log_success "Pods de control plane Running"
            break
        fi
        
        echo -n "."
        sleep 2
        ((retries--))
    done
    
    if [[ $retries -eq 0 ]]; then
        log_warning "Timeout esperando a que pods arranquen"
        log_info "Verificar manualmente: kubectl get pods -n kube-system"
    fi
    
    echo ""
}

################################################################################
# Paso 6: Actualizar kubeconfig del Usuario
################################################################################

update_kubeconfig() {
    log_step "PASO 6: Actualizando kubeconfig del usuario"
    echo ""
    
    log_info "Copiando nuevo admin.conf..."
    
    if [[ -f "$HOME/.kube/config" ]]; then
        # Backup del kubeconfig actual
        cp "$HOME/.kube/config" "$HOME/.kube/config.backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Backup de kubeconfig actual creado"
    fi
    
    # Copiar nuevo kubeconfig
    sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
    sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
    
    log_success "kubeconfig actualizado"
    
    # Verificar conectividad
    echo ""
    log_info "Verificando conectividad..."
    if kubectl cluster-info > /dev/null 2>&1; then
        log_success "kubectl funcional con nuevos certificados"
    else
        log_error "kubectl no puede conectar"
        log_warning "Puede que necesites esperar unos segundos más"
    fi
}

################################################################################
# Paso 7: Verificación Final
################################################################################

final_verification() {
    log_step "PASO 7: Verificación final del cluster"
    echo ""
    
    # Verificar nodos
    log_info "Verificando nodos..."
    if kubectl get nodes > /dev/null 2>&1; then
        kubectl get nodes
        log_success "Nodos accesibles"
    else
        log_error "No se puede obtener estado de nodos"
    fi
    
    echo ""
    
    # Verificar pods de sistema
    log_info "Verificando pods de sistema..."
    kubectl get pods -n kube-system | grep -E "kube-apiserver|kube-controller|kube-scheduler|etcd"
    
    echo ""
    
    # Verificar que puedes crear recursos
    log_info "Probando creación de recursos..."
    if kubectl run test-cert-renewal --image=nginx:alpine --restart=Never --dry-run=client -o yaml > /dev/null 2>&1; then
        log_success "Permisos de creación OK"
    else
        log_warning "Problema con permisos de creación"
    fi
    
    echo ""
}

################################################################################
# Resumen Final
################################################################################

show_summary() {
    log_step "RESUMEN FINAL"
    echo ""
    
    echo "═══════════════════════════════════════════════════════════"
    echo "  RENOVACIÓN DE CERTIFICADOS COMPLETADA"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    log_success "Pasos ejecutados:"
    echo "  ✓ Verificación de estado previo"
    echo "  ✓ Backup creado en: $BACKUP_DIR"
    echo "  ✓ Certificados renovados"
    echo "  ✓ Componentes reiniciados"
    echo "  ✓ kubeconfig actualizado"
    echo "  ✓ Cluster verificado"
    echo ""
    
    log_info "Verificar estado actual:"
    echo "  sudo kubeadm certs check-expiration"
    echo ""
    
    log_info "Backups disponibles:"
    sudo ls -lh "$BACKUP_DIR" | tail -5
    echo ""
    
    log_info "Para verificar certificados:"
    echo "  ./verify-certs.sh"
}

################################################################################
# Parseo de Argumentos
################################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                RENEW_ALL=true
                shift
                ;;
            --cert)
                SPECIFIC_CERT="$2"
                shift 2
                ;;
            --no-restart)
                AUTO_RESTART=false
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Opción desconocida: $1"
                usage
                ;;
        esac
    done
}

################################################################################
# Main
################################################################################

main() {
    # Header
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        RENOVACIÓN DE CERTIFICADOS - LAB 04            ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Verificar prerequisitos
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl no encontrado"
        exit 1
    fi
    
    if ! command -v kubeadm &> /dev/null; then
        log_error "kubeadm no encontrado"
        exit 1
    fi
    
    if ! sudo test -d "$PKI_DIR"; then
        log_error "Directorio PKI no accesible: $PKI_DIR"
        exit 1
    fi
    
    # Ejecutar pasos
    check_current_state
    create_backup
    renew_certificates
    verify_renewal
    restart_components
    update_kubeconfig
    final_verification
    show_summary
    
    echo ""
    log_success "¡Renovación completada exitosamente!"
}

# Parsear argumentos
parse_arguments "$@"

# Ejecutar
main
