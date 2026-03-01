# Capítulo 5: Instalación de Minikube

Llevamos cuatro capítulos construyendo una base teórica: virtualización, contenedores, qué es Kubernetes y cómo funciona su arquitectura interna. Todo ese conocimiento es necesario, pero hay un límite a lo que se puede aprender leyendo. Ha llegado el momento de tener un cluster real en tus manos.

**El problema real**: Kubernetes no se puede aprender de memoria como una tabla de multiplicar. Cada concepto -Pods, Services, Deployments, ConfigMaps- solo se entiende verdaderamente cuando lo ejecutas, lo rompes y lo reparas. Sin un cluster donde practicar, estás memorizando comandos sin comprender qué hacen. Y los clusters de producción o de nube tienen costos, restricciones de permisos y consecuencias reales cuando algo sale mal, lo que los hace inadecuados para aprender.

**La solución**: Minikube crea un cluster de Kubernetes completo, con todos sus componentes, corriendo en tu laptop en cuestión de minutos. Es el entorno perfecto para experimentar sin miedo: si rompes algo, basta con `minikube delete` y `minikube start` para tener un cluster limpio en segundos.

**La analogía**: Aprender Kubernetes sin un cluster es como aprender a volar solo con libros. Minikube es el simulador de vuelo: un entorno controlado y seguro donde puedes practicar todas las maniobras, cometer errores sin consecuencias y ganar confianza antes de operar un cluster real en producción.

**En este capítulo** instalarás Docker, kubectl y Minikube paso a paso con verificaciones en cada etapa, aprenderás los comandos esenciales para manejar el ciclo de vida del cluster, explorarás el dashboard visual de Kubernetes, y habilitarás addons útiles como metrics-server e ingress. A partir de aquí, cada capítulo del curso irá acompañado de laboratorios prácticos que ejecutarás en este entorno.

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

#### 1.2 Drivers de Minikube: Comparativa Detallada

Minikube soporta varios drivers. El driver determina qué tecnología de virtualización o contenedores se usa para aislar el cluster. Elegir el driver correcto afecta rendimiento, compatibilidad y facilidad de uso.

| Driver | OS Compatible | Rendimiento | Virt. Anidada | Recomendado |
|--------|--------------|-------------|---------------|-------------|
| `docker` | Linux / macOS / Windows | Excelente | Si | Si (default) |
| `virtualbox` | Linux / macOS / Windows | Bueno | Si | Alternativa multiplataforma |
| `hyperkit` | macOS | Bueno | Si | macOS nativo (sin Docker Desktop) |
| `hyper-v` | Windows Pro/Enterprise | Bueno | No | Windows nativo |
| `kvm2` | Linux | Excelente | Si | Linux nativo (bare metal) |
| `podman` | Linux / macOS | Bueno | Si | Alternativa rootless a Docker |

**Notas importantes por driver:**

- **docker**: El mas recomendado para aprendizaje. Usa Docker como hypervisor de contenedores. No requiere VM completa, por lo que arranca rapido y consume menos RAM. El networking usa port-forward en lugar de IPs directas.
- **virtualbox**: Crea una VM completa. Mas aislamiento pero mayor consumo de recursos. Util como fallback si Docker no esta disponible.
- **hyperkit**: Driver nativo para macOS (antes de Apple Silicon). Requiere permisos de sudo. Deprecado en favor de Docker Desktop en maquinas Apple.
- **hyper-v**: Driver nativo de Windows. Requiere Windows Pro o Enterprise y que Hyper-V este habilitado en BIOS. No soporta virtualizacion anidada.
- **kvm2**: Driver nativo de Linux usando KVM/QEMU. Ofrece el mejor rendimiento en servidores Linux bare metal. Requiere que el CPU soporte virtualizacion y el modulo kvm cargado.
- **podman**: Alternativa rootless a Docker. Util en entornos corporativos donde Docker no esta permitido. Menos maduro que Docker para este caso de uso.

**Para este curso usamos Docker** porque:
- ✅ Instalacion simple y rapida en cualquier OS
- ✅ Bajo consumo de recursos comparado con VMs completas
- ✅ Excelente para aprendizaje y desarrollo
- ✅ Compatibilidad multiplataforma (Linux, macOS, Windows WSL2)
- ✅ Facil limpieza: `minikube delete` elimina solo el contenedor

**Configurar el driver por defecto** (evita escribirlo en cada `minikube start`):

```bash
# Establecer docker como driver por defecto
minikube config set driver docker

# Verificar el driver configurado
minikube config get driver
# Salida esperada: docker

# Ver toda la configuracion activa
minikube config view
# Salida esperada:
# - driver: docker
# - memory: 4096
# - cpus: 2
```

📖 **Ejemplo de comparacion**: [`ejemplos/01-instalacion/comparativa-drivers.md`](./ejemplos/01-instalacion/comparativa-drivers.md)

#### 1.3 Minikube vs Otras Herramientas de Cluster Local

Ademas de Minikube existen otras herramientas para correr Kubernetes localmente. Cada una tiene un caso de uso diferente. Esta tabla ayuda a entender por que el curso usa Minikube:

| Caracteristica | Minikube | Kind | k3d | k3s |
|----------------|----------|------|-----|-----|
| **Proposito principal** | Aprendizaje / Desarrollo | CI/Testing | Multi-nodo local | Edge / IoT / Produccion ligera |
| **Multi-nodo** | Si (--nodes=N) | Si | Si | Si |
| **Dashboard integrado** | Si (addon) | No | No | No |
| **Addons (30+)** | Si | No | No | Solo Helm |
| **Consumo de recursos** | Medio | Bajo | Bajo | Muy bajo |
| **Velocidad de inicio** | 1-3 min | 30-60 seg | 20-40 seg | Variable |
| **Ideal para** | Este curso | GitHub Actions / pipelines | Simular multi-cluster | Produccion en Raspberry Pi |

**Cuando usar cada herramienta:**

- **Minikube**: Cuando aprendes Kubernetes por primera vez o desarrollas localmente. El dashboard y los addons facilitan la exploracion visual del cluster.
- **Kind** (Kubernetes in Docker): Cuando necesitas clusters efimeros en pipelines de CI/CD (GitHub Actions, Jenkins). Arranca rapido y no deja estado persistente.
- **k3d**: Cuando necesitas simular un cluster multi-nodo en tu laptop para probar comportamiento de HA o scheduling. Wrapper de k3s en Docker.
- **k3s**: Cuando deploys en dispositivos con recursos limitados (Raspberry Pi, IoT) o necesitas un cluster ligero en produccion. No es una herramienta de desarrollo local sino una distribucion de Kubernetes reducida.

**Conclusion**: Para este curso, Minikube es la eleccion correcta. Su dashboard visual, sus mas de 30 addons preconfigurados y su documentacion extensa lo convierten en el mejor entorno de aprendizaje. Una vez que domines los conceptos aqui, trabajar con Kind, k3d o un cluster AKS real sera una transicion natural.

#### 1.4 Componentes que Instalaremos

```
┌─────────────────────────────────────────────────────────────┐
│                    STACK COMPLETO                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Docker Engine         → Runtime para Minikube           │
│  2. kubectl               → CLI de Kubernetes               │
│  3. Minikube              → Cluster local de K8s            │
│                                                             │
│  Flujo de instalación:                                      │
│  Docker → kubectl → Minikube → Verificación                 │
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
# Instalación automatizada con script
./ejemplos/01-instalacion/install-docker.sh

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

**Problema 6: minikube start se congela y no avanza**

```bash
# Sintoma:
# El comando "minikube start" se queda colgado mas de 5 minutos
# sin mostrar progreso ni errores.

# Causa mas comun: el driver no esta instalado o la virtualizacion
# no esta habilitada en el BIOS del host.

# Diagnostico:
minikube start --driver=docker --alsologtostderr -v=7
# La salida verbosa mostrara el punto exacto donde se atasca.

# Verificar que Docker esta activo:
systemctl is-active docker
# Salida esperada: active

# Verificar virtualizacion del CPU (necesario para kvm2/virtualbox):
grep -E 'vmx|svm' /proc/cpuinfo | head -1
# Si no hay salida, la virtualizacion esta deshabilitada en BIOS.

# Solucion con driver docker:
minikube delete
systemctl start docker
minikube start --driver=docker
```

**Problema 7: PROVIDER_DOCKER_NOT_RUNNING**

```bash
# Error:
# "Exiting due to PROVIDER_DOCKER_NOT_RUNNING: Found docker, but the
#  docker service is not healthy: ..."

# Causa: el daemon de Docker esta detenido o no tiene permisos.

# Solucion paso a paso:
# 1. Iniciar el daemon de Docker
sudo systemctl start docker

# 2. Verificar estado
sudo systemctl status docker
# Salida esperada: Active: active (running)

# 3. Verificar que tu usuario esta en el grupo docker
groups $USER | grep docker
# Si no aparece "docker", agregar el usuario:
sudo usermod -aG docker $USER
newgrp docker  # Aplicar sin cerrar sesion

# 4. Reintentar
minikube start --driver=docker
```

**Problema 8: "Requested memory allocation X is less than..."**

```bash
# Error:
# "Requested memory allocation (2048 MB) is less than the minimum
#  recommended amount (4096 MB) for Kubernetes."

# Causa: el host no tiene suficiente RAM libre o se esta asignando
# muy poca memoria al cluster.

# Verificar RAM disponible en el host:
free -h
# Salida de ejemplo:
#               total        used        free
# Mem:           15Gi        8.2Gi       6.8Gi

# Solucion: aumentar la memoria asignada a Minikube
minikube delete
minikube start --driver=docker --memory=4096
# O guardar como configuracion permanente:
minikube config set memory 4096
minikube start
```

**Problema 9: "Unable to connect to the server: dial tcp..."**

```bash
# Error:
# "Unable to connect to the server: dial tcp 127.0.0.1:XXXXX:
#  connect: connection refused"

# Causa: Minikube no esta iniciado o el contexto de kubectl
# apunta a otro cluster.

# Verificar que Minikube este corriendo:
minikube status
# Si la salida es "host: Stopped" o "host: Nonexistent":
minikube start

# Verificar el contexto activo de kubectl:
kubectl config current-context
# Debe mostrar: minikube
# Si muestra otro contexto:
kubectl config use-context minikube

# Regenerar kubeconfig si el problema persiste:
minikube update-context
kubectl config view --minify
```

**Problema 10: Problemas de DNS dentro del cluster**

```bash
# Sintoma: los Pods no pueden resolver nombres DNS internos
# (p.ej., "my-service.default.svc.cluster.local" no resuelve).

# Diagnostico: entrar al nodo y revisar la configuracion DNS:
minikube ssh

# Dentro del nodo Minikube:
cat /etc/resolv.conf
# Salida esperada: nameserver apuntando a la IP del cluster (10.96.0.10)

# Salir del nodo y revisar el Pod de CoreDNS:
kubectl get pods -n kube-system -l k8s-app=kube-dns
# Todos los pods CoreDNS deben estar en estado Running.

# Si CoreDNS no esta corriendo, reiniciarlo:
kubectl rollout restart deployment coredns -n kube-system

# Probar resolucion DNS desde un Pod temporal:
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- \
  nslookup kubernetes.default.svc.cluster.local
# Salida esperada: Server: 10.96.0.10 / Address: ...
```

📄 **Guia completa**: [`ejemplos/02-configuracion/troubleshooting-guide.md`](./ejemplos/02-configuracion/troubleshooting-guide.md)

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
# Script completo de setup del entorno
./ejemplos/02-configuracion/setup-environment.sh
```

📄 **Ver script completo**: [`ejemplos/02-configuracion/setup-environment.sh`](./ejemplos/02-configuracion/setup-environment.sh)

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

## Resumen del Capítulo

Este capítulo cubrió los conceptos fundamentales de instalación de minikube, desde la teoría hasta la práctica con ejemplos y manifiestos YAML aplicables en entornos reales. Los laboratorios en el directorio `laboratorios/` permiten practicar cada concepto, y el `RESUMEN-MODULO.md` sirve como guía de repaso rápido.
