# 📝 RESUMEN: Instalación y Configuración de Minikube

> **Guía de Instalación Rápida** - De cero a cluster Kubernetes local funcionando en tu máquina.

---

## 🎯 Conceptos Clave en 5 Minutos

### ¿Qué es Minikube?
**Minikube** es una herramienta que ejecuta un **cluster Kubernetes de un solo nodo** localmente en tu máquina. Es ideal para:
- Desarrollo y testing de aplicaciones K8s
- Aprendizaje y experimentación
- CI/CD pipelines
- Demos y PoCs

### Minikube vs Producción

```
MINIKUBE (Local):                PRODUCCIÓN (EKS/AKS/GKE):
┌────────────────────┐           ┌──────────────────────────┐
│   Tu Laptop/VM     │           │   Cloud Provider         │
│  ┌──────────────┐  │           │  ┌────────┐ ┌────────┐   │
│  │   Minikube   │  │           │  │Master 1│ │Master 2│   │
│  │  (1 nodo)    │  │           │  └────────┘ └────────┘   │
│  │              │  │           │  ┌────────────────────┐  │
│  │ Control Plane│  │           │  │Workers (3-100+)    │  │
│  │ + Worker     │  │           │  └────────────────────┘  │
│  └──────────────┘  │           └──────────────────────────┘
└────────────────────┘
```

---

## 🛠️ Instalación Completa (Ubuntu/Linux)

### Paso 1: Instalar Docker

**¿Por qué Docker?**
- Minikube usa Docker como "driver" (motor para ejecutar el cluster)
- Docker proporciona el container runtime

```bash
# Actualizar paquetes
sudo apt-get update

# Instalar dependencias
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Añadir repositorio de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Añadir tu usuario al grupo docker (evitar sudo)
sudo usermod -aG docker $USER
newgrp docker  # Aplicar cambio sin logout

# Verificar instalación
docker version
docker run hello-world
```

**Verificación**:
```bash
docker ps
# Debe funcionar SIN sudo
```

---

### Paso 2: Instalar kubectl

**¿Qué es kubectl?**
- CLI (Command Line Interface) para interactuar con Kubernetes
- Envía comandos al API Server del cluster

```bash
# Descargar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Dar permisos de ejecución
chmod +x kubectl

# Mover a /usr/local/bin (en PATH)
sudo mv kubectl /usr/local/bin/

# Verificar instalación
kubectl version --client
```

**Configurar autocompletado (recomendado)**:

```bash
# Para bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc

# Para zsh
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
echo 'alias k=kubectl' >> ~/.zshrc
echo 'compdef __start_kubectl k' >> ~/.zshrc
source ~/.zshrc
```

**Verificación**:
```bash
kubectl version --client
# Debe mostrar Client Version: v1.28.X
```

---

### Paso 3: Instalar Minikube

```bash
# Descargar Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Instalar
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verificar instalación
minikube version
```

---

### Paso 4: Iniciar Cluster

```bash
# Iniciar Minikube con driver Docker
minikube start --driver=docker

# Proceso:
# 1. Descarga imagen de Minikube (puede tardar 2-5 min)
# 2. Crea contenedor Docker con K8s
# 3. Configura kubectl para conectar a Minikube
# 4. Inicia componentes del Control Plane
# 5. Listo!
```

**Salida esperada**:
```
😄  minikube v1.32.0 on Ubuntu 22.04
✨  Using the docker driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=4000MB) ...
🐳  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
🔎  Verifying Kubernetes components...
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster
```

---

### Paso 5: Verificar Instalación

```bash
# Ver estado de Minikube
minikube status
# Debe mostrar:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
# kubeconfig: Configured

# Ver nodos del cluster
kubectl get nodes
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   2m    v1.28.3

# Ver componentes del sistema
kubectl get pods -n kube-system
# Deberías ver:
# - coredns (DNS)
# - etcd (base de datos)
# - kube-apiserver (API)
# - kube-controller-manager
# - kube-proxy
# - kube-scheduler
# - storage-provisioner

# Ver información del cluster
kubectl cluster-info
# Kubernetes control plane is running at https://192.168.49.2:8443
# CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

---

## 🚀 Primera Aplicación

### Desplegar nginx

```bash
# Crear deployment de nginx
kubectl create deployment nginx --image=nginx:1.21

# Ver deployment
kubectl get deployment
# NAME    READY   UP-TO-DATE   AVAILABLE   AGE
# nginx   1/1     1            1           10s

# Ver pods
kubectl get pods
# NAME                     READY   STATUS    RESTARTS   AGE
# nginx-5d7f9c8d9b-xyz12   1/1     Running   0          15s

# Ver detalles del pod
kubectl describe pod nginx-5d7f9c8d9b-xyz12
```

### Exponer aplicación

```bash
# Crear Service
kubectl expose deployment nginx --port=80 --type=NodePort

# Ver Service
kubectl get service nginx
# NAME    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# nginx   NodePort   10.96.123.45    <none>        80:30123/TCP   5s

# Acceder a la aplicación (Minikube service)
minikube service nginx
# Abre navegador con URL: http://192.168.49.2:30123

# Alternativamente, port-forward
kubectl port-forward service/nginx 8080:80
# Acceder en: http://localhost:8080
```

### Limpiar

```bash
# Eliminar service
kubectl delete service nginx

# Eliminar deployment
kubectl delete deployment nginx

# Verificar limpieza
kubectl get all
# No resources found in default namespace.
```

---

## 📋 Comandos Esenciales de Minikube

### Gestión del Cluster

```bash
# Iniciar cluster
minikube start

# Iniciar con configuración específica
minikube start --cpus=4 --memory=8192 --driver=docker

# Ver estado
minikube status

# Pausar cluster (ahorra recursos)
minikube pause

# Reanudar cluster
minikube unpause

# Detener cluster (mantiene configuración)
minikube stop

# Eliminar cluster (borra todo)
minikube delete

# Ver logs del cluster
minikube logs

# SSH al nodo de Minikube
minikube ssh
```

---

### Addons de Minikube

**Addons** son componentes opcionales que añaden funcionalidad al cluster.

```bash
# Listar addons disponibles
minikube addons list

# Habilitar metrics-server (para kubectl top)
minikube addons enable metrics-server

# Habilitar dashboard (UI web)
minikube addons enable dashboard

# Abrir dashboard
minikube dashboard

# Habilitar Ingress (routing HTTP)
minikube addons enable ingress

# Deshabilitar addon
minikube addons disable dashboard
```

**Addons más útiles**:
| Addon | Función | Comando |
|-------|---------|---------|
| **metrics-server** | Métricas de CPU/RAM | `minikube addons enable metrics-server` |
| **dashboard** | UI web de K8s | `minikube addons enable dashboard` |
| **ingress** | Ingress controller | `minikube addons enable ingress` |
| **registry** | Registry local de Docker | `minikube addons enable registry` |
| **storage-provisioner** | Persistent Volumes | Habilitado por defecto |

---

### Información del Cluster

```bash
# Ver IP del cluster
minikube ip
# 192.168.49.2

# Ver URL de la API
minikube kubectl -- cluster-info

# Ver versión de Kubernetes
minikube kubectl -- version

# Ver configuración de kubectl
kubectl config view

# Ver contexto actual
kubectl config current-context
# minikube

# Cambiar contexto (si tienes múltiples clusters)
kubectl config use-context minikube
```

---

## 🔍 Comandos Esenciales de kubectl

### Ver Recursos

```bash
# Ver todos los recursos en namespace default
kubectl get all

# Ver pods
kubectl get pods
kubectl get pods -o wide        # Más información (IP, nodo)
kubectl get pods -A             # Todos los namespaces

# Ver deployments
kubectl get deployments

# Ver services
kubectl get services

# Ver namespaces
kubectl get namespaces

# Ver nodos
kubectl get nodes

# Ver eventos (útil para troubleshooting)
kubectl get events --sort-by='.metadata.creationTimestamp'
```

---

### Inspeccionar Recursos

```bash
# Describir pod (mucha información, eventos)
kubectl describe pod <nombre-pod>

# Ver logs de un pod
kubectl logs <nombre-pod>

# Ver logs en tiempo real
kubectl logs -f <nombre-pod>

# Ejecutar comando en pod
kubectl exec <nombre-pod> -- ls /app

# Shell interactivo en pod
kubectl exec -it <nombre-pod> -- /bin/bash
```

---

### Crear/Modificar Recursos

```bash
# Crear deployment
kubectl create deployment nginx --image=nginx

# Crear desde archivo YAML
kubectl apply -f deployment.yaml

# Editar recurso existente
kubectl edit deployment nginx

# Escalar deployment
kubectl scale deployment nginx --replicas=3

# Eliminar recurso
kubectl delete deployment nginx

# Eliminar desde archivo YAML
kubectl delete -f deployment.yaml
```

---

## 🛠️ Troubleshooting Común

### Problema 1: Minikube no inicia

**Síntoma**:
```bash
minikube start
# ❌ Exiting due to PROVIDER_DOCKER_NOT_RUNNING: ...
```

**Solución**:
```bash
# Verificar Docker
sudo systemctl status docker
# Si no está running:
sudo systemctl start docker

# Verificar permisos
docker ps
# Si falla, añadir usuario a grupo docker:
sudo usermod -aG docker $USER
newgrp docker

# Reiniciar Minikube
minikube delete
minikube start
```

---

### Problema 2: kubectl no conecta

**Síntoma**:
```bash
kubectl get nodes
# The connection to the server localhost:8080 was refused
```

**Solución**:
```bash
# Verificar que Minikube está running
minikube status

# Reconfigurar kubectl para Minikube
minikube update-context

# Verificar configuración
kubectl config current-context
# Debe decir: minikube

# Si no funciona, reiniciar
minikube stop
minikube start
```

---

### Problema 3: Pods no se crean

**Síntoma**:
```bash
kubectl get pods
# nginx-xxx   0/1   ImagePullBackOff   0   2m
```

**Diagnóstico**:
```bash
# Ver detalles del pod
kubectl describe pod nginx-xxx
# Buscar sección "Events" al final

# Ver logs (si el contenedor inició)
kubectl logs nginx-xxx
```

**Soluciones comunes**:

1. **ImagePullBackOff**: Imagen no existe
   ```bash
   # Verificar nombre de imagen en deployment
   kubectl edit deployment nginx
   # Corregir image: nginx:1.21 (no nignx o version incorrecta)
   ```

2. **CrashLoopBackOff**: Contenedor inicia y falla
   ```bash
   # Ver logs
   kubectl logs nginx-xxx
   # Revisar error de aplicación
   ```

3. **Pending**: Sin recursos
   ```bash
   # Ver eventos
   kubectl describe pod nginx-xxx
   # Puede decir: "Insufficient memory" o "Insufficient cpu"
   
   # Ver recursos del nodo
   kubectl describe node minikube | grep -A 5 "Allocated resources"
   
   # Solución: Aumentar recursos de Minikube
   minikube delete
   minikube start --cpus=4 --memory=8192
   ```

---

### Problema 4: "Permission denied" al usar Docker

**Síntoma**:
```bash
docker ps
# Got permission denied while trying to connect to the Docker daemon socket
```

**Solución**:
```bash
# Añadir usuario al grupo docker
sudo usermod -aG docker $USER

# Aplicar cambio
newgrp docker

# Verificar
docker ps
# Debe funcionar sin sudo
```

---

### Problema 5: Virtualización no habilitada

**Síntoma**:
```bash
minikube start
# ❌ Exiting due to HOST_VIRT_UNAVAILABLE: Failed to start host: ...
```

**Diagnóstico**:
```bash
# Verificar virtualización
egrep -c '(vmx|svm)' /proc/cpuinfo
# Si devuelve 0 → virtualización deshabilitada
```

**Solución**:
- Habilitar Intel VT-x o AMD-V en BIOS
- En VM de cloud: Verificar que soporta nested virtualization
- Alternativamente, usar driver `none`:
  ```bash
  minikube start --driver=none
  # ⚠️ Solo en Linux, requiere sudo, menos seguro
  ```

---

## 📊 Drivers de Minikube

### ¿Qué es un Driver?

El **driver** es la tecnología que Minikube usa para ejecutar el cluster:

| Driver | Descripción | Sistema | Recomendado |
|--------|-------------|---------|-------------|
| **docker** | Ejecuta K8s dentro de contenedor Docker | Linux, macOS, Windows | ✅ SÍ (2024+) |
| **virtualbox** | VM con VirtualBox | Todos | ❌ Legacy (lento) |
| **kvm2** | VM con KVM/QEMU | Linux | ⚠️ Linux avanzado |
| **hyperv** | VM con Hyper-V | Windows Pro | ⚠️ Windows Pro |
| **none** | Bare metal (sin virtualización) | Linux | ⚠️ Solo CI/CD |

### Docker Driver (Recomendado)

**Ventajas**:
- ✅ Más rápido (no VM completa)
- ✅ Menor consumo de recursos
- ✅ Funciona en Docker Desktop (macOS/Windows)
- ✅ Mejor integración con desarrollo local

**Desventajas**:
- ❌ Requiere Docker instalado
- ❌ Menos aislamiento que VM completa

**Uso**:
```bash
minikube start --driver=docker

# Establecer como default
minikube config set driver docker
```

---

### VirtualBox Driver (Legacy)

**Ventajas**:
- ✅ Funciona en cualquier OS
- ✅ Aislamiento completo (VM)

**Desventajas**:
- ❌ Lento (overhead de VM)
- ❌ Consume más recursos
- ❌ Requiere VirtualBox instalado

**Uso**:
```bash
# Instalar VirtualBox primero
sudo apt-get install virtualbox

# Iniciar con VirtualBox
minikube start --driver=virtualbox
```

---

### None Driver (Bare Metal)

**Solo para CI/CD o testing avanzado**

**Ventajas**:
- ✅ Máximo rendimiento (sin virtualización)

**Desventajas**:
- ❌ Requiere ejecutar como root
- ❌ Menos aislamiento (K8s en host directamente)
- ❌ Puede conflictuar con software del host

**Uso**:
```bash
# ⚠️ Solo en Linux, con sudo
sudo minikube start --driver=none
```

---

## 🎯 Configuraciones Avanzadas

### Personalizar Recursos del Cluster

```bash
# Iniciar con 4 CPUs y 8GB RAM
minikube start --cpus=4 --memory=8192

# Especificar versión de Kubernetes
minikube start --kubernetes-version=v1.28.0

# Múltiples nodos (experimental)
minikube start --nodes=3

# Especificar driver
minikube start --driver=docker
```

---

### Múltiples Clusters Minikube

```bash
# Crear cluster "dev"
minikube start -p dev

# Crear cluster "staging"
minikube start -p staging

# Listar clusters
minikube profile list

# Cambiar entre clusters
minikube profile dev
kubectl get nodes

minikube profile staging
kubectl get nodes

# Eliminar cluster específico
minikube delete -p dev
```

---

### Configuración Persistente

```bash
# Establecer driver default
minikube config set driver docker

# Establecer CPUs default
minikube config set cpus 4

# Establecer memoria default
minikube config set memory 8192

# Ver configuración
minikube config view
```

---

## 📚 Cheat Sheet Rápido

### Minikube Lifecycle

```bash
minikube start              # Iniciar cluster
minikube status             # Ver estado
minikube pause              # Pausar (ahorra recursos)
minikube unpause            # Reanudar
minikube stop               # Detener
minikube delete             # Eliminar cluster
minikube logs               # Ver logs
```

---

### kubectl Básico

```bash
kubectl get pods            # Listar pods
kubectl get all             # Todos los recursos
kubectl describe pod <name> # Detalles del pod
kubectl logs <pod>          # Ver logs
kubectl exec -it <pod> sh   # Shell en pod
kubectl delete pod <name>   # Eliminar pod
```

---

### Crear Recursos

```bash
kubectl create deployment nginx --image=nginx    # Deployment
kubectl expose deployment nginx --port=80        # Service
kubectl scale deployment nginx --replicas=3      # Escalar
kubectl apply -f app.yaml                        # Desde YAML
kubectl delete -f app.yaml                       # Eliminar YAML
```

---

### Troubleshooting

```bash
kubectl get events                               # Ver eventos
kubectl describe pod <name>                      # Diagnosticar pod
kubectl logs <pod>                               # Logs del pod
kubectl logs -f <pod>                            # Logs en tiempo real
kubectl exec <pod> -- <command>                  # Ejecutar comando
minikube logs                                    # Logs de Minikube
```

---

## ❓ Preguntas de Repaso

### Conceptuales

1. **¿Cuál es la diferencia entre Minikube y un cluster de producción?**
   <details>
   <summary>Ver respuesta</summary>
   
   | Aspecto | Minikube | Producción |
   |---------|----------|------------|
   | **Nodos** | 1 (single-node) | Multi-nodo (3-100+) |
   | **Control Plane** | En el mismo nodo | Separado (HA) |
   | **Uso** | Desarrollo, testing | Aplicaciones reales |
   | **HA** | No | Sí (multi-master) |
   | **Persistencia** | Efímera | Permanente |
   | **Costo** | Gratis | $$$ |
   </details>

2. **¿Para qué sirve kubectl?**
   <details>
   <summary>Ver respuesta</summary>
   
   - **kubectl** es el CLI (Command Line Interface) de Kubernetes
   - Permite interactuar con el cluster (crear, leer, actualizar, eliminar recursos)
   - Se comunica con el **API Server** del cluster
   - Funciona con cualquier cluster K8s (Minikube, EKS, AKS, GKE, etc.)
   - Usa el archivo `~/.kube/config` para autenticarse
   </details>

---

### Técnicas

3. **¿Cómo verificas que Minikube está funcionando correctamente?**
   <details>
   <summary>Ver respuesta</summary>
   
   ```bash
   # Paso 1: Estado de Minikube
   minikube status
   # Debe mostrar: host, kubelet, apiserver = Running
   
   # Paso 2: Nodos del cluster
   kubectl get nodes
   # minikube   Ready   control-plane   ...
   
   # Paso 3: Pods del sistema
   kubectl get pods -n kube-system
   # Todos deberían estar "Running"
   
   # Paso 4: Información del cluster
   kubectl cluster-info
   # Debe mostrar URL del API server
   
   # Paso 5: Crear pod de prueba
   kubectl run test --image=nginx
   kubectl get pod test
   # Debe estar "Running"
   kubectl delete pod test
   ```
   </details>

4. **¿Cómo expones una aplicación en Minikube para acceder desde tu navegador?**
   <details>
   <summary>Ver respuesta</summary>
   
   **Opción 1: NodePort Service + minikube service**
   ```bash
   # Crear deployment
   kubectl create deployment nginx --image=nginx
   
   # Exponer con NodePort
   kubectl expose deployment nginx --port=80 --type=NodePort
   
   # Acceder (abre navegador)
   minikube service nginx
   ```
   
   **Opción 2: Port-forward**
   ```bash
   # Port-forward directo
   kubectl port-forward service/nginx 8080:80
   # Acceder: http://localhost:8080
   ```
   
   **Opción 3: Ingress (más avanzado)**
   ```bash
   # Habilitar addon
   minikube addons enable ingress
   
   # Crear Ingress resource
   kubectl apply -f ingress.yaml
   
   # Acceder con IP de Minikube
   curl http://$(minikube ip)/ruta
   ```
   </details>

---

### Troubleshooting

5. **Un pod está en estado `ImagePullBackOff`. ¿Cómo lo diagnosticas?**
   <details>
   <summary>Ver respuesta</summary>
   
   ```bash
   # Paso 1: Ver detalles del pod
   kubectl describe pod <nombre-pod>
   # Buscar sección "Events" al final
   # Probablemente diga: "Failed to pull image ..."
   
   # Paso 2: Verificar nombre de imagen
   kubectl get pod <nombre-pod> -o yaml | grep image:
   # Buscar typos: nignx vs nginx, version incorrecta
   
   # Paso 3: Corregir deployment
   kubectl edit deployment <nombre>
   # Cambiar image: nginx:1.21 (correcto)
   
   # Paso 4: Verificar pull de imagen (desde Minikube)
   minikube ssh
   docker pull nginx:1.21
   # Si falla → problema de conectividad o imagen no existe
   ```
   </details>

6. **Minikube no inicia y dice "PROVIDER_DOCKER_NOT_RUNNING". ¿Qué haces?**
   <details>
   <summary>Ver respuesta</summary>
   
   ```bash
   # Paso 1: Verificar Docker
   sudo systemctl status docker
   # Si está "inactive" → iniciarlo
   sudo systemctl start docker
   
   # Paso 2: Verificar permisos
   docker ps
   # Si dice "permission denied":
   sudo usermod -aG docker $USER
   newgrp docker
   
   # Paso 3: Limpiar y reintentar
   minikube delete
   minikube start --driver=docker
   
   # Paso 4: Verificar
   minikube status
   ```
   </details>

---

## 🎓 Siguiente Paso

Ahora que tienes Minikube funcionando:

➡️ **Módulo 04: Pods vs Contenedores** - Crear tu primer Pod

Aprenderás a:
- Crear Pods con kubectl y YAML
- Entender la diferencia entre Pod y contenedor Docker
- Inspeccionar Pods con describe, logs, exec
- Pods multi-contenedor

**Tu cluster está listo para experimentar!** 🚀

---

**✅ Checklist de Instalación**:
- [ ] Docker instalado y funcionando (`docker ps`)
- [ ] kubectl instalado (`kubectl version`)
- [ ] Minikube instalado (`minikube version`)
- [ ] Cluster iniciado (`minikube status` = Running)
- [ ] kubectl conectado (`kubectl get nodes` = Ready)
- [ ] Pod de prueba funciona (`kubectl run test --image=nginx`)

Si todos los checks están ✅ → **¡Estás listo para continuar el curso!**
