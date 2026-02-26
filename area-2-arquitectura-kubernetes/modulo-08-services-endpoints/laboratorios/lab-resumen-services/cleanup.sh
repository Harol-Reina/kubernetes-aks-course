#!/bin/bash

##############################################################################
# Script de Limpieza - Lab Resumen: Tipos de Service
#
# Descripcion: Elimina el namespace lab-services y todos sus recursos
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab Resumen Services...${NC}"
echo

if kubectl get namespace lab-services &> /dev/null; then
    kubectl delete namespace lab-services
    echo -e "  ${GREEN}✓ namespace/lab-services eliminado (todos los recursos incluidos)${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-services no existe (skip)${NC}"
fi

echo
echo -e "${GREEN}🎉 Limpieza completada!${NC}"
