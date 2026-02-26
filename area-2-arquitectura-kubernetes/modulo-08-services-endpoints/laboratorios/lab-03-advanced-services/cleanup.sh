#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 03: Services Avanzados
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

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 03: Services Avanzados...${NC}"
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

# 1. Eliminar namespace production (borra todo dentro)
echo "🗂️  Eliminando namespace production..."
if kubectl get namespace production &> /dev/null; then
    kubectl delete namespace production
    echo -e "  ${GREEN}✓ namespace/production eliminado${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/production no existe (skip)${NC}"
fi

# 2. Eliminar StatefulSet y Headless Service
echo
echo "📦 Eliminando StatefulSet MySQL..."
delete_resource statefulset mysql
delete_resource service mysql-headless

# 3. Eliminar ExternalName y migration Services
echo
echo "🌐 Eliminando Services..."
delete_resource service external-api
delete_resource service database
delete_resource service external-database

# 4. Eliminar Endpoints manuales
echo
echo "🔗 Eliminando Endpoints..."
delete_resource endpoints external-database

# 5. Eliminar Deployments
echo
echo "📦 Eliminando Deployments..."
delete_resource deployment backend-app
delete_resource deployment app-external-db

# 6. Eliminar Secrets
echo
echo "🔑 Eliminando Secrets..."
delete_resource secret mysql-secret

# 7. Eliminar PVCs de MySQL
echo
echo "💾 Eliminando PVCs..."
for i in 0 1 2; do
    delete_resource pvc "data-mysql-$i"
done

echo
echo -e "${GREEN}🎉 Limpieza del Lab 03 completada!${NC}"
