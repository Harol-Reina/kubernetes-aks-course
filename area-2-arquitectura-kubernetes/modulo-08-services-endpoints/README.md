# Módulo 08: Services y Endpoints en Kubernetes

## 📋 Información del Módulo

- **Duración estimada**: 4 horas
- **Nivel**: Intermedio
- **Requisitos previos**: 
  - Módulo 04: Pods vs Contenedores
  - Módulo 06: ReplicaSets
  - Módulo 07: Deployments y Rolling Updates

## 🎯 Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:

1. Comprender el concepto de Service como abstracción de red en Kubernetes
2. Diferenciar entre los tipos de Services: ClusterIP, NodePort, LoadBalancer, ExternalName
3. Entender el rol de los Endpoints en el descubrimiento de servicios
4. Configurar Services para comunicación interna y externa
5. Implementar balanceo de carga entre Pods
6. Gestionar descubrimiento de servicios mediante DNS
7. Configurar Services headless para casos avanzados
8. Aplicar best practices de networking en producción

---

## 📚 Contenido

### 1. Introducción a Services

#### ¿Qué son los Services?

Los **Services** en Kubernetes son una abstracción que define un conjunto lógico de Pods y una política de acceso a ellos. Resuelven el problema fundamental de la comunicación en entornos dinámicos donde los Pods son efímeros.

**Problema a resolver**:
```
Deployment con 3 réplicas
├── Pod-1 (IP: 10.1.2.3) ← Muere y se recrea
├── Pod-2 (IP: 10.1.2.4) ← Nueva IP: 10.1.2.8
└── Pod-3 (IP: 10.1.2.5) ← Escala a 5 réplicas

❌ Los clientes NO pueden seguir los cambios de IP
✅ Service proporciona una IP estable
```

**Solución con Service**:
```
Service (IP estable: 10.96.0.10, DNS: my-app.default.svc.cluster.local)
    ↓ Balancea tráfico entre
Endpoints (lista dinámica de Pods)
    ├── Pod-1: 10.1.2.3:8080
    ├── Pod-2: 10.1.2.4:8080
    └── Pod-3: 10.1.2.5:8080
```

#### Características Clave

- **IP Estable**: Service tiene una ClusterIP que no cambia
- **DNS Interno**: Nombre DNS automático (`<service>.<namespace>.svc.cluster.local`)
- **Balanceo de Carga**: Distribuye tráfico entre Pods backend
- **Descubrimiento de Servicios**: Mediante DNS o variables de entorno
- **Desacoplamiento**: Clientes independientes de la topología de Pods

---

### 2. Anatomía de un Service

#### Componentes Fundamentales

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service          # Nombre del Service
  namespace: default        # Namespace
  labels:
    app: my-app             # Labels del Service
spec:
  selector:                 # Selector para encontrar Pods
    app: my-app
    tier: backend
  ports:                    # Puertos expuestos
    - name: http
      protocol: TCP
      port: 80              # Puerto del Service
      targetPort: 8080      # Puerto del Pod
  type: ClusterIP           # Tipo de Service
```

#### Flujo de Comunicación

```
1. Cliente hace petición a Service
   ↓
   curl http://my-service:80

2. DNS resuelve a ClusterIP
   ↓
   my-service → 10.96.0.10

3. kube-proxy intercepta tráfico
   ↓
   iptables/IPVS rules

4. Selecciona un Endpoint (Pod)
   ↓
   Balanceo: Pod-1, Pod-2, o Pod-3

5. NAT hacia targetPort del Pod
   ↓
   10.1.2.3:8080
```

---

### 3. Tipos de Services

#### Comparativa Rápida

| Tipo | Alcance | IP Externa | Puerto | Caso de Uso |
|------|---------|------------|--------|-------------|
| **ClusterIP** | Interno | No | N/A | Comunicación entre microservicios |
| **NodePort** | Interno + Externo | No (usa IP nodo) | 30000-32767 | Testing, acceso externo simple |
| **LoadBalancer** | Interno + Externo | Sí | Cualquiera | Producción en cloud (AWS, GCP, Azure) |
| **ExternalName** | Interno | N/A | N/A | Redirigir a servicios externos vía DNS |

#### Diagrama de Tipos de Services

```
┌─────────────────────────────────────────────────────────────┐
│                     CLUSTER KUBERNETES                      │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    ClusterIP                         │   │
│  │  IP: 10.96.0.10 (solo interna)                       │   │
│  │  ├─> Pod-1: 10.1.2.3:8080                            │   │
│  │  ├─> Pod-2: 10.1.2.4:8080                            │   │
│  │  └─> Pod-3: 10.1.2.5:8080                            │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↑                                  │
│                    Solo accesible                           │
│                  dentro del cluster                         │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    NodePort                          │   │
│  │  ClusterIP: 10.96.0.20                               │   │
│  │  NodePort: 30080 (en cada nodo)                      │   │
│  │                                                      │   │
│  │  Node-1 (IP: 192.168.1.10:30080) ──┐                 │   │
│  │  Node-2 (IP: 192.168.1.11:30080) ──┼─> Pods          │   │
│  │  Node-3 (IP: 192.168.1.12:30080) ──┘                 │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↑                                  │
│               Accesible desde fuera                         │
│              <NodeIP>:<NodePort>                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                          ↑
                          │
┌─────────────────────────┴──────────────────────────┐
│                 LoadBalancer                       │
│  IP Pública: 203.0.113.25                          │
│  ├─> NodePort: 30080                               │
│  │   ├─> ClusterIP: 10.96.0.30                     │
│  │   │   ├─> Pod-1                                 │
│  │   │   ├─> Pod-2                                 │
│  │   │   └─> Pod-3                                 │
└────────────────────────────────────────────────────┘
        ↑
  Accesible desde
    Internet
```

---

### 4. Service ClusterIP (Por Defecto)

#### Descripción

- **Tipo por defecto** si no se especifica `type`
- **IP interna** solo accesible dentro del cluster
- **Uso principal**: Comunicación entre microservicios

#### Ejemplo Básico

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
    tier: api
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 8080
  type: ClusterIP  # Opcional, es el valor por defecto
```

#### ¿Cómo Funciona?

1. **Creación**: Kubernetes asigna una IP del rango de ClusterIP (ej: `10.96.0.0/12`)
2. **DNS**: Se crea automáticamente un registro DNS
   - Mismo namespace: `backend-service`
   - Otros namespaces: `backend-service.default.svc.cluster.local`
3. **Endpoints**: Controlador crea objeto Endpoints con IPs de Pods que coinciden con selector
4. **kube-proxy**: Configura reglas iptables/IPVS para balanceo de carga

#### Acceso al Service

**Desde un Pod en el mismo namespace**:
```bash
curl http://backend-service:80
```

**Desde un Pod en otro namespace**:
```bash
curl http://backend-service.default.svc.cluster.local:80
```

**Desde un Pod con variables de entorno** (legacy):
```bash
echo $BACKEND_SERVICE_SERVICE_HOST  # 10.96.0.10
echo $BACKEND_SERVICE_SERVICE_PORT  # 80
```

#### Ver también
- [Ejemplo: service-clusterip-basic.yaml](ejemplos/01-clusterip/service-clusterip-basic.yaml)
- [Ejemplo: service-multi-port.yaml](ejemplos/01-clusterip/service-multi-port.yaml)

---

### 5. Endpoints

#### ¿Qué son los Endpoints?

Los **Endpoints** son objetos de Kubernetes que contienen la lista de direcciones IP de los Pods que coinciden con el selector de un Service.

#### Relación Service ↔ Endpoints ↔ Pods

```
Service (my-service)
    ↓ (selector: app=backend)
Endpoints (my-service)
    ├── addresses:
    │   ├── ip: 10.1.2.3
    │   ├── ip: 10.1.2.4
    │   └── ip: 10.1.2.5
    └── ports:
        └── port: 8080
             ↓
Pods con label app=backend
    ├── Pod-1: 10.1.2.3:8080
    ├── Pod-2: 10.1.2.4:8080
    └── Pod-3: 10.1.2.5:8080
```

#### Ver Endpoints

```bash
# Listar todos los Endpoints
kubectl get endpoints

# Ver Endpoints de un Service específico
kubectl get endpoints my-service

# Ver detalles en YAML
kubectl get endpoints my-service -o yaml
```

**Output ejemplo**:
```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: my-service
subsets:
  - addresses:
      - ip: 10.1.2.3
        nodeName: node-1
        targetRef:
          kind: Pod
          name: backend-pod-1
          namespace: default
      - ip: 10.1.2.4
        nodeName: node-2
        targetRef:
          kind: Pod
          name: backend-pod-2
          namespace: default
    ports:
      - name: http
        port: 8080
        protocol: TCP
```

#### Endpoints Automáticos vs Manuales

**Automáticos** (con selector):
- Kubernetes crea y actualiza Endpoints automáticamente
- Se sincronizan con los Pods que coinciden con el selector

**Manuales** (sin selector):
```yaml
# Service sin selector
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306

---
# Endpoints manuales
apiVersion: v1
kind: Endpoints
metadata:
  name: external-db  # Mismo nombre que el Service
subsets:
  - addresses:
      - ip: 192.168.1.100  # IP externa (ej: base de datos)
    ports:
      - port: 3306
```

**Uso**: Servicios externos, bases de datos legacy, migración gradual a Kubernetes.

#### Ver también
- [Ejemplo: service-manual-endpoints.yaml](ejemplos/05-endpoints/service-manual-endpoints.yaml)
- [Laboratorio 1: Endpoints en detalle](laboratorios/lab-01-clusterip-basics.md#ejercicio-2-explorar-endpoints)

---

### 6. Service NodePort

#### Descripción

- Expone el Service en **cada nodo del cluster** en un puerto estático
- Rango de puertos: **30000-32767** (configurable)
- Crea automáticamente un ClusterIP
- **Uso**: Testing, desarrollo, acceso externo simple

#### Ejemplo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-nodeport
spec:
  type: NodePort
  selector:
    app: webapp
  ports:
    - name: http
      protocol: TCP
      port: 80          # Puerto del Service (interno)
      targetPort: 8080  # Puerto del Pod
      nodePort: 30080   # Puerto en cada nodo (30000-32767)
```

#### ¿Cómo Funciona?

```
1. Petición externa
   ↓
   http://192.168.1.10:30080

2. Llega a NodePort en cualquier nodo
   ↓
   Node-1, Node-2, o Node-3:30080

3. kube-proxy redirige a ClusterIP
   ↓
   10.96.0.20:80

4. Balanceo a Pod backend
   ↓
   Pod en cualquier nodo del cluster
```

#### Acceso

**Desde fuera del cluster**:
```bash
# Con IP de cualquier nodo
curl http://192.168.1.10:30080
curl http://192.168.1.11:30080
curl http://192.168.1.12:30080

# Todos los nodos redirigen al mismo Service
```

**Desde dentro del cluster** (funciona igual que ClusterIP):
```bash
curl http://webapp-nodeport:80
```

#### Asignación de NodePort

**Automática**:
```yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 8080
      # nodePort no especificado → Kubernetes asigna uno aleatorio
```

**Manual**:
```yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30080  # Asignación manual (debe estar libre)
```

#### Limitaciones

- ❌ Solo un Service por puerto (30000-32767)
- ❌ Rango de puertos limitado
- ❌ Si cambias IPs de nodos, debes actualizar clientes
- ❌ No hay balanceo externo real

#### Ver también
- [Ejemplo: service-nodeport-basic.yaml](ejemplos/02-nodeport/service-nodeport-basic.yaml)
- [Laboratorio 2: NodePort en acción](laboratorios/lab-02-nodeport-loadbalancer.md#ejercicio-1-crear-service-nodeport)

---

### 7. Service LoadBalancer

#### Descripción

- Crea un **balanceador de carga externo** (en cloud providers)
- Asigna una **IP pública** automáticamente
- Crea automáticamente NodePort y ClusterIP
- **Uso**: Producción en AWS, GCP, Azure, etc.

#### Ejemplo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: webapp
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 8080
```

#### ¿Cómo Funciona?

```
1. Kubernetes solicita LoadBalancer al cloud provider
   ↓
   AWS ELB / GCP Load Balancer / Azure LB

2. Cloud crea balanceador con IP pública
   ↓
   IP Pública: 203.0.113.25

3. Balanceador dirige a NodePort
   ↓
   NodePort automático (ej: 31234)

4. NodePort redirige a ClusterIP
   ↓
   ClusterIP: 10.96.0.30:80

5. Balanceo entre Pods
   ↓
   Pods backend
```

#### Ver Estado del LoadBalancer

```bash
kubectl get service webapp-loadbalancer
```

**Output**:
```
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
webapp-loadbalancer    LoadBalancer   10.96.0.30     203.0.113.25     80:31234/TCP   2m
```

**Campos importantes**:
- `CLUSTER-IP`: IP interna (10.96.0.30)
- `EXTERNAL-IP`: IP pública del balanceador (203.0.113.25)
- `PORT(S)`: `80:31234/TCP` → Puerto 80 mapeado a NodePort 31234

#### Acceso

**Desde Internet**:
```bash
curl http://203.0.113.25
```

**Desde dentro del cluster**:
```bash
curl http://webapp-loadbalancer:80
```

#### Configuración Específica por Cloud Provider

**AWS (ELB)**:
```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # Network Load Balancer
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"  # Interno
```

**GCP**:
```yaml
metadata:
  annotations:
    cloud.google.com/load-balancer-type: "Internal"  # LB interno
```

**Azure**:
```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
```

#### Limitaciones

- ❌ Solo funciona en cloud providers soportados
- ❌ Costo adicional por balanceador (cada Service = 1 LB)
- ❌ En clusters locales (minikube, kind) queda en `<pending>`

#### Ver también
- [Ejemplo: service-loadbalancer-basic.yaml](ejemplos/03-loadbalancer/service-loadbalancer-basic.yaml)
- [Ejemplo: service-loadbalancer-annotations.yaml](ejemplos/03-loadbalancer/service-loadbalancer-annotations.yaml)

---

### 8. Service ExternalName

#### Descripción

- Mapea un Service a un **nombre DNS externo**
- No crea proxy ni IP propia
- Usa **CNAME** DNS record
- **Uso**: Redirigir a servicios externos (bases de datos, APIs externas)

#### Ejemplo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-api
spec:
  type: ExternalName
  externalName: api.example.com  # FQDN externo
```

#### ¿Cómo Funciona?

```
1. Pod consulta DNS interno
   ↓
   curl http://external-api.default.svc.cluster.local

2. DNS retorna CNAME record
   ↓
   external-api → api.example.com

3. Cliente resuelve DNS externo
   ↓
   api.example.com → 203.0.113.50

4. Conexión directa a servicio externo
   ↓
   http://203.0.113.50
```

#### Casos de Uso

**1. Migración gradual a Kubernetes**:
```yaml
# Fase 1: Base de datos externa
apiVersion: v1
kind: Service
metadata:
  name: database
spec:
  type: ExternalName
  externalName: legacy-db.company.com

# Fase 2: Migrar a Kubernetes (cambiar type, mantener nombre)
apiVersion: v1
kind: Service
metadata:
  name: database  # Mismo nombre!
spec:
  type: ClusterIP
  selector:
    app: postgres
```

**2. Diferentes entornos**:
```yaml
# Production
apiVersion: v1
kind: Service
metadata:
  name: payment-api
  namespace: production
spec:
  type: ExternalName
  externalName: payment.prod.company.com

---
# Development
apiVersion: v1
kind: Service
metadata:
  name: payment-api
  namespace: development
spec:
  type: ExternalName
  externalName: payment-sandbox.company.com
```

#### Limitaciones

- ❌ No hay balanceo de carga
- ❌ No hay verificación de salud (health checks)
- ❌ Solo funciona con protocolos que usan nombres de host
- ⚠️ Problemas con TLS/SSL si el hostname difiere

#### Ver también
- [Ejemplo: service-externalname-basic.yaml](ejemplos/04-externalname/service-externalname-basic.yaml)
- [Laboratorio 3: ExternalName avanzado](laboratorios/lab-03-advanced-services.md#ejercicio-1-externalname-service)

---

### 9. Services Headless

#### Descripción

Un Service **headless** es un Service sin ClusterIP (`clusterIP: None`). No tiene balanceo de carga; en su lugar, retorna **todas las IPs de los Pods** directamente.

#### ¿Por Qué Usar Headless?

- 🎯 **Control directo**: Aplicaciones necesitan conectarse a Pods específicos
- 🎯 **StatefulSets**: Cada Pod tiene identidad única (ej: bases de datos)
- 🎯 **Service discovery**: Obtener lista de todos los Pods

#### Ejemplo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: database-headless
spec:
  clusterIP: None  # ¡Headless!
  selector:
    app: database
  ports:
    - name: mysql
      protocol: TCP
      port: 3306
      targetPort: 3306
```

#### Resolución DNS

**Service normal (ClusterIP)**:
```bash
nslookup my-service.default.svc.cluster.local
# Retorna: 10.96.0.10 (IP del Service)
```

**Service headless**:
```bash
nslookup database-headless.default.svc.cluster.local
# Retorna: Lista de IPs de TODOS los Pods
# 10.1.2.3
# 10.1.2.4
# 10.1.2.5
```

#### Con StatefulSet

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
    - port: 3306

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql  # Usa el headless Service
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
```

**DNS de cada Pod**:
```
mysql-0.mysql.default.svc.cluster.local → 10.1.2.3
mysql-1.mysql.default.svc.cluster.local → 10.1.2.4
mysql-2.mysql.default.svc.cluster.local → 10.1.2.5
```

#### Ver también
- [Ejemplo: service-headless-statefulset.yaml](ejemplos/06-headless/service-headless-statefulset.yaml)
- [Laboratorio 3: Services headless](laboratorios/lab-03-advanced-services.md#ejercicio-2-headless-services)

---

### 10. Descubrimiento de Servicios

Kubernetes ofrece dos métodos principales para descubrir Services:

#### 10.1 DNS (Recomendado)

**CoreDNS** (addon estándar) crea registros DNS automáticamente para cada Service.

**Formato DNS**:
```
<service-name>.<namespace>.svc.<cluster-domain>
```

**Ejemplo**:
```
my-service.default.svc.cluster.local
│         │       │   │
│         │       │   └── Dominio del cluster (por defecto)
│         │       └────── Sufijo de Service
│         └────────────── Namespace
└──────────────────────── Nombre del Service
```

**Shortcuts**:
- Mismo namespace: `my-service`
- Mismo namespace con puerto: `my-service:80`
- Otro namespace: `my-service.other-namespace`
- FQDN completo: `my-service.default.svc.cluster.local`

**Ejemplo práctico**:
```bash
# Desde un Pod en namespace "default"
curl http://backend-service:80

# Desde un Pod en namespace "frontend" accediendo a "default"
curl http://backend-service.default:80

# FQDN completo (siempre funciona)
curl http://backend-service.default.svc.cluster.local:80
```

#### 10.2 Variables de Entorno (Legacy)

Cuando un Pod se crea, Kubernetes inyecta variables de entorno para **todos los Services existentes** en el mismo namespace.

**Formato**:
```bash
{SVCNAME}_SERVICE_HOST=<clusterIP>
{SVCNAME}_SERVICE_PORT=<port>
```

**Ejemplo**:
```bash
# Service "backend-service" en puerto 80
BACKEND_SERVICE_SERVICE_HOST=10.96.0.10
BACKEND_SERVICE_SERVICE_PORT=80

# Compatible con Docker links
BACKEND_SERVICE_PORT=tcp://10.96.0.10:80
BACKEND_SERVICE_PORT_80_TCP=tcp://10.96.0.10:80
BACKEND_SERVICE_PORT_80_TCP_PROTO=tcp
BACKEND_SERVICE_PORT_80_TCP_PORT=80
BACKEND_SERVICE_PORT_80_TCP_ADDR=10.96.0.10
```

**Limitación importante**:
⚠️ Las variables solo se inyectan para Services que **existen ANTES** de crear el Pod. No se actualizan dinámicamente.

**Orden correcto**:
```bash
# 1. Crear Service primero
kubectl apply -f service.yaml

# 2. Luego crear Pods/Deployment
kubectl apply -f deployment.yaml
```

**Orden incorrecto (no funciona)**:
```bash
# 1. Crear Pods primero
kubectl apply -f deployment.yaml  # ❌ Variables no disponibles

# 2. Luego crear Service
kubectl apply -f service.yaml     # Pods ya creados, no tienen variables
```

**Recomendación**: Usar **DNS en lugar de variables de entorno**.

---

### 11. kube-proxy y Modos de Proxy

#### ¿Qué es kube-proxy?

**kube-proxy** es un componente que corre en cada nodo y gestiona las reglas de red para los Services. Implementa la VIP (Virtual IP) del Service.

#### Modos de Operación

**1. Userspace** (Deprecated)
```
Cliente → iptables → kube-proxy (userspace) → Pod
```
- ❌ Lento (context switching)
- ❌ Obsoleto desde Kubernetes 1.2

**2. iptables** (Default en muchas distros)
```
Cliente → iptables rules → Pod (directo)
```
- ✅ Más rápido que userspace
- ✅ No requiere kube-proxy en data path
- ❌ Escala mal con >5000 Services (reglas lineales)
- ❌ No tiene health checks activos

**3. IPVS** (Recomendado)
```
Cliente → IPVS rules → Pod
```
- ✅ Muy rápido (hash table en kernel)
- ✅ Escala a decenas de miles de Services
- ✅ Algoritmos de balanceo avanzados:
  - `rr`: Round-robin
  - `lc`: Least connections
  - `sh`: Source hashing
  - `dh`: Destination hashing
- ✅ Health checks integrados
- ⚠️ Requiere módulos kernel IPVS

#### Verificar Modo Actual

```bash
# Ver configuración de kube-proxy
kubectl -n kube-system get configmap kube-proxy -o yaml | grep mode
```

**Output**:
```yaml
mode: "ipvs"  # o "iptables" o "userspace"
```

#### Configurar Modo IPVS

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-proxy
  namespace: kube-system
data:
  config.conf: |
    mode: "ipvs"
    ipvs:
      scheduler: "rr"  # round-robin
```

**Cargar módulos kernel** (en cada nodo):
```bash
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack
```

#### Ver también
- [Documentación oficial: kube-proxy](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/)

---

### 12. Session Affinity (Afinidad de Sesión)

#### Descripción

Por defecto, los Services balancean tráfico **aleatoriamente** entre Pods. Session Affinity permite mantener conexiones del **mismo cliente** al **mismo Pod**.

#### Configuración

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-service
spec:
  selector:
    app: webapp
  ports:
    - port: 80
      targetPort: 8080
  sessionAffinity: ClientIP  # "None" (default) o "ClientIP"
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 horas (default: 10800)
```

#### ¿Cómo Funciona?

**Sin Session Affinity**:
```
Cliente (IP: 203.0.113.10)
  ├─> Request 1 → Pod-1
  ├─> Request 2 → Pod-3
  ├─> Request 3 → Pod-2
  └─> Request 4 → Pod-1
```

**Con Session Affinity (ClientIP)**:
```
Cliente (IP: 203.0.113.10)
  ├─> Request 1 → Pod-2
  ├─> Request 2 → Pod-2  ← Mismo Pod
  ├─> Request 3 → Pod-2  ← Mismo Pod
  └─> Request 4 → Pod-2  ← Mismo Pod (hasta timeout)
```

#### Casos de Uso

- ✅ **Aplicaciones con estado de sesión** (session storage local)
- ✅ **WebSockets** (conexiones persistentes)
- ✅ **Carritos de compra** (sin Redis/memcached)
- ❌ **No usar** si la app es stateless (mejor balanceo)

#### Limitaciones

- ⚠️ Basado en **IP origen** (no cookies/headers)
- ⚠️ NAT puede agrupar múltiples clientes en una IP
- ⚠️ No funciona bien detrás de proxies/load balancers

---

### 13. ExternalTrafficPolicy

#### Descripción

Controla cómo se enruta el tráfico **externo** (NodePort, LoadBalancer) a los Pods.

#### Valores

**1. Cluster (default)**:
```yaml
spec:
  type: NodePort
  externalTrafficPolicy: Cluster  # Default
```

**Comportamiento**:
- Tráfico puede ir a **cualquier nodo**
- Luego se redirige a **cualquier Pod** (incluso en otros nodos)
- ✅ Balanceo uniforme
- ❌ IP origen del cliente se pierde (SNAT)
- ❌ Hop adicional si Pod está en otro nodo

**2. Local**:
```yaml
spec:
  type: NodePort
  externalTrafficPolicy: Local
```

**Comportamiento**:
- Tráfico solo va a Pods **en el mismo nodo**
- ✅ Preserva IP origen del cliente
- ✅ Sin hop adicional (mejor latencia)
- ❌ Balanceo desigual si Pods no están distribuidos uniformemente
- ⚠️ Si un nodo no tiene Pods, el tráfico falla

#### Comparación Visual

**Cluster Policy**:
```
External LB (203.0.113.25)
    ↓
Node-1 (NodePort 30080)
    ├─> Pod en Node-1 ✅
    ├─> Pod en Node-2 ✅ (hop extra)
    └─> Pod en Node-3 ✅ (hop extra)

IP vista por Pod: IP del nodo (SNAT)
```

**Local Policy**:
```
External LB (203.0.113.25)
    ↓
Node-1 (NodePort 30080)
    └─> Pod en Node-1 SOLO ✅

Node-2 (NodePort 30080)
    └─> Pod en Node-2 SOLO ✅

IP vista por Pod: 203.0.113.25 (cliente real) ✅
```

#### Caso de Uso: Logging de IPs Reales

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local  # Preservar IP origen
  selector:
    app: webapp
  ports:
    - port: 80
      targetPort: 8080
```

**Logs en Pod** (con `Local`):
```
2025-11-09 10:30:15 [INFO] Request from 203.0.113.45 - GET /api/users
```

**Logs en Pod** (con `Cluster`):
```
2025-11-09 10:30:15 [INFO] Request from 10.244.1.1 - GET /api/users
                                          ↑ IP del nodo, no del cliente
```

#### Ver también
- [Ejemplo: service-external-traffic-policy.yaml](ejemplos/07-produccion/service-external-traffic-policy.yaml)

---

### 14. Puertos Múltiples

#### Ejemplo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  selector:
    app: webapp
  ports:
    - name: http      # ¡Nombres obligatorios con múltiples puertos!
      protocol: TCP
      port: 80
      targetPort: 8080
    - name: https
      protocol: TCP
      port: 443
      targetPort: 8443
    - name: metrics
      protocol: TCP
      port: 9090
      targetPort: 9090
```

**Regla importante**: Con múltiples puertos, **todos deben tener nombre**.

#### targetPort con Nombres

```yaml
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  template:
    spec:
      containers:
      - name: app
        ports:
        - name: http-port    # Nombre del puerto
          containerPort: 8080
        - name: https-port
          containerPort: 8443

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  selector:
    app: webapp
  ports:
    - name: http
      port: 80
      targetPort: http-port   # Referencia por nombre ✅
    - name: https
      port: 443
      targetPort: https-port  # Referencia por nombre ✅
```

**Ventaja**: Cambiar puerto del contenedor sin modificar Service.

---

### 15. Mejores Prácticas

#### 15.1 Naming Conventions

```yaml
# ✅ BIEN: Nombres descriptivos
apiVersion: v1
kind: Service
metadata:
  name: backend-api-service  # Claro y específico
  labels:
    app: backend
    component: api
    tier: backend
    environment: production

# ❌ MAL: Nombres genéricos
metadata:
  name: service1  # ¿Qué hace?
  name: svc       # Demasiado corto
```

#### 15.2 Labels y Selectors

```yaml
# ✅ BIEN: Labels consistentes
spec:
  selector:
    app: webapp
    version: v1.2.0
    tier: frontend
    environment: production

# ❌ MAL: Selectores muy amplios
spec:
  selector:
    app: webapp  # Podría matchear múltiples versiones
```

#### 15.3 Health Checks

**SIEMPRE** usar readiness probes en Pods para que solo reciban tráfico cuando estén listos:

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        readinessProbe:  # ¡Crítico para Services!
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
```

**Sin readiness probe**: Service enviará tráfico a Pods no listos → errores 500.

#### 15.4 Tipo de Service Apropiado

| Escenario | Tipo Recomendado |
|-----------|------------------|
| Comunicación interna entre microservicios | `ClusterIP` |
| Testing local, desarrollo | `NodePort` |
| Producción en cloud (AWS, GCP, Azure) | `LoadBalancer` |
| Redirección a servicio externo | `ExternalName` |
| Base de datos stateful | `Headless` + `StatefulSet` |

#### 15.5 Production Checklist

```yaml
apiVersion: v1
kind: Service
metadata:
  name: production-api
  labels:
    app: api
    tier: backend
    environment: production
  annotations:
    # Prometheus monitoring
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
spec:
  type: LoadBalancer
  selector:
    app: api
    version: v2.1.0  # Version específica
  ports:
    - name: https
      protocol: TCP
      port: 443
      targetPort: 8443
  sessionAffinity: ClientIP  # Si se necesita
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
  externalTrafficPolicy: Local  # Preservar IPs cliente
```

#### 15.6 Seguridad

**1. Network Policies**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: frontend  # Solo frontend puede acceder
      ports:
      - protocol: TCP
        port: 8080
```

**2. TLS/SSL**:
- No terminar TLS en Service (es Layer 4)
- Usar Ingress para TLS termination
- O configurar TLS en el Pod directamente

**3. LoadBalancer Source Ranges**:
```yaml
spec:
  type: LoadBalancer
  loadBalancerSourceRanges:
    - "203.0.113.0/24"  # Solo esta IP range puede acceder
```

---

### 16. Troubleshooting

#### 16.1 Service No Responde

**Síntoma**: `curl http://my-service` timeout o error de conexión.

**Diagnóstico**:

```bash
# 1. Verificar que el Service existe
kubectl get service my-service

# 2. Ver detalles
kubectl describe service my-service

# 3. Verificar Endpoints
kubectl get endpoints my-service

# Output esperado:
# NAME         ENDPOINTS                     AGE
# my-service   10.1.2.3:8080,10.1.2.4:8080   5m

# ❌ Si ENDPOINTS está vacío:
# NAME         ENDPOINTS   AGE
# my-service   <none>      5m
```

**Solución si Endpoints vacío**:

```bash
# Verificar selector del Service
kubectl get service my-service -o yaml | grep -A 5 selector

# Verificar labels de los Pods
kubectl get pods -l app=my-app --show-labels

# ¿Coinciden? Si no, corregir selector o labels
```

#### 16.2 DNS No Funciona

**Síntoma**: `nslookup my-service` falla.

**Diagnóstico**:

```bash
# 1. Verificar CoreDNS está corriendo
kubectl -n kube-system get pods -l k8s-app=kube-dns

# 2. Ver logs de CoreDNS
kubectl -n kube-system logs -l k8s-app=kube-dns

# 3. Test desde un Pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
/ # nslookup my-service
/ # nslookup my-service.default.svc.cluster.local
```

#### 16.3 LoadBalancer en `<pending>`

**Síntoma**:
```bash
kubectl get service
# EXTERNAL-IP en <pending>
```

**Causas**:
- ❌ Cluster local (minikube, kind) → No hay cloud provider
- ❌ Cloud provider mal configurado
- ❌ Cuotas de cloud excedidas

**Solución**:
```bash
# En clusters locales, usar minikube tunnel
minikube tunnel  # En otra terminal

# O usar MetalLB (bare-metal load balancer)
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
```

#### 16.4 Tráfico No Llega a Pods

**Síntoma**: Service existe, Endpoints OK, pero Pods no reciben tráfico.

**Diagnóstico**:

```bash
# 1. Verificar Pods están Ready
kubectl get pods -l app=my-app

# 2. Ver readiness probe
kubectl describe pod <pod-name> | grep -A 10 Readiness

# 3. Test directo al Pod (bypass Service)
kubectl port-forward pod/<pod-name> 8080:8080
curl http://localhost:8080

# 4. Ver reglas de kube-proxy
kubectl -n kube-system logs -l k8s-app=kube-proxy
```

**Comandos útiles**:

```bash
# Ver configuración de kube-proxy
kubectl -n kube-system get configmap kube-proxy -o yaml

# Restart kube-proxy
kubectl -n kube-system delete pod -l k8s-app=kube-proxy

# Ver iptables rules (en el nodo)
sudo iptables-save | grep my-service

# Ver IPVS rules (si usa IPVS)
sudo ipvsadm -Ln
```

---

## 📁 Ejemplos Prácticos

Todos los ejemplos están en la carpeta [`ejemplos/`](ejemplos/):

### ClusterIP
- [`service-clusterip-basic.yaml`](ejemplos/01-clusterip/service-clusterip-basic.yaml) - Service ClusterIP básico
- [`service-multi-port.yaml`](ejemplos/01-clusterip/service-multi-port.yaml) - Service con múltiples puertos
- [`service-session-affinity.yaml`](ejemplos/01-clusterip/service-session-affinity.yaml) - Session affinity

### NodePort
- [`service-nodeport-basic.yaml`](ejemplos/02-nodeport/service-nodeport-basic.yaml) - Service NodePort básico
- [`service-nodeport-custom-port.yaml`](ejemplos/02-nodeport/service-nodeport-custom-port.yaml) - NodePort con puerto específico

### LoadBalancer
- [`service-loadbalancer-basic.yaml`](ejemplos/03-loadbalancer/service-loadbalancer-basic.yaml) - LoadBalancer básico
- [`service-loadbalancer-annotations.yaml`](ejemplos/03-loadbalancer/service-loadbalancer-annotations.yaml) - Con annotations cloud

### ExternalName
- [`service-externalname-basic.yaml`](ejemplos/04-externalname/service-externalname-basic.yaml) - Redirigir a DNS externo

### Endpoints
- [`service-manual-endpoints.yaml`](ejemplos/05-endpoints/service-manual-endpoints.yaml) - Endpoints manuales
- [`service-external-database.yaml`](ejemplos/05-endpoints/service-external-database.yaml) - BD externa

### Headless
- [`service-headless-statefulset.yaml`](ejemplos/06-headless/service-headless-statefulset.yaml) - Service headless con StatefulSet

### Producción
- [`service-production-ready.yaml`](ejemplos/07-produccion/service-production-ready.yaml) - Configuración completa
- [`service-external-traffic-policy.yaml`](ejemplos/07-produccion/service-external-traffic-policy.yaml) - ExternalTrafficPolicy

Ver guía completa: [ejemplos/README.md](ejemplos/README.md)

---

## 🧪 Laboratorios Prácticos

### Laboratorio 1: ClusterIP y Endpoints (40 min)
Introducción a Services ClusterIP, explorar Endpoints, descubrimiento DNS.

➡️ [Ir al Laboratorio 1](laboratorios/lab-01-clusterip-basics.md)

### Laboratorio 2: NodePort y LoadBalancer (50 min)
Exposición externa con NodePort, LoadBalancer en cloud, troubleshooting.

➡️ [Ir al Laboratorio 2](laboratorios/lab-02-nodeport-loadbalancer.md)

### Laboratorio 3: Services Avanzados (60 min)
ExternalName, Services headless, StatefulSets, session affinity, production best practices.

➡️ [Ir al Laboratorio 3](laboratorios/lab-03-advanced-services.md)

---

## 📖 Recursos Adicionales

### Documentación Oficial
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

### Artículos Recomendados
- [pabpereza.dev - Servicios en Kubernetes](https://pabpereza.dev/docs/cursos/kubernetes/servicios_en_kubernetes_clusterip_nodeport_y_loadbalancer)
- [Service Mesh (Istio, Linkerd)](https://kubernetes.io/docs/concepts/services-networking/service/)

### Herramientas
- [MetalLB](https://metallb.universe.tf/) - Load balancer para bare-metal
- [CoreDNS](https://coredns.io/) - DNS server para Kubernetes
- [Cilium](https://cilium.io/) - Networking y seguridad avanzada

---

## 🎓 Evaluación de Conocimientos

### Preguntas de Repaso

1. **¿Cuál es la diferencia principal entre un Service ClusterIP y un NodePort?**
   <details><summary>Ver respuesta</summary>
   ClusterIP solo es accesible dentro del cluster (IP interna). NodePort expone el Service en cada nodo en un puerto estático (30000-32767), permitiendo acceso externo.
   </details>

2. **¿Qué pasa si elimino un Pod que está siendo usado por un Service?**
   <details><summary>Ver respuesta</summary>
   El controlador de Endpoints detecta el cambio y actualiza la lista de IPs. El Service automáticamente deja de enviar tráfico a ese Pod y balancea entre los Pods restantes. Si hay un ReplicaSet/Deployment, se creará un nuevo Pod que será agregado a los Endpoints.
   </details>

3. **¿Por qué un Service de tipo LoadBalancer queda en `<pending>` en minikube?**
   <details><summary>Ver respuesta</summary>
   Minikube no tiene un cloud provider que provisione balanceadores de carga externos. Soluciones: usar `minikube tunnel` o instalar MetalLB.
   </details>

4. **¿Cuándo usar un Service headless?**
   <details><summary>Ver respuesta</summary>
   Cuando necesitas conectarte a Pods específicos directamente (ej: StatefulSets con bases de datos), o cuando la aplicación necesita descubrir todas las IPs de los Pods para hacer su propio balanceo.
   </details>

5. **¿Qué es mejor para producción: externalTrafficPolicy Cluster o Local?**
   <details><summary>Ver respuesta</summary>
   Depende del caso. `Local` preserva la IP del cliente y evita hops extra (mejor latencia), pero puede causar balanceo desigual. `Cluster` tiene mejor balanceo pero pierde la IP origen. Para logging/security que requiere IP real, usa `Local`.
   </details>

### Ejercicios Prácticos

1. Crea un Deployment con 3 réplicas de nginx y expónlo con un Service ClusterIP
2. Modifica el Service anterior a NodePort y accede desde fuera del cluster
3. Crea un Service sin selector y Endpoints manuales apuntando a `8.8.8.8:53`
4. Implementa un StatefulSet de MongoDB con Service headless
5. Configura session affinity y verifica que funciona con múltiples requests

---

## 🔗 Navegación del Curso

- ⬅️ **Anterior**: [Módulo 07 - Deployments y Rolling Updates](../modulo-07-deployments-rollouts/)
- ➡️ **Siguiente**: [Módulo 09 - Ingress Controllers](../modulo-09-ingress-controllers/)
- 🏠 **Inicio**: [Área 2 - Arquitectura de Kubernetes](../)

---

## 📝 Resumen

En este módulo aprendiste:

- ✅ **Concepto de Service**: Abstracción para acceder a conjuntos de Pods
- ✅ **Tipos de Services**: ClusterIP, NodePort, LoadBalancer, ExternalName
- ✅ **Endpoints**: Mapeo dinámico entre Services y Pods
- ✅ **Descubrimiento**: DNS (recomendado) y variables de entorno
- ✅ **kube-proxy**: Modos userspace, iptables, IPVS
- ✅ **Services headless**: Para acceso directo a Pods individuales
- ✅ **Session affinity**: Mantener clientes en el mismo Pod
- ✅ **ExternalTrafficPolicy**: Preservar IPs de clientes
- ✅ **Best practices**: Naming, labels, health checks, seguridad
- ✅ **Troubleshooting**: Diagnosticar problemas comunes

**¡Felicitaciones!** Ahora dominas los Services en Kubernetes. 🎉

Continúa con los laboratorios para poner en práctica estos conocimientos.
