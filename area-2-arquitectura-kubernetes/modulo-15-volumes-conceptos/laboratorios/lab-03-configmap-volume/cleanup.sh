#!/bin/bash

##############################################################################
# Cleanup Script - Lab 03: ConfigMap Volume
# 
# Limpia todos los recursos creados en este laboratorio
##############################################################################

echo "🧹 Limpiando recursos del Lab 03: ConfigMap Volume..."
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función para eliminar recursos
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    
    if kubectl get $resource_type $resource_name &> /dev/null; then
        echo -e "${YELLOW}Eliminando $resource_type/$resource_name...${NC}"
        kubectl delete $resource_type $resource_name --ignore-not-found=true
        echo -e "${GREEN}✓ $resource_name eliminado${NC}"
    else
        echo -e "${GREEN}✓ $resource_name no existe (ya limpio)${NC}"
    fi
}

# Eliminar Pods
echo "📦 Eliminando Pods..."
delete_resource pod pod-configmap-volume
delete_resource pod pod-nginx-configmap
delete_resource pod pod-selective-keys
delete_resource pod pod-config-permissions
delete_resource pod pod-dynamic-config

# Eliminar ConfigMaps
echo ""
echo "🗂️  Eliminando ConfigMaps..."
delete_resource configmap app-config
delete_resource configmap nginx-config
delete_resource configmap multi-config
delete_resource configmap dynamic-config

# Limpiar archivos locales
echo ""
echo "🗑️  Limpiando archivos locales..."
if [ -f nginx.conf ]; then
    rm -f nginx.conf
    echo -e "${GREEN}✓ nginx.conf eliminado${NC}"
else
    echo -e "${GREEN}✓ nginx.conf no existe${NC}"
fi

echo ""
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""
echo "Verificación final:"
kubectl get pods,configmaps 2>/dev/null | grep -E "pod-|app-config|nginx-config|multi-config|dynamic-config" || \
    echo "✓ No hay recursos restantes"

echo ""
echo "🎉 Lab 03 limpio. ¡Módulo 15 completado!"
echo "➡️  Siguiente: Módulo 16 - Volumes Tipos Storage (PV, PVC, StorageClass)"
