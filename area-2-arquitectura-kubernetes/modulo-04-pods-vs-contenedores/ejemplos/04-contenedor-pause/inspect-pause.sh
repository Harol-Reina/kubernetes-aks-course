#!/bin/bash
# inspect-pause.sh - Ver el contenedor pause (infraestructura)

set -euo pipefail

POD_NAME="${1:-nginx}"

echo "========== Inspección del Contenedor Pause =========="
echo

# Obtener nodo donde corre el pod
NODE=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.nodeName}')
echo "Nodo: $NODE"

# En minikube, conectar al nodo y listar contenedores
echo
echo "Contenedores en el nodo (incluye pause):"
echo

if command -v minikube &>/dev/null; then
    minikube ssh "docker ps | grep -E 'pause|$POD_NAME'"
else
    echo "Nota: Este script funciona mejor con minikube"
    echo "En cluster real, usa: docker ps en el nodo worker"
fi

echo
echo "El contenedor 'pause' mantiene los namespaces del pod"
