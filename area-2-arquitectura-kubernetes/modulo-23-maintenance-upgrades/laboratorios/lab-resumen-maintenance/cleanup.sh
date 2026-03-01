#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Limpieza del Lab Resumen: Maintenance & Upgrades...${NC}"

# Uncordon any cordoned nodes first
echo ""
echo "Verificando nodos en estado cordoned..."
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    if kubectl get node "$node" -o jsonpath='{.spec.unschedulable}' 2>/dev/null | grep -q "true"; then
        kubectl uncordon "$node"
        echo -e "  ${GREEN}[OK] node/$node uncordoned${NC}"
    else
        echo -e "  ${YELLOW}[--] node/$node ya esta schedulable${NC}"
    fi
done

echo ""
echo "Eliminando namespace lab-maintenance-test..."
if kubectl get namespace lab-maintenance-test &> /dev/null; then
    kubectl delete namespace lab-maintenance-test
    echo -e "  ${GREEN}[OK] namespace/lab-maintenance-test eliminado${NC}"
else
    echo -e "  ${YELLOW}[--] namespace/lab-maintenance-test no existe (skip)${NC}"
fi

echo ""
kubectl config set-context --current --namespace=default 2>/dev/null || true
echo -e "  ${GREEN}[OK] contexto restaurado a namespace default${NC}"

echo ""
echo -e "${GREEN}Limpieza completada!${NC}"
