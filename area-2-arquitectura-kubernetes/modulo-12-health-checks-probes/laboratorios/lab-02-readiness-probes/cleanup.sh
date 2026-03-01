#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 02: Startup Probes y Casos Avanzados
#
# Descripcion: Elimina todos los recursos creados durante el laboratorio
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 02: Startup Probes y Casos Avanzados...${NC}"
echo

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

echo "📦 Eliminando Pods..."
delete_resource pod slow-app-without-startup
delete_resource pod slow-app-with-startup
delete_resource pod postgres-production

echo
echo "🚀 Eliminando Deployments..."
delete_resource deployment nodejs-production
delete_resource deployment critical-app

echo
echo -e "${GREEN}🎉 Limpieza del Lab 02 completada!${NC}"
