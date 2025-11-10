#!/bin/bash
# Script para crear Secret de tipo docker-registry

echo "=== Creando Secret para Docker Registry Privado ==="

# Opción 1: Usando kubectl create (recomendado)
kubectl create secret docker-registry my-registry-secret \
  --docker-server=myregistry.example.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=user@example.com

echo ""
echo "Secret 'my-registry-secret' creado"
echo ""

# Verificar Secret
echo "=== Detalles del Secret ==="
kubectl get secret my-registry-secret
kubectl describe secret my-registry-secret

echo ""
echo "=== Contenido del Secret (Base64) ==="
kubectl get secret my-registry-secret -o yaml

echo ""
echo "=== Decodificar .dockerconfigjson ==="
kubectl get secret my-registry-secret -o jsonpath='{.data.\.dockerconfigjson}' | \
  base64 --decode | jq '.'

# Opción 2: Crear desde archivo ~/.docker/config.json existente
echo ""
echo "=== Alternativa: Crear desde ~/.docker/config.json ==="
echo "kubectl create secret generic regcred \\"
echo "  --from-file=.dockerconfigjson=\$HOME/.docker/config.json \\"
echo "  --type=kubernetes.io/dockerconfigjson"

echo ""
echo "=== Comando para limpiar ==="
echo "kubectl delete secret my-registry-secret"
