#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NAMESPACE="lab-arquitectura-test"

echo -e "${YELLOW}Iniciando limpieza del Lab Resumen: Arquitectura del Cluster...${NC}"
echo

# Eliminar namespace completo (elimina todos los recursos dentro)
if kubectl get namespace $NAMESPACE &>/dev/null; then
    echo "Eliminando namespace $NAMESPACE y todos sus recursos..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    echo -e "  ${GREEN}namespace/$NAMESPACE eliminado${NC}"
else
    echo -e "  ${YELLOW}namespace/$NAMESPACE no existe (skip)${NC}"
fi

echo
echo -e "${GREEN}Limpieza del Lab Resumen de Arquitectura completada!${NC}"
