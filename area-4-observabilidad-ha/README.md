# Área 4 - Observabilidad, Alta Disponibilidad e Integración

**Duración**: 9 horas  
**Modalidad**: Teórico – Práctico

## 🎯 Objetivos de Aprendizaje

Al completar esta área, serás capaz de:

- Implementar logging centralizado con Fluentd y Azure Log Analytics
- Configurar monitoreo completo con Prometheus y Grafana
- Crear dashboards y alertas personalizadas
- Implementar alta disponibilidad y autoescalado
- Configurar CI/CD pipelines para Kubernetes
- Implementar GitOps con ArgoCD
- Realizar troubleshooting avanzado de aplicaciones

---

## 📚 Módulo 1: Logging y Observabilidad (2.5 horas)

### Conceptos de Observabilidad

La **observabilidad** es la capacidad de entender el estado interno de un sistema basándose en sus salidas externas.

#### Los Tres Pilares de la Observabilidad

```
┌─────────────────────────────────────────────┐
│               OBSERVABILIDAD                │
├─────────────────┬───────────────┬───────────┤
│     LOGS        │   METRICS     │  TRACES   │
├─────────────────┼───────────────┼───────────┤
│ • Eventos       │ • Métricas    │ • Request │
│ • Errores       │ • Contadores  │   tracing │
│ • Debug info    │ • Gauges      │ • Latencia│
│ • Audit trails  │ • Histogramas │ • Spans   │
└─────────────────┴───────────────┴───────────┘
```

1. **Logs**: Eventos discretos con timestamp
2. **Metrics**: Mediciones numéricas agregadas
3. **Traces**: Seguimiento de requests a través de servicios

### Logging en Kubernetes

#### Niveles de Logging

1. **Pod/Container logs**: stdout/stderr de contenedores
2. **Node logs**: kubelet, container runtime, sistema
3. **Cluster logs**: API server, controller manager, scheduler

#### Arquitectura de Logging

```
Pods → Node Agent (Fluentd/Fluent Bit) → Aggregator → Storage (Elasticsearch/Azure Log Analytics)
                                                   ↓
                                               Visualization (Kibana/Azure Monitor)
```

### Azure Monitor y Log Analytics

#### Configurar Container Insights

```bash
# Habilitar Container Insights en AKS
az aks enable-addons \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --addons monitoring \
  --workspace-resource-id "/subscriptions/<subscription-id>/resourceGroups/rg-kubernetes-course/providers/Microsoft.OperationalInsights/workspaces/la-k8s-course"

# Verificar configuración
kubectl get pods -n kube-system | grep omsagent
```

#### Queries KQL Útiles

```kql
// Logs de contenedores con errores
ContainerLog
| where LogEntry contains "error" or LogEntry contains "ERROR"
| project TimeGenerated, Computer, ContainerID, LogEntry
| order by TimeGenerated desc

// Métricas de CPU por pod
Perf
| where ObjectName == "K8SContainer" and CounterName == "cpuUsageNanoCores"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m), InstanceName
| render timechart

// Eventos de Kubernetes
KubeEvents
| where Reason contains "Failed" or Reason contains "Error"
| project TimeGenerated, Namespace, Name, Reason, Message
| order by TimeGenerated desc
```

### Fluentd para Logging Centralizado

#### Configuración de Fluentd

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: kube-system
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      read_from_head true
      <parse>
        @type json
        time_format %Y-%m-%dT%H:%M:%S.%NZ
      </parse>
    </source>
    
    <filter kubernetes.**>
      @type kubernetes_metadata
    </filter>
    
    <match **>
      @type elasticsearch
      host elasticsearch.logging.svc.cluster.local
      port 9200
      index_name kubernetes
      type_name _doc
    </match>
```

### 🧪 Laboratorio 4.1: Configurar Logging Centralizado

#### Paso 1: Desplegar ELK Stack

```bash
# Crear namespace para logging
kubectl create namespace logging

# Desplegar Elasticsearch
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
  namespace: logging
spec:
  serviceName: elasticsearch
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
        env:
        - name: discovery.type
          value: single-node
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        ports:
        - containerPort: 9200
        - containerPort: 9300
        volumeMounts:
        - name: elasticsearch-data
          mountPath: /usr/share/elasticsearch/data
  volumeClaimTemplates:
  - metadata:
      name: elasticsearch-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: logging
spec:
  selector:
    app: elasticsearch
  ports:
  - port: 9200
    targetPort: 9200
EOF

# Desplegar Kibana
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:7.17.0
        env:
        - name: ELASTICSEARCH_HOSTS
          value: http://elasticsearch:9200
        ports:
        - containerPort: 5601
---
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: logging
spec:
  type: LoadBalancer
  selector:
    app: kibana
  ports:
  - port: 5601
    targetPort: 5601
EOF
```

#### Paso 2: Configurar Fluentd

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluentd
rules:
- apiGroups: [""]
  resources: ["pods", "namespaces"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluentd
roleRef:
  kind: ClusterRole
  name: fluentd
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: fluentd
  namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      serviceAccount: fluentd
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-elasticsearch
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.logging.svc.cluster.local"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        - name: FLUENT_ELASTICSEARCH_SCHEME
          value: "http"
        - name: FLUENT_UID
          value: "0"
        resources:
          limits:
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
EOF
```

#### Paso 3: Generar Logs de Prueba

```bash
# Aplicación que genera logs
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: log-generator
  namespace: desarrollo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: log-generator
  template:
    metadata:
      labels:
        app: log-generator
    spec:
      containers:
      - name: log-generator
        image: busybox
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo $(date) - INFO: This is a log message; echo $(date) - ERROR: This is an error message; sleep 30; done"]
EOF

# Verificar logs
kubectl logs -f deployment/log-generator -n desarrollo
```

#### Paso 4: Visualizar en Kibana

```bash
# Obtener IP de Kibana
KIBANA_IP=$(kubectl get service kibana -n logging -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Kibana URL: http://$KIBANA_IP:5601"

# Acceder a Kibana y configurar index pattern: kubernetes-*
```

---

## 📚 Módulo 2: Monitoreo con Prometheus y Grafana (2.5 horas)

### Arquitectura de Prometheus

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

#### Componentes Principales

1. **Prometheus Server**: Recolección y almacenamiento
2. **Alertmanager**: Gestión de alertas
3. **Pushgateway**: Para métricas batch
4. **Exporters**: Métricas de servicios externos

### Métricas en Kubernetes

#### Tipos de Métricas

1. **Infrastructure metrics**: CPU, memoria, red, disco
2. **Kubernetes metrics**: Pods, services, deployments
3. **Application metrics**: Métricas específicas de aplicación

#### Fuentes de Métricas

- **kubelet**: cAdvisor metrics
- **kube-state-metrics**: Estado de objetos Kubernetes
- **node-exporter**: Métricas del sistema operativo

### 🧪 Laboratorio 4.2: Instalar Prometheus Stack

#### Paso 1: Instalar con Helm

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

#### Paso 2: Acceder a Interfaces

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

#### Paso 3: Configurar ServiceMonitor Personalizado

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

### Consultas PromQL Útiles

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

### 🧪 Laboratorio 4.3: Crear Dashboards y Alertas

#### Paso 1: Importar Dashboards

```bash
# Lista de dashboards útiles para importar en Grafana:
# - 315: Kubernetes cluster monitoring
# - 8588: Kubernetes Deployment Statefulset Daemonset metrics
# - 6417: Kubernetes cluster overview
# - 7249: Kubernetes cluster (Prometheus)
```

#### Paso 2: Configurar Alertas

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

#### Paso 3: Configurar Notificaciones

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

## 📚 Módulo 3: Alta Disponibilidad y Autoescalado (2 horas)

### Horizontal Pod Autoscaler (HPA)

El **HPA** escala automáticamente el número de Pods basándose en métricas como CPU, memoria o métricas personalizadas.

#### Configuración Básica de HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
  namespace: desarrollo
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  minReplicas: 2
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
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

### Vertical Pod Autoscaler (VPA)

El **VPA** ajusta automáticamente los requests y limits de CPU y memoria.

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: app-vpa
  namespace: desarrollo
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: app
      controlledResources: ["cpu", "memory"]
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 2
        memory: 2Gi
```

### Cluster Autoscaler

El **Cluster Autoscaler** ajusta automáticamente el número de nodos en el clúster.

```bash
# Habilitar Cluster Autoscaler en AKS
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5

# Configurar profile de autoscaling
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --cluster-autoscaler-profile scale-down-delay-after-add=10m,scale-down-unneeded-time=10m
```

### Pod Disruption Budgets (PDB)

Los **PDB** definen el número mínimo de Pods que deben estar disponibles durante disrupciones voluntarias.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
  namespace: desarrollo
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: sample-app
```

### 🧪 Laboratorio 4.4: Configurar Autoescalado

#### Paso 1: Aplicación con Resource Requests

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stress-app
  namespace: desarrollo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: stress-app
  template:
    metadata:
      labels:
        app: stress-app
    spec:
      containers:
      - name: stress
        image: nginx:1.21
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: stress-app-service
  namespace: desarrollo
spec:
  selector:
    app: stress-app
  ports:
  - port: 80
    targetPort: 80
EOF
```

#### Paso 2: Configurar HPA

```bash
# Crear HPA
kubectl autoscale deployment stress-app \
  --namespace=desarrollo \
  --cpu-percent=50 \
  --min=2 \
  --max=10

# Verificar HPA
kubectl get hpa -n desarrollo
kubectl describe hpa stress-app -n desarrollo
```

#### Paso 3: Generar Carga y Probar Autoscaling

```bash
# Pod generador de carga
kubectl run load-generator \
  --image=busybox \
  --restart=Never \
  --namespace=desarrollo \
  -- /bin/sh -c "while true; do wget -q -O- http://stress-app-service; done"

# Monitorear HPA
kubectl get hpa stress-app -n desarrollo --watch

# Ver escalado de pods
kubectl get pods -n desarrollo -l app=stress-app --watch

# Limpiar carga
kubectl delete pod load-generator -n desarrollo
```

#### Paso 4: Configurar PDB

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: stress-app-pdb
  namespace: desarrollo
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: stress-app
EOF

# Verificar PDB
kubectl get pdb -n desarrollo
kubectl describe pdb stress-app-pdb -n desarrollo
```

---

## 📚 Módulo 4: Troubleshooting Avanzado (1 hora)

### Estrategias de Diagnóstico

#### Flujo de Troubleshooting

```
1. Identificar el problema
   ↓
2. Recopilar información
   ↓
3. Analizar logs y métricas
   ↓
4. Probar hipótesis
   ↓
5. Implementar solución
   ↓
6. Verificar resolución
```

### Comandos de Diagnóstico

#### Información del Clúster

```bash
# Estado general del clúster
kubectl cluster-info
kubectl get nodes
kubectl top nodes

# Eventos del clúster
kubectl get events --sort-by=.metadata.creationTimestamp

# Recursos del sistema
kubectl get pods -n kube-system
kubectl describe node <node-name>
```

#### Diagnóstico de Pods

```bash
# Estado de pods
kubectl get pods -o wide
kubectl describe pod <pod-name>

# Logs detallados
kubectl logs <pod-name> -c <container-name> --previous
kubectl logs <pod-name> --since=1h --tail=100

# Ejecutar comandos en pod
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec <pod-name> -- ps aux
kubectl exec <pod-name> -- netstat -tulpn
```

#### Diagnóstico de Red

```bash
# Conectividad entre pods
kubectl run test-pod --image=curlimages/curl -i --rm --restart=Never -- curl <service-url>

# DNS resolution
kubectl run test-dns --image=busybox -i --rm --restart=Never -- nslookup kubernetes.default

# Network policies
kubectl describe networkpolicy <policy-name>
```

### Escenarios Comunes de Troubleshooting

#### Pod en Estado Pending

```bash
# Verificar recursos del nodo
kubectl describe node

# Verificar PodDisruptionBudgets
kubectl get pdb -A

# Verificar taints y tolerations
kubectl describe node | grep Taints
```

#### Pod en CrashLoopBackOff

```bash
# Ver logs del contenedor anterior
kubectl logs <pod-name> --previous

# Verificar health checks
kubectl describe pod <pod-name> | grep -A 10 "Liveness\|Readiness"

# Verificar recursos
kubectl top pod <pod-name>
```

#### Problemas de Conectividad

```bash
# Verificar servicios
kubectl get svc
kubectl get endpoints

# Probar conectividad de red
kubectl exec -it <pod-name> -- telnet <service-ip> <port>

# Verificar DNS
kubectl exec -it <pod-name> -- cat /etc/resolv.conf
```

### 🧪 Laboratorio 4.5: Troubleshooting Práctico

#### Paso 1: Crear Aplicación con Problemas

```bash
# Aplicación con problemas intencionados
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: problematic-app
  namespace: desarrollo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: problematic-app
  template:
    metadata:
      labels:
        app: problematic-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        resources:
          requests:
            cpu: 2000m  # Recurso excesivo
            memory: 4Gi
          limits:
            cpu: 2000m
            memory: 4Gi
        readinessProbe:
          httpGet:
            path: /nonexistent  # Path que no existe
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
EOF
```

#### Paso 2: Diagnosticar Problemas

```bash
# Ver estado de pods
kubectl get pods -n desarrollo -l app=problematic-app

# Describir pod problemático
POD_NAME=$(kubectl get pods -n desarrollo -l app=problematic-app -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME -n desarrollo

# Ver eventos
kubectl get events -n desarrollo --sort-by=.metadata.creationTimestamp | tail -10

# Verificar recursos disponibles
kubectl top nodes
kubectl describe nodes | grep -A 5 "Allocated resources"
```

#### Paso 3: Corregir Problemas

```bash
# Corregir configuración
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: problematic-app
  namespace: desarrollo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: problematic-app
  template:
    metadata:
      labels:
        app: problematic-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        resources:
          requests:
            cpu: 100m  # Recurso razonable
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
        readinessProbe:
          httpGet:
            path: /  # Path correcto
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
EOF

# Verificar corrección
kubectl get pods -n desarrollo -l app=problematic-app
kubectl rollout status deployment/problematic-app -n desarrollo
```

---

## 📚 Módulo 5: CI/CD y GitOps (1 hora)

### Azure DevOps con AKS

#### Pipeline YAML para Kubernetes

```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

variables:
  dockerRegistryServiceConnection: 'acrConnection'
  imageRepository: 'myapp'
  containerRegistry: 'acrk8scourse.azurecr.io'
  dockerfilePath: '**/Dockerfile'
  tag: '$(Build.BuildId)'
  kubernetesServiceConnection: 'aksConnection'

stages:
- stage: Build
  displayName: Build and push image
  jobs:
  - job: Build
    steps:
    - task: Docker@2
      displayName: Build and push image
      inputs:
        command: buildAndPush
        repository: $(imageRepository)
        dockerfile: $(dockerfilePath)
        containerRegistry: $(dockerRegistryServiceConnection)
        tags: |
          $(tag)
          latest

- stage: Deploy
  displayName: Deploy to AKS
  dependsOn: Build
  jobs:
  - deployment: Deploy
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: Deploy to Kubernetes cluster
            inputs:
              action: deploy
              kubernetesServiceConnection: $(kubernetesServiceConnection)
              manifests: |
                k8s/deployment.yaml
                k8s/service.yaml
              containers: |
                $(containerRegistry)/$(imageRepository):$(tag)
```

### GitOps con ArgoCD

#### Instalación de ArgoCD

```bash
# Crear namespace
kubectl create namespace argocd

# Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Exponer ArgoCD Server
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Obtener password inicial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

#### Configurar Aplicación en ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mi-usuario/mi-repo-k8s
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

---

## 📝 Resumen del Área 4

### Conceptos Clave Aprendidos

1. **Observabilidad Completa**
   - Logging centralizado con ELK Stack
   - Monitoreo con Prometheus y Grafana
   - Alertas y notificaciones automatizadas

2. **Alta Disponibilidad**
   - Horizontal Pod Autoscaler (HPA)
   - Vertical Pod Autoscaler (VPA)
   - Cluster Autoscaler
   - Pod Disruption Budgets

3. **Troubleshooting**
   - Estrategias de diagnóstico sistemático
   - Herramientas de depuración
   - Resolución de problemas comunes

4. **CI/CD y GitOps**
   - Pipelines de Azure DevOps
   - GitOps con ArgoCD
   - Automatización de despliegues

### Habilidades Prácticas Desarrolladas

✅ Implementar observabilidad completa  
✅ Configurar monitoreo y alertas  
✅ Gestionar alta disponibilidad  
✅ Realizar troubleshooting efectivo  
✅ Automatizar despliegues con CI/CD  
✅ Implementar GitOps workflows  

### Preparación para el Proyecto Final

Con todo el conocimiento adquirido, estás listo para:
- Implementar una aplicación completa de 3 capas
- Configurar toda la infraestructura necesaria
- Aplicar mejores prácticas de seguridad y monitoreo
- Automatizar el ciclo de vida completo

---

## 🔗 Enlaces Útiles

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Azure DevOps with Kubernetes](https://docs.microsoft.com/en-us/azure/devops/pipelines/ecosystems/kubernetes/)

## ▶️ Siguiente: [Proyecto Final](../proyecto-final/README.md)