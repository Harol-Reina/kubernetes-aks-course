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
echo "💡 Ejecuta en otra terminal para acceder al servicio:"
echo ""
echo "kubectl port-forward service/test-web 8080:80"
echo ""
echo "Luego accede a: http://localhost:8080"

# Crear script para port-forwarding automático
cat << 'EOF' > ~/port-forward-test.sh
#!/bin/bash
echo "🚀 Iniciando port-forwarding para test-web..."
echo "📌 Accede a http://localhost:8080"
echo "⏹️ Presiona Ctrl+C para detener"
kubectl port-forward service/test-web 8080:80
EOF

chmod +x ~/port-forward-test.sh

echo "📋 Script creado: ~/port-forward-test.sh"
echo "🔧 Para probar el servicio, ejecuta: ~/port-forward-test.sh"

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
