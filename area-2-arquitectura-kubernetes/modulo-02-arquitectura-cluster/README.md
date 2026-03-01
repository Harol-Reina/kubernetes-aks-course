# Capítulo 4: Arquitectura de un Cluster Kubernetes

Con Kubernetes presentado, exploramos su arquitectura interna: el plano de control, los nodos worker y cómo cada componente contribuye al funcionamiento del cluster.

---

## 🏛️ 1. Arquitectura General

### **🎯 Vista de Alto Nivel:**

```mermaid
graph TB
    subgraph "🚀 KUBERNETES CLUSTER"
        subgraph "🎛️ CONTROL PLANE"
            API[📡 kube-apiserver<br/>REST API Gateway]
            ETCD[🗄️ etcd<br/>Distributed Database]
            SCHED[🧠 kube-scheduler<br/>Pod Placement]
            CM[🎮 kube-controller-manager<br/>State Management]
            CCM[☁️ cloud-controller-manager<br/>Cloud Integration]
        end
        
        subgraph "💪 WORKER NODES"
            subgraph "🖥️ Node 1"
                KUBELET1[🤖 kubelet]
                PROXY1[🌐 kube-proxy]
                RUNTIME1[🐳 containerd]
                PODS1[📦 Pods 1-5]
            end
            
            subgraph "🖥️ Node 2"
                KUBELET2[🤖 kubelet]
                PROXY2[🌐 kube-proxy]
                RUNTIME2[🐳 containerd]
                PODS2[📦 Pods 6-10]
            end
            
            subgraph "🖥️ Node 3"
                KUBELET3[🤖 kubelet]
                PROXY3[🌐 kube-proxy]
                RUNTIME3[🐳 containerd]
                PODS3[📦 Pods 11-15]
            end
        end
        
        subgraph "🌐 EXTERNAL ACCESS"
            LB[⚖️ Load Balancer]
            ING[🚪 Ingress Controller]
            EXT[🌍 External Traffic]
        end
    end
    
    %% Control Plane Internal
    API -.-> ETCD
    API -.-> SCHED
    API -.-> CM
    API -.-> CCM
    
    %% Control Plane to Workers
    API --> KUBELET1
    API --> KUBELET2
    API --> KUBELET3
    
    %% Worker Node Internal
    KUBELET1 --> RUNTIME1
    KUBELET1 --> PODS1
    PROXY1 -.-> PODS1
    
    KUBELET2 --> RUNTIME2
    KUBELET2 --> PODS2
    PROXY2 -.-> PODS2
    
    KUBELET3 --> RUNTIME3
    KUBELET3 --> PODS3
    PROXY3 -.-> PODS3
    
    %% External Access
    EXT --> LB
    LB --> ING
    ING --> PROXY1
    ING --> PROXY2
    ING --> PROXY3
    
    %% Styling
    classDef controlPlane fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef workerNode fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef external fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef pods fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    class API,ETCD,SCHED,CM,CCM controlPlane
    class KUBELET1,KUBELET2,KUBELET3,PROXY1,PROXY2,PROXY3,RUNTIME1,RUNTIME2,RUNTIME3 workerNode
    class LB,ING,EXT external
    class PODS1,PODS2,PODS3 pods
```

### **📋 Explicación del Diagrama:**

**🎛️ CONTROL PLANE (Plano de Control):**
- **📡 kube-apiserver**: Punto central de comunicación - todos los componentes hablan con él
- **🗄️ etcd**: Base de datos distribuida que almacena todo el estado del cluster
- **🧠 kube-scheduler**: Inteligencia que decide en qué nodo colocar cada Pod
- **🎮 kube-controller-manager**: Gestores que mantienen el estado deseado del sistema
- **☁️ cloud-controller-manager**: Integración específica con proveedores de nube

**💪 WORKER NODES (Nodos de Trabajo):**
- **🤖 kubelet**: Agente en cada nodo que ejecuta y monitorea los Pods
- **🌐 kube-proxy**: Gestiona la red y el balanceo de carga para los servicios
- **🐳 containerd**: Runtime que ejecuta los contenedores dentro de los Pods
- **📦 Pods**: Unidades mínimas de despliegue que contienen las aplicaciones

**🌐 ACCESO EXTERNO:**
- **🌍 External Traffic**: Tráfico de usuarios externos (internet, VPN, etc.)
- **⚖️ Load Balancer**: Distribuye el tráfico entre múltiples puntos de entrada
- **🚪 Ingress Controller**: Enruta las requests HTTP/HTTPS a los servicios internos

**🔄 Flujo de Comunicación:**
1. **Control Interno**: API Server se comunica con etcd para persistir estado
2. **Coordinación**: Scheduler y Controller Manager consultan API Server para decisiones
3. **Ejecución**: API Server envía instrucciones a kubelet en cada worker node
4. **Networking**: kube-proxy gestiona la conectividad entre Pods y servicios
5. **Acceso Externo**: External Traffic → Load Balancer → Ingress → kube-proxy → Pods

**🎨 Diagrama Interactivo Completo:**

[![Kubernetes Cluster Overview](https://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/svg/cluster-overview.svg)](https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/cluster-overview.drawio)

> 🔗 **[Abrir diagrama interactivo en Draw.io](https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/cluster-overview.drawio)**

### **🔑 Principios Fundamentales:**

1. **Separación de Responsabilidades**: Control vs Workload
2. **API-Driven**: Todo pasa por el API Server
3. **Desired State**: Control loops mantienen estado deseado
4. **Distributed**: Componentes pueden ejecutarse en múltiples nodos
5. **Extensible**: Plugins y custom resources

---

## 🧠 2. Control Plane (Master Nodes)

```mermaid
graph TB
    subgraph "🎛️ CONTROL PLANE COMPONENTS"
        API[📡 kube-apiserver<br/>- REST API Gateway<br/>- Authentication & Authorization<br/>- Request Validation<br/>- Admission Controllers]
        ETCD[🗄️ etcd<br/>- Distributed Key-Value Store<br/>- Cluster State<br/>- Configuration Data<br/>- Secrets & ConfigMaps]
        SCHED[🧠 kube-scheduler<br/>- Pod Placement Decisions<br/>- Resource Requirements<br/>- Node Selection<br/>- Affinity Rules]
        CM[🎮 kube-controller-manager<br/>- Deployment Controller<br/>- ReplicaSet Controller<br/>- Node Controller<br/>- Service Account Controller]
        CCM[☁️ cloud-controller-manager<br/>- Node Lifecycle Management<br/>- Route Controller<br/>- Service Controller<br/>- Volume Controller]
    end
    
    subgraph "🔄 CONTROL FLOW"
        USER[👤 User/kubectl]
        WORKER[💪 Worker Nodes]
    end
    
    USER --> API
    API --> ETCD
    API --> SCHED
    API --> CM
    API --> CCM
    SCHED --> API
    CM --> API
    CCM --> API
    API --> WORKER
    
    classDef api fill:#e3f2fd,stroke:#1976d2,stroke-width:3px
    classDef storage fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef controllers fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef external fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    
    class API api
    class ETCD storage
    class SCHED,CM,CCM controllers
    class USER,WORKER external
```

**� Diagrama Detallado del Control Plane:**

[![Control Plane Detailed](https://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/svg/control-plane-detailed.svg)](https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/control-plane-detailed.drawio)

> 🔗 **[Abrir diagrama interactivo en Draw.io](https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/control-plane-detailed.drawio)**

### **🎛️ Componentes del Control Plane:**

#### **2.1 API Server (kube-apiserver)**

```mermaid
graph LR
    subgraph "🌐 CLIENT REQUESTS"
        KUBECTL[🖥️ kubectl]
        DASH[📊 Dashboard]
        APPS[📱 Client Apps]
        CTRL[🎮 Controllers]
    end
    
    subgraph "📡 kube-apiserver"
        subgraph "🔐 Authentication Layer"
            TLS[🔒 TLS Certificates]
            SA[👤 Service Accounts]
            JWT[🎫 JWT Tokens]
            OIDC[🆔 OIDC Providers]
        end
        
        subgraph "🛡️ Authorization Layer"
            RBAC[👥 RBAC]
            ABAC[📋 ABAC]
            NODE[🖥️ Node Authorization]
            WEBHOOK[🔗 Webhook]
        end
        
        subgraph "✅ Validation & Admission"
            SCHEMA[📝 Schema Validation]
            SEMANTIC[🧠 Semantic Validation]
            MUTATING[🔄 Mutating Admission]
            VALIDATING[✅ Validating Admission]
        end
        
        subgraph "🗄️ Storage Interface"
            ETCD_INT[📊 etcd Interface]
        end
    end
    
    KUBECTL --> TLS
    DASH --> SA
    APPS --> JWT
    CTRL --> SA
    
    TLS --> RBAC
    SA --> RBAC
    JWT --> RBAC
    OIDC --> RBAC
    
    RBAC --> SCHEMA
    ABAC --> SEMANTIC
    NODE --> MUTATING
    WEBHOOK --> VALIDATING
    
    SCHEMA --> ETCD_INT
    SEMANTIC --> ETCD_INT
    MUTATING --> ETCD_INT
    VALIDATING --> ETCD_INT
    
    classDef client fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef auth fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef authz fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef validation fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef storage fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    
    class KUBECTL,DASH,APPS,CTRL client
    class TLS,SA,JWT,OIDC auth
    class RBAC,ABAC,NODE,WEBHOOK authz
    class SCHEMA,SEMANTIC,MUTATING,VALIDATING validation
    class ETCD_INT storage
```

**Función**: Punto de entrada único para todas las operaciones del cluster

[![API Server Request Flow](https://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/svg/api-request-flow.svg)](https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/api-request-flow.drawio)

**� Flujo completo de procesamiento de requests en el API Server de Kubernetes**

El API Server de Kubernetes procesa todas las requests siguiendo un pipeline estructurado en 4 etapas principales:

#### 🔐 **Etapa 1: Autenticación**
- **TLS Certificates**: Autenticación mutua con certificados y cadena de CA
- **Service Accounts**: Cuentas de servicio por defecto y personalizadas con gestión de tokens
- **JWT Tokens**: Tokens Bearer con verificación de expiración y firma
- **OIDC Providers**: Identidad externa integrada con LDAP y Active Directory

#### 🛡️ **Etapa 2: Autorización**
- **RBAC**: Control de acceso basado en roles con Roles y RoleBindings
- **ABAC**: Control de acceso basado en atributos con motor de políticas
- **Node Authorization**: Permisos específicos para kubelet y recursos de nodos
- **Webhook**: Autorización externa con motor de políticas personalizado

#### ✅ **Etapa 3: Validación y Control de Admisión**
- **Schema Validation**: Verificación de esquema JSON con validación de tipos y formatos
- **Semantic Validation**: Verificación de lógica de negocio y dependencias de recursos
- **Mutating Admission**: Modificación de objetos con inyección de valores por defecto y etiquetas
- **Validating Admission**: Aplicación de políticas y cumplimiento de seguridad

#### 🗄️ **Etapa 4: Interfaz de Almacenamiento**
- **Operaciones CRUD**: Creación, lectura, actualización y eliminación de recursos
- **Watch Streams**: Actualizaciones en tiempo real con notificaciones de eventos
- **Actualizaciones Atómicas**: Seguridad transaccional con garantías de consistencia
- **Historial de Eventos**: Auditoría y seguimiento de cambios
- **Consistencia**: Consistencia fuerte con cumplimiento ACID

[🔗 **Editar Diagrama en Draw.io**](https://app.diagrams.net/?mode=github&url=https%3A%2F%2Fraw.githubusercontent.com%2Fuser%2Frepo%2Fbranch%2Fassets%2Fdiagrams%2F02-arquitectura-cluster%2Fapi-request-flow.drawio)
                                                                                         │


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

#### **2.2 etcd - Almacén de Estado Distribuido**

```mermaid
graph TB
    subgraph "🗄️ etcd CLUSTER"
        subgraph "📊 DATA STORAGE"
            KV[🔑 Key-Value Store<br/>- Hierarchical Keys<br/>- JSON Values<br/>- Versioning]
            CLUSTER[🏛️ Cluster State<br/>- Nodes<br/>- Pods<br/>- Services<br/>- Endpoints]
            CONFIG[⚙️ Configuration<br/>- ConfigMaps<br/>- Secrets<br/>- Network Policies]
            EVENTS[📝 Event History<br/>- API Calls<br/>- State Changes<br/>- Audit Logs]
        end
        
        subgraph "🔄 RAFT CONSENSUS"
            LEADER[👑 Leader Node<br/>- Write Operations<br/>- Log Replication<br/>- Heartbeats]
            FOLLOWER1[🤝 Follower 1<br/>- Read Operations<br/>- Vote in Elections<br/>- Replicate Logs]
            FOLLOWER2[🤝 Follower 2<br/>- Read Operations<br/>- Vote in Elections<br/>- Replicate Logs]
        end
        
        subgraph "🛡️ BACKUP & RECOVERY"
            SNAPSHOT[📸 Snapshots<br/>- Point-in-time<br/>- Automated<br/>- Compression]
            WAL[📜 Write-Ahead Log<br/>- Transaction Log<br/>- Recovery<br/>- Durability]
        end
    end
    
    subgraph "🔗 CLIENT CONNECTIONS"
        API_SERVER[📡 kube-apiserver]
        WATCH[👁️ Watch Streams]
        BACKUP_TOOL[💾 Backup Tools]
    end
    
    API_SERVER --> LEADER
    API_SERVER --> FOLLOWER1
    API_SERVER --> FOLLOWER2
    
    LEADER --> FOLLOWER1
    LEADER --> FOLLOWER2
    
    FOLLOWER1 -.-> LEADER
    FOLLOWER2 -.-> LEADER
    
    LEADER --> SNAPSHOT
    LEADER --> WAL
    
    WATCH --> API_SERVER
    BACKUP_TOOL --> SNAPSHOT
    
    classDef storage fill:#e8f5e8,stroke:#388e3c,stroke-width:3px
    classDef consensus fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef backup fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef client fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    
    class KV,CLUSTER,CONFIG,EVENTS storage
    class LEADER,FOLLOWER1,FOLLOWER2 consensus
    class SNAPSHOT,WAL backup
    class API_SERVER,WATCH,BACKUP_TOOL client
```

**Función**: Base de datos distribuida que almacena todo el estado del cluster

**🏗️ Arquitectura de Almacenamiento etcd:**
```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                              🗄️ etcd DISTRIBUTED DATABASE                                       │
│                                                                                                 │
│  ┌────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                            📊 DATA ORGANIZATION                                            │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐           │ │
│  │  │🏛️ Cluster State │ │⚙️ Configuration │ │🔐 Secrets       │ │📦 ConfigMaps    │           │ │
│  │  │                 │ │                 │ │                 │ │                 │           │ │
│  │  │/registry/       │ │/registry/       │ │/registry/       │ │/registry/       │           │ │
│  │  │  nodes/         │ │  configmaps/    │ │  secrets/       │ │  configmaps/    │           │ │
│  │  │  pods/          │ │  networkpolicies│ │  default/       │ │  kube-system/   │           │ │
│  │  │  services/      │ │  storageclasses/│ │  kube-system/   │ │  default/       │           │ │
│  │  │  endpoints/     │ │  csinodes/      │ │  tls-certs/     │ │  app-configs/   │           │ │
│  │  │  deployments/   │ │  persistentv/   │ │  docker-registry│ │  feature-flags/ │           │ │
│  │  │  replicasets/   │ │  validating/    │ │  ssh-keys/      │ │  environments/  │           │ │
│  │  │  namespaces/    │ │  mutating/      │ │  api-tokens/    │ │  templates/     │           │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘           │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐           │ │
│  │  │📝 Events        │ │👥 RBAC          │ │🌐 Network       │ │💾 Storage       │           │ │
│  │  │                 │ │                 │ │                 │ │                 │           │ │
│  │  │/registry/       │ │/registry/       │ │/registry/       │ │/registry/       │           │ │
│  │  │  events/        │ │  roles/         │ │  services/      │ │  persistentv/   │           │ │
│  │  │  audit/         │ │  rolebindings/  │ │  ingresses/     │ │  storageclasses/│           │ │
│  │  │  warnings/      │ │  clusterroles/  │ │  networkpolicies│ │  volumeclaims/  │           │ │
│  │  │  normal/        │ │  clusterrolebind│ │  endpoints/     │ │  csidriver/     │           │ │
│  │  │  failed/        │ │  serviceaccounts│ │  endpointslices/│ │  csistoragecap/ │           │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘           │ │
│  └────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                         ▲                                                       │
│                                         │                                                       │
│  ┌──────────────────────────────────────┼─────────────────────────────────────────────────────┐ │
│  │                         🔄 RAFT CONSENSUS ALGORITHM                                        │ │
│  │                                      │                                                     │ │
│  │  ┌───────────────────────────────────┼─────────────────────────────────────────────────┐   │ │
│  │  │                   👑 LEADER NODE  │                                                 │   │ │
│  │  │  ┌─────────────────┐ ┌────────────┼──────────┐ ┌─────────────────┐ ┌──────────────┐ │   │ │
│  │  │  │📝 Write Ops     │ │🔄 Log Repl │ication   │ │💓 Heartbeats    │ │⚖️ LoadBalance│ │   │ │
│  │  │  │   - PUT/POST    │ │   - Entries│          │ │   - Health      │ │              │ │   │ │
│  │  │  │   - DELETE      │ │   - Order  │          │ │   - Timeout     │ │              │ │   │ │
│  │  │  │   - PATCH       │ │   - Commit │          │ │   - Election    │ │              │ │   │ │
│  │  │  └─────────────────┘ └────────────┼──────────┘ └─────────────────┘ └──────────────┘ │   │ │
│  │  └───────────────────────────────────┼─────────────────────────────────────────────────┘   │ │
│  │                                      ▼                                                     │ │
│  │  ┌───────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                            🤝 FOLLOWER NODES                                          │ │ │
│  │  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐      │ │ │
│  │  │  │📖 Read Ops      │ │🗳️ Elections     │ │📥 Log Entries   │ │🔍 Health Checks │      │ │ │
│  │  │  │   - GET         │ │   - Vote Cast   │ │   - Replication │ │   - Node Status │      │ │ │
│  │  │  │   - LIST        │ │   - Term Inc    │ │   - Apply Order │ │   - Conn Status │      │ │ │
│  │  │  │   - WATCH       │ │   - Candidate   │ │   - Consistency │ │   - Sync Status │      │ │ │
│  │  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘      │ │ │
│  │  └───────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                         ▲                                                       │
│                                         │                                                       │
│  ┌──────────────────────────────────────┼─────────────────────────────────────────────────────┐ │
│  │                      🛡️ BACKUP & RECOVERY SYSTEM                                           │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐           │ │
│  │  │📸 Snapshots     │ │📜 Write-Ahead   │ │🔄 Recovery      │ │🗜️ Compression   │           │ │
│  │  │   - Point-time  │ │   Log (WAL)     │ │   - Auto Repair │ │   - Storage Opt │           │ │
│  │  │   - Scheduled   │ │   - Durability  │ │   - Data Restore│ │   - Bandwidth   │           │ │
│  │  │   - Manual      │ │   - Transaction │ │   - Consistency │ │   - Encryption  │           │ │
│  │  │   - Incremental │ │   - Recovery    │ │   - Validation  │ │   - Dedup       │           │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘           │ │
│  └────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Responsabilidades:**
- ✅ **Almacenamiento** de todo el estado del cluster
- ✅ **Consistencia** ACID para operaciones críticas
- ✅ **Distribución** con consenso RAFT para alta disponibilidad
- ✅ **Watch API** para notificaciones en tiempo real
- ✅ **Backup/Recovery** con snapshots automáticos
- ✅ **Encriptación** de datos en reposo

**Ejemplo de datos almacenados:**
```bash
# Estructura jerárquica en etcd
/registry/pods/default/nginx-deployment-abc123
/registry/deployments/default/web-application
/registry/services/default/api-gateway-service
/registry/configmaps/kube-system/cluster-configuration
/registry/secrets/default/database-credentials
```

#### **2.3 Scheduler (kube-scheduler)**

```mermaid
graph TB
    subgraph "🧠 kube-scheduler WORKFLOW"
        subgraph "📥 INPUT PHASE"
            QUEUE[📋 Scheduling Queue<br/>- Priority Queue<br/>- Pending Pods<br/>- Backoff Management]
            WATCH[👁️ Watch API<br/>- New Pods<br/>- Node Updates<br/>- Resource Changes]
        end
        
        subgraph "🔍 FILTERING PHASE"
            PREDICATES[🎯 Node Predicates<br/>- Resource Requirements<br/>- Node Constraints<br/>- Affinity Rules<br/>- Taints & Tolerations]
            FEASIBLE[✅ Feasible Nodes<br/>- Filtered Results<br/>- Available Nodes<br/>- Resource Capacity]
        end
        
        subgraph "📊 SCORING PHASE"
            PRIORITIES[🏆 Priority Functions<br/>- Resource Utilization<br/>- Affinity Preferences<br/>- Spreading Policies<br/>- Custom Schedulers]
            RANKING[📈 Node Ranking<br/>- Weighted Scores<br/>- Best Fit Selection<br/>- Load Balancing]
        end
        
        subgraph "🎯 BINDING PHASE"
            BINDING[🔗 Pod Binding<br/>- API Server Update<br/>- Node Assignment<br/>- Status Update]
            KUBELET[🤖 kubelet Notification<br/>- Pod Creation<br/>- Container Start<br/>- Status Report]
        end
    end
    
    subgraph "🔄 FEEDBACK LOOP"
        METRICS[📊 Metrics Collection]
        OPTIMIZATION[⚡ Performance Tuning]
    end
    
    WATCH --> QUEUE
    QUEUE --> PREDICATES
    PREDICATES --> FEASIBLE
    FEASIBLE --> PRIORITIES
    PRIORITIES --> RANKING
    RANKING --> BINDING
    BINDING --> KUBELET
    
    KUBELET --> METRICS
    METRICS --> OPTIMIZATION
    OPTIMIZATION --> QUEUE
    
    classDef input fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef filtering fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef scoring fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef binding fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef feedback fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    
    class QUEUE,WATCH input
    class PREDICATES,FEASIBLE filtering
    class PRIORITIES,RANKING scoring
    class BINDING,KUBELET binding
    class METRICS,OPTIMIZATION feedback
```

**Función**: Inteligencia para la colocación óptima de Pods en el cluster

[![Scheduler Process](../../assets/diagrams/02-arquitectura-cluster/svg/scheduler-process.svg)](../../assets/diagrams/02-arquitectura-cluster/scheduler-process.drawio)

**🎯 Proceso Profesional de Scheduling:**

> 🔗 **[Editar Diagrama en Draw.io](https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/scheduler-process.drawio)**

**📋 Etapas del Proceso:**

1. **📥 INPUT**: Monitor de nuevos pods y cambios de nodos
2. **🔍 FILTERING**: Aplicación de predicados para encontrar nodos viables  
3. **📊 SCORING**: Clasificación de nodos usando funciones de prioridad
4. **🎯 BINDING**: Asignación del pod al mejor nodo y notificación al kubelet

**⚡ Métricas de Rendimiento:**
- **Tiempo típico**: 5-10ms por pod
- **Throughput**: 1000+ pods/segundo  
- **Predicados estándar**: 15+ filtros automáticos
- **Funciones de prioridad**: 10+ algoritmos de scoring
```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  ┌────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                           📊 SCORING PHASE (Priorities)                            │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │ │
│  │  │⚖️ Load Balancing│ │📏 Resource Util │ │🎯 Affinity Pref │ │🌍 Zone Spread   │   │ │
│  │  │   - Even Distrib│ │   - CPU Usage   │ │   - Preferences │ │   - Multi-Zone  │   │ │
│  │  │   - Replica Spr │ │   - Memory Load │ │   - Soft Rules  │ │   - Failure Dom │   │ │
│  │  │   - Anti-Affin  │ │   - Disk I/O    │ │   - Weights     │ │   - Region Dist │   │ │
│  │  │   - Pod Density │ │   - Network BW  │ │   - Priorities  │ │   - Rack Aware  │   │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘   │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │ │
│  │  │🏆 Priority Class│ │💰 Cost Optimiz  │ │🔧 Maintenance   │ │📊 Performance   │   │ │
│  │  │   - High Prior  │ │   - Spot Inst   │ │   - Drain Nodes │ │   - Latency     │   │ │
│  │  │   - Preemption  │ │   - Reserved    │ │   - Upgrades    │ │   - Throughput  │   │ │
│  │  │   - QoS Classes │ │   - On-Demand   │ │   - Cordon      │ │   - IOPS        │   │ │
│  │  │   - SLA Levels  │ │   - Savings     │ │   - Scheduling  │ │   - Optimization│   │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘│
│                                         ▼                                               │
│  ┌────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                            🎯 BINDING & NOTIFICATION                               │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │ │
│  │  │🔗 Pod Binding   │ │📡 API Update    │ │🤖 kubelet Notify│ │📊 Metrics       │   │ │
│  │  │   - Node Assign │ │   - etcd Write  │ │   - Pod Creation│ │   - Schedule    │   │ │
│  │  │   - Spec Update │ │   - Event Log   │ │   - Image Pull  │ │   - Latency     │   │ │
│  │  │   - Status Set  │ │   - Audit Trail │ │   - Container   │ │   - Success Rate│   │ │
│  │  │   - Annotation  │ │   - Watch Notify│ │   - Health Check│ │   - Node Utiliz │   │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘   │ │
│  └────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```
**Ejemplo de proceso de scheduling:**

1. **Filtering (Predicates)**:
```yaml
# Nodos válidos basado en:
spec:
  nodeSelector: 
    disk: "ssd"
    zone: "us-west-1a"
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
      nvidia.com/gpu: "1"
  tolerations: 
  - key: "node-type"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "topology.kubernetes.io/zone"
            operator: In
            values: ["us-west-1a", "us-west-1b"]
```

2. **Scoring (Priorities)**:
```yaml
# Ranking de nodos por:
- LeastRequestedPriority: 85      # Menor uso de recursos (85/100)
- BalancedResourceAllocation: 78  # Balance CPU/Memory (78/100)
- NodeAffinityPriority: 92        # Cumple preferencias (92/100)
- InterPodAffinityPriority: 71    # Cumple afinidad pods (71/100)
- TaintTolerationPriority: 100    # Tolera taints (100/100)
- SelectorSpreadPriority: 88      # Distribución uniforme (88/100)
# Nodo final seleccionado: node-gpu-west-1a (Score: 89/100)
```

3. **Binding**:
```bash
# Resultado final
kubectl get pod web-app-abc123 -o wide
NAME            READY   STATUS    NODE
web-app-abc123  1/1     Running   node-gpu-west-1a
```

#### **2.4 Controller Manager (kube-controller-manager)**

```mermaid
graph TB
    subgraph "🎮 kube-controller-manager"
        subgraph "🚀 WORKLOAD CONTROLLERS"
            DEPLOY[📦 Deployment Controller<br/>- Rolling Updates<br/>- Rollback Management<br/>- Revision History]
            RS[📋 ReplicaSet Controller<br/>- Pod Scaling<br/>- Replica Management<br/>- Pod Recreation]
            JOB[🎫 Job Controller<br/>- Batch Processing<br/>- Completion Tracking<br/>- Parallel Execution]
            CRON[⏰ CronJob Controller<br/>- Scheduled Execution<br/>- History Management<br/>- Timezone Support]
        end
        
        subgraph "🖥️ NODE CONTROLLERS"
            NODE[🖥️ Node Controller<br/>- Health Monitoring<br/>- Lease Management<br/>- Eviction Control]
            NSL[🌐 NodeLifecycle Controller<br/>- Ready/NotReady States<br/>- Taint Management<br/>- Pod Eviction]
        end
        
        subgraph "🌐 SERVICE CONTROLLERS"
            SVC[🌐 Service Controller<br/>- Endpoint Management<br/>- Load Balancer Sync<br/>- ClusterIP Assignment]
            EP[🔗 Endpoint Controller<br/>- Service Discovery<br/>- Pod IP Tracking<br/>- Health Checks]
            ING[🚪 Ingress Controller<br/>- Traffic Routing<br/>- TLS Termination<br/>- Path-based Routing]
        end
        
        subgraph "🔐 SECURITY CONTROLLERS"
            SA[👤 ServiceAccount Controller<br/>- Token Management<br/>- Secret Injection<br/>- RBAC Integration]
            RBAC[🛡️ RBAC Controller<br/>- Role Management<br/>- Permission Updates<br/>- Access Control]
        end
        
        subgraph "📁 RESOURCE CONTROLLERS"
            NS[📁 Namespace Controller<br/>- Lifecycle Management<br/>- Resource Cleanup<br/>- Finalizers]
            PV[💾 PersistentVolume Controller<br/>- Volume Binding<br/>- Storage Classes<br/>- Provisioning]
            QUOTA[📊 ResourceQuota Controller<br/>- Usage Tracking<br/>- Limit Enforcement<br/>- Reporting]
        end
    end
    
    subgraph "🔄 CONTROL LOOP"
        API_WATCH[👁️ API Server Watch]
        DESIRED[🎯 Desired State]
        CURRENT[📊 Current State]
        RECONCILE[🔄 Reconciliation]
    end
    
    API_WATCH --> DESIRED
    DESIRED --> CURRENT
    CURRENT --> RECONCILE
    RECONCILE --> API_WATCH
    
    %% Controller connections
    DEPLOY --> RECONCILE
    RS --> RECONCILE
    JOB --> RECONCILE
    CRON --> RECONCILE
    NODE --> RECONCILE
    NSL --> RECONCILE
    SVC --> RECONCILE
    EP --> RECONCILE
    ING --> RECONCILE
    SA --> RECONCILE
    RBAC --> RECONCILE
    NS --> RECONCILE
    PV --> RECONCILE
    QUOTA --> RECONCILE
    
    classDef workload fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef node fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef service fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef security fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef resource fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef control fill:#f9fbe7,stroke:#689f38,stroke-width:2px
    
    class DEPLOY,RS,JOB,CRON workload
    class NODE,NSL node
    class SVC,EP,ING service
    class SA,RBAC security
    class NS,PV,QUOTA resource
    class API_WATCH,DESIRED,CURRENT,RECONCILE control
```

**Función**: Conjunto de control loops que mantienen el estado deseado del cluster
**🔄 Control Loop Pattern (Reconciliation)**:
```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                          🎮 CONTROLLER MANAGER - CONTROL LOOPS                           │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              🔄 RECONCILIATION PATTERN                              │ │
│  │                                                                                     │ │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐           │ │
│  │  │👁️ Watch API │───►│🎯 Desired   │───►│📊 Current   │───►│🔄 Reconcile │           │ │
│  │  │   Events    │    │   State     │    │   State     │    │   Actions   │           │ │
│  │  │             │    │             │    │             │    │             │           │ │
│  │  │- Create     │    │- Spec       │    │- Status     │    │- Create     │           │ │
│  │  │- Update     │    │- Replicas: 3│    │- Ready: 2   │    │- Update     │           │ │
│  │  │- Delete     │    │- Image      │    │- Conditions │    │- Delete     │           │ │
│  │  │- Error      │    │- Resources  │    │- Metrics    │    │- Scale      │           │ │
│  │  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘           │ │
│  │          ▲                                                        │                 │ │
│  │          │                                                        ▼                 │ │
│  │          └────────────────────────── CONTINUOUS LOOP ─────────────┘                 │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                            🚀 WORKLOAD CONTROLLERS                                  │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │📦 Deployment    │ │📋 ReplicaSet    │ │🎫 Job           │ │⏰ CronJob       │    │ │
│  │  │   Controller    │ │   Controller    │ │   Controller    │ │   Controller    │    │ │
│  │  │                 │ │                 │ │                 │ │                 │    │ │
│  │  │🔄 Rolling Update│ │📊 Scale Up/Down │ │✅ Completion    │ │📅 Schedule      │    │ │
│  │  │📚 Revisions     │ │🔄 Pod Recreation│ │🔁 Retry Logic   │ │📈 History Mgmt  │    │ │
│  │  │⏪ Rollback      │ │⚖️ Load Balance  │ │⏸️ Parallelism   │ │🕐 Timezone      │    │ │
│  │  │🎯 Strategy      │ │🏥 Health Check  │ │🔒 Security Ctx  │ │🚫 Suspend       │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                           🖥️ INFRASTRUCTURE CONTROLLERS                             │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │🖥️ Node          │ │🔄 NodeLifecycle │ │🌐 Service       │ │🔗 Endpoint      │    │ │
│  │  │   Controller    │ │   Controller    │ │   Controller    │ │   Controller    │    │ │
│  │  │                 │ │                 │ │                 │ │                 │    │ │
│  │  │💓 Health Mon    │ │🟢 Ready/NotReady│ │⚖️ Load Balancer │ │🎯 Service Disc  │    │ │
│  │  │⏰ Lease Mgmt    │ │🏷️ Taint Mgmt    │ │🌐 ClusterIP     │ │📍 Pod IP Track  │    │ │
│  │  │🚫 Eviction      │ │👥 Pod Eviction  │ │🔄 Sync External │ │🔍 Health Check  │    │ │
│  │  │📊 Conditions    │ │🕐 Grace Period  │ │📡 External IP   │ │📊 Ready Count   │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                            🔐 SECURITY & ACCESS CONTROLLERS                         │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │👤 ServiceAccount│ │🛡️ RBAC          │ │📁 Namespace     │ │🎫 Token         │    │ │
│  │  │   Controller    │ │   Controller    │ │   Controller    │ │   Controller    │    │ │
│  │  │                 │ │                 │ │                 │ │                 │    │ │
│  │  │🔑 Token Mgmt    │ │👥 Role Mgmt     │ │🔄 Lifecycle     │ │⏰ Rotation      │    │ │
│  │  │🔐 Secret Inject │ │🔐 Permission    │ │🧹 Cleanup       │ │🚫 Expiration    │    │ │
│  │  │🔗 RBAC Integr   │ │📋 Updates       │ │🏁 Finalizers    │ │🔐 Auto-mount    │    │ │
│  │  │📊 Auto-creation │ │🔍 Access Control│ │🗑️ Resource Del  │ │📊 Usage Track   │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                           💾 STORAGE & RESOURCE CONTROLLERS                         │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │💾 PersistentVol │ │📊 ResourceQuota │ │🚫 LimitRange    │ │🗂️ CSI           │    │ │
│  │  │   Controller    │ │   Controller    │ │   Controller    │ │   Controller    │    │ │
│  │  │                 │ │                 │ │                 │ │                 │    │ │
│  │  │🔗 Volume Bind   │ │📈 Usage Track   │ │⚖️ Resource Limit│ │🔌 Driver Mgmt   │    │ │
│  │  │🏭 Provisioning  │ │🚫 Limit Enforce │ │🔍 Validation    │ │📦 Volume Attach │    │ │
│  │  │📊 Storage Class │ │📊 Reporting     │ │📋 Default Set   │ │🔄 Mount/Unmount │    │ │
│  │  │🔄 Status Update │ │🔔 Alerts        │ │🎯 Policy Apply  │ │🛠️ Capabilities  │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                          │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

**Ejemplo de Controller en acción:**

```yaml
# Deployment deseado
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3              # DESIRED STATE
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

```bash
# Controller detecta diferencia y reconcilia
kubectl get pods -l app=web
NAME                      READY   STATUS    RESTARTS   AGE
web-app-abc123           1/1     Running   0          30s
web-app-def456           1/1     Running   0          30s
# Solo 2 pods → Controller crea el tercero
web-app-ghi789           0/1     Pending   0          1s


┌──────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────┐ │
│  │Controller   │Controller   │Controller   │ │
│  └─────────────┴─────────────┴─────────────┘ │
└──────────────────────────────────────────────┘
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

#### **2.5 Cloud Controller Manager (cloud-controller-manager)**

```mermaid
graph TB
    subgraph "☁️ cloud-controller-manager"
        subgraph "🖥️ NODE MANAGEMENT"
            NODE_LM[🖥️ Node Lifecycle Manager<br/>- Instance Provisioning<br/>- Termination Handling<br/>- Health Monitoring<br/>- Auto-scaling Integration]
        end
        
        subgraph "🛣️ NETWORK MANAGEMENT"
            ROUTE[🛣️ Route Controller<br/>- Network Routing<br/>- Subnet Management<br/>- Firewall Rules<br/>- VPC Integration]
        end
        
        subgraph "🌐 SERVICE MANAGEMENT"
            LB[⚖️ LoadBalancer Controller<br/>- External Load Balancers<br/>- Health Checks<br/>- Traffic Distribution<br/>- SSL Termination]
        end
        
        subgraph "💾 STORAGE MANAGEMENT"
            VOL[💾 Volume Controller<br/>- Persistent Volume Provisioning<br/>- Snapshot Management<br/>- Backup Automation<br/>- Storage Classes]
        end
        
        subgraph "🔐 SECURITY & IAM"
            IAM[🔐 IAM Integration<br/>- Service Account Mapping<br/>- Role Assignment<br/>- Policy Enforcement<br/>- Token Exchange]
        end
    end
    
    subgraph "☁️ CLOUD PROVIDERS"
        AWS[🟠 AWS<br/>- EC2<br/>- ELB<br/>- EBS<br/>- IAM]
        GCP[🔵 Google Cloud<br/>- Compute Engine<br/>- Cloud Load Balancing<br/>- Persistent Disk<br/>- Cloud IAM]
        AZURE[🔷 Azure<br/>- Virtual Machines<br/>- Load Balancer<br/>- Managed Disks<br/>- Azure AD]
        OTHERS[⚪ Others<br/>- OpenStack<br/>- VMware<br/>- DigitalOcean<br/>- Alibaba Cloud]
    end
    
    NODE_LM --> AWS
    NODE_LM --> GCP
    NODE_LM --> AZURE
    NODE_LM --> OTHERS
    
    ROUTE --> AWS
    ROUTE --> GCP
    ROUTE --> AZURE
    
    LB --> AWS
    LB --> GCP
    LB --> AZURE
    
    VOL --> AWS
    VOL --> GCP
    VOL --> AZURE
    
    IAM --> AWS
    IAM --> GCP
    IAM --> AZURE
    
    classDef node fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef network fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef service fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef storage fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef security fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef cloud fill:#f9fbe7,stroke:#689f38,stroke-width:2px
    
    class NODE_LM node
    class ROUTE network
    class LB service
    class VOL storage
    class IAM security
    class AWS,GCP,AZURE,OTHERS cloud
```

**Función**: Interfaz entre Kubernetes y proveedores de nube

**☁️ Integración con Proveedores de Nube:**
```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                         ☁️ CLOUD CONTROLLER MANAGER                                      │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                           🖥️ NODE LIFECYCLE MANAGEMENT                              │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │🚀 Provisioning  │ │💀 Termination   │ │💓 Health Mon    │ │📈 Auto-scaling  │    │ │
│  │  │   - Instance Sz │ │   - Graceful    │ │   - Node Ready  │ │   - Scale Up    │    │ │
│  │  │   - AMI/Image   │ │   - Drain Pods  │ │   - Resource    │ │   - Scale Down  │    │ │
│  │  │   - Security Gr │ │   - Cleanup     │ │   - Network     │ │   - Triggers    │    │ │
│  │  │   - Tagging     │ │   - Spot Handle │ │   - Storage     │ │   - Policies    │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                         ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                           🛣️ NETWORK & ROUTING MANAGEMENT                           │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │🌐 Route Tables  │ │🔥 Firewall      │ │🏢 VPC/VNet      │ │📡 DNS           │    │ │
│  │  │   - Pod CIDR    │ │   - Security Gr │ │   - Subnets     │ │   - Service     │    │ │
│  │  │   - Service     │ │   - Network ACL │ │   - Peering     │ │   - Discovery   │    │ │
│  │  │   - External    │ │   - Ingress     │ │   - Gateways    │ │   - External    │    │ │
│  │  │   - Multi-zone  │ │   - Egress      │ │   - NAT         │ │   - Resolution  │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                         ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                           🌐 SERVICE & LOAD BALANCER MANAGEMENT                     │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │⚖️ Load Balancer │ │🔍 Health Checks │ │📊 Traffic Dist  │ │🔐 SSL/TLS       │    │ │
│  │  │   - External LB │ │   - HTTP/TCP    │ │   - Round Robin │ │   - Cert Mgmt   │    │ │
│  │  │   - Internal LB │ │   - Custom      │ │   - Weighted    │ │   - Termination │    │ │
│  │  │   - Layer 4/7   │ │   - Endpoints   │ │   - Geolocation │ │   - SNI         │    │ │
│  │  │   - Multi-zone  │ │   - Failover    │ │   - Sticky Sess │ │   - Auto-renew  │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                         ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                            💾 STORAGE & VOLUME MANAGEMENT                           │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │🏭 Dynamic Prov  │ │📸 Snapshots     │ │🔄 Backup        │ │📊 Storage Class │    │ │
│  │  │   - PV Creation │ │   - Point-time  │ │   - Automated   │ │   - Performance │    │ │
│  │  │   - Auto-attach │ │   - Incremental │ │   - Retention   │ │   - Encryption  │    │ │
│  │  │   - Mount/Unmnt │ │   - Cross-region│ │   - Restore     │ │   - Replication │    │ │
│  │  │   - Resize      │ │   - Scheduling  │ │   - Compliance  │ │   - Access Mode │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                         │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

**Responsabilidades por Cloud Provider:**

```yaml
# AWS Integration
aws:
  nodeLifecycle:
    - instanceTypes: ["m5.large", "c5.xlarge", "t3.medium"]
    - spotInstances: true
    - autoScaling: enabled
    - tagging: 
        Environment: "production"
        Team: "platform"
  loadBalancer:
    - type: "Network Load Balancer"
    - crossZone: true
    - sslPolicy: "ELBSecurityPolicy-TLS-1-2-2017-01"
  storage:
    - ebs: ["gp3", "io2", "sc1"]
    - efs: enabled
    - backup: automated

# Google Cloud Integration  
gcp:
  nodeLifecycle:
    - machineTypes: ["e2-standard-4", "n1-standard-2"]
    - preemptible: true
    - autoScaling: enabled
  loadBalancer:
    - type: "Global Load Balancer"
    - cdn: enabled
    - ssl: managed
  storage:
    - persistentDisk: ["pd-ssd", "pd-balanced"]
    - filestore: enabled
    - backup: scheduled

# Azure Integration
azure:
  nodeLifecycle:
    - vmSizes: ["Standard_D2s_v3", "Standard_B2ms"]
    - spotInstances: true
    - vmss: enabled
  loadBalancer:
    - type: "Standard Load Balancer"
    - zones: ["1", "2", "3"]
    - ssl: applicationGateway
  storage:
    - managedDisks: ["Premium_SSD", "Standard_SSD"]
    - azureFiles: enabled
    - backup: vaults
```

---

## 🔧 3. Worker Nodes

```mermaid
graph TB
    subgraph "💪 WORKER NODE ARCHITECTURE"
        subgraph "🤖 kubelet"
            POD_MGMT[📦 Pod Management<br/>- Pod Lifecycle<br/>- Container Runtime Interface<br/>- Resource Monitoring<br/>- Health Checks]
            NODE_STATUS[📊 Node Status Reporting<br/>- Resource Usage<br/>- Capacity Information<br/>- Conditions & Events<br/>- Heartbeat to API Server]
        end
        
        subgraph "🌐 kube-proxy"
            SERVICE_PROXY[🔄 Service Proxy<br/>- iptables/IPVS Rules<br/>- Load Balancing<br/>- Session Affinity<br/>- Traffic Distribution]
            NETWORK[🌐 Network Management<br/>- Cluster Networking<br/>- Service Discovery<br/>- Port Forwarding<br/>- NAT Rules]
        end
        
        subgraph "🐳 Container Runtime"
            CRI[🔌 Container Runtime Interface<br/>- containerd/CRI-O/Docker<br/>- Image Management<br/>- Container Lifecycle<br/>- Security Context]
            CNI[🌐 Container Network Interface<br/>- Network Plugins<br/>- IP Address Management<br/>- Network Policies<br/>- Multi-tenancy]
            CSI[💾 Container Storage Interface<br/>- Volume Plugins<br/>- Storage Provisioning<br/>- Mount Management<br/>- Encryption]
        end
        
        subgraph "📦 RUNNING WORKLOADS"
            PODS[📦 Pod Instances<br/>- Application Containers<br/>- Sidecar Containers<br/>- Init Containers<br/>- Ephemeral Containers]
        end
    end
    
    subgraph "🔗 EXTERNAL INTERFACES"
        API_SERVER[📡 API Server]
        REGISTRY[📚 Container Registry]
        STORAGE[💾 External Storage]
        NETWORK_EXT[🌐 External Network]
    end
    
    NODE_STATUS --> API_SERVER
    POD_MGMT --> API_SERVER
    CRI --> REGISTRY
    CSI --> STORAGE
    CNI --> NETWORK_EXT
    SERVICE_PROXY --> NETWORK_EXT
    
    POD_MGMT --> CRI
    POD_MGMT --> PODS
    CRI --> PODS
    CNI --> PODS
    CSI --> PODS
    SERVICE_PROXY --> PODS
    
    classDef kubelet fill:#e3f2fd,stroke:#1976d2,stroke-width:3px
    classDef proxy fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef runtime fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef workload fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef external fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    
    class POD_MGMT,NODE_STATUS kubelet
    class SERVICE_PROXY,NETWORK proxy
    class CRI,CNI,CSI runtime
    class PODS workload
    class API_SERVER,REGISTRY,STORAGE,NETWORK_EXT external
```

**🎨 Diagrama Detallado de Worker Nodes:**

[![Worker Nodes Detailed](https://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/svg/worker-nodes-detailed.svg)](https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/worker-nodes-detailed.drawio)

> 🔗 **[Abrir diagrama interactivo en Draw.io](https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/worker-nodes-detailed.drawio)**

### **⚙️ Componentes de Worker Nodes:**

#### **3.1 kubelet - Agente de Nodo**

```mermaid
graph TB
    subgraph "🤖 kubelet AGENT"
        subgraph "📦 POD LIFECYCLE MANAGEMENT"
            PODSPEC[📋 PodSpec Processing<br/>- Manifest Validation<br/>- Resource Allocation<br/>- Security Context<br/>- Init Containers]
            LIFECYCLE[🔄 Container Lifecycle<br/>- Image Pulling<br/>- Container Creation<br/>- Health Monitoring<br/>- Restart Policies]
            CLEANUP[🧹 Cleanup Operations<br/>- Pod Termination<br/>- Resource Cleanup<br/>- Garbage Collection<br/>- Log Rotation]
        end
        
        subgraph "📊 NODE STATUS & MONITORING"
            RESOURCES[📊 Resource Monitoring<br/>- CPU/Memory Usage<br/>- Disk I/O<br/>- Network Stats<br/>- Custom Metrics]
            HEALTH[💓 Health Reporting<br/>- Node Conditions<br/>- Ready Status<br/>- Capacity Info<br/>- Allocatable Resources]
            EVENTS[📝 Event Generation<br/>- Pod Events<br/>- Node Events<br/>- Warning/Error Events<br/>- Audit Logging]
        end
        
        subgraph "🔌 RUNTIME INTERFACES"
            CRI_CLIENT[🐳 CRI Client<br/>- Container Runtime<br/>- Image Management<br/>- Runtime Status<br/>- Security Features]
            CNI_CLIENT[🌐 CNI Client<br/>- Network Setup<br/>- IP Management<br/>- Network Policies<br/>- Multi-tenancy]
            CSI_CLIENT[💾 CSI Client<br/>- Volume Operations<br/>- Mount/Unmount<br/>- Storage Monitoring<br/>- Encryption]
        end
        
        subgraph "🔐 SECURITY & ADMISSION"
            ADMISSION[🛡️ Admission Control<br/>- Pod Security Standards<br/>- Resource Validation<br/>- Policy Enforcement<br/>- Runtime Security]
            CERTS[🔐 Certificate Management<br/>- Node Authentication<br/>- TLS Rotation<br/>- CA Validation<br/>- Secure Communication]
        end
    end
    
    subgraph "🔄 EXTERNAL COMMUNICATION"
        API_SERVER[📡 API Server]
        REGISTRY[📚 Container Registry]
        RUNTIME[🐳 Container Runtime]
        NETWORK[🌐 Network Plugins]
        STORAGE[💾 Storage Plugins]
    end
    
    PODSPEC --> API_SERVER
    HEALTH --> API_SERVER
    EVENTS --> API_SERVER
    
    CRI_CLIENT --> RUNTIME
    CRI_CLIENT --> REGISTRY
    CNI_CLIENT --> NETWORK
    CSI_CLIENT --> STORAGE
    
    LIFECYCLE --> CRI_CLIENT
    LIFECYCLE --> CNI_CLIENT
    LIFECYCLE --> CSI_CLIENT
    
    ADMISSION --> PODSPEC
    CERTS --> API_SERVER
    
    classDef lifecycle fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef monitoring fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef interfaces fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef security fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef external fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    
    class PODSPEC,LIFECYCLE,CLEANUP lifecycle
    class RESOURCES,HEALTH,EVENTS monitoring
    class CRI_CLIENT,CNI_CLIENT,CSI_CLIENT interfaces
    class ADMISSION,CERTS security
    class API_SERVER,REGISTRY,RUNTIME,NETWORK,STORAGE external
```

**Función**: Agente principal que ejecuta y gestiona los Pods en cada nodo

**🔄 Ciclo de Vida Completo de un Pod:**
```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                               🤖 kubelet POD LIFECYCLE                                   │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                            📥 POD SPECIFICATION PROCESSING                          │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │📋 Manifest      │ │🔍 Validation    │ │📊 Resource      │ │🔐 Security      │    │ │
│  │  │   Reception     │ │   - Schema      │ │   Allocation    │ │   Context       │    │ │
│  │  │   - API Watch   │ │   - Semantic    │ │   - CPU/Memory  │ │   - User/Group  │    │ │
│  │  │   - Config File │ │   - Policy      │ │   - Storage     │ │   - Capabilities│    │ │
│  │  │   - Static Pods │ │   - Admission   │ │   - Network     │ │   - SELinux     │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                         ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              🔄 INITIALIZATION PHASE                                │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │🌐 Network Setup │ │💾 Volume Mount  │ │🔧 Init Container│ │📋 Environment   │    │ │
│  │  │   - Pod IP      │ │   - PV Binding  │ │   - Pre-work    │ │   - ConfigMaps  │    │ │
│  │  │   - DNS Config  │ │   - Mount Points│ │   - Dependencies│ │   - Secrets     │    │ │
│  │  │   - Network Pol │ │   - Permissions │ │   - Setup Tasks │ │   - Variables   │    │ │
│  │  │   - CNI Plugin  │ │   - Encryption  │ │   - Exit Codes  │ │   - Service Acc │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                         ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                             🚀 CONTAINER EXECUTION                                  │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │📥 Image Pull    │ │🐳 Container     │ │💓 Health Checks │ │📊 Resource      │    │ │
│  │  │   - Registry    │ │   Creation      │ │   - Liveness    │ │   Monitoring    │    │ │
│  │  │   - Auth        │ │   - Runtime     │ │   - Readiness   │ │   - CPU Usage   │    │ │
│  │  │   - Layers      │ │   - Security    │ │   - Startup     │ │   - Memory      │    │ │
│  │  │   - Caching     │ │   - Namespaces  │ │   - Custom      │ │   - Disk I/O    │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                         ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              📊 MONITORING & REPORTING                              │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │💓 Status Report │ │📝 Event Gen     │ │🔔 Alerts        │ │📈 Metrics       │    │ │
│  │  │   - Pod Status  │ │   - Lifecycle   │ │   - Failures    │ │   - Performance │    │ │
│  │  │   - Node Health │ │   - Errors      │ │   - Resource    │ │   - Availability│    │ │
│  │  │   - Conditions  │ │   - Warnings    │ │   - Threshold   │ │   - Utilization │    │ │
│  │  │   - Heartbeat   │ │   - Audit       │ │   - SLA         │ │   - Trends      │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                         ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              🧹 CLEANUP & TERMINATION                               │ │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │ │
│  │  │⏹️ Graceful Stop │ │🗑️ Resource      │ │🧹 Garbage       │ │📋 Final Status  │    │ │
│  │  │   - SIGTERM     │ │   Cleanup       │ │   Collection    │ │   - Exit Codes  │    │ │
│  │  │   - Grace Period│ │   - Volumes     │ │   - Logs        │ │   - Timestamps  │    │ │
│  │  │   - SIGKILL     │ │   - Network     │ │   - Images      │ │   - Conditions  │    │ │
│  │  │   - Exit Hooks  │ │   - Storage     │ │   - Containers  │ │   - Events      │    │ │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                          │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

#### **3.2 kube-proxy - Networking**

**Función**: Implementa Services y load balancing

```
┌─────────────────────────────────────────┐
│               kube-proxy                │
│                                         │
│  ┌─────────────┐    ┌─────────────┐     │
│  │   Service   │───►│   iptables  │     │
│  │   Rules     │    │    Rules    │     │
│  └─────────────┘    └─────────────┘     │
│                                         │
│  ┌─────────────┐    ┌─────────────┐     │
│  │ EndpointS   │───►│   IPVS      │     │
│  │   Updates   │    │   Config    │     │
│  └─────────────┘    └─────────────┘     │
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
│  ┌─────────────┐    ┌─────────────┐     │
│  │   Docker    │    │ containerd  │     │
│  │   Engine    │    │             │     │
│  └─────────────┘    └─────────────┘     │
│                                         │
│  ┌─────────────┐    ┌─────────────┐     │
│  │   CRI-O     │    │    runc     │     │
│  │             │    │  (OCI)      │     │
│  └─────────────┘    └─────────────┘     │
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
│    ├─ Autenticación ✓                           │
│    ├─ Autorización ✓                            │
│    ├─ Admission Controllers ✓                   │
│    └─ Validación ✓                              │
└─────────────┬───────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────────┐
│ 2. etcd                                         │
│    └─ Guarda Deployment object                  │
└─────────────┬───────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────────┐
│ 3. Deployment Controller                        │
│    ├─ Detecta nuevo Deployment (watch)          │
│    └─ Crea ReplicaSet                           │
└─────────────┬───────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────────┐
│ 4. ReplicaSet Controller                        │
│    ├─ Detecta nuevo ReplicaSet (watch)          │
│    └─ Crea Pod                                  │
└─────────────┬───────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────────┐
│ 5. Scheduler                                    │
│    ├─ Detecta Pod sin nodo (watch)              │
│    ├─ Evalúa nodos disponibles                  │
│    └─ Asigna Pod a mejor nodo                   │
└─────────────┬───────────────────────────────────┘
              ▼
┌─────────────────────────────────────────────────┐
│ 6. kubelet (en nodo seleccionado)               │
│    ├─ Detecta Pod asignado (watch)              │
│    ├─ Descarga imagen                           │
│    ├─ Crea contenedor                           │
│    └─ Reporta estado a API Server               │
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
│    Single Node          │
│  ┌─────────────────┐    │
│  │ Control Plane   │    │
│  ├─────────────────┤    │
│  │ Worker          │    │
│  │ Components      │    │
│  └─────────────────┘    │
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
│  ┌─────────────────────────────────┐│
│  │     Managed Control Plane       ││  ← Invisible
│  │   (API Server, etcd, etc.)      ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
              │
┌─────────────┐  ┌─────────────┐
│  Worker 1   │  │  Worker N   │      ← You manage
└─────────────┘  └─────────────┘
```

---

## 🧪 Ejercicios Prácticos: Explorando la Arquitectura

### **🔬 Ejercicio 1: Verificar Componentes del Cluster**

**Objetivo**: Identificar todos los componentes del Control Plane y Worker Nodes

```bash
# 1. Ver todos los componentes del sistema
kubectl get pods -n kube-system

# Deberías ver:
# - kube-apiserver
# - etcd
# - kube-scheduler
# - kube-controller-manager
# - coredns
# - kube-proxy

# 2. Ver detalles de un componente específico
kubectl describe pod kube-apiserver-minikube -n kube-system

# 3. Ver logs del API Server
kubectl logs kube-apiserver-minikube -n kube-system

# 4. Verificar los nodos del cluster
kubectl get nodes -o wide

# 5. Ver información detallada del nodo
kubectl describe node minikube
```

**✅ Validación**: Debes poder identificar cada componente y entender su función.

---

### **🔍 Ejercicio 2: Explorar el API Server**

**Objetivo**: Entender cómo funciona el API Server

```bash
# 1. Ver la versión del API Server
kubectl version

# 2. Ver todos los recursos disponibles (API Resources)
kubectl api-resources

# 3. Ver todas las API versions
kubectl api-versions

# 4. Hacer una petición directa al API Server
kubectl proxy &
curl http://localhost:8001/api/v1/namespaces/default/pods

# 5. Ver configuración de acceso al cluster
kubectl config view

# 6. Ver el contexto actual
kubectl config current-context
```

**✅ Validación**: Entiendes que todas las operaciones pasan por el API Server.

---

### **🗄️ Ejercicio 3: Inspeccionar etcd (Conceptual)**

**Objetivo**: Entender qué datos almacena etcd

```bash
# 1. Crear un deployment para ver qué se guarda en etcd
kubectl create deployment test-etcd --image=nginx --replicas=2

# 2. Ver el deployment
kubectl get deployment test-etcd -o yaml

# 3. Ver los pods creados
kubectl get pods -l app=test-etcd

# 4. Ver el ReplicaSet creado automáticamente
kubectl get replicaset

# 5. Eliminar el deployment y observar la cascada
kubectl delete deployment test-etcd

# 6. Verificar que todo se eliminó
kubectl get all
```

**💡 Conceptual**: Cada comando `kubectl` hace que:
- API Server reciba la petición
- API Server guarde el estado en etcd
- Controllers lean de etcd y actúen en consecuencia

**✅ Validación**: Entiendes que etcd es la única fuente de verdad del cluster.

---

### **🧠 Ejercicio 4: Observar el Scheduler en Acción**

**Objetivo**: Ver cómo el Scheduler asigna Pods a Nodos

```bash
# 1. Crear un deployment sin especificar nodo
kubectl create deployment scheduler-test --image=nginx --replicas=3

# 2. Ver en qué nodos se asignaron los pods
kubectl get pods -o wide

# 3. Ver eventos del scheduler
kubectl get events --sort-by='.lastTimestamp' | grep -i scheduled

# 4. Crear un pod con nodeSelector (forzar scheduler)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-manual-schedule
spec:
  nodeName: minikube  # Asignación manual (bypassing scheduler)
  containers:
  - name: nginx
    image: nginx
EOF

# 5. Ver que se asignó directamente sin scheduler
kubectl get pod nginx-manual-schedule -o wide

# 6. Cleanup
kubectl delete deployment scheduler-test
kubectl delete pod nginx-manual-schedule
```

**✅ Validación**: Entiendes cómo el Scheduler decide dónde colocar los Pods.

---

### **🎮 Ejercicio 5: Ver Controllers en Acción**

**Objetivo**: Observar el comportamiento de auto-healing de los Controllers

```bash
# 1. Crear un deployment con 3 réplicas
kubectl create deployment controller-demo --image=nginx --replicas=3

# 2. Ver los pods
kubectl get pods -l app=controller-demo

# 3. Eliminar manualmente un pod
POD_NAME=$(kubectl get pods -l app=controller-demo -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME

# 4. Ver inmediatamente cómo se crea un nuevo pod (self-healing)
kubectl get pods -l app=controller-demo --watch

# (Presiona Ctrl+C para salir del watch)

# 5. Escalar el deployment (ReplicaSet Controller)
kubectl scale deployment controller-demo --replicas=5

# 6. Ver cómo se crean 2 pods adicionales
kubectl get pods -l app=controller-demo

# 7. Ver el ReplicaSet que gestiona estos pods
kubectl get replicaset

# 8. Cleanup
kubectl delete deployment controller-demo
```

**✅ Validación**: Observaste el ReplicaSet Controller manteniendo el estado deseado.

---

### **🌐 Ejercicio 6: Analizar kube-proxy y Networking**

**Objetivo**: Entender cómo funciona el Service networking

```bash
# 1. Crear un deployment y exponer como Service
kubectl create deployment web --image=nginx --replicas=3
kubectl expose deployment web --port=80 --target-port=80

# 2. Ver el Service creado
kubectl get service web

# 3. Describir el Service (ver Endpoints)
kubectl describe service web

# 4. Ver los Endpoints (IPs de los pods)
kubectl get endpoints web

# 5. Ver las reglas de iptables creadas por kube-proxy (en el nodo)
# Si usas Minikube:
minikube ssh
sudo iptables-save | grep web
exit

# 6. Probar conectividad desde otro pod
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://web

# 7. Ver logs de kube-proxy
kubectl logs -n kube-system -l k8s-app=kube-proxy

# 8. Cleanup
kubectl delete deployment web
kubectl delete service web
```

**✅ Validación**: Entiendes cómo kube-proxy implementa el Service networking.

---

### **🤖 Ejercicio 7: Inspeccionar kubelet (Worker Node)**

**Objetivo**: Ver el agente que ejecuta en cada nodo

```bash
# 1. Ver información del nodo
kubectl get nodes -o wide

# 2. Describir el nodo para ver capacidad y recursos
kubectl describe node minikube

# 3. Ver los pods ejecutando en el nodo
kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=minikube

# 4. Si usas Minikube, ver el proceso kubelet
minikube ssh
ps aux | grep kubelet
exit

# 5. Ver métricas del nodo (si metrics-server está instalado)
kubectl top node

# 6. Ver métricas de pods
kubectl top pods --all-namespaces
```

**✅ Validación**: Entiendes que kubelet es el responsable de ejecutar los pods en cada nodo.

---

### **📊 Ejercicio 8: Request Flow Completo**

**Objetivo**: Seguir el flujo completo de una petición

```bash
# 1. Crear un deployment y seguir cada paso
echo "=== PASO 1: Usuario ejecuta kubectl ==="
kubectl create deployment flow-demo --image=nginx --replicas=2 --dry-run=client -o yaml

echo "=== PASO 2: kubectl construye JSON y lo envía al API Server ==="
kubectl create deployment flow-demo --image=nginx --replicas=2 -v=8

# El flag -v=8 muestra todos los detalles de comunicación con API Server

echo "=== PASO 3: Ver que se guardó en etcd (verificar deployment existe) ==="
kubectl get deployment flow-demo -o yaml

echo "=== PASO 4: Deployment Controller crea ReplicaSet ==="
kubectl get replicaset

echo "=== PASO 5: ReplicaSet Controller solicita creación de Pods ==="
kubectl get pods -l app=flow-demo

echo "=== PASO 6: Scheduler asigna Pods a Nodos ==="
kubectl get pods -l app=flow-demo -o wide

echo "=== PASO 7: Kubelet ejecuta los contenedores ==="
kubectl describe pod -l app=flow-demo

echo "=== PASO 8: Ver eventos de todo el proceso ==="
kubectl get events --sort-by='.lastTimestamp' | head -20

# Cleanup
kubectl delete deployment flow-demo
```

**✅ Validación**: Puedes explicar cada paso del flujo de un deployment.

---

### **🔧 Ejercicio 9: Troubleshooting de Componentes**

**Objetivo**: Diagnosticar problemas comunes

```bash
# 1. Ver salud general del cluster
kubectl get componentstatuses
# Nota: Este comando está deprecated pero útil para clusters auto-gestionados

# 2. Ver eventos del cluster
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# 3. Verificar que todos los pods del sistema están corriendo
kubectl get pods -n kube-system

# 4. Crear un pod problemático intencionalmente
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: bad-pod
spec:
  containers:
  - name: app
    image: imagen-que-no-existe:v1.0
EOF

# 5. Ver por qué falla
kubectl describe pod bad-pod
kubectl get events --field-selector involvedObject.name=bad-pod

# 6. Ver logs de API Server para diagnóstico
kubectl logs -n kube-system -l component=kube-apiserver --tail=50

# 7. Cleanup
kubectl delete pod bad-pod
```

**✅ Validación**: Sabes usar comandos de diagnóstico cuando algo falla.

---

### **📝 Ejercicio 10: Resumen de Arquitectura**

**Objetivo**: Consolidar todo el conocimiento

**Completa este checklist ejecutando comandos:**

```bash
# ✅ Control Plane Components
kubectl get pods -n kube-system | grep -E "(apiserver|etcd|scheduler|controller)"

# ✅ Worker Node Components
kubectl get pods -n kube-system | grep -E "(proxy|coredns)"

# ✅ Ver todos los recursos del cluster
kubectl api-resources | wc -l

# ✅ Crear un deployment completo
kubectl create deployment final-test --image=nginx --replicas=3
kubectl expose deployment final-test --port=80
kubectl get all -l app=final-test

# ✅ Verificar que todo funciona
kubectl run test --image=busybox --rm -it --restart=Never -- wget -qO- http://final-test

# ✅ Cleanup final
kubectl delete deployment final-test
kubectl delete service final-test
```

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

## Resumen del Capítulo

Este capítulo cubrió los conceptos fundamentales de arquitectura de un cluster kubernetes, desde la teoría hasta la práctica con ejemplos y manifiestos YAML aplicables en entornos reales. Los laboratorios en el directorio `laboratorios/` permiten practicar cada concepto, y el `RESUMEN-MODULO.md` sirve como guía de repaso rápido.
