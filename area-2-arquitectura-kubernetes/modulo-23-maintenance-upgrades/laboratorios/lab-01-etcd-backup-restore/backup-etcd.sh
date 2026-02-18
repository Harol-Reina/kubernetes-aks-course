#!/bin/bash
#
# backup-etcd.sh - Script de automatización de backups de etcd
#
# Este script realiza backups automáticos de etcd con verificación de integridad
# y rotación de backups antiguos.
#
# Uso: sudo /usr/local/bin/backup-etcd.sh
# Cron: 0 */6 * * * /usr/local/bin/backup-etcd.sh >> /var/log/etcd-backup.log 2>&1
#
# Autor: Kubernetes Course - Módulo 23
# Versión: 1.0
# Fecha: 2025-11-13

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# =============================================================================
# CONFIGURACIÓN
# =============================================================================

# Directorios
BACKUP_DIR="/var/lib/etcd-backup"
LOG_FILE="/var/log/etcd-backup.log"

# Configuración de etcd
export ETCDCTL_API=3
ETCD_CACERT="/etc/kubernetes/pki/etcd/ca.crt"
ETCD_CERT="/etc/kubernetes/pki/etcd/server.crt"
ETCD_KEY="/etc/kubernetes/pki/etcd/server.key"
ETCD_ENDPOINTS="https://127.0.0.1:2379"

# Retención de backups (días)
RETENTION_DAYS=7

# Alertas (configurar email si es necesario)
ALERT_EMAIL=""  # ejemplo: admin@example.com
SEND_ALERTS=false  # cambiar a true para habilitar alertas

# =============================================================================
# FUNCIONES
# =============================================================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

send_alert() {
    local subject="$1"
    local message="$2"
    
    if [ "$SEND_ALERTS" = true ] && [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "$subject" "$ALERT_EMAIL" 2>/dev/null || true
    fi
}

check_prerequisites() {
    log "Verificando prerequisitos..."
    
    # Verificar que estamos ejecutando como root
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script debe ejecutarse como root"
        exit 1
    fi
    
    # Verificar etcdctl
    if ! command -v etcdctl &> /dev/null; then
        log_error "etcdctl no está instalado"
        exit 1
    fi
    
    # Verificar certificados
    for cert in "$ETCD_CACERT" "$ETCD_CERT" "$ETCD_KEY"; do
        if [ ! -f "$cert" ]; then
            log_error "Certificado no encontrado: $cert"
            exit 1
        fi
    done
    
    # Crear directorio de backup si no existe
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        chmod 700 "$BACKUP_DIR"
        log "Directorio de backup creado: $BACKUP_DIR"
    fi
    
    log "✅ Prerequisitos verificados"
}

check_etcd_health() {
    log "Verificando salud de etcd..."
    
    local health_output
    health_output=$(etcdctl endpoint health \
        --cacert="$ETCD_CACERT" \
        --cert="$ETCD_CERT" \
        --key="$ETCD_KEY" \
        --endpoints="$ETCD_ENDPOINTS" 2>&1)
    
    if echo "$health_output" | grep -q "is healthy"; then
        log "✅ etcd está saludable"
        return 0
    else
        log_error "etcd no está saludable: $health_output"
        send_alert "etcd Backup FAILED" "etcd no está saludable antes del backup:\n$health_output"
        exit 1
    fi
}

create_backup() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$BACKUP_DIR/snapshot-${timestamp}.db"
    
    log "Iniciando backup de etcd..."
    log "Archivo destino: $backup_file"
    
    # Ejecutar snapshot
    if etcdctl snapshot save "$backup_file" \
        --cacert="$ETCD_CACERT" \
        --cert="$ETCD_CERT" \
        --key="$ETCD_KEY" \
        --endpoints="$ETCD_ENDPOINTS" 2>&1 | tee -a "$LOG_FILE"; then
        
        log "✅ Snapshot creado exitosamente"
        echo "$backup_file"  # Retornar path del backup
        return 0
    else
        log_error "Falló la creación del snapshot"
        send_alert "etcd Backup FAILED" "Error al crear snapshot de etcd"
        exit 1
    fi
}

verify_backup() {
    local backup_file="$1"
    
    log "Verificando integridad del backup..."
    
    # Verificar que el archivo existe y tiene tamaño > 0
    if [ ! -s "$backup_file" ]; then
        log_error "Archivo de backup vacío o no existe: $backup_file"
        return 1
    fi
    
    # Verificar status del snapshot
    local status_output
    status_output=$(etcdctl snapshot status "$backup_file" --write-out=table 2>&1)
    
    if [ $? -eq 0 ]; then
        log "✅ Backup verificado correctamente"
        echo "$status_output" | tee -a "$LOG_FILE"
        
        # Extraer información del backup
        local file_size=$(du -h "$backup_file" | awk '{print $1}')
        log "Tamaño del backup: $file_size"
        
        return 0
    else
        log_error "Verificación de backup falló: $status_output"
        return 1
    fi
}

rotate_old_backups() {
    log "Rotando backups antiguos (>$RETENTION_DAYS días)..."
    
    local deleted_count=0
    
    # Encontrar y eliminar backups antiguos
    while IFS= read -r -d '' old_backup; do
        log "Eliminando backup antiguo: $(basename "$old_backup")"
        rm -f "$old_backup"
        ((deleted_count++))
    done < <(find "$BACKUP_DIR" -name "snapshot-*.db" -type f -mtime +"$RETENTION_DAYS" -print0)
    
    if [ $deleted_count -gt 0 ]; then
        log "✅ Eliminados $deleted_count backups antiguos"
    else
        log "✅ No hay backups antiguos para eliminar"
    fi
    
    # Listar backups restantes
    local remaining_count=$(find "$BACKUP_DIR" -name "snapshot-*.db" -type f | wc -l)
    log "Backups actuales en disco: $remaining_count"
    
    # Mostrar los 5 más recientes
    if [ $remaining_count -gt 0 ]; then
        log "Últimos 5 backups:"
        ls -lht "$BACKUP_DIR"/snapshot-*.db | head -5 | while read -r line; do
            log "  $line"
        done
    fi
}

get_backup_statistics() {
    log "Estadísticas de backup:"
    
    # Tamaño total de backups
    local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')
    log "  Tamaño total de backups: $total_size"
    
    # Número de backups
    local backup_count=$(find "$BACKUP_DIR" -name "snapshot-*.db" -type f | wc -l)
    log "  Número de backups: $backup_count"
    
    # Backup más antiguo
    local oldest=$(find "$BACKUP_DIR" -name "snapshot-*.db" -type f -printf '%T+ %p\n' 2>/dev/null | sort | head -1 | awk '{print $2}')
    if [ -n "$oldest" ]; then
        local oldest_age=$(find "$oldest" -mtime +0 -printf '%Cd' 2>/dev/null || echo "N/A")
        log "  Backup más antiguo: $(basename "$oldest") ($oldest_age)"
    fi
    
    # Espacio disponible
    local available_space=$(df -h "$BACKUP_DIR" | tail -1 | awk '{print $4}')
    log "  Espacio disponible: $available_space"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    log "=========================================="
    log "Iniciando proceso de backup de etcd"
    log "=========================================="
    
    # Verificar prerequisitos
    check_prerequisites
    
    # Verificar salud de etcd
    check_etcd_health
    
    # Crear backup
    backup_file=$(create_backup)
    
    # Verificar integridad
    if verify_backup "$backup_file"; then
        log "✅ Backup completado y verificado exitosamente"
        
        # Rotar backups antiguos
        rotate_old_backups
        
        # Mostrar estadísticas
        get_backup_statistics
        
        # Enviar notificación de éxito (si está configurado)
        send_alert "etcd Backup SUCCESS" "Backup de etcd completado exitosamente:\n\nArchivo: $backup_file\nFecha: $(date)"
        
        log "=========================================="
        log "Proceso de backup finalizado exitosamente"
        log "=========================================="
        
        exit 0
    else
        log_error "Backup creado pero falló la verificación"
        
        # Eliminar backup corrupto
        log "Eliminando backup corrupto: $backup_file"
        rm -f "$backup_file"
        
        send_alert "etcd Backup FAILED" "Backup creado pero falló la verificación de integridad"
        
        exit 1
    fi
}

# Ejecutar main con manejo de errores global
if main; then
    exit 0
else
    log_error "Proceso de backup falló"
    exit 1
fi
