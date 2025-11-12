#!/bin/bash

################################################################################
# Script: install-kubectl.sh
# Descripción: Instalación automatizada de kubectl en Linux
# Uso: ./install-kubectl.sh (sin sudo - instala en ~/.local/bin)
#      sudo ./install-kubectl.sh (instala en /usr/local/bin)
# Requisitos: curl instalado
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

print_message "Iniciando instalación de kubectl..."

# 1. Detectar arquitectura
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        KUBECTL_ARCH="amd64"
        ;;
    aarch64)
        KUBECTL_ARCH="arm64"
        ;;
    armv7l)
        KUBECTL_ARCH="arm"
        ;;
    *)
        print_error "Arquitectura no soportada: $ARCH"
        exit 1
        ;;
esac

print_message "Arquitectura detectada: $ARCH ($KUBECTL_ARCH)"

# 2. Obtener última versión estable
print_message "Obteniendo última versión estable..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
print_message "Versión a instalar: $KUBECTL_VERSION"

# 3. Descargar kubectl
TEMP_FILE=$(mktemp)
print_message "Descargando kubectl $KUBECTL_VERSION..."
curl -L "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/$KUBECTL_ARCH/kubectl" \
    -o "$TEMP_FILE" \
    --progress-bar

# 4. Descargar y verificar checksum
print_message "Verificando checksum..."
CHECKSUM_FILE=$(mktemp)
curl -L "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/$KUBECTL_ARCH/kubectl.sha256" \
    -o "$CHECKSUM_FILE" -s

# Verificar checksum
echo "$(cat $CHECKSUM_FILE) $TEMP_FILE" | sha256sum --check --status
if [ $? -eq 0 ]; then
    print_message "✓ Checksum verificado correctamente"
else
    print_error "Checksum no coincide. Instalación abortada."
    rm -f "$TEMP_FILE" "$CHECKSUM_FILE"
    exit 1
fi

# 5. Instalar kubectl
print_message "Instalando kubectl en $INSTALL_DIR..."
chmod +x "$TEMP_FILE"

if [ "$EUID" -eq 0 ]; then
    mv "$TEMP_FILE" "$INSTALL_DIR/kubectl"
else
    mv "$TEMP_FILE" "$INSTALL_DIR/kubectl"
fi

# Limpiar archivos temporales
rm -f "$CHECKSUM_FILE"

# 6. Verificar instalación
INSTALLED_VERSION=$(kubectl version --client --short 2>/dev/null || kubectl version --client)
print_message "✓ kubectl instalado correctamente"

# Información post-instalación
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          kubectl instalado correctamente ✓                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Versión instalada:${NC}"
echo "$INSTALLED_VERSION"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "  1. Configura autocomplete (bash):"
echo -e "     ${BLUE}kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl${NC}"
echo ""
echo "  2. Configura autocomplete (zsh):"
echo -e "     ${BLUE}kubectl completion zsh > ~/.zsh/completion/_kubectl${NC}"
echo ""
echo "  3. Crea alias conveniente:"
echo -e "     ${BLUE}echo 'alias k=kubectl' >> ~/.bashrc${NC}"
echo ""
echo "  4. Verifica conexión (después de instalar minikube):"
echo -e "     ${BLUE}kubectl version${NC}"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo "  kubectl version --client      # Ver versión de cliente"
echo "  kubectl cluster-info          # Info del cluster"
echo "  kubectl get nodes             # Listar nodos"
echo "  kubectl config view           # Ver configuración"
echo ""

exit 0
