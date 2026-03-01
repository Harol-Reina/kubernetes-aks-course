# Setup - Lab 01: Cluster Básico con kubeadm init

## 📋 Requisitos del Sistema

### Hardware Mínimo

| Recurso | Mínimo | Recomendado | Descripción |
|---------|--------|-------------|-------------|
| **CPU** | 2 cores | 4 cores | Requerido para control plane |
| **RAM** | 2 GB | 4 GB | Mínimo para componentes K8s |
| **Disco** | 20 GB | 50 GB | Para sistema + imágenes |
| **Network** | 1 Gbps | 1 Gbps | Conectividad estable |

**⚠️ IMPORTANTE**: 
- Un cluster de producción necesita más recursos
- Este lab es para aprendizaje/desarrollo
- Para múltiples nodos, cada uno necesita recursos mínimos

### Sistema Operativo Soportado

| OS | Versión | Estado | Notas |
|----|---------|--------|-------|
| **Ubuntu** | 20.04 LTS | ✅ Probado | Recomendado para labs |
| **Ubuntu** | 22.04 LTS | ✅ Probado | Versión más reciente |
| **Debian** | 11+ | ✅ Soportado | Compatible |
| **CentOS** | 8+ | ⚠️ Deprecated | Usar Rocky/Alma Linux |
| **RHEL** | 8/9 | ✅ Soportado | Enterprise |
| **Rocky Linux** | 8/9 | ✅ Soportado | CentOS replacement |

## 🔧 Prerequisitos de Software

### Versiones Requeridas

```bash
# Verificar versiones antes de iniciar
Component           Minimum     Recommended
--------------------------------------------------
Kubernetes          1.25.0      1.28.0+
kubeadm            1.25.0      1.28.0+
kubelet            1.25.0      1.28.0+
kubectl            1.25.0      1.28.0+
containerd         1.6.0       1.7.0+
runc               1.1.0       1.1.9+
CNI plugins        1.1.0       1.3.0+
```

### Container Runtime

**⚠️ CRÍTICO**: Este lab usa **containerd** como container runtime.

**No se soporta**:
- Docker (deprecated desde Kubernetes 1.24)
- CRI-O (posible pero no cubierto en este lab)

## 🌐 Requisitos de Red

### Puertos Requeridos

#### Control Plane Node

| Protocolo | Dirección | Puerto | Usado Por | Descripción |
|-----------|-----------|--------|-----------|-------------|
| TCP | Inbound | 6443 | API server | Kubernetes API |
| TCP | Inbound | 2379-2380 | etcd | etcd server client API |
| TCP | Inbound | 10250 | Kubelet | Kubelet API |
| TCP | Inbound | 10259 | kube-scheduler | Scheduler |
| TCP | Inbound | 10257 | kube-controller-manager | Controller manager |

#### Worker Nodes (si se agregan después)

| Protocolo | Dirección | Puerto | Usado Por | Descripción |
|-----------|-----------|--------|-----------|-------------|
| TCP | Inbound | 10250 | Kubelet | Kubelet API |
| TCP | Inbound | 30000-32767 | NodePort Services | Servicios externos |

### Verificar Puertos Disponibles

```bash
# Verificar que los puertos críticos estén libres
check_ports() {
  local ports=(6443 2379 2380 10250 10259 10257)
  
  echo "Verificando disponibilidad de puertos..."
  for port in "${ports[@]}"; do
    if sudo netstat -tulpn | grep -q ":$port "; then
      echo "❌ Puerto $port está en uso"
      sudo netstat -tulpn | grep ":$port "
    else
      echo "✅ Puerto $port disponible"
    fi
  done
}

check_ports
```

### Configuración de Firewall

#### Para Ubuntu/Debian (ufw)

```bash
# Deshabilitar firewall para simplificar (solo en labs)
sudo ufw disable

# O configurar reglas específicas (producción)
sudo ufw allow 6443/tcp
sudo ufw allow 2379:2380/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10257/tcp
sudo ufw allow 10259/tcp
sudo ufw reload
```

#### Para RHEL/CentOS/Rocky (firewalld)

```bash
# Deshabilitar firewall para labs
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# O configurar reglas específicas (producción)
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=10257/tcp
sudo firewall-cmd --permanent --add-port=10259/tcp
sudo firewall-cmd --reload
```

### Configuración de Red

```bash
# 1. Obtener IP principal del nodo
ip addr show | grep 'inet ' | grep -v '127.0.0.1'

# 2. Verificar hostname resolvible
hostname
hostname -I
ping -c 2 $(hostname)

# 3. Configurar /etc/hosts si es necesario
echo "$(hostname -I | awk '{print $1}') $(hostname)" | sudo tee -a /etc/hosts

# 4. Verificar conectividad a internet
ping -c 3 8.8.8.8
ping -c 3 github.com
```

## ✅ Script de Validación de Prerequisites

Crea y ejecuta este script antes de iniciar el lab:

```bash
#!/bin/bash
# validate-prerequisites.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "==========================================="
echo "Validación de Prerequisites - Lab 01"
echo "==========================================="
echo ""

# 1. Verificar sistema operativo
echo "1. Verificando Sistema Operativo..."
if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo -e "${GREEN}✅ OS: $NAME $VERSION${NC}"
else
  echo -e "${RED}❌ No se pudo detectar el sistema operativo${NC}"
  exit 1
fi

# 2. Verificar recursos
echo ""
echo "2. Verificando Recursos del Sistema..."

# CPU
CPU_CORES=$(nproc)
if [ $CPU_CORES -ge 2 ]; then
  echo -e "${GREEN}✅ CPU: $CPU_CORES cores (mínimo: 2)${NC}"
else
  echo -e "${RED}❌ CPU: $CPU_CORES cores (mínimo requerido: 2)${NC}"
  exit 1
fi

# RAM
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ $TOTAL_RAM -ge 2 ]; then
  echo -e "${GREEN}✅ RAM: ${TOTAL_RAM}GB (mínimo: 2GB)${NC}"
else
  echo -e "${RED}❌ RAM: ${TOTAL_RAM}GB (mínimo requerido: 2GB)${NC}"
  exit 1
fi

# Disco
DISK_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ $DISK_SPACE -ge 20 ]; then
  echo -e "${GREEN}✅ Disco: ${DISK_SPACE}GB disponibles (mínimo: 20GB)${NC}"
else
  echo -e "${YELLOW}⚠️  Disco: ${DISK_SPACE}GB disponibles (recomendado: 20GB+)${NC}"
fi

# 3. Verificar swap
echo ""
echo "3. Verificando Swap..."
SWAP_SIZE=$(free -h | awk '/^Swap:/{print $2}')
if [ "$SWAP_SIZE" = "0B" ] || [ "$SWAP_SIZE" = "0" ]; then
  echo -e "${GREEN}✅ Swap deshabilitado${NC}"
else
  echo -e "${RED}❌ Swap habilitado ($SWAP_SIZE) - debe estar deshabilitado${NC}"
  echo "   Ejecuta: sudo swapoff -a"
  echo "   Luego: sudo sed -i '/ swap / s/^/#/' /etc/fstab"
  exit 1
fi

# 4. Verificar módulos del kernel
echo ""
echo "4. Verificando Módulos del Kernel..."
MODULES=("overlay" "br_netfilter")
for mod in "${MODULES[@]}"; do
  if lsmod | grep -q "^$mod "; then
    echo -e "${GREEN}✅ Módulo $mod cargado${NC}"
  else
    echo -e "${YELLOW}⚠️  Módulo $mod NO cargado (se cargará durante setup)${NC}"
  fi
done

# 5. Verificar parámetros sysctl
echo ""
echo "5. Verificando Parámetros Sysctl..."
check_sysctl() {
  local param=$1
  local expected=$2
  local actual=$(sysctl -n $param 2>/dev/null || echo "0")
  
  if [ "$actual" = "$expected" ]; then
    echo -e "${GREEN}✅ $param = $actual${NC}"
  else
    echo -e "${YELLOW}⚠️  $param = $actual (esperado: $expected, se configurará)${NC}"
  fi
}

check_sysctl "net.bridge.bridge-nf-call-iptables" "1"
check_sysctl "net.bridge.bridge-nf-call-ip6tables" "1"
check_sysctl "net.ipv4.ip_forward" "1"

# 6. Verificar puertos
echo ""
echo "6. Verificando Disponibilidad de Puertos..."
PORTS=(6443 2379 2380 10250 10259 10257)
for port in "${PORTS[@]}"; do
  if sudo netstat -tulpn 2>/dev/null | grep -q ":$port "; then
    echo -e "${RED}❌ Puerto $port en uso${NC}"
    sudo netstat -tulpn | grep ":$port " || true
  else
    echo -e "${GREEN}✅ Puerto $port disponible${NC}"
  fi
done

# 7. Verificar conectividad
echo ""
echo "7. Verificando Conectividad de Red..."
if ping -c 2 8.8.8.8 &>/dev/null; then
  echo -e "${GREEN}✅ Conectividad a Internet${NC}"
else
  echo -e "${RED}❌ Sin conectividad a Internet${NC}"
  exit 1
fi

# 8. Verificar hostname
echo ""
echo "8. Verificando Hostname..."
HOSTNAME=$(hostname)
HOSTNAME_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}✅ Hostname: $HOSTNAME${NC}"
echo -e "${GREEN}✅ IP: $HOSTNAME_IP${NC}"

# 9. Verificar si kubeadm/kubelet/kubectl ya están instalados
echo ""
echo "9. Verificando Instalación Previa de Componentes..."
for cmd in kubeadm kubelet kubectl; do
  if command -v $cmd &>/dev/null; then
    VERSION=$($cmd version --short 2>/dev/null | head -1 || echo "unknown")
    echo -e "${YELLOW}⚠️  $cmd ya instalado: $VERSION${NC}"
    echo "   (Se usará versión existente o se actualizará)"
  else
    echo -e "${GREEN}✅ $cmd no instalado (se instalará)${NC}"
  fi
done

# 10. Verificar containerd
echo ""
echo "10. Verificando Container Runtime..."
if systemctl is-active --quiet containerd; then
  CONTAINERD_VERSION=$(containerd --version | awk '{print $3}')
  echo -e "${GREEN}✅ containerd activo: $CONTAINERD_VERSION${NC}"
else
  if command -v containerd &>/dev/null; then
    echo -e "${YELLOW}⚠️  containerd instalado pero no activo${NC}"
  else
    echo -e "${YELLOW}⚠️  containerd no instalado (se instalará)${NC}"
  fi
fi

# 11. Verificar acceso root/sudo
echo ""
echo "11. Verificando Privilegios..."
if [ "$EUID" -eq 0 ]; then
  echo -e "${GREEN}✅ Ejecutando como root${NC}"
elif sudo -n true 2>/dev/null; then
  echo -e "${GREEN}✅ Usuario con acceso sudo sin password${NC}"
else
  echo -e "${YELLOW}⚠️  Requerirá password para sudo${NC}"
fi

# Resumen final
echo ""
echo "==========================================="
echo "Resumen de Validación"
echo "==========================================="
echo -e "${GREEN}Sistema listo para kubeadm init${NC}"
echo ""
echo "Pasos siguientes:"
echo "1. Revisar el README.md del laboratorio"
echo "2. Ejecutar instalación de containerd si es necesario"
echo "3. Instalar kubeadm, kubelet, kubectl"
echo "4. Ejecutar kubeadm init"

---

## Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `kubeadm-config.yaml` | Configuracion kubeadm para inicializar cluster single master (editar IPs antes de usar) |
| `validate-prerequisites.sh` | Script de validacion de prerequisites del sistema |
| `verify-cluster.sh` | Script de verificacion del cluster post-init |
| `cleanup.sh` | Script de limpieza completa del cluster |

> **Nota:** Este laboratorio esta disenado para VMs reales. No requiere Minikube ni sus addons.

---

**Proximo paso:** Ejecutar el procedimiento del laboratorio en [README.md](./README.md)
echo ""
