#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 05: Migracion de Docker Compose a Kubernetes
#
# Descripcion: Elimina todos los recursos Kubernetes creados en el laboratorio:
#              Deployments (web, api, db), Services, ConfigMaps, Secret y PVC.
#              Tambien termina procesos de port-forward activos.
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 05: Migracion Docker Compose...${NC}"
echo

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

echo -e "${YELLOW}Eliminando Deployments...${NC}"
delete_resource deployment web
delete_resource deployment api
delete_resource deployment db

echo
echo -e "${YELLOW}Eliminando Services...${NC}"
delete_resource service web
delete_resource service api
delete_resource service db

echo
echo -e "${YELLOW}Eliminando ConfigMaps...${NC}"
delete_resource configmap nginx-config
delete_resource configmap api-config
delete_resource configmap postgres-config

echo
echo -e "${YELLOW}Eliminando Secrets...${NC}"
delete_resource secret postgres-secret

echo
echo -e "${YELLOW}Eliminando PersistentVolumeClaims...${NC}"
delete_resource pvc postgres-pvc

echo
echo -e "${YELLOW}Terminando procesos port-forward activos...${NC}"
if pgrep -f "kubectl port-forward" > /dev/null 2>&1; then
    pkill -f "kubectl port-forward" || true
    echo -e "  ${GREEN}✓ Procesos port-forward terminados${NC}"
else
    echo -e "  ${YELLOW}⚠ No hay procesos port-forward activos (skip)${NC}"
fi

echo
echo -e "${YELLOW}Verificando que no quedan recursos...${NC}"
kubectl get deployment web api db 2>/dev/null || echo -e "  ${GREEN}✓ Sin Deployments residuales${NC}"
kubectl get pvc postgres-pvc 2>/dev/null || echo -e "  ${GREEN}✓ Sin PVCs residuales${NC}"

echo
echo -e "${GREEN}🎉 Limpieza del Lab 05 completada!${NC}"
