#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 03: Ingress en Produccion...${NC}"

delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-default}
    if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
        kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

echo -e "\n${YELLOW}Eliminando Ingress resources...${NC}"
delete_resource ingress production
delete_resource ingress canary
delete_resource ingress rate-limited-api
delete_resource ingress admin-whitelist

echo -e "\n${YELLOW}Eliminando Deployments...${NC}"
delete_resource deployment app-v1
delete_resource deployment app-v2

echo -e "\n${YELLOW}Eliminando Services...${NC}"
delete_resource service app-v1
delete_resource service app-v2

echo -e "\n${YELLOW}Eliminando PodDisruptionBudget...${NC}"
delete_resource pdb ingress-nginx-pdb ingress-nginx

echo -e "\n${YELLOW}Limpiando /etc/hosts...${NC}"
if grep -q "example.com" /etc/hosts 2>/dev/null; then
    sudo sed -i '/example.com/d' /etc/hosts
    echo -e "  ${GREEN}✓ Entradas example.com eliminadas de /etc/hosts${NC}"
else
    echo -e "  ${YELLOW}⚠ No hay entradas de example.com en /etc/hosts (skip)${NC}"
fi

echo -e "\n${GREEN}🎉 Limpieza del Lab 03 completada!${NC}"
