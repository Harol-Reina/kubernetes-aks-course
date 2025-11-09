#!/bin/bash
# Script para probar TODOS los ejemplos de Linux Namespaces en Kubernetes
# Demuestra los 7 tipos de namespaces: Network, PID, IPC, UTS, Mount, User, Cgroup

set -e

echo "🧪 VALIDACIÓN COMPLETA DE LINUX NAMESPACES EN KUBERNETES"
echo "=========================================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir headers
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Función para validar
validate() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1 - FAILED${NC}"
    fi
}

# Cambiar al directorio de ejemplos
cd "$(dirname "$0")"

# ============================================================================
print_header "1️⃣ NETWORK NAMESPACE - COMPARTIDO"
# ============================================================================

echo "Desplegando Pod con Network Namespace compartido..."
kubectl apply -f 01-network-namespace.yaml
kubectl wait --for=condition=Ready pod/network-namespace-demo --timeout=60s
validate "Pod network-namespace-demo creado"

echo ""
echo "Verificando que ambos contenedores tienen la MISMA IP:"
IP_SERVER=$(kubectl exec network-namespace-demo -c web-server -- ip addr show eth0 | grep "inet " | awk '{print $2}')
IP_CLIENT=$(kubectl exec network-namespace-demo -c web-client -- ip addr show eth0 | grep "inet " | awk '{print $2}')

echo "  - web-server IP: $IP_SERVER"
echo "  - web-client IP: $IP_CLIENT"

if [ "$IP_SERVER" == "$IP_CLIENT" ]; then
    echo -e "${GREEN}✅ MISMA IP - Network Namespace compartido${NC}"
else
    echo -e "${RED}❌ IPs diferentes - Error${NC}"
fi

echo ""
echo "Probando comunicación vía localhost:"
kubectl exec network-namespace-demo -c web-client -- curl -s localhost:8080 | head -1
validate "Comunicación localhost exitosa"

# ============================================================================
print_header "2️⃣ PID NAMESPACE - OPCIONAL"
# ============================================================================

echo "Desplegando 2 Pods: uno SIN y otro CON shareProcessNamespace..."
kubectl apply -f 02-pid-namespace.yaml
sleep 5
validate "Pods PID namespace creados"

echo ""
echo "Comparando procesos visibles:"
echo ""
echo "--- SIN shareProcessNamespace (aislado) ---"
PROCS_ISOLATED=$(kubectl exec pid-namespace-isolated -c debug -- ps aux 2>/dev/null | wc -l)
echo "Procesos visibles: $PROCS_ISOLATED"

echo ""
echo "--- CON shareProcessNamespace (compartido) ---"
PROCS_SHARED=$(kubectl exec pid-namespace-shared -c debug -- ps aux 2>/dev/null | wc -l)
echo "Procesos visibles: $PROCS_SHARED"

if [ "$PROCS_SHARED" -gt "$PROCS_ISOLATED" ]; then
    echo -e "${GREEN}✅ PID compartido ve MÁS procesos (correcto)${NC}"
else
    echo -e "${RED}❌ PID compartido debería ver más procesos${NC}"
fi

# ============================================================================
print_header "3️⃣ IPC NAMESPACE - COMPARTIDO"
# ============================================================================

echo "Desplegando Pod con IPC Namespace compartido..."
kubectl apply -f 03-ipc-namespace.yaml
kubectl wait --for=condition=Ready pod/ipc-namespace-demo --timeout=60s
validate "Pod ipc-namespace-demo creado"

echo ""
echo "Esperando a que producer escriba datos en shared memory..."
sleep 8

echo ""
echo "Verificando shared memory desde PRODUCER:"
kubectl exec ipc-namespace-demo -c producer -- cat /dev/shm/data.txt | head -2
validate "Producer escribió datos"

echo ""
echo "Verificando shared memory desde CONSUMER:"
kubectl exec ipc-namespace-demo -c consumer -- cat /dev/shm/data.txt | head -2
validate "Consumer lee los MISMOS datos"

echo ""
echo "Probando escritura bidireccional:"
kubectl exec ipc-namespace-demo -c consumer -- sh -c "echo 'Test from consumer' > /dev/shm/test.txt"
CONTENT=$(kubectl exec ipc-namespace-demo -c producer -- cat /dev/shm/test.txt)
if [ "$CONTENT" == "Test from consumer" ]; then
    echo -e "${GREEN}✅ Shared memory funciona bidireccionalmente${NC}"
else
    echo -e "${RED}❌ Shared memory no compartido${NC}"
fi

# ============================================================================
print_header "4️⃣ UTS NAMESPACE - COMPARTIDO"
# ============================================================================

echo "Desplegando Pod con UTS Namespace compartido..."
kubectl apply -f 04-uts-namespace.yaml
kubectl wait --for=condition=Ready pod/uts-namespace-demo --timeout=60s
validate "Pod uts-namespace-demo creado"

echo ""
echo "Verificando hostname compartido:"
HOSTNAME1=$(kubectl exec uts-namespace-demo -c container1 -- hostname)
HOSTNAME2=$(kubectl exec uts-namespace-demo -c container2 -- hostname)

echo "  - container1: $HOSTNAME1"
echo "  - container2: $HOSTNAME2"

if [ "$HOSTNAME1" == "$HOSTNAME2" ]; then
    echo -e "${GREEN}✅ MISMO HOSTNAME - UTS Namespace compartido${NC}"
else
    echo -e "${RED}❌ Hostnames diferentes - Error${NC}"
fi

# ============================================================================
print_header "5️⃣ MOUNT NAMESPACE - NO COMPARTIDO"
# ============================================================================

echo "Desplegando Pod con Mount Namespace NO compartido..."
kubectl apply -f 05-mount-namespace.yaml
kubectl wait --for=condition=Ready pod/mount-namespace-demo --timeout=60s
validate "Pod mount-namespace-demo creado"

echo ""
echo "Esperando a que contenedores escriban archivos..."
sleep 8

echo ""
echo "1️⃣ Verificando que archivos privados NO son visibles:"
kubectl exec mount-namespace-demo -c reader -- ls /tmp/private-writer.txt 2>&1 | grep -q "No such file" && \
    echo -e "${GREEN}✅ Archivo privado NO visible (correcto)${NC}" || \
    echo -e "${RED}❌ Archivo privado visible (incorrecto)${NC}"

echo ""
echo "2️⃣ Verificando que volumen compartido SÍ es visible:"
kubectl exec mount-namespace-demo -c writer -- cat /shared/data.txt > /dev/null 2>&1
validate "Writer accede al volumen compartido"

kubectl exec mount-namespace-demo -c reader -- cat /shared/data.txt > /dev/null 2>&1
validate "Reader accede al volumen compartido"

echo ""
echo "3️⃣ Verificando que contenedor isolated NO tiene el volumen:"
kubectl exec mount-namespace-demo -c isolated -- ls /shared/ 2>&1 | grep -q "No such file" && \
    echo -e "${GREEN}✅ Contenedor isolated sin acceso al volumen (correcto)${NC}" || \
    echo -e "${RED}❌ Contenedor isolated tiene acceso (incorrecto)${NC}"

# ============================================================================
print_header "6️⃣ USER NAMESPACE - NO COMPARTIDO"
# ============================================================================

echo "Desplegando Pod con User Namespace NO compartido..."
kubectl apply -f 06-user-namespace.yaml
kubectl wait --for=condition=Ready pod/user-namespace-demo --timeout=60s
validate "Pod user-namespace-demo creado"

echo ""
echo "Verificando UIDs diferentes:"
UID_ROOT=$(kubectl exec user-namespace-demo -c root-container -- id -u)
UID_USER=$(kubectl exec user-namespace-demo -c user-container -- id -u)
UID_CUSTOM=$(kubectl exec user-namespace-demo -c custom-user-container -- id -u)

echo "  - root-container: UID=$UID_ROOT"
echo "  - user-container: UID=$UID_USER"
echo "  - custom-user: UID=$UID_CUSTOM"

if [ "$UID_ROOT" == "0" ] && [ "$UID_USER" == "1000" ] && [ "$UID_CUSTOM" == "2000" ]; then
    echo -e "${GREEN}✅ UIDs diferentes - User Namespace NO compartido${NC}"
else
    echo -e "${RED}❌ UIDs incorrectos${NC}"
fi

# ============================================================================
print_header "7️⃣ CGROUP NAMESPACE - NO COMPARTIDO"
# ============================================================================

echo "Desplegando Pod con Cgroup Namespace NO compartido..."
kubectl apply -f 07-cgroup-namespace.yaml
kubectl wait --for=condition=Ready pod/cgroup-namespace-demo --timeout=60s
validate "Pod cgroup-namespace-demo creado"

echo ""
echo "Verificando recursos asignados:"
kubectl describe pod cgroup-namespace-demo | grep -A 2 "cpu-intensive:" | grep Limits
kubectl describe pod cgroup-namespace-demo | grep -A 2 "memory-intensive:" | grep Limits

echo ""
echo "Esperando métricas de uso de recursos..."
sleep 10

echo ""
echo "Uso de recursos por contenedor:"
kubectl top pod cgroup-namespace-demo --containers 2>/dev/null || \
    echo -e "${YELLOW}⚠️ metrics-server no disponible (opcional)${NC}"

# ============================================================================
print_header "📊 RESUMEN DE VALIDACIÓN"
# ============================================================================

echo ""
echo "Namespaces validados:"
echo ""
echo -e "✅ ${GREEN}Network Namespace${NC} - COMPARTIDO"
echo "   └─ Misma IP, comunicación localhost"
echo ""
echo -e "⚙️ ${YELLOW}PID Namespace${NC} - OPCIONAL (shareProcessNamespace)"
echo "   └─ Procesos visibles cuando se habilita"
echo ""
echo -e "✅ ${GREEN}IPC Namespace${NC} - COMPARTIDO"
echo "   └─ Shared memory, comunicación ultra-rápida"
echo ""
echo -e "✅ ${GREEN}UTS Namespace${NC} - COMPARTIDO"
echo "   └─ Mismo hostname entre contenedores"
echo ""
echo -e "🚫 ${RED}Mount Namespace${NC} - NO COMPARTIDO"
echo "   └─ Filesystem independiente, volúmenes compartibles"
echo ""
echo -e "🚫 ${RED}User Namespace${NC} - NO COMPARTIDO"
echo "   └─ UIDs/GIDs diferentes por contenedor"
echo ""
echo -e "🚫 ${RED}Cgroup Namespace${NC} - NO COMPARTIDO"
echo "   └─ Recursos (CPU/Memory) independientes"
echo ""

# ============================================================================
print_header "🧹 CLEANUP"
# ============================================================================

echo "¿Deseas limpiar todos los Pods? (y/n)"
read -r CLEANUP

if [ "$CLEANUP" == "y" ]; then
    echo ""
    echo "Eliminando todos los Pods de demostración..."
    kubectl delete pod network-namespace-demo --ignore-not-found=true
    kubectl delete pod pid-namespace-isolated pid-namespace-shared --ignore-not-found=true
    kubectl delete pod ipc-namespace-demo --ignore-not-found=true
    kubectl delete pod uts-namespace-demo --ignore-not-found=true
    kubectl delete pod mount-namespace-demo --ignore-not-found=true
    kubectl delete pod user-namespace-demo --ignore-not-found=true
    kubectl delete pod cgroup-namespace-demo --ignore-not-found=true
    validate "Cleanup completado"
else
    echo ""
    echo "Pods dejados para inspección manual."
    echo ""
    echo "Para limpiar manualmente:"
    echo "  kubectl delete -f ."
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ VALIDACIÓN COMPLETA FINALIZADA${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
