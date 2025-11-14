#!/bin/bash
# Deploy all troubleshooting tools

echo "🚀 Desplegando herramientas de troubleshooting..."

kubectl apply -f troubleshooting-tools.yaml

echo "✅ Herramientas desplegadas!"
echo ""
echo "📋 Pods disponibles:"
kubectl get pods | grep -E "netshoot|debug|python|nodejs"
echo ""
echo "💡 Uso rápido:"
echo "  kubectl exec -it deployment/debug-netshoot -- bash"
echo "  kubectl exec -it python-debug -- python3"
echo "  kubectl exec -it nodejs-debug -- node"
