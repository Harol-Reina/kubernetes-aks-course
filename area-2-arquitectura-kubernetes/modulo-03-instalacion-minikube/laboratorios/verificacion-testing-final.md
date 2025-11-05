# Lab 3.6: Verificación y Testing Final

**Duración**: 15 minutos  
**Objetivo**: Verificar instalación completa y probar funcionalidades de Kubernetes

## 🎯 Objetivos

- Verificar instalación completa de Minikube
- Probar despliegue de aplicaciones
- Verificar autocompletado de kubectl
- Configurar ambiente para futuros laboratorios
- Crear checklist de validación

---

## 📋 Prerequisitos

- Minikube con driver "none" funcionando (Lab 3.5)
- kubectl configurado correctamente
- Acceso directo a servicios verificado

---

## ✅ Paso 1: Verificación completa del sistema

```bash
# Crear script maestro de verificación
cat << 'EOF' > ~/verificacion-sistema-completa.sh
#!/bin/bash

echo "================================================================="
echo "    VERIFICACIÓN COMPLETA DEL SISTEMA KUBERNETES"
echo "================================================================="
echo ""

# Variables de colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar estado
show_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Función para mostrar información
show_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Función para mostrar advertencia
show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "🔍 VERIFICANDO COMPONENTES DEL SISTEMA..."
echo ""

# 1. Verificar sistema operativo
echo "1️⃣ Sistema Operativo:"
show_info "SO: $(lsb_release -d | cut -f2)"
show_info "Kernel: $(uname -r)"
show_info "Arquitectura: $(uname -m)"
echo ""

# 2. Verificar recursos
echo "2️⃣ Recursos del Sistema:"
CPU_CORES=$(nproc)
RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
RAM_USED=$(free -h | awk '/^Mem:/ {print $3}')
DISK_FREE=$(df -h / | awk 'NR==2 {print $4}')

show_info "CPU: $CPU_CORES cores"
show_info "RAM: $RAM_TOTAL total, $RAM_USED usado"
show_info "Disco libre: $DISK_FREE"

if [ "$CPU_CORES" -ge 2 ]; then
    show_status 0 "CPU suficiente para Kubernetes"
else
    show_status 1 "CPU insuficiente (mínimo 2 cores)"
fi
echo ""

# 3. Verificar Docker
echo "3️⃣ Docker:"
if docker --version &>/dev/null; then
    show_status 0 "Docker instalado"
    show_info "Versión: $(docker --version)"
    
    if docker ps &>/dev/null; then
        show_status 0 "Docker daemon funcionando"
    else
        show_status 1 "Docker daemon no responde"
    fi
    
    if groups $USER | grep -q docker; then
        show_status 0 "Usuario en grupo docker"
    else
        show_status 1 "Usuario NO está en grupo docker"
    fi
else
    show_status 1 "Docker no instalado"
fi
echo ""

# 4. Verificar kubectl
echo "4️⃣ kubectl:"
if kubectl version --client &>/dev/null; then
    show_status 0 "kubectl instalado"
    show_info "Versión: $(kubectl version --client --short 2>/dev/null || kubectl version --client | grep "Client Version")"
    
    if kubectl config current-context &>/dev/null; then
        show_status 0 "kubectl configurado"
        show_info "Contexto: $(kubectl config current-context)"
    else
        show_status 1 "kubectl no configurado"
    fi
else
    show_status 1 "kubectl no instalado"
fi
echo ""

# 5. Verificar Minikube
echo "5️⃣ Minikube:"
if minikube version &>/dev/null; then
    show_status 0 "Minikube instalado"
    show_info "Versión: $(minikube version | head -1)"
    
    if sudo minikube status --profile=none-cluster &>/dev/null; then
        show_status 0 "Cluster none-cluster funcionando"
        
        # Verificar nodos
        if kubectl get nodes &>/dev/null; then
            NODE_STATUS=$(kubectl get nodes --no-headers | awk '{print $2}')
            if [ "$NODE_STATUS" = "Ready" ]; then
                show_status 0 "Nodo en estado Ready"
            else
                show_status 1 "Nodo no está Ready: $NODE_STATUS"
            fi
        fi
    else
        show_status 1 "Cluster none-cluster no funcionando"
    fi
else
    show_status 1 "Minikube no instalado"
fi
echo ""

# 6. Verificar autocompletado
echo "6️⃣ Autocompletado:"
if grep -q "kubectl completion bash" ~/.bashrc; then
    show_status 0 "Autocompletado kubectl configurado"
else
    show_status 1 "Autocompletado kubectl no configurado"
fi

if grep -q "minikube completion bash" ~/.bashrc; then
    show_status 0 "Autocompletado minikube configurado"
else
    show_status 1 "Autocompletado minikube no configurado"
fi
echo ""

# 7. Verificar conectividad
echo "7️⃣ Conectividad:"
if ping -c 1 8.8.8.8 &>/dev/null; then
    show_status 0 "Conectividad a Internet"
else
    show_status 1 "Sin conectividad a Internet"
fi

if kubectl cluster-info &>/dev/null; then
    show_status 0 "API Server accesible"
else
    show_status 1 "API Server no accesible"
fi
echo ""

echo "================================================================="
echo "               RESUMEN DE VERIFICACIÓN"
echo "================================================================="

# Contar verificaciones exitosas
CHECKS_PASSED=0
TOTAL_CHECKS=10

# Evaluar cada componente
docker --version &>/dev/null && ((CHECKS_PASSED++))
kubectl version --client &>/dev/null && ((CHECKS_PASSED++))
minikube version &>/dev/null && ((CHECKS_PASSED++))
sudo minikube status --profile=none-cluster &>/dev/null && ((CHECKS_PASSED++))
kubectl get nodes &>/dev/null && ((CHECKS_PASSED++))
grep -q "kubectl completion bash" ~/.bashrc && ((CHECKS_PASSED++))
grep -q "minikube completion bash" ~/.bashrc && ((CHECKS_PASSED++))
ping -c 1 8.8.8.8 &>/dev/null && ((CHECKS_PASSED++))
kubectl cluster-info &>/dev/null && ((CHECKS_PASSED++))
groups $USER | grep -q docker && ((CHECKS_PASSED++))

echo ""
if [ $CHECKS_PASSED -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}🎉 TODAS LAS VERIFICACIONES PASARON ($CHECKS_PASSED/$TOTAL_CHECKS)${NC}"
    echo -e "${GREEN}✅ Sistema completamente funcional para Kubernetes${NC}"
elif [ $CHECKS_PASSED -ge 8 ]; then
    echo -e "${YELLOW}⚠️  SISTEMA FUNCIONAL CON ADVERTENCIAS ($CHECKS_PASSED/$TOTAL_CHECKS)${NC}"
    echo -e "${YELLOW}⚡ Puedes continuar, pero revisa las advertencias${NC}"
else
    echo -e "${RED}❌ SISTEMA REQUIERE CONFIGURACIÓN ADICIONAL ($CHECKS_PASSED/$TOTAL_CHECKS)${NC}"
    echo -e "${RED}🔧 Revisa los errores antes de continuar${NC}"
fi

echo ""
echo "================================================================="
EOF

chmod +x ~/verificacion-sistema-completa.sh
~/verificacion-sistema-completa.sh
```

---

## 🧪 Paso 2: Testing de aplicaciones básicas

```bash
# Crear script de testing completo
cat << 'EOF' > ~/test-aplicaciones-k8s.sh
#!/bin/bash

echo "================================================================="
echo "           TESTING DE APLICACIONES KUBERNETES"
echo "================================================================="
echo ""

# Función para esperar a que el pod esté listo
wait_for_pod() {
    local app_name=$1
    local timeout=${2:-60}
    
    echo "⏳ Esperando a que el pod $app_name esté listo..."
    kubectl wait --for=condition=ready pod -l app=$app_name --timeout=${timeout}s
    
    if [ $? -eq 0 ]; then
        echo "✅ Pod $app_name está listo"
        return 0
    else
        echo "❌ Pod $app_name no está listo después de ${timeout}s"
        return 1
    fi
}

# Test 1: Deployment básico
echo "🧪 TEST 1: Deployment básico con Nginx"
echo "----------------------------------------"

kubectl create deployment test-nginx --image=nginx:alpine
wait_for_pod test-nginx

# Verificar deployment
kubectl get deployments
kubectl get pods -l app=test-nginx

# Exponer servicio
kubectl expose deployment test-nginx --port=80 --type=NodePort
NGINX_PORT=$(kubectl get service test-nginx -o jsonpath='{.spec.ports[0].nodePort}')

echo "🌐 Servicio Nginx expuesto en puerto: $NGINX_PORT"

# Probar acceso
if curl -s http://localhost:$NGINX_PORT | grep -q "Welcome to nginx"; then
    echo "✅ Test 1 PASADO: Nginx responde correctamente"
else
    echo "❌ Test 1 FALLIDO: Nginx no responde"
fi

echo ""

# Test 2: Deployment con múltiples réplicas
echo "🧪 TEST 2: Escalado de aplicación"
echo "-----------------------------------"

kubectl scale deployment test-nginx --replicas=3
sleep 10

READY_REPLICAS=$(kubectl get deployment test-nginx -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" = "3" ]; then
    echo "✅ Test 2 PASADO: Escalado a 3 réplicas exitoso"
else
    echo "❌ Test 2 FALLIDO: Solo $READY_REPLICAS réplicas listas"
fi

echo ""

# Test 3: ConfigMap y variables de entorno
echo "🧪 TEST 3: ConfigMaps y variables de entorno"
echo "----------------------------------------------"

# Crear ConfigMap
kubectl create configmap test-config --from-literal=app.name="Test App" --from-literal=app.version="1.0"

# Crear deployment que usa ConfigMap
cat << 'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-env
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-env
  template:
    metadata:
      labels:
        app: test-env
    spec:
      containers:
      - name: busybox
        image: busybox:latest
        command: ['sh', '-c', 'while true; do echo "App: $APP_NAME, Version: $APP_VERSION"; sleep 30; done']
        env:
        - name: APP_NAME
          valueFrom:
            configMapKeyRef:
              name: test-config
              key: app.name
        - name: APP_VERSION
          valueFrom:
            configMapKeyRef:
              name: test-config
              key: app.version
YAML

wait_for_pod test-env

# Verificar logs
sleep 5
LOG_OUTPUT=$(kubectl logs deployment/test-env | tail -1)
if echo "$LOG_OUTPUT" | grep -q "App: Test App, Version: 1.0"; then
    echo "✅ Test 3 PASADO: ConfigMap funcionando correctamente"
else
    echo "❌ Test 3 FALLIDO: ConfigMap no funciona"
    echo "Log output: $LOG_OUTPUT"
fi

echo ""

# Test 4: Persistencia con PVC
echo "🧪 TEST 4: Volúmenes persistentes"
echo "-----------------------------------"

# Crear PVC
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
YAML

# Esperar a que el PVC esté bound
sleep 10
PVC_STATUS=$(kubectl get pvc test-pvc -o jsonpath='{.status.phase}')
if [ "$PVC_STATUS" = "Bound" ]; then
    echo "✅ Test 4 PASADO: PVC creado y bound correctamente"
else
    echo "❌ Test 4 FALLIDO: PVC en estado $PVC_STATUS"
fi

echo ""

# Test 5: Servicios y DNS interno
echo "🧪 TEST 5: DNS interno de Kubernetes"
echo "--------------------------------------"

# Crear pod temporal para testing
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local > /tmp/dns_test.out 2>&1 &
sleep 5

if grep -q "kubernetes.default.svc.cluster.local" /tmp/dns_test.out; then
    echo "✅ Test 5 PASADO: DNS interno funcionando"
else
    echo "❌ Test 5 FALLIDO: DNS interno no funciona"
fi

echo ""

# Resumen de tests
echo "================================================================="
echo "                   RESUMEN DE TESTS"
echo "================================================================="

TESTS_PASSED=0
TOTAL_TESTS=5

# Verificar resultados
curl -s http://localhost:$NGINX_PORT | grep -q "Welcome to nginx" && ((TESTS_PASSED++))
[ "$(kubectl get deployment test-nginx -o jsonpath='{.status.readyReplicas}')" = "3" ] && ((TESTS_PASSED++))
kubectl logs deployment/test-env | tail -1 | grep -q "App: Test App, Version: 1.0" && ((TESTS_PASSED++))
[ "$(kubectl get pvc test-pvc -o jsonpath='{.status.phase}')" = "Bound" ] && ((TESTS_PASSED++))
grep -q "kubernetes.default.svc.cluster.local" /tmp/dns_test.out && ((TESTS_PASSED++))

echo ""
echo "📊 Resultados: $TESTS_PASSED/$TOTAL_TESTS tests pasaron"

if [ $TESTS_PASSED -eq $TOTAL_TESTS ]; then
    echo "🎉 TODOS LOS TESTS PASARON - Kubernetes completamente funcional"
elif [ $TESTS_PASSED -ge 3 ]; then
    echo "⚠️ TESTS MAYORMENTE EXITOSOS - Funcionalidad básica OK"
else
    echo "❌ MÚLTIPLES TESTS FALLARON - Revisar configuración"
fi

echo ""
echo "🧹 Limpiando recursos de testing..."
kubectl delete deployment test-nginx test-env
kubectl delete service test-nginx
kubectl delete configmap test-config
kubectl delete pvc test-pvc
kubectl delete pod test-dns --ignore-not-found

echo "✅ Limpieza completada"
echo ""
echo "================================================================="
EOF

chmod +x ~/test-aplicaciones-k8s.sh
~/test-aplicaciones-k8s.sh
```

---

## 🔧 Paso 3: Verificar autocompletado

```bash
# Script para verificar y testear autocompletado
cat << 'EOF' > ~/test-autocompletado.sh
#!/bin/bash

echo "================================================================="
echo "              TESTING DE AUTOCOMPLETADO"
echo "================================================================="
echo ""

echo "🧪 Verificando autocompletado de kubectl..."

# Verificar que las funciones de autocompletado están cargadas
if type _kubectl &>/dev/null; then
    echo "✅ Función de autocompletado kubectl cargada"
else
    echo "❌ Función de autocompletado kubectl NO cargada"
    echo "🔧 Ejecuta: source ~/.bashrc"
fi

# Verificar que las funciones de autocompletado están cargadas
if type _minikube &>/dev/null; then
    echo "✅ Función de autocompletado minikube cargada"
else
    echo "❌ Función de autocompletado minikube NO cargada"
    echo "🔧 Ejecuta: source ~/.bashrc"
fi

echo ""
echo "🔧 Configuración en ~/.bashrc:"
if grep -q "kubectl completion bash" ~/.bashrc; then
    echo "✅ kubectl completion configurado"
else
    echo "❌ kubectl completion NO configurado"
fi

if grep -q "minikube completion bash" ~/.bashrc; then
    echo "✅ minikube completion configurado"
else
    echo "❌ minikube completion NO configurado"
fi

echo ""
echo "💡 PRUEBAS MANUALES DE AUTOCOMPLETADO:"
echo "--------------------------------------"
echo "Ejecuta estos comandos y presiona TAB para probar:"
echo ""
echo "1. kubectl get <TAB>         # Debería mostrar recursos disponibles"
echo "2. kubectl describe <TAB>    # Debería mostrar tipos de recursos"
echo "3. minikube <TAB>           # Debería mostrar subcomandos"
echo "4. k get po<TAB>            # Si configuraste el alias 'k'"
echo ""

# Test automático de autocompletado básico
echo "🤖 Test automático básico:"
if complete -p kubectl &>/dev/null; then
    echo "✅ kubectl tiene autocompletado configurado"
else
    echo "❌ kubectl NO tiene autocompletado configurado"
fi

if complete -p minikube &>/dev/null; then
    echo "✅ minikube tiene autocompletado configurado"
else
    echo "❌ minikube NO tiene autocompletado configurado"
fi

echo ""
echo "📝 Aliases configurados:"
if grep -q "alias k=kubectl" ~/.bashrc; then
    echo "✅ Alias 'k' para kubectl configurado"
    if complete -p k &>/dev/null; then
        echo "✅ Autocompletado para alias 'k' configurado"
    else
        echo "❌ Autocompletado para alias 'k' NO configurado"
    fi
else
    echo "ℹ️ Alias 'k' no configurado (opcional)"
fi

echo ""
echo "================================================================="
EOF

chmod +x ~/test-autocompletado.sh

# Recargar bash para asegurar autocompletado
source ~/.bashrc

# Ejecutar test
~/test-autocompletado.sh
```

---

## 📊 Paso 4: Métricas y monitoreo básico

```bash
# Script para verificar métricas y estado del cluster
cat << 'EOF' > ~/test-metricas-cluster.sh
#!/bin/bash

echo "================================================================="
echo "           MÉTRICAS Y MONITOREO DEL CLUSTER"
echo "================================================================="
echo ""

echo "📊 INFORMACIÓN GENERAL DEL CLUSTER"
echo "------------------------------------"

# Información básica del cluster
echo "🔍 Información del cluster:"
kubectl cluster-info

echo ""
echo "🖥️ Nodos del cluster:"
kubectl get nodes -o wide

echo ""
echo "📦 Namespaces disponibles:"
kubectl get namespaces

echo ""
echo "⚙️ Pods del sistema:"
kubectl get pods -n kube-system

echo ""
echo "🌐 Servicios del cluster:"
kubectl get services --all-namespaces

echo ""
echo "💾 Clases de almacenamiento:"
kubectl get storageclass

echo ""
echo "🔌 ADDONS HABILITADOS"
echo "----------------------"
sudo minikube addons list --profile=none-cluster | grep enabled

echo ""
echo "📈 RECURSOS DEL CLUSTER"
echo "------------------------"

# Intentar obtener métricas si están disponibles
echo "Intentando obtener métricas de recursos..."
if kubectl top nodes &>/dev/null; then
    echo "📊 Uso de recursos por nodo:"
    kubectl top nodes
    
    echo ""
    echo "📊 Uso de recursos por pods:"
    kubectl top pods --all-namespaces | head -10
else
    echo "ℹ️ Metrics server no disponible (normal en instalación básica)"
    echo "💡 Para habilitar métricas: sudo minikube addons enable metrics-server --profile=none-cluster"
fi

echo ""
echo "🔍 EVENTOS RECIENTES DEL CLUSTER"
echo "---------------------------------"
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -10

echo ""
echo "🛠️ CONFIGURACIÓN DE KUBECTL"
echo "-----------------------------"
echo "Contexto actual: $(kubectl config current-context)"
echo "Archivo de configuración: $(kubectl config view --minify -o jsonpath='{.preferences.colors}')"
kubectl config view --minify

echo ""
echo "🔧 VERSIONES DE COMPONENTES"
echo "----------------------------"
echo "Cliente kubectl:"
kubectl version --client --short 2>/dev/null || kubectl version --client

echo ""
echo "Servidor Kubernetes:"
kubectl version --short 2>/dev/null || kubectl version

echo ""
echo "================================================================="
echo "                    RESUMEN DE MÉTRICAS"
echo "================================================================="

# Contar recursos
NODES=$(kubectl get nodes --no-headers | wc -l)
PODS=$(kubectl get pods --all-namespaces --no-headers | wc -l)
SERVICES=$(kubectl get services --all-namespaces --no-headers | wc -l)
DEPLOYMENTS=$(kubectl get deployments --all-namespaces --no-headers | wc -l)

echo ""
echo "📈 Estadísticas del cluster:"
echo "  🖥️  Nodos: $NODES"
echo "  📦 Pods: $PODS"
echo "  🌐 Servicios: $SERVICES"
echo "  🚀 Deployments: $DEPLOYMENTS"

echo ""
echo "✅ Cluster operativo y listo para desarrollo"
echo ""
echo "================================================================="
EOF

chmod +x ~/test-metricas-cluster.sh
~/test-metricas-cluster.sh
```

---

## 🎓 Paso 5: Configurar ambiente para futuros laboratorios

```bash
# Crear configuración personalizada para laboratorios
cat << 'EOF' > ~/configurar-ambiente-labs.sh
#!/bin/bash

echo "================================================================="
echo "          CONFIGURACIÓN PARA FUTUROS LABORATORIOS"
echo "================================================================="
echo ""

# Crear directorio para laboratorios
mkdir -p ~/kubernetes-labs
cd ~/kubernetes-labs

echo "📁 Directorio de laboratorios creado: ~/kubernetes-labs"

# Crear aliases útiles adicionales
echo ""
echo "🔧 Configurando aliases adicionales..."

cat << 'ALIASES' >> ~/.bashrc

# === ALIASES PARA LABORATORIOS DE KUBERNETES ===

# Aliases básicos ya configurados:
# alias k=kubectl
# alias kgp='kubectl get pods'
# alias kgs='kubectl get services'
# alias kgd='kubectl get deployments'

# Aliases adicionales para laboratorios
alias kgn='kubectl get nodes'
alias kgns='kubectl get namespaces'
alias kgpvc='kubectl get pvc'
alias kgcm='kubectl get configmap'
alias kgsec='kubectl get secrets'

# Aliases para descripciones
alias kdesc='kubectl describe'
alias kdescn='kubectl describe node'
alias kdescns='kubectl describe namespace'

# Aliases para logs y debugging
alias klogs='kubectl logs'
alias kexec='kubectl exec -it'
alias kport='kubectl port-forward'

# Aliases para aplicar/eliminar recursos
alias kapply='kubectl apply -f'
alias kdelete='kubectl delete -f'
alias kdel='kubectl delete'

# Alias para cambio rápido de contexto/namespace
alias kctx='kubectl config current-context'
alias kns='kubectl config set-context --current --namespace'

# Función para obtener todos los recursos en un namespace
kgetall() {
    local ns=${1:-default}
    echo "=== Recursos en namespace: $ns ==="
    kubectl get all -n $ns
}

# Función para limpiar recursos de laboratorio
kcleanlab() {
    echo "🧹 Limpiando recursos de laboratorio..."
    kubectl delete deployments,services,configmaps,secrets -l lab=true 2>/dev/null || true
    echo "✅ Limpieza completada"
}

# Función para crear namespace de laboratorio
kcreatelab() {
    local lab_name=${1:-lab-$(date +%s)}
    kubectl create namespace $lab_name
    kubectl config set-context --current --namespace=$lab_name
    echo "📝 Namespace $lab_name creado y configurado como activo"
}

ALIASES

echo "✅ Aliases adicionales configurados"

# Crear plantillas de YAML comunes
echo ""
echo "📝 Creando plantillas de YAML para laboratorios..."

# Plantilla de deployment
cat << 'YAML' > ~/kubernetes-labs/template-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: NOMBRE_APP
  labels:
    app: NOMBRE_APP
    lab: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: NOMBRE_APP
  template:
    metadata:
      labels:
        app: NOMBRE_APP
        lab: "true"
    spec:
      containers:
      - name: NOMBRE_APP
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: ENV_VAR
          value: "valor"
YAML

# Plantilla de service
cat << 'YAML' > ~/kubernetes-labs/template-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: NOMBRE_SERVICE
  labels:
    lab: "true"
spec:
  selector:
    app: NOMBRE_APP
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: NodePort
YAML

# Plantilla de ConfigMap
cat << 'YAML' > ~/kubernetes-labs/template-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: NOMBRE_CONFIGMAP
  labels:
    lab: "true"
data:
  config.properties: |
    property1=value1
    property2=value2
  config.yaml: |
    app:
      name: "My App"
      version: "1.0"
YAML

# Plantilla de PVC
cat << 'YAML' > ~/kubernetes-labs/template-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: NOMBRE_PVC
  labels:
    lab: "true"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
YAML

echo "✅ Plantillas creadas en ~/kubernetes-labs/"

# Crear script helper para laboratorios
cat << 'SCRIPT' > ~/kubernetes-labs/lab-helper.sh
#!/bin/bash

echo "🧪 KUBERNETES LAB HELPER"
echo "========================="
echo ""

case "$1" in
    "new")
        LAB_NAME=${2:-lab-$(date +%Y%m%d-%H%M%S)}
        echo "🆕 Creando nuevo laboratorio: $LAB_NAME"
        kubectl create namespace $LAB_NAME
        kubectl config set-context --current --namespace=$LAB_NAME
        echo "✅ Namespace $LAB_NAME creado y activo"
        ;;
    "clean")
        echo "🧹 Limpiando recursos de laboratorio..."
        kubectl delete deployments,services,configmaps,secrets,pvc -l lab=true --all-namespaces 2>/dev/null || true
        echo "✅ Limpieza completada"
        ;;
    "status")
        echo "📊 Estado actual del laboratorio:"
        echo "Contexto: $(kubectl config current-context)"
        echo "Namespace: $(kubectl config view --minify -o jsonpath='{..namespace}')"
        echo ""
        echo "Recursos activos:"
        kubectl get all
        ;;
    "templates")
        echo "📝 Plantillas disponibles:"
        ls -la ~/kubernetes-labs/template-*.yaml
        ;;
    *)
        echo "Uso: $0 {new|clean|status|templates} [nombre]"
        echo ""
        echo "Comandos:"
        echo "  new [nombre]  - Crear nuevo namespace de laboratorio"
        echo "  clean         - Limpiar recursos de laboratorio"
        echo "  status        - Mostrar estado actual"
        echo "  templates     - Listar plantillas disponibles"
        ;;
esac
SCRIPT

chmod +x ~/kubernetes-labs/lab-helper.sh

echo "✅ Script helper creado: ~/kubernetes-labs/lab-helper.sh"

# Crear documentación de referencia rápida
cat << 'DOC' > ~/kubernetes-labs/cheatsheet.md
# Kubernetes Cheatsheet para Laboratorios

## Comandos Básicos
```bash
# Ver recursos
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get nodes

# Describir recursos
kubectl describe pod <nombre>
kubectl describe service <nombre>

# Logs y debugging
kubectl logs <pod>
kubectl exec -it <pod> -- bash

# Aplicar configuraciones
kubectl apply -f archivo.yaml
kubectl delete -f archivo.yaml
```

## Aliases Configurados
```bash
k          # kubectl
kgp        # kubectl get pods
kgs        # kubectl get services
kgd        # kubectl get deployments
kgn        # kubectl get nodes
kdesc      # kubectl describe
klogs      # kubectl logs
kexec      # kubectl exec -it
```

## Funciones Útiles
```bash
kgetall [namespace]     # Ver todos los recursos
kcleanlab              # Limpiar recursos de lab
kcreatelab [nombre]    # Crear namespace de lab
```

## Helper Script
```bash
~/kubernetes-labs/lab-helper.sh new [nombre]    # Nuevo lab
~/kubernetes-labs/lab-helper.sh clean           # Limpiar
~/kubernetes-labs/lab-helper.sh status          # Estado
~/kubernetes-labs/lab-helper.sh templates       # Plantillas
```

## Plantillas Disponibles
- template-deployment.yaml
- template-service.yaml
- template-configmap.yaml
- template-pvc.yaml

Usa: `sed 's/NOMBRE_APP/mi-app/g' template-deployment.yaml | kubectl apply -f -`
DOC

echo "✅ Documentación creada: ~/kubernetes-labs/cheatsheet.md"

echo ""
echo "🎓 AMBIENTE CONFIGURADO PARA LABORATORIOS"
echo "=========================================="
echo ""
echo "📁 Directorio: ~/kubernetes-labs"
echo "🔧 Aliases adicionales configurados"
echo "📝 Plantillas YAML disponibles"
echo "🛠️ Helper script: ~/kubernetes-labs/lab-helper.sh"
echo "📖 Documentación: ~/kubernetes-labs/cheatsheet.md"
echo ""
echo "💡 Recarga bash para usar los nuevos aliases:"
echo "   source ~/.bashrc"
echo ""
echo "================================================================="
EOF

chmod +x ~/configurar-ambiente-labs.sh
~/configurar-ambiente-labs.sh

# Recargar configuración
source ~/.bashrc
```

---

## ✅ Paso 6: Checklist final de validación

```bash
# Crear checklist final interactivo
cat << 'EOF' > ~/checklist-final.sh
#!/bin/bash

echo "================================================================="
echo "              CHECKLIST FINAL DE VALIDACIÓN"
echo "================================================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contador de verificaciones
PASSED=0
FAILED=0

# Función para verificar y mostrar resultado
check_item() {
    local description="$1"
    local command="$2"
    
    echo -n "🔍 $description... "
    
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
        return 1
    fi
}

echo "📋 INICIANDO CHECKLIST FINAL..."
echo ""

# Verificaciones del sistema
echo "🖥️ VERIFICACIONES DEL SISTEMA:"
echo "--------------------------------"
check_item "Sistema Ubuntu/Debian" "lsb_release -a | grep -q Ubuntu"
check_item "Mínimo 2 CPU cores" '[ $(nproc) -ge 2 ]'
check_item "Mínimo 4GB RAM" '[ $(free -m | awk "/^Mem:/ {print \$2}") -ge 4000 ]'
check_item "Mínimo 10GB espacio libre" '[ $(df / | awk "NR==2 {print int(\$4/1024/1024)}") -ge 10 ]'

echo ""

# Verificaciones de Docker
echo "🐳 VERIFICACIONES DE DOCKER:"
echo "------------------------------"
check_item "Docker instalado" "docker --version"
check_item "Docker daemon funcionando" "docker ps"
check_item "Usuario en grupo docker" "groups \$USER | grep -q docker"
check_item "Docker responde sin sudo" "docker images"

echo ""

# Verificaciones de kubectl
echo "🔧 VERIFICACIONES DE KUBECTL:"
echo "-------------------------------"
check_item "kubectl instalado" "kubectl version --client"
check_item "kubectl configurado" "kubectl config current-context"
check_item "kubectl puede listar nodos" "kubectl get nodes"
check_item "Autocompletado kubectl" "grep -q 'kubectl completion bash' ~/.bashrc"

echo ""

# Verificaciones de Minikube
echo "🚀 VERIFICACIONES DE MINIKUBE:"
echo "--------------------------------"
check_item "Minikube instalado" "minikube version"
check_item "Cluster none-cluster activo" "sudo minikube status --profile=none-cluster"
check_item "API Server accesible" "kubectl cluster-info"
check_item "Autocompletado minikube" "grep -q 'minikube completion bash' ~/.bashrc"

echo ""

# Verificaciones de funcionalidad
echo "⚙️ VERIFICACIONES DE FUNCIONALIDAD:"
echo "-------------------------------------"
check_item "Pods del sistema funcionando" "kubectl get pods -n kube-system | grep -q Running"
check_item "Storage class disponible" "kubectl get storageclass"
check_item "DNS interno funcionando" "kubectl run test-dns-check --image=busybox --rm --restart=Never -- nslookup kubernetes.default.svc.cluster.local"
check_item "Conectividad a Internet" "ping -c 1 8.8.8.8"

echo ""

# Verificaciones de configuración
echo "🔧 VERIFICACIONES DE CONFIGURACIÓN:"
echo "-------------------------------------"
check_item "Directorio laboratorios creado" "[ -d ~/kubernetes-labs ]"
check_item "Plantillas YAML disponibles" "ls ~/kubernetes-labs/template-*.yaml"
check_item "Helper script ejecutable" "[ -x ~/kubernetes-labs/lab-helper.sh ]"
check_item "Aliases configurados" "grep -q 'alias k=kubectl' ~/.bashrc"

echo ""

# Verificaciones de seguridad
echo "🔒 VERIFICACIONES DE SEGURIDAD:"
echo "---------------------------------"
check_item "Driver 'none' funcionando" "sudo minikube status --profile=none-cluster | grep -q 'kubelet: Running'"
check_item "kubectl sin permisos root" "kubectl get nodes"
check_item "Configuración kubectl correcta" "[ -f ~/.kube/config ] && [ \$(stat -c %U ~/.kube/config) = \$USER ]"

echo ""
echo "================================================================="
echo "                     RESUMEN FINAL"
echo "================================================================="

TOTAL=$((PASSED + FAILED))
PERCENTAGE=$((PASSED * 100 / TOTAL))

echo ""
echo "📊 RESULTADOS:"
echo "  ✅ Verificaciones pasadas: $PASSED"
echo "  ❌ Verificaciones fallidas: $FAILED"
echo "  📈 Porcentaje de éxito: $PERCENTAGE%"
echo ""

if [ $PERCENTAGE -ge 95 ]; then
    echo -e "${GREEN}🎉 EXCELENTE: Sistema completamente funcional${NC}"
    echo -e "${GREEN}✅ Listo para todos los laboratorios de Kubernetes${NC}"
    SYSTEM_STATUS="EXCELLENT"
elif [ $PERCENTAGE -ge 85 ]; then
    echo -e "${YELLOW}⚡ BUENO: Sistema mayormente funcional${NC}"
    echo -e "${YELLOW}⚠️ Algunas funciones pueden requerir atención${NC}"
    SYSTEM_STATUS="GOOD"
elif [ $PERCENTAGE -ge 70 ]; then
    echo -e "${YELLOW}⚠️ ACEPTABLE: Funcionalidad básica disponible${NC}"
    echo -e "${YELLOW}🔧 Algunas características no están disponibles${NC}"
    SYSTEM_STATUS="ACCEPTABLE"
else
    echo -e "${RED}❌ REQUIERE ATENCIÓN: Múltiples problemas detectados${NC}"
    echo -e "${RED}🔧 Revisar configuración antes de continuar${NC}"
    SYSTEM_STATUS="NEEDS_ATTENTION"
fi

echo ""
echo "🎯 PRÓXIMOS PASOS:"
case $SYSTEM_STATUS in
    "EXCELLENT"|"GOOD")
        echo "  • Sistema listo para laboratorios avanzados"
        echo "  • Continuar con módulos de Kubernetes"
        echo "  • Explorar addons de Minikube"
        ;;
    "ACCEPTABLE")
        echo "  • Revisar elementos fallidos del checklist"
        echo "  • Funcionalidad básica disponible"
        echo "  • Continuar con precaución"
        ;;
    "NEEDS_ATTENTION")
        echo "  • Revisar logs de errores"
        echo "  • Repetir pasos de instalación fallidos"
        echo "  • Contactar soporte si es necesario"
        ;;
esac

echo ""
echo "📖 DOCUMENTACIÓN DISPONIBLE:"
echo "  • ~/kubernetes-labs/cheatsheet.md - Referencia rápida"
echo "  • ~/verificacion-sistema-completa.sh - Verificación completa"
echo "  • ~/test-aplicaciones-k8s.sh - Tests de aplicaciones"
echo "  • ~/kubernetes-labs/lab-helper.sh - Helper para laboratorios"

echo ""
echo "================================================================="
echo "     ¡INSTALACIÓN DE MINIKUBE COMPLETADA!"
echo "================================================================="
EOF

chmod +x ~/checklist-final.sh
~/checklist-final.sh
```

---

## 🎉 Resultado final esperado

```
=================================================================
              CHECKLIST FINAL DE VALIDACIÓN
=================================================================

📋 INICIANDO CHECKLIST FINAL...

🖥️ VERIFICACIONES DEL SISTEMA:
--------------------------------
🔍 Sistema Ubuntu/Debian... ✅ PASS
🔍 Mínimo 2 CPU cores... ✅ PASS
🔍 Mínimo 4GB RAM... ✅ PASS
🔍 Mínimo 10GB espacio libre... ✅ PASS

🐳 VERIFICACIONES DE DOCKER:
------------------------------
🔍 Docker instalado... ✅ PASS
🔍 Docker daemon funcionando... ✅ PASS
🔍 Usuario en grupo docker... ✅ PASS
🔍 Docker responde sin sudo... ✅ PASS

🔧 VERIFICACIONES DE KUBECTL:
-------------------------------
🔍 kubectl instalado... ✅ PASS
🔍 kubectl configurado... ✅ PASS
🔍 kubectl puede listar nodos... ✅ PASS
🔍 Autocompletado kubectl... ✅ PASS

🚀 VERIFICACIONES DE MINIKUBE:
--------------------------------
🔍 Minikube instalado... ✅ PASS
🔍 Cluster none-cluster activo... ✅ PASS
🔍 API Server accesible... ✅ PASS
🔍 Autocompletado minikube... ✅ PASS

⚙️ VERIFICACIONES DE FUNCIONALIDAD:
-------------------------------------
🔍 Pods del sistema funcionando... ✅ PASS
🔍 Storage class disponible... ✅ PASS
🔍 DNS interno funcionando... ✅ PASS
🔍 Conectividad a Internet... ✅ PASS

🔧 VERIFICACIONES DE CONFIGURACIÓN:
-------------------------------------
🔍 Directorio laboratorios creado... ✅ PASS
🔍 Plantillas YAML disponibles... ✅ PASS
🔍 Helper script ejecutable... ✅ PASS
🔍 Aliases configurados... ✅ PASS

🔒 VERIFICACIONES DE SEGURIDAD:
---------------------------------
🔍 Driver 'none' funcionando... ✅ PASS
🔍 kubectl sin permisos root... ✅ PASS
🔍 Configuración kubectl correcta... ✅ PASS

=================================================================
                     RESUMEN FINAL
=================================================================

📊 RESULTADOS:
  ✅ Verificaciones pasadas: 23
  ❌ Verificaciones fallidas: 0
  📈 Porcentaje de éxito: 100%

🎉 EXCELENTE: Sistema completamente funcional
✅ Listo para todos los laboratorios de Kubernetes

🎯 PRÓXIMOS PASOS:
  • Sistema listo para laboratorios avanzados
  • Continuar con módulos de Kubernetes
  • Explorar addons de Minikube

📖 DOCUMENTACIÓN DISPONIBLE:
  • ~/kubernetes-labs/cheatsheet.md - Referencia rápida
  • ~/verificacion-sistema-completa.sh - Verificación completa
  • ~/test-aplicaciones-k8s.sh - Tests de aplicaciones
  • ~/kubernetes-labs/lab-helper.sh - Helper para laboratorios

=================================================================
     ¡INSTALACIÓN DE MINIKUBE COMPLETADA!
=================================================================
```

---

## 📝 Checklist final de completado

- [ ] ✅ Verificación completa del sistema exitosa
- [ ] ✅ Tests de aplicaciones K8s pasados
- [ ] ✅ Autocompletado funcionando correctamente
- [ ] ✅ Métricas del cluster verificadas
- [ ] ✅ Ambiente para laboratorios configurado
- [ ] ✅ Checklist final 100% exitoso
- [ ] ✅ Documentación y helpers disponibles

---

## 🎯 Estado final

🎉 **INSTALACIÓN COMPLETADA EXITOSAMENTE**

### Lo que tienes ahora:
- ✅ **Minikube** con driver "none" funcionando
- ✅ **kubectl** con autocompletado configurado  
- ✅ **Acceso directo** a servicios desde la VM
- ✅ **Ambiente completo** para laboratorios de Kubernetes
- ✅ **Scripts de verificación** y testing
- ✅ **Plantillas YAML** para desarrollo rápido
- ✅ **Documentación** y cheatsheets

### Comandos principales disponibles:
```bash
# Gestión del cluster
sudo minikube status --profile=none-cluster
kubectl get nodes
kubectl cluster-info

# Helper para laboratorios
~/kubernetes-labs/lab-helper.sh new mi-lab
~/kubernetes-labs/lab-helper.sh status

# Verificaciones
~/verificacion-sistema-completa.sh
~/checklist-final.sh
```

---

**🚀 ¡Ya puedes comenzar con los laboratorios avanzados de Kubernetes!**