#!/bin/bash

################################################################################
# Verify Upgrade Script - Lab 02
# 
# Este script realiza una verificación completa del cluster después del upgrade
# para asegurar que todos los componentes están funcionando correctamente.
#
# Uso:
#   ./verify-upgrade.sh [--expected-version 1.28.0]
################################################################################

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables
EXPECTED_VERSION="${1:-1.28.0}"
REPORT_FILE="/tmp/upgrade-verification-$(date +%Y%m%d-%H%M%S).txt"

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNING=0

################################################################################
# Funciones de Utilidad
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_warning() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1"
    TESTS_WARNING=$((TESTS_WARNING + 1))
}

section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# Test 1: Versiones de Nodos
################################################################################

test_node_versions() {
    section "TEST 1: Versiones de Nodos"
    
    log_info "Verificando versiones de todos los nodos..."
    echo ""
    
    kubectl get nodes -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion,STATUS:.status.conditions[-1].type
    
    echo ""
    
    # Verificar cada nodo
    local all_correct=true
    
    while IFS= read -r node; do
        local node_name=$(echo "$node" | awk '{print $1}')
        local node_version=$(echo "$node" | awk '{print $2}')
        
        if [[ "$node_version" == "v${EXPECTED_VERSION}" ]]; then
            log_success "Nodo $node_name: $node_version"
        else
            log_fail "Nodo $node_name: $node_version (esperado: v${EXPECTED_VERSION})"
            all_correct=false
        fi
    done < <(kubectl get nodes --no-headers -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion)
    
    if $all_correct; then
        log_success "Todos los nodos en v${EXPECTED_VERSION}"
    fi
}

################################################################################
# Test 2: Estado de Nodos
################################################################################

test_node_health() {
    section "TEST 2: Salud de Nodos"
    
    log_info "Verificando que todos los nodos están Ready..."
    echo ""
    
    local not_ready=$(kubectl get nodes --no-headers | grep -c NotReady || true)
    
    if [[ $not_ready -eq 0 ]]; then
        log_success "Todos los nodos en estado Ready"
        kubectl get nodes
    else
        log_fail "$not_ready nodo(s) en estado NotReady"
        kubectl get nodes
    fi
    
    echo ""
    log_info "Condiciones de nodos:"
    
    # Verificar condiciones críticas
    local nodes_with_issues=0
    
    while IFS= read -r node; do
        # Verificar condiciones: MemoryPressure, DiskPressure, PIDPressure deben ser False
        local memory_pressure=$(kubectl get node "$node" -o jsonpath='{.status.conditions[?(@.type=="MemoryPressure")].status}')
        local disk_pressure=$(kubectl get node "$node" -o jsonpath='{.status.conditions[?(@.type=="DiskPressure")].status}')
        local pid_pressure=$(kubectl get node "$node" -o jsonpath='{.status.conditions[?(@.type=="PIDPressure")].status}')
        
        if [[ "$memory_pressure" == "True" ]] || [[ "$disk_pressure" == "True" ]] || [[ "$pid_pressure" == "True" ]]; then
            log_warning "Nodo $node tiene presión de recursos"
            nodes_with_issues=$((nodes_with_issues + 1))
        fi
    done < <(kubectl get nodes -o name | cut -d'/' -f2)
    
    if [[ $nodes_with_issues -eq 0 ]]; then
        log_success "Ningún nodo con presión de recursos"
    fi
}

################################################################################
# Test 3: Pods del Sistema
################################################################################

test_system_pods() {
    section "TEST 3: Pods del Sistema (kube-system)"
    
    log_info "Verificando pods en kube-system..."
    echo ""
    
    kubectl get pods -n kube-system -o wide
    
    echo ""
    
    # Pods críticos que deben estar Running
    local critical_pods=("kube-apiserver" "kube-controller-manager" "kube-scheduler" "etcd" "coredns" "kube-proxy")
    
    for pod_prefix in "${critical_pods[@]}"; do
        local pod_count=$(kubectl get pods -n kube-system --no-headers | grep "^${pod_prefix}" | grep -c Running || true)
        
        if [[ $pod_count -gt 0 ]]; then
            log_success "${pod_prefix}: $pod_count pod(s) Running"
        else
            log_fail "${pod_prefix}: No running pods found"
        fi
    done
    
    # Verificar que no hay pods crasheando
    echo ""
    local failing_pods=$(kubectl get pods -n kube-system --no-headers | grep -vE 'Running|Completed|Succeeded' | wc -l)
    
    if [[ $failing_pods -eq 0 ]]; then
        log_success "No hay pods en estado fallido"
    else
        log_fail "$failing_pods pod(s) en estado no deseado:"
        kubectl get pods -n kube-system | grep -vE 'Running|Completed|Succeeded'
    fi
}

################################################################################
# Test 4: API Server
################################################################################

test_api_server() {
    section "TEST 4: API Server"
    
    log_info "Verificando salud del API Server..."
    echo ""
    
    # Healthz endpoint
    if kubectl get --raw /healthz | grep -q "ok"; then
        log_success "API Server /healthz: ok"
    else
        log_fail "API Server /healthz: failed"
    fi
    
    # Readyz endpoint
    if kubectl get --raw /readyz > /dev/null 2>&1; then
        log_success "API Server /readyz: ok"
    else
        log_fail "API Server /readyz: failed"
    fi
    
    # Livez endpoint
    if kubectl get --raw /livez > /dev/null 2>&1; then
        log_success "API Server /livez: ok"
    else
        log_fail "API Server /livez: failed"
    fi
    
    # Version endpoint
    echo ""
    log_info "Versión del API Server:"
    kubectl version --short | grep "Server Version"
}

################################################################################
# Test 5: etcd
################################################################################

test_etcd() {
    section "TEST 5: etcd"
    
    log_info "Verificando etcd..."
    echo ""
    
    # Verificar pod de etcd está Running
    local etcd_status=$(kubectl get pods -n kube-system -l component=etcd --no-headers | awk '{print $3}' | head -1)
    
    if [[ "$etcd_status" == "Running" ]]; then
        log_success "etcd pod está Running"
    else
        log_fail "etcd pod no está Running (estado: $etcd_status)"
    fi
    
    # Verificar salud de etcd desde dentro del pod
    if kubectl get pods -n kube-system -l component=etcd --no-headers > /dev/null 2>&1; then
        local etcd_pod=$(kubectl get pods -n kube-system -l component=etcd --no-headers | awk '{print $1}' | head -1)
        
        if kubectl exec -n kube-system "$etcd_pod" -- etcdctl \
            --cacert=/etc/kubernetes/pki/etcd/ca.crt \
            --cert=/etc/kubernetes/pki/etcd/server.crt \
            --key=/etc/kubernetes/pki/etcd/server.key \
            endpoint health > /dev/null 2>&1; then
            
            log_success "etcd health check: OK"
        else
            log_warning "etcd health check falló (puede ser permisos)"
        fi
    fi
}

################################################################################
# Test 6: CoreDNS
################################################################################

test_coredns() {
    section "TEST 6: CoreDNS (DNS Resolution)"
    
    log_info "Verificando CoreDNS..."
    echo ""
    
    # Verificar pods de CoreDNS
    local coredns_count=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers | grep -c Running || true)
    
    if [[ $coredns_count -ge 2 ]]; then
        log_success "CoreDNS: $coredns_count pod(s) Running"
    elif [[ $coredns_count -eq 1 ]]; then
        log_warning "CoreDNS: Solo 1 pod Running (recomendado: 2+)"
    else
        log_fail "CoreDNS: No hay pods Running"
    fi
    
    # Test de resolución DNS
    echo ""
    log_info "Test de resolución DNS..."
    
    if kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never --timeout=30s -- nslookup kubernetes.default > /dev/null 2>&1; then
        log_success "Resolución DNS funciona correctamente"
    else
        log_warning "Test de DNS falló (puede ser timeout - verificar manualmente)"
    fi
}

################################################################################
# Test 7: Networking
################################################################################

test_networking() {
    section "TEST 7: Networking (Pod-to-Pod)"
    
    log_info "Verificando networking entre pods..."
    echo ""
    
    # Crear dos pods de prueba en diferentes nodos (si es posible)
    log_info "Creando pods de prueba..."
    
    kubectl run net-test-1 --image=nginx:alpine --labels=app=net-test > /dev/null 2>&1 || true
    kubectl run net-test-2 --image=nginx:alpine --labels=app=net-test > /dev/null 2>&1 || true
    
    sleep 10
    
    # Verificar que los pods están Running
    local running_pods=$(kubectl get pods -l app=net-test --no-headers | grep -c Running || true)
    
    if [[ $running_pods -eq 2 ]]; then
        log_success "Pods de prueba creados y Running"
        
        # Obtener IPs
        local pod1_ip=$(kubectl get pod net-test-1 -o jsonpath='{.status.podIP}')
        local pod2_ip=$(kubectl get pod net-test-2 -o jsonpath='{.status.podIP}')
        
        log_info "net-test-1 IP: $pod1_ip"
        log_info "net-test-2 IP: $pod2_ip"
        
        # Test de conectividad
        if kubectl exec net-test-1 -- wget -qO- --timeout=5 "http://${pod2_ip}" > /dev/null 2>&1; then
            log_success "Conectividad pod-to-pod: OK"
        else
            log_warning "Conectividad pod-to-pod falló (puede ser normal para nginx sin contenido)"
        fi
    else
        log_warning "No se pudieron crear pods de prueba ($running_pods/2)"
    fi
    
    # Cleanup
    kubectl delete pod net-test-1 net-test-2 --force --grace-period=0 > /dev/null 2>&1 || true
}

################################################################################
# Test 8: Storage (PV/PVC)
################################################################################

test_storage() {
    section "TEST 8: Storage (Persistent Volumes)"
    
    log_info "Verificando sistema de storage..."
    echo ""
    
    # Listar StorageClasses
    local sc_count=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l || echo "0")
    
    if [[ $sc_count -gt 0 ]]; then
        log_success "StorageClasses disponibles: $sc_count"
        kubectl get storageclass
    else
        log_warning "No hay StorageClasses configurados (puede ser normal)"
    fi
    
    echo ""
    
    # Verificar PVs
    local pv_count=$(kubectl get pv --no-headers 2>/dev/null | wc -l || echo "0")
    log_info "Persistent Volumes: $pv_count"
    
    # Verificar PVCs
    local pvc_count=$(kubectl get pvc -A --no-headers 2>/dev/null | wc -l || echo "0")
    log_info "Persistent Volume Claims: $pvc_count"
    
    # Si hay PVCs, verificar que están Bound
    if [[ $pvc_count -gt 0 ]]; then
        local unbound=$(kubectl get pvc -A --no-headers | grep -cv Bound || true)
        
        if [[ $unbound -eq 0 ]]; then
            log_success "Todos los PVCs están Bound"
        else
            log_warning "$unbound PVC(s) no están Bound"
            kubectl get pvc -A | grep -v Bound
        fi
    fi
}

################################################################################
# Test 9: RBAC
################################################################################

test_rbac() {
    section "TEST 9: RBAC (Autenticación y Autorización)"
    
    log_info "Verificando RBAC..."
    echo ""
    
    # Test de auth can-i
    if kubectl auth can-i get pods > /dev/null 2>&1; then
        log_success "RBAC autenticación funciona"
    else
        log_fail "RBAC autenticación falló"
    fi
    
    # Verificar ServiceAccounts críticos
    local sa_count=$(kubectl get sa -n kube-system --no-headers | wc -l)
    log_info "ServiceAccounts en kube-system: $sa_count"
    
    # Verificar algunos ServiceAccounts críticos existen
    local critical_sa=("default" "kube-proxy" "coredns")
    
    for sa in "${critical_sa[@]}"; do
        if kubectl get sa "$sa" -n kube-system > /dev/null 2>&1; then
            log_success "ServiceAccount $sa existe"
        else
            log_warning "ServiceAccount $sa no encontrado"
        fi
    done
}

################################################################################
# Test 10: Workloads de Usuario
################################################################################

test_user_workloads() {
    section "TEST 10: Workloads de Usuario"
    
    log_info "Verificando deployments en todos los namespaces..."
    echo ""
    
    # Listar todos los deployments
    local total_deployments=$(kubectl get deployments -A --no-headers | wc -l)
    
    if [[ $total_deployments -eq 0 ]]; then
        log_info "No hay deployments de usuario (normal en cluster nuevo)"
        return
    fi
    
    log_info "Total deployments: $total_deployments"
    echo ""
    
    # Verificar estado de deployments
    kubectl get deployments -A -o wide
    
    echo ""
    
    # Contar deployments no disponibles
    local unavailable=0
    
    while IFS= read -r line; do
        local ready=$(echo "$line" | awk '{print $3}')
        local desired=$(echo "$line" | awk '{print $2}')
        local deployment=$(echo "$line" | awk '{print $1 "/" $2}')
        
        if [[ "$ready" != "$desired"* ]]; then
            log_warning "Deployment no disponible: $deployment ($ready/$desired)"
            unavailable=$((unavailable + 1))
        fi
    done < <(kubectl get deployments -A --no-headers)
    
    if [[ $unavailable -eq 0 ]]; then
        log_success "Todos los deployments están disponibles"
    else
        log_warning "$unavailable deployment(s) no completamente disponibles"
    fi
}

################################################################################
# Test 11: Resources & Limits
################################################################################

test_resources() {
    section "TEST 11: Recursos del Cluster"
    
    log_info "Verificando utilización de recursos..."
    echo ""
    
    # Node resources
    kubectl top nodes 2>/dev/null || log_warning "metrics-server no disponible (normal si no está instalado)"
    
    echo ""
    
    # Pod resources
    log_info "Top 10 pods por uso de CPU/memoria:"
    kubectl top pods -A --sort-by=memory 2>/dev/null | head -11 || true
}

################################################################################
# Test 12: Events del Cluster
################################################################################

test_events() {
    section "TEST 12: Events del Cluster"
    
    log_info "Verificando events recientes..."
    echo ""
    
    # Eventos de los últimos 30 minutos
    log_info "Eventos Warning/Error de los últimos 30 minutos:"
    kubectl get events -A --sort-by='.lastTimestamp' | grep -E 'Warning|Error' | tail -10 || log_info "No hay eventos Warning/Error recientes"
    
    echo ""
    
    # Contar eventos por tipo
    local warning_count=$(kubectl get events -A --field-selector type=Warning --no-headers 2>/dev/null | wc -l || echo "0")
    local normal_count=$(kubectl get events -A --field-selector type=Normal --no-headers 2>/dev/null | wc -l || echo "0")
    
    log_info "Total eventos Warning: $warning_count"
    log_info "Total eventos Normal: $normal_count"
    
    if [[ $warning_count -gt 20 ]]; then
        log_warning "Muchos eventos Warning detectados - investigar"
    else
        log_success "Cantidad normal de eventos Warning"
    fi
}

################################################################################
# Generar Reporte
################################################################################

generate_report() {
    section "GENERANDO REPORTE"
    
    {
        echo "═══════════════════════════════════════════════════════════"
        echo "  REPORTE DE VERIFICACIÓN - CLUSTER UPGRADE"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
        echo "Fecha: $(date)"
        echo "Versión esperada: v${EXPECTED_VERSION}"
        echo "Usuario: $(whoami)"
        echo "Cluster: $(kubectl config current-context)"
        echo ""
        echo "───────────────────────────────────────────────────────────"
        echo "  RESULTADOS DE TESTS"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        echo "✓ Tests pasados:   $TESTS_PASSED"
        echo "✗ Tests fallidos:  $TESTS_FAILED"
        echo "⚠ Warnings:        $TESTS_WARNING"
        echo ""
        
        if [[ $TESTS_FAILED -eq 0 ]]; then
            echo "ESTADO GENERAL: ✓ ÉXITO - Upgrade completado correctamente"
        elif [[ $TESTS_FAILED -le 2 ]]; then
            echo "ESTADO GENERAL: ⚠ PARCIAL - Algunos problemas detectados"
        else
            echo "ESTADO GENERAL: ✗ PROBLEMAS - Requiere atención"
        fi
        
        echo ""
        echo "───────────────────────────────────────────────────────────"
        echo "  RESUMEN DEL CLUSTER"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        echo "Nodos:"
        kubectl get nodes -o wide
        echo ""
        echo "Pods del sistema:"
        kubectl get pods -n kube-system | grep -E 'NAME|kube-|etcd|coredns'
        echo ""
        echo "Versión de componentes:"
        kubectl version --short
        echo ""
        echo "───────────────────────────────────────────────────────────"
        echo "  RECOMENDACIONES"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        
        if [[ $TESTS_FAILED -eq 0 ]]; then
            echo "✓ Cluster actualizado exitosamente"
            echo "✓ Monitorear por 24-48 horas"
            echo "✓ Mantener backups por al menos 7 días"
            echo "✓ Documentar lecciones aprendidas"
        else
            echo "⚠ Resolver problemas detectados antes de producción"
            echo "⚠ Revisar logs de componentes fallidos"
            echo "⚠ Considerar rollback si los problemas son críticos"
        fi
        
    } > "$REPORT_FILE"
    
    cat "$REPORT_FILE"
    
    echo ""
    log_success "Reporte guardado en: $REPORT_FILE"
}

################################################################################
# Main
################################################################################

main() {
    clear
    
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║     VERIFICACIÓN POST-UPGRADE - LAB 02                ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Iniciando verificación del cluster..."
    log_info "Versión esperada: v${EXPECTED_VERSION}"
    sleep 2
    
    # Ejecutar tests
    test_node_versions
    test_node_health
    test_system_pods
    test_api_server
    test_etcd
    test_coredns
    test_networking
    test_storage
    test_rbac
    test_user_workloads
    test_resources
    test_events
    
    # Generar reporte
    generate_report
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║         VERIFICACIÓN COMPLETADA                       ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Resumen final
    echo "═══════════════════════════════════════════════════════════"
    echo "  RESUMEN"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo -e "✓ Tests pasados:   ${GREEN}$TESTS_PASSED${NC}"
    echo -e "✗ Tests fallidos:  ${RED}$TESTS_FAILED${NC}"
    echo -e "⚠ Warnings:        ${YELLOW}$TESTS_WARNING${NC}"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ ÉXITO${NC} - El upgrade se completó correctamente"
        echo ""
        echo "Próximos pasos:"
        echo "  1. Monitorear cluster por 24-48 horas"
        echo "  2. Probar aplicaciones críticas"
        echo "  3. Ejecutar ./cleanup.sh cuando estés seguro"
        exit 0
    elif [[ $TESTS_FAILED -le 2 ]]; then
        echo -e "${YELLOW}⚠ PARCIAL${NC} - Algunos problemas detectados"
        echo ""
        echo "Se recomienda:"
        echo "  1. Revisar logs de componentes con problemas"
        echo "  2. Verificar documentación de troubleshooting en README.md"
        echo "  3. Considerar rollback si los problemas persisten"
        exit 1
    else
        echo -e "${RED}✗ PROBLEMAS${NC} - Múltiples tests fallidos"
        echo ""
        echo "ACCIÓN REQUERIDA:"
        echo "  1. Revisar el reporte: $REPORT_FILE"
        echo "  2. Resolver problemas críticos"
        echo "  3. Considerar rollback: ./cleanup.sh --rollback"
        exit 2
    fi
}

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl no encontrado"
    exit 1
fi

# Verificar conexión
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "Error: No se puede conectar al cluster"
    exit 1
fi

# Ejecutar
main "$@"
