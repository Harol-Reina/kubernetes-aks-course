#!/bin/bash

################################################################################
# Upgrade Worker Node Script - Lab 02
# 
# Este script automatiza el upgrade de un worker node de Kubernetes
# desde v1.27.x a v1.28.x.
#
# PREREQUISITOS:
#   - Control plane ya actualizado a v1.28.x
#   - Acceso SSH al worker node
#   - kubectl configurado
#
# Uso:
#   ./upgrade-worker.sh <worker-node-name> [--version 1.28.0]
#
# Ejemplo:
#   ./upgrade-worker.sh k8s-worker-01
#   ./upgrade-worker.sh k8s-worker-02 --version 1.28.1
################################################################################

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Argumentos
WORKER_NODE="${1:-}"
TARGET_VERSION="${2:-1.28.0}"
APT_VERSION="${TARGET_VERSION}-00"
LOG_FILE="/var/log/k8s-upgrade/worker-${WORKER_NODE}-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# Funciones de Utilidad
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
}

die() {
    log_error "$1"
    exit 1
}

confirm() {
    local prompt="$1"
    read -p "$prompt [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

usage() {
    echo "Uso: $0 <worker-node-name> [VERSION]"
    echo ""
    echo "Argumentos:"
    echo "  worker-node-name   Nombre del worker node a actualizar"
    echo "  VERSION            Versión target (default: 1.28.0)"
    echo ""
    echo "Ejemplos:"
    echo "  $0 k8s-worker-01"
    echo "  $0 k8s-worker-02 1.28.1"
    echo ""
    exit 1
}

################################################################################
# Validaciones
################################################################################

validate_arguments() {
    if [[ -z "$WORKER_NODE" ]]; then
        log_error "Falta argumento: worker-node-name"
        usage
    fi
    
    # Verificar que el nodo existe
    if ! kubectl get node "$WORKER_NODE" > /dev/null 2>&1; then
        die "Nodo '$WORKER_NODE' no encontrado en el cluster"
    fi
    
    # Verificar que NO es control plane
    if kubectl get node "$WORKER_NODE" -o jsonpath='{.metadata.labels}' | grep -q "node-role.kubernetes.io/control-plane"; then
        die "Error: $WORKER_NODE es un control plane node. Usa upgrade-control-plane.sh"
    fi
    
    log_success "Nodo $WORKER_NODE validado"
}

validate_control_plane_version() {
    log_info "Verificando versión del control plane..."
    
    local cp_version=$(kubectl get nodes --selector='node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}')
    
    log_info "Control plane version: $cp_version"
    log_info "Target worker version: v${TARGET_VERSION}"
    
    if [[ "$cp_version" != "v${TARGET_VERSION}" ]]; then
        log_warning "Control plane ($cp_version) != target (v${TARGET_VERSION})"
        if ! confirm "¿Continuar de todos modos?"; then
            exit 0
        fi
    else
        log_success "Control plane está en la versión correcta"
    fi
}

################################################################################
# Fase 1: Drain Worker Node
################################################################################

drain_worker() {
    log_info "=== FASE 1: Drenar worker node ==="
    
    log_info "Drenando nodo: $WORKER_NODE"
    log_warning "Los pods migrarán a otros workers disponibles"
    echo ""
    
    # Mostrar pods actuales en el nodo
    log_info "Pods actuales en $WORKER_NODE:"
    kubectl get pods -A -o wide --field-selector spec.nodeName="$WORKER_NODE" | tee -a "$LOG_FILE"
    
    echo ""
    if ! confirm "¿Proceder con el drain?"; then
        log_info "Drain cancelado"
        exit 0
    fi
    
    # Drenar nodo
    if kubectl drain "$WORKER_NODE" --ignore-daemonsets --delete-emptydir-data; then
        log_success "Nodo $WORKER_NODE drenado exitosamente"
    else
        log_error "Problemas durante el drain"
        
        log_info "Pods problemáticos:"
        kubectl get pods -A -o wide --field-selector spec.nodeName="$WORKER_NODE"
        
        if confirm "¿Forzar drain (puede causar pérdida de datos)?"; then
            kubectl drain "$WORKER_NODE" --ignore-daemonsets --delete-emptydir-data --force --grace-period=0
            log_warning "Drain forzado completado"
        else
            die "Drain abortado - resuelve problemas de pods manualmente"
        fi
    fi
    
    # Verificar que el nodo está cordoned
    if kubectl get node "$WORKER_NODE" | grep -q SchedulingDisabled; then
        log_success "Nodo en modo SchedulingDisabled (cordoned)"
    else
        log_warning "Nodo no está cordoned - verificar estado"
    fi
    
    # Verificar que los pods migraron
    echo ""
    log_info "Pods restantes en $WORKER_NODE (solo DaemonSets esperados):"
    kubectl get pods -A -o wide --field-selector spec.nodeName="$WORKER_NODE" | tee -a "$LOG_FILE"
}

################################################################################
# Fase 2: SSH y Upgrade en Worker Node
################################################################################

upgrade_worker_packages() {
    log_info "=== FASE 2: Actualizar paquetes en worker node ==="
    
    log_info "Conectando a $WORKER_NODE via SSH..."
    
    # Crear script temporal para ejecutar en el worker
    local upgrade_script="/tmp/worker-upgrade-${WORKER_NODE}.sh"
    
    cat > "$upgrade_script" << EOF
#!/bin/bash
set -euo pipefail

echo "=== Worker Node Upgrade Script ==="
echo "Hostname: \$(hostname)"
echo "Target version: ${TARGET_VERSION}"
echo ""

# 1. Actualizar kubeadm
echo "[1/5] Actualizando kubeadm..."
apt-mark unhold kubeadm
apt-get update -qq
apt-get install -y kubeadm=${APT_VERSION}
apt-mark hold kubeadm

# Verificar versión
kubeadm version

# 2. Upgrade node config
echo "[2/5] Ejecutando kubeadm upgrade node..."
kubeadm upgrade node

# 3. Actualizar kubelet y kubectl
echo "[3/5] Actualizando kubelet y kubectl..."
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=${APT_VERSION} kubectl=${APT_VERSION}
apt-mark hold kubelet kubectl

# 4. Reiniciar kubelet
echo "[4/5] Reiniciando kubelet..."
systemctl daemon-reload
systemctl restart kubelet

# 5. Verificar kubelet
echo "[5/5] Verificando kubelet..."
sleep 5
systemctl status kubelet --no-pager

# Mostrar versiones finales
echo ""
echo "=== Versiones instaladas ==="
kubeadm version
kubelet --version
kubectl version --client

echo ""
echo "✓ Upgrade del worker node completado"
EOF
    
    chmod +x "$upgrade_script"
    
    # Ejecutar en el worker node
    log_info "Ejecutando upgrade en $WORKER_NODE..."
    
    if ssh "$WORKER_NODE" 'bash -s' < "$upgrade_script" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Paquetes actualizados en $WORKER_NODE"
    else
        log_error "Fallo durante la actualización de paquetes"
        
        # Intentar verificar estado del kubelet remotamente
        log_info "Verificando estado de kubelet..."
        ssh "$WORKER_NODE" 'sudo systemctl status kubelet' || true
        
        die "Upgrade falló en $WORKER_NODE - revisa logs arriba"
    fi
    
    # Limpiar script temporal
    rm -f "$upgrade_script"
}

################################################################################
# Fase 3: Uncordon Worker Node
################################################################################

uncordon_worker() {
    log_info "=== FASE 3: Uncordon worker node ==="
    
    log_info "Habilitando scheduling en $WORKER_NODE..."
    
    if kubectl uncordon "$WORKER_NODE"; then
        log_success "Nodo $WORKER_NODE uncordoned"
    else
        die "Fallo al hacer uncordon - ejecutar manualmente: kubectl uncordon $WORKER_NODE"
    fi
    
    # Esperar a que el nodo esté Ready
    log_info "Esperando a que el nodo esté Ready..."
    
    local retries=12
    local count=0
    
    while [[ $count -lt $retries ]]; do
        if kubectl get node "$WORKER_NODE" | grep -q "Ready"; then
            log_success "Nodo $WORKER_NODE está Ready"
            break
        fi
        
        count=$((count + 1))
        log_info "Esperando... ($count/$retries)"
        sleep 5
    done
    
    if [[ $count -eq $retries ]]; then
        log_warning "Nodo no está Ready después de 60 segundos"
    fi
    
    # Mostrar estado del nodo
    kubectl get node "$WORKER_NODE" -o wide | tee -a "$LOG_FILE"
}

################################################################################
# Fase 4: Verificación
################################################################################

verify_worker_upgrade() {
    log_info "=== FASE 4: Verificación del worker node ==="
    
    echo ""
    log_info "1. Versión del nodo:"
    kubectl get node "$WORKER_NODE" -o wide | tee -a "$LOG_FILE"
    
    # Extraer versión
    local node_version=$(kubectl get node "$WORKER_NODE" -o jsonpath='{.status.nodeInfo.kubeletVersion}')
    
    if [[ "$node_version" == "v${TARGET_VERSION}" ]]; then
        log_success "Versión correcta: $node_version"
    else
        log_error "Versión incorrecta: $node_version (esperado: v${TARGET_VERSION})"
    fi
    
    echo ""
    log_info "2. Condiciones del nodo:"
    kubectl get node "$WORKER_NODE" -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\n"}{end}' | tee -a "$LOG_FILE"
    
    echo ""
    log_info "3. Pods en el nodo (después de 10 segundos):"
    sleep 10
    kubectl get pods -A -o wide --field-selector spec.nodeName="$WORKER_NODE" | tee -a "$LOG_FILE"
    
    echo ""
    log_info "4. Test de scheduling:"
    
    # Crear pod de prueba con nodeSelector
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-worker-${WORKER_NODE}
  labels:
    app: upgrade-test
spec:
  nodeName: $WORKER_NODE
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
  restartPolicy: Never
EOF
    
    # Esperar a que el pod esté Running
    sleep 5
    
    if kubectl wait --for=condition=Ready --timeout=60s pod/test-worker-${WORKER_NODE} > /dev/null 2>&1; then
        log_success "Pod de prueba creado y Running en $WORKER_NODE"
        
        # Limpiar
        kubectl delete pod test-worker-${WORKER_NODE} > /dev/null 2>&1
        log_info "Pod de prueba eliminado"
    else
        log_warning "Pod de prueba no llegó a Ready (puede ser normal si hay problemas de red/imagen)"
        kubectl get pod test-worker-${WORKER_NODE}
        kubectl delete pod test-worker-${WORKER_NODE} --force --grace-period=0 > /dev/null 2>&1 || true
    fi
}

################################################################################
# Resumen
################################################################################

print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║     UPGRADE DE WORKER NODE COMPLETADO                 ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_success "Worker $WORKER_NODE actualizado a v${TARGET_VERSION}"
    
    echo ""
    log_info "Estado actual del cluster:"
    kubectl get nodes -o wide | tee -a "$LOG_FILE"
    
    echo ""
    log_info "Pods del sistema en $WORKER_NODE:"
    kubectl get pods -n kube-system -o wide --field-selector spec.nodeName="$WORKER_NODE" | head -10
    
    echo ""
    log_info "PRÓXIMOS PASOS:"
    
    # Ver si hay más workers para actualizar
    local remaining_workers=$(kubectl get nodes --no-headers | grep -v control-plane | grep -v "v${TARGET_VERSION}" | wc -l)
    
    if [[ $remaining_workers -gt 0 ]]; then
        echo "  1. Monitorear $WORKER_NODE por 5-10 minutos"
        echo "  2. Actualizar el siguiente worker node:"
        echo ""
        kubectl get nodes --no-headers | grep -v control-plane | grep -v "v${TARGET_VERSION}" | while read node _; do
            echo "     ./upgrade-worker.sh $node"
        done
    else
        echo "  ✓ Todos los nodos actualizados a v${TARGET_VERSION}"
        echo "  1. Verificar que todas las aplicaciones funcionan"
        echo "  2. Ejecutar ./verify-upgrade.sh para validación completa"
        echo "  3. Monitorear cluster por 24-48 horas"
    fi
    
    echo ""
    log_info "Log completo: $LOG_FILE"
}

################################################################################
# Main
################################################################################

main() {
    # Crear directorio de logs
    mkdir -p /var/log/k8s-upgrade
    
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        UPGRADE WORKER NODE: v${TARGET_VERSION}                ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Inicio: $(date)"
    log_info "Worker node: $WORKER_NODE"
    log_info "Target version: v${TARGET_VERSION}"
    echo ""
    
    # Ejecutar fases
    validate_arguments
    validate_control_plane_version
    echo ""
    
    drain_worker
    echo ""
    
    upgrade_worker_packages
    echo ""
    
    uncordon_worker
    echo ""
    
    verify_worker_upgrade
    
    print_summary
}

# Verificar kubectl está disponible
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl no encontrado"
    exit 1
fi

# Verificar conexión al cluster
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
