#!/bin/bash

################################################################################
# Cleanup Script - Lab 02: Cluster Upgrade
# 
# Este script limpia los recursos creados durante el laboratorio de upgrade
# y opcionalmente realiza rollback a la versión anterior.
#
# ADVERTENCIA: Ejecutar solo después de verificar que el upgrade fue exitoso
#              o si necesitas hacer rollback a la versión anterior.
#
# Uso:
#   ./cleanup.sh            # Limpieza normal (mantiene upgrade)
#   ./cleanup.sh --rollback # Rollback completo a v1.27
################################################################################

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuración
UPGRADE_LOG_DIR="/var/log/k8s-upgrade"
BACKUP_DIR="/var/lib/etcd-backup"
MANIFEST_BACKUP_DIR="/root/k8s-manifests-backup"
ROLLBACK_MODE=false

# Detectar modo rollback
if [[ "${1:-}" == "--rollback" ]]; then
    ROLLBACK_MODE=true
fi

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

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" response
    response=${response:-$default}
    
    [[ "$response" =~ ^[Yy]$ ]]
}

check_cluster_health() {
    log_info "Verificando salud del cluster..."
    
    if ! kubectl cluster-info > /dev/null 2>&1; then
        log_error "No se puede conectar al cluster"
        return 1
    fi
    
    # Verificar nodos
    local not_ready=$(kubectl get nodes --no-headers | grep -c NotReady || true)
    if [[ $not_ready -gt 0 ]]; then
        log_warning "$not_ready nodo(s) en estado NotReady"
        kubectl get nodes
        return 1
    fi
    
    log_success "Cluster está saludable"
    return 0
}

################################################################################
# Paso 1: Verificar Estado del Upgrade
################################################################################

step_verify_upgrade() {
    echo ""
    echo "=========================================="
    echo "  PASO 1: Verificar Estado del Upgrade"
    echo "=========================================="
    echo ""
    
    log_info "Verificando versiones de los nodos..."
    kubectl get nodes -o wide
    
    echo ""
    log_info "Versiones detectadas:"
    kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'
    
    echo ""
    if $ROLLBACK_MODE; then
        log_warning "Modo ROLLBACK activado - se revertirá a v1.27.x"
    else
        log_info "Modo CLEANUP normal - se mantendrá v1.28.x"
    fi
}

################################################################################
# Paso 2: Backup Final (si es rollback)
################################################################################

step_final_backup() {
    if ! $ROLLBACK_MODE; then
        log_info "Saltando backup final (no es rollback)"
        return 0
    fi
    
    echo ""
    echo "=========================================="
    echo "  PASO 2: Backup Final Antes de Rollback"
    echo "=========================================="
    echo ""
    
    log_info "Creando backup de etcd antes de rollback..."
    
    local snapshot_file="${BACKUP_DIR}/snapshot-pre-rollback-$(date +%Y%m%d-%H%M%S).db"
    
    if sudo ETCDCTL_API=3 etcdctl snapshot save "$snapshot_file" \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        --endpoints=https://127.0.0.1:2379; then
        
        log_success "Backup creado: $snapshot_file"
        sudo etcdctl snapshot status "$snapshot_file" --write-out=table
    else
        log_error "Fallo al crear backup - abortando rollback"
        exit 1
    fi
}

################################################################################
# Paso 3: Rollback de Paquetes (si aplica)
################################################################################

step_rollback_packages() {
    if ! $ROLLBACK_MODE; then
        log_info "Saltando rollback de paquetes"
        return 0
    fi
    
    echo ""
    echo "=========================================="
    echo "  PASO 3: Rollback de Paquetes Kubernetes"
    echo "=========================================="
    echo ""
    
    log_warning "Este paso downgradeará kubeadm, kubelet y kubectl a v1.27.0"
    
    if ! confirm "¿Continuar con el rollback de paquetes?" "n"; then
        log_info "Rollback cancelado por el usuario"
        exit 0
    fi
    
    local TARGET_VERSION="1.27.0-00"
    
    # Control Plane
    log_info "Rollback en control plane..."
    
    sudo apt-mark unhold kubeadm kubelet kubectl
    sudo apt-get update
    
    if sudo apt-get install -y --allow-downgrades \
        kubeadm=$TARGET_VERSION \
        kubelet=$TARGET_VERSION \
        kubectl=$TARGET_VERSION; then
        
        log_success "Paquetes downgradeados a $TARGET_VERSION"
    else
        log_error "Fallo al downgradear paquetes"
        exit 1
    fi
    
    sudo apt-mark hold kubeadm kubelet kubectl
    
    # Reiniciar kubelet
    log_info "Reiniciando kubelet..."
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
    sleep 10
    
    if sudo systemctl is-active --quiet kubelet; then
        log_success "kubelet reiniciado correctamente"
    else
        log_error "kubelet no está corriendo"
        sudo journalctl -xeu kubelet | tail -20
        exit 1
    fi
    
    # TODO: Workers
    log_warning "MANUAL: Debes repetir el rollback en cada worker node:"
    echo ""
    echo "  ssh worker-node"
    echo "  sudo apt-mark unhold kubeadm kubelet kubectl"
    echo "  sudo apt-get install -y --allow-downgrades kubeadm=1.27.0-00 kubelet=1.27.0-00 kubectl=1.27.0-00"
    echo "  sudo apt-mark hold kubeadm kubelet kubectl"
    echo "  sudo systemctl daemon-reload && sudo systemctl restart kubelet"
    echo ""
}

################################################################################
# Paso 4: Restaurar etcd (si es rollback)
################################################################################

step_restore_etcd() {
    if ! $ROLLBACK_MODE; then
        log_info "Saltando restauración de etcd"
        return 0
    fi
    
    echo ""
    echo "=========================================="
    echo "  PASO 4: Restaurar etcd desde Backup"
    echo "=========================================="
    echo ""
    
    # Buscar backup pre-upgrade
    local pre_upgrade_backup=$(ls -t ${BACKUP_DIR}/snapshot-pre-upgrade-*.db 2>/dev/null | head -1)
    
    if [[ -z "$pre_upgrade_backup" ]]; then
        log_error "No se encontró backup pre-upgrade"
        log_info "Backups disponibles:"
        ls -lh ${BACKUP_DIR}/ || true
        exit 1
    fi
    
    log_info "Backup a restaurar: $pre_upgrade_backup"
    sudo etcdctl snapshot status "$pre_upgrade_backup" --write-out=table
    
    echo ""
    log_warning "⚠️  ADVERTENCIA CRÍTICA ⚠️"
    log_warning "Esto restaurará el cluster al estado ANTES del upgrade"
    log_warning "Se perderán TODOS los cambios posteriores al backup"
    echo ""
    
    if ! confirm "¿Estás SEGURO de restaurar etcd?" "n"; then
        log_info "Restauración cancelada"
        exit 0
    fi
    
    log_info "Usando script de restore del Lab 01..."
    
    if [[ -f "../lab-01-etcd-backup-restore/restore-etcd.sh" ]]; then
        sudo ../lab-01-etcd-backup-restore/restore-etcd.sh "$pre_upgrade_backup"
    else
        log_error "Script restore-etcd.sh no encontrado"
        log_info "Restore manual requerido - ver Lab 01"
        exit 1
    fi
}

################################################################################
# Paso 5: Limpiar Deployment de Prueba
################################################################################

step_cleanup_test_deployments() {
    echo ""
    echo "=========================================="
    echo "  PASO 5: Limpiar Deployments de Prueba"
    echo "=========================================="
    echo ""
    
    log_info "Buscando deployments de prueba creados durante el lab..."
    
    # Buscar deployments comunes de testing
    local test_deployments=$(kubectl get deployments -A --no-headers | grep -E 'nginx-test|test-upgrade|upgrade-demo' | awk '{print $1 "/" $2}' || true)
    
    if [[ -z "$test_deployments" ]]; then
        log_info "No se encontraron deployments de prueba"
        return 0
    fi
    
    echo "Deployments encontrados:"
    echo "$test_deployments"
    echo ""
    
    if confirm "¿Eliminar estos deployments?" "y"; then
        while IFS= read -r dep; do
            local namespace=$(echo $dep | cut -d'/' -f1)
            local name=$(echo $dep | cut -d'/' -f2)
            
            log_info "Eliminando $namespace/$name..."
            kubectl delete deployment "$name" -n "$namespace" --wait=true
        done <<< "$test_deployments"
        
        log_success "Deployments de prueba eliminados"
    else
        log_info "Manteniendo deployments de prueba"
    fi
}

################################################################################
# Paso 6: Limpiar Logs de Upgrade
################################################################################

step_cleanup_logs() {
    echo ""
    echo "=========================================="
    echo "  PASO 6: Limpiar Logs de Upgrade"
    echo "=========================================="
    echo ""
    
    if [[ -d "$UPGRADE_LOG_DIR" ]]; then
        log_info "Logs encontrados en: $UPGRADE_LOG_DIR"
        sudo ls -lh "$UPGRADE_LOG_DIR/" 2>/dev/null || true
        
        echo ""
        if confirm "¿Eliminar logs de upgrade?" "n"; then
            sudo rm -rf "$UPGRADE_LOG_DIR"/*
            log_success "Logs eliminados"
        else
            log_info "Manteniendo logs en: $UPGRADE_LOG_DIR"
        fi
    else
        log_info "No se encontraron logs de upgrade"
    fi
}

################################################################################
# Paso 7: Gestionar Backups de etcd
################################################################################

step_manage_backups() {
    echo ""
    echo "=========================================="
    echo "  PASO 7: Gestión de Backups de etcd"
    echo "=========================================="
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_info "No se encontró directorio de backups"
        return 0
    fi
    
    log_info "Backups existentes:"
    sudo ls -lh "$BACKUP_DIR"/ 2>/dev/null || true
    
    local total_size=$(sudo du -sh "$BACKUP_DIR" | awk '{print $1}')
    log_info "Espacio total usado: $total_size"
    
    echo ""
    log_info "Recomendaciones:"
    echo "  - Mantener backup pre-upgrade por al menos 7 días"
    echo "  - Backups post-upgrade pueden eliminarse si el sistema es estable"
    echo "  - Considerar mover backups antiguos a almacenamiento externo"
    
    echo ""
    if confirm "¿Eliminar backups antiguos (>7 días)?" "n"; then
        log_info "Eliminando backups >7 días..."
        sudo find "$BACKUP_DIR" -name "snapshot-*.db" -mtime +7 -delete
        log_success "Backups antiguos eliminados"
    else
        log_info "Manteniendo todos los backups"
    fi
}

################################################################################
# Paso 8: Limpiar Backups de Manifests
################################################################################

step_cleanup_manifest_backups() {
    echo ""
    echo "=========================================="
    echo "  PASO 8: Backups de Manifests"
    echo "=========================================="
    echo ""
    
    if [[ ! -d "$MANIFEST_BACKUP_DIR" ]]; then
        log_info "No se encontraron backups de manifests"
        return 0
    fi
    
    log_info "Backups de manifests encontrados:"
    sudo ls -lh "$MANIFEST_BACKUP_DIR"/ 2>/dev/null || true
    
    echo ""
    if $ROLLBACK_MODE; then
        log_info "Modo rollback - manteniendo backups de manifests"
    else
        if confirm "¿Eliminar backups de manifests (upgrade exitoso)?" "n"; then
            sudo rm -rf "$MANIFEST_BACKUP_DIR"/*
            log_success "Backups de manifests eliminados"
        else
            log_info "Manteniendo backups de manifests"
        fi
    fi
}

################################################################################
# Paso 9: Verificar Cluster Post-Cleanup
################################################################################

step_final_verification() {
    echo ""
    echo "=========================================="
    echo "  PASO 9: Verificación Final del Cluster"
    echo "=========================================="
    echo ""
    
    log_info "Verificando salud del cluster..."
    
    # Verificar nodos
    log_info "Estado de nodos:"
    kubectl get nodes -o wide
    
    # Verificar pods del sistema
    echo ""
    log_info "Pods del sistema:"
    kubectl get pods -n kube-system
    
    # Verificar que no hay pods failing
    echo ""
    local failing_pods=$(kubectl get pods -A --no-headers | grep -vE 'Running|Completed|Succeeded' | wc -l)
    
    if [[ $failing_pods -eq 0 ]]; then
        log_success "Todos los pods están en estado correcto"
    else
        log_warning "$failing_pods pod(s) en estado no deseado:"
        kubectl get pods -A | grep -vE 'Running|Completed|Succeeded'
    fi
    
    # Health check
    echo ""
    if check_cluster_health; then
        log_success "Cluster está operacional"
    else
        log_warning "Se detectaron problemas en el cluster"
    fi
}

################################################################################
# Paso 10: Generar Reporte de Cleanup
################################################################################

step_generate_report() {
    echo ""
    echo "=========================================="
    echo "  PASO 10: Generar Reporte de Cleanup"
    echo "=========================================="
    echo ""
    
    local report_file="/tmp/upgrade-cleanup-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "=========================================="
        echo "  REPORTE DE CLEANUP - LAB 02"
        echo "=========================================="
        echo ""
        echo "Fecha: $(date)"
        echo "Usuario: $(whoami)"
        echo "Hostname: $(hostname)"
        echo "Modo: $(if $ROLLBACK_MODE; then echo 'ROLLBACK'; else echo 'CLEANUP NORMAL'; fi)"
        echo ""
        
        echo "--- VERSIONES ACTUALES ---"
        kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'
        echo ""
        
        echo "--- COMPONENTES DEL SISTEMA ---"
        kubectl get pods -n kube-system --no-headers | awk '{print $1 "\t" $3}'
        echo ""
        
        echo "--- ESPACIO EN DISCO ---"
        df -h | grep -E 'Filesystem|/var/lib'
        echo ""
        
        echo "--- BACKUPS RESTANTES ---"
        sudo ls -lh "$BACKUP_DIR/" 2>/dev/null || echo "No backups"
        echo ""
        
        echo "--- RECOMENDACIONES ---"
        if $ROLLBACK_MODE; then
            echo "✓ Rollback completado a v1.27.x"
            echo "✓ Verificar que todas las aplicaciones funcionan"
            echo "✓ Revisar logs de kubelet en todos los nodos"
            echo "⚠ Investigar causa del fallo del upgrade"
        else
            echo "✓ Cleanup completado - cluster en v1.28.x"
            echo "✓ Monitorear cluster por 24-48 horas"
            echo "✓ Mantener backups por al menos 7 días"
            echo "✓ Documentar lessons learned del upgrade"
        fi
        
    } > "$report_file"
    
    cat "$report_file"
    
    echo ""
    log_success "Reporte guardado en: $report_file"
}

################################################################################
# Main
################################################################################

main() {
    clear
    
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        CLEANUP - LAB 02: CLUSTER UPGRADE              ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    if $ROLLBACK_MODE; then
        log_warning "⚠️  MODO ROLLBACK ACTIVADO ⚠️"
        log_warning "Se revertirá el cluster a v1.27.x"
        echo ""
        if ! confirm "¿Estás seguro de continuar con el ROLLBACK?" "n"; then
            log_info "Rollback cancelado"
            exit 0
        fi
    else
        log_info "Modo cleanup normal (mantiene v1.28.x)"
    fi
    
    echo ""
    log_info "Iniciando proceso de cleanup..."
    sleep 2
    
    # Ejecutar pasos
    step_verify_upgrade
    step_final_backup
    step_rollback_packages
    step_restore_etcd
    step_cleanup_test_deployments
    step_cleanup_logs
    step_manage_backups
    step_cleanup_manifest_backups
    step_final_verification
    step_generate_report
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║              CLEANUP COMPLETADO                        ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    if $ROLLBACK_MODE; then
        log_success "Rollback completado exitosamente"
        log_warning "Verifica que todas las aplicaciones funcionan correctamente"
    else
        log_success "Cleanup completado - cluster en v1.28.x"
        log_info "Próximo laboratorio: Lab 03 - Node Drain & Cordon"
    fi
}

# Verificar que se ejecuta como root o con sudo
if [[ $EUID -eq 0 ]]; then
    log_warning "Ejecutando como root"
elif ! sudo -n true 2>/dev/null; then
    log_error "Este script requiere permisos sudo"
    exit 1
fi

# Ejecutar
main "$@"
