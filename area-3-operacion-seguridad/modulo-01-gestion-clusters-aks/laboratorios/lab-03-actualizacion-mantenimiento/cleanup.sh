#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 03: Actualización y Mantenimiento...${NC}"

kubectl delete deployment app-critica --ignore-not-found=true 2>/dev/null
kubectl delete pdb app-critica-pdb --ignore-not-found=true 2>/dev/null
echo -e "  ${GREEN}✓ Recursos de aplicación eliminados${NC}"

# Uncordon todos los nodos por si alguno quedó cordoned
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    kubectl uncordon $node 2>/dev/null || true
done
echo -e "  ${GREEN}✓ Nodos restaurados (uncordoned)${NC}"

echo -e "\n${GREEN}🎉 Limpieza completada!${NC}"
