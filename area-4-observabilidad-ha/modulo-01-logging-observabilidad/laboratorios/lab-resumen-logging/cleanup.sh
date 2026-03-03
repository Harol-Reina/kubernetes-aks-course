#!/bin/bash

##############################################################################
# Script de Limpieza - Lab Resumen: Logging en Kubernetes
#
# Descripcion: Elimina el namespace lab-logging y restaura el contexto
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab Resumen Logging...${NC}"
echo

if kubectl get namespace lab-logging &> /dev/null; then
    kubectl delete namespace lab-logging
    echo -e "  ${GREEN}✓ namespace/lab-logging eliminado (todos los recursos incluidos)${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-logging no existe (skip)${NC}"
fi

echo
echo -e "${YELLOW}Restaurando namespace por defecto...${NC}"
kubectl config set-context --current --namespace=default 2>/dev/null || true
echo -e "  ${GREEN}✓ Contexto restaurado a namespace 'default'${NC}"

echo
echo -e "${GREEN}🎉 Limpieza completada!${NC}"
