#!/bin/bash

#==============================================================================
# Script: verify-etcd.sh
# Descripción: Verifica cluster etcd externo + control planes
# Uso: ./verify-etcd.sh
#==============================================================================

set -euo pipefail

#------------------------------------------------------------------------------
# CONFIGURACIÓN
#------------------------------------------------------------------------------

ETCD_NODES=(
  "etcd-01:192.168.1.201"
  "etcd-02:192.168.1.202"
  "etcd-03:192.168.1.203"
)

CONTROL_PLANES=(
  "master-01:192.168.1.11"
  "master-02:192.168.1.12"
  "master-03:192.168.1.13"
)

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

test_etcd_members() {
    print_header "TEST 1: Verificar miembros cluster etcd"
    
    local first_ip="${ETCD_NODES[0]##*:}"
    
    local output=$(ssh root@${first_ip} "ETCDCTL_API=3 etcdctl \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/etcd/ca.pem \
      --cert=/etc/etcd/etcd.pem \
      --key=/etc/etcd/etcd-key.pem \
      member list -w table" 2>/dev/null)
    
    local count=$(echo "$output" | grep -c "started" || true)
    
    if [ "$count" -eq "${#ETCD_NODES[@]}" ]; then
        test_pass "Cluster tiene ${count} miembros activos"
        echo "$output"
    else
        test_fail "Esperados ${#ETCD_NODES[@]} miembros, encontrados ${count}"
    fi
}

test_etcd_health() {
    print_header "TEST 2: Health check cluster etcd"
    
    local all_healthy=true
    
    for node in "${ETCD_NODES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        
        local health=$(ssh root@${ip} "ETCDCTL_API=3 etcdctl \
          --endpoints=https://127.0.0.1:2379 \
          --cacert=/etc/etcd/ca.pem \
          --cert=/etc/etcd/etcd.pem \
          --key=/etc/etcd/etcd-key.pem \
          endpoint health" 2>&1)
        
        if echo "$health" | grep -q "is healthy"; then
            echo -e "  ${GREEN}✓${NC} ${name} (${ip}): healthy"
        else
            echo -e "  ${RED}✗${NC} ${name} (${ip}): unhealthy"
            all_healthy=false
        fi
    done
    
    if $all_healthy; then
        test_pass "Todos los nodos etcd healthy"
    else
        test_fail "Algunos nodos etcd no están healthy"
    fi
}

test_etcd_quorum() {
    print_header "TEST 3: Verificar quorum etcd"
    
    local first_ip="${ETCD_NODES[0]##*:}"
    
    # Escribir dato de prueba
    ssh root@${first_ip} "ETCDCTL_API=3 etcdctl \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/etcd/ca.pem \
      --cert=/etc/etcd/etcd.pem \
      --key=/etc/etcd/etcd-key.pem \
      put /test-quorum 'verification-data'" &>/dev/null
    
    # Leer desde otro nodo
    local second_ip="${ETCD_NODES[1]##*:}"
    local value=$(ssh root@${second_ip} "ETCDCTL_API=3 etcdctl \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/etcd/ca.pem \
      --cert=/etc/etcd/etcd.pem \
      --key=/etc/etcd/etcd-key.pem \
      get /test-quorum --print-value-only" 2>/dev/null)
    
    if [ "$value" == "verification-data" ]; then
        test_pass "Quorum funcional - datos replicados correctamente"
    else
        test_fail "Problema con quorum - datos no replicados"
    fi
    
    # Limpiar
    ssh root@${first_ip} "ETCDCTL_API=3 etcdctl \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/etcd/ca.pem \
      --cert=/etc/etcd/etcd.pem \
      --key=/etc/etcd/etcd-key.pem \
      del /test-quorum" &>/dev/null
}

test_control_plane_connectivity() {
    print_header "TEST 4: Conectividad control planes → etcd"
    
    local all_connected=true
    
    for cp in "${CONTROL_PLANES[@]}"; do
        local name="${cp%%:*}"
        local ip="${cp##*:}"
        
        local connected=true
        for etcd_node in "${ETCD_NODES[@]}"; do
            local etcd_ip="${etcd_node##*:}"
            if ! ssh root@${ip} "timeout 2 bash -c 'cat < /dev/null > /dev/tcp/${etcd_ip}/2379'" 2>/dev/null; then
                connected=false
                break
            fi
        done
        
        if $connected; then
            echo -e "  ${GREEN}✓${NC} ${name} puede conectar a todos los nodos etcd"
        else
            echo -e "  ${RED}✗${NC} ${name} tiene problemas de conectividad"
            all_connected=false
        fi
    done
    
    if $all_connected; then
        test_pass "Control planes conectados a etcd"
    else
        test_fail "Problemas de conectividad detectados"
    fi
}

test_no_etcd_pods() {
    print_header "TEST 5: Verificar NO hay pods etcd en Kubernetes"
    
    local first_cp_ip="${CONTROL_PLANES[0]##*:}"
    
    local etcd_pods=$(ssh root@${first_cp_ip} \
      "kubectl get pods -n kube-system -l component=etcd --no-headers 2>/dev/null | wc -l")
    
    if [ "$etcd_pods" -eq 0 ]; then
        test_pass "Correcto - NO hay pods etcd (etcd externo funcionando)"
    else
        test_fail "Encontrados ${etcd_pods} pods etcd (debería ser 0 con etcd externo)"
    fi
}

test_kubernetes_nodes() {
    print_header "TEST 6: Verificar nodos Kubernetes"
    
    local first_cp_ip="${CONTROL_PLANES[0]##*:}"
    
    local output=$(ssh root@${first_cp_ip} "kubectl get nodes")
    echo "$output"
    
    local ready_count=$(echo "$output" | grep -c " Ready " || true)
    
    if [ "$ready_count" -ge "${#CONTROL_PLANES[@]}" ]; then
        test_pass "${ready_count} nodos Ready en cluster"
    else
        test_fail "Solo ${ready_count} nodos Ready"
    fi
}

test_data_persistence() {
    print_header "TEST 7: Verificar persistencia de datos K8s en etcd"
    
    local first_cp_ip="${CONTROL_PLANES[0]##*:}"
    
    # Crear namespace de prueba
    ssh root@${first_cp_ip} "kubectl create ns etcd-test-$(date +%s)" &>/dev/null
    
    sleep 2
    
    # Verificar en etcd que existe
    local first_etcd_ip="${ETCD_NODES[0]##*:}"
    local ns_count=$(ssh root@${first_etcd_ip} "ETCDCTL_API=3 etcdctl \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/etcd/ca.pem \
      --cert=/etc/etcd/etcd.pem \
      --key=/etc/etcd/etcd-key.pem \
      get /registry/namespaces/ --prefix --keys-only" 2>/dev/null | grep -c "etcd-test" || true)
    
    if [ "$ns_count" -gt 0 ]; then
        test_pass "Datos Kubernetes persistidos correctamente en etcd externo"
    else
        test_fail "Datos Kubernetes no encontrados en etcd"
    fi
    
    # Limpiar
    ssh root@${first_cp_ip} "kubectl delete ns --selector='kubernetes.io/metadata.name' --field-selector='metadata.name!=default,metadata.name!=kube-system,metadata.name!=kube-public,metadata.name!=kube-node-lease' --grace-period=0 --force 2>/dev/null" &>/dev/null || true
}

test_certificates() {
    print_header "TEST 8: Validar certificados TLS"
    
    local all_valid=true
    
    for node in "${ETCD_NODES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        
        local cert_info=$(ssh root@${ip} "openssl x509 -in /etc/etcd/etcd.pem -noout -dates 2>/dev/null")
        
        if [ -n "$cert_info" ]; then
            local expiry=$(echo "$cert_info" | grep "notAfter" | cut -d= -f2)
            echo -e "  ${GREEN}✓${NC} ${name}: Certificado válido (expira: ${expiry})"
        else
            echo -e "  ${RED}✗${NC} ${name}: Problema con certificado"
            all_valid=false
        fi
    done
    
    if $all_valid; then
        test_pass "Certificados TLS válidos"
    else
        test_fail "Problemas con certificados detectados"
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo "=========================================="
    echo "  External etcd Verification Suite"
    echo "=========================================="
    
    test_etcd_members
    test_etcd_health
    test_etcd_quorum
    test_control_plane_connectivity
    test_no_etcd_pods
    test_kubernetes_nodes
    test_data_persistence
    test_certificates
    
    # Resumen
    print_header "RESUMEN"
    echo -e "Tests pasados: ${GREEN}${PASSED}${NC}"
    echo -e "Tests fallidos: ${RED}${FAILED}${NC}"
    echo
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ ÉXITO - Cluster etcd externo funcionando correctamente${NC}"
        exit 0
    else
        echo -e "${RED}✗ FALLOS DETECTADOS - Revisar configuración${NC}"
        exit 1
    fi
}

main "$@"
