#!/bin/bash
# Cleanup script for Lab 01: Application Troubleshooting

echo "🧹 Limpiando recursos del Lab 01..."

# Delete all pods and deployments from scenarios
kubectl delete deployment webapp-crash api-server config-app --ignore-not-found
kubectl delete pod memory-hog backend-app web-server api-pod python-app test --ignore-not-found
kubectl delete svc api-service python-service postgres-service --ignore-not-found
kubectl delete pod postgres --ignore-not-found
kubectl delete configmap app-settings --ignore-not-found

echo "✅ Lab 01 limpieza completada!"
