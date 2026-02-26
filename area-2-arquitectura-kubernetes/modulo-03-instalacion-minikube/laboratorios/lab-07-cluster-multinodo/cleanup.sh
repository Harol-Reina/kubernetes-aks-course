#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 3.7: Cluster Multi-Nodo...${NC}"

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

# Asegurarse de estar en el contexto correcto
echo -e "\n${YELLOW}Cambiando al contexto k8s-lab...${NC}"
kubectl config use-context k8s-lab 2>/dev/null || echo -e "  ${YELLOW}⚠ Contexto k8s-lab no disponible${NC}"

# Eliminar recursos de prueba del lab
echo -e "\n${YELLOW}Eliminando recursos de prueba...${NC}"
delete_resource deployment nginx-test
delete_resource pod test-cp

# Nota: NO eliminamos el cluster k8s-lab ni el taint
# porque se usan en laboratorios posteriores
echo -e "\n${YELLOW}ℹ️  El cluster k8s-lab y el taint se mantienen para labs posteriores.${NC}"
echo -e "${YELLOW}    Para eliminar el cluster completamente, ejecuta:${NC}"
echo -e "${YELLOW}    minikube delete -p k8s-lab${NC}"

echo -e "\n${GREEN}🎉 Script de limpieza completado!${NC}"
