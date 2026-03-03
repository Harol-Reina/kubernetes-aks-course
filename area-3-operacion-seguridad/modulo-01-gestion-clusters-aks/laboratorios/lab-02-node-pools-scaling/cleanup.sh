#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 02: Node Pools y Scaling...${NC}"

kubectl delete deployment webapp --ignore-not-found=true 2>/dev/null
kubectl delete hpa webapp --ignore-not-found=true 2>/dev/null
echo -e "  ${GREEN}✓ Recursos de aplicación eliminados${NC}"

for pool in webpool batchpool; do
    if az aks nodepool show --resource-group rg-lab-aks --cluster-name aks-lab-01 --name $pool &> /dev/null 2>&1; then
        az aks nodepool delete --resource-group rg-lab-aks --cluster-name aks-lab-01 --name $pool --no-wait
        echo -e "  ${GREEN}✓ Node pool $pool marcado para eliminación${NC}"
    else
        echo -e "  ${YELLOW}⚠ Node pool $pool no existe (skip)${NC}"
    fi
done

echo -e "\n${GREEN}🎉 Limpieza completada!${NC}"
