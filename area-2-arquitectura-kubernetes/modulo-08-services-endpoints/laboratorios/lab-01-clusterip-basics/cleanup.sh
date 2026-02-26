#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 01: ClusterIP Basics
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

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 01: ClusterIP Basics...${NC}"
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

# 1. Eliminar Pods de troubleshooting
echo "📦 Eliminando Pods de troubleshooting..."
delete_resource pod backend-not-ready
delete_resource pod backend-wrong-label

# 2. Eliminar Services
echo
echo "🌐 Eliminando Services..."
delete_resource service backend-service

# 3. Eliminar Deployments
echo
echo "📦 Eliminando Deployments..."
delete_resource deployment backend-deployment

# 4. Eliminar namespace de testing
echo
echo "🗂️  Eliminando namespaces..."
if kubectl get namespace testing &> /dev/null; then
    kubectl delete namespace testing
    echo -e "  ${GREEN}✓ namespace/testing eliminado${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/testing no existe (skip)${NC}"
fi

echo
echo -e "${GREEN}🎉 Limpieza del Lab 01 completada!${NC}"
