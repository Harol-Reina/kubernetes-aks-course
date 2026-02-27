# Laboratorio 03: Resource Limits en Produccion

**Duracion estimada:** 50-60 minutos
**Nivel:** Avanzado
**Objetivo:** Implementar best practices y autoscaling en produccion

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Tier System (QoS por criticidad)** | Clasificacion de workloads en Tier 1 (Guaranteed), Tier 2 (Burstable) y Tier 3 (Batch) segun su criticidad de negocio. Define la estrategia de resources y autoscaling para cada capa |
| **Vertical Pod Autoscaler (VPA)** | Ajusta automaticamente los requests y limits de containers basandose en el uso historico real. Modo "Off" solo recomienda; modo "Auto" aplica cambios reiniciando Pods. Ideal para apps stateful |
| **Horizontal Pod Autoscaler (HPA)** | Escala el numero de replicas basandose en metricas de CPU, memoria o custom metrics de Prometheus. Politicas de comportamiento controlan la velocidad de scale up y scale down |
| **Pod-level Resources (K8s 1.34+)** | Feature gate PodLevelResources permite definir un presupuesto total de recursos a nivel de Pod que comparten todos los containers, simplificando la configuracion de sidecars |
| **Monitoreo con Prometheus** | Reglas de alerting para detectar OOMKilled, CPU throttling alto, memoria cerca del limite y Pods Pending prolongados. Base para optimizacion proactiva de recursos |
| **Best Practices de Produccion** | Combinacion de PodAntiAffinity, PriorityClass, ServiceAccount dedicado, ephemeral-storage limits, security context estricto y emptyDir con sizeLimit |
| **PriorityClass y Preemption** | Asigna prioridad numerica a los Pods para controlar el orden de scheduling y preemption cuando el cluster esta bajo presion de recursos |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML independientes y documentados:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `tier1-database.yaml` | 1 | StatefulSet PostgreSQL + Headless Service con QoS Guaranteed |
| `tier2-api.yaml` | 1 | Deployment API REST + Service ClusterIP con QoS Burstable y sidecar |
| `tier3-batch.yaml` | 1 | CronJob de reportes nocturnos con recursos bajos (Tier 3) |
| `vpa-recommend.yaml` | 2 | VPA en modo Off: genera recomendaciones sin aplicar cambios |
| `vpa-auto.yaml` | 2 | VPA en modo Auto: actualiza resources reiniciando Pods automaticamente |
| `hpa-cpu.yaml` | 3 | HPA basado en CPU (70%) con politicas de scale up agresivo |
| `hpa-multi.yaml` | 3 | HPA con CPU (70%) y memoria (80%) simultaneamente |
| `hpa-custom.yaml` | 3 | HPA con metricas custom de Prometheus (RPS y latencia) |
| `pod-level-app.yaml` | 4 | Deployment con Pod-level resources compartidos (K8s 1.34+) |
| `container-level-app.yaml` | 4 | Deployment con container-level resources tradicionales (comparacion) |
| `prometheus-alerts.yaml` | 5 | ConfigMap con reglas de alerting para OOMKilled y throttling |
| `production-app.yaml` | 6 | Deployment completo con todas las best practices de produccion |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Elimina namespace production, PriorityClass y recursos del laboratorio |

---

## Requisitos Previos

- Cluster Kubernetes 1.28+
- `kubectl` configurado
- `metrics-server` instalado (ver SETUP.md)
- Completar **Lab 01** y **Lab 02** (recomendado)
- Prometheus (opcional para Ejercicio 5)
- VPA instalado (opcional para Ejercicio 2)

Ver [SETUP.md](./SETUP.md) para instrucciones de instalacion y verificacion del entorno.

---

## Objetivos de Aprendizaje

Al completar este laboratorio, seras capaz de:

1. Implementar best practices de resource management en produccion
2. Configurar Vertical Pod Autoscaler (VPA) en modos recommend y auto
3. Configurar Horizontal Pod Autoscaler (HPA) con CPU, memoria y metricas custom
4. Usar Pod-level resources (K8s 1.34+) para simplificar sidecars
5. Monitorear recursos con Prometheus y crear alertas
6. Aplicar QoS strategies segun criticidad (Tier System)
7. Optimizar costos y rendimiento con PriorityClass y autoscaling

---

## Contexto Teorico

### Best Practices Framework

```
+---------------------------------------------+
|  Tier 1: CRITICO (Guaranteed)               |
|  - Bases de datos                           |
|  - Payment services                         |
|  - Auth services                            |
|  +- QoS: Guaranteed                         |
|  +- Resources: request == limit             |
|  +- Autoscaling: VPA (vertical)             |
|  +- Monitoring: Alertas estrictas           |
+---------------------------------------------+
              |
              v
+---------------------------------------------+
|  Tier 2: IMPORTANTE (Burstable)             |
|  - API REST                                 |
|  - Web frontends                            |
|  - Background workers                       |
|  +- QoS: Burstable                          |
|  +- Resources: request < limit              |
|  +- Autoscaling: HPA (horizontal)           |
|  +- Monitoring: Alertas moderadas           |
+---------------------------------------------+
              |
              v
+---------------------------------------------+
|  Tier 3: BATCH/DEV (BestEffort)             |
|  - Batch jobs                               |
|  - CI/CD pipelines                          |
|  - Development environments                 |
|  +- QoS: BestEffort o Burstable bajo       |
|  +- Resources: requests bajos o vacios      |
|  +- Autoscaling: Opcional                   |
|  +- Monitoring: Basico                      |
+---------------------------------------------+
```

### Autoscaling Strategies

| Strategy | Tipo | Cuando Usar | Beneficios |
|----------|------|-------------|------------|
| **VPA** | Vertical (resize containers) | Carga predecible, stateful apps | Optimiza requests/limits automaticamente |
| **HPA** | Horizontal (mas Pods) | Carga variable, stateless apps | Escala segun demanda |
| **Cluster Autoscaler** | Horizontal (mas nodos) | Cluster elastico | Agrega/remueve nodos segun carga |
| **Combinado** | VPA + HPA | Apps complejas | Mejor adaptacion a patrones variados |

---

## Ejercicio 1: Implementar Tier System (Criticality-based QoS)

### Paso 1.1: Crear el namespace y desplegar Tier 1 (Critico - Guaranteed)

Primero crear el namespace de produccion:

```bash
kubectl create namespace production
```

Salida esperada:

```
namespace/production created
```

Revisa el archivo `tier1-database.yaml`:

```bash
cat tier1-database.yaml
```

Puntos clave del manifiesto:
- **StatefulSet** con `serviceName` para Headless Service
- **QoS Guaranteed**: requests identicos a limits en CPU y memoria (`cpu: "2"`, `memory: "4Gi"`)
- **initContainer** para permisos de directorio de datos con recursos propios
- **Headless Service** (`clusterIP: None`) requerido para StatefulSets
- **volumeClaimTemplates** para persistencia de datos de PostgreSQL

```bash
kubectl apply -f tier1-database.yaml
```

Salida esperada:

```
statefulset.apps/postgres-db created
service/postgres created
```

Verificar QoS class:

```bash
kubectl get pod -n production -l app=postgres -o jsonpath='{.items[0].status.qosClass}'
```

Salida esperada:

```
Guaranteed
```

### Paso 1.2: Desplegar Tier 2 (Importante - Burstable)

Revisa el archivo `tier2-api.yaml`:

```bash
cat tier2-api.yaml
```

Puntos clave del manifiesto:
- **QoS Burstable**: requests menores a limits (`cpu: "500m"` con limit `cpu: "2"`)
- **Sidecar logger** con su propio presupuesto de recursos
- **Liveness y readiness probes** para alta disponibilidad
- **3 replicas** para tolerancia a fallos

```bash
kubectl apply -f tier2-api.yaml
```

Salida esperada:

```
deployment.apps/api-server created
service/api-server created
```

Verificar QoS:

```bash
kubectl get pods -n production -l app=api -o custom-columns=\
NAME:.metadata.name,\
QoS:.status.qosClass
```

Salida esperada:

```
NAME                          QoS
api-server-xxxxxxxxx-xxxxx    Burstable
api-server-xxxxxxxxx-xxxxx    Burstable
api-server-xxxxxxxxx-xxxxx    Burstable
```

### Paso 1.3: Desplegar Tier 3 (Batch - BestEffort/Low Burstable)

Revisa el archivo `tier3-batch.yaml`:

```bash
cat tier3-batch.yaml
```

Puntos clave del manifiesto:
- **Requests bajos** (`cpu: "100m"`, `memory: "128Mi"`): no bloquea recursos del nodo
- **Limits altos** (`cpu: "1"`, `memory: "512Mi"`): puede usar recursos idle disponibles
- **CronJob** programado a las 2am para minimizar impacto en produccion
- **restartPolicy: OnFailure** para trabajos batch que pueden fallar y reintentar

```bash
kubectl apply -f tier3-batch.yaml
```

Salida esperada:

```
cronjob.batch/nightly-report created
```

### Paso 1.4: Ver Tier Distribution

```bash
kubectl get pods -n production -o custom-columns=\
NAME:.metadata.name,\
TIER:.metadata.labels.tier,\
QoS:.status.qosClass,\
CPU_REQ:.spec.containers[0].resources.requests.cpu,\
MEM_REQ:.spec.containers[0].resources.requests.memory
```

Salida esperada (cuando el StatefulSet haya arrancado):

```
NAME                        TIER       QoS          CPU_REQ   MEM_REQ
api-server-xxx-xxx          important  Burstable     500m      512Mi
api-server-xxx-xxx          important  Burstable     500m      512Mi
api-server-xxx-xxx          important  Burstable     500m      512Mi
postgres-db-0               critical   Guaranteed    2         4Gi
```

---

## Ejercicio 2: Configurar Vertical Pod Autoscaler (VPA)

> **Prerequisito:** VPA debe estar instalado. Ver SETUP.md para instrucciones.
> Si no tienes VPA instalado, puedes saltar al Ejercicio 3.

### Paso 2.1: Instalar VPA

```bash
# Clonar repo de VPA
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler

# Instalar VPA
./hack/vpa-up.sh

# Verificar instalacion
kubectl get pods -n kube-system | grep vpa
```

Salida esperada:

```
vpa-admission-controller-...   1/1     Running   0          1m
vpa-recommender-...            1/1     Running   0          1m
vpa-updater-...                1/1     Running   0          1m
```

### Paso 2.2: Crear VPA en Modo "Recommend" (Solo Observar)

Revisa el archivo `vpa-recommend.yaml`:

```bash
cat vpa-recommend.yaml
```

```bash
kubectl apply -f vpa-recommend.yaml
```

Salida esperada:

```
verticalpodautoscaler.autoscaling.k8s.io/api-server-vpa created
```

### Paso 2.3: Ver Recomendaciones de VPA

```bash
# Esperar ~2 minutos para que VPA recolecte metricas
sleep 120

# Ver recomendaciones
kubectl describe vpa api-server-vpa -n production
```

Salida esperada:

```
Recommendation:
  Container Recommendations:
    Container Name:  api
    Lower Bound:
      Cpu:     300m
      Memory:  400Mi
    Target:
      Cpu:     450m
      Memory:  600Mi
    Uncapped Target:
      Cpu:     450m
      Memory:  600Mi
    Upper Bound:
      Cpu:     800m
      Memory:  1Gi
```

**Analisis de los valores de recomendacion:**

- **Lower Bound**: Minimo para funcionar sin problemas bajo carga normal
- **Target**: Recomendacion optima — usar este valor para actualizar manifiestos
- **Upper Bound**: Maximo observado durante picos de uso

**Recomendacion**: Ajustar requests al "Target" de VPA en el manifiesto de la aplicacion:

```yaml
resources:
  requests:
    cpu: "450m"      # Usar VPA Target
    memory: "600Mi"
  limits:
    cpu: "2"
    memory: "2Gi"
```

### Paso 2.4: Crear VPA en Modo "Auto" (Actualizar Automaticamente)

> **PRECAUCION:** Modo "Auto" reinicia Pods para aplicar nuevos resources.

Revisa el archivo `vpa-auto.yaml`:

```bash
cat vpa-auto.yaml
```

```bash
kubectl apply -f vpa-auto.yaml
```

Salida esperada:

```
verticalpodautoscaler.autoscaling.k8s.io/postgres-vpa created
```

**Cuando usar "Auto" vs "Off"?**

<details>
<summary>Respuesta</summary>

**updateMode: "Off"** (Solo recomendar):
- Apps stateful (bases de datos)
- Apps que no toleran reinicios
- Produccion critica
- Cuando quieres revisar manualmente antes de aplicar

**updateMode: "Auto"** (Actualizar automaticamente):
- Apps stateless
- Development/staging
- Deployments con multiples replicas (rolling update)
- NO para StatefulSets en produccion (puede causar downtime)

</details>

### Paso 2.5: Cleanup VPA de este ejercicio

```bash
kubectl delete vpa api-server-vpa postgres-vpa -n production
```

---

## Ejercicio 3: Configurar Horizontal Pod Autoscaler (HPA)

### Paso 3.1: Crear HPA Basado en CPU

Revisa el archivo `hpa-cpu.yaml`:

```bash
cat hpa-cpu.yaml
```

```bash
kubectl apply -f hpa-cpu.yaml
```

Verificar:

```bash
kubectl get hpa -n production
```

Salida esperada:

```
NAME              REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
api-server-hpa    Deployment/api-server  15%/70%   3         10        3          1m
```

### Paso 3.2: Crear HPA Basado en CPU y Memoria

Revisa el archivo `hpa-multi.yaml`:

```bash
cat hpa-multi.yaml
```

**Como decide HPA cuando escalar con multiples metricas?**

<details>
<summary>Respuesta</summary>

HPA calcula el numero de replicas necesarias para CADA metrica y usa el **maximo**:

```
CPU necesita:    5 replicas (para llegar a 70%)
Memory necesita: 3 replicas (para llegar a 80%)

HPA escala a: MAX(5, 3) = 5 replicas
```

Esto asegura que todas las metricas esten bajo el target simultaneamente.
</details>

### Paso 3.3: Simular Carga y Ver Autoscaling

```bash
# Generar carga de CPU
kubectl run load-generator --image=busybox:1.36 -n production --restart=Never -- \
  sh -c "while true; do wget -q -O- http://api-server; done"

# Observar HPA en tiempo real
kubectl get hpa api-server-hpa -n production --watch
```

Salida esperada (escalando):

```
NAME             REFERENCE              TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
api-server-hpa   Deployment/api-server  15%/70%    3         10        3          5m
api-server-hpa   Deployment/api-server  75%/70%    3         10        3          6m
api-server-hpa   Deployment/api-server  75%/70%    3         10        4          6m
api-server-hpa   Deployment/api-server  68%/70%    3         10        4          7m
```

Ver Pods escalados:

```bash
kubectl get pods -n production -l app=api
```

Detener carga:

```bash
kubectl delete pod load-generator -n production
```

### Paso 3.4: HPA con Metricas Customizadas (Prometheus)

> **Requiere:** Prometheus Adapter instalado (ver SETUP.md)

Revisa el archivo `hpa-custom.yaml`:

```bash
cat hpa-custom.yaml
```

**Best Practice:** Escalar en base a metricas de negocio (RPS, latencia) en lugar de solo CPU/memoria es mas preciso porque refleja directamente la experiencia del usuario final.

---

## Ejercicio 4: Pod-level Resources (K8s 1.34+)

### Paso 4.1: Verificar Feature Gate

```bash
kubectl version --short
# Debe ser v1.34+

# Verificar feature gate (si es minikube)
minikube ssh
cat /var/lib/kubelet/config.yaml | grep -A 10 featureGates
# Debe tener: PodLevelResources: true
```

### Paso 4.2: Crear Deployment con Pod-level Resources

Revisa el archivo `pod-level-app.yaml`:

```bash
cat pod-level-app.yaml
```

Puntos clave del manifiesto:
- **`spec.template.spec.resources`**: define el presupuesto total del Pod
- **Contenedores sin resources individuales**: comparten el presupuesto del Pod
- **4 contenedores** (app + 3 sidecars) que comparten 1 CPU / 2Gi

```bash
kubectl apply -f pod-level-app.yaml
```

Salida esperada (si K8s 1.34+ con PodLevelResources activado):

```
deployment.apps/service-mesh-app created
```

Verificar:

```bash
kubectl describe pod -n production -l app=mesh | grep -A 20 "Resources:"
```

**Ventaja:** Con 4 sidecars, no necesitas calcular recursos individuales. Todos comparten del presupuesto total del Pod, y los sidecars pueden usar mas recursos cuando la app principal no los necesita.

### Paso 4.3: Comparar con Container-level Resources

Revisa el archivo `container-level-app.yaml` (enfoque tradicional):

```bash
cat container-level-app.yaml
```

```bash
kubectl apply -f container-level-app.yaml
```

**Comparacion:**

| Enfoque | Total Request | Total Limit | Complejidad | Flexibilidad |
|---------|--------------|-------------|-------------|--------------|
| **Pod-level** | 1 CPU, 1Gi | 2 CPU, 2Gi | Baja (1 configuracion) | Alta (sidecars comparten) |
| **Container-level** | 1 CPU, 1Gi | 2 CPU, 2Gi | Alta (4 configuraciones) | Baja (fijos por contenedor) |

---

## Ejercicio 5: Monitoreo con Prometheus

### Paso 5.1: Instalar Prometheus (Helm)

```bash
# Agregar repo de Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Verificar
kubectl get pods -n monitoring
```

### Paso 5.2: Ver Metricas de Recursos en Prometheus

```bash
# Port-forward Prometheus UI
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# Abrir en navegador: http://localhost:9090
```

**Queries utiles:**

```promql
# 1. CPU usage por Pod
sum(rate(container_cpu_usage_seconds_total{namespace="production"}[5m])) by (pod)

# 2. Memory usage por Pod
sum(container_memory_working_set_bytes{namespace="production"}) by (pod)

# 3. CPU throttling rate
sum(rate(container_cpu_cfs_throttled_seconds_total{namespace="production"}[5m])) by (pod)

# 4. Pods por QoS class
count(kube_pod_status_qos_class{namespace="production"}) by (qos_class)

# 5. Recursos requested vs available
sum(kube_pod_container_resource_requests{namespace="production",resource="cpu"}) /
sum(kube_node_status_allocatable{resource="cpu"}) * 100
```

### Paso 5.3: Crear Alertas de Prometheus

Revisa el archivo `prometheus-alerts.yaml`:

```bash
cat prometheus-alerts.yaml
```

```bash
kubectl apply -f prometheus-alerts.yaml
```

Salida esperada:

```
configmap/prometheus-alerts created
```

---

## Ejercicio 6: Best Practices Completas

### Paso 6.1: Crear Production-Ready Deployment

Revisa el archivo `production-app.yaml` con **TODAS** las best practices:

```bash
cat production-app.yaml
```

El manifiesto incluye los siguientes recursos en orden:
1. **Deployment** `production-api` con todas las best practices
2. **PriorityClass** `high-priority` (cluster-scoped)
3. **ServiceAccount** `api-service-account` dedicado
4. **Service** `production-api` con named ports
5. **HPA** `production-api-hpa` con CPU y memoria

```bash
kubectl apply -f production-app.yaml
```

Salida esperada:

```
deployment.apps/production-api created
priorityclass.scheduling.k8s.io/high-priority created
serviceaccount/api-service-account created
service/production-api created
horizontalpodautoscaler.autoscaling.v2/production-api-hpa created
```

Verificar:

```bash
kubectl get all -n production -l app=api
kubectl describe pod -n production -l app=api | head -100
```

---

## Best Practices Checklist

### Siempre Hacer

```
Definir requests (NUNCA omitir)
Definir limits para memory (prevenir OOMKilled)
Usar sizeLimit en emptyDir
QoS Guaranteed para apps criticas
Liveness y Readiness probes
Security context (runAsNonRoot)
Resource limits para ephemeral-storage
Usar VPA o HPA segun el caso
Monitorear con Prometheus
Alertas para OOMKilled y throttling
```

### Evitar

```
Pods sin requests (BestEffort en produccion)
Limits muy altos sin justificacion
emptyDir sin sizeLimit
QoS BestEffort para servicios criticos
Containers corriendo como root
Ignorar restart count alto
No monitorear throttling
HPA y VPA juntos en el mismo recurso (conflicto)
```

### Por Tipo de Aplicacion

**Bases de Datos:**
```yaml
- QoS: Guaranteed
- Autoscaling: VPA (modo "Off", revisar manualmente)
- PriorityClass: Alta
- Backup de datos antes de resize
```

**APIs REST:**
```yaml
- QoS: Burstable
- Autoscaling: HPA (basado en CPU/RPS)
- Replicas: >= 3 (alta disponibilidad)
- Rolling update: maxUnavailable=0
```

**Batch Jobs:**
```yaml
- QoS: BestEffort o Burstable bajo
- Autoscaling: No necesario
- RestartPolicy: OnFailure
- PriorityClass: Baja
```

---

## Limpieza

```bash
# Usar el script de limpieza
chmod +x cleanup.sh
./cleanup.sh
```

El script elimina:
- Namespace `production` (cascade: todos los recursos dentro)
- PriorityClass `high-priority` (cluster-scoped)
- Pod `load-generator` si existe en namespace default
- Muestra instrucciones para limpiar VPA y Prometheus (opcionales)

---

## Proximos Pasos

Has completado el modulo de Resource Limits. Continua con:

1. **Modulo 12**: Namespaces y Resource Quotas
2. **Modulo 13**: LimitRanges
3. **Modulo 19**: Observability y Monitoring

---

## Referencias

- **[README Principal](../../README.md)**: Documentacion completa del modulo
- **[Lab 01: Fundamentos](../lab-01-fundamentos/)**: Conceptos basicos de resource limits
- **[Lab 02: Troubleshooting](../lab-02-troubleshooting/)**: Debugging de problemas de recursos
- **[VPA Docs](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)**: Vertical Pod Autoscaler
- **[HPA Docs](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)**: Horizontal Pod Autoscaler

---

**Felicidades!** Has completado todos los laboratorios de Resource Limits y estas listo para produccion.
