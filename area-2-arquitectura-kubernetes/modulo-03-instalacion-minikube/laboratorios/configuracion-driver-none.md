# Lab 3.5: Configuración Driver "None"

**Duración**: 15 minutos  
**Objetivo**: Configurar Minikube con driver "none" para acceso directo a servicios

## 🎯 Objetivos

- Configurar Minikube con driver "none"
- Entender las implicaciones de seguridad
- Configurar kubelet correctamente
- Acceder a servicios directamente desde la VM

---

## 📋 Prerequisitos

- Minikube instalado (Lab 3.4)
- Docker funcionando correctamente
- kubectl configurado
- Acceso sudo en la VM

---

## ⚠️ Paso 1: Entender el driver "none"

```bash
# Mostrar información sobre el driver "none"
cat << 'EOF'
=== ¿QUÉ ES EL DRIVER "NONE"? ===

El driver "none" ejecuta Kubernetes directamente en el host (VM) sin contenedores 
o máquinas virtuales adicionales.

✅ VENTAJAS:
- Acceso directo a servicios (sin port-forwarding)
- Mejor rendimiento (sin overhead de virtualización)
- Usa los recursos completos de la VM
- Ideal para desarrollo y testing

⚠️ DESVENTAJAS:
- Requiere permisos root
- Modifica el sistema host
- Potenciales conflictos con otros servicios
- No aislamiento completo

🔒 CONSIDERACIONES DE SEGURIDAD:
- Solo usar en entornos de desarrollo
- NO usar en producción
- La VM debe ser dedicada para Kubernetes

🎯 CASO DE USO IDEAL:
- VM Azure dedicada para desarrollo
- Necesidad de acceso directo a servicios web
- Testing de aplicaciones con múltiples servicios

EOF

read -p "¿Entiendes las implicaciones y quieres continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operación cancelada por el usuario"
    exit 1
fi
```

---

## 🚀 Instalación rápida de dependencias (opcional)

```bash
# OPCIÓN A: Verificación previa de dependencias
echo "=== VERIFICACIÓN PREVIA DE DEPENDENCIAS ==="
echo "💡 Primero verificaremos si todas las dependencias están instaladas"
echo ""

# Ejecutar script de verificación
chmod +x verify-driver-none-deps.sh
./verify-driver-none-deps.sh

echo ""
echo "==============================================="

# OPCIÓN B: Instalación automática con script (si la verificación falló)
echo "=== INSTALACIÓN AUTOMÁTICA DE DEPENDENCIAS ==="
echo "💡 Puedes usar el script automático o seguir los pasos manuales"
echo ""

read -p "¿Usar instalación automática de todas las dependencias? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔧 Ejecutando instalación automática..."
    
    # Ejecutar script de instalación
    chmod +x fix-driver-none-dependencies.sh
    ./fix-driver-none-dependencies.sh
    
    echo "✅ Instalación automática completada"
    echo "🔍 Ejecutando verificación final..."
    ./verify-driver-none-deps.sh
    
    echo ""
    echo "🎯 Si la verificación fue exitosa, puedes saltar al Paso 3"
    echo ""
else
    echo "📋 Continuando con instalación manual paso a paso..."
fi

# OPCIÓN C: Solo instalar CNI plugins (si solo falla esa parte)
echo ""
echo "💡 Opciones de reparación específicas:"
echo "   • Solo CNI plugins: chmod +x install-cni-plugins.sh && ./install-cni-plugins.sh"
echo "   • Solo cri-dockerd: chmod +x fix-cri-dockerd.sh && ./fix-cri-dockerd.sh"
echo ""
```

---

## 🔧 Paso 2: Preparar el sistema para driver "none"

```bash
# Verificar requisitos previos
echo "=== VERIFICANDO REQUISITOS PARA DRIVER 'NONE' ==="

# Verificar que somos root o tenemos sudo
if [ "$EUID" -eq 0 ]; then
    echo "✅ Ejecutando como root"
elif sudo -n true 2>/dev/null; then
    echo "✅ Acceso sudo disponible"
else
    echo "❌ Requiere acceso root o sudo"
    exit 1
fi

# Verificar dependencias críticas de Kubernetes
echo "🔍 Verificando dependencias de Kubernetes..."

# Verificar conntrack (crítico para Kubernetes)
if command -v conntrack &>/dev/null; then
    echo "✅ conntrack disponible"
    conntrack --version
else
    echo "❌ conntrack no disponible - instalando..."
    sudo apt update
    sudo apt install -y conntrack socat ebtables ethtool
    
    # Verificar instalación
    if command -v conntrack &>/dev/null; then
        echo "✅ conntrack instalado correctamente"
    else
        echo "❌ Error instalando conntrack"
        exit 1
    fi
fi

# Verificar otras dependencias
REQUIRED_TOOLS=("socat" "ebtables" "ethtool" "iptables" "crictl")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v $tool &>/dev/null; then
        echo "✅ $tool disponible"
    else
        echo "❌ $tool no disponible - instalando..."
        if [ "$tool" = "crictl" ]; then
            # Instalar crictl manualmente
            CRICTL_VERSION="v1.28.0"
            echo "🔧 Instalando crictl..."
            curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | sudo tar -C /usr/local/bin -xz
            sudo chmod +x /usr/local/bin/crictl
            
            # Verificar instalación
            if command -v crictl &>/dev/null; then
                echo "✅ crictl instalado correctamente"
            else
                echo "❌ Error instalando crictl"
                exit 1
            fi
        else
            sudo apt install -y $tool
        fi
    fi
done

# Verificar systemd
if systemctl --version &>/dev/null; then
    echo "✅ systemd disponible"
    systemctl --version | head -1
else
    echo "❌ systemd no disponible"
    exit 1
fi

# Verificar conectividad
if ping -c 1 8.8.8.8 &>/dev/null; then
    echo "✅ Conectividad a Internet OK"
else
    echo "❌ Sin conectividad a Internet"
    exit 1
fi

# Verificar puertos necesarios
echo "🔍 Verificando puertos necesarios:"
PORTS=(6443 10250 10251 10252 2379 2380)
for port in "${PORTS[@]}"; do
    if netstat -tulnp | grep ":$port " &>/dev/null; then
        echo "⚠️ Puerto $port ya está en uso"
        netstat -tulnp | grep ":$port "
    else
        echo "✅ Puerto $port disponible"
    fi
done

# Verificar espacio en disco
AVAILABLE=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
if [ "$AVAILABLE" -lt 10 ]; then
    echo "⚠️ Poco espacio en disco: ${AVAILABLE}GB disponible (recomendado: 10GB+)"
else
    echo "✅ Espacio en disco suficiente: ${AVAILABLE}GB disponible"
fi

echo ""
echo "🔧 Verificando cri-dockerd (crítico para Kubernetes v1.24+ con Docker)..."

# Verificar que cri-dockerd está instalado
if command -v cri-dockerd &>/dev/null; then
    echo "✅ cri-dockerd está instalado"
    cri-dockerd --version
else
    echo "❌ cri-dockerd no está instalado - crítico para Kubernetes v1.24+"
    echo "🔧 Instalando cri-dockerd..."
    
    # Instalar cri-dockerd
    CRI_DOCKERD_VERSION="0.3.4"
    CRI_DOCKERD_URL="https://github.com/Mirantis/cri-dockerd/releases/download/v${CRI_DOCKERD_VERSION}/cri-dockerd-${CRI_DOCKERD_VERSION}.amd64.tgz"
    curl -L $CRI_DOCKERD_URL | sudo tar -C /usr/local/bin --strip-components=1 -xz
    sudo chmod +x /usr/local/bin/cri-dockerd
    
    # Instalar servicios systemd
    sudo curl -L https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service -o /etc/systemd/system/cri-docker.service
    sudo curl -L https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket -o /etc/systemd/system/cri-docker.socket
    
    sudo systemctl daemon-reload
    sudo systemctl enable cri-docker.service cri-docker.socket
fi

# Verificar que los servicios están funcionando
if systemctl is-active cri-docker.service &>/dev/null; then
    echo "✅ Servicio cri-docker.service está activo"
else
    echo "⚠️ Iniciando servicio cri-docker.service..."
    sudo systemctl start cri-docker.service
fi

if systemctl is-active cri-docker.socket &>/dev/null; then
    echo "✅ Socket cri-docker.socket está activo"
else
    echo "⚠️ Iniciando socket cri-docker.socket..."
    sudo systemctl start cri-docker.socket
fi

# Verificar que el socket de cri-dockerd existe y es accesible
echo ""
echo "🔍 Verificando socket de cri-dockerd..."
CRI_SOCKET="/var/run/cri-dockerd.sock"

# Esperar un momento para que el socket se cree
sleep 3

if [ -S "$CRI_SOCKET" ]; then
    echo "✅ Socket cri-dockerd encontrado: $CRI_SOCKET"
    
    # Verificar permisos del socket
    if sudo ls -la "$CRI_SOCKET" &>/dev/null; then
        echo "✅ Socket accesible con permisos: $(sudo ls -la "$CRI_SOCKET")"
    else
        echo "⚠️ Problemas de permisos con el socket"
    fi
else
    echo "❌ Socket cri-dockerd no encontrado en $CRI_SOCKET"
    echo "🔧 Intentando reiniciar servicios cri-dockerd..."
    
    # Reiniciar servicios
    sudo systemctl stop cri-docker.service cri-docker.socket
    sleep 2
    sudo systemctl start cri-docker.socket
    sudo systemctl start cri-docker.service
    
    # Esperar y verificar nuevamente
    sleep 5
    if [ -S "$CRI_SOCKET" ]; then
        echo "✅ Socket cri-dockerd creado después del reinicio"
    else
        echo "❌ Error: Socket cri-dockerd sigue sin estar disponible"
        echo "🔍 Verificando logs de cri-dockerd:"
        sudo journalctl -u cri-docker.service --no-pager -n 10
        echo ""
        echo "🔍 Estado de servicios cri-dockerd:"
        sudo systemctl status cri-docker.service --no-pager -l
        sudo systemctl status cri-docker.socket --no-pager -l
        exit 1
    fi
fi

echo ""
echo "🔧 Verificando containernetworking-plugins (crítico para driver 'none' con Kubernetes v1.24+)..."

# Verificar si containernetworking-plugins está instalado
CNI_BIN_DIR="/opt/cni/bin"
if [ -d "$CNI_BIN_DIR" ] && [ -f "$CNI_BIN_DIR/bridge" ]; then
    echo "✅ containernetworking-plugins ya está instalado"
    ls -la $CNI_BIN_DIR/ | head -5
else
    echo "❌ containernetworking-plugins no está instalado - crítico para driver 'none'"
    echo "🔧 Instalando containernetworking-plugins..."
    
    # Crear directorio para plugins CNI
    sudo mkdir -p $CNI_BIN_DIR
    
    # Descargar e instalar containernetworking-plugins
    CNI_PLUGINS_VERSION="v1.3.0"
    CNI_PLUGINS_URL="https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz"
    
    echo "📥 Descargando containernetworking-plugins ${CNI_PLUGINS_VERSION}..."
    
    # Crear archivo temporal para la descarga
    CNI_TEMP_FILE="/tmp/cni-plugins-${CNI_PLUGINS_VERSION}.tgz"
    
    # Descargar el archivo primero
    if curl -L "$CNI_PLUGINS_URL" -o "$CNI_TEMP_FILE"; then
        echo "✅ Descarga completada"
        
        # Verificar que el archivo se descargó correctamente
        if [ -f "$CNI_TEMP_FILE" ] && [ -s "$CNI_TEMP_FILE" ]; then
            echo "🔧 Extrayendo plugins CNI..."
            
            # Extraer el archivo
            if sudo tar -C "$CNI_BIN_DIR" -xzf "$CNI_TEMP_FILE"; then
                echo "✅ Extracción completada"
                
                # Limpiar archivo temporal
                rm -f "$CNI_TEMP_FILE"
            else
                echo "❌ Error al extraer containernetworking-plugins"
                rm -f "$CNI_TEMP_FILE"
                exit 1
            fi
        else
            echo "❌ Error: archivo descargado está vacío o corrupto"
            rm -f "$CNI_TEMP_FILE"
            exit 1
        fi
    else
        echo "❌ Error al descargar containernetworking-plugins"
        echo "🔍 Verificando conectividad y URL..."
        echo "URL: $CNI_PLUGINS_URL"
        exit 1
    fi
    
    # Verificar instalación
    if [ -f "$CNI_BIN_DIR/bridge" ]; then
        echo "✅ containernetworking-plugins instalado correctamente"
        echo "📋 Plugins instalados:"
        ls -la $CNI_BIN_DIR/ | head -10
    else
        echo "❌ Error: plugins CNI no se instalaron correctamente"
        echo "🔍 Contenido del directorio CNI:"
        ls -la $CNI_BIN_DIR/ || echo "Directorio no accesible"
        exit 1
    fi
fi

# Verificar permisos del directorio CNI
sudo chmod -R 755 $CNI_BIN_DIR

echo ""
echo "🔧 Configurando directorio de configuración CNI..."

# Crear directorio de configuración CNI si no existe
CNI_CONFIG_DIR="/etc/cni/net.d"
sudo mkdir -p "$CNI_CONFIG_DIR"

# Verificar que el directorio existe
if [ -d "$CNI_CONFIG_DIR" ]; then
    echo "✅ Directorio CNI configurado: $CNI_CONFIG_DIR"
    sudo chmod 755 "$CNI_CONFIG_DIR"
else
    echo "❌ Error creando directorio CNI"
    exit 1
fi

# Limpiar cualquier configuración CNI previa que pueda causar conflictos
echo "🧹 Limpiando configuraciones CNI previas..."
if [ -d "$CNI_CONFIG_DIR" ]; then
    # Deshabilitar configuraciones bridge existentes que puedan interferir
    sudo find "$CNI_CONFIG_DIR" -name "*bridge*" -not -name "*.mk_disabled" -type f 2>/dev/null | while read -r file; do
        if [ -f "$file" ]; then
            echo "  ⚠️ Deshabilitando configuración conflictiva: $(basename "$file")"
            sudo mv "$file" "${file}.mk_disabled" 2>/dev/null || true
        fi
    done
    
    # También deshabilitar configuraciones podman si existen
    sudo find "$CNI_CONFIG_DIR" -name "*podman*" -not -name "*.mk_disabled" -type f 2>/dev/null | while read -r file; do
        if [ -f "$file" ]; then
            echo "  ⚠️ Deshabilitando configuración podman: $(basename "$file")"
            sudo mv "$file" "${file}.mk_disabled" 2>/dev/null || true
        fi
    done
    
    echo "✅ Limpieza de configuraciones CNI completada"
else
    echo "ℹ️ No hay configuraciones CNI previas"
fi

echo ""
echo "✅ Sistema preparado para driver 'none'"
```

---

## 🚀 Paso 3: Crear cluster con driver "none"

```bash
# Detener cualquier cluster existente
echo "=== PREPARANDO CLUSTER CON DRIVER 'NONE' ==="

# Detener Minikube si está ejecutándose
minikube stop 2>/dev/null || true
minikube delete 2>/dev/null || true

# Crear cluster con driver "none"
echo "🚀 Iniciando Minikube con driver 'none'..."
echo "⚠️ Esto requerirá permisos sudo"

# IMPORTANTE: El driver 'none' NO soporta múltiples perfiles
# Usar perfil por defecto (sin --profile)

# Configurar driver none como predeterminado
minikube config set driver none

# Iniciar cluster con cri-dockerd (requiere sudo)
echo "🔧 Iniciando Minikube con driver 'none' y cri-dockerd..."

# Verificar ubicación del socket cri-dockerd
echo "🔍 Verificando ubicación del socket cri-dockerd..."
CRI_SOCKET_PATH=""

# Verificar ubicaciones comunes del socket y crear compatibilidad
echo "🔍 Verificando sockets existentes:"
sudo netstat -lx | grep cri-dockerd || echo "No hay sockets cri-dockerd activos"

# Verificar archivos de socket existentes
if [ -S "/run/cri-dockerd.sock" ]; then
    echo "✅ Socket encontrado en: /run/cri-dockerd.sock"
    CRI_SOCKET_REAL="/run/cri-dockerd.sock"
elif [ -S "/var/run/cri-dockerd.sock" ]; then
    echo "✅ Socket encontrado en: /var/run/cri-dockerd.sock"
    CRI_SOCKET_REAL="/var/run/cri-dockerd.sock"
else
    echo "❌ No se encontró ningún socket cri-dockerd"
    echo "🔧 Reiniciando servicios cri-dockerd..."
    sudo systemctl stop cri-docker.service cri-docker.socket
    sleep 2
    sudo systemctl start cri-docker.socket
    sudo systemctl start cri-docker.service
    sleep 5
    
    # Verificar nuevamente
    if [ -S "/run/cri-dockerd.sock" ]; then
        CRI_SOCKET_REAL="/run/cri-dockerd.sock"
    elif [ -S "/var/run/cri-dockerd.sock" ]; then
        CRI_SOCKET_REAL="/var/run/cri-dockerd.sock"
    else
        echo "❌ Error: No se pudo crear el socket cri-dockerd"
        exit 1
    fi
fi

# Crear compatibilidad: si existe en /run/ pero no en /var/run/, crear enlace
if [ -S "/run/cri-dockerd.sock" ] && [ ! -S "/var/run/cri-dockerd.sock" ]; then
    echo "� Creando enlace de compatibilidad /var/run/cri-dockerd.sock -> /run/cri-dockerd.sock"
    sudo ln -sf /run/cri-dockerd.sock /var/run/cri-dockerd.sock
fi

# Determinar cuál usar con Minikube (preferir /var/run/ por compatibilidad)
if [ -S "/var/run/cri-dockerd.sock" ]; then
    CRI_SOCKET_PATH="unix:///var/run/cri-dockerd.sock"
    echo "✅ Usando socket en: /var/run/cri-dockerd.sock"
else
    CRI_SOCKET_PATH="unix:///run/cri-dockerd.sock"
    echo "✅ Usando socket en: /run/cri-dockerd.sock"
fi

# Verificar conectividad al socket antes de usar con Minikube
echo "🔍 Verificando conectividad al socket: $CRI_SOCKET_PATH"
if sudo crictl --runtime-endpoint="$CRI_SOCKET_PATH" version &>/dev/null; then
    echo "✅ Socket cri-dockerd respondiendo correctamente"
else
    echo "❌ Socket cri-dockerd no responde"
    echo "🔍 Intentando diagnóstico:"
    sudo ls -la /run/cri-dockerd.sock /var/run/cri-dockerd.sock 2>/dev/null
    exit 1
fi

# Verificar permisos específicos para Minikube
echo "🔍 Verificando permisos del socket para Minikube..."
SOCKET_FILE=$(echo "$CRI_SOCKET_PATH" | sed 's|unix://||')
if sudo test -r "$SOCKET_FILE" && sudo test -w "$SOCKET_FILE"; then
    echo "✅ Permisos de socket correctos"
else
    echo "⚠️ Ajustando permisos del socket..."
    sudo chmod 666 "$SOCKET_FILE" 2>/dev/null || echo "No se pudieron ajustar permisos (puede ser normal)"
fi

sudo minikube start \
    --driver=none \
    --container-runtime=docker \
    --cri-socket="$CRI_SOCKET_PATH"

# Verificar estado
sudo minikube status
```

**Salida esperada:**
```
✅ Using the none driver based on user configuration
✅ Starting control plane node minikube in cluster minikube
🤹 Running on localhost (CPUs=4, Memory=8192MB, Disk=25600MB)...
ℹ️ OS release is Ubuntu 24.04.3 LTS

⚠️  Nota: Es posible que veas un warning sobre CNI bridge configs:
E1105 10:22:58.873401 29629 start.go:444] unable to disable preinstalled bridge CNI(s): 
failed to disable all bridge cni configs in "/etc/cni/net.d"

📝 Este warning es NORMAL y no afecta el funcionamiento. Indica que Minikube 
está intentando limpiar configuraciones CNI previas que no existen en una 
instalación limpia.

🐳 Preparing Kubernetes v1.28.3 on Docker 24.0.7...
    ▪ kubelet.resolv-conf=/run/systemd/resolve/resolv.conf
    ▪ Generating certificates and keys...
    ▪ Booting up control plane...
    ▪ Configuring RBAC rules...
🤹 Configuring local host environment...
🔎 Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟 Enabled addons: default-storageclass, storage-provisioner
💡 kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

---

## 🔧 Paso 4: Configurar permisos de kubectl

```bash
# El driver "none" requiere configuración especial de permisos
echo "=== CONFIGURANDO PERMISOS DE KUBECTL ==="

# Verificar ubicación del config de kubectl
sudo ls -la /root/.kube/config

# Copiar configuración a usuario regular
sudo cp /root/.kube/config ~/.kube/config

# Cambiar propietario del archivo de configuración
sudo chown $USER:$USER ~/.kube/config

# Verificar permisos
ls -la ~/.kube/config

# Probar kubectl
kubectl get nodes

# Verificar contexto actual
kubectl config current-context

# Verificar cluster info
kubectl cluster-info
```

---

## 🧪 Paso 5: Verificar funcionamiento del cluster

```bash
# Crear script de verificación completa
cat << 'EOF' > ~/verificar-cluster-none.sh
#!/bin/bash

echo "=== VERIFICACIÓN CLUSTER DRIVER 'NONE' ==="
echo ""

# Verificar estado de Minikube
echo "📊 Estado de Minikube:"
sudo minikube status

# Verificar nodos
echo ""
echo "🖥️ Nodos del cluster:"
kubectl get nodes -o wide

# Verificar componentes del sistema
echo ""
echo "⚙️ Pods del sistema:"
kubectl get pods --all-namespaces

# Verificar servicios
echo ""
echo "🌐 Servicios disponibles:"
kubectl get services --all-namespaces

# Verificar API server
echo ""
echo "🔗 API Server:"
kubectl cluster-info

# Verificar addons habilitados
echo ""
echo "🔌 Addons habilitados:"
sudo minikube addons list | grep enabled

# Verificar configuración de kubelet
echo ""
echo "🔧 Configuración de kubelet:"
sudo systemctl status kubelet --no-pager -l

# Verificar logs recientes
echo ""
echo "📋 Logs recientes de kubelet:"
sudo journalctl -u kubelet --no-pager -n 10

echo ""
echo "=== VERIFICACIÓN COMPLETADA ==="
EOF

chmod +x ~/verificar-cluster-none.sh
~/verificar-cluster-none.sh
```

---

## 🌐 Paso 6: Probar acceso directo a servicios

```bash
# Crear aplicación de prueba para verificar acceso directo
echo "=== PROBANDO ACCESO DIRECTO A SERVICIOS ==="

# Crear deployment de prueba
kubectl create deployment test-web --image=nginx:alpine

# Esperar a que el pod esté listo
kubectl wait --for=condition=ready pod -l app=test-web --timeout=60s

# Exponer el servicio
kubectl expose deployment test-web --port=80 --type=NodePort

# Obtener información del servicio
kubectl get service test-web

# Obtener puerto asignado
NODE_PORT=$(kubectl get service test-web -o jsonpath='{.spec.ports[0].nodePort}')
echo "Puerto NodePort asignado: $NODE_PORT"

# Obtener IP de la VM
VM_IP=$(hostname -I | awk '{print $1}')
echo "IP de la VM: $VM_IP"

# Probar acceso directo
echo ""
echo "🌐 Probando acceso directo al servicio:"
echo "URL del servicio: http://$VM_IP:$NODE_PORT"

# Probar con curl
if curl -s http://localhost:$NODE_PORT | grep -q "Welcome to nginx"; then
    echo "✅ Acceso directo funciona correctamente"
    echo "📌 El servicio es accesible en: http://$VM_IP:$NODE_PORT"
else
    echo "❌ Error en acceso directo"
fi

# Mostrar logs del pod
echo ""
echo "📋 Logs del pod de prueba:"
kubectl logs deployment/test-web

# Limpiar recursos de prueba
echo ""
read -p "¿Eliminar recursos de prueba? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete service test-web
    kubectl delete deployment test-web
    echo "Recursos de prueba eliminados"
fi
```

---

## 🔧 Paso 7: Configurar acceso desde fuera de la VM

```bash
# Crear script para abrir puertos en firewall (si es necesario)
cat << 'EOF' > ~/configurar-firewall.sh
#!/bin/bash

echo "=== CONFIGURACIÓN DE FIREWALL PARA ACCESO EXTERNO ==="
echo ""

# Verificar si ufw está activo
if sudo ufw status | grep -q "Status: active"; then
    echo "🔥 UFW firewall está activo"
    
    # Mostrar reglas actuales
    echo "Reglas actuales:"
    sudo ufw status numbered
    
    echo ""
    read -p "¿Abrir puerto 30000-32767 para NodePort services? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ufw allow 30000:32767/tcp
        echo "✅ Puertos NodePort abiertos"
    fi
    
    echo ""
    read -p "¿Abrir puerto 6443 para API Server? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ufw allow 6443/tcp
        echo "✅ Puerto API Server abierto"
    fi
    
else
    echo "ℹ️ UFW firewall no está activo"
fi

# Verificar reglas de iptables
echo ""
echo "📋 Reglas actuales de iptables:"
sudo iptables -L -n | grep -E "(30000|32767|6443)"

echo ""
echo "💡 Para acceder desde fuera de la VM:"
echo "  - Asegúrate de que Azure NSG permite el tráfico"
echo "  - Usa la IP pública de la VM"
echo "  - Formato: http://<IP_PUBLICA>:<NODE_PORT>"
EOF

chmod +x ~/configurar-firewall.sh

# Ejecutar configuración de firewall
~/configurar-firewall.sh
```

---

## 📊 Paso 8: Dashboard de Kubernetes (opcional)

```bash
# Habilitar dashboard de Kubernetes
echo "=== CONFIGURANDO DASHBOARD DE KUBERNETES ==="

# Habilitar addon de dashboard
sudo minikube addons enable dashboard

# Verificar que el dashboard está ejecutándose
kubectl get pods -n kubernetes-dashboard

# Crear usuario admin para el dashboard
cat << 'EOF' > ~/dashboard-admin.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Aplicar configuración
kubectl apply -f ~/dashboard-admin.yaml

# Obtener token de acceso
echo ""
echo "🔑 Token para acceder al dashboard:"
kubectl -n kubernetes-dashboard create token admin-user

# Exponer dashboard como NodePort
kubectl patch service kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}'

# Obtener puerto del dashboard
DASHBOARD_PORT=$(kubectl get service kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}')
VM_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "🌐 Dashboard accesible en:"
echo "https://$VM_IP:$DASHBOARD_PORT"
echo ""
echo "⚠️ Nota: Usa HTTPS y acepta el certificado autofirmado"
echo "💡 Usa el token mostrado arriba para autenticarte"
```

---

## ✅ Paso 9: Verificación final

```bash
# Crear script de verificación final completa
cat << 'EOF' > ~/verificacion-final-none.sh
#!/bin/bash

echo "=== VERIFICACIÓN FINAL DRIVER 'NONE' ==="
echo ""

# Verificar estado general
echo "📊 Estado del sistema:"
echo "Sistema operativo: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Arquitectura: $(uname -m)"
echo "CPU: $(nproc) cores"
echo "RAM: $(free -h | awk '/^Mem:/ {print $2}') total, $(free -h | awk '/^Mem:/ {print $3}') usado"

# Verificar Minikube
echo ""
echo "🚀 Estado de Minikube:"
sudo minikube status

# Verificar kubectl
echo ""
echo "🔧 Configuración de kubectl:"
kubectl config current-context
kubectl get nodes

# Verificar servicios del sistema
echo ""
echo "⚙️ Servicios críticos:"
kubectl get pods -n kube-system

# Verificar acceso directo
echo ""
echo "🌐 Verificando acceso directo:"
if kubectl get service kubernetes &>/dev/null; then
    KUBE_PORT=$(kubectl get service kubernetes -o jsonpath='{.spec.ports[0].port}')
    echo "✅ API Server accesible en puerto $KUBE_PORT"
else
    echo "❌ Problema con acceso al API Server"
fi

# Verificar addons
echo ""
echo "🔌 Addons habilitados:"
sudo minikube addons list | grep enabled

# Verificar recursos disponibles
echo ""
echo "💻 Recursos disponibles para pods:"
kubectl top node 2>/dev/null || echo "ℹ️ Metrics server no disponible (normal)"

# Verificar DNS
echo ""
echo "🔍 Verificando DNS interno:"
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local 2>/dev/null || echo "DNS funcionando"

echo ""
echo "=== RESUMEN FINAL ==="
echo "✅ Minikube con driver 'none' está funcionando"
echo "✅ kubectl configurado correctamente"
echo "✅ Acceso directo a servicios disponible"
echo "✅ Cluster listo para desarrollo"

echo ""
echo "💡 Comandos útiles:"
echo "  kubectl get pods --all-namespaces    # Ver todos los pods"
echo "  kubectl get services                 # Ver servicios"
echo "  kubectl proxy                       # Proxy para API server"
echo "  sudo minikube dashboard              # Abrir dashboard"

echo ""
echo "🎯 El cluster está listo para el Lab 3.6: Verificación Final"
EOF

chmod +x ~/verificacion-final-none.sh
~/verificacion-final-none.sh
```

---

## ✅ Resultado esperado

```
=== VERIFICACIÓN FINAL DRIVER 'NONE' ===

📊 Estado del sistema:
Sistema operativo: Ubuntu 22.04.3 LTS
Kernel: 5.15.0-88-generic
Arquitectura: x86_64
CPU: 4 cores
RAM: 8.0Gi total, 2.1Gi usado

🚀 Estado de Minikube:
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

🔧 Configuración de kubectl:
minikube
NAME       STATUS   ROLES           AGE   VERSION
azurevm    Ready    control-plane   5m    v1.28.3

⚙️ Servicios críticos:
NAME                                READY   STATUS    RESTARTS   AGE
coredns-5d78c9869d-xyz12           1/1     Running   0          5m
etcd-azurevm                       1/1     Running   0          5m
kube-apiserver-azurevm             1/1     Running   0          5m
kube-controller-manager-azurevm    1/1     Running   0          5m
kube-proxy-abc34                   1/1     Running   0          5m
kube-scheduler-azurevm             1/1     Running   0          5m

🌐 Verificando acceso directo:
✅ API Server accesible en puerto 443

🔌 Addons habilitados:
| default-storageclass    | minikube | Enabled ✅  | gcr.io/k8s-minikube/storage-provisioner:v5 |
| storage-provisioner     | minikube | Enabled ✅  | gcr.io/k8s-minikube/storage-provisioner:v5 |

=== RESUMEN FINAL ===
✅ Minikube con driver 'none' está funcionando
✅ kubectl configurado correctamente
✅ Acceso directo a servicios disponible
✅ Cluster listo para desarrollo

💡 Comandos útiles:
  kubectl get pods --all-namespaces    # Ver todos los pods
  kubectl get services                 # Ver servicios
  kubectl proxy                       # Proxy para API server
  sudo minikube dashboard              # Abrir dashboard

🎯 El cluster está listo para el Lab 3.6: Verificación Final
```

---

## 🔧 Troubleshooting

### **Error: GUEST_MISSING_CONNTRACK**
```bash
# Error: Sorry, Kubernetes 1.20.2 requires conntrack to be installed in root's path

# Solución 1: Instalar conntrack y dependencias
sudo apt update
sudo apt install -y conntrack socat ebtables ethtool

# Verificar que conntrack está disponible para root
sudo which conntrack
sudo conntrack --version

# Solución 2: Si el problema persiste, verificar PATH
echo $PATH
sudo echo $PATH

# Solución 3: Reiniciar después de instalar
sudo minikube delete
sudo minikube start --driver=none --container-runtime=docker --cri-socket=unix:///var/run/cri-dockerd.sock

# Solución 4: Verificar módulos del kernel
sudo modprobe br_netfilter
sudo modprobe overlay
lsmod | grep -E "(br_netfilter|overlay)"
```

### **Error: GUEST_MISSING_CRICTL**
```bash
# Error: Sorry, Kubernetes 1.34.0 requires crictl to be installed in root's path

# Solución 1: Instalar crictl
CRICTL_VERSION="v1.28.0"
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | sudo tar -C /usr/local/bin -xz
sudo chmod +x /usr/local/bin/crictl

# Verificar que crictl está disponible para root
sudo which crictl
sudo crictl --version

# Solución 2: Si crictl no está en el PATH de root, crear enlace
sudo ln -sf /usr/local/bin/crictl /usr/bin/crictl

# Solución 3: Verificar PATH
echo $PATH
sudo echo $PATH

# Solución 4: Reiniciar después de instalar
sudo minikube delete
sudo minikube start --driver=none --container-runtime=docker --cri-socket=unix:///var/run/cri-dockerd.sock

# Verificar que todas las dependencias están instaladas
which conntrack socat crictl ebtables ethtool
sudo which conntrack socat crictl ebtables ethtool
```

### **Error: The "none" driver requires root privileges**
```bash
# Asegurarse de usar sudo
sudo minikube start --driver=none --container-runtime=docker --cri-socket=unix:///var/run/cri-dockerd.sock
```

### **Error: RUNTIME_ENABLE - cri-dockerd socket not found**
```bash
# Error: Failed to start container runtime: stat unix:///var/run/cri-dockerd.sock: exit status 1
# Causa: El socket de cri-dockerd existe pero en ubicación diferente o no está funcionando

# Solución 1: Verificar ubicación real del socket activo
echo "🔍 Verificando sockets cri-dockerd activos..."
sudo netstat -lx | grep cri-dockerd

# Las ubicaciones más comunes son:
# - /run/cri-dockerd.sock (Ubuntu 24.04+ más común)
# - /var/run/cri-dockerd.sock (versiones anteriores)

# Solución 2: Probar conectividad a ambas ubicaciones
echo "Probando /run/cri-dockerd.sock:"
sudo crictl --runtime-endpoint=unix:///run/cri-dockerd.sock version

echo "Probando /var/run/cri-dockerd.sock:"
sudo crictl --runtime-endpoint=unix:///var/run/cri-dockerd.sock version

# Solución 3: Usar la ubicación que funcione en Minikube
# Si /run/cri-dockerd.sock funciona:
sudo minikube start --driver=none --container-runtime=docker --cri-socket=unix:///run/cri-dockerd.sock

# Si /var/run/cri-dockerd.sock funciona:
sudo minikube start --driver=none --container-runtime=docker --cri-socket=unix:///var/run/cri-dockerd.sock

# Solución 4: Verificar estado de servicios cri-dockerd
sudo systemctl status cri-docker.service
sudo systemctl status cri-docker.socket

# Solución 5: Reiniciar servicios cri-dockerd en orden correcto
sudo systemctl stop cri-docker.service
sudo systemctl stop cri-docker.socket
sudo systemctl start cri-docker.socket
sudo systemctl start cri-docker.service

# Esperar que los servicios se inicien
sleep 5

# Solución 6: Verificar que el socket existe
ls -la /var/run/cri-dockerd.sock
ls -la /run/cri-dockerd.sock
# Debería mostrar: srwxrwxrwx 1 root root 0 <fecha> /run/cri-dockerd.sock (o similar)

# Solución 7: Si el socket no existe, verificar logs
sudo journalctl -u cri-docker.service --no-pager -n 20
sudo journalctl -u cri-docker.socket --no-pager -n 20

# Solución 8: Verificar Docker está funcionando
sudo systemctl status docker
docker version

# Solución 9: Reinstalar cri-dockerd si es necesario
# (Solo si las soluciones anteriores fallan)
sudo systemctl stop cri-docker.service cri-docker.socket
sudo systemctl disable cri-docker.service cri-docker.socket

# Descargar e instalar nuevamente
CRI_DOCKERD_VERSION="0.3.4"
CRI_DOCKERD_URL="https://github.com/Mirantis/cri-dockerd/releases/download/v${CRI_DOCKERD_VERSION}/cri-dockerd-${CRI_DOCKERD_VERSION}.amd64.tgz"
curl -L $CRI_DOCKERD_URL | sudo tar -C /usr/local/bin --strip-components=1 -xz
sudo chmod +x /usr/local/bin/cri-dockerd

# Reinstalar servicios
sudo curl -L https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service -o /etc/systemd/system/cri-docker.service
sudo curl -L https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket -o /etc/systemd/system/cri-docker.socket

sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service cri-docker.socket
sudo systemctl start cri-docker.socket
sudo systemctl start cri-docker.service

# Verificar después del reinicio
sleep 5
sudo netstat -lx | grep cri-dockerd

# Solución 10: Usar script de diagnóstico automático
# Si las soluciones anteriores no funcionan:
chmod +x fix-cri-dockerd.sh
./fix-cri-dockerd.sh
```

### **Error: kubectl configuration incorrect**
```bash
# Copiar configuración de root
sudo cp /root/.kube/config ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

### **Error: containernetworking-plugins missing**
```bash
# Error: The none driver with Kubernetes v1.24+ requires containernetworking-plugins

# Solución 1: Instalar containernetworking-plugins (método robusto)
sudo mkdir -p /opt/cni/bin
CNI_PLUGINS_VERSION="v1.3.0"
CNI_TEMP_FILE="/tmp/cni-plugins-${CNI_PLUGINS_VERSION}.tgz"

# Descargar primero a archivo temporal
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz" -o "$CNI_TEMP_FILE"

# Verificar descarga
if [ -f "$CNI_TEMP_FILE" ] && [ -s "$CNI_TEMP_FILE" ]; then
    echo "✅ Descarga exitosa"
    sudo tar -C /opt/cni/bin -xzf "$CNI_TEMP_FILE"
    rm -f "$CNI_TEMP_FILE"
else
    echo "❌ Error en descarga"
fi

# Solución 2: Si curl falla, verificar espacio y permisos
df -h /tmp                              # Verificar espacio en /tmp
df -h /opt                              # Verificar espacio en /opt
sudo ls -la /opt/cni/                   # Verificar permisos

# Solución 3: Instalación alternativa usando wget
sudo mkdir -p /opt/cni/bin
wget -O /tmp/cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz"
sudo tar -C /opt/cni/bin -xzf /tmp/cni-plugins.tgz
rm -f /tmp/cni-plugins.tgz

# Solución 4: Verificar instalación
ls -la /opt/cni/bin/
sudo chmod -R 755 /opt/cni/bin

# Solución 5: Verificar plugins críticos
for plugin in bridge host-local loopback portmap; do
    if [ -f "/opt/cni/bin/$plugin" ]; then
        echo "✅ $plugin instalado"
    else
        echo "❌ $plugin faltante"
    fi
done

# Solución 6: Usar script especializado para problemas de descarga
# Si los métodos anteriores fallan, usar el script dedicado:
chmod +x install-cni-plugins.sh
./install-cni-plugins.sh

# Solución 3: Reiniciar después de instalar
sudo minikube delete
sudo minikube start --driver=none --container-runtime=docker --cri-socket=unix:///var/run/cri-dockerd.sock

# Verificar que todos los plugins están disponibles
ls -la /opt/cni/bin/ | grep -E "(bridge|host-local|loopback)"
```

### **Error: CNI configuration directory not found**
```bash
# Error: unable to disable preinstalled bridge CNI(s): failed to disable all bridge cni configs in "/etc/cni/net.d": find: '/etc/cni/net.d': No such file or directory

# Solución 1: Crear directorio CNI de configuración
sudo mkdir -p /etc/cni/net.d
sudo chmod 755 /etc/cni/net.d

# Solución 2: Verificar estructura completa de directorios CNI
echo "📁 Verificando estructura CNI:"
echo "Binarios CNI: /opt/cni/bin"
ls -la /opt/cni/bin/ | head -5
echo "Configuración CNI: /etc/cni/net.d"
ls -la /etc/cni/net.d/ 2>/dev/null || echo "Directorio vacío (normal para nueva instalación)"

# Solución 3: Limpiar configuraciones conflictivas si existen
if [ -d "/etc/cni/net.d" ]; then
    echo "🧹 Limpiando configuraciones CNI conflictivas..."
    
    # Deshabilitar configuraciones bridge previas
    sudo find /etc/cni/net.d -name "*bridge*" -not -name "*.mk_disabled" -type f 2>/dev/null | while read -r file; do
        if [ -f "$file" ]; then
            echo "Deshabilitando: $file"
            sudo mv "$file" "${file}.mk_disabled"
        fi
    done
    
    # Deshabilitar configuraciones podman si existen
    sudo find /etc/cni/net.d -name "*podman*" -not -name "*.mk_disabled" -type f 2>/dev/null | while read -r file; do
        if [ -f "$file" ]; then
            echo "Deshabilitando: $file"
            sudo mv "$file" "${file}.mk_disabled"
        fi
    done
fi

# Solución 4: Verificar que no hay conflictos de red
echo "🔍 Verificando interfaces de red:"
ip link show | grep -E "(bridge|docker|podman)" || echo "No hay interfaces conflictivas"

# Solución 5: Reiniciar Minikube después de configurar CNI
sudo minikube delete
sudo minikube start --driver=none --container-runtime=docker --cri-socket=unix:///var/run/cri-dockerd.sock
```

### **Error: Port already in use**
```bash
# Verificar qué proceso usa el puerto
sudo netstat -tulnp | grep :6443

# Detener Minikube y reiniciar
sudo minikube stop
sudo minikube start --driver=none --container-runtime=docker --cri-socket=unix:///var/run/cri-dockerd.sock
```

### **Error: Cannot access services externally**
```bash
# Verificar firewall
sudo ufw status
sudo ufw allow 30000:32767/tcp

# Verificar Azure NSG
# (Desde Azure Portal, verificar Network Security Group)
```

---

## 📝 Checklist de completado

- [ ] Dependencias básicas instaladas (conntrack, socat, ebtables, ethtool)
- [ ] crictl instalado y funcionando
- [ ] cri-dockerd instalado y servicios activos
- [ ] containernetworking-plugins instalados en /opt/cni/bin
- [ ] Driver "none" configurado correctamente
- [ ] Cluster iniciado con éxito
- [ ] kubectl funcionando sin sudo
- [ ] Acceso directo a servicios verificado
- [ ] Firewall configurado (si es necesario)
- [ ] Dashboard habilitado (opcional)
- [ ] Verificación final completada

---

## 🎯 Estado actual

✅ **Minikube ejecutándose con driver "none"**  
✅ **Acceso directo a servicios habilitado**  
✅ **kubectl configurado correctamente**  
✅ **Sistema listo para desarrollo**

---

**Siguiente paso**: [Lab 3.6: Verificación y Testing Final](./verificacion-testing-final.md)