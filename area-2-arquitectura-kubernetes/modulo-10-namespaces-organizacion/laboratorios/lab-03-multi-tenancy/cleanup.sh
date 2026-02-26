#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 03: Multi-Tenancy...${NC}"

delete_namespace() {
    local ns=$1
    if kubectl get namespace $ns &> /dev/null; then
        kubectl delete namespace $ns --ignore-not-found=true
        echo -e "  ${GREEN}✓ namespace/$ns eliminado (todos los recursos incluidos)${NC}"
    else
        echo -e "  ${YELLOW}⚠ namespace/$ns no existe (skip)${NC}"
    fi
}

echo -e "\n${YELLOW}Eliminando namespaces de tenants...${NC}"
delete_namespace tenant-company-a
delete_namespace tenant-company-b
delete_namespace tenant-company-c
delete_namespace tenant-vip

echo -e "\n${GREEN}🎉 Limpieza del Lab 03 completada!${NC}"
