#!/bin/bash

##############################################################################
# Script de Limpieza - Lab Resumen: Kubernetes Secrets y Azure Key Vault
#
# Descripcion: Elimina el namespace lab-key-vault y todos sus recursos
#              (Secrets, ConfigMap, Pods, ServiceAccount).
#              Restaura el contexto de kubectl al namespace default.
#
# Uso: chmod +x cleanup.sh && ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando limpieza del Lab Resumen: Kubernetes Secrets y Key Vault...${NC}"
echo

# Eliminar el namespace completo (incluye todos los recursos dentro)
if kubectl get namespace lab-key-vault &> /dev/null; then
    echo -e "  Eliminando namespace lab-key-vault y todos sus recursos..."
    kubectl delete namespace lab-key-vault
    echo -e "  ${GREEN}namespace/lab-key-vault eliminado (Secrets, ConfigMap, Pods, ServiceAccount incluidos)${NC}"
else
    echo -e "  ${YELLOW}namespace/lab-key-vault no existe (skip)${NC}"
fi

echo

# Restaurar el contexto de kubectl al namespace default
echo -e "  Restaurando contexto al namespace default..."
kubectl config set-context --current --namespace=default &> /dev/null && \
    echo -e "  ${GREEN}Contexto restaurado a namespace: default${NC}" || \
    echo -e "  ${YELLOW}No se pudo restaurar el contexto (no es critico)${NC}"

echo
echo -e "${GREEN}Limpieza completada!${NC}"
echo -e "  Recursos eliminados:"
echo -e "    - namespace/lab-key-vault"
echo -e "    - Secret/db-credentials"
echo -e "    - Secret/api-credentials"
echo -e "    - Secret/registry-credentials"
echo -e "    - Secret/app-tls-cert"
echo -e "    - ConfigMap/app-config"
echo -e "    - Pod/pod-secret-volume"
echo -e "    - Pod/pod-secret-env"
echo -e "    - Pod/pod-configmap-compare"
echo -e "    - ServiceAccount/app-service-account"
