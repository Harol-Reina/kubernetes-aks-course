#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando limpieza del Lab 03: Worker Nodes...${NC}"
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

echo "Eliminando Pods..."
delete_resource pod unhealthy-pod
delete_resource pod high-cpu-pod
delete_resource pod memory-hog
delete_resource pod multi-container
delete_resource pod guaranteed

echo
echo "Eliminando Services..."
delete_resource service external-db

echo
echo "Eliminando Endpoints..."
delete_resource endpoints external-db

echo
echo "Eliminando NetworkPolicies..."
delete_resource networkpolicy deny-all
delete_resource networkpolicy allow-from-frontend

echo
echo -e "${GREEN}Limpieza del Lab 03 completada!${NC}"
