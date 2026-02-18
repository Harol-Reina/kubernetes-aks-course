#!/bin/bash

################################################################################
# Script: verify-cluster.sh
# Descripción: Verifica que el cluster de Minikube está funcionando correctamente
# Uso: ./verify-cluster.sh [profile-name]
################################################################################

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PROFILE=${1:-minikube}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Verificación del Cluster Minikube                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Función para verificar
check() {
    local description="$1"
    local command="$2"
    
    echo -n "Verificando $description... "
    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

FAILED=0

# 1. Verificar que Minikube está instalado
check "Minikube instalado" "command -v minikube" || ((FAILED++))

# 2. Verificar que kubectl está instalado
check "kubectl instalado" "command -v kubectl" || ((FAILED++))

# 3. Verificar estado de Minikube
echo -n "Verificando estado de Minikube... "
STATUS=$(minikube status -p $PROFILE -f='{{.Host}}' 2>/dev/null)
if [ "$STATUS" = "Running" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC} (Estado: $STATUS)"
    ((FAILED++))
fi

# 4. Verificar que kubelet está corriendo
echo -n "Verificando kubelet... "
KUBELET=$(minikube status -p $PROFILE -f='{{.Kubelet}}' 2>/dev/null)
if [ "$KUBELET" = "Running" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC} (Estado: $KUBELET)"
    ((FAILED++))
fi

# 5. Verificar que apiserver está corriendo
echo -n "Verificando apiserver... "
APISERVER=$(minikube status -p $PROFILE -f='{{.APIServer}}' 2>/dev/null)
if [ "$APISERVER" = "Running" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC} (Estado: $APISERVER)"
    ((FAILED++))
fi

# 6. Verificar que kubectl puede conectarse
check "Conexión kubectl" "kubectl get nodes" || ((FAILED++))

# 7. Verificar que hay nodos Ready
echo -n "Verificando nodos Ready... "
READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready")
if [ "$READY_NODES" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} ($READY_NODES nodos)"
else
    echo -e "${RED}✗${NC}"
    ((FAILED++))
fi

# 8. Verificar pods del sistema
echo -n "Verificando pods del sistema (kube-system)... "
RUNNING_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c " Running")
TOTAL_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l)
if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} ($RUNNING_PODS/$TOTAL_PODS corriendo)"
else
    echo -e "${YELLOW}⚠${NC} ($RUNNING_PODS/$TOTAL_PODS corriendo)"
fi

# 9. Verificar Docker (si driver=docker)
DRIVER=$(minikube profile list -o json 2>/dev/null | grep -o '"Driver":"[^"]*"' | cut -d'"' -f4)
if [ "$DRIVER" = "docker" ]; then
    check "Docker corriendo" "docker ps" || ((FAILED++))
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# Resumen
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Todas las verificaciones pasaron correctamente${NC}"
    echo ""
    
    # Mostrar información adicional
    echo -e "${YELLOW}Información del cluster:${NC}"
    echo ""
    minikube status -p $PROFILE
    echo ""
    echo -e "${YELLOW}Nodos:${NC}"
    kubectl get nodes -o wide
    echo ""
    echo -e "${YELLOW}Pods del sistema:${NC}"
    kubectl get pods -n kube-system
    echo ""
    
    exit 0
else
    echo -e "${RED}✗ $FAILED verificaciones fallaron${NC}"
    echo ""
    echo -e "${YELLOW}Acciones sugeridas:${NC}"
    echo "  1. Reinicia Minikube:"
    echo "     minikube stop -p $PROFILE && minikube start -p $PROFILE"
    echo ""
    echo "  2. Revisa logs:"
    echo "     minikube logs -p $PROFILE"
    echo ""
    echo "  3. Si el problema persiste, elimina y recrea:"
    echo "     minikube delete -p $PROFILE"
    echo "     ejemplos/02-configuracion/minikube-start-custom.sh $PROFILE"
    echo ""
    
    exit 1
fi
