# Capítulo 35: Prometheus y Grafana

Los logs dan visibilidad sobre eventos. Prometheus y Grafana añaden el segundo pilar: métricas numéricas en tiempo real con dashboards visuales y alertas automatizadas.

---

## Arquitectura de Prometheus

```
┌─────────────────────────────────────────────┐
│                PROMETHEUS                   │
├─────────────────┬───────────────────────────┤
│   COLLECTION    │         STORAGE           │
├─────────────────┼───────────────────────────┤
│ • Service       │ • Time Series DB          │
│   Discovery     │ • Retention Policies      │
│ • Metrics       │ • Local Storage           │
│   Scraping      │ • Remote Storage          │
│ • Alertmanager  │                           │
└─────────────────┴───────────────────────────┘
```

### Componentes Principales

1. **Prometheus Server**: Recolección y almacenamiento
2. **Alertmanager**: Gestión de alertas
3. **Pushgateway**: Para métricas batch
4. **Exporters**: Métricas de servicios externos

## Métricas en Kubernetes

### Tipos de Métricas

1. **Infrastructure metrics**: CPU, memoria, red, disco
2. **Kubernetes metrics**: Pods, services, deployments
3. **Application metrics**: Métricas específicas de aplicación

### Fuentes de Métricas

- **kubelet**: cAdvisor metrics
- **kube-state-metrics**: Estado de objetos Kubernetes
- **node-exporter**: Métricas del sistema operativo

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

## Resumen del Capítulo

Prometheus recolecta métricas mediante scraping, las almacena en una base de datos de series temporales y evalúa reglas de alerta. Grafana visualiza esas métricas en dashboards. Instalamos el stack completo con Helm, configuramos ServiceMonitors para métricas personalizadas, escribimos queries PromQL y creamos alertas para detectar pods en crash loop, alto uso de CPU/memoria y pods no listos.
