# Queries PromQL para el Laboratorio

Estas queries se ejecutan en Prometheus (http://localhost:9090) o como paneles en Grafana.

---

## 1. Consumo de CPU

### CPU por Pod (todas los namespaces del lab)
```promql
sum(rate(container_cpu_usage_seconds_total{namespace=~"tienda-.*|stress-test"}[5m])) by (pod, namespace)
```

### CPU por Namespace (total)
```promql
sum(rate(container_cpu_usage_seconds_total{namespace=~"tienda-.*|stress-test"}[5m])) by (namespace)
```

### % de CPU usado vs requested por namespace
```promql
sum(rate(container_cpu_usage_seconds_total{namespace=~"tienda-.*|stress-test"}[5m])) by (namespace)
/
sum(kube_pod_container_resource_requests{resource="cpu", namespace=~"tienda-.*|stress-test"}) by (namespace)
* 100
```

### Top 5 Pods que mas CPU consumen
```promql
topk(5, sum(rate(container_cpu_usage_seconds_total{namespace=~"tienda-.*|stress-test"}[5m])) by (pod, namespace))
```

---

## 2. Consumo de Memoria

### Memoria por Pod
```promql
sum(container_memory_usage_bytes{namespace=~"tienda-.*|stress-test"}) by (pod, namespace)
```

### Memoria por Namespace (en MB)
```promql
sum(container_memory_usage_bytes{namespace=~"tienda-.*|stress-test"}) by (namespace) / 1024 / 1024
```

### % de memoria usada vs limit
```promql
sum(container_memory_usage_bytes{namespace=~"tienda-.*|stress-test"}) by (pod, namespace)
/
sum(kube_pod_container_resource_limits{resource="memory", namespace=~"tienda-.*|stress-test"}) by (pod, namespace)
* 100
```

### Pods cerca de OOMKill (memoria > 80% del limit)
```promql
(
  sum(container_memory_usage_bytes{namespace=~"tienda-.*|stress-test"}) by (pod, namespace)
  /
  sum(kube_pod_container_resource_limits{resource="memory", namespace=~"tienda-.*|stress-test"}) by (pod, namespace)
) > 0.8
```

---

## 3. ResourceQuotas

### Uso de CPU vs quota por namespace
```promql
kube_resourcequota{namespace=~"tienda-.*|stress-test", resource="requests.cpu", type="used"}
```

### Quota de memoria (usado vs hard limit)
```promql
kube_resourcequota{namespace=~"tienda-.*|stress-test", resource="limits.memory"}
```

### % de quota de pods utilizada
```promql
kube_resourcequota{namespace=~"tienda-.*|stress-test", resource="pods", type="used"}
/
kube_resourcequota{namespace=~"tienda-.*|stress-test", resource="pods", type="hard"}
* 100
```

---

## 4. Estado de los Nodos

### CPU total usado por nodo
```promql
sum(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance)
```

### Memoria disponible por nodo (en GB)
```promql
node_memory_MemAvailable_bytes / 1024 / 1024 / 1024
```

### Disco disponible por nodo (en GB)
```promql
node_filesystem_avail_bytes{mountpoint="/"} / 1024 / 1024 / 1024
```

### Numero de nodos ready
```promql
count(kube_node_status_condition{condition="Ready", status="true"})
```

---

## 5. Estado de los Pods

### Pods en estado no-Running
```promql
kube_pod_status_phase{namespace=~"tienda-.*|stress-test", phase!="Running"} > 0
```

### Reinicios de contenedores (indica problemas)
```promql
sum(kube_pod_container_status_restarts_total{namespace=~"tienda-.*|stress-test"}) by (pod, namespace)
```

### Pods OOMKilled
```promql
kube_pod_container_status_last_terminated_reason{namespace=~"tienda-.*|stress-test", reason="OOMKilled"}
```

---

## 6. HPA (Autoscaling)

### Replicas actuales vs deseadas
```promql
kube_horizontalpodautoscaler_status_current_replicas{namespace="tienda-api"}
```

### Replicas maximas configuradas
```promql
kube_horizontalpodautoscaler_spec_max_replicas{namespace="tienda-api"}
```

---

## 7. Red y Servicios

### Trafico de red por Pod (bytes recibidos/seg)
```promql
sum(rate(container_network_receive_bytes_total{namespace=~"tienda-.*"}[5m])) by (pod, namespace)
```

### Trafico de red enviado por namespace
```promql
sum(rate(container_network_transmit_bytes_total{namespace=~"tienda-.*"}[5m])) by (namespace)
```

---

## Dashboards Recomendados en Grafana

Los siguientes dashboards vienen preinstalados con kube-prometheus-stack:

| Dashboard | Que muestra |
|-----------|-------------|
| **Kubernetes / Compute Resources / Cluster** | Vista global del cluster |
| **Kubernetes / Compute Resources / Namespace (Pods)** | CPU/Memoria por namespace |
| **Kubernetes / Compute Resources / Pod** | Detalle de un pod especifico |
| **Node Exporter / Nodes** | Metricas del SO de cada nodo |
| **Kubernetes / Networking / Namespace (Pods)** | Trafico de red |

Para filtrar por los namespaces del lab, usa el dropdown de namespace
y selecciona `tienda-web`, `tienda-api`, `tienda-db` o `stress-test`.
