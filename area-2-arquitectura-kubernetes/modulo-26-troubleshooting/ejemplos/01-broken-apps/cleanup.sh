#!/bin/bash
# Cleanup script for Broken Apps example

echo "🧹 Limpiando recursos del Ejemplo 01: Broken Apps..."

# Delete all broken pods
echo "Eliminando pods..."
kubectl delete pod broken-crashloop broken-imagepull broken-oom \
  broken-init broken-liveness broken-readiness \
  broken-configmap broken-secret broken-command \
  broken-cpu broken-volume broken-port \
  --ignore-not-found

# Delete supporting resources
echo "Eliminando recursos auxiliares..."
kubectl delete configmap app-config --ignore-not-found
kubectl delete secret app-secret --ignore-not-found
kubectl delete pod postgres --ignore-not-found
kubectl delete svc postgres-service --ignore-not-found

echo "✅ Limpieza completada!"
