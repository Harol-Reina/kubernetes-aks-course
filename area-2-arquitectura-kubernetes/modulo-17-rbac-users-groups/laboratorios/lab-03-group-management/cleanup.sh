#!/bin/bash
set -euo pipefail

USERS=("alice" "bob" "charlie" "diana" "eve" "frank")
NAMESPACES=("dev" "test")

GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

echo "========== Cleanup: Group Management Lab =========="

# Eliminar RoleBindings
kubectl delete rolebinding developers-binding -n dev 2>/dev/null || true
kubectl delete rolebinding testers-binding -n test 2>/dev/null || true
kubectl delete clusterrolebinding admins-binding 2>/dev/null || true
log_info "✓ RoleBindings eliminados"

# Eliminar Roles
kubectl delete role pod-reader -n dev 2>/dev/null || true
kubectl delete role pod-writer -n test 2>/dev/null || true
kubectl delete clusterrole cluster-viewer 2>/dev/null || true
log_info "✓ Roles eliminados"

# Eliminar namespaces
for ns in "${NAMESPACES[@]}"; do
    kubectl delete namespace $ns --grace-period=0 --force 2>/dev/null || true
done
log_info "✓ Namespaces eliminados"

# Limpiar contextos
for user in "${USERS[@]}"; do
    kubectl config delete-context ${user}@kubernetes 2>/dev/null || true
    kubectl config delete-user ${user} 2>/dev/null || true
done
log_info "✓ Contextos kubectl eliminados"

# Archivos locales
rm -rf "${HOME}/k8s-rbac-lab03"
log_info "✓ Archivos locales eliminados"

# Restaurar contexto admin
ADMIN_CTX=$(kubectl config get-contexts -o name | grep -E "minikube|admin" | head -1)
[ -n "$ADMIN_CTX" ] && kubectl config use-context ${ADMIN_CTX} &>/dev/null

log_info "=========================================="
log_info "Cleanup completado"
