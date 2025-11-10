# Ejemplos Prácticos - Resource Limits en Pods

Este directorio contiene **29 ejemplos** organizados en **14 categorías**. Cada ejemplo está en su propio archivo para facilitar aplicación individual y comprensión.

## 📁 Estructura del Directorio

```
ejemplos/
├── 01-requests-limits-basico/          # Conceptos fundamentales
│   └── pod.yaml
├── 02-multi-container/                 # Múltiples contenedores
│   └── pod.yaml
├── 03-init-containers/                 # Init containers con max()
│   └── pod.yaml
├── 04-solo-requests/                   # Request-only configuration
│   └── pod.yaml
├── 05-solo-limits/                     # Limit-only con auto-copy
│   └── pod.yaml
├── 06-ephemeral-storage-basico/        # Ephemeral storage básico
│   └── pod.yaml
├── 07-qos-guaranteed/                  # QoS: Guaranteed
│   └── pod.yaml
├── 08-qos-burstable/                   # QoS: Burstable (3 ejemplos)
│   ├── flexible.yaml
│   ├── request-only.yaml
│   └── mixed.yaml
├── 09-qos-besteffort/                  # QoS: BestEffort (2 ejemplos)
│   ├── pod.yaml
│   └── deployment.yaml
├── 10-ephemeral-storage/               # Ephemeral storage avanzado (7 ejemplos)
│   ├── 01-emptydir-con-sizelimit.yaml
│   ├── 02-emptydir-sin-sizelimit-peligroso.yaml
│   ├── 03-tmpfs-memory-backed.yaml
│   ├── 04-multiples-emptydir.yaml
│   ├── 05-monitoreo.yaml
│   ├── 06-eviction-demo.yaml
│   └── 07-deployment-best-practices.yaml
├── 11-pod-level-resources/             # Pod-level resources K8s 1.34+ (3 ejemplos)
│   ├── 01-pod-level-basico.yaml
│   ├── 02-pod-level-hibrido.yaml
│   └── 03-deployment-multi-sidecar.yaml
├── 12-extended-resources/              # GPUs y recursos custom (3 ejemplos)
│   ├── 01-nvidia-gpu.yaml
│   ├── 02-amd-gpu.yaml
│   └── 03-custom-resources.yaml
├── 13-troubleshooting-oom/             # OOMKilled troubleshooting (2 ejemplos)
│   ├── 01-oomkilled-demo.yaml
│   └── 02-gradual-leak.yaml
└── 14-troubleshooting-cpu/             # CPU throttling (3 ejemplos)
    ├── 01-cpu-throttling-demo.yaml
    ├── 02-cpu-comparison.yaml
    └── 03-deployment-con-hpa.yaml
```

## 🎯 Learning Paths

### Path 1: Fundamentos (Principiantes)
**Tiempo**: ~45 minutos | **Requisitos**: Cluster K8s básico

```bash
# 1. Requests y Limits Básicos
kubectl apply -f 01-requests-limits-basico/pod.yaml
kubectl get pod requests-limits-basic
kubectl top pod requests-limits-basic

# 2. Múltiples Contenedores (suma de recursos)
kubectl apply -f 02-multi-container/pod.yaml
kubectl describe pod multi-container-resources

# 3. Init Containers (cálculo max)
kubectl apply -f 03-init-containers/pod.yaml
kubectl describe pod init-container-resources

# 4. QoS Classes
kubectl apply -f 07-qos-guaranteed/pod.yaml
kubectl apply -f 08-qos-burstable/flexible.yaml
kubectl apply -f 09-qos-besteffort/pod.yaml

kubectl get pods -o custom-columns=\
NAME:.metadata.name,\
QOS:.status.qosClass
```

**Conceptos aprendidos**: Requests, Limits, Resource summation, QoS Classes

---

### Path 2: QoS Classes en Detalle (Intermedio)
**Tiempo**: ~30 minutos | **Requisitos**: Completar Path 1

```bash
# Guaranteed: request == limit
kubectl apply -f 07-qos-guaranteed/pod.yaml

# Burstable: request < limit
kubectl apply -f 08-qos-burstable/flexible.yaml
kubectl apply -f 08-qos-burstable/request-only.yaml
kubectl apply -f 08-qos-burstable/mixed.yaml

# BestEffort: sin resources
kubectl apply -f 09-qos-besteffort/pod.yaml
kubectl apply -f 09-qos-besteffort/deployment.yaml

# Ver QoS de todos
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.qosClass}{"\n"}{end}'

# Ver orden de eviction bajo presión
kubectl describe nodes | grep -A 5 "Allocated resources"
```

**Conceptos aprendidos**: Guaranteed, Burstable, BestEffort, Eviction order

---

### Path 3: Ephemeral Storage (Intermedio)
**Tiempo**: ~60 minutos | **Requisitos**: Cluster con metrics-server

```bash
# 1. emptyDir con sizeLimit (best practice)
kubectl apply -f 10-ephemeral-storage/01-emptydir-con-sizelimit.yaml
kubectl exec -it emptydir-with-sizelimit -- df -h /cache

# 2. emptyDir sin sizeLimit (peligroso)
kubectl apply -f 10-ephemeral-storage/02-emptydir-sin-sizelimit-peligroso.yaml

# 3. tmpfs (memory-backed)
kubectl apply -f 10-ephemeral-storage/03-tmpfs-memory-backed.yaml
kubectl exec -it emptydir-tmpfs -- mount | grep /tmp

# 4. Múltiples emptyDir
kubectl apply -f 10-ephemeral-storage/04-multiples-emptydir.yaml

# 5. Monitoreo en tiempo real
kubectl apply -f 10-ephemeral-storage/05-monitoreo.yaml
kubectl logs -f ephemeral-monitor -c monitor

# 6. Eviction por storage
kubectl apply -f 10-ephemeral-storage/06-eviction-demo.yaml
# Esperar eviction...
kubectl describe pod ephemeral-eviction-demo | grep -i evict

# 7. Deployment production-ready
kubectl apply -f 10-ephemeral-storage/07-deployment-best-practices.yaml
```

**Conceptos aprendidos**: emptyDir, sizeLimit, tmpfs, storage eviction, best practices

---

### Path 4: Troubleshooting (Avanzado)
**Tiempo**: ~90 minutos | **Requisitos**: Conocimientos de debugging

```bash
# === OOMKilled Troubleshooting ===

# 1. OOMKilled simulation
kubectl apply -f 13-troubleshooting-oom/01-oomkilled-demo.yaml

# Ver OOMKilled en acción
kubectl get pod oomkilled-demo --watch
# Esperar CrashLoopBackOff...

# Ver detalles del crash
kubectl describe pod oomkilled-demo | grep -A 10 "Last State"
kubectl logs oomkilled-demo --previous

# 2. Memory leak gradual (más realista)
kubectl apply -f 13-troubleshooting-oom/02-gradual-leak.yaml
kubectl logs -f gradual-memory-leak
# En otra terminal:
watch kubectl top pod gradual-memory-leak

# === CPU Throttling Troubleshooting ===

# 3. CPU throttling demo
kubectl apply -f 14-troubleshooting-cpu/01-cpu-throttling-demo.yaml
kubectl top pod cpu-throttling-demo
# Verás CPU stuck en límite (500m)

# Ver throttling stats
kubectl exec -it cpu-throttling-demo -- cat /sys/fs/cgroup/cpu/cpu.stat

# 4. Comparación lado a lado
kubectl apply -f 14-troubleshooting-cpu/02-cpu-comparison.yaml
kubectl top pod cpu-comparison --containers

# 5. Solución con HPA (recomendado)
kubectl apply -f 14-troubleshooting-cpu/03-deployment-con-hpa.yaml

# Generar carga
kubectl run load-gen --image=busybox:1.36 --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://cpu-app; done"

# Ver HPA en acción
watch kubectl get hpa cpu-app-hpa
```

**Conceptos aprendidos**: OOMKilled, Exit Code 137, CrashLoopBackOff, CPU throttling, HPA

---

### Path 5: Extended Resources (Avanzado)
**Tiempo**: ~45 minutos | **Requisitos**: Nodos con GPUs o configuración manual

```bash
# ⚠️ Requiere Device Plugins instalados

# 1. NVIDIA GPUs
# Instalar NVIDIA Device Plugin:
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.0/nvidia-device-plugin.yml

kubectl apply -f 12-extended-resources/01-nvidia-gpu.yaml
kubectl logs gpu-pod-nvidia
kubectl exec -it gpu-pod-nvidia -- nvidia-smi

# 2. AMD GPUs
kubectl apply -f 12-extended-resources/02-amd-gpu.yaml
kubectl exec -it gpu-pod-amd -- rocm-smi

# 3. Custom resources (FPGAs, dongles, etc.)
# Primero anuncia el recurso:
NODE_NAME="your-node"
kubectl patch node $NODE_NAME --subresource=status --type=json -p='[
  {"op":"add","path":"/status/capacity/example.com~1fpga","value":"4"}
]'

kubectl apply -f 12-extended-resources/03-custom-resources.yaml
```

**Conceptos aprendidos**: NVIDIA GPUs, AMD GPUs, Custom extended resources, Device Plugins

---

### Path 6: Pod-level Resources (Experimental)
**Tiempo**: ~30 minutos | **Requisitos**: Kubernetes 1.34+ con PodLevelResources feature gate

```bash
# ⚠️ Feature Beta en K8s 1.34+
# Verificar que esté habilitado:
kubectl version --short

# 1. Pod-level básico
kubectl apply -f 11-pod-level-resources/01-pod-level-basico.yaml
kubectl describe pod pod-level-basic

# 2. Híbrido (Pod + Container level)
kubectl apply -f 11-pod-level-resources/02-pod-level-hibrido.yaml
kubectl top pod pod-level-hybrid --containers

# 3. Deployment con múltiples sidecars
kubectl apply -f 11-pod-level-resources/03-deployment-multi-sidecar.yaml
kubectl get pods -l app=multi-sidecar
kubectl top pods -l app=multi-sidecar --containers
```

**Conceptos aprendidos**: Pod-level resources, Resource sharing, Sidecar patterns

---

## 📊 Tabla Comparativa de Ejemplos

| Categoría | # Ejemplos | Dificultad | Requisitos Especiales |
|-----------|------------|------------|----------------------|
| Básicos (01-06) | 6 | ⭐ Básico | Ninguno |
| QoS Classes (07-09) | 6 | ⭐⭐ Intermedio | Ninguno |
| Ephemeral Storage (10) | 7 | ⭐⭐ Intermedio | metrics-server |
| Pod-level Resources (11) | 3 | ⭐⭐⭐ Avanzado | K8s 1.34+ |
| Extended Resources (12) | 3 | ⭐⭐⭐ Avanzado | GPUs o config manual |
| Troubleshooting OOM (13) | 2 | ⭐⭐ Intermedio | Ninguno |
| Troubleshooting CPU (14) | 3 | ⭐⭐⭐ Avanzado | metrics-server, HPA |

**Total**: 29 ejemplos

---

## 🚀 Quick Start

### Aplicar un ejemplo individual

```bash
# Navega al directorio
cd ejemplos/

# Aplica un ejemplo específico
kubectl apply -f 01-requests-limits-basico/pod.yaml

# Ver estado
kubectl get pods

# Ver detalles
kubectl describe pod requests-limits-basic

# Ver logs
kubectl logs requests-limits-basic

# Limpiar
kubectl delete -f 01-requests-limits-basico/pod.yaml
```

### Aplicar todos los ejemplos de una categoría

```bash
# Todos los QoS Burstable
kubectl apply -f 08-qos-burstable/

# Ver todos
kubectl get pods -l example=qos-demo

# Limpiar todos
kubectl delete -f 08-qos-burstable/
```

### Aplicar todos los ejemplos básicos

```bash
kubectl apply -f 01-requests-limits-basico/
kubectl apply -f 02-multi-container/
kubectl apply -f 03-init-containers/
kubectl apply -f 04-solo-requests/
kubectl apply -f 05-solo-limits/
kubectl apply -f 06-ephemeral-storage-basico/

# Ver todos
kubectl get pods
```

---

## 🔍 Comandos Útiles

### Ver recursos de Pods

```bash
# CPU y Memory usage
kubectl top pod <pod-name>

# CPU y Memory por contenedor
kubectl top pod <pod-name> --containers

# Ver limits y requests
kubectl describe pod <pod-name> | grep -A 10 "Limits:"

# Ver QoS Class
kubectl get pod <pod-name> -o jsonpath='{.status.qosClass}'
```

### Troubleshooting

```bash
# Ver eventos
kubectl get events --sort-by='.lastTimestamp'

# Ver logs anteriores (tras crash)
kubectl logs <pod-name> --previous

# Describir Pod
kubectl describe pod <pod-name>

# Ver restart count
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].restartCount}'

# Ver exit code
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'
```

### Monitoreo con Prometheus

```bash
# CPU usage
container_cpu_usage_seconds_total{pod="<pod-name>"}

# Memory usage
container_memory_usage_bytes{pod="<pod-name>"}

# CPU throttling
rate(container_cpu_cfs_throttled_seconds_total{pod="<pod-name>"}[5m])

# OOMKilled events
kube_pod_container_status_terminated_reason{reason="OOMKilled"}
```

---

## 📚 Referencias

- [Documentación principal](../README.md)
- [Laboratorios prácticos](../labs/)
- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Quality of Service](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)
- [Ephemeral Storage](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#local-ephemeral-storage)

---

## 💡 Tips

1. **Comienza por los fundamentos**: Sigue Path 1 antes de avanzar a ejemplos más complejos
2. **Un ejemplo a la vez**: Aplica, observa, limpia, luego pasa al siguiente
3. **Lee los comentarios**: Cada YAML tiene documentación exhaustiva inline
4. **Usa `kubectl describe`**: Proporciona detalles cruciales de resources
5. **Monitorea con `kubectl top`**: Verifica uso real vs límites
6. **Experimenta**: Modifica los YAMLs, observa el comportamiento
7. **Limpia después**: `kubectl delete -f <file>` para no saturar el cluster

---

## 🛠️ Requisitos

### Mínimos (para ejemplos básicos)
- Kubernetes 1.20+
- kubectl configurado
- Acceso a un cluster

### Recomendados (para ejemplos avanzados)
- Kubernetes 1.25+
- metrics-server instalado
- Prometheus (opcional, para métricas)
- Nodos con GPUs (solo para ejemplos 12-*)

### Experimentales
- Kubernetes 1.34+ (para pod-level resources)
- NVIDIA/AMD Device Plugins (para GPUs)

---

## ❓ FAQ

**P: ¿Por qué cada ejemplo está en su propio archivo?**  
R: Facilita aplicar ejemplos individuales con `kubectl apply -f` sin tener que editar o separar manualmente.

**P: ¿Puedo aplicar todos los ejemplos a la vez?**  
R: Sí, pero no es recomendado. Algunos ejemplos (OOMKilled, eviction) causan problemas intencionalmente. Mejor aplicar por categoría.

**P: ¿Necesito un cluster de producción?**  
R: No. Minikube, kind, o k3s son suficientes para la mayoría de ejemplos.

**P: ¿Qué ejemplos son seguros para producción?**  
R: 01-06, 07, 08, 10/01, 10/03, 10/04, 10/07, 11-*, 12-*. Los de troubleshooting (13-*, 14-*) son solo para testing.

**P: ¿Cómo limpio todos los recursos?**  
R: `kubectl delete pods -l example=<label>` o elimina por archivo individual.
