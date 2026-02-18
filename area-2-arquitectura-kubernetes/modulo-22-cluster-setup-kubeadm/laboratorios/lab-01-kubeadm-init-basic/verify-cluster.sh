#!/bin/bash
# verify-cluster.sh
# Script de verificación completa del cluster post-kubeadm init

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
CHECKS=0

echo -e "${BLUE}==========================================="
echo "Verificación del Cluster - Lab 01"
echo "kubeadm init - Cluster Básico"
echo "==========================================="
echo -e "${NC}"

# Función helper para verificaciones
check() {
  CHECKS=$((CHECKS + 1))
  if eval "$1" &>/dev/null; then
    echo -e "${GREEN}✅ $2${NC}"
    return 0
  else
    echo -e "${RED}❌ $2${NC}"
    ERRORS=$((ERRORS + 1))
    return 1
  fi
}

warn() {
  CHECKS=$((CHECKS + 1))
  if eval "$1" &>/dev/null; then
    echo -e "${GREEN}✅ $2${NC}"
    return 0
  else
    echo -e "${YELLOW}⚠️  $2${NC}"
    WARNINGS=$((WARNINGS + 1))
    return 1
  fi
}

# 1. Verificar acceso a kubectl
echo -e "${BLUE}[1/12] Verificando kubectl...${NC}"
check "kubectl version --client &>/dev/null" "kubectl instalado y funcionando"

if kubectl cluster-info &>/dev/null; then
  echo -e "${GREEN}✅ kubectl puede conectar al cluster${NC}"
  kubectl cluster-info | head -3
else
  echo -e "${RED}❌ kubectl NO puede conectar al cluster${NC}"
  echo "   Verifica:"
  echo "   - export KUBECONFIG=/etc/kubernetes/admin.conf"
  echo "   - o copia admin.conf a ~/.kube/config"
  ERRORS=$((ERRORS + 1))
fi

# 2. Verificar nodos
echo ""
echo -e "${BLUE}[2/12] Verificando nodos del cluster...${NC}"
if check "kubectl get nodes &>/dev/null" "Comando 'kubectl get nodes' funciona"; then
  NODE_STATUS=$(kubectl get nodes --no-headers | awk '{print $2}')
  NODE_NAME=$(kubectl get nodes --no-headers | awk '{print $1}')
  
  if [ "$NODE_STATUS" = "Ready" ]; then
    echo -e "${GREEN}✅ Nodo '$NODE_NAME' en estado Ready${NC}"
  else
    echo -e "${RED}❌ Nodo '$NODE_NAME' en estado: $NODE_STATUS${NC}"
    ERRORS=$((ERRORS + 1))
  fi
  
  # Mostrar detalles del nodo
  echo ""
  kubectl get nodes -o wide
fi

# 3. Verificar componentes del control plane
echo ""
echo -e "${BLUE}[3/12] Verificando componentes del control plane...${NC}"

CONTROL_PLANE_PODS=(
  "kube-apiserver"
  "kube-controller-manager"
  "kube-scheduler"
  "etcd"
)

for component in "${CONTROL_PLANE_PODS[@]}"; do
  POD_STATUS=$(kubectl get pods -n kube-system -l component=$component --no-headers 2>/dev/null | awk '{print $3}' | head -1)
  
  if [ -z "$POD_STATUS" ]; then
    # Intentar con nombre del pod directamente
    POD_STATUS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep "^$component-" | awk '{print $3}' | head -1)
  fi
  
  if [ "$POD_STATUS" = "Running" ]; then
    echo -e "${GREEN}✅ $component: Running${NC}"
  elif [ -z "$POD_STATUS" ]; then
    echo -e "${RED}❌ $component: No encontrado${NC}"
    ERRORS=$((ERRORS + 1))
  else
    echo -e "${RED}❌ $component: $POD_STATUS${NC}"
    ERRORS=$((ERRORS + 1))
  fi
done

# 4. Verificar CoreDNS
echo ""
echo -e "${BLUE}[4/12] Verificando CoreDNS...${NC}"
COREDNS_REPLICAS=$(kubectl get deployment -n kube-system coredns -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
COREDNS_DESIRED=$(kubectl get deployment -n kube-system coredns -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

if [ "$COREDNS_REPLICAS" = "$COREDNS_DESIRED" ] && [ "$COREDNS_REPLICAS" != "0" ]; then
  echo -e "${GREEN}✅ CoreDNS: $COREDNS_REPLICAS/$COREDNS_DESIRED replicas listas${NC}"
else
  echo -e "${RED}❌ CoreDNS: $COREDNS_REPLICAS/$COREDNS_DESIRED replicas listas${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 5. Verificar kube-proxy
echo ""
echo -e "${BLUE}[5/12] Verificando kube-proxy...${NC}"
KUBE_PROXY_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers 2>/dev/null | grep Running | wc -l)
TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)

if [ "$KUBE_PROXY_PODS" -eq "$TOTAL_NODES" ]; then
  echo -e "${GREEN}✅ kube-proxy: $KUBE_PROXY_PODS/$TOTAL_NODES pods Running${NC}"
else
  echo -e "${YELLOW}⚠️  kube-proxy: $KUBE_PROXY_PODS/$TOTAL_NODES pods Running${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# 6. Verificar CNI plugin (Calico)
echo ""
echo -e "${BLUE}[6/12] Verificando CNI plugin (Calico)...${NC}"
CALICO_NODES=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep Running | wc -l)
CALICO_CONTROLLER=$(kubectl get deployment -n kube-system calico-kube-controllers -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

if [ "$CALICO_NODES" -eq "$TOTAL_NODES" ]; then
  echo -e "${GREEN}✅ calico-node: $CALICO_NODES/$TOTAL_NODES pods Running${NC}"
else
  echo -e "${RED}❌ calico-node: $CALICO_NODES/$TOTAL_NODES pods Running${NC}"
  ERRORS=$((ERRORS + 1))
fi

if [ "$CALICO_CONTROLLER" = "1" ]; then
  echo -e "${GREEN}✅ calico-kube-controllers: 1/1 replica lista${NC}"
else
  echo -e "${RED}❌ calico-kube-controllers: $CALICO_CONTROLLER/1 replica lista${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 7. Verificar API server health
echo ""
echo -e "${BLUE}[7/12] Verificando API server health endpoints...${NC}"
check "kubectl get --raw /healthz" "API server /healthz"
check "kubectl get --raw /readyz" "API server /readyz"
check "kubectl get --raw /livez" "API server /livez"

# 8. Verificar etcd
echo ""
echo -e "${BLUE}[8/12] Verificando etcd...${NC}"
if command -v etcdctl &>/dev/null; then
  if sudo ETCDCTL_API=3 etcdctl \
    --endpoints=127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    endpoint health &>/dev/null; then
    echo -e "${GREEN}✅ etcd health check passed${NC}"
  else
    echo -e "${RED}❌ etcd health check failed${NC}"
    ERRORS=$((ERRORS + 1))
  fi
  
  # Verificar miembros de etcd
  ETCD_MEMBERS=$(sudo ETCDCTL_API=3 etcdctl \
    --endpoints=127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    member list 2>/dev/null | wc -l)
  
  echo -e "${GREEN}✅ etcd tiene $ETCD_MEMBERS miembro(s)${NC}"
else
  echo -e "${YELLOW}⚠️  etcdctl no instalado (skip detallado)${NC}"
  WARNINGS=$((WARNINGS + 1))
  
  # Verificar solo que el pod esté corriendo
  warn "kubectl get pods -n kube-system | grep etcd | grep Running" "etcd pod Running"
fi

# 9. Verificar certificados
echo ""
echo -e "${BLUE}[9/12] Verificando certificados...${NC}"
if command -v kubeadm &>/dev/null; then
  echo "Certificados y su expiración:"
  sudo kubeadm certs check-expiration 2>/dev/null | grep -E 'CERTIFICATE|admin|apiserver' | head -5
  
  # Verificar que no expiren pronto
  EXPIRING_CERTS=$(sudo kubeadm certs check-expiration 2>/dev/null | grep -c "EXPIRED" || echo "0")
  if [ "$EXPIRING_CERTS" -eq 0 ]; then
    echo -e "${GREEN}✅ No hay certificados expirados${NC}"
  else
    echo -e "${RED}❌ Hay $EXPIRING_CERTS certificados expirados${NC}"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo -e "${YELLOW}⚠️  kubeadm no disponible (skip)${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# 10. Verificar namespaces del sistema
echo ""
echo -e "${BLUE}[10/12] Verificando namespaces del sistema...${NC}"
REQUIRED_NAMESPACES=("default" "kube-system" "kube-public" "kube-node-lease")

for ns in "${REQUIRED_NAMESPACES[@]}"; do
  check "kubectl get namespace $ns" "Namespace '$ns' existe"
done

# 11. Verificar funcionalidad básica
echo ""
echo -e "${BLUE}[11/12] Verificando funcionalidad básica del cluster...${NC}"

# Test 1: Crear namespace de prueba
if kubectl create namespace verify-test &>/dev/null; then
  echo -e "${GREEN}✅ Puede crear namespaces${NC}"
  
  # Test 2: Crear pod de prueba
  if kubectl run test-pod --image=nginx:alpine -n verify-test --restart=Never &>/dev/null; then
    echo -e "${GREEN}✅ Puede crear pods${NC}"
    
    # Esperar a que el pod esté Running (timeout 60s)
    for i in {1..12}; do
      POD_STATUS=$(kubectl get pod test-pod -n verify-test --no-headers 2>/dev/null | awk '{print $3}')
      if [ "$POD_STATUS" = "Running" ]; then
        echo -e "${GREEN}✅ Pod alcanzó estado Running${NC}"
        break
      elif [ "$i" -eq 12 ]; then
        echo -e "${YELLOW}⚠️  Pod no alcanzó estado Running (timeout)${NC}"
        echo "   Estado actual: $POD_STATUS"
        WARNINGS=$((WARNINGS + 1))
      else
        sleep 5
      fi
    done
    
    # Test 3: Crear service
    if kubectl expose pod test-pod --port=80 -n verify-test &>/dev/null; then
      echo -e "${GREEN}✅ Puede crear services${NC}"
    else
      echo -e "${YELLOW}⚠️  No pudo crear service${NC}"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo -e "${RED}❌ No pudo crear pod${NC}"
    ERRORS=$((ERRORS + 1))
  fi
  
  # Limpiar namespace de prueba
  kubectl delete namespace verify-test --timeout=30s &>/dev/null || true
else
  echo -e "${RED}❌ No pudo crear namespace${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 12. Verificar logs de componentes (últimas líneas)
echo ""
echo -e "${BLUE}[12/12] Verificando logs de componentes críticos...${NC}"

# API server logs
if kubectl logs -n kube-system $(kubectl get pods -n kube-system -l component=kube-apiserver --no-headers | awk '{print $1}' | head -1) --tail=5 &>/dev/null; then
  echo -e "${GREEN}✅ Logs de kube-apiserver accesibles${NC}"
else
  echo -e "${YELLOW}⚠️  No se pueden leer logs de kube-apiserver${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# Kubelet logs
if sudo journalctl -u kubelet --no-pager -n 5 &>/dev/null; then
  echo -e "${GREEN}✅ Logs de kubelet accesibles${NC}"
  # Verificar errores recientes
  KUBELET_ERRORS=$(sudo journalctl -u kubelet --no-pager -n 50 --since "5 minutes ago" | grep -i "error" | wc -l)
  if [ "$KUBELET_ERRORS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Kubelet tiene $KUBELET_ERRORS errores recientes${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo -e "${YELLOW}⚠️  No se pueden leer logs de kubelet${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# Resumen final
echo ""
echo -e "${BLUE}==========================================="
echo "Resumen de Verificación"
echo "==========================================="
echo -e "${NC}"

echo "Total de checks: $CHECKS"
echo -e "Errores: ${RED}$ERRORS${NC}"
echo -e "Advertencias: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✅ CLUSTER COMPLETAMENTE FUNCIONAL${NC}"
  echo ""
  echo "El cluster de Kubernetes está completamente operativo."
  echo "Todos los componentes están funcionando correctamente."
  EXIT_CODE=0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠️  CLUSTER FUNCIONAL CON ADVERTENCIAS${NC}"
  echo ""
  echo "El cluster está operativo pero tiene algunas advertencias."
  echo "Revisa los mensajes anteriores para detalles."
  EXIT_CODE=1
else
  echo -e "${RED}❌ CLUSTER CON PROBLEMAS${NC}"
  echo ""
  echo "El cluster tiene problemas que deben ser resueltos."
  echo "Revisa los errores anteriores y los logs de componentes."
  EXIT_CODE=2
fi

# Información adicional útil
echo ""
echo -e "${BLUE}Información del Cluster:${NC}"
echo ""
kubectl get nodes -o wide 2>/dev/null || true
echo ""
echo "Pods del sistema:"
kubectl get pods -n kube-system -o wide 2>/dev/null || true

echo ""
echo -e "${BLUE}Comandos útiles para troubleshooting:${NC}"
echo "  kubectl get pods -A                     # Ver todos los pods"
echo "  kubectl describe node <node-name>      # Detalles del nodo"
echo "  kubectl logs -n kube-system <pod>      # Logs de pods del sistema"
echo "  sudo journalctl -u kubelet -f          # Logs de kubelet"
echo "  sudo journalctl -u containerd -f       # Logs de containerd"
echo ""

exit $EXIT_CODE
