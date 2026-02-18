#!/bin/bash
# safe-rollback.sh - Rollback automático si se detectan errores

DEPLOYMENT=$1
NAMESPACE=${2:-default}

if [ -z "$DEPLOYMENT" ]; then
  echo "Uso: ./safe-rollback.sh <deployment> [namespace]"
  exit 1
fi

echo "Verificando estado de $DEPLOYMENT en namespace $NAMESPACE..."

# Verificar si hay Pods con errores
ERROR_PODS=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT \
  -o jsonpath='{.items[?(@.status.phase!="Running")].metadata.name}')

if [ -n "$ERROR_PODS" ]; then
  echo "⚠️  Pods con errores detectados:"
  echo "$ERROR_PODS"
  echo ""
  echo "Ejecutando rollback..."
  kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE
  kubectl annotate deployment/$DEPLOYMENT -n $NAMESPACE \
    kubernetes.io/change-cause="EMERGENCY ROLLBACK - $(date +%Y-%m-%d_%H:%M:%S)" --overwrite
  echo "✅ Rollback completado"
else
  echo "✅ No hay errores, Deployment saludable"
fi
