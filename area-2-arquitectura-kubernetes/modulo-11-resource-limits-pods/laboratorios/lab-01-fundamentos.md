# Laboratorio 01: Fundamentos de Resource Limits

## 📋 Información General

- **Duración estimada**: 35-40 minutos
- **Dificultad**: ⭐ Básico
- **Objetivo**: Comprender requests, limits y QoS classes
- **Requisitos**:
  - Cluster Kubernetes 1.28+
  - `kubectl` configurado
  - `metrics-server` instalado
  - Permisos para crear Pods y Deployments

---

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

1. ✅ Configurar requests y limits para CPU y memoria
2. ✅ Entender la diferencia entre requests y limits
3. ✅ Identificar las 3 QoS Classes (Guaranteed, Burstable, BestEffort)
4. ✅ Usar `kubectl top` para monitorear recursos
5. ✅ Predecir el comportamiento del scheduler basado en requests
6. ✅ Observar el comportamiento bajo presión de recursos

---

## 📚 Contexto Teórico

### Requests vs Limits

```
┌──────────────────────────────────────────────┐
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │         LIMIT (tope máximo)         │    │
│  │   500m CPU  /  512Mi Memory         │    │
│  └─────────────────────────────────────┘    │
│              ▲                               │
│              │  Puede usar HASTA el límite   │
│              │                               │
│  ┌───────────┴────────────────────────┐     │
│  │   REQUEST (reserva garantizada)    │     │
│  │   200m CPU  /  256Mi Memory        │     │
│  └────────────────────────────────────┘     │
│              ▲                               │
│              │  SIEMPRE disponible           │
│                                              │
└──────────────────────────────────────────────┘
```

**Request**: Lo que el scheduler GARANTIZA que estará disponible.  
**Limit**: El máximo que puede usar (enforcement por kernel).

### QoS Classes

| QoS Class | Condición | Prioridad Eviction | Uso |
|-----------|-----------|-------------------|-----|
| **Guaranteed** | `request == limit` (todos los contenedores) | Máxima (se evicted último) | Producción crítica |
| **Burstable** | Tiene requests pero `request < limit` o solo requests | Media | Apps con tráfico variable |
| **BestEffort** | Sin requests ni limits | Mínima (se evicted primero) | Batch jobs no críticos |

---

## 🧪 Ejercicio 1: Crear Pod con Requests y Limits

### Paso 1.1: Crear Pod Básico

Crea un archivo `pod-basic.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-basic
  labels:
    lab: fundamentos
    exercise: "1"
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    resources:
      requests:
        cpu: "200m"        # Reserva garantizada
        memory: "128Mi"
      limits:
        cpu: "500m"        # Máximo permitido
        memory: "256Mi"
```

Aplica el manifiesto:

```bash
kubectl apply -f pod-basic.yaml
```

### Paso 1.2: Verificar el Pod

```bash
# Ver estado
kubectl get pod app-basic

# Ver QoS Class
kubectl get pod app-basic -o jsonpath='{.status.qosClass}'
# Salida esperada: Burstable
```

**❓ ¿Por qué es Burstable?**

<details>
<summary>Respuesta</summary>

Porque tiene requests **diferentes** de limits:
- CPU: `200m < 500m`
- Memory: `128Mi < 256Mi`

Para ser Guaranteed, necesitaría `request == limit` en ambos.
</details>

### Paso 1.3: Ver Recursos Asignados

```bash
kubectl describe pod app-basic | grep -A 10 "Requests"
```

Salida esperada:

```
Requests:
  cpu:        200m
  memory:     128Mi
Limits:
  cpu:        500m
  memory:     256Mi
```

### Paso 1.4: Monitorear Uso de Recursos

```bash
# Instalar metrics-server si no lo tienes
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Ver uso actual
kubectl top pod app-basic
```

Salida esperada:

```
NAME        CPU(cores)   MEMORY(bytes)
app-basic   2m           10Mi
```

**📊 Análisis**:
- **Request CPU**: 200m → **Uso real**: ~2m (solo 1%)
- **Request Memory**: 128Mi → **Uso real**: ~10Mi (solo 8%)
- Hay **over-provisioning**, pero está bien para absorber picos de tráfico.

---

## 🧪 Ejercicio 2: Comparar las 3 QoS Classes

### Paso 2.1: Crear 3 Pods con diferentes QoS

Crea `qos-comparison.yaml`:

```yaml
---
# Pod 1: QoS Guaranteed
apiVersion: v1
kind: Pod
metadata:
  name: qos-guaranteed
  labels:
    lab: fundamentos
    exercise: "2"
    qos: guaranteed
spec:
  containers:
  - name: app
    image: nginx:1.25
    resources:
      requests:
        cpu: "500m"
        memory: "256Mi"
      limits:
        cpu: "500m"       # ← Igual a request
        memory: "256Mi"   # ← Igual a request

---
# Pod 2: QoS Burstable
apiVersion: v1
kind: Pod
metadata:
  name: qos-burstable
  labels:
    lab: fundamentos
    exercise: "2"
    qos: burstable
spec:
  containers:
  - name: app
    image: nginx:1.25
    resources:
      requests:
        cpu: "200m"
        memory: "128Mi"
      limits:
        cpu: "1"          # ← Mayor que request
        memory: "512Mi"   # ← Mayor que request

---
# Pod 3: QoS BestEffort
apiVersion: v1
kind: Pod
metadata:
  name: qos-besteffort
  labels:
    lab: fundamentos
    exercise: "2"
    qos: besteffort
spec:
  containers:
  - name: app
    image: nginx:1.25
    # Sin resources definidos
```

Aplica:

```bash
kubectl apply -f qos-comparison.yaml
```

### Paso 2.2: Verificar QoS Classes

```bash
kubectl get pods -l exercise="2" -o custom-columns=\
NAME:.metadata.name,\
QoS:.status.qosClass,\
CPU_REQ:.spec.containers[0].resources.requests.cpu,\
CPU_LIM:.spec.containers[0].resources.limits.cpu,\
MEM_REQ:.spec.containers[0].resources.requests.memory,\
MEM_LIM:.spec.containers[0].resources.limits.memory
```

Salida esperada:

```
NAME              QoS         CPU_REQ   CPU_LIM   MEM_REQ   MEM_LIM
qos-guaranteed    Guaranteed  500m      500m      256Mi     256Mi
qos-burstable     Burstable   200m      1         128Mi     512Mi
qos-besteffort    BestEffort  <none>    <none>    <none>    <none>
```

### Paso 2.3: Ver Prioridad de Eviction

```bash
kubectl get pods -l exercise="2" -o custom-columns=\
NAME:.metadata.name,\
QoS:.status.qosClass,\
PRIORITY:.spec.priority | \
sort -k2
```

**📊 Orden de Eviction** (cuando el nodo tiene presión de recursos):

```
1. qos-besteffort   ◄── Se evicted PRIMERO
2. qos-burstable    ◄── Prioridad media
3. qos-guaranteed   ◄── Se evicted ÚLTIMO (máxima protección)
```

---

## 🧪 Ejercicio 3: Scheduler y Requests

### Paso 3.1: Ver Capacidad del Nodo

```bash
kubectl describe node | grep -A 10 "Allocatable:"
```

Salida ejemplo:

```
Allocatable:
  cpu:                4
  memory:             8Gi
  pods:               110
```

### Paso 3.2: Ver Recursos Asignados

```bash
kubectl describe node | grep -A 10 "Allocated resources:"
```

Salida ejemplo:

```
Allocated resources:
  Resource           Requests      Limits
  --------           --------      ------
  cpu                1200m (30%)   3500m (87%)
  memory             2Gi (25%)     6Gi (75%)
```

**🔍 Análisis Importante**:

- El scheduler SOLO usa **Requests** para decidir dónde colocar Pods.
- Los **Limits** NO afectan al scheduler (pueden sumar >100%).

### Paso 3.3: Crear Deployment que Llene el Nodo

Crea `fill-node.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fill-node
  labels:
    lab: fundamentos
    exercise: "3"
spec:
  replicas: 10
  selector:
    matchLabels:
      app: filler
  template:
    metadata:
      labels:
        app: filler
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        resources:
          requests:
            cpu: "300m"
            memory: "256Mi"
          limits:
            cpu: "1"
            memory: "512Mi"
```

Aplica:

```bash
kubectl apply -f fill-node.yaml
```

### Paso 3.4: Observar Comportamiento del Scheduler

```bash
# Ver cuántos Pods se crearon
kubectl get pods -l app=filler

# Ver eventos
kubectl get events --field-selector involvedObject.name=fill-node --sort-by='.lastTimestamp'
```

**❓ ¿Qué pasa si la suma de requests excede la capacidad del nodo?**

<details>
<summary>Respuesta</summary>

El scheduler NO puede colocar más Pods:

```bash
kubectl get pods -l app=filler | grep Pending

# Ver razón
kubectl describe pod <pending-pod-name>
# Events:
#   Warning  FailedScheduling  ... 0/3 nodes are available: 3 Insufficient cpu.
```

Los Pods quedan en **Pending** hasta que se liberen recursos o se agreguen nodos.
</details>

---

## 🧪 Ejercicio 4: Multi-Container Resources

### Paso 4.1: Crear Pod con Múltiples Contenedores

Crea `multi-container.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-app
  labels:
    lab: fundamentos
    exercise: "4"
spec:
  containers:
  # Contenedor principal
  - name: app
    image: nginx:1.25
    resources:
      requests:
        cpu: "300m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
  
  # Sidecar 1: logging
  - name: logger
    image: busybox:1.36
    command: ['sh', '-c', 'tail -f /dev/null']
    resources:
      requests:
        cpu: "100m"
        memory: "64Mi"
      limits:
        cpu: "200m"
        memory: "128Mi"
  
  # Sidecar 2: metrics
  - name: metrics
    image: busybox:1.36
    command: ['sh', '-c', 'tail -f /dev/null']
    resources:
      requests:
        cpu: "100m"
        memory: "64Mi"
      limits:
        cpu: "200m"
        memory: "128Mi"
```

Aplica:

```bash
kubectl apply -f multi-container.yaml
```

### Paso 4.2: Calcular Recursos Totales del Pod

```bash
kubectl describe pod multi-container-app | grep -A 15 "Containers:"
```

**📊 Cálculo de Recursos Totales**:

| Contenedor | CPU Request | CPU Limit | Mem Request | Mem Limit |
|-----------|-------------|-----------|-------------|-----------|
| app       | 300m        | 500m      | 256Mi       | 512Mi     |
| logger    | 100m        | 200m      | 64Mi        | 128Mi     |
| metrics   | 100m        | 200m      | 64Mi        | 128Mi     |
| **TOTAL** | **500m**    | **900m**  | **384Mi**   | **768Mi** |

**❓ ¿Qué QoS Class tiene este Pod?**

<details>
<summary>Respuesta</summary>

```bash
kubectl get pod multi-container-app -o jsonpath='{.status.qosClass}'
# Salida: Burstable
```

Porque todos los contenedores tienen `request < limit`.
</details>

### Paso 4.3: Ver Uso por Contenedor

```bash
kubectl top pod multi-container-app --containers
```

Salida esperada:

```
POD                    NAME      CPU(cores)   MEMORY(bytes)
multi-container-app    app       3m           12Mi
multi-container-app    logger    0m           1Mi
multi-container-app    metrics   0m           1Mi
```

---

## 🧪 Ejercicio 5: Init Containers y Recursos

### Paso 5.1: Crear Pod con Init Container

Crea `init-container.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-container-demo
  labels:
    lab: fundamentos
    exercise: "5"
spec:
  initContainers:
  - name: init-db
    image: busybox:1.36
    command: ['sh', '-c', 'sleep 10']
    resources:
      requests:
        cpu: "500m"       # ← Init container pide MUCHO
        memory: "512Mi"
      limits:
        cpu: "1"
        memory: "1Gi"
  
  containers:
  - name: app
    image: nginx:1.25
    resources:
      requests:
        cpu: "200m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "256Mi"
```

Aplica:

```bash
kubectl apply -f init-container.yaml
```

### Paso 5.2: Entender la Regla del Máximo

```bash
kubectl describe pod init-container-demo | grep -A 10 "Init Containers"
```

**📊 Regla del Máximo** (para calcular requests del Pod):

```
Pod Request CPU = MAX(
  Sum(all app containers),     ← 200m
  MAX(all init containers)     ← 500m  ◄── GANA
)

Pod Request CPU = 500m
```

**Por qué**: Init containers se ejecutan **secuencialmente** y solo uno a la vez, así que solo necesitas reservar el más grande.

**❓ ¿Qué pasa cuando el init container termina?**

<details>
<summary>Respuesta</summary>

Los recursos del init container **se liberan** y solo quedan los del app container:

```bash
kubectl top pod init-container-demo
# CPU: ~2m (solo app container)
```

El scheduler reservó 500m inicialmente, pero después de que init-db termina, solo se usan los 200m del app container.
</details>

---

## 🧪 Ejercicio 6: Monitoreo con kubectl top

### Paso 6.1: Ver Uso de Todos los Pods

```bash
kubectl top pods -l lab=fundamentos
```

Salida ejemplo:

```
NAME                    CPU(cores)   MEMORY(bytes)
app-basic               2m           10Mi
qos-guaranteed          3m           12Mi
qos-burstable           2m           9Mi
qos-besteffort          2m           8Mi
multi-container-app     3m           14Mi
```

### Paso 6.2: Ver Uso de Todos los Nodos

```bash
kubectl top nodes
```

Salida ejemplo:

```
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   450m         11%    2Gi             25%
```

### Paso 6.3: Ver Recursos por Namespace

```bash
kubectl top pods --all-namespaces | head -20
```

---

## 🧪 Ejercicio 7: Cleanup y Análisis Final

### Paso 7.1: Ver Todos los Recursos Creados

```bash
kubectl get pods -l lab=fundamentos -o custom-columns=\
NAME:.metadata.name,\
QoS:.status.qosClass,\
STATUS:.status.phase,\
AGE:.metadata.creationTimestamp
```

### Paso 7.2: Limpiar Recursos

```bash
# Limpiar por label
kubectl delete pods,deployments -l lab=fundamentos

# Verificar
kubectl get pods -l lab=fundamentos
# No resources found
```

### Paso 7.3: Verificar Liberación de Recursos

```bash
kubectl describe node | grep -A 10 "Allocated resources:"
```

Deberías ver que los recursos allocated disminuyeron.

---

## 📊 Resumen de Conceptos Aprendidos

### 1. Requests vs Limits

| Aspecto | Request | Limit |
|---------|---------|-------|
| **Propósito** | Garantía mínima | Tope máximo |
| **Usado por** | Scheduler (placement) | Kernel (enforcement) |
| **Enforcement** | NO (solo scheduler) | SÍ (CPU throttling, OOM) |
| **Puede faltar** | ⚠️ Malo (BestEffort) | ✅ OK (solo requests) |

### 2. QoS Classes

```
┌─────────────────────────────────────────────┐
│  Guaranteed (request == limit)              │
│  - Máxima protección contra eviction       │
│  - Uso: Producción crítica                 │
│  - Ejemplo: Bases de datos                 │
└─────────────────────────────────────────────┘
            ▲
            │
┌───────────┴─────────────────────────────────┐
│  Burstable (request < limit)                │
│  - Balance flexibilidad/protección          │
│  - Uso: Apps web con tráfico variable      │
│  - Ejemplo: APIs REST                       │
└─────────────────────────────────────────────┘
            ▲
            │
┌───────────┴─────────────────────────────────┐
│  BestEffort (sin resources)                 │
│  - Mínima protección (se evicted primero)   │
│  - Uso: Batch jobs no críticos              │
│  - Ejemplo: Procesamiento offline           │
└─────────────────────────────────────────────┘
```

### 3. Multi-Container Resources

- **Total Pod Request** = Sum(all app containers)
- **Total Pod Limit** = Sum(all app containers)
- **Init containers**: Regla del máximo (solo el más grande)
- **QoS Class**: Se calcula con TODOS los contenedores (app + init)

### 4. Scheduler Behavior

- ✅ Usa **solo requests** para placement
- ❌ NO considera limits
- Puede colocar Pods donde `sum(limits) > 100%` del nodo
- Si `sum(requests) > allocatable` → Pod queda **Pending**

---

## 🎓 Verificación de Conocimientos

### Quiz Final

**1. ¿Qué QoS Class tiene este Pod?**

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"  # ← Diferente de request
```

<details>
<summary>Respuesta</summary>

**Burstable**

Aunque CPU tiene `request == limit`, la memoria tiene `request < limit`, por lo que el Pod completo es Burstable.

Para ser Guaranteed, **todos** los recursos deben tener `request == limit`.
</details>

---

**2. ¿Cuál es el request total de CPU de este Pod?**

```yaml
initContainers:
- name: init
  resources:
    requests:
      cpu: "1"

containers:
- name: app1
  resources:
    requests:
      cpu: "300m"
- name: app2
  resources:
    requests:
      cpu: "200m"
```

<details>
<summary>Respuesta</summary>

**1 CPU** (del init container)

Regla del máximo:
- `MAX(init containers) = 1`
- `SUM(app containers) = 300m + 200m = 500m`
- `Pod Request = MAX(1, 500m) = 1`
</details>

---

**3. ¿Este Pod puede ser scheduled en un nodo con 800m CPU allocatable?**

```yaml
resources:
  requests:
    cpu: "900m"
  limits:
    cpu: "2"
```

<details>
<summary>Respuesta</summary>

**NO**

El scheduler usa **requests**, no limits.

- Request: 900m
- Allocatable: 800m
- 900m > 800m → **Pod queda Pending**

El límite de 2 CPUs NO importa para scheduling.
</details>

---

## 📚 Próximos Pasos

Ahora que dominas los fundamentos, continúa con:

1. **[Laboratorio 02: Troubleshooting](./lab-02-troubleshooting.md)**: OOMKilled, CPU throttling, eviction
2. **[Laboratorio 03: Producción](./lab-03-produccion.md)**: Best practices, VPA, HPA, Prometheus

---

## 📖 Referencias

- **[README Principal](../README.md)**: Documentación completa
- **[Ejemplos Básicos](../ejemplos/01-basico/)**: Manifiestos de referencia
- **[Ejemplos QoS](../ejemplos/02-qos/)**: QoS Classes en detalle
- **[Kubernetes Docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)**: Documentación oficial

---

**¡Felicidades!** 🎉 Has completado el laboratorio de fundamentos de Resource Limits.
