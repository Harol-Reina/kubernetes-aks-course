#!/bin/bash

##############################################################################
# Cleanup Script - Lab 01: EmptyDir Volume
# 
# Limpia todos los recursos creados en este laboratorio
##############################################################################

echo "🧹 Limpiando recursos del Lab 01: EmptyDir Volume..."
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
delete_resource pod pod-emptydir-shared
delete_resource pod pod-emptydir-memory
delete_resource pod pod-emptydir-sized

echo ""
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""
echo "Verificación final:"
kubectl get pods -l app=emptydir-demo 2>/dev/null || echo "✓ No hay Pods con label app=emptydir-demo"

echo ""
echo "🎉 Lab 01 limpio. Listo para ejecutar nuevamente o continuar al siguiente lab."
