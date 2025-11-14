#!/bin/bash

################################################################################
# Verify Certificates Script - Lab 04
# 
# Este script verifica que los certificados renovados funcionan correctamente,
# validando conectividad y funcionalidad del cluster.
#
# Uso:
#   ./verify-certs.sh
################################################################################

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Contadores
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0
TOTAL_CHECKS=0

################################################################################
# Funciones de Utilidad
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((CHECKS_PASSED++))
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    ((CHECKS_WARNING++))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((CHECKS_FAILED++))
}

log_section() {
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# Verificación 1: Fechas de Expiración
################################################################################

check_expiration_dates() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 1: FECHAS DE EXPIRACIÓN"
    
    log_info "Verificando que certificados tienen ~1 año de validez..."
    echo ""
    
    # Obtener output de kubeadm
    local output=$(sudo kubeadm certs check-expiration 2>/dev/null)
    
    if [[ -z "$output" ]]; then
        log_error "No se pudo obtener información de certificados"
        return 1
    fi
    
    echo "$output"
    echo ""
    
    # Verificar que todos tienen más de 350 días
    local short_validity=$(echo "$output" | grep -E "^\[certificates\]|^CERTIFICATE" | grep -v "CERTIFICATE AUTHORITY" | grep -oP '\d+d' | sed 's/d//' | awk '$1 < 350 {print}' | wc -l)
    
    if [[ $short_validity -gt 0 ]]; then
        log_warning "Algunos certificados tienen menos de 350 días de validez"
        log_info "Puede ser normal si la renovación fue hace tiempo"
    else
        log_success "Todos los certificados tienen validez óptima (≥350 días)"
    fi
}

################################################################################
# Verificación 2: Conectividad del Cluster
################################################################################

check_cluster_connectivity() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 2: CONECTIVIDAD AL CLUSTER"
    
    log_info "Verificando conexión al API Server..."
    
    if kubectl cluster-info > /dev/null 2>&1; then
        log_success "Conectividad al API Server OK"
        echo ""
        kubectl cluster-info
    else
        log_error "No se puede conectar al API Server"
        log_info "Verificar logs: sudo journalctl -u kubelet -n 50"
        return 1
    fi
}

################################################################################
# Verificación 3: Estado de Nodos
################################################################################

check_nodes_status() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 3: ESTADO DE NODOS"
    
    log_info "Verificando que nodos están Ready..."
    echo ""
    
    kubectl get nodes -o wide
    
    echo ""
    
    local notready=$(kubectl get nodes --no-headers | grep -v "Ready" | grep "NotReady" | wc -l || true)
    
    if [[ $notready -gt 0 ]]; then
        log_error "$notready nodo(s) en estado NotReady"
    else
        log_success "Todos los nodos están Ready"
    fi
}

################################################################################
# Verificación 4: Pods de Control Plane
################################################################################

check_control_plane_pods() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 4: PODS DE CONTROL PLANE"
    
    log_info "Verificando pods críticos en kube-system..."
    echo ""
    
    kubectl get pods -n kube-system | grep -E "kube-apiserver|kube-controller|kube-scheduler|etcd" || true
    
    echo ""
    
    # Verificar que todos están Running
    local not_running=$(kubectl get pods -n kube-system --no-headers | grep -E "kube-apiserver|kube-controller|kube-scheduler|etcd" | grep -v "Running" | wc -l || true)
    
    if [[ $not_running -gt 0 ]]; then
        log_error "$not_running pod(s) de control plane NO están Running"
        log_info "Verificar con: kubectl describe pod <pod-name> -n kube-system"
    else
        log_success "Todos los pods de control plane están Running"
    fi
}

################################################################################
# Verificación 5: Funcionalidad de kubectl
################################################################################

check_kubectl_functionality() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 5: FUNCIONALIDAD DE KUBECTL"
    
    log_info "Probando operaciones comunes de kubectl..."
    echo ""
    
    # Test 1: get nodes
    log_info "Test 1: kubectl get nodes"
    if kubectl get nodes > /dev/null 2>&1; then
        log_success "  kubectl get nodes OK"
    else
        log_error "  kubectl get nodes FALLÓ"
    fi
    
    # Test 2: get pods -A
    log_info "Test 2: kubectl get pods -A"
    if kubectl get pods -A > /dev/null 2>&1; then
        log_success "  kubectl get pods -A OK"
    else
        log_error "  kubectl get pods -A FALLÓ"
    fi
    
    # Test 3: create (dry-run)
    log_info "Test 3: kubectl run (dry-run)"
    if kubectl run test-cert --image=nginx:alpine --restart=Never --dry-run=client -o yaml > /dev/null 2>&1; then
        log_success "  kubectl run (dry-run) OK"
    else
        log_error "  kubectl run (dry-run) FALLÓ"
    fi
    
    # Test 4: logs (de un pod existente)
    log_info "Test 4: kubectl logs"
    local test_pod=$(kubectl get pods -n kube-system --no-headers | grep -E "coredns|kube-proxy" | head -1 | awk '{print $1}')
    
    if [[ -n "$test_pod" ]]; then
        if kubectl logs -n kube-system "$test_pod" --tail=1 > /dev/null 2>&1; then
            log_success "  kubectl logs OK"
        else
            log_warning "  kubectl logs FALLÓ (puede ser normal si pod no tiene logs)"
        fi
    else
        log_warning "  No se encontró pod para probar logs"
    fi
    
    # Test 5: exec (simulado con api-resources)
    log_info "Test 5: kubectl api-resources"
    if kubectl api-resources > /dev/null 2>&1; then
        log_success "  kubectl api-resources OK"
    else
        log_error "  kubectl api-resources FALLÓ"
    fi
}

################################################################################
# Verificación 6: Certificados con openssl
################################################################################

check_certs_with_openssl() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 6: VALIDACIÓN CON OPENSSL"
    
    log_info "Verificando certificados críticos con openssl..."
    echo ""
    
    local pki_dir="/etc/kubernetes/pki"
    local critical_certs=("apiserver.crt" "apiserver-kubelet-client.crt" "front-proxy-client.crt")
    
    for cert in "${critical_certs[@]}"; do
        local cert_path="$pki_dir/$cert"
        
        if sudo test -f "$cert_path"; then
            # Verificar que no está expirado
            local enddate=$(sudo openssl x509 -in "$cert_path" -noout -enddate 2>/dev/null | cut -d= -f2)
            local expiry_epoch=$(date -d "$enddate" +%s 2>/dev/null || echo 0)
            local now_epoch=$(date +%s)
            
            if [[ $expiry_epoch -gt $now_epoch ]]; then
                local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
                log_success "$cert válido ($days_left días restantes)"
            else
                log_error "$cert EXPIRADO"
            fi
        else
            log_error "$cert NO encontrado"
        fi
    done
}

################################################################################
# Verificación 7: Logs del Kubelet
################################################################################

check_kubelet_logs() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 7: LOGS DEL KUBELET"
    
    log_info "Verificando logs recientes del kubelet..."
    echo ""
    
    local error_count=$(sudo journalctl -u kubelet --since "5 minutes ago" | grep -i "error" | grep -v "Failed to list" | wc -l || echo 0)
    local cert_errors=$(sudo journalctl -u kubelet --since "5 minutes ago" | grep -i "certificate" | grep -i "error\|expired\|invalid" | wc -l || echo 0)
    
    if [[ $cert_errors -gt 0 ]]; then
        log_error "$cert_errors error(es) relacionado(s) con certificados en logs"
        echo ""
        log_info "Errores recientes:"
        sudo journalctl -u kubelet --since "5 minutes ago" | grep -i "certificate" | grep -i "error\|expired\|invalid" | tail -5
    elif [[ $error_count -gt 5 ]]; then
        log_warning "$error_count errores en kubelet (no relacionados con certs)"
    else
        log_success "No hay errores críticos en logs del kubelet"
    fi
}

################################################################################
# Verificación 8: Creación Real de Recurso
################################################################################

check_resource_creation() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 8: CREACIÓN DE RECURSO DE PRUEBA"
    
    log_info "Creando pod de prueba para validar funcionalidad completa..."
    echo ""
    
    # Crear pod
    if kubectl run test-cert-verification --image=nginx:alpine --restart=Never > /dev/null 2>&1; then
        log_success "Pod creado exitosamente"
        
        # Esperar a que esté Running
        sleep 5
        
        local status=$(kubectl get pod test-cert-verification -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        
        if [[ "$status" == "Running" || "$status" == "Pending" ]]; then
            log_success "Pod en estado: $status"
        else
            log_warning "Pod en estado inesperado: $status"
        fi
        
        # Limpiar
        kubectl delete pod test-cert-verification > /dev/null 2>&1
        log_info "Pod de prueba eliminado"
    else
        log_error "Fallo al crear pod de prueba"
        log_info "Puede indicar problemas con autenticación de certificados"
    fi
}

################################################################################
# Resumen Final
################################################################################

show_summary() {
    log_section "RESUMEN DE VERIFICACIÓN"
    
    local total=$((TOTAL_CHECKS))
    local passed=$CHECKS_PASSED
    local failed=$CHECKS_FAILED
    local warnings=$CHECKS_WARNING
    
    echo "Total de verificaciones: $total"
    echo "  ${GREEN}✓${NC} Pasadas:      $passed"
    echo "  ${YELLOW}⚠${NC} Advertencias: $warnings"
    echo "  ${RED}✗${NC} Fallidas:     $failed"
    echo ""
    
    if [[ $failed -eq 0 && $warnings -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}═════════════════════════════════════════════${NC}"
        echo -e "${GREEN}${BOLD}  ✅ TODAS LAS VERIFICACIONES PASARON${NC}"
        echo -e "${GREEN}${BOLD}═════════════════════════════════════════════${NC}"
        echo ""
        log_info "Los certificados están funcionando correctamente"
        log_info "El cluster está operacional"
        return 0
    elif [[ $failed -eq 0 ]]; then
        echo -e "${YELLOW}${BOLD}═════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}${BOLD}  ⚠️  VERIFICACIÓN CON ADVERTENCIAS${NC}"
        echo -e "${YELLOW}${BOLD}═════════════════════════════════════════════${NC}"
        echo ""
        log_warning "Revisa las advertencias arriba"
        log_info "El cluster está funcional pero puede requerir atención"
        return 1
    else
        echo -e "${RED}${BOLD}═════════════════════════════════════════════${NC}"
        echo -e "${RED}${BOLD}  ❌ ERRORES CRÍTICOS DETECTADOS${NC}"
        echo -e "${RED}${BOLD}═════════════════════════════════════════════${NC}"
        echo ""
        log_error "$failed verificación(es) fallaron"
        log_info "Revisa los errores arriba y toma acción correctiva"
        echo ""
        log_info "Comandos útiles para troubleshooting:"
        echo "  • sudo journalctl -u kubelet -f"
        echo "  • kubectl get pods -A"
        echo "  • sudo kubeadm certs check-expiration"
        echo "  • kubectl logs -n kube-system <pod-name>"
        return 2
    fi
}

################################################################################
# Main
################################################################################

main() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║     VERIFICACIÓN DE CERTIFICADOS POST-RENOVACIÓN      ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Verificar prerequisitos
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl no encontrado"
        exit 1
    fi
    
    if ! command -v kubeadm &> /dev/null; then
        log_error "kubeadm no encontrado"
        exit 1
    fi
    
    # Ejecutar verificaciones
    check_expiration_dates
    check_cluster_connectivity
    check_nodes_status
    check_control_plane_pods
    check_kubectl_functionality
    check_certs_with_openssl
    check_kubelet_logs
    check_resource_creation
    
    # Mostrar resumen
    show_summary
    
    local exit_code=$?
    
    echo ""
    log_info "Verificación completada"
    
    exit $exit_code
}

main "$@"
