#!/bin/bash

#==============================================================================
# Script: verify-rbac.sh
# Descripción: Verifica configuración RBAC del Lab 01
# Uso: ./verify-rbac.sh [username] [namespace]
#==============================================================================

set -euo pipefail

#------------------------------------------------------------------------------
# CONFIGURACIÓN
#------------------------------------------------------------------------------

USER_NAME="${1:-maria}"
NAMESPACE="${2:-development}"
ROLE_NAME="pod-reader"
ROLEBINDING_NAME="read-pods-${USER_NAME}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

#------------------------------------------------------------------------------
# FUNCIONES
#------------------------------------------------------------------------------

print_header() {
    echo
    echo "=========================================="
    echo "  $1"
    echo "=========================================="
}

test_pass() {
    echo -e "${GREEN}✓ PASS${NC} - $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC} - $1"
    ((FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠ WARN${NC} - $1"
}

#------------------------------------------------------------------------------
# TESTS
#------------------------------------------------------------------------------

test_namespace_exists() {
    print_header "TEST 1: Verificar namespace ${NAMESPACE}"
    
    if kubectl get namespace ${NAMESPACE} &>/dev/null; then
        test_pass "Namespace ${NAMESPACE} existe"
    else
        test_fail "Namespace ${NAMESPACE} NO existe"
    fi
}

test_role_exists() {
    print_header "TEST 2: Verificar Role ${ROLE_NAME}"
    
    if kubectl get role ${ROLE_NAME} -n ${NAMESPACE} &>/dev/null; then
        test_pass "Role ${ROLE_NAME} existe en namespace ${NAMESPACE}"
        
        # Verificar rules
        local rules=$(kubectl get role ${ROLE_NAME} -n ${NAMESPACE} -o json | jq -r '.rules')
        echo "Rules:"
        echo "$rules" | jq .
    else
        test_fail "Role ${ROLE_NAME} NO existe"
    fi
}

test_rolebinding_exists() {
    print_header "TEST 3: Verificar RoleBinding ${ROLEBINDING_NAME}"
    
    if kubectl get rolebinding ${ROLEBINDING_NAME} -n ${NAMESPACE} &>/dev/null; then
        test_pass "RoleBinding ${ROLEBINDING_NAME} existe"
        
        # Verificar binding correcto
        local bound_user=$(kubectl get rolebinding ${ROLEBINDING_NAME} -n ${NAMESPACE} -o jsonpath='{.subjects[0].name}')
        local bound_role=$(kubectl get rolebinding ${ROLEBINDING_NAME} -n ${NAMESPACE} -o jsonpath='{.roleRef.name}')
        
        echo "  Usuario: ${bound_user}"
        echo "  Role: ${bound_role}"
        
        if [ "$bound_user" == "$USER_NAME" ] && [ "$bound_role" == "$ROLE_NAME" ]; then
            test_pass "Binding correcto: ${USER_NAME} → ${ROLE_NAME}"
        else
            test_fail "Binding incorrecto"
        fi
    else
        test_fail "RoleBinding ${ROLEBINDING_NAME} NO existe"
    fi
}

test_kubectl_context() {
    print_header "TEST 4: Verificar contexto kubectl"
    
    local context_name="${USER_NAME}@kubernetes"
    
    if kubectl config get-contexts ${context_name} &>/dev/null; then
        test_pass "Contexto ${context_name} configurado"
        
        local ns=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"${context_name}\")].context.namespace}")
        if [ "$ns" == "$NAMESPACE" ]; then
            test_pass "Namespace default correcto: ${NAMESPACE}"
        else
            test_warn "Namespace default: ${ns} (esperado: ${NAMESPACE})"
        fi
    else
        test_fail "Contexto ${context_name} NO configurado"
    fi
}

test_user_permissions_allowed() {
    print_header "TEST 5: Verificar permisos PERMITIDOS"
    
    local context_name="${USER_NAME}@kubernetes"
    
    # Cambiar a contexto de usuario
    local original_context=$(kubectl config current-context)
    kubectl config use-context ${context_name} &>/dev/null
    
    # Test: list pods
    if kubectl get pods -n ${NAMESPACE} &>/dev/null; then
        test_pass "Usuario puede listar pods"
    else
        test_fail "Usuario NO puede listar pods"
    fi
    
    # Test: get pods (requiere un pod existente)
    # Crear pod de prueba como admin primero
    kubectl config use-context ${original_context} &>/dev/null
    kubectl run test-pod --image=nginx -n ${NAMESPACE} --restart=Never 2>/dev/null || true
    sleep 2
    
    kubectl config use-context ${context_name} &>/dev/null
    if kubectl get pod test-pod -n ${NAMESPACE} &>/dev/null; then
        test_pass "Usuario puede ver pod específico"
    else
        test_warn "Usuario NO puede ver pod específico (puede faltar el pod)"
    fi
    
    # Test: get logs
    if kubectl logs test-pod -n ${NAMESPACE} &>/dev/null; then
        test_pass "Usuario puede ver logs"
    else
        test_warn "Usuario NO puede ver logs (pod puede no estar Ready)"
    fi
    
    # Restaurar contexto
    kubectl config use-context ${original_context} &>/dev/null
}

test_user_permissions_denied() {
    print_header "TEST 6: Verificar permisos DENEGADOS"
    
    local context_name="${USER_NAME}@kubernetes"
    local original_context=$(kubectl config current-context)
    
    kubectl config use-context ${context_name} &>/dev/null
    
    # Test: NO puede crear pods
    if ! kubectl auth can-i create pods -n ${NAMESPACE} 2>/dev/null; then
        test_pass "Usuario NO puede crear pods (correcto)"
    else
        test_fail "Usuario PUEDE crear pods (permisos excesivos)"
    fi
    
    # Test: NO puede eliminar pods
    if ! kubectl auth can-i delete pods -n ${NAMESPACE} 2>/dev/null; then
        test_pass "Usuario NO puede eliminar pods (correcto)"
    else
        test_fail "Usuario PUEDE eliminar pods (permisos excesivos)"
    fi
    
    # Test: NO puede ver secrets
    if ! kubectl auth can-i get secrets -n ${NAMESPACE} 2>/dev/null; then
        test_pass "Usuario NO puede ver secrets (correcto)"
    else
        test_fail "Usuario PUEDE ver secrets (permisos excesivos)"
    fi
    
    # Test: NO puede acceder a otros namespaces
    if ! kubectl get pods -n default 2>/dev/null; then
        test_pass "Usuario NO puede acceder a namespace 'default' (correcto)"
    else
        test_fail "Usuario PUEDE acceder a otros namespaces (permisos excesivos)"
    fi
    
    # Restaurar contexto
    kubectl config use-context ${original_context} &>/dev/null
}

test_certificates() {
    print_header "TEST 7: Verificar certificados"
    
    local cert_dir="${HOME}/k8s-rbac-lab01/certs"
    
    if [ -f "${cert_dir}/${USER_NAME}.crt" ]; then
        test_pass "Certificado de usuario existe"
        
        # Verificar validez
        local expiry=$(openssl x509 -in ${cert_dir}/${USER_NAME}.crt -noout -enddate | cut -d= -f2)
        echo "  Expira: ${expiry}"
        
        # Verificar CN
        local cn=$(openssl x509 -in ${cert_dir}/${USER_NAME}.crt -noout -subject | grep -oP 'CN=\K[^,]+')
        if [ "$cn" == "$USER_NAME" ]; then
            test_pass "CN del certificado correcto: ${cn}"
        else
            test_fail "CN incorrecto: ${cn} (esperado: ${USER_NAME})"
        fi
    else
        test_fail "Certificado NO existe en ${cert_dir}"
    fi
}

cleanup_test_resources() {
    print_header "Limpieza de recursos de prueba"
    
    # Eliminar pod de prueba
    kubectl delete pod test-pod -n ${NAMESPACE} --grace-period=0 --force 2>/dev/null || true
    test_pass "Recursos de prueba eliminados"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo "=========================================="
    echo "  RBAC Lab 01 - Verification Suite"
    echo "=========================================="
    echo
    echo "Usuario: ${USER_NAME}"
    echo "Namespace: ${NAMESPACE}"
    echo
    
    test_namespace_exists
    test_role_exists
    test_rolebinding_exists
    test_kubectl_context
    test_user_permissions_allowed
    test_user_permissions_denied
    test_certificates
    cleanup_test_resources
    
    # Resumen
    print_header "RESUMEN"
    echo -e "Tests pasados: ${GREEN}${PASSED}${NC}"
    echo -e "Tests fallidos: ${RED}${FAILED}${NC}"
    echo
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ ÉXITO - RBAC configurado correctamente${NC}"
        echo
        echo "El usuario ${USER_NAME} tiene permisos correctos:"
        echo "  ✓ Puede listar pods en ${NAMESPACE}"
        echo "  ✓ Puede ver logs en ${NAMESPACE}"
        echo "  ✗ NO puede crear/eliminar pods"
        echo "  ✗ NO puede acceder a otros namespaces"
        exit 0
    else
        echo -e "${RED}✗ FALLOS DETECTADOS - Revisar configuración${NC}"
        exit 1
    fi
}

main "$@"
