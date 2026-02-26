#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 04: Estrategia Recreate
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

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 04: Estrategia Recreate...${NC}"
echo

# Función para eliminar recurso con verificación
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-lab-recreate}

    if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
        kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

# 1. Eliminar Deployments
echo "📦 Eliminando Deployments..."
delete_resource deployment nginx-recreate
delete_resource deployment nginx-rolling

# 2. Eliminar namespace
echo
echo "🗂️  Eliminando namespace..."
if kubectl get namespace lab-recreate &> /dev/null; then
    kubectl delete namespace lab-recreate
    echo -e "  ${GREEN}✓ namespace/lab-recreate eliminado${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-recreate no existe (skip)${NC}"
fi

# 3. Restaurar contexto
echo
echo "🔧 Restaurando contexto..."
kubectl config set-context --current --namespace=default
echo -e "  ${GREEN}✓ Namespace por defecto restaurado a 'default'${NC}"

# 4. Verificar limpieza
echo
echo "🔍 Verificando limpieza..."

NS_EXISTS=$(kubectl get namespace lab-recreate --no-headers 2>/dev/null | wc -l || true)

if [ "$NS_EXISTS" -eq 0 ]; then
    echo -e "${GREEN}✅ Limpieza completa exitosa!${NC}"
    echo
    echo "Recursos eliminados:"
    echo "  • 2 Deployments (nginx-recreate, nginx-rolling)"
    echo "  • Namespace lab-recreate"
    echo "  • Contexto restaurado a default"
else
    echo -e "${RED}⚠️  El namespace lab-recreate aún existe (puede estar terminando)${NC}"
fi

echo
echo -e "${GREEN}🎉 Script de limpieza completado!${NC}"
