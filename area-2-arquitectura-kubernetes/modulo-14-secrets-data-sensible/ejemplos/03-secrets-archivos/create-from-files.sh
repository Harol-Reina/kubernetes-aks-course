#!/bin/bash
# Script para crear Secrets desde archivos

# 1. Crear Secret desde un solo archivo
# La clave será el nombre del archivo (credentials.txt)
kubectl create secret generic file-secret \
  --from-file=credentials.txt

echo "Secret 'file-secret' creado desde credentials.txt"

# 2. Crear Secret desde archivo con nombre de clave personalizado
kubectl create secret generic custom-key-secret \
  --from-file=db-credentials=credentials.txt \
  --from-file=token=api-token.txt

echo "Secret 'custom-key-secret' creado con claves personalizadas"

# 3. Crear Secret desde múltiples archivos
kubectl create secret generic multi-file-secret \
  --from-file=credentials.txt \
  --from-file=api-token.txt

echo "Secret 'multi-file-secret' creado desde múltiples archivos"

# 4. Crear Secret desde un directorio completo
# (Todos los archivos del directorio se incluirán)
# kubectl create secret generic dir-secret \
#   --from-file=./secret-files/

# 5. Verificar Secrets creados
echo -e "\n=== Secrets creados ==="
kubectl get secrets | grep -E 'file-secret|custom-key-secret|multi-file-secret'

# 6. Ver contenido de un Secret
echo -e "\n=== Contenido de custom-key-secret ==="
kubectl get secret custom-key-secret -o yaml

# 7. Decodificar contenido del archivo
echo -e "\n=== Contenido decodificado de db-credentials ==="
kubectl get secret custom-key-secret -o jsonpath='{.data.db-credentials}' | base64 --decode
echo ""

echo -e "\n=== Contenido decodificado de token ==="
kubectl get secret custom-key-secret -o jsonpath='{.data.token}' | base64 --decode
echo ""

# 8. Limpiar (descomentar para eliminar)
# kubectl delete secret file-secret custom-key-secret multi-file-secret
