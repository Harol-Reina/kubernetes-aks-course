# 📚 RESUMEN - Módulo 02 (Área 4): Prometheus y Grafana

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre **Prometheus y Grafana** — la stack de monitorización estándar de Kubernetes. Aprenderás a recolectar métricas de tu cluster y aplicaciones, crear alertas, y visualizar datos en dashboards de Grafana.

**Duración**: 6 horas (teoría + labs)
**Nivel**: Intermedio-Avanzado
**Prerequisitos**: Pods, Services, DaemonSets, kubectl top

---

## 📋 Objetivos de Aprendizaje

### Fundamentos
- ✅ Entender qué son las métricas y por qué importan
- ✅ Conocer la arquitectura de Prometheus (pull model)
- ✅ Diferenciar tipos de métricas: Counter, Gauge, Histogram, Summary
- ✅ Entender el rol de Grafana como visualizador

### Técnico
- ✅ Desplegar Prometheus en Kubernetes
- ✅ Configurar scraping de métricas
- ✅ Escribir queries PromQL básicos
- ✅ Crear dashboards en Grafana
- ✅ Configurar alertas con AlertManager
- ✅ Exponer métricas custom desde aplicaciones

---

## 🗺️ Estructura de Aprendizaje

### Arquitectura de Prometheus

```
┌─────────────────────────────────────────────────────────┐
│                   PROMETHEUS STACK                        │
│                                                          │
│  ┌──────────┐  scrape  ┌──────────────┐  query          │
│  │ Targets  │ ◄─────── │  Prometheus  │ ◄──── Grafana   │
│  │ (Pods)   │          │  (TSDB)      │       (UI)      │
│  │ /metrics │          │              │                  │
│  └──────────┘          └──────┬───────┘                  │
│                               │ alert                    │
│                               ▼                          │
│                        ┌──────────────┐                  │
│                        │ AlertManager │ → Email/Slack    │
│                        └──────────────┘                  │
└─────────────────────────────────────────────────────────┘
```

### Tipos de Métricas

| Tipo | Descripción | Ejemplo | Analogía |
|------|------------|---------|----------|
| **Counter** | Solo sube (nunca baja) | Total de requests HTTP | Odómetro del coche |
| **Gauge** | Sube y baja | Temperatura CPU, Pods activos | Termómetro |
| **Histogram** | Distribución de valores | Latencia de requests | Histograma de edades |
| **Summary** | Similar a Histogram | Percentiles de latencia | Resumen estadístico |

---

## 🔧 Comandos Esenciales

### PromQL Básico

```promql
# Uso de CPU por Pod
rate(container_cpu_usage_seconds_total[5m])

# Memoria usada por Pod
container_memory_working_set_bytes

# Requests HTTP por segundo
rate(http_requests_total[5m])

# Latencia promedio
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])

# Pods no ready
kube_pod_status_ready{condition="false"}

# Nodos con presión de memoria
kube_node_status_condition{condition="MemoryPressure", status="true"}
```

### kubectl para métricas

```bash
# Métricas de nodos
kubectl top nodes

# Métricas de Pods
kubectl top pods -n <namespace>

# Métricas de un Pod específico
kubectl top pod <pod-name> -n <namespace> --containers

# Ver endpoints de métricas
kubectl get endpoints -n monitoring
```

---

## 📝 Cheat Sheet: Configuración

### ServiceMonitor (Prometheus Operator)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: mi-app-monitor
spec:
  selector:
    matchLabels:
      app: mi-app
  endpoints:
  - port: metrics
    interval: 15s
    path: /metrics
```

### PrometheusRule (Alertas)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: pod-alerts
spec:
  groups:
  - name: pod-alerts
    rules:
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.pod }} está en CrashLoopBackOff"
```

---

## ❗ Problemas Comunes

### 1. Prometheus no encuentra targets
**Causa**: Los labels del ServiceMonitor no coinciden con el Service.
**Solución**: Verificar labels y que el endpoint `/metrics` responde.

### 2. Grafana no muestra datos
**Causa**: El datasource de Prometheus no está configurado.
**Solución**: Settings → Data Sources → Add → Prometheus → URL: http://prometheus:9090

### 3. Alertas no se disparan
**Causa**: AlertManager no está configurado o la regla tiene errores.
**Solución**: Verificar en Prometheus UI → Alerts que la regla está activa.

---

## ✅ Checklist

- [ ] Entiendo la arquitectura pull de Prometheus
- [ ] Conozco los 4 tipos de métricas
- [ ] Puedo escribir queries PromQL básicos
- [ ] Sé crear un ServiceMonitor
- [ ] Puedo configurar dashboards en Grafana
- [ ] Sé configurar alertas con AlertManager

---

## 📝 Preguntas de Repaso

### 1. ¿Por qué Prometheus usa pull en vez de push?

<details><summary>Ver respuesta</summary>
Con pull, Prometheus controla la frecuencia de recolección y puede detectar cuando un target está caído (porque deja de responder). Con push, el target envía métricas y si se cae, Prometheus no lo sabe inmediatamente. Además, pull simplifica la configuración: los targets solo necesitan exponer un endpoint /metrics.
</details>

### 2. ¿Cuál es la diferencia entre Counter y Gauge?

<details><summary>Ver respuesta</summary>
Un **Counter** solo puede incrementar (como el odómetro de un coche). Para ver la tasa de cambio se usa `rate()`. Un **Gauge** puede subir y bajar (como la temperatura). Se puede usar directamente para ver el valor actual.
</details>

### 3. ¿Qué es PromQL?

<details><summary>Ver respuesta</summary>
PromQL (Prometheus Query Language) es el lenguaje para consultar métricas en Prometheus. Permite filtrar por labels, calcular tasas de cambio (rate), agregar métricas (sum, avg), y crear expresiones para alertas y dashboards.
</details>

---

## 🎓 Certificaciones

- **CKA**: Monitorización del cluster, metrics-server
- **AKS**: Azure Monitor, Container Insights, Prometheus managed

---

## 🔗 Siguiente Paso

Continúa con el **Módulo 03: Alta Disponibilidad** para aprender a diseñar aplicaciones resistentes a fallos.
