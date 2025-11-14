# Lab 3.5: Configuración Driver "Docker"

**Duración**: 10 minutos  
**Objetivo**: Configurar Minikube con driver "docker" para desarrollo fácil y estable

## 🎯 Objetivos

- Configurar Minikube con driver "docker"
- Entender las ventajas del driver docker
- Configurar port-forwarding para acceso a servicios
- Gestionar el cluster de forma segura y aislada

---

## 📋 Prerequisitos

- Minikube instalado (Lab 3.4)
- Docker funcionando correctamente
- kubectl configurado
- Usuario en grupo docker

---

## ⚠️ Paso 1: Entender el driver "docker"

```bash
# Mostrar información sobre el driver "docker"
cat << 'EOF'
=== ¿QUÉ ES EL DRIVER "DOCKER"? ===

El driver "docker" ejecuta Kubernetes dentro de un contenedor Docker,
proporcionando aislamiento completo del sistema host.

✅ VENTAJAS:
- Aislamiento completo del sistema host
- No requiere permisos root para operaciones normales
- Fácil limpieza (solo eliminar contenedor)
- Compatible con Docker Desktop
- Muy estable y bien mantenido
- Ideal para desarrollo local

⚠️ CONSIDERACIONES:
- Requiere port-forwarding para acceso externo
- Usa recursos de Docker (pero eficientemente)
- Perfecto aislamiento de red

🔒 VENTAJAS DE SEGURIDAD:
- No modifica el sistema host
- Kubernetes aislado en contenedor
- Fácil de resetear completamente
- Sin conflictos con otros servicios

🎯 CASO DE USO IDEAL:
- Desarrollo local de aplicaciones Kubernetes
- Aprendizaje de Kubernetes
- Testing de manifiestos
- Entornos de desarrollo personal

EOF

read -p "¿Entiendes las ventajas y quieres continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operación cancelada por el usuario"
    exit 1
fi
```

---

## 🚀 Paso 2: Verificar requisitos para driver "docker"

```bash
# Verificar requisitos para driver docker
echo "=== VERIFICANDO REQUISITOS PARA DRIVER 'DOCKER' ==="

# Verificar que Docker está funcionando
if docker version &>/dev/null; then
    echo "✅ Docker está funcionando"
    docker version | head -10
else
    echo "❌ Docker no está funcionando correctamente"
    echo "🔧 Iniciando Docker..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Verificar nuevamente
    if docker version &>/dev/null; then
        echo "✅ Docker iniciado correctamente"
    else
        echo "❌ Error: Docker no funciona. Instala Docker primero."
        exit 1
    fi
fi

# Verificar que el usuario está en el grupo docker
if groups | grep -q docker; then
    echo "✅ Usuario en grupo docker"
else
    echo "⚠️ Agregando usuario al grupo docker..."
    sudo usermod -aG docker $USER
    echo "💡 Necesitas cerrar sesión y volver a entrar para aplicar los cambios"
    echo "💡 O ejecuta: newgrp docker"
fi

# Verificar conectividad de Docker
if docker ps &>/dev/null; then
    echo "✅ Docker accesible sin sudo"
else
    echo "⚠️ Aplicando permisos de grupo docker..."
    newgrp docker
fi

# Verificar recursos disponibles
echo ""
echo "📊 Recursos disponibles:"
echo "CPU: $(nproc) cores"
echo "RAM: $(free -h | awk '/^Mem:/ {print $2}') total"
echo "Espacio disponible: $(df -h / | awk 'NR==2 {print $4}')"

# Verificar que hay suficientes recursos
AVAILABLE_RAM_GB=$(free -m | awk '/^Mem:/ {print int($2/1024)}')
if [ "$AVAILABLE_RAM_GB" -lt 4 ]; then
    echo "⚠️ RAM disponible: ${AVAILABLE_RAM_GB}GB (recomendado: 4GB+)"
    echo "💡 Minikube funcionará pero con recursos limitados"
else
    echo "✅ RAM suficiente: ${AVAILABLE_RAM_GB}GB"
fi

# Verificar conectividad
if ping -c 1 8.8.8.8 &>/dev/null; then
    echo "✅ Conectividad a Internet OK"
else
    echo "❌ Sin conectividad a Internet"
    exit 1
fi

echo ""
echo "✅ Sistema listo para driver 'docker'"
```

---

## 🚀 Paso 3: Crear cluster con driver "docker"

```bash
# Limpiar cualquier cluster existente
echo "=== PREPARANDO CLUSTER CON DRIVER 'DOCKER' ==="

# Detener y eliminar cualquier cluster existente
minikube stop 2>/dev/null || true
minikube delete 2>/dev/null || true

# Configurar driver docker como predeterminado
echo "� Configurando driver docker como predeterminado..."
minikube config set driver docker

# Configurar recursos para el cluster
echo "🔧 Configurando recursos del cluster..."
minikube config set memory 3072
minikube config set cpus 2

# Mostrar configuración actual
echo "📋 Configuración actual de Minikube:"
minikube config view

# Crear cluster con driver docker
echo "� Iniciando Minikube con driver 'docker'..."
minikube start --driver=docker

# Verificar estado del cluster
echo ""
echo "📊 Estado del cluster:"
minikube status

# Verificar nodos
echo ""
echo "🖥️ Nodos disponibles:"
kubectl get nodes

# Verificar contexto de kubectl
echo ""
echo "� Contexto de kubectl:"
kubectl config current-context
```

**Salida esperada:**
```
✅ minikube v1.37.0 on Ubuntu 24.04
✨ Using the docker driver based on user configuration
👍 Starting control plane node minikube in cluster minikube
🚜 Pulling base image ...
🔥 Creating docker container (CPUs=2, Memory=3072MB) ...
🐳 Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗 Configuring bridge CNI (Container Networking Interface) ...
🔎 Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟 Enabled addons: storage-provisioner, default-storageclass
💡 kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

---

## 🔧 Paso 4: Verificar funcionamiento del cluster

```bash
# Crear script de verificación completa
cat << 'EOF' > ~/verificar-cluster-docker.sh
#!/bin/bash

echo "=== VERIFICACIÓN CLUSTER DRIVER 'DOCKER' ==="
echo ""

# Verificar estado de Minikube
echo "📊 Estado de Minikube:"
minikube status

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
minikube addons list | grep enabled

# Verificar contenedor Docker de Minikube
echo ""
echo "🐳 Contenedor Docker de Minikube:"
docker ps --filter "name=minikube"

# Verificar recursos del contenedor
echo ""
echo "💻 Recursos del contenedor:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" minikube

echo ""
echo "=== VERIFICACIÓN COMPLETADA ==="
EOF

chmod +x ~/verificar-cluster-docker.sh
~/verificar-cluster-docker.sh
```

---

## 🌐 Paso 5: Configurar acceso a servicios con port-forwarding

```bash
# Crear aplicación de prueba para demostrar port-forwarding
echo "=== CONFIGURANDO ACCESO A SERVICIOS CON PORT-FORWARDING ==="

# Crear deployment de prueba
kubectl create deployment test-web --image=nginx:alpine

# Esperar a que el pod esté listo
kubectl wait --for=condition=ready pod -l app=test-web --timeout=60s

# Exponer el servicio
kubectl expose deployment test-web --port=80 --type=ClusterIP

# Obtener información del servicio
kubectl get service test-web

# Obtener nombre del pod
POD_NAME=$(kubectl get pods -l app=test-web -o jsonpath='{.items[0].metadata.name}')
echo "Pod creado: $POD_NAME"

# Configurar port-forwarding
echo ""
echo "🌐 Configurando port-forwarding..."
echo ""
echo "� OPCIONES PARA PORT-FORWARDING SIN BLOQUEAR TERMINAL:"
echo ""
echo "1️⃣ En SEGUNDA TERMINAL (recomendado):"
echo "   kubectl port-forward service/test-web 8080:80"
echo ""
echo "2️⃣ En SEGUNDO PLANO con &:"
echo "   kubectl port-forward service/test-web 8080:80 &"
echo "   # Esto ejecuta en background y devuelve la terminal"
echo ""
echo "3️⃣ Con NOHUP (sobrevive al cierre de terminal):"
echo "   nohup kubectl port-forward service/test-web 8080:80 > /tmp/port-forward.log 2>&1 &"
echo ""
echo "4️⃣ Con SCREEN (terminal virtual):"
echo "   screen -dmS port-forward kubectl port-forward service/test-web 8080:80"
echo "   # Para ver: screen -r port-forward"
echo ""
echo "5️⃣ Con TMUX (terminal multiplexer):"
echo "   tmux new-session -d -s port-forward 'kubectl port-forward service/test-web 8080:80'"
echo "   # Para ver: tmux attach -t port-forward"
echo ""
echo "Luego accede a: http://localhost:8080"

# Crear script mejorado para port-forwarding con opciones
cat << 'EOF' > ~/port-forward-test.sh
#!/bin/bash

SERVICE_NAME="test-web"
LOCAL_PORT="8080"
SERVICE_PORT="80"

echo "🚀 SCRIPT DE PORT-FORWARDING AVANZADO"
echo "====================================="
echo ""
echo "Servicio: $SERVICE_NAME"
echo "Puerto local: $LOCAL_PORT"
echo "Puerto servicio: $SERVICE_PORT"
echo ""

# Función para mostrar opciones
show_options() {
    echo "Selecciona cómo ejecutar port-forwarding:"
    echo "1) Primer plano (bloquea terminal hasta Ctrl+C)"
    echo "2) Segundo plano (&) - devuelve terminal"
    echo "3) Con nohup - sobrevive al cierre de terminal"
    echo "4) Con screen - terminal virtual"
    echo "5) Con tmux - terminal multiplexer"
    echo "6) Mostrar procesos de port-forward activos"
    echo "7) Detener todos los port-forwards"
    echo "8) Salir"
}

# Función para verificar si el servicio existe
check_service() {
    if ! kubectl get service $SERVICE_NAME &>/dev/null; then
        echo "❌ Servicio $SERVICE_NAME no encontrado"
        echo "📋 Servicios disponibles:"
        kubectl get services
        exit 1
    fi
}

# Función para port-forward en primer plano
foreground_portforward() {
    echo "🔄 Iniciando port-forwarding en PRIMER PLANO..."
    echo "📌 Accede a: http://localhost:$LOCAL_PORT"
    echo "⏹️ Presiona Ctrl+C para detener"
    echo ""
    kubectl port-forward service/$SERVICE_NAME $LOCAL_PORT:$SERVICE_PORT
}

# Función para port-forward en segundo plano
background_portforward() {
    echo "🔄 Iniciando port-forwarding en SEGUNDO PLANO..."
    kubectl port-forward service/$SERVICE_NAME $LOCAL_PORT:$SERVICE_PORT &
    PID=$!
    echo "✅ Port-forward iniciado en background (PID: $PID)"
    echo "📌 Accede a: http://localhost:$LOCAL_PORT"
    echo "⏹️ Para detener: kill $PID"
    echo "💡 Terminal libre para otros comandos"
}

# Función para port-forward con nohup
nohup_portforward() {
    echo "🔄 Iniciando port-forwarding con NOHUP..."
    nohup kubectl port-forward service/$SERVICE_NAME $LOCAL_PORT:$SERVICE_PORT > /tmp/port-forward-$SERVICE_NAME.log 2>&1 &
    PID=$!
    echo "✅ Port-forward iniciado con nohup (PID: $PID)"
    echo "📌 Accede a: http://localhost:$LOCAL_PORT"
    echo "📋 Logs en: /tmp/port-forward-$SERVICE_NAME.log"
    echo "⏹️ Para detener: kill $PID"
    echo "💡 Sobrevivirá al cierre de terminal"
}

# Función para port-forward con screen
screen_portforward() {
    if ! command -v screen &>/dev/null; then
        echo "❌ Screen no está instalado"
        echo "🔧 Instalar con: sudo apt install screen"
        return 1
    fi
    
    echo "🔄 Iniciando port-forwarding con SCREEN..."
    screen -dmS port-forward-$SERVICE_NAME kubectl port-forward service/$SERVICE_NAME $LOCAL_PORT:$SERVICE_PORT
    echo "✅ Port-forward iniciado en screen"
    echo "📌 Accede a: http://localhost:$LOCAL_PORT"
    echo "👁️ Para ver sesión: screen -r port-forward-$SERVICE_NAME"
    echo "⏹️ Para detener: screen -X -S port-forward-$SERVICE_NAME quit"
}

# Función para port-forward con tmux
tmux_portforward() {
    if ! command -v tmux &>/dev/null; then
        echo "❌ Tmux no está instalado"
        echo "🔧 Instalar con: sudo apt install tmux"
        return 1
    fi
    
    echo "🔄 Iniciando port-forwarding con TMUX..."
    tmux new-session -d -s port-forward-$SERVICE_NAME "kubectl port-forward service/$SERVICE_NAME $LOCAL_PORT:$SERVICE_PORT"
    echo "✅ Port-forward iniciado en tmux"
    echo "📌 Accede a: http://localhost:$LOCAL_PORT"
    echo "👁️ Para ver sesión: tmux attach -t port-forward-$SERVICE_NAME"
    echo "⏹️ Para detener: tmux kill-session -t port-forward-$SERVICE_NAME"
}

# Función para mostrar procesos activos
show_active_portforwards() {
    echo "📋 PROCESOS DE PORT-FORWARD ACTIVOS:"
    echo "===================================="
    
    # Buscar procesos kubectl port-forward
    PROCESSES=$(ps aux | grep "kubectl port-forward" | grep -v grep)
    if [ -z "$PROCESSES" ]; then
        echo "❌ No hay procesos de port-forward activos"
    else
        echo "$PROCESSES"
        echo ""
        echo "💡 Para detener un proceso: kill <PID>"
    fi
    
    echo ""
    echo "📱 SESIONES DE SCREEN:"
    if command -v screen &>/dev/null; then
        screen -list | grep port-forward || echo "❌ No hay sesiones de screen activas"
    else
        echo "❌ Screen no está instalado"
    fi
    
    echo ""
    echo "📱 SESIONES DE TMUX:"
    if command -v tmux &>/dev/null; then
        tmux list-sessions 2>/dev/null | grep port-forward || echo "❌ No hay sesiones de tmux activas"
    else
        echo "❌ Tmux no está instalado"
    fi
}

# Función para detener todos los port-forwards
stop_all_portforwards() {
    echo "🛑 DETENIENDO TODOS LOS PORT-FORWARDS..."
    echo "======================================="
    
    # Detener procesos kubectl port-forward
    PIDS=$(ps aux | grep "kubectl port-forward" | grep -v grep | awk '{print $2}')
    if [ ! -z "$PIDS" ]; then
        echo "⏹️ Deteniendo procesos kubectl port-forward..."
        echo "$PIDS" | xargs kill
        echo "✅ Procesos terminados"
    else
        echo "❌ No hay procesos kubectl port-forward activos"
    fi
    
    # Detener sesiones screen
    if command -v screen &>/dev/null; then
        SCREEN_SESSIONS=$(screen -list | grep port-forward | awk '{print $1}')
        if [ ! -z "$SCREEN_SESSIONS" ]; then
            echo "⏹️ Deteniendo sesiones de screen..."
            echo "$SCREEN_SESSIONS" | while read session; do
                screen -X -S "$session" quit
            done
            echo "✅ Sesiones de screen terminadas"
        fi
    fi
    
    # Detener sesiones tmux
    if command -v tmux &>/dev/null; then
        TMUX_SESSIONS=$(tmux list-sessions 2>/dev/null | grep port-forward | cut -d: -f1)
        if [ ! -z "$TMUX_SESSIONS" ]; then
            echo "⏹️ Deteniendo sesiones de tmux..."
            echo "$TMUX_SESSIONS" | while read session; do
                tmux kill-session -t "$session"
            done
            echo "✅ Sesiones de tmux terminadas"
        fi
    fi
    
    echo "🎉 Todos los port-forwards han sido detenidos"
}

# Verificar servicio
check_service

# Menú principal
while true; do
    echo ""
    show_options
    read -p "Selecciona una opción (1-8): " choice
    echo ""
    
    case $choice in
        1) foreground_portforward ;;
        2) background_portforward ;;
        3) nohup_portforward ;;
        4) screen_portforward ;;
        5) tmux_portforward ;;
        6) show_active_portforwards ;;
        7) stop_all_portforwards ;;
        8) echo "👋 ¡Hasta luego!"; exit 0 ;;
        *) echo "❌ Opción inválida. Selecciona 1-8." ;;
    esac
    
    if [ $choice -ne 6 ] && [ $choice -ne 7 ] && [ $choice -ne 8 ]; then
        echo ""
        read -p "Presiona Enter para volver al menú..."
    fi
done
EOF

chmod +x ~/port-forward-test.sh

echo "📋 Script mejorado creado: ~/port-forward-test.sh"
echo "🔧 Para probar el servicio con opciones avanzadas: ~/port-forward-test.sh"

echo ""
echo "🚀 COMANDOS RÁPIDOS DE PORT-FORWARDING:"
echo "======================================="
echo ""
echo "💡 Para uso rápido sin scripts:"
echo ""
echo "# En segundo plano (& libera terminal):"
echo "kubectl port-forward service/test-web 8080:80 &"
echo ""
echo "# Con nohup (sobrevive al cierre de terminal):"
echo "nohup kubectl port-forward service/test-web 8080:80 > /tmp/pf.log 2>&1 &"
echo ""
echo "# Ver procesos activos:"
echo "ps aux | grep 'kubectl port-forward'"
echo ""
echo "# Detener todos los port-forwards:"
echo "pkill -f 'kubectl port-forward'"
echo ""
echo "🌐 Acceso: http://localhost:8080"

# Mostrar logs del pod
echo ""
echo "📋 Logs del pod de prueba:"
kubectl logs $POD_NAME

# Probar acceso interno al cluster
echo ""
echo "🔍 Probando acceso interno al servicio..."
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl -s http://test-web

echo ""
echo "✅ Servicio funcionando correctamente"
echo "💡 Para acceso externo, usa port-forwarding con: ~/port-forward-test.sh"
```

---

## 🌩️ Paso 5.1: Configuración especial para VM de Azure

```bash
# SOLUCIÓN PARA VMs DE AZURE - Acceso a servicios desde fuera de la VM
echo "=== CONFIGURACIÓN PARA VM DE AZURE ==="

# Problema: Las VMs de Azure no permiten acceso directo a puertos via IP pública
# Solución: Usar port-forwarding con binding a todas las interfaces

# Crear script mejorado para VMs de Azure
cat << 'EOF' > ~/azure-port-forward.sh
#!/bin/bash

echo "🌩️ CONFIGURACIÓN PARA VM DE AZURE"
echo "=================================="
echo ""
echo "⚠️ IMPORTANTE: Para acceder desde fuera de la VM necesitas:"
echo "1. Port-forwarding con bind a 0.0.0.0"
echo "2. Configurar Network Security Group en Azure"
echo "3. Usar túnel SSH (recomendado para seguridad)"
echo ""

# Función para mostrar opciones
show_options() {
    echo "Selecciona una opción:"
    echo "1) Dashboard de Kubernetes (puerto 8001)"
    echo "2) Servicio test-web (puerto 8080)"
    echo "3) Configurar túnel SSH (RECOMENDADO)"
    echo "4) Mostrar info de conectividad"
    echo "5) Salir"
}

# Función para configurar dashboard
setup_dashboard() {
    echo "🎛️ Configurando acceso al Dashboard..."
    
    # Habilitar Dashboard con addon de Minikube
    if ! minikube addons list | grep -q "dashboard.*enabled"; then
        echo "📦 Habilitando Dashboard de Kubernetes con addon..."
        minikube addons enable dashboard
        
        # Esperar a que esté listo
        echo "⏳ Esperando a que el Dashboard esté listo..."
        kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=120s
    else
        echo "✅ Dashboard ya está habilitado"
    fi
    
    # Crear usuario admin si no existe
    if ! kubectl get serviceaccount admin-user -n kubernetes-dashboard &>/dev/null; then
        echo "👤 Creando usuario administrador..."
        kubectl create serviceaccount admin-user -n kubernetes-dashboard
        kubectl create clusterrolebinding admin-user --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:admin-user
    fi
    
    echo "🚀 Iniciando proxy del Dashboard..."
    echo "📌 Dashboard disponible en: http://IP_PUBLICA_VM:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    echo "⚠️ NOTA: Debes configurar NSG en Azure para el puerto 8001"
    echo "🔐 Para token de acceso, ejecuta: kubectl -n kubernetes-dashboard create token admin-user"
    
    kubectl proxy --address=0.0.0.0 --port=8001 --accept-hosts='.*'
}

# Función para configurar servicio test
setup_test_service() {
    echo "🌐 Configurando acceso al servicio test-web..."
    echo "📌 Servicio disponible en: http://IP_PUBLICA_VM:8080"
    echo "⚠️ NOTA: Debes configurar NSG en Azure para el puerto 8080"
    echo ""
    echo "Selecciona cómo ejecutar port-forwarding:"
    echo "1) Primer plano (bloquea terminal)"
    echo "2) Segundo plano (libera terminal)"
    echo "3) Con nohup (sobrevive cierre de terminal)"
    read -p "Opción (1-3): " pf_choice
    
    case $pf_choice in
        1)
            echo "🔄 Port-forwarding en primer plano..."
            echo "⏹️ Presiona Ctrl+C para detener"
            kubectl port-forward --address=0.0.0.0 service/test-web 8080:80
            ;;
        2)
            echo "🔄 Port-forwarding en segundo plano..."
            kubectl port-forward --address=0.0.0.0 service/test-web 8080:80 &
            PID=$!
            echo "✅ Port-forward iniciado en background (PID: $PID)"
            echo "⏹️ Para detener: kill $PID"
            echo "💡 Terminal libre para otros comandos"
            ;;
        3)
            echo "🔄 Port-forwarding con nohup..."
            nohup kubectl port-forward --address=0.0.0.0 service/test-web 8080:80 > /tmp/azure-pf.log 2>&1 &
            PID=$!
            echo "✅ Port-forward iniciado con nohup (PID: $PID)"
            echo "📋 Logs en: /tmp/azure-pf.log"
            echo "⏹️ Para detener: kill $PID"
            echo "💡 Sobrevivirá al cierre de terminal"
            ;;
        *)
            echo "❌ Opción inválida, usando primer plano..."
            kubectl port-forward --address=0.0.0.0 service/test-web 8080:80
            ;;
    esac
}

# Función para configurar túnel SSH (más seguro)
setup_ssh_tunnel() {
    VM_IP=$(curl -s ifconfig.me)
    echo "🔐 CONFIGURACIÓN DE TÚNEL SSH (RECOMENDADO)"
    echo "==========================================="
    echo ""
    echo "Esta es la opción MÁS SEGURA para acceder a los servicios."
    echo "No requiere abrir puertos en Azure NSG."
    echo ""
    echo "1. En tu máquina LOCAL, ejecuta:"
    echo "   # Para Dashboard:"
    echo "   ssh -L 8001:localhost:8001 usuario@$VM_IP"
    echo ""
    echo "   # Para servicios (puerto 8080):"
    echo "   ssh -L 8080:localhost:8080 usuario@$VM_IP"
    echo ""
    echo "2. Luego en la VM (esta sesión SSH), ejecuta:"
    echo "   # Para Dashboard:"
    echo "   kubectl proxy --port=8001"
    echo ""
    echo "   # Para servicios:"
    echo "   kubectl port-forward service/test-web 8080:80"
    echo ""
    echo "3. En tu máquina local, accede a:"
    echo "   - Dashboard: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    echo "   - Servicios: http://localhost:8080"
    echo ""
    echo "✅ VENTAJAS del túnel SSH:"
    echo "   • No necesitas abrir puertos en Azure NSG"
    echo "   • Conexión cifrada y segura"
    echo "   • Acceso directo desde tu navegador local"
    echo ""
}

# Función para mostrar info de conectividad
show_connectivity_info() {
    VM_IP=$(curl -s ifconfig.me 2>/dev/null || echo "No se pudo obtener IP pública")
    PRIVATE_IP=$(hostname -I | awk '{print $1}')
    
    echo "🌐 INFORMACIÓN DE CONECTIVIDAD"
    echo "=============================="
    echo "IP Pública de la VM: $VM_IP"
    echo "IP Privada de la VM: $PRIVATE_IP"
    echo ""
    echo "🔧 CONFIGURACIÓN AZURE NSG REQUERIDA:"
    echo "Para acceso directo (menos seguro), agrega estas reglas:"
    echo "• Puerto 8001 (Dashboard) - Inbound rule"
    echo "• Puerto 8080 (Servicios) - Inbound rule"
    echo "• Fuente: Tu IP pública o 'Any' (menos seguro)"
    echo ""
    echo "🔐 OPCIÓN RECOMENDADA: Usar túnel SSH (opción 3)"
    echo ""
    echo "📋 SERVICIOS DISPONIBLES EN EL CLUSTER:"
    kubectl get services --all-namespaces
}

# Menú principal
while true; do
    echo ""
    show_options
    read -p "Selecciona una opción (1-5): " choice
    
    case $choice in
        1) setup_dashboard ;;
        2) setup_test_service ;;
        3) setup_ssh_tunnel ;;
        4) show_connectivity_info ;;
        5) echo "👋 ¡Hasta luego!"; exit 0 ;;
        *) echo "❌ Opción inválida. Selecciona 1-5." ;;
    esac
done
EOF

chmod +x ~/azure-port-forward.sh

echo ""
echo "🎯 Script para VM de Azure creado: ~/azure-port-forward.sh"
echo "🚀 Ejecuta: ~/azure-port-forward.sh"
echo ""
echo "📋 RESUMEN DE OPCIONES PARA VM DE AZURE:"
echo "1. 🔐 Túnel SSH (MÁS SEGURO - recomendado)"
echo "2. 🌐 Port-forwarding directo + Azure NSG"
echo "3. 🎛️ Dashboard con acceso externo"
```

---

## 🔧 Paso 6: Gestión avanzada del cluster

```bash
# Comandos útiles para gestionar el cluster Docker
echo "=== GESTIÓN AVANZADA DEL CLUSTER ==="

# Mostrar información del cluster
echo "📊 Información del cluster:"
kubectl cluster-info dump --output-directory=cluster-info --quiet
echo "✅ Información guardada en ./cluster-info/"

# Configurar dashboard
echo ""
echo "🌐 Configurando Dashboard de Kubernetes..."
minikube addons enable dashboard

# Verificar que el dashboard está funcionando
kubectl get pods -n kubernetes-dashboard

# Crear acceso al dashboard
echo ""
echo "🔑 Para acceder al dashboard, ejecuta en otra terminal:"
echo "minikube dashboard"
echo ""
echo "💡 Esto abrirá automáticamente el dashboard en tu navegador"

# Configurar métricas
echo ""
echo "📈 Habilitando métricas del servidor..."
minikube addons enable metrics-server

# Esperar a que metrics-server esté listo
echo "⏳ Esperando a que metrics-server esté listo..."
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=60s

# Mostrar uso de recursos
echo ""
echo "💻 Uso de recursos de nodos:"
kubectl top nodes

echo ""
echo "💻 Uso de recursos de pods:"
kubectl top pods --all-namespaces

# Configurar ingress (opcional)
echo ""
read -p "¿Habilitar Ingress Controller? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    minikube addons enable ingress
    echo "✅ Ingress Controller habilitado"
    kubectl get pods -n ingress-nginx
fi

# Mostrar addons disponibles
echo ""
echo "🔌 Addons disponibles:"
minikube addons list

echo ""
echo "✅ Cluster Docker configurado y listo para desarrollo"
```

---

## 📊 Paso 7: Scripts de utilidad

```bash
# Crear scripts útiles para trabajar con el cluster
echo "=== CREANDO SCRIPTS DE UTILIDAD ==="

# Script para iniciar el cluster
cat << 'EOF' > ~/start-minikube.sh
#!/bin/bash
echo "🚀 Iniciando cluster Minikube..."
minikube start --driver=docker
echo "✅ Cluster iniciado"
minikube status
EOF

# Script para detener el cluster
cat << 'EOF' > ~/stop-minikube.sh
#!/bin/bash
echo "⏹️ Deteniendo cluster Minikube..."
minikube stop
echo "✅ Cluster detenido"
EOF

# Script para reiniciar el cluster
cat << 'EOF' > ~/restart-minikube.sh
#!/bin/bash
echo "🔄 Reiniciando cluster Minikube..."
minikube stop
minikube start --driver=docker
echo "✅ Cluster reiniciado"
minikube status
EOF

# Script para limpiar completamente
cat << 'EOF' > ~/clean-minikube.sh
#!/bin/bash
echo "🧹 Limpiando cluster Minikube completamente..."
minikube stop
minikube delete
docker system prune -f
echo "✅ Limpieza completada"
echo "💡 Ejecuta ~/start-minikube.sh para crear un nuevo cluster"
EOF

# Script para monitorear recursos
cat << 'EOF' > ~/monitor-cluster.sh
#!/bin/bash
echo "=== MONITOREO DEL CLUSTER ==="
echo ""
echo "📊 Estado del cluster:"
minikube status
echo ""
echo "🐳 Contenedor Docker:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" minikube
echo ""
echo "🖥️ Nodos:"
kubectl top nodes 2>/dev/null || echo "Metrics server no disponible"
echo ""
echo "📦 Pods:"
kubectl top pods --all-namespaces 2>/dev/null || echo "Metrics server no disponible"
echo ""
echo "🌐 Servicios:"
kubectl get services --all-namespaces
EOF

# Hacer ejecutables todos los scripts
chmod +x ~/start-minikube.sh
chmod +x ~/stop-minikube.sh
chmod +x ~/restart-minikube.sh
chmod +x ~/clean-minikube.sh
chmod +x ~/monitor-cluster.sh

echo "📋 Scripts creados:"
echo "  • ~/start-minikube.sh      - Iniciar cluster"
echo "  • ~/stop-minikube.sh       - Detener cluster"
echo "  • ~/restart-minikube.sh    - Reiniciar cluster"
echo "  • ~/clean-minikube.sh      - Limpiar completamente"
echo "  • ~/monitor-cluster.sh     - Monitorear recursos"
echo "  • ~/port-forward-test.sh   - Probar port-forwarding"

echo ""
echo "💡 Ejemplos de uso:"
echo "  ./start-minikube.sh"
echo "  ./monitor-cluster.sh"
echo "  ./port-forward-test.sh"
```

---

## 🔧 Troubleshooting

### **Error: Docker no disponible**
```bash
# Verificar que Docker está instalado
if ! command -v docker &>/dev/null; then
    echo "❌ Docker no está instalado"
    echo "🔧 Instalar Docker..."
    # Seguir guía de instalación de Docker para Ubuntu
    exit 1
fi

# Verificar que Docker está funcionando
if ! docker version &>/dev/null; then
    echo "❌ Docker no está funcionando"
    echo "🔧 Iniciar Docker..."
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Verificar permisos de usuario
if ! groups | grep -q docker; then
    echo "⚠️ Agregar usuario al grupo docker..."
    sudo usermod -aG docker $USER
    echo "💡 Cerrar sesión y volver a entrar"
fi
```

### **Error: Cluster no inicia**
```bash
# Limpiar configuración anterior
minikube delete
docker system prune -f

# Reiniciar con configuración limpia
minikube start --driver=docker --memory=3072 --cpus=2
```

### **Error: Port-forwarding no funciona**
```bash
# Verificar que el servicio existe
kubectl get service <service-name>

# Usar port-forwarding específico
kubectl port-forward service/<service-name> <local-port>:<service-port>

# Verificar en navegador: http://localhost:<local-port>
```

### **Error: Usuario no en grupo docker**
```bash
# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Aplicar cambios inmediatamente
newgrp docker

# Verificar acceso
docker ps
```

### **Error: No puedo acceder a servicios desde fuera de VM Azure**
```bash
# PROBLEMA COMÚN EN VMs DE AZURE
echo "🌩️ SOLUCIÓN PARA VMs DE AZURE"

# Opción 1: Túnel SSH (MÁS SEGURO - recomendado)
echo "🔐 TÚNEL SSH (recomendado):"
echo "En tu máquina local ejecuta:"
echo "ssh -L 8080:localhost:8080 usuario@IP_PUBLICA_VM"
echo "Luego en la VM: kubectl port-forward service/mi-servicio 8080:80"
echo "Accede desde tu navegador local: http://localhost:8080"

# Opción 2: Port-forwarding directo + Azure NSG
echo ""
echo "🌐 PORT-FORWARDING DIRECTO:"
echo "1. Configurar port-forwarding con bind a todas las interfaces:"
echo "   kubectl port-forward --address=0.0.0.0 service/mi-servicio 8080:80"
echo ""
echo "2. Configurar Azure Network Security Group:"
echo "   - Ir a Azure Portal -> VM -> Networking"
echo "   - Agregar regla inbound:"
echo "     • Puerto: 8080"
echo "     • Protocolo: TCP"
echo "     • Fuente: Tu IP pública (recomendado) o Any (menos seguro)"
echo "     • Acción: Allow"
echo ""
echo "3. Acceder desde navegador: http://IP_PUBLICA_VM:8080"

# Opción 3: Dashboard de Kubernetes
echo ""
echo "🎛️ DASHBOARD DE KUBERNETES:"
echo "1. Habilitar Dashboard con addon de Minikube:"
echo "   minikube addons enable dashboard"
echo ""
echo "2. Crear usuario admin:"
cat << 'EOF'
kubectl create serviceaccount admin-user -n kubernetes-dashboard
kubectl create clusterrolebinding admin-user --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:admin-user
EOF
echo ""
echo "3. Obtener token:"
echo "   kubectl -n kubernetes-dashboard create token admin-user"
echo ""
echo "4. Iniciar proxy con acceso externo:"
echo "   kubectl proxy --address=0.0.0.0 --port=8001 --accept-hosts='.*'"
echo ""
echo "5. Configurar Azure NSG para puerto 8001"
echo ""
echo "6. Acceder: http://IP_PUBLICA_VM:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"

# Script de ayuda
echo ""
echo "💡 Usa el script helper: ~/azure-port-forward.sh"
echo "   Este script te guía paso a paso para configurar el acceso"

# Verificar IP pública
IP_PUBLICA=$(curl -s ifconfig.me 2>/dev/null || echo "No disponible")
echo ""
echo "📍 Tu IP pública de VM: $IP_PUBLICA"
echo "📍 Usa esta IP para configurar NSG y acceder a servicios"
```

---

## 📝 Checklist de completado

- [ ] Docker funcionando correctamente
- [ ] Usuario en grupo docker  
- [ ] Minikube instalado y configurado
- [ ] Driver docker configurado como predeterminado
- [ ] Cluster iniciado con éxito
- [ ] kubectl funcionando correctamente
- [ ] Port-forwarding configurado para servicios
- [ ] Scripts de utilidad creados
- [ ] Dashboard habilitado (opcional)
- [ ] Verificación final completada

---

## 🎯 Estado actual

✅ **Minikube ejecutándose con driver "docker"**  
✅ **Cluster aislado en contenedor Docker**  
✅ **Port-forwarding configurado para acceso a servicios**  
✅ **Dashboard y métricas disponibles**  
✅ **Sistema listo para desarrollo seguro**

---

**Siguiente paso**: [Lab 3.6: Verificación y Testing Final](./verificacion-testing-final.md)
