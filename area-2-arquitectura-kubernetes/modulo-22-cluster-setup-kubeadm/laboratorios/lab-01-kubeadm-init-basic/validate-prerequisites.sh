#!/bin/bash
# validate-prerequisites.sh
# Script de validación de prerequisites para kubeadm init

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo -e "${BLUE}==========================================="
echo "Validación de Prerequisites - Lab 01"
echo "kubeadm init - Cluster Básico"
echo "==========================================="
echo -e "${NC}"

# 1. Verificar sistema operativo
echo -e "${BLUE}1. Verificando Sistema Operativo...${NC}"
if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo -e "${GREEN}✅ OS: $NAME $VERSION${NC}"
  echo "   ID: $ID"
  echo "   Version ID: $VERSION_ID"
else
  echo -e "${RED}❌ No se pudo detectar el sistema operativo${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 2. Verificar arquitectura
echo ""
echo -e "${BLUE}2. Verificando Arquitectura del Sistema...${NC}"
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
  echo -e "${GREEN}✅ Arquitectura: $ARCH (soportada)${NC}"
else
  echo -e "${YELLOW}⚠️  Arquitectura: $ARCH (podría no estar soportada)${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# 3. Verificar recursos
echo ""
echo -e "${BLUE}3. Verificando Recursos del Sistema...${NC}"

# CPU
CPU_CORES=$(nproc)
if [ $CPU_CORES -ge 2 ]; then
  echo -e "${GREEN}✅ CPU: $CPU_CORES cores (mínimo: 2)${NC}"
else
  echo -e "${RED}❌ CPU: $CPU_CORES cores (mínimo requerido: 2)${NC}"
  ERRORS=$((ERRORS + 1))
fi

# RAM
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ $TOTAL_RAM -ge 2 ]; then
  echo -e "${GREEN}✅ RAM: ${TOTAL_RAM}GB (mínimo: 2GB)${NC}"
elif [ $TOTAL_RAM -eq 1 ]; then
  # Verificar en MB si es ~2GB
  TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
  if [ $TOTAL_RAM_MB -ge 1800 ]; then
    echo -e "${GREEN}✅ RAM: ${TOTAL_RAM_MB}MB (~2GB mínimo)${NC}"
  else
    echo -e "${RED}❌ RAM: ${TOTAL_RAM_MB}MB (mínimo requerido: 2GB)${NC}"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo -e "${RED}❌ RAM: ${TOTAL_RAM}GB (mínimo requerido: 2GB)${NC}"
  ERRORS=$((ERRORS + 1))
fi

# Disco
DISK_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ $DISK_SPACE -ge 20 ]; then
  echo -e "${GREEN}✅ Disco: ${DISK_SPACE}GB disponibles (mínimo: 20GB)${NC}"
else
  echo -e "${YELLOW}⚠️  Disco: ${DISK_SPACE}GB disponibles (recomendado: 20GB+)${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# 4. Verificar swap
echo ""
echo -e "${BLUE}4. Verificando Swap...${NC}"
SWAP_SIZE=$(free -h | awk '/^Swap:/{print $2}')
if [ "$SWAP_SIZE" = "0B" ] || [ "$SWAP_SIZE" = "0" ]; then
  echo -e "${GREEN}✅ Swap deshabilitado${NC}"
else
  echo -e "${RED}❌ Swap habilitado ($SWAP_SIZE) - debe estar deshabilitado${NC}"
  echo -e "${YELLOW}   Ejecuta:${NC}"
  echo "   sudo swapoff -a"
  echo "   sudo sed -i '/ swap / s/^/#/' /etc/fstab"
  ERRORS=$((ERRORS + 1))
fi

# 5. Verificar módulos del kernel
echo ""
echo -e "${BLUE}5. Verificando Módulos del Kernel...${NC}"
MODULES=("overlay" "br_netfilter")
for mod in "${MODULES[@]}"; do
  if lsmod | grep -q "^$mod "; then
    echo -e "${GREEN}✅ Módulo $mod cargado${NC}"
  else
    echo -e "${YELLOW}⚠️  Módulo $mod NO cargado (se cargará durante setup)${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
done

# 6. Verificar parámetros sysctl
echo ""
echo -e "${BLUE}6. Verificando Parámetros Sysctl...${NC}"
check_sysctl() {
  local param=$1
  local expected=$2
  local actual=$(sysctl -n $param 2>/dev/null || echo "0")
  
  if [ "$actual" = "$expected" ]; then
    echo -e "${GREEN}✅ $param = $actual${NC}"
  else
    echo -e "${YELLOW}⚠️  $param = $actual (esperado: $expected, se configurará)${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
}

check_sysctl "net.bridge.bridge-nf-call-iptables" "1"
check_sysctl "net.bridge.bridge-nf-call-ip6tables" "1"
check_sysctl "net.ipv4.ip_forward" "1"

# 7. Verificar puertos
echo ""
echo -e "${BLUE}7. Verificando Disponibilidad de Puertos...${NC}"
PORTS=(6443 2379 2380 10250 10259 10257)
for port in "${PORTS[@]}"; do
  if command -v netstat &>/dev/null; then
    if sudo netstat -tulpn 2>/dev/null | grep -q ":$port "; then
      echo -e "${RED}❌ Puerto $port en uso:${NC}"
      sudo netstat -tulpn | grep ":$port " || true
      ERRORS=$((ERRORS + 1))
    else
      echo -e "${GREEN}✅ Puerto $port disponible${NC}"
    fi
  elif command -v ss &>/dev/null; then
    if sudo ss -tulpn 2>/dev/null | grep -q ":$port "; then
      echo -e "${RED}❌ Puerto $port en uso:${NC}"
      sudo ss -tulpn | grep ":$port " || true
      ERRORS=$((ERRORS + 1))
    else
      echo -e "${GREEN}✅ Puerto $port disponible${NC}"
    fi
  else
    echo -e "${YELLOW}⚠️  No se puede verificar puertos (netstat/ss no disponible)${NC}"
    WARNINGS=$((WARNINGS + 1))
    break
  fi
done

# 8. Verificar conectividad
echo ""
echo -e "${BLUE}8. Verificando Conectividad de Red...${NC}"
if ping -c 2 -W 3 8.8.8.8 &>/dev/null; then
  echo -e "${GREEN}✅ Conectividad a Internet (8.8.8.8)${NC}"
else
  echo -e "${RED}❌ Sin conectividad a Internet${NC}"
  ERRORS=$((ERRORS + 1))
fi

# Verificar resolución DNS
if ping -c 2 -W 3 github.com &>/dev/null; then
  echo -e "${GREEN}✅ Resolución DNS funcionando${NC}"
else
  echo -e "${YELLOW}⚠️  Problema con resolución DNS${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# 9. Verificar hostname
echo ""
echo -e "${BLUE}9. Verificando Hostname...${NC}"
HOSTNAME=$(hostname)
HOSTNAME_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}✅ Hostname: $HOSTNAME${NC}"
echo -e "${GREEN}✅ IP Principal: $HOSTNAME_IP${NC}"

# Verificar que hostname sea resolvible
if ping -c 1 -W 2 $(hostname) &>/dev/null; then
  echo -e "${GREEN}✅ Hostname resolvible${NC}"
else
  echo -e "${YELLOW}⚠️  Hostname no resolvible (se configurará en /etc/hosts)${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# 10. Verificar si kubeadm/kubelet/kubectl ya están instalados
echo ""
echo -e "${BLUE}10. Verificando Instalación Previa de Componentes...${NC}"
for cmd in kubeadm kubelet kubectl; do
  if command -v $cmd &>/dev/null; then
    if [ "$cmd" = "kubectl" ]; then
      VERSION=$($cmd version --client --short 2>/dev/null | head -1 || echo "unknown")
    else
      VERSION=$($cmd version -o short 2>/dev/null || echo "unknown")
    fi
    echo -e "${YELLOW}⚠️  $cmd ya instalado: $VERSION${NC}"
    echo "   (Se usará versión existente o se actualizará)"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "${GREEN}✅ $cmd no instalado (se instalará)${NC}"
  fi
done

# 11. Verificar containerd
echo ""
echo -e "${BLUE}11. Verificando Container Runtime...${NC}"
if systemctl is-active --quiet containerd 2>/dev/null; then
  CONTAINERD_VERSION=$(containerd --version 2>/dev/null | awk '{print $3}' || echo "unknown")
  echo -e "${GREEN}✅ containerd activo: $CONTAINERD_VERSION${NC}"
  
  # Verificar configuración de systemd cgroup
  if grep -q "SystemdCgroup = true" /etc/containerd/config.toml 2>/dev/null; then
    echo -e "${GREEN}✅ SystemdCgroup configurado correctamente${NC}"
  else
    echo -e "${YELLOW}⚠️  SystemdCgroup no configurado (se configurará)${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  if command -v containerd &>/dev/null; then
    echo -e "${YELLOW}⚠️  containerd instalado pero no activo${NC}"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "${YELLOW}⚠️  containerd no instalado (se instalará)${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# 12. Verificar acceso root/sudo
echo ""
echo -e "${BLUE}12. Verificando Privilegios...${NC}"
if [ "$EUID" -eq 0 ]; then
  echo -e "${GREEN}✅ Ejecutando como root${NC}"
elif sudo -n true 2>/dev/null; then
  echo -e "${GREEN}✅ Usuario con acceso sudo sin password${NC}"
else
  echo -e "${YELLOW}⚠️  Requerirá password para sudo${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# 13. Verificar SELinux (si aplica)
echo ""
echo -e "${BLUE}13. Verificando SELinux...${NC}"
if command -v getenforce &>/dev/null; then
  SELINUX_STATUS=$(getenforce)
  if [ "$SELINUX_STATUS" = "Disabled" ] || [ "$SELINUX_STATUS" = "Permissive" ]; then
    echo -e "${GREEN}✅ SELinux: $SELINUX_STATUS${NC}"
  else
    echo -e "${YELLOW}⚠️  SELinux: $SELINUX_STATUS (puede causar problemas)${NC}"
    echo "   Se recomienda: sudo setenforce 0"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo -e "${GREEN}✅ SELinux no presente${NC}"
fi

# 14. Verificar clusters Kubernetes previos
echo ""
echo -e "${BLUE}14. Verificando Instalaciones Previas de Kubernetes...${NC}"
if [ -d "/etc/kubernetes" ]; then
  echo -e "${YELLOW}⚠️  Directorio /etc/kubernetes existe${NC}"
  echo "   Puede haber una instalación previa"
  echo "   Ejecuta 'sudo kubeadm reset -f' si deseas limpiar"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}✅ No hay instalación previa de Kubernetes${NC}"
fi

if [ -d "/var/lib/kubelet" ]; then
  echo -e "${YELLOW}⚠️  Directorio /var/lib/kubelet existe${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

if [ -d "/var/lib/etcd" ]; then
  echo -e "${YELLOW}⚠️  Directorio /var/lib/etcd existe${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# Resumen final
echo ""
echo -e "${BLUE}==========================================="
echo "Resumen de Validación"
echo "==========================================="
echo -e "${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✅ SISTEMA COMPLETAMENTE LISTO${NC}"
  echo ""
  echo "El sistema cumple todos los prerequisitos."
  echo "Puedes proceder con kubeadm init."
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠️  SISTEMA LISTO CON ADVERTENCIAS${NC}"
  echo ""
  echo "Errores: $ERRORS"
  echo "Advertencias: $WARNINGS"
  echo ""
  echo "El sistema cumple los prerequisitos mínimos."
  echo "Las advertencias se resolverán durante el setup."
else
  echo -e "${RED}❌ SISTEMA NO LISTO${NC}"
  echo ""
  echo "Errores: $ERRORS"
  echo "Advertencias: $WARNINGS"
  echo ""
  echo "Debes resolver los errores antes de continuar."
  echo ""
  exit 1
fi

echo ""
echo -e "${BLUE}Pasos siguientes:${NC}"
echo "1. Revisar el README.md del laboratorio"
echo "2. Ejecutar instalación de containerd si es necesario"
echo "3. Instalar kubeadm, kubelet, kubectl"
echo "4. Ejecutar kubeadm init"
echo ""

exit 0
