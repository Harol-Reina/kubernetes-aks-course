#!/bin/bash
echo "🧹 Limpiando recursos..."
kubectl delete -f . 2>/dev/null || echo "  - No hay recursos para eliminar"
echo "✅ Limpieza completada"
