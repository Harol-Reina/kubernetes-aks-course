#!/bin/bash

# 🔗 Script de Configuración Rápida del VS Code Tunnel
# Uso: ./setup-tunnel.sh [nombre-del-tunnel]

set -e

# Colores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuración
TUNNEL_NAME=${1:-"docker-k8s-lab-$USER"}

echo -e "${BLUE}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   🔗 CONFIGURACIÓN RÁPIDA DE VS CODE TUNNEL             ║
║                                                          ║
║   Este script te ayudará a configurar el tunnel         ║
║   y el servicio systemd en unos pocos pasos.            ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}📋 Configuración:${NC}"
echo "   Tunnel Name: $TUNNEL_NAME"
echo "   Usuario: $USER"
echo ""

# Verificar que VS Code CLI está instalado
if ! command -v code &> /dev/null; then
    echo -e "${RED}❌ VS Code CLI no está instalado.${NC}"
    echo "Ejecuta primero: ./install-vscode-server.sh"
    exit 1
fi

echo -e "${GREEN}✅ VS Code CLI encontrado: $(code --version | head -1)${NC}"

# Paso 1: Configurar tunnel inicial
echo -e "\n${BLUE}🔧 Paso 1: Configuración inicial del tunnel${NC}"
echo "Esto abrirá un navegador para autenticación con GitHub/Microsoft"
echo ""
read -p "¿Continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Configuración cancelada."
    exit 0
fi

echo -e "${YELLOW}Ejecutando tunnel inicial...${NC}"
echo "Sigue las instrucciones en pantalla para autenticarte."
echo "Una vez completado, presiona Ctrl+C para continuar con el setup automático."
echo ""

# Ejecutar tunnel manual para setup inicial
code tunnel --accept-server-license-terms --name "$TUNNEL_NAME" &
TUNNEL_PID=$!

# Esperar a que el usuario complete la configuración
echo -e "${GREEN}Presiona Enter cuando hayas completado la autenticación y quieras continuar...${NC}"
read -r

# Matar el proceso manual del tunnel
kill $TUNNEL_PID 2>/dev/null || true
wait $TUNNEL_PID 2>/dev/null || true

# Paso 2: Configurar servicio systemd
echo -e "\n${BLUE}🔧 Paso 2: Configurando servicio systemd${NC}"

# Verificar si el servicio ya existe
if systemctl list-unit-files | grep -q vscode-tunnel.service; then
    echo -e "${YELLOW}⚠️  Servicio vscode-tunnel ya existe${NC}"
    read -p "¿Reconfigurar? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl stop vscode-tunnel 2>/dev/null || true
        sudo systemctl disable vscode-tunnel 2>/dev/null || true
    else
        echo "Manteniendo configuración existente."
        echo -e "${GREEN}Para iniciar el servicio: sudo systemctl start vscode-tunnel${NC}"
        exit 0
    fi
fi

# Crear servicio systemd
echo "Creando servicio systemd..."
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

# Recargar systemd y habilitar servicio
sudo systemctl daemon-reload
sudo systemctl enable vscode-tunnel

echo -e "${GREEN}✅ Servicio systemd configurado${NC}"

# Paso 3: Iniciar servicio
echo -e "\n${BLUE}🔧 Paso 3: Iniciando servicio${NC}"
sudo systemctl start vscode-tunnel

# Verificar estado
sleep 3
if systemctl is-active --quiet vscode-tunnel; then
    echo -e "${GREEN}✅ Tunnel activo y funcionando${NC}"
else
    echo -e "${RED}❌ Error al iniciar el tunnel${NC}"
    echo "Ver logs: sudo journalctl -u vscode-tunnel -f"
    exit 1
fi

# Mostrar información de acceso
echo -e "\n${GREEN}🎉 ¡CONFIGURACIÓN COMPLETADA! 🎉${NC}\n"

cat << EOF
┌─────────────────────────────────────────────────────────┐
│                    🎯 INFORMACIÓN DE ACCESO             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  🔗 Tunnel Name: $TUNNEL_NAME                            │
│  🌐 URL Web: https://vscode.dev/tunnel/$TUNNEL_NAME     │
│  💻 URL Desktop: vscode://vscode.dev/tunnel/$TUNNEL_NAME│
│                                                         │
│  📁 Workspace: ~/docker-kubernetes-labs/               │
│               docker-k8s.code-workspace                │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                    🔧 COMANDOS ÚTILES                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  sudo systemctl status vscode-tunnel  # Estado         │
│  sudo systemctl restart vscode-tunnel # Reiniciar      │
│  code tunnel status                    # Info tunnel    │
│  ~/system-info.sh                     # Info sistema   │
│                                                         │
└─────────────────────────────────────────────────────────┘
EOF

echo -e "\n${BLUE}🚀 EMPEZAR:${NC}"
echo "1. Abre VS Code Desktop y usa: vscode://vscode.dev/tunnel/$TUNNEL_NAME"
echo "2. O abre el navegador en: https://vscode.dev/tunnel/$TUNNEL_NAME"
echo "3. Abre el workspace: docker-k8s.code-workspace"
echo "4. ¡Comienza con los laboratorios!"
echo ""

echo -e "${GREEN}¡Disfruta aprendiendo Docker y Kubernetes! 🐳☸️${NC}"