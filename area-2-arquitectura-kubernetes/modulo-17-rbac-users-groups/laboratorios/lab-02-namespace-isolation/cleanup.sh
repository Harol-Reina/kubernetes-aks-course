#!/bin/bash
set -euo pipefail

NAMESPACES=("dev" "test" "prod")
USERS=("dev-user" "test-user" "prod-admin")

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "========== Cleanup: Namespace Isolation Lab =========="

# Eliminar RoleBindings
for i in "${!USERS[@]}"; do
    user="${USERS[$i]}"
    ns="${NAMESPACES[$i]}"
    kubectl delete rolebinding ${user}-binding -n $ns 2>/dev/null || true
done
log_info "✓ RoleBindings eliminados"

# Eliminar namespaces (esto elimina Roles también)
for ns in "${NAMESPACES[@]}"; do
    kubectl delete namespace $ns --grace-period=0 --force 2>/dev/null || true
done
log_info "✓ Namespaces eliminados"

# Limpiar contextos kubectl
for user in "${USERS[@]}"; do
    kubectl config delete-context ${user}@kubernetes 2>/dev/null || true
    kubectl config delete-user ${user} 2>/dev/null || true
done
log_info "✓ Contextos kubectl eliminados"

# Limpiar archivos locales
rm -rf "${HOME}/k8s-rbac-lab02"
log_info "✓ Archivos locales eliminados"

# Restaurar contexto admin
ADMIN_CTX=$(kubectl config get-contexts -o name | grep -E "minikube|admin" | head -1)
if [ -n "$ADMIN_CTX" ]; then
    kubectl config use-context ${ADMIN_CTX} &>/dev/null
    log_info "✓ Contexto restaurado a: ${ADMIN_CTX}"
fi

log_info "=========================================="
log_info "Cleanup completado - Lab listo para repetir"
