# Resumen Practico: Alta Disponibilidad en Kubernetes

**Duracion:** 60 minutos | **Nivel:** Principiante | **Archivo:** `ha-lab.yaml`

Un solo YAML despliega todos los conceptos fundamentales de Alta Disponibilidad: anti-affinity para distribuir Pods en nodos, topologySpreadConstraints para balancear entre zonas, PodDisruptionBudgets para proteger el mantenimiento, sessionAffinity para stickiness de sesion, y un Pod que falla periodicamente para observar el auto-recovery de Kubernetes. Todo en Minikube.

---

## Conceptos Previos: Antes de Empezar

Si es tu primera vez trabajando con Alta Disponibilidad en Kubernetes, lee esta seccion completa. Contiene la base conceptual necesaria para que los comandos del lab tengan sentido. Si ya conoces el tema, salta directamente al Paso 0.

### La analogia del hospital con enfermeros de guardia

La Alta Disponibilidad (HA) es el conjunto de tecnicas para garantizar que un sistema siga funcionando aunque alguno de sus componentes falle.

Imagina un hospital de urgencias. En un turno normal hay 10 enfermeros. Si uno de ellos se enferma y no hay guardia de reemplazo, los otros 9 tienen que absorber su trabajo: la atencion se ralentiza, los pacientes esperan mas, la calidad baja. Si se enferman 4 a la vez, el servicio puede colapsar.

Un hospital bien gestionado tiene:

- **Enfermeros en distintas plantas** (no todos juntos): si hay un incendio en la planta 3, los de la planta 1 siguen trabajando. Esto es **anti-affinity**: distribuir los Pods en nodos distintos para que un fallo de hardware no elimine todas las replicas de golpe.
- **Guardia minima garantizada**: por ley, siempre debe haber al menos 3 enfermeros de guardia aunque haya reformas en el edificio. Esto es el **PodDisruptionBudget**: aunque alguien haga mantenimiento (drain de un nodo), Kubernetes garantiza que siempre quede el minimo operativo.
- **Medico de guardia disponible 24/7**: si un medico se va, hay otro que toma su lugar en minutos. Esto es el **auto-recovery**: cuando un Pod falla, Kubernetes lo reinicia automaticamente.
- **Paciente asignado al mismo enfermero**: para continuidad de cuidado, cada paciente tiene un enfermero asignado que conoce su historial. Esto es **sessionAffinity**: el mismo cliente siempre llega al mismo Pod.

El resultado: el paciente (usuario) nunca nota la diferencia cuando un enfermero (Pod) se enferma. El sistema absorbe el fallo sin interrumpir el servicio.

---

### Que significa 99.9% vs 99.99% de disponibilidad

La disponibilidad se expresa como el porcentaje del tiempo que el sistema esta operativo. La diferencia entre un nueve y cuatro nueves parece pequena en porcentaje pero es enorme en minutos de downtime anuales.

```
Disponibilidad    Downtime al anio   Downtime al mes   Por semana
---------------------------------------------------------------------------
99%               87.6 horas         7.3 horas         1.7 horas
99.5%             43.8 horas         3.6 horas         50 minutos
99.9%  (3 nueves) 8.7  horas         43.8 minutos      10.1 minutos
99.95%            4.4  horas         21.9 minutos      5 minutos
99.99% (4 nueves) 52.6 minutos       4.4 minutos       1 minuto
99.999%(5 nueves) 5.3  minutos       26 segundos       6 segundos
---------------------------------------------------------------------------
```

La diferencia entre 99.9% y 99.99% es pasar de 8.7 horas de caidas anuales a 52 minutos. Para una tienda online que factura 1.000 euros por minuto, esos 8 horas adicionales de caida equivalen a 480.000 euros de perdidas al anio.

**Implicacion practica**: para alcanzar 99.9% con Kubernetes necesitas al menos 3 replicas distribuidas en zonas distintas con PDBs configurados. Para 99.99% necesitas multi-zona con redundancia activa-activa y Cluster Autoscaler.

---

### Replicas: la primera linea de defensa

Una **replica** es una copia identica de tu aplicacion corriendo en paralelo. Si tienes 3 replicas y una falla, las otras 2 absorben el trafico inmediatamente. El usuario no nota interrupciones porque el Service de Kubernetes redistribuye las peticiones automaticamente.

```
SIN replicas (1 Pod):
  Usuario -> [Pod-A]
             Si Pod-A falla -> ERROR 503 para el usuario

CON replicas (3 Pods):
  Usuario -> Service -> [Pod-A]  \
                        [Pod-B]   } Service balancea entre los 3
                        [Pod-C]  /
  Si Pod-A falla -> Service redirige a Pod-B o Pod-C -> INVISIBLE para usuario
```

El numero minimo de replicas recomendado para produccion es 3:
- 1 replica puede estar en mantenimiento (drain)
- 1 replica puede tener un fallo transitorio
- Queda 1 replica siempre atendiendo trafico (garantizado por PDB)

---

### Anti-affinity: separar Pods en nodos distintos

Por defecto, el scheduler de Kubernetes puede colocar todas las replicas en el mismo nodo fisico. Esto es eficiente en uso de recursos pero catastrofico para la disponibilidad: si ese nodo falla (hardware, electricidad, actualizacion de kernel), pierdes todas las replicas al mismo tiempo.

**podAntiAffinity** le dice al scheduler: "intenta NO colocar dos Pods del mismo Deployment en el mismo nodo".

```
SIN anti-affinity (todas en nodo-1):
  nodo-1: [Pod-A] [Pod-B] [Pod-C]
  nodo-2: (vacio)
  nodo-3: (vacio)

  Si nodo-1 falla -> 3 de 3 replicas perdidas -> SERVICIO CAIDO

CON anti-affinity (distribuidas):
  nodo-1: [Pod-A]
  nodo-2: [Pod-B]
  nodo-3: [Pod-C]

  Si nodo-1 falla -> 1 de 3 replicas perdidas -> 2 REPLICAS SIGUEN ACTIVAS
```

Hay dos modos de anti-affinity:
- **Preferida (soft)**: el scheduler intenta cumplirla pero programa el Pod de todos modos si no puede. Funciona en Minikube (1 nodo). Los 3 Pods quedaran en el mismo nodo pero el sistema funciona.
- **Requerida (hard)**: el scheduler NO programa el Pod si no puede cumplir la regla. Solo funciona si tienes suficientes nodos diferentes. En Minikube con 1 nodo, los Pods quedaran en Pending.

En este lab usamos anti-affinity **preferida** para que funcione en cualquier entorno.

---

### PodDisruptionBudget: proteccion durante el mantenimiento

Un **PodDisruptionBudget (PDB)** es un contrato que le dices a Kubernetes: "durante operaciones planificadas (mantenimiento, actualizaciones, drain de nodos), garantiza que siempre queden al menos N Pods disponibles".

Sin PDB, cuando un administrador ejecuta `kubectl drain nodo-1` para hacer mantenimiento, Kubernetes puede eliminar todos los Pods de ese nodo a la vez, aunque eso deje el servicio sin replicas.

Con PDB configurado, `kubectl drain` respeta el minimo y espera a que se creen nuevos Pods en otros nodos antes de eliminar los del nodo que se va a vaciar.

```
SIN PDB (drain elimina todo de golpe):
  kubectl drain nodo-1
  -> Elimina Pod-A, Pod-B, Pod-C del nodo-1
  -> El scheduler crea nuevos Pods... pero hay un gap de tiempo
  -> Durante ese gap: 0 replicas disponibles -> DOWNTIME

CON PDB minAvailable:2 (drain respeta el minimo):
  kubectl drain nodo-1
  -> Kubernetes comprueba: tengo 3 Pods, necesito minimo 2
  -> Puede eliminar como maximo 1 a la vez
  -> Elimina Pod-A -> espera a que nodo-2 cree nuevo Pod
  -> Confirma que hay 2+ Pods activos -> elimina siguiente
  -> NUNCA hay menos de 2 Pods activos -> CERO DOWNTIME
```

Hay dos formas de especificar un PDB:
- **minAvailable: N**: siempre debe haber al menos N Pods disponibles. Absoluto.
- **maxUnavailable: N**: como maximo N Pods pueden estar no disponibles. Relativo al total.

---

### topologySpreadConstraints: distribucion entre zonas

**topologySpreadConstraints** es la evolucion moderna de podAntiAffinity para entornos multi-zona. En lugar de simplemente "separa los Pods", permite controlar el **desbalance maximo** (maxSkew) entre zonas de disponibilidad.

Un cluster de produccion en Azure tipicamente tiene 3 zonas de disponibilidad (AZ1, AZ2, AZ3). Cada zona es un datacenter fisicamente separado con alimentacion electrica, refrigeracion y red independientes. Un fallo en AZ1 no afecta a AZ2 ni AZ3.

```
SIN topologySpreadConstraints (distribucion aleatoria):
  AZ1: [Pod-A] [Pod-B] [Pod-C] [Pod-D]
  AZ2: (vacio)
  AZ3: (vacio)
  Si AZ1 falla -> TODOS los Pods perdidos

CON topologySpreadConstraints (maxSkew: 1):
  AZ1: [Pod-A] [Pod-B]
  AZ2: [Pod-C] [Pod-D]
  AZ3: [Pod-E] [Pod-F]
  Si AZ1 falla -> 4 de 6 Pods siguen activos (66% capacidad)
```

El parametro `maxSkew: 1` significa que ninguna zona puede tener mas de 1 Pod adicional respecto a la zona con menos Pods. Ejemplo: con 4 Pods y 3 zonas, la distribucion 2-1-1 es valida (diferencia maxima = 1), pero 3-1-0 no (diferencia = 3 > maxSkew de 1).

---

### Diagrama: distribucion de Pods en nodos y zonas

El siguiente diagrama muestra como se distribuyen los Pods con las estrategias de este lab en un cluster de produccion con 3 zonas y 6 nodos:

```
CLUSTER DE PRODUCCION (3 zonas de disponibilidad)
================================================================

  ZONA A (datacenter Madrid)    ZONA B (datacenter Barcelona)
  ┌──────────────────────────┐  ┌──────────────────────────┐
  │ Nodo-1       Nodo-2      │  │ Nodo-3       Nodo-4      │
  │ ┌─────────┐ ┌─────────┐  │  │ ┌─────────┐ ┌─────────┐  │
  │ │ webapp  │ │ webapp  │  │  │ │ webapp  │ │         │  │
  │ │ anti-a  │ │ spread  │  │  │ │ spread  │ │         │  │
  │ └─────────┘ └─────────┘  │  │ └─────────┘ └─────────┘  │
  └──────────────────────────┘  └──────────────────────────┘

  ZONA C (datacenter Valencia)
  ┌──────────────────────────┐
  │ Nodo-5       Nodo-6      │
  │ ┌─────────┐ ┌─────────┐  │
  │ │ webapp  │ │ webapp  │  │
  │ │ anti-a  │ │ spread  │  │
  │ └─────────┘ └─────────┘  │
  └──────────────────────────┘

  GARANTIAS CON ESTA DISTRIBUCION:
  - Fallo de Nodo-1: 5 de 6 Pods activos (83% capacidad)
  - Fallo de Zona A: 4 de 6 Pods activos (66% capacidad)
  - Fallo de Zona A + B: 2 Pods activos (33% capacidad, servicio degradado)
  - PDB garantiza minimo 2 Pods durante drain/mantenimiento

  ESTE LAB (Minikube, 1 nodo):
  - Todos los Pods en el mismo nodo (anti-affinity soft)
  - La logica del scheduler es identica; solo falta hardware real
  - Conceptos y comandos son 100% transferibles a produccion
```

---

### Tabla: Estrategias de Alta Disponibilidad

| Estrategia | Que hace | Cuando usar | Limitacion |
|------------|----------|-------------|-----------|
| **Replicas (>= 3)** | Multiples copias del Pod activas en paralelo | Siempre en produccion | No garantiza distribucion en distintos nodos |
| **podAntiAffinity preferida** | Intenta separar Pods en nodos distintos | Clusters con pocos nodos | No garantiza separacion si no hay nodos suficientes |
| **podAntiAffinity requerida** | Exige separacion en nodos distintos | Clusters con muchos nodos | Pods en Pending si no hay nodos disponibles |
| **topologySpreadConstraints** | Distribucion uniforme entre zonas/nodos | Clusters multi-zona | Requiere labels de zona en los nodos |
| **PDB minAvailable** | Garantiza minimo de Pods durante drain | Siempre con >= 2 replicas | No protege contra fallos espontaneos, solo disrupciones planificadas |
| **PDB maxUnavailable** | Limita cuantos Pods pueden caer | Preferible para Deployments grandes | Mismas limitaciones que minAvailable |
| **sessionAffinity ClientIP** | Mismo cliente siempre va al mismo Pod | Apps con estado de sesion | Si el Pod falla, la sesion se pierde de todos modos |
| **ReadinessProbe** | Pod solo recibe trafico cuando esta listo | Siempre en produccion | No evita que un Pod falle despues de estar listo |
| **LivenessProbe** | Reinicia el Pod si deja de responder | Siempre en produccion | Puede causar restart loops si mal configurado |

---

## Recursos Desplegados por ha-lab.yaml

```
NAMESPACE: lab-ha
├── ConfigMap: configuracion-ha
│     Configuracion centralizada (SLO, zonas, estado HA)
├── Deployment: webapp-anti-affinity (3 replicas)
│     Anti-affinity preferida por hostname
│     Conectado a: pdb-min-available, webapp-ha-service
├── Deployment: webapp-topology-spread (3 replicas)
│     topologySpreadConstraints por zona y nodo
│     Conectado a: pdb-max-unavailable, webapp-spread-service
├── PodDisruptionBudget: pdb-min-available
│     minAvailable: 2 -> protege webapp-anti-affinity
├── PodDisruptionBudget: pdb-max-unavailable
│     maxUnavailable: 1 -> protege webapp-topology-spread
├── Service: webapp-ha-service (sessionAffinity: ClientIP)
│     Stickiness de sesion por IP del cliente
├── Service: webapp-spread-service (sessionAffinity: None)
│     Balance round-robin sin stickiness
└── Pod: pod-fallo-simulado
      Simula crash cada 60s para ver RESTARTS en accion
```

---

## Paso 0: Preparar Minikube (2 min)

Minikube es una herramienta que crea un cluster de Kubernetes local en tu maquina, con un unico nodo. Es suficiente para aprender y practicar los conceptos de HA porque la logica del scheduler y los PDBs funciona de forma identica que en produccion. La unica diferencia es que en Minikube todos los Pods estaran en el mismo nodo fisico (hay uno solo), mientras que en produccion se distribuiran entre multiples nodos.

```bash
minikube start

# Verificar que el cluster esta activo
minikube status
kubectl cluster-info
kubectl get nodes
```

Salida esperada de `kubectl get nodes`:

```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.28.x
```

Un unico nodo en estado `Ready`. Nota el rol `control-plane`: en Minikube, el mismo nodo actua como plano de control y como nodo de trabajo.

---

## Paso 1: Desplegar Todo (2 min)

Este comando aplica `ha-lab.yaml` y crea simultáneamente todos los recursos del lab: el namespace, el ConfigMap, los dos Deployments, los dos PDBs, los dos Services, y el Pod de fallo simulado.

```bash
cd /ruta/al/directorio/lab-resumen-ha
kubectl apply -f ha-lab.yaml
```

Salida esperada:

```
namespace/lab-ha created
configmap/configuracion-ha created
deployment.apps/webapp-anti-affinity created
deployment.apps/webapp-topology-spread created
poddisruptionbudget.policy/pdb-min-available created
poddisruptionbudget.policy/pdb-max-unavailable created
service/webapp-ha-service created
service/webapp-spread-service created
pod/pod-fallo-simulado created
```

Ahora configuramos el namespace por defecto para no tener que escribir `-n lab-ha` en cada comando:

```bash
kubectl config set-context --current --namespace=lab-ha
```

Verificar que todos los recursos se crearon correctamente:

```bash
kubectl get all -n lab-ha
```

Salida esperada (aproximada, los nombres de Pods variaran):

```
NAME                                          READY   STATUS    RESTARTS   AGE
pod/pod-fallo-simulado                        1/1     Running   0          30s
pod/webapp-anti-affinity-abc123-def45         1/1     Running   0          30s
pod/webapp-anti-affinity-abc123-ghi67         1/1     Running   0          30s
pod/webapp-anti-affinity-abc123-jkl89         1/1     Running   0          30s
pod/webapp-topology-spread-xyz111-mno22       1/1     Running   0          30s
pod/webapp-topology-spread-xyz111-pqr33       1/1     Running   0          30s
pod/webapp-topology-spread-xyz111-stu44       1/1     Running   0          30s

NAME                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/webapp-ha-service        ClusterIP   10.96.xxx.xxx   <none>        80/TCP    30s
service/webapp-spread-service    ClusterIP   10.96.yyy.yyy   <none>        80/TCP    30s

NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/webapp-anti-affinity     3/3     3            3           30s
deployment.apps/webapp-topology-spread   3/3     3            3           30s

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/webapp-anti-affinity-abc123          3         3         3       30s
replicaset.apps/webapp-topology-spread-xyz111        3         3         3       30s
```

La columna `READY` debe mostrar `3/3` para ambos Deployments. Si ves `0/3` o `1/3`, espera unos segundos y vuelve a ejecutar el comando: los Pods pueden tardar unos segundos en arrancar y pasar las readiness probes.

---

## Paso 2: Explorar Anti-Affinity (8 min)

Vamos a ver como el scheduler coloco los Pods del Deployment `webapp-anti-affinity`. En produccion estarian en nodos distintos gracias a la anti-affinity preferida. En Minikube (1 nodo) todos estaran en el mismo nodo, pero la configuracion es correcta y funcionaria en un cluster real.

```bash
# Ver en que nodo esta cada Pod (columna NODE)
kubectl get pods -n lab-ha -l app=webapp-ha -o wide
```

Salida esperada en Minikube:

```
NAME                                    READY   STATUS    NODE       IP
webapp-anti-affinity-abc123-def45       1/1     Running   minikube   172.17.0.4
webapp-anti-affinity-abc123-ghi67       1/1     Running   minikube   172.17.0.5
webapp-anti-affinity-abc123-jkl89       1/1     Running   minikube   172.17.0.6
```

Todos en `minikube` porque solo hay un nodo. En un cluster con 3 nodos, cada Pod estaria en un nodo distinto.

Ahora inspeccionemos la regla de anti-affinity tal como fue configurada:

```bash
# Ver la configuracion de affinity del Deployment
kubectl get deployment webapp-anti-affinity -n lab-ha \
  -o jsonpath='{.spec.template.spec.affinity}' | python3 -m json.tool
```

Salida esperada:

```json
{
    "podAntiAffinity": {
        "preferredDuringSchedulingIgnoredDuringExecution": [
            {
                "podAffinityTerm": {
                    "labelSelector": {
                        "matchLabels": {
                            "app": "webapp-ha",
                            "tier": "frontend"
                        }
                    },
                    "topologyKey": "kubernetes.io/hostname"
                },
                "weight": 100
            }
        ]
    }
}
```

Punto clave: `preferredDuringSchedulingIgnoredDuringExecution` confirma que es una regla **soft** (preferida, no requerida). El `weight: 100` indica maxima prioridad para esta preferencia.

Ahora simula lo que pasaria si borramos un Pod manualmente (equivale a un fallo de hardware):

```bash
# Obten el nombre del primer Pod
POD1=$(kubectl get pods -n lab-ha -l app=webapp-ha -o jsonpath='{.items[0].metadata.name}')
echo "Eliminando Pod: $POD1"

# Eliminalo (simula un fallo)
kubectl delete pod $POD1 -n lab-ha

# Observa como el ReplicaSet lo recrea inmediatamente
kubectl get pods -n lab-ha -l app=webapp-ha -w
```

Salida esperada (--watch):

```
NAME                                    READY   STATUS        RESTARTS   AGE
webapp-anti-affinity-abc123-def45       1/1     Terminating   0          3m
webapp-anti-affinity-abc123-ghi67       1/1     Running       0          3m
webapp-anti-affinity-abc123-jkl89       1/1     Running       0          3m
webapp-anti-affinity-abc123-new99       0/1     Pending       0          1s
webapp-anti-affinity-abc123-new99       0/1     Running       0          3s
webapp-anti-affinity-abc123-new99       1/1     Running       0          8s
```

Presiona `Ctrl+C` para salir del modo watch. Lo que acabas de ver: el Pod fue eliminado y en segundos el ReplicaSet creo uno nuevo para mantener las 3 replicas. Nunca hubo menos de 2 Pods activos porque la terminacion y la creacion se solapan.

---

## Paso 3: Explorar topologySpreadConstraints (8 min)

Ahora observamos el Deployment `webapp-topology-spread` que usa `topologySpreadConstraints` en lugar de `podAntiAffinity`.

```bash
# Ver los Pods del segundo Deployment
kubectl get pods -n lab-ha -l app=webapp-spread -o wide
```

Salida esperada en Minikube:

```
NAME                                       READY   STATUS    NODE       IP
webapp-topology-spread-xyz111-mno22        1/1     Running   minikube   172.17.0.7
webapp-topology-spread-xyz111-pqr33        1/1     Running   minikube   172.17.0.8
webapp-topology-spread-xyz111-stu44        1/1     Running   minikube   172.17.0.9
```

Inspeccionamos la configuracion de `topologySpreadConstraints`:

```bash
kubectl get deployment webapp-topology-spread -n lab-ha \
  -o jsonpath='{.spec.template.spec.topologySpreadConstraints}' | python3 -m json.tool
```

Salida esperada:

```json
[
    {
        "labelSelector": {
            "matchLabels": {
                "app": "webapp-spread"
            }
        },
        "maxSkew": 1,
        "topologyKey": "topology.kubernetes.io/zone",
        "whenUnsatisfiable": "ScheduleAnyway"
    },
    {
        "labelSelector": {
            "matchLabels": {
                "app": "webapp-spread"
            }
        },
        "maxSkew": 1,
        "topologyKey": "kubernetes.io/hostname",
        "whenUnsatisfiable": "ScheduleAnyway"
    }
]
```

Hay dos restricciones:
1. Por zona (`topology.kubernetes.io/zone`): maxSkew 1 entre zonas
2. Por hostname (`kubernetes.io/hostname`): maxSkew 1 entre nodos

Ambas con `whenUnsatisfiable: ScheduleAnyway` (equivalente a soft/preferida). En Minikube, el nodo no tiene el label de zona, asi que esta restriccion se ignora. En AKS, los nodos tienen este label automaticamente.

Ahora escalamos el Deployment a 6 replicas para ver como intenta balancear:

```bash
kubectl scale deployment webapp-topology-spread --replicas=6 -n lab-ha

# Ver como distribuye los nuevos Pods
kubectl get pods -n lab-ha -l app=webapp-spread -o wide
```

Salida esperada (todos en minikube porque es 1 nodo, pero en produccion se distribuirian):

```
NAME                                       READY   STATUS    NODE       IP
webapp-topology-spread-xyz111-mno22        1/1     Running   minikube   172.17.0.7
webapp-topology-spread-xyz111-pqr33        1/1     Running   minikube   172.17.0.8
webapp-topology-spread-xyz111-stu44        1/1     Running   minikube   172.17.0.9
webapp-topology-spread-xyz111-abc01        1/1     Running   minikube   172.17.0.10
webapp-topology-spread-xyz111-def02        1/1     Running   minikube   172.17.0.11
webapp-topology-spread-xyz111-ghi03        1/1     Running   minikube   172.17.0.12
```

Devolvemos a 3 replicas:

```bash
kubectl scale deployment webapp-topology-spread --replicas=3 -n lab-ha
```

---

## Paso 4: Verificar los PodDisruptionBudgets (8 min)

Un PDB es invisible en el funcionamiento normal del cluster. Solo actua cuando hay una **disrupcion voluntaria** (drain, eviction, actualizacion de nodo). Vamos a ver su configuracion actual y entender que garantiza cada uno.

```bash
# Ver todos los PDBs del namespace
kubectl get pdb -n lab-ha
```

Salida esperada:

```
NAME                   MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
pdb-max-unavailable    N/A             1                 2                     5m
pdb-min-available      2               N/A               1                     5m
```

La columna `ALLOWED DISRUPTIONS` es la clave:
- `pdb-min-available`: minAvailable=2, tenemos 3 Pods -> puede disrumpir 1 a la vez
- `pdb-max-unavailable`: maxUnavailable=1, tenemos 3 Pods -> puede disrumpir 1 a la vez

En este caso el resultado es el mismo (1 Pod a la vez), pero la diferencia emerge cuando escalas:
- Con 10 replicas y `minAvailable: 2`: todavia puedes disrumpir 8 a la vez
- Con 10 replicas y `maxUnavailable: 1`: sigues pudiendo disrumpir solo 1 a la vez

Inspeccionamos el detalle de cada PDB:

```bash
kubectl describe pdb pdb-min-available -n lab-ha
```

Salida esperada:

```
Name:           pdb-min-available
Namespace:      lab-ha
Min available:  2
Selector:       app=webapp-ha,tier=frontend
Status:
    Allowed disruptions:  1
    Current:              3
    Desired:              2
    Total:                3
Events:                   <none>
```

La seccion `Status` muestra el estado en tiempo real:
- `Current: 3` - cuantos Pods estan disponibles ahora mismo
- `Desired: 2` - cuantos necesitamos segun el minAvailable
- `Allowed disruptions: 1` - cuantos Pods podemos disrumpir sin violar el PDB

```bash
kubectl describe pdb pdb-max-unavailable -n lab-ha
```

Salida esperada:

```
Name:             pdb-max-unavailable
Namespace:        lab-ha
Max unavailable:  1
Selector:         app=webapp-spread,tier=backend
Status:
    Allowed disruptions:  2
    Current:              3
    Desired:              2
    Total:                3
Events:                   <none>
```

Nota: con `maxUnavailable: 1` y 3 Pods, `Allowed disruptions` es 2. Esto es correcto: podemos tener como maximo 1 no disponible, y como tenemos 3, podemos disrumpir hasta 2 antes de que el restante sea el unico activo (que ya seria 1 disponible, violando el maxUnavailable si cayera 1 mas).

---

## Paso 5: Explorar la sessionAffinity (8 min)

El Service `webapp-ha-service` tiene `sessionAffinity: ClientIP` configurado. Esto garantiza que peticiones desde la misma IP siempre lleguen al mismo Pod. Vamos a verificarlo.

```bash
# Ver la configuracion de los dos Services
kubectl get service webapp-ha-service -n lab-ha -o yaml | grep -A 5 "sessionAffinity"
```

Salida esperada:

```yaml
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

```bash
kubectl get service webapp-spread-service -n lab-ha -o yaml | grep -A 3 "sessionAffinity"
```

Salida esperada:

```yaml
  sessionAffinity: None
```

Para comparar el comportamiento en la practica, lanzamos un Pod de herramientas:

```bash
kubectl run curl-tools --image=curlimages/curl:latest -n lab-ha \
  --restart=Never --command -- sleep 3600
```

Esperamos a que este listo:

```bash
kubectl wait pod curl-tools --for=condition=Ready -n lab-ha --timeout=60s
```

Ahora hacemos multiples peticiones al Service con sessionAffinity. Con `ClientIP`, todas las peticiones desde la misma IP (el Pod `curl-tools`) deben llegar al mismo Pod backend:

```bash
# Obtener la IP del Service
SVC_IP=$(kubectl get service webapp-ha-service -n lab-ha -o jsonpath='{.spec.clusterIP}')
echo "IP del Service: $SVC_IP"

# Hacer 5 peticiones y ver desde que Pod responde (Server header)
for i in 1 2 3 4 5; do
  kubectl exec -n lab-ha curl-tools -- curl -s -I "http://${SVC_IP}" 2>/dev/null | grep -i server || echo "Peticion $i"
done
```

Salida esperada (todas las respuestas vienen del mismo Pod nginx):

```
Server: nginx/1.25.x
Server: nginx/1.25.x
Server: nginx/1.25.x
Server: nginx/1.25.x
Server: nginx/1.25.x
```

Para comparar con el Service sin sessionAffinity (round-robin), las peticiones se distribuirian entre los 3 Pods. En un entorno de prueba con nginx todos responden igual, pero en una app real con estado, el sessionAffinity garantiza que el usuario siempre encuentre su sesion en el mismo Pod.

Limpiamos el Pod de herramientas:

```bash
kubectl delete pod curl-tools -n lab-ha --ignore-not-found=true
```

---

## Paso 6: Observar el Auto-Recovery con pod-fallo-simulado (10 min)

Este es uno de los conceptos mas importantes de Kubernetes: cuando un Pod falla, el sistema lo reinicia automaticamente sin intervencion humana. El Pod `pod-fallo-simulado` esta disenado para crashear cada 60 segundos para que puedas observar este comportamiento.

```bash
# Observar el Pod en tiempo real
kubectl get pods pod-fallo-simulado -n lab-ha -w
```

Salida esperada (observa durante 2-3 minutos):

```
NAME                  READY   STATUS    RESTARTS   AGE
pod-fallo-simulado    1/1     Running   0          1m
pod-fallo-simulado    0/1     Error     0          1m30s
pod-fallo-simulado    0/1     Error     1          1m31s
pod-fallo-simulado    0/1     CrashLoopBackOff   1   1m35s
pod-fallo-simulado    1/1     Running   1          2m15s
pod-fallo-simulado    0/1     Error     1          3m15s
pod-fallo-simulado    0/1     CrashLoopBackOff   2   3m20s
```

Presiona `Ctrl+C` para salir del watch.

Cada linea es una transicion de estado:

1. `Running` -> El Pod inicio correctamente y la app esta funcionando
2. `Error` -> El proceso salio con codigo 1 (el `exit 1` del script)
3. `CrashLoopBackOff` -> Kubernetes noto que el Pod falla repetidamente y espera antes de reintentar
4. `Running` -> Kubernetes reinicio el Pod (el contador RESTARTS sube en 1)

El `CrashLoopBackOff` NO es una falla de Kubernetes: es una proteccion inteligente. Si Kubernetes reiniciara el Pod instantaneamente en un bucle infinito, consumiria toda la CPU del nodo. El backoff exponencial (10s, 20s, 40s, 80s, 160s, maximo 5min) reduce el impacto mientras espera que el problema se corrija.

Ahora vemos los logs del Pod para leer los mensajes que escribio antes de crashear:

```bash
# Ver los logs del ultimo crash (flag --previous para logs de la ejecucion anterior)
kubectl logs pod-fallo-simulado -n lab-ha --previous
```

Salida esperada:

```
Aplicacion iniciada. Funcionando durante 60 segundos...
ERROR: Fallo critico simulado (codigo de salida 1)
```

```bash
# Ver descripcion completa con historial de reinicios
kubectl describe pod pod-fallo-simulado -n lab-ha | tail -25
```

Salida esperada (seccion Events):

```
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  5m                 default-scheduler  Successfully assigned lab-ha/pod-fallo-simulado to minikube
  Normal   Pulled     5m                 kubelet            Container image "busybox:1.36" already present on machine
  Normal   Created    5m                 kubelet            Created container app-inestable
  Normal   Started    5m                 kubelet            Started container app-inestable
  Normal   Pulled     4m                 kubelet            Container image "busybox:1.36" already present on machine
  Normal   Created    4m                 kubelet            Created container app-inestable
  Normal   Started    4m                 kubelet            Started container app-inestable
  Warning  BackOff    3m (x3 over 4m)   kubelet            Back-off restarting failed container
```

La linea `Back-off restarting failed container` confirma que Kubernetes esta aplicando el backoff exponencial antes de reiniciar. Las lineas `Created` y `Started` son cada ciclo de restart.

---

## Paso 7: Verificar el ConfigMap y las Labels (5 min)

El ConfigMap `configuracion-ha` inyecta parametros de configuracion en los Pods del Deployment `webapp-anti-affinity`. Vamos a verificar que los Pods lo estan usando.

```bash
# Ver el contenido del ConfigMap
kubectl get configmap configuracion-ha -n lab-ha -o yaml
```

Salida esperada:

```yaml
apiVersion: v1
data:
  APP_STATUS: HA mode enabled
  AVAILABILITY_TARGET: "99.9"
  MAX_RESPONSE_TIME_MS: "500"
  MIN_REPLICAS: "3"
  PREFERRED_ZONE: multi-zona
kind: ConfigMap
metadata:
  name: configuracion-ha
  namespace: lab-ha
```

Verificamos que un Pod del Deployment tiene acceso a estas variables:

```bash
# Obtener el nombre de un Pod del Deployment
POD=$(kubectl get pods -n lab-ha -l app=webapp-ha -o jsonpath='{.items[0].metadata.name}')
echo "Inspeccionando Pod: $POD"

# Ver las variables de entorno inyectadas desde el ConfigMap
kubectl exec -n lab-ha $POD -- env | grep -E "AVAILABILITY|MAX_RESPONSE|MIN_REPLICAS|PREFERRED|APP_STATUS"
```

Salida esperada:

```
MAX_RESPONSE_TIME_MS=500
AVAILABILITY_TARGET=99.9
MIN_REPLICAS=3
PREFERRED_ZONE=multi-zona
APP_STATUS=HA mode enabled
```

Ahora revisamos las labels de los recursos del namespace para entender como los selectores conectan todo:

```bash
# Ver labels de los Pods del primer Deployment
kubectl get pods -n lab-ha -l app=webapp-ha --show-labels

# Ver labels de los Pods del segundo Deployment
kubectl get pods -n lab-ha -l app=webapp-spread --show-labels
```

Salida esperada (primera):

```
NAME                                   READY   STATUS    LABELS
webapp-anti-affinity-abc123-def45      1/1     Running   app=webapp-ha,pod-template-hash=abc123,strategy=anti-affinity,tier=frontend
webapp-anti-affinity-abc123-ghi67      1/1     Running   app=webapp-ha,pod-template-hash=abc123,strategy=anti-affinity,tier=frontend
webapp-anti-affinity-abc123-jkl89      1/1     Running   app=webapp-ha,pod-template-hash=abc123,strategy=anti-affinity,tier=frontend
```

Las labels son el pegamento del sistema: los Services usan `app=webapp-ha` para saber a que Pods enviar trafico, los PDBs usan `app=webapp-ha,tier=frontend` para saber que Pods proteger, y el podAntiAffinity usa las mismas labels para saber que Pods deben estar separados.

---

## Paso 8: Limpiar (2 min)

El script de limpieza elimina el namespace `lab-ha` y todos los recursos dentro de el (ambos Deployments, Pods, Services, PDBs, ConfigMap), luego restaura el contexto al namespace `default`.

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-ha
kubectl config set-context --current --namespace=default
```

Verificar que la limpieza fue exitosa:

```bash
kubectl get ns lab-ha
# Debe mostrar: Error from server (NotFound): namespaces "lab-ha" not found
```

---

## Resumen Visual

```
ALTA DISPONIBILIDAD: CAPAS DE PROTECCION
================================================================

  CAPA 1: REPLICAS (proteccion contra fallo de Pod)
  ┌──────────────────────────────────────────────┐
  │  3 replicas de cada Deployment               │
  │  Si 1 falla -> 2 siguen atendiendo trafico   │
  │  ReplicaSet crea un nuevo Pod automaticamente│
  └──────────────────────────────────────────────┘

  CAPA 2: DISTRIBUCION (proteccion contra fallo de nodo/zona)
  ┌──────────────────────────────────────────────┐
  │  podAntiAffinity: Pods en nodos distintos    │
  │  topologySpreadConstraints: Pods en zonas    │
  │  Si un nodo/zona falla -> otros siguen UP    │
  └──────────────────────────────────────────────┘

  CAPA 3: PDB (proteccion durante mantenimiento)
  ┌──────────────────────────────────────────────┐
  │  PDB garantiza minimo de Pods durante drain  │
  │  minAvailable: 2 -> siempre 2 Pods activos   │
  │  maxUnavailable: 1 -> como maximo 1 caido    │
  └──────────────────────────────────────────────┘

  CAPA 4: PROBES (deteccion y recuperacion automatica)
  ┌──────────────────────────────────────────────┐
  │  ReadinessProbe: Pod listo antes de trafico  │
  │  LivenessProbe: reinicio si deja de responder│
  │  CrashLoopBackOff: proteccion ante bucles    │
  └──────────────────────────────────────────────┘
```

## Lo Que Aprendiste en Este Lab

Al completar este lab has practicado los siguientes conceptos:

- **Replicas como base de la HA**: tres copias permiten absorber fallos sin downtime
- **podAntiAffinity preferida**: intenta distribuir Pods en nodos distintos para tolerancia a fallos de hardware
- **topologySpreadConstraints**: distribucion controlada entre zonas con maxSkew para evitar concentracion de Pods
- **PodDisruptionBudget minAvailable**: garantia absoluta del numero minimo de Pods activos durante disrupciones planificadas
- **PodDisruptionBudget maxUnavailable**: limite relativo del numero de Pods que pueden caer simultaneamente
- **sessionAffinity ClientIP**: stickiness de sesion para aplicaciones con estado
- **Auto-recovery y CrashLoopBackOff**: como Kubernetes detecta fallos y reinicia Pods con backoff exponencial
- **Labels como pegamento**: como Services, PDBs y affinity rules usan labels para conectar recursos
- **Disponibilidad numerica**: la diferencia practica entre 99.9% y 99.99% de uptime anual
