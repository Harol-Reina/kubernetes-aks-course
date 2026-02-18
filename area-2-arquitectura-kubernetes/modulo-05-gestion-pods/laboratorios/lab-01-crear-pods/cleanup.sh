#!/bin/bash

# cleanup.sh - Lab 01: Crear Pods
# Limpia todos los recursos creados durante el laboratorio

echo "🧹 Limpiando recursos del Lab 01: Crear Pods..."

# Eliminar todos los pods creados en el lab
echo "Eliminando pods..."
kubectl delete pod mi-primer-pod 2>/dev/null || echo "  - mi-primer-pod no existe"
kubectl delete pod nginx-pod 2>/dev/null || echo "  - nginx-pod no existe"
kubectl delete pod pod-con-recursos 2>/dev/null || echo "  - pod-con-recursos no existe"
kubectl delete pod pod-variables 2>/dev/null || echo "  - pod-variables no existe"

# Eliminar pods por label si se crearon con ese método
kubectl delete pods -l lab=lab-01-crear-pods 2>/dev/null

# Limpiar namespace dedicado si se creó
read -p "¿Eliminar namespace 'lab-pods' si existe? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    kubectl delete namespace lab-pods 2>/dev/null && echo "✅ Namespace eliminado" || echo "  - Namespace no existe"
fi

echo ""
echo "✅ Limpieza completada"
echo "Verificando estado final..."
kubectl get pods 2>/dev/null | grep -E "mi-primer-pod|nginx-pod|pod-con-recursos|pod-variables" || echo "✓ No quedan pods del lab"
