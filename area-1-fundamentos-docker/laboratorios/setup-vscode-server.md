# 🖥️ Configuración de VS Code Tunnel en Azure VM

**Objetivo**: Instalar y configurar Visual Studio Code CLI con tunnel en una VM de Azure para acceso remoto seguro  
**Duración**: 15-20 minutos  
**Prerequisitos**: VM de Azure con Ubuntu 20.04/22.04

---

## 🎯 ¿Por qué VS Code Tunnel?

- **Acceso seguro desde cualquier lugar**: Sin configuración de puertos o firewall
- **Autenticación con GitHub/Microsoft**: Sin contraseñas adicionales que gestionar
- **Sincronización automática**: Extensions, configuración y settings
- **Conexión cifrada**: Túnel seguro a través de Microsoft/GitHub
- **Sin infraestructura adicional**: No requiere configurar reverse proxy o certificados

---

## 📋 Prerequisitos

### **VM de Azure recomendada:**
- **OS**: Ubuntu 22.04 LTS
- **Tamaño**: Standard_B2s (2 vCPUs, 4 GB RAM) mínimo
- **Almacenamiento**: 30 GB SSD
- **Red**: ¡No necesita puertos adicionales abiertos! 🎉

### **Cuenta requerida:**
- **GitHub** o **Microsoft Account** para autenticación del tunnel
### **Verificar acceso SSH:**
```bash
# Desde tu terminal local
ssh azureuser@TU-IP-PUBLICA

# Si tienes problemas de SSH, usa Azure Cloud Shell
```

---

## 🚀 Instalación Paso a Paso

### **Paso 1: Conectar a la VM**

```bash
# Opción A: SSH directo
ssh azureuser@YOUR-VM-IP

# Opción B: Azure Cloud Shell
# 1. Ve al Portal de Azure
# 2. Clic en Cloud Shell (icono >_)
# 3. ssh azureuser@YOUR-VM-IP
```

### **Paso 2: Actualizar el sistema**

```bash
# Actualizar paquetes
sudo apt update && sudo apt upgrade -y

# Instalar dependencias básicas
sudo apt install -y curl wget git unzip software-properties-common
```

### **Paso 3: Instalar Docker (necesario para los labs)**

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Aplicar cambios de grupo
newgrp docker

# Verificar instalación
docker --version
docker run hello-world
```

### **Paso 4: Instalar VS Code CLI**

```bash
# Descargar VS Code CLI
curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz

# Extraer el CLI
tar -xf vscode_cli.tar.gz

# Mover a ubicación global
sudo mv code /usr/local/bin/

# Verificar instalación
code --version
```

### **Paso 5: Configurar VS Code Tunnel**

```bash
# Iniciar tunnel con nombre personalizado
code tunnel --accept-server-license-terms --name "docker-k8s-lab-$(whoami)"

# El comando te mostrará:
# 1. Un enlace para autorizar con GitHub/Microsoft
# 2. Un código de dispositivo
# 3. La URL del tunnel una vez configurado
```

**Durante la configuración verás algo como:**
```
To grant access to the server, please log into https://github.com/login/device 
and use code: XXXX-XXXX
```

1. **Abre el enlace** en tu navegador local
2. **Introduce el código** mostrado
3. **Autoriza la aplicación** con tu cuenta GitHub/Microsoft
4. **¡Listo!** El tunnel estará activo

### **Paso 6: Crear servicio systemd para tunnel persistente**

```bash
# Crear archivo de servicio
sudo tee /etc/systemd/system/vscode-tunnel.service > /dev/null <<EOF
[Unit]
Description=VS Code Tunnel
Documentation=https://code.visualstudio.com/docs/remote/tunnels
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/code tunnel --accept-server-license-terms --name docker-k8s-lab-$(whoami)
Restart=always
RestartSec=10
User=$USER
Group=$USER
Environment=HOME=/home/$USER

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd
sudo systemctl daemon-reload

# Habilitar servicio (se iniciará después del primer setup manual)
sudo systemctl enable vscode-tunnel

# NOTA: No iniciar aún - primero hay que completar la autenticación manual
```

---

## 🔧 Configuración Avanzada

### **Completar configuración automática del tunnel:**

```bash
# Una vez completada la autenticación manual la primera vez:
# Detener el tunnel manual (Ctrl+C)

# Iniciar el servicio systemd
sudo systemctl start vscode-tunnel

# Verificar que está funcionando
sudo systemctl status vscode-tunnel

# Ver logs en tiempo real
sudo journalctl -u vscode-tunnel -f
```

### **Configuración de workspace:**

```bash
# Crear directorio para los labs
mkdir -p ~/docker-kubernetes-labs
cd ~/docker-kubernetes-labs

# Crear estructura de directorios
mkdir -p {docker-basics,kubernetes-basics,projects,exercises}

# Crear archivo de configuración del workspace
cat << 'EOF' > docker-k8s.code-workspace
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
        }
    ],
    "settings": {
        "terminal.integrated.defaultProfile.linux": "bash",
        "docker.showStartPage": false,
        "files.autoSave": "afterDelay",
        "editor.formatOnSave": true,
        "workbench.colorTheme": "Default Dark+"
    },
    "extensions": {
        "recommendations": [
            "ms-vscode.docker",
            "ms-kubernetes-tools.vscode-kubernetes-tools",
            "ms-python.python",
            "redhat.vscode-yaml"
        ]
    }
}
EOF
```

---

## 🔐 Ventajas de Seguridad del Tunnel

### **1. Sin configuración de firewall:**
- No necesitas abrir puertos en Azure NSG
- El tunnel se conecta de salida (outbound) solamente
- Conexión cifrada de extremo a extremo

### **2. Autenticación robusta:**
- Usa tu cuenta GitHub o Microsoft existente
- Sin contraseñas adicionales que gestionar
- Token de acceso renovable automáticamente

### **3. Gestión centralizada:**
- Manage tunnels desde https://vscode.dev/tunnels
- Revoca acceso desde el portal web
- Historial de conexiones y actividad

---

## 🌍 Acceso al Tunnel

### **1. Obtener URL del tunnel:**

Una vez configurado, verás algo como:
```
Open in VS Code Desktop: vscode://vscode.dev/tunnel/docker-k8s-lab-azureuser
Web UI: https://vscode.dev/tunnel/docker-k8s-lab-azureuser
```

### **2. Opciones de acceso:**

#### **Opción A: VS Code Desktop (Recomendado)**
1. **Tener VS Code instalado** localmente
2. **Clic en el enlace** `vscode://vscode.dev/tunnel/...`
3. **Automáticamente abre** VS Code Desktop conectado al tunnel

#### **Opción B: VS Code Web**
1. **Abrir navegador** en `https://vscode.dev/tunnel/docker-k8s-lab-azureuser`
2. **Autenticarse** con la misma cuenta (GitHub/Microsoft)
3. **¡Listo!** VS Code ejecutándose en el navegador

#### **Opción C: VS Code Mobile**
- **VS Code para tablets** funciona con los tunnels
- **Experiencia táctil** optimizada para touch

---

## 🛠️ Troubleshooting

### **Error: "Failed to connect to tunnel"**

```bash
# Verificar que el servicio está ejecutándose
sudo systemctl status vscode-tunnel

# Ver logs del servicio
sudo journalctl -u vscode-tunnel -f

# Reiniciar tunnel manualmente para debug
code tunnel --accept-server-license-terms --name docker-k8s-lab-$(whoami) --verbose
```

### **Error: "Authentication failed"**

```bash
# Limpiar tokens existentes
rm -rf ~/.vscode-cli

# Reiniciar proceso de autenticación
code tunnel --accept-server-license-terms --name docker-k8s-lab-$(whoami)
```

### **Error: "Tunnel name already in use"**

```bash
# Usar nombre único con timestamp
TUNNEL_NAME="docker-k8s-lab-$(whoami)-$(date +%s)"
code tunnel --accept-server-license-terms --name $TUNNEL_NAME
```

### **Tunnel se desconecta frecuentemente**

```bash
# Verificar conectividad de red
ping -c 4 8.8.8.8

# Verificar logs del sistema
sudo journalctl -u vscode-tunnel --since "10 minutes ago"

# Aumentar timeout del servicio systemd
sudo systemctl edit vscode-tunnel
# Agregar:
# [Service]
# Restart=always
# RestartSec=5
```

```

---

## 📱 Gestión de Tunnels

### **Portal web de gestión:**
- **URL**: https://vscode.dev/tunnels
- **Funciones**:
  - Ver tunnels activos
  - Revocar acceso
  - Gestionar nombres
  - Historial de conexiones

### **Comandos de gestión:**

```bash
# Listar tunnels activos
code tunnel status

# Renombrar tunnel
code tunnel rename NUEVO-NOMBRE

# Eliminar tunnel
code tunnel unregister

# Ver información del tunnel actual
code tunnel show
```

---

## 📱 Acceso desde Dispositivos Móviles

VS Code Tunnel funciona perfectamente en dispositivos móviles:

1. **iPad/iPhone**: Safari o VS Code app
2. **Android**: Chrome o VS Code app
3. **Tablets**: Experiencia completa con teclado virtual
4. **Chromebooks**: Funciona nativamente

### **Error: "Password incorrect"**

```bash
# Verificar contraseña en configuración
cat ~/.config/code-server/config.yaml

# Ver logs para más detalles
sudo journalctl -u code-server --since "5 minutes ago"
```

### **Error: "Cannot reach this page"**

```bash
# Verificar NSG en Azure Portal
# Asegurar que puerto 8080 está abierto

# Verificar IP pública
az vm show -d -g YOUR-RESOURCE-GROUP -n YOUR-VM-NAME --query publicIps -o tsv
```

### **Rendimiento lento**

```bash
# Verificar recursos de la VM
htop
# O
top

# Verificar uso de disco
df -h

# Aumentar tamaño de VM si es necesario
```

---

## 📱 Acceso desde Dispositivos Móviles

VS Code Server también funciona en tablets y smartphones:

1. **iPad/iPhone**: Safari funciona perfectamente
2. **Android**: Chrome o Firefox
3. **Recomendación**: Usar en modo landscape para mejor experiencia

---

## 🔄 Mantenimiento y Actualizaciones

### **Actualizar code-server:**

```bash
# Detener servicio
sudo systemctl stop code-server

# Actualizar
curl -fsSL https://code-server.dev/install.sh | sh

# Reiniciar servicio
sudo systemctl start code-server
```

### **Monitoreo del sistema:**

```bash
# Script de monitoreo
cat << 'EOF' > ~/monitor-system.sh
#!/bin/bash
echo "=== System Status ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Memory: $(free -h | grep Mem)"
echo "Disk: $(df -h / | tail -1)"
echo "Code-server: $(systemctl is-active code-server)"
echo "Docker: $(systemctl is-active docker)"
echo "========================"
EOF

chmod +x ~/monitor-system.sh
```

---

## 📚 Recursos Adicionales

### **Documentación oficial:**
- [code-server GitHub](https://github.com/coder/code-server)
- [VS Code Extensions](https://marketplace.visualstudio.com/vscode)

### **Comandos útiles de referencia rápida:**

```bash
# Gestión del servicio
sudo systemctl status code-server    # Ver estado
sudo systemctl restart code-server   # Reiniciar
sudo systemctl logs code-server      # Ver logs

# Gestión de extensiones
code-server --list-extensions        # Listar instaladas
code-server --install-extension X    # Instalar extensión
code-server --uninstall-extension X  # Desinstalar

# Información del sistema
curl ifconfig.me                     # IP pública
docker ps                           # Contenedores activos
docker images                       # Imágenes disponibles
```

---

## ✅ Verificación Final

Antes de comenzar los laboratorios, verifica que todo funciona:

- [ ] VS Code accesible desde navegador
- [ ] Terminal funciona correctamente
- [ ] Docker instalado y funcional
- [ ] Extensiones necesarias instaladas
- [ ] Workspace configurado
- [ ] Backup configurado

---

## 🎉 ¡Listo para los Laboratorios!

Ahora tienes un entorno de desarrollo completo y potente ejecutándose en Azure, accesible desde cualquier navegador. Los estudiantes pueden:

- **Trabajar desde cualquier lugar** con solo una conexión a internet
- **Tener un entorno consistente** sin problemas de configuración local
- **Colaborar fácilmente** compartiendo enlaces y configuraciones
- **Aprovechar la potencia de Azure** para ejecutar contenedores y clusters

**Próximo paso**: [Comenzar con el Lab M2.1: Primer Contenedor](./primer-contenedor-lab.md)

---

**💡 Tip para instructores**: Pueden preparar una imagen de VM con todo preconfigurado y distribuirla a los estudiantes para un setup aún más rápido.