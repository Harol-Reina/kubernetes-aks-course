# 📚 RESUMEN - Módulo 01 (Área 4): Logging y Observabilidad

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre **logging y observabilidad** en Kubernetes — cómo recolectar, centralizar y analizar logs de tus aplicaciones y del cluster. Aprenderás a usar kubectl logs, configurar log forwarding con DaemonSets, y entender los tres pilares de la observabilidad (logs, métricas, traces).

**Duración**: 6 horas (teoría + labs)
**Nivel**: Intermedio
**Prerequisitos**: Pods, Deployments, DaemonSets, namespaces

---

## 📋 Objetivos de Aprendizaje

### Fundamentos
- ✅ Entender los 3 pilares de observabilidad: logs, métricas, traces
- ✅ Saber cómo Kubernetes captura logs de contenedores
- ✅ Diferenciar entre logging estructurado y no estructurado
- ✅ Entender stdout/stderr como salida estándar de logs

### Técnico
- ✅ Usar kubectl logs con todas sus opciones
- ✅ Configurar log forwarding con DaemonSets (Fluentd/Fluent Bit)
- ✅ Implementar logging estructurado (JSON)
- ✅ Configurar Container Insights en AKS
- ✅ Buscar y filtrar logs por nivel, timestamp, contenedor

### Troubleshooting
- ✅ Diagnosticar problemas usando logs
- ✅ Correlacionar logs entre múltiples Pods
- ✅ Recuperar logs de contenedores crasheados

---

## 🗺️ Estructura de Aprendizaje

### Los 3 Pilares de la Observabilidad

```
┌─────────────────────────────────────────────────────┐
│                 OBSERVABILIDAD                       │
│                                                      │
│   📝 LOGS          📊 MÉTRICAS      🔗 TRACES       │
│   ¿Qué pasó?      ¿Cómo está?     ¿Dónde tardó?   │
│                                                      │
│   • Texto libre    • Números       • Spans          │
│   • Eventos        • Contadores    • Latencia       │
│   • Errores        • Gauges        • Dependencias   │
│   • Debugging      • Alertas       • Request flow   │
│                                                      │
│   kubectl logs     Prometheus      Jaeger/Zipkin    │
│   Fluentd/EFK     Grafana         OpenTelemetry     │
│   Container Ins.  Azure Monitor   App Insights      │
└─────────────────────────────────────────────────────┘
```

### Flujo de Logs en Kubernetes

```
┌──────────┐     stdout/stderr     ┌──────────────┐     ┌───────────┐
│ Container│ ──────────────────►  │ kubelet       │ ──► │ Archivo   │
│ (app)    │                      │ (en el nodo)  │     │ en nodo   │
└──────────┘                      └──────────────┘     └─────┬─────┘
                                                             │
                                                             ▼
                                                    ┌───────────────┐
                                                    │ DaemonSet     │
                                                    │ (Fluentd/FB)  │
                                                    └───────┬───────┘
                                                            │
                                                            ▼
                                                    ┌───────────────┐
                                                    │ Elasticsearch │
                                                    │ / Azure Log   │
                                                    │ Analytics     │
                                                    └───────────────┘
```

---

## 🔧 Comandos Esenciales

### Básicos

```bash
# Ver logs de un Pod
kubectl logs <pod-name>

# Ver logs de un contenedor específico (multi-container)
kubectl logs <pod-name> -c <container-name>

# Logs en tiempo real (follow)
kubectl logs <pod-name> -f

# Últimas N líneas
kubectl logs <pod-name> --tail=50

# Logs desde hace X tiempo
kubectl logs <pod-name> --since=1h
kubectl logs <pod-name> --since=30m

# Logs de un contenedor crasheado (previous)
kubectl logs <pod-name> --previous

# Logs de TODOS los Pods con un label
kubectl logs -l app=webapp --all-containers

# Logs con timestamps
kubectl logs <pod-name> --timestamps
```

### Intermedios

```bash
# Filtrar logs con grep
kubectl logs <pod-name> | grep ERROR
kubectl logs <pod-name> | grep -i "warning\|error"

# Logs de un Deployment completo
kubectl logs deployment/<deploy-name> --all-containers

# Logs de un Job
kubectl logs job/<job-name>

# Contar errores
kubectl logs <pod-name> | grep -c ERROR

# Logs JSON parseados
kubectl logs <pod-name> | jq '.level, .message'
```

---

## 📝 Cheat Sheet: Logging Best Practices

### Logging Estructurado (JSON)

```json
{
  "timestamp": "2026-03-03T10:15:30Z",
  "level": "ERROR",
  "service": "api-backend",
  "message": "Failed to connect to database",
  "error": "connection refused",
  "host": "db.production.svc",
  "port": 5432,
  "retry_count": 3
}
```

### DaemonSet para Colector de Logs

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      tolerations:
      - operator: Exists
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:latest
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: containers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: containers
        hostPath:
          path: /var/lib/docker/containers
```

---

## ❗ Problemas Comunes y Soluciones

### 1. "No logs found" o logs vacíos
**Causa**: La aplicación no escribe a stdout/stderr.
**Solución**: Verificar que la app escribe logs a la consola, no a archivos internos.

### 2. Logs del contenedor anterior perdidos
**Solución**: `kubectl logs <pod> --previous` muestra los logs del contenedor crasheado anterior.

### 3. Demasiados logs, difícil encontrar errores
**Solución**: Implementar logging estructurado (JSON) y usar `jq` para filtrar, o centralizar con EFK/Container Insights.

### 4. Logs cortados o truncados
**Causa**: Kubernetes rota logs cuando superan 10MB por defecto.
**Solución**: Configurar log rotation o enviar a un sistema centralizado.

---

## ✅ Checklist de Conceptos

- [ ] Entiendo los 3 pilares de observabilidad
- [ ] Sé usar kubectl logs con --tail, --since, -f, --previous
- [ ] Puedo ver logs de contenedores específicos en Pods multi-container
- [ ] Entiendo stdout/stderr como mecanismo de logging
- [ ] Conozco la diferencia entre logging estructurado y no estructurado
- [ ] Sé cómo funcionan los DaemonSets para recolección de logs
- [ ] Puedo filtrar logs con grep y jq

---

## 📝 Preguntas de Repaso

### 1. ¿Por qué Kubernetes usa stdout/stderr para logs?

<details><summary>Ver respuesta</summary>
Kubernetes captura automáticamente todo lo que un contenedor escribe a stdout y stderr. El kubelet almacena estos logs en archivos del nodo. Esto permite que kubectl logs funcione sin configuración adicional y que herramientas de recolección (Fluentd, Fluent Bit) los procesen de forma estándar.
</details>

### 2. ¿Cómo ves logs de un contenedor que ya crasheó?

<details><summary>Ver respuesta</summary>
`kubectl logs <pod-name> --previous` muestra los logs de la ejecución anterior del contenedor. Útil para diagnosticar CrashLoopBackOff.
</details>

### 3. ¿Cuál es la ventaja del logging estructurado (JSON)?

<details><summary>Ver respuesta</summary>
Los logs JSON pueden ser parseados automáticamente por herramientas de análisis (Elasticsearch, Azure Log Analytics). Permiten buscar por campos específicos (level=ERROR, service=api), crear dashboards, y configurar alertas basadas en patrones. Los logs de texto plano requieren regex para ser parseados.
</details>

### 4. ¿Qué hace un DaemonSet de recolección de logs?

<details><summary>Ver respuesta</summary>
Corre un Pod colector en cada nodo que lee los archivos de log del nodo (/var/log/containers/) y los envía a un sistema centralizado (Elasticsearch, Azure Log Analytics, Splunk). Garantiza que los logs se recolectan de todos los nodos automáticamente.
</details>

---

## 🎓 Relevancia para Certificaciones

- **CKA**: kubectl logs, diagnóstico con logs (~5%)
- **CKAD**: Logging de aplicaciones, multi-container logging
- **AKS**: Container Insights, Azure Monitor, Log Analytics

---

## 🔗 Siguiente Paso

Continúa con el **Módulo 02: Prometheus y Grafana** para aprender el segundo pilar de observabilidad: las métricas.
