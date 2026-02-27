# Resumen Practico: Resource Limits en Pods

**Duracion:** 15 minutos | **Nivel:** Repaso integral | **Archivo:** `resources-lab.yaml`

Un solo YAML despliega Pods con las 3 QoS classes, un Deployment con resource limits, un Pod multi-container con sidecars, y un Pod con init container para practicar todos los conceptos de resource management de un vistazo, usando Minikube.

---

## Que son los Resource Limits

Los **Resource Limits** en Kubernetes controlan cuanta CPU y memoria puede usar cada contenedor. Se dividen en dos conceptos:

- **Requests**: Garantia minima que el scheduler reserva para el Pod. Determina en que nodo se coloca.
- **Limits**: Tope maximo que el kernel permite. CPU se throttlea, memoria causa OOMKilled.

```
Pod con Resources
├── qos-guaranteed    → request == limit (maxima proteccion)
├── qos-burstable     → request < limit (puede usar mas si hay recursos)
├── qos-besteffort    → sin resources (minima proteccion, evicted primero)
├── webapp (3 rep.)   → Deployment con requests/limits por replica
├── multi-container   → 3 contenedores, recursos se suman
└── init-container    → Regla del maximo: MAX(init, sum(app))
```

---

## Conceptos Cubiertos en Este Lab

| Concepto | Que demuestra |
|----------|---------------|
| **Requests vs Limits** | Diferencia entre garantia del scheduler y tope del kernel |
| **QoS Guaranteed** | Pod con `request == limit` en todos los contenedores. Maxima proteccion |
| **QoS Burstable** | Pod con `request < limit`. Puede usar recursos extra si estan disponibles |
| **QoS BestEffort** | Pod sin resources definidos. Primero en ser evicted |
| **Multi-container resources** | Recursos totales = suma de todos los contenedores |
| **Init container resources** | Regla del maximo: `MAX(max_init, sum_app)` |
| **kubectl top** | Monitoreo de uso real de CPU y memoria por Pod |

---

## Diagrama Visual

```
                    ┌──────────────────────────────────────────┐
                    │         NAMESPACE: lab-resources          │
                    │                                          │
  ┌─────────────────┼──────────────────────────────────────────┤
  │ QoS Pods        │                                          │
  │                 │  qos-guaranteed  (CPU:200m/200m)         │
  │                 │  qos-burstable   (CPU:100m/500m)         │
  │                 │  qos-besteffort  (sin resources)         │
  ├─────────────────┼──────────────────────────────────────────┤
  │ Deployment      │                                          │
  │                 │  webapp (3 replicas, CPU:100m/300m)      │
  │                 │  Service webapp (ClusterIP:80)           │
  ├─────────────────┼──────────────────────────────────────────┤
  │ Multi-container │                                          │
  │                 │  multi-container-app                     │
  │                 │    app    (CPU:200m/400m, Mem:128/256Mi) │
  │                 │    logger (CPU:100m/200m, Mem:64/128Mi)  │
  │                 │    metrics(CPU:100m/200m, Mem:128/256Mi) │
  ├─────────────────┼──────────────────────────────────────────┤
  │ Init container  │                                          │
  │                 │  init-container-demo                     │
  │                 │    init: 500m CPU (se libera al terminar)│
  │                 │    app:  200m CPU (uso en estado estable)│
  └─────────────────┼──────────────────────────────────────────┤
                    └──────────────────────────────────────────┘
```

---

## Tabla Comparativa: QoS Classes

| QoS Class | Condicion | Prioridad Eviction | Caso de uso |
|-----------|-----------|-------------------|-------------|
| **Guaranteed** | `request == limit` en todos los contenedores | Maxima (ultimo en ser evicted) | Bases de datos, servicios criticos |
| **Burstable** | Tiene requests pero `request < limit` | Media | APIs REST, apps web |
| **BestEffort** | Sin requests ni limits definidos | Minima (primero en ser evicted) | Batch jobs, desarrollo |

---

## Paso 0: Preparar Minikube (2 min)

```bash
minikube start

# Habilitar metrics-server (necesario para kubectl top)
minikube addons enable metrics-server

# Verificar
minikube status
kubectl cluster-info
```

---

## Paso 1: Desplegar Todo (1 min)

```bash
kubectl apply -f resources-lab.yaml
```

Verificar:

```bash
# Ver namespace creado
kubectl get ns lab-resources --show-labels

# Ver todos los recursos
kubectl get all -n lab-resources
```

**Salida esperada:** 1 namespace, 3 Pods de QoS, 1 Deployment con 3 replicas, 1 Service, 1 Pod multi-container, 1 Pod con init container, 1 Pod de prueba.

---

## Paso 2: Explorar QoS Classes (3 min)

```bash
# Ver QoS de cada Pod
kubectl get pods -n lab-resources -l app=qos-demo -o custom-columns=\
NAME:.metadata.name,\
QoS:.status.qosClass,\
CPU_REQ:.spec.containers[0].resources.requests.cpu,\
CPU_LIM:.spec.containers[0].resources.limits.cpu,\
MEM_REQ:.spec.containers[0].resources.requests.memory,\
MEM_LIM:.spec.containers[0].resources.limits.memory
```

**Salida esperada:**

```
NAME              QoS          CPU_REQ   CPU_LIM   MEM_REQ   MEM_LIM
qos-guaranteed    Guaranteed   200m      200m      128Mi     128Mi
qos-burstable     Burstable    100m      500m      64Mi      256Mi
qos-besteffort    BestEffort   <none>    <none>    <none>    <none>
```

**Pregunta:** Si el nodo tiene presion de memoria, en que orden se eliminan?

1. `qos-besteffort` (primero)
2. `qos-burstable` (segundo)
3. `qos-guaranteed` (ultimo, maxima proteccion)

---

## Paso 3: Analizar Deployment con Limits (3 min)

```bash
# Ver Pods del Deployment
kubectl get pods -n lab-resources -l app=webapp -o wide

# Ver recursos asignados
kubectl describe deployment webapp -n lab-resources | grep -A 8 "Limits:"
```

**Salida esperada:**

```
    Limits:
      cpu:     300m
      memory:  128Mi
    Requests:
      cpu:        100m
      memory:     64Mi
```

```bash
# Ver uso real (esperar ~2 min despues del deploy para metricas)
kubectl top pods -n lab-resources -l app=webapp
```

**Salida esperada:**

```
NAME                     CPU(cores)   MEMORY(bytes)
webapp-abc123            2m           5Mi
webapp-def456            2m           5Mi
webapp-ghi789            2m           5Mi
```

**Analisis:** Cada replica usa ~2m de 100m request (2% utilizacion). Los limits de 300m permiten absorber picos.

---

## Paso 4: Multi-container Resources (2 min)

```bash
# Ver recursos por contenedor
kubectl top pod multi-container-app -n lab-resources --containers
```

**Salida esperada:**

```
POD                    NAME      CPU(cores)   MEMORY(bytes)
multi-container-app    app       2m           5Mi
multi-container-app    logger    0m           1Mi
multi-container-app    metrics   0m           1Mi
```

```bash
# Ver QoS class
kubectl get pod multi-container-app -n lab-resources -o jsonpath='{.status.qosClass}'
# Salida: Burstable (porque request < limit en todos)
```

**Calculo de recursos totales del Pod:**

| Contenedor | CPU Request | CPU Limit | Mem Request | Mem Limit |
|-----------|-------------|-----------|-------------|-----------|
| app       | 200m        | 400m      | 128Mi       | 256Mi     |
| logger    | 100m        | 200m      | 64Mi        | 128Mi     |
| metrics   | 100m        | 200m      | 128Mi       | 256Mi     |
| **TOTAL** | **400m**    | **800m**  | **320Mi**   | **640Mi** |

---

## Paso 5: Init Container y Regla del Maximo (2 min)

```bash
# Ver estado del Pod (init debe haber completado)
kubectl get pod init-container-demo -n lab-resources
```

**Salida esperada:**

```
NAME                  READY   STATUS    RESTARTS   AGE
init-container-demo   1/1     Running   0          2m
```

```bash
# Ver recursos
kubectl describe pod init-container-demo -n lab-resources | grep -A 5 "Init Containers:"
kubectl describe pod init-container-demo -n lab-resources | grep -A 5 "Containers:"
```

**Regla del maximo para scheduling:**

```
Pod Request CPU = MAX(
  max(init containers) = 500m,
  sum(app containers)  = 200m
) = 500m   <-- El scheduler reserva 500m

Pero despues de que init termina, solo se usan 200m.
```

---

## Paso 6: Ver Recursos del Nodo (2 min)

```bash
# Ver capacidad del nodo
kubectl describe node | grep -A 5 "Allocatable:"

# Ver recursos consumidos
kubectl describe node | grep -A 10 "Allocated resources:"
```

**Salida esperada (ejemplo):**

```
Allocated resources:
  Resource           Requests      Limits
  --------           --------      ------
  cpu                1250m (31%)   2100m (52%)
  memory             912Mi (11%)   1920Mi (24%)
```

**Observacion:** Los Requests determinan scheduling. Los Limits pueden sumar mas del 100% del nodo (overcommit).

---

## Paso 7: Limpiar (1 min)

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-resources
kubectl config set-context --current --namespace=default
```

---

## Resumen Visual

```
┌─────────────────────────────────────────────────┐
│  REQUESTS (scheduler)                           │
│  - Garantia minima reservada                    │
│  - Usado para PLACEMENT (en que nodo va)        │
│  - sum(requests) <= allocatable del nodo         │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│  LIMITS (kernel enforcement)                    │
│  - Tope maximo permitido                        │
│  - CPU: throttling (proceso lento)              │
│  - Memory: OOMKilled (proceso terminado)        │
│  - sum(limits) puede exceder capacidad del nodo │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│  QoS CLASS (prioridad ante eviction)            │
│  Guaranteed > Burstable > BestEffort            │
│  - Se calcula automaticamente segun resources   │
│  - Afecta orden de eviction bajo presion        │
└─────────────────────────────────────────────────┘
```
