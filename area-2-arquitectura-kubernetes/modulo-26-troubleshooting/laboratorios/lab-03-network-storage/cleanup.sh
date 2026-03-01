#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 03: Network & Storage Troubleshooting
#
# Descripcion: Elimina todos los recursos creados durante el laboratorio
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 03: Network & Storage Troubleshooting...${NC}"
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

echo "📦 Eliminando Ingress..."
delete_resource ingress app-ingress

echo
echo "📦 Eliminando StatefulSets..."
delete_resource statefulset web

echo
echo "🔒 Eliminando Network Policies..."
delete_resource networkpolicy deny-all
delete_resource networkpolicy allow-frontend-to-backend
delete_resource networkpolicy allow-frontend-egress
delete_resource networkpolicy allow-dns

echo
echo "📦 Eliminando Pods..."
delete_resource pod test-dns
delete_resource pod nginx-test
delete_resource pod test
delete_resource pod web-pod
delete_resource pod frontend
delete_resource pod backend
delete_resource pod app-pod
delete_resource pod pod1
delete_resource pod pod2
delete_resource pod writer-pod

echo
echo "🌐 Eliminando Services..."
delete_resource service web-service
delete_resource service nginx-test
delete_resource service app-service

echo
echo "💾 Eliminando PVCs..."
delete_resource pvc my-pvc
delete_resource pvc data-web-0
delete_resource pvc data-web-1

echo
echo "💾 Eliminando PVs..."
delete_resource pv my-pv
delete_resource pv pv-web-0
delete_resource pv pv-web-1

echo
echo -e "${GREEN}🎉 Limpieza del Lab 03 completada!${NC}"
