#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 02: Rolling Updates y Estrategias de Despliegue
#
# Descripción: Elimina todos los recursos creados durante el laboratorio
# Uso: ./cleanup.sh
##############################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 02: Rolling Updates...${NC}"
echo

# Función para eliminar recurso con verificación
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-lab-rolling-updates}

    if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
        kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

# 1. Eliminar Deployments
echo "📦 Eliminando Deployments..."
delete_resource deployment rolling-demo
delete_resource deployment rolling-ha
delete_resource deployment rolling-fast
delete_resource deployment recreate-demo
delete_resource deployment pause-demo
delete_resource deployment challenge-app

# 2. Eliminar namespace
echo
echo "🗂️  Eliminando namespace..."
if kubectl get namespace lab-rolling-updates &> /dev/null; then
    kubectl delete namespace lab-rolling-updates
    echo -e "  ${GREEN}✓ namespace/lab-rolling-updates eliminado${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-rolling-updates no existe (skip)${NC}"
fi

# 3. Restaurar contexto
echo
echo "🔧 Restaurando contexto..."
kubectl config set-context --current --namespace=default
echo -e "  ${GREEN}✓ Namespace por defecto restaurado a 'default'${NC}"

# 4. Verificar limpieza
echo
echo "🔍 Verificando limpieza..."

NS_EXISTS=$(kubectl get namespace lab-rolling-updates --no-headers 2>/dev/null | wc -l || true)

if [ "$NS_EXISTS" -eq 0 ]; then
    echo -e "${GREEN}✅ Limpieza completa exitosa!${NC}"
    echo
    echo "Recursos eliminados:"
    echo "  • 6 Deployments (rolling-demo, rolling-ha, rolling-fast, recreate-demo, pause-demo, challenge-app)"
    echo "  • Namespace lab-rolling-updates"
    echo "  • Contexto restaurado a default"
else
    echo -e "${RED}⚠️  El namespace lab-rolling-updates aún existe (puede estar terminando)${NC}"
fi

echo
echo -e "${GREEN}🎉 Script de limpieza completado!${NC}"
