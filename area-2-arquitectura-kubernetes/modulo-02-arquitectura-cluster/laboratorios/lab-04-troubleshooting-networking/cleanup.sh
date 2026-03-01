#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando limpieza del Lab 04: Troubleshooting de Networking...${NC}"
echo

delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-default}
    if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
        kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
        echo -e "  ${GREEN}$resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}$resource_type/$resource_name no existe (skip)${NC}"
    fi
}

echo "Eliminando Deployments..."
delete_resource deployment broken-app
delete_resource deployment backend
delete_resource deployment web
delete_resource deployment trace-test
delete_resource deployment myapp

echo
echo "Eliminando Services..."
delete_resource service broken-service
delete_resource service backend-service
delete_resource service web
delete_resource service trace-test
delete_resource service myapp

echo
echo "Eliminando Pods..."
delete_resource pod netshoot
delete_resource pod minimal

echo
echo -e "${GREEN}Limpieza del Lab 04 completada!${NC}"
