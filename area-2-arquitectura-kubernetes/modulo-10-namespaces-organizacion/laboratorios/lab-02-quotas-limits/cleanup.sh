#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 02: Quotas y Limits...${NC}"

delete_namespace() {
    local ns=$1
    if kubectl get namespace $ns &> /dev/null; then
        kubectl delete namespace $ns --ignore-not-found=true
        echo -e "  ${GREEN}✓ namespace/$ns eliminado (todos los recursos incluidos)${NC}"
    else
        echo -e "  ${YELLOW}⚠ namespace/$ns no existe (skip)${NC}"
    fi
}

echo -e "\n${YELLOW}Eliminando namespaces creados...${NC}"
delete_namespace dev-limited
delete_namespace test-quota

echo -e "\n${GREEN}🎉 Limpieza del Lab 02 completada!${NC}"
