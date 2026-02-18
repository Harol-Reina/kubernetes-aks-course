#!/bin/bash

################################################################################
# Drain Demo Script - Lab 03
# 
# Este script automatiza la demostración de drain de un nodo worker,
# mostrando paso a paso el proceso de evacuación de pods.
#
# Uso:
#   ./drain-demo.sh <node-name>
#
# Ejemplo:
#   ./drain-demo.sh k8s-worker-01
################################################################################

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Argumentos
NODE_NAME="${1:-}"

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

log_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

pause() {
    local message="${1:-Presiona ENTER para continuar...}"
    echo ""
    read -p "$message"
}

usage() {
    echo "Uso: $0 <node-name>"
    echo ""
    echo "Argumentos:"
    echo "  node-name   Nombre del nodo worker a drenar"
    echo ""
    echo "Ejemplos:"
    echo "  $0 k8s-worker-01"
    echo "  $0 worker-node-1"
    echo ""
    exit 1
}

################################################################################
# Validaciones
################################################################################

validate_arguments() {
    if [[ -z "$NODE_NAME" ]]; then
        log_error "Falta argumento: node-name"
        usage
    fi
    
    # Verificar que el nodo existe
    if ! kubectl get node "$NODE_NAME" > /dev/null 2>&1; then
        log_error "Nodo '$NODE_NAME' no encontrado"
        echo ""
        log_info "Nodos disponibles:"
        kubectl get nodes
        exit 1
    fi
    
    # Verificar que NO es control plane
    if kubectl get node "$NODE_NAME" -o jsonpath='{.metadata.labels}' | grep -q "node-role.kubernetes.io/control-plane"; then
        log_error "Error: $NODE_NAME es un control plane node"
        log_warning "Este script es solo para worker nodes"
        exit 1
    fi
    
    log_success "Nodo $NODE_NAME validado"
}

################################################################################
# Paso 1: Estado Inicial
################################################################################

show_initial_state() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║         DRAIN DEMO - PASO 1: ESTADO INICIAL           ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_step "Nodo objetivo: $NODE_NAME"
    echo ""
    
    log_info "1. Estado actual de nodos:"
    kubectl get nodes
    
    echo ""
    log_info "2. Pods en $NODE_NAME:"
    local pod_count=$(kubectl get pods -A --field-selector spec.nodeName="$NODE_NAME" --no-headers | wc -l)
    echo "Total: $pod_count pods"
    echo ""
    kubectl get pods -A --field-selector spec.nodeName="$NODE_NAME" -o wide
    
    echo ""
    log_info "3. Distribución de pods en el cluster:"
    for node in $(kubectl get nodes -o name | cut -d'/' -f2); do
        local count=$(kubectl get pods -A --field-selector spec.nodeName="$node" --no-headers | wc -l)
        echo "  📍 $node: $count pods"
    done
    
    pause
}

################################################################################
# Paso 2: Cordon
################################################################################

demo_cordon() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║         DRAIN DEMO - PASO 2: CORDON                   ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_step "kubectl cordon $NODE_NAME"
    echo ""
    
    log_info "Cordoning marca el nodo como SchedulingDisabled"
    log_info "Los pods existentes NO se afectan"
    log_info "Los nuevos pods NO se programarán en este nodo"
    
    pause "Presiona ENTER para ejecutar cordon..."
    
    if kubectl cordon "$NODE_NAME"; then
        log_success "Nodo $NODE_NAME cordoned"
    else
        log_error "Fallo al hacer cordon"
        exit 1
    fi
    
    echo ""
    log_info "Estado actual:"
    kubectl get nodes | grep -E "NAME|$NODE_NAME"
    
    echo ""
    log_info "Nota: El nodo muestra 'SchedulingDisabled'"
    
    pause
}

################################################################################
# Paso 3: Verificar Comportamiento de Cordon
################################################################################

demo_cordon_behavior() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║   DRAIN DEMO - PASO 3: COMPORTAMIENTO DE CORDON       ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_step "Probando que nuevos pods NO van a nodo cordoned"
    echo ""
    
    log_info "Creando pod de prueba..."
    
    kubectl run test-cordon --image=nginx:alpine --restart=Never -n default
    
    sleep 5
    
    local pod_node=$(kubectl get pod test-cordon -n default -o jsonpath='{.spec.nodeName}')
    
    echo ""
    log_info "Pod creado en nodo: $pod_node"
    
    if [[ "$pod_node" == "$NODE_NAME" ]]; then
        log_error "❌ El pod fue a $NODE_NAME (no debería)"
    else
        log_success "✓ El pod fue a $pod_node (correcto, no al cordoned)"
    fi
    
    # Limpiar pod de prueba
    kubectl delete pod test-cordon -n default > /dev/null 2>&1
    
    echo ""
    log_info "Los pods existentes en $NODE_NAME SIGUEN corriendo:"
    kubectl get pods -A --field-selector spec.nodeName="$NODE_NAME" --no-headers | wc -l | xargs echo "Total pods:"
    
    pause
}

################################################################################
# Paso 4: Drain
################################################################################

demo_drain() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║         DRAIN DEMO - PASO 4: DRAIN                    ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_step "kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data"
    echo ""
    
    log_info "Drain realizará:"
    echo "  1. Evacuar todos los pods (excepto DaemonSets)"
    echo "  2. Respetar PodDisruptionBudgets"
    echo "  3. Esperar graceful termination"
    echo "  4. Deployment controller recreará pods en otros nodos"
    
    pause "Presiona ENTER para ejecutar drain..."
    
    echo ""
    log_info "Ejecutando drain..."
    
    if kubectl drain "$NODE_NAME" --ignore-daemonsets --delete-emptydir-data; then
        log_success "Drain completado"
    else
        log_warning "Drain completado con advertencias (puede ser normal)"
    fi
    
    pause
}

################################################################################
# Paso 5: Verificar Evacuación
################################################################################

verify_evacuation() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║    DRAIN DEMO - PASO 5: VERIFICAR EVACUACIÓN          ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_step "Verificando que los pods migraron"
    echo ""
    
    log_info "Pods restantes en $NODE_NAME:"
    kubectl get pods -A --field-selector spec.nodeName="$NODE_NAME" -o wide || log_info "Ninguno (solo DaemonSets esperado)"
    
    echo ""
    local remaining=$(kubectl get pods -A --field-selector spec.nodeName="$NODE_NAME" --no-headers | grep -v DaemonSet | wc -l || true)
    
    if [[ $remaining -eq 0 ]]; then
        log_success "✓ Nodo evacuado correctamente (solo DaemonSets)"
    else
        log_warning "⚠️ $remaining pod(s) aún en el nodo"
    fi
    
    echo ""
    log_info "Nueva distribución de pods:"
    for node in $(kubectl get nodes -o name | cut -d'/' -f2); do
        local count=$(kubectl get pods -A --field-selector spec.nodeName="$node" --no-headers | wc -l)
        if [[ "$node" == "$NODE_NAME" ]]; then
            echo "  📍 $node: $count pods (drenado)"
        else
            echo "  📍 $node: $count pods"
        fi
    done
    
    pause
}

################################################################################
# Paso 6: Simular Mantenimiento
################################################################################

simulate_maintenance() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║    DRAIN DEMO - PASO 6: MANTENIMIENTO (SIMULADO)      ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_step "Simulando mantenimiento del nodo"
    echo ""
    
    log_info "En producción, harías:"
    echo "  • ssh $NODE_NAME"
    echo "  • sudo apt-get update && sudo apt-get upgrade"
    echo "  • sudo reboot"
    echo ""
    
    log_info "Para este demo, solo esperamos 5 segundos..."
    
    for i in {5..1}; do
        echo -n "$i... "
        sleep 1
    done
    echo ""
    
    log_success "Mantenimiento (simulado) completado"
    
    pause
}

################################################################################
# Paso 7: Uncordon
################################################################################

demo_uncordon() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║         DRAIN DEMO - PASO 7: UNCORDON                 ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_step "kubectl uncordon $NODE_NAME"
    echo ""
    
    log_info "Uncordon habilitará scheduling nuevamente"
    log_info "Los pods NO se mueven automáticamente de vuelta"
    log_info "Los NUEVOS pods se distribuirán a este nodo también"
    
    pause "Presiona ENTER para ejecutar uncordon..."
    
    if kubectl uncordon "$NODE_NAME"; then
        log_success "Nodo $NODE_NAME uncordoned"
    else
        log_error "Fallo al hacer uncordon"
        exit 1
    fi
    
    echo ""
    log_info "Estado actual:"
    kubectl get nodes | grep -E "NAME|$NODE_NAME"
    
    echo ""
    log_info "Nota: 'SchedulingDisabled' ya no aparece"
    
    pause
}

################################################################################
# Paso 8: Verificar Rebalanceo
################################################################################

verify_rebalancing() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║    DRAIN DEMO - PASO 8: REBALANCEO NATURAL            ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_step "Verificando que nuevos pods pueden ir a $NODE_NAME"
    echo ""
    
    log_info "Creando pod de prueba..."
    
    kubectl run test-uncordon --image=nginx:alpine --restart=Never -n default
    
    sleep 5
    
    local pod_node=$(kubectl get pod test-uncordon -n default -o jsonpath='{.spec.nodeName}' || true)
    
    echo ""
    log_info "Pod creado en nodo: $pod_node"
    
    if [[ "$pod_node" == "$NODE_NAME" ]]; then
        log_success "✓ El pod fue a $NODE_NAME (nodo está disponible)"
    else
        log_info "El pod fue a $pod_node (también válido, scheduler decide)"
    fi
    
    # Limpiar
    kubectl delete pod test-uncordon -n default > /dev/null 2>&1
    
    echo ""
    log_info "Distribución final de pods:"
    for node in $(kubectl get nodes -o name | cut -d'/' -f2); do
        local count=$(kubectl get pods -A --field-selector spec.nodeName="$node" --no-headers | wc -l)
        echo "  📍 $node: $count pods"
    done
    
    pause
}

################################################################################
# Resumen Final
################################################################################

show_summary() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║         DRAIN DEMO - RESUMEN FINAL                    ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_success "Demo completado exitosamente"
    echo ""
    
    echo "═══════════════════════════════════════════════════════════"
    echo "  FLUJO COMPLETO DE MANTENIMIENTO"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "1. CORDON       → Prevenir nuevos pods"
    echo "   kubectl cordon $NODE_NAME"
    echo ""
    echo "2. DRAIN        → Evacuar pods existentes"
    echo "   kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data"
    echo ""
    echo "3. MANTENIMIENTO → Actualizar, reiniciar, etc."
    echo "   ssh $NODE_NAME 'sudo apt upgrade && sudo reboot'"
    echo ""
    echo "4. UNCORDON     → Habilitar scheduling"
    echo "   kubectl uncordon $NODE_NAME"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  CONCEPTOS CLAVE"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "✓ CORDON: Solo previene nuevos pods"
    echo "✓ DRAIN: Cordon + evacua pods existentes"
    echo "✓ DaemonSets NUNCA se evacuan (--ignore-daemonsets)"
    echo "✓ Drain respeta PodDisruptionBudgets"
    echo "✓ Uncordon NO mueve pods automáticamente"
    echo ""
    
    log_info "Estado final del nodo $NODE_NAME:"
    kubectl get node "$NODE_NAME"
    
    echo ""
    log_info "Este nodo está listo para uso normal"
}

################################################################################
# Main
################################################################################

main() {
    # Validar argumentos
    validate_arguments
    
    # Ejecutar demo paso a paso
    show_initial_state
    demo_cordon
    demo_cordon_behavior
    demo_drain
    verify_evacuation
    simulate_maintenance
    demo_uncordon
    verify_rebalancing
    show_summary
    
    echo ""
    log_success "¡Demo completado!"
    log_info "El nodo $NODE_NAME está disponible y funcional"
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

# Mostrar ayuda si se solicita
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
fi

# Ejecutar
main "$@"
