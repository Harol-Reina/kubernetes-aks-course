# Capítulo 34: Logging y Observabilidad

Hemos completado el bloque de seguridad y operaciones: RBAC, Network Policies, almacenamiento persistente y Azure Key Vault. El cluster está asegurado, los datos persisten y los secretos están protegidos. Ahora pasamos al área más crítica para el día a día de operaciones: ¿qué está ocurriendo dentro del cluster en este momento?

Imagina que un usuario reporta que la aplicación devolvió un error a las 3:47 AM. Tienes 50 Pods repartidos en 10 nodos. ¿Cuál de esos Pods procesó esa request? ¿Qué línea de log corresponde al error? Sin logging centralizado, tendrías que conectarte a cada nodo, buscar en cada archivo de log del sistema, ejecutar `kubectl logs` en cada Pod individualmente — y para cuando termines, el Pod responsable ya ha podido haberse reiniciado y sus logs locales han desaparecido. El problema es invisible.

El logging centralizado resuelve esto: un agente como Fluent Bit corre en cada nodo como DaemonSet, recopila la salida stdout/stderr de todos los contenedores, enriquece los logs con metadatos de Kubernetes (nombre del Pod, namespace, labels), y los envía a un almacén centralizado como Azure Log Analytics. Desde ahí puedes buscar en todos los logs con una sola consulta, crear alertas y visualizar patrones en dashboards.

Piensa en el logging centralizado como las cámaras de seguridad de un edificio: sin ellas, si algo ocurre solo sabes que pasó, pero no dónde ni cómo. Con ellas, puedes reproducir exactamente qué ocurrió, en qué lugar y a qué hora — y configurar alarmas para situaciones específicas.

En este capítulo aprenderás los tres pilares de la observabilidad (logs, métricas y traces), a usar `kubectl logs` con sus opciones avanzadas, a desplegar Fluent Bit como DaemonSet para recolección de logs, a integrar con Azure Monitor y Log Analytics Workspace, y a implementar logging estructurado en JSON para consultas más eficientes.

---

## Los Tres Pilares de Observabilidad: Desde Cero

### ¿Qué es la Observabilidad?

La **observabilidad** es la capacidad de entender el estado interno de un sistema basándose únicamente en sus salidas externas — sin necesidad de modificar el sistema para inspeccionarlo. El concepto viene de la teoría de control: un sistema es "observable" si su estado interno puede determinarse a partir de sus outputs.

En el contexto de Kubernetes y microservicios, esto significa responder tres preguntas fundamentales en cualquier momento:

- **¿Qué ocurrió?** — Algún evento específico tuvo lugar. Un error. Una excepción. Una conexión rechazada.
- **¿Cómo está rindiendo el sistema?** — CPU al 95%. Latencia en aumento. Tasa de errores HTTP 500.
- **¿Dónde fue la request del usuario?** — Pasó por 7 servicios. Se tardó 2 segundos en el servicio de pagos.

Cada pregunta corresponde a uno de los tres pilares:

```
┌─────────────────────────────────────────────────────────────────┐
│                        OBSERVABILIDAD                           │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │     LOGS     │    │   METRICS    │    │    TRACES    │      │
│  │              │    │              │    │              │      │
│  │  "¿Qué       │    │  "¿Cómo      │    │  "¿Dónde     │      │
│  │   pasó?"     │    │   rinde?"    │    │   fue?"      │      │
│  │              │    │              │    │              │      │
│  │  Eventos     │    │  Números     │    │  Camino      │      │
│  │  Errores     │    │  CPU/RAM     │    │  Latencia    │      │
│  │  Audit trail │    │  Tasa req    │    │  Spans       │      │
│  │              │    │              │    │              │      │
│  │  ELK / Loki  │    │  Prometheus  │    │  Jaeger      │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                 │
│  Capítulo 34 (este)   Capítulo 35          Capítulo futuro     │
└─────────────────────────────────────────────────────────────────┘
```

### Los Tres Pilares en Detalle

**Pilar 1: Logs — Eventos Discretos**

Un log es un registro de un evento que ocurrió en un momento específico. Tiene timestamp, nivel de severidad, mensaje y contexto. Los logs responden a "¿QUÉ pasó exactamente?"

```
2024-03-15T10:30:01Z  ERROR  user-api  Failed to connect to database: timeout after 30s
2024-03-15T10:30:02Z  WARN   user-api  Retrying database connection (attempt 2/3)
2024-03-15T10:30:05Z  INFO   user-api  Database connection established
```

Los logs son el pilar más inmediato — cuando algo falla, los logs son el primer lugar a mirar. Son la diferencia entre "la aplicación devolvió 500" y "la aplicación devolvió 500 porque la conexión a la base de datos expiró tras 30 segundos".

**Pilar 2: Metrics — Mediciones Numéricas en el Tiempo**

Una métrica es un número medido periódicamente. CPU al 45%. 1,200 requests por segundo. 15ms de latencia en el percentil 99. Las métricas responden a "¿CÓMO está rindiendo el sistema?" y permiten detectar tendencias antes de que se conviertan en problemas.

```
# Ejemplo de métricas de Prometheus
http_requests_total{method="GET", status="200", service="user-api"} 58234
http_request_duration_seconds{quantile="0.99", service="user-api"}  0.015
container_cpu_usage_seconds_total{pod="user-api-abc123", namespace="prod"} 1.234
```

Las métricas son eficientes en almacenamiento (un número cada 15 segundos vs miles de líneas de log) y permiten crear dashboards y alertas automáticas.

**Pilar 3: Traces — Seguimiento de Requests Distribuidas**

Un trace registra el camino completo de una request a través de múltiples servicios. Cada servicio que procesa la request añade un "span" con su tiempo de procesamiento. Los traces responden a "¿DÓNDE está el cuello de botella o el fallo?"

```
Request del usuario: 340ms total
  ├── API Gateway:         5ms
  ├── Servicio de Auth:   12ms
  ├── Servicio de Users:  18ms
  ├── Servicio de Pagos: 280ms  ← aquí está el problema
  └── Base de datos:     25ms
```

Los traces son esenciales en arquitecturas de microservicios donde una sola request de usuario puede atravesar 10-20 servicios.

### Por Qué Necesitas los Tres Pilares

Un solo pilar es insuficiente para entender lo que ocurre en producción:

| Solo con... | Puedes ver | No puedes ver |
|-------------|-----------|---------------|
| Solo Logs | Qué errores ocurrieron | Si el sistema está degradándose gradualmente |
| Solo Metrics | Que la latencia subió a las 3 AM | Por qué subió (qué error específico) |
| Solo Traces | Qué servicio es lento | Si hay patrones a lo largo del tiempo |

La observabilidad real combina los tres: las **métricas** te alertan de que algo está mal, los **logs** te dicen exactamente qué ocurrió, y los **traces** te muestran dónde en el flujo distribuido ocurrió el problema.

### Niveles de Madurez en Observabilidad

La mayoría de los equipos comienzan con lo básico y van añadiendo capas:

```
Nivel 0: Sin observabilidad
  └── "No sé que algo está mal hasta que el usuario se queja"

Nivel 1: kubectl logs básico
  └── Puedes ver logs de un Pod individual si sabes cuál buscar

Nivel 2: Logging centralizado
  └── Todos los logs en un sistema central, buscable con queries

Nivel 3: Métricas + Alertas
  └── Sabes que algo está mal antes de que el usuario te avise

Nivel 4: Traces distribuidos
  └── Puedes seguir una request a través de todos los servicios

Nivel 5: Observabilidad completa
  └── Correlación automática entre logs, métricas y traces
```

Este capítulo te lleva del Nivel 1 al Nivel 2 con los fundamentos del Nivel 3. Los capítulos siguientes cubren métricas con Prometheus/Grafana (Nivel 3) y la integración con Azure Monitor.

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

---

## kubectl logs: Opciones Básicas y Avanzadas

El punto de entrada al logging en Kubernetes es `kubectl logs`. Antes de configurar un sistema centralizado, es esencial dominar este comando: es la herramienta de diagnóstico rápido que usarás cientos de veces al día.

### Uso Básico

```bash
# Log del Pod actual (todos los contenedores del Pod si solo hay uno)
kubectl logs <nombre-del-pod>

# Ejemplo concreto
kubectl logs web-app-7d9f8b-xk2p4

# Salida esperada:
# 2024-03-15T10:30:01Z INFO  Server started on :8080
# 2024-03-15T10:30:02Z INFO  Connecting to database...
# 2024-03-15T10:30:05Z INFO  Database connection established
# 2024-03-15T10:30:10Z INFO  Health check: OK
```

### Pods con Múltiples Contenedores

Cuando un Pod tiene varios contenedores (patrón sidecar, init containers), debes especificar cuál:

```bash
# Listar contenedores de un Pod
kubectl get pod web-app-7d9f8b-xk2p4 -o jsonpath='{.spec.containers[*].name}'
# Salida: web-app fluent-bit

# Ver logs de un contenedor específico
kubectl logs web-app-7d9f8b-xk2p4 -c web-app
kubectl logs web-app-7d9f8b-xk2p4 -c fluent-bit

# Ver todos los contenedores a la vez
kubectl logs web-app-7d9f8b-xk2p4 --all-containers=true
```

### Contenedor Anterior (Después de un Crash)

Cuando un contenedor se reinicia (CrashLoopBackOff, OOMKilled), los logs del contenedor muerto se pierden — a menos que uses `--previous`:

```bash
# Ver logs del contenedor que acaba de crashear
kubectl logs web-app-7d9f8b-xk2p4 --previous

# Combinado: ver los últimos 50 líneas del contenedor anterior
kubectl logs web-app-7d9f8b-xk2p4 --previous --tail=50

# Salida esperada (un crash por OOM):
# 2024-03-15T10:45:01Z INFO  Processing batch of 50000 records...
# 2024-03-15T10:45:03Z INFO  Allocating memory buffer...
# Killed
```

### Seguimiento en Tiempo Real

```bash
# Seguir logs en tiempo real (equivalente a tail -f)
kubectl logs -f web-app-7d9f8b-xk2p4

# Seguir + solo los últimos 20 líneas como punto de partida
kubectl logs -f web-app-7d9f8b-xk2p4 --tail=20
```

### Filtros por Tiempo

```bash
# Logs de la última hora
kubectl logs web-app-7d9f8b-xk2p4 --since=1h

# Logs de los últimos 30 minutos
kubectl logs web-app-7d9f8b-xk2p4 --since=30m

# Logs desde una fecha/hora específica (formato RFC3339)
kubectl logs web-app-7d9f8b-xk2p4 --since-time="2024-03-15T10:00:00Z"

# Salida esperada:
# 2024-03-15T10:00:05Z INFO  Service started
# 2024-03-15T10:01:20Z WARN  High memory usage detected: 85%
# 2024-03-15T10:01:45Z ERROR DB connection pool exhausted
```

### Limitar Número de Líneas

```bash
# Solo las últimas 100 líneas
kubectl logs web-app-7d9f8b-xk2p4 --tail=100

# Las últimas 50 líneas de todos los contenedores
kubectl logs web-app-7d9f8b-xk2p4 --all-containers=true --tail=50
```

### Logs de un Deployment Completo

En lugar de buscar el nombre exacto del Pod, puedes apuntar directamente al Deployment:

```bash
# Logs de cualquier Pod del Deployment (el primero que encuentre)
kubectl logs deployment/web-app

# Las últimas 100 líneas de TODOS los Pods del Deployment
kubectl logs deployment/web-app --tail=100 --all-containers=true

# Salida esperada:
# Found 3 pods, using pod/web-app-7d9f8b-xk2p4
# 2024-03-15T10:30:01Z INFO  Server started on :8080
# 2024-03-15T10:30:05Z INFO  Connected to database
# ...
```

### Filtrar por Labels

Para ver logs de múltiples Pods que comparten una label, sin necesitar los nombres exactos:

```bash
# Logs de todos los Pods con label app=web-app
kubectl logs -l app=web-app

# Combinar con tail para no saturar la terminal
kubectl logs -l app=web-app --tail=20

# Logs de todos los Pods del namespace produccion con ese label
kubectl logs -l app=web-app -n produccion --tail=50

# Seguimiento en tiempo real de todos los Pods de un servicio
kubectl logs -l app=web-app -f --tail=10
```

### Tabla de Opciones Más Útiles

| Opción | Descripción | Ejemplo |
|--------|-------------|---------|
| `-c <nombre>` | Contenedor específico | `-c nginx` |
| `--previous` / `-p` | Contenedor anterior (tras crash) | `--previous` |
| `-f` / `--follow` | Seguimiento en tiempo real | `-f` |
| `--tail=N` | Últimas N líneas | `--tail=100` |
| `--since=<dur>` | Logs desde hace X tiempo | `--since=1h` |
| `--since-time=<ts>` | Logs desde timestamp RFC3339 | `--since-time="2024-01-01T00:00:00Z"` |
| `--all-containers` | Todos los contenedores del Pod | `--all-containers=true` |
| `-l <selector>` | Filtrar por label selector | `-l app=web-app` |

### Limitaciones de kubectl logs

`kubectl logs` es excelente para debugging puntual, pero tiene limitaciones fundamentales que hacen imprescindible un sistema de logging centralizado:

1. **Solo contenedor actual o anterior**: No puedes ver el historial completo de reinicios previos.
2. **Logs efímeros**: Cuando un Pod es eliminado (por scaling, rollout, nodo caído), sus logs desaparecen para siempre.
3. **Sin búsqueda ni filtrado**: No puedes hacer `grep "user_id=12345"` a través de múltiples Pods de forma eficiente.
4. **No escala**: Con 100 Pods repartidos en 20 nodos, revisar logs manualmente es inviable.
5. **Sin correlación**: No puedes correlacionar un log con una métrica o un evento de Kubernetes.
6. **Sin almacenamiento histórico**: No puedes ver qué ocurrió hace 3 días si el Pod ya no existe.

---

## ¿Por Qué No Basta con kubectl logs?

Considera este escenario real:

> Un usuario reporta que recibió un error 500 a las 3:47 AM del jueves pasado. Tu aplicación tiene 50 Pods repartidos en 10 nodos, y hay rolling deployments cada hora. ¿Qué haces?

Con solo `kubectl logs`:

1. Necesitas saber qué Pod procesó esa request — imposible sin logging centralizado.
2. Si encontraras el Pod, probablemente ya fue reemplazado en el siguiente deployment.
3. Incluso si el Pod sigue vivo, `kubectl logs` solo guarda el buffer reciente del runtime del contenedor (típicamente ~10MB o los últimos ~10,000 mensajes según la configuración del nodo).
4. Tendrías que ejecutar `kubectl logs` en los 50 Pods y hacer grep manualmente — llevando 10-15 minutos.

### El Problema del Logging a Escala

```
Sin logging centralizado:              Con logging centralizado:

Pod1 → logs en nodo1                   Pod1 ─┐
Pod2 → logs en nodo1                   Pod2 ─┤
Pod3 → logs en nodo2       vs          Pod3 ─┼──▶ [Almacén Central] ──▶ [Dashboard]
Pod4 → logs en nodo2                   Pod4 ─┤    (Elasticsearch)       (Kibana)
Pod5 → logs en nodo3                   Pod5 ─┘    (Azure Log Analytics) (Azure Monitor)

❌ Buscar = SSH a cada nodo            ✅ Buscar = una query de 3 segundos
❌ Logs desaparecen con el Pod         ✅ Logs retenidos 30-90 días
❌ Sin alertas automáticas             ✅ Alerta en Slack cuando error rate > 5%
❌ Sin visibilidad histórica           ✅ Puedes ver qué pasó hace 2 semanas
```

### Cuándo Usar Cada Herramienta

| Situación | Herramienta recomendada |
|-----------|------------------------|
| Debugging rápido de un Pod específico | `kubectl logs` |
| Ver logs de un crash reciente | `kubectl logs --previous` |
| Seguir logs en tiempo real durante desarrollo | `kubectl logs -f` |
| Investigar un error reportado por un usuario | Sistema centralizado (ELK/Loki/Azure Monitor) |
| Crear alertas basadas en patrones de log | Sistema centralizado |
| Auditoría o análisis histórico | Sistema centralizado |
| Correlacionar logs con métricas | Sistema centralizado + Prometheus |

El flujo de trabajo recomendado es: **usar el sistema centralizado primero** para encontrar el Pod y el timestamp relevante, luego usar `kubectl logs` si necesitas ver el contexto en tiempo real de ese Pod específico.

---

## Logging Centralizado: Arquitectura

### El Patrón DaemonSet

La arquitectura estándar de logging en Kubernetes utiliza el patrón **DaemonSet**: un Pod agente de logging se ejecuta en cada nodo del cluster, garantizando que no hay nodo sin cobertura. Este agente:

1. Lee los archivos de log de todos los contenedores en el nodo (`/var/log/containers/*.log`)
2. Parsea y estructura los logs
3. Enriquece con metadatos de Kubernetes (Pod name, namespace, labels, node name)
4. Envía al sistema centralizado de almacenamiento

```
┌────────────────────────────────────────────────────────────────┐
│  CLUSTER KUBERNETES                                            │
│                                                                │
│  ┌──────────────────┐  ┌──────────────────┐                  │
│  │     Nodo 1       │  │     Nodo 2       │                  │
│  │                  │  │                  │                  │
│  │  Pod: web-1      │  │  Pod: web-2      │                  │
│  │  Pod: api-1      │  │  Pod: api-2      │     ...          │
│  │  Pod: db-1       │  │  Pod: worker-1   │                  │
│  │                  │  │                  │                  │
│  │  ┌────────────┐  │  │  ┌────────────┐  │                  │
│  │  │ Fluent Bit │  │  │  │ Fluent Bit │  │                  │
│  │  │ (DaemonSet)│  │  │  │ (DaemonSet)│  │                  │
│  │  └─────┬──────┘  │  │  └─────┬──────┘  │                  │
│  └────────┼─────────┘  └────────┼─────────┘                  │
│           │                     │                             │
│           └──────────┬──────────┘                             │
│                      ▼                                        │
│           ┌─────────────────────┐                             │
│           │   Almacén Central   │                             │
│           │                     │                             │
│           │  Elasticsearch /    │──▶  Kibana / Grafana        │
│           │  Azure Log Analytics│──▶  Azure Monitor           │
│           │  Loki               │──▶  Grafana                 │
│           └─────────────────────┘                             │
└────────────────────────────────────────────────────────────────┘
```

### Comparativa: Agentes de Logging

| Característica | Fluentd | Fluent Bit | Promtail |
|----------------|---------|-----------|----------|
| Uso de memoria | ~40 MB | ~15 MB | ~25 MB |
| Uso de CPU | Medio | Muy bajo | Bajo |
| Número de plugins | 700+ | 70+ | Solo Loki |
| Lenguaje | Ruby | C | Go |
| Complejidad config | Alta | Media | Baja |
| Transformaciones | Muy completas | Básicas | Básicas |
| Mejor para | Routing complejo, múltiples destinos | Recursos limitados, AKS | Stack Grafana/Loki |
| Certificaciones | CKA/CKAD | CKA/CKAD | CKAD |

**Recomendación por caso de uso:**

- **AKS + Azure Monitor**: Usa el agente `omsagent` integrado (Container Insights). Cero configuración.
- **AKS + Elasticsearch/Loki**: Usa **Fluent Bit** — más ligero, nativo en Kubernetes, excelente rendimiento.
- **Infraestructura compleja, múltiples destinos**: Usa **Fluentd** cuando necesites routing condicional, transformaciones avanzadas o fanout a varios sistemas.
- **Stack Grafana completo**: Usa **Promtail** si ya tienes Loki como backend.

### Backends de Almacenamiento

| Backend | Tipo | Fortalezas | Debilidades |
|---------|------|-----------|------------|
| Elasticsearch | Search engine | Búsqueda full-text poderosa, Kibana | Alto consumo de recursos, coste |
| Azure Log Analytics | SaaS managed | Cero ops, integrado con AKS, KQL | Coste por GB, vendor lock-in |
| Loki | Log aggregation | Bajo coste, etiquetas como Prometheus | Búsqueda full-text limitada |
| OpenSearch | Search engine | Open source, compatible con ES API | Comunidad más pequeña |

---

## Azure Monitor y Container Insights

### ¿Qué es Container Insights?

**Container Insights** es la solución de monitoreo integrada de AKS dentro de Azure Monitor. A diferencia de Fluent Bit o Elasticsearch (que debes configurar y mantener tú mismo), Container Insights es un add-on gestionado: lo activas con un comando y Azure se encarga del resto.

Cuando lo habilitas, Azure despliega automáticamente el agente `omsagent` como DaemonSet en tu cluster. Este agente recopila:

- Logs stdout/stderr de todos los contenedores
- Métricas de CPU y memoria por Pod, nodo y namespace
- Eventos de Kubernetes (Pods fallando, reinicios, evictions)
- Salud de los nodos y del cluster en general
- Logs del plano de control (API server, controller manager)

### Habilitar Container Insights en AKS

**Opción 1: Durante la creación del cluster**

```bash
# Crear Log Analytics Workspace
az monitor log-analytics workspace create \
  --resource-group rg-kubernetes-course \
  --workspace-name la-k8s-course \
  --location eastus

# Obtener el ID del workspace
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group rg-kubernetes-course \
  --workspace-name la-k8s-course \
  --query id -o tsv)

# Crear AKS con monitoring habilitado desde el inicio
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --node-count 3 \
  --enable-addons monitoring \
  --workspace-resource-id $WORKSPACE_ID \
  --generate-ssh-keys
```

**Opción 2: En un cluster existente**

```bash
# Habilitar Container Insights en AKS existente
az aks enable-addons \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --addons monitoring \
  --workspace-resource-id "/subscriptions/<subscription-id>/resourceGroups/rg-kubernetes-course/providers/Microsoft.OperationalInsights/workspaces/la-k8s-course"

# Verificar que el agente está corriendo
kubectl get pods -n kube-system | grep omsagent

# Salida esperada:
# omsagent-4fzx2          1/1     Running   0          2m
# omsagent-7k9p1          1/1     Running   0          2m
# omsagent-rs-6d8b9c79d   1/1     Running   0          2m
# (uno por nodo + un ReplicaSet para el aggregator)

# Verificar la configuración del addon
az aks addon show \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --addon monitoring
```

### Queries KQL Útiles

**KQL (Kusto Query Language)** es el lenguaje de consulta de Azure Monitor. Es similar a SQL pero orientado a series temporales y análisis de logs.

```kql
// ─── Logs de contenedores con errores ───────────────────────────────────────
ContainerLog
| where LogEntry contains "error" or LogEntry contains "ERROR"
| project TimeGenerated, Computer, ContainerID, LogEntry
| order by TimeGenerated desc
| take 50

// ─── Buscar errores en un namespace específico ───────────────────────────────
ContainerLog
| where Namespace == "produccion"
| where LogEntry contains "exception" or LogEntry contains "Exception"
| project TimeGenerated, PodName, ContainerName, LogEntry
| order by TimeGenerated desc

// ─── Pods con más reinicios en las últimas 24 horas ─────────────────────────
KubePodInventory
| where TimeGenerated > ago(24h)
| where PodRestartCount > 0
| summarize MaxRestarts = max(PodRestartCount) by PodName, Namespace
| order by MaxRestarts desc
| take 20

// ─── Métricas de CPU por Pod ─────────────────────────────────────────────────
Perf
| where ObjectName == "K8SContainer" and CounterName == "cpuUsageNanoCores"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m), InstanceName
| render timechart

// ─── Memoria usada por namespace ─────────────────────────────────────────────
KubePodInventory
| where TimeGenerated > ago(1h)
| join kind=inner (
    Perf
    | where ObjectName == "K8SContainer"
    | where CounterName == "memoryWorkingSetBytes"
    | summarize AvgMemory = avg(CounterValue) by InstanceName
) on $left.ContainerName == $right.InstanceName
| summarize TotalMemoryMB = sum(AvgMemory) / 1024 / 1024 by Namespace
| order by TotalMemoryMB desc

// ─── Eventos de error de Kubernetes ──────────────────────────────────────────
KubeEvents
| where Reason contains "Failed" or Reason contains "Error" or Reason == "OOMKilling"
| project TimeGenerated, Namespace, Name, Reason, Message
| order by TimeGenerated desc

// ─── Tasa de errores HTTP 5xx en la última hora ──────────────────────────────
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry matches regex @'"status":\s*5\d\d'
| summarize ErrorCount = count() by bin(TimeGenerated, 5m), PodName
| render timechart
```

### Crear Alertas desde Queries KQL

Una de las ventajas clave de Container Insights es la capacidad de crear alertas automáticas:

```bash
# Crear una alerta cuando haya más de 10 errores por minuto
az monitor scheduled-query create \
  --resource-group rg-kubernetes-course \
  --name "alerta-errores-produccion" \
  --scopes "/subscriptions/<id>/resourceGroups/rg-kubernetes-course/providers/Microsoft.OperationalInsights/workspaces/la-k8s-course" \
  --condition-query "ContainerLog | where Namespace == 'produccion' | where LogEntry contains 'ERROR' | summarize count() by bin(TimeGenerated, 1m)" \
  --condition-threshold 10 \
  --condition-operator GreaterThan \
  --condition-time-aggregation Count \
  --evaluation-frequency 5m \
  --window-size 5m \
  --severity 2 \
  --description "Alerta cuando hay mas de 10 errores por minuto en produccion"
```

### Consideraciones de Coste

Container Insights tiene costes asociados que debes planificar:

| Componente | Modelo de coste | Estimación típica |
|------------|----------------|------------------|
| Log Analytics ingestión | Por GB ingerido | ~$2.30/GB |
| Retención extendida (>31 días) | Por GB/mes | ~$0.10/GB/mes |
| Retención básica (31 días) | Incluida | Gratis |
| Alertas | Por regla/mes | ~$0.10/regla |

**Consejos para reducir coste:**

```bash
# Configurar filtros para excluir logs de alta frecuencia (health checks, etc.)
# En el ConfigMap del omsagent:
kubectl get configmap container-azm-ms-agentconfig -n kube-system -o yaml

# Reducir la frecuencia de recolección de métricas (default: 60s)
# Puedes aumentar a 120s o 300s para clusters grandes
```

---

## Logging Estructurado: JSON vs Texto Plano

### Por Qué Importa el Formato de los Logs

La mayoría de aplicaciones generan logs como texto plano: una cadena legible por humanos. Esto funciona bien cuando lees los logs tú mismo en una terminal. Pero cuando tienes un sistema centralizado procesando millones de líneas de log al día, el texto plano se convierte en un problema.

**El problema con texto plano:**

```
# Texto plano — Legible por humanos, difícil de parsear automáticamente
2024-03-15 10:30:01 ERROR Failed to connect to database: timeout after 30s for user_id=12345 from service user-api

# Para buscar todos los errores del usuario 12345 tendrías que hacer regex:
# ContainerLog | where LogEntry matches regex "user_id=12345"
# ... que rompe si alguien cambia el formato del mensaje
```

**La solución: JSON estructurado:**

```json
{
  "timestamp": "2024-03-15T10:30:01Z",
  "level": "ERROR",
  "message": "Failed to connect to database",
  "error": "timeout after 30s",
  "service": "user-api",
  "user_id": "12345",
  "pod": "user-api-7d9f8b-xk2p4",
  "trace_id": "abc123def456"
}
```

Ahora en KQL o Elasticsearch puedes hacer:
```kql
// Buscar todos los errores del usuario 12345 — exacto y rápido
ContainerLog
| where parse_json(LogEntry).user_id == "12345"
| where parse_json(LogEntry).level == "ERROR"
```

### Comparativa: Texto Plano vs JSON Estructurado

| Aspecto | Texto Plano | JSON Estructurado |
|---------|------------|------------------|
| Legibilidad directa | Alta | Media (requiere prettify) |
| Parseable automáticamente | No (requiere regex) | Sí (nativo) |
| Filtrado por campo | Difícil, frágil | Simple y robusto |
| Indexación eficiente | No | Sí |
| Compatibilidad con sistemas | Universal | Universal (JSON es estándar) |
| Overhead de tamaño | Bajo | ~20% mayor |
| Recomendado para producción | No | Sí |

### Niveles de Log y Cuándo Usarlos

Los niveles de log son una convención universal para indicar la severidad de un evento:

| Nivel | Uso | Ejemplo |
|-------|-----|---------|
| `DEBUG` | Información detallada para diagnóstico | `"Entering function processPayment with params: {}"` |
| `INFO` | Eventos normales del ciclo de vida | `"Server started on port 8080"`, `"User logged in"` |
| `WARN` | Situación inesperada pero no crítica | `"Retry attempt 2/3 for database connection"` |
| `ERROR` | Error que afecta a una operación | `"Payment processing failed for order_id=456"` |
| `FATAL` | Error que detiene la aplicación | `"Cannot bind to port 8080 — exiting"` |

**Regla práctica**: En producción, el nivel mínimo debe ser `INFO`. Usa `DEBUG` solo en desarrollo o para diagnóstico temporal (puede generar 10-100x más volumen de logs).

### Qué Incluir (y Qué Evitar) en los Logs

**Siempre incluir:**

```json
{
  "timestamp": "2024-03-15T10:30:01Z",      // ISO 8601, siempre UTC
  "level": "ERROR",                          // Nivel de severidad
  "message": "Database connection failed",   // Mensaje corto y descriptivo
  "service": "user-api",                     // Nombre del servicio
  "trace_id": "abc123",                      // Para correlación con traces
  "error": "connection timeout after 30s",   // Detalle del error si aplica
  "request_id": "req-xyz789"                 // ID único de la request
}
```

**Nunca incluir (datos sensibles):**

```
❌ Contraseñas, tokens, API keys
❌ Números de tarjeta de crédito completos
❌ Datos personales (DNI, dirección completa)
❌ Tokens de sesión
❌ Credenciales de base de datos

✅ Si necesitas identificar a un usuario: usa un ID opaco (user_id="12345")
✅ Para datos de pago: solo los últimos 4 dígitos (**** **** **** 1234)
```

### Configurar JSON Logging en Aplicaciones Comunes

**Node.js con Winston:**

```javascript
// logger.js
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()    // <-- esto produce JSON estructurado
  ),
  transports: [
    new winston.transports.Console()  // stdout → Kubernetes lo captura
  ]
});

// Uso:
logger.error('Database connection failed', {
  error: err.message,
  service: 'user-api',
  user_id: userId
});
// Salida: {"timestamp":"2024-03-15T10:30:01Z","level":"error","message":"Database connection failed","error":"timeout","service":"user-api","user_id":"12345"}
```

**Python con structlog:**

```python
import structlog
import logging

structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer()
    ]
)

logger = structlog.get_logger()

# Uso:
logger.error("database_connection_failed",
             error=str(e),
             service="user-api",
             user_id=user_id)
```

**Java con Logback + logstash-logback-encoder:**

```xml
<!-- logback.xml -->
<appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
  <encoder class="net.logstash.logback.encoder.LogstashEncoder"/>
</appender>
```

### Fluent Bit y el Parseo de Logs JSON

Cuando tus aplicaciones producen JSON, Fluent Bit puede parsear y enriquecer automáticamente:

```yaml
# ConfigMap para Fluent Bit con parser JSON
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
  namespace: kube-system
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush        1
        Daemon       off
        Log_Level    info

    [INPUT]
        Name              tail
        Path              /var/log/containers/*.log
        Parser            docker
        Tag               kube.*
        Refresh_Interval  5
        Mem_Buf_Limit     50MB
        Skip_Long_Lines   On

    [FILTER]
        Name                kubernetes
        Match               kube.*
        Kube_URL            https://kubernetes.default.svc:443
        Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
        Merge_Log           On
        Keep_Log            Off
        K8S-Logging.Parser  On

    [OUTPUT]
        Name  es
        Match *
        Host  elasticsearch.logging.svc.cluster.local
        Port  9200
        Index kubernetes
        Type  _doc

  parsers.conf: |
    [PARSER]
        Name        docker
        Format      json
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%LZ

    [PARSER]
        Name        json-app
        Format      json
        Time_Key    timestamp
        Time_Format %Y-%m-%dT%H:%M:%SZ
```

---

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

## Troubleshooting: Problemas Comunes de Logging

El logging centralizado introduce nuevas capas que pueden fallar. Esta sección cubre los 6 escenarios más frecuentes que encontrarás en producción.

### Escenario 1: Los Logs No Aparecen en el Sistema Central

**Síntoma**: La aplicación genera logs (visibles con `kubectl logs`) pero no aparecen en Elasticsearch/Kibana o Azure Monitor.

**Diagnóstico**:

```bash
# 1. Verificar que el agente de logging está corriendo en TODOS los nodos
kubectl get pods -n kube-system -l k8s-app=fluent-bit -o wide
# Cada nodo debe tener un Pod en estado Running

# Si algún Pod no está Running:
kubectl describe pod fluent-bit-abc12 -n kube-system
# Buscar: Events, State, Last State

# 2. Ver logs del agente para errores
kubectl logs fluent-bit-abc12 -n kube-system --tail=50
# Buscar líneas con [error] o connection refused o timeout

# 3. Verificar que el servicio de Elasticsearch es accesible desde el agente
kubectl exec -n kube-system fluent-bit-abc12 -- \
  curl -s http://elasticsearch.logging.svc.cluster.local:9200/_cat/health

# Salida esperada:
# epoch  timestamp  cluster  status  node.total  ...
# 1710500000  10:30:00  kubernetes  green  3  ...

# Si falla: el problema es de red/DNS, no del agente
```

**Causas comunes y soluciones**:

| Causa | Síntoma en logs | Solución |
|-------|----------------|----------|
| DaemonSet con tolerations incorrectos | Nodos sin Pod de logging | Añadir tolerations para master/control-plane nodes |
| Error de permisos RBAC | `Forbidden` en logs del agente | Revisar ClusterRole y ClusterRoleBinding |
| Elasticsearch caído/saturado | `connection refused` o `429 Too Many Requests` | Reiniciar ES, aumentar recursos |
| NetworkPolicy bloqueando | Timeout sin mensaje de error | Verificar NetworkPolicy en namespace del agente |

---

### Escenario 2: Container Insights No Muestra Datos en Azure Monitor

**Síntoma**: Habilitaste Container Insights pero en Azure Monitor no aparecen datos del cluster.

**Diagnóstico**:

```bash
# 1. Verificar que el omsagent está corriendo
kubectl get pods -n kube-system | grep omsagent
# Debe haber: omsagent-XXXXX (uno por nodo) + omsagent-rs-XXXXX (aggregator)

# Si no hay Pods de omsagent, el addon no está activo:
az aks addon list \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --query "[?name=='monitoring']"

# 2. Ver logs del omsagent para errores
kubectl logs -n kube-system omsagent-abc12 --tail=50

# 3. Verificar conectividad al workspace de Log Analytics
kubectl exec -n kube-system omsagent-abc12 -- \
  curl -I https://<workspace-id>.ods.opinsights.azure.com

# 4. Comprobar que el workspace ID está configurado correctamente
kubectl get configmap -n kube-system container-azm-ms-agentconfig -o yaml

# Solución si el addon está caído: re-habilitarlo
az aks disable-addons \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --addons monitoring

az aks enable-addons \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --addons monitoring \
  --workspace-resource-id $WORKSPACE_ID
```

---

### Escenario 3: Logs con Retraso Excesivo

**Síntoma**: Los logs aparecen en el sistema centralizado con 5-15 minutos de retraso en lugar de segundos.

**Diagnóstico y solución**:

```bash
# Ver la configuración actual del buffer en Fluent Bit
kubectl get configmap fluent-bit-config -n kube-system -o yaml | grep -A 20 "\[OUTPUT\]"

# El problema típico: buffer lleno por volumen alto de logs
# En los logs del agente verás:
# [warn] [output:es:es.0] Buffer queue is full

# Solución 1: Reducir el buffer y aumentar la frecuencia de flush
# En el ConfigMap de Fluent Bit:
# [SERVICE]
#     Flush         1      <- flush cada 1 segundo (default: 5)
#     Mem_Buf_Limit 100MB  <- aumentar si el volumen es alto

# Solución 2: Aumentar recursos del agente
kubectl patch daemonset fluent-bit -n kube-system --type=json -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "512Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "256Mi"}
]'

# Verificar el estado del buffer
kubectl exec -n kube-system fluent-bit-abc12 -- \
  curl -s http://localhost:2020/api/v1/metrics/prometheus | grep buffer
```

---

### Escenario 4: Volumen de Logs Excesivamente Alto

**Síntoma**: El coste de Log Analytics o el almacenamiento de Elasticsearch crece de forma inesperada. Los dashboards son lentos. El agente de logging consume mucha memoria.

**Diagnóstico**:

```bash
# Identificar los contenedores que generan más logs
# En Azure Monitor KQL:
# ContainerLog
# | summarize LogCount = count(), SizeMB = sum(strlen(LogEntry)) / 1024 / 1024
#   by ContainerName, PodName, Namespace
# | order by SizeMB desc
# | take 20

# En Elasticsearch (si usas ELK):
kubectl exec -n logging elasticsearch-0 -- \
  curl -s "http://localhost:9200/_cat/indices?v&s=store.size:desc" | head -10

# Identificar si son health checks (el caso más común):
kubectl logs deployment/web-app --tail=100 | grep -c "GET /health"
# Si este número es alto (ej. 80 de 100 líneas), los health checks saturan los logs
```

**Soluciones**:

```yaml
# Opción 1: Filtrar logs de health checks en Fluent Bit
# Añadir al ConfigMap de Fluent Bit:
data:
  fluent-bit.conf: |
    # ... [INPUT] y [FILTER] de kubernetes ...

    [FILTER]
        Name    grep
        Match   kube.*
        # Excluir líneas de health check
        Exclude log .*GET /health.*
        Exclude log .*GET /readyz.*
        Exclude log .*GET /livez.*

# Opción 2: Filtrar por namespace (no enviar logs de kube-system a storage caro)
    [FILTER]
        Name    grep
        Match   kube.*
        Exclude $kubernetes['namespace_name'] kube-system

# Opción 3: Reducir nivel de log en la aplicación
# En el Deployment, cambiar la variable de entorno:
# env:
# - name: LOG_LEVEL
#   value: "warn"   # en lugar de "debug" o "info"
```

---

### Escenario 5: Logs del Container Runtime Que No Aparecen

**Síntoma**: Algunos contenedores no tienen logs en el sistema centralizado, aunque `kubectl logs` muestra datos. El problema afecta a contenedores específicos, no a todos.

**Diagnóstico**:

```bash
# Verificar el runtime de contenedores en uso
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
# Salida: containerd://1.6.x  (o docker://... en clusters más antiguos)

# El path de logs varía según el runtime:
# - containerd: /var/log/pods/<namespace>_<pod>_<uid>/<container>/0.log
# - Docker: /var/lib/docker/containers/<id>/<id>-json.log

# Si el agente está configurado para Docker pero el runtime es containerd:
kubectl exec -n kube-system fluent-bit-abc12 -- ls /var/log/containers/
# Si hay archivos aquí, el agente debería leerlos
# (Kubernetes crea symlinks en /var/log/containers/ independientemente del runtime)

# Verificar que el volumen hostPath está montado correctamente
kubectl describe pod fluent-bit-abc12 -n kube-system | grep -A 5 "Volumes:"

# La configuración correcta para containerd:
# volumes:
# - name: varlog
#   hostPath:
#     path: /var/log
# - name: varlibdockercontainers  <- este nombre es histórico, sigue siendo necesario
#   hostPath:
#     path: /var/lib/docker/containers  <- puede no existir en containerd puro
```

**Solución para containerd sin Docker:**

```yaml
# Para clusters con containerd sin Docker, montar el path correcto
volumes:
- name: varlog
  hostPath:
    path: /var/log
- name: etcmachineid
  hostPath:
    path: /etc/machine-id
    type: File
# Nota: en containerd los logs están en /var/log/pods/ que es accesible
# desde /var/log/ — no necesitas /var/lib/docker/containers
```

---

### Escenario 6: Logs Multilínea Que Aparecen Fragmentados

**Síntoma**: Los stack traces de Java/Python aparecen como decenas de líneas individuales separadas en Kibana/Azure Monitor, en lugar de un solo evento de log.

**Ejemplo del problema**:

```
# Lo que ves en Kibana (cada línea es un documento separado):
2024-03-15T10:30:01Z  ERROR  Exception in thread "main"
2024-03-15T10:30:01Z  ERROR  java.lang.NullPointerException
2024-03-15T10:30:01Z  ERROR      at com.example.App.processUser(App.java:45)
2024-03-15T10:30:01Z  ERROR      at com.example.App.main(App.java:12)

# Lo que quieres (un solo documento con todo el stack trace)
```

**Causa**: Cada línea del contenedor se registra como un evento separado. Para stack traces multilínea, el agente necesita un parser multilínea.

**Solución con Fluent Bit:**

```yaml
# ConfigMap de Fluent Bit con parser multilínea para Java
data:
  fluent-bit.conf: |
    [INPUT]
        Name              tail
        Path              /var/log/containers/*.log
        Parser            docker
        Tag               kube.*
        Multiline         On
        Multiline_Flush   5
        Parser_Firstline  java_multiline

  parsers.conf: |
    # Parser para detectar el inicio de un log de Java
    # Una línea de inicio tiene el patrón: YYYY-MM-DD HH:MM:SS.mmm LEVEL
    [MULTILINE_PARSER]
        Name          java_multiline
        Type          regex
        Flush_Timeout 2000
        Rule          "start_state"  "/^\d{4}-\d{2}-\d{2}/"  "java_after_start"
        Rule          "java_after_start"  "/^(\s+at |Caused by:)/"  "java_after_start"

    # Parser para Python tracebacks
    [MULTILINE_PARSER]
        Name          python_multiline
        Type          regex
        Flush_Timeout 2000
        Rule          "start_state"  "/^Traceback/"  "python_after_start"
        Rule          "python_after_start"  "/^(\s+File |[A-Za-z]+Error:)/"  "python_after_start"
```

---

## Resumen del Capítulo

### Conceptos Clave

En este capítulo hemos construido una base sólida de observabilidad para Kubernetes, comenzando desde los fundamentos y llegando a sistemas de producción:

**Los tres pilares son complementarios y necesarios**. Los logs te dicen qué ocurrió. Las métricas te dicen cómo está el sistema. Los traces te dicen dónde en el flujo distribuido ocurrió el problema. Ninguno reemplaza a los demás.

**`kubectl logs` es el punto de partida**, pero tiene limitaciones fundamentales: los logs son efímeros, no hay búsqueda cross-Pod, y no escala más allá de un puñado de Pods. Para producción necesitas logging centralizado.

**El patrón DaemonSet** es la arquitectura estándar: un agente ligero (Fluent Bit recomendado) corre en cada nodo, recopila todos los logs del nodo, añade metadatos de Kubernetes, y los envía al almacén central.

**El logging estructurado en JSON** transforma los logs de cadenas de texto difíciles de parsear en documentos estructurados y filtrables. Es la diferencia entre "hay un error en algún lado" y "hay 47 errores de timeout para el user_id=12345 en los últimos 5 minutos".

**Azure Container Insights** ofrece logging y monitoreo integrado en AKS con cero configuración. El lenguaje KQL permite consultas potentes y la creación de alertas automáticas. Tiene costes por GB que deben planificarse.

### Comandos Esenciales

```bash
# Debugging rápido
kubectl logs <pod>                                  # Logs del Pod
kubectl logs <pod> --previous                       # Logs tras un crash
kubectl logs <pod> -c <container>                   # Contenedor específico
kubectl logs <pod> -f --tail=50                     # Seguimiento en tiempo real
kubectl logs deployment/<name> --all-containers     # Todos los Pods del Deployment
kubectl logs -l app=<label> --tail=20               # Por label selector
kubectl logs <pod> --since=1h                       # Logs de la última hora

# Verificar estado del logging centralizado
kubectl get pods -n kube-system | grep fluent       # Estado de Fluent Bit/Fluentd
kubectl get pods -n kube-system | grep omsagent     # Estado de Container Insights
kubectl logs -n kube-system <fluent-bit-pod>        # Logs del agente

# Diagnosticar problemas
kubectl get daemonset -n kube-system fluent-bit     # DaemonSet de logging
kubectl describe pod <fluent-bit-pod> -n kube-system  # Detalle del agente

# Azure Monitor
az aks addon list \
  --resource-group <rg> \
  --name <cluster>                                  # Estado de addons
```

### Arquitectura Recomendada para Producción

```
┌──────────────────────────────────────────────────────────┐
│  STACK DE LOGGING PARA AKS EN PRODUCCION                 │
│                                                          │
│  Nivel básico (Desarrollo/Staging):                      │
│    kubectl logs + Container Insights básico              │
│    Coste: ~$50-100/mes para cluster pequeño              │
│                                                          │
│  Nivel intermedio (Produccion pequeña):                  │
│    Fluent Bit → Azure Log Analytics                      │
│    KQL queries + Alertas de Azure Monitor                │
│    Coste: ~$200-500/mes según volumen de logs            │
│                                                          │
│  Nivel avanzado (Produccion enterprise):                 │
│    Fluent Bit → Elasticsearch (Azure Elastic Cloud)      │
│    Kibana para visualización                             │
│    Alertas + correlación con métricas (Prometheus)       │
│    Coste: variable según volumen                         │
│                                                          │
│  Siguiente paso: Capítulo 35 — Métricas con Prometheus   │
└──────────────────────────────────────────────────────────┘
```

### Relevancia para Certificaciones

| Tema | CKA | CKAD | AKS |
|------|-----|------|-----|
| `kubectl logs` y sus opciones | Examen | Examen | Practica |
| DaemonSet para logging | Conceptual | Conceptual | Practicum |
| Fluentd / Fluent Bit config | Conceptual | No aplica | Practicum |
| Container Insights / Azure Monitor | No aplica | No aplica | Examen |
| KQL queries | No aplica | No aplica | Examen |
| Structured logging / JSON | Buenas practicas | Buenas practicas | Buenas practicas |
| Troubleshooting logging pipeline | Examen | Examen | Examen |

El examen **CKA** puede preguntar cómo verificar logs de componentes del plano de control (`/var/log/pods/kube-system_*/`) y cómo interpretar eventos de Kubernetes con `kubectl get events`. El examen **CKAD** puede incluir configurar una aplicación para generar logs estructurados y verificar su funcionamiento. La certificación **AKS** cubre Azure Monitor, Container Insights y KQL en profundidad.
