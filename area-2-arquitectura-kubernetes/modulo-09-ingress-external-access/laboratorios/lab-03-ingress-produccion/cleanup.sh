#!/bin/bash
echo "🧹 Limpiando Ingress y recursos..."
kubectl delete ingress --all -n default 2>/dev/null || true
kubectl delete svc --all -n default 2>/dev/null || true
kubectl delete pods --all -n default 2>/dev/null || true
echo "✅ Limpieza completada"
