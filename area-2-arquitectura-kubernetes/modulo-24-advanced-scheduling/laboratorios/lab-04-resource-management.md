# Laboratorio 04: Resource Management - Quotas, Limits y Priorities

## Información del Laboratorio

- **Duración estimada**: 45-60 minutos
- **Dificultad**: ⭐⭐⭐ (Intermedio-Avanzado)
- **Requisitos**: Cluster con acceso de admin
- **Cobertura CKA**: ~2% del examen

## Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

1. Configurar ResourceQuotas en namespaces
2. Implementar LimitRanges para defaults y límites
3. Crear y usar PriorityClasses
4. Entender preemption y QoS classes
5. Troubleshoot problemas de recursos

## Pre-requisitos

```bash
# Verificar permisos de admin
kubectl auth can-i create resourcequotas --all-namespaces
kubectl auth can-i create priorityclasses

# Deben retornar "yes"
```

---

## Ejercicio 1: ResourceQuotas - Control de Recursos por Namespace (20 minutos)

### Objetivo
Implementar quotas para controlar uso de recursos en namespaces compartidos.

### Paso 1: Crear namespace de desarrollo

```bash
# Crear namespace
kubectl create namespace dev-team-a

# Verificar
kubectl get namespace dev-team-a
```

### Paso 2: Aplicar ResourceQuota

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-team-a-quota
  namespace: dev-team-a
spec:
  hard:
    # Compute resources
    requests.cpu: "10"           # Total: 10 cores de CPU requests
    requests.memory: "20Gi"      # Total: 20 GB de memory requests
    limits.cpu: "20"             # Total: 20 cores de CPU limits
    limits.memory: "40Gi"        # Total: 40 GB de memory limits
    
    # Object counts
    pods: "50"                   # Máximo 50 pods
    services: "10"               # Máximo 10 services
    persistentvolumeclaims: "20" # Máximo 20 PVCs
    
    # Storage
    requests.storage: "500Gi"    # Total: 500 GB de storage
EOF
```

**Verificar quota:**

```bash
# Ver quota
kubectl get resourcequota -n dev-team-a

# Ver detalles y uso actual
kubectl describe resourcequota dev-team-a-quota -n dev-team-a

# Debe mostrar:
# - Used: 0 (nada usado aún)
# - Hard: límites configurados
```

### Paso 3: Intentar crear pod SIN resource requests (FALLARÁ)

```bash
# Intentar crear pod sin resources
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-no-resources
  namespace: dev-team-a
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
EOF

# RESULTADO: Error
# "failed quota: dev-team-a-quota: must specify limits.cpu,limits.memory,requests.cpu,requests.memory"
```

**Explicación:**
Cuando hay ResourceQuota, TODOS los pods DEBEN especificar resource requests/limits.

### Paso 4: Crear pod CON resource requests (FUNCIONA)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-resources
  namespace: dev-team-a
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    resources:
      requests:
        cpu: "200m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
EOF
```

**Verificar uso de quota:**

```bash
kubectl describe resourcequota dev-team-a-quota -n dev-team-a

# Debe mostrar:
# Used:
#   limits.cpu: 500m
#   limits.memory: 512Mi
#   pods: 1
#   requests.cpu: 200m
#   requests.memory: 256Mi
```

### Paso 5: Crear deployment hasta agotar quota

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: dev-team-a
spec:
  replicas: 30  # Intentaremos crear 30 pods
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        resources:
          requests:
            cpu: "500m"    # 30 pods * 500m = 15 cores
            memory: "1Gi"  # 30 pods * 1Gi = 30 GB
          limits:
            cpu: "1000m"
            memory: "2Gi"
EOF
```

**Analizar resultado:**

```bash
# Ver pods creados
kubectl get pods -n dev-team-a

# Ver eventos del ReplicaSet
kubectl get events -n dev-team-a --sort-by='.lastTimestamp' | grep quota

# Ver cuántos pods se crearon
kubectl get pods -n dev-team-a --no-headers | wc -l

# Ver quota actual
kubectl describe resourcequota dev-team-a-quota -n dev-team-a

# El deployment creará pods hasta agotar CPU o Memory quota
# Luego verás eventos: "exceeded quota"
```

**Calcular capacidad:**

```bash
# Quota permite: 10 cores de CPU requests
# Cada pod pide: 500m (0.5 cores)
# Máximo pods por CPU: 10 / 0.5 = 20 pods

# Quota permite: 20 GB de Memory requests
# Cada pod pide: 1 Gi
# Máximo pods por Memory: 20 / 1 = 20 pods

# Por tanto, solo 19 pods se crearán (20 - 1 pod existente)
```

### Paso 6: Ajustar deployment a capacidad

```bash
# Reducir a 15 replicas (dentro de quota)
kubectl scale deployment nginx-deployment --replicas=15 -n dev-team-a

# Esperar
kubectl wait --for=condition=Ready pod -l app=nginx -n dev-team-a --timeout=60s

# Verificar
kubectl get pods -n dev-team-a | grep nginx
kubectl describe resourcequota dev-team-a-quota -n dev-team-a
```

### ✅ Criterios de Éxito - Ejercicio 1

- [ ] ResourceQuota aplicada correctamente
- [ ] Pods sin resources requests son rechazados
- [ ] Quota bloquea creación cuando se exceden límites
- [ ] Puedes calcular capacidad de pods basado en quota

---

## Ejercicio 2: LimitRange - Defaults y Límites Automáticos (15 minutos)

### Objetivo
Usar LimitRange para aplicar defaults y validar límites de recursos.

### Paso 1: Crear nuevo namespace con LimitRange

```bash
# Crear namespace
kubectl create namespace dev-team-b

# Aplicar LimitRange
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: dev-team-b-limits
  namespace: dev-team-b
spec:
  limits:
  # Container level
  - type: Container
    # Defaults aplicados si no se especifican
    default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    # Límites máximos y mínimos
    max:
      cpu: "2000m"
      memory: "4Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    # Ratio máximo limits/requests
    maxLimitRequestRatio:
      cpu: "4"
      memory: "3"
  
  # Pod level
  - type: Pod
    max:
      cpu: "4000m"
      memory: "8Gi"
  
  # PVC level
  - type: PersistentVolumeClaim
    max:
      storage: "100Gi"
    min:
      storage: "1Gi"
EOF
```

**Verificar:**

```bash
kubectl get limitrange -n dev-team-b
kubectl describe limitrange dev-team-b-limits -n dev-team-b
```

### Paso 2: Crear pod SIN resources (defaults se aplican)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-defaults
  namespace: dev-team-b
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
EOF
```

**Verificar defaults aplicados:**

```bash
# Ver resources aplicados
kubectl get pod pod-with-defaults -n dev-team-b -o jsonpath='{.spec.containers[0].resources}' | jq

# Debe mostrar:
# {
#   "limits": {
#     "cpu": "500m",
#     "memory": "512Mi"
#   },
#   "requests": {
#     "cpu": "100m",
#     "memory": "128Mi"
#   }
# }
```

### Paso 3: Intentar violar límites máximos (FALLARÁ)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-violates-max
  namespace: dev-team-b
spec:
  containers:
  - name: greedy
    image: nginx:1.25-alpine
    resources:
      requests:
        cpu: "3000m"      # VIOLA max: 2000m
        memory: "5Gi"     # VIOLA max: 4Gi
      limits:
        cpu: "5000m"
        memory: "10Gi"
EOF

# Error esperado:
# "limits.cpu: Invalid value: '5000m': must be less than or equal to 2000m"
```

### Paso 4: Intentar violar ratio limits/requests (FALLARÁ)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-violates-ratio
  namespace: dev-team-b
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"       # Ratio: 5x (VIOLA maxRatio: 4)
        memory: "512Mi"   # Ratio: 4x (OK)
EOF

# Error esperado:
# "limits.cpu/requests.cpu: Invalid value: '5': must be less than or equal to 4"
```

### Paso 5: Crear pod válido dentro de límites

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-valid
  namespace: dev-team-b
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    resources:
      requests:
        cpu: "200m"      # OK (min: 50m, max: 2000m)
        memory: "256Mi"  # OK (min: 64Mi, max: 4Gi)
      limits:
        cpu: "600m"      # Ratio: 3x (OK, max ratio: 4)
        memory: "768Mi"  # Ratio: 3x (OK, max ratio: 3)
EOF

# Este pod se crea exitosamente
kubectl get pod pod-valid -n dev-team-b
```

### Paso 6: Combinar ResourceQuota + LimitRange

```bash
# Aplicar ResourceQuota también
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-team-b-quota
  namespace: dev-team-b
spec:
  hard:
    requests.cpu: "5"
    requests.memory: "10Gi"
    limits.cpu: "10"
    limits.memory: "20Gi"
    pods: "20"
EOF
```

**Probar comportamiento combinado:**

```bash
# Pod sin resources: LimitRange aplica defaults
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-auto-defaults
  namespace: dev-team-b
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
  - name: sidecar
    image: busybox
    command: ["sleep", "3600"]
EOF

# Ver resources aplicados
kubectl get pod pod-auto-defaults -n dev-team-b -o yaml | grep -A 10 resources:

# Cada container obtiene defaults del LimitRange
# Y cuenta contra el ResourceQuota
```

**Verificar quota:**

```bash
kubectl describe resourcequota dev-team-b-quota -n dev-team-b

# Debe mostrar uso acumulado de todos los pods
```

### ✅ Criterios de Éxito - Ejercicio 2

- [ ] LimitRange aplica defaults automáticamente
- [ ] Pods que violan max/min son rechazados
- [ ] maxLimitRequestRatio se valida correctamente
- [ ] LimitRange + ResourceQuota funcionan juntos

---

## Ejercicio 3: PriorityClasses y Preemption (20 minutos)

### Objetivo
Implementar priorización de pods y observar preemption en acción.

### Paso 1: Crear PriorityClasses

```bash
# Priority alta (aplicaciones críticas)
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 100000
globalDefault: false
description: "High priority for critical applications"
EOF

# Priority media (default para todos)
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: medium-priority
value: 10000
globalDefault: true
description: "Medium priority - default for all pods"
EOF

# Priority baja (batch jobs)
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 1000
globalDefault: false
preemptionPolicy: Never  # No puede preempt otros pods
description: "Low priority for batch jobs"
EOF
```

**Verificar:**

```bash
kubectl get priorityclasses

# Debe mostrar:
# NAME                      VALUE     GLOBAL-DEFAULT   AGE
# high-priority            100000    false            ...
# medium-priority          10000     true             ...
# low-priority             1000      false            ...
# system-cluster-critical  2000000000 false           ...
# system-node-critical     2000001000 false           ...
```

### Paso 2: Crear namespace de prueba

```bash
kubectl create namespace priority-test
```

### Paso 3: Crear pods de baja prioridad (batch jobs)

```bash
# Crear 3 pods de baja prioridad que consuman recursos
for i in 1 2 3; do
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: batch-job-$i
  namespace: priority-test
spec:
  priorityClassName: low-priority
  containers:
  - name: worker
    image: busybox
    command: ["sh", "-c", "echo Batch job $i running; sleep 3600"]
    resources:
      requests:
        cpu: "1000m"
        memory: "2Gi"
      limits:
        cpu: "1000m"
        memory: "2Gi"
EOF
done

# Esperar a que se creen
kubectl wait --for=condition=Ready pod -l "" -n priority-test --timeout=60s

# Ver pods
kubectl get pods -n priority-test -o custom-columns=\
NAME:.metadata.name,\
PRIORITY:.spec.priorityClassName,\
VALUE:.spec.priority,\
NODE:.spec.nodeName,\
STATUS:.status.phase
```

### Paso 4: Crear pod de ALTA prioridad (fuerza preemption)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: critical-service
  namespace: priority-test
spec:
  priorityClassName: high-priority
  containers:
  - name: api
    image: nginx:1.25-alpine
    resources:
      requests:
        cpu: "2000m"
        memory: "4Gi"
      limits:
        cpu: "2000m"
        memory: "4Gi"
EOF
```

**Observar preemption:**

```bash
# Ver eventos de preemption
kubectl get events -n priority-test --sort-by='.lastTimestamp' | grep -i preempt

# Ver estado de pods
kubectl get pods -n priority-test -w

# Verás que algunos pods de baja prioridad son evicted
# para hacer espacio al pod de alta prioridad

# Ver cuáles fueron evicted
kubectl get pods -n priority-test --field-selector=status.phase=Failed
```

**Verificar pods restantes:**

```bash
kubectl get pods -n priority-test -o custom-columns=\
NAME:.metadata.name,\
PRIORITY:.spec.priorityClassName,\
VALUE:.spec.priority,\
STATUS:.status.phase

# El pod critical-service estará Running
# Algunos batch-job-X estarán Evicted o Terminated
```

### Paso 5: Deployment con prioridad media

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: priority-test
spec:
  replicas: 5
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      priorityClassName: medium-priority  # Usa default
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
EOF
```

**Ver jerarquía de prioridades:**

```bash
kubectl get pods -n priority-test -o custom-columns=\
NAME:.metadata.name,\
PRIORITY:.spec.priorityClassName,\
VALUE:.spec.priority | sort -k3 -n -r

# Debe mostrar orden:
# 1. critical-service (high-priority, 100000)
# 2. web-app-xxx (medium-priority, 10000)
# 3. batch-job-X (low-priority, 1000)
```

### Paso 6: Probar preemptionPolicy: Never

```bash
# Intentar crear pod de baja prioridad con muchos recursos
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: large-batch-job
  namespace: priority-test
spec:
  priorityClassName: low-priority  # preemptionPolicy: Never
  containers:
  - name: worker
    image: busybox
    command: ["sleep", "3600"]
    resources:
      requests:
        cpu: "3000m"
        memory: "6Gi"
      limits:
        cpu: "3000m"
        memory: "6Gi"
EOF

# Ver estado
kubectl get pod large-batch-job -n priority-test

# Quedará en Pending porque:
# 1. Necesita muchos recursos
# 2. Su preemptionPolicy: Never no le permite evictar otros pods
# 3. No hay suficientes recursos disponibles

# Ver por qué está Pending
kubectl describe pod large-batch-job -n priority-test | grep -A 5 Events
```

### Paso 7: Ver QoS Classes resultantes

```bash
# Ver QoS class de cada pod
kubectl get pods -n priority-test -o custom-columns=\
NAME:.metadata.name,\
QOS:.status.qosClass,\
PRIORITY:.spec.priorityClassName

# QoS Classes:
# - Guaranteed: requests == limits (todos nuestros pods)
# - Burstable: requests < limits
# - BestEffort: sin requests/limits
```

**Entender orden de eviction bajo presión:**

```bash
echo "=== Orden de Eviction (bajo presión de recursos) ==="
echo "1. BestEffort pods (lowest QoS)"
echo "2. Burstable pods exceeding requests"
echo "3. Burstable pods within requests (por prioridad)"
echo "4. Guaranteed pods (por prioridad)"
echo ""
echo "Dentro de cada QoS class:"
echo "- Menor prioridad primero"
echo "- Si igual prioridad: mayor uso de recursos"
```

### ✅ Criterios de Éxito - Ejercicio 3

- [ ] PriorityClasses creadas y asignadas correctamente
- [ ] Preemption ocurre cuando pod de alta prioridad necesita recursos
- [ ] preemptionPolicy: Never previene eviction de otros pods
- [ ] Entiendes la relación entre QoS class y priority

---

## Limpieza del Laboratorio

```bash
# Eliminar namespaces (elimina todo su contenido)
kubectl delete namespace dev-team-a dev-team-b priority-test

# Eliminar PriorityClasses (opcional, pueden reutilizarse)
kubectl delete priorityclass high-priority medium-priority low-priority

# Verificar limpieza
kubectl get namespaces | grep dev-team
kubectl get priorityclasses | grep -E 'high|medium|low'
```

---

## Resumen de Comandos Útiles

```bash
# ResourceQuotas
kubectl get resourcequota -n <namespace>
kubectl describe resourcequota <name> -n <namespace>

# LimitRanges
kubectl get limitrange -n <namespace>
kubectl describe limitrange <name> -n <namespace>

# PriorityClasses
kubectl get priorityclasses
kubectl describe priorityclass <name>

# Ver recursos de pods
kubectl get pods -n <namespace> -o custom-columns=\
NAME:.metadata.name,\
CPU_REQ:.spec.containers[*].resources.requests.cpu,\
MEM_REQ:.spec.containers[*].resources.requests.memory,\
CPU_LIM:.spec.containers[*].resources.limits.cpu,\
MEM_LIM:.spec.containers[*].resources.limits.memory

# Ver uso actual de recursos
kubectl top pods -n <namespace>
kubectl top nodes

# Ver eventos relacionados con quotas
kubectl get events -n <namespace> --field-selector reason=FailedCreate

# Ver pods por prioridad
kubectl get pods -A -o custom-columns=\
NAMESPACE:.metadata.namespace,\
NAME:.metadata.name,\
PRIORITY:.spec.priorityClassName,\
VALUE:.spec.priority,\
QOS:.status.qosClass

# Calcular uso total de un namespace
kubectl get pods -n <namespace> -o json | \
  jq '[.items[].spec.containers[].resources.requests.cpu] | add'
```

---

## Troubleshooting Tips

### Pod rechazado por ResourceQuota

```bash
# Síntoma: Error "exceeded quota"

# Verificar quota actual
kubectl describe resourcequota -n <namespace>

# Ver qué está consumiendo recursos
kubectl get pods -n <namespace> -o custom-columns=\
NAME:.metadata.name,\
CPU:.spec.containers[*].resources.requests.cpu,\
MEMORY:.spec.containers[*].resources.requests.memory

# Opciones:
# 1. Reducir requests del nuevo pod
# 2. Eliminar pods innecesarios
# 3. Aumentar quota (si apropiado)
```

### Pod rechazado por LimitRange

```bash
# Síntoma: Error "must be less than or equal to..."

# Ver LimitRange
kubectl describe limitrange -n <namespace>

# Ajustar resources del pod para cumplir:
# - requests >= min
# - limits <= max
# - limits/requests <= maxLimitRequestRatio
```

### Pod stuck en Pending - Preemption no ocurre

```bash
# Razones posibles:
# 1. preemptionPolicy: Never
# 2. No hay pods de menor prioridad que evictar
# 3. Evictar pods de menor prioridad no liberaría suficientes recursos
# 4. Pods de menor prioridad son Guaranteed y no se pueden evictar

# Ver prioridades de todos los pods
kubectl get pods -A -o custom-columns=\
NAME:.metadata.name,\
PRIORITY:.spec.priority,\
QOS:.status.qosClass,\
NODE:.spec.nodeName
```

---

## Conceptos Clave Aprendidos

### 1. ResourceQuota
- **Scope**: Namespace-level
- **Purpose**: Limitar recursos totales en namespace
- **Types**: Compute (CPU/memory), storage, object counts
- **Scopes**: BestEffort, NotBestEffort, PriorityClass

### 2. LimitRange
- **Scope**: Namespace-level
- **Purpose**: Defaults y validación para pods/containers
- **Types**: Container, Pod, PersistentVolumeClaim
- **Features**: default, defaultRequest, min, max, maxLimitRequestRatio

### 3. PriorityClass
- **Scope**: Cluster-level
- **Purpose**: Priorización de pods
- **Value**: Número (mayor = más prioritario)
- **Features**: globalDefault, preemptionPolicy
- **Preemption**: Evicción automática de pods de menor prioridad

### 4. QoS Classes
- **Guaranteed**: requests == limits (máxima estabilidad)
- **Burstable**: requests < limits (puede usar más si disponible)
- **BestEffort**: sin requests/limits (primera en evictar)

### 5. Orden de Eviction
1. QoS class (BestEffort → Burstable → Guaranteed)
2. Priority dentro de QoS class
3. Uso de recursos vs requests

---

**¡Laboratorio completado!** ✅

Has aprendido a gestionar recursos en Kubernetes usando ResourceQuotas, LimitRanges y PriorityClasses, herramientas esenciales para clusters multi-tenant y ambientes de producción con control de costos y garantías de QoS.
