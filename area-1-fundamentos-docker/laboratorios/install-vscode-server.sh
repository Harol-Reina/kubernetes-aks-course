#!/bin/bash

# 🚀 Instalador Automático de VS Code Tunnel para Azure VM
# Autor: Curso Docker & Kubernetes
# Versión: 2.0
# Fecha: Noviembre 2024

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo -e "${BLUE}"
cat << 'EOF'
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   🚀 INSTALADOR VS CODE TUNNEL PARA DOCKER & K8S       │
│                                                         │
│   Este script instalará automáticamente:               │
│   ✅ Docker Engine                                      │
│   ✅ VS Code CLI con Tunnel support                     │
│   ✅ Configuración automática de servicios             │
│   ✅ Workspace preconfigurado                          │
│   🔐 Sin necesidad de puertos abiertos                 │
│   🌐 Acceso seguro con GitHub/Microsoft                │
│                                                         │
└─────────────────────────────────────────────────────────┘
EOF
echo -e "${NC}"

# Verificar que se ejecuta en Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    log_error "Este script está diseñado para Ubuntu. OS detectado: $(cat /etc/os-release | grep PRETTY_NAME)"
    exit 1
fi

# Verificar conexión a Internet
log_info "Verificando conectividad..."
if ! ping -c 1 google.com &> /dev/null; then
    log_error "No hay conexión a Internet. Verificar configuración de red."
    exit 1
fi
log_success "Conectividad verificada ✓"

# Configuración personalizable
read -p "🏷️ Nombre del tunnel (default: docker-k8s-lab-$USER): " TUNNEL_NAME
TUNNEL_NAME=${TUNNEL_NAME:-"docker-k8s-lab-$USER"}

echo -e "\n${YELLOW}📋 CONFIGURACIÓN:${NC}"
echo "   Tunnel Name: $TUNNEL_NAME"
echo "   Usuario: $USER"
echo "   Autenticación: GitHub/Microsoft (interactiva)"
echo ""

read -p "¿Continuar con la instalación? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Instalación cancelada por el usuario"
    exit 0
fi

log_info "🚀 Iniciando instalación..."

# 1. Actualizar sistema
log_info "📦 Actualizando sistema..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release htop

# 2. Instalar Docker
log_info "🐳 Instalando Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Agregar usuario al grupo docker
    sudo usermod -aG docker $USER
    log_success "Docker instalado correctamente"
else
    log_warning "Docker ya está instalado"
fi

# 3. Instalar VS Code CLI
log_info "� Instalando VS Code CLI..."
if ! command -v code &> /dev/null; then
    # Descargar VS Code CLI
    curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz
    
    # Extraer el CLI
    tar -xf vscode_cli.tar.gz
    
    # Mover a ubicación global
    sudo mv code /usr/local/bin/
    
    # Limpiar archivo temporal
    rm vscode_cli.tar.gz
    
    log_success "VS Code CLI $(code --version) instalado"
else
    log_warning "VS Code CLI ya está instalado: $(code --version)"
fi

# 4. Crear servicio systemd para tunnel
log_info "🔧 Creando servicio systemd..."
sudo tee /etc/systemd/system/vscode-tunnel.service > /dev/null <<EOF
[Unit]
Description=VS Code Tunnel
Documentation=https://code.visualstudio.com/docs/remote/tunnels
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/code tunnel --accept-server-license-terms --name $TUNNEL_NAME
Restart=always
RestartSec=10
User=$USER
Group=$USER
Environment=HOME=/home/$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable vscode-tunnel
log_success "Servicio systemd configurado"

# 5. Crear estructura de directorios para labs
log_info "📁 Creando estructura de directorios..."
mkdir -p ~/docker-kubernetes-labs/{docker-basics,kubernetes-basics,projects,exercises}

# Crear workspace
cat << 'EOF' > ~/docker-kubernetes-labs/docker-k8s.code-workspace
{
    "folders": [
        {
            "name": "🐳 Docker Labs",
            "path": "./docker-basics"
        },
        {
            "name": "☸️ Kubernetes Labs", 
            "path": "./kubernetes-basics"
        },
        {
            "name": "🚀 Projects",
            "path": "./projects"
        },
        {
            "name": "📝 Exercises",
            "path": "./exercises"
        }
    ],
    "settings": {
        "terminal.integrated.defaultProfile.linux": "bash",
        "docker.showStartPage": false,
        "files.autoSave": "afterDelay",
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true,
        "workbench.colorTheme": "Default Dark+",
        "terminal.integrated.fontSize": 14
    },
    "extensions": {
        "recommendations": [
            "ms-vscode.docker",
            "ms-kubernetes-tools.vscode-kubernetes-tools",
            "ms-python.python",
            "redhat.vscode-yaml",
            "ms-vscode.vscode-json"
        ]
    }
}
EOF

log_success "Estructura de directorios creada"

# 6. Crear archivos de ejemplo
log_info "📄 Creando archivos de ejemplo..."
cat << 'EOF' > ~/docker-kubernetes-labs/docker-basics/README.md
# 🐳 Docker Labs

¡Bienvenido a los laboratorios de Docker!

## 📚 Laboratorios Disponibles:

1. **[Primer Contenedor](../../../laboratorios/primer-contenedor-lab.md)** - Conceptos básicos
2. **[Imágenes Personalizadas](../../../laboratorios/imagenes-personalizadas-lab.md)** - Dockerfile y construcción
3. **[Volúmenes y Persistencia](../../../laboratorios/volumenes-persistencia-lab.md)** - Gestión de datos
4. **[Redes en Docker](../../../laboratorios/redes-docker-lab.md)** - Conectividad entre contenedores

## 🚀 Empezar:

```bash
# Verificar Docker
docker --version
docker run hello-world

# Abrir terminal integrada: Ctrl+Shift+`
# Ver laboratorios: Explorar panel izquierdo
```

¡Disfruta aprendiendo Docker! 🎉
EOF

cat << 'EOF' > ~/docker-kubernetes-labs/docker-basics/hello-docker.py
#!/usr/bin/env python3
"""
🐳 Ejemplo básico de aplicación para contenerizar
"""

from flask import Flask, jsonify
import os
import socket
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        'message': '¡Hola desde Docker! 🐳',
        'hostname': socket.gethostname(),
        'timestamp': datetime.now().isoformat(),
        'python_version': os.sys.version
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'hello-docker'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

# 7. Obtener IP pública para referencia
log_info "🌐 Obteniendo información del sistema..."
PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || echo "No disponible")

# 8. Configurar tunnel inicial (requiere interacción del usuario)
log_info "🔗 Configurando VS Code Tunnel..."
echo -e "\n${YELLOW}⚠️  CONFIGURACIÓN INTERACTIVA REQUERIDA:${NC}"
echo "   1. El tunnel requiere autenticación con GitHub o Microsoft"
echo "   2. Se abrirá un proceso interactivo"
echo "   3. Sigue las instrucciones en pantalla"
echo "   4. Una vez completado, presiona Ctrl+C y el servicio systemd tomará el control"
echo ""

read -p "¿Proceder con la configuración del tunnel? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Iniciando configuración del tunnel..."
    echo -e "${BLUE}Ejecuta el siguiente comando y sigue las instrucciones:${NC}"
    echo -e "${GREEN}code tunnel --accept-server-license-terms --name $TUNNEL_NAME${NC}"
    echo ""
    echo -e "${YELLOW}Después de completar la autenticación:${NC}"
    echo -e "1. Presiona ${RED}Ctrl+C${NC} para detener el proceso manual"
    echo -e "2. Ejecuta: ${GREEN}sudo systemctl start vscode-tunnel${NC}"
    echo -e "3. El tunnel estará disponible en: ${BLUE}https://vscode.dev/tunnel/$TUNNEL_NAME${NC}"
    echo ""
else
    log_warning "Configuración del tunnel pospuesta"
    echo -e "${YELLOW}Para configurar manualmente más tarde:${NC}"
    echo -e "1. ${GREEN}code tunnel --accept-server-license-terms --name $TUNNEL_NAME${NC}"
    echo -e "2. ${GREEN}sudo systemctl start vscode-tunnel${NC}"
fi

# 9. Crear script de información del sistema
cat << EOF > ~/system-info.sh
#!/bin/bash
echo "📊 INFORMACIÓN DEL SISTEMA"
echo "=========================="
echo "📅 Fecha: \$(date)"
echo "⏰ Uptime: \$(uptime -p)"
echo "💾 Memoria: \$(free -h | grep Mem | awk '{print \$3 "/" \$2}')"
echo "💽 Disco: \$(df -h / | tail -1 | awk '{print \$3 "/" \$2 " (" \$5 " usado)"}')"
echo "🐳 Docker: \$(systemctl is-active docker)"
echo "� VS Code Tunnel: \$(systemctl is-active vscode-tunnel)"
echo "🌐 IP Pública: $PUBLIC_IP"
echo ""
echo "🔗 ACCESO AL TUNNEL:"
echo "   URL Web: https://vscode.dev/tunnel/$TUNNEL_NAME"
echo "   URL Desktop: vscode://vscode.dev/tunnel/$TUNNEL_NAME"
echo ""
echo "🚀 COMANDOS ÚTILES:"
echo "   sudo systemctl status vscode-tunnel   # Estado del tunnel"
echo "   code tunnel status                    # Info del tunnel"
echo "   docker ps                            # Contenedores activos"
echo "   docker images                        # Imágenes disponibles"
echo "   htop                                 # Monitor del sistema"
EOF

chmod +x ~/system-info.sh

# Verificar estado final
log_info "🔍 Verificando instalación..."

if command -v code &> /dev/null; then
    log_success "✅ VS Code CLI está instalado: $(code --version | head -1)"
else
    log_error "❌ VS Code CLI no está instalado correctamente"
fi

if command -v docker &> /dev/null && docker ps &> /dev/null; then
    log_success "✅ Docker está funcionando correctamente"
else
    log_error "❌ Docker no está funcionando. Puede requerir logout/login para aplicar permisos de grupo"
fi

# Mostrar resumen final
echo -e "\n${GREEN}🎉 ¡INSTALACIÓN COMPLETADA! 🎉${NC}\n"

cat << EOF
┌─────────────────────────────────────────────────────────┐
│                    🎯 INFORMACIÓN DE ACCESO             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  🔗 Tunnel Name: $TUNNEL_NAME                              │
│  🌐 URL Web: https://vscode.dev/tunnel/$TUNNEL_NAME      │
│  💻 URL Desktop: vscode://vscode.dev/tunnel/$TUNNEL_NAME │
│  📁 Workspace: docker-k8s.code-workspace               │
│                                                         │
│  📚 Pasos siguientes:                                   │
│  1. Configurar tunnel: code tunnel --accept-server-... │
│  2. Iniciar servicio: sudo systemctl start vscode-... │
│  3. Acceder desde VS Code Desktop o Web                │
│  4. ¡Comienza con los laboratorios!                    │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                    🔧 COMANDOS ÚTILES                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ~/system-info.sh                    # Info del sistema │
│  sudo systemctl restart vscode-tunnel # Reiniciar      │
│  code tunnel status                   # Estado tunnel   │
│  docker --version                     # Verificar Docker │
│  code --version                       # Verificar CLI   │
│                                                         │
└─────────────────────────────────────────────────────────┘
EOF

echo -e "\n${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "   • No necesitas configurar firewall o NSG"
echo "   • La conexión es segura vía tunnel encriptado"
echo "   • Requiere autenticación con GitHub/Microsoft"
echo "   • Hacer logout/login si Docker no funciona"
echo ""

log_success "Script completado. ¡Disfruta programando! 🚀"