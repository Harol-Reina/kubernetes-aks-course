# Laboratorio 02: Troubleshooting de Resource Limits

**Duracion estimada:** 45-50 minutos
**Nivel:** Intermedio
**Objetivo:** Diagnosticar y resolver los problemas mas comunes de gestion de recursos en Pods

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **OOMKilled (Exit Code 137)** | El kernel OOM Killer termina el proceso cuando el contenedor excede su memory limit. Causa CrashLoopBackOff con restart count creciente. Detectable con `kubectl describe pod` en el campo "Last State" |
| **CPU Throttling** | cgroups CFS limita el tiempo de CPU disponible cuando se supera el CPU limit. El proceso sigue ejecutandose pero a velocidad reducida. Detectable via `/sys/fs/cgroup/cpu/cpu.stat` |
| **Ephemeral Storage Eviction** | El kubelet evicta el Pod del nodo cuando supera el limite de ephemeral-storage o el sizeLimit de un emptyDir. El Pod queda en estado Failed/Evicted, no reinicia |
| **Pods en Pending** | El scheduler no puede asignar el Pod a ningun nodo porque los requests declarados superan los recursos Allocatable disponibles. Diagnostico: `kubectl describe pod` seccion Events |
| **kubectl top** | Muestra el uso real de CPU y memoria de Pods y nodos (requiere metrics-server). Permite detectar over-provisioning y CPU stuck en el limite |
| **Debugging con eventos y logs** | `kubectl get events`, `kubectl logs --previous`, y `kubectl describe` son las herramientas principales para diagnosticar fallos de recursos |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML separados y documentados:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `oomkilled-demo.yaml` | 1 | Pod con memory leak: intenta 150Mi con limite de 100Mi |
| `cpu-throttling-demo.yaml` | 2 | Pod con CPU stress: intenta 2 CPUs con limite de 500m |
| `cpu-no-throttling.yaml` | 2 | Pod identico sin limite de CPU (comparacion) |
| `storage-eviction-demo.yaml` | 3 | Pod que escribe 250MB en emptyDir con limite de 200Mi |
| `pending-demo.yaml` | 4 | Deployment con 10 replicas pidiendo 4 CPU + 4Gi por Pod |
| `metrics-demo.yaml` | 5 | Deployment de 3 replicas nginx para practicar kubectl top |
| `problem-app.yaml` | 6 | Deployment con OOMKilled en contenedor principal + throttling en sidecar |
| `problem-app-fixed.yaml` | 6 | Version corregida con limites ajustados y replicas reducidas |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Requisitos Previos

- Cluster Kubernetes 1.28+
- `kubectl` configurado
- `metrics-server` instalado (requerido para Ejercicios 5 y 6)
- Completar **Lab 01: Fundamentos** (recomendado)

Ver [SETUP.md](./SETUP.md) para instrucciones de verificacion del entorno y habilitacion de metrics-server.

---

## Objetivos de Aprendizaje

Al completar este laboratorio, seras capaz de:

1. Detectar y diagnosticar OOMKilled (Out Of Memory)
2. Identificar CPU throttling y su impacto en el rendimiento
3. Troubleshoot evictions por ephemeral storage
4. Analizar metricas de recursos con `kubectl top`
5. Resolver problemas comunes de resource management
6. Usar eventos y logs para debugging sistematico

---

## Contexto Teorico

### Tipos de Problemas de Recursos

| Problema | Recurso | Comportamiento | Exit Code | Restart |
|----------|---------|----------------|-----------|---------|
| **OOMKilled** | Memory | Container terminado por kernel | 137 | Si |
| **CPU Throttling** | CPU | Container lento, no termina | N/A | No |
| **Eviction** | Storage | Pod eliminado del nodo | N/A | Si (re-schedule) |
| **Pending** | CPU/Mem | Pod no puede ser scheduled | N/A | N/A |

### Enforcement Mechanisms

```
+--------------------------------------------------+
|  CPU Limit Exceeded                              |
|  -> cgroups THROTTLING                           |
|  -> Proceso se vuelve LENTO                      |
|  -> NO se termina                                |
|  -> Detectable: /sys/fs/cgroup/cpu/cpu.stat      |
+--------------------------------------------------+

+--------------------------------------------------+
|  Memory Limit Exceeded                           |
|  -> Kernel OOM Killer                            |
|  -> Proceso TERMINADO (SIGKILL)                  |
|  -> Exit Code: 137                               |
|  -> Container REINICIA (restartPolicy: Always)   |
+--------------------------------------------------+

+--------------------------------------------------+
|  Ephemeral Storage Exceeded                      |
|  -> kubelet EVICTION                             |
|  -> Pod ELIMINADO del nodo                       |
|  -> Pod RE-SCHEDULED en otro nodo                |
|  -> Detectable: kubectl get events               |
+--------------------------------------------------+
```

---

## Ejercicio 1: Diagnosticar OOMKilled

### Paso 1.1: Revisar y aplicar el Pod con Memory Leak

Revisa el archivo `oomkilled-demo.yaml`:

```bash
cat oomkilled-demo.yaml
```

Puntos clave del manifiesto:
- **Memory limit: 100Mi** intencionalmente bajo
- **stress --vm-bytes 150M**: intenta usar 150Mi (supera el limite)
- **restartPolicy: Always**: el Pod se reiniciara continuamente tras cada OOMKilled

```bash
kubectl apply -f oomkilled-demo.yaml
```

### Paso 1.2: Observar el Comportamiento

```bash
# Ver el Pod (se reiniciara continuamente)
kubectl get pod oomkilled-demo --watch

# Salida esperada (despues de ~10 segundos):
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
  Reason:       OOMKilled         <- Killed por OOM
  Exit Code:    137               <- SIGKILL (128 + 9)
  Started:      Mon, 01 Jan 2024 10:00:00 +0000
  Finished:     Mon, 01 Jan 2024 10:00:05 +0000
```

**Detalles Tecnicos**:

- **Exit Code 137** = 128 + 9 (SIGKILL)
- Kernel OOM Killer envia SIGKILL al proceso
- Container NO puede capturar esta senal (terminacion forzada)

### Paso 1.4: Ver Restart Count

```bash
kubectl get pod oomkilled-demo -o jsonpath='{.status.containerStatuses[0].restartCount}'
# Salida: 5 (o mayor, dependiendo del tiempo)
```

### Paso 1.5: Ver Logs del Intento Fallido

```bash
# Ver logs del intento actual (puede estar vacio si fallo muy rapido)
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

### Paso 1.7: Soluciones Posibles

**Opcion 1**: Aumentar el limite de memoria

```yaml
resources:
  limits:
    memory: "200Mi"  # Aumentar a 200Mi
```

**Opcion 2**: Reducir el consumo de memoria de la aplicacion

```yaml
args:
- "--vm-bytes"
- "80M"  # Reducir a 80Mi (bajo el limite)
```

**Opcion 3**: Usar Vertical Pod Autoscaler (VPA)

```yaml
# Ver Lab 03 para VPA
```

### Paso 1.8: Cleanup del Ejercicio

```bash
kubectl delete pod oomkilled-demo
```

---

## Ejercicio 2: Detectar CPU Throttling

### Paso 2.1: Revisar y aplicar el Pod con CPU Stress

Revisa el archivo `cpu-throttling-demo.yaml`:

```bash
cat cpu-throttling-demo.yaml
```

Puntos clave del manifiesto:
- **CPU limit: 500m** (0.5 CPU)
- **stress --cpu 2**: intenta usar 2 CPUs completas
- El proceso no termina, solo se ralentiza

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

**Observacion**: El Pod esta "stuck" en ~500m (el limite), intentando usar mas pero siendo throttled.

Presiona `Ctrl+C` para salir.

### Paso 2.3: Verificar Throttling Stats (Dentro del Container)

```bash
kubectl exec -it cpu-throttling-demo -- cat /sys/fs/cgroup/cpu/cpu.stat
```

Salida esperada:

```
nr_periods 1500           # Total de periodos (100ms cada uno)
nr_throttled 1200         # Periodos donde fue throttled
throttled_time 85000000   # Tiempo total throttled (nanosegundos)
```

**Analisis**:

- **nr_throttled / nr_periods** = 1200 / 1500 = **80%**
- El container fue throttled **80% del tiempo**
- Esto significa que la aplicacion esta ejecutandose **MUY lenta**

### Paso 2.4: Ver Comportamiento del Container

```bash
# Ver logs (deberia ser lento para generar output)
kubectl logs cpu-throttling-demo
```

Salida esperada:

```
stress: info: [1] dispatching hogs: 2 cpu, 0 io, 0 vm, 0 hdd
```

**Por que el Pod NO se termina (a diferencia de OOMKilled)?**

<details>
<summary>Respuesta</summary>

Porque CPU throttling **NO termina el proceso**, solo lo hace mas lento:

- Memory limit -> **OOMKilled** (terminado)
- CPU limit -> **Throttling** (solo lento)

El kernel usa **cgroups** para limitar el tiempo de CPU disponible, pero el proceso sigue corriendo.
</details>

### Paso 2.5: Comparar con Pod Sin Limite

Revisa el archivo `cpu-no-throttling.yaml`:

```bash
cat cpu-no-throttling.yaml
```

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

**Comparacion**:

| Pod | CPU Limit | CPU Usado | Throttled |
|-----|-----------|-----------|-----------|
| cpu-throttling-demo | 500m | ~500m | Si (80%) |
| cpu-no-throttling | None | ~1950m | No |

### Paso 2.6: Detectar Throttling con Prometheus (Opcional)

Si tienes Prometheus instalado:

```promql
# Query para ver throttling rate
rate(container_cpu_cfs_throttled_seconds_total{pod="cpu-throttling-demo"}[5m])

# Query para ver porcentaje de throttling
rate(container_cpu_cfs_throttled_periods_total{pod="cpu-throttling-demo"}[5m]) /
rate(container_cpu_cfs_periods_total{pod="cpu-throttling-demo"}[5m]) * 100
```

### Paso 2.7: Soluciones Posibles

**Opcion 1**: Aumentar el limite de CPU

```yaml
resources:
  limits:
    cpu: "2"  # Aumentar a 2 CPUs
```

**Opcion 2**: Reducir la carga de CPU

```yaml
args:
- "--cpu"
- "1"  # Solo 1 CPU (bajo el limite)
```

**Opcion 3**: Remover el limite (solo requests)

```yaml
resources:
  requests:
    cpu: "500m"
  # Sin limite (puede usar lo que necesite)
```

**Opcion 4**: Horizontal Pod Autoscaler (HPA)

```bash
kubectl autoscale deployment <name> --cpu-percent=70 --min=2 --max=10
```

### Paso 2.8: Cleanup del Ejercicio

```bash
kubectl delete pod cpu-throttling-demo cpu-no-throttling
```

---

## Ejercicio 3: Troubleshoot Ephemeral Storage Eviction

### Paso 3.1: Revisar y aplicar el Pod con Ephemeral Storage Limit

Revisa el archivo `storage-eviction-demo.yaml`:

```bash
cat storage-eviction-demo.yaml
```

Puntos clave del manifiesto:
- **ephemeral-storage limit: 200Mi** en el contenedor
- **emptyDir sizeLimit: 200Mi** como best practice adicional
- El contenedor escribe 250MB, superando ambos limites

```bash
kubectl apply -f storage-eviction-demo.yaml
```

### Paso 3.2: Observar Eviction

```bash
kubectl get pod storage-eviction-demo --watch
```

Salida esperada (despues de ~30 segundos):

```
NAME                     READY   STATUS    RESTARTS   AGE
storage-eviction-demo    1/1     Running   0          5s
storage-eviction-demo    0/1     Evicted   0          35s
```

### Paso 3.3: Ver Razon de Eviction

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

# Limpiar TODOS los Pods evicted en el cluster
kubectl delete pods --all-namespaces --field-selector=status.phase=Failed
```

### Paso 3.7: Soluciones Posibles

**Opcion 1**: Aumentar el limite de ephemeral storage

```yaml
resources:
  limits:
    ephemeral-storage: "500Mi"
volumes:
- name: cache
  emptyDir:
    sizeLimit: "500Mi"
```

**Opcion 2**: Usar PersistentVolume en lugar de emptyDir

```yaml
volumes:
- name: data
  persistentVolumeClaim:
    claimName: my-pvc
```

**Opcion 3**: Limpiar archivos temporales periodicamente

```yaml
command:
- sh
- -c
- |
  while true; do
    # Tu aplicacion
    find /cache -type f -mtime +1 -delete  # Limpiar archivos viejos
    sleep 3600
  done
```

---

## Ejercicio 4: Troubleshoot Pending Pods

### Paso 4.1: Revisar y aplicar el Deployment con Requests Altos

Revisa el archivo `pending-demo.yaml`:

```bash
cat pending-demo.yaml
```

Puntos clave del manifiesto:
- **10 replicas** con requests de 4 CPU + 4Gi cada una
- En un nodo tipico de 4 CPU, solo cabe 1 Pod como maximo
- Los Pods restantes quedan en estado Pending

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

### Paso 4.3: Diagnosticar por que estan Pending

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

**Diagnostico**: El scheduler NO puede encontrar un nodo con suficiente CPU y memoria.

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

**Analisis**:

- Cada Pod pide: 4 CPU + 4Gi memory
- Nodo tiene: 4 CPU + 8Gi memory
- Solo caben **1-2 Pods por nodo**
- Los demas Pods quedan **Pending**

### Paso 4.5: Ver que Recursos Estan Consumidos

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

### Paso 4.6: Soluciones Posibles

**Opcion 1**: Reducir requests

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
```

**Opcion 2**: Reducir numero de replicas

```yaml
spec:
  replicas: 2  # Reducir a lo que cabe
```

**Opcion 3**: Agregar mas nodos al cluster

```bash
# Ejemplo con minikube
minikube node add

# Ejemplo con cloud provider
# kubectl scale --replicas=5 deployment/cluster-autoscaler
```

### Paso 4.7: Cleanup del Ejercicio

```bash
kubectl delete deployment pending-demo
```

---

## Ejercicio 5: Usar Metricas para Troubleshooting

### Paso 5.1: Revisar y aplicar el Deployment para Monitoreo

Revisa el archivo `metrics-demo.yaml`:

```bash
cat metrics-demo.yaml
```

Puntos clave del manifiesto:
- **3 replicas** de nginx con requests de 100m CPU y 64Mi memoria
- nginx tipicamente usa ~2m CPU y ~15Mi memoria en reposo
- Ilustra over-provisioning: requests >> uso real

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

### Paso 5.4: Calcular Utilizacion de Recursos

```bash
# Ver recursos asignados
kubectl describe deployment metrics-demo | grep -A 10 "Requests:"

# Calcular utilizacion
# CPU: 2m / 100m = 2%
# Memory: 15Mi / 64Mi = 23%
```

**Analisis**:

- **CPU**: Usando 2m de 100m request = **2% utilizacion** -> Mucho over-provisioning
- **Memory**: Usando 15Mi de 64Mi request = **23% utilizacion** -> Over-provisioning

**Recomendacion**: Reducir requests a valores mas cercanos al uso real:

```yaml
resources:
  requests:
    cpu: "10m"     # Reducir de 100m
    memory: "32Mi" # Reducir de 64Mi
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

### Paso 5.6: Cleanup del Ejercicio

```bash
kubectl delete deployment metrics-demo
```

---

## Ejercicio 6: Caso Practico Completo

### Escenario

Tienes una aplicacion en produccion que esta experimentando:
- Reinicios frecuentes
- Lentitud intermitente
- Algunos Pods en estado Pending

### Paso 6.1: Desplegar la Aplicacion Problematica

Revisa el archivo `problem-app.yaml`:

```bash
cat problem-app.yaml
```

Puntos clave del manifiesto:
- **Contenedor `app`**: memory leak con 120M sobre limite de 100Mi (OOMKilled)
- **Contenedor `logger`**: 2 CPUs sobre limite de 100m (throttling)
- **5 replicas**: algunas probablemente quedaran en Pending en nodos pequenos

```bash
kubectl apply -f problem-app.yaml
```

### Paso 6.2: Investigacion Inicial

```bash
# Ver estado de los Pods
kubectl get pods -l app=problem

# Ver eventos recientes
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

**Que problemas observas?**

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

# Describir un Pod problematico
kubectl describe pod <pod-name> | grep -A 10 "Last State"
```

### Paso 6.4: Diagnosticar CPU Throttling

```bash
# Ver uso de CPU
kubectl top pods -l app=problem --containers
```

Observaras que el contenedor `logger` esta stuck en ~100m (su limite).

### Paso 6.5: Diagnosticar Pending Pods

```bash
kubectl describe pod <pending-pod> | grep -A 5 "Events:"
```

### Paso 6.6: Aplicar la Version Corregida

Revisa el archivo `problem-app-fixed.yaml`:

```bash
cat problem-app-fixed.yaml
```

Puntos clave de la correccion:
- **`app`**: cambiado a nginx (sin memory leak) con limite de 256Mi
- **`logger`**: cambiado a busybox con `tail -f /dev/null` (sin CPU excesivo)
- **3 replicas** en lugar de 5 para caber en nodos pequenos

```bash
kubectl apply -f problem-app-fixed.yaml
```

Verifica:

```bash
kubectl get pods -l app=problem-fixed
kubectl top pods -l app=problem-fixed --containers
```

### Paso 6.7: Cleanup del Ejercicio

```bash
kubectl delete deployment problem-app problem-app-fixed
```

---

## Troubleshooting Checklist

### Cuando un Pod esta CrashLoopBackOff

```bash
# 1. Ver restart count
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].restartCount}'

# 2. Ver exit code
kubectl describe pod <pod-name> | grep -A 10 "Last State"

# 3. Si Exit Code = 137 -> OOMKilled
kubectl logs <pod-name> --previous

# 4. Ver recursos
kubectl describe pod <pod-name> | grep -A 10 "Limits:"

# 5. Aumentar limite de memoria
kubectl edit deployment <deployment-name>
```

### Cuando un Pod esta Lento

```bash
# 1. Ver CPU usage
kubectl top pod <pod-name> --containers

# 2. Si CPU stuck en el limite -> throttling
kubectl exec -it <pod-name> -- cat /sys/fs/cgroup/cpu/cpu.stat

# 3. Calcular % throttled
# nr_throttled / nr_periods * 100

# 4. Aumentar limite de CPU o remover limite
kubectl edit deployment <deployment-name>
```

### Cuando un Pod esta Pending

```bash
# 1. Ver razon
kubectl describe pod <pod-name> | grep -A 10 "Events:"

# 2. Si "Insufficient cpu/memory" -> ver nodos
kubectl describe nodes | grep -A 10 "Allocatable:"

# 3. Ver que Pods estan usando recursos
kubectl get pods -o custom-columns=\
NAME:.metadata.name,\
CPU_REQ:.spec.containers[0].resources.requests.cpu,\
MEM_REQ:.spec.containers[0].resources.requests.memory

# 4. Reducir requests o agregar nodos
```

### Cuando un Pod fue Evicted

```bash
# 1. Ver razon de eviction
kubectl describe pod <pod-name> | grep -A 5 "Message:"

# 2. Si "ephemeral storage" -> ver uso
kubectl exec -it <pod-name> -- df -h

# 3. Ver eventos de eviction
kubectl get events --field-selector reason=Evicted

# 4. Aumentar limite o limpiar archivos
```

---

## Resumen de Patrones de Troubleshooting

### OOMKilled Pattern

```
Sintomas:
- CrashLoopBackOff
- Restart count alto
- Exit Code: 137

Diagnostico:
kubectl describe pod | grep "Last State"
kubectl logs --previous

Solucion:
- Aumentar memory limit
- Optimizar aplicacion (fix memory leak)
- Usar VPA
```

### CPU Throttling Pattern

```
Sintomas:
- Pod lento pero no crashea
- CPU usage stuck en el limite
- No aumenta con load

Diagnostico:
kubectl top pod --containers
kubectl exec -- cat /sys/fs/cgroup/cpu/cpu.stat

Solucion:
- Aumentar CPU limit
- Remover limite (solo requests)
- Usar HPA para escalar horizontalmente
```

### Eviction Pattern

```
Sintomas:
- Pod status: Evicted
- Pod re-scheduled en otro nodo

Diagnostico:
kubectl get events --field-selector reason=Evicted
kubectl describe pod | grep "Message:"

Solucion:
- Aumentar ephemeral-storage limit
- Usar sizeLimit en emptyDir
- Limpiar archivos periodicamente
- Usar PersistentVolume
```

### Pending Pattern

```
Sintomas:
- Pod status: Pending (no Running)
- No se asigna a ningun nodo

Diagnostico:
kubectl describe pod | grep "Events:"
kubectl describe nodes | grep "Allocatable:"

Solucion:
- Reducir requests
- Reducir numero de replicas
- Agregar mas nodos
- Usar Cluster Autoscaler
```

---

## Limpieza Completa

```bash
# Usar el script de limpieza
chmod +x cleanup.sh
./cleanup.sh
```

El script elimina todos los recursos del laboratorio:
- Pods: oomkilled-demo, cpu-throttling-demo, cpu-no-throttling, storage-eviction-demo
- Deployments: pending-demo, metrics-demo, problem-app, problem-app-fixed
- Pods restantes con label `lab=troubleshooting`
- Pods en estado Failed (Evicted)

---

## Proximos Pasos

Ahora que dominas troubleshooting, continua con:

1. **[Laboratorio 03: Produccion](../lab-03-produccion/)**: Best practices, VPA, HPA, Prometheus monitoring

---

## Referencias

- **[README Principal](../../README.md)**: Documentacion completa del modulo
- **[Lab 01: Fundamentos](../lab-01-fundamentos/)**: Conceptos basicos de resource limits
- **[Guia de Ejemplos](../../ejemplos/README.md)**: Catalogo completo de ejemplos
- **[Ejemplos Troubleshooting](../../ejemplos/)**:
  - [13-troubleshooting-oom](../../ejemplos/13-troubleshooting-oom/): Problemas de memoria
  - [14-troubleshooting-cpu](../../ejemplos/14-troubleshooting-cpu/): Throttling y CPU
- **[Kubernetes Docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)**: Documentacion oficial

---

**Felicidades!** Has completado el laboratorio de troubleshooting de Resource Limits.
