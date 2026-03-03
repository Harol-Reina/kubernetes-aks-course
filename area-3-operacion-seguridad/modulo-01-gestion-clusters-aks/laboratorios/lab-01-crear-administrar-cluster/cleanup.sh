#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 01: Crear y Administrar Cluster...${NC}"

# Eliminar deployment de prueba
kubectl delete deployment nginx-test --ignore-not-found=true 2>/dev/null
kubectl delete service nginx-test --ignore-not-found=true 2>/dev/null
echo -e "  ${GREEN}✓ Recursos de prueba eliminados${NC}"

# Eliminar resource group (incluye el cluster)
if az group show --name rg-lab-aks &> /dev/null; then
    echo -e "  ${YELLOW}Eliminando resource group rg-lab-aks...${NC}"
    az group delete --name rg-lab-aks --yes --no-wait
    echo -e "  ${GREEN}✓ Resource group marcado para eliminación${NC}"
else
    echo -e "  ${YELLOW}⚠ Resource group rg-lab-aks no existe (skip)${NC}"
fi

# Limpiar contexto kubectl
kubectl config delete-context aks-lab-01 2>/dev/null || true
echo -e "  ${GREEN}✓ Contexto kubectl limpiado${NC}"

echo -e "\n${GREEN}🎉 Limpieza completada!${NC}"
