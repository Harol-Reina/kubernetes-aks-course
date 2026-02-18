#!/bin/bash

#==============================================================================
# Script: cleanup.sh
# Descripción: Limpia recursos creados en Lab 01 RBAC Básico
# Uso: ./cleanup.sh [--force]
#==============================================================================

set -euo pipefail

#------------------------------------------------------------------------------
# CONFIGURACIÓN
#------------------------------------------------------------------------------

NAMESPACE="development"
USER_NAME="maria"
ROLE_NAME="pod-reader"
ROLEBINDING_NAME="read-pods-maria"
CERT_DIR="${HOME}/k8s-rbac-lab01/certs"
CONFIG_DIR="${HOME}/k8s-rbac-lab01/configs"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

FORCE=false
[[ "${1:-}" == "--force" ]] && FORCE=true

#------------------------------------------------------------------------------
# FUNCIONES
#------------------------------------------------------------------------------

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

confirm_cleanup() {
    if ! $FORCE; then
        echo
        log_warn "Esta operación eliminará:"
        echo "  - Namespace: ${NAMESPACE}"
        echo "  - Role: ${ROLE_NAME}"
        echo "  - RoleBinding: ${ROLEBINDING_NAME}"
        echo "  - Contexto kubectl: ${USER_NAME}@kubernetes"
        echo "  - Certificados locales en ${CERT_DIR}"
        echo
        read -p "¿Continuar con cleanup? (yes/no): " response
        
        if [[ ! "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Cleanup cancelado"
            exit 0
        fi
    fi
}

delete_rolebinding() {
    log_info "Eliminando RoleBinding ${ROLEBINDING_NAME}..."
    
    if kubectl get rolebinding ${ROLEBINDING_NAME} -n ${NAMESPACE} &>/dev/null; then
        kubectl delete rolebinding ${ROLEBINDING_NAME} -n ${NAMESPACE}
        log_info "✓ RoleBinding eliminado"
    else
        log_warn "RoleBinding ${ROLEBINDING_NAME} no existe (ya fue eliminado)"
    fi
}

delete_role() {
    log_info "Eliminando Role ${ROLE_NAME}..."
    
    if kubectl get role ${ROLE_NAME} -n ${NAMESPACE} &>/dev/null; then
        kubectl delete role ${ROLE_NAME} -n ${NAMESPACE}
        log_info "✓ Role eliminado"
    else
        log_warn "Role ${ROLE_NAME} no existe (ya fue eliminado)"
    fi
}

delete_namespace() {
    log_info "Eliminando namespace ${NAMESPACE}..."
    
    if kubectl get namespace ${NAMESPACE} &>/dev/null; then
        # Eliminar pods primero para acelerar
        kubectl delete pods --all -n ${NAMESPACE} --grace-period=0 --force 2>/dev/null || true
        
        # Eliminar namespace
        kubectl delete namespace ${NAMESPACE}
        log_info "✓ Namespace eliminado"
    else
        log_warn "Namespace ${NAMESPACE} no existe (ya fue eliminado)"
    fi
}

cleanup_kubectl_context() {
    log_info "Limpiando contexto kubectl de usuario ${USER_NAME}..."
    
    local context_name="${USER_NAME}@kubernetes"
    
    # Eliminar contexto
    if kubectl config get-contexts ${context_name} &>/dev/null; then
        kubectl config delete-context ${context_name} 2>/dev/null || true
        log_info "  Contexto eliminado"
    fi
    
    # Eliminar user
    if kubectl config get-users ${USER_NAME} &>/dev/null; then
        kubectl config delete-user ${USER_NAME} 2>/dev/null || true
        log_info "  Usuario eliminado de kubeconfig"
    fi
    
    log_info "✓ Contexto kubectl limpiado"
}

cleanup_local_files() {
    log_info "Limpiando archivos locales..."
    
    local cleaned=0
    
    if [ -d "${CERT_DIR}" ]; then
        rm -rf "${CERT_DIR}"
        log_info "  Certificados eliminados: ${CERT_DIR}"
        ((cleaned++))
    fi
    
    if [ -d "${CONFIG_DIR}" ]; then
        rm -rf "${CONFIG_DIR}"
        log_info "  Configs eliminados: ${CONFIG_DIR}"
        ((cleaned++))
    fi
    
    # Eliminar directorio raíz si está vacío
    local lab_dir="${HOME}/k8s-rbac-lab01"
    if [ -d "${lab_dir}" ]; then
        # Solo eliminar si está vacío
        if [ -z "$(ls -A ${lab_dir})" ]; then
            rmdir "${lab_dir}"
            log_info "  Directorio lab eliminado: ${lab_dir}"
            ((cleaned++))
        else
            log_warn "  Directorio ${lab_dir} no eliminado (contiene archivos)"
        fi
    fi
    
    if [ $cleaned -gt 0 ]; then
        log_info "✓ ${cleaned} directorios limpiados"
    else
        log_warn "No se encontraron archivos locales para limpiar"
    fi
}

verify_cleanup() {
    log_info "Verificando cleanup..."
    
    local issues=0
    
    # Verificar namespace eliminado
    if kubectl get namespace ${NAMESPACE} &>/dev/null; then
        log_warn "Namespace ${NAMESPACE} aún existe"
        ((issues++))
    fi
    
    # Verificar role eliminado
    if kubectl get role ${ROLE_NAME} -n default &>/dev/null; then
        log_warn "Role ${ROLE_NAME} aún existe"
        ((issues++))
    fi
    
    # Verificar rolebinding eliminado
    if kubectl get rolebinding ${ROLEBINDING_NAME} -n default &>/dev/null; then
        log_warn "RoleBinding ${ROLEBINDING_NAME} aún existe"
        ((issues++))
    fi
    
    # Verificar contexto kubectl
    if kubectl config get-contexts ${USER_NAME}@kubernetes &>/dev/null; then
        log_warn "Contexto kubectl ${USER_NAME}@kubernetes aún existe"
        ((issues++))
    fi
    
    # Verificar archivos locales
    if [ -d "${CERT_DIR}" ] || [ -d "${CONFIG_DIR}" ]; then
        log_warn "Archivos locales aún existen"
        ((issues++))
    fi
    
    if [ $issues -eq 0 ]; then
        log_info "✓ Cleanup verificado - sin problemas"
    else
        log_warn "${issues} problemas detectados durante verificación"
    fi
}

restore_admin_context() {
    log_info "Restaurando contexto administrativo..."
    
    # Detectar contexto admin disponible
    local admin_context=""
    
    if kubectl config get-contexts minikube &>/dev/null; then
        admin_context="minikube"
    elif kubectl config get-contexts kubernetes-admin@kubernetes &>/dev/null; then
        admin_context="kubernetes-admin@kubernetes"
    else
        # Usar el primer contexto disponible
        admin_context=$(kubectl config get-contexts -o name | head -1)
    fi
    
    if [ -n "$admin_context" ]; then
        kubectl config use-context ${admin_context}
        log_info "✓ Contexto restaurado a: ${admin_context}"
    else
        log_warn "No se encontró contexto administrativo para restaurar"
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo "=========================================="
    echo "  RBAC Lab 01 - Cleanup Script"
    echo "=========================================="
    echo
    
    confirm_cleanup
    
    echo
    log_info "Iniciando cleanup..."
    echo
    
    # Orden importante: primero RoleBinding, luego Role, luego Namespace
    delete_rolebinding
    delete_role
    delete_namespace
    cleanup_kubectl_context
    cleanup_local_files
    restore_admin_context
    verify_cleanup
    
    echo
    log_info "=========================================="
    log_info "Cleanup completado exitosamente"
    log_info "=========================================="
    echo
    log_info "El cluster ha sido restaurado al estado inicial."
    log_info "Puedes repetir el laboratorio desde el principio."
}

main "$@"
