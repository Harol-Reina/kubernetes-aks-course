# Laboratorio Integral AKS — Guia Completa "Para Dummies"

**Duracion**: 2 horas 30 minutos | **Nivel**: Intermedio | **Cluster**: Azure AKS

> Este laboratorio despliega una aplicacion multi-tier completa en AKS con namespaces,
> limites de recursos, generacion de carga, autoscaling y observabilidad con Prometheus + Grafana.
> Cada paso esta explicado para que lo sigas sin conocimiento previo avanzado.

---

## Que vas a construir

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CLUSTER AKS (1 nodo → hasta 4 nodos)            │
│                    Standard_D4alds_v6 (4 vCPU, 8 GB RAM)          │
│                                                                     │
│  ┌─────────────┐   ┌─────────────────┐   ┌──────────────┐          │
│  │ tienda-web  │   │   tienda-api    │   │  tienda-db   │          │
│  │             │   │                 │   │              │          │
│  │ nginx x2    │──▶│ api-gateway x2  │──▶│ redis x1     │          │
│  │ (frontend)  │   │ api-worker x1   │   │ (cache/db)   │          │
│  │             │   │                 │   │              │          │
│  │ Quota: 1CPU │   │ Quota: 3CPU     │   │ Quota: 1CPU  │          │
│  │        1Gi  │   │        2Gi      │   │        1Gi   │          │
│  └─────────────┘   └─────────────────┘   └──────────────┘          │
│                                                                     │
│  ┌─────────────┐   ┌──────────────────────────────────────┐        │
│  │ stress-test │   │           monitoring                 │        │
│  │             │   │                                      │        │
│  │ cpu-burner  │   │ Prometheus + Grafana + AlertManager  │        │
│  │ mem-eater   │   │ Node Exporter + Kube State Metrics   │        │
│  │             │   │                                      │        │
│  │ Quota: 4CPU │   │ Dashboards: CPU, RAM, Pods, Nodos    │        │
│  │        3Gi  │   │ Queries PromQL en tiempo real        │        │
│  └─────────────┘   └──────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────────────┘
```

**Flujo de comunicacion**:
```
Tu navegador
    │
    ▼
LoadBalancer (IP publica Azure)
    │
    ▼
nginx-frontend (tienda-web)  ──proxy /api/──▶  api-gateway (tienda-api)
                                                       │
                                                       ▼
                                                 redis (tienda-db)
```

---

## Conceptos Kubernetes que practicaras

| # | Concepto | Donde se usa | Que aprenderas |
|---|----------|-------------|----------------|
| 1 | Namespaces | 5 namespaces | Aislamiento logico entre capas |
| 2 | ResourceQuota | Cada namespace | Limitar recursos TOTALES de un namespace |
| 3 | LimitRange | Cada namespace | Defaults y min/max POR contenedor |
| 4 | Deployments | Frontend, API, workers | Gestionar replicas declarativamente |
| 5 | Services ClusterIP | Redis, API Gateway | Comunicacion interna entre Pods |
| 6 | Services LoadBalancer | Frontend, API external | Exponer al exterior via Azure LB |
| 7 | ConfigMaps | Configuracion nginx | Separar config de la imagen |
| 8 | Secrets | Password Redis | Almacenar datos sensibles |
| 9 | Liveness Probes | Redis, API, Frontend | K8s reinicia Pods que fallan |
| 10 | Readiness Probes | Redis, API, Frontend | K8s no envia trafico a Pods no listos |
| 11 | initContainers | Frontend | Tareas de setup antes del contenedor principal |
| 12 | HPA | API Gateway | Autoscaling horizontal por CPU/memoria |
| 13 | Cluster Autoscaler | Nodos AKS | Azure agrega nodos cuando no hay espacio |
| 14 | DNS Cross-Namespace | Frontend→API→Redis | `<svc>.<ns>.svc.cluster.local` |
| 15 | Prometheus + Grafana | Stack de monitoreo | Metricas, dashboards, alertas |
| 16 | PromQL | Queries de consumo | Lenguaje de consulta de Prometheus |
| 17 | OOMKilled | mem-eater | Que pasa cuando excedes memoria |
| 18 | CPU Throttling | cpu-burner, worker | Que pasa cuando excedes CPU |
| 19 | kubectl top | Verificacion | Monitoreo nativo de recursos |
| 20 | QoS Classes | Todos los Pods | Guaranteed, Burstable, BestEffort |

---

## Estructura de archivos del laboratorio

```
laboratorio-integral-aks/
├── README.md                              ← ESTAS AQUI (esta guia)
├── SETUP.md                              ← Prerequisitos y verificacion
├── cleanup.sh                            ← Limpieza total al finalizar
├── 01-namespaces/
│   ├── namespaces.yaml                   ← 5 namespaces con labels
│   ├── resource-quotas.yaml              ← Quotas por namespace
│   └── limit-ranges.yaml                ← Defaults por contenedor
├── 02-aplicacion/
│   ├── redis-secret.yaml                 ← Password de Redis
│   ├── redis-deployment.yaml             ← Redis + Service
│   ├── api-configmap.yaml                ← Configuracion nginx del API
│   ├── api-gateway-deployment.yaml       ← API Gateway + Services
│   ├── api-worker-deployment.yaml        ← Worker CPU-intensive
│   ├── frontend-configmap.yaml           ← HTML + config nginx frontend
│   └── frontend-deployment.yaml          ← Frontend + Service LoadBalancer
├── 03-stress/
│   ├── cpu-burner.yaml                   ← Pod que quema CPU
│   ├── mem-eater.yaml                    ← Pod que consume memoria
│   └── hpa-api.yaml                      ← HPA para API Gateway
├── 04-monitoring/
│   ├── prometheus-values.yaml            ← Valores Helm ajustados a 8GB
│   ├── instalar-prometheus.sh            ← Script de instalacion
│   └── queries-promql.md                 ← Queries PromQL documentadas
└── 05-verificacion/
    ├── test-conectividad.sh              ← Tests automatizados
    └── troubleshooting.md                ← Guia de problemas comunes
```

---

## Prerequisitos

Antes de empezar, verifica que tienes todo. Lee [SETUP.md](SETUP.md) para detalles.

```bash
# Verificacion rapida (copia y pega todo junto)
kubectl get nodes -o wide && echo "---" && helm version --short && echo "--- LISTO"
```

**Deberias ver**: al menos 1 nodo Ready y Helm v3.x.x.

---

# BLOQUE 1: Infraestructura Base (25 minutos)

## Paso 1.1: Verificar el cluster

Antes de crear nada, entiende tu cluster actual:

```bash
# Ver nodos disponibles
kubectl get nodes -o wide
```

**Salida esperada** (1 nodo):
```
NAME                                STATUS   ROLES    AGE   VERSION
aks-nodepool1-xxxxx-vmss000000      Ready    <none>   1d    v1.28.x
```

```bash
# Ver cuanta capacidad tiene el nodo
kubectl describe node $(kubectl get nodes -o name | head -1) | grep -A 5 "Allocatable"
```

**Salida esperada**:
```
Allocatable:
  cpu:                3860m     ← ~3.8 cores disponibles (de 4 totales, el SO usa el resto)
  memory:             6957Mi    ← ~6.8 GB disponibles (de 8 totales)
  ephemeral-storage:  28Gi
  pods:               110
```

> **Que significa esto?** Tu nodo tiene 4 vCPUs y 8 GB, pero Kubernetes reserva
> parte para el sistema operativo y los componentes del cluster (kubelet, kube-proxy).
> Lo "Allocatable" es lo que queda para tus Pods.

## Paso 1.2: Crear los namespaces

```bash
# Desde la raiz del laboratorio
kubectl apply -f 01-namespaces/namespaces.yaml
```

**Salida esperada**:
```
namespace/tienda-web created
namespace/tienda-api created
namespace/tienda-db created
namespace/stress-test created
```

**Verificar**:
```bash
# Ver todos los namespaces (los del lab tendran el label proyecto=laboratorio-integral)
kubectl get namespaces -l proyecto=laboratorio-integral
```

**Salida esperada**:
```
NAME           STATUS   AGE
stress-test    Active   5s
tienda-api     Active   5s
tienda-db      Active   5s
tienda-web     Active   5s
```

> **Para dummies**: Un namespace es como una carpeta en tu computadora. Los archivos
> de una carpeta no interfieren con los de otra. Aqui, los Pods de `tienda-web` no
> interfieren con los de `tienda-db`, aunque estan en el mismo cluster.

## Paso 1.3: Aplicar ResourceQuotas

Las quotas limitan cuantos recursos TOTALES puede usar cada namespace:

```bash
kubectl apply -f 01-namespaces/resource-quotas.yaml
```

**Salida esperada**:
```
resourcequota/quota-tienda-web created
resourcequota/quota-tienda-api created
resourcequota/quota-tienda-db created
resourcequota/quota-stress-test created
```

**Verificar una quota** (por ejemplo tienda-web):
```bash
kubectl describe resourcequota quota-tienda-web -n tienda-web
```

**Salida esperada**:
```
Name:            quota-tienda-web
Namespace:       tienda-web
Resource         Used  Hard
--------         ----  ----
limits.cpu       0     1
limits.memory    0     1Gi
pods             0     6
requests.cpu     0     500m
requests.memory  0     512Mi
services         0     4
```

> **Para dummies**: "Hard" es el limite maximo. "Used" es cuanto se usa ahora (0 porque
> aun no hay Pods). Cuando despliegues Pods, "Used" ira subiendo. Si intentas desplegar
> algo que supere "Hard", Kubernetes lo rechaza con un error.

## Paso 1.4: Aplicar LimitRanges

Los LimitRanges ponen defaults a los contenedores que no especifican requests/limits:

```bash
kubectl apply -f 01-namespaces/limit-ranges.yaml
```

**Verificar**:
```bash
kubectl describe limitrange limitrange-tienda-web -n tienda-web
```

**Salida esperada**:
```
Type        Resource  Min   Max    Default  Default Request
----        --------  ---   ---    -------  ---------------
Container   cpu       10m   500m   200m     50m
Container   memory    16Mi  512Mi  128Mi    64Mi
```

> **Para dummies**: Si creas un Pod sin decir cuanta CPU necesita, el LimitRange le
> asigna automaticamente 50m de request y 200m de limit. Esto evita que Pods "sin
> limites" consuman todo el nodo.

## Paso 1.5: Probar que la quota funciona

Vamos a crear un Pod SIN requests/limits para ver el LimitRange en accion:

```bash
# Crear un Pod simple sin especificar resources
kubectl run test-defaults --image=nginx:alpine -n tienda-web

# Esperar a que este Running
kubectl get pod test-defaults -n tienda-web -w
# (Presiona Ctrl+C cuando veas STATUS: Running)
```

```bash
# Ver que recursos le asigno el LimitRange automaticamente
kubectl get pod test-defaults -n tienda-web -o jsonpath='{.spec.containers[0].resources}' | python3 -m json.tool
```

**Salida esperada**:
```json
{
    "limits": {
        "cpu": "200m",
        "memory": "128Mi"
    },
    "requests": {
        "cpu": "50m",
        "memory": "64Mi"
    }
}
```

> El Pod recibio los defaults del LimitRange automaticamente.

```bash
# Ver como la quota refleja el consumo
kubectl describe resourcequota quota-tienda-web -n tienda-web
```

Ahora "Used" muestra los recursos del Pod de test.

```bash
# Eliminar el pod de test
kubectl delete pod test-defaults -n tienda-web
```

---

# BLOQUE 2: Desplegar la Aplicacion (30 minutos)

## Paso 2.1: Desplegar Redis (Base de datos)

Primero el Secret con la password, luego Redis:

```bash
# Crear el Secret
kubectl apply -f 02-aplicacion/redis-secret.yaml

# Desplegar Redis
kubectl apply -f 02-aplicacion/redis-deployment.yaml
```

**Verificar**:
```bash
# Ver que el Pod esta Running
kubectl get pods -n tienda-db -w
# (Espera hasta ver STATUS: Running, luego Ctrl+C)
```

**Salida esperada**:
```
NAME                     READY   STATUS    RESTARTS   AGE
redis-xxxxxxxxx-xxxxx    1/1     Running   0          30s
```

```bash
# Verificar que Redis responde
kubectl exec -n tienda-db deploy/redis -- redis-cli -a "Lab2024SecurePass!" ping
```

**Salida esperada**:
```
PONG
```

> **Para dummies**: Redis es una base de datos en memoria, super rapida.
> Aqui la usamos como la "capa de datos" de nuestra tienda. El Secret
> guarda la password para que no este visible en el YAML del Deployment.

## Paso 2.2: Desplegar el API Gateway

```bash
# Primero el ConfigMap con la configuracion nginx
kubectl apply -f 02-aplicacion/api-configmap.yaml

# Luego el Deployment y Services
kubectl apply -f 02-aplicacion/api-gateway-deployment.yaml
```

**Verificar**:
```bash
kubectl get pods -n tienda-api -w
# Espera a ver 2 pods Running (tiene 2 replicas)
```

**Salida esperada**:
```
NAME                           READY   STATUS    RESTARTS   AGE
api-gateway-xxxxxxxxx-xxxxx    1/1     Running   0          20s
api-gateway-xxxxxxxxx-yyyyy    1/1     Running   0          20s
```

```bash
# Probar que el API responde (desde dentro del cluster)
kubectl exec -n tienda-api deploy/api-gateway -- wget -qO- http://localhost:8080/api/info
```

**Salida esperada** (JSON con info del pod):
```json
{"service":"api-gateway","hostname":"api-gateway-xxxxx","server_addr":"10.x.x.x",...}
```

## Paso 2.3: Desplegar el Worker

```bash
kubectl apply -f 02-aplicacion/api-worker-deployment.yaml
```

**Verificar**:
```bash
kubectl get pods -n tienda-api
```

**Salida esperada** (3 pods: 2 api-gateway + 1 worker):
```
NAME                           READY   STATUS    RESTARTS   AGE
api-gateway-xxxxxxxxx-xxxxx    1/1     Running   0          2m
api-gateway-xxxxxxxxx-yyyyy    1/1     Running   0          2m
api-worker-xxxxxxxxx-zzzzz     1/1     Running   0          10s
```

## Paso 2.4: Desplegar el Frontend

```bash
# ConfigMap con HTML y configuracion nginx
kubectl apply -f 02-aplicacion/frontend-configmap.yaml

# Deployment y Services (incluye LoadBalancer)
kubectl apply -f 02-aplicacion/frontend-deployment.yaml
```

**Verificar**:
```bash
kubectl get pods -n tienda-web
```

**Salida esperada**:
```
NAME                        READY   STATUS    RESTARTS   AGE
frontend-xxxxxxxxx-xxxxx    1/1     Running   0          20s
frontend-xxxxxxxxx-yyyyy    1/1     Running   0          20s
```

## Paso 2.5: Obtener la IP publica

Azure tarda 1-3 minutos en asignar la IP del LoadBalancer:

```bash
# Observar hasta que EXTERNAL-IP aparezca
kubectl get svc frontend-external -n tienda-web -w
```

**Salida esperada** (espera hasta que `<pending>` cambie a una IP):
```
NAME                TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)
frontend-external   LoadBalancer   10.0.x.x      20.x.x.x      80:3xxxx/TCP
```

> **Presiona Ctrl+C** cuando veas la IP.

```bash
# Guardar la IP para usarla despues
FRONTEND_IP=$(kubectl get svc frontend-external -n tienda-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Frontend disponible en: http://$FRONTEND_IP"
```

**Abre esa URL en tu navegador**. Deberias ver la pagina del laboratorio con botones para verificar los servicios.

## Paso 2.6: Verificar comunicacion cross-namespace

Esta es la parte mas importante: los servicios en diferentes namespaces se comunican entre si.

```bash
# Desde un Pod en tienda-web, acceder al API Gateway en tienda-api
kubectl run test-cross-ns --rm -it --restart=Never \
    --image=busybox:1.36 \
    --namespace=tienda-web \
    -- wget -qO- --timeout=5 http://api-gateway.tienda-api.svc.cluster.local:8080/api/info
```

**Salida esperada**: JSON con los datos del API Gateway.

> **Para dummies**: La URL `api-gateway.tienda-api.svc.cluster.local` es el DNS interno
> de Kubernetes. Se lee asi:
> - `api-gateway` = nombre del Service
> - `tienda-api` = namespace donde esta
> - `svc.cluster.local` = sufijo del cluster
>
> Esto permite que un Pod en un namespace hable con un Service en otro namespace.

```bash
# Desde tienda-api, hacer PING a Redis en tienda-db
kubectl run test-redis-conn --rm -it --restart=Never \
    --image=redis:7-alpine \
    --namespace=tienda-api \
    -- redis-cli -h redis.tienda-db.svc.cluster.local -a "Lab2024SecurePass!" ping
```

**Salida esperada**:
```
PONG
```

## Paso 2.7: Ver el estado de las quotas

Ahora que hay Pods desplegados, las quotas muestran el consumo real:

```bash
# Ver quotas de todos los namespaces del lab
for NS in tienda-web tienda-api tienda-db; do
    echo "=== $NS ==="
    kubectl describe resourcequota -n $NS | grep -E "Resource|Used|Hard|---"
    echo ""
done
```

---

# BLOQUE 3: Generacion de Carga y Autoscaling (20 minutos)

## Paso 3.1: Desplegar el CPU Burner

Este Pod intenta consumir toda la CPU posible (contenido por su limit):

```bash
kubectl apply -f 03-stress/cpu-burner.yaml
```

```bash
# Esperar a que este Running
kubectl get pods -n stress-test -w
```

```bash
# Ver cuanta CPU esta consumiendo (espera ~1 min para que haya metricas)
kubectl top pods -n stress-test
```

**Salida esperada**:
```
NAME                          CPU(cores)   MEMORY(bytes)
cpu-burner-xxxxxxxxx-xxxxx    999m         1Mi
```

> El Pod intenta usar 2 cores pero su limit es 1 CPU. Kubernetes lo "throttlea"
> (lo frena) a ~1000m. No lo mata — solo lo ralentiza. Esto es diferente de la memoria.

## Paso 3.2: Desplegar el Memory Eater

```bash
kubectl apply -f 03-stress/mem-eater.yaml
```

```bash
# Ver consumo de memoria
kubectl top pods -n stress-test
```

**Salida esperada**:
```
NAME                          CPU(cores)   MEMORY(bytes)
cpu-burner-xxxxxxxxx-xxxxx    999m         1Mi
mem-eater-xxxxxxxxx-xxxxx     50m          200Mi
```

> El mem-eater usa 200Mi de los 256Mi de limit. Esta dentro del rango, funciona bien.

## Paso 3.3: Provocar un OOMKilled (ejercicio educativo)

Ahora vamos a cambiar el mem-eater para que pida MAS memoria de la permitida:

```bash
# Escalar mem-eater con mas memoria de la permitida
# Creamos un Pod que pide 400MB pero su limit es 256Mi → OOMKilled
kubectl run mem-eater-oom --restart=Always \
    --image=polinux/stress \
    --namespace=stress-test \
    --limits="cpu=200m,memory=256Mi" \
    --requests="cpu=100m,memory=128Mi" \
    -- stress --vm 1 --vm-bytes 400M --vm-hang 60 --timeout 7200s
```

```bash
# Observar como el Pod falla y se reinicia
kubectl get pods -n stress-test -w
```

**Salida esperada** (despues de ~10 segundos):
```
NAME                          READY   STATUS      RESTARTS   AGE
mem-eater-oom                 0/1     OOMKilled   0          10s
mem-eater-oom                 0/1     CrashLoopBackOff   1   15s
```

> **Para dummies**: OOMKilled = Out Of Memory Killed. El kernel de Linux detecto que
> el contenedor supero su limite de memoria y lo mato. Kubernetes lo reinicia, pero
> vuelve a fallar → entra en CrashLoopBackOff (espera progresiva entre reinicios).

```bash
# Ver los detalles del OOMKilled
kubectl describe pod mem-eater-oom -n stress-test | grep -A 5 "Last State"
```

**Salida esperada**:
```
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
```

> Exit Code 137 = el proceso fue matado por una signal (SIGKILL del OOM killer).

```bash
# Limpiar el Pod OOMKilled
kubectl delete pod mem-eater-oom -n stress-test
```

## Paso 3.4: Activar el HPA (Horizontal Pod Autoscaler)

```bash
kubectl apply -f 03-stress/hpa-api.yaml
```

```bash
# Ver el estado del HPA
kubectl get hpa -n tienda-api
```

**Salida esperada**:
```
NAME              REFERENCE              TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
hpa-api-gateway   Deployment/api-gateway  <unknown>/50%   2         6         2          10s
```

> `<unknown>` cambia a un porcentaje real despues de ~30 segundos.

## Paso 3.5: Generar carga para activar el HPA

Abre una **segunda terminal** y ejecuta:

```bash
# Generar carga continua al API Gateway (dejar corriendo 2-3 minutos)
kubectl run load-generator --rm -it --restart=Never \
    --image=busybox:1.36 \
    -- sh -c "while true; do wget -q -O- http://api-gateway.tienda-api.svc.cluster.local:8080/api/info > /dev/null 2>&1; done"
```

**En la primera terminal**, observa el HPA:

```bash
kubectl get hpa -n tienda-api -w
```

**Salida esperada** (despues de 1-2 minutos):
```
NAME              REFERENCE              TARGETS    MINPODS   MAXPODS   REPLICAS
hpa-api-gateway   Deployment/api-gateway  67%/50%    2         6         3
```

> Las replicas subieron de 2 a 3 (o mas). El HPA detecto que el CPU promedio
> supero el 50% y creo replicas adicionales para distribuir la carga.

**Detener el load-generator**: Presiona Ctrl+C en la segunda terminal.

## Paso 3.6: Escalar CPU Burner para provocar autoscaling de nodos

```bash
# Escalar a 3 replicas del CPU Burner (cada una pide 500m CPU)
kubectl scale deployment cpu-burner -n stress-test --replicas=3
```

```bash
# Ver si hay pods Pending (no caben en el nodo actual)
kubectl get pods -n stress-test
```

Si el nodo no tiene capacidad para 3 CPU Burners, veras pods en `Pending`.
El cluster autoscaler de AKS detectara esto y agregara un nodo nuevo:

```bash
# Observar nodos (puede tardar 2-5 minutos)
kubectl get nodes -w
```

**Salida esperada** (cuando el autoscaler actua):
```
NAME                                STATUS     ROLES    AGE
aks-nodepool1-xxxxx-vmss000000      Ready      <none>   1d
aks-nodepool1-xxxxx-vmss000001      NotReady   <none>   30s    ← NUEVO NODO
aks-nodepool1-xxxxx-vmss000001      Ready      <none>   90s    ← Ya listo
```

> **Para dummies**: El cluster autoscaler vio que habia Pods esperando porque
> no cabian en el nodo existente. Automaticamente le pidio a Azure que creara
> otro nodo. Cuando el nodo esta Ready, los Pods Pending se mueven ahi.

```bash
# Ver en que nodo esta cada Pod
kubectl get pods -A -o wide | grep -E "tienda|stress"
```

---

# BLOQUE 4: Observabilidad — Prometheus + Grafana (35 minutos)

## Paso 4.1: Instalar Prometheus + Grafana

```bash
# Ejecutar el script de instalacion (tarda 2-3 minutos)
bash 04-monitoring/instalar-prometheus.sh
```

**Salida esperada**:
```
[5/5] Verificando pods en namespace monitoring...

NAME                                                     READY   STATUS    RESTARTS   AGE
prometheus-grafana-xxxxxxxxx-xxxxx                       3/3     Running   0          60s
prometheus-kube-prometheus-operator-xxxxxxxxx-xxxxx      1/1     Running   0          60s
prometheus-kube-state-metrics-xxxxxxxxx-xxxxx            1/1     Running   0          60s
prometheus-prometheus-node-exporter-xxxxx                1/1     Running   0          60s
prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   0          45s
```

> Si algun Pod tarda en arrancar, espera 2-3 minutos. Es normal.

## Paso 4.2: Acceder a Grafana

```bash
# Abrir tunel al servicio de Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```

> **Deja esta terminal abierta** mientras uses Grafana.

**En tu navegador**, abre: `http://localhost:3000`

**Credenciales**:
- **Usuario**: `admin`
- **Password**: `LabAKS2024!`

## Paso 4.3: Explorar los dashboards de Kubernetes

Una vez dentro de Grafana:

1. **Click** en el icono de menu (hamburguesa, arriba a la izquierda)
2. **Click** en "Dashboards"
3. Busca y abre: **"Kubernetes / Compute Resources / Namespace (Pods)"**
4. En el dropdown **"namespace"** (arriba), selecciona `tienda-api`

**Que veras**:
- Graficos de CPU por Pod (el worker y los api-gateways)
- Graficos de memoria por Pod
- Consumo vs requests y limits (barras amarillas y rojas)

5. Cambia el namespace a `stress-test`

**Que veras**:
- El cpu-burner consumiendo casi todo su limit de CPU
- El mem-eater usando ~200Mi de memoria

6. Abre el dashboard: **"Kubernetes / Compute Resources / Cluster"**

**Que veras**:
- Vista global: CPU y memoria de todo el cluster
- Cuantos nodos hay activos
- Distribucion de carga entre nodos

7. Abre: **"Node Exporter / Nodes"**

**Que veras**:
- Metricas del sistema operativo de cada nodo
- Uso de disco, red, CPU por core

## Paso 4.4: Acceder a Prometheus directamente

Abre otra terminal:

```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
```

**En tu navegador**: `http://localhost:9090`

### Queries PromQL para probar

Copia y pega estas queries en el campo de busqueda de Prometheus:

**1. CPU por namespace (las del lab)**:
```promql
sum(rate(container_cpu_usage_seconds_total{namespace=~"tienda-.*|stress-test"}[5m])) by (namespace)
```

> Click en "Execute" y luego en la pestana "Graph".
> Veras lineas de cada namespace con su consumo de CPU en el tiempo.

**2. Memoria por Pod**:
```promql
sum(container_memory_usage_bytes{namespace=~"tienda-.*|stress-test"}) by (pod, namespace) / 1024 / 1024
```

> Muestra la memoria en MB de cada Pod.

**3. Quotas: uso vs limite**:
```promql
kube_resourcequota{namespace=~"tienda-.*|stress-test", resource="limits.cpu"}
```

> Muestra dos lineas por namespace: `type="used"` (cuanto se usa) y `type="hard"` (el limite).

**4. Pods con reinidos (problemas)**:
```promql
sum(kube_pod_container_status_restarts_total{namespace=~"tienda-.*|stress-test"}) by (pod, namespace) > 0
```

> Si el mem-eater-oom estuvo corriendo, veras reinicios aqui.

**5. Nodos del cluster**:
```promql
count(kube_node_status_condition{condition="Ready", status="true"})
```

> Muestra cuantos nodos estan Ready. Deberia ser 1, 2, o mas si autoescalo.

> Consulta [04-monitoring/queries-promql.md](04-monitoring/queries-promql.md) para mas queries.

## Paso 4.5: Ver consumo con kubectl top

Sin salir de la terminal:

```bash
# Consumo de recursos por nodo
kubectl top nodes
```

**Salida esperada**:
```
NAME                                CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
aks-nodepool1-xxxxx-vmss000000      1250m        32%    3200Mi          46%
aks-nodepool1-xxxxx-vmss000001      850m         22%    1100Mi          16%
```

```bash
# Consumo por Pod en todos los namespaces del lab
kubectl top pods -n tienda-web
kubectl top pods -n tienda-api
kubectl top pods -n tienda-db
kubectl top pods -n stress-test
```

```bash
# Top consumidores de CPU en todo el cluster
kubectl top pods -A --sort-by=cpu | head -10
```

---

# BLOQUE 5: Exploracion y Troubleshooting (15 minutos)

## Paso 5.1: Identificar que namespace consume mas

```bash
# Resumen de quotas de todos los namespaces
for NS in tienda-web tienda-api tienda-db stress-test; do
    echo "=== $NS ==="
    kubectl describe resourcequota -n $NS | grep -E "^Resource|requests\.cpu|requests\.memory|limits\.cpu|limits\.memory|pods"
    echo ""
done
```

## Paso 5.2: Ver la distribucion de Pods en nodos

```bash
# Que Pods estan en cada nodo
kubectl get pods -A -o wide --field-selector status.phase=Running | grep -E "tienda|stress|monitoring"
```

> Observa la columna NODE. Los Pods se distribuyen entre los nodos disponibles.

## Paso 5.3: Ver eventos del cluster

```bash
# Eventos recientes (autoscaler, scheduling, probes)
kubectl get events -A --sort-by='.lastTimestamp' | tail -20
```

Busca eventos como:
- `ScaledUp` / `ScaledDown` — del HPA
- `TriggeredScaleUp` — del cluster autoscaler
- `Pulling` / `Pulled` — descarga de imagenes
- `Unhealthy` — probes fallando

## Paso 5.4: Verificar QoS Classes

```bash
# Ver la QoS Class de cada Pod
kubectl get pods -n tienda-api -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
```

**Salida esperada**:
```
NAME                           QOS
api-gateway-xxxxxxxxx-xxxxx    Burstable
api-gateway-xxxxxxxxx-yyyyy    Burstable
api-worker-xxxxxxxxx-zzzzz     Burstable
```

> **Burstable** = tiene requests diferentes de limits. Si requests == limits seria
> **Guaranteed** (mayor prioridad). Si no tiene ni requests ni limits seria
> **BestEffort** (primera victima si el nodo se queda sin memoria).

## Paso 5.5: Ejecutar test automatizado

```bash
bash 05-verificacion/test-conectividad.sh
```

---

# BLOQUE 6: Cierre y Limpieza (5 minutos)

## Resumen de lo que hiciste

| Bloque | Que desplegaste | Que aprendiste |
|--------|----------------|---------------|
| 1 | 5 Namespaces + Quotas + LimitRanges | Governance y aislamiento |
| 2 | Redis + API Gateway + Frontend | Deployments, Services, ConfigMaps, Secrets, Probes, DNS cross-namespace |
| 3 | CPU Burner + Mem Eater + HPA | Stress testing, OOMKilled, CPU throttling, autoscaling |
| 4 | Prometheus + Grafana | Metricas, dashboards, PromQL |
| 5 | Troubleshooting | kubectl top, eventos, QoS Classes |

## Reducir carga antes de limpiar

```bash
# Reducir cpu-burners para que el cluster reduzca nodos
kubectl scale deployment cpu-burner -n stress-test --replicas=0
kubectl scale deployment mem-eater -n stress-test --replicas=0
```

## Limpieza completa

```bash
bash cleanup.sh
```

> Esto elimina todos los namespaces, Prometheus, y los CRDs.
> El cluster AKS queda intacto. Los nodos extra del autoscaler
> se eliminan solos en ~10 minutos al no haber carga.

---

## Preguntas de Repaso

<details>
<summary>1. Cual es la diferencia entre ResourceQuota y LimitRange?</summary>

**ResourceQuota** limita el TOTAL de recursos de un namespace (ej: maximo 3 CPU entre todos los Pods).
**LimitRange** limita los recursos POR CONTENEDOR individual (ej: cada contenedor maximo 500m CPU)
y ademas define defaults para contenedores que no especifican resources.
</details>

<details>
<summary>2. Que pasa si un Pod supera su limit de CPU vs su limit de memoria?</summary>

- **CPU**: Se throttlea (se ralentiza). El kernel lo frena pero NO lo mata. El Pod sigue corriendo pero mas lento.
- **Memoria**: Se mata con OOMKilled. El kernel no puede "ralentizar" la memoria — si no hay espacio, mata el proceso. Kubernetes reinicia el Pod.
</details>

<details>
<summary>3. Como se comunican Pods en diferentes namespaces?</summary>

Via DNS interno de Kubernetes: `<nombre-service>.<namespace>.svc.cluster.local`
Ejemplo: `redis.tienda-db.svc.cluster.local:6379`
</details>

<details>
<summary>4. Que es el Cluster Autoscaler y cuando actua?</summary>

Es un componente de AKS que agrega o elimina nodos automaticamente.
**Agrega nodos** cuando hay Pods en estado Pending porque no caben en los nodos actuales.
**Elimina nodos** cuando un nodo esta infrautilizado y sus Pods caben en otros nodos.
</details>

<details>
<summary>5. Que diferencia hay entre un Service ClusterIP y LoadBalancer?</summary>

- **ClusterIP**: Solo accesible DENTRO del cluster. Otros Pods pueden llamarlo, pero no se puede acceder desde internet.
- **LoadBalancer**: Azure crea un Azure Load Balancer con una IP publica. Accesible desde internet.
</details>

<details>
<summary>6. Para que sirve un LimitRange si ya tengo ResourceQuota?</summary>

ResourceQuota rechaza Pods sin resources definidos (porque no puede calcular si exceden la quota).
LimitRange pone defaults automaticamente, permitiendo que esos Pods se creen sin error.
Ademas, LimitRange impide que un solo contenedor pida demasiados recursos (max/min por contenedor).
</details>

<details>
<summary>7. Que query de PromQL usarias para ver que namespace consume mas CPU?</summary>

```promql
sum(rate(container_cpu_usage_seconds_total{namespace=~"tienda-.*|stress-test"}[5m])) by (namespace)
```
</details>

<details>
<summary>8. Que son las QoS Classes y por que importan?</summary>

Kubernetes asigna una clase de servicio a cada Pod:
- **Guaranteed**: requests == limits. Ultima prioridad para ser eliminado. Mas estable.
- **Burstable**: requests < limits. Prioridad intermedia.
- **BestEffort**: sin requests ni limits. Primera victima si el nodo se queda sin recursos.

Importa porque cuando el nodo tiene presion de memoria, Kubernetes elimina primero los BestEffort, luego Burstable, y Guaranteed al final.
</details>
