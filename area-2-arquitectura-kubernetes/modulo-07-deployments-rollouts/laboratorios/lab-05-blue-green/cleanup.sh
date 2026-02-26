#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 05: Estrategias Blue-Green y Canary
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

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 05: Estrategias Blue-Green y Canary...${NC}"
echo

# Funcion para eliminar recurso con verificacion
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-lab-estrategias}

    if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
        kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

# 1. Eliminar Deployments
echo "📦 Eliminando Deployments..."
delete_resource deployment app-blue
delete_resource deployment app-green
delete_resource deployment app-stable
delete_resource deployment app-canary
delete_resource deployment app-v1
delete_resource deployment app-v2
delete_resource deployment app-stable-health
delete_resource deployment app-canary-failing

# 2. Eliminar Services
echo
echo "🌐 Eliminando Services..."
delete_resource service app-production
delete_resource service app-green-test
delete_resource service app-canary-service
delete_resource service weighted-app-service
delete_resource service health-app-service

# 3. Eliminar namespace
echo
echo "🗂️  Eliminando namespace..."
if kubectl get namespace lab-estrategias &> /dev/null; then
    kubectl delete namespace lab-estrategias
    echo -e "  ${GREEN}✓ namespace/lab-estrategias eliminado${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-estrategias no existe (skip)${NC}"
fi

# 4. Restaurar contexto
echo
echo "🔧 Restaurando contexto..."
kubectl config set-context --current --namespace=default
echo -e "  ${GREEN}✓ Namespace por defecto restaurado a 'default'${NC}"

# 5. Verificar limpieza
echo
echo "🔍 Verificando limpieza..."

NS_EXISTS=$(kubectl get namespace lab-estrategias --no-headers 2>/dev/null | wc -l || true)

if [ "$NS_EXISTS" -eq 0 ]; then
    echo -e "${GREEN}✅ Limpieza completa exitosa!${NC}"
    echo
    echo "Recursos eliminados:"
    echo "  • Deployments: app-blue, app-green, app-stable, app-canary"
    echo "  • Deployments: app-v1, app-v2, app-stable-health, app-canary-failing"
    echo "  • Services: app-production, app-green-test, app-canary-service"
    echo "  • Services: weighted-app-service, health-app-service"
    echo "  • Namespace: lab-estrategias"
    echo "  • Contexto restaurado a default"
else
    echo -e "${RED}⚠️  El namespace lab-estrategias aun existe (puede estar terminando)${NC}"
fi

echo
echo -e "${GREEN}🎉 Script de limpieza completado!${NC}"
