# Resumen Practico: Resource Limits en Pods

**Duracion:** 15 minutos | **Nivel:** Repaso integral | **Archivo:** `resources-lab.yaml`

Un solo YAML despliega Pods con las 3 QoS classes, un Deployment con resource limits, un Pod multi-container con sidecars, y un Pod con init container para practicar todos los conceptos de resource management de un vistazo, usando Minikube.

---

## Conceptos Previos: Antes de Empezar

Si nunca has trabajado con resource limits en Kubernetes, lee esta seccion antes de los pasos del lab. Si ya conoces el tema, salta directamente al Paso 0.

### Los contenedores usan CPU y memoria

Un contenedor es un proceso que corre dentro de tu computadora (o servidor). Como cualquier programa, necesita dos recursos fundamentales:

- **CPU**: La capacidad de procesar calculos. Si tienes poca CPU, el programa se vuelve lento.
- **Memoria (RAM)**: El espacio donde el programa guarda datos temporales. Si se queda sin memoria, el sistema operativo lo termina abruptamente.

En un cluster de Kubernetes, muchos Pods comparten los mismos Nodes (servidores). Sin control, un Pod podria consumir toda la CPU o memoria de un Node, dejando a los demas sin recursos. Los **Resource Limits** existen para evitar esto.

### La analogia del presupuesto mensual

Piensa en los recursos de un Pod como el presupuesto de un departamento en una empresa:

- **Request** = el presupuesto minimo garantizado que el departamento necesita para funcionar. La empresa (el scheduler de Kubernetes) reserva esa cantidad solo para ti.
- **Limit** = el techo maximo que el departamento puede gastar. No puedes superar este limite, aunque haya dinero disponible.

Un departamento con `request: 100` y `limit: 500` tiene garantizados 100 euros al mes, pero puede gastar hasta 500 si hay fondos disponibles. Si intenta gastar 501, se le bloquea.

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

## Entendiendo las Unidades: CPU y Memoria

Antes de ver codigo, es fundamental entender como Kubernetes expresa cantidades de CPU y memoria. Estas unidades confunden a la mayoria de los principiantes.

### Unidades de CPU

La CPU en Kubernetes se mide en **milicores** (milli-CPU). La letra `m` significa "milesimas de un core".

```
1000m  =  1 CPU core completo
 500m  =  0.5 CPU cores (medio core)
 250m  =  0.25 CPU cores (un cuarto de core)
 100m  =  0.1 CPU cores (una decima parte de un core)
  10m  =  0.01 CPU cores (una centesima parte, muy poco)
```

Para un servidor pequeno con 2 cores, el total disponible es 2000m. Si un Pod pide `request: 500m`, ocupa la cuarta parte de ese servidor.

**Analogia**: Imagina que un core de CPU es una hora de trabajo de un empleado. Si tienes 2 empleados (2 cores = 2000m), y un Pod pide 500m, esta pidiendo media hora de trabajo de uno de tus empleados.

### Unidades de Memoria

La memoria usa sufijos de potencias de dos (sistema binario):

```
Ki  =  Kibibyte  =  1,024 bytes
Mi  =  Mebibyte  =  1,048,576 bytes     (~1 MB)
Gi  =  Gibibyte  =  1,073,741,824 bytes (~1 GB)
```

Ejemplos comunes:

```
 64Mi  =   64 Mebibytes  (~67 MB)   -- muy poco, solo texto simple
128Mi  =  128 Mebibytes  (~134 MB)  -- app web basica
256Mi  =  256 Mebibytes  (~268 MB)  -- app web moderada
512Mi  =  512 Mebibytes  (~537 MB)  -- app con base de datos pequena
  1Gi  =    1 Gibibyte   (~1.07 GB) -- app con carga de trabajo real
```

**Nota importante**: Si un contenedor supera su limite de memoria, el kernel de Linux lo termina inmediatamente con el error `OOMKilled` (Out Of Memory Killed). Esto no es gradual como el throttling de CPU: es una terminacion abrupta.

---

## Las 3 QoS Classes: El Sistema de Prioridades

Kubernetes asigna automaticamente una **QoS Class** (Quality of Service Class) a cada Pod segun como definas sus resources. Esta clase determina quien "sale primero" cuando el Node se queda sin recursos.

### Guaranteed: El asiento de primera clase

Un Pod es Guaranteed cuando `request == limit` en **todos** sus contenedores para CPU y memoria.

```yaml
resources:
  requests:
    cpu: "200m"
    memory: "128Mi"
  limits:
    cpu: "200m"      # igual que request
    memory: "128Mi"  # igual que request
```

Es como tener un asiento reservado en primera clase de un avion: tienes un lugar garantizado y nadie te lo puede quitar. Kubernetes evicta estos Pods como ultimo recurso, solo cuando ya no queda ninguna otra opcion.

**Caso de uso**: Bases de datos, servicios criticos de produccion, cualquier carga de trabajo que no puede interrumpirse.

### Burstable: El asiento de turista que puede mejorar

Un Pod es Burstable cuando tiene al menos un request definido pero `request < limit` en algun contenedor.

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "64Mi"
  limits:
    cpu: "500m"      # mayor que request: puede usar mas si hay disponible
    memory: "256Mi"  # mayor que request
```

Es como un asiento de clase turista con posibilidad de upgrade: tienes un lugar garantizado (el request), pero si hay sitios libres en business class, puedes usarlos (el limit). Sin embargo, si el avion se llena, te quedas en tu asiento original.

**Caso de uso**: APIs REST, aplicaciones web que tienen picos ocasionales de trafico.

### BestEffort: El pasajero standby

Un Pod es BestEffort cuando no tiene ningun request ni limit definido.

```yaml
# Sin seccion resources en absoluto
containers:
  - name: mi-contenedor
    image: nginx
    # sin resources: {}
```

Es como volar en standby: solo subes al avion si hay asientos sobrantes. Si el avion (el Node) se llena, eres el primero en bajarte. Kubernetes puede terminar estos Pods en cualquier momento cuando hay presion de recursos.

**Caso de uso**: Tareas batch no criticas, entornos de desarrollo/pruebas donde la interrupcion es aceptable.

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

Minikube es una herramienta que crea un cluster de Kubernetes local en tu maquina. Para este lab necesitamos tambien `metrics-server`, que es el componente que recopila datos de uso de CPU y memoria en tiempo real (sin el, los comandos `kubectl top` no funcionan).

```bash
minikube start

# Habilitar metrics-server (necesario para kubectl top)
minikube addons enable metrics-server

# Verificar
minikube status
kubectl cluster-info
```

**Que esperar**: `minikube status` debe mostrar `host: Running`, `kubelet: Running`, y `apiserver: Running`. `kubectl cluster-info` muestra la URL del API server del cluster.

---

## Paso 1: Desplegar Todo (1 min)

Este comando aplica el archivo `resources-lab.yaml` que contiene todos los recursos del lab: el namespace, los tres Pods de QoS, el Deployment con su Service, el Pod multi-container y el Pod con init container.

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

**Que significa la columna STATUS**: Los Pods deben aparecer en estado `Running`. Si ves `Pending`, el cluster no tiene suficientes recursos para colocar el Pod. Si ves `Init:0/1`, el init container todavia esta corriendo (es normal al principio).

**Que acabamos de aprender**: Al ejecutar un solo archivo YAML, Kubernetes creo simultaneamente todos los recursos del lab en un namespace aislado llamado `lab-resources`. Los namespaces son como "carpetas" que agrupan recursos y los aíslan de otros namespaces.

---

## Paso 2: Explorar QoS Classes (3 min)

Ahora vamos a ver como Kubernetes asigno automaticamente la QoS class a cada Pod segun los recursos que definimos. El flag `-o custom-columns` nos permite elegir exactamente que columnas mostrar en la salida.

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

**Como leer esta salida:**

- `qos-guaranteed`: Los valores de CPU_REQ y CPU_LIM son identicos (200m = 200m), lo mismo para memoria. Por eso es Guaranteed.
- `qos-burstable`: CPU_REQ (100m) es menor que CPU_LIM (500m). Tiene un request pero no iguala el limit. Por eso es Burstable.
- `qos-besteffort`: Todos los valores muestran `<none>`, es decir, no tiene ninguna definicion de recursos. Por eso es BestEffort.

**Pregunta:** Si el nodo tiene presion de memoria, en que orden se eliminan?

1. `qos-besteffort` (primero, no tiene garantia alguna)
2. `qos-burstable` (segundo, tiene garantia parcial)
3. `qos-guaranteed` (ultimo, tiene la maxima proteccion)

**Que acabamos de aprender**: Kubernetes calcula la QoS class automaticamente: no es algo que defines explicitamente, sino una consecuencia de como configuras los requests y limits. Puedes ver la clase asignada en `.status.qosClass`.

---

## Paso 3: Analizar Deployment con Limits (3 min)

Un Deployment gestiona multiples replicas de un Pod. Los resource limits se definen una vez en la plantilla del Deployment y se aplican identicamente a cada replica. Esto es importante: si tienes 3 replicas y cada una tiene `request: 100m`, el Deployment en total consume 300m de CPU.

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

**Que significa esto para el cluster**: Cada replica reserva 100m de CPU (request). Con 3 replicas, el Deployment en total reserva 300m de CPU en el Node. Si el Node tiene 2 cores (2000m), este Deployment ocupa el 15% de la CPU total.

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

**Como leer esta salida**: Cada Pod usa actualmente solo 2m de CPU, aunque tiene reservados 100m (request) y puede usar hasta 300m (limit). Esto es normal: la app esta inactiva. Los 100m reservados estan "bloqueados" para este Pod aunque no los use, garantizando que siempre tenga esa capacidad disponible si la necesita.

**Analisis:** Cada replica usa ~2m de 100m request (2% utilizacion). Los limits de 300m permiten absorber picos de trafico sin necesidad de escalar horizontalmente de inmediato.

**Que acabamos de aprender**: Hay una diferencia entre recursos *reservados* (request) y recursos *en uso real* (lo que muestra `kubectl top`). Un Pod puede tener reservado mucho mas de lo que realmente consume. Esto es normal y deseable: los requests garantizan disponibilidad futura.

---

## Paso 4: Multi-container Resources (2 min)

Cuando un Pod tiene multiples contenedores, los recursos de cada contenedor se suman para obtener el total del Pod. Esto es relevante para el scheduling: el scheduler busca un Node con suficiente espacio para la suma total, no para cada contenedor por separado.

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

**Como leer esta salida**: El flag `--containers` desglosa el uso de recursos por cada contenedor dentro del Pod. El contenedor `app` usa 2m de CPU y 5Mi de memoria. Los contenedores `logger` y `metrics` usan cantidades minimas (0m significa menos de 0.5m, que se redondea a 0).

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

El scheduler busca un Node con al menos 400m de CPU y 320Mi de memoria libres para poder colocar este Pod.

**Que acabamos de aprender**: En un Pod multi-container, los recursos son aditivos. Si tienes un sidecar de logging que usa 100m de CPU, ese costo se suma a tu contenedor principal. Al disenyar arquitecturas con sidecars, hay que considerar el impacto en los recursos totales del Pod.

---

## Paso 5: Init Container y Regla del Maximo (2 min)

Los init containers son contenedores especiales que corren antes de los contenedores principales del Pod y deben completarse exitosamente antes de que arranquen los demas. Tienen una regla especial para el calculo de recursos: el scheduler reserva el maximo entre los recursos del init container y la suma de los contenedores principales.

**Por que esta regla existe**: El init container y los contenedores principales nunca corren simultaneamente. Primero corre el init (y termina), luego arrancan los principales. Por lo tanto, el nodo solo necesita espacio para uno u otro en cada momento, no para ambos al mismo tiempo.

```bash
# Ver estado del Pod (init debe haber completado)
kubectl get pod init-container-demo -n lab-resources
```

**Salida esperada:**

```
NAME                  READY   STATUS    RESTARTS   AGE
init-container-demo   1/1     Running   0          2m
```

**Que indica STATUS=Running aqui**: El init container ya termino su tarea y el contenedor principal esta corriendo. Si vieras `Init:0/1`, significaria que el init container todavia esta ejecutandose. El `1/1` en READY confirma que el contenedor principal esta listo para recibir trafico.

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

El init container necesitaba 500m para completar su trabajo de inicializacion (por ejemplo, migrar una base de datos). Una vez que termino, libera esos recursos. El contenedor principal solo necesita 200m para funcionar normalmente.

**Que acabamos de aprender**: Los init containers pueden tener recursos diferentes (incluso mayores) que los contenedores principales. Esto tiene sentido: una tarea de setup puede requerir mas CPU que la app en si. Despues de que el init termina, esos recursos quedan disponibles para otros Pods.

---

## Paso 6: Ver Recursos del Nodo (2 min)

Hasta ahora hemos visto los recursos desde la perspectiva de los Pods. Ahora vamos a ver el panorama completo desde la perspectiva del Node: cuanto hay disponible en total y cuanto esta ya reservado por todos los Pods que estan corriendo.

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

**Como leer esta salida:**

- **Requests 1250m (31%)**: Los Pods en este Node tienen reservados colectivamente 1250m de CPU. El scheduler solo colocara un nuevo Pod aqui si su request cabe en el 69% restante.
- **Limits 2100m (52%)**: Los Pods pueden usar en total hasta 2100m de CPU. Este valor puede superar el 100% del Node porque los limits representan picos eventuales, no el uso constante.
- La diferencia entre 31% (requests) y 52% (limits) representa el "headroom" disponible para picos: si todos los Pods usaran sus limits al mismo tiempo, habria contention de CPU.

**Observacion:** Los Requests determinan scheduling. Los Limits pueden sumar mas del 100% del nodo (overcommit). Kubernetes apuesta a que no todos los Pods alcanzaran su limit simultaneamente, lo que es razonable en la practica.

**Que acabamos de aprender**: El Node es como un edificio con una capacidad maxima. Los requests son los contratos de arrendamiento firmados (espacio garantizado). Los limits son el espacio maximo que cada inquilino podria usar si hubiera disponibilidad. El edificio puede tener mas "contratos maximos" que espacio real porque en la practica nadie usa el maximo al mismo tiempo.

---

## Paso 7: Limpiar (1 min)

El script de limpieza elimina el namespace `lab-resources` y todos los recursos dentro de el (Pods, Deployment, Service, etc.), luego restaura el contexto de kubectl al namespace `default`.

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-resources
kubectl config set-context --current --namespace=default
```

**Verificar que la limpieza fue exitosa:**

```bash
kubectl get ns lab-resources
# Debe mostrar: Error from server (NotFound): namespaces "lab-resources" not found
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

## Lo Que Aprendiste en Este Lab

Al completar este lab has practicado los siguientes conceptos:

- **Unidades de recursos**: CPU en milicores (m) y memoria en mebibytes (Mi/Gi)
- **Requests vs Limits**: la diferencia entre lo garantizado y lo maximo permitido
- **QoS Classes**: como Kubernetes asigna Guaranteed, Burstable o BestEffort automaticamente
- **Orden de eviction**: BestEffort primero, Guaranteed ultimo
- **Recursos aditivos en multi-container Pods**: el scheduler suma todos los contenedores
- **Regla del maximo en init containers**: MAX(init, sum(app))
- **Overcommit de Limits**: los limits pueden sumar mas del 100% del Node
- **kubectl top**: como monitorear el uso real frente a los recursos reservados
