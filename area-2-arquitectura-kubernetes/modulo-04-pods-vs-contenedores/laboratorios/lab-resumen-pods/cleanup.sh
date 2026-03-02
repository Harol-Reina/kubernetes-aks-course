#!/bin/bash

##############################################################################
# Script de Limpieza - Lab Resumen: Pods vs Contenedores
#
# Descripcion: Elimina el namespace lab-pods-test y todos sus recursos
#              (Pods multi-container, sidecar, init, shared-pid, test-pod).
#              Restaura el namespace por defecto en el contexto activo.
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Limpieza del Lab Resumen: Pods vs Contenedores...${NC}"
echo

if kubectl get namespace lab-pods-test &> /dev/null; then
    kubectl delete namespace lab-pods-test
    echo -e "  ${GREEN}✓ namespace/lab-pods-test eliminado (todos los Pods incluidos)${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-pods-test no existe (skip)${NC}"
fi

echo
echo -e "${YELLOW}Restaurando namespace por defecto...${NC}"
kubectl config set-context --current --namespace=default 2>/dev/null || true
echo -e "  ${GREEN}✓ Contexto restaurado a namespace 'default'${NC}"

echo
echo -e "${GREEN}🎉 Limpieza completada!${NC}"
