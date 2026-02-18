# Módulo 26: Troubleshooting Avanzado en Kubernetes

## Índice
1. [Introducción al Troubleshooting](#introducción-al-troubleshooting)
2. [Metodología Sistemática](#metodología-sistemática)
3. [Troubleshooting de Aplicaciones](#troubleshooting-de-aplicaciones)
4. [Troubleshooting del Control Plane](#troubleshooting-del-control-plane)
5. [Troubleshooting de Worker Nodes](#troubleshooting-de-worker-nodes)
6. [Troubleshooting de Red](#troubleshooting-de-red)
7. [Troubleshooting de Storage](#troubleshooting-de-storage)
8. [Troubleshooting de Performance](#troubleshooting-de-performance)
9. [Troubleshooting de Seguridad y RBAC](#troubleshooting-de-seguridad-y-rbac)
10. [Herramientas de Diagnóstico](#herramientas-de-diagnóstico)
11. [Best Practices](#best-practices)
12. [Preparación CKA](#preparación-cka)

---

## Introducción al Troubleshooting

El troubleshooting en Kubernetes es una habilidad crítica que representa aproximadamente el **25-30% del examen CKA**. A diferencia de otros dominios que se centran en configurar recursos, el troubleshooting requiere:

- **Pensamiento sistemático**: Enfoque de capas (Application → Node → Network → Storage)
- **Conocimiento profundo**: Comprender cómo interactúan los componentes
- **Velocidad bajo presión**: El examen CKA tiene límites de tiempo estrictos
- **Práctica deliberada**: Necesitas experiencia con fallos reales

### Por Qué es Importante

```
REAL-WORLD KUBERNETES TROUBLESHOOTING
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Symptom: "My application is not working"                  │
│                                                             │
│  Could be:                                                  │
│  ├─ Application Layer (50%)                                │
│  │  ├─ Pod crashes (CrashLoopBackOff)                      │
│  │  ├─ Image pull failures (ImagePullBackOff)              │
│  │  ├─ Resource limits (OOMKilled)                         │
│  │  └─ Init container issues                               │
│  │                                                          │
│  ├─ Network Layer (25%)                                    │
│  │  ├─ Service misconfiguration                            │
│  │  ├─ DNS failures                                        │
│  │  ├─ Network policies blocking traffic                   │
│  │  └─ Ingress issues                                      │
│  │                                                          │
│  ├─ Node Layer (15%)                                       │
│  │  ├─ Node NotReady                                       │
│  │  ├─ Disk pressure                                       │
│  │  └─ Resource exhaustion                                 │
│  │                                                          │
│  └─ Storage Layer (10%)                                    │
│     ├─ PVC not bound                                       │
│     ├─ Mount failures                                      │
│     └─ Permission issues                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Objetivos del Módulo

Al completar este módulo, serás capaz de:

- ✅ Diagnosticar y resolver problemas de aplicaciones (pods, containers, crashes)
- ✅ Identificar y solucionar problemas del control plane (API server, etcd, scheduler)
- ✅ Resolver problemas de worker nodes (kubelet, kube-proxy, CNI)
- ✅ Diagnosticar problemas de red (DNS, services, network policies, ingress)
- ✅ Solucionar problemas de almacenamiento (PV/PVC, mounts, permissions)
- ✅ Analizar problemas de rendimiento (resources, QoS, eviction)
- ✅ Resolver problemas de RBAC y seguridad (permissions, service accounts)
- ✅ Usar herramientas de diagnóstico profesionales (kubectl, logs, events, debug pods)

---

## Metodología Sistemática

### El Approach de 5 Pasos

```
TROUBLESHOOTING WORKFLOW
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  1. IDENTIFY (Identificar el Síntoma)                      │
│     ├─ ¿Qué está fallando exactamente?                     │
│     ├─ ¿Cuándo comenzó el problema?                        │
│     └─ ¿Hay errores visibles?                              │
│                                                             │
│  2. GATHER (Recopilar Información)                         │
│     ├─ kubectl get/describe                                │
│     ├─ kubectl logs                                        │
│     ├─ kubectl events                                      │
│     └─ Component logs                                      │
│                                                             │
│  3. ANALYZE (Analizar la Causa Raíz)                       │
│     ├─ Layer-by-layer inspection                           │
│     ├─ Check dependencies                                  │
│     └─ Validate configurations                             │
│                                                             │
│  4. RESOLVE (Resolver el Problema)                         │
│     ├─ Apply fix                                           │
│     ├─ Verify solution                                     │
│     └─ Document changes                                    │
│                                                             │
│  5. PREVENT (Prevenir Recurrencia)                         │
│     ├─ Root cause analysis                                 │
│     ├─ Update monitoring/alerts                            │
│     └─ Implement best practices                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Layer-by-Layer Troubleshooting

Kubernetes es un sistema de capas. Troubleshoot de abajo hacia arriba:

```
KUBERNETES TROUBLESHOOTING LAYERS
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Layer 7: Application Logic                                │
│           ├─ Application crashes                           │
│           ├─ Configuration errors                          │
│           └─ Database connection issues                    │
│                                                             │
│  Layer 6: Kubernetes Resources                             │
│           ├─ Deployments, StatefulSets, DaemonSets         │
│           ├─ ConfigMaps, Secrets                           │
│           └─ Services, Ingress                             │
│                                                             │
│  Layer 5: Pod & Container                                  │
│           ├─ Pod status (Pending, CrashLoopBackOff)        │
│           ├─ Container runtime issues                      │
│           └─ Resource limits                               │
│                                                             │
│  Layer 4: Network                                          │
│           ├─ Services & Endpoints                          │
│           ├─ DNS resolution                                │
│           ├─ Network policies                              │
│           └─ Ingress & LoadBalancer                        │
│                                                             │
│  Layer 3: Storage                                          │
│           ├─ PersistentVolumes                             │
│           ├─ PersistentVolumeClaims                        │
│           └─ StorageClasses                                │
│                                                             │
│  Layer 2: Node                                             │
│           ├─ Node status (Ready, NotReady)                 │
│           ├─ kubelet, kube-proxy                           │
│           ├─ Container runtime (containerd, docker)        │
│           └─ CNI plugin                                    │
│                                                             │
│  Layer 1: Control Plane                                    │
│           ├─ API Server                                    │
│           ├─ etcd                                          │
│           ├─ Scheduler                                     │
│           └─ Controller Manager                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Start troubleshooting from Layer 1 (infrastructure) and move up
```

### Decision Tree por Síntoma

#### Síntoma: Pod en estado "Pending"

```
Pod PENDING
│
├─ Check Events
│  └─ kubectl describe pod <pod-name>
│
├─ Possible Causes:
│  │
│  ├─ Insufficient Resources
│  │  └─ No node has enough CPU/Memory
│  │     ├─ Check: kubectl describe nodes | grep -A 5 "Allocated resources"
│  │     └─ Fix: Scale cluster OR reduce pod requests
│  │
│  ├─ Node Selector / Affinity Issues
│  │  └─ Pod requires labels that no node has
│  │     ├─ Check: kubectl get nodes --show-labels
│  │     └─ Fix: Add labels to nodes OR update pod spec
│  │
│  ├─ Taints and Tolerations
│  │  └─ All matching nodes are tainted
│  │     ├─ Check: kubectl describe nodes | grep Taints
│  │     └─ Fix: Add tolerations OR remove taints
│  │
│  └─ PVC Not Bound
│     └─ Waiting for storage
│        ├─ Check: kubectl get pvc
│        └─ Fix: Create PV OR fix StorageClass
```

#### Síntoma: Pod en "CrashLoopBackOff"

```
Pod CrashLoopBackOff
│
├─ Check Logs
│  ├─ kubectl logs <pod-name>
│  └─ kubectl logs <pod-name> --previous  # Last crash
│
├─ Possible Causes:
│  │
│  ├─ Application Error
│  │  └─ Code crash, misconfiguration
│  │     ├─ Check: Application logs
│  │     └─ Fix: Debug application code
│  │
│  ├─ Missing Dependencies
│  │  └─ ConfigMap, Secret, Service not available
│  │     ├─ Check: kubectl get cm,secret,svc
│  │     └─ Fix: Create missing resources
│  │
│  ├─ Liveness Probe Failing
│  │  └─ Health check endpoint not ready
│  │     ├─ Check: kubectl describe pod | grep Liveness
│  │     └─ Fix: Adjust probe OR fix endpoint
│  │
│  ├─ Resource Limits
│  │  └─ OOMKilled (Out of Memory)
│  │     ├─ Check: kubectl describe pod | grep -A 5 "Last State"
│  │     └─ Fix: Increase memory limits
│  │
│  └─ Incorrect Command/Args
│     └─ Entrypoint or arguments wrong
│        ├─ Check: kubectl get pod <name> -o yaml | grep -A 10 command
│        └─ Fix: Update deployment spec
```

#### Síntoma: "ImagePullBackOff"

```
ImagePullBackOff
│
├─ Check Events
│  └─ kubectl describe pod <pod-name>
│
├─ Possible Causes:
│  │
│  ├─ Image Does Not Exist
│  │  └─ Typo in image name or tag
│  │     ├─ Check: Verify image:tag in registry
│  │     └─ Fix: Correct image name
│  │
│  ├─ Authentication Required
│  │  └─ Private registry needs credentials
│  │     ├─ Check: kubectl get secret <imagePullSecret>
│  │     └─ Fix: Create/update imagePullSecrets
│  │
│  ├─ Network Issues
│  │  └─ Cannot reach registry
│  │     ├─ Check: DNS, firewall, proxy
│  │     └─ Fix: Configure network access
│  │
│  └─ Rate Limiting
│     └─ Docker Hub rate limits
│        └─ Fix: Use authenticated pulls OR mirror
```

---

## Troubleshooting de Aplicaciones

### Estados de Pods

Los pods pueden estar en múltiples estados. Comprender cada uno es crítico:

| Estado | Significado | Causa Común | Comando de Diagnóstico |
|--------|-------------|-------------|------------------------|
| **Pending** | Esperando ser programado | Recursos insuficientes, node selector | `kubectl describe pod` |
| **ContainerCreating** | Creando contenedores | Pulling image, mounting volumes | `kubectl describe pod` |
| **Running** | Todo funcionando | N/A | `kubectl logs` |
| **CrashLoopBackOff** | Container crashea repetidamente | Application error, config issues | `kubectl logs --previous` |
| **Error** | Container terminó con error | Application crash | `kubectl logs` |
| **Completed** | Container terminó exitosamente | Job/CronJob completado | `kubectl logs` |
| **ImagePullBackOff** | No puede descargar imagen | Image no existe, auth required | `kubectl describe pod` |
| **OOMKilled** | Out of Memory | Memory limits muy bajos | `kubectl describe pod` |
| **Evicted** | Expulsado por falta de recursos | Node disk/memory pressure | `kubectl get events` |
| **Unknown** | Estado desconocido | Node communication lost | `kubectl get nodes` |

### Diagnóstico de Containers

#### 1. Container Crashes

```bash
# Ver logs del container actual
kubectl logs <pod-name> -c <container-name>

# Ver logs del container anterior (último crash)
kubectl logs <pod-name> -c <container-name> --previous

# Ver últimas 100 líneas
kubectl logs <pod-name> --tail=100

# Seguir logs en tiempo real
kubectl logs <pod-name> -f

# Logs de todos los containers en un pod
kubectl logs <pod-name> --all-containers=true

# Ver detalles del crash
kubectl describe pod <pod-name> | grep -A 10 "Last State"
```

**Ejemplo de Output OOMKilled:**
```
Last State:     Terminated
  Reason:       OOMKilled
  Exit Code:    137
  Started:      Wed, 13 Nov 2024 10:00:00 +0000
  Finished:     Wed, 13 Nov 2024 10:05:30 +0000
```

**Exit Codes Comunes:**
- `0`: Success
- `1`: Generic error
- `137`: OOMKilled (128 + 9 SIGKILL)
- `139`: Segmentation fault
- `143`: Terminated (128 + 15 SIGTERM)

#### 2. Init Containers

Los init containers deben completarse antes de que los app containers inicien:

```bash
# Ver estado de init containers
kubectl describe pod <pod-name> | grep -A 20 "Init Containers"

# Logs de init container
kubectl logs <pod-name> -c <init-container-name>

# Ejemplo de init container bloqueado
kubectl get pod <pod-name> -o jsonpath='{.status.initContainerStatuses[*].state}'
```

**Problema Común:**
```yaml
# Init container esperando por servicio
initContainers:
- name: wait-for-db
  image: busybox
  command: ['sh', '-c', 'until nslookup db-service; do sleep 2; done']
  # Si db-service no existe, pod queda en Init:0/1
```

#### 3. Readiness y Liveness Probes

```bash
# Ver configuración de probes
kubectl get pod <pod-name> -o yaml | grep -A 10 "livenessProbe\|readinessProbe"

# Ver fallos de probes en events
kubectl describe pod <pod-name> | grep -A 5 "Liveness\|Readiness"
```

**Debugging Probes:**

```bash
# Exec en el pod para probar el probe manualmente
kubectl exec <pod-name> -- /bin/sh -c "curl localhost:8080/health"

# Ver si el probe es muy agresivo
# Liveness probe failing:
#   initialDelaySeconds: 10   # ← Too low if app takes 30s to start
#   periodSeconds: 5
#   failureThreshold: 3       # Will kill after 3*5=15 seconds
```

**Fix Common Probe Issues:**

```yaml
# Before (too aggressive)
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 5      # App not ready yet
  periodSeconds: 5
  failureThreshold: 2

# After (more tolerant)
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30     # Give app time to start
  periodSeconds: 10
  failureThreshold: 3
  timeoutSeconds: 5
```

### Debugging Interactivo

#### 1. Exec en Pods

```bash
# Shell en un pod
kubectl exec -it <pod-name> -- /bin/sh
kubectl exec -it <pod-name> -- /bin/bash  # Si bash existe

# En un container específico
kubectl exec -it <pod-name> -c <container-name> -- /bin/sh

# Ejecutar comando único
kubectl exec <pod-name> -- ls /var/log
kubectl exec <pod-name> -- cat /etc/config/app.conf

# Ver variables de entorno
kubectl exec <pod-name> -- env

# Probar conectividad desde dentro del pod
kubectl exec <pod-name> -- ping google.com
kubectl exec <pod-name> -- curl http://backend-service:8080
kubectl exec <pod-name> -- nslookup backend-service
```

#### 2. Debug Pods (Ephemeral Containers)

Kubernetes 1.23+ soporta ephemeral containers para debugging:

```bash
# Agregar debug container a un pod en ejecución
kubectl debug <pod-name> -it --image=busybox --target=<container-name>

# Debug con imagen que tenga herramientas
kubectl debug <pod-name> -it --image=nicolaka/netshoot

# Crear copia del pod con nueva imagen para debug
kubectl debug <pod-name> -it --copy-to=<pod-name>-debug --container=app --image=busybox

# Debug de nodo (útil para troubleshooting de kubelet)
kubectl debug node/<node-name> -it --image=ubuntu
```

#### 3. Port Forward para Testing

```bash
# Forward puerto del pod a localhost
kubectl port-forward pod/<pod-name> 8080:80

# Forward puerto del service
kubectl port-forward service/<service-name> 8080:80

# Ahora puedes probar con curl
curl http://localhost:8080
```

### ConfigMaps y Secrets

#### Verificar ConfigMaps

```bash
# Listar ConfigMaps
kubectl get cm

# Ver contenido
kubectl describe cm <configmap-name>
kubectl get cm <configmap-name> -o yaml

# Verificar que el pod usa el CM correcto
kubectl get pod <pod-name> -o yaml | grep -A 10 configMap
```

**Problema Común: ConfigMap no existe**

```bash
# Pod no puede iniciar porque CM no existe
kubectl describe pod <pod-name>
# Events: Error: configmap "app-config" not found
```

#### Verificar Secrets

```bash
# Listar secrets
kubectl get secrets

# Ver metadata (data está encoded)
kubectl describe secret <secret-name>

# Decodificar secret
kubectl get secret <secret-name> -o jsonpath='{.data.password}' | base64 -d

# Verificar que el pod usa el secret
kubectl get pod <pod-name> -o yaml | grep -A 10 secret
```

### Resource Limits y QoS

#### Diagnosticar OOMKilled

```bash
# Ver límites de recursos
kubectl describe pod <pod-name> | grep -A 5 "Limits\|Requests"

# Ver estado de terminación
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated}'

# Verificar uso de memoria en tiempo real (requiere metrics-server)
kubectl top pod <pod-name>
kubectl top pod <pod-name> --containers
```

**Ejemplo de OOMKilled:**

```yaml
# Pod spec con límites muy bajos
resources:
  limits:
    memory: "128Mi"  # ← Muy bajo para aplicación Java
  requests:
    memory: "64Mi"

# Fix: Aumentar límites
resources:
  limits:
    memory: "512Mi"
  requests:
    memory: "256Mi"
```

#### QoS Classes

Kubernetes asigna QoS class basándose en requests/limits:

```
QoS CLASSES (Calidad de Servicio)
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Guaranteed (Mejor protección)                             │
│  ├─ Todos los containers tienen limits = requests          │
│  └─ Último en ser evicted bajo presión                     │
│                                                             │
│  Burstable (Protección media)                              │
│  ├─ Al menos un container tiene requests o limits          │
│  └─ Evicted después de BestEffort                          │
│                                                             │
│  BestEffort (Sin protección)                               │
│  ├─ Ningún container tiene requests ni limits              │
│  └─ Primero en ser evicted bajo presión                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```bash
# Ver QoS class de un pod
kubectl get pod <pod-name> -o jsonpath='{.status.qosClass}'

# Listar pods por QoS
kubectl get pods -A -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
```

---

## Troubleshooting del Control Plane

El control plane es el cerebro de Kubernetes. Problemas aquí afectan a TODO el cluster.

### Componentes del Control Plane

```
CONTROL PLANE ARCHITECTURE
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────┐                                           │
│  │  API Server │  ← Entry point for all operations         │
│  └──────┬──────┘                                           │
│         │                                                   │
│    ┌────┴────┐                                             │
│    │         │                                             │
│  ┌─▼──┐   ┌─▼────────┐   ┌──────────┐                    │
│  │etcd│   │Scheduler │   │Controller│                    │
│  │    │   │          │   │ Manager  │                    │
│  └────┘   └──────────┘   └──────────┘                    │
│    ▲                                                       │
│    │                                                       │
│    └─── Persistent state store                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1. API Server Issues

El API Server es crítico - si cae, el cluster es inaccesible.

#### Verificar Estado

```bash
# Verificar que API server responde
kubectl cluster-info
kubectl get --raw /healthz
kubectl get --raw /livez
kubectl get --raw /readyz

# Ver componentes del control plane
kubectl get componentstatuses  # Deprecated pero útil
kubectl get pods -n kube-system

# Logs del API server (si es un pod)
kubectl logs -n kube-system kube-apiserver-<node-name>

# En kubeadm clusters (static pod)
sudo cat /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log

# En managed clusters (EKS, AKS, GKE)
# Usa cloud provider logs (CloudWatch, Azure Monitor, Stackdriver)
```

#### Problemas Comunes

**1. Certificate Expired:**

```bash
# Verificar certificates
sudo kubeadm certs check-expiration

# Renovar certificates
sudo kubeadm certs renew all

# Restart API server
sudo docker restart $(sudo docker ps | grep kube-apiserver | awk '{print $1}')
```

**2. etcd Connection Issues:**

```bash
# API server logs mostrarán:
# "Failed to connect to etcd"

# Verificar etcd está corriendo
kubectl get pods -n kube-system | grep etcd

# Ver logs de etcd
kubectl logs -n kube-system etcd-<node-name>

# Verificar endpoints de etcd en API server manifest
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep etcd-servers
```

**3. High API Request Latency:**

```bash
# Verificar métricas (requiere metrics endpoint)
kubectl get --raw /metrics | grep apiserver_request_duration

# Ver requests más lentos
kubectl get --raw /metrics | grep apiserver_request_duration_seconds_bucket

# Posibles causas:
# - etcd slow (disk I/O)
# - Too many watches/list operations
# - Large objects being retrieved
```

### 2. etcd Issues

etcd es la base de datos del cluster. Problemas aquí son **críticos**.

#### Verificar Salud

```bash
# Verificar pod de etcd
kubectl get pods -n kube-system | grep etcd

# Logs
kubectl logs -n kube-system etcd-<node-name>

# Para etcd outside cluster
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Verificar miembros del cluster etcd
ETCDCTL_API=3 etcdctl member list
```

#### Problemas Comunes

**1. etcd Disk Space Full:**

```bash
# Ver alarmas
ETCDCTL_API=3 etcdctl alarm list

# Si "NOSPACE" alarm está activa:
# 1. Liberar espacio (compact + defrag)
ETCDCTL_API=3 etcdctl compact <revision>
ETCDCTL_API=3 etcdctl defrag

# 2. Desarmar alarm
ETCDCTL_API=3 etcdctl alarm disarm
```

**2. etcd Restore desde Backup:**

```bash
# Crear snapshot (backup)
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db

# Verificar snapshot
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot.db

# Restore (requiere detener API server primero)
sudo systemctl stop kube-apiserver

ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restored

# Update etcd manifest para usar nuevo data-dir
sudo vi /etc/kubernetes/manifests/etcd.yaml
# Change: --data-dir=/var/lib/etcd-restored

# Restart
sudo systemctl start kube-apiserver
```

### 3. Scheduler Issues

El scheduler asigna pods a nodos.

#### Verificar Estado

```bash
# Ver pod del scheduler
kubectl get pods -n kube-system | grep kube-scheduler

# Logs
kubectl logs -n kube-system kube-scheduler-<node-name>

# Ver eventos de scheduling
kubectl get events --field-selector reason=FailedScheduling
kubectl get events --field-selector involvedObject.kind=Pod | grep -i schedule
```

#### Problemas Comunes

**Pods en Pending porque no hay nodos que cumplan requisitos:**

```bash
# Diagnosticar por qué no se puede programar
kubectl describe pod <pod-name> | grep -A 10 Events

# Ejemplos de mensajes:
# "0/3 nodes are available: 1 node had taint, 2 Insufficient cpu"
# "0/3 nodes are available: 3 node(s) didn't match node selector"

# Soluciones:
# - Agregar más nodos
# - Reducir requests del pod
# - Quitar node selector/affinity
# - Agregar tolerations para taints
```

### 4. Controller Manager Issues

El controller manager ejecuta todos los controllers (Deployment, ReplicaSet, etc.).

#### Verificar Estado

```bash
# Ver pod
kubectl get pods -n kube-system | grep kube-controller-manager

# Logs
kubectl logs -n kube-system kube-controller-manager-<node-name>

# Ver leases (para leader election)
kubectl get leases -n kube-system
```

#### Problemas Comunes

**ReplicaSets no creando pods:**

```bash
# Ver eventos del ReplicaSet
kubectl describe rs <replicaset-name>

# Verificar controller manager logs
kubectl logs -n kube-system kube-controller-manager-<node-name> | grep -i error

# Posibles causas:
# - Controller manager no está running
# - RBAC permissions issues
# - API server communication problems
```

### Control Plane en Managed Kubernetes

En EKS, AKS, GKE el control plane es managed. Troubleshooting es diferente:

```bash
# AWS EKS - CloudWatch Logs
aws logs filter-log-events --log-group-name /aws/eks/cluster-name/cluster

# Azure AKS - Logs
az aks get-credentials --resource-group myRG --name myCluster
kubectl logs -n kube-system <component-pod>

# GCP GKE - Stackdriver
gcloud logging read "resource.type=k8s_cluster"
```

---

## Troubleshooting de Worker Nodes

Los worker nodes ejecutan los pods. Problemas aquí afectan workloads específicos.

### Node States

```bash
# Ver estado de todos los nodos
kubectl get nodes

# Detalles de un nodo
kubectl describe node <node-name>

# Ver condiciones del nodo
kubectl get node <node-name> -o jsonpath='{.status.conditions[*].type}'
```

**Node Conditions:**

| Condition | Normal Value | Meaning |
|-----------|--------------|---------|
| `Ready` | True | Node puede aceptar pods |
| `MemoryPressure` | False | Node tiene suficiente memoria |
| `DiskPressure` | False | Node tiene suficiente disco |
| `PIDPressure` | False | Node tiene suficientes process IDs |
| `NetworkUnavailable` | False | Network está configurado correctamente |

### Node NotReady

```
NODE NOTREADY TROUBLESHOOTING
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  kubectl get nodes                                          │
│  NAME     STATUS      ROLES    AGE   VERSION                │
│  node-1   NotReady    <none>   5d    v1.28.0                │
│                                                             │
│  Possible Causes:                                           │
│  ├─ kubelet not running                                     │
│  ├─ Network plugin (CNI) failed                             │
│  ├─ Node out of resources                                   │
│  └─ Certificate expired                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Diagnóstico

```bash
# 1. Ver condiciones del nodo
kubectl describe node <node-name> | grep -A 10 Conditions

# 2. SSH al nodo y verificar kubelet
ssh node-1
sudo systemctl status kubelet

# Ver logs de kubelet
sudo journalctl -u kubelet -f

# Verificar kubelet está escuchando
sudo netstat -tlnp | grep kubelet

# 3. Verificar CNI plugin
sudo ls -la /etc/cni/net.d/
sudo ls -la /opt/cni/bin/

# 4. Verificar resources
df -h          # Disk space
free -h        # Memory
top            # CPU and processes

# 5. Verificar certificates
sudo kubeadm certs check-expiration
```

#### Soluciones Comunes

**kubelet no está corriendo:**

```bash
# Restart kubelet
sudo systemctl restart kubelet

# Verificar errores en config
sudo kubelet --config=/var/lib/kubelet/config.yaml --dry-run

# Ver kubelet config
sudo cat /var/lib/kubelet/config.yaml
```

**CNI plugin no instalado o corrupto:**

```bash
# Re-instalar CNI (ejemplo con Calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Verificar CNI pods
kubectl get pods -n kube-system | grep -E 'calico|flannel|weave'
```

**Disk pressure:**

```bash
# Limpiar imágenes no usadas
sudo crictl rmi --prune

# Limpiar logs viejos
sudo journalctl --vacuum-time=1d

# Limpiar containers stopped
sudo crictl rm $(sudo crictl ps -a -q)
```

### Taints y Cordoning

```bash
# Ver taints en nodos
kubectl describe nodes | grep Taints

# Agregar taint (previene scheduling)
kubectl taint nodes <node-name> key=value:NoSchedule

# Remover taint
kubectl taint nodes <node-name> key=value:NoSchedule-

# Cordon (mark as unschedulable, pero pods existentes siguen)
kubectl cordon <node-name>

# Uncordon
kubectl uncordon <node-name>

# Drain (evict todos los pods del nodo)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

### kubelet Issues

```bash
# Ver configuración de kubelet
sudo cat /var/lib/kubelet/config.yaml

# Verificar kubelet puede comunicarse con API server
sudo cat /etc/kubernetes/kubelet.conf

# Ver certificado de kubelet
sudo openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -text -noout

# Restart kubelet con debug logging
sudo systemctl stop kubelet
sudo kubelet --v=5  # Verbose logging
```

### kube-proxy Issues

kube-proxy maneja networking de Services.

```bash
# Ver pods de kube-proxy
kubectl get pods -n kube-system -l k8s-app=kube-proxy

# Logs
kubectl logs -n kube-system <kube-proxy-pod>

# Ver iptables rules (kube-proxy mode iptables)
sudo iptables-save | grep KUBE

# Ver ipvs rules (kube-proxy mode ipvs)
sudo ipvsadm -ln

# Verificar modo de kube-proxy
kubectl logs -n kube-system <kube-proxy-pod> | grep "Using"
# Output: "Using iptables Proxier"
```

**Service no accesible desde dentro del cluster:**

```bash
# 1. Verificar service existe
kubectl get svc <service-name>

# 2. Verificar endpoints
kubectl get endpoints <service-name>

# 3. Ver kube-proxy logs
kubectl logs -n kube-system <kube-proxy-pod>

# 4. Desde un nodo, verificar iptables
sudo iptables-save | grep <service-name>

# 5. Test desde pod de debug
kubectl run test --image=busybox -it --rm -- wget -O- http://<service-name>
```

---

## Troubleshooting de Red

La red en Kubernetes es compleja. Problemas comunes incluyen DNS, Services, Network Policies.

### DNS Troubleshooting

#### CoreDNS Health Check

```bash
# Verificar pods de CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Logs de CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns

# Verificar ConfigMap de CoreDNS
kubectl get cm -n kube-system coredns -o yaml
```

#### Test DNS Resolution

```bash
# Crear pod de debug
kubectl run dnstest --image=busybox:1.28 -it --rm -- sh

# Dentro del pod
nslookup kubernetes.default
nslookup <service-name>.<namespace>.svc.cluster.local
cat /etc/resolv.conf

# Alternativamente, desde fuera
kubectl exec -it <pod-name> -- nslookup kubernetes.default
```

**Problemas Comunes DNS:**

**1. CoreDNS pods no están running:**

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
# Si están CrashLoopBackOff:
kubectl logs -n kube-system -l k8s-app=kube-dns

# Posibles causas:
# - Loop detected (CoreDNS → host DNS → CoreDNS)
# - Insufficient resources
```

**2. DNS resolution lento o timeout:**

```bash
# Ver latencia
kubectl exec -it dnstest -- time nslookup kubernetes.default

# Verificar CPU/Memory de CoreDNS
kubectl top pods -n kube-system -l k8s-app=kube-dns

# Scale CoreDNS si es necesario
kubectl scale deployment coredns -n kube-system --replicas=3
```

**3. Loop detected en CoreDNS:**

```bash
# Ver logs
kubectl logs -n kube-system -l k8s-app=kube-dns | grep loop

# Fix: Editar CoreDNS ConfigMap
kubectl edit cm coredns -n kube-system

# Cambiar de:
#   forward . /etc/resolv.conf
# A:
#   forward . 8.8.8.8 8.8.4.4
```

### Service Troubleshooting

Ver módulo 25 para detalles completos. Resumen:

```bash
# 1. Service existe y tiene endpoints
kubectl get svc <service-name>
kubectl get endpoints <service-name>

# 2. Pods tienen labels correctos
kubectl get pods --show-labels
kubectl get svc <service-name> -o jsonpath='{.spec.selector}'

# 3. Ports son correctos
kubectl get svc <service-name> -o yaml
# Verificar: port, targetPort, protocol

# 4. Test desde dentro del cluster
kubectl run test --image=nicolaka/netshoot -it --rm -- sh
curl http://<service-name>:<port>
```

### Network Policy Troubleshooting

```bash
# Ver network policies
kubectl get networkpolicy
kubectl describe networkpolicy <policy-name>

# Verificar CNI soporta network policies
kubectl get pods -n kube-system | grep -E 'calico|cilium|weave'

# Test conectividad
# Pod A → Pod B
kubectl exec -it pod-a -- wget -O- http://<pod-b-ip>

# Si falla, verificar:
# 1. Default deny policy?
kubectl get netpol -o yaml | grep -A 5 "podSelector: {}"

# 2. Ingress rules permiten tráfico?
kubectl get netpol <policy-name> -o yaml | grep -A 20 ingress

# 3. Namespaces correctos?
kubectl get netpol <policy-name> -o yaml | grep -A 10 namespaceSelector
```

### Ingress Troubleshooting

Ver módulo 25 para detalles. Resumen rápido:

```bash
# 1. Ingress controller está running
kubectl get pods -n ingress-nginx

# 2. Ingress resource existe
kubectl get ingress
kubectl describe ingress <ingress-name>

# 3. Backend service y pods existen
kubectl get svc <backend-service>
kubectl get endpoints <backend-service>

# 4. Logs del ingress controller
kubectl logs -n ingress-nginx <controller-pod>

# 5. Test
curl -H "Host: myapp.example.com" http://<ingress-ip>/
```

---

## Troubleshooting de Storage

### PersistentVolume y PersistentVolumeClaim

#### Estados de PVC

| Estado | Significado | Causa Común |
|--------|-------------|-------------|
| `Pending` | Esperando bind | No hay PV que coincida |
| `Bound` | Conectado a PV | OK |
| `Lost` | PV fue eliminado | PV deletion |

```bash
# Ver PVCs
kubectl get pvc

# Ver PVs
kubectl get pv

# Detalles de PVC
kubectl describe pvc <pvc-name>

# Eventos
kubectl get events --field-selector involvedObject.kind=PersistentVolumeClaim
```

#### Problema: PVC en Pending

```bash
# Diagnóstico
kubectl describe pvc <pvc-name>

# Posibles causas:

# 1. No hay PV con capacidad suficiente
kubectl get pv
# Solución: Crear PV con suficiente storage

# 2. StorageClass no existe
kubectl get sc
kubectl get pvc <pvc-name> -o jsonpath='{.spec.storageClassName}'
# Solución: Crear StorageClass o usar existente

# 3. Access modes no coinciden
kubectl get pvc <pvc-name> -o yaml | grep accessModes
kubectl get pv -o custom-columns=NAME:.metadata.name,ACCESS:.spec.accessModes
# Solución: Ajustar accessModes
```

#### Problema: Pod no puede montar volumen

```bash
# Ver eventos del pod
kubectl describe pod <pod-name> | grep -A 10 Events

# Mensajes comunes:
# "Unable to attach or mount volumes"
# "Permission denied"
# "Volume is already exclusively attached"

# Verificar mount en el nodo
kubectl describe node <node-name> | grep -A 10 "Attached Volumes"

# SSH al nodo y verificar
ssh <node>
sudo lsblk
sudo mount | grep <volume-id>
```

### StatefulSet Storage Issues

```bash
# Ver PVCs creados por StatefulSet
kubectl get pvc -l app=<statefulset-app>

# Verificar volumeClaimTemplates
kubectl get sts <statefulset-name> -o yaml | grep -A 20 volumeClaimTemplates

# Problema: PVC no se crea automáticamente
# Verificar que StorageClass existe y tiene default
kubectl get sc
kubectl describe sc <storage-class-name>
```

---

## Troubleshooting de Performance

### Metrics Server

Primero necesitas metrics-server instalado:

```bash
# Verificar metrics-server
kubectl get deployment metrics-server -n kube-system

# Instalar si no existe
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Ver métricas de nodos
kubectl top nodes

# Ver métricas de pods
kubectl top pods
kubectl top pods --all-namespaces
kubectl top pods --containers  # Por container
```

### Resource Consumption

```bash
# Ver top consumers de CPU
kubectl top pods --all-namespaces --sort-by=cpu

# Ver top consumers de memoria
kubectl top pods --all-namespaces --sort-by=memory

# Ver uso de un namespace
kubectl top pods -n <namespace>

# Detalles de un pod
kubectl top pod <pod-name> --containers
```

### Eviction Troubleshooting

Los nodos pueden evict pods si hay presión de recursos:

```bash
# Ver pods evicted
kubectl get pods --all-namespaces --field-selector=status.phase=Failed

# Detalles de eviction
kubectl describe pod <evicted-pod>
# Reason: Evicted
# Message: The node was low on resource: memory

# Ver condiciones del nodo
kubectl describe node <node-name> | grep -A 10 Conditions
```

**Prevenir Evictions:**

```yaml
# Usar PriorityClass para pods críticos
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
description: "High priority for critical apps"
---
# En el pod
spec:
  priorityClassName: high-priority
```

### HPA (Horizontal Pod Autoscaler) Troubleshooting

```bash
# Ver HPA
kubectl get hpa

# Detalles
kubectl describe hpa <hpa-name>

# Ver eventos
kubectl get events --field-selector involvedObject.kind=HorizontalPodAutoscaler

# Problemas comunes:

# 1. Metrics not available
# Verificar metrics-server está running
kubectl get pods -n kube-system | grep metrics-server

# 2. HPA no escala
# Verificar target metrics
kubectl describe hpa <hpa-name> | grep -A 5 Metrics

# 3. Escala muy frecuentemente
# Ajustar behavior:
kubectl get hpa <hpa-name> -o yaml | grep -A 20 behavior
```

---

## Troubleshooting de Seguridad y RBAC

### RBAC Debugging

```bash
# Verificar si un usuario/SA puede hacer una acción
kubectl auth can-i create pods --as=user@example.com
kubectl auth can-i get secrets --as=system:serviceaccount:default:my-sa

# Ver todos los permisos
kubectl auth can-i --list --as=user@example.com

# Ver Roles y RoleBindings
kubectl get roles,rolebindings -n <namespace>

# Ver ClusterRoles y ClusterRoleBindings
kubectl get clusterroles,clusterrolebindings

# Describe para ver permisos
kubectl describe role <role-name> -n <namespace>
kubectl describe clusterrole <clusterrole-name>
```

### ServiceAccount Issues

```bash
# Ver ServiceAccounts
kubectl get sa

# Ver tokens del SA
kubectl get secret | grep <sa-name>

# Verificar que pod usa el SA correcto
kubectl get pod <pod-name> -o jsonpath='{.spec.serviceAccountName}'

# Ver permisos del SA
kubectl auth can-i --list --as=system:serviceaccount:<namespace>:<sa-name>
```

**Problema: Pod no puede acceder API server**

```bash
# Verificar SA
kubectl get pod <pod-name> -o jsonpath='{.spec.serviceAccountName}'

# Verificar RoleBinding
kubectl get rolebindings -n <namespace> -o yaml | grep <sa-name>

# Exec en pod y probar API
kubectl exec -it <pod-name> -- sh
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces/default/pods
```

### Admission Controller Issues

```bash
# Ver admission controllers habilitados
kubectl exec -it -n kube-system kube-apiserver-<node> -- kube-apiserver -h | grep enable-admission-plugins

# Logs de API server para admissions
kubectl logs -n kube-system kube-apiserver-<node> | grep admission
```

---

## Herramientas de Diagnóstico

### kubectl Tips Avanzados

```bash
# Ver todas las APIs disponibles
kubectl api-resources

# Ver versiones de API
kubectl api-versions

# Explain de cualquier resource
kubectl explain pod.spec.containers.livenessProbe

# Output en diferentes formatos
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pods -o json
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# Filtrar por labels
kubectl get pods -l app=nginx
kubectl get pods -l 'environment in (prod,staging)'

# Filtrar por field selectors
kubectl get pods --field-selector status.phase=Running
kubectl get events --field-selector involvedObject.kind=Pod

# Watch para cambios en tiempo real
kubectl get pods -w
kubectl get events -w

# Dry run (ver qué se va a crear sin crearlo)
kubectl apply -f manifest.yaml --dry-run=client
kubectl apply -f manifest.yaml --dry-run=server

# Diff antes de apply
kubectl diff -f manifest.yaml
```

### Debug Pods y Herramientas

```bash
# netshoot - networking debugging
kubectl run netshoot --image=nicolaka/netshoot -it --rm -- bash

# Dentro puedes usar:
# ping, traceroute, nslookup, dig, curl, wget, netstat, ss, tcpdump, etc.

# busybox - lightweight testing
kubectl run busybox --image=busybox:1.28 -it --rm -- sh

# dnsutils - DNS debugging
kubectl run dnsutils --image=tutum/dnsutils -it --rm -- bash

# curl pod
kubectl run curl --image=curlimages/curl -it --rm -- sh
```

### Logs Avanzados

```bash
# Logs con timestamps
kubectl logs <pod> --timestamps

# Logs desde hace X tiempo
kubectl logs <pod> --since=1h
kubectl logs <pod> --since=10m

# Logs de todos los containers
kubectl logs <pod> --all-containers=true

# Logs de container anterior (crashed)
kubectl logs <pod> --previous

# Follow logs
kubectl logs <pod> -f

# Logs con prefix de container
kubectl logs <pod> --all-containers=true --prefix=true

# Combinar con grep
kubectl logs <pod> | grep ERROR
kubectl logs <pod> | grep -i "exception\|error\|fail"
```

### Events

```bash
# Todos los events
kubectl get events

# Events ordenados por tiempo
kubectl get events --sort-by='.lastTimestamp'

# Events de un namespace
kubectl get events -n <namespace>

# Events de un recurso específico
kubectl get events --field-selector involvedObject.name=<pod-name>

# Events filtrados por type
kubectl get events --field-selector type=Warning
kubectl get events --field-selector type=Normal

# Watch events
kubectl get events -w
```

### Cluster Info

```bash
# Info general del cluster
kubectl cluster-info
kubectl cluster-info dump

# Versión
kubectl version
kubectl version --short

# Config actual
kubectl config view
kubectl config get-contexts
kubectl config current-context

# Nodes info
kubectl get nodes -o wide
kubectl describe nodes

# Component status
kubectl get componentstatuses
kubectl get cs
```

---

## Best Practices

### 1. Logging

```yaml
# Siempre loguea a STDOUT/STDERR
# ❌ Mal - log a archivo
command: ["sh", "-c", "app > /var/log/app.log 2>&1"]

# ✅ Bien - log a stdout
command: ["sh", "-c", "app"]
```

### 2. Health Checks

```yaml
# Siempre define liveness y readiness probes
spec:
  containers:
  - name: app
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

### 3. Resource Limits

```yaml
# Siempre define requests y limits
spec:
  containers:
  - name: app
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

### 4. Labels y Annotations

```yaml
# Usa labels consistentes
metadata:
  labels:
    app: myapp
    version: "1.0"
    environment: production
    tier: backend
  annotations:
    description: "Backend API service"
    owner: "backend-team@company.com"
```

### 5. ConfigMaps y Secrets

```yaml
# Externaliza configuración
# ✅ Bien
env:
- name: DATABASE_URL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: db-url

# ❌ Mal - hardcoded
env:
- name: DATABASE_URL
  value: "postgresql://db:5432/mydb"
```

### 6. Graceful Shutdown

```yaml
# Maneja SIGTERM correctamente
spec:
  containers:
  - name: app
    lifecycle:
      preStop:
        exec:
          command: ["/bin/sh", "-c", "sleep 15"]
  terminationGracePeriodSeconds: 30
```

### 7. Monitoring y Alerting

```yaml
# Exporta métricas
spec:
  containers:
  - name: app
    ports:
    - name: metrics
      containerPort: 9090
      protocol: TCP
    # Prometheus scraping
```

### 8. Debugging Info

```yaml
# Incluye versión en labels para debugging
metadata:
  labels:
    version: "v1.2.3"
    git-commit: "abc123"
    build-date: "2024-11-13"
```

---

## Preparación CKA

### Examen CKA - Troubleshooting Domain

El troubleshooting es **25-30% del examen CKA**. Necesitas:

#### Skills Requeridos

1. **Diagnóstico de Aplicaciones**
   - Identificar por qué pods no inician
   - Debug crashes (CrashLoopBackOff, OOMKilled)
   - Resolver problemas de imagen (ImagePullBackOff)
   - Fix liveness/readiness probes

2. **Diagnóstico de Cluster**
   - Identificar componentes del control plane con problemas
   - Fix worker nodes NotReady
   - Resolver problemas de kubelet

3. **Diagnóstico de Red**
   - Debug DNS issues
   - Fix Services sin endpoints
   - Troubleshoot Network Policies
   - Debug Ingress

4. **Diagnóstico de Storage**
   - Fix PVCs en Pending
   - Resolver mount failures
   - Debug StatefulSet storage

#### Comandos Esenciales

Memoriza estos:

```bash
# Pods
kubectl get pods -A
kubectl describe pod <name>
kubectl logs <pod> --previous
kubectl exec -it <pod> -- sh

# Nodes
kubectl get nodes
kubectl describe node <name>
kubectl top nodes

# Services
kubectl get svc
kubectl get endpoints <svc>

# Events
kubectl get events --sort-by='.lastTimestamp'

# Debugging
kubectl run test --image=busybox -it --rm -- sh
kubectl debug <pod> -it --image=busybox

# Logs de componentes
kubectl logs -n kube-system <component-pod>
```

#### Time Management

- ⏱️ Tienes **2 horas** para completar ~15-20 tareas
- ⏱️ Troubleshooting tasks son típicamente **6-8 minutos** cada una
- ⏱️ Si te atascas más de 5 minutos, **marca y continúa**

#### Estrategia

1. **Lee el problema completo** antes de empezar
2. **Identifica el layer** (app, node, network, storage)
3. **Usa kubectl describe/logs** primero siempre
4. **Verifica lo obvio**: typos, labels, selectors
5. **No asumas nada**: verifica todo
6. **Documenta cambios** si es necesario volver atrás

#### Practice Labs

Los laboratorios de este módulo simulan el examen:

- **Lab 01**: Application Troubleshooting (⭐⭐⭐)
- **Lab 02**: Control Plane & Nodes (⭐⭐⭐⭐)
- **Lab 03**: Network & Storage (⭐⭐⭐⭐)
- **Lab 04**: Complete Cluster Troubleshooting (⭐⭐⭐⭐)

Completa cada lab **sin mirar soluciones** primero.

---

## Resumen

Este módulo cubre troubleshooting en Kubernetes desde fundamentos hasta nivel experto:

### Conceptos Clave

✅ **Metodología Sistemática**: Layer-by-layer approach
✅ **Application Layer**: Pods, containers, crashes, probes
✅ **Control Plane**: API server, etcd, scheduler, controller-manager
✅ **Worker Nodes**: kubelet, kube-proxy, CNI, node status
✅ **Networking**: DNS, Services, Network Policies, Ingress
✅ **Storage**: PV/PVC, mounts, StatefulSets
✅ **Performance**: Resources, QoS, eviction, HPA
✅ **Security**: RBAC, ServiceAccounts, admission controllers
✅ **Herramientas**: kubectl, logs, events, debug pods

### Próximos Pasos

1. **Estudia** RESUMEN-MODULO.md (cheatsheet de comandos)
2. **Practica** con los ejemplos en `ejemplos/`
3. **Completa** los 4 laboratorios en orden
4. **Revisa** logs y eventos de problemas reales
5. **Simula** el examen CKA con time constraints

### CKA Coverage

Este módulo cubre **~25-30%** del examen CKA:
- ✅ Troubleshoot cluster components
- ✅ Troubleshoot applications
- ✅ Troubleshoot networking
- ✅ Monitor cluster components
- ✅ Monitor applications

Con los módulos 22-26, tienes **100% coverage** del CKA! 🎉

---

**Siguiente**: [RESUMEN-MODULO.md](./RESUMEN-MODULO.md) - Cheatsheet para el examen CKA

**Laboratorios**: [laboratorios/README.md](./laboratorios/README.md)

**Módulo Anterior**: [Módulo 25 - Networking](../modulo-25-networking/README.md)
