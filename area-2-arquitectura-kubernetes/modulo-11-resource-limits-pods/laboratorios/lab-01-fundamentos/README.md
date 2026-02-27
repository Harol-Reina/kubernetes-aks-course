# Laboratorio 01: Fundamentos de Resource Limits

**Duracion estimada:** 35-40 minutos
**Nivel:** Basico
**Objetivo:** Comprender requests, limits y QoS classes en Kubernetes

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Resource Requests** | Cantidad de CPU/memoria que el scheduler garantiza al Pod. Determina el placement en el nodo |
| **Resource Limits** | Tope maximo que el kernel enforce: CPU throttling si se excede, OOM kill si la memoria supera el limit |
| **QoS Guaranteed** | Pod con request == limit en todos los contenedores. Maxima proteccion contra eviction |
| **QoS Burstable** | Pod con requests definidos pero request < limit. Balance entre flexibilidad y proteccion |
| **QoS BestEffort** | Pod sin resources definidos. Se evicted primero bajo presion de recursos |
| **Multi-Container Resources** | Total del Pod = suma de requests/limits de todos los contenedores app |
| **Init Container Max Rule** | Pod Request = MAX(suma app containers, mayor init container). Init containers no se acumulan |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `pod-basic.yaml` | 1 | Pod nginx con requests y limits explicitos (QoS Burstable) |
| `qos-comparison.yaml` | 2 | Tres Pods representando las 3 QoS Classes distintas |
| `fill-node.yaml` | 3 | Deployment de 10 replicas para observar el scheduler con requests altos |
| `multi-container.yaml` | 4 | Pod con contenedor principal y dos sidecars con resources independientes |
| `init-container.yaml` | 5 | Pod con init container que pide mas recursos que el app container |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Requisitos Previos

- Cluster de Kubernetes funcional (minikube, kind, k3s, o cloud)
- kubectl configurado
- metrics-server habilitado (para `kubectl top`)
- Conocimientos basicos de Pods y Deployments (modulos 03-05)

Consulta [SETUP.md](./SETUP.md) para instrucciones detalladas de verificacion del entorno.

### Verificacion rapida del entorno

```bash
# Verificar cluster
kubectl cluster-info

# Verificar nodos
kubectl get nodes

# Verificar metrics-server
kubectl top nodes

# Verificar archivos YAML del laboratorio
ls *.yaml
```

---

## Contexto Teorico

### Requests vs Limits

```
+----------------------------------------------+
|                                              |
|  +-------------------------------------+     |
|  |         LIMIT (tope maximo)         |     |
|  |   500m CPU  /  512Mi Memory         |     |
|  +-------------------------------------+     |
|              ^                               |
|              |  Puede usar HASTA el limite   |
|              |                               |
|  +-----------+-----------------------------+ |
|  |   REQUEST (reserva garantizada)         | |
|  |   200m CPU  /  256Mi Memory             | |
|  +-----------------------------------------+ |
|              ^                               |
|              |  SIEMPRE disponible           |
|                                              |
+----------------------------------------------+
```

**Request**: Lo que el scheduler GARANTIZA que estara disponible.
**Limit**: El maximo que puede usar (enforcement por kernel).

### QoS Classes

| QoS Class | Condicion | Prioridad Eviction | Uso |
|-----------|-----------|-------------------|-----|
| **Guaranteed** | `request == limit` (todos los contenedores) | Maxima (se evicted ultimo) | Produccion critica |
| **Burstable** | Tiene requests pero `request < limit` o solo requests | Media | Apps con trafico variable |
| **BestEffort** | Sin requests ni limits | Minima (se evicted primero) | Batch jobs no criticos |

---

## Ejercicio 1: Crear Pod con Requests y Limits

### Paso 1.1: Revisar el manifiesto

Revisa el archivo `pod-basic.yaml`:

```bash
cat pod-basic.yaml
```

Puntos clave del manifiesto:
- **requests.cpu: 200m** — el scheduler garantiza 200 milliCPU en el nodo elegido
- **limits.cpu: 500m** — el kernel limita el CPU a 500m (throttling si se excede)
- **requests.memory: 128Mi** — reserva de memoria garantizada
- **limits.memory: 256Mi** — si el proceso supera este valor el kernel lo termina (OOM)
- Como `request < limit`, la QoS Class sera **Burstable**

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

**Por que es Burstable?**

<details>
<summary>Respuesta</summary>

Porque tiene requests **diferentes** de limits:
- CPU: `200m < 500m`
- Memory: `128Mi < 256Mi`

Para ser Guaranteed, necesitaria `request == limit` en ambos.
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
# Ver uso actual
kubectl top pod app-basic
```

Salida esperada:

```
NAME        CPU(cores)   MEMORY(bytes)
app-basic   2m           10Mi
```

**Analisis**:
- **Request CPU**: 200m -> **Uso real**: ~2m (solo 1%)
- **Request Memory**: 128Mi -> **Uso real**: ~10Mi (solo 8%)
- Hay **over-provisioning**, pero esta bien para absorber picos de trafico.

---

## Ejercicio 2: Comparar las 3 QoS Classes

### Paso 2.1: Revisar y aplicar los 3 Pods

Revisa el archivo `qos-comparison.yaml`:

```bash
cat qos-comparison.yaml
```

Puntos clave del manifiesto:
- **qos-guaranteed**: CPU y memoria con `request == limit` en ambos -> Guaranteed
- **qos-burstable**: `request < limit` en CPU y memoria -> Burstable
- **qos-besteffort**: sin seccion `resources` definida -> BestEffort

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

**Orden de Eviction** (cuando el nodo tiene presion de recursos):

```
1. qos-besteffort   <-- Se evicted PRIMERO
2. qos-burstable    <-- Prioridad media
3. qos-guaranteed   <-- Se evicted ULTIMO (maxima proteccion)
```

---

## Ejercicio 3: Scheduler y Requests

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

**Analisis Importante**:

- El scheduler SOLO usa **Requests** para decidir donde colocar Pods.
- Los **Limits** NO afectan al scheduler (pueden sumar >100%).

### Paso 3.3: Revisar y aplicar el Deployment

Revisa el archivo `fill-node.yaml`:

```bash
cat fill-node.yaml
```

Puntos clave del manifiesto:
- **10 replicas** con 300m CPU request cada una: sum = 3000m de CPU solo en requests
- Si el nodo tiene menos de 3000m allocatable, algunos Pods quedaran en Pending
- Los limits (1 CPU por Pod) no afectan al scheduler

```bash
kubectl apply -f fill-node.yaml
```

### Paso 3.4: Observar Comportamiento del Scheduler

```bash
# Ver cuantos Pods se crearon vs cuantos quedaron Pending
kubectl get pods -l app=filler

# Ver eventos del Deployment
kubectl get events --field-selector involvedObject.name=fill-node --sort-by='.lastTimestamp'
```

**Que pasa si la suma de requests excede la capacidad del nodo?**

<details>
<summary>Respuesta</summary>

El scheduler NO puede colocar mas Pods:

```bash
kubectl get pods -l app=filler | grep Pending

# Ver razon en el Pod en Pending
kubectl describe pod <pending-pod-name>
# Events:
#   Warning  FailedScheduling  ... 0/3 nodes are available: 3 Insufficient cpu.
```

Los Pods quedan en **Pending** hasta que se liberen recursos o se agreguen nodos.
</details>

---

## Ejercicio 4: Multi-Container Resources

### Paso 4.1: Revisar y aplicar el Pod

Revisa el archivo `multi-container.yaml`:

```bash
cat multi-container.yaml
```

Puntos clave del manifiesto:
- **app**: contenedor principal con 300m/500m CPU y 256Mi/512Mi memoria
- **logger**: sidecar con 100m/200m CPU y 64Mi/128Mi memoria
- **metrics**: sidecar con 100m/200m CPU y 64Mi/128Mi memoria
- El total del Pod es la suma de los tres contenedores

```bash
kubectl apply -f multi-container.yaml
```

### Paso 4.2: Calcular Recursos Totales del Pod

```bash
kubectl describe pod multi-container-app | grep -A 15 "Containers:"
```

**Calculo de Recursos Totales**:

| Contenedor | CPU Request | CPU Limit | Mem Request | Mem Limit |
|-----------|-------------|-----------|-------------|-----------|
| app       | 300m        | 500m      | 256Mi       | 512Mi     |
| logger    | 100m        | 200m      | 64Mi        | 128Mi     |
| metrics   | 100m        | 200m      | 64Mi        | 128Mi     |
| **TOTAL** | **500m**    | **900m**  | **384Mi**   | **768Mi** |

**Que QoS Class tiene este Pod?**

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

## Ejercicio 5: Init Containers y Recursos

### Paso 5.1: Revisar y aplicar el Pod

Revisa el archivo `init-container.yaml`:

```bash
cat init-container.yaml
```

Puntos clave del manifiesto:
- **init-db**: init container que duerme 10 segundos y pide 500m CPU / 512Mi memoria
- **app**: contenedor principal con solo 200m CPU / 128Mi memoria
- El scheduler reserva el MAX entre ambos: 500m CPU (del init container gana)

```bash
kubectl apply -f init-container.yaml
```

### Paso 5.2: Entender la Regla del Maximo

```bash
kubectl describe pod init-container-demo | grep -A 10 "Init Containers"
```

**Regla del Maximo** (para calcular requests del Pod):

```
Pod Request CPU = MAX(
  Sum(all app containers),     <- 200m
  MAX(all init containers)     <- 500m  <-- GANA
)

Pod Request CPU = 500m
```

**Por que**: Init containers se ejecutan **secuencialmente** y solo uno a la vez,
asi que solo necesitas reservar el mas grande.

**Que pasa cuando el init container termina?**

<details>
<summary>Respuesta</summary>

Los recursos del init container **se liberan** y solo quedan los del app container:

```bash
kubectl top pod init-container-demo
# CPU: ~2m (solo app container)
```

El scheduler reservo 500m inicialmente, pero despues de que init-db termina,
solo se usan los 200m del app container.
</details>

---

## Ejercicio 6: Monitoreo con kubectl top

### Paso 6.1: Ver Uso de Todos los Pods del Lab

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

## Ejercicio 7: Cleanup y Analisis Final

### Paso 7.1: Ver Todos los Recursos Creados

```bash
kubectl get pods -l lab=fundamentos -o custom-columns=\
NAME:.metadata.name,\
QoS:.status.qosClass,\
STATUS:.status.phase,\
AGE:.metadata.creationTimestamp
```

### Paso 7.2: Ver Recursos Asignados Antes de Limpiar

```bash
kubectl describe node | grep -A 10 "Allocated resources:"
```

Anota los valores actuales. Despues de limpiar, los recursos allocated disminuiran.

### Paso 7.3: Limpiar con el Script

```bash
chmod +x cleanup.sh
./cleanup.sh
```

### Paso 7.4: Verificar Liberacion de Recursos

```bash
kubectl describe node | grep -A 10 "Allocated resources:"
```

Deberias ver que los recursos allocated disminuyeron respecto a los valores anotados en 7.2.

---

## Resumen de Conceptos Aprendidos

### 1. Requests vs Limits

| Aspecto | Request | Limit |
|---------|---------|-------|
| **Proposito** | Garantia minima | Tope maximo |
| **Usado por** | Scheduler (placement) | Kernel (enforcement) |
| **Enforcement** | NO (solo scheduler) | SI (CPU throttling, OOM) |
| **Puede faltar** | Malo (BestEffort) | OK (solo requests) |

### 2. QoS Classes

```
+-----------------------------------------+
|  Guaranteed (request == limit)          |
|  - Maxima proteccion contra eviction    |
|  - Uso: Produccion critica              |
|  - Ejemplo: Bases de datos              |
+-----------------------------------------+
            ^
            |
+-----------+-----------------------------+
|  Burstable (request < limit)            |
|  - Balance flexibilidad/proteccion      |
|  - Uso: Apps web con trafico variable   |
|  - Ejemplo: APIs REST                   |
+-----------------------------------------+
            ^
            |
+-----------+-----------------------------+
|  BestEffort (sin resources)             |
|  - Minima proteccion (evicted primero)  |
|  - Uso: Batch jobs no criticos          |
|  - Ejemplo: Procesamiento offline       |
+-----------------------------------------+
```

### 3. Multi-Container Resources

- **Total Pod Request** = Sum(all app containers)
- **Total Pod Limit** = Sum(all app containers)
- **Init containers**: Regla del maximo (solo el mas grande)
- **QoS Class**: Se calcula con TODOS los contenedores (app + init)

### 4. Scheduler Behavior

- Usa **solo requests** para placement
- NO considera limits para scheduling
- Puede colocar Pods donde `sum(limits) > 100%` del nodo
- Si `sum(requests) > allocatable` -> Pod queda **Pending**

---

## Verificacion de Conocimientos

### Quiz Final

**1. Que QoS Class tiene este Pod?**

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"  # Diferente de request
```

<details>
<summary>Respuesta</summary>

**Burstable**

Aunque CPU tiene `request == limit`, la memoria tiene `request < limit`, por lo que
el Pod completo es Burstable.

Para ser Guaranteed, **todos** los recursos deben tener `request == limit`.
</details>

---

**2. Cual es el request total de CPU de este Pod?**

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

Regla del maximo:
- `MAX(init containers) = 1`
- `SUM(app containers) = 300m + 200m = 500m`
- `Pod Request = MAX(1, 500m) = 1`
</details>

---

**3. Este Pod puede ser scheduled en un nodo con 800m CPU allocatable?**

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
- 900m > 800m -> **Pod queda Pending**

El limite de 2 CPUs NO importa para scheduling.
</details>

---

## Limpieza

```bash
# Usar el script de limpieza
chmod +x cleanup.sh
./cleanup.sh
```

---

## Proximos Pasos

1. **Laboratorio 02: Troubleshooting** — OOMKilled, CPU throttling, eviction
2. **Laboratorio 03: Produccion** — Best practices, VPA, HPA, Prometheus

---

## Referencias

- **[README Principal](../../README.md)**: Documentacion completa del modulo
- **[Guia de Ejemplos](../../ejemplos/README.md)**: Catalogo completo de ejemplos organizados
- **[Ejemplos Fundamentos](../../ejemplos/)**:
  - [01-requests-limits-basico](../../ejemplos/01-requests-limits-basico/)
  - [02-multi-container](../../ejemplos/02-multi-container/)
  - [03-init-containers](../../ejemplos/03-init-containers/)
- **[Ejemplos QoS](../../ejemplos/)**:
  - [07-qos-guaranteed](../../ejemplos/07-qos-guaranteed/)
  - [08-qos-burstable](../../ejemplos/08-qos-burstable/)
  - [09-qos-besteffort](../../ejemplos/09-qos-besteffort/)
- **[Kubernetes Docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)**: Documentacion oficial

---

**Felicidades!** Has completado el Laboratorio 01.
Tienes las bases solidas para trabajar con Resource Limits en Kubernetes.
