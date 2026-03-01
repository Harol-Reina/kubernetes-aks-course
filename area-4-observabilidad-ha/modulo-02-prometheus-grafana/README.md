# Capítulo 35: Prometheus y Grafana

En el capítulo anterior implementamos logging centralizado: ahora sabemos qué eventos ocurrieron, cuándo y en qué Pod. Los logs responden a la pregunta "¿qué pasó?". Pero hay una dimensión diferente de visibilidad que los logs no cubren bien: ¿cómo está rindiendo el sistema en este momento? ¿Está subiendo el uso de memoria? ¿Está aumentando la latencia de respuesta?

Considera este escenario sin monitoreo de métricas: el uso de CPU lleva subiendo durante 4 horas, alcanzando el 95%. La memoria de un microservicio crece 2MB cada minuto — una fuga de memoria clásica. Los tiempos de respuesta de la API se han multiplicado por tres en las últimas dos horas. Tú no lo sabes. Los usuarios empiezan a notar lentitud, luego errores intermitentes, luego la aplicación deja de responder por completo. Tu equipo recibe la alerta a través de un ticket de soporte. Investigar qué pasó lleva horas porque no tienes datos históricos de las métricas en el momento del fallo.

Prometheus resuelve esto: cada 15 o 30 segundos hace scraping (recolección) de métricas numéricas de todos los Pods, nodos y componentes de Kubernetes, las almacena en una base de datos de series temporales, y evalúa reglas de alerta continuamente. Grafana conecta con Prometheus para visualizar esas métricas en dashboards en tiempo real. AlertManager gestiona las notificaciones para que el equipo sea alertado antes de que los usuarios noten el problema.

Piensa en los logs como el historial de eventos de un coche: te dicen qué ocurrió ("freno de emergencia a las 14:32"). Las métricas son el cuadro de instrumentos en tiempo real: velocidad, temperatura del motor, nivel de combustible, revoluciones. El cuadro de instrumentos te permite actuar antes de que el motor se sobrecaliente, no después.

En este capítulo aprenderás la arquitectura de Prometheus y sus componentes principales, a instalar el kube-prometheus-stack con Helm (Prometheus + Grafana + AlertManager en un solo chart), a escribir consultas PromQL para analizar métricas del cluster, a crear dashboards personalizados en Grafana, y a configurar AlertManager para enviar notificaciones a Slack, email o PagerDuty.

---

## ¿Qué Son las Métricas y Por Qué Son Diferentes de los Logs?

Antes de instalar nada, es fundamental entender por qué las métricas y los logs son herramientas complementarias — no sustitutos la una de la otra.

### Logs vs Métricas: Una Comparación Directa

```
┌─────────────────────────────────────────────────────────────────────┐
│                    LOGS  vs  MÉTRICAS                               │
├───────────────────────────┬─────────────────────────────────────────┤
│          LOGS             │           MÉTRICAS                      │
├───────────────────────────┼─────────────────────────────────────────┤
│ Formato: texto libre      │ Formato: número + timestamp + etiquetas │
│ Cardinalidad: alta        │ Cardinalidad: baja                      │
│ Pregunta: ¿qué pasó?      │ Pregunta: ¿cómo está rindiendo?         │
│ Unidad: evento            │ Unidad: muestra numérica (sample)       │
│ Almacenamiento: costoso   │ Almacenamiento: eficiente               │
│ Query: lento (full scan)  │ Query: rápido (índice temporal)         │
│ Alertas: difíciles        │ Alertas: nativas y precisas             │
│ Ejemplo: "ERROR 500 POST  │ Ejemplo: http_errors_total{code="500"}  │
│  /api/users at 14:32"     │  = 247 (a las 14:32)                   │
└───────────────────────────┴─────────────────────────────────────────┘
```

**¿Por qué no puedes reemplazar métricas con logs?**

Imagina que quieres saber el percentil 99 de latencia de tu API durante las últimas 24 horas. Con logs, necesitarías:
1. Escanear gigabytes de líneas de texto
2. Extraer campos de duración con expresiones regulares
3. Ordenar y calcular percentiles en tiempo real

Con métricas Prometheus:
```promql
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[24h]))
```
Esta query responde en milisegundos porque los datos ya están indexados y pre-agregados.

El coste de almacenamiento también es radicalmente diferente. Una métrica que se muestrea cada 15 segundos durante 30 días genera aproximadamente 172.800 puntos de datos. Prometheus almacena cada punto en ~1-2 bytes después de compresión. Son menos de 350KB por serie. El equivalente en logs — un mensaje de texto por request — puede ser miles de veces más voluminoso.

### Los Cuatro Tipos de Métricas en Prometheus

Prometheus define cuatro tipos fundamentales de métricas. Cada tipo tiene un comportamiento diferente y sirve para casos de uso distintos:

**1. Counter (Contador)**

Solo puede aumentar (o reiniciarse a cero si el proceso se reinicia). Nunca decrece. Se usa para contar eventos acumulados.

```
Ejemplos:
  http_requests_total          — total de peticiones HTTP recibidas
  http_errors_total            — total de errores HTTP
  container_cpu_usage_seconds_total  — segundos de CPU consumidos

Uso en PromQL:
  rate(http_requests_total[5m])   — peticiones por segundo (últimos 5 min)
  increase(http_errors_total[1h]) — incremento de errores en la última hora
```

**Regla clave**: Nunca uses un Counter directamente para ver su valor absoluto en alertas — usa `rate()` o `increase()`. El valor absoluto sigue creciendo indefinidamente.

**2. Gauge (Indicador)**

Puede subir y bajar libremente. Representa un valor en un instante dado — como un termómetro.

```
Ejemplos:
  container_memory_usage_bytes     — bytes de memoria en uso ahora
  kube_pod_status_phase            — fase actual del Pod
  node_filesystem_avail_bytes      — espacio disponible en disco

Uso en PromQL:
  container_memory_usage_bytes     — valor directo (no necesita rate())
  node_filesystem_avail_bytes / node_filesystem_size_bytes * 100
```

**3. Histogram (Histograma)**

Mide la distribución de valores observados — frecuencias en rangos (buckets). Ideal para latencias y tamaños de respuesta.

```
Estructura interna (ejemplo: http_request_duration_seconds):
  http_request_duration_seconds_bucket{le="0.1"}  = 234  ← ≤ 100ms
  http_request_duration_seconds_bucket{le="0.5"}  = 891  ← ≤ 500ms
  http_request_duration_seconds_bucket{le="1.0"}  = 943  ← ≤ 1s
  http_request_duration_seconds_bucket{le="+Inf"} = 950  ← total
  http_request_duration_seconds_sum               = 312.4 ← suma total
  http_request_duration_seconds_count             = 950   ← total muestras

Uso en PromQL:
  histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
  — calcula el percentil 99 de latencia
```

**4. Summary (Resumen)**

Similar al Histogram pero calcula quantiles en el cliente (en la propia aplicación), no en Prometheus. Los quantiles ya están pre-calculados antes de llegar a Prometheus.

```
Estructura interna:
  rpc_duration_seconds{quantile="0.5"}  = 0.047    ← mediana
  rpc_duration_seconds{quantile="0.9"}  = 0.120    ← percentil 90
  rpc_duration_seconds{quantile="0.99"} = 0.380    ← percentil 99
  rpc_duration_seconds_sum              = 17560.3
  rpc_duration_seconds_count            = 2693

Ventaja: no requiere histograma_quantile() en PromQL
Desventaja: no se pueden agregar quantiles de múltiples instancias
```

**¿Cuándo usar Histogram vs Summary?** Usa Histogram cuando necesitas agregar percentiles de múltiples Pods (el caso más común en Kubernetes). Usa Summary cuando tienes una sola instancia y necesitas quantiles muy precisos.

### El Modelo Pull de Prometheus

Prometheus usa un modelo "pull" (tirar): es Prometheus quien va a buscar las métricas a cada target, no los targets que las envían a Prometheus. Esto es contrario a cómo funciona la mayoría de sistemas de monitoreo.

```
Prometheus (modelo pull):

┌──────────────┐     scrape /metrics      ┌───────────────┐
│  Prometheus  │◀─────────────────────────│  App Pod      │
│  Server      │     cada 30 segundos     │  :8080        │
│              │                          │  /metrics     │
│  ┌────────┐  │                          └───────────────┘
│  │  TSDB  │  │
│  │(series │  │     scrape /metrics      ┌───────────────┐
│  │temporal│  │◀─────────────────────────│  App Pod      │
│  └────────┘  │     cada 30 segundos     │  :8080        │
│              │                          │  /metrics     │
│  ┌────────┐  │                          └───────────────┘
│  │Alerting│  │
│  │ Rules  │  │     scrape /metrics      ┌───────────────┐
│  └────────┘  │◀─────────────────────────│  node-exporter│
│              │     cada 15 segundos     │  :9100        │
└──────────────┘                          └───────────────┘

Cada /metrics endpoint expone texto plano:
  # HELP http_requests_total Total HTTP requests
  # TYPE http_requests_total counter
  http_requests_total{method="GET",code="200"} 1234
  http_requests_total{method="POST",code="500"} 7
```

**Ventajas del modelo pull:**
- Prometheus controla el ritmo de scraping — no se satura si los targets son lentos
- Fácil detectar targets caídos (el scrape falla con timeout)
- Los targets no necesitan saber dónde está Prometheus
- El endpoint `/metrics` es depurable directamente con `curl`

---

## Arquitectura de Prometheus en Detalle

### Visión General del Stack Completo

```
┌──────────────────────────────────────────────────────────────────┐
│                     Prometheus Stack                             │
│                                                                  │
│  ┌─────────────┐    descubrimiento     ┌─────────────────────┐  │
│  │  Kubernetes │───────────────────────▶│  Prometheus Server  │  │
│  │  API Server │    (SD roles: pod,    │                     │  │
│  │  (Service   │     node, service,    │  ┌───────────────┐  │  │
│  │  Discovery) │     endpoints)        │  │  Scrape Loop  │  │  │
│  └─────────────┘                       │  │  (cada 15-30s)│  │  │
│                                        │  └───────┬───────┘  │  │
│  ┌─────────────┐                       │          │           │  │
│  │ node-export │◀──── scrape ──────────│  ┌───────▼───────┐  │  │
│  │  :9100      │                       │  │     TSDB      │  │  │
│  └─────────────┘                       │  │ (base de datos│  │  │
│                                        │  │  de series    │  │  │
│  ┌─────────────┐                       │  │  temporales)  │  │  │
│  │kube-state-  │◀──── scrape ──────────│  └───────┬───────┘  │  │
│  │metrics :8080│                       │          │           │  │
│  └─────────────┘                       │  ┌───────▼───────┐  │  │
│                                        │  │  Alert Rules  │  │  │
│  ┌─────────────┐                       │  │  Evaluation   │  │  │
│  │  App Pods   │◀──── scrape ──────────│  └───────┬───────┘  │  │
│  │  /metrics   │                       │          │           │  │
│  └─────────────┘                       └──────────┼───────────┘  │
│                                                   │              │
│                          ┌────────────────────────▼───────────┐  │
│                          │         AlertManager               │  │
│                          │  ┌──────────┐  ┌────────────────┐  │  │
│                          │  │  Router  │  │  Inhibition /  │  │  │
│                          │  │  Grouper │  │  Silencing     │  │  │
│                          │  └────┬─────┘  └────────────────┘  │  │
│                          └───────┼────────────────────────────┘  │
│                                  │                               │
│              ┌───────────────────┼────────────────────┐         │
│              ▼                   ▼                    ▼         │
│        ┌──────────┐       ┌──────────┐       ┌──────────────┐  │
│        │  Slack   │       │  Email   │       │  PagerDuty / │  │
│        │ Webhook  │       │  SMTP    │       │  OpsGenie    │  │
│        └──────────┘       └──────────┘       └──────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                       Grafana                            │   │
│  │  Data Source: Prometheus ──▶ Dashboards ──▶ Panels      │   │
│  │  Variables / Alertas visuales / Anotaciones              │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### Service Discovery: Cómo Prometheus Encuentra Sus Targets

En Kubernetes, los Pods se crean y destruyen constantemente. Prometheus no puede tener una lista estática de IPs a las que hacer scraping — necesita descubrir dinámicamente qué targets existen.

Esto lo resuelve `kubernetes_sd_config`, que conecta con el API Server de Kubernetes para obtener información sobre los objetos del cluster. Hay cinco roles de descubrimiento:

```
Role: node
  ─────────
  Descubre: cada nodo del cluster
  IP de scraping: IP interna del nodo
  Uso típico: node-exporter (métricas del SO)
  Ejemplo de label: __meta_kubernetes_node_name="worker-1"

Role: pod
  ────────
  Descubre: cada Pod en el cluster
  IP de scraping: IP del Pod (no del Service)
  Uso típico: aplicaciones con /metrics expuesto directamente
  Ejemplo de label: __meta_kubernetes_pod_name="api-pod-xyz"

Role: service
  ─────────────
  Descubre: cada Service del cluster
  IP de scraping: IP del ClusterIP del Service
  Uso típico: blackbox monitoring (verificar que el servicio responde)

Role: endpoints
  ──────────────
  Descubre: los Endpoints de cada Service (IPs de Pods detrás del Service)
  IP de scraping: IP individual de cada Pod
  Uso típico: el más común — scraping de todas las réplicas de un Deployment
  Ejemplo de label: __meta_kubernetes_endpoint_port_name="metrics"

Role: ingress
  ─────────────
  Descubre: cada Ingress del cluster
  Uso típico: blackbox monitoring de URLs externas
```

**El objeto ServiceMonitor** es la forma declarativa de configurar Service Discovery en el Operator pattern. En lugar de editar el `prometheus.yaml` directamente, creas un ServiceMonitor que le dice al Prometheus Operator qué Services monitorear:

```yaml
# Ejemplo: ServiceMonitor selecciona Services con label app=mi-api
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: mi-api-monitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: mi-api          # Selecciona Services con este label
  namespaceSelector:
    matchNames:
    - produccion           # Solo en el namespace "produccion"
  endpoints:
  - port: metrics          # Puerto llamado "metrics" en el Service
    path: /metrics         # Ruta del endpoint (default: /metrics)
    interval: 30s          # Frecuencia de scraping
```

El Prometheus Operator detecta este ServiceMonitor y reconfigura automáticamente a Prometheus para que scrape esos targets. No necesitas reiniciar Prometheus ni editar ConfigMaps manualmente.

### TSDB: La Base de Datos de Series Temporales

Prometheus almacena las métricas en su propia base de datos de series temporales (Time Series Database, TSDB) integrada en el proceso principal. No depende de MySQL, PostgreSQL ni ninguna base de datos externa.

```
Estructura de una serie temporal:
  ─────────────────────────────────
  Nombre de métrica + conjunto de etiquetas = una serie única

  http_requests_total{method="GET", code="200", pod="api-1"}
  │                   └──────────────────────────────────┘
  │                        Labels (etiquetas)
  └── Metric name

  Cada serie almacena una secuencia de (timestamp, value):
  ┌──────────────┬──────────┐
  │  Timestamp   │  Value   │
  ├──────────────┼──────────┤
  │ 1709001600   │  1234.0  │
  │ 1709001630   │  1241.0  │  ← cada 30 segundos
  │ 1709001660   │  1255.0  │
  │ 1709001690   │  1263.0  │
  └──────────────┴──────────┘

Retención por defecto: 15 días
Compresión: ~1.3 bytes por muestra (XOR encoding de Gorilla)
```

**Cardinalidad**: el número total de series activas. Es el factor más importante para el uso de memoria de Prometheus. Cada combinación única de (metric_name + labels) crea una nueva serie. Si una etiqueta tiene 1.000 valores posibles (como un `user_id`), cada métrica que la use generará 1.000 series. Esto es lo que se conoce como "alta cardinalidad" y puede causar OOM en el servidor Prometheus.

### Componentes Principales

1. **Prometheus Server**: Recolección y almacenamiento
2. **Alertmanager**: Gestión de alertas
3. **Pushgateway**: Para métricas batch
4. **Exporters**: Métricas de servicios externos

---

## Métricas en Kubernetes

### Tipos de Métricas

1. **Infrastructure metrics**: CPU, memoria, red, disco
2. **Kubernetes metrics**: Pods, services, deployments
3. **Application metrics**: Métricas específicas de aplicación

### Fuentes de Métricas

- **kubelet**: cAdvisor metrics
- **kube-state-metrics**: Estado de objetos Kubernetes
- **node-exporter**: Métricas del sistema operativo

---

## Instalación con Helm: kube-prometheus-stack

### ¿Qué Incluye el Chart kube-prometheus-stack?

`kube-prometheus-stack` es el chart oficial de la comunidad Prometheus. Instala todo el stack de observabilidad con un solo comando:

```
Componentes instalados:
─────────────────────────────────────────────────────────────────
  Prometheus Operator       ← gestiona la configuración como CRDs
  Prometheus Server         ← recolecta y almacena métricas
  Grafana                   ← visualización y dashboards
  AlertManager              ← routing y notificaciones de alertas
  node-exporter             ← métricas del SO en cada nodo
  kube-state-metrics        ← estado de objetos K8s
  Prometheus Adapter        ← expone métricas a HPA (opcional)

CRDs instalados:
  PrometheusRule            ← define reglas de alerta
  ServiceMonitor            ← configura scraping de Services
  PodMonitor                ← configura scraping de Pods directamente
  AlertmanagerConfig        ← configura routing de alertas

Dashboards pre-configurados en Grafana (ejemplos):
  - Kubernetes / Compute Resources / Cluster
  - Kubernetes / Compute Resources / Namespace (Pods)
  - Kubernetes / Networking / Cluster
  - Node Exporter / Full
  - Alertmanager / Overview
```

### Paso 1: Instalar con Helm

```bash
# Agregar repositorio Prometheus Community
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Crear namespace para monitoreo
kubectl create namespace monitoring

# Instalar kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes=["ReadWriteOnce"] \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=LoadBalancer

# Verificar instalación
kubectl get pods -n monitoring
kubectl get services -n monitoring
```

Salida esperada de `kubectl get pods -n monitoring`:
```
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   0          2m
prometheus-grafana-6d9b4fcd94-xp7kq                      3/3     Running   0          2m
prometheus-kube-prometheus-operator-7d4d6f9b5b-r2s8k     1/1     Running   0          2m
prometheus-kube-prometheus-prometheus-0                   2/2     Running   0          2m
prometheus-kube-state-metrics-5f8b7c9d4f-vw3xn           1/1     Running   0          2m
prometheus-prometheus-node-exporter-4h9kp                1/1     Running   0          2m
prometheus-prometheus-node-exporter-7mnqz                1/1     Running   0          2m
```

### Instalación con values.yaml para Producción

En producción conviene usar un archivo `values.yaml` en lugar de múltiples `--set`. Esto permite control de versiones y reproducibilidad:

```yaml
# values-production.yaml
# Uso: helm install prometheus prometheus-community/kube-prometheus-stack \
#        --namespace monitoring -f values-production.yaml

prometheus:
  prometheusSpec:
    # Retención de datos: 30 días en producción
    retention: 30d
    retentionSize: "45GB"

    # Persistencia: evitar perder datos si el Pod se reinicia
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: managed-premium   # Azure: Premium SSD
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

    # Scraping de todos los ServiceMonitors, no solo los del chart
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false

    # Límites de recursos del servidor Prometheus
    resources:
      requests:
        memory: "2Gi"
        cpu: "500m"
      limits:
        memory: "4Gi"
        cpu: "2000m"

    # Alta disponibilidad: 2 réplicas con Thanos Sidecar (avanzado)
    # replicas: 2

grafana:
  adminPassword: "CHANGE_ME_IN_PRODUCTION"

  # Persistencia para dashboards y configuración
  persistence:
    enabled: true
    size: 10Gi

  # Recursos
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"

  # Ingress para Grafana (ajustar hostname)
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
    - grafana.mi-empresa.com
    tls:
    - secretName: grafana-tls
      hosts:
      - grafana.mi-empresa.com

alertmanager:
  alertmanagerSpec:
    # Persistencia para silencias y notificaciones
    storage:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi

nodeExporter:
  enabled: true   # métricas del SO en todos los nodos

kubeStateMetrics:
  enabled: true   # estado de objetos Kubernetes
```

```bash
# Aplicar con values de producción
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f values-production.yaml

# O actualizar una instalación existente
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f values-production.yaml
```

### Paso 2: Acceder a Interfaces

```bash
# Obtener IP de Grafana
GRAFANA_IP=$(kubectl get service prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Grafana URL: http://$GRAFANA_IP"
echo "Usuario: admin, Password: admin123"

# Port-forward para Prometheus (alternativo)
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090 &
echo "Prometheus URL: http://localhost:9090"

# Port-forward para AlertManager
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager -n monitoring 9093:9093 &
echo "AlertManager URL: http://localhost:9093"
```

### Paso 3: Configurar ServiceMonitor Personalizado

```bash
# Aplicación con métricas Prometheus
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: desarrollo
  labels:
    app: sample-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: app
        image: prom/node-exporter:latest
        ports:
        - containerPort: 9100
          name: metrics
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-service
  namespace: desarrollo
  labels:
    app: sample-app
spec:
  selector:
    app: sample-app
  ports:
  - port: 9100
    targetPort: 9100
    name: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: sample-app-monitor
  namespace: desarrollo
  labels:
    app: sample-app
spec:
  selector:
    matchLabels:
      app: sample-app
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
EOF
```

---

## PromQL desde Cero

PromQL (Prometheus Query Language) es el lenguaje para consultar las métricas almacenadas en Prometheus. Su sintaxis es compacta pero expresiva. Esta sección te lleva de cero a consultas útiles en producción.

### Conceptos Fundamentales

**Selector de métricas**: el bloque básico de cualquier query PromQL.

```
http_requests_total
│
└── Devuelve TODAS las series con ese nombre de métrica

http_requests_total{method="GET"}
│                   └──────────┘
│                   Label matcher (filtro exacto)
└── Solo series donde method es exactamente "GET"

http_requests_total{method=~"GET|POST"}
│                          └──────────┘
│                          Regex matcher (=~ para incluir, !~ para excluir)
└── Series donde method es GET o POST

http_requests_total{namespace!="kube-system"}
│                          └───────────────┘
│                          != para excluir valor exacto
└── Series donde namespace NO es kube-system
```

**Vectores instantáneos vs vectores de rango:**

```
http_requests_total          ← Vector instantáneo: valor en el momento actual
http_requests_total[5m]      ← Vector de rango: todos los valores de los últimos 5 min

Los vectores de rango son el input de funciones como rate() e increase().
No se pueden usar directamente en un gráfico — necesitan una función que los
convierta de nuevo a un vector instantáneo.

Notación de tiempo:
  s  = segundos     [30s]
  m  = minutos      [5m]
  h  = horas        [1h]
  d  = días         [7d]
  w  = semanas      [2w]
```

### Funciones Esenciales

```
rate(counter[rango])
  — Tasa de cambio por segundo (promedio en el rango)
  — Para Counters. Maneja reinicios automáticamente.
  — Ejemplo: rate(http_requests_total[5m]) → req/s en los últimos 5 min

increase(counter[rango])
  — Incremento total en el rango (no por segundo)
  — Ejemplo: increase(http_errors_total[1h]) → errores en la última hora

irate(counter[rango])
  — Tasa instantánea (últimas 2 muestras del rango)
  — Más reactiva que rate(), pero más ruidosa
  — Útil para gráficos de alta resolución temporal

sum(vector) by (label)
  — Suma todas las series, agrupando por etiqueta
  — Ejemplo: sum(http_requests_total) by (pod) → total por Pod

avg(vector) by (label)
  — Media aritmética, agrupada por etiqueta

max(vector) by (label)
  — Valor máximo por grupo

histogram_quantile(φ, rate(histogram_bucket[rango]))
  — Calcula el percentil φ (0.0 a 1.0) de un histograma
  — Ejemplo: histogram_quantile(0.99, ...) → percentil 99

topk(k, vector)
  — Los k valores más altos
  — Ejemplo: topk(5, rate(http_requests_total[5m])) → top 5 endpoints

predict_linear(gauge[rango], segundos)
  — Predice el valor futuro usando regresión lineal
  — Ejemplo: predict_linear(node_filesystem_avail_bytes[6h], 4*3600)
  — ¿En cuántas horas se llena el disco?
```

### 10 Queries Esenciales para Kubernetes

**Query 1: Uso de CPU por Pod**

```promql
sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (pod, namespace)
```
Qué mide: núcleos de CPU consumidos por cada Pod, promediados en 5 minutos.
Cuándo usarlo: investigar qué Pods están consumiendo más CPU; baseline para alertas.
Resultado: valor en "cores" (0.5 = 50% de un core; 2.0 = 2 cores completos).

**Query 2: Uso de Memoria por Pod**

```promql
sum(container_memory_working_set_bytes{container!=""}) by (pod, namespace)
```
Qué mide: bytes de memoria en uso activo (working set) por Pod.
Por qué `working_set` y no `usage_bytes`: working set excluye páginas de memoria cacheadas que el kernel puede reclamar. Es el valor que Kubernetes usa para OOMKill.
Resultado: valor en bytes. Divide entre 1048576 para megabytes.

**Query 3: Porcentaje de Memoria Respecto al Límite**

```promql
sum(container_memory_working_set_bytes{container!=""}) by (pod)
  /
sum(kube_pod_container_resource_limits{resource="memory"}) by (pod)
  * 100
```
Qué mide: qué porcentaje del límite de memoria está usando cada Pod.
Cuándo usarlo: detectar Pods en riesgo de OOMKill (valores cercanos a 100).

**Query 4: Número de Pods por Namespace**

```promql
count by (namespace) (kube_pod_info{phase="Running"})
```
Qué mide: cuántos Pods están en estado Running en cada namespace.
Cuándo usarlo: verificar el estado general del cluster; detectar namespace con Pods inesperados.

**Query 5: Tasa de Requests HTTP**

```promql
sum(rate(http_requests_total[5m])) by (service, method)
```
Qué mide: peticiones por segundo por servicio y método HTTP.
Requiere: que tu aplicación instrumente y exponga `http_requests_total`.
Cuándo usarlo: monitoreo de tráfico; detectar picos de carga.

**Query 6: Tasa de Errores HTTP 5xx**

```promql
sum(rate(http_requests_total{code=~"5.."}[5m])) by (service)
  /
sum(rate(http_requests_total[5m])) by (service)
  * 100
```
Qué mide: porcentaje de respuestas con código 5xx sobre el total.
Cuándo usarlo: SLO de disponibilidad ("menos del 0.1% de errores 5xx").
Alerta típica: disparar si este valor supera el 1% durante más de 2 minutos.

**Query 7: Latencia P99 (Percentil 99)**

```promql
histogram_quantile(
  0.99,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
)
```
Qué mide: el tiempo de respuesta que el 99% de las peticiones están por debajo.
Qué significa: si el P99 es 2 segundos, el 1% de los usuarios experimenta más de 2s de espera.
Cuándo usarlo: SLO de latencia ("el P99 debe ser menor de 500ms").

**Query 8: Saturación de CPU en Nodos**

```promql
(1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))) * 100
```
Qué mide: porcentaje de uso de CPU en cada nodo (100% - porcentaje idle).
Cuándo usarlo: decidir si necesitas escalar horizontalmente el cluster.
Alerta típica: si un nodo supera el 85% durante más de 10 minutos.

**Query 9: Reinicios de Contenedores**

```promql
increase(kube_pod_container_status_restarts_total[1h])
```
Qué mide: número de veces que cada contenedor se reinició en la última hora.
Cuándo usarlo: detectar crash loops; los contenedores no deberían reiniciarse en condiciones normales.
Alerta típica: disparar si cualquier contenedor tiene más de 3 reinicios en 15 minutos.

**Query 10: Ancho de Banda de Red por Pod**

```promql
# Tráfico de entrada
sum(rate(container_network_receive_bytes_total[5m])) by (pod, namespace)

# Tráfico de salida
sum(rate(container_network_transmit_bytes_total[5m])) by (pod, namespace)
```
Qué mide: bytes por segundo recibidos/enviados por cada Pod.
Cuándo usarlo: detectar Pods con tráfico anormal; planificar capacidad de red.
Resultado: en bytes/s. Multiplica por 8 para bits/s; divide entre 1048576 para MB/s.

### Queries Avanzadas Útiles

**Uso de disco en Persistent Volumes:**

```promql
# Espacio disponible como porcentaje
(
  kubelet_volume_stats_available_bytes
    /
  kubelet_volume_stats_capacity_bytes
) * 100
```

**Predicción de llenado de disco (en horas):**

```promql
predict_linear(
  kubelet_volume_stats_available_bytes[6h],
  4 * 3600
) < 0
```
Devuelve los PVs que se quedarán sin espacio en las próximas 4 horas si la tendencia continúa.

**Pods que no están en Running:**

```promql
kube_pod_status_phase{phase!~"Running|Succeeded"} > 0
```

**Nodos con high memory pressure:**

```promql
(
  node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
) / node_memory_MemTotal_bytes * 100 > 90
```

---

## Grafana Dashboards

Grafana es la capa de visualización del stack. Se conecta a Prometheus como data source y permite crear dashboards interactivos con paneles de series temporales, gauges, tablas, heatmaps y más.

### Conectar Grafana con Prometheus

Si usaste `kube-prometheus-stack`, Prometheus ya está configurado como data source automáticamente. Para verificarlo o añadirlo manualmente:

```
1. Ir a: Connections → Data sources
2. Hacer clic en "Add data source"
3. Seleccionar "Prometheus"
4. URL: http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090
   (Si Grafana está en el mismo cluster, usar el nombre DNS interno)
5. Hacer clic en "Save & Test"
   Resultado esperado: "Successfully queried the Prometheus API."
```

### Importar Dashboards de la Comunidad

Grafana tiene un repositorio público de dashboards en grafana.com/dashboards. Los más útiles para Kubernetes son:

```
ID      Nombre                                          Descripción
──────  ──────────────────────────────────────────────  ────────────────────────────────
315     Kubernetes cluster monitoring (via Prometheus)  Vista general del cluster
6417    Kubernetes Cluster Overview                     CPU, memoria, nodos
7249    Kubernetes cluster (Prometheus)                 Métricas detalladas por nodo
8588    K8s Deployment StatefulSet DaemonSet metrics    Estado de workloads
12206   Kubernetes apiserver                            Métricas del API Server
1860    Node Exporter Full                              Métricas detalladas del SO
10000   Kubernetes Cluster Monitoring                   Dashboard completo
9614    NGINX Ingress controller                        Si usas NGINX Ingress
```

Para importar un dashboard:
```
1. Ir a: Dashboards → Import
2. Introducir el ID del dashboard (ej: 315)
3. Hacer clic en "Load"
4. Seleccionar el data source Prometheus en el campo "Prometheus"
5. Hacer clic en "Import"
```

### Crear un Dashboard Personalizado Paso a Paso

Un dashboard personalizado te permite monitorear exactamente las métricas de tu aplicación.

**Paso 1: Crear el dashboard**
```
1. Hacer clic en el "+" en la barra lateral → "New dashboard"
2. Hacer clic en "Add visualization"
3. Seleccionar "Prometheus" como data source
```

**Paso 2: Configurar el primer panel — CPU por Pod**
```
1. En "Query", escribir:
   sum(rate(container_cpu_usage_seconds_total{namespace="produccion",container!=""}[5m])) by (pod)

2. En "Legend", escribir: {{pod}}
   (usa el nombre del Pod como leyenda de cada línea)

3. En "Panel title" (panel derecho): "CPU por Pod (cores)"

4. En "Standard options" → Unit: seleccionar "CPU cores" o "short"

5. Hacer clic en "Apply"
```

**Paso 3: Añadir un panel de Memoria**
```
1. Hacer clic en "Add panel" → "Add visualization"
2. Query:
   sum(container_memory_working_set_bytes{namespace="produccion",container!=""}) by (pod)
3. Legend: {{pod}}
4. Unit: bytes (IEC) — Grafana lo convierte automáticamente a MB/GB
5. Title: "Memoria por Pod (working set)"
6. Hacer clic en "Apply"
```

**Paso 4: Añadir un Stat panel para el total de Pods**
```
1. Añadir panel → "Add visualization"
2. Query:
   count(kube_pod_info{namespace="produccion"})
3. Visualization type: "Stat" (número grande en la pantalla)
4. Unit: "none"
5. Title: "Pods en produccion"
6. Hacer clic en "Apply"
```

**Paso 5: Añadir variables para filtrar por namespace**

Las variables convierten un dashboard estático en uno interactivo con dropdowns.

```
1. Ir a Dashboard settings (icono de engranaje arriba)
2. Seleccionar "Variables" → "Add variable"
3. Configurar:
   Name: namespace
   Type: Query
   Data source: Prometheus
   Query: label_values(kube_pod_info, namespace)
   Sort: Alphabetical (asc)
4. Guardar y volver al dashboard
5. Actualizar las queries para usar la variable:
   sum(rate(container_cpu_usage_seconds_total{namespace="$namespace",container!=""}[5m])) by (pod)
   — Ahora el dropdown de namespace filtra todos los paneles
```

**Paso 6: Configurar el rango de tiempo por defecto**
```
En Dashboard settings → Time options:
  Auto refresh: 30s (se actualiza cada 30 segundos)
  Time range: Last 1 hour (default al abrir)
```

### Tipos de Visualización en Grafana

```
Time series  ← El más común. Líneas a lo largo del tiempo.
             Ideal para: CPU, memoria, tráfico de red, latencia.

Stat         ← Un número grande con contexto. Admite umbrales de color.
             Ideal para: número de Pods activos, errores totales.

Gauge        ← Medidor tipo velocímetro. Útil para porcentajes.
             Ideal para: % de CPU, % de memoria, % de disco.

Bar chart    ← Barras verticales u horizontales.
             Ideal para: comparar valores entre namespaces o servicios.

Table        ← Vista tabular con múltiples columnas.
             Ideal para: listar Pods con sus métricas actuales.

Heatmap      ← Distribución de histogramas en el tiempo.
             Ideal para: distribución de latencias, patrones de carga.
```

---

## Alertas con AlertManager

Las métricas por sí solas no son suficientes — necesitas ser notificado cuando algo sale mal. AlertManager es el componente que gestiona el ciclo de vida de las alertas: recepción, agrupación, routing y notificación.

### El Flujo Completo de una Alerta

```
1. Prometheus evalúa una regla PromQL cada N segundos (evaluation_interval)

2. Si la condición es verdadera durante el período "for":
   Estado: PENDING → FIRING

3. Prometheus envía el alert a AlertManager

4. AlertManager:
   a. Agrupa alertas relacionadas (evitar spam)
   b. Aplica inhibición (suprimir alertas menores si hay una mayor)
   c. Aplica silencias (suprimir durante mantenimientos)
   d. Enruta al receiver correcto (Slack, email, PagerDuty...)

5. El receiver envía la notificación

Ejemplo de línea de tiempo:
  t=0    Condición: CPU > 80%           → estado: INACTIVE
  t=30s  CPU sigue > 80%                → estado: PENDING
  t=60s  CPU sigue > 80% (for: 1m)     → estado: FIRING
  t=60s  Prometheus notifica AlertManager
  t=65s  AlertManager espera group_wait (30s)
  t=95s  AlertManager envía notificación a Slack
  t=3h   Si CPU sigue alta, repite cada repeat_interval (1h)
```

### Escribir PrometheusRule Resources

Las alertas se definen como recursos Kubernetes con el CRD `PrometheusRule`:

```yaml
# Uso: kubectl apply -f alertas-produccion.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: alertas-produccion
  namespace: monitoring
  labels:
    # Este label es necesario para que el Operator incluya estas reglas
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
  # ── Grupo 1: Alertas de disponibilidad ──────────────────────────────
  - name: disponibilidad
    interval: 30s   # Frecuencia de evaluación (default: global evaluation_interval)
    rules:
    - alert: PodCrashLooping
      # Expresión: más de 3 reinicios en 15 minutos en cualquier contenedor
      expr: increase(kube_pod_container_status_restarts_total[15m]) > 3
      for: 0m   # 0m = disparar inmediatamente, sin período de gracia
      labels:
        severity: warning
        equipo: plataforma
      annotations:
        summary: "Pod en crash loop: {{ $labels.namespace }}/{{ $labels.pod }}"
        description: |
          El contenedor {{ $labels.container }} en el Pod
          {{ $labels.namespace }}/{{ $labels.pod }} se ha reiniciado
          {{ $value | printf "%.0f" }} veces en los últimos 15 minutos.
        runbook_url: "https://wiki.empresa.com/runbooks/pod-crash-loop"

    - alert: DeploymentNoDisponible
      expr: kube_deployment_status_replicas_available == 0
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Deployment sin réplicas: {{ $labels.namespace }}/{{ $labels.deployment }}"
        description: "El Deployment {{ $labels.deployment }} no tiene réplicas disponibles."

  # ── Grupo 2: Alertas de recursos ────────────────────────────────────
  - name: recursos
    rules:
    - alert: AltoUsoCPU
      expr: |
        sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (pod, namespace)
          /
        sum(kube_pod_container_resource_limits{resource="cpu"}) by (pod, namespace)
          * 100 > 85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Alto uso de CPU: {{ $labels.namespace }}/{{ $labels.pod }}"
        description: "El Pod usa {{ $value | printf \"%.1f\" }}% de su límite de CPU."

    - alert: AltoUsoMemoria
      expr: |
        sum(container_memory_working_set_bytes{container!=""}) by (pod, namespace)
          /
        sum(kube_pod_container_resource_limits{resource="memory"}) by (pod, namespace)
          * 100 > 90
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Alto uso de memoria: {{ $labels.namespace }}/{{ $labels.pod }}"
        description: "El Pod usa {{ $value | printf \"%.1f\" }}% de su límite de memoria. Riesgo de OOMKill."

    - alert: DiscoPVCLleno
      expr: |
        (
          kubelet_volume_stats_available_bytes
            /
          kubelet_volume_stats_capacity_bytes
        ) * 100 < 10
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "PVC casi lleno: {{ $labels.persistentvolumeclaim }}"
        description: "Queda solo {{ $value | printf \"%.1f\" }}% de espacio libre."

    - alert: DiscoLlenoPredecible
      expr: predict_linear(kubelet_volume_stats_available_bytes[6h], 4 * 3600) < 0
      for: 30m
      labels:
        severity: warning
      annotations:
        summary: "PVC se llenará en ~4h: {{ $labels.persistentvolumeclaim }}"
        description: "Basado en la tendencia de las últimas 6h, el PVC se llenará en menos de 4 horas."
```

### Configuración de AlertManager: Routing y Receivers

AlertManager se configura mediante un Secret llamado `alertmanager-main` (o `alertmanager-prometheus-kube-prometheus-alertmanager` en kube-prometheus-stack):

```yaml
# Uso: kubectl apply -f alertmanager-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-prometheus-kube-prometheus-alertmanager
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    global:
      # Tiempo que AlertManager espera antes de declarar que un receiver
      # no responde y lo marca como "resolved"
      resolve_timeout: 5m

      # Configuración global de Slack (se puede sobreescribir por receiver)
      slack_api_url: 'https://hooks.slack.com/services/TU/SLACK/WEBHOOK'

    # ── Árbol de routing ──────────────────────────────────────────────
    route:
      # Agrupar alertas del mismo tipo para evitar spam
      group_by: ['alertname', 'namespace']
      # Tiempo de espera antes de enviar la primera notificación de un grupo nuevo
      group_wait: 30s
      # Tiempo de espera antes de enviar nuevas alertas al mismo grupo
      group_interval: 5m
      # Tiempo entre notificaciones repetidas si la alerta sigue activa
      repeat_interval: 4h
      # Receiver por defecto para todo lo que no coincida con ninguna ruta
      receiver: 'slack-general'

      # Sub-rutas: se evalúan en orden, la primera que coincide gana
      routes:
      # Alertas críticas → canal Slack de críticos + PagerDuty
      - match:
          severity: critical
        receiver: 'critico'
        group_wait: 10s       # Notificar más rápido para críticos
        repeat_interval: 1h

      # Alertas del equipo de base de datos → canal específico
      - match:
          equipo: bbdd
        receiver: 'slack-bbdd'

      # Alertas de watchdog (heartbeat) → no notificar
      - match:
          alertname: Watchdog
        receiver: 'null'

    # ── Receivers ─────────────────────────────────────────────────────
    receivers:
    # Receiver nulo: descarta alertas silenciosamente
    - name: 'null'

    # Canal general de Slack
    - name: 'slack-general'
      slack_configs:
      - channel: '#kubernetes-alertas'
        send_resolved: true
        title: |-
          [{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}]
          {{ .CommonLabels.alertname }}
        text: |-
          {{ range .Alerts }}
          *Alerta:* {{ .Annotations.summary }}
          *Namespace:* {{ .Labels.namespace }}
          *Descripción:* {{ .Annotations.description }}
          {{ if .Annotations.runbook_url }}*Runbook:* {{ .Annotations.runbook_url }}{{ end }}
          {{ end }}

    # Críticos: Slack prioritario + PagerDuty
    - name: 'critico'
      slack_configs:
      - channel: '#kubernetes-critico'
        send_resolved: true
        title: "CRITICO: {{ .CommonLabels.alertname }}"
        text: "{{ range .Alerts }}{{ .Annotations.description }}{{ end }}"
        color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'
      pagerduty_configs:
      - routing_key: 'TU_PAGERDUTY_INTEGRATION_KEY'
        description: "{{ .CommonLabels.alertname }}: {{ .CommonAnnotations.summary }}"

    # Canal del equipo de base de datos
    - name: 'slack-bbdd'
      slack_configs:
      - channel: '#alertas-bbdd'
        send_resolved: true
        title: "{{ .CommonLabels.alertname }}"
        text: "{{ range .Alerts }}{{ .Annotations.description }}{{ end }}"

    # ── Inhibition rules ──────────────────────────────────────────────
    # Suprimir alertas de warning si hay una alerta crítica del mismo nodo
    inhibit_rules:
    - source_match:
        severity: 'critical'
      target_match:
        severity: 'warning'
      equal: ['alertname', 'namespace', 'pod']
```

### Gestionar Silencias

Las silencias permiten suprimir alertas temporalmente — útil durante ventanas de mantenimiento:

```bash
# Crear una silencia via API de AlertManager (ejemplo: suprimir todo durante 2h)
curl -X POST http://localhost:9093/api/v2/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [
      {"name": "namespace", "value": "produccion", "isRegex": false}
    ],
    "startsAt": "2024-03-01T02:00:00Z",
    "endsAt": "2024-03-01T04:00:00Z",
    "comment": "Mantenimiento programado base de datos",
    "createdBy": "ops-team"
  }'

# Listar silencias activas
curl http://localhost:9093/api/v2/silences | jq '.[] | {id, status, comment}'

# Eliminar una silencia (reemplazar ID con el obtenido arriba)
curl -X DELETE http://localhost:9093/api/v2/silence/SILENCE-UUID
```

### Buenas Prácticas para Alertas

**Evitar alert fatigue (fatiga de alertas)**: Si recibes demasiadas alertas que no requieren acción inmediata, empiezas a ignorarlas todas — incluyendo las importantes. Principios clave:

```
1. Cada alerta debe requerir una acción humana.
   Mala alerta:  "CPU > 50%"  — puede ser normal en producción
   Buena alerta: "CPU > 90% durante 10 minutos" — acción real requerida

2. Las alertas deben ser síntomas, no causas internas.
   Mala alerta:  "kube-scheduler latency high"  — demasiado interno
   Buena alerta: "Pod scheduling taking > 30s"  — impacto visible

3. Cada alerta debe tener un runbook.
   El campo annotations.runbook_url con un link a pasos de resolución.

4. Usar períodos "for" generosos para alertas de warning.
   severity: warning → for: 5m o 10m (evitar alertas flapping)
   severity: critical → for: 1m o 2m (respuesta rápida requerida)

5. Testar las alertas regularmente.
   Crear incidentes de prueba para verificar que las notificaciones llegan.
```

---

## Laboratorio 4.2: Instalar Prometheus Stack

### Paso 1: Instalar con Helm

```bash
# Agregar repositorio Prometheus Community
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Crear namespace para monitoreo
kubectl create namespace monitoring

# Instalar kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes=["ReadWriteOnce"] \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=LoadBalancer

# Verificar instalación
kubectl get pods -n monitoring
kubectl get services -n monitoring
```

### Paso 2: Acceder a Interfaces

```bash
# Obtener IP de Grafana
GRAFANA_IP=$(kubectl get service prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Grafana URL: http://$GRAFANA_IP"
echo "Usuario: admin, Password: admin123"

# Port-forward para Prometheus (alternativo)
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090 &
echo "Prometheus URL: http://localhost:9090"

# Port-forward para AlertManager
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager -n monitoring 9093:9093 &
echo "AlertManager URL: http://localhost:9093"
```

### Paso 3: Configurar ServiceMonitor Personalizado

```bash
# Aplicación con métricas Prometheus
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: desarrollo
  labels:
    app: sample-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: app
        image: prom/node-exporter:latest
        ports:
        - containerPort: 9100
          name: metrics
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-service
  namespace: desarrollo
  labels:
    app: sample-app
spec:
  selector:
    app: sample-app
  ports:
  - port: 9100
    targetPort: 9100
    name: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: sample-app-monitor
  namespace: desarrollo
  labels:
    app: sample-app
spec:
  selector:
    matchLabels:
      app: sample-app
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
EOF
```

---

## Consultas PromQL Útiles

```promql
# CPU usage por pod
rate(container_cpu_usage_seconds_total[5m]) * 100

# Memoria usage por pod
container_memory_usage_bytes / container_spec_memory_limit_bytes * 100

# Número de pods por namespace
count by (namespace) (kube_pod_info)

# Request rate por servicio
rate(http_requests_total[5m])

# 95th percentile de latencia
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Pods en estado no Running
kube_pod_status_phase{phase!="Running"} > 0

# Nodos con alta utilización de CPU
(1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))) * 100 > 80
```

---

## Laboratorio 4.3: Crear Dashboards y Alertas

### Paso 1: Importar Dashboards

```bash
# Lista de dashboards útiles para importar en Grafana:
# - 315: Kubernetes cluster monitoring
# - 8588: Kubernetes Deployment Statefulset Daemonset metrics
# - 6417: Kubernetes cluster overview
# - 7249: Kubernetes cluster (Prometheus)
```

### Paso 2: Configurar Alertas

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: kubernetes-alerts
  namespace: monitoring
  labels:
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
  - name: kubernetes-alerts
    rules:
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 0m
      labels:
        severity: warning
      annotations:
        summary: "Pod is crash looping"
        description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"

    - alert: HighCPUUsage
      expr: (rate(container_cpu_usage_seconds_total[5m]) * 100) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage detected"
        description: "Container {{ $labels.container }} in pod {{ $labels.pod }} has high CPU usage: {{ $value }}%"

    - alert: HighMemoryUsage
      expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes * 100) > 90
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High memory usage detected"
        description: "Container {{ $labels.container }} in pod {{ $labels.pod }} has high memory usage: {{ $value }}%"

    - alert: PodNotReady
      expr: kube_pod_status_ready{condition="false"} > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod not ready"
        description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is not ready for more than 5 minutes"
EOF
```

### Paso 3: Configurar Notificaciones

```bash
# Configurar Slack notifications (ejemplo)
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-config
  namespace: monitoring
stringData:
  alertmanager.yml: |
    global:
      slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'slack-notifications'

    receivers:
    - name: 'slack-notifications'
      slack_configs:
      - channel: '#alerts'
        title: 'Kubernetes Alert'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
EOF
```

---

## Troubleshooting: Prometheus y Grafana

Esta sección cubre los seis problemas más frecuentes al operar el stack de monitoreo. Cada escenario incluye cómo identificarlo, su causa raíz y los pasos de resolución.

### Escenario 1: Targets Aparecen como "DOWN" en Prometheus

**Síntoma**: En `http://localhost:9090/targets`, uno o más targets muestran estado `DOWN` con un error de conexión.

```
Cómo verificar:
  kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
  → Abrir http://localhost:9090/targets
  → Buscar targets con estado "DOWN" y leer el mensaje de error

Errores comunes:
  "connection refused"     → el Pod no expone el puerto correcto
  "no such host"           → el DNS del Service no resuelve
  "context deadline exceeded (scrape timeout)" → el endpoint tarda demasiado
```

**Causa más frecuente**: el selector del ServiceMonitor no coincide con los labels del Service.

```bash
# Diagnóstico paso a paso:

# 1. Ver el ServiceMonitor y su selector
kubectl get servicemonitor mi-app-monitor -n monitoring -o yaml | grep -A5 selector

# 2. Ver los labels del Service objetivo
kubectl get service mi-app-svc -n produccion --show-labels

# 3. Comparar: el matchLabels del ServiceMonitor debe coincidir exactamente
#    con los labels del Service

# Ejemplo de problema:
#   ServiceMonitor selector:  matchLabels: {app: mi-app}
#   Service labels:           {app: mi-app-v2, tier: backend}
#   → No coincide (app: mi-app vs app: mi-app-v2)

# Solución: corregir los labels del Service o el selector del ServiceMonitor
kubectl patch service mi-app-svc -n produccion \
  --type=json \
  -p='[{"op":"add","path":"/metadata/labels/app","value":"mi-app"}]'

# 4. Verificar que el puerto llamado "metrics" existe en el Service
kubectl get service mi-app-svc -n produccion -o jsonpath='{.spec.ports}'
# Debe mostrar un puerto con name: "metrics"
```

### Escenario 2: Errores de Scraping — Endpoint /metrics No Accesible

**Síntoma**: El target aparece como `UP` intermitentemente, o los logs del Pod de Prometheus muestran errores de scraping.

```bash
# Ver logs de Prometheus para errores de scraping
kubectl logs prometheus-kube-prometheus-prometheus-0 \
  -n monitoring -c prometheus \
  | grep -i "scrape error\|failed to scrape"

# Probar el endpoint /metrics directamente desde dentro del cluster
kubectl run -it --rm debug-pod --image=curlimages/curl:latest --restart=Never -- \
  curl http://IP-DEL-POD:8080/metrics

# Ver la IP del Pod objetivo
kubectl get pod mi-app-pod -n produccion -o jsonpath='{.status.podIP}'
```

**Causas y soluciones comunes:**

```
Causa: La aplicación no expone /metrics
  Solución: Instrumentar la aplicación con la librería Prometheus del lenguaje
  (prometheus/client_golang, prometheus_client para Python, etc.)

Causa: El puerto en el ServiceMonitor no coincide con el del contenedor
  Verificar: spec.endpoints[].port debe coincidir con el name del containerPort
  Ejemplo correcto:
    Service port name: "metrics"  ← ServiceMonitor.spec.endpoints[].port: "metrics"
    containerPort name: "metrics" ← Service targetPort: "metrics"

Causa: NetworkPolicy bloquea el scraping de Prometheus
  Prometheus hace scraping desde el namespace "monitoring"
  Si hay NetworkPolicies restrictivas, añadir una regla:
```

```yaml
# Uso: kubectl apply -f allow-prometheus-scraping.yaml
# Permite que Prometheus (namespace: monitoring) acceda al puerto /metrics
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-prometheus-scraping
  namespace: produccion
spec:
  podSelector:
    matchLabels:
      app: mi-app
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
    ports:
    - port: 8080
      protocol: TCP
```

### Escenario 3: Alta Cardinalidad — OOM en el Servidor Prometheus

**Síntoma**: El Pod de Prometheus se reinicia con OOMKilled, o el uso de memoria crece indefinidamente.

```bash
# Verificar si Prometheus está siendo OOMKilled
kubectl describe pod prometheus-kube-prometheus-prometheus-0 -n monitoring \
  | grep -A3 "OOMKilled\|Last State"

# Ver el número de series activas (en la UI de Prometheus)
# Ir a http://localhost:9090/api/v1/status/tsdb
# O con curl:
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090 &
curl http://localhost:9090/api/v1/status/tsdb | jq '.data.seriesCountByMetricName[:10]'

# Identificar métricas con alta cardinalidad
curl http://localhost:9090/api/v1/status/tsdb | \
  jq '.data.seriesCountByLabelValuePair | sort_by(.seriesCount) | reverse | .[0:10]'
```

**Causa raíz y solución:**

La alta cardinalidad ocurre cuando una etiqueta tiene demasiados valores únicos. Los casos más comunes en Kubernetes:

```
Problema: etiqueta con IDs únicos de usuarios, URLs, o UUIDs
  Ejemplo malo: http_requests_total{user_id="a3f8d2c1-..."}
  — Si hay 100.000 usuarios, crea 100.000 series para esta métrica
  Solución: NO incluir IDs individuales como etiquetas Prometheus
  En su lugar: instrumentar con histogramas por endpoint, no por usuario

Problema: etiqueta con demasiados valores de pod (en clusters muy grandes)
  Solución parcial: usar metric_relabel_configs para eliminar la etiqueta:
```

```yaml
# En la configuración del ServiceMonitor:
spec:
  endpoints:
  - port: metrics
    metricRelabelings:
    # Eliminar la etiqueta pod de métricas de alta cardinalidad
    - sourceLabels: [__name__]
      regex: 'very_high_cardinality_metric'
      action: drop    # O 'labeldrop' para solo eliminar la etiqueta
```

### Escenario 4: Grafana Muestra "No Data" en los Paneles

**Síntoma**: Los paneles de Grafana muestran "No data" o el mensaje "Error: No datapoints in time range".

```
Diagnóstico en orden:

1. Verificar el data source:
   Grafana → Connections → Data sources → Prometheus → Save & Test
   Si falla: el URL del data source es incorrecto o Prometheus no responde

2. Verificar que la métrica existe en Prometheus:
   Abrir http://localhost:9090
   Buscar la métrica directamente: escribir el nombre y hacer clic en Execute
   Si no aparece: Prometheus no está scrapeando esa métrica

3. Verificar el rango de tiempo en Grafana:
   Asegurarse de que el rango de tiempo (arriba a la derecha) incluye
   datos existentes. Si seleccionas "Last 5 minutes" pero la métrica
   solo tiene datos de hace 1 hora, no verás nada.

4. Verificar la query PromQL en el panel:
   Editar el panel → ir a la pestaña Query
   Hacer clic en "Run queries" con el botón de play
   Ver si devuelve datos o un error específico

5. Problema de namespace en la variable:
   Si el dashboard usa variables ($namespace), verificar que la variable
   esté correctamente configurada y tenga un valor seleccionado.
```

```bash
# Verificar conectividad desde Grafana a Prometheus
kubectl exec -n monitoring deploy/prometheus-grafana -- \
  wget -qO- http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090/-/healthy

# Resultado esperado: "Prometheus Server is Healthy."
```

### Escenario 5: AlertManager No Envía Notificaciones

**Síntoma**: Las alertas aparecen como FIRING en Prometheus pero no llegan al canal de Slack o email.

```bash
# Paso 1: Verificar que la alerta llega a AlertManager
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager -n monitoring 9093:9093 &
curl http://localhost:9093/api/v2/alerts | jq '.[].labels.alertname'

# Si la alerta no aparece en AlertManager pero sí en Prometheus:
#   → Problema de conectividad entre Prometheus y AlertManager
kubectl get secret alertmanager-prometheus-kube-prometheus-alertmanager \
  -n monitoring -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d

# Paso 2: Ver logs de AlertManager para errores de envío
kubectl logs alertmanager-prometheus-kube-prometheus-alertmanager-0 \
  -n monitoring -c alertmanager \
  | grep -i "error\|failed\|notify"

# Errores comunes en los logs:
#   "connection refused" → URL del webhook de Slack incorrecto
#   "no such host"       → nombre de dominio del receptor no resuelve
#   "401 Unauthorized"   → token o API key inválido

# Paso 3: Verificar la configuración del Secret
kubectl get secret alertmanager-prometheus-kube-prometheus-alertmanager \
  -n monitoring -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d | grep -A5 receivers
```

**Causas comunes:**

```
URL de Slack incorrecta o expirada
  → Regenerar el webhook en la configuración de Slack
  → Actualizar el Secret de AlertManager

Alerta en período de silencia
  → Verificar silencias activas: http://localhost:9093/#/silences

Regla de inhibición suprimiendo la alerta
  → Verificar inhibit_rules en la configuración de AlertManager

El grupo group_wait aún no ha expirado
  → AlertManager espera group_wait (por defecto 30s) antes del primer envío
```

### Escenario 6: Almacenamiento de Prometheus Lleno

**Síntoma**: El Pod de Prometheus muestra errores al escribir, o `kubectl get pvc -n monitoring` muestra uso al 100%.

```bash
# Verificar el uso del PVC de Prometheus
kubectl get pvc -n monitoring
# Salida esperada (problema):
# NAME                                                  STATUS   CAPACITY   ...
# prometheus-prometheus-kube-prometheus-prometheus-db   Bound    10Gi       ...
# (Si la columna USED aparece cerca de 10Gi, el disco está lleno)

# Ver uso desde dentro del Pod
kubectl exec prometheus-kube-prometheus-prometheus-0 -n monitoring -c prometheus -- \
  df -h /prometheus

# Verificar la retención configurada
kubectl get prometheus prometheus-kube-prometheus-prometheus \
  -n monitoring -o jsonpath='{.spec.retention}'
```

**Soluciones:**

```bash
# Solución 1: Reducir el período de retención
kubectl patch prometheus prometheus-kube-prometheus-prometheus \
  -n monitoring \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/retention", "value": "7d"}]'

# Solución 2: Ampliar el PVC (requiere StorageClass con allowVolumeExpansion=true)
kubectl patch pvc prometheus-prometheus-kube-prometheus-prometheus-db \
  -n monitoring \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/resources/requests/storage", "value": "30Gi"}]'

# Solución 3: Forzar compactación (libera espacio de bloques obsoletos)
# Esto borra datos fuera del período de retención inmediatamente
curl -X POST http://localhost:9090/api/v1/admin/tsdb/clean_tombstones
# Nota: requiere --web.enable-admin-api en los args de Prometheus

# Solución 4: Añadir retentionSize como límite de almacenamiento
# Editar los values de Helm:
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --reuse-values \
  --set prometheus.prometheusSpec.retentionSize="8GB"
  # Prometheus borrará los bloques más antiguos cuando supere este tamaño
```

---

## Resumen del Capítulo

Las métricas y los logs son complementarios: los logs dicen qué ocurrió, las métricas dicen cómo está rindiendo el sistema. Prometheus usa un modelo pull — hace scraping del endpoint `/metrics` de cada target cada 15-30 segundos — y almacena las muestras en su TSDB (base de datos de series temporales) local. Las cuatro tipos de métricas son Counter (solo sube), Gauge (sube y baja), Histogram (distribución en buckets) y Summary (quantiles pre-calculados en cliente).

El stack `kube-prometheus-stack` instala con un solo chart de Helm: Prometheus Server, AlertManager, Grafana, node-exporter, kube-state-metrics y el Prometheus Operator. El Operator gestiona la configuración mediante CRDs declarativos: ServiceMonitor para scraping, PrometheusRule para reglas de alerta, AlertmanagerConfig para routing de notificaciones.

PromQL permite consultar las series temporales con funciones como `rate()` para tasas de Counters, `histogram_quantile()` para percentiles de latencia, y operadores de agregación como `sum() by (namespace)`. Las diez queries esenciales cubren CPU por Pod, memoria, error rate HTTP, latencia P99, reinicios de contenedores, y predicción de llenado de disco.

Grafana se conecta a Prometheus como data source y permite importar dashboards de la comunidad (IDs: 315, 6417, 1860, 8588) o crear dashboards personalizados con variables interactivas. AlertManager recibe alertas de Prometheus y las enruta según reglas de severidad y equipo hacia canales de Slack, email o PagerDuty, con soporte para silencias, inhibición y agrupación para evitar alert fatigue.

Los seis problemas más comunes son: targets DOWN por mismatch de selectores, errores de scraping por NetworkPolicies o puertos incorrectos, OOM por alta cardinalidad en etiquetas, "No data" en Grafana por data source o query incorrecta, AlertManager sin notificaciones por webhook expirado o silencias activas, y almacenamiento lleno por retención demasiado larga.
