# 🏗️ Módulo 02: Arquitectura de Cluster Kubernetes

**Duración**: 60 minutos  
**Modalidad**: Teórico-Práctico  
**Dificultad**: Intermedio

## 🎯 Objetivos del Módulo

Al completar este módulo serás capaz de:

- ✅ **Identificar todos los componentes** del Control Plane
- ✅ **Entender la arquitectura** de Worker Nodes
- ✅ **Explicar la comunicación** entre componentes
- ✅ **Diagnosticar problemas** básicos de cluster
- ✅ **Visualizar el flujo** de requests en Kubernetes

---

## 🏛️ 1. Arquitectura General

### **🎯 Vista de Alto Nivel:**

```
┌─────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                       │
│                                                             │
│  ┌─────────────────────┐    ┌─────────────────────────────┐ │
│  │   CONTROL PLANE     │    │       WORKER NODES          │ │
│  │   (Master Nodes)    │◄──►│                             │ │
│  │                     │    │  ┌─────┐ ┌─────┐ ┌─────┐   │ │
│  │  ┌───────────────┐  │    │  │Pod 1│ │Pod 2│ │Pod 3│   │ │
│  │  │ API Server    │  │    │  └─────┘ └─────┘ └─────┘   │ │
│  │  │ etcd          │  │    │                             │ │
│  │  │ Scheduler     │  │    │  ┌─────┐ ┌─────┐ ┌─────┐   │ │
│  │  │ Controller    │  │    │  │Pod 4│ │Pod 5│ │Pod 6│   │ │
│  │  │ Manager       │  │    │  └─────┘ └─────┘ └─────┘   │ │
│  │  └───────────────┘  │    │                             │ │
│  └─────────────────────┘    └─────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### **🔑 Principios Fundamentales:**

1. **Separación de Responsabilidades**: Control vs Workload
2. **API-Driven**: Todo pasa por el API Server
3. **Desired State**: Control loops mantienen estado deseado
4. **Distributed**: Componentes pueden ejecutarse en múltiples nodos
5. **Extensible**: Plugins y custom resources

---

## 🧠 2. Control Plane (Master Nodes)

### **🎛️ Componentes del Control Plane:**

#### **2.1 API Server (kube-apiserver)**

**Función**: Punto de entrada único para todas las operaciones

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   kubectl   │───►│ API Server  │◄───│  Dashboard  │
└─────────────┘    │             │    └─────────────┘
┌─────────────┐───►│ - REST API  │◄───┌─────────────┐
│ Controllers │    │ - Auth      │    │   Client    │
└─────────────┘    │ - Admission │    │    Apps     │
                   │ - Validation│    └─────────────┘
                   └─────────────┘
```

**Responsabilidades:**
- ✅ **Autenticación y autorización** de requests
- ✅ **Validación** de objetos de Kubernetes
- ✅ **Admission control** y políticas
- ✅ **RESTful API** para todos los recursos
- ✅ **Frontend** único para el cluster

**Ejemplo de interacción:**
```bash
# Todo pasa por API Server
kubectl get pods              # → GET /api/v1/pods
kubectl create deployment     # → POST /apis/apps/v1/deployments
kubectl scale deployment      # → PATCH /apis/apps/v1/deployments
```

#### **2.2 etcd - Almacén de Estado**

**Función**: Base de datos distribuida que guarda todo el estado del cluster

```
┌─────────────────────────────────────────┐
│                 etcd                    │
│  ┌─────────────────────────────────────┐ │
│  │        Cluster State                │ │
│  │  ┌─────────┬─────────┬─────────┐   │ │
│  │  │  Pods   │Services │Configma│   │ │
│  │  │         │         │ps       │   │ │
│  │  ├─────────┼─────────┼─────────┤   │ │
│  │  │Deploym. │Secrets  │Nodes    │   │ │
│  │  │         │         │         │   │ │
│  │  └─────────┴─────────┴─────────┘   │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Características:**
- ✅ **Consistencia**: Garantiza ACID properties
- ✅ **Distribuido**: Cluster de múltiples nodos
- ✅ **Backup**: Snapshotting para recovery
- ✅ **Watch API**: Notificaciones de cambios
- ✅ **Encryption**: Datos en reposo encriptados

**Datos almacenados:**
```bash
# Todo el estado del cluster vive en etcd
/registry/pods/default/nginx-pod
/registry/deployments/default/web-app
/registry/services/default/api-service
/registry/configmaps/kube-system/cluster-info
```

#### **2.3 Scheduler (kube-scheduler)**

**Función**: Decide en qué nodo ejecutar cada Pod

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   New Pod   │───►│  Scheduler  │───►│ Best Node   │
│ (unscheduled│    │             │    │             │
│             │    │ ┌─────────┐ │    │             │
└─────────────┘    │ │Filtering│ │    └─────────────┘
                   │ │Scoring  │ │
                   │ │Binding  │ │
                   │ └─────────┘ │
                   └─────────────┘
```

**Proceso de scheduling:**

1. **Filtering (Predicates)**:
```yaml
# Nodos válidos basado en:
- nodeSelector: "disk=ssd"
- resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
- tolerations: 
  - key: "node-type"
    value: "gpu"
```

2. **Scoring (Priorities)**:
```yaml
# Ranking de nodos por:
- LeastRequestedPriority    # Menor uso de recursos
- BalancedResourceAllocation # Balance CPU/Memory
- NodeAffinityPriority      # Afinidad preferida
- InterPodAffinityPriority  # Co-location o anti-affinity
```

3. **Binding**:
```yaml
# Asignar Pod al nodo seleccionado
apiVersion: v1
kind: Binding
metadata:
  name: nginx-pod
target:
  apiVersion: v1
  kind: Node
  name: worker-node-1
```

#### **2.4 Controller Manager (kube-controller-manager)**

**Función**: Ejecuta controllers que mantienen el estado deseado

```
┌─────────────────────────────────────────────┐
│          Controller Manager                 │
│  ┌─────────────┬─────────────┬─────────────┐ │
│  │Deployment   │ReplicaSet   │Node         │ │
│  │Controller   │Controller   │Controller   │ │
│  ├─────────────┼─────────────┼─────────────┤ │
│  │Service      │Endpoint     │Namespace    │ │
│  │Controller   │Controller   │Controller   │ │
│  ├─────────────┼─────────────┼─────────────┤ │
│  │Job          │CronJob      │PV           │ │
│  │Controller   │Controller   │Controller   │ │
│  └─────────────┴─────────────┴─────────────┘ │
└─────────────────────────────────────────────┘
```

**Controllers principales:**

```go
// Ejemplo conceptual: ReplicaSet Controller
for {
    desired := getReplicaSetSpec().Replicas
    current := countRunningPods()
    
    if current < desired {
        createPods(desired - current)
    } else if current > desired {
        deletePods(current - desired)
    }
    
    sleep(reconcileInterval)
}
```

**Controllers críticos:**
- ✅ **Deployment Controller**: Gestiona rolling updates
- ✅ **ReplicaSet Controller**: Mantiene réplicas deseadas
- ✅ **Service Controller**: Configura load balancers
- ✅ **Node Controller**: Monitorea salud de nodos
- ✅ **Namespace Controller**: Limpia recursos eliminados

---

## 🔧 3. Worker Nodes

### **⚙️ Componentes de Worker Nodes:**

#### **3.1 kubelet - Agente de Nodo**

**Función**: Asegura que los contenedores ejecuten según especificación

```
┌─────────────────────────────────────────┐
│                kubelet                  │
│  ┌─────────────────────────────────────┐ │
│  │        Pod Lifecycle                │ │
│  │  ┌─────────┬─────────┬─────────┐   │ │
│  │  │ Pull    │ Start   │ Health  │   │ │
│  │  │ Images  │ Pods    │ Checks  │   │ │
│  │  └─────────┴─────────┴─────────┘   │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────────────────────────┐ │
│  │         Node Status                 │ │
│  │  ┌─────────┬─────────┬─────────┐   │ │
│  │  │Resources│Network  │ Storage │   │ │
│  │  │ Usage   │ Status  │ Status  │   │ │
│  │  └─────────┴─────────┴─────────┘   │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Responsabilidades:**
```yaml
# kubelet gestiona:
podSpec:
  containers:
  - name: app
    image: nginx:1.20
    ports:
    - containerPort: 80
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
    livenessProbe:
      httpGet:
        path: /health
        port: 80
    volumeMounts:
    - name: data
      mountPath: /var/data
```

#### **3.2 kube-proxy - Networking**

**Función**: Implementa Services y load balancing

```
┌─────────────────────────────────────────┐
│               kube-proxy                │
│                                         │
│  ┌─────────────┐    ┌─────────────┐    │
│  │   Service   │───►│   iptables  │    │
│  │   Rules     │    │    Rules    │    │
│  └─────────────┘    └─────────────┘    │
│                                         │
│  ┌─────────────┐    ┌─────────────┐    │
│  │ EndpointS   │───►│   IPVS      │    │
│  │   Updates   │    │   Config    │    │
│  └─────────────┘    └─────────────┘    │
└─────────────────────────────────────────┘
```

**Modos de operación:**

1. **iptables mode** (default):
```bash
# kube-proxy crea reglas como:
iptables -A KUBE-SERVICES -d 10.96.0.1/32 -p tcp --dport 443 -j KUBE-SVC-NPX46M4PTMTKRN6Y
iptables -A KUBE-SVC-NPX46M4PTMTKRN6Y -m statistic --mode random --probability 0.33333 -j KUBE-SEP-ID1
```

2. **IPVS mode** (high performance):
```bash
# kube-proxy configura IPVS:
ipvsadm -A -t 10.96.0.1:443 -s rr
ipvsadm -a -t 10.96.0.1:443 -r 192.168.1.10:6443 -m
ipvsadm -a -t 10.96.0.1:443 -r 192.168.1.11:6443 -m
```

#### **3.3 Container Runtime**

**Función**: Ejecuta y gestiona contenedores

```
┌─────────────────────────────────────────┐
│           Container Runtime             │
│                                         │
│  ┌─────────────┐    ┌─────────────┐    │
│  │   Docker    │    │ containerd  │    │
│  │   Engine    │    │             │    │
│  └─────────────┘    └─────────────┘    │
│                                         │
│  ┌─────────────┐    ┌─────────────┐    │
│  │   CRI-O     │    │    runc     │    │
│  │             │    │  (OCI)      │    │
│  └─────────────┘    └─────────────┘    │
└─────────────────────────────────────────┘
```

**Container Runtime Interface (CRI)**:
```protobuf
// kubelet habla con runtime via CRI
service RuntimeService {
    rpc CreateContainer(CreateContainerRequest) returns (CreateContainerResponse);
    rpc StartContainer(StartContainerRequest) returns (StartContainerResponse);
    rpc StopContainer(StopContainerRequest) returns (StopContainerResponse);
    rpc RemoveContainer(RemoveContainerRequest) returns (RemoveContainerResponse);
}
```

---

## 🔄 4. Flujo de Comunicación

### **📡 Request Flow Ejemplo:**

```
kubectl create deployment nginx --image=nginx
    │
    ▼
┌─────────────────────────────────────────────────┐
│ 1. API Server                                   │
│    ├─ Autenticación ✓                          │
│    ├─ Autorización ✓                           │
│    ├─ Admission Controllers ✓                  │
│    └─ Validación ✓                             │
└─────────────┬───────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────────┐
│ 2. etcd                                         │
│    └─ Guarda Deployment object                 │
└─────────────┬───────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────────┐
│ 3. Deployment Controller                        │
│    ├─ Detecta nuevo Deployment (watch)         │
│    └─ Crea ReplicaSet                          │
└─────────────┬───────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────────┐
│ 4. ReplicaSet Controller                        │
│    ├─ Detecta nuevo ReplicaSet (watch)         │
│    └─ Crea Pod                                 │
└─────────────┬───────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────────┐
│ 5. Scheduler                                    │
│    ├─ Detecta Pod sin nodo (watch)             │
│    ├─ Evalúa nodos disponibles                 │
│    └─ Asigna Pod a mejor nodo                  │
└─────────────┬───────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────────┐
│ 6. kubelet (en nodo seleccionado)              │
│    ├─ Detecta Pod asignado (watch)             │
│    ├─ Descarga imagen                          │
│    ├─ Crea contenedor                          │
│    └─ Reporta estado a API Server              │
└─────────────────────────────────────────────────┘
```

### **⚡ Watch API Pattern:**

```go
// Todos los componentes usan watch para eficiencia
watch, err := clientset.CoreV1().Pods("default").Watch(context.TODO(), metav1.ListOptions{})
for event := range watch.ResultChan() {
    switch event.Type {
    case watch.Added:
        handlePodAdded(event.Object)
    case watch.Modified:
        handlePodModified(event.Object)
    case watch.Deleted:
        handlePodDeleted(event.Object)
    }
}
```

---

## 🔍 5. Estados y Condiciones

### **📊 Node Conditions:**

```yaml
# kubectl describe node worker-1
Conditions:
  Type                 Status  Reason                       Message
  ----                 ------  ------                       -------
  NetworkUnavailable   False   RouteCreated                 
  MemoryPressure       False   KubeletHasSufficientMemory   
  DiskPressure         False   KubeletHasNoDiskPressure     
  PIDPressure          False   KubeletHasSufficientPID      
  Ready                True    KubeletReady                 
```

### **🔄 Pod Phases:**

```yaml
# Lifecycle de un Pod
Pod Phases:
  Pending    → Pod creado, esperando scheduling/descarga imagen
  Running    → Contenedores ejecutándose
  Succeeded  → Containers terminated successfully (Jobs)
  Failed     → Containers terminated with errors
  Unknown    → Node communication lost
```

### **⚕️ Container States:**

```yaml
# Estados de contenedores individuales
Container States:
  Waiting:
    reason: "ImagePullBackOff"
  Running:
    startedAt: "2023-01-01T10:00:00Z"
  Terminated:
    exitCode: 0
    finishedAt: "2023-01-01T11:00:00Z"
```

---

## 🛠️ 6. Troubleshooting Arquitectura

### **🔧 Comandos de Diagnóstico:**

#### **Control Plane Health:**
```bash
# Verificar componentes del control plane
kubectl get componentstatuses
kubectl get nodes
kubectl cluster-info

# Logs de componentes
kubectl logs -n kube-system kube-apiserver-master
kubectl logs -n kube-system etcd-master
kubectl logs -n kube-system kube-scheduler-master
kubectl logs -n kube-system kube-controller-manager-master
```

#### **Worker Node Health:**
```bash
# En el worker node
systemctl status kubelet
systemctl status docker  # o containerd
journalctl -u kubelet -f

# Network troubleshooting
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

#### **etcd Health:**
```bash
# Verificar etcd cluster
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/server.crt \
  --key=/etc/etcd/server.key \
  endpoint health

# Backup de etcd
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  snapshot save backup.db
```

### **🚨 Problemas Comunes:**

| Síntoma | Causa Probable | Solución |
|---------|----------------|----------|
| Pods "Pending" | Scheduler down / No resources | Check scheduler logs / Add nodes |
| Services not working | kube-proxy issues | Restart kube-proxy |
| API slow | etcd performance | Check etcd metrics |
| Nodes "NotReady" | kubelet/network issues | Check kubelet logs |

---

## 📊 7. Arquitecturas de Despliegue

### **🏠 Single-Node (Minikube/Kind):**
```
┌─────────────────────────┐
│    Single Node         │
│  ┌─────────────────┐   │
│  │ Control Plane   │   │
│  ├─────────────────┤   │
│  │ Worker          │   │
│  │ Components      │   │
│  └─────────────────┘   │
└─────────────────────────┘
```

### **🏢 Multi-Master HA:**
```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Master 1   │  │  Master 2   │  │  Master 3   │
│             │  │             │  │             │
└─────────────┘  └─────────────┘  └─────────────┘
       │                │                │
       └────────────────┼────────────────┘
                        │
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Worker 1   │  │  Worker 2   │  │  Worker N   │
└─────────────┘  └─────────────┘  └─────────────┘
```

### **☁️ Managed Kubernetes:**
```
┌─────────────────────────────────────┐
│        Cloud Provider               │
│  ┌─────────────────────────────────┐ │
│  │     Managed Control Plane       │ │  ← Invisible
│  │   (API Server, etcd, etc.)      │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
              │
┌─────────────┐  ┌─────────────┐
│  Worker 1   │  │  Worker N   │      ← You manage
└─────────────┘  └─────────────┘
```

---

## 🧪 Laboratorio: Explorando la Arquitectura

### **[🔬 Lab: Cluster Architecture Deep Dive](./laboratorios/cluster-architecture-lab.md)**

En este laboratorio vas a:
- Instalar y configurar Minikube
- Explorar todos los componentes del control plane
- Analizar la comunicación entre componentes
- Diagnosticar problemas comunes
- Entender el flujo de requests

**Duración**: 45 minutos  
**Dificultad**: Intermedio

---

## 📚 8. Conceptos Avanzados

### **🔐 Security Context:**
```yaml
# Los componentes ejecutan con privilegios mínimos
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

### **📊 Resource Management:**
```yaml
# Control plane components también tienen límites
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kube-apiserver
    resources:
      requests:
        cpu: 250m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 1Gi
```

### **🔄 High Availability:**
```yaml
# Control plane distribuido
- Multiple masters (odd number: 3, 5, 7)
- etcd cluster (separate from masters recommended)
- Load balancer in front of API servers
- Shared storage for persistent data
```

---

## ✅ Resumen del Módulo

### **🎯 Lo que aprendiste:**

1. **Control Plane Components**:
   - API Server como punto único de entrada
   - etcd como almacén de estado distribuido
   - Scheduler para placement de Pods
   - Controller Manager para mantener estado deseado

2. **Worker Node Components**:
   - kubelet como agente de nodo
   - kube-proxy para networking
   - Container runtime para ejecutar contenedores

3. **Communication Patterns**:
   - Watch API para eficiencia
   - Reconciliation loops en controllers
   - Desired state management

4. **Troubleshooting**:
   - Comandos de diagnóstico
   - Logs y métricas
   - Problemas comunes y soluciones

### **🔄 Preparación para siguiente módulo:**

Con este conocimiento de arquitectura, estás listo para:
- Instalar tu propio cluster (Minikube)
- Entender cómo los comandos kubectl afectan los componentes
- Diagnosticar problemas cuando aparezcan
- Apreciar la robustez del diseño de Kubernetes

---

## ⏭️ Siguiente Paso

**¡Ahora instalemos Kubernetes!**

🎯 **Próximo módulo**: **[M03: Instalación de Minikube](../modulo-03-instalacion-minikube/README.md)**

Donde vas a:
- Instalar Minikube en tu sistema
- Configurar kubectl
- Crear tu primer cluster
- Verificar todos los componentes que acabas de aprender

---

## 🏠 Navegación

- **[⬅️ M01: Introducción](../modulo-01-introduccion-kubernetes/README.md)**
- **[🏠 Área 2: Índice Principal](../README-NUEVO.md)**
- **[➡️ M03: Instalación Minikube](../modulo-03-instalacion-minikube/README.md)**