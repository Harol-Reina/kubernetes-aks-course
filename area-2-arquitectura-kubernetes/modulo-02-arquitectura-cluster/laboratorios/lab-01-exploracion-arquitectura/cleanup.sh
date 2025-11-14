#!/bin/bash
echo "🧹 Limpiando recursos de Kubernetes..."

# Eliminar recursos creados en el laboratorio
kubectl delete all --all -n default 2>/dev/null || true

echo "✅ Limpieza completada"
