#!/bin/bash
# Script para backup automatizado de etcd
# Uso: ./etcd-backup.sh [backup|restore|list]
# Requiere: etcdctl instalado

set -e

# Configuración
BACKUP_DIR="/var/backups/etcd"
ETCD_ENDPOINTS="https://127.0.0.1:2379"
ETCD_CACERT="/etc/kubernetes/pki/etcd/ca.crt"
ETCD_CERT="/etc/kubernetes/pki/etcd/server.crt"
ETCD_KEY="/etc/kubernetes/pki/etcd/server.key"
RETENTION_DAYS=7

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    print_error "Este script debe ejecutarse como root"
    exit 1
fi

# Verificar etcdctl
if ! command -v etcdctl &> /dev/null; then
    print_error "etcdctl no está instalado"
    echo "Instalar: sudo apt-get install -y etcd-client"
    exit 1
fi

# Crear directorio de backups
mkdir -p "$BACKUP_DIR"

# Función: Crear backup
backup_etcd() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="${BACKUP_DIR}/etcd-snapshot-${timestamp}.db"
    
    print_info "Iniciando backup de etcd..."
    print_info "Archivo: $backup_file"
    
    # Realizar snapshot
    ETCDCTL_API=3 etcdctl snapshot save "$backup_file" \
        --endpoints="$ETCD_ENDPOINTS" \
        --cacert="$ETCD_CACERT" \
        --cert="$ETCD_CERT" \
        --key="$ETCD_KEY"
    
    if [ $? -eq 0 ]; then
        print_info "✓ Backup completado exitosamente"
        
        # Verificar integridad del snapshot
        print_info "Verificando integridad del snapshot..."
        ETCDCTL_API=3 etcdctl snapshot status "$backup_file" \
            --write-out=table
        
        # Comprimir backup
        print_info "Comprimiendo backup..."
        gzip "$backup_file"
        backup_file="${backup_file}.gz"
        
        # Mostrar tamaño
        local size=$(du -h "$backup_file" | cut -f1)
        print_info "✓ Backup comprimido: $size"
        
        # Limpiar backups antiguos
        cleanup_old_backups
        
        return 0
    else
        print_error "Falló el backup de etcd"
        return 1
    fi
}

# Función: Restaurar backup
restore_etcd() {
    print_warning "============================================"
    print_warning "ADVERTENCIA: RESTAURAR ETCD"
    print_warning "============================================"
    print_warning "Esta operación:"
    print_warning "  - Detendrá el cluster temporalmente"
    print_warning "  - Restaurará datos desde el snapshot"
    print_warning "  - Puede causar pérdida de datos recientes"
    print_warning ""
    
    # Listar backups disponibles
    print_info "Backups disponibles:"
    list_backups
    
    echo ""
    read -p "¿Nombre del archivo de backup (sin .gz)? " backup_name
    
    local backup_file="${BACKUP_DIR}/${backup_name}.gz"
    
    if [ ! -f "$backup_file" ]; then
        print_error "Archivo de backup no encontrado: $backup_file"
        return 1
    fi
    
    print_warning ""
    read -p "¿Confirmar restauración? (escribir 'yes'): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Restauración cancelada"
        return 0
    fi
    
    # Directorio temporal para descomprimir
    local temp_snapshot="${BACKUP_DIR}/temp-snapshot.db"
    
    print_info "Descomprimiendo backup..."
    gunzip -c "$backup_file" > "$temp_snapshot"
    
    print_info "Verificando snapshot..."
    ETCDCTL_API=3 etcdctl snapshot status "$temp_snapshot" \
        --write-out=table
    
    print_info ""
    print_warning "PRÓXIMOS PASOS MANUALES:"
    print_warning ""
    print_warning "1. Detener todos los componentes del control plane:"
    print_warning "   sudo systemctl stop kube-apiserver"
    print_warning "   sudo systemctl stop kube-controller-manager"
    print_warning "   sudo systemctl stop kube-scheduler"
    print_warning ""
    print_warning "2. Mover datos etcd actuales (backup de seguridad):"
    print_warning "   sudo mv /var/lib/etcd /var/lib/etcd.backup"
    print_warning ""
    print_warning "3. Restaurar snapshot:"
    print_warning "   sudo ETCDCTL_API=3 etcdctl snapshot restore $temp_snapshot \\"
    print_warning "     --data-dir=/var/lib/etcd-restore \\"
    print_warning "     --name=<node-name> \\"
    print_warning "     --initial-cluster=<initial-cluster> \\"
    print_warning "     --initial-advertise-peer-urls=<peer-urls>"
    print_warning ""
    print_warning "4. Mover datos restaurados:"
    print_warning "   sudo mv /var/lib/etcd-restore /var/lib/etcd"
    print_warning ""
    print_warning "5. Reiniciar componentes:"
    print_warning "   sudo systemctl start kube-apiserver"
    print_warning "   sudo systemctl start kube-controller-manager"
    print_warning "   sudo systemctl start kube-scheduler"
    print_warning ""
    print_warning "6. Verificar cluster:"
    print_warning "   kubectl get nodes"
    print_warning "   kubectl get pods --all-namespaces"
    print_warning ""
    
    print_info "Snapshot preparado en: $temp_snapshot"
}

# Función: Listar backups
list_backups() {
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR)" ]; then
        print_warning "No hay backups disponibles"
        return 0
    fi
    
    echo "----------------------------------------"
    printf "%-30s %10s %20s\n" "ARCHIVO" "TAMAÑO" "FECHA"
    echo "----------------------------------------"
    
    for backup in $(ls -t "$BACKUP_DIR"/*.gz 2>/dev/null); do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c %y "$backup" | cut -d' ' -f1,2 | cut -d'.' -f1)
        printf "%-30s %10s %20s\n" "$filename" "$size" "$date"
    done
    
    echo "----------------------------------------"
    
    # Mostrar total
    local total_backups=$(ls "$BACKUP_DIR"/*.gz 2>/dev/null | wc -l)
    local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo "Total: $total_backups backups, $total_size"
}

# Función: Limpiar backups antiguos
cleanup_old_backups() {
    print_info "Limpiando backups antiguos (>$RETENTION_DAYS días)..."
    
    local deleted=0
    while IFS= read -r backup; do
        rm -f "$backup"
        print_info "  Eliminado: $(basename $backup)"
        ((deleted++))
    done < <(find "$BACKUP_DIR" -name "etcd-snapshot-*.db.gz" -mtime +$RETENTION_DAYS)
    
    if [ $deleted -eq 0 ]; then
        print_info "No hay backups antiguos para eliminar"
    else
        print_info "✓ Eliminados $deleted backups antiguos"
    fi
}

# Función: Verificar salud de etcd
check_etcd_health() {
    print_info "Verificando salud de etcd..."
    
    ETCDCTL_API=3 etcdctl endpoint health \
        --endpoints="$ETCD_ENDPOINTS" \
        --cacert="$ETCD_CACERT" \
        --cert="$ETCD_CERT" \
        --key="$ETCD_KEY"
    
    print_info ""
    print_info "Estadísticas de etcd:"
    ETCDCTL_API=3 etcdctl endpoint status \
        --endpoints="$ETCD_ENDPOINTS" \
        --cacert="$ETCD_CACERT" \
        --cert="$ETCD_CERT" \
        --key="$ETCD_KEY" \
        --write-out=table
}

# Función: Mostrar uso
show_usage() {
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos:"
    echo "  backup    - Crear nuevo backup de etcd"
    echo "  restore   - Restaurar desde backup"
    echo "  list      - Listar backups disponibles"
    echo "  health    - Verificar salud de etcd"
    echo "  cleanup   - Limpiar backups antiguos manualmente"
    echo ""
    echo "Ejemplos:"
    echo "  $0 backup"
    echo "  $0 list"
    echo "  $0 restore"
    echo ""
}

# Main
case "${1:-}" in
    backup)
        backup_etcd
        ;;
    restore)
        restore_etcd
        ;;
    list)
        list_backups
        ;;
    health)
        check_etcd_health
        ;;
    cleanup)
        cleanup_old_backups
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

exit 0
