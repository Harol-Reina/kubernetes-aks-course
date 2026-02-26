#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 06: Best Practices en Production
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

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 06: Best Practices en Production...${NC}"
echo

# Función para eliminar recurso con verificación
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-lab-production}

    if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
        kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

# 1. Eliminar HPA (antes del Deployment para evitar conflictos de escalado)
echo "📈 Eliminando HorizontalPodAutoscaler..."
delete_resource hpa webapp-hpa

# 2. Eliminar PodDisruptionBudgets
echo
echo "🛡️  Eliminando PodDisruptionBudgets..."
delete_resource pdb webapp-pdb
delete_resource pdb webapp-pdb-percentage

# 3. Eliminar NetworkPolicies
echo
echo "🔒 Eliminando NetworkPolicies..."
delete_resource networkpolicy webapp-network-policy

# 4. Eliminar Deployments
echo
echo "📦 Eliminando Deployments..."
delete_resource deployment webapp-prod
delete_resource deployment webapp-with-config

# 5. Eliminar Services
echo
echo "🌐 Eliminando Services..."
delete_resource service webapp-service

# 6. Eliminar ConfigMaps
echo
echo "⚙️  Eliminando ConfigMaps..."
delete_resource configmap webapp-config

# 7. Eliminar namespace (incluye cualquier recurso restante)
echo
echo "🗂️  Eliminando namespace..."
if kubectl get namespace lab-production &> /dev/null; then
    kubectl delete namespace lab-production
    echo -e "  ${GREEN}✓ namespace/lab-production eliminado${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-production no existe (skip)${NC}"
fi

# 8. Restaurar contexto al namespace default
echo
echo "🔧 Restaurando contexto..."
kubectl config set-context --current --namespace=default
echo -e "  ${GREEN}✓ Namespace por defecto restaurado a 'default'${NC}"

# 9. Verificar limpieza
echo
echo "🔍 Verificando limpieza..."

NS_EXISTS=$(kubectl get namespace lab-production --no-headers 2>/dev/null | wc -l || true)

if [ "$NS_EXISTS" -eq 0 ]; then
    echo -e "${GREEN}✅ Limpieza completa exitosa!${NC}"
    echo
    echo "Recursos eliminados:"
    echo "  • HPA: webapp-hpa"
    echo "  • PDBs: webapp-pdb, webapp-pdb-percentage"
    echo "  • NetworkPolicy: webapp-network-policy"
    echo "  • Deployments: webapp-prod, webapp-with-config"
    echo "  • Service: webapp-service"
    echo "  • ConfigMap: webapp-config"
    echo "  • Namespace: lab-production"
    echo "  • Contexto restaurado a default"
else
    echo -e "${RED}⚠️  El namespace lab-production aún existe (puede estar terminando)${NC}"
fi

echo
echo -e "${GREEN}🎉 Script de limpieza completado!${NC}"
