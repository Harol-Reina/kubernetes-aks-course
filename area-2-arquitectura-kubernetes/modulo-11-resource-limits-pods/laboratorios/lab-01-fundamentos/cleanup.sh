#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 01: Fundamentos de Resource Limits
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

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 01: Fundamentos de Resource Limits...${NC}"
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

# 1. Eliminar Pods individuales
echo "📦 Eliminando Pods del laboratorio..."
delete_resource pod app-basic
delete_resource pod qos-guaranteed
delete_resource pod qos-burstable
delete_resource pod qos-besteffort
delete_resource pod multi-container-app
delete_resource pod init-container-demo

# 2. Eliminar Deployments
echo
echo "🚀 Eliminando Deployments..."
delete_resource deployment fill-node

# 3. Limpieza adicional por label (por si quedaron recursos residuales)
echo
echo "🏷️  Limpiando recursos residuales por label lab=fundamentos..."
if kubectl get pods -l lab=fundamentos --no-headers 2>/dev/null | grep -q .; then
    kubectl delete pods,deployments -l lab=fundamentos --ignore-not-found=true
    echo -e "  ${GREEN}✓ Recursos con label lab=fundamentos eliminados${NC}"
else
    echo -e "  ${YELLOW}⚠ No se encontraron recursos residuales con label lab=fundamentos (skip)${NC}"
fi

echo
echo -e "${GREEN}🎉 Limpieza del Lab 01 completada!${NC}"
