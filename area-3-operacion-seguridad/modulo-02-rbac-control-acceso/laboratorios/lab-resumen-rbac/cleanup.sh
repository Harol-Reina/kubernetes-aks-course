#!/bin/bash

##############################################################################
# Script de Limpieza - Lab Resumen: RBAC y Control de Acceso
#
# Descripcion: Elimina namespace lab-rbac, ClusterRole y ClusterRoleBinding
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab Resumen RBAC...${NC}"
echo

# Eliminar namespace (elimina todos los recursos namespaced dentro)
if kubectl get namespace lab-rbac &> /dev/null; then
    kubectl delete namespace lab-rbac
    echo -e "  ${GREEN}✓ namespace/lab-rbac eliminado (todos los recursos incluidos)${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-rbac no existe (skip)${NC}"
fi

# Eliminar recursos cluster-scoped (no se eliminan con el namespace)
kubectl delete clusterrole auditor-global --ignore-not-found=true 2>/dev/null
echo -e "  ${GREEN}✓ clusterrole/auditor-global eliminado${NC}"

kubectl delete clusterrolebinding auditor-acceso-global --ignore-not-found=true 2>/dev/null
echo -e "  ${GREEN}✓ clusterrolebinding/auditor-acceso-global eliminado${NC}"

echo
echo -e "${YELLOW}Restaurando namespace por defecto...${NC}"
kubectl config set-context --current --namespace=default 2>/dev/null || true
echo -e "  ${GREEN}✓ Contexto restaurado a namespace 'default'${NC}"

echo
echo -e "${GREEN}🎉 Limpieza completada!${NC}"
