# Capítulo 34: Logging y Observabilidad

Con la operación segura, necesitamos visibilidad: saber qué ocurre dentro del cluster en tiempo real. La observabilidad se construye sobre tres pilares — logs, métricas y traces — y en este capítulo implementamos el primero con logging centralizado.

---

## Conceptos de Observabilidad

La **observabilidad** es la capacidad de entender el estado interno de un sistema basándose en sus salidas externas.

### Los Tres Pilares de la Observabilidad

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

## Logging en Kubernetes

### Niveles de Logging

1. **Pod/Container logs**: stdout/stderr de contenedores
2. **Node logs**: kubelet, container runtime, sistema
3. **Cluster logs**: API server, controller manager, scheduler

### Arquitectura de Logging

```
Pods → Node Agent (Fluentd/Fluent Bit) → Aggregator → Storage (Elasticsearch/Azure Log Analytics)
                                                   ↓
                                               Visualization (Kibana/Azure Monitor)
```

## Azure Monitor y Log Analytics

### Configurar Container Insights

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

### Queries KQL Útiles

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

## Fluentd para Logging Centralizado

### Configuración de Fluentd

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

## Laboratorio 4.1: Configurar Logging Centralizado

### Paso 1: Desplegar ELK Stack

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

### Paso 2: Configurar Fluentd

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

### Paso 3: Generar Logs de Prueba

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

### Paso 4: Visualizar en Kibana

```bash
# Obtener IP de Kibana
KIBANA_IP=$(kubectl get service kibana -n logging -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Kibana URL: http://$KIBANA_IP:5601"

# Acceder a Kibana y configurar index pattern: kubernetes-*
```

---

## Resumen del Capítulo

La observabilidad comienza con logging centralizado. Implementamos un stack ELK (Elasticsearch + Kibana) con Fluentd como agente recolector, y aprendimos a usar Azure Container Insights con queries KQL. Los tres niveles de logging (Pod, Node, Cluster) proporcionan visibilidad completa sobre lo que ocurre en el sistema.
