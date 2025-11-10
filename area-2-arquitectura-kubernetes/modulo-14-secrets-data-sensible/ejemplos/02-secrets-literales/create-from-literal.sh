#!/bin/bash
# Script para crear Secrets desde literales usando kubectl create

# 1. Secret simple con una sola clave-valor
kubectl create secret generic simple-secret \
  --from-literal=api-key='abc123xyz789'

# 2. Secret con múltiples claves-valor
kubectl create secret generic multi-secret \
  --from-literal=username='admin' \
  --from-literal=password='SecureP@ss!' \
  --from-literal=database='production' \
  --from-literal=port='5432'

# 3. Secret con caracteres especiales (usar comillas)
kubectl create secret generic special-chars-secret \
  --from-literal=token='Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  --from-literal=url='https://api.example.com/v1?key=value&token=abc'

# 4. Verificar Secrets creados
echo "Secrets creados:"
kubectl get secrets | grep -E 'simple-secret|multi-secret|special-chars-secret'

# 5. Ver detalles de un Secret (sin mostrar valores)
echo -e "\nDetalles de multi-secret:"
kubectl describe secret multi-secret

# 6. Ver Secret completo (valores en Base64)
echo -e "\nSecret multi-secret en YAML:"
kubectl get secret multi-secret -o yaml

# 7. Decodificar un valor específico
echo -e "\nValor decodificado de 'password':"
kubectl get secret multi-secret -o jsonpath='{.data.password}' | base64 --decode
echo ""

# 8. Limpiar (descomentar para eliminar)
# kubectl delete secret simple-secret multi-secret special-chars-secret
