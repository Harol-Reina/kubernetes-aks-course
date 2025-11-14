#!/bin/bash
#
# verify-ha.sh - Verificación completa de cluster HA
#
# Propósito:
#   Ejecuta una batería completa de tests para validar:
#   - Alta disponibilidad del control plane
#   - Funcionamiento del Load Balancer
#   - Health del cluster etcd
#   - Failover automático
#   - Resiliencia del cluster
#
# Uso:
#   ./verify-ha.sh [--master1-ip IP] [--lb-ip IP]
#
# Author: Kubernetes Course
# Version: 1.0
#

set -euo pipefail

#---------------------------------------------------------------------
# Variables globales
#---------------------------------------------------------------------

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

MASTER1_IP="${MASTER1_IP:-}"
LB_IP="${LB_IP:-}"
ERRORS=0
WARNINGS=0
TESTS_RUN=0

#---------------------------------------------------------------------
# Funciones de utilidad
#---------------------------------------------------------------------

pass() {
    echo -e "${GREEN}✅ PASS${NC}: $*"
    ((TESTS_RUN++))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $*"
    ((ERRORS++))
    ((TESTS_RUN++))
}

warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $*"
    ((WARNINGS++))
    ((TESTS_RUN++))
}

info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $*"
}

section() {
    echo ""
    echo "========================================" 
    echo "$1"
    echo "========================================"
    echo ""
}

usage() {
    cat <<EOF
Uso: $0 [OPTIONS]

Opciones:
  --master1-ip IP    IP del primer control plane (para ejecutar kubectl)
  --lb-ip IP         IP del Load Balancer
  --help             Mostrar esta ayuda

Si no se proporcionan IPs, se intentará detectarlas automáticamente.

Ejemplo:
  $0 --master1-ip 192.168.1.101 --lb-ip 192.168.1.100

EOF
    exit 1
}

#---------------------------------------------------------------------
# Parse argumentos
#---------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --master1-ip)
                MASTER1_IP="$2"
                shift 2
                ;;
            --lb-ip)
                LB_IP="$2"
                shift 2
                ;;
            --help)
                usage
                ;;
            *)
                echo "Opción desconocida: $1"
                usage
                ;;
        esac
    done
}

#---------------------------------------------------------------------
# Test 1: Verificar nodos del cluster
#---------------------------------------------------------------------

test_cluster_nodes() {
    section "Test 1: Verificar Nodos del Cluster"

    info "Obteniendo lista de nodos..."
    
    if ! kubectl get nodes &>/dev/null; then
        fail "No se puede conectar al cluster (verificar kubeconfig)"
        return
    fi

    # Contar nodos totales
    TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
    info "Total de nodos en el cluster: $TOTAL_NODES"

    # Contar control planes
    CONTROL_PLANES=$(kubectl get nodes --no-headers -l node-role.kubernetes.io/control-plane | wc -l)
    
    if [[ $CONTROL_PLANES -ge 3 ]]; then
        pass "Control planes detectados: $CONTROL_PLANES (mínimo 3 para HA)"
    elif [[ $CONTROL_PLANES -eq 2 ]]; then
        warn "Solo 2 control planes (recomendado: 3 o más para quorum)"
    else
        fail "Insuficientes control planes: $CONTROL_PLANES (mínimo 2 para HA)"
    fi

    # Verificar que todos estén Ready
    NOT_READY=$(kubectl get nodes --no-headers | grep -vc Ready || echo "0")
    
    if [[ $NOT_READY -eq 0 ]]; then
        pass "Todos los nodos están en estado Ready"
    else
        fail "$NOT_READY nodos NO están Ready"
        kubectl get nodes --no-headers | grep -v Ready
    fi

    # Mostrar info de nodos
    echo ""
    info "Detalle de nodos:"
    kubectl get nodes -o wide
}

#---------------------------------------------------------------------
# Test 2: Verificar componentes del control plane
#---------------------------------------------------------------------

test_control_plane_components() {
    section "Test 2: Verificar Componentes del Control Plane"

    # API Servers
    info "Verificando kube-apiserver..."
    API_SERVERS=$(kubectl get pods -n kube-system -l component=kube-apiserver --no-headers | grep -c Running || echo "0")
    
    if [[ $API_SERVERS -ge 3 ]]; then
        pass "kube-apiserver: $API_SERVERS réplicas corriendo"
    else
        fail "kube-apiserver: Solo $API_SERVERS réplicas corriendo (esperado: 3)"
    fi

    # Controller Manager
    info "Verificando kube-controller-manager..."
    CONTROLLERS=$(kubectl get pods -n kube-system -l component=kube-controller-manager --no-headers | grep -c Running || echo "0")
    
    if [[ $CONTROLLERS -ge 3 ]]; then
        pass "kube-controller-manager: $CONTROLLERS réplicas corriendo"
    else
        fail "kube-controller-manager: Solo $CONTROLLERS réplicas corriendo"
    fi

    # Scheduler
    info "Verificando kube-scheduler..."
    SCHEDULERS=$(kubectl get pods -n kube-system -l component=kube-scheduler --no-headers | grep -c Running || echo "0")
    
    if [[ $SCHEDULERS -ge 3 ]]; then
        pass "kube-scheduler: $SCHEDULERS réplicas corriendo"
    else
        fail "kube-scheduler: Solo $SCHEDULERS réplicas corriendo"
    fi

    # etcd
    info "Verificando etcd..."
    ETCD_PODS=$(kubectl get pods -n kube-system -l component=etcd --no-headers | grep -c Running || echo "0")
    
    if [[ $ETCD_PODS -ge 3 ]]; then
        pass "etcd: $ETCD_PODS miembros corriendo"
    else
        fail "etcd: Solo $ETCD_PODS miembros corriendo"
    fi

    # Mostrar pods del control plane
    echo ""
    info "Pods del control plane:"
    kubectl get pods -n kube-system -l tier=control-plane -o wide
}

#---------------------------------------------------------------------
# Test 3: Verificar etcd cluster
#---------------------------------------------------------------------

test_etcd_cluster() {
    section "Test 3: Verificar Cluster etcd"

    if [[ -z "$MASTER1_IP" ]]; then
        warn "No se proporcionó IP de master1, saltando test de etcd"
        return
    fi

    info "Verificando miembros de etcd..."
    
    ETCD_MEMBERS=$(ssh "$MASTER1_IP" "sudo ETCDCTL_API=3 etcdctl \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        member list" 2>/dev/null | wc -l || echo "0")

    if [[ $ETCD_MEMBERS -ge 3 ]]; then
        pass "etcd cluster tiene $ETCD_MEMBERS miembros"
    else
        fail "etcd cluster tiene solo $ETCD_MEMBERS miembros (esperado: 3)"
    fi

    # Verificar health de etcd
    info "Verificando health de endpoints etcd..."
    
    ETCD_HEALTH=$(ssh "$MASTER1_IP" "sudo ETCDCTL_API=3 etcdctl \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        endpoint health" 2>/dev/null || echo "")

    if echo "$ETCD_HEALTH" | grep -q "is healthy"; then
        HEALTHY_COUNT=$(echo "$ETCD_HEALTH" | grep -c "is healthy")
        pass "etcd health: $HEALTHY_COUNT endpoints saludables"
    else
        fail "etcd health check falló"
    fi

    # Mostrar lista de miembros
    echo ""
    info "Lista de miembros etcd:"
    ssh "$MASTER1_IP" "sudo ETCDCTL_API=3 etcdctl \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        member list" 2>/dev/null || warn "No se pudo obtener lista de miembros"
}

#---------------------------------------------------------------------
# Test 4: Verificar Load Balancer
#---------------------------------------------------------------------

test_load_balancer() {
    section "Test 4: Verificar Load Balancer"

    if [[ -z "$LB_IP" ]]; then
        warn "No se proporcionó IP del LB, saltando test"
        return
    fi

    # Verificar conectividad al LB
    info "Verificando conectividad al Load Balancer..."
    
    if ping -c 2 "$LB_IP" &>/dev/null; then
        pass "Conectividad al Load Balancer ($LB_IP): OK"
    else
        fail "No se puede alcanzar Load Balancer ($LB_IP)"
    fi

    # Verificar puerto 6443
    info "Verificando puerto 6443 en Load Balancer..."
    
    if nc -zv -w 2 "$LB_IP" 6443 2>&1 | grep -q succeeded; then
        pass "Puerto 6443 accesible en Load Balancer"
    else
        fail "Puerto 6443 NO accesible en Load Balancer"
    fi

    # Verificar API Server vía LB
    info "Verificando API Server vía Load Balancer..."
    
    if curl -k -s "https://${LB_IP}:6443/healthz" 2>/dev/null | grep -q "ok"; then
        pass "API Server responde correctamente vía Load Balancer"
    else
        fail "API Server NO responde vía Load Balancer"
    fi

    # Verificar stats HAProxy (si está habilitado)
    info "Verificando stats de HAProxy..."
    
    if curl -s "http://${LB_IP}:9090" 2>/dev/null | grep -q "HAProxy"; then
        pass "HAProxy stats accesible en http://${LB_IP}:9090"
    else
        warn "HAProxy stats no accesible (puede estar deshabilitado)"
    fi
}

#---------------------------------------------------------------------
# Test 5: Verificar distribución de workloads
#---------------------------------------------------------------------

test_workload_distribution() {
    section "Test 5: Verificar Distribución de Workloads"

    info "Creando deployment de prueba..."
    
    kubectl create deployment nginx-ha-test --image=nginx --replicas=3 2>/dev/null || \
        kubectl scale deployment nginx-ha-test --replicas=3 &>/dev/null

    # Esperar a que los pods estén corriendo
    info "Esperando a que pods estén corriendo..."
    for i in {1..30}; do
        RUNNING_PODS=$(kubectl get pods -l app=nginx-ha-test --no-headers | grep -c Running || echo "0")
        if [[ $RUNNING_PODS -eq 3 ]]; then
            break
        fi
        sleep 2
    done

    if [[ $RUNNING_PODS -eq 3 ]]; then
        pass "3 réplicas de nginx-ha-test corriendo"
    else
        fail "Solo $RUNNING_PODS de 3 réplicas corriendo"
    fi

    # Verificar distribución de pods
    info "Verificando distribución de pods entre nodos..."
    kubectl get pods -l app=nginx-ha-test -o wide

    # Cleanup
    info "Limpiando deployment de prueba..."
    kubectl delete deployment nginx-ha-test --wait=false &>/dev/null
}

#---------------------------------------------------------------------
# Test 6: Test de failover (simulación)
#---------------------------------------------------------------------

test_failover_simulation() {
    section "Test 6: Test de Failover (Simulación)"

    info "Este test simula un failover verificando resiliencia del cluster"

    # Crear pod de prueba
    info "Creando pod de prueba..."
    kubectl run failover-test --image=nginx --restart=Never 2>/dev/null || true

    # Esperar a que esté corriendo
    for i in {1..20}; do
        if kubectl get pod failover-test -o jsonpath='{.status.phase}' 2>/dev/null | grep -q Running; then
            break
        fi
        sleep 2
    done

    if kubectl get pod failover-test &>/dev/null; then
        pass "Pod de prueba creado exitosamente"
    else
        fail "No se pudo crear pod de prueba"
    fi

    # Verificar que el cluster puede crear recursos
    info "Verificando capacidad de crear recursos..."
    
    if kubectl create namespace ha-test-$(date +%s) &>/dev/null; then
        pass "Cluster puede crear recursos (API Server operativo)"
    else
        fail "Cluster NO puede crear recursos"
    fi

    # Cleanup
    kubectl delete pod failover-test --wait=false &>/dev/null 2>&1 || true
    kubectl delete ns --selector='!kube' --wait=false &>/dev/null 2>&1 || true
}

#---------------------------------------------------------------------
# Test 7: Verificar certificados
#---------------------------------------------------------------------

test_certificates() {
    section "Test 7: Verificar Certificados"

    if [[ -z "$MASTER1_IP" ]]; then
        warn "No se proporcionó IP de master1, saltando test de certificados"
        return
    fi

    info "Verificando expiración de certificados..."
    
    CERT_INFO=$(ssh "$MASTER1_IP" "sudo kubeadm certs check-expiration" 2>/dev/null || echo "")

    if echo "$CERT_INFO" | grep -q "CERTIFICATE"; then
        pass "Certificados verificados correctamente"
        
        # Buscar certificados próximos a expirar (< 30 días)
        if echo "$CERT_INFO" | grep -E "[0-9]+d" | awk '{print $3}' | sed 's/d//' | \
           awk '$1 < 30 {exit 1}'; then
            warn "Algunos certificados expiran en menos de 30 días"
        else
            pass "Todos los certificados tienen más de 30 días de validez"
        fi
    else
        fail "No se pudo verificar certificados"
    fi

    # Mostrar info de certificados
    echo ""
    info "Detalle de certificados:"
    echo "$CERT_INFO" | head -15
}

#---------------------------------------------------------------------
# Test 8: Verificar API Server health
#---------------------------------------------------------------------

test_api_health() {
    section "Test 8: Verificar Health del API Server"

    # Healthz endpoint
    info "Verificando /healthz..."
    
    if kubectl get --raw='/healthz' 2>/dev/null | grep -q "ok"; then
        pass "/healthz responde correctamente"
    else
        fail "/healthz NO responde correctamente"
    fi

    # Livez endpoint
    info "Verificando /livez..."
    
    if kubectl get --raw='/livez' 2>/dev/null | grep -q "ok"; then
        pass "/livez responde correctamente"
    else
        fail "/livez NO responde correctamente"
    fi

    # Readyz endpoint
    info "Verificando /readyz..."
    
    if kubectl get --raw='/readyz' 2>/dev/null | grep -q "ok"; then
        pass "/readyz responde correctamente"
    else
        fail "/readyz NO responde correctamente"
    fi
}

#---------------------------------------------------------------------
# Resumen final
#---------------------------------------------------------------------

print_summary() {
    section "📊 Resumen de Verificación"

    echo "Tests ejecutados: $TESTS_RUN"
    echo -e "Errores: ${RED}$ERRORS${NC}"
    echo -e "Advertencias: ${YELLOW}$WARNINGS${NC}"
    echo ""

    if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}✅ CLUSTER HA VERIFICADO CORRECTAMENTE${NC}"
        echo "El cluster está completamente operativo y en alta disponibilidad."
        return 0
    elif [[ $ERRORS -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  CLUSTER HA OPERATIVO CON ADVERTENCIAS${NC}"
        echo "El cluster funciona pero tiene $WARNINGS advertencias."
        echo "Revisa las advertencias para optimizar la configuración."
        return 0
    else
        echo -e "${RED}❌ CLUSTER HA TIENE PROBLEMAS${NC}"
        echo "Se encontraron $ERRORS errores críticos."
        echo "Revisa los fallos y corrígelos antes de usar en producción."
        return 1
    fi
}

#---------------------------------------------------------------------
# Main
#---------------------------------------------------------------------

main() {
    echo "========================================"
    echo "🔍 Verificación de Cluster HA"
    echo "========================================"
    echo ""

    parse_args "$@"

    # Detectar IPs automáticamente si no se proporcionaron
    if [[ -z "$MASTER1_IP" ]]; then
        info "Intentando detectar IP de master1..."
        MASTER1_IP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")
        if [[ -n "$MASTER1_IP" ]]; then
            info "Master1 IP detectada: $MASTER1_IP"
        fi
    fi

    if [[ -z "$LB_IP" ]]; then
        info "Intentando detectar IP del Load Balancer..."
        LB_IP=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null | grep -oP '//\K[^:]+' || echo "")
        if [[ -n "$LB_IP" ]]; then
            info "Load Balancer IP detectada: $LB_IP"
        fi
    fi

    # Ejecutar tests
    test_cluster_nodes
    test_control_plane_components
    test_etcd_cluster
    test_load_balancer
    test_workload_distribution
    test_failover_simulation
    test_certificates
    test_api_health

    # Resumen
    print_summary
}

# Ejecutar
main "$@"
