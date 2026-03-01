#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 01: Application Troubleshooting
#
# Descripcion: Elimina todos los recursos creados durante el laboratorio
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 01: Application Troubleshooting...${NC}"
echo

# Funcion para eliminar recurso con verificacion
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

echo "📦 Eliminando Deployments..."
delete_resource deployment webapp-crash
delete_resource deployment api-server
delete_resource deployment config-app

echo
echo "📦 Eliminando Pods..."
delete_resource pod memory-hog
delete_resource pod backend-app
delete_resource pod web-server
delete_resource pod api-pod
delete_resource pod python-app
delete_resource pod postgres
delete_resource pod test

echo
echo "🌐 Eliminando Services..."
delete_resource service api-service
delete_resource service python-service
delete_resource service postgres-service

echo
echo "📋 Eliminando ConfigMaps..."
delete_resource configmap app-settings

echo
echo -e "${GREEN}🎉 Limpieza del Lab 01 completada!${NC}"
