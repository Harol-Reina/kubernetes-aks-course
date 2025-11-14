#!/bin/bash
set -euo pipefail

NAMESPACES=("dev" "test" "prod")
USERS=("dev-user" "test-user" "prod-admin")
ROLES=("pod-reader" "pod-writer" "namespace-admin")

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Verificar prerequisites
command -v kubectl >/dev/null || log_error "kubectl no instalado"
command -v openssl >/dev/null || log_error "openssl no instalado"
kubectl cluster-info &>/dev/null || log_error "cluster no accesible"

CERT_DIR="${HOME}/k8s-rbac-lab02/certs"
mkdir -p "${CERT_DIR}"

log_info "Creando 3 namespaces..."
for ns in "${NAMESPACES[@]}"; do
    kubectl create namespace $ns 2>/dev/null || log_info "  $ns ya existe"
done

log_info "Generando certificados para 3 usuarios..."
cd "${CERT_DIR}"

# Obtener CA del cluster (solo una vez)
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
kubectl config view --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 -d > ca.key

for user in "${USERS[@]}"; do
    openssl genrsa -out ${user}.key 2048 2>/dev/null
    openssl req -new -key ${user}.key -out ${user}.csr -subj "/CN=${user}/O=developers" 2>/dev/null
    openssl x509 -req -in ${user}.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out ${user}.crt -days 365 2>/dev/null
    log_info "  ✓ ${user}"
done

log_info "Configurando kubectl para 3 usuarios..."
CLUSTER_NAME=$(kubectl config view -o jsonpath='{.clusters[0].name}')
SERVER_URL=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')

for i in "${!USERS[@]}"; do
    user="${USERS[$i]}"
    ns="${NAMESPACES[$i]}"
    
    kubectl config set-credentials ${user} \
      --client-certificate=${CERT_DIR}/${user}.crt \
      --client-key=${CERT_DIR}/${user}.key \
      --embed-certs=true >/dev/null
    
    kubectl config set-context ${user}@kubernetes \
      --cluster=${CLUSTER_NAME} \
      --namespace=${ns} \
      --user=${user} >/dev/null
    
    log_info "  ✓ ${user} → ${ns}"
done

log_info "Creando Roles con permisos diferenciados..."

# Role 1: pod-reader (solo lectura)
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
EOF

# Role 2: pod-writer (lectura + escritura)
kubectl apply -f - <<EOF >/dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-writer
  namespace: test
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch", "create", "delete"]
EOF

# Role 3: namespace-admin (todos los permisos)
kubectl apply -f - <<EOF >/dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-admin
  namespace: prod
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["*"]
  verbs: ["*"]
EOF

log_info "  ✓ 3 Roles creados"

log_info "Creando RoleBindings..."
for i in "${!USERS[@]}"; do
    user="${USERS[$i]}"
    ns="${NAMESPACES[$i]}"
    role="${ROLES[$i]}"
    
    kubectl create rolebinding ${user}-binding \
      --role=${role} \
      --user=${user} \
      --namespace=${ns} 2>/dev/null || true
    
    log_info "  ✓ ${user} → ${role} en ${ns}"
done

log_info "=========================================="
log_info "Setup completado - 3 usuarios configurados:"
echo ""
echo "  dev-user   → dev  (lectura pods)"
echo "  test-user  → test (lectura + escritura pods)"
echo "  prod-admin → prod (todos los permisos)"
echo ""
log_info "Probar con:"
echo "  kubectl config use-context dev-user@kubernetes"
echo "  kubectl get pods"
