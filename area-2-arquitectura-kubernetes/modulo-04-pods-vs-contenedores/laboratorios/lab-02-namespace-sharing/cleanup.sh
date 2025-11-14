#!/bin/bash
echo "🧹 Limpiando Pods..."
kubectl delete pods --all -n default 2>/dev/null || true
echo "✅ Limpieza completada"
