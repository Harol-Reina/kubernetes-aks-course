#!/bin/bash
# test-loadbalancing.sh - Verificar balanceo de carga entre Pods

SERVICE="backend-clusterip"
NAMESPACE="lab-services"
ITERATIONS=20

echo "🔄 Probando balanceo de carga del servicio $SERVICE"
echo "Iteraciones: $ITERATIONS"
echo ""

# Obtener IP del servicio
SVC_IP=$(kubectl get svc $SERVICE -n $NAMESPACE -o jsonpath='{.spec.clusterIP}')
echo "IP del servicio: $SVC_IP"
echo ""

# Ejecutar requests desde un pod temporal
kubectl run test-curl --rm -i --restart=Never -n $NAMESPACE --image=curlimages/curl -- sh -c "
for i in \$(seq 1 $ITERATIONS); do
  curl -s http://$SVC_IP | grep -oP 'Hostname: \K.*' || echo 'Error'
  sleep 0.1
done
" | sort | uniq -c

echo ""
echo "✅ Test completado. Revisa la distribución de requests."
