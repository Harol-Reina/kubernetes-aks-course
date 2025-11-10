# Ejemplos Prácticos - Resource Limits en Pods

Este directorio contiene ejemplos completos y bien documentados sobre gestión de recursos en Kubernetes.

## 📑 Índice de Ejemplos

| # | Nombre | Archivo | Conceptos | Dificultad |
|---|--------|---------|-----------|------------|
| 1 | Requests y Limits Básicos | [01-basico/requests-limits-basic.yaml](./01-basico/requests-limits-basic.yaml) | Requests, Limits, Multi-container, Init containers | ⭐ Básico |
| 2 | Quality of Service Classes | [02-qos/qos-classes.yaml](./02-qos/qos-classes.yaml) | Guaranteed, Burstable, BestEffort | ⭐⭐ Intermedio |
| 3 | Ephemeral Storage | [03-ephemeral/ephemeral-storage.yaml](./03-ephemeral/ephemeral-storage.yaml) | emptyDir, sizeLimit, tmpfs, eviction | ⭐⭐ Intermedio |
| 4 | Pod-level Resources | [04-pod-level/pod-level-resources.yaml](./04-pod-level/pod-level-resources.yaml) | Feature beta K8s 1.34, resource sharing | ⭐⭐⭐ Avanzado |
| 5 | Extended Resources | [05-extended/extended-resources.yaml](./05-extended/extended-resources.yaml) | GPUs, custom resources | ⭐⭐ Intermedio |
| 6 | OOMKilled Simulation | [06-troubleshooting/oomkilled-simulation.yaml](./06-troubleshooting/oomkilled-simulation.yaml) | Memory leak, OOMKilled, troubleshooting | ⭐⭐ Intermedio |
| 7 | CPU Throttling | [07-troubleshooting/cpu-throttling.yaml](./07-troubleshooting/cpu-throttling.yaml) | CPU stress, throttling, HPA | ⭐⭐⭐ Avanzado |

---

## 🎯 Learning Paths

### Path 1: Fundamentos (Para principiantes)
Aprende los conceptos básicos de resource management:

```bash
# 1. Conceptos básicos
kubectl apply -f 01-basico/requests-limits-basic.yaml
kubectl get pods -l example=basic-resources
kubectl top pod requests-limits-basic

# 2. Entender QoS Classes
kubectl apply -f 02-qos/qos-classes.yaml
kubectl get pods -l example=qos-demo -o custom-columns=\
NAME:.metadata.name,\
QoS:.status.qosClass

# 3. Ver comportamiento
kubectl describe pod qos-guaranteed
kubectl describe pod qos-burstable-flexible
kubectl describe pod qos-besteffort
```

**Tiempo estimado**: 30 minutos  
**Requisitos**: Cluster Kubernetes básico

### Path 2: Troubleshooting (Para administradores)
Aprende a diagnosticar y resolver problemas comunes:

```bash
# 1. Simular OOMKilled
kubectl apply -f 06-troubleshooting/oomkilled-simulation.yaml
kubectl get pod oomkilled-demo --watch

# Esperar ~30 segundos y observar
kubectl describe pod oomkilled-demo | grep -A 10 "Last State"

# 2. Detectar CPU Throttling
kubectl apply -f 07-troubleshooting/cpu-throttling.yaml
kubectl top pod cpu-throttling-demo --watch

# 3. Verificar ephemeral storage
kubectl apply -f 03-ephemeral/ephemeral-storage.yaml
kubectl logs -f ephemeral-monitor -c monitor
```

**Tiempo estimado**: 45 minutos  
**Requisitos**: metrics-server instalado

### Path 3: Producción (Para arquitectos)
Configuraciones avanzadas para ambientes productivos:

```bash
# 1. Pod-level resources (K8s 1.34+)
kubectl apply -f 04-pod-level/pod-level-resources.yaml
kubectl describe pod pod-level-hybrid | grep -A 20 "Resources"

# 2. Extended resources (requiere device plugins)
kubectl describe node | grep -i "nvidia.com/gpu"
kubectl apply -f 05-extended/extended-resources.yaml

# 3. Deployment con best practices
kubectl apply -f 03-ephemeral/ephemeral-storage.yaml
kubectl get deployment web-app-with-storage -o yaml
```

**Tiempo estimado**: 60 minutos  
**Requisitos**: K8s 1.34+, device plugins (opcional)

---

## 📚 Descripción Detallada de Ejemplos

### 1. Requests y Limits Básicos
**Archivo**: `01-basico/requests-limits-basic.yaml`

**Qué aprenderás**:
- Diferencia entre requests y limits
- QoS Class: Burstable
- Pods con múltiples contenedores
- Init containers con recursos
- Solo requests (sin limits)
- Solo limits (sin requests)
- Ephemeral storage básico

**Ejemplos incluidos**:
- ✅ Pod básico con requests/limits
- ✅ Multi-container resource allocation
- ✅ Init containers (regla del máximo)
- ✅ Request-only configuration
- ✅ Limit-only configuration (auto-copy)
- ✅ Ephemeral storage demo

**Comandos clave**:
```bash
kubectl apply -f 01-basico/requests-limits-basic.yaml
kubectl get pods -l example
kubectl describe pod requests-limits-basic
kubectl get pod requests-limits-basic -o jsonpath='{.status.qosClass}'
kubectl top pod requests-limits-basic
```

---

### 2. Quality of Service (QoS) Classes
**Archivo**: `02-qos/qos-classes.yaml`

**Qué aprenderás**:
- QoS Class: Guaranteed
- QoS Class: Burstable (3 variantes)
- QoS Class: BestEffort
- Orden de eviction bajo presión de recursos
- Comparación directa de comportamiento

**Ejemplos incluidos**:
- ✅ Guaranteed Pod (request == limit)
- ✅ Burstable flexible (request < limit)
- ✅ Burstable request-only (sin limits)
- ✅ Burstable mixed (contenedores mixtos)
- ✅ BestEffort (sin resources)
- ✅ Deployment con comparación

**Orden de Eviction**:
```
1. BestEffort  ◄── Se eliminan PRIMERO
2. Burstable   ◄── Prioridad media
3. Guaranteed  ◄── Se eliminan ÚLTIMO (máxima protección)
```

**Comandos clave**:
```bash
kubectl apply -f 02-qos/qos-classes.yaml
kubectl get pods -l example=qos-demo -o custom-columns=\
NAME:.metadata.name,QoS:.status.qosClass
```

---

### 3. Ephemeral Storage
**Archivo**: `03-ephemeral/ephemeral-storage.yaml`

**Qué aprenderás**:
- emptyDir con sizeLimit (✅ best practice)
- emptyDir sin sizeLimit (⚠️ peligroso)
- tmpfs (memory-backed)
- Múltiples emptyDir en un Pod
- Monitoreo de uso de storage
- Eviction por exceso de storage

**Ejemplos incluidos**:
- ✅ emptyDir con sizeLimit seguro
- ⚠️ emptyDir sin límite (demo)
- ✅ tmpfs (cuenta como memoria, no storage)
- ✅ Múltiples volúmenes con límites
- ✅ Pod de monitoreo de storage
- 🔥 Demo de eviction intencional
- ✅ Deployment con best practices

**⚠️ Importante**:
```yaml
# tmpfs NO cuenta como ephemeral-storage
emptyDir:
  medium: Memory  # ← Usa RAM, cuenta como memory usage

# emptyDir regular SÍ cuenta
emptyDir:
  sizeLimit: "1Gi"  # ← Cuenta como ephemeral-storage
```

**Comandos clave**:
```bash
kubectl apply -f 03-ephemeral/ephemeral-storage.yaml
kubectl logs -f ephemeral-monitor -c monitor
kubectl exec -it emptydir-with-sizelimit -- df -h /cache
kubectl get events --field-selector reason=Evicted
```

---

### 4. Pod-level Resources (Beta K8s 1.34+)
**Archivo**: `04-pod-level/pod-level-resources.yaml`

**Qué aprenderás**:
- Feature gate `PodLevelResources`
- Especificar presupuesto total del Pod
- Resource sharing entre contenedores
- Combinación Pod-level + Container-level

**Ejemplos incluidos**:
- ✅ Solo Pod-level (contenedores comparten)
- ✅ Híbrido (app con límite + sidecars sin límite)
- ✅ Deployment multi-sidecar

**⚠️ Requisitos**:
- Kubernetes 1.34+
- Feature gate `PodLevelResources=true` (default en 1.34)

**Ventajas**:
- ✅ Simplifica configuración con muchos sidecars
- ✅ Mejor utilización de recursos idle
- ✅ Reduce over-provisioning

**Comandos clave**:
```bash
kubectl apply -f 04-pod-level/pod-level-resources.yaml
kubectl describe pod pod-level-basic | grep -A 10 "Resources"
kubectl top pod pod-level-hybrid --containers
```

---

### 5. Extended Resources
**Archivo**: `05-extended/extended-resources.yaml`

**Qué aprenderás**:
- Solicitar GPUs NVIDIA
- Solicitar GPUs AMD
- Custom extended resources

**Ejemplos incluidos**:
- ✅ NVIDIA GPU request
- ✅ AMD GPU request
- ✅ Custom resources (FPGA, dongles)

**⚠️ Requisitos**:
- Device plugin instalado en el nodo
- Nodo debe anunciar el recurso

**Instalación NVIDIA GPU Device Plugin**:
```bash
kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/main/nvidia-device-plugin.yml
```

**Verificar recursos disponibles**:
```bash
kubectl describe node | grep -i "nvidia.com/gpu"
```

**Comandos clave**:
```bash
kubectl apply -f 05-extended/extended-resources.yaml
kubectl describe pod gpu-pod-nvidia
```

---

### 6. OOMKilled Simulation
**Archivo**: `06-troubleshooting/oomkilled-simulation.yaml`

**Qué aprenderás**:
- Simular memory leak
- Observar comportamiento de OOMKilled
- Detectar Exit Code 137
- Analizar restart count
- CrashLoopBackOff

**Ejemplos incluidos**:
- 🔥 Memory leak intencional (stress)
- 🔥 Memory leak gradual (script)

**Comportamiento esperado**:
```
1. Container intenta usar más memoria que el límite
2. Kernel OOM Killer detecta exceso
3. Proceso terminado con SIGKILL
4. Exit Code: 137
5. Pod reinicia (restartPolicy: Always)
6. Si falla repetidamente → CrashLoopBackOff
```

**⚠️ SOLO PARA TESTING** - No usar en producción

**Comandos clave**:
```bash
kubectl apply -f 06-troubleshooting/oomkilled-simulation.yaml
kubectl get pod oomkilled-demo --watch

# Esperar ~30 segundos
kubectl describe pod oomkilled-demo | grep -A 10 "Last State"
# Reason: OOMKilled
# Exit Code: 137

kubectl get pod oomkilled-demo -o jsonpath='{.status.containerStatuses[0].restartCount}'
kubectl logs oomkilled-demo --previous
```

---

### 7. CPU Throttling
**Archivo**: `07-troubleshooting/cpu-throttling.yaml`

**Qué aprenderás**:
- Simular carga de CPU
- Detectar throttling
- Comparar con y sin throttling
- Alternativa: Horizontal Pod Autoscaler

**Ejemplos incluidos**:
- 🔥 CPU stress con límite bajo (throttled)
- ✅ Comparación throttled vs not-throttled
- ✅ Deployment con HPA

**Comportamiento de Throttling**:
```
- Intenta usar 2 CPUs
- Límite: 0.5 CPU
- Kernel throttles el proceso
- CPU usage stuck en ~500m
- Aplicación se vuelve lenta
- NO se termina (diferente a OOMKill)
```

**Detectar Throttling**:
```bash
# Ver CPU usage (stuck en el límite)
kubectl top pod cpu-throttling-demo

# Ver stats de throttling (dentro del contenedor)
kubectl exec -it cpu-throttling-demo -- cat /sys/fs/cgroup/cpu/cpu.stat
# nr_throttled: 800  # ← 80% del tiempo throttled!

# Con Prometheus
rate(container_cpu_cfs_throttled_seconds_total{pod="cpu-throttling-demo"}[5m])
```

**⚠️ SOLO PARA TESTING**

**Comandos clave**:
```bash
kubectl apply -f 07-troubleshooting/cpu-throttling.yaml
kubectl top pod cpu-throttling-demo --watch
kubectl top pod cpu-comparison --containers
```

---

## 🛠️ Casos de Uso Prácticos

### Caso 1: Aplicación Web (Burstable)
**Escenario**: API REST con tráfico variable

```yaml
# Usar: 01-basico/requests-limits-basic.yaml
resources:
  requests:
    cpu: "250m"
    memory: "128Mi"
  limits:
    cpu: "1"
    memory: "512Mi"
```

**Por qué**:
- Request bajo → scheduler puede colocar más Pods
- Limit alto → puede manejar picos de tráfico
- QoS: Burstable (balance costo/flexibilidad)

### Caso 2: Base de Datos (Guaranteed)
**Escenario**: PostgreSQL en producción

```yaml
# Usar: 02-qos/qos-classes.yaml (qos-guaranteed)
resources:
  requests:
    cpu: "2"
    memory: "4Gi"
  limits:
    cpu: "2"
    memory: "4Gi"
```

**Por qué**:
- Request == Limit → QoS Guaranteed
- Máxima protección contra eviction
- Rendimiento predecible

### Caso 3: Batch Jobs (BestEffort)
**Escenario**: Procesamiento batch no crítico

```yaml
# Usar: 02-qos/qos-classes.yaml (qos-besteffort)
# Sin resources definidos
```

**Por qué**:
- No reserva recursos → más Pods en el clúster
- Puede usar recursos idle
- Se evicted primero (aceptable para batch jobs)

### Caso 4: Multi-Sidecar App (Pod-level)
**Escenario**: App con 4+ sidecars (service mesh, logging, etc.)

```yaml
# Usar: 04-pod-level/pod-level-resources.yaml
spec:
  resources:
    limits:
      cpu: "3"
      memory: "3Gi"
  # Todos los contenedores comparten
```

**Por qué**:
- Difícil calcular recursos para cada sidecar
- Sidecars comparten recursos idle
- Menos over-provisioning

---

## 📊 Comandos Útiles

### Monitoreo

```bash
# Ver uso de recursos de todos los Pods
kubectl top pods --all-namespaces

# Ver uso de recursos de un Pod con contenedores
kubectl top pod <pod-name> --containers

# Ver uso de recursos de nodos
kubectl top nodes

# Ver recursos asignados en un nodo
kubectl describe node <node-name> | grep -A 10 "Allocated resources"
```

### Troubleshooting

```bash
# Ver QoS Class de un Pod
kubectl get pod <pod-name> -o jsonpath='{.status.qosClass}'

# Ver eventos de un Pod
kubectl get events --field-selector involvedObject.name=<pod-name>

# Ver logs del contenedor anterior (tras crash)
kubectl logs <pod-name> --previous

# Ver restart count
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].restartCount}'

# Ver Pods evicted
kubectl get pods --field-selector=status.phase=Failed

# Ver eventos de eviction
kubectl get events --all-namespaces | grep -i evict

# Ver eventos de OOMKilled
kubectl get events --all-namespaces --field-selector reason=OOMKilled
```

### Análisis

```bash
# Ver recursos de todos los Pods en formato customizado
kubectl get pods -o custom-columns=\
NAME:.metadata.name,\
CPU_REQ:.spec.containers[0].resources.requests.cpu,\
CPU_LIM:.spec.containers[0].resources.limits.cpu,\
MEM_REQ:.spec.containers[0].resources.requests.memory,\
MEM_LIM:.spec.containers[0].resources.limits.memory,\
QoS:.status.qosClass

# Contar Pods por QoS class
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[].status.qosClass' | sort | uniq -c

# Ver Pods con restart count alto
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] | select(.status.containerStatuses[].restartCount > 5) | 
  "\(.metadata.namespace)/\(.metadata.name): \(.status.containerStatuses[].restartCount) restarts"'
```

---

## 🧹 Limpieza

```bash
# Limpiar ejemplos individuales
kubectl delete -f 01-basico/requests-limits-basic.yaml
kubectl delete -f 02-qos/qos-classes.yaml
kubectl delete -f 03-ephemeral/ephemeral-storage.yaml
kubectl delete -f 04-pod-level/pod-level-resources.yaml
kubectl delete -f 05-extended/extended-resources.yaml
kubectl delete -f 06-troubleshooting/oomkilled-simulation.yaml
kubectl delete -f 07-troubleshooting/cpu-throttling.yaml

# Limpiar TODOS los ejemplos
kubectl delete pods,deployments -l example
```

---

## 📖 Referencias

- **[README Principal](../README.md)**: Documentación completa del módulo
- **[Laboratorios](../laboratorios/)**: Ejercicios prácticos guiados
- **[Kubernetes Docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)**: Documentación oficial

---

**Última actualización**: Noviembre 2025  
**Versión**: Kubernetes 1.28+
