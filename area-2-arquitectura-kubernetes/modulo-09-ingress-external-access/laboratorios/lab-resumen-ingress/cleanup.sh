#!/bin/bash

##############################################################################
# Script de Limpieza - Lab Resumen: Patrones de Ingress
#
# Descripcion: Elimina el namespace lab-ingress, certificados TLS
#              temporales, y entradas de /etc/hosts del laboratorio
# Uso: ./cleanup.sh
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab Resumen Ingress...${NC}"
echo

# Eliminar namespace (borra todos los recursos del lab)
if kubectl get namespace lab-ingress &> /dev/null; then
    kubectl delete namespace lab-ingress
    echo -e "  ${GREEN}✓ namespace/lab-ingress eliminado (todos los recursos incluidos)${NC}"
else
    echo -e "  ${YELLOW}⚠ namespace/lab-ingress no existe (skip)${NC}"
fi

# Limpiar certificados TLS temporales
echo
echo -e "${YELLOW}Limpiando certificados temporales...${NC}"
for cert_file in /tmp/tls.key /tmp/tls.crt; do
    if [ -f "$cert_file" ]; then
        rm -f "$cert_file"
        echo -e "  ${GREEN}✓ $cert_file eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $cert_file no existe (skip)${NC}"
    fi
done

# Limpiar /etc/hosts
echo
echo -e "${YELLOW}Limpiando /etc/hosts...${NC}"
if grep -q "\.lab" /etc/hosts 2>/dev/null; then
    sudo sed -i '/\.lab$/d' /etc/hosts
    echo -e "  ${GREEN}✓ Entradas .lab eliminadas de /etc/hosts${NC}"
else
    echo -e "  ${YELLOW}⚠ No hay entradas .lab en /etc/hosts (skip)${NC}"
fi

echo
echo -e "${GREEN}🎉 Limpieza completada!${NC}"
