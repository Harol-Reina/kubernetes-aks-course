#!/bin/bash

################################################################################
# Script: install-minikube.sh
# Descripción: Instalación automatizada de Minikube en Linux
# Uso: ./install-minikube.sh (sin sudo - instala en ~/.local/bin)
#      sudo ./install-minikube.sh (instala en /usr/local/bin)
# Requisitos: curl instalado, Docker instalado (para driver docker)
################################################################################

set -e  # Detener en caso de error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Determinar directorio de instalación
if [ "$EUID" -eq 0 ]; then
    INSTALL_DIR="/usr/local/bin"
    print_message "Instalación global (requiere sudo)"
else
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    print_message "Instalación local en $INSTALL_DIR"
    
    # Verificar si está en PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        print_warning "$INSTALL_DIR no está en tu PATH"
        print_warning "Agrega al final de ~/.bashrc o ~/.zshrc:"
        echo -e "${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    fi
fi

print_message "Iniciando instalación de Minikube..."

# 1. Detectar arquitectura
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        MINIKUBE_ARCH="amd64"
        ;;
    aarch64)
        MINIKUBE_ARCH="arm64"
        ;;
    armv7l)
        MINIKUBE_ARCH="arm"
        ;;
    *)
        print_error "Arquitectura no soportada: $ARCH"
        exit 1
        ;;
esac

print_message "Arquitectura detectada: $ARCH ($MINIKUBE_ARCH)"

# 2. Descargar Minikube (última versión)
TEMP_FILE=$(mktemp)
MINIKUBE_URL="https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${MINIKUBE_ARCH}"

print_message "Descargando Minikube desde $MINIKUBE_URL..."
curl -L "$MINIKUBE_URL" -o "$TEMP_FILE" --progress-bar

# 3. Verificar descarga
if [ ! -s "$TEMP_FILE" ]; then
    print_error "Error al descargar Minikube"
    rm -f "$TEMP_FILE"
    exit 1
fi

print_message "✓ Descarga completada"

# 4. Instalar Minikube
print_message "Instalando Minikube en $INSTALL_DIR..."
chmod +x "$TEMP_FILE"

if [ "$EUID" -eq 0 ]; then
    mv "$TEMP_FILE" "$INSTALL_DIR/minikube"
else
    mv "$TEMP_FILE" "$INSTALL_DIR/minikube"
fi

print_message "✓ Minikube instalado correctamente"

# 5. Verificar instalación
MINIKUBE_VERSION=$(minikube version --short)
print_message "Versión instalada: $MINIKUBE_VERSION"

# 6. Verificar prerequisitos
echo ""
print_message "Verificando prerequisitos..."

# Verificar Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_message "✓ Docker encontrado: $DOCKER_VERSION"
    
    # Verificar que docker funciona sin sudo
    if docker ps &> /dev/null; then
        print_message "✓ Docker configurado correctamente (sin sudo)"
    else
        print_warning "Docker requiere sudo. Agrega tu usuario al grupo docker:"
        echo -e "  ${BLUE}sudo usermod -aG docker \$USER${NC}"
        echo -e "  ${BLUE}newgrp docker${NC}"
    fi
else
    print_warning "Docker no está instalado. Instálalo antes de usar Minikube con driver docker"
    echo -e "  Ver: ${BLUE}ejemplos/01-instalacion/install-docker.sh${NC}"
fi

# Verificar kubectl
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null || kubectl version --client)
    print_message "✓ kubectl encontrado"
else
    print_warning "kubectl no está instalado. Se recomienda instalarlo:"
    echo -e "  Ver: ${BLUE}ejemplos/01-instalacion/install-kubectl.sh${NC}"
fi

# Información post-instalación
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Minikube instalado correctamente ✓                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Versión instalada:${NC} $MINIKUBE_VERSION"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo ""
echo "  1. Configura autocomplete (bash):"
echo -e "     ${BLUE}minikube completion bash | sudo tee /etc/bash_completion.d/minikube${NC}"
echo ""
echo "  2. Configura autocomplete (zsh):"
echo -e "     ${BLUE}minikube completion zsh > ~/.zsh/completion/_minikube${NC}"
echo ""
echo "  3. Crea alias conveniente:"
echo -e "     ${BLUE}echo 'alias mk=minikube' >> ~/.bashrc${NC}"
echo ""
echo "  4. Inicia tu primer cluster:"
echo -e "     ${BLUE}minikube start --driver=docker --cpus=2 --memory=4096${NC}"
echo ""
echo "  5. Verifica el cluster:"
echo -e "     ${BLUE}minikube status${NC}"
echo -e "     ${BLUE}kubectl get nodes${NC}"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo "  minikube status               # Estado del cluster"
echo "  minikube start                # Iniciar cluster"
echo "  minikube stop                 # Detener cluster"
echo "  minikube delete               # Eliminar cluster"
echo "  minikube dashboard            # Abrir dashboard web"
echo "  minikube profile list         # Listar perfiles"
echo ""
echo -e "${YELLOW}Recursos adicionales:${NC}"
echo "  - Comparativa de drivers: ejemplos/01-instalacion/comparativa-drivers.md"
echo "  - Scripts de configuración: ejemplos/02-configuracion/"
echo "  - Primeros pasos: ejemplos/03-primeros-pasos/"
echo ""

exit 0
