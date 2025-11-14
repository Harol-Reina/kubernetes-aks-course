# Setup - Lab 03: High Availability Control Plane

## Descripción General

Este documento detalla todos los **prerequisites, requisitos de hardware, configuración de red y validaciones** necesarios antes de desplegar un cluster HA con múltiples control planes.

---

## Tabla de Contenidos

1. [Requisitos de Hardware](#requisitos-de-hardware)
2. [Topología de Red](#topología-de-red)
3. [Requisitos de Software](#requisitos-de-software)
4. [Preparación del Load Balancer](#preparación-del-load-balancer)
5. [Validación de Prerequisites](#validación-de-prerequisites)
6. [Preparación Rápida](#preparación-rápida)

---

## Requisitos de Hardware

### Configuración Mínima (Lab/Testing)

| Componente | Cantidad | CPU | RAM | Disco | Propósito |
|------------|----------|-----|-----|-------|-----------|
| **Load Balancer** | 1 | 1 core | 512 MB | 10 GB | HAProxy/nginx |
| **Control Planes** | 3 | 2 cores | 2 GB | 20 GB | API Server + etcd |
| **Workers** (opcional) | 0-3 | 2 cores | 2 GB | 20 GB | Workloads |

**Total mínimo**: 4 nodos (1 LB + 3 control planes)

### Configuración Recomendada (Producción)

| Componente | Cantidad | CPU | RAM | Disco | Propósito |
|------------|----------|-----|-----|-------|-----------|
| **Load Balancer** | 2 (HA) | 2 cores | 2 GB | 20 GB | HAProxy + keepalived |
| **Control Planes** | 3-5 | 4 cores | 8 GB | 100 GB SSD | API Server + etcd |
| **Workers** | 3+ | 4+ cores | 8+ GB | 100+ GB SSD | Workloads |

### Notas sobre Hardware

```
IMPORTANTE:
├── Control Planes: Número IMPAR (3, 5, 7) para quorum etcd
├── Load Balancer: 1 suficiente para lab, 2 para producción (con VIP)
├── etcd: SSD recomendado (latencia <10ms crítica)
└── Workers: Escalable según workload

QUORUM etcd:
├── 3 nodos: Tolera 1 fallo (mínimo recomendado)
├── 5 nodos: Tolera 2 fallos (producción estándar)
└── 7 nodos: Tolera 3 fallos (solo si realmente necesario)
```

---

## Topología de Red

### Arquitectura Recomendada

```
NETWORK TOPOLOGY:

Internet/External Network
         │
         ▼
    ┌─────────┐
    │ Router/ │  (Opcional: para acceso externo)
    │ Firewall│
    └────┬────┘
         │
    ┌────┴────────────────────────────────────┐
    │   Internal Network: 192.168.1.0/24      │
    └─────────────────────────────────────────┘
         │
         ├─── Load Balancer:  192.168.1.100:6443
         │
         ├─── master-01:      192.168.1.101:6443
         ├─── master-02:      192.168.1.102:6443
         ├─── master-03:      192.168.1.103:6443
         │
         ├─── worker-01:      192.168.1.111
         ├─── worker-02:      192.168.1.112
         └─── worker-03:      192.168.1.113

DNS/Hosts:
├── k8s-lb.example.com      → 192.168.1.100
├── master-01.example.com   → 192.168.1.101
├── master-02.example.com   → 192.168.1.102
└── master-03.example.com   → 192.168.1.103
```

### Requisitos de Conectividad

**1. Conectividad entre nodos** (CRÍTICO):

```bash
# Todos los nodos deben poder alcanzarse entre sí
# Verificar desde cada nodo:

# Desde Load Balancer
ping -c 2 192.168.1.101  # master-01
ping -c 2 192.168.1.102  # master-02
ping -c 2 192.168.1.103  # master-03

# Desde master-01
ping -c 2 192.168.1.100  # Load Balancer
ping -c 2 192.168.1.102  # master-02
ping -c 2 192.168.1.103  # master-03

# Repetir desde master-02 y master-03
```

**2. Resolución de nombres**:

Opción A: Configurar DNS (recomendado para producción):

```bash
# /etc/resolv.conf en todos los nodos
nameserver 192.168.1.1
search example.com
```

Opción B: Configurar /etc/hosts (válido para labs):

```bash
# Agregar en TODOS los nodos (/etc/hosts)
cat <<EOF | sudo tee -a /etc/hosts
192.168.1.100   k8s-lb k8s-lb.example.com
192.168.1.101   master-01 master-01.example.com
192.168.1.102   master-02 master-02.example.com
192.168.1.103   master-03 master-03.example.com
192.168.1.111   worker-01 worker-01.example.com
192.168.1.112   worker-02 worker-02.example.com
192.168.1.113   worker-03 worker-03.example.com
EOF

# Verificar resolución
getent hosts master-01
# 192.168.1.101   master-01 master-01.example.com
```

**3. Puertos requeridos**:

### Puertos - Load Balancer

| Puerto | Protocolo | Propósito | Fuente permitida |
|--------|-----------|-----------|------------------|
| 6443 | TCP | Kubernetes API Server | Control planes, workers, kubectl |
| 9090 | TCP | HAProxy Stats (opcional) | Admin only |

### Puertos - Control Planes

| Puerto | Protocolo | Propósito | Fuente permitida |
|--------|-----------|-----------|------------------|
| 6443 | TCP | Kubernetes API Server | Load Balancer, workers, otros control planes |
| 2379 | TCP | etcd client | kube-apiserver |
| 2380 | TCP | etcd peer | Otros miembros etcd |
| 10250 | TCP | Kubelet API | Control planes, workers |
| 10259 | TCP | kube-scheduler | Localhost |
| 10257 | TCP | kube-controller-manager | Localhost |

### Puertos - Workers

| Puerto | Protocolo | Propósito | Fuente permitida |
|--------|-----------|-----------|------------------|
| 10250 | TCP | Kubelet API | Control planes |
| 30000-32767 | TCP | NodePort Services | External clients |

**Script de verificación de puertos**:

```bash
#!/bin/bash
# check-ports.sh - Verificar puertos necesarios

echo "=== Verificando puertos en Control Planes ==="

CONTROL_PLANE_PORTS=(6443 2379 2380 10250 10259 10257)

for node in master-01 master-02 master-03; do
    echo "Checking $node..."
    for port in "${CONTROL_PLANE_PORTS[@]}"; do
        if nc -zv -w 2 $node $port 2>&1 | grep -q succeeded; then
            echo "  ✅ Port $port is open on $node"
        else
            echo "  ❌ Port $port is CLOSED on $node"
        fi
    done
done

echo ""
echo "=== Verificando Load Balancer ==="
if nc -zv -w 2 k8s-lb 6443 2>&1 | grep -q succeeded; then
    echo "  ✅ Port 6443 is open on Load Balancer"
else
    echo "  ❌ Port 6443 is CLOSED on Load Balancer"
fi
```

---

## Requisitos de Software

### Sistemas Operativos Soportados

- ✅ **Ubuntu**: 20.04 LTS, 22.04 LTS (recomendado)
- ✅ **Debian**: 10 (Buster), 11 (Bullseye)
- ✅ **CentOS/RHEL**: 8.x, 9.x
- ✅ **Rocky Linux**: 8.x, 9.x

### Versiones de Componentes

**CRÍTICO**: Todas las versiones deben coincidir en todos los nodos.

| Componente | Versión Recomendada | Versión Mínima | Notas |
|------------|---------------------|----------------|-------|
| **Kubernetes** | v1.28.x | v1.26.x | Última estable |
| **kubeadm** | v1.28.x | v1.26.x | Debe coincidir con K8s |
| **kubelet** | v1.28.x | v1.26.x | Debe coincidir con K8s |
| **kubectl** | v1.28.x | v1.26.x | ±1 versión menor OK |
| **containerd** | v1.7.x | v1.6.x | Container runtime |
| **etcd** | v3.5.x | v3.4.x | Instalado por kubeadm |
| **CNI Plugin** | Calico 3.26.x | Flannel 0.22.x | Según preferencia |
| **HAProxy** | 2.8.x | 2.4.x | Load Balancer |

### Instalación de Componentes Base

**En TODOS los nodos (control planes + workers)**:

```bash
#!/bin/bash
# install-kubernetes-components.sh

# 1. Actualizar sistema
sudo apt-get update
sudo apt-get upgrade -y

# 2. Instalar containerd
sudo apt-get install -y containerd

# Configurar containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Habilitar systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# 3. Desactivar swap (REQUERIDO por Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 4. Configurar módulos del kernel
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 5. Configurar sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# 6. Instalar kubeadm, kubelet, kubectl
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# 7. Habilitar kubelet
sudo systemctl enable kubelet

echo "✅ Kubernetes components installed successfully"
```

**En el nodo Load Balancer**:

```bash
#!/bin/bash
# install-haproxy.sh

# Instalar HAProxy
sudo apt-get update
sudo apt-get install -y haproxy

# Verificar versión
haproxy -v

# Habilitar servicio
sudo systemctl enable haproxy

echo "✅ HAProxy installed successfully"
```

---

## Preparación del Load Balancer

### Configuración HAProxy

**Archivo**: `/etc/haproxy/haproxy.cfg`

```haproxy
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # See: https://ssl-config.mozilla.org/#server=haproxy
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

#---------------------------------------------------------------------
# Defaults
#---------------------------------------------------------------------
defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

#---------------------------------------------------------------------
# Kubernetes API Server Frontend
#---------------------------------------------------------------------
frontend kubernetes-apiserver-frontend
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes-apiserver-backend

#---------------------------------------------------------------------
# Kubernetes API Server Backend
#---------------------------------------------------------------------
backend kubernetes-apiserver-backend
    mode tcp
    balance roundrobin
    option tcp-check
    
    # Health check: verifica que el API Server responda
    # Cada 2 segundos, si falla 3 veces consecutivas marca como down
    # Si responde 2 veces consecutivas lo marca como up
    
    # IMPORTANTE: Cambiar IPs por las de tus control planes
    server master-01 192.168.1.101:6443 check fall 3 rise 2
    server master-02 192.168.1.102:6443 check fall 3 rise 2
    server master-03 192.168.1.103:6443 check fall 3 rise 2

#---------------------------------------------------------------------
# HAProxy Stats (Opcional - para monitoreo)
#---------------------------------------------------------------------
listen stats
    bind *:9090
    mode http
    stats enable
    stats uri /
    stats realm HAProxy\ Statistics
    stats auth admin:admin  # CAMBIAR en producción
    stats refresh 30s
```

**Pasos de instalación**:

```bash
# 1. Backup de configuración original
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup

# 2. Aplicar nueva configuración
sudo nano /etc/haproxy/haproxy.cfg
# (Pegar contenido de arriba y cambiar IPs)

# 3. Verificar sintaxis
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
# Configuration file is valid

# 4. Reiniciar HAProxy
sudo systemctl restart haproxy

# 5. Verificar estado
sudo systemctl status haproxy

# 6. Ver logs en tiempo real
sudo journalctl -u haproxy -f
```

### Alternativa: nginx como Load Balancer

Si prefieres nginx en lugar de HAProxy:

```nginx
# /etc/nginx/nginx.conf

stream {
    upstream kubernetes {
        server 192.168.1.101:6443 max_fails=3 fail_timeout=30s;
        server 192.168.1.102:6443 max_fails=3 fail_timeout=30s;
        server 192.168.1.103:6443 max_fails=3 fail_timeout=30s;
    }

    server {
        listen 6443;
        proxy_pass kubernetes;
        proxy_timeout 10m;
        proxy_connect_timeout 1s;
    }
}
```

---

## Validación de Prerequisites

### Script de Validación Completo

**Archivo**: `validate-ha-prerequisites.sh`

```bash
#!/bin/bash
#
# validate-ha-prerequisites.sh - Validar prerequisites para cluster HA
#
# Uso: ./validate-ha-prerequisites.sh --role [lb|control-plane|worker]
#

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ROLE=""
ERRORS=0
WARNINGS=0

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --role)
            ROLE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$ROLE" ]]; then
    echo "Usage: $0 --role [lb|control-plane|worker]"
    exit 1
fi

echo "========================================"
echo "HA Prerequisites Validation - Role: $ROLE"
echo "========================================"
echo ""

# Función para checks
check_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
}

check_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((ERRORS++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    ((WARNINGS++))
}

# 1. Verificar OS
echo "1. Verificando Sistema Operativo..."
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]]; then
        check_pass "OS soportado: $PRETTY_NAME"
    else
        check_warn "OS no probado: $PRETTY_NAME (puede funcionar)"
    fi
else
    check_fail "No se puede determinar el OS"
fi

# 2. Verificar recursos (solo para control-plane y worker)
if [[ "$ROLE" != "lb" ]]; then
    echo ""
    echo "2. Verificando Recursos de Hardware..."
    
    # CPU
    CPU_CORES=$(nproc)
    if [[ "$ROLE" == "control-plane" ]]; then
        if [[ $CPU_CORES -ge 2 ]]; then
            check_pass "CPU cores: $CPU_CORES (mínimo 2 para control plane)"
        else
            check_fail "CPU insuficientes: $CPU_CORES (mínimo 2 requerido)"
        fi
    fi
    
    # RAM
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
    
    if [[ "$ROLE" == "control-plane" ]]; then
        if [[ $TOTAL_RAM_MB -ge 2048 ]]; then
            check_pass "RAM: ${TOTAL_RAM_MB}MB (mínimo 2GB para control plane)"
        else
            check_fail "RAM insuficiente: ${TOTAL_RAM_MB}MB (mínimo 2048MB requerido)"
        fi
    fi
    
    # Disco
    DISK_AVAIL_GB=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    if [[ $DISK_AVAIL_GB -ge 20 ]]; then
        check_pass "Disco disponible: ${DISK_AVAIL_GB}GB"
    else
        check_warn "Disco limitado: ${DISK_AVAIL_GB}GB (recomendado 20GB+)"
    fi
fi

# 3. Verificar swap desactivado (solo control-plane y worker)
if [[ "$ROLE" != "lb" ]]; then
    echo ""
    echo "3. Verificando Swap..."
    
    if [[ $(swapon --show | wc -l) -eq 0 ]]; then
        check_pass "Swap está desactivado"
    else
        check_fail "Swap está ACTIVADO (debe estar desactivado)"
        echo "   Ejecutar: sudo swapoff -a && sudo sed -i '/ swap / s/^/#/' /etc/fstab"
    fi
fi

# 4. Verificar conectividad de red
echo ""
echo "4. Verificando Conectividad de Red..."

# Verificar interfaz de red activa
if ip link show | grep -q "state UP"; then
    check_pass "Interfaz de red activa detectada"
else
    check_fail "No hay interfaz de red activa"
fi

# Verificar conectividad a internet
if ping -c 1 8.8.8.8 &>/dev/null; then
    check_pass "Conectividad a internet OK"
else
    check_warn "Sin conectividad a internet (puede afectar instalación de paquetes)"
fi

# 5. Verificar puertos (según rol)
echo ""
echo "5. Verificando Puertos Disponibles..."

check_port() {
    local port=$1
    if ss -tuln | grep -q ":$port "; then
        check_fail "Puerto $port YA ESTÁ EN USO"
    else
        check_pass "Puerto $port disponible"
    fi
}

if [[ "$ROLE" == "lb" ]]; then
    check_port 6443  # Kubernetes API
    check_port 9090  # HAProxy stats (opcional)
elif [[ "$ROLE" == "control-plane" ]]; then
    check_port 6443  # API Server
    check_port 2379  # etcd client
    check_port 2380  # etcd peer
    check_port 10250 # Kubelet
    check_port 10259 # kube-scheduler
    check_port 10257 # kube-controller-manager
fi

# 6. Verificar software instalado
echo ""
echo "6. Verificando Software Requerido..."

if [[ "$ROLE" == "lb" ]]; then
    # Load Balancer necesita HAProxy o nginx
    if command -v haproxy &>/dev/null; then
        HAPROXY_VERSION=$(haproxy -v | head -1 | awk '{print $3}')
        check_pass "HAProxy instalado: $HAPROXY_VERSION"
    elif command -v nginx &>/dev/null; then
        NGINX_VERSION=$(nginx -v 2>&1 | awk '{print $3}')
        check_pass "nginx instalado: $NGINX_VERSION"
    else
        check_fail "Ni HAProxy ni nginx instalados"
    fi
else
    # Control plane y workers necesitan Kubernetes components
    
    if command -v kubeadm &>/dev/null; then
        KUBEADM_VERSION=$(kubeadm version -o short)
        check_pass "kubeadm instalado: $KUBEADM_VERSION"
    else
        check_fail "kubeadm NO instalado"
    fi
    
    if command -v kubelet &>/dev/null; then
        KUBELET_VERSION=$(kubelet --version | awk '{print $2}')
        check_pass "kubelet instalado: $KUBELET_VERSION"
    else
        check_fail "kubelet NO instalado"
    fi
    
    if command -v kubectl &>/dev/null; then
        KUBECTL_VERSION=$(kubectl version --client -o json | grep -o '"gitVersion":"[^"]*' | cut -d'"' -f4)
        check_pass "kubectl instalado: $KUBECTL_VERSION"
    else
        check_warn "kubectl NO instalado (recomendado)"
    fi
    
    # Container runtime (containerd)
    if systemctl is-active --quiet containerd; then
        check_pass "containerd está corriendo"
    else
        check_fail "containerd NO está corriendo"
    fi
fi

# 7. Verificar módulos del kernel (solo control-plane y worker)
if [[ "$ROLE" != "lb" ]]; then
    echo ""
    echo "7. Verificando Módulos del Kernel..."
    
    if lsmod | grep -q br_netfilter; then
        check_pass "Módulo br_netfilter cargado"
    else
        check_fail "Módulo br_netfilter NO cargado"
        echo "   Ejecutar: sudo modprobe br_netfilter"
    fi
    
    if lsmod | grep -q overlay; then
        check_pass "Módulo overlay cargado"
    else
        check_fail "Módulo overlay NO cargado"
        echo "   Ejecutar: sudo modprobe overlay"
    fi
fi

# Resumen final
echo ""
echo "========================================"
echo "Resumen de Validación"
echo "========================================"

if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}✅ LISTO PARA INSTALACIÓN${NC}"
    echo "   Todos los prerequisites cumplidos."
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  LISTO CON ADVERTENCIAS${NC}"
    echo "   Errores: $ERRORS | Advertencias: $WARNINGS"
    echo "   Puedes continuar, pero revisa las advertencias."
    exit 0
else
    echo -e "${RED}❌ NO LISTO PARA INSTALACIÓN${NC}"
    echo "   Errores: $ERRORS | Advertencias: $WARNINGS"
    echo "   Corrige los errores antes de continuar."
    exit 1
fi
```

### Uso del Script de Validación

```bash
# Hacer ejecutable
chmod +x validate-ha-prerequisites.sh

# En Load Balancer
./validate-ha-prerequisites.sh --role lb

# En cada Control Plane
./validate-ha-prerequisites.sh --role control-plane

# En cada Worker (si aplica)
./validate-ha-prerequisites.sh --role worker
```

---

## Preparación Rápida

### Opción A: Preparación Manual (paso a paso)

```bash
# 1. En TODOS los nodos: Instalar componentes base
curl -fsSL https://raw.githubusercontent.com/your-repo/install-k8s.sh | bash

# 2. En Load Balancer: Configurar HAProxy
sudo nano /etc/haproxy/haproxy.cfg
# (Editar IPs de control planes)
sudo systemctl restart haproxy

# 3. En cada nodo: Validar prerequisites
./validate-ha-prerequisites.sh --role <tu-rol>

# 4. Continuar con el README.md principal
```

### Opción B: Preparación Automatizada (script completo)

**Archivo**: `quick-setup-ha.sh`

```bash
#!/bin/bash
# quick-setup-ha.sh - Setup completo automatizado para lab HA

ROLE=$1

if [[ -z "$ROLE" ]]; then
    echo "Usage: $0 [lb|control-plane|worker]"
    exit 1
fi

echo "Iniciando setup para rol: $ROLE"

# 1. Instalar componentes
if [[ "$ROLE" == "lb" ]]; then
    sudo apt-get update && sudo apt-get install -y haproxy
else
    curl -fsSL https://raw.githubusercontent.com/your-repo/install-k8s.sh | bash
fi

# 2. Validar
./validate-ha-prerequisites.sh --role $ROLE

echo "✅ Setup completado para $ROLE"
```

---

## Checklist Final

Antes de continuar con el lab principal, verifica:

### Load Balancer
- [ ] HAProxy instalado y corriendo
- [ ] Configuración `/etc/haproxy/haproxy.cfg` con IPs correctas
- [ ] Puerto 6443 abierto y escuchando
- [ ] Firewall permite tráfico desde control planes y workers

### Control Planes (cada uno)
- [ ] kubeadm, kubelet, kubectl instalados (misma versión)
- [ ] containerd instalado y corriendo
- [ ] Swap desactivado permanentemente
- [ ] Módulos br_netfilter y overlay cargados
- [ ] sysctl configurado correctamente
- [ ] Puertos 6443, 2379, 2380, 10250, 10257, 10259 disponibles
- [ ] Conectividad al Load Balancer verificada
- [ ] Conectividad entre control planes verificada
- [ ] Hostname único configurado

### Workers (si aplica)
- [ ] kubeadm, kubelet instalados (misma versión)
- [ ] containerd instalado y corriendo
- [ ] Swap desactivado
- [ ] Conectividad al Load Balancer verificada

---

## Troubleshooting de Prerequisites

### Problema: Versiones de kubeadm/kubelet no coinciden

```bash
# Verificar versiones
kubeadm version -o short
kubelet --version

# Si difieren, reinstalar con versión específica
sudo apt-get remove -y kubeadm kubelet kubectl
sudo apt-get install -y kubeadm=1.28.0-00 kubelet=1.28.0-00 kubectl=1.28.0-00
```

### Problema: HAProxy no arranca

```bash
# Verificar sintaxis
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Ver logs
sudo journalctl -u haproxy -n 50

# Problemas comunes:
# - Puerto 6443 ya en uso → identificar proceso: sudo lsof -i :6443
# - IPs de backends incorrectas → verificar /etc/haproxy/haproxy.cfg
```

---

**Siguiente paso**: Una vez validados todos los prerequisites, continúa con el [README.md](./README.md) para el despliegue del cluster HA.
