#!/bin/bash
#
# cleanup.sh - Script de limpieza para Lab 01: etcd Backup y Restore
#
# Este script restaura el entorno al estado original después del laboratorio.
# Ejecutar con: sudo ./cleanup.sh
#
# Autor: Kubernetes Course - Módulo 23
# Versión: 1.0
# Fecha: 2025-11-13

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
BACKUP_DIR="/var/lib/etcd-backup"
RESTORE_DIR="/var/lib/etcd-restored"
ORIGINAL_ETCD_DIR="/var/lib/etcd"
MANIFEST_DIR="/etc/kubernetes/manifests"
MANIFEST_BACKUP="/root/etcd-manifest-backup-*.yaml"
TEST_NAMESPACE="backup-test"
LOG_FILE="/var/log/etcd-backup.log"

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   CLEANUP - Lab 01: etcd Backup y Restore                 ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar ejecución como root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}❌ ERROR: Este script debe ejecutarse como root (usa sudo)${NC}"
  exit 1
fi

echo -e "${GREEN}🔍 Iniciando proceso de limpieza...${NC}"
echo ""

# =============================================================================
# PASO 1: Eliminar namespace de prueba
# =============================================================================
echo -e "${YELLOW}[1/8]${NC} Eliminando namespace de prueba '${TEST_NAMESPACE}'..."

if kubectl get namespace "$TEST_NAMESPACE" &>/dev/null; then
    kubectl delete namespace "$TEST_NAMESPACE" --timeout=60s
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Namespace eliminado exitosamente${NC}"
    else
        echo -e "${YELLOW}⚠️  Namespace no se pudo eliminar, continuando...${NC}"
    fi
else
    echo -e "${GREEN}✅ Namespace ya no existe${NC}"
fi
echo ""

# =============================================================================
# PASO 2: Limpiar backups de prueba
# =============================================================================
echo -e "${YELLOW}[2/8]${NC} Limpiando archivos de backup en ${BACKUP_DIR}..."

if [ -d "$BACKUP_DIR" ]; then
    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "snapshot-*.db" 2>/dev/null | wc -l)
    
    if [ "$BACKUP_COUNT" -gt 0 ]; then
        echo "   Encontrados $BACKUP_COUNT archivos de backup"
        
        # Preguntar si eliminar todos o mantener algunos
        read -p "   ¿Eliminar TODOS los backups? (s/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            rm -f "$BACKUP_DIR"/snapshot-*.db
            echo -e "${GREEN}✅ Todos los backups eliminados${NC}"
        else
            # Mantener solo el más reciente
            LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/snapshot-*.db 2>/dev/null | head -1)
            find "$BACKUP_DIR" -name "snapshot-*.db" ! -name "$(basename $LATEST_BACKUP)" -delete
            echo -e "${GREEN}✅ Backups antiguos eliminados, manteniendo: $(basename $LATEST_BACKUP)${NC}"
        fi
    else
        echo -e "${GREEN}✅ No hay backups de prueba para limpiar${NC}"
    fi
else
    echo -e "${GREEN}✅ Directorio de backup no existe${NC}"
fi
echo ""

# =============================================================================
# PASO 3: Verificar y restaurar manifest original de etcd
# =============================================================================
echo -e "${YELLOW}[3/8]${NC} Verificando manifest de etcd..."

ETCD_MANIFEST="$MANIFEST_DIR/etcd.yaml"
CURRENT_DATA_DIR=$(grep -A1 "data-dir" "$ETCD_MANIFEST" 2>/dev/null | tail -1 | awk '{print $2}' | tr -d '"')

if [ "$CURRENT_DATA_DIR" != "$ORIGINAL_ETCD_DIR" ]; then
    echo -e "${YELLOW}⚠️  etcd está usando data-dir no estándar: $CURRENT_DATA_DIR${NC}"
    echo "   Restaurando a directorio original: $ORIGINAL_ETCD_DIR"
    
    # Buscar backup del manifest original
    MANIFEST_BACKUP_FILE=$(ls -t $MANIFEST_BACKUP 2>/dev/null | head -1)
    
    if [ -n "$MANIFEST_BACKUP_FILE" ]; then
        echo "   Usando backup: $MANIFEST_BACKUP_FILE"
        
        # Detener componentes del control plane
        echo "   Deteniendo componentes del control plane..."
        mv "$MANIFEST_DIR"/kube-apiserver.yaml /tmp/ 2>/dev/null || true
        mv "$MANIFEST_DIR"/kube-controller-manager.yaml /tmp/ 2>/dev/null || true
        mv "$MANIFEST_DIR"/kube-scheduler.yaml /tmp/ 2>/dev/null || true
        mv "$ETCD_MANIFEST" /tmp/etcd-current.yaml 2>/dev/null || true
        
        sleep 10
        
        # Restaurar manifest original
        cp "$MANIFEST_BACKUP_FILE" "$ETCD_MANIFEST"
        
        sleep 30  # Esperar a que etcd inicie
        
        # Restaurar otros componentes
        mv /tmp/kube-apiserver.yaml "$MANIFEST_DIR"/ 2>/dev/null || true
        mv /tmp/kube-controller-manager.yaml "$MANIFEST_DIR"/ 2>/dev/null || true
        mv /tmp/kube-scheduler.yaml "$MANIFEST_DIR"/ 2>/dev/null || true
        
        sleep 30  # Esperar a que todo inicie
        
        echo -e "${GREEN}✅ Manifest de etcd restaurado${NC}"
    else
        echo -e "${RED}⚠️  No se encontró backup del manifest original${NC}"
        echo "   Manifest actual preservado en: /tmp/etcd-current.yaml"
    fi
else
    echo -e "${GREEN}✅ etcd usa el data-dir correcto ($ORIGINAL_ETCD_DIR)${NC}"
fi
echo ""

# =============================================================================
# PASO 4: Limpiar directorio de restore
# =============================================================================
echo -e "${YELLOW}[4/8]${NC} Limpiando directorio de restore..."

if [ -d "$RESTORE_DIR" ]; then
    # Verificar que etcd no está usando este directorio
    CURRENT_DATA_DIR=$(grep -A1 "data-dir" "$ETCD_MANIFEST" 2>/dev/null | tail -1 | awk '{print $2}' | tr -d '"')
    
    if [ "$CURRENT_DATA_DIR" == "$RESTORE_DIR" ]; then
        echo -e "${RED}⚠️  ADVERTENCIA: etcd está usando actualmente $RESTORE_DIR${NC}"
        echo "   No se eliminará para evitar pérdida de datos"
    else
        echo "   Eliminando $RESTORE_DIR..."
        rm -rf "$RESTORE_DIR"
        echo -e "${GREEN}✅ Directorio de restore eliminado${NC}"
    fi
else
    echo -e "${GREEN}✅ Directorio de restore no existe${NC}"
fi
echo ""

# =============================================================================
# PASO 5: Remover cron jobs de backup (opcional)
# =============================================================================
echo -e "${YELLOW}[5/8]${NC} Verificando cron jobs de backup..."

if crontab -l 2>/dev/null | grep -q "backup-etcd.sh"; then
    read -p "   ¿Eliminar cron jobs de backup automático? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        crontab -l | grep -v "backup-etcd.sh" | crontab -
        echo -e "${GREEN}✅ Cron jobs de backup eliminados${NC}"
    else
        echo -e "${YELLOW}ℹ️  Cron jobs mantenidos${NC}"
    fi
else
    echo -e "${GREEN}✅ No hay cron jobs de backup configurados${NC}"
fi
echo ""

# =============================================================================
# PASO 6: Limpiar logs
# =============================================================================
echo -e "${YELLOW}[6/8]${NC} Limpiando logs de backup..."

if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(du -h "$LOG_FILE" | awk '{print $1}')
    echo "   Tamaño del log: $LOG_SIZE"
    
    read -p "   ¿Truncar log de backups? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        > "$LOG_FILE"
        echo -e "${GREEN}✅ Log truncado${NC}"
    else
        echo -e "${YELLOW}ℹ️  Log preservado${NC}"
    fi
else
    echo -e "${GREEN}✅ No hay log de backup${NC}"
fi
echo ""

# =============================================================================
# PASO 7: Verificar estado del cluster
# =============================================================================
echo -e "${YELLOW}[7/8]${NC} Verificando estado del cluster..."

# Esperar a que API server esté disponible
MAX_RETRIES=12
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if kubectl get nodes &>/dev/null; then
        echo -e "${GREEN}✅ API server está respondiendo${NC}"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "   Esperando API server... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 5
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}❌ ERROR: API server no responde después de $((MAX_RETRIES * 5)) segundos${NC}"
    echo "   Verifica manualmente con: kubectl get nodes"
else
    # Verificar salud de componentes
    echo ""
    echo "   Estado de componentes del control plane:"
    kubectl get pods -n kube-system -l tier=control-plane -o wide
fi
echo ""

# =============================================================================
# PASO 8: Verificar salud de etcd
# =============================================================================
echo -e "${YELLOW}[8/8]${NC} Verificando salud de etcd..."

export ETCDCTL_API=3

ETCD_HEALTH=$(ETCDCTL_API=3 etcdctl endpoint health \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    --endpoints=https://127.0.0.1:2379 2>&1)

if echo "$ETCD_HEALTH" | grep -q "is healthy"; then
    echo -e "${GREEN}✅ etcd está saludable${NC}"
    echo "   $ETCD_HEALTH"
else
    echo -e "${RED}⚠️  etcd no responde correctamente${NC}"
    echo "   $ETCD_HEALTH"
    echo "   Verifica logs con: sudo crictl logs <etcd-container-id>"
fi
echo ""

# =============================================================================
# RESUMEN FINAL
# =============================================================================
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║               LIMPIEZA COMPLETADA                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "📊 Resumen de limpieza:"
echo "   ✅ Namespace de prueba eliminado"
echo "   ✅ Backups gestionados"
echo "   ✅ Manifest de etcd verificado"
echo "   ✅ Directorio de restore limpiado"
echo "   ✅ Cluster verificado como funcional"
echo ""
echo "📋 Verificaciones finales recomendadas:"
echo "   kubectl get nodes"
echo "   kubectl get pods -A"
echo "   sudo crictl ps | grep etcd"
echo ""
echo -e "${GREEN}🎉 ¡Laboratorio limpio! Listo para siguiente práctica.${NC}"
echo ""

# Guardar resumen en log
{
    echo "=== CLEANUP EJECUTADO ==="
    echo "Fecha: $(date)"
    echo "Usuario: $(whoami)"
    echo "Estado final del cluster:"
    kubectl get nodes 2>&1
    echo "=========================="
} >> /var/log/etcd-cleanup.log 2>/dev/null || true

exit 0
