#!/bin/bash

##############################################################################
# Script de Limpieza - Lab Resumen: Troubleshooting Avanzado
#
# Descripcion: Elimina el namespace lab-troubleshooting-avanzado y todos
#              sus recursos (Pods, Deployments, ConfigMaps).
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab Resumen: Troubleshooting Avanzado...${NC}"
echo

if kubectl get namespace lab-troubleshooting-avanzado &> /dev/null; then
    kubectl delete namespace lab-troubleshooting-avanzado
    echo -e "  ${GREEN}✓ namespace/lab-troubleshooting-avanzado eliminado (todos los recursos incluidos)${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-troubleshooting-avanzado no existe (skip)${NC}"
fi

# Restaurar contexto al namespace por defecto
kubectl config set-context --current --namespace=default 2>/dev/null || true

echo
echo -e "${GREEN}🎉 Limpieza completada!${NC}"
