#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Iniciando limpieza del Ejemplo 03: Escalado...${NC}"

kubectl delete deployment webapp-escalable --ignore-not-found=true 2>/dev/null
kubectl delete hpa webapp-hpa --ignore-not-found=true 2>/dev/null
kubectl delete service webapp-escalable --ignore-not-found=true 2>/dev/null
echo -e "  ${GREEN}✓ Recursos de escalado eliminados${NC}"

echo -e "\n${GREEN}🎉 Limpieza completada!${NC}"
