#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 02: NodePort y LoadBalancer
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

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 02: NodePort y LoadBalancer...${NC}"
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

# 1. Eliminar Services
echo "🌐 Eliminando Services..."
delete_resource service webapp-nodeport-auto
delete_resource service webapp-nodeport-custom
delete_resource service webapp-cluster-policy
delete_resource service webapp-local-policy
delete_resource service webapp-lb

# 2. Eliminar Deployments
echo
echo "📦 Eliminando Deployments..."
delete_resource deployment webapp

echo
echo -e "${GREEN}🎉 Limpieza del Lab 02 completada!${NC}"
