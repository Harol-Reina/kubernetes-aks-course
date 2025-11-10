# Laboratorio 02: Troubleshooting de Resource Limits

## 📋 Información General

- **Duración estimada**: 45-50 minutos
- **Dificultad**: ⭐⭐ Intermedio
- **Objetivo**: Diagnosticar y resolver problemas comunes de recursos
- **Requisitos**:
  - Cluster Kubernetes 1.28+
  - `kubectl` configurado
  - `metrics-server` instalado
  - Completar **Lab 01: Fundamentos** (recomendado)

---

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

1. ✅ Detectar y diagnosticar OOMKilled (Out Of Memory)
2. ✅ Identificar CPU throttling y su impacto
3. ✅ Troubleshoot evictions por ephemeral storage
4. ✅ Analizar métricas de recursos con kubectl y Prometheus
5. ✅ Resolver problemas comunes de resource management
6. ✅ Usar eventos y logs para debugging

---

## 📚 Contexto Teórico

### Tipos de Problemas de Recursos

| Problema | Recurso | Comportamiento | Exit Code | Restart |
|----------|---------|----------------|-----------|---------|
| **OOMKilled** | Memory | Container terminado por kernel | 137 | Sí |
| **CPU Throttling** | CPU | Container lento, no termina | N/A | No |
| **Eviction** | Storage | Pod eliminado del nodo | N/A | Sí (re-schedule) |
| **Pending** | CPU/Mem | Pod no puede ser scheduled | N/A | N/A |

### Enforcement Mechanisms

```
┌─────────────────────────────────────────────────┐
│  CPU Limit Exceeded                             │
│  → cgroups THROTTLING                           │
│  → Proceso se vuelve LENTO                      │
│  → NO se termina                                │
│  → Detectable: container_cpu_cfs_throttled_*    │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Memory Limit Exceeded                          │
│  → Kernel OOM Killer                            │
│  → Proceso TERMINADO (SIGKILL)                  │
│  → Exit Code: 137                               │
│  → Container REINICIA (restartPolicy: Always)   │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Ephemeral Storage Exceeded                     │
│  → kubelet EVICTION                             │
│  → Pod ELIMINADO del nodo                       │
│  → Pod RE-SCHEDULED en otro nodo                │
│  → Detectable: kubectl get events               │
└─────────────────────────────────────────────────┘
```

---

## 🧪 Ejercicio 1: Diagnosticar OOMKilled

### Paso 1.1: Crear Pod con Memory Leak

Crea `oomkilled-demo.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: oomkilled-demo
  labels:
    lab: troubleshooting
    exercise: "1"
spec:
  restartPolicy: Always
  containers:
  - name: memory-leak
    image: polinux/stress:1.0.4
    resources:
      requests:
        memory: "50Mi"
      limits:
        memory: "100Mi"  # ← Límite bajo intencional
    command: ["stress"]
    args:
    - "--vm"
    - "1"
    - "--vm-bytes"
    - "150M"  # ← Intenta usar 150Mi (más que el límite de 100Mi)
    - "--vm-hang"
    - "0"
```

Aplica:

```bash
kubectl apply -f oomkilled-demo.yaml
```

### Paso 1.2: Observar el Comportamiento

```bash
# Ver el Pod (se reiniciará continuamente)
kubectl get pod oomkilled-demo --watch

# Salida esperada (después de ~10 segundos):
# NAME             READY   STATUS             RESTARTS   AGE
# oomkilled-demo   0/1     CrashLoopBackOff   3          1m
```

Presiona `Ctrl+C` para salir.

### Paso 1.3: Ver el Exit Code

```bash
kubectl describe pod oomkilled-demo | grep -A 10 "Last State"
```

Salida esperada:

```
Last State:     Terminated
  Reason:       OOMKilled         ◄── Killed por OOM
  Exit Code:    137               ◄── SIGKILL (128 + 9)
  Started:      Mon, 01 Jan 2024 10:00:00 +0000
  Finished:     Mon, 01 Jan 2024 10:00:05 +0000
```

**🔍 Detalles Técnicos**:

- **Exit Code 137** = 128 + 9 (SIGKILL)
- Kernel OOM Killer envía SIGKILL al proceso
- Container NO puede capturar esta señal (terminación forzada)

### Paso 1.4: Ver Restart Count

```bash
kubectl get pod oomkilled-demo -o jsonpath='{.status.containerStatuses[0].restartCount}'
# Salida: 5 (o mayor, dependiendo del tiempo)
```

### Paso 1.5: Ver Logs del Intento Fallido

```bash
# Ver logs del intento actual (puede estar vacío si falló muy rápido)
kubectl logs oomkilled-demo

# Ver logs del intento ANTERIOR
kubectl logs oomkilled-demo --previous
```

Salida esperada:

```
stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd
stress: FAIL: [1] (415) <-- worker 7 got signal 9
```

**Signal 9** = SIGKILL (OOM Killer)

### Paso 1.6: Ver Eventos

```bash
kubectl get events --field-selector involvedObject.name=oomkilled-demo --sort-by='.lastTimestamp'
```

Salida esperada:

```
LAST SEEN   TYPE      REASON      OBJECT             MESSAGE
1m          Normal    Scheduled   pod/oomkilled...   Successfully assigned...
1m          Normal    Pulling     pod/oomkilled...   Pulling image...
1m          Normal    Created     pod/oomkilled...   Created container...
1m          Normal    Started     pod/oomkilled...   Started container...
50s         Warning   BackOff     pod/oomkilled...   Back-off restarting failed container
```

### Paso 1.7: Solución

**Opción 1**: Aumentar el límite de memoria

```yaml
resources:
  limits:
    memory: "200Mi"  # ← Aumentar a 200Mi
```

**Opción 2**: Reducir el consumo de memoria de la aplicación

```yaml
args:
- "--vm-bytes"
- "80M"  # ← Reducir a 80Mi (bajo el límite)
```

**Opción 3**: Usar Vertical Pod Autoscaler (VPA)

```yaml
# Ver Lab 03 para VPA
```

### Paso 1.8: Cleanup

```bash
kubectl delete pod oomkilled-demo
```

---

## 🧪 Ejercicio 2: Detectar CPU Throttling

### Paso 2.1: Crear Pod con CPU Stress

Crea `cpu-throttling-demo.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-throttling-demo
  labels:
    lab: troubleshooting
    exercise: "2"
spec:
  containers:
  - name: cpu-stress
    image: polinux/stress:1.0.4
    resources:
      requests:
        cpu: "100m"
      limits:
        cpu: "500m"  # ← Límite bajo
    command: ["stress"]
    args:
    - "--cpu"
    - "2"  # ← Intenta usar 2 CPUs (más que el límite de 0.5)
```

Aplica:

```bash
kubectl apply -f cpu-throttling-demo.yaml
```

### Paso 2.2: Monitorear CPU Usage

```bash
kubectl top pod cpu-throttling-demo --watch
```

Salida esperada:

```
NAME                  CPU(cores)   MEMORY(bytes)
cpu-throttling-demo   499m         5Mi
```

**🔍 Observación**: El Pod está "stuck" en ~500m (el límite), intentando usar más pero siendo throttled.

Presiona `Ctrl+C` para salir.

### Paso 2.3: Verificar Throttling Stats (Dentro del Container)

```bash
kubectl exec -it cpu-throttling-demo -- cat /sys/fs/cgroup/cpu/cpu.stat
```

Salida esperada:

```
nr_periods 1500           # Total de períodos (100ms cada uno)
nr_throttled 1200         # Períodos donde fue throttled
throttled_time 85000000   # Tiempo total throttled (nanosegundos)
```

**📊 Análisis**:

- **nr_throttled / nr_periods** = 1200 / 1500 = **80%**
- El container fue throttled **80% del tiempo**!
- Esto significa que la aplicación está ejecutándose **MUY lenta**

### Paso 2.4: Ver Comportamiento del Container

```bash
# Ver logs (debería ser lento para generar output)
kubectl logs cpu-throttling-demo
```

Salida esperada:

```
stress: info: [1] dispatching hogs: 2 cpu, 0 io, 0 vm, 0 hdd
```

**❓ ¿Por qué el Pod NO se termina (a diferencia de OOMKilled)?**

<details>
<summary>Respuesta</summary>

Porque CPU throttling **NO termina el proceso**, solo lo hace más lento:

- Memory limit → **OOMKilled** (terminado)
- CPU limit → **Throttling** (solo lento)

El kernel usa **cgroups** para limitar el tiempo de CPU disponible, pero el proceso sigue corriendo.
</details>

### Paso 2.5: Comparar con Pod Sin Límite

Crea `cpu-no-throttling.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-no-throttling
  labels:
    lab: troubleshooting
    exercise: "2"
spec:
  containers:
  - name: cpu-stress
    image: polinux/stress:1.0.4
    resources:
      requests:
        cpu: "100m"
      # Sin límite de CPU
    command: ["stress"]
    args:
    - "--cpu"
    - "2"
```

Aplica:

```bash
kubectl apply -f cpu-no-throttling.yaml
```

Ver uso:

```bash
kubectl top pod cpu-no-throttling
```

Salida esperada:

```
NAME                 CPU(cores)   MEMORY(bytes)
cpu-no-throttling    1950m        5Mi
```

**📊 Comparación**:

| Pod | CPU Limit | CPU Usado | Throttled |
|-----|-----------|-----------|-----------|
| cpu-throttling-demo | 500m | ~500m | ✅ Sí (80%) |
| cpu-no-throttling | None | ~1950m | ❌ No |

### Paso 2.6: Detectar Throttling con Prometheus (Opcional)

Si tienes Prometheus instalado:

```promql
# Query para ver throttling rate
rate(container_cpu_cfs_throttled_seconds_total{pod="cpu-throttling-demo"}[5m])

# Query para ver porcentaje de throttling
rate(container_cpu_cfs_throttled_periods_total{pod="cpu-throttling-demo"}[5m]) / 
rate(container_cpu_cfs_periods_total{pod="cpu-throttling-demo"}[5m]) * 100
```

### Paso 2.7: Solución

**Opción 1**: Aumentar el límite de CPU

```yaml
resources:
  limits:
    cpu: "2"  # ← Aumentar a 2 CPUs
```

**Opción 2**: Reducir la carga de CPU

```yaml
args:
- "--cpu"
- "1"  # ← Solo 1 CPU (bajo el límite)
```

**Opción 3**: Remover el límite (solo requests)

```yaml
resources:
  requests:
    cpu: "500m"
  # Sin límite (puede usar lo que necesite)
```

**Opción 4**: Horizontal Pod Autoscaler (HPA)

```bash
kubectl autoscale deployment <name> --cpu-percent=70 --min=2 --max=10
```

### Paso 2.8: Cleanup

```bash
kubectl delete pod cpu-throttling-demo cpu-no-throttling
```

---

## 🧪 Ejercicio 3: Troubleshoot Ephemeral Storage Eviction

### Paso 3.1: Crear Pod con Ephemeral Storage Limit

Crea `storage-eviction-demo.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-eviction-demo
  labels:
    lab: troubleshooting
    exercise: "3"
spec:
  containers:
  - name: writer
    image: busybox:1.36
    resources:
      requests:
        ephemeral-storage: "100Mi"
      limits:
        ephemeral-storage: "200Mi"  # ← Límite bajo
    command: 
    - sh
    - -c
    - |
      echo "Writing 250MB to exceed limit..."
      dd if=/dev/zero of=/cache/bigfile bs=1M count=250
      sleep 3600
    volumeMounts:
    - name: cache
      mountPath: /cache
  
  volumes:
  - name: cache
    emptyDir:
      sizeLimit: "200Mi"  # ← Best practice: siempre usar sizeLimit
```

Aplica:

```bash
kubectl apply -f storage-eviction-demo.yaml
```

### Paso 3.2: Observar Eviction

```bash
kubectl get pod storage-eviction-demo --watch
```

Salida esperada (después de ~30 segundos):

```
NAME                     READY   STATUS    RESTARTS   AGE
storage-eviction-demo    1/1     Running   0          5s
storage-eviction-demo    0/1     Evicted   0          35s
```

### Paso 3.3: Ver Razón de Eviction

```bash
kubectl describe pod storage-eviction-demo | grep -A 10 "Status:"
```

Salida esperada:

```
Status:  Failed
Reason:  Evicted
Message: Pod ephemeral local storage usage exceeds the total limit of containers 200Mi
```

### Paso 3.4: Ver Eventos de Eviction

```bash
kubectl get events --field-selector reason=Evicted --sort-by='.lastTimestamp'
```

Salida esperada:

```
LAST SEEN   TYPE      REASON    OBJECT                      MESSAGE
30s         Warning   Evicted   pod/storage-eviction-demo   Pod ephemeral local storage usage exceeds...
```

### Paso 3.5: Ver Todos los Pods Evicted

```bash
kubectl get pods --field-selector=status.phase=Failed
```

Salida esperada:

```
NAME                    READY   STATUS    RESTARTS   AGE
storage-eviction-demo   0/1     Evicted   0          2m
```

### Paso 3.6: Cleanup de Pods Evicted

```bash
# Limpiar UN Pod evicted
kubectl delete pod storage-eviction-demo

# Limpiar TODOS los Pods evicted en el namespace
kubectl delete pods --field-selector=status.phase=Failed

# Limpiar TODOS los Pods evicted en el clúster
kubectl delete pods --all-namespaces --field-selector=status.phase=Failed
```

### Paso 3.7: Solución

**Opción 1**: Aumentar el límite de ephemeral storage

```yaml
resources:
  limits:
    ephemeral-storage: "500Mi"
volumes:
- name: cache
  emptyDir:
    sizeLimit: "500Mi"
```

**Opción 2**: Usar PersistentVolume en lugar de emptyDir

```yaml
volumes:
- name: data
  persistentVolumeClaim:
    claimName: my-pvc
```

**Opción 3**: Limpiar archivos temporales periódicamente

```yaml
command:
- sh
- -c
- |
  while true; do
    # Tu aplicación
    find /cache -type f -mtime +1 -delete  # Limpiar archivos viejos
    sleep 3600
  done
```

---

## 🧪 Ejercicio 4: Troubleshoot Pending Pods

### Paso 4.1: Crear Deployment con Requests Muy Altos

Crea `pending-demo.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pending-demo
  labels:
    lab: troubleshooting
    exercise: "4"
spec:
  replicas: 10
  selector:
    matchLabels:
      app: overrequest
  template:
    metadata:
      labels:
        app: overrequest
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        resources:
          requests:
            cpu: "4"        # ← Request MUY alto (4 CPUs por Pod)
            memory: "4Gi"   # ← Request MUY alto (4Gi por Pod)
          limits:
            cpu: "4"
            memory: "4Gi"
```

Aplica:

```bash
kubectl apply -f pending-demo.yaml
```

### Paso 4.2: Ver Pods Pending

```bash
kubectl get pods -l app=overrequest
```

Salida esperada:

```
NAME                           READY   STATUS    RESTARTS   AGE
pending-demo-5c7d9f8b7-abcde   1/1     Running   0          1m
pending-demo-5c7d9f8b7-fghij   0/1     Pending   0          1m
pending-demo-5c7d9f8b7-klmno   0/1     Pending   0          1m
pending-demo-5c7d9f8b7-pqrst   0/1     Pending   0          1m
...
```

### Paso 4.3: Diagnosticar por qué están Pending

```bash
kubectl describe pod <pending-pod-name> | grep -A 10 "Events:"
```

Salida esperada:

```
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  30s   default-scheduler  0/3 nodes are available: 
           3 Insufficient cpu, 3 Insufficient memory.
```

**🔍 Diagnóstico**: El scheduler NO puede encontrar un nodo con suficiente CPU y memoria.

### Paso 4.4: Ver Recursos Disponibles en Nodos

```bash
kubectl describe nodes | grep -A 10 "Allocatable:"
```

Salida ejemplo:

```
Allocatable:
  cpu:                4
  memory:             8Gi
```

**📊 Análisis**:

- Cada Pod pide: 4 CPU + 4Gi memory
- Nodo tiene: 4 CPU + 8Gi memory
- Solo caben **1-2 Pods por nodo**
- Los demás Pods quedan **Pending**

### Paso 4.5: Ver Qué Recursos Están Consumidos

```bash
kubectl describe node <node-name> | grep -A 10 "Allocated resources:"
```

Salida ejemplo:

```
Allocated resources:
  Resource           Requests      Limits
  --------           --------      ------
  cpu                4000m (100%)  4000m (100%)
  memory             4Gi (50%)     4Gi (50%)
```

### Paso 4.6: Solución

**Opción 1**: Reducir requests

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
```

**Opción 2**: Reducir número de replicas

```yaml
spec:
  replicas: 2  # ← Reducir a lo que cabe
```

**Opción 3**: Agregar más nodos al clúster

```bash
# Ejemplo con minikube
minikube node add

# Ejemplo con cloud provider
# kubectl scale --replicas=5 deployment/cluster-autoscaler
```

### Paso 4.7: Cleanup

```bash
kubectl delete deployment pending-demo
```

---

## 🧪 Ejercicio 5: Usar Métricas para Troubleshooting

### Paso 5.1: Crear Deployment para Monitoreo

Crea `metrics-demo.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-demo
  labels:
    lab: troubleshooting
    exercise: "5"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webserver
  template:
    metadata:
      labels:
        app: webserver
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        resources:
          requests:
            cpu: "100m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
```

Aplica:

```bash
kubectl apply -f metrics-demo.yaml
```

### Paso 5.2: Ver Uso por Pod

```bash
kubectl top pods -l app=webserver
```

Salida esperada:

```
NAME                           CPU(cores)   MEMORY(bytes)
metrics-demo-5c7d9f8b7-abcde   2m           15Mi
metrics-demo-5c7d9f8b7-fghij   2m           15Mi
metrics-demo-5c7d9f8b7-klmno   2m           14Mi
```

### Paso 5.3: Ver Uso por Contenedor

```bash
kubectl top pods -l app=webserver --containers
```

Salida esperada:

```
POD                            NAME    CPU(cores)   MEMORY(bytes)
metrics-demo-5c7d9f8b7-abcde   nginx   2m           15Mi
metrics-demo-5c7d9f8b7-fghij   nginx   2m           15Mi
metrics-demo-5c7d9f8b7-klmno   nginx   2m           14Mi
```

### Paso 5.4: Calcular Utilización de Recursos

```bash
# Ver recursos asignados
kubectl describe deployment metrics-demo | grep -A 10 "Requests:"

# Calcular utilización
# CPU: 2m / 100m = 2%
# Memory: 15Mi / 64Mi = 23%
```

**📊 Análisis**:

- **CPU**: Usando 2m de 100m request = **2% utilización** → Mucho over-provisioning
- **Memory**: Usando 15Mi de 64Mi request = **23% utilización** → Over-provisioning

**💡 Recomendación**: Reducir requests a:

```yaml
resources:
  requests:
    cpu: "10m"     # ← Reducir de 100m
    memory: "32Mi" # ← Reducir de 64Mi
```

### Paso 5.5: Ver Uso de Todos los Nodos

```bash
kubectl top nodes
```

Salida esperada:

```
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   450m         11%    2Gi             25%
```

### Paso 5.6: Cleanup

```bash
kubectl delete deployment metrics-demo
```

---

## 🧪 Ejercicio 6: Caso Práctico Completo

### Escenario

Tienes una aplicación en producción que está experimentando:
- Reinicios frecuentes
- Lentitud intermitente
- Algunos Pods en estado Pending

### Paso 6.1: Desplegar la Aplicación Problemática

Crea `problem-app.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: problem-app
  labels:
    lab: troubleshooting
    exercise: "6"
spec:
  replicas: 5
  selector:
    matchLabels:
      app: problem
  template:
    metadata:
      labels:
        app: problem
    spec:
      containers:
      # App principal con memory leak
      - name: app
        image: polinux/stress:1.0.4
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "200m"
            memory: "100Mi"
        command: ["stress"]
        args:
        - "--vm"
        - "1"
        - "--vm-bytes"
        - "120M"  # ← Excede el límite (OOMKilled)
      
      # Sidecar con CPU stress
      - name: logger
        image: polinux/stress:1.0.4
        resources:
          requests:
            cpu: "50m"
            memory: "32Mi"
          limits:
            cpu: "100m"
            memory: "64Mi"
        command: ["stress"]
        args:
        - "--cpu"
        - "2"  # ← Causa throttling
```

Aplica:

```bash
kubectl apply -f problem-app.yaml
```

### Paso 6.2: Investigación Inicial

```bash
# Ver estado de los Pods
kubectl get pods -l app=problem

# Ver eventos recientes
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

**❓ ¿Qué problemas observas?**

<details>
<summary>Respuesta</summary>

1. **CrashLoopBackOff**: Algunos Pods reiniciando continuamente
2. **Pending**: Algunos Pods no pueden ser scheduled
3. **Running pero lento**: Algunos Pods throttled
</details>

### Paso 6.3: Diagnosticar OOMKilled

```bash
# Ver Pods con restart count alto
kubectl get pods -l app=problem -o custom-columns=\
NAME:.metadata.name,\
RESTARTS:.status.containerStatuses[0].restartCount

# Describir un Pod problemático
kubectl describe pod <pod-name> | grep -A 10 "Last State"
```

### Paso 6.4: Diagnosticar CPU Throttling

```bash
# Ver uso de CPU
kubectl top pods -l app=problem --containers
```

Observarás que el contenedor `logger` está stuck en ~100m (su límite).

### Paso 6.5: Diagnosticar Pending Pods

```bash
kubectl describe pod <pending-pod> | grep -A 5 "Events:"
```

### Paso 6.6: Aplicar Soluciones

Crea `problem-app-fixed.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: problem-app-fixed
  labels:
    lab: troubleshooting
    exercise: "6"
spec:
  replicas: 3  # ← Reducir replicas
  selector:
    matchLabels:
      app: problem-fixed
  template:
    metadata:
      labels:
        app: problem-fixed
    spec:
      containers:
      # App principal - FIX: aumentar límite de memoria
      - name: app
        image: nginx:1.25  # ← Cambiar a app real sin leak
        resources:
          requests:
            cpu: "100m"
            memory: "64Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"  # ← Aumentado
      
      # Sidecar - FIX: aumentar límite de CPU o reducir carga
      - name: logger
        image: busybox:1.36  # ← Cambiar a app real
        command: ['sh', '-c', 'tail -f /dev/null']
        resources:
          requests:
            cpu: "10m"      # ← Reducido
            memory: "16Mi"
          limits:
            cpu: "50m"      # ← Reducido
            memory: "32Mi"
```

Aplica:

```bash
kubectl apply -f problem-app-fixed.yaml
```

Verifica:

```bash
kubectl get pods -l app=problem-fixed
kubectl top pods -l app=problem-fixed --containers
```

### Paso 6.7: Cleanup

```bash
kubectl delete deployment problem-app problem-app-fixed
```

---

## 📊 Troubleshooting Checklist

### Cuando un Pod está CrashLoopBackOff

```bash
# 1. Ver restart count
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].restartCount}'

# 2. Ver exit code
kubectl describe pod <pod-name> | grep -A 10 "Last State"

# 3. Si Exit Code = 137 → OOMKilled
kubectl logs <pod-name> --previous

# 4. Ver recursos
kubectl describe pod <pod-name> | grep -A 10 "Limits:"

# 5. Aumentar límite de memoria
kubectl edit deployment <deployment-name>
```

### Cuando un Pod está Lento

```bash
# 1. Ver CPU usage
kubectl top pod <pod-name> --containers

# 2. Si CPU stuck en el límite → throttling
kubectl exec -it <pod-name> -- cat /sys/fs/cgroup/cpu/cpu.stat

# 3. Calcular % throttled
# nr_throttled / nr_periods * 100

# 4. Aumentar límite de CPU o remover límite
kubectl edit deployment <deployment-name>
```

### Cuando un Pod está Pending

```bash
# 1. Ver razón
kubectl describe pod <pod-name> | grep -A 10 "Events:"

# 2. Si "Insufficient cpu/memory" → ver nodos
kubectl describe nodes | grep -A 10 "Allocatable:"

# 3. Ver qué Pods están usando recursos
kubectl get pods -o custom-columns=\
NAME:.metadata.name,\
CPU_REQ:.spec.containers[0].resources.requests.cpu,\
MEM_REQ:.spec.containers[0].resources.requests.memory

# 4. Reducir requests o agregar nodos
```

### Cuando un Pod fue Evicted

```bash
# 1. Ver razón de eviction
kubectl describe pod <pod-name> | grep -A 5 "Message:"

# 2. Si "ephemeral storage" → ver uso
kubectl exec -it <pod-name> -- df -h

# 3. Ver eventos de eviction
kubectl get events --field-selector reason=Evicted

# 4. Aumentar límite o limpiar archivos
```

---

## 🎓 Resumen de Patrones de Troubleshooting

### OOMKilled Pattern

```
Síntomas:
- CrashLoopBackOff
- Restart count alto
- Exit Code: 137

Diagnóstico:
kubectl describe pod | grep "Last State"
kubectl logs --previous

Solución:
- Aumentar memory limit
- Optimizar aplicación (fix memory leak)
- Usar VPA
```

### CPU Throttling Pattern

```
Síntomas:
- Pod lento pero no crashea
- CPU usage stuck en el límite
- No aumenta con load

Diagnóstico:
kubectl top pod --containers
kubectl exec -- cat /sys/fs/cgroup/cpu/cpu.stat

Solución:
- Aumentar CPU limit
- Remover límite (solo requests)
- Usar HPA para escalar horizontalmente
```

### Eviction Pattern

```
Síntomas:
- Pod status: Evicted
- Pod re-scheduled en otro nodo

Diagnóstico:
kubectl get events --field-selector reason=Evicted
kubectl describe pod | grep "Message:"

Solución:
- Aumentar ephemeral-storage limit
- Usar sizeLimit en emptyDir
- Limpiar archivos periódicamente
- Usar PersistentVolume
```

### Pending Pattern

```
Síntomas:
- Pod status: Pending (no Running)
- No se asigna a ningún nodo

Diagnóstico:
kubectl describe pod | grep "Events:"
kubectl describe nodes | grep "Allocatable:"

Solución:
- Reducir requests
- Reducir número de replicas
- Agregar más nodos
- Usar Cluster Autoscaler
```

---

## 📚 Próximos Pasos

Ahora que dominas troubleshooting, continúa con:

1. **[Laboratorio 03: Producción](./lab-03-produccion.md)**: Best practices, VPA, HPA, Prometheus monitoring

---

## 📖 Referencias

- **[README Principal](../README.md)**: Documentación completa
- **[Lab 01: Fundamentos](./lab-01-fundamentos.md)**: Conceptos básicos
- **[Ejemplos Troubleshooting](../ejemplos/)**: Manifiestos de referencia
- **[Kubernetes Docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)**: Documentación oficial

---

**¡Felicidades!** 🎉 Has completado el laboratorio de troubleshooting de Resource Limits.
