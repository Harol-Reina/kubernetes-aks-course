#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Ejemplo 01: Crear Cluster AKS...${NC}"

# Eliminar el resource group completo (incluye cluster y todos sus recursos)
if az group show --name rg-ejemplo-aks &> /dev/null; then
    echo -e "  ${YELLOW}Eliminando resource group rg-ejemplo-aks (esto tarda ~5 min)...${NC}"
    az group delete --name rg-ejemplo-aks --yes --no-wait
    echo -e "  ${GREEN}✓ Resource group rg-ejemplo-aks marcado para eliminación${NC}"
else
    echo -e "  ${YELLOW}⚠ Resource group rg-ejemplo-aks no existe (skip)${NC}"
fi

# Limpiar contexto de kubectl
kubectl config delete-context aks-ejemplo 2>/dev/null || true
echo -e "  ${GREEN}✓ Contexto kubectl limpiado${NC}"

echo -e "\n${GREEN}🎉 Limpieza completada!${NC}"
