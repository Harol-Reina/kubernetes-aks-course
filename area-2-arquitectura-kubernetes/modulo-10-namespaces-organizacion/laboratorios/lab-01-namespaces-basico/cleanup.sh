#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 01: Namespaces Basico...${NC}"

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
delete_namespace development
delete_namespace staging
delete_namespace production

echo -e "\n${YELLOW}Eliminando contextos personalizados...${NC}"
for ctx in staging-context prod-context; do
    if kubectl config get-contexts $ctx &> /dev/null 2>&1; then
        kubectl config delete-context $ctx
        echo -e "  ${GREEN}✓ context/$ctx eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ context/$ctx no existe (skip)${NC}"
    fi
done

echo -e "\n${YELLOW}Restaurando contexto original...${NC}"
ORIGINAL=$(kubectl config get-contexts -o name | head -1)
kubectl config set-context --current --namespace=default
echo -e "  ${GREEN}✓ Namespace restaurado a 'default'${NC}"

echo -e "\n${GREEN}🎉 Limpieza del Lab 01 completada!${NC}"
