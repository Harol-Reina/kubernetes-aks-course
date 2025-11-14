#!/bin/bash

set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Limpieza Lab 03: Secret Env Vars...${NC}"

# Eliminar pods
kubectl delete pod app-envfrom --ignore-not-found=true
kubectl delete pod app-selective --ignore-not-found=true
kubectl delete pod app-combined --ignore-not-found=true

# Eliminar secrets
kubectl delete secret db-config --ignore-not-found=true
kubectl delete secret smtp-config --ignore-not-found=true
kubectl delete secret api-credentials --ignore-not-found=true

# Eliminar configmap
kubectl delete configmap app-config --ignore-not-found=true

# Eliminar archivos YAML
rm -f pod-envfrom.yaml pod-env-selective.yaml pod-combined.yaml

echo -e "${GREEN}✅ Limpieza completada!${NC}"
kubectl get pods,secrets,configmaps 2>/dev/null || echo "Namespace limpio"
