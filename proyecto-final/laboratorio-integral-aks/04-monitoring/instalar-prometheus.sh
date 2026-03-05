#!/bin/bash
# Instalar kube-prometheus-stack en el cluster AKS
# Uso: bash instalar-prometheus.sh
#
# Prerequisitos:
#   - Helm 3 instalado (helm version)
#   - kubectl conectado al cluster AKS
#   - Namespace 'monitoring' ya creado o se crea aqui
#
# Despues de instalar:
#   - Grafana: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
#   - Prometheus: kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
#   - Usuario Grafana: admin / LabAKS2024!

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Instalacion de Prometheus + Grafana   ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Paso 1: Verificar prerequisitos
echo -e "${YELLOW}[1/5] Verificando prerequisitos...${NC}"

if ! command -v helm &> /dev/null; then
    echo -e "${RED}ERROR: Helm no esta instalado${NC}"
    echo "Instala Helm: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    exit 1
fi
echo -e "  ${GREEN}Helm: $(helm version --short)${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}ERROR: kubectl no esta instalado${NC}"
    exit 1
fi
echo -e "  ${GREEN}kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client -o yaml | grep gitVersion | head -1)${NC}"

NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
if [ "$NODES" -eq 0 ]; then
    echo -e "${RED}ERROR: No hay nodos disponibles. Verifica tu conexion al cluster.${NC}"
    exit 1
fi
echo -e "  ${GREEN}Nodos en el cluster: $NODES${NC}"

# Paso 2: Agregar repositorio Helm
echo ""
echo -e "${YELLOW}[2/5] Agregando repositorio de Helm charts...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update
echo -e "  ${GREEN}Repositorio actualizado${NC}"

# Paso 3: Crear namespace si no existe
echo ""
echo -e "${YELLOW}[3/5] Verificando namespace monitoring...${NC}"
if kubectl get namespace monitoring &> /dev/null; then
    echo -e "  ${GREEN}Namespace 'monitoring' ya existe${NC}"
else
    kubectl create namespace monitoring
    kubectl label namespace monitoring proyecto=laboratorio-integral tier=monitoring env=laboratorio
    echo -e "  ${GREEN}Namespace 'monitoring' creado${NC}"
fi

# Paso 4: Instalar kube-prometheus-stack
echo ""
echo -e "${YELLOW}[4/5] Instalando kube-prometheus-stack (esto tarda 2-3 minutos)...${NC}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values "${SCRIPT_DIR}/prometheus-values.yaml" \
    --timeout 5m \
    --wait

echo -e "  ${GREEN}kube-prometheus-stack instalado correctamente${NC}"

# Paso 5: Verificar instalacion
echo ""
echo -e "${YELLOW}[5/5] Verificando pods en namespace monitoring...${NC}"
echo ""
kubectl get pods -n monitoring -o wide
echo ""
kubectl get svc -n monitoring

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Instalacion completada!               ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Para acceder a Grafana:${NC}"
echo -e "  kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
echo -e "  Abrir: http://localhost:3000"
echo -e "  Usuario: admin"
echo -e "  Password: LabAKS2024!"
echo ""
echo -e "${BLUE}Para acceder a Prometheus:${NC}"
echo -e "  kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring"
echo -e "  Abrir: http://localhost:9090"
echo ""
echo -e "${BLUE}Para acceder a AlertManager:${NC}"
echo -e "  kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n monitoring"
echo -e "  Abrir: http://localhost:9093"
