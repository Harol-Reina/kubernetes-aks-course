#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 01: Ingress Basico...${NC}"

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
delete_resource ingress path-based-ingress
delete_resource ingress host-based-ingress

echo -e "\n${YELLOW}Eliminando Deployments...${NC}"
delete_resource deployment app1
delete_resource deployment app2

echo -e "\n${YELLOW}Eliminando Services...${NC}"
delete_resource service servicio-app1
delete_resource service servicio-app2

echo -e "\n${YELLOW}Limpiando /etc/hosts...${NC}"
if grep -q "app1.example.com" /etc/hosts 2>/dev/null; then
    sudo sed -i '/app1.example.com/d' /etc/hosts
    echo -e "  ${GREEN}✓ Entrada app1.example.com eliminada de /etc/hosts${NC}"
else
    echo -e "  ${YELLOW}⚠ No hay entradas de example.com en /etc/hosts (skip)${NC}"
fi
if grep -q "app2.example.com" /etc/hosts 2>/dev/null; then
    sudo sed -i '/app2.example.com/d' /etc/hosts
    echo -e "  ${GREEN}✓ Entrada app2.example.com eliminada de /etc/hosts${NC}"
fi

echo -e "\n${GREEN}🎉 Limpieza del Lab 01 completada!${NC}"
