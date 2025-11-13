# Módulo 24: Advanced Scheduling

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Manual Scheduling](#manual-scheduling)
3. [Static Pods](#static-pods)
4. [Taints y Tolerations](#taints-y-tolerations)
5. [Node Affinity](#node-affinity)
6. [Pod Affinity y Anti-Affinity](#pod-affinity-y-anti-affinity)
7. [Resource Quotas y LimitRanges](#resource-quotas-y-limitranges)
8. [Priority Classes](#priority-classes)
9. [Scheduler Profiles](#scheduler-profiles)
10. [Troubleshooting](#troubleshooting)

---

## 🎯 Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:

- ✅ Controlar el scheduling de pods manualmente
- ✅ Crear y gestionar static pods
- ✅ Aplicar taints y tolerations para control de nodos
- ✅ Usar node affinity para scheduling avanzado
- ✅ Implementar pod affinity y anti-affinity
- ✅ Configurar resource quotas y limits
- ✅ Trabajar con priority classes
- ✅ Entender scheduler profiles personalizados

---

## 📚 Introducción

### ¿Qué es el Scheduler?

El **kube-scheduler** es el componente que decide en qué nodo debe ejecutarse cada pod.

```
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Scheduler Workflow               │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. FILTERING (Predicates)                              │
│     ┌────────────────────────────────────┐             │
│     │ Node tiene recursos suficientes?   │             │
│     │ Node satisface nodeSelector?       │             │
│     │ Pod tolera taints del node?        │             │
│     │ Puertos disponibles?                │             │
│     └────────────────────────────────────┘             │
│                    │                                     │
│                    ▼                                     │
│  2. SCORING (Priorities)                                │
│     ┌────────────────────────────────────┐             │
│     │ Balance de recursos                │             │
│     │ Affinity rules                     │             │
│     │ Spreading                          │             │
│     │ Image locality                     │             │
│     └────────────────────────────────────┘             │
│                    │                                     │
│                    ▼                                     │
│  3. BINDING                                             │
│     ┌────────────────────────────────────┐             │
│     │ Asignar pod al nodo con           │             │
│     │ mayor score                        │             │
│     └────────────────────────────────────┘             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Scheduling Decision Factors

1. **Recursos:** CPU, Memoria, Storage
2. **Constraints:** nodeSelector, affinity, taints/tolerations
3. **Policies:** Spreading, packing, priorities
4. **Estado:** Capacidad disponible, health del nodo

---

## 🎮 Manual Scheduling

### Método 1: nodeName (Bypass Scheduler)

Asignar directamente un pod a un nodo específico:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: manual-pod
spec:
  nodeName: worker-01  # Bypass scheduler, ir directo a worker-01
  containers:
  - name: nginx
    image: nginx
```

**Características:**
- ✅ Scheduling inmediato (no espera scheduler)
- ✅ Útil para debugging
- ❌ No considera recursos disponibles
- ❌ No aplica taints/tolerations
- ❌ Si nodo no existe, pod queda Pending

```bash
# Crear pod con nodeName
kubectl apply -f manual-pod.yaml

# Verificar
kubectl get pod manual-pod -o wide
# NAME         READY   STATUS    RESTARTS   AGE   IP            NODE
# manual-pod   1/1     Running   0          5s    10.244.1.5    worker-01
```

### Método 2: nodeSelector (Scheduler con Labels)

Usar labels para seleccionar nodos:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: selector-pod
spec:
  nodeSelector:
    disktype: ssd
    environment: production
  containers:
  - name: nginx
    image: nginx
```

**Workflow:**
1. Scheduler filtra nodos con labels especificados
2. Aplica scoring entre nodos válidos
3. Asigna al mejor nodo

```bash
# Etiquetar nodo
kubectl label nodes worker-01 disktype=ssd environment=production

# Ver labels
kubectl get nodes --show-labels

# Crear pod
kubectl apply -f selector-pod.yaml

# Pod irá solo a nodos con esos labels
```

**✅ Cuándo usar:**
- Nodos con hardware específico (GPU, SSD)
- Separación por ambientes (prod, staging)
- Compliance requirements (región, zona)

---

## 🗿 Static Pods

### ¿Qué son Static Pods?

Pods gestionados directamente por kubelet en un nodo específico, **sin pasar por API server**.

```
┌─────────────────────────────────────────────────────────┐
│              Static Pods vs Regular Pods                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Regular Pod                    Static Pod              │
│  ┌──────────┐                   ┌──────────┐           │
│  │ kubectl  │                   │   File   │           │
│  │ create   │                   │ /etc/.../ │           │
│  └────┬─────┘                   └────┬─────┘           │
│       │                              │                  │
│       ▼                              ▼                  │
│  ┌──────────┐                   ┌──────────┐           │
│  │   API    │                   │ kubelet  │           │
│  │  Server  │                   │  watch   │           │
│  └────┬─────┘                   └────┬─────┘           │
│       │                              │                  │
│       ▼                              ▼                  │
│  ┌──────────┐                   ┌──────────┐           │
│  │Scheduler │                   │   Pod    │           │
│  └────┬─────┘                   │  created │           │
│       │                         └──────────┘           │
│       ▼                                                 │
│  ┌──────────┐                                          │
│  │ kubelet  │                                          │
│  └────┬─────┘                                          │
│       │                                                 │
│       ▼                                                 │
│  ┌──────────┐                                          │
│  │   Pod    │                                          │
│  └──────────┘                                          │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Crear Static Pod

**Ubicación del manifesto:**
```bash
# Verificar staticPodPath en kubelet config
grep staticPodPath /var/lib/kubelet/config.yaml
# staticPodPath: /etc/kubernetes/manifests

# Crear static pod
sudo cat <<EOF > /etc/kubernetes/manifests/static-nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-nginx
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
EOF

# kubelet detecta el archivo automáticamente (watch)
# Pod aparece en cluster con sufijo -<nodename>
kubectl get pods
# NAME                      READY   STATUS    RESTARTS   AGE
# static-nginx-worker-01    1/1     Running   0          10s
```

**Características:**
- ✅ Sobreviven a reinicio de kubelet
- ✅ Kubelet los recrea automáticamente
- ✅ Útiles para componentes del control plane
- ❌ No pueden ser eliminados vía kubectl
- ❌ Ligados a un nodo específico

```bash
# Intentar eliminar static pod (no funciona)
kubectl delete pod static-nginx-worker-01
# pod "static-nginx-worker-01" deleted

# Pero reaparece inmediatamente
kubectl get pods
# NAME                      READY   STATUS    RESTARTS   AGE
# static-nginx-worker-01    1/1     Running   0          2s

# Para eliminar realmente, borrar el archivo
sudo rm /etc/kubernetes/manifests/static-nginx.yaml
```

**🎯 Casos de uso:**
- **Control plane components:** kube-apiserver, etcd, kube-scheduler (en clusters kubeadm)
- **Node-level daemons:** Monitoring agents específicos de nodo
- **Bootstrap:** Componentes que deben estar antes de que cluster esté funcional

---

## 🚫 Taints y Tolerations

### Concepto

**Taints** = "Repelentes" en nodos  
**Tolerations** = "Tolerancia" en pods para ignorar taints

```
┌─────────────────────────────────────────────────────────┐
│              Taints & Tolerations                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Node con Taint                                         │
│  ┌────────────────────────────────┐                    │
│  │ Node: worker-01                │                    │
│  │ Taint: gpu=true:NoSchedule     │                    │
│  │         ☢️ REPELENTE            │                    │
│  └────────────────────────────────┘                    │
│                                                          │
│  Pod SIN Toleration        Pod CON Toleration          │
│  ┌────────────┐            ┌────────────┐             │
│  │            │            │ Toleration:│             │
│  │  ❌ REJECTED│            │ gpu=true   │             │
│  │            │            │ ✅ ACCEPTED │             │
│  └────────────┘            └────────────┘             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Taint Effects

1. **NoSchedule:** No schedule nuevos pods (los existentes siguen)
2. **PreferNoSchedule:** Intenta no schedulear, pero no es garantía
3. **NoExecute:** No schedule nuevos + evict pods existentes

### Aplicar Taints

```bash
# Sintaxis:
# kubectl taint nodes <node> <key>=<value>:<effect>

# Ejemplo 1: NoSchedule
kubectl taint nodes worker-01 gpu=true:NoSchedule

# Ejemplo 2: Dedicated node para equipo específico
kubectl taint nodes worker-02 team=frontend:NoSchedule

# Ejemplo 3: NoExecute (evict existentes)
kubectl taint nodes worker-03 maintenance=true:NoExecute

# Ver taints de un nodo
kubectl describe node worker-01 | grep Taints
# Taints: gpu=true:NoSchedule

# Remover taint (añadir - al final)
kubectl taint nodes worker-01 gpu=true:NoSchedule-
```

### Tolerations en Pods

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  tolerations:
  - key: "gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  containers:
  - name: cuda-app
    image: nvidia/cuda:11.0-base
```

**Operators disponibles:**

```yaml
# Exact match
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"

# Cualquier valor para esa key
tolerations:
- key: "key1"
  operator: "Exists"
  effect: "NoSchedule"

# Tolerar todos los taints (wildcard)
tolerations:
- operator: "Exists"
```

**Toleration para NoExecute con tiempo de gracia:**

```yaml
tolerations:
- key: "node.kubernetes.io/unreachable"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 300  # Esperar 5 min antes de evict
```

### Taints Automáticos

Kubernetes añade taints automáticamente en ciertas condiciones:

```yaml
# Nodo NotReady
node.kubernetes.io/not-ready:NoExecute

# Nodo sin recursos
node.kubernetes.io/memory-pressure:NoSchedule
node.kubernetes.io/disk-pressure:NoSchedule
node.kubernetes.io/pid-pressure:NoSchedule

# Nodo sin conectividad
node.kubernetes.io/unreachable:NoExecute

# Nodo no inicializado
node.kubernetes.io/unschedulable:NoSchedule
```

**🎯 Casos de uso:**
- **Hardware específico:** GPUs, FPGAs
- **Dedicated nodes:** Un equipo, una app
- **Maintenance:** Evict pods antes de mantenimiento
- **Multi-tenancy:** Separación de cargas

---

## 🧲 Node Affinity

### Concepto

Node affinity = "Atracción" hacia ciertos nodos (más poderoso que nodeSelector).

### Tipos de Node Affinity

1. **requiredDuringSchedulingIgnoredDuringExecution**
   - HARD requirement
   - Si no cumple, pod NO schedules (Pending)

2. **preferredDuringSchedulingIgnoredDuringExecution**
   - SOFT requirement
   - Intenta cumplir, pero si no puede, schedules igual

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: affinity-pod
spec:
  affinity:
    nodeAffinity:
      # REQUIRED (hard)
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
            - nvme
          - key: region
            operator: NotIn
            values:
            - us-west-1
      
      # PREFERRED (soft)
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100  # 0-100, mayor = más preferido
        preference:
          matchExpressions:
          - key: availability-zone
            operator: In
            values:
            - us-east-1a
  containers:
  - name: nginx
    image: nginx
```

### Operators Disponibles

```yaml
# In: Valor está en la lista
- key: environment
  operator: In
  values: [production, staging]

# NotIn: Valor NO está en la lista
- key: environment
  operator: NotIn
  values: [development]

# Exists: Key existe (valor no importa)
- key: ssd
  operator: Exists

# DoesNotExist: Key NO existe
- key: gpu
  operator: DoesNotExist

# Gt: Mayor que (valores numéricos)
- key: cpu-cores
  operator: Gt
  values: ["16"]

# Lt: Menor que
- key: memory-gb
  operator: Lt
  values: ["64"]
```

### Ejemplo Complejo

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: database-pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        # Opción 1: SSD + al menos 32GB RAM
        - matchExpressions:
          - key: disktype
            operator: In
            values: [ssd]
          - key: memory-gb
            operator: Gt
            values: ["32"]
        # O Opción 2: NVMe (cualquier RAM)
        - matchExpressions:
          - key: disktype
            operator: In
            values: [nvme]
      
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: zone
            operator: In
            values: [us-east-1a]
      - weight: 50
        preference:
          matchExpressions:
          - key: rack
            operator: In
            values: [rack-1, rack-2]
  containers:
  - name: postgres
    image: postgres:14
```

**🎯 Casos de uso:**
- **Performance:** Scheduling en nodos high-performance
- **Compliance:** Datos en regiones específicas
- **Cost optimization:** Preferir instancias spot/preemptible
- **Multi-cloud:** Dirigir workloads a proveedores específicos

---

## 🤝 Pod Affinity y Anti-Affinity

### Concepto

- **Pod Affinity:** "Quiero estar CERCA de estos pods"
- **Pod Anti-Affinity:** "Quiero estar LEJOS de estos pods"

```
┌─────────────────────────────────────────────────────────┐
│           Pod Affinity & Anti-Affinity                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Pod Affinity (Co-location)                             │
│  ┌────────────────────────────────────┐                │
│  │ Node 1                             │                │
│  │  ┌────────┐  ┌────────┐           │                │
│  │  │ Cache  │  │  App   │ ← Together│                │
│  │  └────────┘  └────────┘           │                │
│  └────────────────────────────────────┘                │
│                                                          │
│  Anti-Affinity (Spreading)                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│  │ Node 1   │    │ Node 2   │    │ Node 3   │         │
│  │ ┌──────┐ │    │ ┌──────┐ │    │ ┌──────┐ │         │
│  │ │ App  │ │    │ │ App  │ │    │ │ App  │ │         │
│  │ └──────┘ │    │ └──────┘ │    │ └──────┘ │         │
│  └──────────┘    └──────────┘    └──────────┘         │
│                   ← Spread Apart                        │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Pod Affinity

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - cache
        topologyKey: kubernetes.io/hostname
  containers:
  - name: web
    image: nginx
```

**Significado:**
- "Schedúlame en el MISMO nodo (hostname) que pods con label `app=cache`"
- Si no hay pod con `app=cache`, este pod queda Pending

**topologyKey opciones:**
```yaml
# Mismo nodo
topologyKey: kubernetes.io/hostname

# Misma zona
topologyKey: topology.kubernetes.io/zone

# Misma región
topologyKey: topology.kubernetes.io/region

# Custom topology
topologyKey: rack
```

### Pod Anti-Affinity

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web
            topologyKey: kubernetes.io/hostname
      containers:
      - name: nginx
        image: nginx
```

**Significado:**
- "NO me schedules en el mismo nodo que otros pods con `app=web`"
- Garantiza que cada réplica va a un nodo diferente
- Alta disponibilidad

### Preferred Anti-Affinity

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 5
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - api
              topologyKey: kubernetes.io/hostname
      containers:
      - name: api
        image: myapi:latest
```

**Significado:**
- "INTENTA no ponerme en el mismo nodo que otros pods `app=api`"
- Pero si solo hay 3 nodos y 5 réplicas, algunas compartirán nodo
- Más flexible que `required`

**🎯 Casos de uso:**
- **High Availability:** Spread replicas across nodes/zones
- **Performance:** Co-locate cache with app
- **Security:** Separate sensitive workloads
- **Compliance:** Data locality requirements

---

## 📊 Resource Quotas y LimitRanges

### Resource Quotas (Namespace-level)

Limitar recursos a nivel de namespace:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: development
spec:
  hard:
    # Compute resources
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    
    # Storage
    requests.storage: 100Gi
    persistentvolumeclaims: "10"
    
    # Objects
    pods: "50"
    services: "10"
    configmaps: "20"
    secrets: "20"
    
    # Specific resource classes
    requests.nvidia.com/gpu: "2"
```

```bash
# Aplicar quota
kubectl apply -f resource-quota.yaml

# Ver quotas
kubectl get resourcequota -n development

# Describir (ver usage)
kubectl describe resourcequota compute-quota -n development
# Name:                   compute-quota
# Namespace:              development
# Resource                Used   Hard
# --------                ----   ----
# limits.cpu              8      20
# limits.memory           16Gi   40Gi
# pods                    15     50
# requests.cpu            4      10
# requests.memory         8Gi    20Gi
```

### LimitRange (Pod/Container-level)

Definir límites default y rangos válidos:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: development
spec:
  limits:
  # Límites para Containers
  - type: Container
    max:
      cpu: "2"
      memory: 4Gi
    min:
      cpu: "100m"
      memory: 128Mi
    default:
      cpu: "500m"
      memory: 512Mi
    defaultRequest:
      cpu: "200m"
      memory: 256Mi
    maxLimitRequestRatio:
      cpu: "10"  # limit puede ser máx 10x el request
      memory: "2"
  
  # Límites para Pods
  - type: Pod
    max:
      cpu: "4"
      memory: 8Gi
    min:
      cpu: "200m"
      memory: 256Mi
  
  # Límites para PVCs
  - type: PersistentVolumeClaim
    max:
      storage: 50Gi
    min:
      storage: 1Gi
```

```bash
# Aplicar limit range
kubectl apply -f limit-range.yaml

# Ver limit ranges
kubectl get limitrange -n development

# Describir
kubectl describe limitrange resource-limits -n development
```

**Efecto en pods SIN límites definidos:**

```yaml
# Pod sin limits/requests
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  namespace: development
spec:
  containers:
  - name: app
    image: nginx

# Kubernetes aplica automáticamente los defaults del LimitRange:
# requests:
#   cpu: 200m
#   memory: 256Mi
# limits:
#   cpu: 500m
#   memory: 512Mi
```

### Best Practices

```yaml
# Siempre definir requests y limits
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"

# CPU: limits opcionales (permite bursting)
# Memory: limits obligatorios (OOMKill si excede)

# QoS Classes resultantes:
# 1. Guaranteed: requests == limits
# 2. Burstable: requests < limits
# 3. BestEffort: sin requests ni limits
```

---

## ⚡ Priority Classes

### Concepto

Priorizar ciertos pods sobre otros cuando hay escasez de recursos.

```
┌─────────────────────────────────────────────────────────┐
│              Pod Priority & Preemption                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Cluster con recursos limitados                         │
│  ┌────────────────────────────────────┐                │
│  │ Node: 4 CPU disponibles            │                │
│  │                                     │                │
│  │ ┌──────────┐  ┌──────────┐        │                │
│  │ │Priority=1│  │Priority=1│  (6 CPU)│                │
│  │ └──────────┘  └──────────┘        │                │
│  └────────────────────────────────────┘                │
│                                                          │
│  Llega pod con Priority=100                             │
│  ┌────────────────────────────────────┐                │
│  │ ┌──────────────┐                   │                │
│  │ │ Priority=100 │ (2 CPU needed)    │                │
│  │ └──────────────┘                   │                │
│  └────────────────────────────────────┘                │
│                    │                                     │
│                    ▼ PREEMPTION                         │
│  ┌────────────────────────────────────┐                │
│  │ ┌──────────────┐  ┌──────────┐    │                │
│  │ │ Priority=100 │  │Priority=1│    │                │
│  │ └──────────────┘  └──────────┘    │                │
│  │                                     │                │
│  │ Pod Priority=1 eliminado (evicted) │                │
│  └────────────────────────────────────┘                │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Crear PriorityClass

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000  # Mayor número = mayor prioridad
globalDefault: false
preemptionPolicy: PreemptLowerPriority
description: "Para workloads críticos de producción"

---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: medium-priority
value: 100000
globalDefault: false
description: "Para workloads normales de producción"

---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 1000
globalDefault: true  # Default para pods sin priorityClassName
description: "Para workloads de desarrollo y testing"
```

```bash
# Crear priority classes
kubectl apply -f priority-classes.yaml

# Ver priority classes
kubectl get priorityclasses
# NAME                      VALUE        GLOBAL-DEFAULT   AGE
# system-node-critical      2000001000   false            30d
# system-cluster-critical   2000000000   false            30d
# high-priority             1000000      false            1m
# medium-priority           100000       false            1m
# low-priority              1000         true             1m
```

### Usar PriorityClass en Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: critical-app
spec:
  priorityClassName: high-priority
  containers:
  - name: app
    image: critical-app:latest
    resources:
      requests:
        cpu: "1"
        memory: "2Gi"
```

### Preemption en Acción

```bash
# Escenario: Cluster con 4 CPU totales

# 1. Crear pods low-priority que consumen todo
kubectl run low-1 --image=nginx --requests=cpu=2 --priority-class-name=low-priority
kubectl run low-2 --image=nginx --requests=cpu=2 --priority-class-name=low-priority

# 2. Crear pod high-priority que necesita 2 CPU
kubectl run critical --image=nginx --requests=cpu=2 --priority-class-name=high-priority

# Resultado:
# - low-1 o low-2 es evicted (preempted)
# - critical schedules exitosamente

# Ver events
kubectl get events --sort-by='.lastTimestamp' | grep -i preempt
```

**⚠️ Consideraciones:**
- Preemption puede causar disrupciones
- Usar PodDisruptionBudgets para proteger apps
- System priority classes (2000000000+) reservadas para sistema
- No abusar de high priority (todo no puede ser crítico)

---

## 🎨 Scheduler Profiles

### ¿Qué son Scheduler Profiles?

Configuraciones personalizadas del scheduler para diferentes workloads.

```yaml
apiVersion: kubescheduler.config.k8s.io/v1beta3
kind: KubeSchedulerConfiguration
profiles:
# Profile 1: Default (balance general)
- schedulerName: default-scheduler
  plugins:
    score:
      enabled:
      - name: NodeResourcesBalancedAllocation
        weight: 1
      - name: NodeResourcesLeastAllocated
        weight: 1

# Profile 2: Bin packing (máxima densidad)
- schedulerName: bin-packer
  plugins:
    score:
      enabled:
      - name: NodeResourcesMostAllocated
        weight: 5
      disabled:
      - name: NodeResourcesBalancedAllocation

# Profile 3: Spread (máximo spreading)
- schedulerName: spread-scheduler
  plugins:
    score:
      enabled:
      - name: PodTopologySpread
        weight: 10
      - name: NodeResourcesBalancedAllocation
        weight: 5
```

### Usar Scheduler Personalizado

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: packed-pod
spec:
  schedulerName: bin-packer  # Usar scheduler custom
  containers:
  - name: app
    image: myapp
```

**🎯 Casos de uso:**
- **Bin packing:** Minimizar número de nodos (cost optimization)
- **Spreading:** Maximizar distribución (high availability)
- **GPU scheduling:** Lógica especializada para GPUs
- **Multi-tenancy:** Diferentes políticas por tenant

---

## 🐛 Troubleshooting

### Pod en estado Pending

```bash
# Ver por qué no schedules
kubectl describe pod <pod-name>

# Buscar en Events:
# - "0/3 nodes are available: 3 Insufficient cpu"
#   → Cluster sin recursos

# - "0/3 nodes are available: 3 node(s) had taint {key=value:NoSchedule}"
#   → Falta toleration

# - "0/3 nodes are available: 3 node(s) didn't match Pod's node affinity"
#   → Node affinity no cumplida

# - "0/3 nodes are available: 3 node(s) didn't match pod anti-affinity rules"
#   → Anti-affinity bloqueando
```

### Debugging Node Affinity

```bash
# Ver labels de nodos
kubectl get nodes --show-labels

# Ver si nodo cumple affinity
kubectl get nodes -l disktype=ssd

# Añadir label faltante
kubectl label nodes worker-01 disktype=ssd
```

### Debugging Taints

```bash
# Ver taints de todos los nodos
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Describir nodo específico
kubectl describe node worker-01 | grep -A 5 Taints

# Remover taint
kubectl taint nodes worker-01 gpu=true:NoSchedule-
```

### Verificar Resource Quotas

```bash
# Ver si namespace tiene quota excedida
kubectl describe resourcequota -n <namespace>

# Ver LimitRanges
kubectl describe limitrange -n <namespace>

# Si pod rechazado por quota:
# Error: "exceeded quota: compute-quota, requested: requests.cpu=2, used: requests.cpu=9, limited: requests.cpu=10"
```

---

## 📚 Referencias

- [Scheduling Framework](https://kubernetes.io/docs/concepts/scheduling-eviction/scheduling-framework/)
- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)

---

## 🎯 Próximos Pasos

1. **Práctica**: Completar laboratorios de este módulo
2. **Experimentación**: Combinar affinity + taints + priorities
3. **Monitoring**: Ver scheduling decisions con `kubectl describe`
4. **Avanzar**: Continuar con [Módulo 25: Networking Deep Dive](../modulo-25-networking/)

---

**Ver también:**
- [Laboratorios](./laboratorios/README.md) - 4 labs prácticos
- [Ejemplos](./ejemplos/README.md) - YAMLs y configs
- [RESUMEN](./RESUMEN-MODULO.md) - Cheatsheet de comandos

**🎯 CKA Coverage:** Este módulo cubre ~15% del examen CKA (Workloads & Scheduling).
