# Setup - Lab 02: Worker Node Join

## 📋 Requisitos del Sistema

### Hardware Mínimo por Worker Node

| Recurso | Mínimo | Recomendado | Descripción |
|---------|--------|-------------|-------------|
| **CPU** | 1 core | 2+ cores | Para workload pods |
| **RAM** | 1 GB | 2+ GB | Más RAM = más pods |
| **Disco** | 10 GB | 30 GB | Para imágenes y logs |
| **Network** | 1 Gbps | 1 Gbps | Baja latencia crítica |

**⚠️ NOTA**: Workers pueden tener menos recursos que control plane, pero deben tener suficiente para los workloads que ejecutarán.

### Topología del Cluster Requerida

```
┌──────────────────────────────────────────┐
│       Prerequisito Crítico               │
│                                          │
│  Control Plane Node ya inicializado     │
│  (Lab 01 completado exitosamente)       │
│                                          │
│  kubectl get nodes debe mostrar:        │
│  control-plane   Ready   control-plane  │
└──────────────────────────────────────────┘
```

### Configuración Multi-Nodo

Este lab requiere **mínimo 2 máquinas**:

| Nodo | Rol | IP Ejemplo | Hostname | Recursos Mín |
|------|-----|------------|----------|--------------|
| Node 1 | Control Plane | 192.168.1.100 | control-plane | 2 CPU, 2GB RAM |
| Node 2 | Worker | 192.168.1.101 | worker-01 | 1 CPU, 1GB RAM |
| Node 3 | Worker (opcional) | 192.168.1.102 | worker-02 | 1 CPU, 1GB RAM |

## 🌐 Requisitos de Red

### Conectividad Entre Nodos

**CRÍTICO**: Todos los nodos deben poder comunicarse entre sí.

```bash
# Desde cada nodo, verificar ping a otros nodos
ping -c 3 192.168.1.100  # Control plane
ping -c 3 192.168.1.101  # Worker 1
ping -c 3 192.168.1.102  # Worker 2 (si existe)
```

### Puertos Requeridos en Worker Nodes

| Protocolo | Dirección | Puerto | Usado Por | Descripción |
|-----------|-----------|--------|-----------|-------------|
| TCP | Inbound | 10250 | Kubelet | Kubelet API (desde control plane) |
| TCP | Inbound | 30000-32767 | NodePort Services | Servicios tipo NodePort |
| TCP | Outbound | 6443 | API Server | Comunicación con control plane |
| TCP | Outbound | 2379-2380 | etcd | (Solo si etcd externo) |

### Verificación de Puertos

```bash
# En WORKER NODE:
# Verificar que puerto 10250 está libre
sudo netstat -tulpn | grep 10250

# Si hay algo, es probable una instalación previa
# Ejecutar: sudo kubeadm reset -f

# Verificar conectividad a API server del control plane
nc -zv 192.168.1.100 6443

# Debe retornar: Connection to 192.168.1.100 6443 port [tcp/*] succeeded!
```

### Resolución de Nombres

**Opción 1**: DNS configurado (recomendado)
```bash
# Verificar que los hostnames se resuelven
host control-plane
host worker-01
```

**Opción 2**: /etc/hosts (simple para labs)
```bash
# En TODOS los nodos, agregar entradas:
sudo cat <<EOF >> /etc/hosts
192.168.1.100 control-plane
192.168.1.101 worker-01
192.168.1.102 worker-02
EOF

# Verificar
ping control-plane
ping worker-01
```

## 🔧 Prerequisitos de Software

### Versiones Requeridas (DEBEN COINCIDIR CON CONTROL PLANE)

```bash
# Verificar versiones en control plane
kubectl version --short

# En worker node, instalar MISMAS versiones
# Kubernetes: 1.28.0
# kubeadm: 1.28.0
# kubelet: 1.28.0
# kubectl: 1.28.0 (opcional en workers)
# containerd: 1.7.0+
```

**⚠️ CRÍTICO**: 
- Workers deben estar en la **misma versión minor** que control plane
- Skew de versión permitido: máximo ±1 versión minor
- Ejemplo: Control plane 1.28.x puede tener workers 1.27.x o 1.29.x

### Container Runtime

**DEBE ser el mismo que en control plane**:
- Si control plane usa **containerd** → workers usan **containerd**
- Si control plane usa **CRI-O** → workers usan **CRI-O**

**Este lab asume containerd en todos los nodos.**

## ✅ Script de Validación de Prerequisites

Crea y ejecuta este script en el WORKER NODE antes del join:

```bash
#!/bin/bash
# validate-worker-prerequisites.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONTROL_PLANE_IP="${1:-192.168.1.100}"
ERRORS=0
WARNINGS=0

echo -e "${BLUE}==========================================="
echo "Validación Worker Node Prerequisites"
echo "==========================================="
echo -e "${NC}"
echo "Control Plane IP: $CONTROL_PLANE_IP"
echo ""

# 1. Verificar sistema operativo
echo -e "${BLUE}1. Verificando Sistema Operativo...${NC}"
if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo -e "${GREEN}✅ OS: $NAME $VERSION${NC}"
else
  echo -e "${RED}❌ No se pudo detectar el sistema operativo${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 2. Verificar recursos
echo ""
echo -e "${BLUE}2. Verificando Recursos del Sistema...${NC}"

# CPU
CPU_CORES=$(nproc)
if [ $CPU_CORES -ge 1 ]; then
  echo -e "${GREEN}✅ CPU: $CPU_CORES cores (mínimo: 1)${NC}"
else
  echo -e "${RED}❌ CPU insuficiente${NC}"
  ERRORS=$((ERRORS + 1))
fi

# RAM
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
if [ $TOTAL_RAM_MB -ge 900 ]; then
  echo -e "${GREEN}✅ RAM: ${TOTAL_RAM_MB}MB (mínimo: 1GB)${NC}"
else
  echo -e "${RED}❌ RAM: ${TOTAL_RAM_MB}MB (mínimo requerido: 1GB)${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 3. Verificar swap
echo ""
echo -e "${BLUE}3. Verificando Swap...${NC}"
SWAP_SIZE=$(free -h | awk '/^Swap:/{print $2}')
if [ "$SWAP_SIZE" = "0B" ] || [ "$SWAP_SIZE" = "0" ]; then
  echo -e "${GREEN}✅ Swap deshabilitado${NC}"
else
  echo -e "${RED}❌ Swap habilitado ($SWAP_SIZE) - debe estar deshabilitado${NC}"
  echo "   Ejecuta: sudo swapoff -a && sudo sed -i '/ swap / s/^/#/' /etc/fstab"
  ERRORS=$((ERRORS + 1))
fi

# 4. Verificar conectividad al control plane
echo ""
echo -e "${BLUE}4. Verificando Conectividad al Control Plane...${NC}"

# Ping
if ping -c 2 -W 3 $CONTROL_PLANE_IP &>/dev/null; then
  echo -e "${GREEN}✅ Ping al control plane exitoso${NC}"
else
  echo -e "${RED}❌ No se puede hacer ping al control plane${NC}"
  ERRORS=$((ERRORS + 1))
fi

# Puerto 6443 (API server)
if nc -zv $CONTROL_PLANE_IP 6443 &>/dev/null || \
   timeout 3 bash -c "cat < /dev/null > /dev/tcp/$CONTROL_PLANE_IP/6443" &>/dev/null; then
  echo -e "${GREEN}✅ Puerto 6443 (API server) accesible${NC}"
else
  echo -e "${RED}❌ No se puede conectar al puerto 6443${NC}"
  echo "   Verifica firewall en control plane"
  ERRORS=$((ERRORS + 1))
fi

# 5. Verificar puertos locales
echo ""
echo -e "${BLUE}5. Verificando Disponibilidad de Puertos Locales...${NC}"
PORTS=(10250)
for port in "${PORTS[@]}"; do
  if command -v netstat &>/dev/null; then
    if sudo netstat -tulpn 2>/dev/null | grep -q ":$port "; then
      echo -e "${RED}❌ Puerto $port en uso${NC}"
      sudo netstat -tulpn | grep ":$port "
      echo "   Ejecuta: sudo kubeadm reset -f"
      ERRORS=$((ERRORS + 1))
    else
      echo -e "${GREEN}✅ Puerto $port disponible${NC}"
    fi
  elif command -v ss &>/dev/null; then
    if sudo ss -tulpn 2>/dev/null | grep -q ":$port "; then
      echo -e "${RED}❌ Puerto $port en uso${NC}"
      ERRORS=$((ERRORS + 1))
    else
      echo -e "${GREEN}✅ Puerto $port disponible${NC}"
    fi
  fi
done

# 6. Verificar módulos del kernel
echo ""
echo -e "${BLUE}6. Verificando Módulos del Kernel...${NC}"
for mod in overlay br_netfilter; do
  if lsmod | grep -q "^$mod "; then
    echo -e "${GREEN}✅ Módulo $mod cargado${NC}"
  else
    echo -e "${YELLOW}⚠️  Módulo $mod NO cargado${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
done

# 7. Verificar parámetros sysctl
echo ""
echo -e "${BLUE}7. Verificando Parámetros Sysctl...${NC}"
check_sysctl() {
  local param=$1
  local expected=$2
  local actual=$(sysctl -n $param 2>/dev/null || echo "0")
  
  if [ "$actual" = "$expected" ]; then
    echo -e "${GREEN}✅ $param = $actual${NC}"
  else
    echo -e "${YELLOW}⚠️  $param = $actual (esperado: $expected)${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
}

check_sysctl "net.bridge.bridge-nf-call-iptables" "1"
check_sysctl "net.ipv4.ip_forward" "1"

# 8. Verificar kubelet, kubeadm instalados
echo ""
echo -e "${BLUE}8. Verificando Componentes de Kubernetes...${NC}"
for cmd in kubelet kubeadm; do
  if command -v $cmd &>/dev/null; then
    VERSION=$($cmd version -o short 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✅ $cmd instalado: $VERSION${NC}"
  else
    echo -e "${RED}❌ $cmd no instalado${NC}"
    ERRORS=$((ERRORS + 1))
  fi
done

# 9. Verificar containerd
echo ""
echo -e "${BLUE}9. Verificando Container Runtime...${NC}"
if systemctl is-active --quiet containerd; then
  CONTAINERD_VERSION=$(containerd --version 2>/dev/null | awk '{print $3}')
  echo -e "${GREEN}✅ containerd activo: $CONTAINERD_VERSION${NC}"
  
  # Verificar SystemdCgroup
  if grep -q "SystemdCgroup = true" /etc/containerd/config.toml 2>/dev/null; then
    echo -e "${GREEN}✅ SystemdCgroup configurado${NC}"
  else
    echo -e "${YELLOW}⚠️  SystemdCgroup no configurado${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo -e "${RED}❌ containerd no está activo${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 10. Verificar instalación previa de K8s
echo ""
echo -e "${BLUE}10. Verificando Instalaciones Previas...${NC}"
if [ -d "/etc/kubernetes" ]; then
  echo -e "${YELLOW}⚠️  /etc/kubernetes existe${NC}"
  echo "   Ejecuta: sudo kubeadm reset -f"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}✅ No hay instalación previa${NC}"
fi

# 11. Verificar sincronización de hora
echo ""
echo -e "${BLUE}11. Verificando Sincronización de Hora...${NC}"
if command -v timedatectl &>/dev/null; then
  if timedatectl status | grep -q "synchronized: yes"; then
    echo -e "${GREEN}✅ Hora sincronizada via NTP${NC}"
  else
    echo -e "${YELLOW}⚠️  Hora no sincronizada${NC}"
    echo "   Ejecuta: sudo timedatectl set-ntp true"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo -e "${YELLOW}⚠️  timedatectl no disponible${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# Resumen
echo ""
echo -e "${BLUE}==========================================="
echo "Resumen de Validación"
echo "==========================================="
echo -e "${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✅ WORKER NODE LISTO PARA JOIN${NC}"
  echo ""
  echo "Pasos siguientes:"
  echo "1. En control plane: kubeadm token create --print-join-command"
  echo "2. En worker: Ejecutar el join command"
  echo "3. En control plane: kubectl get nodes"
  EXIT_CODE=0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠️  WORKER NODE LISTO CON ADVERTENCIAS${NC}"
  echo ""
  echo "Errores: $ERRORS"
  echo "Advertencias: $WARNINGS"
  EXIT_CODE=0
else
  echo -e "${RED}❌ WORKER NODE NO LISTO${NC}"
  echo ""
  echo "Errores: $ERRORS"
  echo "Advertencias: $WARNINGS"
  echo ""
  echo "Resuelve los errores antes de hacer join."
  EXIT_CODE=1
fi

echo ""
exit $EXIT_CODE
```

## 🚀 Preparación Rápida del Worker Node

### Opción 1: Script Automatizado (Recomendado)

```bash
# Ejecutar script de preparación (incluido en este lab)
./prepare-worker.sh

# Este script hace:
# - Deshabilita swap
# - Configura módulos kernel
# - Configura sysctl
# - Instala y configura containerd
# - Instala kubeadm, kubelet
# - Valida prerequisites
```

### Opción 2: Preparación Manual

```bash
# 1. Deshabilitar swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 2. Cargar módulos
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# 3. Configurar sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# 4. Instalar containerd (Ubuntu)
sudo apt-get update
sudo apt-get install -y containerd.io

# Configurar containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml
sudo systemctl restart containerd

# 5. Instalar kubeadm y kubelet
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm
sudo apt-mark hold kubelet kubeadm

# 6. Validar
./validate-worker-prerequisites.sh 192.168.1.100
```

## 🔒 Consideraciones de Seguridad

### Bootstrap Token Security

- **Tokens son sensibles**: Tratar como passwords
- **TTL por defecto**: 24 horas (después expiran)
- **Rotación**: Crear nuevos tokens regularmente
- **Uso único**: Idealmente, un token por worker node

### CA Certificate Hash

- **Previene**: Man-in-the-middle attacks
- **Siempre verificar**: El hash del CA cert
- **No usar**: `--discovery-token-unsafe-skip-ca-verification` en producción

### Network Policies

```bash
# Después de join, considerar aplicar network policies
# para restringir comunicación entre pods
kubectl apply -f network-policy.yaml
```

## 📊 Troubleshooting Prerequisites

### Problema: No puede instalar kubeadm

**Causa**: Repositorio no configurado correctamente

**Solución**:
```bash
# Verificar repositorio
cat /etc/apt/sources.list.d/kubernetes.list

# Re-agregar GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

sudo apt-get update
```

### Problema: containerd no inicia

**Causa**: Configuración incorrecta

**Solución**:
```bash
# Regenerar configuración por defecto
sudo rm /etc/containerd/config.toml
containerd config default | sudo tee /etc/containerd/config.toml

# Configurar systemd cgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl status containerd
```

### Problema: No hay conectividad al control plane

**Causa**: Firewall bloqueando puerto 6443

**Solución**:
```bash
# En control plane, abrir puerto 6443
sudo ufw allow 6443/tcp

# O deshabilitar firewall (solo labs)
sudo ufw disable
```

## ✅ Checklist de Preparación

Antes de ejecutar `kubeadm join`, verificar:

- [ ] Control plane está funcionando (`kubectl get nodes`)
- [ ] Worker node cumple recursos mínimos (1 CPU, 1GB RAM)
- [ ] Swap está deshabilitado en worker
- [ ] Módulos kernel cargados (overlay, br_netfilter)
- [ ] Parámetros sysctl configurados
- [ ] containerd instalado y corriendo
- [ ] kubeadm y kubelet instalados (misma versión que control plane)
- [ ] Puerto 10250 disponible en worker
- [ ] Worker puede hacer ping al control plane
- [ ] Worker puede conectar al puerto 6443 del control plane
- [ ] Hora sincronizada entre nodos (NTP)
- [ ] Hostnames configurados en /etc/hosts (si no hay DNS)

---

**Próximo paso**: Ejecutar el procedimiento del laboratorio en [README.md](./README.md)
