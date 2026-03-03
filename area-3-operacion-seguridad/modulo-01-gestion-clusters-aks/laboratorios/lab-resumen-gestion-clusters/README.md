# Resumen Practico: Gestión de Clústeres AKS

**Duracion:** 60 minutos | **Nivel:** Principiante a Intermedio | **Archivo:** `gestion-clusters-lab.yaml`

Un solo YAML despliega un entorno completo que simula los patrones de gestión de un cluster AKS en Minikube: namespace aislado con ResourceQuota y LimitRange, Deployments con réplicas y health checks, un DaemonSet de monitoreo, PodDisruptionBudgets para mantenimiento seguro, y un ConfigMap con configuración del cluster.

---

## Conceptos Previos: Antes de Empezar

Si nunca has trabajado con clusters gestionados en la nube, lee esta sección completa. Si ya conoces AKS o servicios similares, salta al Paso 0.

### ¿Qué es un cluster de Kubernetes?

Imagina que tienes una empresa con muchos empleados (tus aplicaciones) que necesitan oficinas (servidores) para trabajar. Un **cluster de Kubernetes** es como un edificio de oficinas inteligente que:

- **Asigna oficinas automáticamente**: Cuando llega un nuevo empleado (aplicación), el edificio encuentra una oficina libre con los recursos necesarios (CPU, memoria).
- **Reemplaza empleados enfermos**: Si un empleado se enferma (un contenedor falla), el edificio contrata automáticamente un reemplazo.
- **Puede crecer**: Si necesitas más espacio, agregas pisos al edificio (nodos al cluster).

Un cluster tiene dos partes fundamentales:

```
┌─────────────────────────────────────────────────────┐
│                   CLUSTER DE KUBERNETES              │
│                                                      │
│  ┌──────────────────────┐  ┌──────────────────────┐ │
│  │   CONTROL PLANE      │  │   WORKER NODES       │ │
│  │   (El cerebro)       │  │   (Los trabajadores)  │ │
│  │                      │  │                       │ │
│  │  • API Server        │  │  Nodo 1: [Pod][Pod]  │ │
│  │  • Scheduler         │  │  Nodo 2: [Pod][Pod]  │ │
│  │  • Controller Mgr    │  │  Nodo 3: [Pod][Pod]  │ │
│  │  • etcd (base datos) │  │                       │ │
│  └──────────────────────┘  └──────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

- **Control Plane** = el cerebro que toma decisiones (dónde colocar cada Pod, qué hacer si algo falla)
- **Worker Nodes** = los servidores donde realmente corren tus aplicaciones

### ¿Por qué usar un servicio gestionado como AKS?

Cuando instalas Kubernetes tú mismo (con herramientas como kubeadm), eres responsable de TODO: instalar el control plane, hacer backups de la base de datos (etcd), renovar certificados de seguridad que expiran cada año, y actualizar Kubernetes cuando sale una versión nueva. Es como ser propietario de una casa: tú arreglas las tuberías, el tejado y la electricidad.

**Azure Kubernetes Service (AKS)** es como mudarte a un apartamento en un edificio con administración: el propietario (Microsoft Azure) se encarga del control plane, los backups, los certificados y las actualizaciones. Tú solo te encargas de tus aplicaciones y los nodos donde corren.

```
Sin AKS (self-managed):              Con AKS (managed):
┌───────────────────────┐            ┌───────────────────────┐
│  TÚ haces TODO:       │            │  AZURE hace:          │
│  ✗ Instalar control   │            │  ✓ Control plane      │
│    plane               │            │  ✓ Backups etcd       │
│  ✗ Backups etcd       │            │  ✓ Certificados TLS   │
│  ✗ Renovar certs      │            │  ✓ Actualizaciones    │
│  ✗ Actualizar K8s     │            │  ✓ Alta disponibilidad│
│  ✗ Alta disponibilidad│            ├───────────────────────┤
├───────────────────────┤            │  TÚ haces:            │
│  TÚ haces:            │            │  ✓ Gestionar nodos    │
│  ✓ Gestionar nodos    │            │  ✓ Desplegar apps     │
│  ✓ Desplegar apps     │            │  ✓ Configurar accesos │
│  ✓ Configurar accesos │            │  ✓ Monitorear apps    │
│  ✓ Monitorear todo    │            └───────────────────────┘
└───────────────────────┘
```

### ¿Qué son los Node Pools?

Un **Node Pool** es un grupo de nodos (servidores) con las mismas características. En AKS, puedes tener diferentes node pools para diferentes tipos de trabajo:

- **System Node Pool**: Obligatorio. Ejecuta los componentes internos de Kubernetes (CoreDNS, metrics-server). Suele usar VMs pequeñas.
- **User Node Pool**: Opcional. Donde corren tus aplicaciones. Puedes tener varios con diferentes tamaños de VM.

```
Cluster AKS
├── System Node Pool (Standard_D2s_v3 - 2 CPU, 8GB)
│   ├── nodo-system-1: [CoreDNS] [metrics-server]
│   └── nodo-system-2: [kube-proxy] [CSI drivers]
│
├── User Node Pool "apps" (Standard_D4s_v3 - 4 CPU, 16GB)
│   ├── nodo-app-1: [webapp] [webapp] [api]
│   ├── nodo-app-2: [webapp] [api] [api]
│   └── nodo-app-3: [webapp] [api]
│
└── User Node Pool "gpu" (Standard_NC6s_v3 - GPU)
    └── nodo-gpu-1: [ml-training] [inference]
```

**Analogía**: Piensa en un hospital. El "system node pool" es la administración (recepción, contabilidad, mantenimiento) que mantiene el hospital funcionando. Los "user node pools" son las diferentes alas: urgencias, cirugía, pediatría, cada una con equipamiento diferente según las necesidades.

### ¿Qué es un ResourceQuota?

Un **ResourceQuota** limita cuántos recursos puede usar un namespace (un espacio de trabajo aislado). Sin quota, un equipo podría desplegar tantos Pods que consuma todos los recursos del cluster, dejando a los demás sin nada.

**Analogía**: Es como el presupuesto de un departamento en una empresa. El departamento de marketing no puede gastar más de $50,000 al mes, sin importar cuántos proyectos tenga. Si alcanza el límite, tiene que esperar al siguiente mes o pedir aprobación para más presupuesto.

### ¿Qué es un LimitRange?

Un **LimitRange** establece valores por defecto y límites para contenedores individuales dentro de un namespace. Si alguien despliega un Pod sin especificar recursos, el LimitRange le asigna valores automáticamente.

**Analogía**: Es como la política de viáticos de una empresa. Si un empleado no especifica cuánto necesita para un viaje, la empresa le asigna el estándar ($100/día para comida). Pero ningún empleado puede gastar más de $500/día, que es el máximo permitido.

### ¿Qué es un PodDisruptionBudget (PDB)?

Un **PDB** garantiza que siempre haya un número mínimo de Pods funcionando, incluso cuando se están haciendo tareas de mantenimiento (como actualizar nodos).

**Analogía**: En un restaurante con 3 meseros, el PDB dice "siempre deben estar trabajando al menos 2 meseros". Si necesitas enviar a uno a capacitación, puedes hacerlo. Pero no puedes enviar a 2 al mismo tiempo porque el restaurante no podría funcionar con solo 1.

### ¿Qué es un DaemonSet?

Un **DaemonSet** garantiza que un Pod específico corra en TODOS los nodos del cluster (o en un subconjunto). Se usa típicamente para agentes de monitoreo, recolectores de logs, o drivers de almacenamiento.

**Analogía**: Es como tener un guardia de seguridad en cada piso de un edificio. No importa cuántos pisos tenga el edificio, siempre hay exactamente un guardia por piso. Si se agrega un piso nuevo, automáticamente se asigna un guardia. Si se elimina un piso, el guardia se va.

---

## Conceptos Cubiertos en Este Lab

| Concepto | Qué demuestra | Relevancia Certificación |
|----------|---------------|--------------------------|
| Namespace | Aislamiento lógico de recursos | CKA, CKAD |
| ResourceQuota | Límites de recursos por namespace | CKA, CKAD |
| LimitRange | Defaults y límites por contenedor | CKA, CKAD |
| Deployment | Despliegue declarativo con réplicas | CKA, CKAD |
| Service | Exposición interna de aplicaciones | CKA, CKAD |
| PodDisruptionBudget | Disponibilidad durante mantenimiento | CKA |
| DaemonSet | Pod en cada nodo (monitoreo) | CKA |
| ConfigMap | Configuración externalizada | CKA, CKAD |
| Health Checks | Liveness y Readiness probes | CKA, CKAD |
| Node Pools (simulado) | Selección de nodos por labels | AKS Specialty |

---

## Diagrama Visual del Lab

```
┌─────────────────────────────────────────────────────────────┐
│  NAMESPACE: lab-gestion-clusters                            │
│                                                             │
│  ┌─── ResourceQuota ────────────────────────────────────┐   │
│  │ CPU req: 2 | CPU lim: 4 | Mem req: 1Gi | Pods: 20   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─── LimitRange ───────────────────────────────────────┐   │
│  │ Default: 100m/64Mi | Max: 1CPU/512Mi | Min: 50m/32Mi │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─── Deployment: webapp-produccion (3 réplicas) ───────┐   │
│  │  [webapp-1]  [webapp-2]  [webapp-3]                   │   │
│  │  100m/64Mi   100m/64Mi   100m/64Mi                    │   │
│  │  PDB: minAvailable=2                                  │   │
│  └────────────────────┬─────────────────────────────────┘   │
│                       │                                     │
│  ┌─── Service ────────┘                                 │   │
│  │  webapp-service (ClusterIP:80)                        │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─── Deployment: api-backend (2 réplicas) ─────────────┐   │
│  │  [api-1]     [api-2]                                  │   │
│  │  150m/128Mi  150m/128Mi                               │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─── DaemonSet: agente-monitoreo ──────────────────────┐   │
│  │  [monitor] en cada nodo (50m/32Mi)                    │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  [test-tools]  [cluster-config ConfigMap]                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Tabla Comparativa: Tipos de Node Pools en AKS

| Característica | System Node Pool | User Node Pool |
|---------------|-----------------|----------------|
| **Obligatorio** | Sí (siempre debe existir) | No (opcional) |
| **Propósito** | Componentes del sistema | Aplicaciones de usuario |
| **Pods típicos** | CoreDNS, kube-proxy, CSI | Tus Deployments, Jobs, etc. |
| **Tamaño VM típico** | Standard_D2s_v3 (2 CPU) | Standard_D4s_v3+ (4+ CPU) |
| **Mínimo nodos** | 1 (2 recomendado) | 0 (puede escalar a cero) |
| **Taint** | CriticalAddonsOnly | Sin taint por defecto |
| **Autoescalado** | Sí | Sí |

---

## Paso 0: Preparar Minikube (5 min)

Antes de ejecutar el lab, necesitas un cluster de Minikube funcionando. Si ya tienes uno corriendo, salta al Paso 1.

### ¿Qué es Minikube?

Minikube crea un cluster de Kubernetes de un solo nodo en tu computadora local. Es perfecto para aprender y practicar sin gastar dinero en la nube.

### Iniciar Minikube

```bash
# Iniciar Minikube con recursos suficientes para el lab
# --cpus 2: asigna 2 CPU cores al cluster
# --memory 4096: asigna 4 GB de RAM
minikube start --cpus 2 --memory 4096
```

**Salida esperada:**

```
😄  minikube v1.32.0 on Ubuntu 22.04
✨  Using the docker driver based on existing profile
👍  Starting control plane node minikube in cluster minikube
🐳  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
🔎  Verifying Kubernetes components...
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster
```

### Verificar que el cluster funciona

```bash
# Verificar que kubectl puede comunicarse con el cluster
kubectl cluster-info
```

**Salida esperada:**

```
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

```bash
# Ver los nodos del cluster (en Minikube solo hay 1)
kubectl get nodes
```

**Salida esperada:**

```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   2m    v1.28.3
```

### Habilitar el addon de metrics-server

```bash
# metrics-server permite ver el consumo de CPU y memoria
# En AKS viene habilitado por defecto
minikube addons enable metrics-server
```

**Salida esperada:**

```
💡  metrics-server is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
🌟  The 'metrics-server' addon is enabled
```

---

## Paso 1: Desplegar Todo (2 min)

Ahora vamos a desplegar todos los recursos del lab con un solo comando. Esto crea automáticamente el namespace, las quotas, los deployments, el daemonset y todo lo demás.

```bash
# Desplegar todos los recursos del lab
# kubectl apply -f: le dice a Kubernetes "crea o actualiza estos recursos"
kubectl apply -f gestion-clusters-lab.yaml
```

**Salida esperada:**

```
namespace/lab-gestion-clusters created
resourcequota/limites-cluster created
limitrange/defaults-contenedores created
deployment.apps/webapp-produccion created
service/webapp-service created
poddisruptionbudget.policy/webapp-pdb created
deployment.apps/api-backend created
daemonset.apps/agente-monitoreo created
configmap/cluster-config created
pod/test-tools created
```

**¿Qué acaba de pasar?** Con un solo comando, Kubernetes leyó el archivo YAML y creó 10 recursos diferentes. Cada línea de la salida confirma qué se creó. Si vuelves a ejecutar el mismo comando, verás "unchanged" o "configured" en lugar de "created", porque Kubernetes es **declarativo**: solo aplica los cambios necesarios.

### Verificar que todo está corriendo

```bash
# Esperar 30 segundos para que los Pods arranquen
# Luego verificar todos los recursos en el namespace
kubectl get all -n lab-gestion-clusters
```

**Salida esperada (tras ~30 segundos):**

```
NAME                                     READY   STATUS    RESTARTS   AGE
pod/agente-monitoreo-xxxxx               1/1     Running   0          30s
pod/api-backend-xxxxx-yyyyy              1/1     Running   0          30s
pod/api-backend-xxxxx-zzzzz              1/1     Running   0          30s
pod/test-tools                           1/1     Running   0          30s
pod/webapp-produccion-xxxxx-aaaaa        1/1     Running   0          30s
pod/webapp-produccion-xxxxx-bbbbb        1/1     Running   0          30s
pod/webapp-produccion-xxxxx-ccccc        1/1     Running   0          30s

NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/webapp-service   ClusterIP   10.96.xxx.xxx   <none>        80/TCP    30s

NAME                               DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   AGE
daemonset.apps/agente-monitoreo    1         1         1       1            1           30s

NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/api-backend         2/2     2            2           30s
deployment.apps/webapp-produccion   3/3     3            3           30s
```

**¿Cómo leer esta salida?** Cada sección muestra un tipo de recurso:
- **pod/**: Los Pods individuales. `1/1 Running` significa que el contenedor está corriendo.
- **service/**: Los Services. `ClusterIP` significa que solo es accesible dentro del cluster.
- **daemonset/**: Los DaemonSets. `DESIRED=1` porque Minikube tiene 1 nodo.
- **deployment/**: Los Deployments. `3/3 Ready` significa que las 3 réplicas están listas.

---

## Paso 2: Explorar el ResourceQuota (8 min)

El ResourceQuota limita cuántos recursos puede usar el namespace. Veamos cómo funciona.

### Ver la quota actual

```bash
# Mostrar los detalles del ResourceQuota
# "describe" muestra información detallada de cualquier recurso
kubectl describe resourcequota limites-cluster -n lab-gestion-clusters
```

**Salida esperada:**

```
Name:            limites-cluster
Namespace:       lab-gestion-clusters
Resource         Used     Hard
--------         ----     ----
configmaps       2        10
limits.cpu       1450m    4
limits.memory    832Mi    2Gi
pods             7        20
requests.cpu     750m     2
requests.memory  448Mi    1Gi
secrets          1        10
services         1        5
```

**¿Cómo leer esto?**
- **Used**: Lo que los Pods actuales están consumiendo.
- **Hard**: El límite máximo permitido.
- **requests.cpu: 750m / 2**: Los Pods han pedido 750 milicores de CPU. El máximo es 2000m (2 cores). Queda espacio para más Pods.
- **pods: 7 / 20**: Hay 7 Pods corriendo de un máximo de 20.

### Intentar exceder la quota

Vamos a intentar crear un Pod que exceda la quota para ver qué pasa:

```bash
# Intentar crear un Pod que pide demasiada CPU
kubectl run pod-excesivo \
  -n lab-gestion-clusters \
  --image=nginx:1.25-alpine \
  --overrides='{"spec":{"containers":[{"name":"nginx","image":"nginx:1.25-alpine","resources":{"requests":{"cpu":"3","memory":"64Mi"},"limits":{"cpu":"5","memory":"128Mi"}}}]}}'
```

**Salida esperada (ERROR):**

```
Error from server (Forbidden): pods "pod-excesivo" is forbidden: exceeded quota: limites-cluster,
requested: limits.cpu=5, requests.cpu=3,
used: limits.cpu=1450m, requests.cpu=750m,
limited: limits.cpu=4, requests.cpu=2
```

**¿Qué significa este error?** Kubernetes rechazó el Pod porque:
- Pediste `requests.cpu=3` pero ya se usan 750m de un máximo de 2 (2000m). Solo quedan 1250m.
- Pediste `limits.cpu=5` pero ya se usan 1450m de un máximo de 4 (4000m). Solo quedan 2550m, pero 5 supera el máximo absoluto.

**Esto es exactamente lo que pasa en un cluster AKS real**: si un equipo intenta desplegar más recursos de los que tiene asignados, Kubernetes lo rechaza inmediatamente.

---

## Paso 3: Explorar el LimitRange (8 min)

El LimitRange establece reglas para los contenedores individuales.

### Ver el LimitRange

```bash
kubectl describe limitrange defaults-contenedores -n lab-gestion-clusters
```

**Salida esperada:**

```
Name:       defaults-contenedores
Namespace:  lab-gestion-clusters
Type        Resource  Min   Max    Default Request  Default Limit  ...
----        --------  ---   ---    ---------------  -------------  ---
Container   cpu       50m   1      100m             200m
Container   memory    32Mi  512Mi  64Mi             128Mi
```

**¿Qué significa cada columna?**
- **Min**: Lo mínimo que un contenedor puede pedir (50m CPU, 32Mi memoria).
- **Max**: Lo máximo que un contenedor puede pedir (1 CPU, 512Mi memoria).
- **Default Request**: Si no especificas `requests`, se asigna este valor automáticamente.
- **Default Limit**: Si no especificas `limits`, se asigna este valor automáticamente.

### Probar los defaults

```bash
# Crear un Pod SIN especificar recursos
kubectl run pod-sin-recursos \
  -n lab-gestion-clusters \
  --image=nginx:1.25-alpine

# Ver qué recursos le asignó el LimitRange
kubectl get pod pod-sin-recursos -n lab-gestion-clusters -o jsonpath='{.spec.containers[0].resources}' | python3 -m json.tool
```

**Salida esperada:**

```json
{
    "limits": {
        "cpu": "200m",
        "memory": "128Mi"
    },
    "requests": {
        "cpu": "100m",
        "memory": "64Mi"
    }
}
```

**El LimitRange rellenó los valores automáticamente.** Aunque no pedimos recursos, el Pod tiene `requests` y `limits` asignados por el LimitRange. En un cluster AKS de producción, esto previene que alguien despliegue Pods sin límites que consuman todos los recursos.

### Limpiar el Pod de prueba

```bash
kubectl delete pod pod-sin-recursos -n lab-gestion-clusters
```

---

## Paso 4: Explorar los Deployments y el PDB (10 min)

### Ver los Deployments

```bash
# Ver el estado de los Deployments
kubectl get deployments -n lab-gestion-clusters -o wide
```

**Salida esperada:**

```
NAME                READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES              SELECTOR
api-backend         2/2     2            2           5m    api          nginx:1.25-alpine   app=api-backend,tier=backend
webapp-produccion   3/3     3            3           5m    nginx        nginx:1.25-alpine   app=webapp,tier=frontend
```

**¿Cómo leer la columna READY?**
- `3/3` = 3 de 3 réplicas deseadas están listas. Todo bien.
- `2/3` = Solo 2 de 3 están listas. Algo puede estar fallando.
- `0/3` = Ninguna réplica está lista. Problema serio.

### Ver el PodDisruptionBudget

```bash
kubectl get pdb -n lab-gestion-clusters
```

**Salida esperada:**

```
NAME         MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
webapp-pdb   2               N/A               1                     5m
```

**¿Cómo interpretar esto?**
- **MIN AVAILABLE: 2** = Siempre deben estar corriendo al menos 2 réplicas de webapp.
- **ALLOWED DISRUPTIONS: 1** = Kubernetes puede interrumpir hasta 1 Pod a la vez (porque hay 3 réplicas y el mínimo es 2).

### Simular un mantenimiento con el PDB

Vamos a intentar "drenar" el nodo (como cuando AKS actualiza un nodo):

```bash
# Ver cuántos Pods están en el nodo
kubectl get pods -n lab-gestion-clusters -o wide
```

**Salida esperada:**

```
NAME                                 READY   STATUS    RESTARTS   AGE   IP            NODE
agente-monitoreo-xxxxx               1/1     Running   0          5m    10.244.0.x    minikube
api-backend-xxxxx-yyyyy              1/1     Running   0          5m    10.244.0.x    minikube
api-backend-xxxxx-zzzzz              1/1     Running   0          5m    10.244.0.x    minikube
test-tools                           1/1     Running   0          5m    10.244.0.x    minikube
webapp-produccion-xxxxx-aaaaa        1/1     Running   0          5m    10.244.0.x    minikube
webapp-produccion-xxxxx-bbbbb        1/1     Running   0          5m    10.244.0.x    minikube
webapp-produccion-xxxxx-ccccc        1/1     Running   0          5m    10.244.0.x    minikube
```

**Nota**: En Minikube todos los Pods están en el mismo nodo. En un cluster AKS con múltiples nodos, los Pods se distribuirían entre nodos diferentes.

### Ver los detalles del PDB

```bash
kubectl describe pdb webapp-pdb -n lab-gestion-clusters
```

**Salida esperada:**

```
Name:           webapp-pdb
Namespace:      lab-gestion-clusters
Min available:  2
Selector:       app=webapp,tier=frontend
Status:
    Allowed disruptions:  1
    Current:              3
    Desired:              2
    Total:                3
```

**El PDB es crucial para AKS** porque cuando Azure actualiza los nodos (durante un upgrade de Kubernetes), necesita reiniciar los nodos uno por uno. El PDB le dice a AKS: "puedes apagar este nodo, pero solo si al menos 2 de mis 3 réplicas siguen corriendo en otros nodos".

---

## Paso 5: Explorar el DaemonSet de Monitoreo (8 min)

### Ver el DaemonSet

```bash
kubectl get daemonset -n lab-gestion-clusters
```

**Salida esperada:**

```
NAME               DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   AGE
agente-monitoreo   1         1         1       1            1           10m
```

**¿Por qué DESIRED=1?** Porque Minikube tiene un solo nodo. Un DaemonSet crea exactamente un Pod por nodo. Si tuvieras un cluster AKS con 5 nodos, verías `DESIRED=5`.

### Ver los logs del agente de monitoreo

```bash
# Ver qué está haciendo el agente de monitoreo
kubectl logs -l app=agente-monitoreo -n lab-gestion-clusters --tail=5
```

**Salida esperada:**

```
Agente de monitoreo iniciado en agente-monitoreo-xxxxx
[Mon Mar  3 10:30:15 UTC 2026] CPU: 0.42 | Mem: N/A
[Mon Mar  3 10:30:45 UTC 2026] CPU: 0.38 | Mem: N/A
[Mon Mar  3 10:31:15 UTC 2026] CPU: 0.55 | Mem: N/A
```

**Esto simula cómo funciona Container Insights en AKS**: un agente que corre en cada nodo recolectando métricas de CPU, memoria y red, y las envía a Azure Monitor para que puedas verlas en dashboards y configurar alertas.

### Comparar con un Pod normal

```bash
# Un DaemonSet no tiene "replicas" como un Deployment
# Se escala automáticamente con el número de nodos
kubectl describe daemonset agente-monitoreo -n lab-gestion-clusters | head -20
```

**Salida esperada:**

```
Name:           agente-monitoreo
Selector:       app=agente-monitoreo
Node-Selector:  <none>
Labels:         app=agente-monitoreo
                lab=gestion-clusters-resumen
                tier=monitoring
...
Desired Number of Nodes Scheduled: 1
Current Number of Nodes Scheduled: 1
Number of Nodes Scheduled with Up-to-date Pods: 1
```

---

## Paso 6: Explorar el ConfigMap y la Configuración (5 min)

### Ver el ConfigMap

```bash
kubectl get configmap cluster-config -n lab-gestion-clusters -o yaml
```

**Salida esperada:**

```yaml
apiVersion: v1
data:
  CLUSTER_NAME: aks-k8s-course
  CLUSTER_REGION: eastus
  ENVIRONMENT: production
  LOG_LEVEL: info
  MONITORING_ENABLED: "true"
  NETWORK_PLUGIN: azure-cni
  NETWORK_POLICY: azure
kind: ConfigMap
metadata:
  name: cluster-config
  namespace: lab-gestion-clusters
```

**¿Para qué sirve un ConfigMap?** Almacena configuración que tus aplicaciones pueden leer como variables de entorno o archivos. En AKS, usarías ConfigMaps para configurar:
- La URL de la base de datos
- El nivel de logging (debug, info, warn, error)
- Feature flags (activar/desactivar funcionalidades)
- Cualquier configuración que cambie entre entornos (dev, staging, producción)

### Verificar conectividad desde el Pod de prueba

```bash
# Usar el pod test-tools para verificar que el Service funciona
kubectl exec test-tools -n lab-gestion-clusters -- wget -qO- http://webapp-service.lab-gestion-clusters.svc.cluster.local 2>/dev/null | head -5
```

**Salida esperada:**

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
</head>
```

**¿Qué acaba de pasar?** Desde el Pod `test-tools`, hicimos una petición HTTP al Service `webapp-service`. Kubernetes resolvió el nombre DNS automáticamente y enrutó la petición a una de las 3 réplicas del Deployment `webapp-produccion`.

---

## Paso 7: Ver el Consumo de Recursos (5 min)

### Usar kubectl top

```bash
# Ver consumo de recursos por Pod
# Nota: metrics-server necesita ~1 minuto para recolectar datos
kubectl top pods -n lab-gestion-clusters
```

**Salida esperada:**

```
NAME                                 CPU(cores)   MEMORY(bytes)
agente-monitoreo-xxxxx               1m           5Mi
api-backend-xxxxx-yyyyy              1m           8Mi
api-backend-xxxxx-zzzzz              1m           7Mi
test-tools                           0m           1Mi
webapp-produccion-xxxxx-aaaaa        1m           8Mi
webapp-produccion-xxxxx-bbbbb        1m           7Mi
webapp-produccion-xxxxx-ccccc        1m           8Mi
```

**¿Cómo leer estos números?**
- **CPU 1m** = 1 milicore. Prácticamente no consume CPU (son contenedores nginx sin tráfico).
- **MEMORY 8Mi** = 8 Mebibytes. El contenedor nginx usa muy poca memoria en reposo.

### Comparar con la quota

```bash
# Ver cuánto de la quota se ha usado
kubectl describe resourcequota limites-cluster -n lab-gestion-clusters | grep -E "Resource|Used|Hard|---"
```

**Esto es lo que un administrador de AKS revisa regularmente** para:
- Saber cuánto espacio queda para más Deployments
- Detectar namespaces que están cerca de su límite
- Planificar cuándo agregar más nodos al cluster

---

## Paso 8: Simular Operaciones de AKS (10 min)

### 8.1: Escalar un Deployment (como autoescalar en AKS)

```bash
# Escalar la webapp de 3 a 5 réplicas
# En AKS, el Horizontal Pod Autoscaler hace esto automáticamente
kubectl scale deployment webapp-produccion -n lab-gestion-clusters --replicas=5
```

**Salida esperada:**

```
deployment.apps/webapp-produccion scaled
```

```bash
# Verificar que las nuevas réplicas arrancaron
kubectl get pods -n lab-gestion-clusters -l app=webapp
```

**Salida esperada:**

```
NAME                                READY   STATUS    RESTARTS   AGE
webapp-produccion-xxxxx-aaaaa       1/1     Running   0          15m
webapp-produccion-xxxxx-bbbbb       1/1     Running   0          15m
webapp-produccion-xxxxx-ccccc       1/1     Running   0          15m
webapp-produccion-xxxxx-ddddd       1/1     Running   0          10s
webapp-produccion-xxxxx-eeeee       1/1     Running   0          10s
```

### 8.2: Verificar que el PDB se actualizó

```bash
kubectl get pdb webapp-pdb -n lab-gestion-clusters
```

**Salida esperada:**

```
NAME         MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
webapp-pdb   2               N/A               3                     15m
```

**ALLOWED DISRUPTIONS ahora es 3** (era 1 antes). Con 5 réplicas y un mínimo de 2, Kubernetes puede interrumpir hasta 3 Pods simultáneamente durante mantenimiento.

### 8.3: Aplicar labels al nodo (simular node pools)

```bash
# En AKS, los nodos tienen labels automáticos según su node pool
# Vamos a simular esto en Minikube
kubectl label node minikube agentpool=userpool --overwrite
kubectl label node minikube kubernetes.azure.com/mode=user --overwrite

# Verificar los labels
kubectl get node minikube --show-labels | tr ',' '\n' | grep -E "agentpool|azure"
```

**Salida esperada:**

```
agentpool=userpool
kubernetes.azure.com/mode=user
```

### 8.4: Restaurar la escala original

```bash
# Volver a 3 réplicas
kubectl scale deployment webapp-produccion -n lab-gestion-clusters --replicas=3
```

---

## Troubleshooting: Problemas Comunes

### Error: "exceeded quota"

```
Error from server (Forbidden): exceeded quota: limites-cluster
```

**Causa**: Intentas crear recursos que exceden los límites del ResourceQuota.
**Solución**: Reduce los `requests`/`limits` del Pod, o aumenta la quota con `kubectl edit resourcequota`.

### Error: "must be less than or equal to cpu limit"

```
Error from server (Forbidden): minimum cpu usage per Container is 50m
```

**Causa**: El LimitRange tiene un mínimo de 50m CPU y el Pod pide menos.
**Solución**: Ajusta los recursos del contenedor para que estén dentro del rango del LimitRange.

### Pods en estado Pending

```
NAME          READY   STATUS    RESTARTS   AGE
mi-pod        0/1     Pending   0          2m
```

**Causa**: No hay recursos suficientes en el cluster para satisfacer los `requests` del Pod.
**Solución**:
1. Verifica la quota: `kubectl describe resourcequota -n <namespace>`
2. Verifica los nodos: `kubectl describe node minikube | grep -A5 "Allocated"`
3. Reduce los `requests` del Pod o agrega más nodos al cluster.

### DaemonSet no crea Pods en un nodo

**Causa**: El nodo tiene un **taint** que el DaemonSet no tolera.
**Solución**: Agrega una toleración al DaemonSet:
```yaml
spec:
  template:
    spec:
      tolerations:
      - operator: Exists    # Tolera TODOS los taints
```

---

## Limpieza (1 min)

Cuando termines de practicar, ejecuta el script de limpieza:

```bash
./cleanup.sh
```

**Salida esperada:**

```
🧹 Iniciando limpieza del Lab Resumen Gestión de Clusters...

  ✓ namespace/lab-gestion-clusters eliminado (todos los recursos incluidos)

Restaurando namespace por defecto...
  ✓ Contexto restaurado a namespace 'default'

🎉 Limpieza completada!
```

**¿Por qué basta con borrar el namespace?** Cuando eliminas un namespace, Kubernetes automáticamente elimina TODOS los recursos dentro de él: Pods, Services, Deployments, ConfigMaps, Secrets, ResourceQuotas, LimitRanges, PDBs, DaemonSets... todo. Es el equivalente a formatear una partición: limpia todo de una sola vez.

---

## Resumen de Conceptos Practicados

| Concepto | Comando Clave | Lo que aprendiste |
|----------|--------------|-------------------|
| Namespace | `kubectl get all -n <ns>` | Aislamiento lógico de recursos |
| ResourceQuota | `kubectl describe resourcequota` | Limitar recursos por namespace |
| LimitRange | `kubectl describe limitrange` | Defaults automáticos para contenedores |
| Deployment | `kubectl get deployments -o wide` | Despliegue declarativo con réplicas |
| PDB | `kubectl get pdb` | Disponibilidad durante mantenimiento |
| DaemonSet | `kubectl get daemonset` | Un Pod por nodo (monitoreo) |
| Escalado | `kubectl scale deployment --replicas=N` | Ajustar capacidad manualmente |
| Labels | `kubectl label node` | Identificar nodos para node pools |
| ConfigMap | `kubectl get configmap -o yaml` | Configuración externalizada |
| Probes | Definidas en el YAML | Health checks automáticos |

---

## Siguiente Paso

Ahora que entiendes cómo se gestiona un cluster y sus recursos, el siguiente módulo te enseñará **RBAC y Control de Acceso**: cómo controlar quién puede hacer qué dentro del cluster. Esto es fundamental en AKS porque normalmente múltiples equipos comparten el mismo cluster.
