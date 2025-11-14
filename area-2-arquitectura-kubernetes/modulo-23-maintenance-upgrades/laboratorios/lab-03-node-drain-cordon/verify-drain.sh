#!/bin/bash

################################################################################
# Verificación de Drain - Lab 03
# 
# Este script verifica que el proceso de drain se ejecutó correctamente,
# validando el estado de nodos, distribución de pods, y PodDisruptionBudgets.
#
# Uso:
#   ./verify-drain.sh [--node <node-name>]
#
# Opciones:
#   --node NAME    Verificar estado específico de un nodo
#
# Códigos de salida:
#   0 - Todas las verificaciones pasaron
#   1 - Advertencias encontradas (no crítico)
#   2 - Errores críticos encontrados
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

# Variables globales
SPECIFIC_NODE=""
EXIT_CODE=0
WARNINGS=0
ERRORS=0
CHECKS_PASSED=0
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
    ((WARNINGS++))
    [[ $EXIT_CODE -lt 1 ]] && EXIT_CODE=1
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((ERRORS++))
    EXIT_CODE=2
}

log_section() {
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

usage() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --node NAME    Verificar estado de un nodo específico"
    echo "  -h, --help     Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0                      # Verificación general del cluster"
    echo "  $0 --node worker-01     # Verificar nodo específico"
    exit 0
}

################################################################################
# Verificación 1: Conexión al Cluster
################################################################################

check_cluster_connection() {
    ((TOTAL_CHECKS++))
    log_info "Verificando conexión al cluster..."
    
    if kubectl cluster-info > /dev/null 2>&1; then
        local context=$(kubectl config current-context)
        log_success "Conectado al cluster: $context"
    else
        log_error "No se puede conectar al cluster de Kubernetes"
        return 1
    fi
}

################################################################################
# Verificación 2: Estado de Nodos
################################################################################

check_node_status() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 2: ESTADO DE NODOS"
    
    log_info "Obteniendo estado de nodos..."
    echo ""
    
    # Mostrar todos los nodos
    kubectl get nodes -o wide
    
    echo ""
    
    # Contar nodos por estado
    local total_nodes=$(kubectl get nodes --no-headers | wc -l)
    local ready_nodes=$(kubectl get nodes --no-headers | grep -c "Ready" || true)
    local notready_nodes=$(kubectl get nodes --no-headers | grep -v "Ready" | wc -l || true)
    
    echo "Estado de nodos:"
    echo "  • Total: $total_nodes"
    echo "  • Ready: $ready_nodes"
    echo "  • NotReady: $notready_nodes"
    
    # Verificar nodos cordoned
    local cordoned=$(kubectl get nodes --no-headers | grep -c "SchedulingDisabled" || true)
    
    if [[ $cordoned -gt 0 ]]; then
        echo ""
        log_warning "$cordoned nodo(s) con SchedulingDisabled (cordoned)"
        echo ""
        log_info "Nodos cordoned:"
        kubectl get nodes | grep "SchedulingDisabled"
        echo ""
        log_info "Para habilitar: kubectl uncordon <node-name>"
    else
        log_success "No hay nodos cordoned"
    fi
    
    # Verificar nodos NotReady
    if [[ $notready_nodes -gt 0 ]]; then
        log_error "$notready_nodes nodo(s) NotReady encontrado(s)"
    else
        log_success "Todos los nodos están Ready"
    fi
}

################################################################################
# Verificación 3: Distribución de Pods
################################################################################

check_pod_distribution() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 3: DISTRIBUCIÓN DE PODS"
    
    log_info "Analizando distribución de pods por nodo..."
    echo ""
    
    # Tabla de distribución
    printf "%-30s %-10s %-15s %-15s\n" "NODO" "TOTAL" "WORKLOAD PODS" "DAEMONSETS"
    printf "%-30s %-10s %-15s %-15s\n" "----" "-----" "-------------" "----------"
    
    for node in $(kubectl get nodes -o name | cut -d'/' -f2); do
        local total=$(kubectl get pods -A --field-selector spec.nodeName="$node" --no-headers | wc -l)
        local daemonsets=$(kubectl get pods -A --field-selector spec.nodeName="$node" --no-headers | \
                          awk '{print $2}' | xargs -I {} kubectl get pod {} -n $(echo {} | cut -d'/' -f1) -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null | grep -c DaemonSet || echo 0)
        local workload=$((total - daemonsets))
        
        printf "%-30s %-10s %-15s %-15s\n" "$node" "$total" "$workload" "$daemonsets"
    done
    
    echo ""
    
    # Verificar balance de workload pods
    local max_pods=0
    local min_pods=999999
    
    for node in $(kubectl get nodes -o name | cut -d'/' -f2); do
        # Contar solo workload pods (no DaemonSets)
        local workload=$(kubectl get pods -A --field-selector spec.nodeName="$node" --no-headers | \
                        awk '{print $1"/"$2}' | while read pod; do
                            ns=$(echo $pod | cut -d'/' -f1)
                            name=$(echo $pod | cut -d'/' -f2)
                            kind=$(kubectl get pod "$name" -n "$ns" -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null || echo "Unknown")
                            if [[ "$kind" != "DaemonSet" ]]; then
                                echo "$pod"
                            fi
                        done | wc -l)
        
        [[ $workload -gt $max_pods ]] && max_pods=$workload
        [[ $workload -lt $min_pods ]] && min_pods=$workload
    done
    
    local difference=$((max_pods - min_pods))
    
    if [[ $difference -le 3 ]]; then
        log_success "Distribución balanceada (diferencia: $difference pods)"
    elif [[ $difference -le 10 ]]; then
        log_warning "Distribución moderadamente desbalanceada (diferencia: $difference pods)"
    else
        log_warning "Distribución muy desbalanceada (diferencia: $difference pods)"
        log_info "Considera forzar rebalanceo con rolling restart"
    fi
}

################################################################################
# Verificación 4: Pods en Estado Problemático
################################################################################

check_problematic_pods() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 4: PODS PROBLEMÁTICOS"
    
    log_info "Buscando pods en estado problemático..."
    echo ""
    
    # Pods no Running
    local non_running=$(kubectl get pods -A --field-selector status.phase!=Running --no-headers 2>/dev/null | wc -l)
    
    if [[ $non_running -gt 0 ]]; then
        log_warning "$non_running pod(s) no están en estado Running"
        echo ""
        kubectl get pods -A --field-selector status.phase!=Running
        echo ""
    else
        log_success "Todos los pods están Running"
    fi
    
    # Pods Pending
    local pending=$(kubectl get pods -A --field-selector status.phase=Pending --no-headers 2>/dev/null | wc -l)
    
    if [[ $pending -gt 0 ]]; then
        log_error "$pending pod(s) en estado Pending"
        echo ""
        kubectl get pods -A --field-selector status.phase=Pending -o wide
        echo ""
        log_info "Investigar con: kubectl describe pod <pod-name> -n <namespace>"
    fi
    
    # Pods con restarts altos
    log_info "Verificando pods con restarts frecuentes..."
    local high_restarts=$(kubectl get pods -A --no-headers | awk '$5 > 5 {print $0}' | wc -l || true)
    
    if [[ $high_restarts -gt 0 ]]; then
        log_warning "$high_restarts pod(s) con más de 5 restarts"
        echo ""
        kubectl get pods -A --no-headers | awk '$5 > 5 {print $0}'
        echo ""
    else
        log_success "No hay pods con restarts excesivos"
    fi
}

################################################################################
# Verificación 5: PodDisruptionBudgets
################################################################################

check_pdbs() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 5: PODDISRUPTIONBUDGETS"
    
    log_info "Verificando PodDisruptionBudgets..."
    echo ""
    
    local pdb_count=$(kubectl get pdb -A --no-headers 2>/dev/null | wc -l || echo 0)
    
    if [[ $pdb_count -eq 0 ]]; then
        log_info "No hay PodDisruptionBudgets definidos"
        return 0
    fi
    
    log_info "PDBs encontrados: $pdb_count"
    echo ""
    
    kubectl get pdb -A -o wide
    
    echo ""
    
    # Verificar PDBs bloqueados
    local allowed=$(kubectl get pdb -A -o json | jq -r '.items[] | select(.status.disruptionsAllowed == 0) | "\(.metadata.namespace)/\(.metadata.name)"' | wc -l || echo 0)
    
    if [[ $allowed -gt 0 ]]; then
        log_warning "$allowed PDB(s) no permiten disrupciones (disruptionsAllowed=0)"
        echo ""
        log_info "PDBs bloqueados:"
        kubectl get pdb -A -o json | jq -r '.items[] | select(.status.disruptionsAllowed == 0) | "  • \(.metadata.namespace)/\(.metadata.name) - \(.spec.minAvailable // "N/A") minAvailable"'
        echo ""
        log_info "Esto puede bloquear futuros drains"
    else
        log_success "Todos los PDBs permiten disrupciones"
    fi
}

################################################################################
# Verificación 6: DaemonSets
################################################################################

check_daemonsets() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 6: DAEMONSETS"
    
    log_info "Verificando DaemonSets..."
    echo ""
    
    local ds_count=$(kubectl get daemonsets -A --no-headers 2>/dev/null | wc -l || echo 0)
    
    if [[ $ds_count -eq 0 ]]; then
        log_info "No hay DaemonSets en el cluster"
        return 0
    fi
    
    log_info "DaemonSets encontrados: $ds_count"
    echo ""
    
    kubectl get daemonsets -A -o wide
    
    echo ""
    
    # Verificar que DaemonSets estén completos
    local incomplete=0
    
    while IFS= read -r line; do
        local desired=$(echo "$line" | awk '{print $3}')
        local current=$(echo "$line" | awk '{print $4}')
        local ready=$(echo "$line" | awk '{print $5}')
        local name=$(echo "$line" | awk '{print $1"/"$2}')
        
        if [[ "$desired" != "$current" ]] || [[ "$desired" != "$ready" ]]; then
            log_warning "DaemonSet $name no completado (Desired: $desired, Current: $current, Ready: $ready)"
            ((incomplete++))
        fi
    done < <(kubectl get daemonsets -A --no-headers)
    
    if [[ $incomplete -eq 0 ]]; then
        log_success "Todos los DaemonSets están completados"
    fi
}

################################################################################
# Verificación 7: Nodo Específico
################################################################################

check_specific_node() {
    local node="$1"
    
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 7: NODO ESPECÍFICO - $node"
    
    # Verificar que existe
    if ! kubectl get node "$node" > /dev/null 2>&1; then
        log_error "Nodo '$node' no encontrado"
        return 1
    fi
    
    # Estado del nodo
    log_info "Estado del nodo:"
    kubectl get node "$node" -o wide
    echo ""
    
    # Condiciones del nodo
    log_info "Condiciones del nodo:"
    kubectl get node "$node" -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\t"}{.message}{"\n"}{end}' | column -t
    echo ""
    
    # Taints
    local taints=$(kubectl get node "$node" -o jsonpath='{.spec.taints}' 2>/dev/null)
    if [[ -n "$taints" ]] && [[ "$taints" != "null" ]]; then
        log_warning "Nodo tiene taints:"
        kubectl get node "$node" -o jsonpath='{range .spec.taints[*]}{.key}={.value}:{.effect}{"\n"}{end}'
        echo ""
    else
        log_success "Nodo sin taints"
    fi
    
    # Pods en el nodo
    local pod_count=$(kubectl get pods -A --field-selector spec.nodeName="$node" --no-headers | wc -l)
    log_info "Pods en el nodo: $pod_count"
    echo ""
    kubectl get pods -A --field-selector spec.nodeName="$node" -o wide
    echo ""
    
    # Verificar si está cordoned
    if kubectl get node "$node" | grep -q "SchedulingDisabled"; then
        log_warning "Nodo está cordoned (SchedulingDisabled)"
        log_info "Para habilitar: kubectl uncordon $node"
    else
        log_success "Nodo permite scheduling"
    fi
    
    # Capacidad vs uso
    log_info "Recursos del nodo:"
    echo ""
    echo "Capacidad:"
    kubectl get node "$node" -o jsonpath='{.status.capacity}' | jq '.'
    echo ""
    echo "Allocatable:"
    kubectl get node "$node" -o jsonpath='{.status.allocatable}' | jq '.'
}

################################################################################
# Verificación 8: Namespaces del Lab
################################################################################

check_lab_namespace() {
    ((TOTAL_CHECKS++))
    log_section "VERIFICACIÓN 8: RECURSOS DEL LAB"
    
    log_info "Verificando namespace 'drain-test'..."
    
    if kubectl get namespace drain-test > /dev/null 2>&1; then
        log_info "Namespace 'drain-test' encontrado"
        echo ""
        
        log_info "Deployments:"
        kubectl get deployments -n drain-test
        echo ""
        
        log_info "Pods:"
        kubectl get pods -n drain-test -o wide
        echo ""
        
        log_info "PodDisruptionBudgets:"
        kubectl get pdb -n drain-test
        
        log_success "Recursos del lab presentes"
    else
        log_info "Namespace 'drain-test' no encontrado (lab no iniciado o ya limpiado)"
    fi
}

################################################################################
# Resumen Final
################################################################################

show_summary() {
    log_section "RESUMEN FINAL"
    
    echo "Total de verificaciones: $TOTAL_CHECKS"
    echo "  ${GREEN}✓${NC} Pasadas: $CHECKS_PASSED"
    echo "  ${YELLOW}⚠${NC} Advertencias: $WARNINGS"
    echo "  ${RED}✗${NC} Errores: $ERRORS"
    echo ""
    
    if [[ $EXIT_CODE -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}═════════════════════════════════════════════${NC}"
        echo -e "${GREEN}${BOLD}  TODAS LAS VERIFICACIONES PASARON ✓${NC}"
        echo -e "${GREEN}${BOLD}═════════════════════════════════════════════${NC}"
    elif [[ $EXIT_CODE -eq 1 ]]; then
        echo -e "${YELLOW}${BOLD}═════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}${BOLD}  VERIFICACIONES CON ADVERTENCIAS ⚠${NC}"
        echo -e "${YELLOW}${BOLD}═════════════════════════════════════════════${NC}"
        echo ""
        log_info "Revisa las advertencias arriba y toma acción si es necesario"
    else
        echo -e "${RED}${BOLD}═════════════════════════════════════════════${NC}"
        echo -e "${RED}${BOLD}  ERRORES CRÍTICOS ENCONTRADOS ✗${NC}"
        echo -e "${RED}${BOLD}═════════════════════════════════════════════${NC}"
        echo ""
        log_error "Revisa los errores arriba antes de continuar"
    fi
    
    echo ""
    log_info "Código de salida: $EXIT_CODE"
}

################################################################################
# Parseo de Argumentos
################################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --node)
                SPECIFIC_NODE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Opción desconocida: $1"
                usage
                ;;
        esac
    done
}

################################################################################
# Main
################################################################################

main() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        VERIFICACIÓN DE DRAIN - LAB 03                 ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Verificar kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl no encontrado"
        exit 2
    fi
    
    # Verificar jq
    if ! command -v jq &> /dev/null; then
        log_warning "jq no encontrado (algunas verificaciones limitadas)"
    fi
    
    # Ejecutar verificaciones
    check_cluster_connection
    check_node_status
    check_pod_distribution
    check_problematic_pods
    check_pdbs
    check_daemonsets
    
    # Verificación específica de nodo si se solicitó
    if [[ -n "$SPECIFIC_NODE" ]]; then
        check_specific_node "$SPECIFIC_NODE"
    fi
    
    check_lab_namespace
    
    # Mostrar resumen
    show_summary
    
    exit $EXIT_CODE
}

# Parsear argumentos
parse_arguments "$@"

# Ejecutar
main
