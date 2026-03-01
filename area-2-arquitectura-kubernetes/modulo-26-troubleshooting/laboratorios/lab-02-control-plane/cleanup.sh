#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 02: Control Plane & Worker Nodes Troubleshooting
#
# Descripcion: Elimina todos los recursos creados durante el laboratorio
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 02: Control Plane Troubleshooting...${NC}"
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
delete_resource deployment test-nginx

echo
echo "📦 Eliminando Pods..."
delete_resource pod test-1
delete_resource pod test-2
delete_resource pod test-dns

echo
echo "📋 Eliminando Static Pods (si existen)..."
if [ -f /etc/kubernetes/manifests/static-web.yaml ]; then
    sudo rm -f /etc/kubernetes/manifests/static-web.yaml
    echo -e "  ${GREEN}✓ /etc/kubernetes/manifests/static-web.yaml eliminado${NC}"
else
    echo -e "  ${YELLOW}⚠ static-web.yaml no existe en manifests (skip)${NC}"
fi

echo
echo -e "${GREEN}🎉 Limpieza del Lab 02 completada!${NC}"
echo
echo -e "${YELLOW}⚠ Recuerda verificar que kubelet este corriendo en todos los nodes:${NC}"
echo "   sudo systemctl status kubelet"
echo "   sudo systemctl start kubelet  # si esta detenido"
