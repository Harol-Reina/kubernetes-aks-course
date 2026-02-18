#!/bin/bash

################################################################################
# Script: primera-app.sh
# Descripción: Despliega una aplicación Nginx simple en Minikube
# Uso: ./primera-app.sh
# Propósito: Demostración de primer deployment en Kubernetes
################################################################################

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Desplegando Primera Aplicación en Kubernetes       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que kubectl funciona
if ! kubectl get nodes &> /dev/null; then
    echo -e "${YELLOW}[ERROR]${NC} No se puede conectar al cluster"
    echo "Inicia Minikube: minikube start"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Creando deployment de Nginx..."
kubectl create deployment nginx --image=nginx:latest

echo -e "${GREEN}[INFO]${NC} Esperando que el pod esté listo..."
kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s

echo -e "${GREEN}[INFO]${NC} Exponiendo deployment como servicio NodePort..."
kubectl expose deployment nginx --type=NodePort --port=80

echo -e "${GREEN}[INFO]${NC} Esperando que el servicio esté disponible..."
sleep 2

# Obtener URL del servicio
SERVICE_URL=$(minikube service nginx --url)

echo ""
echo -e "${GREEN}✓ Aplicación desplegada correctamente${NC}"
echo ""
echo -e "${YELLOW}Información del deployment:${NC}"
kubectl get deployment nginx
echo ""
echo -e "${YELLOW}Pods:${NC}"
kubectl get pods -l app=nginx
echo ""
echo -e "${YELLOW}Servicios:${NC}"
kubectl get service nginx
echo ""
echo -e "${YELLOW}Acceder a la aplicación:${NC}"
echo -e "  URL: ${BLUE}$SERVICE_URL${NC}"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo "  minikube service nginx                    # Abrir en navegador"
echo "  kubectl logs -l app=nginx                 # Ver logs"
echo "  kubectl describe pod -l app=nginx         # Detalles del pod"
echo "  kubectl get all                           # Ver todos los recursos"
echo ""
echo -e "${YELLOW}Para limpiar:${NC}"
echo "  kubectl delete service nginx"
echo "  kubectl delete deployment nginx"
echo ""

exit 0
