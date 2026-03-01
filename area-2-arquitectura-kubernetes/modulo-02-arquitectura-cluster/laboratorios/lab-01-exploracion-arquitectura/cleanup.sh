#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando limpieza del Lab 01: Exploracion de Arquitectura...${NC}"
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
delete_resource pod test-pod
delete_resource pod nginx-test
delete_resource pod test-kubelet
delete_resource pod test-watch
delete_resource pod test-perf

echo
echo "Eliminando Deployments..."
delete_resource deployment nginx-test
delete_resource deployment web

echo
echo -e "${GREEN}Limpieza del Lab 01 completada!${NC}"
