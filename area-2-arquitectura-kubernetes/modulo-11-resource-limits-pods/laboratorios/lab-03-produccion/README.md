# Laboratorio 03: Resource Limits en Producción

## 📋 Información General

- **Duración estimada**: 50-60 minutos
- **Dificultad**: ⭐⭐⭐ Avanzado
- **Objetivo**: Implementar best practices y autoscaling en producción
- **Requisitos**:
  - Cluster Kubernetes 1.28+
  - `kubectl` configurado
  - `metrics-server` instalado
  - Completar **Lab 01** y **Lab 02** (recomendado)
  - Prometheus (opcional para métricas avanzadas)

---

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

1. ✅ Implementar best practices de resource management en producción
2. ✅ Configurar Vertical Pod Autoscaler (VPA)
3. ✅ Configurar Horizontal Pod Autoscaler (HPA)
4. ✅ Usar Pod-level resources (K8s 1.34+)
5. ✅ Monitorear recursos con Prometheus
6. ✅ Aplicar QoS strategies según criticidad
7. ✅ Optimizar costos y rendimiento

---

## 📚 Contexto Teórico

### Best Practices Framework

```
┌─────────────────────────────────────────────┐
│  Tier 1: CRÍTICO (Guaranteed)               │
│  - Bases de datos                           │
│  - Payment services                         │
│  - Auth services                            │
│  ├─ QoS: Guaranteed                         │
│  ├─ Resources: request == limit             │
│  ├─ Autoscaling: VPA (vertical)             │
│  └─ Monitoring: Alertas estrictas           │
└─────────────────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────┐
│  Tier 2: IMPORTANTE (Burstable)             │
│  - API REST                                 │
│  - Web frontends                            │
│  - Background workers                       │
│  ├─ QoS: Burstable                          │
│  ├─ Resources: request < limit              │
│  ├─ Autoscaling: HPA (horizontal)           │
│  └─ Monitoring: Alertas moderadas           │
└─────────────────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────┐
│  Tier 3: BATCH/DEV (BestEffort)             │
│  - Batch jobs                               │
│  - CI/CD pipelines                          │
│  - Development environments                 │
│  ├─ QoS: BestEffort o Burstable bajo       │
│  ├─ Resources: requests bajos o vacíos      │
│  ├─ Autoscaling: Opcional                   │
│  └─ Monitoring: Básico                      │
└─────────────────────────────────────────────┘
```

### Autoscaling Strategies

| Strategy | Tipo | Cuándo Usar | Beneficios |
|----------|------|-------------|------------|
| **VPA** | Vertical (resize containers) | Carga predecible, stateful apps | Optimiza requests/limits automáticamente |
| **HPA** | Horizontal (más Pods) | Carga variable, stateless apps | Escala según demanda |
| **Cluster Autoscaler** | Horizontal (más nodos) | Cluster elástico | Agrega/remueve nodos según carga |
| **Combinado** | VPA + HPA | Apps complejas | Mejor adaptación a patrones variados |

---

## 🧪 Ejercicio 1: Implementar Tier System (Criticality-based QoS)

### Paso 1.1: Desplegar Aplicación Tier 1 (Crítica - Guaranteed)

Crea `tier1-database.yaml`:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-db
  namespace: production
  labels:
    tier: critical
    app: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
        tier: critical
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "password"
        - name: POSTGRES_DB
          value: "production"
        resources:
          requests:
            cpu: "2"
            memory: "4Gi"
          limits:
            cpu: "2"        # ← request == limit (Guaranteed)
            memory: "4Gi"
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
      
      # Best practice: Init container para setup
      initContainers:
      - name: init-permissions
        image: busybox:1.36
        command: ['sh', '-c', 'chown -R 999:999 /var/lib/postgresql/data']
        resources:
          requests:
            cpu: "100m"
            memory: "64Mi"
          limits:
            cpu: "100m"
            memory: "64Mi"
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: production
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None  # Headless service para StatefulSet
```

Crear namespace y aplicar:

```bash
kubectl create namespace production
kubectl apply -f tier1-database.yaml
```

Verificar QoS:

```bash
kubectl get pod -n production -l app=postgres -o jsonpath='{.items[0].status.qosClass}'
# Salida esperada: Guaranteed
```

### Paso 1.2: Desplegar Aplicación Tier 2 (Importante - Burstable)

Crea `tier2-api.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: production
  labels:
    tier: important
    app: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        tier: important
    spec:
      containers:
      # Contenedor principal
      - name: api
        image: nginx:1.25  # Reemplazar con tu API real
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "2"        # ← request < limit (Burstable)
            memory: "2Gi"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
      
      # Sidecar: logging
      - name: logger
        image: busybox:1.36
        command: ['sh', '-c', 'tail -f /dev/null']
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: api-server
  namespace: production
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
```

Aplicar:

```bash
kubectl apply -f tier2-api.yaml
```

Verificar QoS:

```bash
kubectl get pods -n production -l app=api -o custom-columns=\
NAME:.metadata.name,\
QoS:.status.qosClass
# Salida esperada: Burstable
```

### Paso 1.3: Desplegar Aplicación Tier 3 (Batch - BestEffort/Low Burstable)

Crea `tier3-batch.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-report
  namespace: production
  labels:
    tier: batch
    app: reporting
spec:
  schedule: "0 2 * * *"  # 2am diario
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: reporting
            tier: batch
        spec:
          restartPolicy: OnFailure
          containers:
          - name: report-generator
            image: busybox:1.36
            command:
            - sh
            - -c
            - |
              echo "Generating report..."
              sleep 60
              echo "Report complete"
            resources:
              requests:
                cpu: "100m"      # ← Requests bajos
                memory: "128Mi"
              limits:
                cpu: "1"         # ← Puede burst si hay recursos idle
                memory: "512Mi"
```

Aplicar:

```bash
kubectl apply -f tier3-batch.yaml
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

---

## 🧪 Ejercicio 2: Configurar Vertical Pod Autoscaler (VPA)

### Paso 2.1: Instalar VPA

```bash
# Clonar repo de VPA
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler

# Instalar VPA
./hack/vpa-up.sh

# Verificar instalación
kubectl get pods -n kube-system | grep vpa
```

Salida esperada:

```
vpa-admission-controller-...   1/1     Running   0          1m
vpa-recommender-...            1/1     Running   0          1m
vpa-updater-...                1/1     Running   0          1m
```

### Paso 2.2: Crear VPA en Modo "Recommend" (Solo Observar)

Crea `vpa-recommend.yaml`:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-server-vpa
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  updatePolicy:
    updateMode: "Off"  # ← Solo recomienda, no actualiza
  resourcePolicy:
    containerPolicies:
    - containerName: api
      minAllowed:
        cpu: "250m"
        memory: "256Mi"
      maxAllowed:
        cpu: "4"
        memory: "8Gi"
      controlledResources:
      - cpu
      - memory
```

Aplicar:

```bash
kubectl apply -f vpa-recommend.yaml
```

### Paso 2.3: Ver Recomendaciones de VPA

```bash
# Esperar ~2 minutos para que VPA recolecte métricas
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

**📊 Análisis**:

- **Lower Bound**: Mínimo para funcionar sin problemas
- **Target**: Recomendación óptima (usa este valor)
- **Upper Bound**: Máximo observado en picos

**💡 Recomendación**: Ajustar requests al "Target" de VPA:

```yaml
resources:
  requests:
    cpu: "450m"      # ← Usar VPA Target
    memory: "600Mi"
  limits:
    cpu: "2"
    memory: "2Gi"
```

### Paso 2.4: Crear VPA en Modo "Auto" (Actualizar Automáticamente)

**⚠️ PRECAUCIÓN**: Modo "Auto" reinicia Pods para aplicar nuevos resources.

Crea `vpa-auto.yaml`:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: postgres-vpa
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: postgres-db
  updatePolicy:
    updateMode: "Auto"  # ← Actualiza automáticamente
  resourcePolicy:
    containerPolicies:
    - containerName: postgres
      minAllowed:
        cpu: "1"
        memory: "2Gi"
      maxAllowed:
        cpu: "4"
        memory: "8Gi"
      controlledResources:
      - cpu
      - memory
      mode: Auto  # ← VPA puede modificar requests y limits
```

Aplicar:

```bash
kubectl apply -f vpa-auto.yaml
```

**❓ ¿Cuándo usar "Auto" vs "Off"?**

<details>
<summary>Respuesta</summary>

**updateMode: "Off"** (Solo recomendar):
- ✅ Apps stateful (bases de datos)
- ✅ Apps que no toleran reinicios
- ✅ Producción crítica
- ✅ Cuando quieres revisar manualmente

**updateMode: "Auto"** (Actualizar automáticamente):
- ✅ Apps stateless
- ✅ Development/staging
- ✅ Deployments con múltiples replicas (rolling update)
- ⚠️ NO para StatefulSets en producción (puede causar downtime)

</details>

### Paso 2.5: Cleanup VPA

```bash
kubectl delete vpa api-server-vpa postgres-vpa -n production
```

---

## 🧪 Ejercicio 3: Configurar Horizontal Pod Autoscaler (HPA)

### Paso 3.1: Crear HPA Basado en CPU

Crea `hpa-cpu.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # ← Escalar cuando CPU > 70%
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # ← Esperar 5 min antes de scale down
      policies:
      - type: Percent
        value: 50  # ← Scale down máximo 50% a la vez
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0  # ← Scale up inmediato
      policies:
      - type: Percent
        value: 100  # ← Puede duplicar Pods
        periodSeconds: 15
      - type: Pods
        value: 4    # ← Máximo +4 Pods a la vez
        periodSeconds: 15
      selectPolicy: Max  # ← Usar la política más agresiva
```

Aplicar:

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

Crea `hpa-multi.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server-hpa-multi
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 3
  maxReplicas: 10
  metrics:
  # Métrica 1: CPU
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  
  # Métrica 2: Memory
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
    scaleUp:
      stabilizationWindowSeconds: 0
```

**❓ ¿Cómo decide HPA cuándo escalar con múltiples métricas?**

<details>
<summary>Respuesta</summary>

HPA calcula el número de replicas necesarias para CADA métrica y usa el **máximo**:

```
CPU necesita:    5 replicas (para llegar a 70%)
Memory necesita: 3 replicas (para llegar a 80%)

HPA escala a: MAX(5, 3) = 5 replicas
```

Esto asegura que todas las métricas estén bajo el target.
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

### Paso 3.4: HPA con Métricas Customizadas (Prometheus)

**⚠️ Requiere**: Prometheus Adapter instalado

Crea `hpa-custom.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server-hpa-custom
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 3
  maxReplicas: 10
  metrics:
  # Métrica custom: Request rate (RPS)
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"  # ← Escalar cuando > 1000 RPS
  
  # Métrica custom: Response time (latencia)
  - type: Pods
    pods:
      metric:
        name: http_request_duration_seconds
      target:
        type: AverageValue
        averageValue: "500m"  # ← 500ms
```

**💡 Best Practice**: Escalar en base a métricas de negocio (RPS, latencia) en lugar de solo CPU/memory.

---

## 🧪 Ejercicio 4: Pod-level Resources (K8s 1.34+)

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

Crea `pod-level-app.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-mesh-app
  namespace: production
  labels:
    app: mesh
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mesh
  template:
    metadata:
      labels:
        app: mesh
    spec:
      # Pod-level resources (K8s 1.34+)
      resources:
        requests:
          cpu: "1"
          memory: "1Gi"
        limits:
          cpu: "2"
          memory: "2Gi"
      
      containers:
      # Contenedor principal de la app
      - name: app
        image: nginx:1.25
        # Sin resources definidos → comparte del Pod-level
      
      # Sidecar 1: Envoy proxy (service mesh)
      - name: envoy
        image: envoyproxy/envoy:v1.28-latest
        # Sin resources → comparte del Pod-level
      
      # Sidecar 2: Log collector
      - name: fluentbit
        image: fluent/fluent-bit:2.2
        # Sin resources → comparte del Pod-level
      
      # Sidecar 3: Metrics exporter
      - name: prometheus-exporter
        image: prom/node-exporter:v1.7.0
        # Sin resources → comparte del Pod-level
```

**💡 Ventaja**: Con 4 sidecars, no necesitas calcular recursos individuales. Todos comparten del presupuesto del Pod.

Aplicar:

```bash
kubectl apply -f pod-level-app.yaml
```

Verificar:

```bash
kubectl describe pod -n production -l app=mesh | grep -A 20 "Resources:"
```

### Paso 4.3: Comparar con Container-level Resources

Crea `container-level-app.yaml` (enfoque tradicional):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-mesh-app-traditional
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mesh-traditional
  template:
    metadata:
      labels:
        app: mesh-traditional
    spec:
      containers:
      - name: app
        image: nginx:1.25
        resources:
          requests:
            cpu: "400m"
            memory: "400Mi"
          limits:
            cpu: "800m"
            memory: "800Mi"
      
      - name: envoy
        image: envoyproxy/envoy:v1.28-latest
        resources:
          requests:
            cpu: "300m"
            memory: "300Mi"
          limits:
            cpu: "600m"
            memory: "600Mi"
      
      - name: fluentbit
        image: fluent/fluent-bit:2.2
        resources:
          requests:
            cpu: "200m"
            memory: "200Mi"
          limits:
            cpu: "400m"
            memory: "400Mi"
      
      - name: prometheus-exporter
        image: prom/node-exporter:v1.7.0
        resources:
          requests:
            cpu: "100m"
            memory: "100Mi"
          limits:
            cpu: "200m"
            memory: "200Mi"
```

**📊 Comparación**:

| Enfoque | Total Request | Total Limit | Complejidad | Flexibilidad |
|---------|--------------|-------------|-------------|--------------|
| **Pod-level** | 1 CPU, 1Gi | 2 CPU, 2Gi | ⭐ Baja (1 configuración) | ⭐⭐⭐ Alta (sidecars comparten) |
| **Container-level** | 1 CPU, 1Gi | 2 CPU, 2Gi | ⭐⭐⭐ Alta (4 configuraciones) | ⭐ Baja (fijos por contenedor) |

---

## 🧪 Ejercicio 5: Monitoreo con Prometheus

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

### Paso 5.2: Ver Métricas de Recursos en Prometheus

```bash
# Port-forward Prometheus UI
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# Abrir en navegador: http://localhost:9090
```

**Queries útiles**:

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

Crea `prometheus-alerts.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alerts
  namespace: monitoring
data:
  alerts.yaml: |
    groups:
    - name: resource-alerts
      interval: 30s
      rules:
      
      # Alerta: Pod OOMKilled
      - alert: PodOOMKilled
        expr: |
          sum(changes(kube_pod_container_status_restarts_total[5m])) by (pod, namespace) > 0
          and
          kube_pod_container_status_last_terminated_reason{reason="OOMKilled"} == 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Pod {{ $labels.pod }} was OOMKilled"
          description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} was terminated due to OOM"
      
      # Alerta: CPU Throttling Alto
      - alert: HighCPUThrottling
        expr: |
          rate(container_cpu_cfs_throttled_seconds_total[5m]) > 0.3
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU throttling on {{ $labels.pod }}"
          description: "Pod {{ $labels.pod }} is being throttled {{ $value | humanizePercentage }}"
      
      # Alerta: Memory Usage Alto
      - alert: HighMemoryUsage
        expr: |
          (container_memory_working_set_bytes / container_spec_memory_limit_bytes) > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.pod }}"
          description: "Pod {{ $labels.pod }} is using {{ $value | humanizePercentage }} of memory limit"
      
      # Alerta: Pod Pending
      - alert: PodsPending
        expr: |
          kube_pod_status_phase{phase="Pending"} > 0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} is pending"
          description: "Pod {{ $labels.pod }} has been pending for more than 10 minutes"
```

Aplicar:

```bash
kubectl apply -f prometheus-alerts.yaml
```

---

## 🧪 Ejercicio 6: Best Practices Completas

### Paso 6.1: Crear Production-Ready Deployment

Crea `production-app.yaml` con **TODAS** las best practices:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-api
  namespace: production
  labels:
    app: api
    tier: important
    version: v1.0.0
spec:
  replicas: 3
  
  # Strategy: Rolling update sin downtime
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  
  selector:
    matchLabels:
      app: api
  
  template:
    metadata:
      labels:
        app: api
        tier: important
        version: v1.0.0
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
    
    spec:
      # Best Practice 1: Pod Anti-Affinity (no colocar en mismo nodo)
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
      
      # Best Practice 2: Priority Class (mayor prioridad que batch)
      priorityClassName: high-priority
      
      # Best Practice 3: ServiceAccount dedicado
      serviceAccountName: api-service-account
      
      containers:
      - name: api
        image: nginx:1.25  # Reemplazar con tu app
        
        # Best Practice 4: Resources con requests y limits
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
            ephemeral-storage: "1Gi"
          limits:
            cpu: "2"
            memory: "2Gi"
            ephemeral-storage: "2Gi"
        
        # Best Practice 5: Liveness y Readiness probes
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
        
        # Best Practice 6: Startup probe (para apps con startup lento)
        startupProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 30
        
        # Best Practice 7: Security Context
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        # Best Practice 8: Volumes para cache (con sizeLimit)
        volumeMounts:
        - name: cache
          mountPath: /cache
        - name: tmp
          mountPath: /tmp
        
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9090
          name: metrics
      
      # Sidecar: Prometheus metrics exporter
      - name: metrics-exporter
        image: prom/node-exporter:v1.7.0
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
      
      volumes:
      - name: cache
        emptyDir:
          sizeLimit: "1Gi"  # ← Best practice: siempre sizeLimit
      - name: tmp
        emptyDir:
          sizeLimit: "500Mi"
---
# PriorityClass para alta prioridad
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "High priority for important production workloads"
---
# ServiceAccount dedicado
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-service-account
  namespace: production
---
# Service
apiVersion: v1
kind: Service
metadata:
  name: production-api
  namespace: production
  labels:
    app: api
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 8080
    name: http
  - port: 9090
    targetPort: 9090
    name: metrics
  type: ClusterIP
---
# HPA
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: production-api-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: production-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

Aplicar:

```bash
kubectl apply -f production-app.yaml
```

Verificar:

```bash
kubectl get all -n production -l app=api
kubectl describe pod -n production -l app=api | head -100
```

---

## 📊 Best Practices Checklist

### ✅ Siempre Hacer

```yaml
✅ Definir requests (NUNCA omitir)
✅ Definir limits para memory (prevenir OOMKilled)
✅ Usar sizeLimit en emptyDir
✅ QoS Guaranteed para apps críticas
✅ Liveness y Readiness probes
✅ Security context (runAsNonRoot)
✅ Resource limits para ephemeral-storage
✅ Usar VPA o HPA según el caso
✅ Monitorear con Prometheus
✅ Alertas para OOMKilled y throttling
```

### ⚠️ Evitar

```yaml
❌ Pods sin requests (BestEffort en producción)
❌ Limits muy altos sin justificación
❌ emptyDir sin sizeLimit
❌ QoS BestEffort para servicios críticos
❌ Containers corriendo como root
❌ Ignorar restart count alto
❌ No monitorear throttling
❌ HPA y VPA juntos en el mismo recurso (conflicto)
```

### 🎯 Por Tipo de Aplicación

**Bases de Datos**:
```yaml
- QoS: Guaranteed
- Autoscaling: VPA (modo "Off", revisar manualmente)
- PriorityClass: Alta
- Backup de datos antes de resize
```

**APIs REST**:
```yaml
- QoS: Burstable
- Autoscaling: HPA (basado en CPU/RPS)
- Replicas: >= 3 (alta disponibilidad)
- Rolling update: maxUnavailable=0
```

**Batch Jobs**:
```yaml
- QoS: BestEffort o Burstable bajo
- Autoscaling: No necesario
- RestartPolicy: OnFailure
- PriorityClass: Baja
```

---

## 🧹 Cleanup

```bash
kubectl delete namespace production
kubectl delete priorityclass high-priority

# VPA (si instalaste)
cd autoscaler/vertical-pod-autoscaler
./hack/vpa-down.sh

# Prometheus (si instalaste)
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

---

## 📚 Próximos Pasos

Has completado el módulo de Resource Limits. Continúa con:

1. **Módulo 12**: Namespaces y Resource Quotas
2. **Módulo 13**: LimitRanges
3. **Módulo 19**: Observability y Monitoring

---

## 📖 Referencias

- **[README Principal](../README.md)**: Documentación completa
- **[Lab 01: Fundamentos](./lab-01-fundamentos.md)**: Conceptos básicos
- **[Lab 02: Troubleshooting](./lab-02-troubleshooting.md)**: Debugging
- **[VPA Docs](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)**: Vertical Pod Autoscaler
- **[HPA Docs](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)**: Horizontal Pod Autoscaler

---

**¡Felicidades!** 🎉 Has completado todos los laboratorios de Resource Limits y estás listo para producción.
