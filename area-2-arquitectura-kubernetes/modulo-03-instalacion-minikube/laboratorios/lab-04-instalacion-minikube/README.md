# Lab 3.4: Instalación de Minikube

**Duración**: 20 minutos  
**Objetivo**: Instalar Minikube con soporte para múltiples drivers y preparar para configuración "docker"

## 🎯 Objetivos

- Instalar Minikube en VM Azure
- Configurar drivers disponibles
- Entender diferencias entre drivers
- Preparar para configuración driver "docker"

---

## 📋 Prerequisitos

- Docker instalado y funcionando (Lab 3.2)
- kubectl instalado y configurado (Lab 3.3)
- VM con al menos 2 CPU y 4GB RAM
- Usuario con permisos sudo

---

## 📥 Paso 1: Descargar e instalar Minikube

```bash
# Obtener la última versión de Minikube
MINIKUBE_VERSION=$(curl -s "https://api.github.com/repos/kubernetes/minikube/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "Última versión de Minikube: $MINIKUBE_VERSION"

# Descargar Minikube
curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"

# Verificar descarga
ls -la minikube-linux-amd64

# Instalar Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Limpiar archivo descargado
rm minikube-linux-amd64

# Verificar instalación
minikube version
```

**Salida esperada:**
```
minikube version: v1.32.0
commit: 8220a6eb95f0a4d75f7f2d7b14cef975f050512d
```

---

## 🔧 Paso 2: Configurar autocompletado de Minikube

```bash
# Configurar autocompletado para bash
echo 'source <(minikube completion bash)' >> ~/.bashrc

# Recargar configuración
source ~/.bashrc

# Verificar que funciona (probar con TAB)
echo "Prueba escribir 'minikube ' y presiona TAB para ver opciones"
```

---

## 🎛️ Paso 3: Configurar drivers disponibles

### **Información sobre drivers**

```bash
# Ver todos los drivers disponibles
minikube start --help | grep -A 20 "driver string"

# Verificar drivers compatibles en el sistema
minikube config set driver docker    # Para usar Docker
echo "Driver por defecto configurado: docker"

# Ver configuración actual
minikube config view
```

### **Configuración de Docker driver**

```bash
# Verificar que Docker funciona
docker --version
docker ps

# Verificar que el usuario puede usar Docker sin sudo
groups $USER | grep docker || echo "⚠️ Usuario no está en grupo docker"

# Si no está en el grupo docker, agregarlo
if ! groups $USER | grep -q docker; then
    echo "Agregando usuario al grupo docker..."
    sudo usermod -aG docker $USER
    echo "⚠️ Debes cerrar sesión y volver a conectar para aplicar cambios"
    echo "O ejecutar: newgrp docker"
fi
```

### **Verificar requisitos para driver "docker"**

```bash
# El driver "docker" requiere Docker funcionando
echo "=== VERIFICANDO REQUISITOS PARA DRIVER 'DOCKER' ==="

# Verificar que Docker está funcionando
if docker version &>/dev/null; then
    echo "✅ Docker está funcionando"
else
    echo "❌ Docker no está funcionando"
    echo "🔧 Iniciando Docker..."
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Verificar que el usuario está en el grupo docker
if groups | grep -q docker; then
    echo "✅ Usuario en grupo docker"
else
    echo "⚠️ Agregando usuario al grupo docker..."
    sudo usermod -aG docker $USER
    echo "💡 Necesitas cerrar sesión y volver a entrar"
fi

# Verificar conectividad de Docker
if docker ps &>/dev/null; then
    echo "✅ Docker accesible sin sudo"
else
    echo "⚠️ Aplicando permisos de grupo docker..."
    newgrp docker
fi

# Verificar conectividad de red
echo "Verificando conectividad de red:"
ping -c 2 8.8.8.8

# Verificar espacio en disco
echo "Verificando espacio en disco:"
df -h /

echo ""
echo "📌 El driver 'docker' se configurará en el siguiente laboratorio"
```

---

## 🧪 Paso 4: Crear perfil de prueba con Docker driver

```bash
# Crear cluster de prueba para verificar instalación
echo "=== CREANDO CLUSTER DE PRUEBA CON DOCKER DRIVER ==="

# Iniciar Minikube con Docker driver (perfil de prueba)
minikube start --driver=docker --profile=test-docker

# Verificar estado del cluster
minikube status --profile=test-docker

# Verificar nodos
kubectl get nodes

# Verificar pods del sistema
kubectl get pods --all-namespaces

# Verificar configuración de kubectl
kubectl config current-context

# Obtener información del cluster
kubectl cluster-info
```

**Salida esperada:**
```
✅ Using the docker driver based on existing profile
✅ Starting control plane node test-docker in cluster test-docker
🚀 Pulling base image...
🔥 Creating docker container (CPUs=2, Memory=4000MB)...
🐳 Preparing Kubernetes v1.28.3 on Docker 24.0.7...
    ▪ Generating certificates and keys...
    ▪ Booting up control plane...
🔗 Configuring bridge CNI (Container Networking Interface)...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🔎 Verifying Kubernetes components...
🌟 Enabled addons: default-storageclass, storage-provisioner
🏄 Done! kubectl is now configured to use "test-docker" cluster.
```

---

## 🔍 Paso 5: Explorar cluster de prueba

```bash
# Ver información detallada del cluster
echo "=== EXPLORANDO CLUSTER DE PRUEBA ==="

# Ver configuración del contexto
kubectl config view

# Ver nodos con más detalle
kubectl get nodes -o wide

# Ver todos los namespaces
kubectl get namespaces

# Ver servicios del sistema
kubectl get services --all-namespaces

# Ver deployments del sistema
kubectl get deployments --all-namespaces

# Ver pods del sistema con más detalle
kubectl get pods --all-namespaces -o wide

# Probar creación de recurso simple
kubectl create deployment test-nginx --image=nginx:alpine
kubectl get deployments
kubectl get pods

# Limpiar recurso de prueba
kubectl delete deployment test-nginx
```

---

## 🛑 Paso 6: Detener cluster de prueba

```bash
# Detener cluster de prueba
echo "=== DETENIENDO CLUSTER DE PRUEBA ==="

minikube stop --profile=test-docker

# Verificar estado
minikube status --profile=test-docker

# Ver perfiles disponibles
minikube profile list

# Eliminar perfil de prueba (opcional)
read -p "¿Eliminar perfil de prueba? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    minikube delete --profile=test-docker
    echo "Perfil de prueba eliminado"
else
    echo "Perfil de prueba mantenido para referencia"
fi
```

---

## 🔧 Paso 7: Configurar perfiles para diferentes drivers

```bash
# Crear configuración para diferentes drivers
echo "=== CONFIGURANDO PERFILES PARA DIFERENTES DRIVERS ==="

# Configurar perfil para Docker driver
minikube config set profile docker-profile
minikube config set driver docker
minikube config set memory 4096
minikube config set cpus 2

# Ver configuración actual
minikube config view

# Preparar configuración para driver "docker" (siguiente lab)
echo "Preparando configuración para driver 'docker'..."

# Crear script helper para cambio rápido de perfiles
cat << 'EOF' > ~/minikube-profiles.sh
# !/bin/bash

echo "=== PERFILES DE MINIKUBE DISPONIBLES ==="
echo ""

case "$1" in
    "docker")
        echo "🐳 Configurando perfil Docker..."
        minikube config set profile docker-cluster
        minikube config set driver docker
        minikube config set memory 4096
        minikube config set cpus 2
        echo "Perfil Docker configurado"
        ;;
    "vbox")
        echo "�️ Configurando perfil VirtualBox..."
        minikube config set profile virtualbox-cluster
        minikube config set driver virtualbox
        minikube config set memory 4096
        minikube config set cpus 2
        echo "Perfil VirtualBox configurado"
        ;;
    "list")
        echo "📋 Perfiles disponibles:"
        minikube profile list
        echo ""
        echo "💡 Configuración actual:"
        minikube config view
        ;;
    *)
        echo "Uso: $0 {docker|vbox|list}"
        echo ""
        echo "Perfiles disponibles:"
        echo "  docker  - Usar Docker como driver (recomendado)"
        echo "  vbox    - Usar VirtualBox como driver"
        echo "  list    - Mostrar perfiles existentes"
        ;;
esac
EOF

chmod +x ~/minikube-profiles.sh

# Probar script
~/minikube-profiles.sh list
```

---

## 📊 Paso 8: Verificar instalación completa

```bash
# Crear script de verificación completa
cat << 'EOF' > ~/verificar-minikube.sh
# !/bin/bash

echo "=== VERIFICACIÓN COMPLETA DE MINIKUBE ==="
echo ""

# Verificar versión de Minikube
echo "📋 Versión de Minikube:"
minikube version

# Verificar ubicación del binario
echo ""
echo "📍 Ubicación del binario:"
which minikube

# Verificar permisos
echo ""
echo "🔐 Permisos del binario:"
ls -la $(which minikube)

# Verificar configuración
echo ""
echo "⚙️ Configuración actual:"
minikube config view

# Verificar perfiles
echo ""
echo "📂 Perfiles existentes:"
minikube profile list 2>/dev/null || echo "No hay perfiles creados aún"

# Verificar drivers disponibles
echo ""
echo "🎛️ Verificando drivers disponibles:"

# Docker
if docker --version &>/dev/null; then
    echo "✅ Docker driver disponible"
    docker --version | head -1
else
    echo "❌ Docker driver no disponible"
fi

# VirtualBox (si está instalado)
if which VBoxManage &>/dev/null; then
    echo "✅ VirtualBox driver disponible"
    VBoxManage --version | head -1
else
    echo "ℹ️ VirtualBox driver no instalado (opcional)"
fi

# Driver hypervisor adicionales (verificar requisitos)
if which kvm-ok &>/dev/null; then
    echo "✅ KVM driver potencialmente disponible"
    kvm-ok 2>/dev/null || echo "ℹ️ KVM no está configurado"
else
    echo "ℹ️ KVM driver no instalado (opcional)"
fi

# Verificar kubectl
echo ""
echo "🔧 Verificando kubectl:"
if kubectl version --client &>/dev/null; then
    echo "✅ kubectl está instalado"
    kubectl version --client --short 2>/dev/null || kubectl version --client | grep "Client Version"
else
    echo "❌ kubectl no está instalado"
fi

# Verificar autocompletado
echo ""
echo "💡 Verificando autocompletado:"
if grep -q "minikube completion bash" ~/.bashrc; then
    echo "✅ Autocompletado de Minikube configurado"
else
    echo "❌ Autocompletado de Minikube no configurado"
fi

# Verificar recursos del sistema
echo ""
echo "💻 Recursos del sistema:"
echo "CPU: $(nproc) cores"
echo "RAM: $(free -h | awk '/^Mem:/ {print $2}') total"
echo "Disco libre: $(df -h / | awk 'NR==2 {print $4}') en /"

# Verificar red
echo ""
echo "🌐 Conectividad de red:"
if ping -c 1 8.8.8.8 &>/dev/null; then
    echo "✅ Conectividad a Internet OK"
else
    echo "❌ Sin conectividad a Internet"
fi

echo ""
echo "=== RESUMEN ==="
if which minikube &>/dev/null && docker --version &>/dev/null; then
    echo "🎉 Minikube está correctamente instalado!"
    echo "📌 Listo para crear clusters de Kubernetes"
    echo ""
    echo "Próximos pasos:"
    echo "  - Lab 3.5: Configurar driver 'docker'"
    echo "  - Lab 3.6: Verificar funcionamiento completo"
else
    echo "⚠️ Minikube requiere configuración adicional"
fi
EOF

# Ejecutar verificación
chmod +x ~/verificar-minikube.sh
~/verificar-minikube.sh
```

---

## 📖 Paso 9: Comandos útiles de Minikube

```bash
# Crear cheat sheet de comandos útiles
cat << 'EOF' > ~/minikube-cheatsheet.sh
# !/bin/bash

echo "=== COMANDOS ÚTILES DE MINIKUBE ==="
echo ""

echo "🚀 Gestión de clusters:"
echo "  minikube start                    # Iniciar cluster por defecto"
echo "  minikube start --driver=docker   # Iniciar con driver específico"
echo "  minikube stop                    # Detener cluster"
echo "  minikube delete                  # Eliminar cluster"
echo "  minikube pause                   # Pausar cluster"
echo "  minikube unpause                 # Reanudar cluster"
echo ""

echo "📊 Información y estado:"
echo "  minikube status                  # Ver estado del cluster"
echo "  minikube version                 # Ver versión de Minikube"
echo "  minikube ip                      # Obtener IP del cluster"
echo "  minikube profile list            # Listar perfiles"
echo "  minikube config view             # Ver configuración"
echo ""

echo "🔧 Configuración:"
echo "  minikube config set driver docker        # Configurar driver"
echo "  minikube config set memory 4096          # Configurar memoria"
echo "  minikube config set cpus 2               # Configurar CPUs"
echo "  minikube config set profile mi-cluster   # Configurar perfil"
echo ""

echo "🌐 Servicios y acceso:"
echo "  minikube service list            # Listar servicios expuestos"
echo "  minikube service <nombre>        # Abrir servicio en navegador"
echo "  minikube tunnel                  # Crear túnel para LoadBalancer"
echo "  minikube dashboard               # Abrir dashboard de Kubernetes"
echo ""

echo "🔌 Addons:"
echo "  minikube addons list             # Listar addons disponibles"
echo "  minikube addons enable <addon>   # Habilitar addon"
echo "  minikube addons disable <addon>  # Deshabilitar addon"
echo ""

echo "🐛 Troubleshooting:"
echo "  minikube logs                    # Ver logs del cluster"
echo "  minikube ssh                     # Conectar por SSH al nodo"
echo "  minikube docker-env              # Configurar Docker para usar Minikube"
echo ""

echo "📂 Perfiles múltiples:"
echo "  minikube start --profile=dev     # Iniciar cluster con perfil específico"
echo "  minikube stop --profile=dev      # Detener cluster específico"
echo "  minikube profile dev              # Cambiar a perfil específico"
echo ""

echo "💡 Para usar estos comandos, simplemente copia y pega el que necesites"
EOF

chmod +x ~/minikube-cheatsheet.sh

# Mostrar cheat sheet
~/minikube-cheatsheet.sh
```

---

## ✅ Resultado esperado

```
=== VERIFICACIÓN COMPLETA DE MINIKUBE ===

📋 Versión de Minikube:
minikube version: v1.32.0
commit: 8220a6eb95f0a4d75f7f2d7b14cef975f050512d

📍 Ubicación del binario:
/usr/local/bin/minikube

🔐 Permisos del binario:
-rwxr-xr-x 1 root root 81235968 Nov  5 12:30 /usr/local/bin/minikube

⚙️ Configuración actual:
- driver: docker
- memory: 4096
- cpus: 2

🎛️ Verificando drivers disponibles:
✅ Docker driver disponible
Docker version 24.0.7, build afdd53b
ℹ️ VirtualBox driver no instalado (opcional)
✅ KVM driver potencialmente disponible

🔧 Verificando kubectl:
✅ kubectl está instalado
Client Version: v1.28.4

💡 Verificando autocompletado:
✅ Autocompletado de Minikube configurado

💻 Recursos del sistema:
CPU: 4 cores
RAM: 8.0Gi total
Disco libre: 25G en /

🌐 Conectividad de red:
✅ Conectividad a Internet OK

=== RESUMEN ===
🎉 Minikube está correctamente instalado!
📌 Listo para crear clusters de Kubernetes

Próximos pasos:
  - Lab 3.5: Configurar driver 'docker'
  - Lab 3.6: Verificar funcionamiento completo
```

---

## 🔧 Troubleshooting

### **Error: Permission denied**
```bash
# Verificar permisos del binario
ls -la /usr/local/bin/minikube

# Corregir permisos
sudo chmod +x /usr/local/bin/minikube
```

### **Error: Docker daemon not running**
```bash
# Verificar estado de Docker
sudo systemctl status docker

# Iniciar Docker si está parado
sudo systemctl start docker
sudo systemctl enable docker

# Verificar que el usuario está en el grupo docker
groups $USER | grep docker
```

### **Error: Insufficient resources**
```bash
# Verificar recursos disponibles
free -h
nproc

# Ajustar configuración de Minikube
minikube config set memory 2048
minikube config set cpus 1
```

### **Error: Cannot download kubectl**
```bash
# Verificar conectividad
ping -c 3 storage.googleapis.com

# Usar mirror alternativo
minikube start --kubernetes-version=stable
```

---

## 📝 Checklist de completado

- [ ] Minikube instalado correctamente
- [ ] Autocompletado configurado
- [ ] Docker driver verificado
- [ ] Cluster de prueba creado y probado
- [ ] Perfiles configurados
- [ ] Scripts de ayuda creados
- [ ] Verificación completa exitosa
- [ ] Preparado para driver "docker"

---

## 🎯 Estado actual

✅ **Minikube instalado y funcionando**  
✅ **Docker driver configurado y probado**  
✅ **kubectl conectado correctamente**  
🔄 **Preparado para configurar driver "docker"**

---

**Siguiente paso**: [Lab 3.5: Configuración Driver "Docker"](./configuracion-driver-none.md)