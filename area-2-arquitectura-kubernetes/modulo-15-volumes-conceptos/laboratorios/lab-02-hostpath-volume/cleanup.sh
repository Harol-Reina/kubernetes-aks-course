#!/bin/bash

##############################################################################
# Cleanup Script - Lab 02: HostPath Volume
# 
# Limpia todos los recursos creados en este laboratorio
##############################################################################

echo "🧹 Limpiando recursos del Lab 02: HostPath Volume..."
echo ""

# Colores
RED='\033[0;31m'
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
delete_resource pod pod-hostpath-basic
delete_resource pod pod-hostpath-writer
delete_resource pod pod-hostpath-types
delete_resource pod pod-writer
delete_resource pod pod-reader

# Eliminar DaemonSet
echo ""
echo "🔄 Eliminando DaemonSet..."
delete_resource daemonset log-collector

# Limpiar archivos del nodo (opcional)
echo ""
echo "🗑️  ¿Deseas limpiar archivos del nodo Minikube (/mnt/data)? (s/n)"
read -r response

if [[ "$response" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Limpiando /mnt/data en el nodo...${NC}"
    minikube ssh "sudo rm -rf /mnt/data/*" 2>/dev/null && \
        echo -e "${GREEN}✓ Archivos del nodo eliminados${NC}" || \
        echo -e "${RED}✗ No se pudo limpiar (¿Minikube corriendo?)${NC}"
else
    echo "ℹ️  Archivos del nodo conservados en /mnt/data"
fi

echo ""
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""
echo "Verificación final:"
kubectl get pods,daemonsets -l app=hostpath-demo,app=log-collector 2>/dev/null || \
    echo "✓ No hay recursos restantes"

echo ""
echo "🎉 Lab 02 limpio. Listo para ejecutar nuevamente o continuar al siguiente lab."
