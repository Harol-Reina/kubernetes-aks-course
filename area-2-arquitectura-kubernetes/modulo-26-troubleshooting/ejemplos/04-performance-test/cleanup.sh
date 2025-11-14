#!/bin/bash
# Cleanup Performance Test resources

echo "🧹 Limpiando recursos de Performance Test..."

kubectl delete deployment stress-memory stress-cpu memory-leak hpa-test node-pressure-deployment --ignore-not-found
kubectl delete pod disk-io-stress qos-guaranteed qos-burstable qos-besteffort \
  priority-high priority-low load-generator --ignore-not-found
kubectl delete hpa hpa-test --ignore-not-found
kubectl delete svc hpa-test-service --ignore-not-found
kubectl delete resourcequota test-quota --ignore-not-found
kubectl delete limitrange test-limits --ignore-not-found
kubectl delete priorityclass high-priority low-priority --ignore-not-found

echo "✅ Limpieza completada!"
