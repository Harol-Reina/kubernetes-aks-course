#!/bin/bash
# Script de instalación automática de prerequisites para Kubernetes
# Soporta: Ubuntu 20.04+, Ubuntu 22.04, Debian 11+
# Uso: sudo ./install-prerequisites.sh

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables de configuración
K8S_VERSION="1.28"
CONTAINERD_VERSION="1.6.24"

# Función para imprimir mensajes
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    print_error "Este script debe ejecutarse como root (usar sudo)"
    exit 1
fi

# Detectar OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    print_error "No se puede detectar el sistema operativo"
    exit 1
fi

print_message "Sistema operativo detectado: $OS $VERSION"

# Verificar OS soportado
case $OS in
    ubuntu|debian)
        print_message "Sistema operativo soportado"
        ;;
    *)
        print_error "Sistema operativo no soportado: $OS"
        exit 1
        ;;
esac

# 1. Deshabilitar swap (CRÍTICO)
print_message "Deshabilitando swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
print_message "✓ Swap deshabilitado"

# 2. Configurar módulos del kernel
print_message "Configurando módulos del kernel..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
print_message "✓ Módulos del kernel configurados"

# 3. Configurar parámetros sysctl
print_message "Configurando parámetros sysctl..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system > /dev/null 2>&1
print_message "✓ Parámetros sysctl configurados"

# 4. Instalar containerd
print_message "Instalando containerd..."

# Instalar dependencias
apt-get update -qq
apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Instalar containerd
apt-get install -y -qq containerd

# Crear directorio de configuración
mkdir -p /etc/containerd

# Generar configuración por defecto
containerd config default > /etc/containerd/config.toml

# Configurar systemd cgroup driver (CRÍTICO)
print_message "Configurando systemd cgroup driver..."
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Reiniciar containerd
systemctl restart containerd
systemctl enable containerd > /dev/null 2>&1

# Verificar containerd
if systemctl is-active --quiet containerd; then
    print_message "✓ containerd instalado y funcionando"
else
    print_error "containerd no está funcionando correctamente"
    exit 1
fi

# 5. Instalar kubeadm, kubelet, kubectl
print_message "Instalando kubeadm, kubelet y kubectl..."

# Agregar repositorio de Kubernetes
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | \
    tee /etc/apt/sources.list.d/kubernetes.list

# Instalar componentes
apt-get update -qq
apt-get install -y -qq kubelet kubeadm kubectl

# Hold packages para prevenir actualizaciones automáticas
apt-mark hold kubelet kubeadm kubectl

# Verificar instalación
print_message "Versiones instaladas:"
echo "  kubeadm: $(kubeadm version -o short)"
echo "  kubelet: $(kubelet --version | awk '{print $2}')"
echo "  kubectl: $(kubectl version --client -o json | grep gitVersion | awk -F'"' '{print $4}')"

print_message "✓ kubeadm, kubelet y kubectl instalados"

# 6. Habilitar kubelet
print_message "Habilitando kubelet..."
systemctl enable kubelet > /dev/null 2>&1
print_message "✓ kubelet habilitado"

# 7. Configurar crictl (opcional pero recomendado)
print_message "Configurando crictl..."
cat <<EOF | tee /etc/crictl.yaml
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10
debug: false
EOF

print_message "✓ crictl configurado"

# 8. Verificaciones finales
print_message "Realizando verificaciones finales..."

# Verificar swap
if [ $(swapon -s | wc -l) -eq 0 ]; then
    print_message "✓ Swap está deshabilitado"
else
    print_warning "Swap todavía activo - revisar configuración"
fi

# Verificar módulos del kernel
if lsmod | grep -q br_netfilter && lsmod | grep -q overlay; then
    print_message "✓ Módulos del kernel cargados"
else
    print_warning "Algunos módulos del kernel no están cargados"
fi

# Verificar containerd socket
if [ -S /var/run/containerd/containerd.sock ]; then
    print_message "✓ Socket de containerd existe"
else
    print_error "Socket de containerd no encontrado"
fi

# Summary
echo ""
print_message "============================================"
print_message "✓ INSTALACIÓN COMPLETA"
print_message "============================================"
echo ""
echo "Próximos pasos:"
echo ""
echo "  CONTROL PLANE:"
echo "    sudo kubeadm init --pod-network-cidr=192.168.0.0/16"
echo ""
echo "  WORKER NODE:"
echo "    Esperar el comando 'kubeadm join' del control plane"
echo ""
echo "  Después de kubeadm init:"
echo "    mkdir -p \$HOME/.kube"
echo "    sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
echo "    sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
echo ""
echo "  Instalar CNI (Calico recomendado):"
echo "    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
echo ""
print_message "============================================"
