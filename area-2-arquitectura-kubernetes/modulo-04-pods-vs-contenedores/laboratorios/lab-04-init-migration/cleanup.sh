#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 04: Init Container Migration Pattern...${NC}"

delete_resource() {
    local resource_type=$1
    local resource_name=$2
    if kubectl get $resource_type $resource_name &> /dev/null; then
        kubectl delete $resource_type $resource_name --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

# Detener port-forward si sigue activo
echo -e "${YELLOW}  Deteniendo procesos kubectl port-forward...${NC}"
pkill -f "kubectl port-forward pod/app-with-init" 2>/dev/null && \
    echo -e "  ${GREEN}✓ port-forward detenido${NC}" || \
    echo -e "  ${YELLOW}⚠ No habia port-forward activo (skip)${NC}"

# Eliminar Pods
delete_resource pod app-with-init
delete_resource pod db

# Eliminar Service
delete_resource service db-service

# Eliminar ConfigMaps
delete_resource configmap app-code
delete_resource configmap migration-scripts
delete_resource configmap setup-scripts

echo -e "${GREEN}🎉 Script de limpieza completado!${NC}"
