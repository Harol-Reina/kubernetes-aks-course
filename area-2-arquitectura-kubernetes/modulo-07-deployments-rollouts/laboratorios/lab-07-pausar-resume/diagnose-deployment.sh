#!/bin/bash
# diagnose-deployment.sh - Script de diagnóstico de deployments

DEPLOYMENT=$1
NAMESPACE=${2:-default}

if [ -z "$DEPLOYMENT" ]; then
    echo "Uso: $0 <deployment-name> [namespace]"
    exit 1
fi

echo "🔍 DIAGNÓSTICO DE DEPLOYMENT: $DEPLOYMENT"
echo "Namespace: $NAMESPACE"
echo "================================================"
echo ""

# 1. Estado del Deployment
echo "📊 ESTADO DEL DEPLOYMENT:"
kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o wide
echo ""

# 2. ReplicaSets
echo "📦 REPLICASETS:"
kubectl get rs -l app=$DEPLOYMENT -n $NAMESPACE
echo ""

# 3. Pods
echo "🔴 PODS:"
kubectl get pods -l app=$DEPLOYMENT -n $NAMESPACE -o wide
echo ""

# 4. Pods con problemas
echo "⚠️  PODS CON PROBLEMAS:"
kubectl get pods -l app=$DEPLOYMENT -n $NAMESPACE --field-selector status.phase!=Running
echo ""

# 5. Eventos recientes
echo "📋 EVENTOS RECIENTES (últimos 10):"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | grep $DEPLOYMENT | tail -10
echo ""

# 6. Describir deployment
echo "📝 DETALLES DEL DEPLOYMENT:"
kubectl describe deployment $DEPLOYMENT -n $NAMESPACE | tail -30
echo ""

# 7. Logs del primer pod con problemas
PROBLEM_POD=$(kubectl get pods -l app=$DEPLOYMENT -n $NAMESPACE --field-selector status.phase!=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ ! -z "$PROBLEM_POD" ]; then
    echo "📄 LOGS DEL POD PROBLEMÁTICO: $PROBLEM_POD"
    kubectl logs $PROBLEM_POD -n $NAMESPACE --tail=20 2>/dev/null || echo "No hay logs disponibles"
    echo ""
    
    echo "📄 LOGS PREVIOS (si existe):"
    kubectl logs $PROBLEM_POD -n $NAMESPACE --previous --tail=20 2>/dev/null || echo "No hay logs previos"
    echo ""
fi

# 8. Condiciones del deployment
echo "✅ CONDICIONES DEL DEPLOYMENT:"
kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\t"}{.message}{"\n"}{end}'
echo ""

# 9. Rollout status
echo "🔄 ROLLOUT STATUS:"
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5s 2>&1 || echo "Rollout en progreso o con problemas"
echo ""

# 10. Sugerencias
echo "💡 COMANDOS ÚTILES:"
echo "  - Ver logs en tiempo real:  kubectl logs -f -l app=$DEPLOYMENT -n $NAMESPACE"
echo "  - Describir pod específico:  kubectl describe pod <pod-name> -n $NAMESPACE"
echo "  - Editar deployment:         kubectl edit deployment $DEPLOYMENT -n $NAMESPACE"
echo "  - Rollback:                  kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE"
echo "  - Reiniciar deployment:      kubectl rollout restart deployment/$DEPLOYMENT -n $NAMESPACE"
echo ""
