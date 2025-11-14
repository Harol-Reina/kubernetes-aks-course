#!/bin/bash
# compare-policies.sh - Comparar externalTrafficPolicy: Cluster vs Local

NAMESPACE="lab-nodeport"
echo "🔬 Comparación externalTrafficPolicy"
echo ""

# Test Cluster policy
echo "1️⃣  Política: Cluster"
kubectl run test-client --rm -i --restart=Never --image=curlimages/curl -n $NAMESPACE -- sh -c "
  for i in \$(seq 1 10); do
    curl -s http://nodeport-cluster:80 | grep -o 'Pod: [^<]*'
  done
" | sort | uniq -c
echo ""

# Test Local policy
echo "2️⃣  Política: Local"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NODE_PORT=$(kubectl get svc nodeport-local -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}')
echo "Accediendo vía NodeIP:NodePort ($NODE_IP:$NODE_PORT)"

for i in {1..10}; do
  curl -s http://$NODE_IP:$NODE_PORT 2>/dev/null | grep -o 'Pod: [^<]*' || echo "Sin respuesta"
done | sort | uniq -c

echo ""
echo "✅ Comparación completada"
