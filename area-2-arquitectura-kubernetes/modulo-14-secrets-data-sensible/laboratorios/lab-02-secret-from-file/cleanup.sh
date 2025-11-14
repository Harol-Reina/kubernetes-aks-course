#!/bin/bash

set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Limpieza Lab 02: Secret from File...${NC}"

# Eliminar pod
kubectl delete pod nginx-https --ignore-not-found=true
echo -e "${GREEN}✓ Pod eliminado${NC}"

# Eliminar secrets
kubectl delete secret tls-cert --ignore-not-found=true
kubectl delete secret tls-keypair --ignore-not-found=true
kubectl delete secret nginx-config --ignore-not-found=true
kubectl delete secret app-cert --ignore-not-found=true
echo -e "${GREEN}✓ Secrets eliminados${NC}"

# Eliminar archivos locales
cd ~/k8s-labs/lab-secrets-files 2>/dev/null || true
rm -f tls.key tls.crt nginx.conf README.txt nginx-https.yaml

echo -e "${GREEN}✅ Limpieza completada!${NC}"
