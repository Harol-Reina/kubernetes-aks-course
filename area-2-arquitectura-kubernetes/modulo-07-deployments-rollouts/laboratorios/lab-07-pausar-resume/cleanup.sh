#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 07: Troubleshooting de Deployments
#
# Descripcion: Elimina todos los recursos creados durante el laboratorio
# Uso: ./cleanup.sh
##############################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 07: Troubleshooting de Deployments...${NC}"
echo

# Funcion para eliminar recurso con verificacion
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-lab-troubleshooting}

    if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
        kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

# 1. Eliminar Deployments
echo "📦 Eliminando Deployments..."
delete_resource deployment broken-image-app
delete_resource deployment broken-readiness-app
delete_resource deployment oom-app
delete_resource deployment stuck-rollout-app
delete_resource deployment selector-mismatch-app
delete_resource deployment permission-app

# 2. Eliminar namespace
echo
echo "🗂️  Eliminando namespace..."
if kubectl get namespace lab-troubleshooting &> /dev/null; then
    kubectl delete namespace lab-troubleshooting
    echo -e "  ${GREEN}✓ namespace/lab-troubleshooting eliminado${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-troubleshooting no existe (skip)${NC}"
fi

# 3. Restaurar contexto
echo
echo "🔧 Restaurando contexto..."
kubectl config set-context --current --namespace=default
echo -e "  ${GREEN}✓ Namespace por defecto restaurado a 'default'${NC}"

# 4. Verificar limpieza
echo
echo "🔍 Verificando limpieza..."

NS_EXISTS=$(kubectl get namespace lab-troubleshooting --no-headers 2>/dev/null | wc -l || true)

if [ "$NS_EXISTS" -eq 0 ]; then
    echo -e "${GREEN}✅ Limpieza completa exitosa!${NC}"
    echo
    echo "Recursos eliminados:"
    echo "  • broken-image-app"
    echo "  • broken-readiness-app"
    echo "  • oom-app"
    echo "  • stuck-rollout-app"
    echo "  • selector-mismatch-app"
    echo "  • permission-app"
    echo "  • Namespace lab-troubleshooting"
    echo "  • Contexto restaurado a default"
else
    echo -e "${RED}⚠️  El namespace lab-troubleshooting aun existe (puede estar terminando)${NC}"
fi

echo
echo -e "${GREEN}🎉 Script de limpieza completado!${NC}"
