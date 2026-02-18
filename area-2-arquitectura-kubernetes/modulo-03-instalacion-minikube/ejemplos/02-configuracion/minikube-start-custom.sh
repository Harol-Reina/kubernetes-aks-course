#!/bin/bash

################################################################################
# Script: minikube-start-custom.sh
# Descripción: Script para iniciar Minikube con configuración personalizada
# Uso: ./minikube-start-custom.sh [profile-name]
# Ejemplo: ./minikube-start-custom.sh dev
################################################################################

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Nombre del perfil (default: minikube)
PROFILE=${1:-minikube}

# Configuración personalizable
DRIVER="docker"
CPUS="2"
MEMORY="4096"  # 4GB
DISK_SIZE="20g"
KUBERNETES_VERSION=""  # Vacío = última versión estable

print_message "Iniciando Minikube con perfil: $PROFILE"
echo ""
echo -e "${BLUE}Configuración:${NC}"
echo "  Driver:     $DRIVER"
echo "  CPUs:       $CPUS"
echo "  Memoria:    ${MEMORY}MB"
echo "  Disco:      $DISK_SIZE"
echo "  K8s:        $([ -z "$KUBERNETES_VERSION" ] && echo "latest" || echo "$KUBERNETES_VERSION")"
echo ""

# Verificar que Minikube está instalado
if ! command -v minikube &> /dev/null; then
    print_error "Minikube no está instalado"
    echo "Instala Minikube: ejemplos/01-instalacion/install-minikube.sh"
    exit 1
fi

# Verificar que Docker está corriendo (si driver=docker)
if [ "$DRIVER" = "docker" ]; then
    if ! docker ps &> /dev/null; then
        print_error "Docker no está corriendo o no tienes permisos"
        echo "Soluciones:"
        echo "  1. Inicia Docker: sudo systemctl start docker"
        echo "  2. Agrega permisos: sudo usermod -aG docker \$USER && newgrp docker"
        exit 1
    fi
    print_message "✓ Docker está corriendo"
fi

# Construir comando de inicio
CMD="minikube start --profile=$PROFILE --driver=$DRIVER --cpus=$CPUS --memory=$MEMORY --disk-size=$DISK_SIZE"

# Agregar versión de K8s si está especificada
if [ -n "$KUBERNETES_VERSION" ]; then
    CMD="$CMD --kubernetes-version=$KUBERNETES_VERSION"
fi

# Mostrar comando
print_message "Ejecutando:"
echo -e "  ${BLUE}$CMD${NC}"
echo ""

# Ejecutar
$CMD

# Verificar que el cluster está corriendo
print_message "Verificando cluster..."
sleep 2

minikube status --profile=$PROFILE

echo ""
print_message "✓ Cluster iniciado correctamente"
echo ""

# Configurar kubectl para usar este perfil
if [ "$PROFILE" != "minikube" ]; then
    print_message "Configurando kubectl para usar perfil '$PROFILE'..."
    kubectl config use-context $PROFILE
fi

# Mostrar información del cluster
echo -e "${YELLOW}Información del cluster:${NC}"
kubectl cluster-info
echo ""

echo -e "${YELLOW}Nodos disponibles:${NC}"
kubectl get nodes
echo ""

# Comandos útiles
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Cluster Minikube iniciado ✓                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo "  minikube status -p $PROFILE          # Ver estado"
echo "  minikube dashboard -p $PROFILE       # Abrir dashboard"
echo "  minikube stop -p $PROFILE            # Detener cluster"
echo "  minikube delete -p $PROFILE          # Eliminar cluster"
echo "  minikube ssh -p $PROFILE             # SSH al nodo"
echo ""
echo "  kubectl get nodes                    # Ver nodos"
echo "  kubectl get pods -A                  # Ver todos los pods"
echo "  kubectl config current-context       # Ver contexto actual"
echo ""

exit 0
