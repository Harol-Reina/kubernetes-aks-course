#!/bin/bash
# Load generator for HPA testing

echo "🔥 Generando carga para HPA testing..."

# Get service IP
SVC_IP=$(kubectl get svc hpa-test-service -o jsonpath='{.spec.clusterIP}')

if [ -z "$SVC_IP" ]; then
  echo "❌ Servicio hpa-test-service no encontrado"
  echo "Ejecuta primero: kubectl apply -f performance-test.yaml"
  exit 1
fi

echo "Servicio: $SVC_IP"
echo "Generando requests... (Ctrl+C para detener)"

# Launch load generator pod
kubectl run load-generator --image=busybox:1.28 --rm -it -- /bin/sh -c \
  "while true; do wget -q -O- http://$SVC_IP; done"
