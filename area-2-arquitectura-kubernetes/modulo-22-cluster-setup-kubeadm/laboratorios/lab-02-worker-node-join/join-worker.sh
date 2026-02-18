#!/bin/bash
# join-worker.sh
# Script para facilitar el join de worker nodes al cluster

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================="
echo "Worker Node Join Script"
echo "==========================================="
echo -e "${NC}"

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${YELLOW}Este script requiere permisos de root${NC}"
  echo "Ejecutando con sudo..."
  exec sudo "$0" "$@"
fi

# Función de ayuda
usage() {
  echo "Uso: $0 <control-plane-ip> [options]"
  echo ""
  echo "Opciones:"
  echo "  -t, --token TOKEN              Bootstrap token"
  echo "  -h, --hash HASH                CA certificate hash"
  echo "  -n, --node-name NAME           Nombre personalizado del nodo"
  echo "  -p, --port PORT                Puerto del API server (default: 6443)"
  echo "  --skip-validation              Saltar validación de prerequisites"
  echo "  --help                         Mostrar esta ayuda"
  echo ""
  echo "Ejemplos:"
  echo "  # Join básico (genera token desde control plane)"
  echo "  $0 192.168.1.100"
  echo ""
  echo "  # Join con token y hash específicos"
  echo "  $0 192.168.1.100 -t abcdef.0123456789abcdef -h sha256:8cb2de..."
  echo ""
  echo "  # Join con nombre de nodo personalizado"
  echo "  $0 192.168.1.100 --node-name worker-prod-01"
  exit 1
}

# Variables
CONTROL_PLANE_IP=""
TOKEN=""
CA_HASH=""
NODE_NAME=$(hostname)
API_PORT="6443"
SKIP_VALIDATION=false

# Parsear argumentos
if [ $# -eq 0 ]; then
  usage
fi

CONTROL_PLANE_IP=$1
shift

while [[ $# -gt 0 ]]; do
  case $1 in
    -t|--token)
      TOKEN="$2"
      shift 2
      ;;
    -h|--hash)
      CA_HASH="$2"
      shift 2
      ;;
    -n|--node-name)
      NODE_NAME="$2"
      shift 2
      ;;
    -p|--port)
      API_PORT="$2"
      shift 2
      ;;
    --skip-validation)
      SKIP_VALIDATION=true
      shift
      ;;
    --help)
      usage
      ;;
    *)
      echo -e "${RED}Opción desconocida: $1${NC}"
      usage
      ;;
  esac
done

echo "Configuración del join:"
echo "  Control Plane: $CONTROL_PLANE_IP:$API_PORT"
echo "  Node Name: $NODE_NAME"
echo ""

# Paso 1: Validación de prerequisites
if [ "$SKIP_VALIDATION" = false ]; then
  echo -e "${BLUE}[1/6] Validando prerequisites...${NC}"
  
  # Verificar swap
  if free | grep -q "Swap.*[1-9]"; then
    echo -e "${RED}❌ Swap está habilitado${NC}"
    echo "   Deshabilita con: sudo swapoff -a"
    exit 1
  fi
  echo -e "${GREEN}✅ Swap deshabilitado${NC}"
  
  # Verificar containerd
  if ! systemctl is-active --quiet containerd; then
    echo -e "${RED}❌ containerd no está corriendo${NC}"
    exit 1
  fi
  echo -e "${GREEN}✅ containerd activo${NC}"
  
  # Verificar kubeadm
  if ! command -v kubeadm &>/dev/null; then
    echo -e "${RED}❌ kubeadm no instalado${NC}"
    exit 1
  fi
  echo -e "${GREEN}✅ kubeadm instalado${NC}"
  
  # Verificar conectividad al control plane
  if ! ping -c 2 -W 3 "$CONTROL_PLANE_IP" &>/dev/null; then
    echo -e "${RED}❌ No se puede hacer ping al control plane${NC}"
    exit 1
  fi
  echo -e "${GREEN}✅ Conectividad al control plane${NC}"
  
  # Verificar puerto 6443
  if ! nc -zv "$CONTROL_PLANE_IP" "$API_PORT" &>/dev/null 2>&1 && \
     ! timeout 3 bash -c "cat < /dev/null > /dev/tcp/$CONTROL_PLANE_IP/$API_PORT" &>/dev/null 2>&1; then
    echo -e "${RED}❌ No se puede conectar al puerto $API_PORT${NC}"
    exit 1
  fi
  echo -e "${GREEN}✅ Puerto $API_PORT accesible${NC}"
  
  # Verificar que no haya instalación previa
  if [ -f /etc/kubernetes/kubelet.conf ]; then
    echo -e "${YELLOW}⚠️  Detectada instalación previa de Kubernetes${NC}"
    read -p "¿Deseas hacer kubeadm reset primero? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Ejecutando kubeadm reset..."
      kubeadm reset -f
      rm -rf /etc/kubernetes
      rm -rf /var/lib/kubelet
    else
      echo -e "${RED}Cancelado. Ejecuta 'sudo kubeadm reset -f' manualmente${NC}"
      exit 1
    fi
  fi
  
  echo -e "${GREEN}✅ Prerequisites validados${NC}"
else
  echo -e "${YELLOW}⚠️  Saltando validación de prerequisites${NC}"
fi

# Paso 2: Obtener token y hash si no se proporcionaron
if [ -z "$TOKEN" ] || [ -z "$CA_HASH" ]; then
  echo ""
  echo -e "${BLUE}[2/6] Obteniendo token y CA hash...${NC}"
  echo -e "${YELLOW}Necesitas ejecutar el siguiente comando en el CONTROL PLANE:${NC}"
  echo ""
  echo -e "${GREEN}  kubeadm token create --print-join-command${NC}"
  echo ""
  echo "Luego ingresa los datos aquí:"
  echo ""
  
  if [ -z "$TOKEN" ]; then
    read -p "Bootstrap token (formato: xxxxxx.xxxxxxxxxxxxxxxx): " TOKEN
  fi
  
  if [ -z "$CA_HASH" ]; then
    read -p "CA cert hash (formato: sha256:xxxxx...): " CA_HASH
  fi
  
  # Validar formato de token
  if ! echo "$TOKEN" | grep -qE '^[a-z0-9]{6}\.[a-z0-9]{16}$'; then
    echo -e "${RED}❌ Formato de token inválido${NC}"
    echo "   Debe ser: 6 caracteres . 16 caracteres (a-z0-9)"
    exit 1
  fi
  
  # Validar formato de hash
  if ! echo "$CA_HASH" | grep -qE '^sha256:[a-f0-9]{64}$'; then
    echo -e "${RED}❌ Formato de hash inválido${NC}"
    echo "   Debe ser: sha256: seguido de 64 caracteres hexadecimales"
    exit 1
  fi
  
  echo -e "${GREEN}✅ Token y hash validados${NC}"
fi

# Paso 3: Crear kubeadm config (opcional)
echo ""
echo -e "${BLUE}[3/6] Preparando configuración...${NC}"

# Si el nombre del nodo es diferente al hostname, crear config
if [ "$NODE_NAME" != "$(hostname)" ]; then
  cat > /tmp/kubeadm-join-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: "${CONTROL_PLANE_IP}:${API_PORT}"
    token: "${TOKEN}"
    caCertHashes:
    - "${CA_HASH}"
nodeRegistration:
  name: "${NODE_NAME}"
  criSocket: unix:///var/run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
EOF
  
  echo -e "${GREEN}✅ Archivo de configuración creado${NC}"
  CONFIG_FILE="/tmp/kubeadm-join-config.yaml"
else
  CONFIG_FILE=""
fi

# Paso 4: Ejecutar kubeadm join
echo ""
echo -e "${BLUE}[4/6] Ejecutando kubeadm join...${NC}"
echo ""

if [ -n "$CONFIG_FILE" ]; then
  # Join con config file
  kubeadm join --config "$CONFIG_FILE"
else
  # Join directo
  kubeadm join "${CONTROL_PLANE_IP}:${API_PORT}" \
    --token "$TOKEN" \
    --discovery-token-ca-cert-hash "$CA_HASH"
fi

JOIN_EXIT_CODE=$?

if [ $JOIN_EXIT_CODE -ne 0 ]; then
  echo ""
  echo -e "${RED}❌ kubeadm join falló (exit code: $JOIN_EXIT_CODE)${NC}"
  echo ""
  echo "Troubleshooting:"
  echo "  - Verifica que el token no haya expirado"
  echo "  - Verifica que el CA hash sea correcto"
  echo "  - Revisa logs: sudo journalctl -u kubelet -f"
  echo "  - Intenta reset: sudo kubeadm reset -f"
  exit $JOIN_EXIT_CODE
fi

echo ""
echo -e "${GREEN}✅ kubeadm join completado exitosamente${NC}"

# Paso 5: Verificar kubelet
echo ""
echo -e "${BLUE}[5/6] Verificando kubelet...${NC}"
sleep 3

if systemctl is-active --quiet kubelet; then
  echo -e "${GREEN}✅ kubelet está corriendo${NC}"
else
  echo -e "${YELLOW}⚠️  kubelet no está activo, verificando...${NC}"
  systemctl status kubelet --no-pager | tail -10
fi

# Paso 6: Instrucciones post-join
echo ""
echo -e "${BLUE}[6/6] Verificación final${NC}"
echo ""
echo -e "${GREEN}✅ Worker node join completado${NC}"
echo ""
echo "Próximos pasos:"
echo ""
echo "1. En el CONTROL PLANE, verifica que el nodo aparezca:"
echo -e "   ${GREEN}kubectl get nodes${NC}"
echo ""
echo "2. Espera a que el nodo esté en estado Ready (puede tomar 1-2 min):"
echo -e "   ${GREEN}kubectl get nodes -w${NC}"
echo ""
echo "3. Verifica pods del sistema en este nodo:"
echo -e "   ${GREEN}kubectl get pods -A -o wide --field-selector spec.nodeName=$NODE_NAME${NC}"
echo ""
echo "4. Para verificar desde este worker node:"
echo "   - Ver logs de kubelet:"
echo -e "     ${GREEN}sudo journalctl -u kubelet -f${NC}"
echo "   - Ver pods del sistema (requiere kubectl y kubeconfig):"
echo -e "     ${GREEN}sudo crictl pods${NC}"
echo ""

# Limpiar archivo temporal si existe
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
  rm -f "$CONFIG_FILE"
fi

echo -e "${BLUE}==========================================="
echo "Join completado exitosamente"
echo "==========================================="
echo -e "${NC}"
