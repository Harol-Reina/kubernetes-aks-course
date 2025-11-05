#!/bin/bash

# Script de utilidades rápidas para port-forwarding en Kubernetes
# Soluciona el problema de terminals bloqueadas

echo "🚀 UTILIDADES RÁPIDAS PARA PORT-FORWARDING"
echo "=========================================="
echo ""

# Función para mostrar ayuda
show_help() {
    echo "📋 COMANDOS DISPONIBLES:"
    echo ""
    echo "1. Port-forward en segundo plano:"
    echo "   pf-bg <servicio> <puerto-local> <puerto-servicio> [namespace]"
    echo "   Ejemplo: pf-bg nginx 8080 80"
    echo ""
    echo "2. Port-forward con nohup:"
    echo "   pf-nohup <servicio> <puerto-local> <puerto-servicio> [namespace]"
    echo "   Ejemplo: pf-nohup nginx 8080 80"
    echo ""
    echo "3. Mostrar port-forwards activos:"
    echo "   pf-list"
    echo ""
    echo "4. Detener todos los port-forwards:"
    echo "   pf-stop-all"
    echo ""
    echo "5. Detener port-forward específico:"
    echo "   pf-stop <puerto-local>"
    echo "   Ejemplo: pf-stop 8080"
    echo ""
}

# Función para port-forward en segundo plano
pf_bg() {
    local service=$1
    local local_port=$2
    local service_port=$3
    local namespace=${4:-default}
    
    if [ -z "$service" ] || [ -z "$local_port" ] || [ -z "$service_port" ]; then
        echo "❌ Uso: pf-bg <servicio> <puerto-local> <puerto-servicio> [namespace]"
        return 1
    fi
    
    echo "🔄 Iniciando port-forward en segundo plano..."
    echo "Servicio: $service (namespace: $namespace)"
    echo "Puerto: $local_port -> $service_port"
    
    if [ "$namespace" = "default" ]; then
        kubectl port-forward service/$service $local_port:$service_port &
    else
        kubectl port-forward -n $namespace service/$service $local_port:$service_port &
    fi
    
    local pid=$!
    echo "✅ Port-forward iniciado (PID: $pid)"
    echo "📌 Acceso: http://localhost:$local_port"
    echo "⏹️ Para detener: kill $pid"
    echo "💡 Terminal libre para otros comandos"
}

# Función para port-forward con nohup
pf_nohup() {
    local service=$1
    local local_port=$2
    local service_port=$3
    local namespace=${4:-default}
    
    if [ -z "$service" ] || [ -z "$local_port" ] || [ -z "$service_port" ]; then
        echo "❌ Uso: pf-nohup <servicio> <puerto-local> <puerto-servicio> [namespace]"
        return 1
    fi
    
    local log_file="/tmp/port-forward-$service-$local_port.log"
    
    echo "🔄 Iniciando port-forward con nohup..."
    echo "Servicio: $service (namespace: $namespace)"
    echo "Puerto: $local_port -> $service_port"
    echo "Logs: $log_file"
    
    if [ "$namespace" = "default" ]; then
        nohup kubectl port-forward service/$service $local_port:$service_port > $log_file 2>&1 &
    else
        nohup kubectl port-forward -n $namespace service/$service $local_port:$service_port > $log_file 2>&1 &
    fi
    
    local pid=$!
    echo "✅ Port-forward iniciado con nohup (PID: $pid)"
    echo "📌 Acceso: http://localhost:$local_port"
    echo "📋 Logs: $log_file"
    echo "⏹️ Para detener: kill $pid"
    echo "💡 Sobrevivirá al cierre de terminal"
}

# Función para listar port-forwards activos
pf_list() {
    echo "📋 PORT-FORWARDS ACTIVOS:"
    echo "========================="
    
    local processes=$(ps aux | grep "kubectl port-forward" | grep -v grep)
    if [ -z "$processes" ]; then
        echo "❌ No hay port-forwards activos"
    else
        echo "PID    PUERTO    COMANDO"
        echo "======================="
        echo "$processes" | while read line; do
            local pid=$(echo $line | awk '{print $2}')
            local cmd=$(echo $line | awk '{for(i=11;i<=NF;i++) printf $i" "; print ""}')
            local port=$(echo $cmd | grep -o '[0-9]\+:[0-9]\+' | cut -d: -f1)
            printf "%-6s %-9s %s\n" "$pid" "$port" "$cmd"
        done
    fi
    
    echo ""
    echo "📁 ARCHIVOS DE LOG DISPONIBLES:"
    ls -la /tmp/port-forward-*.log 2>/dev/null | awk '{print $9 " (" $5 " bytes)"}' || echo "❌ No hay logs disponibles"
}

# Función para detener port-forward específico
pf_stop() {
    local port=$1
    
    if [ -z "$port" ]; then
        echo "❌ Uso: pf-stop <puerto-local>"
        echo "💡 Usa 'pf-list' para ver puertos activos"
        return 1
    fi
    
    local pid=$(ps aux | grep "kubectl port-forward" | grep ":$port" | grep -v grep | awk '{print $2}')
    
    if [ -z "$pid" ]; then
        echo "❌ No se encontró port-forward en puerto $port"
        echo "💡 Usa 'pf-list' para ver puertos activos"
        return 1
    fi
    
    echo "⏹️ Deteniendo port-forward en puerto $port (PID: $pid)..."
    kill $pid
    
    if [ $? -eq 0 ]; then
        echo "✅ Port-forward detenido"
    else
        echo "❌ Error al detener port-forward"
    fi
}

# Función para detener todos los port-forwards
pf_stop_all() {
    echo "🛑 DETENIENDO TODOS LOS PORT-FORWARDS..."
    
    local pids=$(ps aux | grep "kubectl port-forward" | grep -v grep | awk '{print $2}')
    
    if [ -z "$pids" ]; then
        echo "❌ No hay port-forwards activos"
        return 0
    fi
    
    echo "⏹️ Deteniendo procesos: $pids"
    echo "$pids" | xargs kill
    
    if [ $? -eq 0 ]; then
        echo "✅ Todos los port-forwards han sido detenidos"
    else
        echo "⚠️ Algunos procesos podrían no haberse detenido correctamente"
    fi
    
    # Limpiar logs antiguos (opcional)
    read -p "¿Limpiar archivos de log? (y/N): " clean_logs
    if [[ $clean_logs =~ ^[Yy]$ ]]; then
        rm -f /tmp/port-forward-*.log
        echo "🧹 Logs limpiados"
    fi
}

# Función principal
main() {
    if [ $# -eq 0 ]; then
        show_help
        return 0
    fi
    
    case $1 in
        "pf-bg")
            shift
            pf_bg "$@"
            ;;
        "pf-nohup")
            shift
            pf_nohup "$@"
            ;;
        "pf-list")
            pf_list
            ;;
        "pf-stop")
            pf_stop "$2"
            ;;
        "pf-stop-all")
            pf_stop_all
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo "❌ Comando desconocido: $1"
            echo ""
            show_help
            return 1
            ;;
    esac
}

# Si el script se ejecuta directamente, mostrar menú interactivo
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "🎯 MODO INTERACTIVO - SELECCIONA UNA OPCIÓN:"
    echo ""
    echo "1) Port-forward en segundo plano"
    echo "2) Port-forward con nohup" 
    echo "3) Listar port-forwards activos"
    echo "4) Detener port-forward específico"
    echo "5) Detener todos los port-forwards"
    echo "6) Mostrar ayuda"
    echo "7) Salir"
    echo ""
    
    while true; do
        read -p "Selecciona una opción (1-7): " choice
        echo ""
        
        case $choice in
            1)
                read -p "Nombre del servicio: " service
                read -p "Puerto local: " local_port
                read -p "Puerto del servicio: " service_port
                read -p "Namespace (Enter para 'default'): " namespace
                namespace=${namespace:-default}
                pf_bg "$service" "$local_port" "$service_port" "$namespace"
                ;;
            2)
                read -p "Nombre del servicio: " service
                read -p "Puerto local: " local_port
                read -p "Puerto del servicio: " service_port
                read -p "Namespace (Enter para 'default'): " namespace
                namespace=${namespace:-default}
                pf_nohup "$service" "$local_port" "$service_port" "$namespace"
                ;;
            3)
                pf_list
                ;;
            4)
                read -p "Puerto local a detener: " port
                pf_stop "$port"
                ;;
            5)
                pf_stop_all
                ;;
            6)
                show_help
                ;;
            7)
                echo "👋 ¡Hasta luego!"
                exit 0
                ;;
            *)
                echo "❌ Opción inválida. Selecciona 1-7."
                ;;
        esac
        
        echo ""
        read -p "Presiona Enter para continuar..."
        echo ""
    done
fi

# Exportar funciones para uso como comandos
export -f pf_bg pf_nohup pf_list pf_stop pf_stop_all

echo "✅ Funciones cargadas. Usa 'pf-bg', 'pf-nohup', 'pf-list', 'pf-stop', 'pf-stop-all'"
echo "💡 Para ayuda: ./$(basename $0) help"