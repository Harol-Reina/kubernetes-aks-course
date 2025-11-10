#!/bin/bash
# Crear ConfigMap desde archivos individuales

# Verificar que los archivos existen
if [ ! -f nginx.conf ] || [ ! -f index.html ]; then
    echo "❌ Error: nginx.conf o index.html no encontrados"
    exit 1
fi

# Crear ConfigMap desde archivos
kubectl create configmap nginx-config \
  --from-file=nginx.conf \
  --from-file=index.html

echo "✅ ConfigMap 'nginx-config' creado desde archivos"

# Ver el ConfigMap
echo ""
echo "📋 ConfigMap creado:"
kubectl get configmap nginx-config

# Ver las claves
echo ""
echo "📄 Claves en el ConfigMap:"
kubectl describe configmap nginx-config | grep -A2 "Data"
