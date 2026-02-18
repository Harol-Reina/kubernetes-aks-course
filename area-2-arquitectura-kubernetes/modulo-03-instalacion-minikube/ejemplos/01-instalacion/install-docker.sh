#!/bin/bash

################################################################################
# Script: install-docker.sh
# Descripción: Instalación automatizada de Docker Engine en Ubuntu
# Uso: sudo ./install-docker.sh
# Requisitos: Ubuntu 20.04+ con permisos sudo
################################################################################

set -e  # Detener en caso de error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar que se ejecuta con sudo
if [ "$EUID" -ne 0 ]; then 
    print_error "Por favor ejecuta este script con sudo"
    exit 1
fi

print_message "Iniciando instalación de Docker Engine..."

# 1. Actualizar índice de paquetes
print_message "Paso 1/7: Actualizando repositorios..."
apt-get update -qq

# 2. Instalar dependencias necesarias
print_message "Paso 2/7: Instalando dependencias..."
apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. Agregar GPG key oficial de Docker
print_message "Paso 3/7: Agregando GPG key de Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 4. Configurar repositorio de Docker
print_message "Paso 4/7: Configurando repositorio de Docker..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Actualizar índice con nuevo repositorio
print_message "Paso 5/7: Actualizando repositorios..."
apt-get update -qq

# 6. Instalar Docker Engine
print_message "Paso 6/7: Instalando Docker Engine..."
apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 7. Configurar permisos para usuario actual
if [ -n "$SUDO_USER" ]; then
    print_message "Paso 7/7: Configurando permisos para usuario $SUDO_USER..."
    usermod -aG docker $SUDO_USER
    print_warning "IMPORTANTE: Debes cerrar sesión y volver a iniciar para que los permisos surtan efecto"
else
    print_warning "No se detectó SUDO_USER. Debes agregar tu usuario al grupo docker manualmente:"
    print_warning "  sudo usermod -aG docker \$USER"
fi

# Verificar instalación
print_message "Verificando instalación..."
systemctl start docker
systemctl enable docker

DOCKER_VERSION=$(docker --version)
print_message "✓ Docker instalado correctamente: $DOCKER_VERSION"

# Información post-instalación
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Docker instalado correctamente ✓                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "  1. Cierra sesión y vuelve a iniciar (para permisos de docker)"
echo "  2. Verifica la instalación: docker run hello-world"
echo "  3. Revisa el estado: systemctl status docker"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo "  docker --version              # Ver versión instalada"
echo "  docker info                   # Información del sistema"
echo "  docker ps                     # Contenedores en ejecución"
echo "  systemctl status docker       # Estado del servicio"
echo ""

exit 0
