#!/bin/bash
# cleanup.sh
# Script para remover worker node del cluster

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NODE_NAME="${1:-$(hostname)}"
RUN_ON_CONTROL_PLANE=false
RUN_ON_WORKER=false

echo -e "${BLUE}==========================================="
echo "Cleanup - Worker Node Removal"
echo "Node: $NODE_NAME"
echo "==========================================="
echo -e "${NC}"

# Determinar dónde se ejecuta el script
if [ -f /etc/kubernetes/admin.conf ]; then
  RUN_ON_CONTROL_PLANE=true
  echo "Ejecutando en: Control Plane"
elif [ -f /etc/kubernetes/kubelet.conf ]; then
  RUN_ON_WORKER=true
  echo "Ejecutando en: Worker Node"
else
  echo -e "${YELLOW}No se detectó ni control plane ni worker node${NC}"
  echo "Este script debe ejecutarse en:"
  echo "  - Control plane (para drenar y eliminar nodo)"
  echo "  - Worker node (para hacer reset local)"
fi

echo ""
echo -e "${YELLOW}⚠️  ADVERTENCIA: Este script removerá el worker node del cluster${NC}"
echo ""
echo "Acciones que se realizarán:"

if [ "$RUN_ON_CONTROL_PLANE" = true ]; then
  echo "  - Drenar el nodo $NODE_NAME (mover pods a otros nodos)"
  echo "  - Eliminar el nodo del cluster"
fi

if [ "$RUN_ON_WORKER" = true ]; then
  echo "  - Ejecutar kubeadm reset en el worker node"
  echo "  - Eliminar configuraciones de Kubernetes"
  echo "  - Limpiar directorios y archivos"
fi

echo ""
read -p "¿Deseas continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${GREEN}Operación cancelada${NC}"
  exit 0
fi

# Parte 1: Operaciones en Control Plane
if [ "$RUN_ON_CONTROL_PLANE" = true ]; then
  echo ""
  echo -e "${BLUE}Operaciones en Control Plane${NC}"
  echo ""
  
  # Verificar que kubectl funciona
  if ! command -v kubectl &>/dev/null; then
    echo -e "${RED}❌ kubectl no disponible${NC}"
    exit 1
  fi
  
  # Verificar que el nodo existe
  echo -e "${BLUE}[1/3] Verificando nodo...${NC}"
  if ! kubectl get node "$NODE_NAME" &>/dev/null; then
    echo -e "${YELLOW}⚠️  Nodo $NODE_NAME no encontrado en el cluster${NC}"
    echo "   Ya fue eliminado o el nombre es incorrecto"
  else
    echo -e "${GREEN}✅ Nodo $NODE_NAME encontrado${NC}"
    
    # Drenar el nodo
    echo ""
    echo -e "${BLUE}[2/3] Drenando nodo $NODE_NAME...${NC}"
    kubectl drain "$NODE_NAME" \
      --ignore-daemonsets \
      --delete-emptydir-data \
      --force \
      --timeout=60s 2>&1 | while read line; do
        echo "  $line"
      done || true
    
    echo -e "${GREEN}✅ Nodo drenado${NC}"
    
    # Eliminar el nodo
    echo ""
    echo -e "${BLUE}[3/3] Eliminando nodo del cluster...${NC}"
    kubectl delete node "$NODE_NAME" --timeout=30s
    
    echo -e "${GREEN}✅ Nodo eliminado del cluster${NC}"
    
    echo ""
    echo "Nodos restantes en el cluster:"
    kubectl get nodes
  fi
  
  echo ""
  echo -e "${GREEN}✅ Operaciones en control plane completadas${NC}"
  echo ""
  echo "Ahora debes ejecutar este script EN EL WORKER NODE para limpiar:"
  echo "  ssh $NODE_NAME"
  echo "  sudo ./cleanup.sh"
fi

# Parte 2: Operaciones en Worker Node
if [ "$RUN_ON_WORKER" = true ]; then
  echo ""
  echo -e "${BLUE}Operaciones en Worker Node${NC}"
  echo ""
  
  # Verificar permisos
  if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}Este script requiere permisos de root${NC}"
    echo "Ejecutando con sudo..."
    exec sudo "$0" "$@"
  fi
  
  # Detener kubelet
  echo -e "${BLUE}[1/6] Deteniendo kubelet...${NC}"
  if systemctl is-active --quiet kubelet; then
    systemctl stop kubelet
    echo -e "${GREEN}✅ kubelet detenido${NC}"
  else
    echo -e "${GREEN}✅ kubelet ya estaba detenido${NC}"
  fi
  
  # Ejecutar kubeadm reset
  echo ""
  echo -e "${BLUE}[2/6] Ejecutando kubeadm reset...${NC}"
  if command -v kubeadm &>/dev/null; then
    kubeadm reset -f 2>&1 | while read line; do
      echo "  $line"
    done
    echo -e "${GREEN}✅ kubeadm reset completado${NC}"
  else
    echo -e "${YELLOW}⚠️  kubeadm no disponible (skip)${NC}"
  fi
  
  # Eliminar directorios de Kubernetes
  echo ""
  echo -e "${BLUE}[3/6] Eliminando directorios de Kubernetes...${NC}"
  DIRS_TO_REMOVE=(
    "/etc/kubernetes"
    "/var/lib/kubelet"
    "/var/lib/cni"
    "/etc/cni"
  )
  
  for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [ -d "$dir" ]; then
      rm -rf "$dir"
      echo -e "${GREEN}✅ Eliminado: $dir${NC}"
    else
      echo -e "${GREEN}✅ No existe: $dir${NC}"
    fi
  done
  
  # Limpiar reglas iptables
  echo ""
  echo -e "${BLUE}[4/6] Limpiando reglas iptables...${NC}"
  iptables -F 2>/dev/null || true
  iptables -t nat -F 2>/dev/null || true
  iptables -t mangle -F 2>/dev/null || true
  iptables -X 2>/dev/null || true
  echo -e "${GREEN}✅ Reglas iptables limpiadas${NC}"
  
  # Limpiar interfaces CNI
  echo ""
  echo -e "${BLUE}[5/6] Limpiando interfaces de red CNI...${NC}"
  
  # Calico interfaces
  for iface in $(ip link show | grep -E 'cali|tunl|vxlan.calico' | awk -F: '{print $2}' | tr -d ' ' 2>/dev/null); do
    ip link delete "$iface" 2>/dev/null || true
    echo -e "${GREEN}✅ Eliminada interfaz: $iface${NC}"
  done
  
  # CNI0 bridge
  if ip link show cni0 &>/dev/null; then
    ip link delete cni0 2>/dev/null || true
    echo -e "${GREEN}✅ Eliminada interfaz: cni0${NC}"
  fi
  
  echo -e "${GREEN}✅ Interfaces CNI limpiadas${NC}"
  
  # Reiniciar servicios
  echo ""
  echo -e "${BLUE}[6/6] Reiniciando servicios...${NC}"
  
  if systemctl is-active --quiet containerd; then
    systemctl restart containerd
    echo -e "${GREEN}✅ containerd reiniciado${NC}"
  fi
  
  echo ""
  echo -e "${GREEN}✅ Operaciones en worker node completadas${NC}"
fi

# Resumen final
echo ""
echo -e "${BLUE}==========================================="
echo "Resumen de Limpieza"
echo "==========================================="
echo -e "${NC}"

if [ "$RUN_ON_CONTROL_PLANE" = true ]; then
  echo "✅ Nodo drenado y eliminado del cluster"
  echo ""
  echo "Recuerda ejecutar cleanup en el worker node:"
  echo "  ssh $NODE_NAME 'sudo ./cleanup.sh'"
fi

if [ "$RUN_ON_WORKER" = true ]; then
  echo "✅ Worker node limpiado localmente"
  echo ""
  echo "El nodo está listo para:"
  echo "  - Unirse nuevamente al cluster (kubeadm join)"
  echo "  - Ser apagado/eliminado"
  echo "  - Unirse a un cluster diferente"
  echo ""
  echo "Para re-join al cluster:"
  echo "  1. En control plane: kubeadm token create --print-join-command"
  echo "  2. En worker: Ejecutar el join command"
fi

echo ""
echo -e "${GREEN}✅ Cleanup completado${NC}"
echo ""
