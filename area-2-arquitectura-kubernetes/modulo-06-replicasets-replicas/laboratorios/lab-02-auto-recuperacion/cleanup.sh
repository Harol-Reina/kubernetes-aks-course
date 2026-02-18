#!/bin/bash
echo "🧹 Limpiando ReplicaSets y Pods..."
kubectl delete rs --all -n default 2>/dev/null || true
kubectl delete pods --all -n default 2>/dev/null || true
echo "✅ Limpieza completada"
