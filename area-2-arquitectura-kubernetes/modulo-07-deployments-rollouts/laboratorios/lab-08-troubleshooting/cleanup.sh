#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 08: Proyecto Integrador - Deployment Completo
#
# Descripcion: Elimina todos los recursos creados durante el laboratorio.
#              El namespace ecommerce-prod contiene todos los recursos,
#              por lo que eliminarlo limpia todo de una vez.
# Uso: ./cleanup.sh
##############################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 08: Proyecto Integrador...${NC}"
echo

# Funcion para eliminar recurso con verificacion
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-ecommerce-prod}

    if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
        kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

# 1. Terminar procesos port-forward activos
echo "🔌 Terminando procesos port-forward..."
PF_PIDS=$(pgrep -f "kubectl port-forward" 2>/dev/null || true)
if [ -n "$PF_PIDS" ]; then
    kill $PF_PIDS 2>/dev/null || true
    echo -e "  ${GREEN}✓ Procesos port-forward terminados${NC}"
else
    echo -e "  ${YELLOW}⚠ No hay procesos port-forward activos (skip)${NC}"
fi

# 2. Eliminar namespace completo (elimina todos los recursos dentro)
echo
echo "🗂️  Eliminando namespace ecommerce-prod..."
if kubectl get namespace ecommerce-prod &> /dev/null; then
    kubectl delete namespace ecommerce-prod
    echo -e "  ${GREEN}✓ namespace/ecommerce-prod eliminado${NC}"
    echo -e "  ${GREEN}  (Deployments, Services, ConfigMaps, Secrets, HPAs, PDBs eliminados)${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/ecommerce-prod no existe (skip)${NC}"
fi

# 3. Restaurar contexto al namespace por defecto
echo
echo "🔧 Restaurando contexto..."
kubectl config set-context --current --namespace=default
echo -e "  ${GREEN}✓ Namespace por defecto restaurado a 'default'${NC}"

# 4. Verificar limpieza
echo
echo "🔍 Verificando limpieza..."

NS_EXISTS=$(kubectl get namespace ecommerce-prod --no-headers 2>/dev/null | wc -l || true)

if [ "$NS_EXISTS" -eq 0 ]; then
    echo -e "${GREEN}✅ Limpieza completa exitosa!${NC}"
    echo
    echo "Recursos eliminados:"
    echo "  • Namespace ecommerce-prod"
    echo "  • Deployments: frontend-web, frontend-web-green, product-service, order-service"
    echo "  • Services: frontend-service, frontend-green-test, product-service, order-service"
    echo "  • ConfigMap: frontend-config"
    echo "  • Secret: frontend-secrets"
    echo "  • HPA: frontend-hpa"
    echo "  • PDBs: frontend-pdb, product-service-pdb, order-service-pdb"
    echo "  • Contexto restaurado a default"
else
    echo -e "${RED}⚠️  El namespace ecommerce-prod aun existe (puede estar terminando)${NC}"
    echo -e "${YELLOW}   Ejecuta: kubectl get namespace ecommerce-prod${NC}"
fi

echo
echo -e "${GREEN}🎉 Script de limpieza completado!${NC}"
