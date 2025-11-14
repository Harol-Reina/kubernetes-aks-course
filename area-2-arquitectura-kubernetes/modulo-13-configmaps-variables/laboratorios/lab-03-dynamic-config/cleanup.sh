#!/bin/bash
echo "🧹 Limpiando ConfigMaps y Pods..."
kubectl delete configmap --all -n default 2>/dev/null || true
kubectl delete pods --all -n default 2>/dev/null || true
echo "✅ Limpieza completada"
