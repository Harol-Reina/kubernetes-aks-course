#!/bin/bash
# cleanup.sh
# Script de limpieza completa del cluster de Kubernetes

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================="
echo "Cleanup - Lab 01: Cluster Básico kubeadm"
echo "==========================================="
echo -e "${NC}"

# Verificar si se ejecuta con permisos adecuados
if [ "$EUID" -ne 0 ]; then 
  echo -e "${YELLOW}Este script requiere permisos de root.${NC}"
  echo "Ejecutando con sudo..."
  exec sudo "$0" "$@"
fi

echo -e "${YELLOW}⚠️  ADVERTENCIA: Este script eliminará completamente el cluster${NC}"
echo ""
echo "Se eliminarán:"
echo "  - Cluster de Kubernetes (kubeadm reset)"
echo "  - Directorios /etc/kubernetes, /var/lib/kubelet, /var/lib/etcd"
echo "  - Configuraciones de kubectl (~/.kube)"
echo "  - Reglas iptables de Kubernetes"
echo "  - Namespaces y recursos del cluster"
echo ""
read -p "¿Deseas continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${GREEN}Operación cancelada${NC}"
  exit 0
fi

echo ""
echo -e "${BLUE}Iniciando limpieza del cluster...${NC}"
echo ""

# Paso 1: Eliminar namespace de prueba si existe
echo -e "${BLUE}[1/10] Eliminando namespace de prueba...${NC}"
if kubectl get namespace test-cluster &>/dev/null; then
  kubectl delete namespace test-cluster --ignore-not-found --timeout=60s
  echo -e "${GREEN}✅ Namespace test-cluster eliminado${NC}"
else
  echo -e "${GREEN}✅ Namespace test-cluster no existe${NC}"
fi

# Paso 2: Drenar el nodo (solo si es multi-nodo)
echo ""
echo -e "${BLUE}[2/10] Drenando nodo (si aplica)...${NC}"
NODE_NAME=$(hostname)
if kubectl get nodes &>/dev/null; then
  if kubectl get nodes | grep -q "$NODE_NAME"; then
    kubectl drain $NODE_NAME --delete-emptydir-data --force --ignore-daemonsets --timeout=60s 2>/dev/null || true
    echo -e "${GREEN}✅ Nodo drenado${NC}"
  else
    echo -e "${GREEN}✅ Nodo no encontrado en cluster${NC}"
  fi
else
  echo -e "${GREEN}✅ Cluster no accesible (skip)${NC}"
fi

# Paso 3: Eliminar nodo del cluster
echo ""
echo -e "${BLUE}[3/10] Eliminando nodo del cluster...${NC}"
if kubectl get nodes &>/dev/null; then
  kubectl delete node $NODE_NAME --ignore-not-found --timeout=30s 2>/dev/null || true
  echo -e "${GREEN}✅ Nodo eliminado del cluster${NC}"
else
  echo -e "${GREEN}✅ Cluster no accesible (skip)${NC}"
fi

# Paso 4: Ejecutar kubeadm reset
echo ""
echo -e "${BLUE}[4/10] Ejecutando kubeadm reset...${NC}"
if command -v kubeadm &>/dev/null; then
  kubeadm reset -f 2>/dev/null || true
  echo -e "${GREEN}✅ kubeadm reset completado${NC}"
else
  echo -e "${YELLOW}⚠️  kubeadm no instalado (skip)${NC}"
fi

# Paso 5: Eliminar directorios de Kubernetes
echo ""
echo -e "${BLUE}[5/10] Eliminando directorios de Kubernetes...${NC}"
DIRS_TO_REMOVE=(
  "/etc/kubernetes"
  "/var/lib/kubelet"
  "/var/lib/etcd"
  "/var/lib/cni"
  "/etc/cni"
  "/opt/cni"
)

for dir in "${DIRS_TO_REMOVE[@]}"; do
  if [ -d "$dir" ]; then
    rm -rf "$dir"
    echo -e "${GREEN}✅ Eliminado: $dir${NC}"
  else
    echo -e "${GREEN}✅ No existe: $dir${NC}"
  fi
done

# Paso 6: Eliminar configuración de kubectl de usuario
echo ""
echo -e "${BLUE}[6/10] Eliminando configuración de kubectl...${NC}"
if [ -d "$HOME/.kube" ]; then
  rm -rf "$HOME/.kube"
  echo -e "${GREEN}✅ Eliminado: $HOME/.kube${NC}"
fi

# También eliminar de otros usuarios si existen
for user_home in /home/*; do
  if [ -d "$user_home/.kube" ]; then
    rm -rf "$user_home/.kube"
    echo -e "${GREEN}✅ Eliminado: $user_home/.kube${NC}"
  fi
done

# Paso 7: Limpiar reglas iptables
echo ""
echo -e "${BLUE}[7/10] Limpiando reglas iptables...${NC}"
iptables -F 2>/dev/null || true
iptables -t nat -F 2>/dev/null || true
iptables -t mangle -F 2>/dev/null || true
iptables -X 2>/dev/null || true
echo -e "${GREEN}✅ Reglas iptables limpiadas${NC}"

# Paso 8: Limpiar interfaces de red CNI
echo ""
echo -e "${BLUE}[8/10] Limpiando interfaces de red CNI...${NC}"
# Calico interfaces
for iface in $(ip link show | grep -E 'cali|tunl|vxlan.calico|wireguard.cali' | awk -F: '{print $2}' | tr -d ' '); do
  ip link delete $iface 2>/dev/null || true
  echo -e "${GREEN}✅ Eliminada interfaz: $iface${NC}"
done

# Flannel interface
if ip link show flannel.1 &>/dev/null; then
  ip link delete flannel.1 2>/dev/null || true
  echo -e "${GREEN}✅ Eliminada interfaz: flannel.1${NC}"
fi

# CNI0 bridge
if ip link show cni0 &>/dev/null; then
  ip link delete cni0 2>/dev/null || true
  echo -e "${GREEN}✅ Eliminada interfaz: cni0${NC}"
fi

echo -e "${GREEN}✅ Interfaces CNI limpiadas${NC}"

# Paso 9: Reiniciar servicios
echo ""
echo -e "${BLUE}[9/10] Reiniciando servicios...${NC}"
if systemctl is-active --quiet kubelet 2>/dev/null; then
  systemctl stop kubelet
  echo -e "${GREEN}✅ kubelet detenido${NC}"
fi

if systemctl is-active --quiet containerd 2>/dev/null; then
  systemctl restart containerd
  echo -e "${GREEN}✅ containerd reiniciado${NC}"
fi

# Paso 10: Verificar limpieza
echo ""
echo -e "${BLUE}[10/10] Verificando limpieza...${NC}"

CLEANUP_CHECKS=0

# Verificar directorios eliminados
for dir in "${DIRS_TO_REMOVE[@]}"; do
  if [ -d "$dir" ]; then
    echo -e "${RED}❌ Directorio aún existe: $dir${NC}"
    CLEANUP_CHECKS=$((CLEANUP_CHECKS + 1))
  fi
done

# Verificar puertos liberados
for port in 6443 2379 2380 10250 10259 10257; do
  if command -v netstat &>/dev/null; then
    if netstat -tulpn 2>/dev/null | grep -q ":$port "; then
      echo -e "${YELLOW}⚠️  Puerto $port aún en uso${NC}"
      CLEANUP_CHECKS=$((CLEANUP_CHECKS + 1))
    fi
  fi
done

# Verificar interfaces CNI
if ip link show | grep -qE 'cali|tunl|cni0'; then
  echo -e "${YELLOW}⚠️  Aún existen interfaces CNI${NC}"
  CLEANUP_CHECKS=$((CLEANUP_CHECKS + 1))
fi

if [ $CLEANUP_CHECKS -eq 0 ]; then
  echo -e "${GREEN}✅ Limpieza completada exitosamente${NC}"
else
  echo -e "${YELLOW}⚠️  Limpieza completada con $CLEANUP_CHECKS advertencias${NC}"
  echo "   Algunas interfaces o puertos pueden requerir reboot del sistema"
fi

# Información de estado post-limpieza
echo ""
echo -e "${BLUE}==========================================="
echo "Estado Post-Limpieza"
echo "==========================================="
echo -e "${NC}"

echo "Servicios:"
echo -n "  containerd: "
if systemctl is-active --quiet containerd 2>/dev/null; then
  echo -e "${GREEN}activo${NC}"
else
  echo -e "${RED}inactivo${NC}"
fi

echo -n "  kubelet: "
if systemctl is-active --quiet kubelet 2>/dev/null; then
  echo -e "${YELLOW}activo (inesperado)${NC}"
else
  echo -e "${GREEN}inactivo${NC}"
fi

echo ""
echo "Binarios instalados:"
for cmd in kubeadm kubelet kubectl containerd; do
  echo -n "  $cmd: "
  if command -v $cmd &>/dev/null; then
    echo -e "${GREEN}instalado${NC}"
  else
    echo -e "${YELLOW}no instalado${NC}"
  fi
done

echo ""
echo -e "${GREEN}✅ Limpieza del laboratorio completada${NC}"
echo ""
echo "El sistema está listo para:"
echo "  - Reiniciar el laboratorio con 'kubeadm init'"
echo "  - Desinstalar componentes K8s si lo deseas"
echo "  - Reboot del sistema para limpieza completa"
echo ""
echo "Para desinstalar completamente Kubernetes:"
echo "  sudo apt-get purge -y kubeadm kubectl kubelet kubernetes-cni"
echo "  sudo apt-get autoremove -y"
echo ""
