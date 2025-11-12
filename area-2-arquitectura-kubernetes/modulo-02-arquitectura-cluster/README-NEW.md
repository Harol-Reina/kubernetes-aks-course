# Módulo 02: Arquitectura del Cluster Kubernetes

## Tabla de Contenidos

1. [Introducción al Módulo](#introducción-al-módulo)
2. [Visión General de la Arquitectura](#1-visión-general-de-la-arquitectura)
3. [Control Plane - El Cerebro del Cluster](#2-control-plane---el-cerebro-del-cluster)
4. [Worker Nodes - Donde Corren las Aplicaciones](#3-worker-nodes---donde-corren-las-aplicaciones)
5. [Comunicación entre Componentes](#4-comunicación-entre-componentes)
6. [Alta Disponibilidad y Clustering](#5-alta-disponibilidad-y-clustering)
7. [Addons del Cluster](#6-addons-del-cluster)
8. [Conclusiones y Próximos Pasos](#conclusiones-y-próximos-pasos)

---

## Introducción al Módulo

En el Módulo 01 conociste qué es Kubernetes y por qué es fundamental en la infraestructura moderna. Ahora es momento de profundizar en **cómo funciona internamente** un cluster de Kubernetes.

### Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:
- ✅ Identificar y explicar la función de cada componente del Control Plane
- ✅ Comprender el rol de los componentes en Worker Nodes
- ✅ Describir cómo se comunican los diferentes componentes
- ✅ Diagnosticar problemas básicos de arquitectura
- ✅ Entender los flujos de creación y gestión de recursos
- ✅ Configurar componentes para alta disponibilidad

### Prerequisitos

Para este módulo necesitas:
- Haber completado el Módulo 01 (Introducción a Kubernetes)
- **VM de Azure con Minikube instalado** (usando driver Docker)
- `kubectl` instalado y configurado
- Conocimientos básicos de redes y sistemas distribuidos

### Entorno de Trabajo

**IMPORTANTE**: En este curso trabajaremos exclusivamente con:
- ✅ **Minikube** como plataforma de Kubernetes
- ✅ **Driver Docker** para los contenedores
- ✅ **VM Ubuntu en Azure** como infraestructura base
- ❌ **NO** haremos instalación manual de clusters multi-nodo
- ❌ **NO** usaremos kubeadm o configuraciones bare-metal

**Justificación**: Minikube proporciona un entorno completo de Kubernetes ideal para aprendizaje, permitiéndonos explorar todos los componentes de la arquitectura sin la complejidad operativa de un cluster multi-nodo de producción.

### Duración Estimada

- **Lectura teórica**: 45-60 minutos
- **Ejemplos prácticos**: 30-45 minutos
- **Laboratorios**: 90-120 minutos

### Por Qué es Importante Este Módulo

Entender la arquitectura de Kubernetes es fundamental porque:

1. **Troubleshooting efectivo**: Cuando algo falla, sabrás exactamente dónde buscar
2. **Optimización de recursos**: Comprenderás cómo Kubernetes toma decisiones de scheduling
3. **Seguridad**: Conocerás los puntos críticos que necesitan protección
4. **Alta disponibilidad**: Sabrás cómo diseñar clusters resilientes
5. **Fundamento sólido**: Es la base para todos los módulos siguientes

---

## 1. Visión General de la Arquitectura

### El Modelo Cliente-Servidor Distribuido

Kubernetes sigue una arquitectura cliente-servidor distribuida donde múltiples componentes trabajan coordinadamente para gestionar el estado del cluster. A diferencia de sistemas monolíticos, Kubernetes separa claramente las responsabilidades entre diferentes procesos especializados.

**Principio fundamental**: Kubernetes opera bajo el paradigma de **"Estado Deseado"** (Desired State). Tú declaras cómo quieres que se vea tu aplicación, y Kubernetes trabaja continuamente para hacer que la realidad coincida con tu declaración.

### Los Dos Planos Principales

Un cluster de Kubernetes se divide en dos planos fundamentales:

**1. Control Plane (Plano de Control)** - El Cerebro
- Toma decisiones globales sobre el cluster
- Detecta y responde a eventos del cluster
- Generalmente corre en nodos dedicados (masters)
- Es el "qué" y "cuándo" del cluster

**2. Data Plane / Worker Nodes (Plano de Datos)** - Los Ejecutores  
- Ejecuta las cargas de trabajo (aplicaciones)
- Mantiene los pods en ejecución
- Reporta estado al Control Plane
- Es el "dónde" y "cómo" del cluster

### Ejemplo práctico:

Arquitectura simplificada de un cluster de 3 nodos:

```
┌─────────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                            │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │              CONTROL PLANE (Master Node)               │     │
│  │                                                         │     │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │     │
│  │  │   API    │  │ Scheduler│  │  etcd    │            │     │
│  │  │  Server  │  │          │  │          │            │     │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘            │     │
│  │       │             │             │                    │     │
│  │       └─────────────┴─────────────┘                    │     │
│  │                     │                                   │     │
│  │         ┌───────────┴──────────┐                       │     │
│  │         │   Controller Manager │                       │     │
│  │         └──────────────────────┘                       │     │
│  └─────────────────────┬──────────────────────────────────┘     │
│                        │                                         │
│           ┌────────────┼────────────┐                           │
│           │            │            │                            │
│  ┌────────▼──────┐  ┌─▼─────────┐  ┌▼──────────┐               │
│  │ WORKER NODE 1 │  │WORKER N 2 │  │WORKER N 3 │               │
│  │               │  │           │  │           │               │
│  │ ┌───────────┐ │  │┌─────────┐│  │┌─────────┐│               │
│  │ │  kubelet  │ │  ││kubelet  ││  ││kubelet  ││               │
│  │ └───────────┘ │  │└─────────┘│  │└─────────┘│               │
│  │ ┌───────────┐ │  │┌─────────┐│  │┌─────────┐│               │
│  │ │kube-proxy │ │  ││kube-prxy││  ││kube-prxy││               │
│  │ └───────────┘ │  │└─────────┘│  │└─────────┘│               │
│  │ ┌───────────┐ │  │┌─────────┐│  │┌─────────┐│               │
│  │ │Container  │ │  ││Container││  ││Container││               │
│  │ │ Runtime   │ │  ││Runtime  ││  ││Runtime  ││               │
│  │ └───────────┘ │  │└─────────┘│  │└─────────┘│               │
│  │               │  │           │  │           │               │
│  │ [Pod] [Pod]   │  │[Pod][Pod] │  │[Pod][Pod] │               │
│  └───────────────┘  └───────────┘  └───────────┘               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Flujo de Trabajo Fundamental

Cuando ejecutas un comando como `kubectl create deployment nginx --replicas=3`:

```
1. kubectl → 2. API Server → 3. etcd (guardar) →
4. Scheduler (asignar nodos) → 5. Controller Manager (crear ReplicaSet) →
6. kubelet (ejecutar pods) → 7. Container Runtime (iniciar contenedores)
```

Cada número representa un componente que veremos en detalle. Este flujo es la esencia de cómo Kubernetes orquesta tus aplicaciones.

**📁 Ver diagrama completo:** [`ejemplos/01-arquitectura-general/diagrama-cluster.md`](./ejemplos/01-arquitectura-general/diagrama-cluster.md)

**🔬 Laboratorio**: Explora la arquitectura de tu cluster en [`laboratorios/lab-01-exploracion-arquitectura.md`](./laboratorios/lab-01-exploracion-arquitectura.md)

---

## 2. Control Plane - El Cerebro del Cluster

El Control Plane es el conjunto de componentes que mantienen el estado del cluster. Toma decisiones globales (por ejemplo, dónde ejecutar un pod) y detecta y responde a eventos del cluster (por ejemplo, iniciar un nuevo pod cuando un deployment necesita más réplicas).

### Características del Control Plane

**Stateless por diseño**: Los componentes del Control Plane son stateless. Todo el estado se almacena en etcd, lo que permite escalar y reemplazar componentes fácilmente.

**API-Driven**: Todos los componentes se comunican exclusivamente a través del API Server. No hay comunicación peer-to-peer entre componentes.

**Idempotente**: Puedes ejecutar la misma operación múltiples veces sin cambiar el resultado más allá de la aplicación inicial.

### Componentes del Control Plane

#### 2.1 API Server (kube-apiserver)

**Definición**: El API Server es el frontend del Control Plane de Kubernetes. Expone la API de Kubernetes y es el único componente que se comunica directamente con etcd.

**Rol principal**: Actúa como puerta de entrada para todas las operaciones administrativas en el cluster. Es el intermediario entre todos los componentes.

**Responsabilidades clave**:
- **Autenticación**: Verifica quién eres (usuario, service account, certificado)
- **Autorización**: Verifica qué puedes hacer (RBAC, ABAC, Webhook)
- **Validación**: Verifica que tus requests sean válidos
- **Admission Control**: Aplica políticas y modifica objetos antes de persistirlos
- **RESTful API**: Provee endpoints HTTP para todos los recursos de Kubernetes

### Ejemplo práctico:

Cuando ejecutas un comando kubectl, así interactúa con el API Server:

```bash
# Este comando simple...
kubectl get pods

# ...en realidad hace esto:
# 1. kubectl construye una request HTTP GET
GET /api/v1/namespaces/default/pods HTTP/1.1
Host: kubernetes-api-server:6443
Authorization: Bearer <token>

# 2. API Server procesa:
#    a) Autentica el token
#    b) Verifica permisos RBAC
#    c) Consulta etcd para obtener los pods
#    d) Devuelve la respuesta JSON

# 3. kubectl formatea y muestra los resultados
```

Veamos un ejemplo más complejo creando un pod:

```yaml
# Archivo: pod-nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-example
  labels:
    app: web
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```

```bash
# Al aplicar este archivo:
kubectl apply -f pod-nginx.yaml

# El API Server procesa así:
# ┌─────────────────────────────────────────────────┐
# │ 1. AUTENTICACIÓN                                │
# │    ✓ Validar certificado cliente                │
# │    ✓ Verificar identidad                        │
# └─────────────────────────────────────────────────┘
# ┌─────────────────────────────────────────────────┐
# │ 2. AUTORIZACIÓN (RBAC)                          │
# │    ✓ ¿Puede este usuario crear pods?            │
# │    ✓ ¿En este namespace?                        │
# └─────────────────────────────────────────────────┘
# ┌─────────────────────────────────────────────────┐
# │ 3. VALIDACIÓN                                   │
# │    ✓ Schema correcto                            │
# │    ✓ Campos requeridos presentes                │
# │    ✓ Valores válidos                            │
# └─────────────────────────────────────────────────┘
# ┌─────────────────────────────────────────────────┐
# │ 4. ADMISSION CONTROLLERS                        │
# │    • Mutating: Inyectar valores por defecto     │
# │    • Validating: Aplicar políticas              │
# └─────────────────────────────────────────────────┘
# ┌─────────────────────────────────────────────────┐
# │ 5. PERSISTENCIA                                 │
# │    ✓ Guardar en etcd                            │
# │    ✓ Generar eventos                            │
# │    ✓ Notificar watchers                         │
# └─────────────────────────────────────────────────┘
```

**Puertos importantes**:
- **6443**: Puerto HTTPS seguro (por defecto)
- **8080**: Puerto HTTP inseguro (deshabilitado en versiones recientes por seguridad)

**📁 Ver configuración completa:** [`ejemplos/02-control-plane/01-api-server-config.yaml`](./ejemplos/02-control-plane/01-api-server-config.yaml)

#### 2.2 etcd - El Almacén de Estado

**Definición**: etcd es una base de datos distribuida de tipo clave-valor que almacena todo el estado del cluster de Kubernetes.

**Característica principal**: Utiliza el algoritmo de consenso **RAFT** para garantizar consistencia entre múltiples nodos, asegurando que todos tengan la misma visión del estado del cluster.

**¿Por qué etcd?**:
- **Consistencia fuerte**: Garantías ACID para operaciones críticas
- **Distribuido**: Tolera fallos de nodos individuales
- **Watch API**: Notificaciones en tiempo real de cambios
- **Snapshots**: Backups point-in-time automáticos

### Ejemplo práctico:

Estructura de datos en etcd:

```bash
# etcd organiza los datos jerárquicamente
# Todo bajo el prefijo /registry/

/registry/pods/default/nginx-example
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": "nginx-example",
    "namespace": "default",
    "uid": "abc-123-def-456",
    "resourceVersion": "12345"
  },
  "spec": { ... },
  "status": {
    "phase": "Running",
    "podIP": "10.244.1.5"
  }
}

/registry/services/default/my-service
{
  "apiVersion": "v1",
  "kind": "Service",
  ...
}

/registry/configmaps/kube-system/cluster-info
{
  "apiVersion": "v1",
  "kind": "ConfigMap",
  ...
}
```

**Datos almacenados en etcd**:
- Todos los objetos de Kubernetes (Pods, Services, Deployments, etc.)
- Configuración del cluster
- Secretos (encriptados en reposo desde Kubernetes 1.13+)
- Estado de nodos
- Network policies
- RBAC roles y bindings

### Ejemplo práctico de RAFT consensus:

```
Cluster etcd de 3 nodos:

┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   etcd-1    │      │   etcd-2    │      │   etcd-3    │
│   LEADER    │◄────►│  FOLLOWER   │◄────►│  FOLLOWER   │
└─────────────┘      └─────────────┘      └─────────────┘
      │                     │                     │
      │                     │                     │
      ▼                     ▼                     ▼
  Write Op             Read Op              Read Op
  (Must go            (Can read            (Can read
   to Leader)          from any)            from any)

FLUJO DE ESCRITURA:
1. Client → Leader (write request)
2. Leader → Followers (replicate log entry)
3. Followers → Leader (acknowledge)
4. Leader waits for majority (2 out of 3)
5. Leader commits and responds to client
6. Leader → Followers (commit notification)

Si el Leader falla:
- Followers inician election (timeout detection)
- Follower con más logs recientes se vuelve candidato
- Necesita mayoría de votos (2 de 3)
- Nuevo Leader elegido en ~1 segundo
```

**Comandos útiles para interactuar con etcd**:

```bash
# Ver miembros del cluster etcd (en un pod de etcd)
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# Ver todos los pods en etcd
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/pods --prefix --keys-only

# Crear snapshot (backup)
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /backup/etcd-snapshot-$(date +%Y%m%d-%H%M%S).db
```

**Consideraciones de seguridad**:
- etcd contiene **todos** los secretos del cluster
- Debe estar encriptado en reposo
- Acceso solo por API Server (nunca directamente desde pods)
- Backups regulares son **críticos**

**📁 Ver configuración de etcd cluster:** [`ejemplos/02-control-plane/02-etcd-cluster-config.yaml`](./ejemplos/02-control-plane/02-etcd-cluster-config.yaml)

#### 2.3 Scheduler (kube-scheduler)

**Definición**: El Scheduler es responsable de asignar pods a nodos (workers). Vigila los pods recién creados que no tienen un nodo asignado y selecciona el mejor nodo para ejecutarlos.

**Proceso de decisión en 2 fases**:
1. **Filtering (Filtrado)**: Encuentra nodos que cumplan los requisitos
2. **Scoring (Puntuación)**: Clasifica los nodos viables y elige el mejor

### Ejemplo práctico:

Proceso completo de scheduling:

```yaml
# Pod que necesita ser agendado
apiVersion: v1
kind: Pod
metadata:
  name: webapp
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "500m"      # Necesita 0.5 CPU cores
        memory: "1Gi"    # Necesita 1GB RAM
  nodeSelector:
    disktype: "ssd"      # Solo nodos con SSD
```

```
FASE 1: FILTERING
─────────────────────────────────────────────────────────
Scheduler aplica predicados:

Node1: 
  CPU disponible: 0.3 cores ❌ DESCARTADO (insuficiente)
  Memoria: 2Gi ✓
  disktype: ssd ✓

Node2:
  CPU disponible: 1.5 cores ✓
  Memoria: 512Mi ❌ DESCARTADO (insuficiente)
  disktype: ssd ✓

Node3:
  CPU disponible: 2 cores ✓
  Memoria: 4Gi ✓
  disktype: hdd ❌ DESCARTADO (no tiene SSD)

Node4:
  CPU disponible: 1 core ✓
  Memoria: 2Gi ✓
  disktype: ssd ✓ VIABLE

Node5:
  CPU disponible: 3 cores ✓
  Memoria: 8Gi ✓
  disktype: ssd ✓ VIABLE

NODOS VIABLES: Node4, Node5
─────────────────────────────────────────────────────────

FASE 2: SCORING
─────────────────────────────────────────────────────────
Scheduler calcula puntuaciones:

Node4:
  • LeastRequestedPriority: 65/100
    (recursos utilizados moderadamente)
  • BalancedResourceAllocation: 70/100
    (CPU y memoria equilibradas)
  • NodeAffinityPriority: 100/100
    (cumple preferencias)
  • InterPodAffinityPriority: 50/100
    (no hay otros pods relacionados)
  TOTAL: 71/100

Node5:
  • LeastRequestedPriority: 90/100
    (muchos recursos libres)
  • BalancedResourceAllocation: 85/100
    (muy equilibrado)
  • NodeAffinityPriority: 100/100
    (cumple preferencias)
  • InterPodAffinityPriority: 80/100
    (tiene pods relacionados, mejor localidad)
  TOTAL: 89/100

DECISIÓN: Node5 (mayor puntuación)
─────────────────────────────────────────────────────────

RESULTADO:
kubectl get pod webapp -o wide
NAME     READY   STATUS    NODE
webapp   1/1     Running   node5
```

**Predicados comunes (Filtering)**:
- `PodFitsResources`: Nodo tiene CPU/RAM suficiente
- `PodFitsHost`: Pod solicita un host específico
- `PodFitsHostPorts`: Puertos solicitados están libres
- `PodMatchNodeSelector`: Cumple nodeSelector
- `CheckNodeDiskPressure`: Nodo no tiene presión de disco
- `CheckNodeMemoryPressure`: Nodo no tiene presión de memoria
- `CheckNodePIDPressure`: Nodo no tiene presión de PIDs
- `PodToleratesNodeTaints`: Pod tolera los taints del nodo

**Prioridades comunes (Scoring)**:
- `LeastRequestedPriority`: Prefiere nodos con menos recursos utilizados
- `BalancedResourceAllocation`: Prefiere balance entre CPU y memoria
- `NodeAffinityPriority`: Cumplimiento de affinity preferences
- `InterPodAffinityPriority`: Co-localización de pods relacionados
- `SelectorSpreadPriority`: Distribuye pods del mismo service
- `ImageLocalityPriority`: Prefiere nodos con la imagen ya descargada

**📁 Ver ejemplos de scheduling avanzado:** [`ejemplos/02-control-plane/03-scheduler-ejemplos.yaml`](./ejemplos/02-control-plane/03-scheduler-ejemplos.yaml)

#### 2.4 Controller Manager (kube-controller-manager)

**Definición**: El Controller Manager ejecuta múltiples controladores que regulan el estado del cluster. Cada controlador es un loop de control independiente que vigila el estado deseado vs el estado actual.

**Patrón fundamental - Control Loop**:
```
while true:
  desired_state = get_desired_state()
  current_state = get_current_state()
  
  if current_state != desired_state:
    make_changes_to_match(desired_state)
  
  sleep(reconcile_interval)
```

### Ejemplo práctico:

Veamos cómo funciona el **Deployment Controller**:

```yaml
# Deployment deseado
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 3  # ESTADO DESEADO: 3 réplicas
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx
```

```
CONTROL LOOP DEL DEPLOYMENT CONTROLLER:
──────────────────────────────────────────────────────────

ITERACIÓN 1 (t=0s):
  Desired: 3 réplicas
  Current: 0 réplicas (deployment recién creado)
  Action: Crear ReplicaSet para gestionar 3 pods
  
ITERACIÓN 2 (t=10s):
  Desired: 3 réplicas
  Current: 3 réplicas running ✓
  Action: Ninguna (estado coincide)

EVENTO EXTERNO (t=30s): Un pod se crashea
  
ITERACIÓN 3 (t=40s):
  Desired: 3 réplicas
  Current: 2 réplicas (un pod murió)
  Action: ReplicaSet Controller crea nuevo pod
  
ITERACIÓN 4 (t=50s):
  Desired: 3 réplicas
  Current: 3 réplicas ✓
  Action: Ninguna

CAMBIO DE USUARIO (t=60s):
  kubectl scale deployment webapp --replicas=5
  
ITERACIÓN 5 (t=70s):
  Desired: 5 réplicas (actualizado por usuario)
  Current: 3 réplicas
  Action: Escalar ReplicaSet a 5, crear 2 pods nuevos
  
ITERACIÓN 6 (t=80s):
  Desired: 5 réplicas
  Current: 5 réplicas ✓
  Action: Ninguna
```

**Controladores principales incluidos**:

1. **Node Controller**: Monitorea salud de nodos
2. **Replication Controller**: Mantiene número correcto de pods
3. **Endpoints Controller**: Conecta Services con Pods
4. **Service Account Controller**: Crea ServiceAccounts por defecto
5. **Namespace Controller**: Limpia recursos cuando se elimina un namespace
6. **PersistentVolume Controller**: Gestiona ciclo de vida de volumes
7. **Job Controller**: Ejecuta pods hasta completarse
8. **CronJob Controller**: Ejecuta jobs en horarios programados
9. **Deployment Controller**: Gestiona despliegues y actualizaciones
10. **StatefulSet Controller**: Gestiona aplicaciones con estado
11. **DaemonSet Controller**: Asegura que un pod corra en cada nodo

**Cada controlador vigila recursos específicos mediante el Watch API del API Server**.

**📁 Ver controladores en detalle:** [`ejemplos/02-control-plane/04-controllers-explicados.yaml`](./ejemplos/02-control-plane/04-controllers-explicados.yaml)

**🔬 Laboratorio**: Observa los controladores en acción en [`laboratorios/lab-02-control-plane-practico.md`](./laboratorios/lab-02-control-plane-practico.md)

---

## 3. Worker Nodes - Donde Corren las Aplicaciones

Los Worker Nodes son las máquinas donde realmente se ejecutan tus aplicaciones contenerizadas. A diferencia del Control Plane que toma decisiones, los Worker Nodes son los ejecutores que mantienen los pods corriendo y reportan su estado.

### Características de los Worker Nodes

**Stateless por diseño**: Los workers no almacenan estado crítico del cluster. Si un worker falla, sus pods se recrean en otros nodos.

**Escalables horizontalmente**: Puedes agregar o quitar workers sin afectar el Control Plane. Es común tener docenas o cientos de workers en producción.

**Especializados**: Puedes tener diferentes tipos de workers (CPU-optimized, GPU, memoria alta) y usar node selectors para dirigir workloads específicos.

### Componentes de un Worker Node

#### 3.1 kubelet - El Agente del Nodo

**Definición**: kubelet es el agente primario que corre en cada Worker Node. Es responsable de asegurar que los contenedores estén corriendo en un pod según lo especificado.

**Rol principal**: Actúa como el "capataz" del nodo, tomando instrucciones del API Server y asegurándose de que se ejecuten correctamente.

**Responsabilidades clave**:
- **Registrar el nodo** en el cluster al iniciar
- **Monitorear pods** asignados a su nodo
- **Iniciar contenedores** via Container Runtime Interface (CRI)
- **Ejecutar health checks** (liveness, readiness, startup probes)
- **Reportar estado** del nodo y pods al API Server
- **Gestionar volúmenes** montándolos en los pods

### Ejemplo práctico:

El ciclo de vida de kubelet con un pod:

```yaml
# Pod asignado a este nodo por el Scheduler
apiVersion: v1
kind: Pod
metadata:
  name: webapp
  uid: abc-123-def-456
spec:
  nodeName: worker-node-1  # Scheduler ya asignó este nodo
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 5
```

```
FLUJO DE KUBELET:
───────────────────────────────────────────────────────────

1. WATCH API SERVER (cada 10s)
   kubelet: "¿Hay pods nuevos para worker-node-1?"
   API Server: "Sí, pod 'webapp' (uid: abc-123-def-456)"

2. OBTENER ESPECIFICACIÓN
   kubelet descarga spec completa del pod
   - Imagen: nginx
   - Puerto: 80
   - Probes: liveness HTTP GET /

3. PREPARAR ENTORNO
   kubelet crea:
   - Directorio del pod: /var/lib/kubelet/pods/abc-123-def-456/
   - Directorio de volúmenes
   - Configuración de red

4. CREAR POD SANDBOX
   kubelet → Container Runtime:
   "Crea sandbox para pod abc-123-def-456"
   
   Container Runtime:
   - Crea namespace de red
   - Asigna IP del pod: 10.244.1.5
   - Configura DNS

5. PULL IMAGEN
   kubelet → Container Runtime:
   "Pull imagen nginx"
   
   Container Runtime:
   - Descarga nginx desde Docker Hub
   - Verifica checksum
   - Descomprime layers

6. CREAR Y INICIAR CONTENEDOR
   kubelet → Container Runtime:
   "Crea contenedor 'nginx' en pod abc-123-def-456"
   
   Container Runtime:
   - Crea contenedor
   - Monta volúmenes
   - Configura env vars
   - Inicia proceso nginx

7. MONITOREAR HEALTH (cada 5s)
   kubelet ejecuta liveness probe:
   HTTP GET http://10.244.1.5:80/
   
   Respuesta: 200 OK ✓
   Estado: Healthy

8. REPORTAR ESTADO AL API SERVER (cada 10s)
   kubelet → API Server:
   "Pod 'webapp' en worker-node-1:"
   - Phase: Running
   - IP: 10.244.1.5
   - Container nginx: Running, Healthy
   - Started at: 2024-11-11T10:30:00Z

9. LOOP CONTINUO
   kubelet repite pasos 7-8 mientras el pod exista
```

**Si el contenedor falla**:

```
HEALTH CHECK FALLA:
───────────────────────────────────────────────────────────

Iteración 10: Liveness probe HTTP GET → 503 Service Unavailable
Iteración 11: Liveness probe HTTP GET → Timeout
Iteración 12: Liveness probe HTTP GET → Connection Refused

kubelet detecta: 3 fallos consecutivos

ACCIÓN DE KUBELET:
1. Matar contenedor actual
2. Container Runtime → stop nginx container
3. Incrementar restart count
4. Aplicar backoff (10s, 20s, 40s, ...)
5. Container Runtime → start new nginx container
6. Reportar evento al API Server: "Container restarted"

Usuario ve:
$ kubectl get pod webapp
NAME     READY   STATUS    RESTARTS   AGE
webapp   1/1     Running   1          5m
                          ↑ Restart count incrementado
```

**Configuración de kubelet**:

```bash
# Archivo de configuración: /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
address: 0.0.0.0
port: 10250
authentication:
  webhook:
    enabled: true
  anonymous:
    enabled: false
authorization:
  mode: Webhook
cgroupDriver: systemd
clusterDomain: cluster.local
clusterDNS:
- 10.96.0.10
containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
maxPods: 110
podCIDR: 10.244.1.0/24
```

**📁 Ver configuración completa de kubelet:** [`ejemplos/03-worker-nodes/01-kubelet-config.yaml`](./ejemplos/03-worker-nodes/01-kubelet-config.yaml)

#### 3.2 kube-proxy - El Proxy de Red

**Definición**: kube-proxy es un proxy de red que corre en cada nodo. Mantiene las reglas de red que permiten la comunicación de red hacia los pods desde dentro o fuera del cluster.

**Rol principal**: Implementa el concepto de **Service** de Kubernetes, proporcionando una IP virtual estable que balancea tráfico entre múltiples pods.

**Modos de operación**:
1. **iptables** (por defecto): Usa reglas de firewall de Linux
2. **IPVS** (IP Virtual Server): Más eficiente para muchos servicios
3. **userspace** (legacy): Modo antiguo, no recomendado

### Ejemplo práctico:

Cómo kube-proxy implementa un Service:

```yaml
# Deployment con 3 réplicas
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80

---
# Service que expone el deployment
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  selector:
    app: webapp  # Selecciona pods con esta label
  ports:
  - protocol: TCP
    port: 80        # Puerto del Service
    targetPort: 80  # Puerto del contenedor
  type: ClusterIP
```

```
ESTADO DEL CLUSTER:
───────────────────────────────────────────────────────────

Service webapp-service:
  ClusterIP: 10.96.0.50
  Port: 80

Pods (endpoints):
  webapp-abc123 → 10.244.1.5:80 (worker-node-1)
  webapp-def456 → 10.244.2.8:80 (worker-node-2)
  webapp-ghi789 → 10.244.3.3:80 (worker-node-3)

───────────────────────────────────────────────────────────

KUBE-PROXY EN WORKER-NODE-1:
───────────────────────────────────────────────────────────

1. WATCH API SERVER
   kube-proxy detecta:
   - Nuevo Service: webapp-service (10.96.0.50:80)
   - Endpoints: 3 pods con IPs reales

2. CREAR REGLAS IPTABLES
   kube-proxy configura cadenas de iptables:

   # Regla principal: Capturar tráfico al Service
   -A KUBE-SERVICES -d 10.96.0.50/32 -p tcp -m tcp --dport 80 \
     -j KUBE-SVC-WEBAPP

   # Balanceo de carga (round-robin)
   # 33.3% de tráfico al primer pod
   -A KUBE-SVC-WEBAPP -m statistic --mode random --probability 0.33333 \
     -j KUBE-SEP-POD1

   # 50% del tráfico restante al segundo pod
   -A KUBE-SVC-WEBAPP -m statistic --mode random --probability 0.5 \
     -j KUBE-SEP-POD2

   # El resto al tercer pod
   -A KUBE-SVC-WEBAPP -j KUBE-SEP-POD3

   # DNAT a cada pod específico
   -A KUBE-SEP-POD1 -p tcp -j DNAT --to-destination 10.244.1.5:80
   -A KUBE-SEP-POD2 -p tcp -j DNAT --to-destination 10.244.2.8:80
   -A KUBE-SEP-POD3 -p tcp -j DNAT --to-destination 10.244.3.3:80

3. RESULTADO PRÁCTICO
   Cuando un pod hace:
   curl http://webapp-service:80

   Kernel Linux intercepta el paquete:
   - Destino original: 10.96.0.50:80
   - iptables aplica DNAT
   - Destino final: 10.244.1.5:80 (o uno de los otros pods)
   - Tráfico se enruta al pod seleccionado
```

**Ventajas de cada modo**:

```
MODO IPTABLES (por defecto):
✓ Bajo overhead
✓ Kernel-space (muy rápido)
✓ Ampliamente probado
✗ Performance degrada con 1000+ services
✗ No soporta load balancing algorithms avanzados

MODO IPVS:
✓ Mejor performance con muchos services
✓ Múltiples algoritmos de balanceo (round-robin, least-connection, etc.)
✓ Más eficiente para clusters grandes
✗ Requiere kernel modules adicionales
✗ Más complejo de troubleshoot

CONFIGURACIÓN IPVS:
# kube-proxy config
mode: ipvs
ipvs:
  scheduler: "rr"  # round-robin, lc (least-connection), etc.
```

**Ver reglas de iptables en un nodo**:

```bash
# Ver todas las cadenas de Kubernetes
sudo iptables -t nat -L -n | grep KUBE

# Ver reglas específicas de un service
sudo iptables -t nat -L KUBE-SERVICES -n | grep webapp-service

# Ver balanceo de carga
sudo iptables -t nat -L KUBE-SVC-WEBAPP -n -v
```

**📁 Ver configuración completa de kube-proxy:** [`ejemplos/03-worker-nodes/02-kube-proxy-config.yaml`](./ejemplos/03-worker-nodes/02-kube-proxy-config.yaml)

#### 3.3 Container Runtime - El Motor de Contenedores

**Definición**: El Container Runtime es el software responsable de ejecutar contenedores. Kubernetes delega la ejecución real de contenedores a este componente.

**Rol principal**: Gestionar el ciclo de vida completo de contenedores: pull de imágenes, creación, inicio, parada y eliminación.

**Container Runtime Interface (CRI)**:
Kubernetes usa CRI como abstracción, permitiendo múltiples runtimes:

**Runtimes compatibles**:
1. **containerd** (recomendado): Ligero, mantenido por CNCF
2. **CRI-O**: Diseñado específicamente para Kubernetes
3. **Docker** (via cri-dockerd): Requiere shim adicional desde Kubernetes 1.24+

### Ejemplo práctico:

Flujo completo de creación de contenedor:

```yaml
# Pod simple
apiVersion: v1
kind: Pod
metadata:
  name: redis
spec:
  containers:
  - name: redis
    image: redis:alpine
    ports:
    - containerPort: 6379
    resources:
      requests:
        memory: "256Mi"
        cpu: "500m"
      limits:
        memory: "512Mi"
        cpu: "1000m"
```

```
INTERACCIÓN KUBELET ↔ CONTAINER RUNTIME:
───────────────────────────────────────────────────────────

1. KUBELET → CONTAINER RUNTIME (via CRI)
   Request: "Crea pod sandbox para redis"
   
   Container Runtime (containerd):
   a) Crea pause container (infrastructure container)
      - Este contenedor mantiene el namespace de red del pod
      - IP asignada: 10.244.1.10
      - Network namespace: /var/run/netns/cni-abc123
   
   b) Configura networking (via CNI plugin)
      - Asigna IP del pod
      - Configura rutas
      - Configura DNS

2. KUBELET → CONTAINER RUNTIME
   Request: "Pull imagen redis:alpine"
   
   Container Runtime:
   a) Contacta Docker Hub (registry.hub.docker.com)
   b) Descarga layers:
      - Layer 1: base alpine (5MB)
      - Layer 2: redis binaries (8MB)
      - Layer 3: config files (1KB)
   c) Verifica checksums SHA256
   d) Descomprime y almacena en:
      /var/lib/containerd/io.containerd.content.v1.content/
   
   Response: "Imagen lista"

3. KUBELET → CONTAINER RUNTIME
   Request: "Crea contenedor 'redis' en pod sandbox"
   Params:
   - Imagen: redis:alpine
   - Comando: redis-server
   - Memory limit: 512Mi
   - CPU limit: 1 core
   - Network: compartir con pause container
   
   Container Runtime:
   a) Crea container spec (OCI runtime spec)
   b) Configura cgroups:
      - memory.limit_in_bytes = 512Mi
      - cpu.cfs_quota_us = 100000 (1 core)
   c) Configura namespaces:
      - Network: compartido con pause container
      - PID: aislado
      - Mount: aislado
      - IPC: compartido
   d) Prepara filesystem (overlay2):
      - Lower layers: imagen redis (read-only)
      - Upper layer: cambios del contenedor (read-write)
      - Merged: vista combinada
   
   Response: "Contenedor creado, ID: abc123def456"

4. KUBELET → CONTAINER RUNTIME
   Request: "Inicia contenedor abc123def456"
   
   Container Runtime:
   a) Ejecuta runc (OCI runtime)
   b) Inicia proceso redis-server
   c) PID del proceso: 12345
   d) Estado: Running
   
   Response: "Contenedor iniciado exitosamente"

5. MONITORING CONTINUO
   kubelet → Container Runtime (cada 10s):
   "Estado del contenedor abc123def456?"
   
   Container Runtime:
   - Estado: Running
   - Uso de memoria: 128Mi / 512Mi
   - Uso de CPU: 0.3 cores / 1 core
   - Uptime: 5m 30s
```

**Arquitectura de capas**:

```
┌────────────────────────────────────────────┐
│           kubelet                          │
│  (Kubernetes node agent)                   │
└────────────────┬───────────────────────────┘
                 │ CRI gRPC API
┌────────────────▼───────────────────────────┐
│        Container Runtime                   │
│        (containerd / CRI-O)                │
│  - Image management                        │
│  - Container lifecycle                     │
│  - Pod sandbox management                  │
└────────────────┬───────────────────────────┘
                 │ OCI Runtime API
┌────────────────▼───────────────────────────┐
│         OCI Runtime                        │
│         (runc)                             │
│  - Create container processes              │
│  - Configure namespaces/cgroups            │
│  - Execute container                       │
└────────────────────────────────────────────┘
```

**Verificar Container Runtime**:

```bash
# Ver qué runtime usa el cluster
kubectl get nodes -o wide

# Conectarse al nodo y verificar containerd
sudo crictl info

# Listar pods corriendo (vista del runtime)
sudo crictl pods

# Listar contenedores
sudo crictl ps

# Ver logs de un contenedor
sudo crictl logs <container-id>

# Inspeccionar contenedor
sudo crictl inspect <container-id>
```

**📁 Ver configuración de Container Runtime:** [`ejemplos/03-worker-nodes/03-container-runtime-config.yaml`](./ejemplos/03-worker-nodes/03-container-runtime-config.yaml)

**🔬 Laboratorio**: Explora Worker Nodes en profundidad en [`laboratorios/lab-03-worker-nodes.md`](./laboratorios/lab-03-worker-nodes.md)

---

## 4. Comunicación entre Componentes

Entender cómo se comunican los componentes es crucial para diagnosticar problemas y optimizar el cluster. Kubernetes usa múltiples patrones de comunicación.

### Patrones de Comunicación

#### 4.1 API Server como Hub Central

**Principio fundamental**: TODOS los componentes se comunican a través del API Server. No hay comunicación directa peer-to-peer entre componentes.

```
┌─────────────────────────────────────────────────────────┐
│                     API SERVER                          │
│                   (Hub Central)                         │
└───┬─────┬──────┬──────┬──────┬──────┬──────┬──────┬───┘
    │     │      │      │      │      │      │      │
    ▼     ▼      ▼      ▼      ▼      ▼      ▼      ▼
  etcd  Sched  Ctrl  kubectl kubelet proxy  CCM  Addons
```

**Ventajas de este diseño**:
- **Punto único de autenticación y autorización**
- **Auditoría centralizada** de todas las operaciones
- **Fácil de escalar** el Control Plane (múltiples API servers)
- **Desacoplamiento** entre componentes
- **Consistencia** mediante etcd como única fuente de verdad

### Ejemplo práctico:

Flujo completo de crear un deployment:

```bash
# Usuario ejecuta
kubectl create deployment nginx --image=nginx --replicas=3
```

```
COMUNICACIÓN PASO A PASO:
═══════════════════════════════════════════════════════════

PASO 1: kubectl → API Server
───────────────────────────────────────────────────────────
kubectl:
  POST /apis/apps/v1/namespaces/default/deployments
  Headers:
    Authorization: Bearer <token>
    Content-Type: application/json
  Body:
    {
      "apiVersion": "apps/v1",
      "kind": "Deployment",
      "metadata": {"name": "nginx"},
      "spec": {
        "replicas": 3,
        "selector": {"matchLabels": {"app": "nginx"}},
        "template": {...}
      }
    }

API Server:
  1. Autentica token ✓
  2. Autoriza operación (RBAC) ✓
  3. Valida JSON schema ✓
  4. Ejecuta admission controllers ✓
  5. Persiste en etcd ✓
  
  Response: 201 Created

───────────────────────────────────────────────────────────
PASO 2: API Server → etcd
───────────────────────────────────────────────────────────
API Server → etcd:
  PUT /registry/deployments/default/nginx
  Body: <deployment JSON completo>

etcd:
  - Replica a followers via RAFT
  - Espera quorum (2/3 nodos)
  - Confirma write
  
  Response: Success

───────────────────────────────────────────────────────────
PASO 3: Deployment Controller detecta vía Watch
───────────────────────────────────────────────────────────
Deployment Controller tiene open watch:
  GET /apis/apps/v1/deployments?watch=true
  (conexión HTTP long-polling persistente)

API Server envía evento:
  {
    "type": "ADDED",
    "object": {
      "kind": "Deployment",
      "metadata": {"name": "nginx"},
      ...
    }
  }

Deployment Controller:
  - Detecta nuevo deployment
  - Reconcilia estado: necesita crear ReplicaSet

───────────────────────────────────────────────────────────
PASO 4: Deployment Controller → API Server
───────────────────────────────────────────────────────────
Deployment Controller:
  POST /apis/apps/v1/namespaces/default/replicasets
  Body: {
    "kind": "ReplicaSet",
    "spec": {"replicas": 3, ...}
  }

API Server:
  - Valida y persiste en etcd
  - Notifica watchers
  
  Response: 201 Created

───────────────────────────────────────────────────────────
PASO 5: ReplicaSet Controller detecta vía Watch
───────────────────────────────────────────────────────────
ReplicaSet Controller:
  - Detecta nuevo ReplicaSet
  - Reconcilia: necesita 3 pods, tiene 0
  - Crea 3 pods

ReplicaSet Controller → API Server:
  POST /api/v1/namespaces/default/pods (x3)
  Body: <pod spec>

API Server:
  - Valida y persiste cada pod en etcd
  - Pods creados con status: Pending
  - Notifica watchers

───────────────────────────────────────────────────────────
PASO 6: Scheduler detecta Pods Pending vía Watch
───────────────────────────────────────────────────────────
Scheduler tiene watch:
  GET /api/v1/pods?watch=true&fieldSelector=spec.nodeName=""

API Server envía 3 eventos ADDED

Scheduler:
  - Ejecuta algoritmo de scheduling
  - Elige nodos: worker-1, worker-2, worker-3

Scheduler → API Server (para cada pod):
  PATCH /api/v1/namespaces/default/pods/<pod-name>
  Body: {
    "spec": {"nodeName": "worker-1"}
  }

API Server:
  - Actualiza pod.spec.nodeName en etcd
  - Notifica watchers

───────────────────────────────────────────────────────────
PASO 7: kubelet detecta Pod asignado vía Watch
───────────────────────────────────────────────────────────
kubelet en worker-1 tiene watch:
  GET /api/v1/pods?watch=true&fieldSelector=spec.nodeName=worker-1

API Server envía evento MODIFIED

kubelet:
  - Detecta pod asignado a su nodo
  - Inicia proceso de creación

kubelet → Container Runtime (CRI):
  1. CreatePodSandbox
  2. PullImage
  3. CreateContainer
  4. StartContainer

───────────────────────────────────────────────────────────
PASO 8: kubelet reporta estado → API Server
───────────────────────────────────────────────────────────
kubelet → API Server:
  PATCH /api/v1/namespaces/default/pods/<pod-name>/status
  Body: {
    "status": {
      "phase": "Running",
      "podIP": "10.244.1.5",
      "containerStatuses": [...]
    }
  }

API Server:
  - Actualiza pod.status en etcd
  - Notifica watchers

───────────────────────────────────────────────────────────
PASO 9: Endpoint Controller detecta Pod Ready vía Watch
───────────────────────────────────────────────────────────
Endpoint Controller:
  - Detecta pod Running con label app=nginx
  - Si hay Service matching, actualiza Endpoints

───────────────────────────────────────────────────────────
PASO 10: kube-proxy detecta Endpoints vía Watch
───────────────────────────────────────────────────────────
kube-proxy:
  - Detecta nuevos endpoints
  - Actualiza reglas iptables/IPVS
  - Tráfico puede fluir al pod

═══════════════════════════════════════════════════════════
RESULTADO FINAL:
  3 pods corriendo en 3 nodos diferentes
  Tiempo total: ~10-15 segundos
═══════════════════════════════════════════════════════════
```

#### 4.2 Watch API - Eficiencia en Tiempo Real

**Problema**: Si cada componente hace polling (consultar repetidamente) al API Server, generaría tráfico masivo.

**Solución**: Kubernetes usa **Watch API** - conexiones HTTP long-polling donde el API Server envía eventos solo cuando hay cambios.

```
SIN WATCH (Polling):
────────────────────────────────────────────
Controller → API Server: "¿Hay nuevos deployments?" (cada 1s)
API Server: "No"
Controller → API Server: "¿Hay nuevos deployments?"
API Server: "No"
Controller → API Server: "¿Hay nuevos deployments?"
API Server: "No"
...
(1000s de requests vacíos)

CON WATCH:
────────────────────────────────────────────
Controller → API Server: GET /deployments?watch=true
  (conexión queda abierta)

... silencio (sin tráfico) ...

(Usuario crea deployment)

API Server → Controller:
  {
    "type": "ADDED",
    "object": <deployment>
  }

Controller procesa evento

... silencio ...

(Solo tráfico cuando hay cambios reales)
```

**Implementación de Watch**:

```go
// Ejemplo conceptual en Go (usado internamente por componentes)
watcher, err := clientset.AppsV1().Deployments("default").Watch(
    context.TODO(),
    metav1.ListOptions{},
)

for event := range watcher.ResultChan() {
    switch event.Type {
    case watch.Added:
        // Nuevo deployment creado
        handleAdd(event.Object)
    case watch.Modified:
        // Deployment actualizado
        handleUpdate(event.Object)
    case watch.Deleted:
        // Deployment eliminado
        handleDelete(event.Object)
    }
}
```

#### 4.3 Networking entre Pods

**Modelo de red de Kubernetes**:

1. **Cada Pod tiene una IP única** en el cluster
2. **Pods pueden comunicarse sin NAT** directamente con sus IPs
3. **Nodes pueden comunicarse con todos los Pods** sin NAT
4. **La IP que un Pod ve para sí mismo** es la misma que otros ven

### Ejemplo práctico:

```yaml
# Pod Frontend
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  containers:
  - name: web
    image: nginx
    ports:
    - containerPort: 80

---
# Pod Backend
apiVersion: v1
kind: Pod
metadata:
  name: backend
  labels:
    app: backend
spec:
  containers:
  - name: api
    image: my-api
    ports:
    - containerPort: 8080
```

```
COMUNICACIÓN POD A POD:
───────────────────────────────────────────────────────────

Escenario: frontend necesita llamar a backend

OPCIÓN 1: Comunicación directa (NO recomendado)
───────────────────────────────────────────────
frontend (10.244.1.5) → backend (10.244.2.8:8080)

Problemas:
✗ IP del pod cambia si se recrea
✗ Sin balanceo de carga si hay múltiples backends
✗ Sin service discovery

OPCIÓN 2: Via Service (RECOMENDADO)
───────────────────────────────────────────────

1. Crear Service para backend:

apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080

Service obtiene ClusterIP: 10.96.0.100

2. Frontend usa DNS del cluster:

frontend container:
  $ curl http://backend-service:80/api

3. Flujo de resolución:

   a) DNS Query
      frontend → CoreDNS: "¿IP de backend-service?"
      CoreDNS → frontend: "10.96.0.100"
   
   b) Packet routing
      frontend envía: 10.244.1.5 → 10.96.0.100:80
      
   c) kube-proxy intercept
      iptables/IPVS reescribe destino:
      10.96.0.100:80 → 10.244.2.8:8080
      
   d) Entrega
      Packet llega a backend pod
      backend responde: 10.244.2.8 → 10.244.1.5

Ventajas:
✓ IP estable (Service ClusterIP)
✓ DNS name (backend-service)
✓ Balanceo de carga automático
✓ Service discovery built-in
```

**📁 Ver ejemplos de networking:** [`ejemplos/04-networking/comunicacion-pods.yaml`](./ejemplos/04-networking/comunicacion-pods.yaml)

**🔬 Laboratorio**: Practica troubleshooting de comunicación en [`laboratorios/lab-04-troubleshooting-networking.md`](./laboratorios/lab-04-troubleshooting-networking.md)

---

## 5. Alta Disponibilidad y Conceptos de Clustering

### 📝 Nota sobre el Entorno del Curso

**IMPORTANTE**: En este módulo exploraremos los conceptos de Alta Disponibilidad (HA) desde una perspectiva **teórica y arquitectónica**. 

- ✅ **Comprenderemos** cómo funcionan los clusters HA en producción
- ✅ **Analizaremos** la arquitectura de múltiples masters y etcd clustering
- ✅ **Exploraremos** los componentes del Control Plane en nuestro Minikube
- ❌ **NO implementaremos** un cluster multi-nodo real (usamos Minikube)
- ❌ **NO configuraremos** Load Balancers o etcd externo manualmente

**Justificación**: Minikube simula un cluster completo en un solo nodo, pero nos permite inspeccionar y entender todos los componentes que en producción estarían distribuidos. Los conceptos de HA son fundamentales para entender la arquitectura, aunque su implementación práctica queda fuera del alcance de este curso introductorio.

---

### 5.1 Conceptos de Alta Disponibilidad

La Alta Disponibilidad en Kubernetes garantiza que el cluster continúe operando incluso cuando algunos componentes fallen. Estos conceptos son críticos para entornos de producción donde el downtime no es aceptable.

**Conceptos clave que entenderemos**:
- **Control Plane HA**: Múltiples réplicas de API Server, Scheduler, Controller Manager
- **etcd HA**: Cluster de etcd con quorum (3, 5, o 7 nodos)
- **Worker Node redundancy**: Múltiples workers para distribuir carga
- **Load balancing**: Distribución de tráfico entre componentes replicados

### 5.2 Arquitectura HA en Producción (Conceptual)

Aunque en Minikube todo corre en un solo nodo, es importante entender cómo se ve un cluster de producción con alta disponibilidad.

**Arquitectura HA típica** (referencia conceptual):

```
                    ┌────────────────────────────────────┐
                    │      LOAD BALANCER                 │
                    │   (HAProxy / nginx / cloud LB)     │
                    │   VIP: 192.168.1.100:6443          │
                    └──────────┬─────────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│  MASTER 1     │      │  MASTER 2     │      │  MASTER 3     │
├───────────────┤      ├───────────────┤      ├───────────────┤
│ API Server    │      │ API Server    │      │ API Server    │
│   :6443       │      │   :6443       │      │   :6443       │
├───────────────┤      ├───────────────┤      ├───────────────┤
│ Scheduler     │      │ Scheduler     │      │ Scheduler     │
│ (standby)     │      │ (ACTIVE)      │      │ (standby)     │
├───────────────┤      ├───────────────┤      ├───────────────┤
│ Ctrl Manager  │      │ Ctrl Manager  │      │ Ctrl Manager  │
│ (standby)     │      │ (ACTIVE)      │      │ (standby)     │
└───────┬───────┘      └───────┬───────┘      └───────┬───────┘
        │                      │                      │
        └──────────────────────┼──────────────────────┘
                               │
                    ┌──────────▼─────────────┐
                    │   etcd CLUSTER         │
                    │   3 o 5 nodos          │
                    │   RAFT consensus       │
                    └────────────────────────┘
```

**Ejemplo conceptual de configuración HA** (referencia - NO para implementar):

```yaml
# EJEMPLO TEÓRICO: Configuración de cluster HA con kubeadm
# Este archivo es SOLO para comprensión arquitectónica
# NO lo usaremos en Minikube
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
controlPlaneEndpoint: "192.168.1.100:6443"  # VIP del Load Balancer
etcd:
  external:
    endpoints:
    - https://192.168.1.10:2379  # etcd-1
    - https://192.168.1.11:2379  # etcd-2
    - https://192.168.1.12:2379  # etcd-3
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
    keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
networking:
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/12"
```

**Características importantes**:

1. **API Server**: Múltiples instancias activas (active-active)
   - Todas responden a requests simultáneamente
   - Load Balancer distribuye tráfico
   - Sin coordinación entre ellas (stateless)

2. **Scheduler y Controller Manager**: Leader Election (active-passive)
   
   ```bash
   # CONCEPTO: Solo UNA instancia es líder y trabaja activamente
   # Las demás están en standby esperando
   
   # En un cluster real, verías quién es el líder:
   # $ kubectl get endpoints kube-scheduler -n kube-system -o yaml
   # holderIdentity: master-2_abc123...
   # leaseDurationSeconds: 15
   # renewTime: "2024-11-11T10:45:30Z"
   ```

3. **etcd**: Cluster con RAFT consensus
   - Número impar de nodos (3, 5, 7)
   - Quorum: (N+1)/2
   - 3 nodos: tolera 1 fallo
   - 5 nodos: tolera 2 fallos

**Cómo explorar estos conceptos en Minikube**:

```bash
# Aunque Minikube es single-node, podemos ver cómo están los componentes

# Ver pods del Control Plane
$ kubectl get pods -n kube-system

# En Minikube verás:
# - etcd-minikube (solo 1 instancia)
# - kube-apiserver-minikube
# - kube-controller-manager-minikube
# - kube-scheduler-minikube

# Inspeccionar el API Server
$ kubectl get pod kube-apiserver-minikube -n kube-system -o yaml

# Ver logs del scheduler
$ kubectl logs kube-scheduler-minikube -n kube-system

# En un cluster HA real tendrías múltiples instancias de cada uno
```

**Referencia conceptual**: Pasos que se seguirían en un cluster HA real (SOLO para conocimiento):

```bash
# EJEMPLO TEÓRICO - NO EJECUTAR EN MINIKUBE
# Este es el proceso que usarías con kubeadm en un entorno real

# 1. Configurar Load Balancer (HAProxy/nginx)
# frontend k8s-api
#     bind 192.168.1.100:6443
#     backend: master-1, master-2, master-3

# 2. Inicializar primer master
# $ kubeadm init --config=kubeadm-config.yaml --upload-certs

# 3. Unir masters adicionales
# $ kubeadm join 192.168.1.100:6443 \
#     --control-plane \
#     --certificate-key <cert-key>

# 4. Resultado: múltiples masters
# $ kubectl get nodes
# master-1   Ready    control-plane   10m
# master-2   Ready    control-plane   5m
# master-3   Ready    control-plane   2m
```

**📁 Ver referencia de configuración HA:** [`ejemplos/04-alta-disponibilidad/ha-cluster-setup.yaml`](./ejemplos/04-alta-disponibilidad/ha-cluster-setup.yaml)

### 5.3 etcd: El Almacén de Estado (Conceptos)

etcd es el componente MÁS CRÍTICO del cluster (almacena TODO el estado). En clusters de producción, etcd puede ejecutarse en HA.

**Topologías de etcd** (referencia conceptual):

1. **Stacked etcd** (mismo nodo que control plane):
   ```
   ┌──────────────────┐
   │   Master Node    │
   │ ┌──────────────┐ │
   │ │ API Server   │ │
   │ └──────────────┘ │
   │ ┌──────────────┐ │
   │ │ etcd         │◄┼──┐ Cluster
   │ └──────────────┘ │  │ de etcd
   └──────────────────┘  │
                         │
   ✓ Más simple           │
   ✓ Menos recursos       │
   ✗ Menos resiliente     │
   
   (Minikube usa esta topología)
   ```

2. **External etcd** (nodos dedicados - solo producción):
   ```
   ┌──────────────┐       ┌──────────────┐
   │ Master Node  │       │ etcd Node    │
   │ ┌──────────┐ │       │ ┌──────────┐ │
   │ │API Server├─┼──────►│ │  etcd    │ │
   │ └──────────┘ │       │ └──────────┘ │
   └──────────────┘       └──────────────┘
   
   ✓ Más resiliente
   ✓ Performance aislada
   ✗ Más complejo
   ✗ Más recursos
   ```

**Explorando etcd en Minikube**:

```bash
# Acceder al pod de etcd en Minikube
$ kubectl exec -it etcd-minikube -n kube-system -- sh

# Dentro del pod, ver datos almacenados
$ export ETCDCTL_API=3
$ etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/minikube/certs/etcd/ca.crt \
  --cert=/var/lib/minikube/certs/etcd/server.crt \
  --key=/var/lib/minikube/certs/etcd/server.key \
  get / --prefix --keys-only | head -20

# Verás keys como:
# /registry/pods/default/my-pod
# /registry/services/default/kubernetes
# /registry/deployments/default/my-app

# Ver estadísticas
$ etcdctl endpoint status --write-out=table
```

**REFERENCIA: Cómo se vería etcd cluster en producción** (solo conceptual):

```bash
# EJEMPLO TEÓRICO - Cluster de 3 nodos etcd

# Ver miembros del cluster
# $ ETCDCTL_API=3 etcdctl member list
# etcd-1: https://192.168.1.10:2379 (LEADER)
# etcd-2: https://192.168.1.11:2379 (FOLLOWER)
# etcd-3: https://192.168.1.12:2379 (FOLLOWER)

# Ver salud
# $ ETCDCTL_API=3 etcdctl endpoint health --cluster
# etcd-1 is healthy
# etcd-2 is healthy
# etcd-3 is healthy
```

**Cálculo de quorum** (importante para entender resilencia):

```
Quorum = (N + 1) / 2

┌───────┬────────┬──────────────┬─────────────────┐
│ Nodos │ Quorum │ Fallos OK    │ Recomendación   │
├───────┼────────┼──────────────┼─────────────────┤
│   1   │   1    │ 0 (sin HA)   │ Minikube/Dev    │
│   3   │   2    │ 1 nodo       │ ✓ Producción    │
│   5   │   3    │ 2 nodos      │ ✓ Alta crítica  │
│   7   │   4    │ 3 nodos      │ Casos extremos  │
└───────┴────────┴──────────────┴─────────────────┘

⚠️ IMPORTANTE: Más nodos NO siempre es mejor
- Más latencia (consensus más lento)
- Más ancho de banda (replicación)
- Número impar SIEMPRE (evitar split-brain)
```

**📁 Ver referencia de etcd cluster:** [`ejemplos/04-alta-disponibilidad/etcd-ha-cluster.yaml`](./ejemplos/04-alta-disponibilidad/etcd-ha-cluster.yaml)

### 5.4 Backup y Restore de etcd en Minikube

Aunque no tenemos un cluster multi-nodo, podemos practicar backup y restore de etcd en Minikube.

```bash
# Hacer snapshot del etcd de Minikube
$ minikube ssh

# Dentro de Minikube
$ docker exec -it $(docker ps -qf "name=etcd") sh

# Crear backup
$ ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/minikube/certs/etcd/ca.crt \
  --cert=/var/lib/minikube/certs/etcd/server.crt \
  --key=/var/lib/minikube/certs/etcd/server.key

# Verificar snapshot
$ ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db --write-out=table
```

### 5.5 Conceptos de HA para Producción (Referencia)

**NOTA**: Esta sección es SOLO para referencia conceptual. En producción real con managed Kubernetes (AKS, EKS, GKE), el proveedor de nube gestiona automáticamente la HA del Control Plane.

**Checklist conceptual de HA**:

```yaml
# REFERENCIA: Configuración típica de producción
# (NO aplicable a Minikube)

Control Plane:
  masters: 3  # Número impar
  etcd_nodes: 3  # Puede ser external o stacked
  load_balancer: "Cloud LB (Azure LB, AWS ELB, GCP LB)"
  
Worker Nodes:
  min_workers: 3+
  distribution: "Múltiples availability zones"
  auto_scaling: true
  
Networking:
  cni_plugin: "Calico / Cilium / Azure CNI"
  dns_replicas: 2
  
Storage:
  persistent_volumes: "Con replicación"
  backup_strategy: "Automated etcd snapshots"
  
Monitoring:
  metrics_server: true
  prometheus: true
  alerting: "Critical components down"
```

**Patrones de fallo y recuperación**:

| Escenario | Impacto | Recuperación |
|-----------|---------|--------------|
| 1 API Server cae | ✓ Sin impacto (LB redirige) | Automático |
| 1 etcd nodo cae (de 3) | ✓ Sin impacto (quorum 2/3) | Manual: reemplazar nodo |
| 2 etcd nodos caen | ✗ Cluster read-only | Urgente: restaurar nodos |
| Scheduler cae | ✓ Leader election (1-2s) | Automático |
| Controller Mgr cae | ✓ Leader election (1-2s) | Automático |
| Worker node cae | ✓ Pods migran a otros nodes | Automático (60s-5min) |

**📁 Ver estrategias de backup/restore:** [`ejemplos/04-alta-disponibilidad/backup-restore.yaml`](./ejemplos/04-alta-disponibilidad/backup-restore.yaml)

---

## 6. Cluster Addons

Los Addons son componentes opcionales que extienden la funcionalidad del cluster. Aunque no son parte del core de Kubernetes, son casi imprescindibles en producción.

**Addons comunes**:
- **DNS (CoreDNS)**: Resolución de nombres de Services
- **Metrics Server**: Métricas de recursos (CPU, RAM)
- **Dashboard**: UI web para gestión
- **Ingress Controller**: Routing HTTP/HTTPS
- **CNI Plugin**: Networking entre pods

### 6.1 CoreDNS - Servicio DNS del Cluster

CoreDNS proporciona resolución DNS para todos los Services y Pods en el cluster.

**¿Cómo funciona?**

```
POD solicita: backend-service.default.svc.cluster.local
                                   ↓
            ┌─────────────────────────────────────┐
            │  /etc/resolv.conf del Pod          │
            │  nameserver 10.96.0.10  ← CoreDNS  │
            └─────────────┬───────────────────────┘
                          │ DNS Query
            ┌─────────────▼───────────────────────┐
            │  CoreDNS Pod                        │
            │  - Lee Service resources vía API    │
            │  - Retorna ClusterIP: 10.96.100.50  │
            └─────────────────────────────────────┘
```

**Ejemplo de configuración CoreDNS inline**:

```yaml
# CoreDNS se despliega como un Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
spec:
  replicas: 2  # HA: múltiples réplicas
  selector:
    matchLabels:
      k8s-app: kube-dns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
    spec:
      containers:
      - name: coredns
        image: registry.k8s.io/coredns/coredns:v1.10.1
        args: [ "-conf", "/etc/coredns/Corefile" ]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
      volumes:
      - name: config-volume
        configMap:
          name: coredns
---
# Service para exponer CoreDNS
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
spec:
  clusterIP: 10.96.0.10  # IP fija conocida
  selector:
    k8s-app: kube-dns
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
```

**Configuración de CoreDNS (Corefile)**:

```bash
# ConfigMap: coredns
.:53 {
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf {
       max_concurrent 1000
    }
    cache 30
    loop
    reload
    loadbalance
}
```

**Prueba de DNS**:

```bash
# Desde un pod, verificar DNS
$ kubectl run test-dns --rm -it --image=busybox -- sh

/ # nslookup kubernetes
Server:    10.96.0.10
Address:   10.96.0.10:53

Name:      kubernetes.default.svc.cluster.local
Address:   10.96.0.1

/ # nslookup backend-service
Server:    10.96.0.10
Address:   10.96.0.10:53

Name:      backend-service.default.svc.cluster.local
Address:   10.96.100.50
```

**Formatos DNS válidos**:

```
<service-name>                             → Mismo namespace
<service-name>.<namespace>                 → Namespace específico
<service-name>.<namespace>.svc             → Forma corta
<service-name>.<namespace>.svc.cluster.local → FQDN completo
```

**📁 Ver configuración completa de CoreDNS:** [`ejemplos/05-addons/coredns-config.yaml`](./ejemplos/05-addons/coredns-config.yaml)

### 6.2 Metrics Server - Métricas de Recursos

Metrics Server recolecta métricas de recursos (CPU, memoria) de kubelet y las expone vía API.

**¿Para qué sirve?**
- `kubectl top nodes` / `kubectl top pods`
- Horizontal Pod Autoscaler (HPA)
- Vertical Pod Autoscaler (VPA)

**Arquitectura**:

```
┌──────────────────────────────────────────────────────────┐
│  kubectl top pods                                        │
└────────────┬─────────────────────────────────────────────┘
             │ GET /apis/metrics.k8s.io/v1beta1/pods
┌────────────▼─────────────────────────────────────────────┐
│  API Server (agrega API metrics.k8s.io)                  │
└────────────┬─────────────────────────────────────────────┘
             │ Proxy request
┌────────────▼─────────────────────────────────────────────┐
│  Metrics Server                                          │
│  - Agrega métricas de todos los kubelets                 │
│  - No almacena histórico (solo último valor)             │
└────────────┬─────────────────────────────────────────────┘
             │ HTTPS GET /stats/summary
┌────────────▼─────────────────────────────────────────────┐
│  kubelet (cada Worker Node)                              │
│  - Lee cgroups del kernel                                │
│  - Métricas en tiempo real                               │
└──────────────────────────────────────────────────────────┘
```

**Ejemplo de instalación inline**:

```bash
# Instalar Metrics Server
$ kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verificar instalación
$ kubectl get deployment metrics-server -n kube-system
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
metrics-server   1/1     1            1           2m

# Esperar a que esté listo
$ kubectl wait --for=condition=available --timeout=300s \
  deployment/metrics-server -n kube-system

# Usar métricas
$ kubectl top nodes
NAME         CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
master-1     250m         12%    2048Mi          25%
worker-1     150m         7%     1536Mi          19%
worker-2     180m         9%     1792Mi          22%

$ kubectl top pods
NAME                    CPU(cores)   MEMORY(bytes)
nginx-deployment-abc    10m          64Mi
backend-service-xyz     25m          128Mi
```

**Configuración de Metrics Server**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - name: metrics-server
        image: registry.k8s.io/metrics-server/metrics-server:v0.6.4
        args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP
        - --kubelet-use-node-status-port
        - --metric-resolution=15s  # Frecuencia de scraping
```

**Uso con HPA (Horizontal Pod Autoscaler)**:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Escalar si CPU > 70%
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80  # Escalar si RAM > 80%
```

**📁 Ver configuración de Metrics Server y HPA:** [`ejemplos/05-addons/metrics-server.yaml`](./ejemplos/05-addons/metrics-server.yaml)

### 6.3 Kubernetes Dashboard - UI Web

Dashboard proporciona una interfaz gráfica para gestionar recursos del cluster.

**Instalación**:

```bash
# Instalar Dashboard
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Crear usuario admin
$ kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard
$ kubectl create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:dashboard-admin

# Obtener token
$ kubectl create token dashboard-admin -n kubernetes-dashboard
eyJhbGciOiJSUzI1NiIsImtpZCI6IjRyV...

# Acceder via proxy
$ kubectl proxy
Starting to serve on 127.0.0.1:8001

# URL: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

**Funcionalidades del Dashboard**:
- Ver/editar Deployments, Pods, Services
- Ver logs de contenedores
- Ejecutar shell en pods
- Ver eventos del cluster
- Monitorear recursos (si Metrics Server está instalado)

**⚠️ Consideraciones de seguridad**:
```yaml
# NO usar cluster-admin en producción
# Crear ServiceAccount con permisos limitados

apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-viewer
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view  # Solo lectura
subjects:
- kind: ServiceAccount
  name: dashboard-viewer
  namespace: kubernetes-dashboard
```

**📁 Ver configuración segura de Dashboard:** [`ejemplos/05-addons/dashboard-secure.yaml`](./ejemplos/05-addons/dashboard-secure.yaml)

### 6.4 CNI Plugins - Networking

Container Network Interface (CNI) plugins proporcionan networking entre pods.

**Opciones populares**:

| Plugin | Características | Mejor para |
|--------|----------------|------------|
| **Calico** | Network policies, BGP routing | Producción, seguridad |
| **Flannel** | Simple, overlay VXLAN | Dev, clusters pequeños |
| **Cilium** | eBPF, observabilidad avanzada | Performance, seguridad |
| **Weave Net** | Mesh encryption | Multi-cloud |

**Ejemplo: Instalación de Calico**:

```bash
# Instalar Calico
$ kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Verificar pods de calico
$ kubectl get pods -n kube-system -l k8s-app=calico-node
NAME                READY   STATUS    RESTARTS   AGE
calico-node-abc     1/1     Running   0          2m
calico-node-xyz     1/1     Running   0          2m
calico-node-def     1/1     Running   0          2m

# Verificar networking
$ kubectl get pods -o wide
NAME         READY   STATUS    IP            NODE
frontend     1/1     Running   10.244.1.5    worker-1
backend      1/1     Running   10.244.2.8    worker-2

# Desde frontend, hacer ping a backend
$ kubectl exec frontend -- ping -c 2 10.244.2.8
PING 10.244.2.8 (10.244.2.8): 56 data bytes
64 bytes from 10.244.2.8: seq=0 ttl=62 time=0.5 ms
64 bytes from 10.244.2.8: seq=1 ttl=62 time=0.4 ms
```

**Network Policies con Calico**:

```yaml
# Ejemplo: Denegar todo el tráfico excepto desde frontend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

**📁 Ver comparativa de CNI plugins:** [`ejemplos/05-addons/cni-plugins.yaml`](./ejemplos/05-addons/cni-plugins.yaml)

---

## 🎯 Conclusiones y Resumen del Módulo

### 📚 Conceptos Clave Dominados

Has completado un recorrido exhaustivo por la arquitectura de Kubernetes. Estos son los conceptos fundamentales que ahora dominas:

#### 1. **Arquitectura del Cluster**
- Separación clara entre **Control Plane** (gestión) y **Worker Nodes** (ejecución)
- Arquitectura distribuida y resiliente
- Comunicación centralizada a través del API Server

#### 2. **Control Plane Components**
- **API Server**: Gateway único para todas las operaciones
- **etcd**: Base de datos distribuida con consistencia RAFT
- **Scheduler**: Algoritmo inteligente de placement
- **Controller Manager**: Reconciliation loops para estado deseado

#### 3. **Worker Node Components**
- **kubelet**: Agente que asegura que contenedores están corriendo
- **kube-proxy**: Networking y balanceo de carga
- **Container Runtime**: Interfaz CRI con containerd/CRI-O

#### 4. **High Availability**
- Multi-master setup con etcd clustering
- Load Balancing de Control Plane
- Backup y restore procedures
- Tolerancia a fallos con quorum

#### 5. **Cluster Addons**
- **CoreDNS**: Service discovery interno
- **Metrics Server**: Autoscaling y monitoreo
- **CNI Plugins**: Networking flexible
- **Dashboard**: Gestión visual

---

### ✅ Checklist de Verificación

Antes de pasar al siguiente módulo, asegúrate de poder responder **SÍ** a todas estas preguntas:

#### Arquitectura General
- [ ] ¿Puedo explicar la diferencia entre Control Plane y Data Plane?
- [ ] ¿Entiendo por qué el API Server es el componente central?
- [ ] ¿Conozco el flujo completo desde `kubectl apply` hasta la ejecución?

#### Control Plane
- [ ] ¿Sé cómo el Scheduler selecciona nodos para los pods?
- [ ] ¿Entiendo qué es etcd y por qué es crítico?
- [ ] ¿Puedo explicar qué es un reconciliation loop?
- [ ] ¿Sé hacer backup y restore de etcd?

#### Worker Nodes
- [ ] ¿Entiendo cómo kubelet gestiona el ciclo de vida de pods?
- [ ] ¿Conozco las diferencias entre iptables e IPVS en kube-proxy?
- [ ] ¿Sé usar crictl para debugging de contenedores?
- [ ] ¿Puedo diagnosticar problemas de networking en nodos?

#### High Availability
- [ ] ¿Sé configurar un cluster multi-master?
- [ ] ¿Entiendo cómo funciona el quorum de etcd?
- [ ] ¿Puedo explicar el proceso de elección de líder?
- [ ] ¿Conozco estrategias de disaster recovery?

#### Addons y Networking
- [ ] ¿Entiendo cómo funciona DNS en Kubernetes?
- [ ] ¿Sé troubleshootear Services que no responden?
- [ ] ¿Puedo configurar el Metrics Server para HPA?
- [ ] ¿Conozco las diferencias entre CNI plugins?

---

### 🛠️ Habilidades Prácticas Adquiridas

Después de completar los laboratorios, ahora puedes:

1. **Explorar un Cluster**
   - Inspeccionar componentes del Control Plane
   - Analizar estado de Worker Nodes
   - Verificar comunicación entre componentes

2. **Operar el Control Plane**
   - Interactuar con el API Server vía REST
   - Realizar backup y restore de etcd
   - Analizar decisiones del Scheduler
   - Debuggear reconciliation loops

3. **Gestionar Worker Nodes**
   - Configurar kubelet para diferentes escenarios
   - Cambiar entre modos iptables e IPVS
   - Usar crictl para inspeccionar contenedores
   - Analizar cgroups y namespaces

4. **Troubleshooting Avanzado**
   - Diagnosticar Services que no responden
   - Resolver problemas de DNS
   - Usar tcpdump para análisis de tráfico
   - Debuggear NetworkPolicies

---

### 📊 Mapa Mental de la Arquitectura

```
Kubernetes Cluster
│
├── Control Plane (Master Nodes)
│   │
│   ├── API Server (:6443)
│   │   ├── REST API
│   │   ├── Watch API
│   │   └── Authentication/Authorization
│   │
│   ├── etcd (RAFT)
│   │   ├── Key-Value Store
│   │   ├── Distributed Consensus
│   │   └── Backup/Restore
│   │
│   ├── Scheduler
│   │   ├── Node Selection
│   │   ├── Resource Awareness
│   │   └── Affinity/Taints
│   │
│   └── Controller Manager
│       ├── ReplicaSet Controller
│       ├── Deployment Controller
│       ├── Node Controller
│       └── ... (50+ controllers)
│
└── Worker Nodes
    │
    ├── kubelet
    │   ├── Pod Lifecycle
    │   ├── Health Probes
    │   └── CRI Interface
    │
    ├── kube-proxy
    │   ├── Service Abstraction
    │   ├── Load Balancing
    │   └── iptables/IPVS
    │
    ├── Container Runtime
    │   ├── containerd/CRI-O
    │   ├── runc (OCI)
    │   └── Namespaces/Cgroups
    │
    └── Addons
        ├── CoreDNS (DNS)
        ├── CNI Plugin (Networking)
        └── Metrics Server
```

---

### 🔍 Comandos Esenciales para Recordar

```bash
# Control Plane
kubectl get componentstatuses
kubectl get --raw /api/v1
etcdctl snapshot save backup.db
kubectl describe node <node> | grep -A 5 "Allocated resources"

# Worker Nodes
kubectl get nodes -o wide
kubectl describe node <node>
crictl ps
crictl images

# Networking
kubectl get svc
kubectl get endpoints
kubectl exec -it <pod> -- nslookup kubernetes
tcpdump -i any -n port 80

# Addons
kubectl get pods -n kube-system
kubectl top nodes
kubectl top pods
kubectl logs -n kube-system <coredns-pod>

# Troubleshooting
kubectl get events --sort-by='.lastTimestamp'
kubectl logs <pod> --previous
kubectl debug node/<node> -it --image=ubuntu
kubectl run netshoot --rm -it --image=nicolaka/netshoot
```

---

### 📖 Recursos de Referencia Rápida

#### Documentación Oficial
- [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)
- [Cluster Architecture](https://kubernetes.io/docs/concepts/architecture/)
- [etcd Documentation](https://etcd.io/docs/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)

#### Guías de Troubleshooting
- [Debug Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)
- [Debug Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)
- [Troubleshoot Clusters](https://kubernetes.io/docs/tasks/debug/debug-cluster/)

#### Herramientas
- **crictl**: Container Runtime CLI
- **etcdctl**: etcd command-line tool
- **kubectl debug**: Ephemeral containers
- **netshoot**: Network troubleshooting container

---

### 🚨 Problemas Comunes y Soluciones (En Minikube)

#### "Pods no arrancan en mi cluster"
```bash
# 1. Verificar scheduler
kubectl get pods -n kube-system | grep scheduler

# 2. Ver eventos
kubectl get events --sort-by='.lastTimestamp' | tail

# 3. Verificar recursos del nodo Minikube
kubectl describe node minikube | grep -A 5 "Allocated"

# 4. Ver logs del scheduler
kubectl logs -n kube-system kube-scheduler-minikube
```

#### "Services no responden"
```bash
# 1. Verificar endpoints
kubectl get endpoints <service>

# 2. Comparar labels
kubectl get svc <service> -o jsonpath='{.spec.selector}'
kubectl get pods -l <selector> -o jsonpath='{.items[0].metadata.labels}'

# 3. Probar conectividad directa al pod
kubectl exec -it <test-pod> -- curl http://<pod-ip>:<port>

# 4. Verificar desde dentro de Minikube
minikube ssh
curl <service-cluster-ip>:<port>
```

#### "DNS no funciona"
```bash
# 1. Verificar CoreDNS en Minikube
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 2. Verificar Service
kubectl get svc -n kube-system kube-dns

# 3. Test directo
kubectl run test --rm -it --image=busybox -- nslookup kubernetes

# 4. Reiniciar CoreDNS si es necesario
kubectl rollout restart deployment coredns -n kube-system
```

#### "Minikube no inicia o se queda colgado"
```bash
# Ver logs de Minikube
minikube logs

# Reiniciar completamente
minikube stop
minikube delete
minikube start --driver=docker

# Verificar recursos de la VM
minikube ssh
df -h  # Espacio en disco
free -h  # Memoria
```

---

### 🎓 Preparación para el Siguiente Módulo

**Módulo 03: Operación y Seguridad** se enfocará en:

1. **RBAC (Role-Based Access Control)**
   - Users, Groups, ServiceAccounts
   - Roles y ClusterRoles
   - RoleBindings y ClusterRoleBindings

2. **Security Best Practices**
   - Pod Security Standards
   - Network Policies
   - Secrets Management
   - Security Contexts

3. **Resource Management**
   - Resource Quotas
   - LimitRanges
   - Priority Classes

4. **Operaciones con Minikube**
   - Minikube Addons
   - Persistent Volumes en Minikube
   - Acceso a Services desde el host
   - Disaster Recovery

**Pre-requisitos para Módulo 03:**
- ✅ Comprensión sólida de la arquitectura (este módulo)
- ✅ Capacidad de usar kubectl con confianza
- ✅ Minikube funcionando correctamente
- ✅ Familiaridad con pods, services y deployments básicos

---

### 💡 Mejores Prácticas Aprendidas

#### Trabajando con Minikube
- ✓ **Usa driver Docker** para mejor compatibilidad
- ✓ **Asigna recursos adecuados**: `minikube start --cpus=2 --memory=4096`
- ✓ **Habilita addons necesarios**: `minikube addons enable metrics-server`
- ✓ **Usa `minikube ssh`** para debugging avanzado dentro del nodo

#### Operación del Cluster
- ✓ **Monitorea recursos**: `kubectl top nodes` y `kubectl top pods`
- ✓ **Establece Resource Limits en todos los pods**
- ✓ **Usa Health Probes** (liveness, readiness, startup)
- ✓ **Consulta eventos regularmente**: `kubectl get events --sort-by='.lastTimestamp'`

#### Troubleshooting
- ✓ **Empieza siempre por los eventos**: `kubectl get events`
- ✓ **Verifica endpoints antes de culpar a DNS**
- ✓ **Usa `kubectl describe`** para ver detalles completos
- ✓ **Revisa logs de componentes del sistema**: `kubectl logs -n kube-system`

#### Conceptos de Producción (para el futuro)
- ✓ **En producción, usa managed Kubernetes** (AKS, EKS, GKE)
- ✓ **Nunca expongas API Server sin autenticación**
- ✓ **Usa RBAC para todos los usuarios**
- ✓ **Implementa Network Policies restrictivas**
- ✓ **Automatiza backups de estado crítico**

---

### 🏆 Logros Desbloqueados

✅ **Arquitecto de Kubernetes**: Comprendes todos los componentes del cluster

✅ **Operador del Control Plane**: Puedes gestionar API Server, etcd, Scheduler

✅ **Especialista en Worker Nodes**: Dominas kubelet, kube-proxy, container runtime

✅ **Troubleshooter Experto**: Sabes diagnosticar problemas de networking y Services

✅ **HA Master**: Puedes diseñar e implementar clusters de alta disponibilidad

---

### 📝 Ejercicio Final de Autoevaluación

Antes de continuar, intenta responder sin consultar:

1. ¿Qué sucede cuando ejecutas `kubectl apply -f deployment.yaml`? (describe cada componente involucrado)

2. ¿Cómo decide el Scheduler en qué nodo colocar un pod?

3. ¿Qué diferencia hay entre iptables mode e IPVS mode en kube-proxy?

4. ¿Cómo aseguras que un cluster de 5 nodos etcd puede tolerar 2 fallos?

5. ¿Por qué un Service puede tener ClusterIP pero no endpoints?

**Respuestas esperadas:**
- Detalladas, con referencia a componentes específicos
- Mención de flujos de comunicación
- Consideraciones de HA y troubleshooting

---

### 🎯 Próximos Pasos Recomendados

1. **Práctica Continua en Minikube**
   - Repite los laboratorios en tu VM de Azure
   - Experimenta creando y eliminando recursos
   - Practica troubleshooting intencionalmente (elimina pods, simula fallos)

2. **Profundización**
   - Explora la [documentación oficial de Kubernetes](https://kubernetes.io/docs/)
   - Sigue el blog de Kubernetes para novedades
   - Únete a comunidades en español de Kubernetes

3. **Preparación para Producción (futuro)**
   - Considera preparar **CKA** (Certified Kubernetes Administrator)
   - Explora managed Kubernetes (AKS en Azure)
   - Aprende sobre GitOps (ArgoCD, Flux)

4. **Comunidad**
   - Únete a [Kubernetes Slack](https://slack.k8s.io/)
   - Participa en meetups locales de Cloud Native
   - Comparte tu aprendizaje en LinkedIn/Twitter

---

## 🙏 Agradecimientos

Has completado el **Módulo 02: Arquitectura del Cluster de Kubernetes**.

Este módulo te ha proporcionado las bases sólidas necesarias para:
- Entender cómo funciona Kubernetes internamente
- Trabajar con confianza en Minikube
- Diagnosticar y resolver problemas básicos
- Prepararte para conceptos avanzados de operación y seguridad
- Comprender la diferencia entre entornos de aprendizaje y producción

**Entorno de Trabajo**:
- ✅ Minikube con driver Docker en VM Ubuntu (Azure)
- ✅ Cluster single-node ideal para aprendizaje
- ✅ Todos los componentes del Control Plane accesibles para inspección
- ✅ Conceptos de HA y clustering comprendidos (sin implementación práctica)

**¡Felicitaciones por tu dedicación y esfuerzo! 🎉**

---

**Siguiente:** [Módulo 03 - Operación y Seguridad](../area-3-operacion-seguridad/README.md)

---

*Última actualización: Noviembre 2025*  
*Curso: Kubernetes de Fundamentos a Producción*  
*Área 2: Arquitectura de Kubernetes*  
*Entorno: Minikube + Docker en Azure VM*
