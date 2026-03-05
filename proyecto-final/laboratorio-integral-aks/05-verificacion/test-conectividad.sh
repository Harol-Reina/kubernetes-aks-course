#!/bin/bash
# Script de verificacion de conectividad entre servicios
# Uso: bash test-conectividad.sh
#
# Descripcion:
#   Verifica que todos los componentes del laboratorio estan funcionando
#   y que la comunicacion cross-namespace funciona correctamente.
#   Ejecuta tests desde un Pod temporal con curl/wget.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local description=$1
    local command=$2
    echo -n "  Verificando: $description... "
    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}OK${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FALLO${NC}"
        FAIL=$((FAIL + 1))
    fi
}

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Verificacion del Laboratorio Integral AKS      ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# --- 1. Namespaces ---
echo -e "${YELLOW}[1/6] Verificando Namespaces...${NC}"
check "tienda-web existe" "kubectl get namespace tienda-web"
check "tienda-api existe" "kubectl get namespace tienda-api"
check "tienda-db existe" "kubectl get namespace tienda-db"
check "stress-test existe" "kubectl get namespace stress-test"
check "monitoring existe" "kubectl get namespace monitoring"
echo ""

# --- 2. ResourceQuotas y LimitRanges ---
echo -e "${YELLOW}[2/6] Verificando ResourceQuotas y LimitRanges...${NC}"
check "ResourceQuota en tienda-web" "kubectl get resourcequota -n tienda-web --no-headers | grep -q quota"
check "ResourceQuota en tienda-api" "kubectl get resourcequota -n tienda-api --no-headers | grep -q quota"
check "ResourceQuota en tienda-db" "kubectl get resourcequota -n tienda-db --no-headers | grep -q quota"
check "LimitRange en tienda-web" "kubectl get limitrange -n tienda-web --no-headers | grep -q limitrange"
check "LimitRange en tienda-api" "kubectl get limitrange -n tienda-api --no-headers | grep -q limitrange"
echo ""

# --- 3. Pods Running ---
echo -e "${YELLOW}[3/6] Verificando Pods en estado Running...${NC}"
check "Redis running" "kubectl get pods -n tienda-db -l app=redis --no-headers | grep -q Running"
check "API Gateway running" "kubectl get pods -n tienda-api -l app=api-gateway --no-headers | grep -q Running"
check "Frontend running" "kubectl get pods -n tienda-web -l app=frontend --no-headers | grep -q Running"
check "CPU Burner running" "kubectl get pods -n stress-test -l app=cpu-burner --no-headers | grep -q Running"
echo ""

# --- 4. Services ---
echo -e "${YELLOW}[4/6] Verificando Services...${NC}"
check "Service redis (ClusterIP)" "kubectl get svc redis -n tienda-db"
check "Service api-gateway (ClusterIP)" "kubectl get svc api-gateway -n tienda-api"
check "Service api-gateway-external (LoadBalancer)" "kubectl get svc api-gateway-external -n tienda-api"
check "Service frontend-external (LoadBalancer)" "kubectl get svc frontend-external -n tienda-web"
echo ""

# --- 5. Conectividad Cross-Namespace ---
echo -e "${YELLOW}[5/6] Verificando conectividad cross-namespace...${NC}"
echo "  (Creando Pod temporal para tests de red...)"

# Test desde un Pod temporal: API Gateway responde
kubectl run test-connectivity --rm -it --restart=Never \
    --image=busybox:1.36 \
    --namespace=tienda-web \
    --command -- wget -q -O- --timeout=5 http://api-gateway.tienda-api.svc.cluster.local:8080/health > /tmp/test-api 2>&1
if grep -q "healthy" /tmp/test-api 2>/dev/null; then
    echo -e "  Verificando: tienda-web -> tienda-api (cross-namespace)... ${GREEN}OK${NC}"
    PASS=$((PASS + 1))
else
    echo -e "  Verificando: tienda-web -> tienda-api (cross-namespace)... ${RED}FALLO${NC}"
    FAIL=$((FAIL + 1))
fi

# Test: Redis responde a PING
kubectl run test-redis --rm -it --restart=Never \
    --image=redis:7-alpine \
    --namespace=tienda-api \
    --command -- redis-cli -h redis.tienda-db.svc.cluster.local -a "Lab2024SecurePass!" ping > /tmp/test-redis 2>&1
if grep -q "PONG" /tmp/test-redis 2>/dev/null; then
    echo -e "  Verificando: tienda-api -> tienda-db Redis PING... ${GREEN}OK${NC}"
    PASS=$((PASS + 1))
else
    echo -e "  Verificando: tienda-api -> tienda-db Redis PING... ${RED}FALLO${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# --- 6. Monitoring ---
echo -e "${YELLOW}[6/6] Verificando stack de monitoreo...${NC}"
check "Prometheus running" "kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers | grep -q Running"
check "Grafana running" "kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers | grep -q Running"
check "HPA configurado" "kubectl get hpa -n tienda-api --no-headers | grep -q hpa"
echo ""

# --- Resumen ---
TOTAL=$((PASS + FAIL))
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Resumen de Verificacion                        ${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "  Tests pasados:  ${GREEN}$PASS${NC} / $TOTAL"
echo -e "  Tests fallidos: ${RED}$FAIL${NC} / $TOTAL"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}  TODOS LOS TESTS PASARON - Laboratorio OK!${NC}"
else
    echo -e "${YELLOW}  Hay $FAIL tests fallidos. Revisa los componentes.${NC}"
fi

# --- IPs externas ---
echo ""
echo -e "${BLUE}  IPs Externas (LoadBalancer):${NC}"
echo -e "  Frontend: $(kubectl get svc frontend-external -n tienda-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'pendiente...')"
echo -e "  API:      $(kubectl get svc api-gateway-external -n tienda-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'pendiente...')"
echo ""
