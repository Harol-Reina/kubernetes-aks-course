#!/bin/bash
#
# setup-ha.sh - Automatización completa de cluster HA con kubeadm
#
# Propósito:
#   Automatiza el despliegue de un cluster Kubernetes HA con:
#   - Load Balancer (HAProxy)
#   - Múltiples control planes (3 por defecto)
#   - etcd stacked
#   - CNI (Calico)
#   - Validaciones automáticas
#
# Uso:
#   ./setup-ha.sh --lb-ip 192.168.1.100 \
#                 --master1-ip 192.168.1.101 \
#                 --master2-ip 192.168.1.102 \
#                 --master3-ip 192.168.1.103 \
#                 [--pod-network-cidr 10.244.0.0/16] \
#                 [--k8s-version v1.28.0]
#
# Prerequisitos:
#   - 4 nodos: 1 LB + 3 control planes
#   - SSH configurado con claves (sin contraseña)
#   - kubeadm, kubelet, kubectl instalados en control planes
#   - HAProxy instalado en nodo LB
#   - Script validate-prerequisites.sh del Lab 01
#
# Author: Kubernetes Course
# Version: 1.0
#

set -euo pipefail

#---------------------------------------------------------------------
# Variables globales y valores por defecto
#---------------------------------------------------------------------

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Variables de configuración (se setean vía argumentos)
LB_IP=""
MASTER1_IP=""
MASTER2_IP=""
MASTER3_IP=""
POD_NETWORK_CIDR="10.244.0.0/16"
K8S_VERSION="v1.28.0"
CNI_PROVIDER="calico"  # calico, flannel, weave

# Variables internas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/setup-ha-$(date +%Y%m%d-%H%M%S).log"
KUBEADM_TOKEN=""
CA_CERT_HASH=""
CERTIFICATE_KEY=""

#---------------------------------------------------------------------
# Funciones de utilidad
#---------------------------------------------------------------------

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $*" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $*" | tee -a "$LOG_FILE"
}

print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
    echo ""
}

usage() {
    cat <<EOF
Uso: $0 [OPTIONS]

Opciones requeridas:
  --lb-ip IP           IP del Load Balancer (HAProxy)
  --master1-ip IP      IP del primer control plane
  --master2-ip IP      IP del segundo control plane
  --master3-ip IP      IP del tercer control plane

Opciones opcionales:
  --pod-network-cidr CIDR    Pod network CIDR (default: 10.244.0.0/16)
  --k8s-version VERSION      Versión de Kubernetes (default: v1.28.0)
  --cni PROVIDER             CNI provider: calico|flannel|weave (default: calico)
  --help                     Mostrar esta ayuda

Ejemplo:
  $0 --lb-ip 192.168.1.100 \\
     --master1-ip 192.168.1.101 \\
     --master2-ip 192.168.1.102 \\
     --master3-ip 192.168.1.103

EOF
    exit 1
}

#---------------------------------------------------------------------
# Parsear argumentos
#---------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --lb-ip)
                LB_IP="$2"
                shift 2
                ;;
            --master1-ip)
                MASTER1_IP="$2"
                shift 2
                ;;
            --master2-ip)
                MASTER2_IP="$2"
                shift 2
                ;;
            --master3-ip)
                MASTER3_IP="$2"
                shift 2
                ;;
            --pod-network-cidr)
                POD_NETWORK_CIDR="$2"
                shift 2
                ;;
            --k8s-version)
                K8S_VERSION="$2"
                shift 2
                ;;
            --cni)
                CNI_PROVIDER="$2"
                shift 2
                ;;
            --help)
                usage
                ;;
            *)
                log_error "Opción desconocida: $1"
                usage
                ;;
        esac
    done

    # Validar argumentos requeridos
    if [[ -z "$LB_IP" ]] || [[ -z "$MASTER1_IP" ]] || [[ -z "$MASTER2_IP" ]] || [[ -z "$MASTER3_IP" ]]; then
        log_error "Faltan argumentos requeridos"
        usage
    fi
}

#---------------------------------------------------------------------
# Paso 1: Validar prerequisites
#---------------------------------------------------------------------

validate_prerequisites() {
    print_header "Paso 1/8: Validando Prerequisites"

    log "Verificando conectividad a nodos..."

    # Verificar conectividad al Load Balancer
    if ping -c 2 "$LB_IP" &>/dev/null; then
        log "✅ Conectividad a Load Balancer ($LB_IP): OK"
    else
        log_error "No se puede alcanzar Load Balancer ($LB_IP)"
        exit 1
    fi

    # Verificar conectividad a control planes
    for ip in "$MASTER1_IP" "$MASTER2_IP" "$MASTER3_IP"; do
        if ping -c 2 "$ip" &>/dev/null; then
            log "✅ Conectividad a control plane ($ip): OK"
        else
            log_error "No se puede alcanzar control plane ($ip)"
            exit 1
        fi
    done

    # Verificar SSH a control planes
    log "Verificando acceso SSH..."
    for ip in "$MASTER1_IP" "$MASTER2_IP" "$MASTER3_IP"; do
        if ssh -o ConnectTimeout=5 -o BatchMode=yes "$ip" "echo OK" &>/dev/null; then
            log "✅ SSH a $ip: OK"
        else
            log_error "No se puede acceder vía SSH a $ip (configurar claves SSH)"
            exit 1
        fi
    done

    log "✅ Prerequisites validados correctamente"
}

#---------------------------------------------------------------------
# Paso 2: Configurar Load Balancer (HAProxy)
#---------------------------------------------------------------------

configure_load_balancer() {
    print_header "Paso 2/8: Configurando Load Balancer"

    log "Generando configuración HAProxy..."

    # Generar haproxy.cfg con IPs correctas
    cat > "/tmp/haproxy.cfg" <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms

frontend kubernetes-apiserver
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes-apiserver

backend kubernetes-apiserver
    mode tcp
    balance roundrobin
    option tcp-check
    server master-01 ${MASTER1_IP}:6443 check fall 3 rise 2
    server master-02 ${MASTER2_IP}:6443 check fall 3 rise 2
    server master-03 ${MASTER3_IP}:6443 check fall 3 rise 2

listen stats
    bind *:9090
    mode http
    stats enable
    stats uri /
    stats realm HAProxy\ Statistics
    stats auth admin:admin
    stats refresh 30s
EOF

    log "Copiando configuración a Load Balancer..."
    scp "/tmp/haproxy.cfg" "${LB_IP}:/tmp/haproxy.cfg" >> "$LOG_FILE" 2>&1

    log "Aplicando configuración en Load Balancer..."
    ssh "$LB_IP" "sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg && \
                  sudo systemctl restart haproxy && \
                  sudo systemctl enable haproxy" >> "$LOG_FILE" 2>&1

    # Verificar que HAProxy esté corriendo
    if ssh "$LB_IP" "sudo systemctl is-active haproxy" &>/dev/null; then
        log "✅ HAProxy configurado y corriendo"
    else
        log_error "HAProxy no está corriendo"
        exit 1
    fi

    # Verificar puerto 6443 escuchando
    if ssh "$LB_IP" "sudo netstat -tulpn | grep :6443" &>/dev/null; then
        log "✅ Puerto 6443 escuchando en Load Balancer"
    else
        log_error "Puerto 6443 no está escuchando"
        exit 1
    fi

    log "✅ Load Balancer configurado correctamente"
}

#---------------------------------------------------------------------
# Paso 3: Inicializar primer control plane
#---------------------------------------------------------------------

initialize_first_control_plane() {
    print_header "Paso 3/8: Inicializando Primer Control Plane"

    log "Generando configuración kubeadm para master-01..."

    # Generar certificateKey aleatorio
    CERTIFICATE_KEY=$(openssl rand -hex 32)

    # Crear archivo de configuración kubeadm
    cat > "/tmp/kubeadm-config.yaml" <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: ${K8S_VERSION}
controlPlaneEndpoint: "${LB_IP}:6443"
networking:
  podSubnet: "${POD_NETWORK_CIDR}"
  serviceSubnet: "10.96.0.0/12"
etcd:
  local:
    dataDir: /var/lib/etcd
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "${MASTER1_IP}"
  bindPort: 6443
certificateKey: "${CERTIFICATE_KEY}"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

    log "Copiando configuración a master-01..."
    scp "/tmp/kubeadm-config.yaml" "${MASTER1_IP}:/tmp/kubeadm-config.yaml" >> "$LOG_FILE" 2>&1

    log "Ejecutando kubeadm init en master-01 (esto tomará 3-5 minutos)..."
    ssh "$MASTER1_IP" "sudo kubeadm init --config /tmp/kubeadm-config.yaml --upload-certs" > "/tmp/kubeadm-init-output.log" 2>&1

    # Extraer token y hash del output
    KUBEADM_TOKEN=$(grep -oP 'token \K[a-z0-9]+\.[a-z0-9]+' "/tmp/kubeadm-init-output.log" | head -1)
    CA_CERT_HASH=$(grep -oP 'sha256:\K[a-f0-9]{64}' "/tmp/kubeadm-init-output.log" | head -1)

    if [[ -z "$KUBEADM_TOKEN" ]] || [[ -z "$CA_CERT_HASH" ]]; then
        log_error "No se pudo extraer token o hash del output de kubeadm init"
        log_error "Ver log completo en: /tmp/kubeadm-init-output.log"
        exit 1
    fi

    log "Token: $KUBEADM_TOKEN"
    log "CA Cert Hash: sha256:$CA_CERT_HASH"
    log "Certificate Key: $CERTIFICATE_KEY"

    # Configurar kubectl en master-01
    log "Configurando kubectl en master-01..."
    ssh "$MASTER1_IP" "mkdir -p \$HOME/.kube && \
                       sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config && \
                       sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config" >> "$LOG_FILE" 2>&1

    # Verificar que el nodo está Ready (puede tardar 1-2 min)
    log "Esperando a que master-01 esté Ready..."
    for i in {1..60}; do
        if ssh "$MASTER1_IP" "kubectl get nodes | grep master-01 | grep -q Ready"; then
            log "✅ master-01 está Ready"
            break
        fi
        sleep 5
    done

    log "✅ Primer control plane inicializado correctamente"
}

#---------------------------------------------------------------------
# Paso 4: Instalar CNI
#---------------------------------------------------------------------

install_cni() {
    print_header "Paso 4/8: Instalando CNI ($CNI_PROVIDER)"

    case $CNI_PROVIDER in
        calico)
            log "Instalando Calico..."
            ssh "$MASTER1_IP" "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml" >> "$LOG_FILE" 2>&1
            ;;
        flannel)
            log "Instalando Flannel..."
            ssh "$MASTER1_IP" "kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml" >> "$LOG_FILE" 2>&1
            ;;
        weave)
            log "Instalando Weave Net..."
            ssh "$MASTER1_IP" "kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml" >> "$LOG_FILE" 2>&1
            ;;
        *)
            log_error "CNI provider desconocido: $CNI_PROVIDER"
            exit 1
            ;;
    esac

    # Esperar a que los pods de CNI estén corriendo
    log "Esperando a que pods de CNI estén corriendo..."
    for i in {1..60}; do
        if ssh "$MASTER1_IP" "kubectl get pods -n kube-system -l k8s-app=${CNI_PROVIDER}-node -o jsonpath='{.items[*].status.phase}' | grep -q Running"; then
            log "✅ CNI pods están corriendo"
            break
        fi
        sleep 5
    done

    log "✅ CNI instalado correctamente"
}

#---------------------------------------------------------------------
# Paso 5: Unir segundo control plane
#---------------------------------------------------------------------

join_second_control_plane() {
    print_header "Paso 5/8: Uniendo Segundo Control Plane"

    log "Generando comando kubeadm join para master-02..."

    JOIN_COMMAND="sudo kubeadm join ${LB_IP}:6443 \
        --token ${KUBEADM_TOKEN} \
        --discovery-token-ca-cert-hash sha256:${CA_CERT_HASH} \
        --control-plane \
        --certificate-key ${CERTIFICATE_KEY}"

    log "Ejecutando join en master-02..."
    ssh "$MASTER2_IP" "$JOIN_COMMAND" >> "$LOG_FILE" 2>&1

    # Configurar kubectl en master-02
    log "Configurando kubectl en master-02..."
    ssh "$MASTER2_IP" "mkdir -p \$HOME/.kube && \
                       sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config && \
                       sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config" >> "$LOG_FILE" 2>&1

    # Verificar que master-02 está Ready
    log "Esperando a que master-02 esté Ready..."
    for i in {1..60}; do
        if ssh "$MASTER1_IP" "kubectl get nodes | grep master-02 | grep -q Ready"; then
            log "✅ master-02 está Ready"
            break
        fi
        sleep 5
    done

    log "✅ Segundo control plane unido correctamente"
}

#---------------------------------------------------------------------
# Paso 6: Unir tercer control plane
#---------------------------------------------------------------------

join_third_control_plane() {
    print_header "Paso 6/8: Uniendo Tercer Control Plane"

    log "Ejecutando join en master-03..."

    JOIN_COMMAND="sudo kubeadm join ${LB_IP}:6443 \
        --token ${KUBEADM_TOKEN} \
        --discovery-token-ca-cert-hash sha256:${CA_CERT_HASH} \
        --control-plane \
        --certificate-key ${CERTIFICATE_KEY}"

    ssh "$MASTER3_IP" "$JOIN_COMMAND" >> "$LOG_FILE" 2>&1

    # Configurar kubectl en master-03
    log "Configurando kubectl en master-03..."
    ssh "$MASTER3_IP" "mkdir -p \$HOME/.kube && \
                       sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config && \
                       sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config" >> "$LOG_FILE" 2>&1

    # Verificar que master-03 está Ready
    log "Esperando a que master-03 esté Ready..."
    for i in {1..60}; do
        if ssh "$MASTER1_IP" "kubectl get nodes | grep master-03 | grep -q Ready"; then
            log "✅ master-03 está Ready"
            break
        fi
        sleep 5
    done

    log "✅ Tercer control plane unido correctamente"
}

#---------------------------------------------------------------------
# Paso 7: Verificar cluster HA
#---------------------------------------------------------------------

verify_ha_cluster() {
    print_header "Paso 7/8: Verificando Cluster HA"

    log "Verificando nodos..."
    ssh "$MASTER1_IP" "kubectl get nodes -o wide" | tee -a "$LOG_FILE"

    # Contar nodos Ready
    READY_NODES=$(ssh "$MASTER1_IP" "kubectl get nodes --no-headers | grep -c Ready" || echo "0")
    if [[ "$READY_NODES" -eq 3 ]]; then
        log "✅ Los 3 control planes están Ready"
    else
        log_error "Solo $READY_NODES nodos están Ready (esperado: 3)"
        exit 1
    fi

    log "Verificando componentes del control plane..."
    ssh "$MASTER1_IP" "kubectl get pods -n kube-system -o wide | grep -E 'apiserver|controller|scheduler|etcd'" | tee -a "$LOG_FILE"

    # Verificar que hay 3 API Servers
    API_SERVERS=$(ssh "$MASTER1_IP" "kubectl get pods -n kube-system -l component=kube-apiserver --no-headers | grep -c Running" || echo "0")
    if [[ "$API_SERVERS" -eq 3 ]]; then
        log "✅ 3 API Servers corriendo"
    else
        log_warn "Solo $API_SERVERS API Servers corriendo (esperado: 3)"
    fi

    # Verificar etcd cluster
    log "Verificando etcd cluster..."
    ETCD_MEMBERS=$(ssh "$MASTER1_IP" "sudo ETCDCTL_API=3 etcdctl \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        member list | wc -l" || echo "0")

    if [[ "$ETCD_MEMBERS" -eq 3 ]]; then
        log "✅ etcd cluster tiene 3 miembros"
    else
        log_warn "etcd cluster tiene $ETCD_MEMBERS miembros (esperado: 3)"
    fi

    log "✅ Cluster HA verificado correctamente"
}

#---------------------------------------------------------------------
# Paso 8: Guardar información del cluster
#---------------------------------------------------------------------

save_cluster_info() {
    print_header "Paso 8/8: Guardando Información del Cluster"

    CLUSTER_INFO_FILE="${SCRIPT_DIR}/cluster-info-$(date +%Y%m%d-%H%M%S).txt"

    cat > "$CLUSTER_INFO_FILE" <<EOF
========================================
Cluster HA - Información de Configuración
========================================
Fecha de creación: $(date)

Load Balancer:
  IP: ${LB_IP}
  Puerto: 6443
  Stats: http://${LB_IP}:9090 (admin/admin)

Control Planes:
  master-01: ${MASTER1_IP}
  master-02: ${MASTER2_IP}
  master-03: ${MASTER3_IP}

Kubernetes:
  Versión: ${K8S_VERSION}
  Pod Network CIDR: ${POD_NETWORK_CIDR}
  CNI: ${CNI_PROVIDER}

Tokens (válidos por 24 horas):
  Token: ${KUBEADM_TOKEN}
  CA Cert Hash: sha256:${CA_CERT_HASH}
  Certificate Key: ${CERTIFICATE_KEY}

Comandos para unir nodos adicionales:

# Unir control plane adicional:
kubeadm join ${LB_IP}:6443 \\
  --token ${KUBEADM_TOKEN} \\
  --discovery-token-ca-cert-hash sha256:${CA_CERT_HASH} \\
  --control-plane \\
  --certificate-key ${CERTIFICATE_KEY}

# Unir worker node:
kubeadm join ${LB_IP}:6443 \\
  --token ${KUBEADM_TOKEN} \\
  --discovery-token-ca-cert-hash sha256:${CA_CERT_HASH}

Acceso al cluster:
  1. Copiar kubeconfig desde master-01:
     scp ${MASTER1_IP}:~/.kube/config ~/.kube/config

  2. Verificar acceso:
     kubectl get nodes

Logs completos: ${LOG_FILE}
========================================
EOF

    log "✅ Información del cluster guardada en: $CLUSTER_INFO_FILE"
    cat "$CLUSTER_INFO_FILE"
}

#---------------------------------------------------------------------
# Main
#---------------------------------------------------------------------

main() {
    print_header "🚀 Setup Cluster Kubernetes HA con kubeadm"

    log "Iniciando script de setup..."
    log "Log completo en: $LOG_FILE"

    parse_args "$@"

    validate_prerequisites
    configure_load_balancer
    initialize_first_control_plane
    install_cni
    join_second_control_plane
    join_third_control_plane
    verify_ha_cluster
    save_cluster_info

    print_header "✅ Setup Completado Exitosamente"

    echo ""
    echo "🎉 ¡Cluster HA configurado correctamente!"
    echo ""
    echo "Próximos pasos:"
    echo "  1. Copiar kubeconfig: scp ${MASTER1_IP}:~/.kube/config ~/.kube/config"
    echo "  2. Verificar cluster: kubectl get nodes"
    echo "  3. Ver stats HAProxy: http://${LB_IP}:9090"
    echo ""
    echo "Para unir workers: Ver cluster-info-*.txt"
    echo ""
}

# Ejecutar script
main "$@"
