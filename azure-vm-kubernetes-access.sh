#!/bin/bash

# Script para configurar acceso a servicios Kubernetes desde VM de Azure
# Soluciona el problema de no poder acceder via IP pública

set -e

echo "🌩️ CONFIGURADOR DE ACCESO KUBERNETES PARA VM AZURE"
echo "=================================================="
echo ""

# Obtener IP pública de la VM
VM_PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "No disponible")
VM_PRIVATE_IP=$(hostname -I | awk '{print $1}')

echo "📍 IP Pública de la VM: $VM_PUBLIC_IP"
echo "📍 IP Privada de la VM: $VM_PRIVATE_IP"
echo ""

# Verificar que kubectl funciona
if ! command -v kubectl &>/dev/null; then
    echo "❌ kubectl no está instalado o no está en el PATH"
    exit 1
fi

if ! kubectl cluster-info &>/dev/null; then
    echo "❌ No hay conexión al cluster de Kubernetes"
    echo "💡 Asegúrate de que Minikube esté funcionando: minikube status"
    exit 1
fi

echo "✅ Kubernetes cluster disponible"
echo ""

# Función para mostrar menú
show_menu() {
    echo "OPCIONES DISPONIBLES:"
    echo "1. 🔐 Configurar túnel SSH (MÁS SEGURO - recomendado)"
    echo "2. 🎛️ Configurar Dashboard de Kubernetes"
    echo "3. 🌐 Configurar acceso directo a servicios"
    echo "4. 📋 Mostrar servicios disponibles"
    echo "5. 🔧 Verificar configuración actual"
    echo "6. 📖 Mostrar guía de Azure NSG"
    echo "7. 🚀 Iniciar port-forwarding para servicio específico"
    echo "8. ❌ Salir"
    echo ""
}

# Función para configurar túnel SSH
setup_ssh_tunnel() {
    echo "🔐 CONFIGURACIÓN DE TÚNEL SSH"
    echo "============================="
    echo ""
    echo "Esta es la opción MÁS SEGURA. No requiere modificar Azure NSG."
    echo ""
    echo "PASOS A SEGUIR:"
    echo ""
    echo "1. En tu MÁQUINA LOCAL, abre una terminal y ejecuta:"
    echo "   ssh -L 8080:localhost:8080 -L 8001:localhost:8001 $(whoami)@$VM_PUBLIC_IP"
    echo ""
    echo "2. Una vez conectado por SSH, en esta VM ejecuta:"
    echo "   # Para Dashboard:"
    echo "   kubectl proxy --port=8001"
    echo ""
    echo "   # Para servicios (en otra terminal SSH):"
    echo "   kubectl port-forward service/NOMBRE_SERVICIO 8080:PUERTO"
    echo ""
    echo "3. En tu navegador LOCAL, accede a:"
    echo "   - Dashboard: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    echo "   - Servicios: http://localhost:8080"
    echo ""
    echo "✅ VENTAJAS:"
    echo "   • Conexión segura y cifrada"
    echo "   • No necesita modificar Azure NSG"
    echo "   • Acceso desde tu navegador local"
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para configurar Dashboard
setup_dashboard() {
    echo "🎛️ CONFIGURANDO DASHBOARD DE KUBERNETES"
    echo "======================================="
    echo ""
    
    # Habilitar Dashboard con addon de Minikube
    if ! minikube addons list | grep -q "dashboard.*enabled"; then
        echo "📦 Habilitando Dashboard de Kubernetes con addon..."
        minikube addons enable dashboard
        
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
    
    echo ""
    echo "🔑 TOKEN DE ACCESO AL DASHBOARD:"
    echo "==============================="
    TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user)
    echo "$TOKEN"
    echo ""
    echo "💾 Token guardado en ~/dashboard-token.txt"
    echo "$TOKEN" > ~/dashboard-token.txt
    
    echo ""
    echo "🚀 OPCIONES PARA ACCEDER AL DASHBOARD:"
    echo ""
    echo "OPCIÓN A - Túnel SSH (recomendado):"
    echo "1. En tu máquina local: ssh -L 8001:localhost:8001 $(whoami)@$VM_PUBLIC_IP"
    echo "2. En la VM: kubectl proxy --port=8001"
    echo "3. Navegador local: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    echo ""
    echo "OPCIÓN B - Acceso directo (requiere Azure NSG):"
    echo "1. Configurar Azure NSG para puerto 8001"
    echo "2. En la VM: kubectl proxy --address=0.0.0.0 --port=8001 --accept-hosts='.*'"
    echo "3. Navegador: http://$VM_PUBLIC_IP:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    echo ""
    
    read -p "¿Iniciar proxy del Dashboard ahora? (y/n): " start_proxy
    if [[ $start_proxy =~ ^[Yy]$ ]]; then
        echo "🚀 Iniciando proxy del Dashboard..."
        echo "📌 Dashboard estará disponible en puerto 8001"
        echo "⚠️ Si usas acceso directo, configura Azure NSG para puerto 8001"
        echo "⏹️ Presiona Ctrl+C para detener"
        kubectl proxy --address=0.0.0.0 --port=8001 --accept-hosts='.*'
    fi
}

# Función para configurar acceso directo
setup_direct_access() {
    echo "🌐 CONFIGURACIÓN DE ACCESO DIRECTO"
    echo "=================================="
    echo ""
    echo "⚠️ REQUIERE CONFIGURAR AZURE NETWORK SECURITY GROUP"
    echo ""
    
    # Mostrar servicios disponibles
    echo "📋 Servicios disponibles:"
    kubectl get services --all-namespaces
    echo ""
    
    read -p "Introduce el nombre del servicio: " service_name
    read -p "Introduce el namespace (default si está vacío): " namespace
    read -p "Introduce el puerto del servicio: " service_port
    read -p "Introduce el puerto local (8080 por defecto): " local_port
    
    # Valores por defecto
    namespace=${namespace:-default}
    local_port=${local_port:-8080}
    
    echo ""
    echo "🔧 CONFIGURACIÓN:"
    echo "Servicio: $service_name"
    echo "Namespace: $namespace"
    echo "Puerto servicio: $service_port"
    echo "Puerto local: $local_port"
    echo ""
    
    echo "📋 PASOS PARA AZURE NSG:"
    echo "1. Ir a Azure Portal"
    echo "2. Navegar a tu VM -> Networking"
    echo "3. Agregar regla inbound:"
    echo "   - Puerto: $local_port"
    echo "   - Protocolo: TCP"
    echo "   - Fuente: Tu IP o Any"
    echo "   - Acción: Allow"
    echo ""
    echo "4. Una vez configurado NSG, el servicio estará en:"
    echo "   http://$VM_PUBLIC_IP:$local_port"
    echo ""
    
    read -p "¿Iniciar port-forwarding ahora? (y/n): " start_forward
    if [[ $start_forward =~ ^[Yy]$ ]]; then
        echo "🚀 Iniciando port-forwarding..."
        echo "📌 Servicio disponible en: http://$VM_PUBLIC_IP:$local_port"
        echo "⚠️ Asegúrate de haber configurado Azure NSG"
        echo "⏹️ Presiona Ctrl+C para detener"
        
        if [[ $namespace == "default" ]]; then
            kubectl port-forward --address=0.0.0.0 service/$service_name $local_port:$service_port
        else
            kubectl port-forward --address=0.0.0.0 -n $namespace service/$service_name $local_port:$service_port
        fi
    fi
}

# Función para mostrar servicios
show_services() {
    echo "📋 SERVICIOS DISPONIBLES EN EL CLUSTER"
    echo "======================================"
    kubectl get services --all-namespaces -o wide
    echo ""
    echo "💡 Para acceder a un servicio, usa la opción 7 del menú principal"
}

# Función para verificar configuración
verify_config() {
    echo "🔧 VERIFICACIÓN DE CONFIGURACIÓN"
    echo "================================"
    echo ""
    
    echo "🌐 Conectividad:"
    echo "IP Pública: $VM_PUBLIC_IP"
    echo "IP Privada: $VM_PRIVATE_IP"
    echo ""
    
    echo "🐳 Docker:"
    if command -v docker &>/dev/null && docker ps &>/dev/null; then
        echo "✅ Docker funcionando"
    else
        echo "❌ Docker no disponible"
    fi
    echo ""
    
    echo "☸️ Kubernetes:"
    if kubectl cluster-info &>/dev/null; then
        echo "✅ Cluster accesible"
        kubectl get nodes
    else
        echo "❌ Cluster no accesible"
    fi
    echo ""
    
    echo "📦 Minikube:"
    if command -v minikube &>/dev/null; then
        minikube status
    else
        echo "❌ Minikube no disponible"
    fi
    echo ""
    
    echo "🌐 Servicios activos:"
    kubectl get services --all-namespaces
}

# Función para mostrar guía Azure NSG
show_azure_nsg_guide() {
    echo "📖 GUÍA PARA CONFIGURAR AZURE NETWORK SECURITY GROUP"
    echo "=================================================="
    echo ""
    echo "PASOS DETALLADOS:"
    echo ""
    echo "1. 🌐 Acceder a Azure Portal (portal.azure.com)"
    echo ""
    echo "2. 🔍 Buscar y seleccionar tu VM"
    echo ""
    echo "3. 🌐 En el menú izquierdo, hacer clic en 'Networking'"
    echo ""
    echo "4. ➕ Hacer clic en 'Add inbound port rule'"
    echo ""
    echo "5. ⚙️ Configurar la regla:"
    echo "   - Source: IP Addresses"
    echo "   - Source IP addresses: Tu IP pública (recomendado) o * (menos seguro)"
    echo "   - Source port ranges: *"
    echo "   - Destination: Any"
    echo "   - Service: Custom"
    echo "   - Destination port ranges: 8080,8001 (o puertos específicos)"
    echo "   - Protocol: TCP"
    echo "   - Action: Allow"
    echo "   - Priority: 100"
    echo "   - Name: Allow-Kubernetes-Access"
    echo ""
    echo "6. 💾 Hacer clic en 'Add'"
    echo ""
    echo "🔍 Para encontrar tu IP pública:"
    echo "   - Google: 'what is my ip'"
    echo "   - O usar: curl ifconfig.me"
    echo ""
    echo "⚠️ SEGURIDAD:"
    echo "   • Usar tu IP específica es más seguro que '*'"
    echo "   • Considera usar túnel SSH en lugar de abrir puertos"
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para port-forwarding específico
start_specific_portforward() {
    echo "🚀 PORT-FORWARDING PARA SERVICIO ESPECÍFICO"
    echo "==========================================="
    echo ""
    
    # Mostrar servicios
    echo "📋 Servicios disponibles:"
    kubectl get services --all-namespaces
    echo ""
    
    read -p "Nombre del servicio: " service_name
    read -p "Namespace (Enter para 'default'): " namespace
    read -p "Puerto del servicio: " service_port
    read -p "Puerto local (Enter para 8080): " local_port
    
    # Valores por defecto
    namespace=${namespace:-default}
    local_port=${local_port:-8080}
    
    echo ""
    echo "🔧 Configuración:"
    echo "Servicio: $service_name (namespace: $namespace)"
    echo "Puerto: $service_port -> $local_port"
    echo ""
    echo "🌐 URLs de acceso:"
    echo "Local: http://localhost:$local_port"
    echo "Externo: http://$VM_PUBLIC_IP:$local_port (requiere Azure NSG)"
    echo ""
    echo "⚠️ Para acceso externo, configura Azure NSG para puerto $local_port"
    echo ""
    
    read -p "¿Continuar? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo "🚀 Iniciando port-forwarding..."
        echo "⏹️ Presiona Ctrl+C para detener"
        
        if [[ $namespace == "default" ]]; then
            kubectl port-forward --address=0.0.0.0 service/$service_name $local_port:$service_port
        else
            kubectl port-forward --address=0.0.0.0 -n $namespace service/$service_name $local_port:$service_port
        fi
    fi
}

# Bucle principal del menú
while true; do
    echo ""
    show_menu
    read -p "Selecciona una opción (1-8): " choice
    echo ""
    
    case $choice in
        1) setup_ssh_tunnel ;;
        2) setup_dashboard ;;
        3) setup_direct_access ;;
        4) show_services ;;
        5) verify_config ;;
        6) show_azure_nsg_guide ;;
        7) start_specific_portforward ;;
        8) echo "👋 ¡Hasta luego!"; exit 0 ;;
        *) echo "❌ Opción inválida. Selecciona 1-8." ;;
    esac
    
    echo ""
    read -p "Presiona Enter para volver al menú principal..."
done