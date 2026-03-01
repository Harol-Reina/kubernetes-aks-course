#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando limpieza del Lab 02: Control Plane Practico...${NC}"
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
delete_resource pod created-via-api
delete_resource pod scheduler-test
delete_resource pod ssd-pod
delete_resource pod unschedulable-pod
delete_resource pod huge-pod
delete_resource pod manual-schedule
delete_resource pod broken-pod
delete_resource pod fixed-pod
delete_resource pod api-test
delete_resource pod pod1
delete_resource pod pod2
delete_resource pod pod3

echo
echo "Eliminando Deployments..."
delete_resource deployment test-reconcile

echo
echo "Eliminando Services..."
delete_resource service test-endpoints

echo
echo "Eliminando Namespaces..."
delete_resource namespace backup-test
delete_resource namespace temporal

echo
echo "Eliminando archivos temporales..."
rm -f /tmp/pod-via-api.json etcd-backup-minikube.db 2>/dev/null && \
    echo -e "  ${GREEN}Archivos temporales eliminados${NC}" || \
    echo -e "  ${YELLOW}No habia archivos temporales (skip)${NC}"

echo
echo "Eliminando label disktype del nodo..."
kubectl label node minikube disktype- &>/dev/null && \
    echo -e "  ${GREEN}Label disktype eliminado del nodo${NC}" || \
    echo -e "  ${YELLOW}Label disktype no existia en el nodo (skip)${NC}"

echo
echo -e "${GREEN}Limpieza del Lab 02 completada!${NC}"
