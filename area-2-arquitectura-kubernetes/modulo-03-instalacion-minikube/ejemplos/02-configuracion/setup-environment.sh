#!/bin/bash

################################################################################
# Script: setup-environment.sh
# Descripción: Configuración completa del entorno de desarrollo con Minikube
# Uso: ./setup-environment.sh
# Propósito: Automatiza instalación y configuración de Docker, kubectl, Minikube
################################################################################

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que se ejecuta en Ubuntu
if [ ! -f /etc/os-release ]; then
    print_error "Este script solo funciona en Ubuntu"
    exit 1
fi

source /etc/os-release
if [ "$ID" != "ubuntu" ]; then
    print_error "Este script solo funciona en Ubuntu (detectado: $ID)"
    exit 1
fi

print_message "Sistema detectado: $PRETTY_NAME"

# Directorio base para scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR/../01-instalacion"

print_header "Configuración del Entorno Kubernetes"

# 1. Verificar e instalar Docker
print_header "Paso 1/5: Docker"

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_message "✓ Docker ya está instalado: $DOCKER_VERSION"
    
    if docker ps &> /dev/null; then
        print_message "✓ Docker está funcionando correctamente"
    else
        print_warning "Docker requiere permisos. Configurando..."
        sudo usermod -aG docker $USER
        print_warning "Debes cerrar sesión y volver a entrar para aplicar permisos"
    fi
else
    print_message "Docker no encontrado. Instalando..."
    if [ -f "$INSTALL_DIR/install-docker.sh" ]; then
        sudo bash "$INSTALL_DIR/install-docker.sh"
    else
        print_error "Script de instalación de Docker no encontrado"
        exit 1
    fi
fi

# 2. Verificar e instalar kubectl
print_header "Paso 2/5: kubectl"

if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null || kubectl version --client)
    print_message "✓ kubectl ya está instalado"
else
    print_message "kubectl no encontrado. Instalando..."
    if [ -f "$INSTALL_DIR/install-kubectl.sh" ]; then
        bash "$INSTALL_DIR/install-kubectl.sh"
    else
        print_error "Script de instalación de kubectl no encontrado"
        exit 1
    fi
fi

# 3. Verificar e instalar Minikube
print_header "Paso 3/5: Minikube"

if command -v minikube &> /dev/null; then
    MINIKUBE_VERSION=$(minikube version --short)
    print_message "✓ Minikube ya está instalado: $MINIKUBE_VERSION"
else
    print_message "Minikube no encontrado. Instalando..."
    if [ -f "$INSTALL_DIR/install-minikube.sh" ]; then
        bash "$INSTALL_DIR/install-minikube.sh"
    else
        print_error "Script de instalación de Minikube no encontrado"
        exit 1
    fi
fi

# 4. Configurar autocomplete
print_header "Paso 4/5: Autocomplete"

# Detectar shell
CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" = "bash" ]; then
    print_message "Configurando autocomplete para Bash..."
    if [ -f "$SCRIPT_DIR/kubectl-autocomplete-bash.sh" ]; then
        bash "$SCRIPT_DIR/kubectl-autocomplete-bash.sh"
    fi
elif [ "$CURRENT_SHELL" = "zsh" ]; then
    print_message "Configurando autocomplete para Zsh..."
    if [ -f "$SCRIPT_DIR/kubectl-autocomplete-zsh.sh" ]; then
        zsh "$SCRIPT_DIR/kubectl-autocomplete-zsh.sh"
    fi
else
    print_warning "Shell no reconocido: $CURRENT_SHELL (autocomplete omitido)"
fi

# 5. Verificar instalación completa
print_header "Paso 5/5: Verificación"

VERIFICATION_FAILED=0

# Verificar comandos disponibles
for cmd in docker kubectl minikube; do
    if command -v $cmd &> /dev/null; then
        VERSION=$($cmd version --short 2>/dev/null || $cmd --version 2>/dev/null || echo "instalado")
        print_message "✓ $cmd: $VERSION"
    else
        print_error "✗ $cmd no está disponible"
        ((VERIFICATION_FAILED++))
    fi
done

# Resumen final
print_header "Resumen de Instalación"

if [ $VERIFICATION_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Todas las herramientas instaladas correctamente${NC}"
    echo ""
    echo -e "${YELLOW}Próximos pasos:${NC}"
    echo ""
    echo "1. Si instalaste Docker por primera vez, cierra sesión y vuelve a entrar:"
    echo -e "   ${BLUE}exit${NC}"
    echo ""
    echo "2. Inicia Minikube:"
    echo -e "   ${BLUE}minikube start --driver=docker --cpus=2 --memory=4096${NC}"
    echo ""
    echo "3. Verifica el cluster:"
    echo -e "   ${BLUE}kubectl get nodes${NC}"
    echo -e "   ${BLUE}minikube status${NC}"
    echo ""
    echo "4. Habilita addons útiles:"
    echo -e "   ${BLUE}minikube addons enable metrics-server${NC}"
    echo -e "   ${BLUE}minikube addons enable dashboard${NC}"
    echo ""
    echo "5. Despliega tu primera aplicación:"
    echo -e "   ${BLUE}ejemplos/03-primeros-pasos/primera-app.sh${NC}"
    echo ""
else
    print_error "$VERIFICATION_FAILED herramientas no se instalaron correctamente"
    echo ""
    echo "Revisa los errores anteriores e intenta instalar manualmente:"
    echo "  - Docker:    ejemplos/01-instalacion/install-docker.sh"
    echo "  - kubectl:   ejemplos/01-instalacion/install-kubectl.sh"
    echo "  - Minikube:  ejemplos/01-instalacion/install-minikube.sh"
    exit 1
fi

exit 0
