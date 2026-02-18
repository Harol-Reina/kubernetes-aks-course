#!/bin/bash
echo "🧹 Limpiando namespaces y recursos..."
kubectl delete ns test-namespace 2>/dev/null || true
kubectl delete ns dev prod qa 2>/dev/null || true
echo "✅ Limpieza completada"
