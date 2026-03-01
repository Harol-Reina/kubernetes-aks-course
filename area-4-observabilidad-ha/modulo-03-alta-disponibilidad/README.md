# Capítulo 36: Alta Disponibilidad y Autoescalado

Con Prometheus y Grafana en su lugar, podemos ver exactamente qué está pasando en el cluster: uso de CPU, memoria, latencia, saturación de recursos. Tenemos visibilidad total. El siguiente paso natural es pasar de la observación a la acción automática: si Prometheus detecta que el CPU está al 80%, ¿por qué no escalar los Pods automáticamente en lugar de esperar a que alguien lo haga manualmente?

Es Black Friday. Tu tienda online acaba de aparecer en un artículo viral y el tráfico se multiplica por diez en cuestión de minutos. Tienes 2 Pods del servicio de checkout. Cada uno maneja requests hasta su límite; el tiempo de respuesta pasa de 200ms a 8 segundos; los usuarios abandonan el carrito; las transacciones fallan. Si los Pods hubieran escalado automáticamente a 20 réplicas cuando el CPU superó el 70%, la historia sería diferente. Y si esos 20 Pods hubieran consumido más recursos de los que cabían en los nodos existentes, el Cluster Autoscaler podría haber añadido nuevos nodos al grupo de forma automática.

El HPA (Horizontal Pod Autoscaler) escala el número de réplicas de un Deployment basándose en métricas de CPU, memoria o métricas personalizadas expuestas por Prometheus. El VPA (Vertical Pod Autoscaler) ajusta los resource requests y limits de los Pods según el uso real histórico. El Cluster Autoscaler añade o elimina nodos del node pool de AKS cuando los Pods no pueden ser programados por falta de recursos. Los PodDisruptionBudgets garantizan que durante operaciones de mantenimiento siempre quede un número mínimo de réplicas disponibles.

Piensa en un sistema de peaje en una autopista: en hora punta abren más carriles automáticamente (HPA), y si los carriles no son suficientes, construyen cabinas de peaje adicionales (Cluster Autoscaler). Cuando hay menos tráfico, se cierran las cabinas extra para no desperdiciar recursos. Los PDB son los carriles de emergencia que nunca se cierran.

En este capítulo aprenderás a configurar HPA con métricas de CPU, memoria y métricas personalizadas, a entender VPA y sus modos de operación, a habilitar y ajustar el Cluster Autoscaler en AKS, a definir PodDisruptionBudgets para operaciones sin downtime, y a diseñar arquitecturas multi-zona para alta disponibilidad real en Azure.

---

## ¿Qué Pasa con un Pico de Tráfico?

### El Escenario: Black Friday sin Autoescalado

Son las 00:00 del Black Friday. Tu equipo de marketing lanza una campaña que va viral. En los próximos 10 minutos, el tráfico hacia tu servicio de checkout pasa de 500 req/s a 5.000 req/s. Tienes exactamente 2 Pods respondiendo todas esas peticiones.

Lo que ocurre a continuación es predecible y devastador:

```
T+0min  : 500 req/s   → respuesta 200ms   → todo normal
T+2min  : 1.500 req/s → respuesta 800ms   → lento pero funciona
T+5min  : 3.000 req/s → respuesta 8s      → usuarios abandonan
T+8min  : 5.000 req/s → 502 Bad Gateway   → servicio caído
T+10min : alguien nota el problema y empieza a escalar manualmente
T+18min : 10 Pods corriendo → respuesta 250ms → demasiado tarde
```

El coste de esos 18 minutos de degradación en una tienda grande puede superar 500.000€ en ingresos perdidos, sin contar el daño a la reputación y las penalizaciones de SLA con clientes enterprise.

### El Mismo Escenario con Autoescalado

```
T+0min  : 500 req/s   → 2 Pods  → CPU 30%   → respuesta 200ms
T+2min  : 1.500 req/s → HPA detecta CPU > 70% → escala a 6 Pods
T+3min  : 3.000 req/s → HPA escala a 12 Pods  → respuesta 220ms
T+5min  : 5.000 req/s → HPA escala a 20 Pods  → respuesta 230ms
          Cluster Autoscaler añade 2 nodos nuevos para acomodar 20 Pods
T+6min  : sistema estabilizado → respuesta 210ms → 0 errores
```

### Los Tres Niveles de Autoescalado en Kubernetes

Kubernetes ofrece tres mecanismos complementarios que operan en distintas capas:

```
┌─────────────────────────────────────────────────────────────┐
│                 TRÁFICO / CARGA DE TRABAJO                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│          Nivel 1: Pod Autoscaling (responde en ~30s)        │
│                                                             │
│   HPA (Horizontal Pod Autoscaler)                           │
│   └── Más réplicas del mismo Pod                            │
│       Ideal: apps sin estado, web, APIs                     │
│                                                             │
│   VPA (Vertical Pod Autoscaler)                             │
│   └── Más recursos (CPU/RAM) por Pod                        │
│       Ideal: DBs, apps con estado, batch jobs               │
└──────────────────────┬──────────────────────────────────────┘
                       │  Si no caben más Pods en los nodos
                       ▼
┌─────────────────────────────────────────────────────────────┐
│          Nivel 2: Node Autoscaling (responde en ~3-5min)    │
│                                                             │
│   Cluster Autoscaler                                        │
│   └── Añade o elimina nodos en AKS                          │
│       Activado por: Pods en estado Pending                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│          Nivel 3: Protection (activo siempre)               │
│                                                             │
│   PodDisruptionBudget (PDB)                                 │
│   └── Garantiza mínimo de Pods durante disrupciones         │
│       Activo durante: drain, upgrades, mantenimiento        │
└─────────────────────────────────────────────────────────────┘
```

### Cuándo Usar Cada Nivel

| Situación | Mecanismo recomendado | Por qué |
|-----------|----------------------|---------|
| Pico de tráfico web | HPA (CPU/req/s) | App sin estado, más réplicas = más capacidad |
| Base de datos saturada | VPA | No puedes tener 2 primarios; necesitas más RAM |
| Pods en Pending | Cluster Autoscaler | No hay nodos con recursos suficientes |
| Mantenimiento de nodos | PDB | Previene que el drain deje sin servicio |
| App con uso variable | HPA + Cluster Autoscaler | Escala Pods; si no caben, escala nodos |
| Job de machine learning | VPA | Necesita mucha RAM específica, no réplicas |

---

## Horizontal Pod Autoscaler (HPA)

El **HPA** escala automáticamente el número de Pods basándose en métricas como CPU, memoria o métricas personalizadas.

### Prerrequisito: metrics-server

El HPA obtiene métricas de CPU y memoria a través del **metrics-server**. Sin él, el HPA no puede funcionar y mostrará `<unknown>` en todas las métricas.

```bash
# Verificar si metrics-server está instalado
kubectl get deployment metrics-server -n kube-system

# Verificar que responde correctamente
kubectl top nodes
kubectl top pods -n desarrollo

# En Minikube, habilitarlo como addon
minikube addons enable metrics-server

# En AKS, viene preinstalado en clusters recientes
# Verificar versión
kubectl get deployment metrics-server -n kube-system -o jsonpath='{.spec.template.spec.containers[0].image}'
```

Salida esperada de `kubectl top nodes`:
```
NAME           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
aks-nodepool   245m         12%    1842Mi          58%
```

Si `kubectl top nodes` devuelve `error: metrics not available yet`, espera 60 segundos y vuelve a intentarlo. El metrics-server tarda un poco en recopilar datos iniciales.

### Cómo Funciona el HPA Internamente

El HPA ejecuta un loop de control cada 15 segundos (configurable). En cada iteración:

```
Loop del HPA Controller (cada 15 segundos):

1. LEER métricas actuales
   └── Consulta metrics-server (Resource metrics: CPU, RAM)
   └── O custom-metrics-apiserver (Custom metrics: req/s, latencia)

2. CALCULAR réplicas deseadas
   └── Formula:
       replicasDeseadas = ceil(replicasActuales × (valorActual / valorObjetivo))

   Ejemplo con CPU:
   - 3 réplicas actuales
   - CPU promedio actual: 90%
   - CPU objetivo: 50%
   - replicasDeseadas = ceil(3 × (90 / 50)) = ceil(5.4) = 6

3. VALIDAR contra min/max
   └── Si calculado < minReplicas → usar minReplicas
   └── Si calculado > maxReplicas → usar maxReplicas

4. APLICAR stabilizationWindow
   └── Evitar thrashing: no escalar si hubo escala reciente
   └── scaleDown: ventana de 300s (default)
   └── scaleUp: ventana de 0s (respuesta inmediata por defecto)

5. EJECUTAR escala si necesario
   └── kubectl scale deployment/app --replicas=N
```

### Tipos de Métricas

El HPA soporta tres familias de métricas:

**1. Resource metrics (integradas, sin configuración adicional)**

Usan CPU y memoria directamente del metrics-server. Son las más simples y las primeras que debes configurar.

```yaml
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization       # Porcentaje sobre el request
      averageUtilization: 70  # Escala cuando CPU promedio > 70%
- type: Resource
  resource:
    name: memory
    target:
      type: AverageValue      # Valor absoluto promedio
      averageValue: 200Mi     # Escala cuando RAM promedio > 200Mi
```

**2. Custom metrics (requieren metrics adapter)**

Métricas específicas de la aplicación expuestas vía Prometheus + prometheus-adapter, o Azure Monitor.

```yaml
metrics:
- type: Pods
  pods:
    metric:
      name: http_requests_per_second  # Métrica expuesta por tu app
    target:
      type: AverageValue
      averageValue: "100"  # 100 req/s por Pod
```

**3. External metrics (requieren metrics adapter)**

Métricas externas al cluster: longitud de cola SQS, mensajes en Service Bus, etc.

```yaml
metrics:
- type: External
  external:
    metric:
      name: azure_servicebus_active_messages
      selector:
        matchLabels:
          queue: orders
    target:
      type: AverageValue
      averageValue: "50"  # Escala cuando hay > 50 mensajes por réplica
```

### Scaling Behavior en Detalle

El campo `behavior` controla cómo y cuándo el HPA aplica cambios de escala. Es crítico configurarlo correctamente para evitar dos problemas: escala demasiado lenta (usuarios sufren) o thrashing (el cluster escala arriba/abajo constantemente).

**scaleUp**: debe ser agresivo para responder rápido a picos.
**scaleDown**: debe ser conservador para evitar remover réplicas prematuramente.

```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0      # Escala arriba inmediatamente (sin espera)
    policies:
    - type: Percent                    # Política 1: duplicar réplicas cada 15s
      value: 100                       # +100% de las réplicas actuales
      periodSeconds: 15
    - type: Pods                       # Política 2: añadir max 4 Pods cada 15s
      value: 4
      periodSeconds: 15
    selectPolicy: Max                  # Usar la política que resulte en MÁS Pods
                                       # (Max = más agresivo, Min = más conservador)
  scaleDown:
    stabilizationWindowSeconds: 300    # Esperar 5 minutos antes de escalar abajo
    policies:
    - type: Percent                    # Remover máximo 10% de réplicas cada 60s
      value: 10
      periodSeconds: 60
    selectPolicy: Max                  # Usar la política que resulte en MENOS Pods removidos
```

La opción `selectPolicy: Disabled` deshabilita completamente la escala en esa dirección (útil para apps que nunca deben escalar abajo automáticamente).

### HPA Completo para Producción

```yaml
# Uso: kubectl apply -f hpa-produccion.yaml
#
# HPA de producción con CPU + memoria + comportamiento de escala refinado.
# Requiere: metrics-server instalado, resource requests definidos en el Deployment.
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
  namespace: produccion
  annotations:
    # Documentar el propósito y umbrales para el equipo
    scaling.purpose: "Autoescalado del frontend web ante picos de tráfico"
    scaling.alert: "Revisar si maxReplicas = 20 se alcanza frecuentemente"
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp                       # Nombre exacto del Deployment a escalar
  minReplicas: 3                       # Nunca bajar de 3 (HA mínimo en 3 AZs)
  maxReplicas: 20                      # Límite hard para controlar costes
  metrics:
  # Métrica primaria: CPU
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70         # Objetivo: CPU < 70% en promedio
  # Métrica secundaria: memoria
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80         # Objetivo: RAM < 80% en promedio
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0   # Sin espera para escalar arriba
      policies:
      - type: Percent                  # Permite doblar réplicas cada 15s
        value: 100
        periodSeconds: 15
      - type: Pods                     # O añadir 4 Pods cada 15s
        value: 4
        periodSeconds: 15
      selectPolicy: Max                # La más agresiva de las dos políticas
    scaleDown:
      stabilizationWindowSeconds: 300  # 5 min de gracia antes de escalar abajo
      policies:
      - type: Percent                  # Bajar máximo 10% de réplicas por minuto
        value: 10
        periodSeconds: 60
      selectPolicy: Max                # La que resulte en menos Pods eliminados
```

### Interpretar la Salida de kubectl get hpa

```bash
kubectl get hpa -n produccion
```

```
NAME         REFERENCE           TARGETS          MINPODS   MAXPODS   REPLICAS   AGE
webapp-hpa   Deployment/webapp   45%/70%, 0/80%   3         20        5          2d
```

Interpretación campo por campo:

```
TARGETS: 45%/70%, 0/80%
         │    │   │  └── Objetivo para memoria (80%)
         │    │   └────── CPU memoria actual (0% = no usa nada)
         │    └────────── Objetivo para CPU (70%)
         └─────────────── CPU actual (45% = por debajo del umbral, no escala)

REPLICAS: 5  → Actualmente 5 Pods corriendo
MINPODS:  3  → Nunca bajará de 3
MAXPODS:  20 → Nunca subirá de 20
```

Si ves `<unknown>` en TARGETS, hay un problema (ver sección Troubleshooting).

### Errores Comunes con HPA

**Error 1: No hay resource requests definidos**

El HPA calcula porcentaje de CPU relativo al `requests.cpu`. Si no hay requests, el porcentaje no se puede calcular.

```yaml
# MAL: sin resource requests → HPA muestra <unknown>
containers:
- name: app
  image: nginx:1.21
  # Sin resources: → HPA no puede calcular porcentaje

# BIEN: con resource requests → HPA funciona correctamente
containers:
- name: app
  image: nginx:1.21
  resources:
    requests:
      cpu: 100m       # HPA usa esto como base del cálculo
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 256Mi
```

**Error 2: metrics-server no instalado o no responde**

```bash
# Síntoma
kubectl get hpa
# NAME   TARGETS         REPLICAS
# app    <unknown>/70%   2

# Diagnóstico
kubectl get pods -n kube-system | grep metrics-server
# Si no aparece → no está instalado

kubectl logs -n kube-system deployment/metrics-server
# Si hay errores → revisar configuración
```

---

## VPA: Cuándo Ajustar Recursos en Vez de Réplicas

### HPA vs VPA: Elegir el Mecanismo Correcto

Antes de configurar cualquier autoscaler, la pregunta clave es: ¿necesito **más instancias** de mi Pod, o necesito que **cada instancia tenga más recursos**?

| Escenario | HPA | VPA | Razonamiento |
|-----------|-----|-----|--------------|
| Servicio web sin estado | Sí | No | Más réplicas = más capacidad de forma lineal |
| Base de datos (PostgreSQL, MySQL) | No | Sí | No puedes tener 2 primarios; necesitas más RAM/CPU por Pod |
| Cache (Redis single-node) | No | Sí | Más RAM = más datos en caché; más réplicas complica la consistencia |
| Batch jobs de ML | Depende | Sí | Un job necesita toda la RAM que pueda obtener |
| Aplicación memory-bound | No | Sí | El cuello de botella es RAM, no el número de instancias |
| API sin estado con carga variable | Sí | No | HPA responde bien a cambios de tráfico |
| Worker de colas | Sí | Depende | Más workers = más throughput; VPA puede ajustar si los jobs varían |

La combinación HPA + VPA es posible, pero solo si usan métricas distintas: HPA en CPU/req/s, VPA en memoria. Si ambos intentan ajustar CPU simultáneamente, entran en conflicto.

### Modos de Operación del VPA

El VPA tiene cuatro modos, con distintos niveles de agresividad:

**Off** (Recomendado para empezar)
```
VPA solo observa y genera recomendaciones.
No modifica ningún Pod. Seguro para usar en producción
sin riesgo de interrupciones.

Uso: evaluar qué recursos necesita tu app antes de
     habilitar autoajuste automático.
```

**Initial**
```
VPA aplica sus recomendaciones solo cuando se crea
un Pod nuevo (por restart, rolling update, etc.).
No interrumpe Pods existentes.

Uso: ajuste gradual sin interrupciones activas.
```

**Recreate**
```
VPA puede eliminar y recrear Pods cuando sus
recomendaciones difieren significativamente de los
recursos actuales.

Uso: workloads que toleran reinicios ocasionales
     (batch jobs, workers en segundo plano).
```

**Auto**
```
Similar a Recreate. En un futuro, cuando Kubernetes
soporte in-place resource updates, podrá actualizar
sin necesidad de recrear el Pod.

PRECAUCIÓN: Causa reinicios en producción.
Usar solo con PDB configurado y durante ventanas
de mantenimiento conocidas.
```

### Componentes Internos del VPA

```
┌─────────────────────────────────────────────────────────────┐
│                    VPA Architecture                         │
│                                                             │
│  ┌──────────────────┐                                       │
│  │   VPA Recommender │  ← Lee métricas históricas de        │
│  │                   │    metrics-server / Prometheus        │
│  │  Calcula:         │    Genera recomendaciones de          │
│  │  - lowerBound     │    requests/limits óptimos           │
│  │  - target         │                                       │
│  │  - upperBound     │                                       │
│  └────────┬──────────┘                                       │
│           │ recomendaciones                                  │
│           ▼                                                  │
│  ┌──────────────────┐                                        │
│  │   VPA Updater    │  ← En modo Auto/Recreate:              │
│  │                  │    Elimina Pods con recursos           │
│  │  Evalúa si los   │    muy alejados del target            │
│  │  Pods actuales   │                                        │
│  │  deben recrearse │                                        │
│  └────────┬─────────┘                                        │
│           │ Pod eliminado                                    │
│           ▼                                                  │
│  ┌──────────────────┐                                        │
│  │  VPA Admission   │  ← Intercepta la creación del         │
│  │  Controller      │    nuevo Pod y modifica los           │
│  │                  │    resource requests según             │
│  │  Mutating webhook│    las recomendaciones del VPA        │
│  └──────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

### VPA Completo con Anotaciones

```yaml
# Uso: kubectl apply -f vpa-database.yaml
#
# VPA para una base de datos PostgreSQL.
# Modo "Off" para empezar: solo recomendaciones, sin reinicios.
# Cambiar a "Auto" solo tras revisar recomendaciones y configurar PDB.
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: postgres-vpa
  namespace: produccion
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment           # También funciona con StatefulSet
    name: postgres
  updatePolicy:
    updateMode: "Off"          # Opciones: Off | Initial | Recreate | Auto
                               # Empezar con "Off" para ver recomendaciones
  resourcePolicy:
    containerPolicies:
    - containerName: postgres  # Nombre exacto del container
      controlledResources:
      - cpu
      - memory
      minAllowed:              # VPA nunca recomendará menos que esto
        cpu: 250m
        memory: 256Mi
      maxAllowed:              # VPA nunca recomendará más que esto
        cpu: 4                 # 4 cores máximo
        memory: 8Gi            # 8GB RAM máximo
      controlledValues: RequestsAndLimits  # Ajustar requests y limits juntos
```

Consultar las recomendaciones del VPA sin aplicarlas:

```bash
kubectl describe vpa postgres-vpa -n produccion
```

Salida esperada:
```
Name:         postgres-vpa
Namespace:    produccion
...
Status:
  Recommendation:
    Container Recommendations:
      Container Name:  postgres
      Lower Bound:
        Cpu:     250m
        Memory:  512Mi
      Target:          ← Recomendación ideal según el VPA
        Cpu:     800m
        Memory:  2Gi
      Uncapped Target:
        Cpu:     800m
        Memory:  2Gi
      Upper Bound:
        Cpu:     2
        Memory:  4Gi
```

Usa `Target` como referencia para actualizar manualmente tus resource requests antes de habilitar el modo `Auto`.

### Usar VPA y HPA Juntos

La combinación es válida solo cuando cada uno controla una dimensión diferente:

```
VPA controla: memory (ajusta RAM según uso histórico)
HPA controla: CPU    (escala réplicas según CPU)

NO usar ambos controlando CPU al mismo tiempo:
- VPA intenta ajustar el request de CPU del Pod
- HPA calcula % de CPU sobre ese request
- El denominador cambia constantemente → cálculos incorrectos
```

Configuración válida HPA + VPA:

```yaml
# HPA: escala por CPU
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 70

# VPA: solo ajusta memoria
resourcePolicy:
  containerPolicies:
  - containerName: app
    controlledResources: ["memory"]  # Solo memoria, CPU no tocado
```

---

## Cluster Autoscaler en AKS

El **Cluster Autoscaler** ajusta automáticamente el número de nodos en el cluster.

### Cómo Decide el Cluster Autoscaler Escalar UP

El Cluster Autoscaler monitoriza constantemente el estado de los Pods. Cuando detecta Pods en estado `Pending` (no programados), analiza si se pueden resolver añadiendo nodos:

```
1. Pod A entra en estado Pending
   └── Razón: "Insufficient CPU" o "Insufficient memory"

2. Cluster Autoscaler evalúa:
   └── ¿Existe algún node type en el node pool que pudiera
       acomodar este Pod?
   └── ¿Se respetaría el maxCount configurado?
   └── ¿No hay taints/tolerations que impidan el scheduling?

3. Si todas las condiciones se cumplen:
   └── Solicita a AKS añadir un nodo al node pool
   └── El nodo tarda ~3-5 minutos en estar listo (Azure VM provision)
   └── El Pod se schedula en el nodo nuevo
```

Importante: el Cluster Autoscaler NO escala si el Pod está Pending por otras razones (imagen no disponible, PersistentVolumeClaim no bound, taints que no puede resolver con nuevos nodos).

### Cómo Decide el Cluster Autoscaler Escalar DOWN

El scale-down es más conservador y tiene múltiples comprobaciones de seguridad:

```
Condiciones para eliminar un nodo (TODAS deben cumplirse):

1. Utilización < 50% durante scale-down-unneeded-time (default: 10min)
   Utilización = max(CPU solicitada / CPU total, RAM solicitada / RAM total)

2. Todos los Pods en ese nodo pueden moverse a otros nodos existentes
   └── Hay capacidad suficiente en otros nodos
   └── No hay Pods con local storage (emptyDir con datos)
   └── No hay Pods con afinidad al nodo específico

3. Ningún PDB bloquea el drain del nodo
   └── PDB comprueba que mover los Pods no viola minAvailable/maxUnavailable

4. No es un nodo del control plane (solo worker nodes)
```

```bash
# Ver logs del Cluster Autoscaler para entender sus decisiones
kubectl logs -n kube-system deployment/cluster-autoscaler | grep -i "scale"

# Anotar un Pod para que el CA nunca mueva su nodo
# (útil para workloads con estado local crítico)
kubectl annotate pod mi-pod \
  cluster-autoscaler.kubernetes.io/safe-to-evict="false"
```

### Configurar Cluster Autoscaler en AKS

```bash
# Habilitar Cluster Autoscaler en el node pool principal
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5

# Ajustar el profile del autoscaler (parámetros separados por coma)
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --cluster-autoscaler-profile \
    scale-down-delay-after-add=10m \
    scale-down-unneeded-time=10m \
    scale-down-utilization-threshold=0.5 \
    max-graceful-termination-sec=600 \
    scan-interval=10s \
    skip-nodes-with-local-storage=true
```

### Parámetros del Profile Explicados

| Parámetro | Default | Descripción |
|-----------|---------|-------------|
| `scan-interval` | 10s | Cada cuánto evalúa el estado de los nodos |
| `scale-down-delay-after-add` | 10m | Esperar N min tras añadir nodo antes de evaluar scale-down |
| `scale-down-unneeded-time` | 10m | Nodo debe estar subutilizado N min antes de eliminarlo |
| `scale-down-utilization-threshold` | 0.5 | Umbral de utilización para considerar nodo "innecesario" |
| `max-graceful-termination-sec` | 600 | Tiempo máximo de espera para que los Pods terminen |
| `skip-nodes-with-local-storage` | true | No eliminar nodos con Pods que tienen emptyDir |
| `expander` | random | Estrategia para elegir node pool al escalar (ver abajo) |

### Multiple Node Pools con Autoscaler Diferenciado

En producción es común tener node pools especializados: uno para workloads generales, otro para cargas de ML con GPUs, otro de Spot para batch jobs:

```bash
# Pool general: siempre entre 2 y 10 nodos
az aks nodepool update \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name system \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 10

# Pool de ML (GPUs): puede llegar a 0 cuando no hay jobs
az aks nodepool add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name gpupool \
  --node-vm-size Standard_NC6s_v3 \
  --enable-cluster-autoscaler \
  --min-count 0 \
  --max-count 4 \
  --node-taints sku=gpu:NoSchedule  # Solo Pods con toleration irán aquí

# Pool de Spot: hasta 20 nodos a ~80% de descuento
az aks nodepool add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name spotpool \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \            # Precio de mercado
  --enable-cluster-autoscaler \
  --min-count 0 \
  --max-count 20
```

Los nodos Spot pueden ser reclamados por Azure con 30 segundos de aviso. Son ideales para batch jobs tolerantes a interrupciones, no para servicios web críticos.

### Priority Expander: Qué Pool Escalar Primero

Cuando hay múltiples node pools, el Cluster Autoscaler usa el **expander** para decidir cuál escalar:

```bash
az aks update \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --cluster-autoscaler-profile expander=priority
```

Con `expander=priority`, crear un ConfigMap de prioridades:

```yaml
# El CA leerá este ConfigMap para decidir el orden de expansión
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-autoscaler-priority-expander
  namespace: kube-system
data:
  priorities: |-
    10:                             # Prioridad baja: Spot (barato pero inestable)
      - .*spotpool.*
    50:                             # Prioridad media: GPU (caro, solo si necesita GPU)
      - .*gpupool.*
    100:                            # Prioridad alta: pool general (primero siempre)
      - .*system.*
```

---

## Pod Disruption Budgets (PDB)

Los **PDB** definen el número mínimo de Pods que deben estar disponibles durante disrupciones voluntarias.

### Disrupciones Voluntarias vs Involuntarias

```
Disrupciones INVOLUNTARIAS (PDB NO puede prevenir):
├── Fallo de hardware del nodo
├── Kernel panic
├── Problema en la red de Azure
└── OOMKill por exceso de memoria

Disrupciones VOLUNTARIAS (PDB SÍ protege contra ellas):
├── kubectl drain node-1         ← El más común
├── Upgrades de versión de AKS
├── Rebalanceo del Cluster Autoscaler
├── kubectl delete pod (si el pod no tiene restart policy)
└── Evictions de nodos por mantenimiento programado de Azure
```

El PDB solo protege contra disrupciones voluntarias. Para protegerse contra involuntarias, necesitas múltiples réplicas distribuidas en múltiples zonas.

### minAvailable vs maxUnavailable

Puedes usar uno u otro, nunca ambos en el mismo PDB. Elige según qué es más fácil de razonar para tu app:

```yaml
# Opción A: minAvailable — "siempre deben estar disponibles al menos N Pods"
spec:
  minAvailable: 3             # Valor absoluto: 3 Pods mínimo
  # O en porcentaje:
  minAvailable: "75%"         # 75% de las réplicas deseadas, redondeado abajo

# Opción B: maxUnavailable — "como mucho N Pods pueden estar caídos"
spec:
  maxUnavailable: 1           # Valor absoluto: máximo 1 Pod caído a la vez
  # O en porcentaje:
  maxUnavailable: "25%"       # 25% de las réplicas pueden estar no disponibles
```

### Ejemplo Paso a Paso: PDB Bloqueando un Drain

Tienes 5 réplicas de tu webapp distribuidas en 3 nodos. El PDB dice `minAvailable: 3`. El equipo de infraestructura quiere hacer `kubectl drain` de dos nodos para mantenimiento:

```
Estado inicial:
  nodo-1: pod-a, pod-b   (2 pods)
  nodo-2: pod-c          (1 pod)
  nodo-3: pod-d, pod-e   (2 pods)
  Total disponibles: 5

Intento 1: kubectl drain nodo-1
  Pods a mover: pod-a, pod-b
  PDB check: 5 - 2 = 3 ≥ minAvailable(3) → OK, drain permitido
  Resultado: pod-a y pod-b se recrean en nodo-2 y nodo-3
  Estado: nodo-1 vacío, total disponibles: 5

Intento 2: kubectl drain nodo-2
  Pods a mover: pod-c, pod-a(recién movido), pod-b(recién movido)
  PDB check: 5 - 3 = 2 < minAvailable(3) → BLOQUEADO

  Kubernetes esperará a que los Pods de nodo-1 estén Ready
  en sus nuevos nodos, y volverá a intentar el drain
  gradualmente (de uno en uno).
```

El mensaje que verás cuando el PDB bloquea:

```
error when evicting pods/"pod-c" (will retry after 5s):
Cannot evict pod as it would violate the pod's disruption budget.
```

Esto no es un error a corregir, es el PDB funcionando correctamente.

### PDB para Producción

```yaml
# Uso: kubectl apply -f pdb-produccion.yaml
#
# PDB para un servicio web con mínimo 3 réplicas (multi-AZ).
# Garantiza disponibilidad durante upgrades de AKS y mantenimiento.
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: webapp-pdb
  namespace: produccion
spec:
  minAvailable: 3            # Siempre 3 Pods como mínimo (uno por AZ)
  selector:
    matchLabels:
      app: webapp
      tier: frontend
---
# PDB para workers de colas: más tolerante a disrupciones
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: worker-pdb
  namespace: produccion
spec:
  maxUnavailable: 2          # Toleramos hasta 2 workers caídos
  selector:
    matchLabels:
      app: order-worker
```

Verificar el estado de los PDB:

```bash
kubectl get pdb -n produccion
```

```
NAME         MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
webapp-pdb   3               N/A               2                     5d
worker-pdb   N/A             2                 2                     5d
```

`ALLOWED DISRUPTIONS: 2` significa que actualmente se podrían evictar hasta 2 Pods sin violar el PDB. Si ese número llega a 0, ningún drain adicional será permitido.

### Mejores Prácticas con PDB

```
Siempre crear PDB para:
├── Servicios críticos en producción con > 1 réplica
├── Bases de datos con múltiples réplicas (lectura)
├── Workers de colas críticas
└── Cualquier Deployment con SLA de disponibilidad

Valores recomendados:
├── Para N réplicas en N zonas: minAvailable = N-1
│   (permite bajar una zona a la vez)
├── Para servicios muy críticos: minAvailable = "75%"
└── Para workers tolerantes: maxUnavailable = "50%"

Evitar:
├── minAvailable = número total de réplicas
│   (bloquea CUALQUIER drain, incluso emergencias)
└── PDB en workloads de una sola réplica
    (crea un nodo que nunca puede drenarse)
```

---

## Estrategias de Alta Disponibilidad

### Multi-AZ: Distribuir Pods Automáticamente

En AKS con múltiples zonas de disponibilidad, por defecto el scheduler puede colocar todos los Pods en la misma zona. Para distribuirlos equitativamente, usa `topologySpreadConstraints`:

```yaml
# Uso: kubectl apply -f deployment-multi-az.yaml
#
# Deployment con distribución automática entre zonas de disponibilidad.
# Requiere: cluster AKS creado con --zones 1 2 3
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: produccion
spec:
  replicas: 6                          # 2 por zona (con 3 zonas)
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      topologySpreadConstraints:
      # Restricción 1: distribución entre zonas de disponibilidad
      - maxSkew: 1                     # Máximo 1 Pod de diferencia entre zonas
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule  # No programar si no se puede distribuir
        labelSelector:
          matchLabels:
            app: webapp
      # Restricción 2: distribución entre nodos (evitar 2 Pods en el mismo nodo)
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: ScheduleAnyway  # Intentar distribuir, pero no obligatorio
        labelSelector:
          matchLabels:
            app: webapp
      containers:
      - name: webapp
        image: myregistry.azurecr.io/webapp:v1.5
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 1
            memory: 512Mi
```

`maxSkew: 1` con `DoNotSchedule` significa: "la diferencia de Pods entre la zona con más y la zona con menos no puede superar 1". Con 6 réplicas y 3 zonas, el scheduler buscará 2-2-2. Si no puede conseguirlo, el Pod queda Pending.

### Pod Anti-Affinity: Evitar Colocación en el Mismo Nodo

Cuando el número de réplicas es pequeño (2-3), `topologySpreadConstraints` puede no ser suficiente. La anti-affinity da más control:

```yaml
spec:
  template:
    spec:
      affinity:
        podAntiAffinity:
          # "Preferido": intentar evitar, pero no obligatorio
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname  # No en el mismo nodo
              labelSelector:
                matchLabels:
                  app: webapp
          # "Requerido": NUNCA dos instancias en el mismo nodo
          requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: topology.kubernetes.io/zone  # Nunca en la misma zona
            labelSelector:
              matchLabels:
                app: webapp
```

Usa `required` para workloads donde la co-ubicación es inaceptable (dos réplicas del mismo DB). Usa `preferred` para servicios web donde se intenta distribuir pero no es crítico.

### Crear Cluster AKS Multi-Zona

```bash
# Crear cluster AKS con nodos en las 3 zonas de disponibilidad de Azure
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-ha-cluster \
  --node-count 3 \
  --zones 1 2 3 \                    # Un nodo en cada zona
  --enable-cluster-autoscaler \
  --min-count 3 \
  --max-count 12 \
  --node-vm-size Standard_D4s_v3 \
  --network-plugin azure \
  --generate-ssh-keys

# Verificar distribución de nodos por zona
kubectl get nodes \
  -o custom-columns='NODE:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone'
```

Salida esperada:
```
NODE                                ZONE
aks-nodepool1-12345678-vmss000000   eastus-1
aks-nodepool1-12345678-vmss000001   eastus-2
aks-nodepool1-12345678-vmss000002   eastus-3
```

### Health Checks y Graceful Shutdown

Para que el autoescalado y el mantenimiento funcionen correctamente, los Pods deben comportarse bien cuando se les pide terminar:

```yaml
spec:
  containers:
  - name: webapp
    image: myapp:v1.5

    # Readiness probe: el Pod solo recibe tráfico cuando está listo
    readinessProbe:
      httpGet:
        path: /health/ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
      failureThreshold: 3

    # Liveness probe: reiniciar si la app se cuelga
    livenessProbe:
      httpGet:
        path: /health/live
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      failureThreshold: 3

    lifecycle:
      # preStop hook: dar tiempo para que las conexiones existentes terminen
      # antes de que el container reciba SIGTERM
      preStop:
        exec:
          command: ["/bin/sh", "-c", "sleep 15"]

  # Tiempo máximo para que el Pod termine limpiamente
  # Debe ser > preStop sleep + tiempo para completar requests en vuelo
  terminationGracePeriodSeconds: 60
```

El flujo de terminación con estos ajustes:

```
kubectl drain node / Pod eviction:

1. Kubernetes envía señal de terminación al Pod
2. preStop hook ejecuta: sleep 15s
   (el load balancer tiene tiempo de dejar de enviar tráfico al Pod)
3. Container recibe SIGTERM
   (la app debe completar los requests en vuelo y cerrar limpiamente)
4. Si no termina en terminationGracePeriodSeconds (60s):
   → Kubernetes envía SIGKILL (terminación forzosa)
```

---

## Laboratorio 4.4: Configurar Autoescalado

### Paso 1: Aplicación con Resource Requests

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

### Paso 2: Configurar HPA

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

### Paso 3: Generar Carga y Probar Autoscaling

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

### Paso 4: Configurar PDB

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

## Troubleshooting Autoescalado

Los problemas de autoescalado tienen síntomas claros pero causas que a veces no son obvias. Esta sección cubre los seis escenarios más frecuentes.

### Escenario 1: HPA Stuck — No Escala aunque el CPU Está Alto

**Síntoma:**
```bash
kubectl get hpa -n produccion
# NAME   TARGETS         REPLICAS
# app    <unknown>/70%   2
```

El campo `<unknown>` indica que el HPA no puede leer métricas.

**Diagnóstico:**
```bash
# Verificar si metrics-server está corriendo
kubectl get pods -n kube-system | grep metrics-server

# Si no está, instalar (en Minikube)
minikube addons enable metrics-server

# Verificar que responde
kubectl top pods -n produccion
# Si también devuelve error → metrics-server no funciona

# Ver eventos del HPA
kubectl describe hpa app -n produccion | grep -A 5 "Events:"
```

**Causa:** metrics-server no instalado, o en estado CrashLoopBackOff.

**Solución:**
```bash
# Reinstalar metrics-server con Helm
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set args[0]="--kubelet-insecure-tls"  # En entornos de desarrollo
```

### Escenario 2: HPA Muestra CPU pero No Escala

**Síntoma:**
```bash
kubectl get hpa -n produccion
# NAME   TARGETS   REPLICAS
# app    0%/70%    2          ← CPU 0% aunque hay tráfico real
```

**Diagnóstico:**
```bash
# Verificar si el Deployment tiene resource requests
kubectl get deployment app -n produccion -o jsonpath=\
  '{.spec.template.spec.containers[0].resources}'
# Si devuelve {} → no hay requests definidos
```

**Causa:** Sin `resources.requests.cpu`, el metrics-server no puede calcular porcentaje. Devuelve 0% o `<unknown>`.

**Solución:**
```bash
# Añadir resource requests al Deployment
kubectl patch deployment app -n produccion --patch '
spec:
  template:
    spec:
      containers:
      - name: app
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi'
```

### Escenario 3: Cluster Autoscaler No Añade Nodos

**Síntoma:**
```bash
kubectl get pods -n produccion
# NAME       READY   STATUS    REASON
# webapp-7   0/1     Pending   Insufficient cpu
```

El Pod lleva Pending varios minutos aunque el Cluster Autoscaler debería añadir nodos.

**Diagnóstico:**
```bash
# Ver logs del Cluster Autoscaler
kubectl logs -n kube-system deployment/cluster-autoscaler | tail -50

# Comprobar si se alcanzó el maxCount
az aks nodepool show \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name nodepool1 \
  --query 'count'

# Ver cuota de Azure
az vm list-usage --location eastus --query \
  "[?contains(name.value,'cores')]" -o table
```

**Causas posibles:**
- `maxCount` alcanzado: el CA no puede añadir más nodos aunque haya Pods Pending
- Cuota de VM en Azure agotada: la suscripción tiene límite de cores
- El Pod tiene taints/tolerations que ningún node pool puede satisfacer
- El Pod tiene resource requests mayores que el node type disponible

**Solución según causa:**
```bash
# Causa 1: Aumentar maxCount
az aks nodepool update \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name nodepool1 \
  --max-count 20

# Causa 2: Solicitar aumento de cuota en Azure Portal
# Portal → Subscriptions → Usage + quotas → Request increase

# Causa 3: Verificar node selector y tolerations del Pod
kubectl describe pod webapp-7 -n produccion | grep -A 10 "Node-Selectors:"
```

### Escenario 4: Cluster Autoscaler No Elimina Nodos Infrautilizados

**Síntoma:** Nodos al 10-20% de utilización llevan horas sin eliminarse, generando costes innecesarios.

**Diagnóstico:**
```bash
# Ver por qué el CA no puede drenar un nodo específico
kubectl logs -n kube-system deployment/cluster-autoscaler | grep "scale_down"

# Verificar si hay PDB bloqueando el drain
kubectl get pdb -A
kubectl describe pdb webapp-pdb -n produccion
# Buscar: "Allowed disruptions: 0"

# Ver Pods con anotación safe-to-evict=false
kubectl get pods -A -o json | jq '.items[] |
  select(.metadata.annotations."cluster-autoscaler.kubernetes.io/safe-to-evict" == "false") |
  .metadata.name'
```

**Causas posibles:**
- PDB con `ALLOWED DISRUPTIONS: 0` (todos los Pods del PDB están en ese nodo)
- Pod con anotación `safe-to-evict: "false"` explícita
- Pod con `local-storage` (emptyDir con datos)
- El nodo tiene el label `cluster-autoscaler.kubernetes.io/scale-down-disabled: "true"`

**Solución:**
```bash
# Si el PDB está siendo demasiado restrictivo, revisar si minAvailable es realista
kubectl edit pdb webapp-pdb -n produccion

# Si un Pod tiene safe-to-evict=false innecesariamente
kubectl annotate pod mi-pod \
  cluster-autoscaler.kubernetes.io/safe-to-evict="true" --overwrite
```

### Escenario 5: VPA Reinicia Pods Constantemente

**Síntoma:** Los Pods se reinician cada pocos minutos. Al revisar los eventos:

```bash
kubectl describe pod app-xyz -n produccion
# Events:
#   Type     Reason   Message
#   Warning  Evicted  The VPA updater is evicting the pod for resource update.
```

**Diagnóstico:**
```bash
# Ver qué recomienda el VPA
kubectl describe vpa app-vpa -n produccion | grep -A 15 "Recommendation:"

# Comparar con los recursos actuales del Pod
kubectl get pod app-xyz -n produccion -o jsonpath=\
  '{.spec.containers[0].resources}'
```

**Causa:** El VPA en modo `Auto` o `Recreate` con rangos `minAllowed`/`maxAllowed` muy estrechos, o con un `Target` que sigue cambiando porque la carga del Pod es muy variable.

**Solución:**
```bash
# Cambiar VPA a modo Off temporalmente para que deje de reiniciar
kubectl patch vpa app-vpa -n produccion --type merge -p \
  '{"spec":{"updatePolicy":{"updateMode":"Off"}}}'

# Revisar las recomendaciones durante 24-48h
kubectl describe vpa app-vpa -n produccion

# Una vez estabilizadas las recomendaciones, actualizar manualmente
# los requests del Deployment y luego cambiar VPA a Initial:
kubectl patch vpa app-vpa -n produccion --type merge -p \
  '{"spec":{"updatePolicy":{"updateMode":"Initial"}}}'
```

### Escenario 6: Escalado Demasiado Lento para Picos Bruscos

**Síntoma:** El HPA tarda varios minutos en escalar cuando hay un pico repentino de tráfico. Los usuarios experimentan errores durante ese tiempo.

**Diagnóstico:**
```bash
# Ver el comportamiento actual del HPA
kubectl describe hpa app-hpa -n produccion | grep -A 20 "Behavior:"

# Ver el historial de escalados
kubectl describe hpa app-hpa -n produccion | grep -A 30 "Events:"
```

**Causa:** La configuración por defecto de scaleUp es conservadora: espera a tener tres lecturas de métricas altas consecutivas antes de escalar (45 segundos de latencia mínima). Para picos bruscos, esto es demasiado lento.

**Solución:**
```bash
# Hacer el scaleUp más agresivo
kubectl patch hpa app-hpa -n produccion --type merge -p '
spec:
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 200       # Triplicar réplicas cada 15s si es necesario
        periodSeconds: 15
      - type: Pods
        value: 10        # O añadir hasta 10 Pods cada 15s
        periodSeconds: 15
      selectPolicy: Max'
```

Complementariamente, considera usar KEDA (Kubernetes Event Driven Autoscaling) para picos predecibles (como Black Friday), que permite pre-escalar antes de que el tráfico llegue.

---

## Resumen del Capítulo

La alta disponibilidad en Kubernetes no es un solo mecanismo sino una combinación de capas que trabajan juntas.

**El HPA** escala Pods horizontalmente basándose en métricas de CPU, memoria o métricas personalizadas. Necesita el metrics-server y resource requests definidos en los Pods para funcionar. Su `behavior` controla la velocidad de escala: ser agresivo hacia arriba (stabilizationWindowSeconds=0) y conservador hacia abajo (300 segundos de gracia) es la configuración de producción estándar.

**El VPA** ajusta los recursos de cada Pod basándose en el uso histórico. Es la herramienta correcta para workloads con estado, bases de datos y jobs que no se pueden escalar horizontalmente. El modo `Off` es siempre el punto de partida: observa durante días, revisa las recomendaciones, actualiza manualmente, y solo entonces considera `Initial` o `Recreate`.

**El Cluster Autoscaler** añade y elimina nodos de AKS automáticamente. Escala hacia arriba cuando hay Pods en estado Pending; escala hacia abajo cuando los nodos llevan el tiempo configurado por debajo del umbral de utilización. En AKS, se puede combinar con múltiples node pools (sistema, GPU, Spot) para optimizar costes según el tipo de carga.

**Los PodDisruptionBudgets** son la capa de protección que hace que el autoescalado y el mantenimiento sean seguros. Sin PDB, un `kubectl drain` podría eliminar todos los Pods de un Deployment al mismo tiempo. Con PDB, Kubernetes garantiza que siempre quede el mínimo definido de réplicas disponibles, incluso durante upgrades de AKS.

**Las estrategias multi-AZ** con `topologySpreadConstraints` y pod anti-affinity garantizan que los Pods se distribuyan físicamente entre zonas de disponibilidad, de modo que el fallo de una zona completa no deje el servicio caído.

**El graceful shutdown** con `preStop` hooks y `terminationGracePeriodSeconds` asegura que cuando un Pod se elimina (por drain, scale-down o upgrade), las conexiones en vuelo terminan limpiamente antes de que el container muera.

Juntos, estos mecanismos permiten que las aplicaciones se adapten a la demanda sin intervención manual, mantengan disponibilidad durante el mantenimiento del cluster, y se recuperen automáticamente de fallos de infraestructura.
