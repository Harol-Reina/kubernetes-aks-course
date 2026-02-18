#!/bin/bash
# monitor-quota.sh - Monitoreo de ResourceQuota en namespace

NS="dev-limited"
echo "📊 === Uso de Quota en $NS ==="
echo ""

kubectl get resourcequota -n $NS -o custom-columns=\
NAME:.metadata.name,\
CPU_USED:.status.used.requests\\.cpu,\
CPU_HARD:.status.hard.requests\\.cpu,\
MEM_USED:.status.used.requests\\.memory,\
MEM_HARD:.status.hard.requests\\.memory,\
PODS_USED:.status.used.pods,\
PODS_HARD:.status.hard.pods

echo ""
echo "📋 Pods actuales:"
kubectl get pods -n $NS --no-headers | wc -l

echo ""
echo "💾 Uso de recursos por Pod:"
kubectl top pods -n $NS 2>/dev/null || echo "⚠️  Metrics server no disponible"
