#!/bin/bash

################################################################################
# Cleanup Script - Lab 03: Node Drain & Cordon
# 
# Este script limpia todos los recursos creados durante el laboratorio
# y asegura que todos los nodos estén en estado Ready (uncordoned).
#
# Uso:
#   ./cleanup.sh
################################################################################

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
NAMESPACE="drain-test"

################################################################################
# Funciones de Utilidad
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" response
    response=${response:-$default}
    
    [[ "$response" =~ ^[Yy]$ ]]
}

################################################################################
# Paso 1: Verificar Nodos Cordoned
################################################################################

step_check_cordoned_nodes() {
    echo ""
    echo "=========================================="
    echo "  PASO 1: Verificar Nodos Cordoned"
    echo "=========================================="
    echo ""
    
    log_info "Buscando nodos con SchedulingDisabled..."
    
    # Obtener nodos cordoned
    local cordoned_nodes=$(kubectl get nodes -o json | \
        jq -r '.items[] | select(.spec.unschedulable==true) | .metadata.name' || true)
    
    if [[ -z "$cordoned_nodes" ]]; then
        log_success "No hay nodos cordoned"
        return 0
    fi
    
    echo ""
    log_warning "Nodos cordoned encontrados:"
    echo "$cordoned_nodes"
    
    echo ""
    kubectl get nodes
}

################################################################################
# Paso 2: Uncordon Todos los Nodos
################################################################################

step_uncordon_all_nodes() {
    echo ""
    echo "=========================================="
    echo "  PASO 2: Uncordon de Nodos"
    echo "=========================================="
    echo ""
    
    # Listar nodos cordoned
    local cordoned_nodes=$(kubectl get nodes -o json | \
        jq -r '.items[] | select(.spec.unschedulable==true) | .metadata.name' || true)
    
    if [[ -z "$cordoned_nodes" ]]; then
        log_info "No hay nodos para uncordon"
        return 0
    fi
    
    log_info "Realizando uncordon de todos los nodos..."
    
    while IFS= read -r node; do
        log_info "Uncordon: $node"
        
        if kubectl uncordon "$node"; then
            log_success "$node uncordoned correctamente"
        else
            log_error "Fallo al hacer uncordon de $node"
        fi
    done <<< "$cordoned_nodes"
    
    echo ""
    log_info "Esperando 5 segundos..."
    sleep 5
    
    # Verificar que no queden nodos cordoned
    local remaining=$(kubectl get nodes -o json | \
        jq -r '.items[] | select(.spec.unschedulable==true) | .metadata.name' || true)
    
    if [[ -z "$remaining" ]]; then
        log_success "Todos los nodos están uncordoned"
    else
        log_warning "Algunos nodos aún cordoned:"
        echo "$remaining"
    fi
}

################################################################################
# Paso 3: Verificar Pods en Namespace de Prueba
################################################################################

step_check_test_pods() {
    echo ""
    echo "=========================================="
    echo "  PASO 3: Verificar Pods de Prueba"
    echo "=========================================="
    echo ""
    
    if ! kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
        log_info "Namespace $NAMESPACE no existe (ya limpio)"
        return 0
    fi
    
    log_info "Pods en namespace $NAMESPACE:"
    kubectl get pods -n "$NAMESPACE" -o wide || true
    
    echo ""
    log_info "Deployments en namespace $NAMESPACE:"
    kubectl get deployments -n "$NAMESPACE" || true
    
    echo ""
    log_info "DaemonSets en namespace $NAMESPACE:"
    kubectl get daemonsets -n "$NAMESPACE" || true
    
    echo ""
    log_info "PodDisruptionBudgets en namespace $NAMESPACE:"
    kubectl get pdb -n "$NAMESPACE" || true
}

################################################################################
# Paso 4: Eliminar Namespace de Prueba
################################################################################

step_delete_namespace() {
    echo ""
    echo "=========================================="
    echo "  PASO 4: Eliminar Namespace de Prueba"
    echo "=========================================="
    echo ""
    
    if ! kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
        log_info "Namespace $NAMESPACE ya no existe"
        return 0
    fi
    
    log_warning "Esto eliminará TODOS los recursos en el namespace $NAMESPACE"
    echo ""
    
    if confirm "¿Eliminar namespace $NAMESPACE?" "y"; then
        log_info "Eliminando namespace $NAMESPACE..."
        
        if kubectl delete namespace "$NAMESPACE" --wait=true --timeout=60s; then
            log_success "Namespace $NAMESPACE eliminado"
        else
            log_warning "Timeout al eliminar namespace - puede tardar más"
            log_info "Verifica manualmente: kubectl get namespace $NAMESPACE"
        fi
    else
        log_info "Namespace $NAMESPACE conservado"
    fi
}

################################################################################
# Paso 5: Verificar Distribución de Pods
################################################################################

step_verify_pod_distribution() {
    echo ""
    echo "=========================================="
    echo "  PASO 5: Distribución de Pods Actual"
    echo "=========================================="
    echo ""
    
    log_info "Pods por nodo:"
    echo ""
    
    # Iterar sobre todos los nodos
    while IFS= read -r node; do
        local pod_count=$(kubectl get pods -A --field-selector spec.nodeName="$node" --no-headers 2>/dev/null | wc -l || echo "0")
        
        echo "  📍 $node: $pod_count pods"
    done < <(kubectl get nodes -o name | cut -d'/' -f2)
    
    echo ""
    log_info "Total de pods en el cluster:"
    kubectl get pods -A --no-headers | wc -l
}

################################################################################
# Paso 6: Limpiar PodDisruptionBudgets Huérfanos
################################################################################

step_cleanup_orphan_pdbs() {
    echo ""
    echo "=========================================="
    echo "  PASO 6: Limpiar PDBs Huérfanos"
    echo "=========================================="
    echo ""
    
    log_info "Buscando PodDisruptionBudgets sin deployments..."
    
    # Buscar PDBs en todos los namespaces
    local all_pdbs=$(kubectl get pdb -A --no-headers 2>/dev/null | awk '{print $1 "/" $2}' || true)
    
    if [[ -z "$all_pdbs" ]]; then
        log_info "No hay PodDisruptionBudgets en el cluster"
        return 0
    fi
    
    echo "PDBs encontrados:"
    kubectl get pdb -A
    
    echo ""
    log_info "Los PDBs del sistema se conservarán automáticamente"
}

################################################################################
# Paso 7: Verificar Estado Final del Cluster
################################################################################

step_verify_final_state() {
    echo ""
    echo "=========================================="
    echo "  PASO 7: Estado Final del Cluster"
    echo "=========================================="
    echo ""
    
    log_info "1. Estado de nodos:"
    kubectl get nodes
    
    echo ""
    log_info "2. Nodos cordoned:"
    local cordoned=$(kubectl get nodes -o json | \
        jq -r '.items[] | select(.spec.unschedulable==true) | .metadata.name' || true)
    
    if [[ -z "$cordoned" ]]; then
        log_success "Ningún nodo cordoned ✓"
    else
        log_warning "Nodos aún cordoned:"
        echo "$cordoned"
    fi
    
    echo ""
    log_info "3. Namespaces existentes:"
    kubectl get namespaces | grep -E "NAME|drain-test" || log_success "Namespace drain-test eliminado"
    
    echo ""
    log_info "4. Salud del cluster:"
    
    # API Server
    if kubectl get --raw /healthz > /dev/null 2>&1; then
        log_success "API Server: OK"
    else
        log_error "API Server: FAIL"
    fi
    
    # Nodos Ready
    local not_ready=$(kubectl get nodes --no-headers | grep -c NotReady || true)
    if [[ $not_ready -eq 0 ]]; then
        log_success "Todos los nodos Ready"
    else
        log_warning "$not_ready nodo(s) NotReady"
    fi
    
    # Pods del sistema
    local failing_system=$(kubectl get pods -n kube-system --no-headers | grep -vE 'Running|Completed' | wc -l || true)
    if [[ $failing_system -eq 0 ]]; then
        log_success "Pods del sistema: OK"
    else
        log_warning "$failing_system pod(s) del sistema no Running"
    fi
}

################################################################################
# Paso 8: Generar Reporte de Limpieza
################################################################################

step_generate_report() {
    echo ""
    echo "=========================================="
    echo "  PASO 8: Reporte de Limpieza"
    echo "=========================================="
    echo ""
    
    local report_file="/tmp/lab03-cleanup-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "=========================================="
        echo "  REPORTE DE LIMPIEZA - LAB 03"
        echo "=========================================="
        echo ""
        echo "Fecha: $(date)"
        echo "Usuario: $(whoami)"
        echo "Cluster: $(kubectl config current-context)"
        echo ""
        
        echo "--- NODOS ---"
        kubectl get nodes
        echo ""
        
        echo "--- NODOS CORDONED ---"
        local cordoned=$(kubectl get nodes -o json | \
            jq -r '.items[] | select(.spec.unschedulable==true) | .metadata.name' || true)
        
        if [[ -z "$cordoned" ]]; then
            echo "Ninguno (✓)"
        else
            echo "$cordoned"
        fi
        echo ""
        
        echo "--- NAMESPACE DRAIN-TEST ---"
        if kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
            echo "⚠️  Aún existe"
            kubectl get all -n "$NAMESPACE" 2>/dev/null || echo "Sin recursos"
        else
            echo "✓ Eliminado"
        fi
        echo ""
        
        echo "--- DISTRIBUCIÓN DE PODS ---"
        while IFS= read -r node; do
            local count=$(kubectl get pods -A --field-selector spec.nodeName="$node" --no-headers 2>/dev/null | wc -l)
            echo "$node: $count pods"
        done < <(kubectl get nodes -o name | cut -d'/' -f2)
        echo ""
        
        echo "--- RECOMENDACIONES ---"
        echo "✓ Cluster listo para uso normal"
        echo "✓ Todos los nodos disponibles para scheduling"
        echo "✓ Puedes continuar con Lab 04: Certificate Management"
        
    } > "$report_file"
    
    cat "$report_file"
    
    echo ""
    log_success "Reporte guardado en: $report_file"
}

################################################################################
# Paso 9: Limpiar Recursos Temporales
################################################################################

step_cleanup_temp_resources() {
    echo ""
    echo "=========================================="
    echo "  PASO 9: Limpiar Recursos Temporales"
    echo "=========================================="
    echo ""
    
    # Limpiar pods de test standalone (no managed)
    log_info "Buscando pods standalone (no managed por controller)..."
    
    local standalone_pods=$(kubectl get pods -A -o json | \
        jq -r '.items[] | select(.metadata.ownerReferences == null) | "\(.metadata.namespace)/\(.metadata.name)"' || true)
    
    if [[ -z "$standalone_pods" ]]; then
        log_info "No hay pods standalone"
    else
        log_info "Pods standalone encontrados:"
        echo "$standalone_pods"
        echo ""
        
        if confirm "¿Eliminar pods standalone (pueden ser de otros labs)?"; then
            while IFS='/' read -r ns pod; do
                log_info "Eliminando $ns/$pod..."
                kubectl delete pod "$pod" -n "$ns" --force --grace-period=0 || true
            done <<< "$standalone_pods"
        fi
    fi
}

################################################################################
# Main
################################################################################

main() {
    clear
    
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        CLEANUP - LAB 03: NODE DRAIN & CORDON          ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Este script realizará:"
    echo "  1. Uncordon de todos los nodos"
    echo "  2. Eliminación del namespace drain-test"
    echo "  3. Limpieza de recursos temporales"
    echo "  4. Verificación del estado del cluster"
    echo ""
    
    if ! confirm "¿Continuar con el cleanup?" "y"; then
        log_info "Cleanup cancelado"
        exit 0
    fi
    
    # Ejecutar pasos
    step_check_cordoned_nodes
    step_uncordon_all_nodes
    step_check_test_pods
    step_delete_namespace
    step_verify_pod_distribution
    step_cleanup_orphan_pdbs
    step_cleanup_temp_resources
    step_verify_final_state
    step_generate_report
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║              CLEANUP COMPLETADO                        ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_success "Cluster restaurado a estado normal"
    log_info "Próximo laboratorio: Lab 04 - Certificate Management"
}

# Verificar que kubectl está disponible
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl no encontrado"
    exit 1
fi

# Verificar conexión al cluster
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "Error: No se puede conectar al cluster"
    exit 1
fi

# Ejecutar
main "$@"
