#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 04: Complete Cluster Troubleshooting
#
# Descripcion: Elimina todos los recursos creados durante el laboratorio
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 04: Complete Cluster Troubleshooting...${NC}"
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
delete_resource deployment critical-app
delete_resource deployment webapp-crash
delete_resource deployment api-server
delete_resource deployment config-app

echo
echo "📦 Eliminando StatefulSets..."
delete_resource statefulset postgres-db
delete_resource statefulset web

echo
echo "📦 Eliminando Pods..."
delete_resource pod test-restore
delete_resource pod memory-hog
delete_resource pod backend-app
delete_resource pod secure-pod

echo
echo "🌐 Eliminando Services..."
delete_resource service api-service
delete_resource service postgres-db
delete_resource service web

echo
echo "💾 Eliminando PVCs..."
delete_resource pvc data-postgres-db-0
delete_resource pvc data-postgres-db-1
delete_resource pvc data-postgres-db-2
delete_resource pvc data-web-0
delete_resource pvc data-web-1

echo
echo "📋 Eliminando ConfigMaps y Secrets..."
delete_resource configmap app-config
delete_resource configmap app-settings
delete_resource secret app-secret

echo
echo "🔐 Eliminando RBAC..."
delete_resource role pod-reader production
delete_resource rolebinding read-pods production
delete_resource clusterrole cluster-viewer
delete_resource clusterrolebinding cluster-viewer-binding

echo
echo "🔒 Eliminando Network Policies..."
delete_resource networkpolicy default-deny-all production
delete_resource networkpolicy allow-frontend-to-backend production
delete_resource networkpolicy allow-dns production
delete_resource networkpolicy default-deny-all

echo
echo "📊 Eliminando ResourceQuotas y LimitRanges..."
delete_resource resourcequota namespace-quota production
delete_resource limitrange default-limits production

echo
echo "⚡ Eliminando PriorityClasses..."
delete_resource priorityclass high-priority
delete_resource priorityclass low-priority

echo
echo "🗂️ Eliminando Namespaces..."
delete_resource namespace production
delete_resource namespace test-ns

echo
echo -e "${GREEN}🎉 Limpieza del Lab 04 completada!${NC}"
echo
echo -e "${YELLOW}⚠ Si el cluster esta en mal estado:${NC}"
echo "  1. Verificar components: sudo crictl ps | grep -E 'kube-apiserver|etcd'"
echo "  2. Ver logs: sudo journalctl -u kubelet -n 100"
echo "  3. Verificar nodes: kubectl get nodes"
