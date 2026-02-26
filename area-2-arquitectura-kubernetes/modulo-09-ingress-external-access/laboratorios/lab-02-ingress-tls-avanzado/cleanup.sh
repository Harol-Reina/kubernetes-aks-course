#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Lab 02: Ingress TLS Avanzado...${NC}"

delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-default}
    if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
        kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
        echo -e "  ${GREEN}✓ $resource_type/$resource_name eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $resource_type/$resource_name no existe (skip)${NC}"
    fi
}

echo -e "\n${YELLOW}Eliminando Ingress resources...${NC}"
delete_resource ingress tls-ingress
delete_resource ingress multi-host-tls-ingress
delete_resource ingress rewrite-ingress
delete_resource ingress cors-ingress

echo -e "\n${YELLOW}Eliminando Secrets TLS...${NC}"
delete_resource secret tls-secret
delete_resource secret wildcard-tls

echo -e "\n${YELLOW}Limpiando archivos de certificados locales...${NC}"
for cert_file in tls.key tls.crt wildcard.key wildcard.crt; do
    if [ -f "$cert_file" ]; then
        rm -f "$cert_file"
        echo -e "  ${GREEN}✓ $cert_file eliminado${NC}"
    else
        echo -e "  ${YELLOW}⚠ $cert_file no existe (skip)${NC}"
    fi
done

echo -e "\n${YELLOW}Limpiando /etc/hosts...${NC}"
if grep -q "example.com" /etc/hosts 2>/dev/null; then
    sudo sed -i '/example.com/d' /etc/hosts
    echo -e "  ${GREEN}✓ Entradas example.com eliminadas de /etc/hosts${NC}"
else
    echo -e "  ${YELLOW}⚠ No hay entradas de example.com en /etc/hosts (skip)${NC}"
fi

echo -e "\n${GREEN}🎉 Limpieza del Lab 02 completada!${NC}"
