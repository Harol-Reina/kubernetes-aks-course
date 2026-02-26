#!/bin/bash

##############################################################################
# Script de Limpieza - Lab Resumen: Namespaces y Organizacion
#
# Descripcion: Elimina los 3 namespaces del lab y restaura el contexto
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab Resumen Namespaces...${NC}"
echo

for ns in lab-ns-dev lab-ns-staging lab-ns-prod; do
    if kubectl get namespace $ns &> /dev/null; then
        kubectl delete namespace $ns
        echo -e "  ${GREEN}✓ namespace/$ns eliminado (todos los recursos incluidos)${NC}"
    else
        echo -e "  ${YELLOW}⚠ namespace/$ns no existe (skip)${NC}"
    fi
done

echo
echo -e "${YELLOW}Restaurando namespace por defecto...${NC}"
kubectl config set-context --current --namespace=default
echo -e "  ${GREEN}✓ Contexto restaurado a namespace 'default'${NC}"

echo
echo -e "${GREEN}🎉 Limpieza completada!${NC}"
