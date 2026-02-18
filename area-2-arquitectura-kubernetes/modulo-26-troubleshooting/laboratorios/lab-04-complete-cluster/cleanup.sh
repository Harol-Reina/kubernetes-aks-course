#!/bin/bash
# Cleanup and recovery for Lab 04

echo "🧹 Limpiando recursos del Lab 04..."
echo ""

# Delete test resources
echo "1. Eliminando recursos de prueba..."
kubectl delete deployment test-nginx critical-app webapp-crash api-server config-app --ignore-not-found
kubectl delete statefulset postgres-db web --ignore-not-found
kubectl delete pod test-restore memory-hog backend-app --ignore-not-found
kubectl delete svc api-service postgres-db web --ignore-not-found
kubectl delete pvc data-postgres-db-0 data-postgres-db-1 data-postgres-db-2 data-web-0 data-web-1 --ignore-not-found
kubectl delete configmap app-config app-settings --ignore-not-found
kubectl delete secret app-secret --ignore-not-found

# Delete RBAC resources
echo "2. Limpiando recursos RBAC..."
kubectl delete sa app-sa production:app-sa --ignore-not-found
kubectl delete role pod-reader --ignore-not-found
kubectl delete rolebinding read-pods --ignore-not-found
kubectl delete clusterrole cluster-viewer --ignore-not-found
kubectl delete clusterrolebinding cluster-viewer-binding --ignore-not-found

# Delete Network Policies
echo "3. Eliminando Network Policies..."
kubectl delete networkpolicy default-deny-all allow-frontend-to-backend allow-dns --ignore-not-found -n production
kubectl delete networkpolicy default-deny-all --ignore-not-found

# Delete ResourceQuotas and LimitRanges
echo "4. Limpiando quotas y limits..."
kubectl delete resourcequota namespace-quota test-quota --ignore-not-found -n production
kubectl delete limitrange default-limits test-limits --ignore-not-found -n production

# Delete PriorityClasses
echo "5. Eliminando PriorityClasses..."
kubectl delete priorityclass high-priority low-priority --ignore-not-found

# Delete namespaces if created
echo "6. Limpiando namespaces..."
kubectl delete namespace production test-ns --ignore-not-found

echo ""
echo "✅ Limpieza básica completada!"
echo ""
echo "⚠️  Si el cluster está en mal estado:"
echo ""
echo "1. Verificar control plane components:"
echo "   sudo crictl ps | grep -E 'kube-apiserver|etcd|kube-scheduler|kube-controller'"
echo ""
echo "2. Si API server no responde, verificar logs:"
echo "   sudo journalctl -u kubelet -n 100"
echo ""
echo "3. Si es necesario restaurar etcd:"
echo "   ./restore-from-backup.sh"
echo ""
echo "4. Verificar nodes:"
echo "   kubectl get nodes"
echo "   kubectl describe node <node-name>"
echo ""
