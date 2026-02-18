#!/bin/bash

#==============================================================================
# Script: setup-etcd.sh
# Descripción: Configura cluster etcd externo + control planes Kubernetes
# Uso: ./setup-etcd.sh
#==============================================================================

set -euo pipefail

#------------------------------------------------------------------------------
# VARIABLES DE CONFIGURACIÓN
#------------------------------------------------------------------------------

# Nodos etcd (MODIFICAR SEGÚN TU ENTORNO)
ETCD_NODES=(
  "etcd-01:192.168.1.201"
  "etcd-02:192.168.1.202"
  "etcd-03:192.168.1.203"
)

# Control planes (MODIFICAR SEGÚN TU ENTORNO)
CONTROL_PLANES=(
  "master-01:192.168.1.11"
  "master-02:192.168.1.12"
  "master-03:192.168.1.13"
)

# Load balancer
LB_IP="192.168.1.10"
LB_PORT="6443"

# Directorios
CERT_DIR="./certs"
ETCD_CA_DIR="/etc/etcd/pki"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

#------------------------------------------------------------------------------
# FUNCIONES
#------------------------------------------------------------------------------

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_prerequisites() {
    log_info "Verificando prerequisitos..."
    
    for node in "${ETCD_NODES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        if ! ssh root@${ip} "command -v etcd" &>/dev/null; then
            log_error "etcd no instalado en ${name} (${ip})"
            exit 1
        fi
    done
    
    if ! command -v cfssl &>/dev/null || ! command -v cfssljson &>/dev/null; then
        log_error "cfssl/cfssljson no instalados localmente"
        exit 1
    fi
    
    log_info "✓ Prerequisitos OK"
}

generate_certificates() {
    log_info "Generando certificados TLS con cfssl..."
    
    mkdir -p ${CERT_DIR}
    cd ${CERT_DIR}
    
    # CA config
    cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "etcd": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "87600h"
      }
    }
  }
}
EOF
    
    # CA CSR
    cat > ca-csr.json <<EOF
{
  "CN": "etcd-ca",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ES",
      "L": "Madrid",
      "O": "Kubernetes",
      "OU": "etcd"
    }
  ]
}
EOF
    
    # Generar CA
    cfssl gencert -initca ca-csr.json | cfssljson -bare ca
    log_info "✓ CA generada"
    
    # etcd server CSR
    local etcd_ips=""
    for node in "${ETCD_NODES[@]}"; do
        local ip="${node##*:}"
        etcd_ips="${etcd_ips},${ip}"
    done
    etcd_ips="${etcd_ips:1}"  # Remover primera coma
    
    cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ES",
      "L": "Madrid",
      "O": "Kubernetes",
      "OU": "etcd"
    }
  ]
}
EOF
    
    # Generar certificado etcd
    cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -hostname=127.0.0.1,${etcd_ips} \
      -profile=etcd \
      etcd-csr.json | cfssljson -bare etcd
    
    log_info "✓ Certificados etcd generados"
    cd - > /dev/null
}

distribute_certificates() {
    log_info "Distribuyendo certificados a nodos etcd..."
    
    for node in "${ETCD_NODES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        
        log_info "  → ${name} (${ip})"
        ssh root@${ip} "mkdir -p /etc/etcd"
        scp ${CERT_DIR}/ca.pem ${CERT_DIR}/etcd.pem ${CERT_DIR}/etcd-key.pem root@${ip}:/etc/etcd/
        ssh root@${ip} "chmod 600 /etc/etcd/etcd-key.pem"
    done
    
    log_info "✓ Certificados distribuidos a etcd nodes"
}

configure_etcd_cluster() {
    log_info "Configurando cluster etcd..."
    
    # Construir INITIAL_CLUSTER string
    local initial_cluster=""
    for node in "${ETCD_NODES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        initial_cluster="${initial_cluster},${name}=https://${ip}:2380"
    done
    initial_cluster="${initial_cluster:1}"
    
    # Configurar cada nodo
    for node in "${ETCD_NODES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        
        log_info "  Configurando ${name}..."
        
        ssh root@${ip} "cat > /etc/systemd/system/etcd.service" <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${name} \\
  --data-dir /var/lib/etcd \\
  --listen-peer-urls https://${ip}:2380 \\
  --listen-client-urls https://${ip}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${ip}:2379 \\
  --initial-advertise-peer-urls https://${ip}:2380 \\
  --initial-cluster ${initial_cluster} \\
  --initial-cluster-state new \\
  --initial-cluster-token etcd-cluster-1 \\
  --client-cert-auth \\
  --trusted-ca-file /etc/etcd/ca.pem \\
  --cert-file /etc/etcd/etcd.pem \\
  --key-file /etc/etcd/etcd-key.pem \\
  --peer-client-cert-auth \\
  --peer-trusted-ca-file /etc/etcd/ca.pem \\
  --peer-cert-file /etc/etcd/etcd.pem \\
  --peer-key-file /etc/etcd/etcd-key.pem
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        
        ssh root@${ip} "mkdir -p /var/lib/etcd && chmod 700 /var/lib/etcd"
    done
    
    log_info "✓ Configuración etcd completada"
}

start_etcd_cluster() {
    log_info "Iniciando cluster etcd (simultáneamente)..."
    
    for node in "${ETCD_NODES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        ssh root@${ip} "systemctl daemon-reload && systemctl enable etcd" &
    done
    wait
    
    # Iniciar todos a la vez
    for node in "${ETCD_NODES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        ssh root@${ip} "systemctl start etcd" &
    done
    wait
    
    sleep 5
    log_info "✓ Cluster etcd iniciado"
}

verify_etcd_cluster() {
    log_info "Verificando cluster etcd..."
    
    local first_ip="${ETCD_NODES[0]##*:}"
    
    local members=$(ssh root@${first_ip} "ETCDCTL_API=3 etcdctl \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/etcd/ca.pem \
      --cert=/etc/etcd/etcd.pem \
      --key=/etc/etcd/etcd-key.pem \
      member list" 2>/dev/null | wc -l)
    
    if [ "$members" -eq "${#ETCD_NODES[@]}" ]; then
        log_info "✓ ${members} miembros en cluster etcd"
    else
        log_error "Esperados ${#ETCD_NODES[@]} miembros, encontrados ${members}"
        exit 1
    fi
}

distribute_certs_to_control_planes() {
    log_info "Distribuyendo certificados a control planes..."
    
    for node in "${CONTROL_PLANES[@]}"; do
        local name="${node%%:*}"
        local ip="${node##*:}"
        
        log_info "  → ${name} (${ip})"
        ssh root@${ip} "mkdir -p /etc/kubernetes/pki/etcd"
        scp ${CERT_DIR}/ca.pem root@${ip}:/etc/kubernetes/pki/etcd/
        scp ${CERT_DIR}/etcd.pem root@${ip}:/etc/kubernetes/pki/etcd/client.pem
        scp ${CERT_DIR}/etcd-key.pem root@${ip}:/etc/kubernetes/pki/etcd/client-key.pem
    done
    
    log_info "✓ Certificados distribuidos a control planes"
}

init_first_control_plane() {
    log_info "Inicializando primer control plane..."
    
    local first_cp="${CONTROL_PLANES[0]}"
    local name="${first_cp%%:*}"
    local ip="${first_cp##*:}"
    
    # Construir endpoints etcd
    local etcd_endpoints=""
    for node in "${ETCD_NODES[@]}"; do
        local etcd_ip="${node##*:}"
        etcd_endpoints="${etcd_endpoints},https://${etcd_ip}:2379"
    done
    etcd_endpoints="${etcd_endpoints:1}"
    
    # kubeadm config
    ssh root@${ip} "cat > kubeadm-config.yaml" <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
controlPlaneEndpoint: "${LB_IP}:${LB_PORT}"
etcd:
  external:
    endpoints:
$(for node in "${ETCD_NODES[@]}"; do
    local etcd_ip="${node##*:}"
    echo "    - https://${etcd_ip}:2379"
done)
    caFile: /etc/kubernetes/pki/etcd/ca.pem
    certFile: /etc/kubernetes/pki/etcd/client.pem
    keyFile: /etc/kubernetes/pki/etcd/client-key.pem
networking:
  podSubnet: "10.244.0.0/16"
EOF
    
    ssh root@${ip} "kubeadm init --config kubeadm-config.yaml --upload-certs"
    
    log_info "✓ Primer control plane inicializado"
}

install_cni() {
    log_info "Instalando CNI (Calico)..."
    
    local first_cp_ip="${CONTROL_PLANES[0]##*:}"
    
    ssh root@${first_cp_ip} "mkdir -p /root/.kube && \
      cp /etc/kubernetes/admin.conf /root/.kube/config && \
      kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
    
    log_info "✓ CNI instalado"
}

join_additional_control_planes() {
    log_info "Uniendo control planes adicionales..."
    
    local first_cp_ip="${CONTROL_PLANES[0]##*:}"
    
    # Obtener join command
    local join_cmd=$(ssh root@${first_cp_ip} \
      "kubeadm token create --print-join-command --certificate-key \$(kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1)")
    
    for i in "${!CONTROL_PLANES[@]}"; do
        if [ $i -eq 0 ]; then continue; fi
        
        local node="${CONTROL_PLANES[$i]}"
        local name="${node%%:*}"
        local ip="${node##*:}"
        
        log_info "  Uniendo ${name}..."
        ssh root@${ip} "${join_cmd} --control-plane"
    done
    
    log_info "✓ Control planes unidos"
}

final_verification() {
    log_info "Verificación final..."
    
    local first_cp_ip="${CONTROL_PLANES[0]##*:}"
    
    local nodes=$(ssh root@${first_cp_ip} "kubectl get nodes --no-headers" | wc -l)
    log_info "  Nodos Kubernetes: ${nodes}"
    
    local etcd_pods=$(ssh root@${first_cp_ip} "kubectl get pods -n kube-system -l component=etcd --no-headers" 2>/dev/null | wc -l)
    if [ "$etcd_pods" -eq 0 ]; then
        log_info "  ✓ NO hay pods etcd en cluster (correcto - etcd externo)"
    else
        log_warn "  Hay ${etcd_pods} pods etcd (inesperado)"
    fi
    
    log_info "✓ Setup completado exitosamente"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo "=========================================="
    echo "  External etcd Cluster Setup"
    echo "=========================================="
    echo
    
    check_prerequisites
    generate_certificates
    distribute_certificates
    configure_etcd_cluster
    start_etcd_cluster
    verify_etcd_cluster
    distribute_certs_to_control_planes
    init_first_control_plane
    install_cni
    join_additional_control_planes
    final_verification
    
    echo
    log_info "=========================================="
    log_info "Setup completado. Acceso al cluster:"
    log_info "  ssh root@${CONTROL_PLANES[0]##*:}"
    log_info "  kubectl get nodes"
    log_info "=========================================="
}

main "$@"
