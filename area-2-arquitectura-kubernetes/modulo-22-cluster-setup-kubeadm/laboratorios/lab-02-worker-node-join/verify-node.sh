#!/bin/bash
# verify-node.sh
# Script de verificación del worker node después del join

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
NODE_NAME="${1:-$(hostname)}"

echo -e "${BLUE}==========================================="
echo "Verificación de Worker Node"
echo "Node: $NODE_NAME"
echo "==========================================="
echo -e "${NC}"

# Verificar si tenemos acceso a kubectl
if ! command -v kubectl &>/dev/null; then
  echo -e "${YELLOW}⚠️  kubectl no está instalado en este nodo${NC}"
  echo "   Este script debe ejecutarse desde el control plane"
  echo "   o configurar kubeconfig en el worker"
  echo ""
  echo "Desde control plane:"
  echo "  kubectl get nodes"
  echo "  ./verify-node.sh worker-01"
  exit 1
fi

# Verificar acceso al cluster
if ! kubectl cluster-info &>/dev/null; then
  echo -e "${RED}❌ No se puede conectar al cluster${NC}"
  echo "   Verifica KUBECONFIG o copia admin.conf"
  exit 1
fi

# 1. Verificar que el nodo existe
echo -e "${BLUE}[1/10] Verificando existencia del nodo...${NC}"
if kubectl get node "$NODE_NAME" &>/dev/null; then
  echo -e "${GREEN}✅ Nodo '$NODE_NAME' encontrado en el cluster${NC}"
else
  echo -e "${RED}❌ Nodo '$NODE_NAME' NO encontrado${NC}"
  echo ""
  echo "Nodos disponibles:"
  kubectl get nodes
  ERRORS=$((ERRORS + 1))
  exit 1
fi

# 2. Verificar estado del nodo
echo ""
echo -e "${BLUE}[2/10] Verificando estado del nodo...${NC}"
NODE_STATUS=$(kubectl get node "$NODE_NAME" --no-headers | awk '{print $2}')

if [ "$NODE_STATUS" = "Ready" ]; then
  echo -e "${GREEN}✅ Nodo en estado: Ready${NC}"
elif [ "$NODE_STATUS" = "NotReady" ]; then
  echo -e "${RED}❌ Nodo en estado: NotReady${NC}"
  echo "   El nodo no está listo. Verifica:"
  echo "   - CNI plugin instalado"
  echo "   - kubelet corriendo"
  echo "   - Logs: kubectl describe node $NODE_NAME"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${YELLOW}⚠️  Nodo en estado: $NODE_STATUS${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# 3. Verificar roles y labels
echo ""
echo -e "${BLUE}[3/10] Verificando roles y labels...${NC}"
ROLES=$(kubectl get node "$NODE_NAME" --no-headers | awk '{print $3}')

if [ "$ROLES" = "<none>" ] || [ -z "$ROLES" ]; then
  echo -e "${GREEN}✅ Nodo es worker (sin rol control-plane)${NC}"
else
  echo -e "${YELLOW}⚠️  Nodo tiene roles: $ROLES${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# Mostrar labels importantes
echo "Labels del nodo:"
kubectl get node "$NODE_NAME" -o jsonpath='{.metadata.labels}' | \
  jq -r 'to_entries[] | select(.key | startswith("node-role") or startswith("beta.kubernetes.io")) | "  \(.key)=\(.value)"' 2>/dev/null || \
  kubectl get node "$NODE_NAME" --show-labels | grep -o 'node-role[^,]*'

# 4. Verificar condiciones del nodo
echo ""
echo -e "${BLUE}[4/10] Verificando condiciones del nodo...${NC}"

CONDITIONS=("Ready" "MemoryPressure" "DiskPressure" "PIDPressure" "NetworkUnavailable")

for condition in "${CONDITIONS[@]}"; do
  STATUS=$(kubectl get node "$NODE_NAME" -o jsonpath="{.status.conditions[?(@.type=='$condition')].status}" 2>/dev/null)
  
  if [ "$condition" = "Ready" ]; then
    # Ready debe ser True
    if [ "$STATUS" = "True" ]; then
      echo -e "${GREEN}✅ $condition: $STATUS${NC}"
    else
      echo -e "${RED}❌ $condition: $STATUS${NC}"
      ERRORS=$((ERRORS + 1))
    fi
  else
    # Otras condiciones deben ser False
    if [ "$STATUS" = "False" ] || [ -z "$STATUS" ]; then
      echo -e "${GREEN}✅ $condition: ${STATUS:-False}${NC}"
    else
      echo -e "${YELLOW}⚠️  $condition: $STATUS${NC}"
      WARNINGS=$((WARNINGS + 1))
    fi
  fi
done

# 5. Verificar capacidad y recursos
echo ""
echo -e "${BLUE}[5/10] Verificando recursos del nodo...${NC}"

CPU_CAPACITY=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.capacity.cpu}')
MEM_CAPACITY=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.capacity.memory}')
CPU_ALLOCATABLE=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.allocatable.cpu}')
MEM_ALLOCATABLE=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.allocatable.memory}')

echo "Capacidad:"
echo "  CPU: $CPU_CAPACITY (Allocatable: $CPU_ALLOCATABLE)"
echo "  Memory: $MEM_CAPACITY (Allocatable: $MEM_ALLOCATABLE)"

# 6. Verificar pods del sistema en el nodo
echo ""
echo -e "${BLUE}[6/10] Verificando pods del sistema...${NC}"

# kube-proxy
KUBE_PROXY=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy \
  --field-selector spec.nodeName="$NODE_NAME" --no-headers 2>/dev/null | grep Running | wc -l)

if [ "$KUBE_PROXY" -eq 1 ]; then
  echo -e "${GREEN}✅ kube-proxy pod Running${NC}"
else
  echo -e "${RED}❌ kube-proxy pod no encontrado o no Running${NC}"
  ERRORS=$((ERRORS + 1))
fi

# CNI plugin (Calico)
CALICO_NODE=$(kubectl get pods -n kube-system -l k8s-app=calico-node \
  --field-selector spec.nodeName="$NODE_NAME" --no-headers 2>/dev/null | grep Running | wc -l)

if [ "$CALICO_NODE" -eq 1 ]; then
  echo -e "${GREEN}✅ calico-node pod Running${NC}"
else
  echo -e "${YELLOW}⚠️  calico-node pod no encontrado o no Running${NC}"
  echo "   Verifica que Calico esté instalado en el cluster"
  WARNINGS=$((WARNINGS + 1))
fi

# Listar todos los pods del sistema en este nodo
echo ""
echo "Todos los pods del sistema en $NODE_NAME:"
kubectl get pods -n kube-system --field-selector spec.nodeName="$NODE_NAME" \
  -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.conditions[?\(@.type==\"Ready\"\)].status

# 7. Verificar versiones
echo ""
echo -e "${BLUE}[7/10] Verificando versiones de componentes...${NC}"

KUBELET_VERSION=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.nodeInfo.kubeletVersion}')
CONTAINER_RUNTIME=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.nodeInfo.containerRuntimeVersion}')
OS_IMAGE=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.nodeInfo.osImage}')
KERNEL=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.nodeInfo.kernelVersion}')

echo "Versiones:"
echo "  Kubelet: $KUBELET_VERSION"
echo "  Container Runtime: $CONTAINER_RUNTIME"
echo "  OS: $OS_IMAGE"
echo "  Kernel: $KERNEL"

# 8. Test de networking (crear pod de prueba)
echo ""
echo -e "${BLUE}[8/10] Probando networking del nodo...${NC}"

# Crear pod de prueba en este nodo específico
TEST_POD="verify-node-test-$RANDOM"

kubectl run "$TEST_POD" --image=nginx:alpine --restart=Never \
  --overrides="{\"spec\":{\"nodeName\":\"$NODE_NAME\"}}" &>/dev/null

# Esperar a que esté Running (max 60s)
echo -n "Esperando que pod de prueba esté Running..."
for i in {1..12}; do
  POD_STATUS=$(kubectl get pod "$TEST_POD" --no-headers 2>/dev/null | awk '{print $3}')
  if [ "$POD_STATUS" = "Running" ]; then
    echo -e " ${GREEN}OK${NC}"
    echo -e "${GREEN}✅ Pod de prueba creado y Running${NC}"
    
    # Obtener IP del pod
    POD_IP=$(kubectl get pod "$TEST_POD" -o jsonpath='{.status.podIP}')
    echo "  Pod IP: $POD_IP"
    
    # Test DNS
    if kubectl exec "$TEST_POD" -- nslookup kubernetes.default &>/dev/null; then
      echo -e "${GREEN}✅ DNS funcionando dentro del pod${NC}"
    else
      echo -e "${YELLOW}⚠️  DNS no funciona dentro del pod${NC}"
      WARNINGS=$((WARNINGS + 1))
    fi
    
    break
  elif [ "$i" -eq 12 ]; then
    echo -e " ${YELLOW}TIMEOUT${NC}"
    echo -e "${YELLOW}⚠️  Pod no alcanzó Running (estado: $POD_STATUS)${NC}"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -n "."
    sleep 5
  fi
done

# Limpiar pod de prueba
kubectl delete pod "$TEST_POD" --timeout=30s &>/dev/null || true

# 9. Verificar taints
echo ""
echo -e "${BLUE}[9/10] Verificando taints del nodo...${NC}"

TAINTS=$(kubectl get node "$NODE_NAME" -o jsonpath='{.spec.taints}')

if [ -z "$TAINTS" ] || [ "$TAINTS" = "null" ]; then
  echo -e "${GREEN}✅ No hay taints (nodo acepta cualquier pod)${NC}"
else
  echo -e "${YELLOW}⚠️  Nodo tiene taints:${NC}"
  kubectl get node "$NODE_NAME" -o jsonpath='{.spec.taints}' | jq '.' 2>/dev/null || echo "$TAINTS"
  WARNINGS=$((WARNINGS + 1))
fi

# 10. Verificar eventos recientes del nodo
echo ""
echo -e "${BLUE}[10/10] Verificando eventos recientes...${NC}"

EVENTS=$(kubectl get events --field-selector involvedObject.name="$NODE_NAME" \
  --sort-by='.lastTimestamp' 2>/dev/null | tail -5)

if [ -n "$EVENTS" ]; then
  echo "Últimos 5 eventos:"
  kubectl get events --field-selector involvedObject.name="$NODE_NAME" \
    --sort-by='.lastTimestamp' | tail -5
else
  echo -e "${GREEN}✅ No hay eventos recientes${NC}"
fi

# Resumen final
echo ""
echo -e "${BLUE}==========================================="
echo "Resumen de Verificación"
echo "==========================================="
echo -e "${NC}"

echo "Nodo: $NODE_NAME"
echo "Estado: $NODE_STATUS"
echo -e "Errores: ${RED}$ERRORS${NC}"
echo -e "Advertencias: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✅ WORKER NODE COMPLETAMENTE FUNCIONAL${NC}"
  echo ""
  echo "El worker node está listo para ejecutar workloads."
  EXIT_CODE=0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠️  WORKER NODE FUNCIONAL CON ADVERTENCIAS${NC}"
  echo ""
  echo "El nodo está operativo pero revisa las advertencias."
  EXIT_CODE=1
else
  echo -e "${RED}❌ WORKER NODE CON PROBLEMAS${NC}"
  echo ""
  echo "Hay errores que deben resolverse."
  echo ""
  echo "Comandos útiles:"
  echo "  kubectl describe node $NODE_NAME"
  echo "  kubectl get pods -A -o wide --field-selector spec.nodeName=$NODE_NAME"
  echo "  kubectl logs -n kube-system <pod-name>"
  EXIT_CODE=2
fi

echo ""
exit $EXIT_CODE
