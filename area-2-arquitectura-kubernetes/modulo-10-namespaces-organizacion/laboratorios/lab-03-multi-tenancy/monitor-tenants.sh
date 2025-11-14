#!/bin/bash
# monitor-tenants.sh - Monitoreo de multi-tenancy

echo "🏢 MONITOREO DE TENANTS"
echo "===================="
echo ""

for NS in team-a team-b team-c; do
  echo "📦 Namespace: $NS"
  echo "   Quotas:"
  kubectl get resourcequota -n $NS -o custom-columns=CPU:.status.hard.requests\\.cpu,MEM:.status.hard.requests\\.memory,PODS:.status.hard.pods --no-headers 2>/dev/null || echo "   Sin quota"
  
  echo "   Pods: $(kubectl get pods -n $NS --no-headers 2>/dev/null | wc -l)"
  echo "   Services: $(kubectl get svc -n $NS --no-headers 2>/dev/null | wc -l)"
  echo ""
done

echo "🔒 Network Policies activas:"
kubectl get networkpolicy --all-namespaces | grep -E "team-a|team-b|team-c" || echo "   Ninguna"
echo ""
