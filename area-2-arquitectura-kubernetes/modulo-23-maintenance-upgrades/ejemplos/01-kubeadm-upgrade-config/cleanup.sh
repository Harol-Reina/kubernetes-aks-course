#!/bin/bash
echo "ℹ️  Este ejemplo contiene archivos de configuración/documentación"
if [ -f *.yaml ]; then
  echo "Limpiando recursos K8s si existen..."
  kubectl delete -f . 2>/dev/null || echo "No hay recursos para eliminar"
fi
echo "✅ Revisión completada"
