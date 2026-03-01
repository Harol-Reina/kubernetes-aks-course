#!/bin/bash

##############################################################################
# Script de Limpieza - Lab Resumen: Cluster Setup con kubeadm
#
# Descripcion: Elimina el namespace lab-kubeadm-test y todos sus recursos
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab Resumen kubeadm...${NC}"
echo

if kubectl get namespace lab-kubeadm-test &> /dev/null; then
    kubectl delete namespace lab-kubeadm-test
    echo -e "  ${GREEN}✓ namespace/lab-kubeadm-test eliminado (todos los recursos incluidos)${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-kubeadm-test no existe (skip)${NC}"
fi

# Restaurar contexto
kubectl config set-context --current --namespace=default 2>/dev/null || true

echo
echo -e "${GREEN}🎉 Limpieza completada!${NC}"
