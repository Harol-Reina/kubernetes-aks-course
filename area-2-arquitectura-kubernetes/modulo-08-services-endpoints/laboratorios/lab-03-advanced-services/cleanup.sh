#!/bin/bash
echo "🧹 Limpiando Services y Endpoints..."
kubectl delete svc --all -n default 2>/dev/null || true
kubectl delete pods --all -n default 2>/dev/null || true
echo "✅ Limpieza completada"
