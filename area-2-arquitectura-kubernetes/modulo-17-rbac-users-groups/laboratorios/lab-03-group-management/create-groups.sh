#!/bin/bash
set -euo pipefail

GROUPS=("developers" "testers" "admins")
USERS_DEVELOPERS=("alice" "bob")
USERS_TESTERS=("charlie" "diana")
USERS_ADMINS=("eve" "frank")
NAMESPACES=("dev" "test")

GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

CERT_DIR="${HOME}/k8s-rbac-lab03/certs"
mkdir -p "${CERT_DIR}"

# Crear namespaces
for ns in "${NAMESPACES[@]}"; do
    kubectl create namespace $ns 2>/dev/null || true
done
log_info "✓ Namespaces creados"

# Obtener CA
cd "${CERT_DIR}"
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
kubectl config view --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 -d > ca.key

# Función para crear usuario
create_user() {
    local user=$1
    local group=$2
    
    openssl genrsa -out ${user}.key 2048 2>/dev/null
    openssl req -new -key ${user}.key -out ${user}.csr -subj "/CN=${user}/O=${group}" 2>/dev/null
    openssl x509 -req -in ${user}.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out ${user}.crt -days 365 2>/dev/null
    
    CLUSTER_NAME=$(kubectl config view -o jsonpath='{.clusters[0].name}')
    kubectl config set-credentials ${user} \
      --client-certificate=${CERT_DIR}/${user}.crt \
      --client-key=${CERT_DIR}/${user}.key \
      --embed-certs=true >/dev/null
    
    kubectl config set-context ${user}@kubernetes \
      --cluster=${CLUSTER_NAME} \
      --user=${user} >/dev/null
    
    log_info "  ✓ ${user} (grupo: ${group})"
}

# Crear usuarios
log_info "Creando 6 usuarios con grupos..."
for user in "${USERS_DEVELOPERS[@]}"; do create_user $user "developers"; done
for user in "${USERS_TESTERS[@]}"; do create_user $user "testers"; done
for user in "${USERS_ADMINS[@]}"; do create_user $user "admins"; done

# Crear Roles
log_info "Creando Roles..."

kubectl apply -f - <<EOF >/dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: dev
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-writer
  namespace: test
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "create", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-viewer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "namespaces"]
  verbs: ["get", "list", "watch"]
EOF

log_info "✓ Roles creados"

# Crear RoleBindings PARA GRUPOS
log_info "Creando RoleBindings para GRUPOS..."

kubectl create rolebinding developers-binding \
  --role=pod-reader \
  --group=developers \
  --namespace=dev 2>/dev/null || true

kubectl create rolebinding testers-binding \
  --role=pod-writer \
  --group=testers \
  --namespace=test 2>/dev/null || true

kubectl create clusterrolebinding admins-binding \
  --clusterrole=cluster-viewer \
  --group=admins 2>/dev/null || true

log_info "✓ RoleBindings creados"

log_info "=========================================="
log_info "Setup completado - 6 usuarios en 3 grupos:"
echo ""
echo "  developers: alice, bob       → pod-reader (dev)"
echo "  testers:    charlie, diana   → pod-writer (test)"
echo "  admins:     eve, frank       → cluster-viewer (all)"
echo ""
log_info "Probar:"
echo "  kubectl config use-context alice@kubernetes"
echo "  kubectl get pods -n dev"
