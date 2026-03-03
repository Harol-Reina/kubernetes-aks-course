#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Ejemplo 02: Node Pools...${NC}"

# Eliminar deployment
kubectl delete deployment app-en-pool-especifico --ignore-not-found=true 2>/dev/null
echo -e "  ${GREEN}✓ Deployment eliminado${NC}"

# Eliminar node pools adicionales
for pool in apppool gpupool; do
    if az aks nodepool show --resource-group rg-ejemplo-aks --cluster-name aks-ejemplo --name $pool &> /dev/null; then
        az aks nodepool delete --resource-group rg-ejemplo-aks --cluster-name aks-ejemplo --name $pool --no-wait
        echo -e "  ${GREEN}✓ Node pool $pool marcado para eliminación${NC}"
    else
        echo -e "  ${YELLOW}⚠ Node pool $pool no existe (skip)${NC}"
    fi
done

echo -e "\n${GREEN}🎉 Limpieza completada!${NC}"
