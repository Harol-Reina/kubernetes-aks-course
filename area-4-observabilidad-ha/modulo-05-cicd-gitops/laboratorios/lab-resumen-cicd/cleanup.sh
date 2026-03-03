#!/bin/bash

##############################################################################
# Script de Limpieza - Lab Resumen: CI/CD y GitOps
#
# Descripcion: Elimina el namespace lab-cicd y restaura el contexto
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando limpieza del Lab Resumen CI/CD y GitOps...${NC}"
echo

if kubectl get namespace lab-cicd &> /dev/null; then
    kubectl delete namespace lab-cicd
    echo -e "  ${GREEN}v namespace/lab-cicd eliminado (todos los recursos incluidos)${NC}"
else
    echo -e "  ${YELLOW}! namespace/lab-cicd no existe (skip)${NC}"
fi

echo
echo -e "${YELLOW}Restaurando namespace por defecto...${NC}"
kubectl config set-context --current --namespace=default 2>/dev/null || true
echo -e "  ${GREEN}v Contexto restaurado a namespace 'default'${NC}"

echo
echo -e "${GREEN}Limpieza completada!${NC}"
