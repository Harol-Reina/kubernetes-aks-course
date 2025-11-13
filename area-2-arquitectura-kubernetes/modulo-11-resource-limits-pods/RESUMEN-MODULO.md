# 📚 RESUMEN - Módulo 11: Resource Limits en Pods

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre la **gestión de recursos** en Kubernetes - uno de los aspectos más críticos para la estabilidad y eficiencia del clúster. Aprenderás a especificar **requests** y **limits** para CPU, memoria y storage, entender las **QoS classes**, y diagnosticar problemas comunes como OOMKilled y CPU throttling.

**Duración**: 6 horas (teoría + labs)  
**Nivel**: Intermedio-Avanzado  
**Prerequisitos**: Pods, Deployments, Namespaces

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo serás capaz de:

### Fundamentos
- ✅ Diferenciar entre **requests** y **limits**
- ✅ Explicar cómo el scheduler usa requests
- ✅ Identificar tipos de recursos (CPU, memoria, storage)
- ✅ Entender unidades (milicores, MiB, GiB)

### Técnico
- ✅ Configurar requests y limits en Pods
- ✅ Aplicar las 3 QoS classes (Guaranteed, Burstable, BestEffort)
- ✅ Gestionar ephemeral storage
- ✅ Monitorear recursos con `kubectl top`
- ✅ Diagnosticar OOMKilled y CPU throttling

### Avanzado
- ✅ Implementar Pod-level resources (K8s 1.34+)
- ✅ Configurar extended resources (GPUs)
- ✅ Optimizar para producción (right-sizing)
- ✅ Integrar Vertical Pod Autoscaler (VPA)
- ✅ Aplicar best practices a escala

---

## 🗺️ Estructura de Aprendizaje

### Fase 1: Conceptos Fundamentales (30 min)
**Teoría**: Secciones 1-2 del README

#### ¿Qué son Requests y Limits?

**Requests** = Recursos **garantizados**
- Lo mínimo que el contenedor necesita para funcionar
- El scheduler usa esto para decidir en qué nodo colocar el Pod
- El nodo DEBE tener esta cantidad disponible

**Limits** = Recursos **máximos permitidos**
- Techo que el contenedor no puede superar
- Si lo excede: throttling (CPU) o OOMKilled (memoria)
- Opcional (pero recomendado en producción)

**Analogía**: Requests = "Necesito mínimo una cama individual", Limits = "No quiero más que una cama king"

#### Diagrama Mental:
```
┌─────────────────────────────────────┐
│         LÍMITE (limit)              │ ← Techo máximo
├─────────────────────────────────────┤
│                                     │
│      Uso real (fluctúa)             │ ← Puede variar
│                                     │
├─────────────────────────────────────┤
│      PEDIDO (request)               │ ← Garantizado
└─────────────────────────────────────┘
```

#### Diferencias Críticas:

| Aspecto | Request | Limit |
|---------|---------|-------|
| **Propósito** | Scheduling (placement) | Enforcement (control) |
| **Garantía** | Siempre disponible | Máximo permitido |
| **Impacto** | Determina en qué nodo se coloca | Determina throttling/kill |
| **Si no se especifica** | Default de namespace (si hay LimitRange) | Puede usar todos los recursos del nodo |

#### Ejemplo Básico:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:          # Garantizado
        cpu: "100m"      # 0.1 CPU core
        memory: "128Mi"  # 128 MiB
      limits:            # Máximo
        cpu: "500m"      # 0.5 CPU core
        memory: "256Mi"  # 256 MiB
```

**Comportamiento**:
- Pod requiere **mínimo** 100m CPU + 128Mi memoria → scheduler busca nodo con esto disponible
- Puede usar hasta **máximo** 500m CPU + 256Mi memoria
- Si usa >500m CPU → throttling (se ralentiza)
- Si usa >256Mi memoria → OOMKilled (Pod reiniciado)

---

### Fase 2: Tipos de Recursos y Unidades (20 min)
**Teoría**: Secciones 3-4 del README

#### Tipos de Recursos

**1. CPU (Compressible Resource)**:
- Si se excede el limit → **throttling** (contenedor se ralentiza)
- **No causa terminación del Pod**
- Medido en "cores" o "milicores"

**2. Memoria (Incompressible Resource)**:
- Si se excede el limit → **OOMKilled** (Pod terminado)
- **Causa reinicio del contenedor**
- Medido en bytes (Mi, Gi, etc.)

**3. Ephemeral Storage** (opcional):
- Almacenamiento temporal (`/tmp`, logs, etc.)
- Si se excede → **Pod evicted**
- Medido en bytes

#### Unidades de CPU

```bash
# Estas son equivalentes:
1 CPU = 1000m (milicores)
0.5 CPU = 500m
0.1 CPU = 100m

# Ejemplos comunes:
100m   # Microservicio pequeño
250m   # App típica
500m   # App con carga media
1      # App con carga alta
2      # App intensiva en CPU
```

**Nota**: `1 CPU` = 1 core físico (AWS vCPU, GCP core, Azure vCore)

#### Unidades de Memoria

```bash
# Notación decimal (base 10):
1000 bytes  = 1 KB (kilobyte)
1000000     = 1 MB (megabyte)
1000000000  = 1 GB (gigabyte)

# Notación binaria (base 2) - PREFERIDA en Kubernetes:
1024 bytes     = 1 Ki (kibibyte)
1048576        = 1 Mi (mebibyte)
1073741824     = 1 Gi (gibibyte)

# Ejemplos:
128Mi   # 134 MB (app pequeña)
256Mi   # 268 MB (app típica)
512Mi   # 536 MB (app media)
1Gi     # 1073 MB (app grande)
2Gi     # 2147 MB (app intensiva)
```

**Cálculo**:
```bash
1 Mi = 1024 Ki = 1,048,576 bytes ≈ 1.05 MB
1 Gi = 1024 Mi = 1,073,741,824 bytes ≈ 1.07 GB
```

**⚠️ IMPORTANTE**: Usar `Mi`, `Gi` (binario) en vez de `M`, `G` (decimal) para consistencia.

---

### Fase 3: Quality of Service (QoS) Classes (40 min)
**Teoría**: Sección 5 del README

Kubernetes asigna automáticamente una **QoS class** a cada Pod según cómo se configuran requests/limits. Esto determina el orden de eviction cuando el nodo se queda sin recursos.

#### Las 3 QoS Classes

**1. Guaranteed (Prioridad ALTA)**
- ✅ Última en ser evicted
- ✅ Recursos garantizados
- ❌ No puede usar más de su limit

**Condiciones**:
- Todos los contenedores tienen **requests = limits**
- CPU y memoria DEBEN estar especificados
- Valores exactamente iguales

**Ejemplo**:
```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "500m"      # = request
    memory: "512Mi"  # = request
```

**Cuándo usar**: Apps críticas de producción (bases de datos, APIs principales)

---

**2. Burstable (Prioridad MEDIA)**
- ✅ Puede "burst" (usar más que request si hay disponible)
- ✅ Flexibilidad en uso de recursos
- ⚠️ Evicted antes que Guaranteed

**Condiciones**:
- Al menos 1 contenedor tiene requests **< limits**
- O algunos tienen requests pero no limits

**Ejemplo**:
```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"      # > request (puede burst)
    memory: "256Mi"  # > request
```

**Cuándo usar**: Apps normales de producción con carga variable (web apps, workers)

---

**3. BestEffort (Prioridad BAJA)**
- ❌ Sin garantías de recursos
- ❌ Primera en ser evicted
- ✅ Puede usar todos los recursos disponibles del nodo

**Condiciones**:
- **Ningún** contenedor tiene requests ni limits

**Ejemplo**:
```yaml
resources: {}  # Vacío o ausente
```

**Cuándo usar**: Jobs batch de baja prioridad, testing, desarrollo (NUNCA en producción crítica)

---

#### Tabla Resumen QoS

| QoS Class | Requests | Limits | Eviction Order | Uso |
|-----------|----------|--------|----------------|-----|
| **Guaranteed** | = Limits | Especificados | 3º (último) | Apps críticas |
| **Burstable** | < Limits o sin limits | Opcionales | 2º (medio) | Apps normales |
| **BestEffort** | Ninguno | Ninguno | 1º (primero) | Jobs batch, dev |

#### Ver QoS de un Pod:
```bash
kubectl get pod <pod-name> -o jsonpath='{.status.qosClass}'
```

**Lab 1**: [Fundamentos](laboratorios/lab-01-fundamentos.md) - 50 min

---

### Fase 4: Configuración Práctica (30 min)
**Teoría**: Sección 6 del README

#### YAML Completo con Recursos

**Single Container**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: single-container
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
```

**Multi-Container**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
  - name: sidecar
    image: busybox
    resources:
      requests:
        cpu: "100m"
        memory: "64Mi"
      limits:
        cpu: "200m"
        memory: "128Mi"
```

**Total del Pod**: Suma de todos los contenedores
- Requests: 250m + 100m = **350m CPU**, 256Mi + 64Mi = **320Mi memoria**
- Limits: 500m + 200m = **700m CPU**, 512Mi + 128Mi = **640Mi memoria**

#### Init Containers

```yaml
spec:
  initContainers:
  - name: init-db
    image: busybox
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "256Mi"
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
```

**Importante**: Init containers NO se suman a los containers normales (se ejecutan secuencialmente).

**Cálculo de scheduling**:
- Requests totales = **max**(init containers, sum(containers))
- En este caso: max(100m, 250m) = **250m CPU**

---

### Fase 5: Comandos Esenciales (20 min)

#### Crear/Actualizar Recursos

```bash
# Aplicar Pod con recursos
kubectl apply -f pod-with-resources.yaml

# Crear Deployment con recursos (imperativo)
kubectl create deployment nginx --image=nginx --replicas=3

# Actualizar recursos de Deployment existente
kubectl set resources deployment nginx \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=512Mi

# Ver recursos configurados
kubectl get pod <pod-name> -o yaml | grep -A 10 resources:
```

#### Monitoreo de Uso

```bash
# Ver uso actual de CPU/memoria de nodos
kubectl top nodes

# Ver uso de Pods (todos los namespaces)
kubectl top pods -A

# Ver uso de Pods en namespace específico
kubectl top pods -n production

# Ordenar por CPU
kubectl top pods -A --sort-by=cpu

# Ordenar por memoria
kubectl top pods -A --sort-by=memory

# Ver uso de contenedores dentro de un Pod
kubectl top pod <pod-name> --containers
```

#### Troubleshooting

```bash
# Ver eventos del Pod (buscar Insufficient CPU/memory)
kubectl describe pod <pod-name>

# Ver si Pod fue OOMKilled
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'

# Ver logs del contenedor antes del crash
kubectl logs <pod-name> --previous

# Ver QoS class del Pod
kubectl get pod <pod-name> -o jsonpath='{.status.qosClass}'

# Ver recursos solicitados vs disponibles en nodo
kubectl describe node <node-name>
```

---

### Fase 6: Ephemeral Storage (30 min)
**Teoría**: Sección 8 del README

**¿Qué es Ephemeral Storage?**
- Almacenamiento **temporal** en el nodo (no persistente)
- Incluye: `/tmp`, logs de contenedores, EmptyDir volumes, writable layers

**Por qué es importante**:
- Los logs excesivos pueden llenar el disco del nodo
- Writable layers de imágenes grandes consumen espacio
- Sin límites → riesgo de llenar el disco del nodo

**Configuración**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-demo
spec:
  containers:
  - name: app
    image: busybox
    resources:
      requests:
        ephemeral-storage: "1Gi"
      limits:
        ephemeral-storage: "2Gi"
```

**Comportamiento**:
- Si excede el limit → **Pod evicted** (no OOMKilled, simplemente removido)

**Monitoreo**:
```bash
# Ver uso de ephemeral storage (si metrics-server soporta)
kubectl top pods --containers

# Ver eventos de eviction
kubectl get events --sort-by='.lastTimestamp' | grep -i evicted
```

---

### Fase 7: Extended Resources (GPUs, FPGAs) (30 min)
**Teoría**: Sección 9 del README

**Extended Resources** = Recursos personalizados (no CPU/memoria)

**Ejemplos comunes**:
- GPUs (NVIDIA, AMD)
- FPGAs
- Recursos customizados (licencias, dongles)

**Configuración de GPU**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  containers:
  - name: cuda-app
    image: nvidia/cuda:11.0-base
    resources:
      limits:
        nvidia.com/gpu: 1  # Requiere 1 GPU
```

**Nota**: Requiere plugin del nodo (NVIDIA device plugin, AMD device plugin)

**Ver GPUs disponibles en nodo**:
```bash
kubectl describe node <node-name> | grep -i gpu
```

---

### Fase 8: Scheduler y Enforcement (30 min)
**Teoría**: Secciones 10-11 del README

#### Cómo el Scheduler Usa Requests

**Proceso de scheduling**:
1. Usuario crea Pod con requests especificados
2. Scheduler busca nodos con recursos **disponibles** >= requests
3. Si encuentra → coloca Pod en ese nodo
4. Si NO encuentra → Pod queda **Pending** con evento `Insufficient cpu/memory`

**Ejemplo**:
```yaml
resources:
  requests:
    cpu: "2"       # Necesita nodo con >= 2 cores disponibles
    memory: "4Gi"  # Necesita nodo con >= 4Gi disponibles
```

**Ver recursos de nodo**:
```bash
kubectl describe node <node-name>

# Output relevante:
# Allocated resources:
#   CPU Requests:  1500m (75% of 2 cores)    ← 500m disponibles
#   Memory Requests: 3Gi (75% of 4Gi)        ← 1Gi disponible
```

**Si requests del Pod = 2 CPU**: No cabe en este nodo → busca otro.

#### Enforcement de Límites

**CPU Limits** (throttling):
- Si contenedor intenta usar > limit de CPU → **throttled** (ralentizado)
- Proceso sigue corriendo pero más lento
- Ver con: `kubectl top pod <pod> --containers`

**Memory Limits** (OOMKilled):
- Si contenedor usa > limit de memoria → **OOMKilled** (terminado)
- Kubernetes reinicia el contenedor
- Ver razón: `kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'`
- Output: `OOMKilled`

**Lab 2**: [Troubleshooting](laboratorios/lab-02-troubleshooting.md) - 60 min

---

### Fase 9: Best Practices (30 min)
**Teoría**: Sección 13 del README

#### Recomendaciones para Producción

**1. SIEMPRE especificar requests**:
```yaml
# ✅ BUENO
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"

# ❌ MALO (Pod puede no ser schedulable)
resources: {}
```

**2. Especificar limits para memoria (prevenir OOM)**:
```yaml
# ✅ BUENO
resources:
  requests:
    memory: "256Mi"
  limits:
    memory: "512Mi"  # Previene que un leak consuma todo

# ❌ MALO (puede consumir toda la memoria del nodo)
resources:
  requests:
    memory: "256Mi"
  # Sin limits
```

**3. Limits de CPU opcionales (depende del caso)**:
```yaml
# Apps que deben responder rápido → sin limit de CPU
resources:
  requests:
    cpu: "500m"
  # Sin limits: puede usar todo el CPU disponible si necesita

# Apps que comparten nodo → con limit de CPU
resources:
  requests:
    cpu: "500m"
  limits:
    cpu: "1"  # No monopolizar CPU
```

**4. QoS class según criticidad**:
```yaml
# Apps críticas (DB, cache) → Guaranteed
resources:
  requests:
    cpu: "1"
    memory: "1Gi"
  limits:
    cpu: "1"      # = request
    memory: "1Gi" # = request

# Apps normales → Burstable
resources:
  requests:
    cpu: "250m"
    memory: "256Mi"
  limits:
    cpu: "1"      # Puede burst
    memory: "512Mi"
```

**5. Right-sizing (ajustar recursos al uso real)**:
```bash
# Monitorear uso durante 1 semana
kubectl top pods -n production --sort-by=memory

# Ajustar requests/limits según:
# - Max memory usado + 20% buffer = limit
# - Average memory usado = request
# - Similar para CPU
```

**6. Usar Vertical Pod Autoscaler (VPA)**:
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myapp-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "Auto"  # Ajusta automáticamente
```

**7. ResourceQuota + LimitRange por namespace**:
```yaml
# Namespace quota (total)
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: development
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
---
# LimitRange (defaults por Pod)
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: development
spec:
  limits:
  - type: Container
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    default:
      cpu: "500m"
      memory: "512Mi"
```

**Lab 3**: [Producción](laboratorios/lab-03-produccion.md) - 60 min

---

### Fase 10: Troubleshooting Avanzado (30 min)
**Teoría**: Sección 14 del README

#### Problema 1: Pod en Pending - Insufficient CPU/Memory

**Síntoma**:
```bash
kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# myapp   0/1     Pending   0          5m
```

**Diagnóstico**:
```bash
kubectl describe pod myapp

# Events:
# Warning  FailedScheduling  5m  default-scheduler  0/3 nodes are available:
# 3 Insufficient cpu.
```

**Causas**:
1. Requests muy altos (Pod pide más de lo disponible)
2. Clúster sin recursos (todos los nodos llenos)
3. Node selectors/affinity restrictivos

**Soluciones**:
```bash
# Ver recursos disponibles en nodos
kubectl describe nodes | grep -A 5 "Allocated resources"

# Reducir requests
kubectl edit deployment myapp
# Cambiar requests a valores más razonables

# O escalar clúster (agregar nodos)
```

---

#### Problema 2: OOMKilled - Pod reiniciándose

**Síntoma**:
```bash
kubectl get pods
# NAME           READY   STATUS      RESTARTS   AGE
# myapp-abc123   0/1     OOMKilled   5          10m
```

**Diagnóstico**:
```bash
# Verificar razón de terminación
kubectl get pod myapp-abc123 -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'
# Output: OOMKilled

# Ver uso de memoria antes del crash
kubectl top pod myapp-abc123 --containers
```

**Causas**:
1. Memory limit muy bajo
2. Memory leak en la aplicación
3. Spike de tráfico

**Soluciones**:
```bash
# Aumentar memory limit
kubectl set resources deployment myapp \
  --limits=memory=1Gi

# O investigar memory leak en código
kubectl logs myapp-abc123 --previous  # Logs antes del crash
```

---

#### Problema 3: CPU Throttling - App lenta

**Síntoma**:
- App responde lento
- Latencia alta
- No hay OOMKilled

**Diagnóstico**:
```bash
# Ver uso de CPU
kubectl top pods --containers

# Output:
# POD       CONTAINER   CPU(cores)   MEMORY(bytes)
# myapp     app         500m         256Mi
# ↑ Si está cerca del limit → throttling

# Ver limit configurado
kubectl get pod myapp -o yaml | grep -A 5 "limits:"
```

**Causas**:
1. CPU limit muy bajo
2. Spike de tráfico
3. Código ineficiente

**Soluciones**:
```bash
# Aumentar CPU limit (o quitarlo)
kubectl set resources deployment myapp \
  --limits=cpu=2

# O mejorar eficiencia del código
```

---

#### Problema 4: Pod Evicted - Disk Pressure

**Síntoma**:
```bash
kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# myapp   0/1     Evicted   0          1m
```

**Diagnóstico**:
```bash
kubectl describe pod myapp

# Reason: Evicted
# Message: The node was low on resource: ephemeral-storage
```

**Causas**:
1. Logs excesivos
2. Imágenes muy grandes
3. Sin límite de ephemeral storage

**Soluciones**:
```bash
# Limpiar disco del nodo (SSH al nodo)
docker system prune -a

# Agregar límite de ephemeral storage
kubectl set resources deployment myapp \
  --limits=ephemeral-storage=2Gi

# Rotar logs más frecuentemente
```

---

## 📝 Comandos Esenciales - Cheat Sheet

### Configuración de Recursos

```bash
# Aplicar Pod con recursos
kubectl apply -f pod.yaml

# Actualizar recursos de Deployment
kubectl set resources deployment <name> \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=512Mi

# Actualizar solo requests
kubectl set resources deployment <name> \
  --requests=cpu=200m,memory=256Mi

# Actualizar solo limits
kubectl set resources deployment <name> \
  --limits=cpu=1,memory=1Gi
```

### Monitoreo

```bash
# Uso de nodos
kubectl top nodes

# Uso de Pods
kubectl top pods -A
kubectl top pods -n <namespace>
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory

# Uso por contenedor
kubectl top pod <pod-name> --containers
```

### Inspección

```bash
# Ver recursos configurados
kubectl describe pod <pod-name>
kubectl get pod <pod-name> -o yaml | grep -A 10 "resources:"

# Ver QoS class
kubectl get pod <pod-name> -o jsonpath='{.status.qosClass}'

# Ver recursos del nodo
kubectl describe node <node-name>

# Ver por qué Pod está Pending
kubectl describe pod <pod-name> | grep -A 5 Events:

# Ver razón de terminación (OOMKilled)
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'
```

### Troubleshooting

```bash
# Ver eventos recientes
kubectl get events --sort-by='.lastTimestamp'

# Ver logs del contenedor previo (después de crash)
kubectl logs <pod-name> --previous

# Ver recursos disponibles en nodos
kubectl describe nodes | grep -A 5 "Allocated resources"

# Ver Pods que más recursos consumen
kubectl top pods -A --sort-by=memory | head -10
kubectl top pods -A --sort-by=cpu | head -10
```

---

## 🎯 Conceptos Clave para Recordar

### Requests vs Limits

```
REQUEST = Garantizado, usado por scheduler
LIMIT = Máximo permitido, enforcement

Request ≤ Uso Real ≤ Limit
```

### QoS Classes

```
Guaranteed:  requests = limits (todos los recursos)
Burstable:   requests < limits (o solo algunos especificados)
BestEffort:  sin requests ni limits
```

### Enforcement

```
CPU:     Excede limit → Throttling (no termina)
Memory:  Excede limit → OOMKilled (termina y reinicia)
Storage: Excede limit → Evicted (removido del nodo)
```

### Unidades

```
CPU:
  1 = 1 core
  1000m = 1 core
  500m = 0.5 core
  100m = 0.1 core

Memoria:
  1 Mi = 1,048,576 bytes ≈ 1.05 MB
  1 Gi = 1,073,741,824 bytes ≈ 1.07 GB
  
Preferir Mi/Gi (binario) sobre M/G (decimal)
```

---

## ✅ Checklist de Dominio

Marca cuando domines cada concepto:

### Fundamentos
- [ ] Puedo explicar la diferencia entre requests y limits
- [ ] Entiendo cómo el scheduler usa requests
- [ ] Sé qué son recursos compressible vs incompressible
- [ ] Conozco las unidades (milicores, Mi, Gi)

### QoS Classes
- [ ] Puedo identificar las 3 QoS classes
- [ ] Sé cómo se asigna automáticamente la QoS
- [ ] Entiendo el orden de eviction
- [ ] Puedo diseñar Pods Guaranteed, Burstable, BestEffort

### Configuración
- [ ] Sé configurar requests y limits en YAML
- [ ] Puedo calcular recursos totales de un Pod multi-container
- [ ] Entiendo el manejo de init containers
- [ ] Puedo actualizar recursos con `kubectl set resources`

### Monitoreo
- [ ] Uso `kubectl top` para ver uso actual
- [ ] Sé interpretar `kubectl describe node`
- [ ] Puedo correlacionar uso con limits configurados
- [ ] Identifico Pods con alto consumo

### Troubleshooting
- [ ] Diagnostico por qué un Pod está Pending (Insufficient resources)
- [ ] Identifico y resuelvo OOMKilled
- [ ] Detecto CPU throttling
- [ ] Resuelvo Pods evicted por disk pressure

### Best Practices
- [ ] Siempre especifico requests en producción
- [ ] Uso limits de memoria para prevenir OOM
- [ ] Elijo QoS class apropiada según criticidad
- [ ] Aplico right-sizing basado en monitoreo
- [ ] Uso ResourceQuota y LimitRange por namespace

### Avanzado
- [ ] Sé configurar ephemeral storage limits
- [ ] Entiendo extended resources (GPUs)
- [ ] Puedo implementar VPA
- [ ] Aplico estrategias de optimización a escala

### Práctica
- [ ] Completé Lab 01: Fundamentos
- [ ] Completé Lab 02: Troubleshooting
- [ ] Completé Lab 03: Producción
- [ ] Aplico learnings a mis aplicaciones reales

---

## 🎓 Evaluación Final

### Preguntas Clave
1. ¿Qué sucede si un Pod no especifica requests ni limits?
2. ¿Cómo se calcula la QoS class de un Pod?
3. ¿Por qué un Pod puede estar Pending con "Insufficient cpu"?
4. ¿Cuál es la diferencia en comportamiento entre exceder CPU limit vs Memory limit?
5. ¿Cuándo deberías usar QoS Guaranteed vs Burstable?

<details>
<summary>Ver Respuestas</summary>

1. **Sin requests ni limits**:
   - QoS class = **BestEffort**
   - Puede usar todos los recursos disponibles del nodo
   - Primera en ser evicted cuando hay presión de recursos
   - **No recomendado en producción**

2. **Cálculo de QoS**:
   - **Guaranteed**: Todos los contenedores tienen requests = limits para CPU y memoria
   - **Burstable**: Al menos 1 contenedor tiene requests < limits (o solo requests)
   - **BestEffort**: Ningún contenedor tiene requests ni limits

3. **Pod Pending - Insufficient cpu**:
   - Requests del Pod > recursos disponibles en todos los nodos
   - Scheduler no encuentra nodo con suficientes recursos
   - Soluciones: Reducir requests, escalar clúster, o eliminar Pods innecesarios

4. **CPU vs Memory limits**:
   - **CPU** (compressible): Exceder → **throttling** (se ralentiza, no termina)
   - **Memory** (incompressible): Exceder → **OOMKilled** (termina y reinicia)

5. **Guaranteed vs Burstable**:
   - **Guaranteed**: Apps críticas (DB, caché) que necesitan performance predecible
   - **Burstable**: Apps normales con carga variable que pueden burst ocasionalmente
   - Guaranteed tiene menor riesgo de eviction pero menos flexibilidad

</details>

### Escenario Práctico
Tienes un Deployment de 3 réplicas que frecuentemente experimenta OOMKilled. El Pod tiene:
```yaml
resources:
  requests:
    memory: "256Mi"
  limits:
    memory: "512Mi"
```

Observas con `kubectl top` que las réplicas usan 450-480Mi constantemente.

**¿Qué harías?**

<details>
<summary>Ver Solución</summary>

**Análisis**:
- Uso actual: 450-480Mi
- Limit: 512Mi
- Problema: Uso muy cercano al limit → OOMKilled en spikes

**Soluciones**:

**1. Aumentar memory limit (corto plazo)**:
```bash
kubectl set resources deployment myapp \
  --limits=memory=1Gi
```

**2. Investigar memory leak (medio plazo)**:
```bash
# Ver logs para identificar leak
kubectl logs <pod-name>

# Profiling de memoria (si la app lo soporta)
# Herramientas: pprof (Go), VisualVM (Java), memory-profiler (Python)
```

**3. Optimizar código (largo plazo)**:
- Revisar caches en memoria
- Implementar garbage collection más agresivo
- Optimizar queries a DB
- Limitar tamaño de buffers

**4. Monitorear y right-size**:
```bash
# Después de optimizar, monitorear por 1 semana
kubectl top pods -n <namespace> --sort-by=memory

# Ajustar a:
# requests = average uso + 10%
# limits = max uso + 20% buffer
```

**Configuración final recomendada**:
```yaml
resources:
  requests:
    memory: "512Mi"  # Average + 10%
  limits:
    memory: "768Mi"  # Max + 20%
```

</details>

---

## 🔗 Recursos Adicionales

### Documentación Oficial
- [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Quality of Service Classes](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)

### Labs del Módulo
1. [Lab 01 - Fundamentos](laboratorios/lab-01-fundamentos.md) - 50 min
2. [Lab 02 - Troubleshooting](laboratorios/lab-02-troubleshooting.md) - 60 min
3. [Lab 03 - Producción](laboratorios/lab-03-produccion.md) - 60 min

### Ejemplos Prácticos
- [`ejemplos/01-requests-limits-basico/`](ejemplos/01-requests-limits-basico/) - Configuración básica
- [`ejemplos/02-multi-container/`](ejemplos/02-multi-container/) - Múltiples contenedores
- [`ejemplos/07-qos-guaranteed/`](ejemplos/07-qos-guaranteed/) - QoS Guaranteed
- [`ejemplos/08-qos-burstable/`](ejemplos/08-qos-burstable/) - QoS Burstable
- [`ejemplos/13-troubleshooting-oom/`](ejemplos/13-troubleshooting-oom/) - OOMKilled scenarios

### Herramientas
- [kubectl top](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#interacting-with-running-pods) - Monitoreo básico
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server) - Requerido para `kubectl top`
- [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) - Right-sizing automático
- [Goldilocks](https://github.com/FairwindsOps/goldilocks) - Recomendaciones de VPA
- [Prometheus + Grafana](https://prometheus.io/) - Monitoreo avanzado

### Siguiente Módulo
➡️ Módulo 12: Health Checks y Probes

---

## 🎉 ¡Felicitaciones!

Has completado el Módulo 11 de Resource Limits. Ahora puedes:

- ✅ Configurar requests y limits apropiados
- ✅ Diseñar Pods con QoS classes óptimas
- ✅ Monitorear uso de recursos en producción
- ✅ Diagnosticar y resolver OOMKilled, throttling, evictions
- ✅ Aplicar best practices de resource management

**Próximos pasos**:
1. Revisar este resumen periódicamente
2. Completar los 3 laboratorios prácticos
3. Auditar recursos de tus aplicaciones actuales
4. Implementar monitoreo continuo
5. Continuar con Módulo 12: Health Checks

¡Sigue adelante! 🚀
