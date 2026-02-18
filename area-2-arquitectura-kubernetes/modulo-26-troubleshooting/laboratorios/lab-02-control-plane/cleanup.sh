#!/bin/bash
# Cleanup for Lab 02

echo "🧹 Limpiando recursos del Lab 02..."

# Delete test resources
kubectl delete deployment test-nginx --ignore-not-found
kubectl delete pod test-1 test-2 test-dns iperf-server iperf-client --ignore-not-found

# Ensure kubelet is running on all nodes
echo "Verificando kubelet en todos los nodes..."
# Este comando debe ejecutarse en cada node
# sudo systemctl start kubelet
# sudo systemctl enable kubelet

echo "✅ Lab 02 cleanup completado!"
echo "⚠️  Recuerda verificar que kubelet esté corriendo en todos los nodes"
