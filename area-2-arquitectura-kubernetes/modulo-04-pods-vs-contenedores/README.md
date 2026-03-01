# Capítulo 6: Pods vs Contenedores Docker

Con Minikube funcionando, exploramos la unidad mínima de ejecución en Kubernetes: el Pod. Veremos cómo se diferencia de un contenedor Docker y por qué Kubernetes añade esta capa de abstracción.

---

## 💡 Concepto Clave: Pod ≠ Contenedor

**IMPORTANTE**: Un Pod NO es un contenedor más potente.

```
DOCKER:              KUBERNETES:
┌──────────┐         ┌─────────────────────────┐
│Container │         │         Pod             │
│  nginx   │         │  ┌──────────┐           │
└──────────┘         │  │ pause    │ (infra)   │
                     │  └──────────┘           │
                     │  ┌──────────┐           │
                     │  │ nginx    │           │
                     │  └──────────┘           │
                     │  ┌──────────┐           │
                     │  │ logger   │ (sidecar) │
                     │  └──────────┘           │
                     └─────────────────────────┘
                      Comparten: Network, IPC, localhost
```

**Un Pod es una abstracción que permite**:
- Múltiples contenedores hablando por `localhost`
- Volúmenes compartidos entre contenedores
- Ciclo de vida coordinado
- IP única para todo el grupo

---

## 🎯 Objetivos del Módulo (Expandido)

Al completar este módulo serás capaz de:

- ✅ **Explicar la evolución histórica** de contenedores hasta Pods
- ✅ **Definir qué es un Pod** y diferenciarlo de un contenedor Docker
- ✅ **Comprender el contenedor pause** como infraestructura del Pod
- ✅ **Identificar los 7 namespaces Linux** y cuáles se comparten
- ✅ **Diseñar Pods multi-contenedor** usando patrones Sidecar, Adapter, Ambassador
- ✅ **Crear Pods con kubectl** (run, apply) y YAML
- ✅ **Inspeccionar Pods** con describe, logs, exec
- ✅ **Diagnosticar fallos** usando estados y eventos
- ✅ **Aplicar mejores prácticas** en diseño de Pods

### Patrones Multi-Contenedor
- ✅ **Implementar el patrón Sidecar** para logging, monitoring y service mesh
- ✅ **Utilizar Init Containers** para tareas de preparación y dependencias
- ✅ **Aplicar el patrón Ambassador** para proxy y load balancing

### Arquitectura y Decisiones
- ✅ **Decidir cuándo usar** un Pod multi-contenedor vs múltiples Pods
- ✅ **Migrar aplicaciones** de Docker Compose a Kubernetes
- ✅ **Evitar antipatrones** comunes en diseño de Pods

---

## 📚 Prerequisitos

Antes de comenzar este módulo, asegúrate de tener:

**Conocimientos:**
- ✅ Conceptos básicos de contenedores Docker
- ✅ Familiaridad con comandos `docker run`, `docker-compose`
- ✅ Conocimientos básicos de Linux (procesos, networking)
- ✅ Comprensión de la arquitectura de Kubernetes (Módulo 02)

**Entorno técnico:**
- ✅ Minikube instalado y funcionando (completar Módulo 03)
- ✅ kubectl configurado correctamente
- ✅ Cluster de Minikube iniciado con driver Docker

**Verificación rápida:**
```bash
# Verificar que Minikube está corriendo
minikube status

# Verificar conexión a kubectl
kubectl get nodes

# Debería mostrar:
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   Xd    vX.XX.X
```

---

## 🗺️ Estructura del Módulo

Este módulo está organizado siguiendo la progresión **Teoría → Ejemplo → Laboratorio**:

| Sección | Tema | Contenido |
|---------|------|-----------|
| **1** | [Fundamentos y Evolución](#📚-1-la-evolución-de-los-contenedores) | Historia LXC→Docker→K8s, motivación de Pods |
| **2** | [Anatomía de un Pod](#🧩-2-qué-es-un-pod-la-evolución-final) | Contenedor pause, arquitectura interna, networking |
| **3** | [Docker vs Pods](#🆚-3-docker-vs-pods-evolución-práctica) | Evolución práctica y comparación |
| **4** | [Patrones Multi-Contenedor](#🎨-4-patrones-multi-contenedor-en-pods) | Sidecar, Init Containers, Ambassador |
| **5** | [Migración Docker Compose](#🛠️-5-migración-docker-compose--kubernetes) | Cuándo usar Pods vs múltiples Pods, migración |
| **6** | [Laboratorios Prácticos](#🧪-6-laboratorios-prácticos) | Ejercicios guiados paso a paso |
| **7** | [Ciclo de Vida](#🔄-7-ciclo-de-vida-de-pods) | Estados y transiciones de Pods |
| **8** | [Ejemplos Disponibles](#🧪-8-ejemplos-prácticos-disponibles) | Índice completo de ejemplos YAML |
| **9** | [Antipatrones y Best Practices](#🚨-9-antipatrones-y-mejores-prácticas) | Qué evitar y mejores prácticas |
| **10** | [Debugging](#🔧-10-debugging-y-troubleshooting) | Herramientas de diagnóstico |

**🔍 Separación de responsabilidades:**
- Este módulo (04): **Qué es un Pod y patrones básicos**
- Módulo 05: **Gestión avanzada** (manifiestos complejos, resource management, health checks)

---

## 🎓 Recursos de Aprendizaje

### Ejemplos Prácticos
📁 **Carpeta**: [`ejemplos/`](./ejemplos/)
- 40+ archivos YAML ejecutables organizados por concepto
- Cada ejemplo está documentado con comentarios explicativos
- Comandos de prueba incluidos en cada archivo

### Laboratorios Guiados
📁 **Carpeta**: [`laboratorios/`](./laboratorios/)
- 5 laboratorios paso a paso con verificaciones
- Duración total: ~4 horas de práctica
- Incluyen troubleshooting y cleanup

### Documentación de Referencia
- 📖 [`ejemplos/README.md`](./ejemplos/README.md) - Índice de todos los ejemplos
- 📖 [`laboratorios/README.md`](./laboratorios/README.md) - Guía de laboratorios
- 📘 **[`RESUMEN-MODULO.md`](./RESUMEN-MODULO.md)** - **Guía de estudio estructurada** (RECOMENDADO)

---

## 🎓 Guía de Estudio Recomendada

**¿Primera vez con este módulo?** Te recomendamos seguir la guía de estudio:

👉 **[ABRIR GUÍA DE ESTUDIO](./RESUMEN-MODULO.md)**

La guía te proporciona:
- ✅ Ruta de aprendizaje paso a paso
- ✅ Progresión pedagógica: Teoría → Ejemplo → Lab
- ✅ Checkpoints de verificación en cada sección
- ✅ Tiempo estimado por fase
- ✅ Enlaces directos a ejemplos y labs relevantes

**Estructura de la guía**:
1. **Fase 1**: Fundamentos y evolución (45-60 min)
2. **Fase 2**: Namespaces Linux (60-90 min)
3. **Fase 3**: Patrones multi-contenedor (90-120 min)
4. **Fase 4**: Decisiones de arquitectura (45-60 min)
5. **Fase 5**: Best practices (30-45 min)

---

## 📚 1. La Evolución de los Contenedores

🧪 **Laboratorio práctico**: [`laboratorios/lab-01-evolucion.md`](./laboratorios/lab-01-evolucion.md) - Demuestra la evolución con ejemplos ejecutables

### **⏳ Línea de Tiempo: LXC → Docker → Kubernetes**

```
2008: LXC (Linux Containers)
├─ Contenedores completamente aislados
├─ Cada uno con su propia red, PID, IPC
└─ Comunicación entre contenedores muy compleja

2013: Docker 
├─ Simplifica la gestión de contenedores
├─ Introduce la red bridge para comunicación
└─ Facilita compartir recursos entre contenedores

2014: Kubernetes
├─ Introduce el concepto de "Pod"
├─ Agrupa contenedores relacionados
└─ Comparte namespaces automáticamente
```

### **🏗️ El Problema Original (LXC)**

```
┌─────────────────┐    ┌─────────────────┐
│   Contenedor 1  │    │   Contenedor 2  │
│                 │    │                 │
│  🌐 Red: IP1    │ ❌ │  🌐 Red: IP2    │
│  🔄 PID: NS1    │ ❌ │  🔄 PID: NS2    │  
│  💬 IPC: NS1    │ ❌ │  💬 IPC: NS2    │
│  🏷️ UTS: NS1    │ ❌ │  🏷️ UTS: NS2    │
└─────────────────┘    └─────────────────┘

❌ Problema: Aislamiento total = Comunicación compleja
```

### **🌉 La Solución Docker (Red Bridge)**

```
┌─────────────────┐    ┌─────────────────┐
│   Contenedor 1  │    │   Contenedor 2  │
│   IP: 172.17.2  │    │   IP: 172.17.3  │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────┬───────────────┘
                 │
        ┌────────▼────────┐
        │   Docker Bridge │
        │   (docker0)     │
        └─────────────────┘

✅ Solución: Red compartida para comunicación
```

---

## 🧩 2. ¿Qué es un Pod? (La Evolución Final)

### **📖 Definición Técnica:**

> **Pod = Wrapper que comparte Linux namespaces entre contenedores**

### **🔬 Cómo Funciona Internamente:**

Cuando Kubernetes crea un Pod, internamente sigue estos pasos:

```
Paso 1: Kubernetes crea un "contenedor pausa" (dummy)
┌─────────────────────────────────────────┐
│     Contenedor Pausa (k8s.gcr.io/pause) │
│                                         │
│  🌐 Network Namespace: 10.244.1.15      │
│  🔄 PID Namespace: 1001                 │
│  💬 IPC Namespace: 1001                 │
│  🏷️ UTS Namespace: pod-xyz              │
└─────────────────────────────────────────┘

Paso 2: Otros contenedores "heredan" estos namespaces
┌──────────────────┐  ┌──────────────────┐
│   App Container  │  │Sidecar Container │
│                  │  │                  │
│ 🌐 Hereda: ──────┼──┼─→ 10.244.1.15    │
│ 🔄 Hereda: ──────┼──┼─→ PID NS: 1001   │
│ 💬 Hereda: ──────┼──┼─→ IPC NS: 1001   │
│ 🏷️ Hereda: ──────┼──┼─→ UTS: pod-xyz   │
│                  │  │                  │
│ ❌ NO comparten: │  │ ❌ NO comparten: │
│ 📁 Mount NS      │  │ 📁 Mount NS      │
│ 👤 User NS       │  │ � User NS        │
│ ⚙️ Cgroup        │  │ ⚙️ Cgroup        │
└──────────────────┘  └──────────────────┘

Resultado: Pod con comunicación optimizada
```

### **🧬 Los Linux Namespaces en Kubernetes**

#### **📚 ¿Qué son los Namespaces en Linux?**

Un **namespace** en Linux es un mecanismo del kernel que **aísla recursos** entre procesos. Permite que diferentes procesos tengan vistas independientes de recursos del sistema.

| Namespace | Abreviación | Recursos que aísla |
|-----------|-------------|-------------------|
| **Network** | `net` | Stack de red (IP, interfaces, puertos, routing) |
| **PID** | `pid` | IDs de procesos (árbol de procesos) |
| **IPC** | `ipc` | Comunicación entre procesos (shared memory, semaphores, message queues) |
| **UTS** | `uts` | Hostname y nombre de dominio |
| **Mount** | `mnt` | Puntos de montaje del filesystem |
| **User** | `user` | UIDs y GIDs de usuarios |
| **Cgroup** | `cgroup` | Jerarquía de control groups |

Cada contenedor normalmente tiene su **propio conjunto de namespaces**, lo que lo aísla de otros contenedores y del host.

---

### **🎯 Namespaces Compartidos en un Pod (Por Defecto)**

En Kubernetes, **todos los contenedores dentro del mismo Pod comparten automáticamente**:

📂 **Ver ejemplos prácticos completos**: [`ejemplos/02-namespaces/`](./ejemplos/02-namespaces/)  
🧪 **Laboratorio práctico**: [`laboratorios/lab-02-namespace-sharing.md`](./laboratorios/lab-02-namespace-sharing.md) - Explora todos los 7 tipos de namespaces

#### **1. 🌐 Network Namespace (net) - COMPARTIDO**

📄 **Ejemplo práctico**: [`ejemplos/02-namespaces/01-network-namespace.yaml`](./ejemplos/02-namespaces/01-network-namespace.yaml)

```bash
# Todos los contenedores del Pod comparten:
# - Misma IP del Pod
# - Mismas interfaces de red (eth0, lo)
# - Mismo stack TCP/IP
# - Mismos puertos (no pueden usar el mismo puerto dos veces)

IP_DEL_POD="10.244.1.15"

# Comunicación interna vía localhost
Container1 → localhost:8080 → Container2
Container2 → localhost:9090 → Container1

# Verificar IP compartida:
kubectl exec my-pod -c container1 -- ip addr show eth0
kubectl exec my-pod -c container2 -- ip addr show eth0
# ↑ Ambos muestran la MISMA IP: 10.244.1.15
```

**Implicaciones:**
- ✅ Comunicación ultra-rápida vía `localhost`
- ❌ No pueden usar el mismo puerto (conflicto)
- ✅ Comparten la misma IP pública del Pod

---

#### **2. 💬 IPC Namespace (ipc) - COMPARTIDO**

📄 **Ejemplo práctico**: [`ejemplos/02-namespaces/03-ipc-namespace.yaml`](./ejemplos/02-namespaces/03-ipc-namespace.yaml)

```bash
# Inter-Process Communication: Los contenedores pueden comunicarse mediante:
# - POSIX Shared Memory (/dev/shm)
# - Semaphores (sincronización)
# - Message Queues (colas de mensajes)

# Ver recursos IPC compartidos:
kubectl exec my-pod -c container1 -- ipcs -m  # Shared memory segments
kubectl exec my-pod -c container2 -- ipcs -m
# ↑ Ambos ven los MISMOS recursos IPC

# Ver semáforos:
kubectl exec my-pod -c container1 -- ipcs -s

# Ver message queues:
kubectl exec my-pod -c container1 -- ipcs -q
```

**Casos de uso:**
- 🚀 **High-performance computing**: Transferencia de datos sin copiar (zero-copy)
- 📊 **Machine Learning**: Producer-consumer con shared memory
- 🔄 **Sincronización**: Semáforos para coordinar acceso a recursos

**Ejemplo práctico - Shared Memory:**
```bash
# Container 1: Escribir en shared memory
kubectl exec my-pod -c writer -- sh -c 'echo "Hello from writer" > /dev/shm/data.txt'

# Container 2: Leer desde shared memory
kubectl exec my-pod -c reader -- cat /dev/shm/data.txt
# ↑ Output: Hello from writer
```

---

#### **3. 🏷️ UTS Namespace (uts) - COMPARTIDO**

📄 **Ejemplo práctico**: [`ejemplos/02-namespaces/04-uts-namespace.yaml`](./ejemplos/02-namespaces/04-uts-namespace.yaml)

```bash
# Unix Timesharing System: Comparten hostname y dominio

# Verificar hostname compartido:
kubectl exec my-pod -c container1 -- hostname
# → my-pod-xyz-12345

kubectl exec my-pod -c container2 -- hostname  
# → my-pod-xyz-12345 (MISMO hostname)

# Ver información completa:
kubectl exec my-pod -c container1 -- uname -n
```

**Implicación:**
- Útil para aplicaciones que dependen del hostname
- Logs y métricas muestran el mismo hostname

---

### **⚙️ Namespaces Opcionales o Parcialmente Compartidos**

#### **4. 🔄 PID Namespace (pid) - OPCIONAL**

📄 **Ejemplo práctico**: [`ejemplos/02-namespaces/02-pid-namespace.yaml`](./ejemplos/02-namespaces/02-pid-namespace.yaml)

```bash
# Por defecto: NO compartido
# Se puede habilitar con: shareProcessNamespace: true

# SIN shareProcessNamespace (default):
kubectl exec my-pod -c container1 -- ps aux
# ↑ Solo ve sus propios procesos

# CON shareProcessNamespace: true
kubectl exec my-pod -c container1 -- ps aux
# ↑ Ve TODOS los procesos del Pod (container1 Y container2)
```

**Ejemplo con PID Namespace compartido:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shared-pid-demo
spec:
  shareProcessNamespace: true  # ← Habilitar PID compartido
  containers:
  - name: nginx
    image: nginx:alpine
  - name: debug
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
```

```bash
# Ahora el contenedor debug puede ver procesos de nginx:
kubectl exec shared-pid-demo -c debug -- ps aux
# PID  USER     COMMAND
# 1    root     /pause           # Contenedor pause
# 7    root     nginx: master    # Proceso de nginx
# 15   root     sleep 3600       # Proceso de debug
```

**Casos de uso:**
- � **Debugging**: Inspeccionar procesos de otros contenedores
- 📊 **Monitoring**: Sidecars que monitorizan procesos del app
- 🔧 **Process management**: Enviar señales entre contenedores

**Diferencia clave con IPC:**
- **PID Namespace**: Ver/gestionar **procesos** (ps, kill, signals)
- **IPC Namespace**: **Comunicación** entre procesos (shared memory, semaphores)

---

#### **5. 📁 Mount Namespace (mnt) - NO COMPARTIDO (pero pueden compartir volúmenes)**

📄 **Ejemplo práctico**: [`ejemplos/02-namespaces/05-mount-namespace.yaml`](./ejemplos/02-namespaces/05-mount-namespace.yaml)

```yaml
# Cada contenedor tiene su PROPIO filesystem raíz
# PERO pueden montar los MISMOS volúmenes

apiVersion: v1
kind: Pod
spec:
  containers:
  - name: writer
    image: busybox
    volumeMounts:
    - name: shared-data
      mountPath: /data  # ← Mismo volumen, diferente namespace
    command: ["sh", "-c", "echo 'Hello' > /data/file.txt && sleep 3600"]
    
  - name: reader
    image: busybox
    volumeMounts:
    - name: shared-data
      mountPath: /data  # ← Mismo volumen, diferente namespace
    command: ["sh", "-c", "sleep 5 && cat /data/file.txt && sleep 3600"]
    
  volumes:
  - name: shared-data
    emptyDir: {}  # Volumen compartido
```

**Diferencia:**
- ❌ No comparten el **Mount Namespace** (cada uno tiene su vista del filesystem)
- ✅ Sí comparten **volúmenes** si se montan explícitamente

---

### **🚫 Namespaces NO Compartidos**

#### **6. 👤 User Namespace (user) - NO COMPARTIDO**

📄 **Ejemplo práctico**: [`ejemplos/02-namespaces/06-user-namespace.yaml`](./ejemplos/02-namespaces/06-user-namespace.yaml)

```bash
# Cada contenedor puede tener diferentes UIDs/GIDs
# Útil para seguridad (root en container != root en host)

kubectl exec my-pod -c container1 -- id
# uid=0(root) gid=0(root)

kubectl exec my-pod -c container2 -- id
# uid=1000(appuser) gid=1000(appuser)
```

**Seguridad:**
- Permite ejecutar como `root` dentro del contenedor
- Pero mapeado a usuario sin privilegios en el host

---

#### **7. ⚙️ Cgroup Namespace - NO COMPARTIDO (Control de Recursos)**

📄 **Ejemplo práctico**: [`ejemplos/02-namespaces/07-cgroup-namespace.yaml`](./ejemplos/02-namespaces/07-cgroup-namespace.yaml)

```yaml
# Cada contenedor tiene control INDEPENDIENTE de recursos
containers:
- name: web
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "1000m"
      memory: "1Gi"
      
- name: sidecar
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "200m" 
      memory: "256Mi"
```

---

### **📊 Tabla Resumen: Namespaces en Pods**

| Namespace | Compartido | Propósito | Implicación |
|-----------|------------|-----------|-------------|
| **Network** (net) | ✅ Sí | Misma IP, puertos, interfaces | Comunicación localhost |
| **IPC** (ipc) | ✅ Sí | Shared memory, semaphores, queues | Comunicación ultra-rápida |
| **UTS** (uts) | ✅ Sí | Mismo hostname | Identidad compartida |
| **PID** (pid) | ⚙️ Opcional | Ver procesos entre contenedores | Debugging/monitoring |
| **Mount** (mnt) | ⚙️ Parcial | Filesystem independiente | Pueden compartir volúmenes |
| **User** (user) | 🚫 No | UIDs/GIDs independientes | Seguridad |
| **Cgroup** | 🚫 No | Recursos independientes | Aislamiento de recursos |

---

### **🧪 Verificar Namespaces Directamente**

#### **Ver namespaces de un proceso:**
```bash
# Desde el nodo (requiere acceso SSH al nodo):
# 1. Obtener PID de un contenedor
crictl ps | grep my-pod
crictl inspect <container-id> | grep pid

# 2. Listar namespaces del proceso
lsns -p <pid>

# Ejemplo de output:
#        NS TYPE   NPROCS   PID USER  COMMAND
# 4026532198 mnt       2     1 root  /pause
# 4026532199 uts       3     1 root  /pause  ← Compartido
# 4026532200 ipc       3     1 root  /pause  ← Compartido
# 4026532201 pid       2     1 root  /pause
# 4026532202 net       3     1 root  /pause  ← Compartido
```

#### **Comparar namespaces entre contenedores del mismo Pod:**
```bash
# Ver que comparten net, ipc, uts pero NO mnt
lsns -p <pid-container1>
lsns -p <pid-container2>

# Los namespaces net, ipc, uts tendrán el MISMO número
# Los namespaces mnt, pid, user tendrán números DIFERENTES
```

---

### **🧠 Resumen Visual Completo**

```
┌──────────────────────────────────────────────────────────┐
│                    Pod: my-app-pod                       │
│                  IP: 10.244.1.15                         │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  🌐 SHARED: Network Namespace (net)                      │
│     ├─ Misma IP: 10.244.1.15                             │
│     ├─ Mismas interfaces: eth0, lo                       │
│     └─ Comunicación: localhost:8080 ↔ localhost:9090     │
│                                                          │
│  💬 SHARED: IPC Namespace (ipc)                          │
│     ├─ Shared Memory: /dev/shm                           │
│     ├─ Semaphores compartidos                            │
│     └─ Message Queues compartidas                        │
│                                                          │
│  🏷️ SHARED: UTS Namespace (uts)                          │
│     └─ Hostname: my-app-pod-xyz-12345                    │
│                                                          │
│  🔄 OPTIONAL: PID Namespace (pid)                        │
│     └─ Si shareProcessNamespace: true → procesos visibles│
│                                                          │
├──────────────────────────────────────────────────────────┤
│  Container: web-app                                      │
│  ├─ 📁 Mount NS: /app, /usr, /etc (independiente)        │
│  ├─ 👤 User NS: uid=1000 (appuser)                       │
│  ├─ ⚙️ Cgroup: CPU 500m, Memory 512Mi                    │
│  └─ 📦 Volumes: /data → shared-volume                    │
├──────────────────────────────────────────────────────────┤
│  Container: sidecar                                      │
│  ├─ 📁 Mount NS: /app, /usr, /etc (independiente)        │
│  ├─ 👤 User NS: uid=0 (root)                             │
│  ├─ ⚙️ Cgroup: CPU 100m, Memory 128Mi                    │
│  └─ 📦 Volumes: /data → shared-volume                    │
└──────────────────────────────────────────────────────────┘

✅ Compartidos por defecto: Network, IPC, UTS
⚙️ Opcionales: PID (con shareProcessNamespace)
🚫 No compartidos: Mount, User, Cgroup
📦 Volúmenes: Pueden compartirse explícitamente
```

---

### **💡 Key Takeaways: PID vs IPC**

| Aspecto | PID Namespace | IPC Namespace |
|---------|---------------|---------------|
| **Función** | 👀 **Ver** procesos | 💬 **Comunicarse** entre procesos |
| **Compartido por defecto** | ❌ No (opcional) | ✅ Sí (automático) |
| **Activación** | `shareProcessNamespace: true` | Siempre activo en Pods |
| **Comandos útiles** | `ps aux`, `kill`, `top` | `ipcs -m`, `ipcs -s`, `ipcs -q` |
| **Velocidad** | N/A (visibilidad) | 🚀 Ultra-rápido (microsegundos) |
| **Caso de uso** | Debugging, monitoring | High-performance data sharing |
| **Mecanismos** | Ver árbol de procesos | Shared memory, semaphores, queues |
| **Ejemplo** | Ver procesos de nginx desde debug | Transferir datos vía /dev/shm |

---

## 🆚 3. Docker vs Pods: Evolución Práctica

### **📊 Comparación Visual:**

#### **🐳 Docker Approach (Manual)**
```bash
# Crear red personalizada
docker network create app-network

# Ejecutar contenedores en la red
docker run -d --name web --network app-network nginx
docker run -d --name api --network app-network node-app
docker run -d --name db --network app-network postgres

# Comunicación: web → api.app-network → db.app-network
```

#### **☸️ Kubernetes Approach (Automático)**

En Kubernetes, los contenedores en el mismo Pod comparten la red automáticamente:

📄 **Ver ejemplo completo**: [`ejemplos/03-multi-container/web-api-pod.yaml`](./ejemplos/03-multi-container/web-api-pod.yaml)

```yaml
# Snippet simplificado - networking automático
containers:
  - name: web
    image: nginx
    # Puede comunicarse con api en localhost:3000
  - name: api
    image: node-app
    ports:
    - containerPort: 3000
```

### **🔄 Migration Path: Compose → Kubernetes**

#### **Before: docker-compose.yml**
```yaml
version: '3.8'
services:
  web:
    image: nginx
    ports:
      - "8080:80"
    depends_on:
      - api
      
  api:
    image: node-app
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=db
      
  db:
    image: postgres
    environment:
      - POSTGRES_DB=myapp
```

#### **After: Kubernetes Strategy**

**Option A: Multi-Pod (Recommended)**
```yaml
# web-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80

---
# api-deployment.yaml  
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: node-app
        image: node-app
        ports:
        - containerPort: 3000
        env:
        - name: DB_HOST
          value: "db-service"

---
# db-deployment.yaml
apiVersion: apps/v1  
kind: Deployment
metadata:
  name: db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: postgres
        image: postgres
        env:
        - name: POSTGRES_DB
          value: "myapp"
```

**Option B: Single Pod (Edge cases only)**

📄 **Ver ejemplo completo**: [`ejemplos/03-multi-container/tightly-coupled-pod.yaml`](./ejemplos/03-multi-container/tightly-coupled-pod.yaml)

```yaml
# Solo si están fuertemente acoplados (raro)
# Ejemplo: procesamiento de logs en tiempo real
containers:
  - name: main-app
    volumeMounts:
    - name: log-volume
      mountPath: /app/logs
  - name: log-processor
    volumeMounts:
    - name: log-volume
      mountPath: /logs
```

---

## 🎨 4. Patrones Multi-Contenedor en Pods

### **� ¿Qué son los Patrones Multi-Contenedor?**

> **Patrones Multi-Contenedor** = Arquitecturas donde **múltiples contenedores cooperan dentro del mismo Pod** para lograr un objetivo común.

#### **🤔 ¿Por qué varios contenedores en un Pod?**

**Principio de diseño:**
```
┌─────────────────────────────────────────────────┐
│  "Cada contenedor debe hacer UNA cosa bien"     │
│                                                 │
│  ✅ CORRECTO:                                   │
│  ┌──────────────────┐                           │
│  │ Pod: Web App     │                           │
│  ├──────────────────┤                           │
│  │ Container 1: App │  → Lógica de negocio      │
│  │ Container 2: Log │  → Recolección de logs    │
│  │ Container 3: Mtrc│  → Métricas               │
│  └──────────────────┘                           │
│                                                 │
│  ❌ INCORRECTO:                                 │
│  ┌──────────────────┐                           │
│  │ Container único  │                           │
│  ├──────────────────┤                           │
│  │ App + Logs +     │  → Monolito complicado    │
│  │ Métricas + Proxy │     difícil de mantener   │
│  └──────────────────┘                           │
└─────────────────────────────────────────────────┘
```

**Ventajas del enfoque multi-contenedor:**
- 🔧 **Separation of concerns**: Cada contenedor tiene una responsabilidad
- ♻️ **Reusabilidad**: Los sidecars pueden reutilizarse entre aplicaciones
- 🔄 **Actualizaciones independientes**: Actualizar logging sin tocar la app
- 📦 **Imágenes especializadas**: Cada contenedor usa la imagen óptima
- 🎯 **Testing aislado**: Probar componentes por separado

#### **🔑 Características de los Contenedores en un Pod:**

```
┌──────────────────────────────────────────────┐
│              Mismo Pod                       │
│  ┌────────────┐        ┌────────────┐        │
│  │ Container A│        │ Container B│        │
│  └────────────┘        └────────────┘        │
│                                              │
│  ✅ Comparten:                               │
│  ├─ 🌐 Network (localhost)                   │
│  ├─ 💾 Volumes (archivos)                    │
│  ├─ 🔌 IPC (memoria compartida)              │
│  └─ 📍 Mismo nodo físico                     │
│                                              │
│  ❌ NO comparten (por defecto):              │
│  ├─ 🔐 PID namespace                         │
│  ├─ 📁 Filesystem                            │
│  └─ 👤 User namespace                        │
└──────────────────────────────────────────────┘
```

#### **📚 Los 3 Patrones Principales:**

| Patrón | Propósito | Cuándo Corre | Ejemplo Típico |
|--------|-----------|--------------|----------------|
| **🔄 Sidecar** | Extender funcionalidad de la app | ♾️ Simultáneo (toda la vida) | Logging, monitoring, service mesh |
| **🚀 Init Container** | Preparar el ambiente antes de iniciar | ⏰ Antes (secuencial) | Migraciones DB, downloads, wait-for |
| **🔗 Ambassador** | Proxy/intermediario con externos | ♾️ Simultáneo (toda la vida) | Load balancing, SSL, connection pool |

**Analogía del mundo real:**

```
🏗️ Construcción de un Edificio:

┌─────────────────────────────────────────────┐
│ Init Container = Preparar terreno           │
│   - Nivelación                              │
│   - Fundaciones                             │
│   - Instalaciones básicas                   │
│   → Termina antes de construir              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Main Container = Edificio principal         │
│   - Estructura principal                    │
│   - Lógica de negocio                       │
│   → Corre indefinidamente                   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Sidecar = Servicios de soporte              │
│   - Seguridad (guardias)                    │
│   - Mantenimiento (limpieza)                │
│   - Utilities (electricidad)                │
│   → Corre mientras el edificio existe       │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Ambassador = Recepcionista/Portero          │
│   - Filtra quién entra                      │
│   - Dirige visitantes                       │
│   - Gestiona acceso                         │
│   → Intermediario con el exterior           │
└─────────────────────────────────────────────┘
```

#### **🎯 Cuándo Usar Multi-Contenedor vs Múltiples Pods:**

| Situación | Solución | Razón |
|-----------|----------|-------|
| Logging de la app | ✅ Multi-contenedor (Sidecar) | Necesitan acceso a mismo filesystem |
| Database y App | ❌ Pods separados | Lifecycle independiente |
| Migraciones DB | ✅ Multi-contenedor (Init) | Deben ejecutarse antes de la app |
| Load balancer | ❌ Service separado | Infraestructura compartida |
| Connection pooling | ✅ Multi-contenedor (Ambassador) | Tightly coupled con la app |
| Microservicios | ❌ Pods separados | Scaling independiente |
| Service mesh proxy | ✅ Multi-contenedor (Sidecar) | Intercepta todo el tráfico |

#### **⚠️ Consideraciones Importantes:**

```yaml
# ❌ ANTI-PATTERN: Demasiados contenedores
apiVersion: v1
kind: Pod
metadata:
  name: bloated-pod
spec:
  containers:
  - name: app
  - name: logs
  - name: metrics
  - name: proxy
  - name: cache
  - name: queue
  # ... 10 más
  # Problema: Difícil de debugear, alto acoplamiento

# ✅ CORRECTO: Solo lo estrictamente necesario
apiVersion: v1
kind: Pod
metadata:
  name: well-designed-pod
spec:
  containers:
  - name: app           # Lógica principal
  - name: log-shipper   # Solo si necesita acceso al filesystem
  # Los demás servicios (cache, queue) deberían ser Pods separados
```

**Reglas de oro:**
1. 🎯 **Cohesión alta**: Los contenedores deben estar fuertemente relacionados
2. 🔗 **Acoplamiento bajo con otros Pods**: No dependencias fuertes externas
3. ⚖️ **Mismo lifecycle**: Escalan juntos, se despliegan juntos
4. 📦 **Mínimo necesario**: Menos contenedores = más simple

---

### **�🔄 Patrón 1: Sidecar Container**

#### **📖 ¿Qué es un Sidecar?**

> **Sidecar** = Contenedor auxiliar que **extiende o mejora** el contenedor principal sin modificar su código.

**Concepto:**
```
┌─────────────────────────────────────────┐
│              Pod                        │
│  ┌─────────────────┐  ┌──────────────┐  │
│  │ Main Container  │  │   Sidecar    │  │
│  │                 │  │              │  │
│  │  🌐 Web App     │◄─┤ 📊 Logs      │  │
│  │  (Nginx)        │  │ (Fluent Bit) │  │
│  │                 │  │              │  │
│  │  Genera logs ──►│──┤ Procesa logs │  │
│  │                 │  │              │  │
│  └─────────────────┘  └──────────────┘  │
│           │                    │        │
│           └──────┬─────────────┘        │
│                  ▼                      │
│          Shared Volume                  │
└─────────────────────────────────────────┘
```

**Características del Sidecar:**
- ✅ **Corre simultáneamente** con el contenedor principal
- ✅ **Comparte recursos** del Pod (network, volumes)
- ✅ **Funcionalidad cross-cutting**: logging, monitoring, security
- ✅ **No modifica** el código del app principal
- ✅ **Mismo ciclo de vida** que el contenedor principal

#### **🎯 Cuándo Usar Sidecar:**

| Situación | ¿Usar Sidecar? | Razón |
|-----------|----------------|-------|
| Procesar logs de la app | ✅ Sí | El sidecar lee y procesa logs sin modificar la app |
| Exportar métricas | ✅ Sí | El sidecar recolecta y expone métricas |
| Service mesh (Istio) | ✅ Sí | El sidecar maneja networking/security transparentemente |
| Sincronizar configs | ✅ Sí | El sidecar actualiza configs sin reiniciar la app |
| Lógica de negocio | ❌ No | Debe estar en el contenedor principal |

#### **📋 Ejemplos Prácticos**

Los siguientes ejemplos demuestran diferentes usos del patrón Sidecar:

**1. 📊 Logging Sidecar** - Procesamiento de logs con Fluent Bit
```bash
kubectl apply -f ejemplos/03-multi-container/01-sidecar-logging.yaml
kubectl logs web-with-logging -c log-processor
```
👉 Ver archivo completo: [`01-sidecar-logging.yaml`](./ejemplos/03-multi-container/01-sidecar-logging.yaml)

**2. 📈 Monitoring Sidecar** - Exportar métricas con Prometheus
```bash
kubectl apply -f ejemplos/03-multi-container/02-sidecar-monitoring.yaml
kubectl port-forward pod/app-with-monitoring 9113:9113
curl localhost:9113/metrics
```
👉 Ver archivo completo: [`02-sidecar-monitoring.yaml`](./ejemplos/03-multi-container/02-sidecar-monitoring.yaml)

**3. 🌐 Service Mesh Sidecar** - Proxy con Envoy
```bash
kubectl apply -f ejemplos/03-multi-container/03-sidecar-service-mesh.yaml
kubectl port-forward pod/app-with-proxy 8080:10000
```
👉 Ver archivo completo: [`03-sidecar-service-mesh.yaml`](./ejemplos/03-multi-container/03-sidecar-service-mesh.yaml)

📚 **Guía completa:** Ver [`ejemplos/03-multi-container/README.md`](./ejemplos/03-multi-container/README.md)

🧪 **Laboratorio práctico:** [`laboratorios/lab-03-sidecar-real-world.md`](./laboratorios/lab-03-sidecar-real-world.md) - Implementación real con Flask + Fluent Bit

#### **🚀 Casos de Uso Comunes del Patrón Sidecar:**

- **📊 Logging:** Fluentd, Logstash, Filebeat - Centralizar logs sin modificar la app
- **📈 Monitoring:** Prometheus exporter - Exportar métricas custom
- **🔐 Security:** OAuth2 Proxy, Vault Agent - Autenticación/autorización transparente
- **🌐 Service Mesh:** Envoy Proxy (Istio/Linkerd) - mTLS, traffic routing, observability
- **🔄 Config Sync:** Config syncer - Actualizar configs sin reiniciar

#### **✅ Ventajas del Patrón Sidecar:**

- 🔄 **Separación de responsabilidades**: La app se enfoca en negocio
- 🔌 **Reutilizable**: El mismo sidecar para múltiples apps
- 🛡️ **No invasivo**: No modifica el código del app
- 📦 **Composable**: Múltiples sidecars para diferentes funciones
- 🔧 **Actualizable**: Update sidecar sin tocar la app

#### **❌ Cuándo NO Usar Sidecar:**

- ❌ Si la funcionalidad es parte del negocio → Incluir en main container
- ❌ Si requiere comunicación frecuente → Mejor usar localhost HTTP
- ❌ Si hay muchos sidecars → Considerar separar Pods
- ❌ Si consume muchos recursos → Evaluar arquitectura

---

### **🚀 Patrón 2: Init Container**

🧪 **Laboratorio práctico**: [`laboratorios/lab-04-init-migration.md`](./laboratorios/lab-04-init-migration.md) - Migración de Docker setup a Init Containers

#### **📖 ¿Qué es un Init Container?**

> **Init Container** = Contenedor que **se ejecuta y completa ANTES** de que los contenedores principales inicien.

**Concepto:**
```
Ciclo de Vida del Pod:

1. Pod Created
   ↓
2. ┌─────────────────────┐
   │  Init Container 1   │  (Setup database)
   │  Runs → Completes   │
   └─────────────────────┘
   ↓
3. ┌─────────────────────┐
   │  Init Container 2   │  (Download config)
   │  Runs → Completes   │
   └─────────────────────┘
   ↓
4. ┌─────────────────────┐
   │  Main Container     │  ← Solo inicia cuando TODOS
   │  STARTS             │    los Init Containers terminan
   └─────────────────────┘
```

**Diferencias clave:**

| Aspecto | Init Container | Main Container | Sidecar |
|---------|----------------|----------------|---------|
| **Cuándo corre** | ⏰ ANTES | 🏃 Simultáneo | 🏃 Simultáneo |
| **Ejecución** | 📝 Secuencial | 🔄 Paralelo | 🔄 Paralelo |
| **Duración** | ⚡ Termina | ♾️ Corre indefinidamente | ♾️ Corre indefinidamente |
| **Si falla** | 🔁 Pod restart | 🔁 Container restart | 🔁 Container restart |
| **Propósito** | 🛠️ Setup/preparación | 💼 Lógica de negocio | 🔧 Funciones auxiliares |

#### **🎯 Cuándo Usar Init Containers:**

| Situación | ¿Usar Init Container? | Razón |
|-----------|------------------------|-------|
| Migrar DB antes de iniciar | ✅ Sí | Garantiza schema actualizado |
| Esperar que DB esté lista | ✅ Sí | Evita fallos al conectar |
| Descargar assets/configs | ✅ Sí | Prepara ambiente antes de app |
| Setup de permisos | ✅ Sí | Configuración one-time |
| Procesar logs en tiempo real | ❌ No | Usar Sidecar |
| Lógica de negocio | ❌ No | Usar Main Container |

#### **📋 Ejemplos Prácticos**

Los siguientes ejemplos demuestran diferentes usos de Init Containers:

**1. 🗄️ Database Migrations** - Ejecutar migraciones SQL antes de iniciar
```bash
kubectl apply -f ejemplos/04-init-containers/01-init-db-migration.yaml
kubectl logs web-with-init -c database-migration
```
👉 Ver archivo completo: [`01-init-db-migration.yaml`](./ejemplos/04-init-containers/01-init-db-migration.yaml)

**2. ⏳ Wait for Dependencies** - Esperar múltiples servicios externos
```bash
kubectl apply -f ejemplos/04-init-containers/02-init-wait-for-deps.yaml
kubectl logs app-wait-deps -c wait-for-redis
```
👉 Ver archivo completo: [`02-init-wait-for-deps.yaml`](./ejemplos/04-init-containers/02-init-wait-for-deps.yaml)

**3. 🔧 Configuration Setup** - Generar configs, descargar assets, setup permisos
```bash
kubectl apply -f ejemplos/04-init-containers/03-init-config-setup.yaml
kubectl exec app-config-setup -- cat /app/config/app.conf
```
👉 Ver archivo completo: [`03-init-config-setup.yaml`](./ejemplos/04-init-containers/03-init-config-setup.yaml)

📚 **Guía completa:** Ver [`ejemplos/04-init-containers/README.md`](./ejemplos/04-init-containers/README.md)

#### **✅ Ventajas de Init Containers:**

- 🔒 **Orden garantizado**: Ejecución secuencial predecible
- ✅ **Pre-requisitos claros**: La app solo inicia si todo está listo
- 🔁 **Retry automático**: Si falla, K8s reinicia el Pod
- 🧹 **Limpio**: No consume recursos después de completar
- 🛡️ **Separation of concerns**: Setup separado de runtime

#### **❌ Cuándo NO Usar Init Containers:**

- ❌ Para procesos que deben correr **simultáneamente** con la app → Usar Sidecar
- ❌ Para tareas **recurrentes** durante la vida del Pod → Usar Main Container
- ❌ Para **monitoreo continuo** → Usar Sidecar
- ❌ Si la tarea puede **fallar ocasionalmente** sin afectar la app → Usar Job separado

---

### **🔗 Patrón 3: Ambassador Container**

#### **📖 ¿Qué es un Ambassador Container?**

> **Ambassador** = Contenedor que actúa como **proxy/intermediario** entre el contenedor principal y servicios externos.

**Concepto:**
```
┌──────────────────────────────────────────────┐
│                   Pod                        │
│  ┌────────────────┐      ┌───────────────┐   │
│  │ Main Container │      │  Ambassador   │   │
│  │                │      │               │   │
│  │  App conecta:  │      │  🔀 Proxy     │   │
│  │  localhost:5432│─────►│  Maneja:      │   │
│  │                │      │  - Routing    │   │
│  │  (Piensa que   │      │  - Pooling    │───┼─► DB Replica 1
│  │   es DB local) │      │  - Balancing  │   │
│  │                │      │  - Retry      │───┼─► DB Replica 2
│  │                │      │  - Circuit    │   │
│  └────────────────┘      │    Breaking   │───┼─► DB Replica 3
│                          └───────────────┘   │
└──────────────────────────────────────────────┘
```

**Beneficios clave:**
- 🔌 **Abstracción**: La app no sabe que hay múltiples backends
- 🔄 **Load balancing**: Distribuye carga entre réplicas
- 🛡️ **Resiliency**: Circuit breaking, retries automáticos
- 🔐 **Security**: SSL/TLS termination, autenticación
- 📊 **Observability**: Logging, métricas de conexiones

#### **🎯 Cuándo Usar Ambassador:**

| Situación | ¿Usar Ambassador? | Razón |
|-----------|-------------------|-------|
| App conecta a DB con múltiples réplicas | ✅ Sí | Load balancing automático |
| Necesitas connection pooling | ✅ Sí | Ambassador maneja el pool |
| SSL/TLS termination | ✅ Sí | Simplifica configuración de app |
| Circuit breaking | ✅ Sí | Resiliencia sin modificar app |
| Service mesh simple | ✅ Sí | Alternativa ligera a Istio |
| Conexión directa simple | ❌ No | Overhead innecesario |

#### **📋 Ejemplos Prácticos**

Los siguientes ejemplos demuestran diferentes usos del patrón Ambassador:

**1. 🗄️ Database Connection Pooling** - PgBouncer para pooling transparente
```bash
kubectl apply -f ejemplos/05-ambassador/01-ambassador-db-pool.yaml
kubectl logs app-with-pooling -c db-ambassador
```
👉 Ver archivo completo: [`01-ambassador-db-pool.yaml`](./ejemplos/05-ambassador/01-ambassador-db-pool.yaml)

**2. 🔄 Load Balancing** - HAProxy para distribuir carga entre réplicas
```bash
kubectl apply -f ejemplos/05-ambassador/02-ambassador-loadbalancer.yaml
kubectl port-forward pod/app-with-lb 8404:8404
# Ver stats en: http://localhost:8404/stats
```
👉 Ver archivo completo: [`02-ambassador-loadbalancer.yaml`](./ejemplos/05-ambassador/02-ambassador-loadbalancer.yaml)

**3. 🔐 SSL/TLS Termination** - Nginx para manejar encryption/decryption
```bash
kubectl apply -f ejemplos/05-ambassador/03-ambassador-ssl.yaml
kubectl port-forward pod/app-with-ssl 8443:443
curl -k https://localhost:8443
```
� Ver archivo completo: [`03-ambassador-ssl.yaml`](./ejemplos/05-ambassador/03-ambassador-ssl.yaml)

📚 **Guía completa:** Ver [`ejemplos/05-ambassador/README.md`](./ejemplos/05-ambassador/README.md)

#### **✅ Ventajas del Patrón Ambassador:**

- 🔌 **Transparente**: La app no necesita cambios
- 🎯 **Single responsibility**: La app solo hace negocio
- 🔄 **Resiliencia**: Retry, circuit breaking automático
- � **Performance**: Connection pooling, caching
- 🔐 **Seguridad**: Encryption, autenticación centralizada

#### **❌ Cuándo NO Usar Ambassador:**

- ❌ Conexiones **simples y directas** → Overhead innecesario
- ❌ **Service mesh completo** ya instalado (Istio) → Usar el mesh
- ❌ Solo un **backend** disponible → No hay qué balancear
- ❌ App ya maneja **connection pooling** → Duplicaría lógica

---

### **📊 Comparación de los 3 Patrones**

| Aspecto | Sidecar | Init Container | Ambassador |
|---------|---------|----------------|------------|
| **Cuándo corre** | 🔄 Simultáneo con main | ⏰ Antes de main | 🔄 Simultáneo con main |
| **Duración** | ♾️ Toda la vida del Pod | ⚡ Hasta completar | ♾️ Toda la vida del Pod |
| **Propósito** | 🔧 Extender funcionalidad | 🛠️ Setup/preparación | 🔀 Proxy/intermediario |
| **Interacción** | 📁 Shared volumes | 📁 Shared volumes | 🌐 Network localhost |
| **Ejemplos** | Logging, Monitoring | Migrations, Downloads | Load balancing, SSL |
| **Falla** | 🔁 Restart contenedor | 🔁 Restart Pod completo | 🔁 Restart contenedor |
| **Recursos** | ⚖️ Comparte con main | ✨ Liberados al terminar | ⚖️ Comparte con main |

---

### **🎯 Decidir Qué Patrón Usar**

```
┌─────────────────────────────────────────────────────┐
│          ¿Qué Patrón Multi-Container Usar?          │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ❓ ¿Necesitas preparar el ambiente ANTES de        │
│     que la app inicie?                              │
│     └─► ✅ INIT CONTAINER                           │
│         (migrations, downloads, wait-for-deps)      │
│                                                     │
│  ❓ ¿Necesitas procesar/exportar datos de la app    │
│     mientras corre?                                 │
│     └─► ✅ SIDECAR                                  │
│         (logging, monitoring, security)             │
│                                                     │
│  ❓ ¿Necesitas intermediario entre app y servicios  │
│     externos?                                       │
│     └─► ✅ AMBASSADOR                               │
│         (load balancing, SSL, pooling)              │
│                                                     │
│  ❓ ¿La funcionalidad es parte del negocio?         │
│     └─► ❌ NO usar patterns, incluir en MAIN        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 🛠️ 5. Migración: Docker Compose → Kubernetes

🧪 **Laboratorio práctico**: [`laboratorios/lab-05-compose-migration.md`](./laboratorios/lab-05-compose-migration.md) - Migración paso a paso completa

### **🐳 Docker Compose Original:**

📄 **Ver archivo completo**: [`ejemplos/05-migracion-compose/docker-compose.yml`](./ejemplos/05-migracion-compose/docker-compose.yml)

```yaml
# docker-compose.yml - Estructura típica
version: '3.8'
services:
  web:
    image: nginx:1.20
    depends_on: [api]
  api:
    image: my-api:v1.0
    depends_on: [db]
  db:
    image: postgres:13
    volumes:
      - db_data:/var/lib/postgresql/data
```

### **☸️ Kubernetes Equivalent:**

#### **Opción 1: Pods Separados (Recomendado)**

📄 **Ver manifests completos**:
- [`ejemplos/05-migracion-compose/k8s/web-pod.yaml`](./ejemplos/05-migracion-compose/k8s/web-pod.yaml)
- [`ejemplos/05-migracion-compose/k8s/api-pod.yaml`](./ejemplos/05-migracion-compose/k8s/api-pod.yaml)
- [`ejemplos/05-migracion-compose/k8s/db-pod.yaml`](./ejemplos/05-migracion-compose/k8s/db-pod.yaml)

```yaml
# Estructura: 3 Pods + Services + ConfigMaps + Secrets + PVC
# web-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  labels:
    app: web
spec:
  containers:
  - name: nginx
    image: nginx:1.20
    # ... (ver archivo completo para detalles)

---
# api-pod.yaml + Service
# db-pod.yaml + Service + PVC + Secret
# (Ver archivos completos para implementación completa)
```

#### **Opción 2: Multi-Container Pod (Casos específicos)**

📄 **Ver ejemplo completo**: [`ejemplos/03-multi-container/advanced-realtime-processing.yaml`](./ejemplos/03-multi-container/advanced-realtime-processing.yaml)

```yaml
# Solo cuando los contenedores están FUERTEMENTE acoplados
# Ejemplo: procesamiento en tiempo real de datos compartidos
containers:
  - name: web-app
    volumeMounts:
    - name: shared-data
      mountPath: /app/data
  
  - name: data-processor
    volumeMounts:
    - name: shared-data
      mountPath: /processor/input
    # Nota: Solo cuando necesitas IPC, shared memory, baja latencia
```

### **🎯 Decisión Matrix: ¿Un Pod o Múltiples Pods?**

```
┌─────────────────────────────────────────────────────────┐
│                  DECISIÓN ARCHITECTURE                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  🟢 UN SOLO POD cuando:                                 │
│  ├─ Comunicación muy frecuente (microsegundos)          │
│  ├─ Shared memory o IPC necesario                       │
│  ├─ Mismo ciclo de vida ESTRICTO                        │
│  ├─ Datos compartidos en tiempo real                    │
│  └─ Imposible separar funcionalmente                    │
│                                                         │
│  🔴 PODS SEPARADOS cuando:                              │
│  ├─ Escalado independiente necesario                    │
│  ├─ Actualizaciones independientes                      │
│  ├─ Comunicación vía HTTP/gRPC                          │
│  ├─ Diferentes equipos o ownership                      │
│  ├─ Diferentes resource requirements                    │
│  └─ Fault isolation deseado                             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🧪 6. Laboratorios Prácticos

### **🎓 [Ir a Laboratorios Completos](./laboratorios/README.md)**

Hemos preparado **5 laboratorios prácticos** step-by-step para que domines Pods y contenedores:

| Lab | Título | Duración | Nivel | Conceptos Clave |
|-----|--------|----------|-------|-----------------|
| 1️⃣ | [Evolución Histórica Práctica](./laboratorios/lab-01-evolucion.md) | 30 min | Principiante | LXC → Docker → Kubernetes |
| 2️⃣ | [Namespace Sharing Deep Dive](./laboratorios/lab-02-namespace-sharing.md) | 40 min | Intermedio | Network, PID, IPC, UTS, Mount, User |
| 3️⃣ | [Sidecar Pattern Real-World](./laboratorios/lab-03-sidecar-real-world.md) | 60 min | Avanzado | Flask + Fluent Bit, Shared Volumes |
| 4️⃣ | [Init Container Migration](./laboratorios/lab-04-init-migration.md) | 70 min | Avanzado | Sequential Setup, Dependency Mgmt |
| 5️⃣ | [Migración Docker Compose](./laboratorios/lab-05-compose-migration.md) | 50 min | Intermedio | Deployments, Services, PVC |

**Duración total**: ~4 horas | **[📚 Índice completo de laboratorios](./laboratorios/README.md)**

### � Inicio Rápido

```bash
# Navegar a laboratorios
cd laboratorios/

# Comenzar con Lab 1
cat lab-01-evolucion.md
```

Cada laboratorio incluye:
- ✅ Objetivos claros y resultados esperados
- ✅ Código completo copy-paste ready
- ✅ Explicaciones paso a paso con observaciones
- ✅ Verificaciones y tests
- ✅ Cleanup automático

---

## 🔄 7. Ciclo de Vida de Pods

### **📊 Pod Lifecycle:**

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Pending   │───►│   Running   │───►│ Succeeded/  │
│             │    │             │    │   Failed    │
└─────────────┘    └─────────────┘    └─────────────┘
       │                                       │
       └─────────────────┬─────────────────────┘
                         ▼
                  ┌─────────────┐
                  │   Unknown   │
                  └─────────────┘
```

### **🔍 Estados Detallados:**

```yaml
# kubectl describe pod my-pod
Status:           Running
Phase:            Running
Conditions:
  Type              Status
  Initialized       True
  Ready             True  
  ContainersReady   True
  PodScheduled      True

Init Containers:
  init-migration:
    State:          Terminated
    Reason:         Completed
    Exit Code:      0

Containers:
  web-app:
    State:          Running
    Started:        2023-11-02T10:00:00Z
    Ready:          True
    Restart Count:  0
  
  sidecar:
    State:          Running
    Started:        2023-11-02T10:00:05Z
    Ready:          True
    Restart Count:  1
```

### **⚡ Container Restart Policies:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restart-policy-demo
spec:
  restartPolicy: Always  # Always, OnFailure, Never
  containers:
  - name: app
    image: my-app:v1.0
    # Si el container falla:
    # Always: Restart siempre
    # OnFailure: Restart solo si exit code != 0
    # Never: Nunca restart
```

---

## 🧪 8. Ejemplos Prácticos Disponibles

### **� [Ver Todos los Ejemplos](./ejemplos/README.md)**

Todos los ejemplos YAML están disponibles en la carpeta `ejemplos/` organizados por concepto:

### **🚀 Ejemplos Disponibles:**

#### **1. [01-evolucion/](./ejemplos/01-evolucion/)** - Evolución LXC → Docker → Kubernetes
   - `evolution-pod.yaml` - Demo de networking compartido

#### **2. [02-namespaces/](./ejemplos/02-namespaces/)** - Exploración detallada de los 7 namespaces
   - `01-network-namespace.yaml` - 🌐 Network namespace compartido
   - `02-pid-namespace.yaml` - 🔄 PID namespace (con/sin shareProcessNamespace)
   - `03-ipc-namespace.yaml` - 💬 IPC namespace (shared memory, semaphores)
   - `04-uts-namespace.yaml` - 🏷️ UTS namespace (hostname compartido)
   - `05-mount-namespace.yaml` - 📁 Mount namespace (filesystem independiente)
   - `06-user-namespace.yaml` - 👤 User namespace (UIDs/GIDs diferentes)
   - `07-cgroup-namespace.yaml` - ⚙️ Cgroup namespace (recursos independientes)
   - `namespace-pod.yaml` - Demo general (legacy)

#### **3. [03-multi-container/](./ejemplos/03-multi-container/)** - Patrones multi-contenedor
   **Sidecar Pattern:**
   - `01-sidecar-logging.yaml` - Fluent Bit para procesamiento de logs
   - `02-sidecar-monitoring.yaml` - Prometheus exporter para métricas
   - `03-sidecar-service-mesh.yaml` - Envoy proxy para service mesh
   
   **Multi-container avanzado:**
   - `web-api-pod.yaml` - Comunicación localhost entre contenedores
   - `tightly-coupled-pod.yaml` - Pod fuertemente acoplado (edge case)
   - `advanced-realtime-processing.yaml` - Procesamiento en tiempo real
   - `sidecar-pod.yaml` - Demo básica (legacy)

#### **4. [04-init-containers/](./ejemplos/04-init-containers/)** - Init containers
   - `01-init-db-migration.yaml` - Migraciones SQL antes de iniciar
   - `02-init-wait-for-deps.yaml` - Esperar múltiples dependencias
   - `03-init-config-setup.yaml` - Generar configs, descargar assets
   - `init-pod.yaml` - Demo básica (legacy)
   - `postgres-pod.yaml` - Database para testing

#### **5. [05-ambassador/](./ejemplos/05-ambassador/)** - Patrón Ambassador
   - `01-ambassador-db-pool.yaml` - PgBouncer para connection pooling
   - `02-ambassador-loadbalancer.yaml` - HAProxy para load balancing
   - `03-ambassador-ssl.yaml` - Nginx para SSL/TLS termination

#### **6. [05-migracion-compose/](./ejemplos/05-migracion-compose/)** - Migración Docker Compose
   **Original:**
   - `docker-compose.yml` - Configuración Docker Compose original
   
   **Kubernetes (Deployments):**
   - `web-deployment.yaml` - Frontend Nginx con réplicas
   - `api-deployment.yaml` - Backend Node.js con réplicas
   - `db-deployment.yaml` - Database PostgreSQL con PVC
   
   **Kubernetes (Pods - para comparación):**
   - `k8s/web-pod.yaml` - Web Pod con ConfigMap
   - `k8s/api-pod.yaml` - API Pod con Service
   - `k8s/db-pod.yaml` - DB Pod con PVC + Secret

#### **7. [09-antipatrones/](./ejemplos/09-antipatrones/)** - Antipatrones y soluciones
   - `01-fat-pods.yaml` - ❌ Fat Pods → ✅ Separación de responsabilidades
   - `02-singleton-services.yaml` - ❌ Pod único → ✅ Deployment con réplicas
   - `03-volume-abuse.yaml` - ❌ Filesystem para comunicación → ✅ HTTP/gRPC

**Total: 40 archivos YAML** organizados en 7 carpetas temáticas

### **🎯 Inicio Rápido:**

```bash
# 1. Explorar la evolución LXC → Docker → K8s
kubectl apply -f ejemplos/01-evolucion/evolution-pod.yaml
kubectl exec evolution-demo -c web -- wget -qO- http://localhost:8080

# 2. Analizar los 7 tipos de namespaces
kubectl apply -f ejemplos/02-namespaces/01-network-namespace.yaml
kubectl apply -f ejemplos/02-namespaces/02-pid-namespace.yaml
kubectl apply -f ejemplos/02-namespaces/03-ipc-namespace.yaml
# Ver README completo: ejemplos/02-namespaces/README.md

# 3. Probar patrón sidecar (logging)
kubectl apply -f ejemplos/03-multi-container/01-sidecar-logging.yaml
kubectl logs web-with-logging -c log-processor -f

# 4. Probar patrón sidecar (monitoring)
kubectl apply -f ejemplos/03-multi-container/02-sidecar-monitoring.yaml
kubectl port-forward pod/app-with-monitoring 9113:9113
curl localhost:9113/metrics

# 5. Ver init containers en acción
kubectl apply -f ejemplos/04-init-containers/01-init-db-migration.yaml
kubectl get pods -w  # Ver progreso de init containers
kubectl logs <pod> -c wait-for-db
kubectl logs <pod> -c database-migration

# 6. Probar patrón Ambassador (DB pooling)
kubectl apply -f ejemplos/05-ambassador/01-ambassador-db-pool.yaml
kubectl logs app-with-pooling -c db-ambassador

# 7. Estudiar antipatrones y soluciones
kubectl apply -f ejemplos/09-antipatrones/01-fat-pods.yaml
# Ver: ejemplos/09-antipatrones/README.md
```

### **📖 Documentación de Ejemplos:**

Consulta **[ejemplos/README.md](./ejemplos/README.md)** para:
- Descripción detallada de cada ejemplo
- Comandos de uso y testing
- Conceptos que demuestra cada ejemplo
- Instrucciones de limpieza


```bash
# Aplicar y probar
kubectl apply -f multi-container-pod.yaml
kubectl get pods
kubectl logs web-with-sidecar -c nginx
kubectl logs web-with-sidecar -c log-reader -f
kubectl exec -it web-with-sidecar -c nginx -- bash
```

---

## 🚨 9. Antipatrones y Mejores Prácticas

### **❌ Antipatrones Comunes:**

📂 **Ver ejemplos completos en**: [`ejemplos/09-antipatrones/`](./ejemplos/09-antipatrones/)

#### **1. "Fat Pods" - Demasiados contenedores**

📄 **Ejemplo completo**: [`ejemplos/09-antipatrones/01-fat-pods.yaml`](./ejemplos/09-antipatrones/01-fat-pods.yaml)

```yaml
# ❌ MALO: Demasiados contenedores no relacionados
containers:
  - name: web
  - name: api
  - name: worker
  - name: scheduler
  - name: monitoring
  - name: cache
  # ❌ Difícil debugear, alto acoplamiento

# ✅ BUENO: Separar en Pods distintos
# web-pod (nginx + log-processor sidecar)
# api-pod (api + metrics-exporter sidecar)
# worker-pod, cache-pod (separados)
```

#### **2. "Singleton Services" - Un Pod para todo**

📄 **Ejemplo completo**: [`ejemplos/09-antipatrones/02-singleton-services.yaml`](./ejemplos/09-antipatrones/02-singleton-services.yaml)

```yaml
# ❌ MALO: Pod único (single point of failure)
kind: Pod
metadata:
  name: monolith-pod

# ✅ BUENO: Deployment con réplicas
kind: Deployment
spec:
  replicas: 3  # Alta disponibilidad
```

#### **3. "Shared Volumes Abuse" - Volúmenes para comunicación**

📄 **Ejemplo completo**: [`ejemplos/09-antipatrones/03-volume-abuse.yaml`](./ejemplos/09-antipatrones/03-volume-abuse.yaml)

```yaml
# ❌ MALO: Usar filesystem para comunicación
containers:
  - name: producer
    # Escribe archivos para comunicarse
  - name: consumer
    # Lee archivos para obtener datos

# ✅ BUENO: Usar HTTP/gRPC
containers:
  - name: producer
    ports: [8080]
  - name: consumer
    env:
      - name: PRODUCER_URL
        value: "http://localhost:8080"
```

### **✅ Mejores Prácticas:**

1. **Un Pod = Una responsabilidad principal**
2. **Sidecar solo si es esencial** para la función principal
3. **Init containers para setup** que debe completarse antes
4. **Shared volumes solo para datos compartidos** reales
5. **Use Deployments**, no Pods directos en producción

---

## 🔧 10. Debugging y Troubleshooting

### **🔍 Comandos Esenciales:**

```bash
# Información general del Pod
kubectl get pods
kubectl get pods -o wide
kubectl describe pod my-pod

# Logs de contenedores
kubectl logs my-pod                    # Single container
kubectl logs my-pod -c container-name  # Multi-container
kubectl logs my-pod --previous         # Previous instance
kubectl logs my-pod -f                 # Follow logs

# Ejecutar comandos en contenedores
kubectl exec -it my-pod -- bash                    # Single container
kubectl exec -it my-pod -c container-name -- bash  # Multi-container

# Debug de networking
kubectl exec -it my-pod -- wget -qO- localhost:8080
kubectl exec -it my-pod -- netstat -tlnp
kubectl exec -it my-pod -- ps aux

# Información de recursos
kubectl top pod my-pod
kubectl get events --field-selector involvedObject.name=my-pod
```

### **🚨 Problemas Comunes:**

| Síntoma | Causa Probable | Solución |
|---------|----------------|----------|
| Pod "Pending" | Resources insuficientes | `kubectl describe pod` → Check events |
| Pod "CrashLoopBackOff" | App falla al iniciar | `kubectl logs pod --previous` |
| Pod "ImagePullBackOff" | Imagen no existe | Check image name/registry |
| Container "OOMKilled" | Out of memory | Increase memory limits |
| Pod "Evicted" | Node pressure | Check node resources |

---

## ✅ Resumen del Módulo

### **🎯 Conceptos Clave Aprendidos:**

1. **Pod = Unidad mínima** en Kubernetes (no contenedor individual)
2. **Shared resources** entre contenedores del mismo Pod
3. **Patrones de diseño** (Sidecar, Init, Ambassador)
4. **Migración estratégica** de Docker Compose
5. **Mejores prácticas** para diseño de Pods

### **🔄 Diferencias Fundamentales:**

| Docker Compose | Kubernetes Pods |
|----------------|-----------------|
| Service-oriented | Pod-oriented |
| File-based networking | IP-based networking |
| Manual scaling | Declarative scaling |
| Single-host | Multi-host capable |
| External orchestration | Built-in orchestration |

### **💡 Key Takeaways:**

- **No uses Pods directamente** en producción → Usa Deployments
- **Multi-container Pods** solo cuando estén fuertemente acoplados
- **Sidecar pattern** es poderoso para cross-cutting concerns
- **Init containers** son perfectos para setup tasks
- **Shared networking** simplifica comunicación localhost

## Resumen del Capítulo

Este capítulo cubrió los conceptos fundamentales de pods vs contenedores docker, desde la teoría hasta la práctica con ejemplos y manifiestos YAML aplicables en entornos reales. Los laboratorios en el directorio `laboratorios/` permiten practicar cada concepto, y el `RESUMEN-MODULO.md` sirve como guía de repaso rápido.
