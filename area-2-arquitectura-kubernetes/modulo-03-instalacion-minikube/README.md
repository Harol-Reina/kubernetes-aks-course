# Módulo 3: Instalación y Configuración de Minikube

> **Entorno de desarrollo local con Kubernetes usando Minikube y Docker**

## 📖 Descripción del Módulo

Este módulo te guiará en la instalación y configuración de un entorno completo de Kubernetes usando **Minikube con driver Docker** en una VM de Azure (Ubuntu). Aprenderás desde la preparación del entorno hasta el despliegue de tu primera aplicación, siguiendo una metodología práctica donde cada concepto se refuerza inmediatamente con ejemplos ejecutables.

**Duración estimada**: 90-120 minutos  
**Nivel**: Intermedio  
**Audiencia**: Desarrolladores y DevOps

---

## 🎯 Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:

- ✅ Instalar y configurar Docker como runtime para Minikube
- ✅ Instalar kubectl y configurar autocompletado en bash/zsh
- ✅ Instalar y ejecutar Minikube con driver Docker
- ✅ Comprender las diferencias entre drivers de Minikube
- ✅ Verificar el estado y salud del cluster
- ✅ Desplegar y acceder a aplicaciones en Minikube
- ✅ Resolver problemas comunes de instalación

---

## 📋 Prerequisitos

### Conocimientos previos
- Comandos básicos de Linux (ssh, sudo, apt, systemctl)
- Conceptos básicos de Docker y contenedores
- Fundamentos de redes (puertos, IPs, forwarding)

### Recursos técnicos
- **VM de Azure** con Ubuntu 20.04 o superior
- **2 vCPUs** mínimo (recomendado 4)
- **4 GB RAM** mínimo (recomendado 8 GB)
- **20 GB** de espacio en disco
- Conexión SSH configurada
- Usuario con permisos `sudo`
- Conexión a internet estable

---

## 🏗️ Arquitectura del Entorno

Minikube con driver Docker crea una arquitectura multi-capa donde el cluster completo de Kubernetes corre dentro de un contenedor Docker:

```
┌──────────────────────────────────────────────────────────────────┐
│                       AZURE VM (Ubuntu)                          │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Docker Engine                           │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │        Contenedor Minikube                           │ │ │
│  │  │                                                      │ │ │
│  │  │  ┌──────────────────────────────────────────┐       │ │ │
│  │  │  │     CONTROL PLANE                        │       │ │ │
│  │  │  │  • kube-apiserver (puerto 8443)         │       │ │ │
│  │  │  │  • kube-scheduler                        │       │ │ │
│  │  │  │  • kube-controller-manager               │       │ │ │
│  │  │  │  • etcd (datastore)                      │       │ │ │
│  │  │  └──────────────────────────────────────────┘       │ │ │
│  │  │                                                      │ │ │
│  │  │  ┌──────────────────────────────────────────┐       │ │ │
│  │  │  │     WORKER COMPONENTS                    │       │ │ │
│  │  │  │  • kubelet                                │       │ │ │
│  │  │  │  • kube-proxy                             │       │ │ │
│  │  │  │  • container runtime (containerd)         │       │ │ │
│  │  │  └──────────────────────────────────────────┘       │ │ │
│  │  │                                                      │ │ │
│  │  │  ┌──────────────────────────────────────────┐       │ │ │
│  │  │  │     PODS (tus aplicaciones)              │       │ │ │
│  │  │  │  [Pod 1] [Pod 2] [Pod 3] ...            │       │ │ │
│  │  │  └──────────────────────────────────────────┘       │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  kubectl (CLI) ────────► API Server (via localhost:8443)  │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
          │
          │ SSH (desde tu máquina local)
          ▼
   [Tu computadora]
```

### ¿Por qué esta arquitectura?

- **Aislamiento total**: El cluster completo está encapsulado en un contenedor
- **Fácil limpieza**: `minikube delete` elimina todo sin dejar rastros
- **Portabilidad**: La misma configuración funciona en cualquier máquina con Docker
- **Seguridad**: No requiere permisos root para operaciones normales

---

---

## � Contenido del Módulo

### Sección 1: Fundamentos de Minikube

#### 1.1 ¿Qué es Minikube?

Minikube es una herramienta que ejecuta un cluster de Kubernetes de un solo nodo en tu máquina local. Es ideal para:

- 🎓 **Aprendizaje**: Experimentar con Kubernetes sin costos de cloud
- 💻 **Desarrollo**: Probar aplicaciones antes de desplegarlas en producción
- 🧪 **Testing**: Validar manifiestos y configuraciones
- 🔬 **Experimentación**: Probar features de Kubernetes sin riesgo

**Características clave:**
- Cluster completo de Kubernetes (Control Plane + Worker)
- Múltiples drivers soportados (Docker, VirtualBox, KVM, etc.)
- Addons preconfigurados (dashboard, metrics-server, ingress)
- Compatible con kubectl estándar
- Fácil creación y eliminación de clusters

#### 1.2 Drivers de Minikube: Comparativa

Minikube soporta varios drivers, cada uno con ventajas y desventajas:

| Driver | Tecnología | Uso Recomendado | Ventajas | Desventajas |
|--------|------------|----------------|----------|-------------|
| **Docker** | Contenedor | ✅ **Desarrollo/Aprendizaje** | Rápido, ligero, fácil setup | Networking requiere port-forward |
| **VirtualBox** | VM completa | Producción local | Aislamiento total, networking nativo | Alto consumo recursos |
| **KVM** | VM Linux | Servidores Linux | Performance nativo | Solo Linux, configuración compleja |
| **Podman** | Contenedor | Entornos sin root | Sin daemon, rootless | Menos maduro, posibles bugs |
| **HyperV** | VM Windows | Windows Pro/Enterprise | Integración Windows | Solo Windows, licencia requerida |

**Para este curso usamos Docker** porque:
- ✅ Instalación simple y rápida
- ✅ Bajo consumo de recursos
- ✅ Excelente para aprendizaje
- ✅ Funciona en cualquier OS
- ✅ Fácil limpieza y reinstalación

📖 **Ejemplo de comparación**: [`ejemplos/01-instalacion/comparativa-drivers.md`](./ejemplos/01-instalacion/comparativa-drivers.md)

#### 1.3 Componentes que Instalaremos

```
┌─────────────────────────────────────────────────────────────┐
│                    STACK COMPLETO                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Docker Engine         → Runtime para Minikube          │
│  2. kubectl               → CLI de Kubernetes               │
│  3. Minikube              → Cluster local de K8s            │
│                                                             │
│  Flujo de instalación:                                     │
│  Docker → kubectl → Minikube → Verificación                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

### Sección 2: Instalación de Docker

#### 2.1 ¿Por qué Docker primero?

Docker es el **runtime** que ejecutará el contenedor de Minikube. Sin Docker instalado, Minikube no podrá iniciarse con el driver Docker.

**Versión recomendada**: Docker Engine 20.10+ (cualquier versión reciente funciona)

#### 2.2 Proceso de Instalación

**Pasos de instalación:**

1. Actualizar repositorios del sistema
2. Instalar dependencias necesarias
3. Agregar repositorio oficial de Docker
4. Instalar Docker Engine
5. Configurar permisos de usuario
6. Verificar instalación

📝 **Ejemplo inline**: Script de instalación automatizada

```bash
# Ver: ejemplos/01-instalacion/install-docker.sh

#!/bin/bash
# Instalación de Docker en Ubuntu

# Actualizar sistema
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Agregar GPG key de Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Agregar repositorio
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

echo "✅ Docker instalado. Cierra sesión y vuelve a entrar para aplicar permisos."
```

📄 **Archivo completo**: [`ejemplos/01-instalacion/install-docker.sh`](./ejemplos/01-instalacion/install-docker.sh)

#### 2.3 Verificación de Docker

Después de instalar, verifica que Docker funciona correctamente:

```bash
# Verificar versión
docker --version
# Salida esperada: Docker version 24.x.x, build ...

# Verificar que el daemon está corriendo
sudo systemctl status docker
# Salida esperada: Active: active (running)

# Probar Docker (sin sudo)
docker run hello-world
# Debe descargar y ejecutar el contenedor exitosamente
```

**⚠️ Importante**: Si `docker run hello-world` da error de permisos, cierra sesión SSH y vuelve a entrar para que los permisos del grupo docker se apliquen.

🧪 **Laboratorio Práctico**: [Lab 3.1 - Instalación y Configuración de Docker](./laboratorios/lab-01-instalacion-docker.md)

---

### Sección 3: Instalación de kubectl

#### 3.1 ¿Qué es kubectl?

`kubectl` es la **interfaz de línea de comandos (CLI)** para interactuar con clusters de Kubernetes. Es tu herramienta principal para:

- 📦 Desplegar aplicaciones
- 🔍 Inspeccionar recursos
- 📊 Ver logs y métricas
- ⚙️ Configurar el cluster
- 🐛 Debugging y troubleshooting

**Relación con Minikube:**
```
kubectl  ───[API calls]───►  Minikube API Server
   ▲                              │
   │                              │
   └──── ~/.kube/config ──────────┘
        (configuración de acceso)
```

#### 3.2 Instalación de kubectl

**Método 1: Descarga directa (recomendado)**

```bash
# Ver: ejemplos/01-instalacion/install-kubectl.sh

# Descargar kubectl (última versión estable)
curl -LO "https://dl.k8s.io/release/$(curl -L -s \
  https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Dar permisos de ejecución
chmod +x kubectl

# Mover a PATH del sistema
sudo mv kubectl /usr/local/bin/

# Verificar instalación
kubectl version --client
```

📄 **Script completo**: [`ejemplos/01-instalacion/install-kubectl.sh`](./ejemplos/01-instalacion/install-kubectl.sh)

**Método 2: Usando package manager (apt)**

```bash
# Actualizar índice de paquetes
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Agregar clave de firma
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Agregar repositorio
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# Instalar kubectl
sudo apt-get update
sudo apt-get install -y kubectl
```

#### 3.3 Configuración de Autocompletado

El autocompletado te ahorrará **mucho tiempo** al usar kubectl:

```bash
# Para Bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc

# Para Zsh
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
echo 'alias k=kubectl' >> ~/.zshrc
echo 'compdef __start_kubectl k' >> ~/.zshrc
source ~/.zshrc

# Probar autocompletado
kubectl get po<TAB>  # Debe autocompletar a "pods"
k get no<TAB>         # Debe autocompletar a "nodes"
```

📄 **Scripts de configuración**: 
- [`ejemplos/02-configuracion/kubectl-autocomplete-bash.sh`](./ejemplos/02-configuracion/kubectl-autocomplete-bash.sh)
- [`ejemplos/02-configuracion/kubectl-autocomplete-zsh.sh`](./ejemplos/02-configuracion/kubectl-autocomplete-zsh.sh)

🧪 **Laboratorio Práctico**: [Lab 3.2 - Instalación y Configuración de kubectl](./laboratorios/lab-02-instalacion-kubectl.md)

---
---

### Sección 4: Instalación de Minikube

#### 4.1 Descarga e Instalación

Minikube se distribuye como un binario único. La instalación es simple:

```bash
# Ver: ejemplos/01-instalacion/install-minikube.sh

# Descargar binario de Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Instalar en el sistema
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Limpiar archivo descargado
rm minikube-linux-amd64

# Verificar instalación
minikube version
# Salida esperada: minikube version: v1.x.x
```

📄 **Script completo**: [`ejemplos/01-instalacion/install-minikube.sh`](./ejemplos/01-instalacion/install-minikube.sh)

#### 4.2 Configuración Inicial del Cluster

Una vez instalado Minikube, puedes crear tu primer cluster:

```bash
# Iniciar Minikube con driver Docker
minikube start --driver=docker

# Parámetros adicionales útiles (opcional)
minikube start \
  --driver=docker \
  --cpus=2 \
  --memory=4096 \
  --disk-size=20g \
  --kubernetes-version=stable
```

**¿Qué sucede durante `minikube start`?**

```
1. ⬇️  Descarga imagen del contenedor Minikube (si es primera vez)
2. 🔨 Crea contenedor Docker llamado "minikube"
3. 🚀 Inicia componentes del Control Plane dentro del contenedor
   - kube-apiserver
   - etcd
   - kube-scheduler
   - kube-controller-manager
4. 👷 Inicia componentes Worker
   - kubelet
   - kube-proxy
5. 🔧 Configura kubectl para conectarse al cluster
6. ✅ Verifica que todos los componentes estén Ready
```

**Tiempo de inicio**: 2-5 minutos (primera vez), <1 minuto (posteriores)

#### 4.3 Parámetros de Configuración

Minikube acepta varios parámetros para personalizar el cluster:

| Parámetro | Descripción | Valor Recomendado | Ejemplo |
|-----------|-------------|-------------------|---------|
| `--driver` | Runtime a usar | `docker` | `--driver=docker` |
| `--cpus` | CPUs asignadas | `2-4` | `--cpus=2` |
| `--memory` | RAM en MB | `4096-8192` | `--memory=4096` |
| `--disk-size` | Tamaño disco | `20g-50g` | `--disk-size=20g` |
| `--kubernetes-version` | Versión de K8s | `stable` o `latest` | `--kubernetes-version=v1.28.0` |
| `--container-runtime` | Runtime interno | `containerd` (default) | `--container-runtime=containerd` |
| `--addons` | Addons a habilitar | depende del uso | `--addons=metrics-server,dashboard` |

📝 **Ejemplo**: Configuración personalizada

```bash
# Ver: ejemplos/02-configuracion/minikube-start-custom.sh

# Crear cluster con configuración personalizada
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=8192 \
  --disk-size=30g \
  --kubernetes-version=stable \
  --addons=metrics-server \
  --addons=dashboard \
  --container-runtime=containerd
```

📄 **Script**: [`ejemplos/02-configuracion/minikube-start-custom.sh`](./ejemplos/02-configuracion/minikube-start-custom.sh)

#### 4.4 Verificación del Cluster

Después de iniciar Minikube, verifica que todo funciona:

```bash
# 1. Estado de Minikube
minikube status
# Salida esperada:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
# kubeconfig: Configured

# 2. Información del cluster
kubectl cluster-info
# Salida esperada:
# Kubernetes control plane is running at https://127.0.0.1:xxxxx
# CoreDNS is running at https://127.0.0.1:xxxxx/api/v1/namespaces/kube-system/...

# 3. Ver nodos del cluster
kubectl get nodes
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   2m    v1.28.x

# 4. Ver pods del sistema
kubectl get pods -n kube-system
# Todos los pods deben estar Running
```

📝 **Script de verificación**: [`ejemplos/02-configuracion/verify-cluster.sh`](./ejemplos/02-configuracion/verify-cluster.sh)

🧪 **Laboratorio Práctico**: [Lab 3.3 - Instalación y Configuración de Minikube](./laboratorios/lab-03-instalacion-minikube.md)

---

### Sección 5: Primeros Pasos con Minikube

#### 5.1 Comandos Esenciales de Minikube

Domina estos comandos para gestionar tu cluster:

**Gestión del cluster:**
```bash
# Iniciar cluster (si está detenido)
minikube start

# Detener cluster (libera recursos pero mantiene estado)
minikube stop

# Eliminar cluster completamente
minikube delete

# Eliminar y recrear cluster
minikube delete && minikube start --driver=docker

# Pausar cluster (congela pods pero mantiene cluster)
minikube pause

# Reanudar cluster pausado
minikube unpause
```

**Información y diagnóstico:**
```bash
# Ver estado actual
minikube status

# Ver IPs del cluster
minikube ip

# Ver logs del cluster
minikube logs

# SSH al nodo de Minikube
minikube ssh

# Ver dashboard web (abre en navegador)
minikube dashboard

# Ver addons disponibles
minikube addons list

# Habilitar addon
minikube addons enable metrics-server

# Ver configuración de Minikube
minikube config view
```

**Gestión de recursos:**
```bash
# Ver uso de recursos del cluster
kubectl top nodes  # Requiere metrics-server
kubectl top pods -A

# Ver dentro del contenedor Docker
docker ps | grep minikube
docker exec -it minikube bash
```

📄 **Cheatsheet completo**: [`ejemplos/02-configuracion/minikube-cheatsheet.md`](./ejemplos/02-configuracion/minikube-cheatsheet.md)

#### 5.2 Tu Primera Aplicación en Minikube

Vamos a desplegar una aplicación simple para verificar que todo funciona:

```bash
# Ver: ejemplos/03-primeros-pasos/primera-app.sh

# 1. Crear un deployment de nginx
kubectl create deployment nginx --image=nginx

# 2. Verificar que el pod se creó
kubectl get deployments
kubectl get pods

# 3. Exponer el deployment como servicio
kubectl expose deployment nginx --port=80 --type=NodePort

# 4. Ver el servicio creado
kubectl get services nginx

# 5. Obtener URL para acceder
minikube service nginx --url

# 6. Hacer petición al servicio
curl $(minikube service nginx --url)
# Debería retornar el HTML de nginx
```

**Explicación paso a paso:**

1. **`kubectl create deployment`**: Crea un Deployment que gestiona pods con nginx
2. **`kubectl expose`**: Crea un Service tipo NodePort para acceder al pod
3. **`minikube service --url`**: Obtiene la URL completa para acceder desde la VM
4. **`curl`**: Hace petición HTTP para verificar que nginx responde

📄 **Script completo**: [`ejemplos/03-primeros-pasos/primera-app.sh`](./ejemplos/03-primeros-pasos/primera-app.sh)

#### 5.3 Usando Manifiestos YAML

En producción, no usarás comandos imperativos (`kubectl create`). Usarás **manifiestos YAML declarativos**:

```yaml
# Ver: ejemplos/03-primeros-pasos/nginx-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

**Aplicar el manifiesto:**

```bash
# Aplicar configuración
kubectl apply -f ejemplos/03-primeros-pasos/nginx-deployment.yaml

# Verificar recursos creados
kubectl get deployments,pods,services

# Acceder al servicio
minikube service nginx --url
# O directamente: curl http://$(minikube ip):30080
```

📄 **Manifiestos de ejemplo**:
- [`ejemplos/03-primeros-pasos/nginx-deployment.yaml`](./ejemplos/03-primeros-pasos/nginx-deployment.yaml)
- [`ejemplos/03-primeros-pasos/webapp-complete.yaml`](./ejemplos/03-primeros-pasos/webapp-complete.yaml)

🧪 **Laboratorio Práctico**: [Lab 3.4 - Primera Aplicación en Minikube](./laboratorios/lab-04-primera-aplicacion.md)

---

### Sección 6: Addons de Minikube

#### 6.1 ¿Qué son los Addons?

Los addons son **componentes adicionales** que Minikube puede instalar automáticamente en tu cluster. Simplifican la instalación de herramientas comunes.

**Addons más útiles:**

| Addon | Descripción | Uso |
|-------|-------------|-----|
| `metrics-server` | Métricas de CPU/memoria | `kubectl top`, HPA |
| `dashboard` | UI web de Kubernetes | Visualización gráfica |
| `ingress` | Ingress controller (nginx) | Routing HTTP avanzado |
| `registry` | Docker registry local | Pull/push imágenes localmente |
| `storage-provisioner` | Provisión dinámica de PVs | StorageClasses |

#### 6.2 Habilitar Addons

```bash
# Ver addons disponibles
minikube addons list

# Habilitar metrics-server (recomendado)
minikube addons enable metrics-server

# Habilitar dashboard
minikube addons enable dashboard

# Habilitar ingress
minikube addons enable ingress

# Ver pods de addons
kubectl get pods -n kube-system
kubectl get pods -n kubernetes-dashboard
kubectl get pods -n ingress-nginx

# Deshabilitar addon
minikube addons disable dashboard
```

#### 6.3 Usando el Dashboard

```bash
# Abrir dashboard (abre navegador automáticamente)
minikube dashboard

# O obtener URL sin abrir navegador
minikube dashboard --url

# Acceder desde tu máquina local (requiere port-forward)
# En la VM:
kubectl proxy --address='0.0.0.0' --accept-hosts='.*'

# Desde tu máquina:
# http://<vm-ip>:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```

#### 6.4 Usando Metrics Server

```bash
# Verificar que metrics-server está corriendo
kubectl get deployment -n kube-system metrics-server

# Ver métricas de nodos (tarda 1-2 min en recolectar)
kubectl top nodes

# Ver métricas de pods
kubectl top pods -A

# Ver métricas de un namespace específico
kubectl top pods -n default
```

📄 **Guía de addons**: [`ejemplos/02-configuracion/addons-guide.md`](./ejemplos/02-configuracion/addons-guide.md)

🧪 **Laboratorio Práctico**: [Lab 3.5 - Configuración de Addons](./laboratorios/lab-05-addons.md)

---

---

### Sección 7: Troubleshooting y Solución de Problemas

#### 7.1 Problemas Comunes y Soluciones

**Problema 1: Minikube no inicia - Error de Docker**

```bash
# Error:
# "Exiting due to DRV_NOT_HEALTHY: Found docker, but the docker service is not healthy"

# Solución:
sudo systemctl start docker
sudo systemctl enable docker
minikube delete
minikube start --driver=docker
```

**Problema 2: kubectl no se conecta al cluster**

```bash
# Error:
# "The connection to the server localhost:8080 was refused"

# Solución:
minikube status  # Verifica que el cluster está corriendo
kubectl config current-context  # Debe mostrar "minikube"
minikube update-context  # Actualiza configuración
```

**Problema 3: Pods en estado ImagePullBackOff**

```bash
# Diagnóstico:
kubectl describe pod <pod-name>

# Soluciones comunes:
# 1. Nombre de imagen incorrecto
# 2. Sin conexión a internet
# 3. Imagen privada sin credenciales

# Verificar conectividad:
minikube ssh
ping google.com
docker pull nginx  # Probar pull manual
```

**Problema 4: Recursos insuficientes**

```bash
# Error:
# "Insufficient memory" o "Insufficient CPU"

# Solución:
minikube delete
minikube start --driver=docker --memory=8192 --cpus=4

# O verificar recursos del sistema:
free -h
nproc
df -h
```

**Problema 5: Puerto ya en uso**

```bash
# Error:
# "Ports are not available: exposing port ... failed"

# Solución:
# Ver qué proceso usa el puerto:
sudo lsof -i :<puerto>
# O:
sudo netstat -tulpn | grep <puerto>

# Liberar puerto o usar otro en el manifiesto
```

📄 **Guía completa**: [`ejemplos/02-configuracion/troubleshooting-guide.md`](./ejemplos/02-configuracion/troubleshooting-guide.md)

#### 7.2 Comandos de Diagnóstico

```bash
# Ver logs de Minikube
minikube logs

# Ver últimas 50 líneas de logs
minikube logs --length=50

# Logs de un componente específico
minikube logs --file=kubelet

# SSH al nodo para debugging avanzado
minikube ssh

# Dentro del nodo, ver contenedores:
docker ps

# Ver logs de componentes del sistema
kubectl logs -n kube-system -l component=kube-apiserver
kubectl logs -n kube-system -l k8s-app=kube-dns

# Describir recursos problemáticos
kubectl describe pod <pod-name>
kubectl describe node minikube
kubectl get events --sort-by='.lastTimestamp'
```

#### 7.3 Reinicio Limpio

Si todo falla, el mejor approach es reiniciar desde cero:

```bash
# Ver: ejemplos/02-configuracion/clean-restart.sh

# 1. Eliminar cluster completamente
minikube delete --all --purge

# 2. Limpiar configuración de kubectl
rm -rf ~/.kube

# 3. Limpiar caché de Minikube
rm -rf ~/.minikube

# 4. Verificar Docker está funcionando
docker ps
docker run hello-world

# 5. Recrear cluster
minikube start --driver=docker

# 6. Verificar
kubectl get nodes
```

📄 **Script de reinicio**: [`ejemplos/02-configuracion/clean-restart.sh`](./ejemplos/02-configuracion/clean-restart.sh)

🧪 **Laboratorio Práctico**: [Lab 3.6 - Troubleshooting y Resolución de Problemas](./laboratorios/lab-06-troubleshooting.md)

---

### Sección 8: Mejores Prácticas

#### 8.1 Gestión de Recursos

```bash
# Asignar recursos apropiados según tu uso:

# Para aprendizaje básico (mínimo):
minikube start --driver=docker --cpus=2 --memory=4096

# Para desarrollo (recomendado):
minikube start --driver=docker --cpus=4 --memory=8192

# Para testing intensivo:
minikube start --driver=docker --cpus=6 --memory=12288 --disk-size=50g

# Siempre limita recursos en pods:
# ✅ BIEN
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi

# ❌ MAL (sin límites)
# Sin especificar resources
```

#### 8.2 Organización de Manifiestos

```bash
# Estructura recomendada de proyecto:
my-app/
├── k8s/
│   ├── base/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── dev/
│   │   └── kustomization.yaml
│   └── prod/
│       └── kustomization.yaml
├── Dockerfile
└── README.md

# Aplicar configuraciones:
kubectl apply -f k8s/base/
# O usar kustomize:
kubectl apply -k k8s/dev/
```

#### 8.3 Uso de Namespaces

```bash
# Separar ambientes con namespaces
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace prod

# Desplegar en namespace específico
kubectl apply -f deployment.yaml -n dev

# Configurar namespace por defecto
kubectl config set-context --current --namespace=dev

# Ver recursos de todos los namespaces
kubectl get pods -A
```

#### 8.4 Automatización con Scripts

```bash
# Ver: ejemplos/02-configuracion/setup-environment.sh

#!/bin/bash
# Script completo de setup del entorno

# 1. Verificar Docker
if ! docker ps >/dev/null 2>&1; then
    echo "❌ Docker no está corriendo"
    exit 1
fi

# 2. Crear cluster si no existe
if ! minikube status >/dev/null 2>&1; then
    echo "🚀 Creando cluster Minikube..."
    minikube start --driver=docker --cpus=4 --memory=8192
fi

# 3. Habilitar addons
minikube addons enable metrics-server
minikube addons enable dashboard

# 4. Crear namespaces
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -

# 5. Configurar contexto
kubectl config set-context --current --namespace=dev

echo "✅ Entorno configurado correctamente"
```

📄 **Scripts de automatización**: [`ejemplos/02-configuracion/setup-environment.sh`](./ejemplos/02-configuracion/setup-environment.sh)

#### 8.5 Seguridad Básica

```bash
# No usar latest tag en producción
# ❌ MAL
image: nginx:latest

# ✅ BIEN (para prod)
image: nginx:1.25.3

# ✅ ACEPTABLE (para aprendizaje/dev)
image: nginx

# Usar Secrets para datos sensibles
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=secret123

# No commitear secrets en Git
# Agregar a .gitignore:
echo "secrets.yaml" >> .gitignore

# Limitar permisos con RBAC
# (Ver módulos posteriores)
```

---

## 📊 Resumen del Módulo

### ✅ Checklist de Completitud

Verifica que puedas hacer todas estas tareas:

- [ ] Docker instalado y funcionando (`docker run hello-world`)
- [ ] kubectl instalado (`kubectl version --client`)
- [ ] Autocompletado de kubectl configurado (`k get po<TAB>`)
- [ ] Minikube instalado (`minikube version`)
- [ ] Cluster Minikube corriendo (`minikube status`)
- [ ] kubectl conectado al cluster (`kubectl get nodes`)
- [ ] Pods del sistema corriendo (`kubectl get pods -n kube-system`)
- [ ] Metrics-server habilitado (`kubectl top nodes`)
- [ ] Puedes desplegar una aplicación (`kubectl create deployment nginx --image=nginx`)
- [ ] Puedes acceder a servicios (`minikube service nginx --url`)
- [ ] Comprendes troubleshooting básico

### 🎯 Objetivos Alcanzados

Si completaste todos los laboratorios, ahora sabes:

1. **Conceptos fundamentales**:
   - ✅ Qué es Minikube y para qué sirve
   - ✅ Diferencias entre drivers (Docker, VM, etc.)
   - ✅ Arquitectura de Minikube con driver Docker
   - ✅ Componentes de un cluster Kubernetes

2. **Habilidades técnicas**:
   - ✅ Instalar stack completo (Docker, kubectl, Minikube)
   - ✅ Configurar autocompletado y aliases
   - ✅ Gestionar lifecycle del cluster
   - ✅ Desplegar aplicaciones con kubectl
   - ✅ Usar manifiestos YAML
   - ✅ Habilitar y usar addons
   - ✅ Diagnosticar y resolver problemas

3. **Mejores prácticas**:
   - ✅ Organización de manifiestos
   - ✅ Uso de namespaces
   - ✅ Limitación de recursos
   - ✅ Automatización con scripts
   - ✅ Seguridad básica

### �️ Recursos Creados

Durante este módulo has creado/usado estos recursos:

**Scripts de instalación:**
- [`ejemplos/01-instalacion/install-docker.sh`](./ejemplos/01-instalacion/install-docker.sh)
- [`ejemplos/01-instalacion/install-kubectl.sh`](./ejemplos/01-instalacion/install-kubectl.sh)
- [`ejemplos/01-instalacion/install-minikube.sh`](./ejemplos/01-instalacion/install-minikube.sh)

**Scripts de configuración:**
- [`ejemplos/02-configuracion/kubectl-autocomplete-bash.sh`](./ejemplos/02-configuracion/kubectl-autocomplete-bash.sh)
- [`ejemplos/02-configuracion/kubectl-autocomplete-zsh.sh`](./ejemplos/02-configuracion/kubectl-autocomplete-zsh.sh)
- [`ejemplos/02-configuracion/minikube-start-custom.sh`](./ejemplos/02-configuracion/minikube-start-custom.sh)
- [`ejemplos/02-configuracion/setup-environment.sh`](./ejemplos/02-configuracion/setup-environment.sh)

**Manifiestos de ejemplo:**
- [`ejemplos/03-primeros-pasos/nginx-deployment.yaml`](./ejemplos/03-primeros-pasos/nginx-deployment.yaml)
- [`ejemplos/03-primeros-pasos/webapp-complete.yaml`](./ejemplos/03-primeros-pasos/webapp-complete.yaml)

**Laboratorios completados:**
- [Lab 3.1 - Instalación de Docker](./laboratorios/lab-01-instalacion-docker.md)
- [Lab 3.2 - Instalación de kubectl](./laboratorios/lab-02-instalacion-kubectl.md)
- [Lab 3.3 - Instalación de Minikube](./laboratorios/lab-03-instalacion-minikube.md)
- [Lab 3.4 - Primera Aplicación](./laboratorios/lab-04-primera-aplicacion.md)
- [Lab 3.5 - Configuración de Addons](./laboratorios/lab-05-addons.md)
- [Lab 3.6 - Troubleshooting](./laboratorios/lab-06-troubleshooting.md)

---

## 🚀 Próximos Pasos

Has completado la instalación y configuración de tu entorno Kubernetes local. Ahora estás listo para:

### Módulos siguientes:
- **Módulo 4**: Pods vs Contenedores - Comprender la unidad fundamental de Kubernetes
- **Módulo 5**: Gestión de Pods - Ciclo de vida, probes, y debugging
- **Módulo 6**: ReplicaSets y Réplicas - Alta disponibilidad y escalado
- **Módulo 7**: Deployments y Rollouts - Despliegues controlados y rollbacks

### Práctica adicional recomendada:
1. Despliega una aplicación multi-contenedor (frontend + backend + database)
2. Experimenta con diferentes tipos de Services (ClusterIP, NodePort, LoadBalancer)
3. Prueba diferentes configuraciones de recursos
4. Practica rollbacks con Deployments
5. Configura Ingress para routing HTTP

### Recursos para profundizar:
- [Documentación oficial de Minikube](https://minikube.sigs.k8s.io/docs/)
- [Tutorial interactivo de Kubernetes](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Cheatsheet de kubectl](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Ejemplos de manifiestos](https://github.com/kubernetes/examples)

---

## 🔗 Enlaces Rápidos

### Documentación Oficial
- [Minikube Docs](https://minikube.sigs.k8s.io/docs/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [Docker Docs](https://docs.docker.com/)
- [Kubernetes Docs](https://kubernetes.io/docs/home/)

### Herramientas Útiles
- [k9s](https://k9scli.io/) - Terminal UI para Kubernetes
- [kubectx/kubens](https://github.com/ahmetb/kubectx) - Cambio rápido de contextos/namespaces
- [Lens](https://k8slens.dev/) - IDE de Kubernetes
- [Helm](https://helm.sh/) - Package manager para Kubernetes

### Comunidad
- [Kubernetes Slack](https://kubernetes.slack.com/)
- [Stack Overflow - Kubernetes](https://stackoverflow.com/questions/tagged/kubernetes)
- [Reddit r/kubernetes](https://www.reddit.com/r/kubernetes/)

---

## ⚠️ Notas Finales

### Gestión de Recursos

Recuerda que Minikube consume recursos de tu sistema:

```bash
# Ver uso de recursos
docker stats minikube

# Detener cuando no uses (libera CPU/RAM)
minikube stop

# Eliminar completamente (libera disco)
minikube delete
```

### Persistencia de Datos

- Minikube usa volúmenes Docker para persistir datos
- `minikube stop` mantiene todos los datos
- `minikube delete` **elimina todo** (cluster, pods, volúmenes)
- Para producción, siempre usa PersistentVolumes apropiados

### Limitaciones de Minikube

Minikube es **excelente para desarrollo y aprendizaje**, pero tiene limitaciones:

- ❌ **No para producción**: Single-node, no HA
- ❌ **LoadBalancer limitado**: Requiere `minikube tunnel`
- ❌ **Performance**: No es tan rápido como cluster real
- ✅ **Ideal para**: Desarrollo, testing, aprendizaje, CI/CD

---

**🎓 ¡Felicitaciones!** Has completado el Módulo 3. Ahora tienes un entorno completo de Kubernetes funcionando y estás listo para aprender conceptos más avanzados.

**⏱️ Tiempo total estimado**: 90-120 minutos  
**📊 Progreso del curso**: Módulo 3 de 18 completado  
**🎯 Nivel alcanzado**: Fundamentos de Kubernetes - Entorno configurado

---

*Última actualización: Noviembre 2025*  
*Versión del módulo: 2.0*  
*Autor: Equipo de Kubernetes Training*