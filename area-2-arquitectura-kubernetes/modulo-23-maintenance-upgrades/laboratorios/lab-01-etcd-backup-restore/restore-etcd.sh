#!/bin/bash
#
# restore-etcd.sh - Script de automatización de restore de etcd
#
# ⚠️  ADVERTENCIA: Este script causa DOWNTIME del cluster ⚠️
# Solo ejecutar en casos de desastre o testing controlado
#
# Uso: sudo ./restore-etcd.sh <path-to-snapshot.db>
#
# Autor: Kubernetes Course - Módulo 23
# Versión: 1.0
# Fecha: 2025-11-13

set -euo pipefail

# =============================================================================
# CONFIGURACIÓN
# =============================================================================

# Directorios
RESTORE_DIR="/var/lib/etcd-restored"
ORIGINAL_ETCD_DIR="/var/lib/etcd"
MANIFEST_DIR="/etc/kubernetes/manifests"
BACKUP_MANIFEST_DIR="/root"
LOG_FILE="/var/log/etcd-restore.log"

# Configuración de etcd
export ETCDCTL_API=3
ETCD_NAME="default"
ETCD_INITIAL_CLUSTER="default=https://127.0.0.1:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://127.0.0.1:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-restored-$(date +%s)"

# Timeouts
API_TIMEOUT=60
ETCD_TIMEOUT=90

# =============================================================================
# FUNCIONES
# =============================================================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

log_warning() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $*" | tee -a "$LOG_FILE"
}

confirm_action() {
    local message="$1"
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                   ⚠️  ADVERTENCIA ⚠️                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "$message"
    echo ""
    read -p "¿Estás SEGURO de continuar? (escribe 'YES' en mayúsculas): " -r
    echo ""
    
    if [ "$REPLY" != "YES" ]; then
        log "Operación cancelada por el usuario"
        exit 0
    fi
    
    log "Usuario confirmó la operación de restore"
}

check_prerequisites() {
    log "Verificando prerequisitos..."
    
    # Verificar ejecución como root
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script debe ejecutarse como root"
        exit 1
    fi
    
    # Verificar que se proporcionó archivo de backup
    if [ $# -eq 0 ]; then
        log_error "Uso: $0 <path-to-snapshot.db>"
        exit 1
    fi
    
    local snapshot_file="$1"
    
    # Verificar que el archivo existe
    if [ ! -f "$snapshot_file" ]; then
        log_error "Archivo de snapshot no encontrado: $snapshot_file"
        exit 1
    fi
    
    # Verificar integridad del snapshot
    log "Verificando integridad del snapshot..."
    if ! etcdctl snapshot status "$snapshot_file" --write-out=table 2>&1 | tee -a "$LOG_FILE"; then
        log_error "El snapshot está corrupto o es inválido"
        exit 1
    fi
    
    log "✅ Prerequisitos verificados"
    echo "$snapshot_file"  # Retornar path del snapshot
}

backup_current_manifest() {
    log "Creando backup del manifest actual de etcd..."
    
    local manifest_file="$MANIFEST_DIR/etcd.yaml"
    local backup_file="$BACKUP_MANIFEST_DIR/etcd-manifest-backup-$(date +%Y%m%d-%H%M%S).yaml"
    
    if [ -f "$manifest_file" ]; then
        cp "$manifest_file" "$backup_file"
        log "✅ Manifest backed up a: $backup_file"
        echo "$backup_file"
    else
        log_error "Manifest de etcd no encontrado: $manifest_file"
        exit 1
    fi
}

stop_control_plane() {
    log "Deteniendo componentes del control plane..."
    log "⚠️  Esto causará DOWNTIME del cluster"
    
    # Mover manifests fuera del directorio de kubelet
    mv "$MANIFEST_DIR"/kube-apiserver.yaml /tmp/ 2>/dev/null || log_warning "API Server manifest no encontrado"
    mv "$MANIFEST_DIR"/kube-controller-manager.yaml /tmp/ 2>/dev/null || log_warning "Controller Manager manifest no encontrado"
    mv "$MANIFEST_DIR"/kube-scheduler.yaml /tmp/ 2>/dev/null || log_warning "Scheduler manifest no encontrado"
    mv "$MANIFEST_DIR"/etcd.yaml /tmp/ 2>/dev/null || log_warning "etcd manifest no encontrado"
    
    log "Esperando a que los pods se detengan..."
    sleep 10
    
    # Verificar que API server está detenido
    if kubectl version --short &>/dev/null; then
        log_warning "API server todavía responde, esperando más tiempo..."
        sleep 10
    fi
    
    log "✅ Componentes del control plane detenidos"
}

restore_snapshot() {
    local snapshot_file="$1"
    
    log "Restaurando snapshot a: $RESTORE_DIR"
    
    # Eliminar directorio anterior si existe
    if [ -d "$RESTORE_DIR" ]; then
        log_warning "Directorio de restore existente, eliminando..."
        rm -rf "$RESTORE_DIR"
    fi
    
    # Ejecutar restore
    if etcdctl snapshot restore "$snapshot_file" \
        --data-dir="$RESTORE_DIR" \
        --name="$ETCD_NAME" \
        --initial-cluster="$ETCD_INITIAL_CLUSTER" \
        --initial-advertise-peer-urls="$ETCD_INITIAL_ADVERTISE_PEER_URLS" \
        --initial-cluster-token="$ETCD_INITIAL_CLUSTER_TOKEN" 2>&1 | tee -a "$LOG_FILE"; then
        
        log "✅ Snapshot restaurado exitosamente"
        
        # Verificar permisos
        chown -R root:root "$RESTORE_DIR"
        chmod -R 700 "$RESTORE_DIR"
        
        return 0
    else
        log_error "Falló la restauración del snapshot"
        return 1
    fi
}

update_etcd_manifest() {
    local manifest_backup="$1"
    local new_manifest="/tmp/etcd-restored.yaml"
    
    log "Actualizando manifest de etcd para usar directorio restaurado..."
    
    # Copiar manifest original
    cp "$manifest_backup" "$new_manifest"
    
    # Actualizar data-dir
    sed -i "s|$ORIGINAL_ETCD_DIR|$RESTORE_DIR|g" "$new_manifest"
    
    # Actualizar initial-cluster-token (importante para evitar conflictos)
    if grep -q "initial-cluster-token" "$new_manifest"; then
        sed -i "s/--initial-cluster-token=.*/--initial-cluster-token=$ETCD_INITIAL_CLUSTER_TOKEN/g" "$new_manifest"
    else
        # Agregar si no existe
        sed -i "/--initial-cluster=/a\    - --initial-cluster-token=$ETCD_INITIAL_CLUSTER_TOKEN" "$new_manifest"
    fi
    
    log "✅ Manifest actualizado"
    echo "$new_manifest"
}

start_control_plane() {
    local updated_manifest="$1"
    
    log "Reiniciando componentes del control plane..."
    
    # Restaurar manifest de etcd (modificado)
    mv "$updated_manifest" "$MANIFEST_DIR/etcd.yaml"
    
    log "Esperando a que etcd inicie (hasta $ETCD_TIMEOUT segundos)..."
    sleep $ETCD_TIMEOUT
    
    # Verificar que etcd está corriendo
    if ! crictl ps 2>/dev/null | grep -q etcd; then
        log_error "etcd no inició correctamente"
        log "Verificar logs con: sudo crictl logs <etcd-container-id>"
        return 1
    fi
    
    log "✅ etcd iniciado"
    
    # Restaurar otros componentes
    mv /tmp/kube-apiserver.yaml "$MANIFEST_DIR"/ 2>/dev/null || log_warning "API Server manifest no restaurado"
    mv /tmp/kube-controller-manager.yaml "$MANIFEST_DIR"/ 2>/dev/null || log_warning "Controller Manager manifest no restaurado"
    mv /tmp/kube-scheduler.yaml "$MANIFEST_DIR"/ 2>/dev/null || log_warning "Scheduler manifest no restaurado"
    
    log "Esperando a que componentes inicien (hasta $API_TIMEOUT segundos)..."
    sleep $API_TIMEOUT
    
    log "✅ Componentes del control plane reiniciados"
}

verify_cluster() {
    log "Verificando que el cluster está operacional..."
    
    local max_retries=12
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if kubectl get nodes &>/dev/null; then
            log "✅ API server está respondiendo"
            
            # Mostrar estado de nodos
            kubectl get nodes | tee -a "$LOG_FILE"
            
            # Mostrar pods del control plane
            kubectl get pods -n kube-system -l tier=control-plane | tee -a "$LOG_FILE"
            
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        log "Esperando API server... ($retry_count/$max_retries)"
        sleep 5
    done
    
    log_error "API server no responde después de $((max_retries * 5)) segundos"
    return 1
}

verify_data_restored() {
    log "Verificando que los datos fueron restaurados..."
    
    # Contar recursos en el cluster
    local namespaces=$(kubectl get namespaces --no-headers 2>/dev/null | wc -l)
    local pods=$(kubectl get pods -A --no-headers 2>/dev/null | wc -l)
    local deployments=$(kubectl get deployments -A --no-headers 2>/dev/null | wc -l)
    
    log "Recursos encontrados en el cluster restaurado:"
    log "  Namespaces: $namespaces"
    log "  Pods: $pods"
    log "  Deployments: $deployments"
    
    if [ "$namespaces" -gt 2 ]; then  # Al menos kube-system y default
        log "✅ Datos parecen estar restaurados correctamente"
        return 0
    else
        log_warning "Pocos recursos encontrados, verifica manualmente"
        return 1
    fi
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local snapshot_file="$1"
    
    log "=========================================="
    log "Iniciando proceso de RESTORE de etcd"
    log "=========================================="
    log "Snapshot: $snapshot_file"
    
    # Confirmación del usuario
    confirm_action "Este proceso va a:
  1. DETENER el cluster Kubernetes (downtime completo)
  2. Restaurar etcd desde el snapshot proporcionado
  3. ELIMINAR el estado actual del cluster
  4. Reiniciar con los datos del snapshot

  ⚠️  CUALQUIER CAMBIO DESDE EL SNAPSHOT SE PERDERÁ ⚠️"
    
    # Verificar prerequisitos
    snapshot_file=$(check_prerequisites "$snapshot_file")
    
    # Backup del manifest actual
    manifest_backup=$(backup_current_manifest)
    
    # Detener control plane
    stop_control_plane
    
    # Restaurar snapshot
    if ! restore_snapshot "$snapshot_file"; then
        log_error "Falló la restauración, intentando rollback..."
        
        # Intentar restaurar estado previo
        mv /tmp/kube-*.yaml "$MANIFEST_DIR"/ 2>/dev/null || true
        mv /tmp/etcd.yaml "$MANIFEST_DIR"/ 2>/dev/null || true
        
        log "Componentes restaurados, esperando recuperación..."
        sleep 30
        
        exit 1
    fi
    
    # Actualizar manifest
    updated_manifest=$(update_etcd_manifest "$manifest_backup")
    
    # Reiniciar control plane
    if ! start_control_plane "$updated_manifest"; then
        log_error "Falló el reinicio del control plane"
        exit 1
    fi
    
    # Verificar cluster
    if ! verify_cluster; then
        log_error "Cluster no está operacional después del restore"
        exit 1
    fi
    
    # Verificar datos restaurados
    verify_data_restored
    
    log "=========================================="
    log "Proceso de RESTORE completado"
    log "=========================================="
    log ""
    log "📊 ACCIONES POST-RESTORE RECOMENDADAS:"
    log "  1. Verificar todos los recursos críticos"
    log "  2. Revisar logs de componentes: kubectl logs -n kube-system <pod>"
    log "  3. Verificar aplicaciones: kubectl get pods -A"
    log "  4. Considerar crear nuevo backup: /usr/local/bin/backup-etcd.sh"
    log ""
    log "✅ Restore finalizado exitosamente"
    
    exit 0
}

# Manejo de argumentos
if [ $# -eq 0 ]; then
    echo "Uso: $0 <path-to-snapshot.db>"
    echo ""
    echo "Ejemplo:"
    echo "  sudo $0 /var/lib/etcd-backup/snapshot-20251113-103000.db"
    echo ""
    exit 1
fi

main "$1"
