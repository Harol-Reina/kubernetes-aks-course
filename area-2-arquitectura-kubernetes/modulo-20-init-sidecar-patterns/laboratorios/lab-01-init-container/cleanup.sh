#!/bin/bash
echo "🧹 Limpiando Pods y recursos..."
kubectl delete pods --all -n default 2>/dev/null || true
kubectl delete deploy --all -n default 2>/dev/null || true
echo "✅ Limpieza completada"
