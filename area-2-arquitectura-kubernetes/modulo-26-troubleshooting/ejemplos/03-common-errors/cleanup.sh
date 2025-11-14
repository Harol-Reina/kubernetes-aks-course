#!/bin/bash
# Cleanup Common Errors example

echo "🧹 Limpiando recursos del Ejemplo 03..."

kubectl delete deployment error-service-mismatch error-port-mismatch error-latest-tag \
  error-hpa error-probe-timeout --ignore-not-found

kubectl delete pod error-pvc-pending error-pvc-access error-securitycontext --ignore-not-found

kubectl delete svc svc-no-endpoints svc-port-mismatch --ignore-not-found

kubectl delete pvc pvc-no-pv pvc-wrong-access --ignore-not-found

kubectl delete networkpolicy deny-all-ingress --ignore-not-found

kubectl delete ingress ingress-wrong-path --ignore-not-found

kubectl delete statefulset error-statefulset --ignore-not-found

kubectl delete hpa hpa-no-metrics --ignore-not-found

echo "✅ Limpieza completada!"
