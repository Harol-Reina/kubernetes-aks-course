#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 02: Troubleshooting de Resource Limits
#
# Descripcion: Elimina todos los recursos creados durante el laboratorio
# Uso: ./cleanup.sh
##############################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 02: Troubleshooting de Resource Limits...${NC}"
echo

# Funcion para eliminar recurso con verificacion
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-default}

    if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
        kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

# 1. Eliminar Pods de los ejercicios 1-3
echo "📦 Eliminando Pods de troubleshooting..."
delete_resource pod oomkilled-demo
delete_resource pod cpu-throttling-demo
delete_resource pod cpu-no-throttling
delete_resource pod storage-eviction-demo

# 2. Eliminar Deployments de los ejercicios 4-6
echo
echo "🚀 Eliminando Deployments..."
delete_resource deployment pending-demo
delete_resource deployment metrics-demo
delete_resource deployment problem-app
delete_resource deployment problem-app-fixed

# 3. Limpiar Pods por label del laboratorio
echo
echo "🏷️  Limpiando Pods por label lab=troubleshooting..."
if kubectl get pods -l lab=troubleshooting --no-headers 2>/dev/null | grep -q .; then
    kubectl delete pods -l lab=troubleshooting --ignore-not-found=true
    echo -e "  ${GREEN}✓ Pods con label lab=troubleshooting eliminados${NC}"
else
    echo -e "  ${YELLOW}⚠ No hay Pods con label lab=troubleshooting (skip)${NC}"
fi

# 4. Limpiar Pods en estado Failed (Evicted, OOMKilled, etc.)
echo
echo "🗑️  Limpiando Pods en estado Failed (Evicted)..."
FAILED_COUNT=$(kubectl get pods --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
if [ "$FAILED_COUNT" -gt 0 ]; then
    kubectl delete pods --field-selector=status.phase=Failed --ignore-not-found=true
    echo -e "  ${GREEN}✓ $FAILED_COUNT Pod(s) en estado Failed eliminados${NC}"
else
    echo -e "  ${YELLOW}⚠ No hay Pods en estado Failed (skip)${NC}"
fi

echo
echo -e "${GREEN}🎉 Limpieza del Lab 02 completada!${NC}"
