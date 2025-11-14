#!/bin/bash

#==============================================================================
# Script: setup-user.sh
# Descripción: Automatiza la creación de usuario RBAC con certificados
# Uso: ./setup-user.sh <username> <namespace> <role-name>
# Ejemplo: ./setup-user.sh maria development pod-reader
#==============================================================================

set -euo pipefail

#------------------------------------------------------------------------------
# PARÁMETROS
#------------------------------------------------------------------------------

USER_NAME="${1:-maria}"
NAMESPACE="${2:-development}"
ROLE_NAME="${3:-pod-reader}"
ROLEBINDING_NAME="read-pods-${USER_NAME}"

CERT_DIR="${HOME}/k8s-rbac-lab01/certs"
CONFIG_DIR="${HOME}/k8s-rbac-lab01/configs"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

#------------------------------------------------------------------------------
# FUNCIONES
#------------------------------------------------------------------------------

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

print_usage() {
    cat <<EOF
Uso: $0 <username> <namespace> <role-name>

Parámetros:
  username    Nombre del usuario a crear (default: maria)
  namespace   Namespace para los permisos (default: development)
  role-name   Nombre del Role a crear (default: pod-reader)

Ejemplo:
  $0 maria development pod-reader
  $0 juan production deployer

Este script automatiza:
  1. Creación de namespace
  2. Generación de certificados de usuario
  3. Configuración de kubectl para el usuario
  4. Creación de Role con permisos
  5. Binding del Role al usuario
EOF
}

check_prerequisites() {
    log_info "Verificando prerequisites..."
    
    if ! command -v kubectl &>/dev/null; then
        log_error "kubectl no instalado"
    fi
    
    if ! command -v openssl &>/dev/null; then
        log_error "openssl no instalado"
    fi
    
    if ! kubectl cluster-info &>/dev/null; then
        log_error "No hay conexión con cluster Kubernetes"
    fi
    
    if ! kubectl auth can-i create roles &>/dev/null; then
        log_error "No tienes permisos administrativos en el cluster"
    fi
    
    log_info "✓ Prerequisites OK"
}

create_directories() {
    log_info "Creando directorios de trabajo..."
    
    mkdir -p "${CERT_DIR}"
    mkdir -p "${CONFIG_DIR}"
    
    log_info "✓ Directorios creados"
}

create_namespace() {
    log_info "Creando namespace ${NAMESPACE}..."
    
    if kubectl get namespace ${NAMESPACE} &>/dev/null; then
        log_warn "Namespace ${NAMESPACE} ya existe"
    else
        kubectl create namespace ${NAMESPACE}
        log_info "✓ Namespace creado"
    fi
}

generate_certificates() {
    log_info "Generando certificados para usuario ${USER_NAME}..."
    
    cd "${CERT_DIR}"
    
    # Generar private key
    openssl genrsa -out ${USER_NAME}.key 2048
    log_info "  Private key generada"
    
    # Generar CSR
    openssl req -new -key ${USER_NAME}.key -out ${USER_NAME}.csr \
      -subj "/CN=${USER_NAME}/O=developers"
    log_info "  CSR generada"
    
    # Obtener CA del cluster
    kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
      | base64 -d > ca.crt
    
    kubectl config view --raw -o jsonpath='{.users[0].user.client-key-data}' \
      | base64 -d > ca.key
    
    # Firmar certificado con CA del cluster
    openssl x509 -req -in ${USER_NAME}.csr -CA ca.crt -CAkey ca.key \
      -CAcreateserial -out ${USER_NAME}.crt -days 365
    log_info "  Certificado firmado (válido 365 días)"
    
    log_info "✓ Certificados generados en ${CERT_DIR}"
}

configure_kubectl_user() {
    log_info "Configurando kubectl para usuario ${USER_NAME}..."
    
    local cluster_name=$(kubectl config view -o jsonpath='{.clusters[0].name}')
    local server_url=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')
    local context_name="${USER_NAME}@kubernetes"
    
    # Set cluster
    kubectl config set-cluster ${cluster_name} \
      --server=${server_url} \
      --certificate-authority=${CERT_DIR}/ca.crt \
      --embed-certs=true
    
    # Set credentials
    kubectl config set-credentials ${USER_NAME} \
      --client-certificate=${CERT_DIR}/${USER_NAME}.crt \
      --client-key=${CERT_DIR}/${USER_NAME}.key \
      --embed-certs=true
    
    # Set context
    kubectl config set-context ${context_name} \
      --cluster=${cluster_name} \
      --namespace=${NAMESPACE} \
      --user=${USER_NAME}
    
    log_info "✓ kubectl configurado para ${USER_NAME}"
    log_info "  Contexto: ${context_name}"
}

create_role() {
    log_info "Creando Role ${ROLE_NAME} en namespace ${NAMESPACE}..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${ROLE_NAME}
  namespace: ${NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
EOF
    
    log_info "✓ Role creado con permisos:"
    log_info "  - Pods: get, list, watch"
    log_info "  - Logs: get, list"
}

create_rolebinding() {
    log_info "Creando RoleBinding ${ROLEBINDING_NAME}..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${ROLEBINDING_NAME}
  namespace: ${NAMESPACE}
subjects:
- kind: User
  name: ${USER_NAME}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ${ROLE_NAME}
  apiGroup: rbac.authorization.k8s.io
EOF
    
    log_info "✓ RoleBinding creado"
    log_info "  Usuario ${USER_NAME} → Role ${ROLE_NAME}"
}

verify_setup() {
    log_info "Verificando configuración..."
    
    # Verificar que el contexto se puede usar
    local context_name="${USER_NAME}@kubernetes"
    kubectl config use-context ${context_name} &>/dev/null
    
    # Probar permisos
    if kubectl get pods -n ${NAMESPACE} &>/dev/null; then
        log_info "✓ Usuario puede listar pods en ${NAMESPACE}"
    else
        log_warn "Usuario no puede listar pods (puede ser normal si no hay pods)"
    fi
    
    # Verificar que NO puede crear pods
    if ! kubectl auth can-i create pods -n ${NAMESPACE} 2>/dev/null; then
        log_info "✓ Usuario NO puede crear pods (correcto)"
    else
        log_warn "Usuario PUEDE crear pods (permisos excesivos)"
    fi
    
    # Restaurar contexto admin
    kubectl config use-context $(kubectl config view -o jsonpath='{.contexts[0].name}') &>/dev/null
}

print_summary() {
    echo
    log_info "=========================================="
    log_info "Setup completado exitosamente"
    log_info "=========================================="
    echo
    echo "Usuario creado: ${USER_NAME}"
    echo "Namespace: ${NAMESPACE}"
    echo "Role: ${ROLE_NAME}"
    echo "RoleBinding: ${ROLEBINDING_NAME}"
    echo
    echo "Certificados en: ${CERT_DIR}"
    echo
    echo "Para usar este usuario:"
    echo "  kubectl config use-context ${USER_NAME}@kubernetes"
    echo "  kubectl get pods -n ${NAMESPACE}"
    echo
    echo "Para volver a admin:"
    echo "  kubectl config use-context $(kubectl config view -o jsonpath='{.contexts[0].name}')"
    echo
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        print_usage
        exit 0
    fi
    
    echo "=========================================="
    echo "  RBAC User Setup - Automated"
    echo "=========================================="
    echo
    
    check_prerequisites
    create_directories
    create_namespace
    generate_certificates
    configure_kubectl_user
    create_role
    create_rolebinding
    verify_setup
    print_summary
}

main "$@"
