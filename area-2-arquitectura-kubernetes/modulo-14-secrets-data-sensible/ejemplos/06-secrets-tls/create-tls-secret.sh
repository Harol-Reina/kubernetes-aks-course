#!/bin/bash
# Script para generar certificados TLS autofirmados y crear Secret

echo "=== Generando certificados TLS autofirmados ==="

# 1. Generar clave privada
openssl genrsa -out tls.key 2048

# 2. Generar certificado autofirmado (válido por 365 días)
openssl req -new -x509 -key tls.key -out tls.crt -days 365 \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=MyCompany/OU=IT/CN=myapp.example.com"

echo "Certificados generados: tls.key, tls.crt"
echo ""

# 3. Crear Secret TLS en Kubernetes
echo "=== Creando Secret TLS en Kubernetes ==="
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key

echo ""
echo "=== Verificando Secret ==="
kubectl get secret tls-secret
kubectl describe secret tls-secret

echo ""
echo "=== Ver Secret en YAML ==="
kubectl get secret tls-secret -o yaml

# 4. Decodificar certificado para verificar
echo ""
echo "=== Información del certificado ==="
kubectl get secret tls-secret -o jsonpath='{.data.tls\.crt}' | \
  base64 --decode | \
  openssl x509 -text -noout | \
  grep -E 'Subject:|Issuer:|Not Before|Not After|DNS:'

# Limpiar archivos locales (descomentar si deseas)
# rm tls.key tls.crt

echo ""
echo "=== Comandos para limpiar ==="
echo "kubectl delete secret tls-secret"
echo "rm tls.key tls.crt"
