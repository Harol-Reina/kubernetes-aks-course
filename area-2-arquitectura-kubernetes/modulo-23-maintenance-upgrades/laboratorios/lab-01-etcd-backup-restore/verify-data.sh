#!/bin/bash
#
# verify-data.sh - Script de verificación de datos en etcd
#
# Verifica que los datos esperados existen en el cluster después de un restore
#
# Uso: ./verify-data.sh [namespace]
#
# Autor: Kubernetes Course - Módulo 23
# Versión: 1.0
# Fecha: 2025-11-13

set -euo pipefail

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables
TARGET_NAMESPACE="${1:-backup-test}"
VERBOSE=false

# =============================================================================
# FUNCIONES
# =============================================================================

print_header() {
    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║       VERIFICACIÓN DE DATOS EN CLUSTER KUBERNETES          ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_api_server() {
    echo -n "Verificando API Server... "
    
    if kubectl version --short &>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ NO RESPONDE${NC}"
        return 1
    fi
}

check_namespace() {
    local ns="$1"
    echo -n "Verificando namespace '$ns'... "
    
    if kubectl get namespace "$ns" &>/dev/null; then
        echo -e "${GREEN}✅ EXISTE${NC}"
        return 0
    else
        echo -e "${RED}❌ NO EXISTE${NC}"
        return 1
    fi
}

check_deployments() {
    local ns="$1"
    echo ""
    echo "📦 Deployments en namespace '$ns':"
    
    local deployments=$(kubectl get deployments -n "$ns" --no-headers 2>/dev/null | wc -l)
    
    if [ "$deployments" -gt 0 ]; then
        kubectl get deployments -n "$ns" -o wide
        echo -e "${GREEN}✅ Encontrados $deployments deployment(s)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  No se encontraron deployments${NC}"
        return 1
    fi
}

check_pods() {
    local ns="$1"
    echo ""
    echo "🎯 Pods en namespace '$ns':"
    
    local pods=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l)
    
    if [ "$pods" -gt 0 ]; then
        kubectl get pods -n "$ns" -o wide
        
        # Contar pods por estado
        local running=$(kubectl get pods -n "$ns" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
        local pending=$(kubectl get pods -n "$ns" --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
        local failed=$(kubectl get pods -n "$ns" --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
        
        echo ""
        echo "Estado de pods:"
        echo "  Running: $running"
        echo "  Pending: $pending"
        echo "  Failed: $failed"
        
        if [ "$running" -gt 0 ]; then
            echo -e "${GREEN}✅ $running pod(s) en estado Running${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  No hay pods en Running${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  No se encontraron pods${NC}"
        return 1
    fi
}

check_configmaps() {
    local ns="$1"
    echo ""
    echo "⚙️  ConfigMaps en namespace '$ns':"
    
    local configmaps=$(kubectl get configmaps -n "$ns" --no-headers 2>/dev/null | grep -v kube-root-ca | wc -l)
    
    if [ "$configmaps" -gt 0 ]; then
        kubectl get configmaps -n "$ns" | grep -v kube-root-ca
        echo -e "${GREEN}✅ Encontrados $configmaps ConfigMap(s)${NC}"
        
        # Mostrar contenido del primer ConfigMap (si existe)
        if [ "$VERBOSE" = true ]; then
            local first_cm=$(kubectl get configmaps -n "$ns" --no-headers 2>/dev/null | grep -v kube-root-ca | head -1 | awk '{print $1}')
            if [ -n "$first_cm" ]; then
                echo ""
                echo "Contenido de '$first_cm':"
                kubectl get configmap "$first_cm" -n "$ns" -o yaml
            fi
        fi
        
        return 0
    else
        echo -e "${YELLOW}⚠️  No se encontraron ConfigMaps${NC}"
        return 1
    fi
}

check_secrets() {
    local ns="$1"
    echo ""
    echo "🔒 Secrets en namespace '$ns':"
    
    local secrets=$(kubectl get secrets -n "$ns" --no-headers 2>/dev/null | grep -v default-token | wc -l)
    
    if [ "$secrets" -gt 0 ]; then
        kubectl get secrets -n "$ns" | grep -v default-token
        echo -e "${GREEN}✅ Encontrados $secrets Secret(s)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  No se encontraron Secrets (excepto default-token)${NC}"
        return 1
    fi
}

check_services() {
    local ns="$1"
    echo ""
    echo "🌐 Services en namespace '$ns':"
    
    local services=$(kubectl get services -n "$ns" --no-headers 2>/dev/null | wc -l)
    
    if [ "$services" -gt 0 ]; then
        kubectl get services -n "$ns" -o wide
        echo -e "${GREEN}✅ Encontrados $services Service(s)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  No se encontraron Services${NC}"
        return 1
    fi
}

get_cluster_summary() {
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}           RESUMEN DEL CLUSTER                           ${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo "📊 Estadísticas globales:"
    echo ""
    
    # Nodos
    local total_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    local ready_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep -i ready | wc -l)
    echo "  Nodos: $ready_nodes/$total_nodes Ready"
    
    # Namespaces
    local namespaces=$(kubectl get namespaces --no-headers 2>/dev/null | wc -l)
    echo "  Namespaces: $namespaces"
    
    # Pods totales
    local total_pods=$(kubectl get pods -A --no-headers 2>/dev/null | wc -l)
    local running_pods=$(kubectl get pods -A --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    echo "  Pods: $running_pods/$total_pods Running"
    
    # Deployments totales
    local deployments=$(kubectl get deployments -A --no-headers 2>/dev/null | wc -l)
    echo "  Deployments: $deployments"
    
    # Services totales
    local services=$(kubectl get services -A --no-headers 2>/dev/null | wc -l)
    echo "  Services: $services"
    
    # ConfigMaps totales (sin incluir los de sistema)
    local configmaps=$(kubectl get configmaps -A --no-headers 2>/dev/null | grep -v kube-root-ca | wc -l)
    echo "  ConfigMaps: $configmaps"
    
    # Secrets totales (sin incluir tokens)
    local secrets=$(kubectl get secrets -A --no-headers 2>/dev/null | grep -v default-token | wc -l)
    echo "  Secrets: $secrets"
    
    echo ""
}

check_etcd_size() {
    echo "💾 Tamaño de etcd:"
    echo ""
    
    # Intentar obtener tamaño desde el data-dir
    if [ -d "/var/lib/etcd" ]; then
        local size=$(sudo du -sh /var/lib/etcd 2>/dev/null | awk '{print $1}')
        echo "  Data dir original: $size"
    fi
    
    if [ -d "/var/lib/etcd-restored" ]; then
        local restored_size=$(sudo du -sh /var/lib/etcd-restored 2>/dev/null | awk '{print $1}')
        echo "  Data dir restored: $restored_size"
    fi
    
    # Intentar obtener métricas de etcd
    if command -v etcdctl &>/dev/null; then
        export ETCDCTL_API=3
        local status=$(sudo etcdctl endpoint status \
            --cacert=/etc/kubernetes/pki/etcd/ca.crt \
            --cert=/etc/kubernetes/pki/etcd/server.crt \
            --key=/etc/kubernetes/pki/etcd/server.key \
            --endpoints=https://127.0.0.1:2379 \
            --write-out=table 2>/dev/null) || true
        
        if [ -n "$status" ]; then
            echo ""
            echo "$status"
        fi
    fi
    
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    print_header
    
    # Verificaciones básicas
    if ! check_api_server; then
        echo -e "${RED}❌ No se puede continuar sin acceso al API Server${NC}"
        exit 1
    fi
    
    echo ""
    
    # Verificar namespace específico si se proporciona
    if [ -n "$TARGET_NAMESPACE" ]; then
        echo -e "${YELLOW}🔍 Verificando namespace: $TARGET_NAMESPACE${NC}"
        echo ""
        
        if check_namespace "$TARGET_NAMESPACE"; then
            check_deployments "$TARGET_NAMESPACE" || true
            check_pods "$TARGET_NAMESPACE" || true
            check_configmaps "$TARGET_NAMESPACE" || true
            check_secrets "$TARGET_NAMESPACE" || true
            check_services "$TARGET_NAMESPACE" || true
        else
            echo -e "${RED}El namespace '$TARGET_NAMESPACE' no existe${NC}"
        fi
    fi
    
    # Resumen del cluster
    get_cluster_summary
    
    # Información de etcd
    check_etcd_size
    
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            VERIFICACIÓN COMPLETADA                         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Procesar argumentos
while getopts "v" opt; do
    case $opt in
        v)
            VERBOSE=true
            ;;
        \?)
            echo "Opción inválida: -$OPTARG"
            exit 1
            ;;
    esac
done

main
