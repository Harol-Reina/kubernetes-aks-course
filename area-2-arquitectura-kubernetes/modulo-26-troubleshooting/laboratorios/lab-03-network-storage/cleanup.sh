#!/bin/bash
# Cleanup for Lab 03: Network & Storage

echo "🧹 Limpiando recursos del Lab 03..."

# Delete pods
kubectl delete pod test-dns nginx-test test web-pod frontend backend app-pod pod1 pod2 writer-pod --ignore-not-found

# Delete services
kubectl delete svc web-service nginx-test app-service python-service --ignore-not-found

# Delete network policies
kubectl delete networkpolicy deny-all allow-frontend-to-backend allow-frontend-egress allow-dns --ignore-not-found

# Delete PVCs and StatefulSets
kubectl delete pvc my-pvc data-web-0 data-web-1 --ignore-not-found
kubectl delete statefulset web --ignore-not-found

# Delete Ingress
kubectl delete ingress app-ingress --ignore-not-found

# Delete namespaces if created
kubectl delete namespace test-ns --ignore-not-found

echo "✅ Lab 03 cleanup completado!"
