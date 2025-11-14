#!/bin/bash

################################################################################
# Cleanup Script - Lab 04 Certificate Management
# 
# Este script limpia recursos creados durante el lab y opcionalmente
# restaura certificados desde backup.
#
# Uso:
#   ./cleanup.sh [--restore-backup <path>]
#
# Opciones:
#   --restore-backup <path>    Restaurar certificados desde backup específico
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
BACKUP_DIR="/root/k8s-cert-backups"
RESTORE_PATH=""
DO_RESTORE=false

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
    echo "  --restore-backup <path>    Restaurar desde backup específico"
    echo "  -h, --help                 Mostrar ayuda"
    echo ""
    echo "Ejemplo:"
    echo "  $0"
    echo "  $0 --restore-backup /root/k8s-cert-backups/backup-20251113.tar.gz"
    exit 0
}

################################################################################
# Paso 1: Verificar Estado Actual
################################################################################

check_current_state() {
    log_step "PASO 1: Verificación de estado actual"
    echo ""
    
    log_info "Cluster actual:"
    kubectl cluster-info 2>/dev/null || log_warning "No se puede conectar al cluster"
    
    echo ""
    log_info "Certificados actuales:"
    sudo kubeadm certs check-expiration 2>/dev/null || log_warning "No se puede verificar certificados"
    
    echo ""
}

################################################################################
# Paso 2: Limpiar Pods de Prueba
################################################################################

cleanup_test_pods() {
    log_step "PASO 2: Limpiando pods de prueba"
    echo ""
    
    log_info "Buscando pods de prueba..."
    
    local test_pods=$(kubectl get pods --all-namespaces --no-headers | grep -E "test-cert|test-renewal|test-verification" | awk '{print $1"/"$2}' || true)
    
    if [[ -z "$test_pods" ]]; then
        log_info "No hay pods de prueba para limpiar"
    else
        log_info "Pods de prueba encontrados:"
        echo "$test_pods"
        echo ""
        
        if confirm "¿Eliminar estos pods?"; then
            echo "$test_pods" | while IFS=/ read -r ns pod; do
                kubectl delete pod "$pod" -n "$ns" || log_warning "No se pudo eliminar $ns/$pod"
            done
            log_success "Pods de prueba eliminados"
        else
            log_info "Pods de prueba NO eliminados"
        fi
    fi
}

################################################################################
# Paso 3: Listar Backups Disponibles
################################################################################

list_backups() {
    log_step "PASO 3: Backups disponibles"
    echo ""
    
    if sudo test -d "$BACKUP_DIR"; then
        log_info "Backups en $BACKUP_DIR:"
        echo ""
        sudo ls -lh "$BACKUP_DIR" || log_warning "No se puede listar backups"
        echo ""
        
        local count=$(sudo ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l || echo 0)
        log_info "Total de backups: $count"
    else
        log_info "No existe directorio de backups: $BACKUP_DIR"
    fi
}

################################################################################
# Paso 4: Restaurar Backup (Opcional)
################################################################################

restore_backup() {
    if [[ "$DO_RESTORE" == false ]]; then
        log_info "No se solicitó restauración de backup"
        return 0
    fi
    
    log_step "PASO 4: Restaurando certificados desde backup"
    echo ""
    
    # Verificar que existe el backup
    if ! sudo test -f "$RESTORE_PATH"; then
        log_error "Backup no encontrado: $RESTORE_PATH"
        exit 1
    fi
    
    log_warning "⚠️  ADVERTENCIA: Restaurar certificados puede romper el cluster"
    log_warning "⚠️  Solo hazlo si estás seguro de lo que haces"
    echo ""
    
    if ! confirm "¿REALMENTE quieres restaurar certificados desde backup?"; then
        log_info "Restauración cancelada"
        return 0
    fi
    
    # Backup de estado actual antes de restaurar
    log_info "Creando backup del estado actual antes de restaurar..."
    local safety_backup="/root/pki-before-restore-$(date +%Y%m%d-%H%M%S)"
    sudo cp -r /etc/kubernetes/pki "$safety_backup"
    log_success "Safety backup creado: $safety_backup"
    
    # Extraer backup
    log_info "Extrayendo backup..."
    local temp_dir=$(mktemp -d)
    sudo tar -xzf "$RESTORE_PATH" -C "$temp_dir"
    
    # Buscar directorio pki en el backup
    local pki_backup=$(sudo find "$temp_dir" -type d -name "pki" | head -1)
    
    if [[ -z "$pki_backup" ]]; then
        log_error "No se encontró directorio pki en el backup"
        sudo rm -rf "$temp_dir"
        exit 1
    fi
    
    # Restaurar PKI
    log_info "Restaurando /etc/kubernetes/pki..."
    sudo rm -rf /etc/kubernetes/pki
    sudo cp -r "$pki_backup" /etc/kubernetes/pki
    
    # Buscar y restaurar kubeconfigs si existen
    local configs_backup=$(sudo find "$temp_dir" -type d -name "configs" | head -1)
    
    if [[ -n "$configs_backup" ]]; then
        log_info "Restaurando kubeconfigs..."
        sudo cp "$configs_backup"/*.conf /etc/kubernetes/ 2>/dev/null || log_warning "Algunos kubeconfigs no se pudieron restaurar"
    fi
    
    # Limpiar temp
    sudo rm -rf "$temp_dir"
    
    log_success "Certificados restaurados desde backup"
    
    # Reiniciar componentes
    log_warning "Es necesario reiniciar componentes del cluster"
    
    if confirm "¿Reiniciar kubelet y control plane ahora?"; then
        log_info "Reiniciando kubelet..."
        sudo systemctl restart kubelet
        sleep 5
        
        log_info "Reiniciando static pods..."
        for manifest in /etc/kubernetes/manifests/*.yaml; do
            local name=$(basename "$manifest")
            sudo mv "$manifest" /tmp/
            sleep 3
            sudo mv "/tmp/$name" "$manifest"
            sleep 2
        done
        
        log_success "Componentes reiniciados"
        
        # Actualizar kubeconfig del usuario
        log_info "Actualizando kubeconfig del usuario..."
        sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
        sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
        
        log_info "Esperando a que cluster esté listo..."
        sleep 20
        
        if kubectl cluster-info > /dev/null 2>&1; then
            log_success "Cluster operacional después de restaurar"
        else
            log_error "Cluster no responde después de restaurar"
            log_warning "Revisa logs: sudo journalctl -u kubelet -n 100"
        fi
    else
        log_warning "Reinicio manual requerido:"
        echo "  sudo systemctl restart kubelet"
        echo "  # Restart static pods moviendo manifiestos"
    fi
}

################################################################################
# Paso 5: Limpiar Backups Antiguos (Opcional)
################################################################################

cleanup_old_backups() {
    log_step "PASO 5: Limpieza de backups antiguos"
    echo ""
    
    if ! sudo test -d "$BACKUP_DIR"; then
        log_info "No existe directorio de backups"
        return 0
    fi
    
    local backup_count=$(sudo ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l || echo 0)
    
    if [[ $backup_count -eq 0 ]]; then
        log_info "No hay backups para limpiar"
        return 0
    fi
    
    log_info "Backups actuales: $backup_count"
    
    if [[ $backup_count -gt 5 ]]; then
        log_warning "Más de 5 backups detectados"
        
        if confirm "¿Eliminar backups con más de 30 días?"; then
            log_info "Eliminando backups antiguos..."
            sudo find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +30 -delete
            
            local remaining=$(sudo ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l || echo 0)
            log_success "Backups antiguos eliminados. Restantes: $remaining"
        else
            log_info "Backups NO eliminados"
        fi
    else
        log_info "Cantidad de backups OK (≤5)"
    fi
}

################################################################################
# Paso 6: Limpiar Scripts Temporales
################################################################################

cleanup_temp_files() {
    log_step "PASO 6: Limpiando archivos temporales"
    echo ""
    
    log_info "Limpiando archivos temporales del lab..."
    
    # Limpiar archivos en /tmp relacionados con el lab
    sudo find /tmp -name "*cert*" -type f -mtime +1 -delete 2>/dev/null || true
    sudo find /tmp -name "*kubeadm*" -type f -mtime +1 -delete 2>/dev/null || true
    
    log_success "Archivos temporales limpiados"
}

################################################################################
# Paso 7: Verificación Final
################################################################################

final_verification() {
    log_step "PASO 7: Verificación final"
    echo ""
    
    log_info "Estado del cluster:"
    
    if kubectl cluster-info > /dev/null 2>&1; then
        log_success "Cluster accesible"
        kubectl get nodes
    else
        log_error "Cluster no accesible"
        log_warning "Puede requerir troubleshooting"
    fi
    
    echo ""
    
    log_info "Estado de certificados:"
    sudo kubeadm certs check-expiration 2>/dev/null || log_warning "No se pudo verificar certificados"
}

################################################################################
# Resumen Final
################################################################################

show_summary() {
    log_step "RESUMEN DE LIMPIEZA"
    echo ""
    
    echo "═══════════════════════════════════════════════════════════"
    echo "  LIMPIEZA COMPLETADA"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    log_success "Pasos ejecutados:"
    echo "  ✓ Verificación de estado actual"
    echo "  ✓ Limpieza de pods de prueba"
    echo "  ✓ Listado de backups"
    
    if [[ "$DO_RESTORE" == true ]]; then
        echo "  ✓ Restauración desde backup"
    fi
    
    echo "  ✓ Limpieza de backups antiguos"
    echo "  ✓ Limpieza de archivos temporales"
    echo "  ✓ Verificación final"
    echo ""
    
    if sudo test -d "$BACKUP_DIR"; then
        log_info "Backups conservados en: $BACKUP_DIR"
        sudo ls -lh "$BACKUP_DIR" | tail -3
    fi
    
    echo ""
    log_info "Para verificar certificados:"
    echo "  ./check-certs.sh"
    echo ""
    log_info "Para verificar cluster completo:"
    echo "  ./verify-certs.sh"
}

################################################################################
# Parseo de Argumentos
################################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --restore-backup)
                DO_RESTORE=true
                RESTORE_PATH="$2"
                shift 2
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
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        CLEANUP - LAB 04 CERTIFICATE MANAGEMENT        ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Verificar prerequisitos básicos
    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl no encontrado (algunas operaciones limitadas)"
    fi
    
    # Ejecutar pasos
    check_current_state
    cleanup_test_pods
    list_backups
    restore_backup
    cleanup_old_backups
    cleanup_temp_files
    final_verification
    show_summary
    
    echo ""
    log_success "¡Limpieza completada!"
}

# Parsear argumentos
parse_arguments "$@"

# Ejecutar
main
