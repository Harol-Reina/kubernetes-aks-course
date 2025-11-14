# Setup - Lab 04: External etcd Cluster

## Descripción General

Este documento detalla los **prerequisites, requisitos de infraestructura y preparación** necesarios para desplegar un cluster Kubernetes con etcd externo.

---

## Tabla de Contenidos

1. [Requisitos de Hardware](#requisitos-de-hardware)
2. [Topología de Red](#topología-de-red)
3. [Requisitos de Software](#requisitos-de-software)
4. [Preparación de Nodos](#preparación-de-nodos)
5. [Validación de Prerequisites](#validación-de-prerequisites)

---

## Requisitos de Hardware

### Configuración Mínima (Lab/Testing)

| Componente | Cantidad | CPU | RAM | Disco | Notas |
|------------|----------|-----|-----|-------|-------|
| **etcd nodes** | 3 | 2 cores | 2 GB | 20 GB SSD | Dedicados para etcd |
| **Control Planes** | 3 | 2 cores | 2 GB | 20 GB | Sin etcd local |
| **Load Balancer** | 1 | 1 core | 512 MB | 10 GB | HAProxy |
| **Workers** (opcional) | 0-3 | 2 cores | 2 GB | 20 GB | Workloads |

**Total mínimo**: 7 nodos (3 etcd + 3 control + 1 LB)

### Configuración Recomendada (Producción)

| Componente | Cantidad | CPU | RAM | Disco | IOPS | Notas |
|------------|----------|-----|-----|-------|------|-------|
| **etcd nodes** | 3-5 | 4 cores | 8 GB | 100 GB SSD | 3000+ | NVMe recomendado |
| **Control Planes** | 3-5 | 4 cores | 8 GB | 100 GB SSD | 1000+ | Escalable |
| **Load Balancer** | 2 (HA) | 2 cores | 2 GB | 20 GB | - | Con keepalived |
| **Workers** | 3+ | 8+ cores | 16+ GB | 200+ GB | 1000+ | Según workload |

### Notas Críticas sobre Hardware

```
ETCD - REQUISITOS ESPECIALES:
├── SSD OBLIGATORIO (HDD NO soportado en producción)
├── Latencia de disco: <10ms (idealmente <1ms con NVMe)
├── Throughput: 500+ IOPS mínimo
├── Red: Baja latencia (<10ms entre nodos etcd)
└── CPU: 2+ cores dedicados (etcd es single-threaded por operación)

RAZÓN:
etcd escribe cada cambio al disco SINCRÓNICAMENTE
→ Latencia de disco = latencia de escritura en cluster
→ SSD reduce latencia de ~10ms (HDD) a <1ms (NVMe)
→ Mejora performance de cluster 10-100x

QUORUM:
├── 3 nodos: Tolera 1 fallo (50% + 1 = 2/3)
├── 5 nodos: Tolera 2 fallos (3/5)
└── 7 nodos: Tolera 3 fallos (4/7)
   (NO recomendado: más nodos = más latencia)
```

---

## Topología de Red

### Arquitectura de Red Recomendada

```
NETWORK TOPOLOGY - EXTERNAL ETCD:

┌─────────────────────────────────────────────────────┐
│          PRODUCTION NETWORK (10.0.0.0/16)           │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌───────────────────────────────────────────┐    │
│  │    ETCD SUBNET (10.0.1.0/24)              │    │
│  │    VLAN 10 - Aislada                       │    │
│  │                                             │    │
│  │  etcd-01: 10.0.1.11                        │    │
│  │  etcd-02: 10.0.1.12                        │    │
│  │  etcd-03: 10.0.1.13                        │    │
│  │                                             │    │
│  │  Firewall: Solo control planes pueden      │    │
│  │            conectar al puerto 2379         │    │
│  └───────────────────────────────────────────┘    │
│                       │                             │
│  ┌────────────────────┼────────────────────────┐   │
│  │    CONTROL PLANE SUBNET (10.0.2.0/24)      │   │
│  │    VLAN 20                                  │   │
│  │                                             │   │
│  │  master-01: 10.0.2.11                      │   │
│  │  master-02: 10.0.2.12                      │   │
│  │  master-03: 10.0.2.13                      │   │
│  └─────────────────────────────────────────────┘   │
│                       │                             │
│  ┌────────────────────┼────────────────────────┐   │
│  │    WORKER SUBNET (10.0.3.0/24)             │   │
│  │    VLAN 30                                  │   │
│  │                                             │   │
│  │  worker-01: 10.0.3.11                      │   │
│  │  worker-02: 10.0.3.12                      │   │
│  │  worker-03: 10.0.3.13                      │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  Load Balancer: 10.0.0.100 (accesible desde todas) │
│                                                     │
└─────────────────────────────────────────────────────┘

VENTAJAS DE ESTA TOPOLOGÍA:
✅ etcd aislado de workers (seguridad)
✅ Control planes pueden acceder a etcd (2379)
✅ etcd nodes se comunican entre sí (2380)
✅ Fácil aplicar firewall rules por VLAN
```

### Puertos Requeridos

#### etcd Nodes

| Puerto | Protocolo | Fuente | Destino | Propósito |
|--------|-----------|--------|---------|-----------|
| 2379 | TCP | Control Planes | etcd nodes | Client API (API Server → etcd) |
| 2380 | TCP | Otros etcd nodes | etcd nodes | Peer communication (raft) |

#### Control Planes

| Puerto | Protocolo | Fuente | Destino | Propósito |
|--------|-----------|--------|---------|-----------|
| 6443 | TCP | Load Balancer, Workers | Control Planes | Kubernetes API Server |
| 10250 | TCP | Control Planes | Control Planes | Kubelet API |
| 10259 | TCP | Localhost | Control Plane | kube-scheduler |
| 10257 | TCP | Localhost | Control Plane | kube-controller-manager |

#### Load Balancer

| Puerto | Protocolo | Fuente | Destino | Propósito |
|--------|-----------|--------|---------|-----------|
| 6443 | TCP | Workers, Admins | LB | Kubernetes API (frontend) |

### Configuración de Firewall

**En nodos etcd**:

```bash
# Ubuntu/Debian (ufw)
sudo ufw allow from 10.0.2.0/24 to any port 2379 proto tcp  # Control planes
sudo ufw allow from 10.0.1.0/24 to any port 2380 proto tcp  # Otros etcd
sudo ufw enable

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.2.0/24" port port="2379" protocol="tcp" accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.1.0/24" port port="2380" protocol="tcp" accept'
sudo firewall-cmd --reload
```

**En control planes**:

```bash
# Permitir API Server
sudo ufw allow 6443/tcp
sudo ufw allow from 10.0.2.0/24 to any port 10250 proto tcp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.2.0/24" port port="10250" protocol="tcp" accept'
sudo firewall-cmd --reload
```

### Resolución de Nombres

**Opción A: DNS (Recomendado para Producción)**

Configurar registros A en servidor DNS:

```
# /etc/bind/zones/example.com.db (ejemplo BIND9)
etcd-01    IN  A  10.0.1.11
etcd-02    IN  A  10.0.1.12
etcd-03    IN  A  10.0.1.13
master-01  IN  A  10.0.2.11
master-02  IN  A  10.0.2.12
master-03  IN  A  10.0.2.13
k8s-lb     IN  A  10.0.0.100
```

**Opción B: /etc/hosts (Válido para Labs)**

```bash
# Agregar en TODOS los nodos
cat <<EOF | sudo tee -a /etc/hosts
# etcd cluster
10.0.1.11   etcd-01
10.0.1.12   etcd-02
10.0.1.13   etcd-03

# Control planes
10.0.2.11   master-01
10.0.2.12   master-02
10.0.2.13   master-03

# Load Balancer
10.0.0.100  k8s-lb
EOF
```

---

## Requisitos de Software

### Versiones Compatibles

| Software | Versión Recomendada | Versión Mínima | Notas |
|----------|---------------------|----------------|-------|
| **etcd** | v3.5.10 | v3.4.x | Última estable |
| **Kubernetes** | v1.28.x | v1.26.x | Compatible con etcd 3.5 |
| **kubeadm** | v1.28.x | v1.26.x | Debe coincidir con K8s |
| **containerd** | v1.7.x | v1.6.x | Container runtime |
| **HAProxy** | 2.8.x | 2.4.x | Load Balancer |
| **cfssl** | v1.6.4 | v1.6.x | Generación de certs |

### Instalación de etcd

**En cada nodo etcd** (etcd-01, etcd-02, etcd-03):

```bash
#!/bin/bash
# install-etcd.sh

# Versión de etcd
ETCD_VER=v3.5.10

# Detectar arquitectura
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
esac

# Descargar etcd
wget -q --https-only \
  "https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz"

# Verificar checksum (opcional pero recomendado)
wget -q --https-only \
  "https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz.sha256"
sha256sum -c "etcd-${ETCD_VER}-linux-${ARCH}.tar.gz.sha256"

# Extraer binarios
tar xzf "etcd-${ETCD_VER}-linux-${ARCH}.tar.gz"

# Mover a /usr/local/bin
sudo mv "etcd-${ETCD_VER}-linux-${ARCH}/etcd" /usr/local/bin/
sudo mv "etcd-${ETCD_VER}-linux-${ARCH}/etcdctl" /usr/local/bin/
sudo mv "etcd-${ETCD_VER}-linux-${ARCH}/etcdutl" /usr/local/bin/

# Verificar instalación
etcd --version
etcdctl version
etcdutl version

# Crear directorios
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd

echo "✅ etcd instalado correctamente"
```

### Instalación de cfssl (Generación de Certificados)

**En un nodo administrativo** (puede ser tu laptop):

```bash
#!/bin/bash
# install-cfssl.sh

CFSSL_VER=1.6.4

# Detectar arquitectura
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="linux_amd64" ;;
    aarch64) ARCH="linux_arm64" ;;
esac

# Descargar cfssl y cfssljson
wget -q --https-only \
  "https://github.com/cloudflare/cfssl/releases/download/v${CFSSL_VER}/cfssl_${CFSSL_VER}_${ARCH}"
wget -q --https-only \
  "https://github.com/cloudflare/cfssl/releases/download/v${CFSSL_VER}/cfssljson_${CFSSL_VER}_${ARCH}"

# Hacer ejecutables
chmod +x "cfssl_${CFSSL_VER}_${ARCH}"
chmod +x "cfssljson_${CFSSL_VER}_${ARCH}"

# Mover a /usr/local/bin
sudo mv "cfssl_${CFSSL_VER}_${ARCH}" /usr/local/bin/cfssl
sudo mv "cfssljson_${CFSSL_VER}_${ARCH}" /usr/local/bin/cfssljson

# Verificar
cfssl version
cfssljson -version

echo "✅ cfssl instalado correctamente"
```

### Instalación de Kubernetes Components

**En control planes** (usar script del Lab 01):

```bash
# Ver Lab 01: validate-prerequisites.sh
# O ejecutar:

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl containerd
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable kubelet containerd
```

---

## Preparación de Nodos

### Checklist Pre-Setup

**Para nodos etcd**:

- [ ] Sistema operativo actualizado
- [ ] Hostname único configurado
- [ ] etcd binarios instalados (/usr/local/bin/etcd, etcdctl)
- [ ] Directorios creados (/etc/etcd, /var/lib/etcd)
- [ ] Firewall configurado (puertos 2379, 2380)
- [ ] Swap desactivado
- [ ] NTP/chrony configurado (sincronización de tiempo)
- [ ] SSD montado en /var/lib/etcd
- [ ] SSH con claves (sin contraseña)

**Para control planes**:

- [ ] kubeadm, kubelet, kubectl instalados
- [ ] containerd instalado y corriendo
- [ ] Swap desactivado
- [ ] Módulos kernel cargados (overlay, br_netfilter)
- [ ] sysctl configurado (ip_forward, bridge-nf-call-iptables)
- [ ] Firewall configurado (puerto 6443, 10250)
- [ ] SSH con claves

### Sincronización de Tiempo (CRÍTICO para etcd)

etcd requiere que todos los nodos tengan relojes sincronizados (drift <1 segundo):

```bash
# Instalar chrony (o NTP)
sudo apt-get install -y chrony

# Configurar
cat <<EOF | sudo tee /etc/chrony/chrony.conf
# Usar servidores NTP públicos
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst

# Permitir sincronización rápida al inicio
makestep 1.0 3

# Directorio para drift file
driftfile /var/lib/chrony/drift
EOF

# Reiniciar chrony
sudo systemctl restart chrony
sudo systemctl enable chrony

# Verificar sincronización
chronyc tracking
# Debe mostrar: System time: X.XXX seconds fast/slow of NTP time

# Verificar fuentes
chronyc sources
# Debe mostrar servidores NTP con '*' (en uso)
```

### Optimización de Disco para etcd (SSD)

```bash
# Verificar que /var/lib/etcd está en SSD
lsblk -d -o name,rota
# rota=0 → SSD
# rota=1 → HDD (NO usar para producción)

# Verificar latencia de disco
sudo fio --name=random-write --ioengine=libaio --rw=randwrite \
  --bs=4k --size=128m --numjobs=1 --iodepth=1 \
  --runtime=60 --time_based --end_fsync=1 \
  --filename=/var/lib/etcd/fio-test --direct=1

# Latencia esperada:
# SSD SATA: ~0.1-1ms
# NVMe: ~0.01-0.1ms
# HDD: ~10-20ms (INACEPTABLE)

# Limpiar test
sudo rm /var/lib/etcd/fio-test
```

---

## Validación de Prerequisites

### Script de Validación Completo

```bash
#!/bin/bash
# validate-external-etcd-prerequisites.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ROLE="${1:-}"
ERRORS=0
WARNINGS=0

if [[ -z "$ROLE" ]]; then
    echo "Uso: $0 [etcd|control-plane]"
    exit 1
fi

check_pass() { echo -e "${GREEN}✅${NC} $*"; }
check_fail() { echo -e "${RED}❌${NC} $*"; ((ERRORS++)); }
check_warn() { echo -e "${YELLOW}⚠️${NC} $*"; ((WARNINGS++)); }

echo "=== Validando prerequisites para: $ROLE ==="
echo ""

# 1. Sistema operativo
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    check_pass "OS: $PRETTY_NAME"
else
    check_fail "No se puede determinar el OS"
fi

# 2. Verificar swap desactivado
if [[ $(swapon --show | wc -l) -eq 0 ]]; then
    check_pass "Swap desactivado"
else
    check_fail "Swap está ACTIVADO (desactivar con: swapoff -a)"
fi

# 3. Verificar hostname único
HOSTNAME=$(hostname)
if [[ -n "$HOSTNAME" ]] && [[ "$HOSTNAME" != "localhost" ]]; then
    check_pass "Hostname único: $HOSTNAME"
else
    check_warn "Hostname genérico: $HOSTNAME (cambiar con: hostnamectl)"
fi

# 4. Verificar sincronización de tiempo
if command -v chronyc &>/dev/null; then
    TIME_OFFSET=$(chronyc tracking | grep "System time" | awk '{print $4}')
    if (( $(echo "$TIME_OFFSET < 1.0" | bc -l) )); then
        check_pass "Tiempo sincronizado (offset: ${TIME_OFFSET}s)"
    else
        check_warn "Offset de tiempo alto: ${TIME_OFFSET}s (>1s puede causar problemas)"
    fi
else
    check_warn "chrony no instalado (recomendado para etcd)"
fi

# Validaciones específicas por rol
if [[ "$ROLE" == "etcd" ]]; then
    echo ""
    echo "=== Validaciones específicas de etcd ==="
    
    # etcd binarios
    if command -v etcd &>/dev/null; then
        ETCD_VER=$(etcd --version | head -1 | awk '{print $3}')
        check_pass "etcd instalado: $ETCD_VER"
    else
        check_fail "etcd NO instalado"
    fi
    
    if command -v etcdctl &>/dev/null; then
        check_pass "etcdctl instalado"
    else
        check_fail "etcdctl NO instalado"
    fi
    
    # Directorios
    if [[ -d /etc/etcd ]] && [[ -d /var/lib/etcd ]]; then
        check_pass "Directorios etcd creados"
    else
        check_fail "Directorios etcd no existen (crear: mkdir -p /etc/etcd /var/lib/etcd)"
    fi
    
    # Permisos
    if [[ $(stat -c %a /var/lib/etcd) == "700" ]]; then
        check_pass "Permisos /var/lib/etcd correctos (700)"
    else
        check_warn "Permisos /var/lib/etcd incorrectos (ejecutar: chmod 700 /var/lib/etcd)"
    fi
    
    # SSD check
    ETCD_DEVICE=$(df /var/lib/etcd | tail -1 | awk '{print $1}')
    ETCD_DISK=$(lsblk -no pkname "$ETCD_DEVICE" 2>/dev/null || echo "unknown")
    if [[ -n "$ETCD_DISK" ]] && [[ "$ETCD_DISK" != "unknown" ]]; then
        ROTA=$(lsblk -d -no rota "/dev/$ETCD_DISK" 2>/dev/null || echo "1")
        if [[ "$ROTA" == "0" ]]; then
            check_pass "/var/lib/etcd en SSD (rota=0)"
        else
            check_warn "/var/lib/etcd en HDD (rota=1) - NO recomendado para producción"
        fi
    fi
    
    # Puertos
    for port in 2379 2380; do
        if ss -tuln | grep -q ":$port "; then
            check_warn "Puerto $port YA EN USO (puede ser otro servicio)"
        else
            check_pass "Puerto $port disponible"
        fi
    done

elif [[ "$ROLE" == "control-plane" ]]; then
    echo ""
    echo "=== Validaciones específicas de control plane ==="
    
    # Kubernetes components
    for cmd in kubeadm kubelet kubectl; do
        if command -v $cmd &>/dev/null; then
            VERSION=$($cmd version --short 2>/dev/null | head -1 || echo "unknown")
            check_pass "$cmd instalado: $VERSION"
        else
            check_fail "$cmd NO instalado"
        fi
    done
    
    # containerd
    if systemctl is-active --quiet containerd; then
        check_pass "containerd corriendo"
    else
        check_fail "containerd NO corriendo"
    fi
    
    # Módulos kernel
    for mod in overlay br_netfilter; do
        if lsmod | grep -q $mod; then
            check_pass "Módulo $mod cargado"
        else
            check_fail "Módulo $mod NO cargado (cargar: modprobe $mod)"
        fi
    done
    
    # sysctl
    for param in net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables; do
        VALUE=$(sysctl -n $param 2>/dev/null || echo "0")
        if [[ "$VALUE" == "1" ]]; then
            check_pass "sysctl $param = 1"
        else
            check_fail "sysctl $param = 0 (debe ser 1)"
        fi
    done
    
    # Puerto 6443
    if ss -tuln | grep -q ":6443 "; then
        check_warn "Puerto 6443 YA EN USO"
    else
        check_pass "Puerto 6443 disponible"
    fi
fi

# Resumen
echo ""
echo "========================================"
if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}✅ LISTO PARA SETUP${NC}"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}⚠️ LISTO CON $WARNINGS ADVERTENCIAS${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS ERRORES - CORREGIR ANTES DE CONTINUAR${NC}"
    exit 1
fi
```

**Uso**:

```bash
# En nodos etcd
./validate-external-etcd-prerequisites.sh etcd

# En control planes
./validate-external-etcd-prerequisites.sh control-plane
```

---

## Troubleshooting de Prerequisites

### Problema: Time sync drift alto

```bash
# Verificar offset
chronyc tracking | grep "System time"

# Forzar sincronización
sudo chronyc -a makestep

# Reiniciar chrony
sudo systemctl restart chrony
```

### Problema: etcd en HDD (no SSD)

```bash
# Verificar tipo de disco
lsblk -d -o name,rota /dev/sda
# Si rota=1 → HDD

# Opción 1: Agregar SSD y remontar /var/lib/etcd
# Opción 2: Usar tmpfs (SOLO PARA TESTING - datos se pierden al reiniciar)
sudo mount -t tmpfs -o size=2G tmpfs /var/lib/etcd
```

---

**Siguiente paso**: Una vez validados todos los prerequisites, continúa con el [README.md](./README.md) para el despliegue del cluster.
