#!/bin/bash

##############################################################################
# Script de Limpieza - Lab 03: Resource Limits en Produccion
#
# Descripcion: Elimina todos los recursos creados durante el laboratorio.
#              La eliminacion del namespace production en cascada elimina
#              todos los recursos dentro de el (Pods, Deployments, Services,
#              HPAs, VPAs, CronJobs, StatefulSets, ServiceAccounts).
# Uso: ./cleanup.sh
##############################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 03: Resource Limits en Produccion...${NC}"
echo

# Funcion para eliminar recurso con verificacion
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-""}

    if [ -n "$namespace" ]; then
        if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
            kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
            echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado (ns: $namespace)${NC}"
        else
            echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe en $namespace (skip)${NC}"
        fi
    else
        if kubectl get $resource_type $resource_name &> /dev/null; then
            kubectl delete $resource_type $resource_name --ignore-not-found=true
            echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
        else
            echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
        fi
    fi
}

# 1. Eliminar namespace production (cascade: elimina todos los recursos dentro)
echo "🗂️  Eliminando namespace production (cascade)..."
if kubectl get namespace production &> /dev/null; then
    kubectl delete namespace production --ignore-not-found=true
    echo -e "  ${GREEN}✓ namespace/production eliminado (incluye todos sus recursos)${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/production no existe (skip)${NC}"
fi

echo

# 2. Eliminar PriorityClass (recurso cluster-scoped, no pertenece al namespace)
echo "⚡ Eliminando PriorityClass cluster-scoped..."
delete_resource priorityclass high-priority

echo

# 3. Eliminar Pod de generacion de carga si existe en namespace default
echo "📦 Eliminando Pod de load-generator si existe..."
if kubectl get pod load-generator &> /dev/null; then
    kubectl delete pod load-generator --ignore-not-found=true
    echo -e "  ${GREEN}✓ pod/load-generator eliminado del namespace default${NC}"
else
    echo -e "  ${YELLOW}⚠ pod/load-generator no existe en default (skip)${NC}"
fi

echo

# 4. Notas sobre componentes opcionales
echo -e "${YELLOW}📝 Limpieza de componentes opcionales (si los instalaste):${NC}"
echo
echo "  VPA (Vertical Pod Autoscaler):"
echo "    cd autoscaler/vertical-pod-autoscaler"
echo "    ./hack/vpa-down.sh"
echo
echo "  Prometheus (instalado con Helm):"
echo "    helm uninstall prometheus -n monitoring"
echo "    kubectl delete namespace monitoring"
echo

echo -e "${GREEN}🎉 Limpieza del Lab 03 completada!${NC}"
