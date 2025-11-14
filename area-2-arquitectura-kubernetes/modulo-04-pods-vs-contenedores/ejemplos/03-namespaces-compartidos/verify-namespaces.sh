#!/bin/bash
# verify-namespaces.sh - Inspeccionar namespaces compartidos en pod

set -euo pipefail

POD_NAME="${1:-nginx}"

echo "========== Verificación de Namespaces Compartidos =========="
echo "Pod: $POD_NAME"
echo

# Obtener contenedores del pod
CONTAINERS=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.containers[*].name}')
echo "Contenedores: $CONTAINERS"
echo

# Inspeccionar namespaces de red (deben ser iguales)
echo "--- Network Namespaces ---"
for container in $CONTAINERS; do
    echo -n "$container: "
    kubectl exec $POD_NAME -c $container -- cat /proc/1/ns/net 2>/dev/null || echo "N/A"
done

echo
echo "Si los números son iguales → namespaces compartidos ✓"
