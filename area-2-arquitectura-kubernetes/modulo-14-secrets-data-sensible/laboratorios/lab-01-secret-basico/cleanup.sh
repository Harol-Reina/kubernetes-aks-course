#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 01: Secret Básico
# 
# Descripción: Elimina todos los recursos creados durante el laboratorio
# Uso: ./cleanup.sh
##############################################################################

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 01: Secret Básico...${NC}"
echo

# Función para eliminar recurso con verificación
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    
    if kubectl get $resource_type $resource_name &> /dev/null; then
        echo -e "  ${YELLOW}Eliminando $resource_type/$resource_name...${NC}"
        kubectl delete $resource_type $resource_name --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

# 1. Eliminar Pods
echo "📦 Eliminando Pods..."
delete_resource pod app-with-db

# 2. Eliminar Secrets
echo
echo "🔒 Eliminando Secrets..."
delete_resource secret db-credentials
delete_resource secret db-credentials-yaml

# 3. Eliminar archivos YAML locales
echo
echo "📄 Eliminando archivos YAML locales..."
if [ -f "pod-with-secret.yaml" ]; then
    rm -f pod-with-secret.yaml
    echo -e "  ${GREEN}✓ pod-with-secret.yaml eliminado${NC}"
fi

if [ -f "db-secret.yaml" ]; then
    rm -f db-secret.yaml
    echo -e "  ${GREEN}✓ db-secret.yaml eliminado${NC}"
fi

# 4. Verificar limpieza
echo
echo "🔍 Verificando limpieza..."
echo

PODS_COUNT=$(kubectl get pods --no-headers 2>/dev/null | grep -c "app-with-db" || true)
SECRETS_COUNT=$(kubectl get secrets --no-headers 2>/dev/null | grep -c "db-credentials" || true)

if [ "$PODS_COUNT" -eq 0 ] && [ "$SECRETS_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ Limpieza completa exitosa!${NC}"
    echo
    echo "Recursos eliminados:"
    echo "  • 1 Pod (app-with-db)"
    echo "  • 2 Secrets (db-credentials, db-credentials-yaml)"
    echo "  • Archivos YAML locales"
else
    echo -e "${RED}⚠️  Algunos recursos aún existen:${NC}"
    [ "$PODS_COUNT" -gt 0 ] && echo "  - Pods: $PODS_COUNT"
    [ "$SECRETS_COUNT" -gt 0 ] && echo "  - Secrets: $SECRETS_COUNT"
fi

echo
echo -e "${YELLOW}Estado final del namespace:${NC}"
kubectl get pods,secrets 2>/dev/null || echo "  (namespace vacío)"

echo
echo -e "${GREEN}🎉 Script de limpieza completado!${NC}"
