# Capítulo 10: Services y Service Discovery

Con Deployments desplegamos aplicaciones. Ahora necesitamos que se comuniquen entre sí y con el mundo exterior. Los Services proporcionan descubrimiento y balanceo de carga estable.

---

## 🗺️ Guía de Estudio Recomendada

### Para Principiantes (Primera vez con Services)
1. **Día 1** (2 horas):
   - Leer Secciones 1-2 (Introducción + ClusterIP)
   - Ejecutar ejemplos inline
   - Completar Lab 01

2. **Día 2** (2 horas):
   - Leer Sección 3 (NodePort + LoadBalancer)
   - Ejecutar ejemplos
   - Completar Lab 02

3. **Día 3** (2 horas):
   - Leer Secciones 4-6
   - Completar Lab 03
   - Revisar troubleshooting

### Para Estudiantes con Experiencia
1. **Revisión rápida**: Secciones 1-3 (1 hora)
2. **Focus avanzado**: Secciones 4-6 (1.5 horas)
3. **Labs selectivos**: Lab 03 (servicios avanzados)

### Para Preparación de Certificación (CKA/CKAD)
- ✅ Dominar todos los tipos de Services
- ✅ Troubleshooting rápido de Endpoints
- ✅ Configuración de Services sin YAML (imperativos)
- ✅ Practicar Labs bajo tiempo límite

---

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

## ✅ Checkpoint 1: Conceptos Fundamentales

Antes de continuar, asegúrate de comprender:

**Preguntas de Autoevaluación**:
1. ¿Por qué los Pods necesitan Services? ¿Qué problema resuelven?
2. ¿Qué sucede cuando un Pod muere y se recrea? ¿Cómo afecta su IP?
3. ¿Qué componentes intervienen entre un cliente y un Pod backend?
4. Explica con tus palabras: ¿Qué es un Endpoint?

**Respuestas esperadas**:
<details>
<summary>Ver respuestas</summary>

1. Los Pods son efímeros (IP cambia al recrearse). Services proporcionan una IP estable y nombre DNS para acceder a un grupo de Pods dinámico.

2. Cuando un Pod muere, se recrea con una **nueva IP**. Sin Service, los clientes perderían la conexión. El Service mantiene una IP estable y actualiza automáticamente sus Endpoints.

3. Cliente → DNS (resuelve nombre) → Service (ClusterIP) → kube-proxy (balanceo) → Endpoint (IP del Pod) → Pod backend

4. Un Endpoint es la dirección IP:Puerto de un Pod que cumple con el selector del Service. Es el "puente" entre el Service (abstracción) y los Pods reales (implementación).
</details>

**Mini-ejercicio**:
```bash
# Ejecuta estos comandos y observa la relación
kubectl get pods -o wide  # Ver IPs de Pods
kubectl get svc           # Ver ClusterIP del Service
kubectl get endpoints     # Ver mapping Service → Pods
```

**¿Listo para continuar?** Si respondiste correctamente, avanza a la siguiente sección. Si tienes dudas, revisa la Sección 1.

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

## ✅ Checkpoint 2: ClusterIP y Endpoints

Verifica tu comprensión antes de avanzar a exposición externa:

**Preguntas de Autoevaluación**:
1. ¿Cuál es la diferencia entre el `port` y el `targetPort` en un Service?
2. ¿Cómo sabe un Service qué Pods debe incluir en sus Endpoints?
3. ¿Qué sucede si cambias el selector de un Service existente?
4. ¿Cuándo necesitarías crear Endpoints manuales (sin selector)?
5. ¿Qué comando usarías para verificar que un Service tiene Endpoints configurados?

**Respuestas esperadas**:
<details>
<summary>Ver respuestas</summary>

1. **`port`**: Puerto expuesto por el Service (donde escucha el Service). **`targetPort`**: Puerto donde escucha el contenedor en el Pod. Ejemplo: Service en puerto 80 → redirige a puerto 8080 del Pod.

2. El Service usa el **`selector`** para encontrar Pods. El controlador de Endpoints busca todos los Pods con labels que coincidan con el selector y crea/actualiza el objeto Endpoints automáticamente.

3. Kubernetes actualiza los Endpoints inmediatamente. Los Pods que cumplan el nuevo selector se agregan; los que ya no cumplan se eliminan de los Endpoints.

4. Endpoints manuales se usan para:
   - Servicios externos (bases de datos fuera de K8s)
   - Migración gradual a Kubernetes
   - Servicios legacy que no son Pods

5. `kubectl get endpoints <service-name>` o `kubectl describe service <service-name>` (ver sección Endpoints)
</details>

**Ejercicio Práctico**:
```bash
# Crea un Deployment y Service
kubectl create deployment nginx --image=nginx --replicas=3
kubectl expose deployment nginx --port=80 --target-port=80

# Verifica la cadena completa
kubectl get pods -o wide -l app=nginx        # Ver IPs de Pods
kubectl get svc nginx                        # Ver ClusterIP
kubectl get endpoints nginx                  # Ver mapping
kubectl describe svc nginx                   # Ver todo junto

# Test desde otro Pod
kubectl run test --image=busybox -it --rm -- wget -O- http://nginx
```

**¿Listo?** Si entiendes ClusterIP y Endpoints, ¡continuemos con exposición externa!

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
- [Laboratorio 2: NodePort y LoadBalancer](laboratorios/lab-02-nodeport-loadbalancer.md)

---

## ✅ Checkpoint 3: Exposición Externa

Evalúa tu dominio de NodePort y LoadBalancer:

**Preguntas de Autoevaluación**:
1. ¿Cuál es el rango de puertos válido para NodePort? ¿Por qué existe ese rango?
2. ¿Qué sucede "bajo el capó" cuando creas un Service de tipo LoadBalancer?
3. Si tienes un NodePort en el puerto 30080, ¿puedes acceder al Service desde cualquier nodo del cluster?
4. ¿Por qué un LoadBalancer queda en `<pending>` en minikube? ¿Cómo lo solucionarías?
5. Compara: ¿Cuándo usarías NodePort vs LoadBalancer en producción?

**Respuestas esperadas**:
<details>
<summary>Ver respuestas</summary>

1. **Rango**: 30000-32767. Este rango existe para evitar conflictos con puertos del sistema (0-1023) y aplicaciones comunes (1024-29999). Es configurable en la API server.

2. LoadBalancer crea **tres capas**:
   - ClusterIP (interno)
   - NodePort automático (para que LB pueda llegar)
   - Solicitud al cloud provider para crear balanceador externo con IP pública

3. **Sí**, el tráfico llega a cualquier nodo:30080 y kube-proxy lo redirige internamente a Pods en cualquier nodo. Todos los nodos escuchan en el NodePort.

4. Minikube no tiene cloud provider. Soluciones:
   - `minikube tunnel` (simula LoadBalancer)
   - Usar MetalLB (bare-metal load balancer)
   - Cambiar a NodePort para testing local

5. **NodePort**: Solo para testing/dev o clusters sin cloud provider. **LoadBalancer**: Producción en cloud (AWS/GCP/Azure) - proporciona IP pública, health checks, distribución de tráfico real.
</details>

**Comparación Rápida**:
| Aspecto | ClusterIP | NodePort | LoadBalancer |
|---------|-----------|----------|--------------|
| Acceso | Solo interno | Interno + Externo (IP nodo) | Interno + Externo (IP pública) |
| Producción | ✅ Microservicios | ❌ Solo dev/test | ✅ Apps públicas |
| Costo | Gratis | Gratis | 💰 Costo por LB |
| Complejidad | Baja | Media | Media-Alta |

**Mini-Lab**:
```bash
# Experimenta con los 3 tipos
kubectl create deployment web --image=nginx --replicas=2

# 1. ClusterIP (interno)
kubectl expose deployment web --port=80 --name=web-clusterip

# 2. NodePort (externo)
kubectl expose deployment web --port=80 --type=NodePort --name=web-nodeport

# 3. LoadBalancer (si tienes cloud o minikube tunnel)
kubectl expose deployment web --port=80 --type=LoadBalancer --name=web-lb

# Compara
kubectl get svc
```

**Continúa cuando domines la diferencia entre los 3 tipos principales!**

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

## ✅ Checkpoint 4: Configuraciones Avanzadas

Verifica tu dominio de características avanzadas:

**Preguntas de Autoevaluación**:
1. ¿Qué es un Service headless y cuándo lo usarías?
2. Explica la diferencia entre Session Affinity "None" y "ClientIP"
3. ¿Cuál es el beneficio de usar `externalTrafficPolicy: Local`? ¿Qué desventaja tiene?
4. ¿Cómo afecta el modo de kube-proxy (iptables vs IPVS) al performance?
5. ¿Puedes tener múltiples Services apuntando a los mismos Pods?

**Respuestas esperadas**:
<details>
<summary>Ver respuestas</summary>

1. **Headless Service**: `clusterIP: None`. No tiene balanceo automático. DNS retorna **todas las IPs de Pods** directamente. Uso: StatefulSets (bases de datos), cuando la app necesita conectarse a Pods específicos.

2. **None** (default): Cada request se balancea aleatoriamente entre Pods. **ClientIP**: Requests de la misma IP origen van siempre al mismo Pod (hasta timeout). Útil para sesiones stateful.

3. **Beneficio de Local**: Preserva IP origen del cliente (logs reales), sin hop extra (mejor latencia). **Desventaja**: Balanceo desigual si Pods no están distribuidos uniformemente; si un nodo no tiene Pods, el tráfico falla.

4. **iptables**: Reglas lineales (lento con >5000 Services). **IPVS**: Hash table en kernel (muy rápido), algoritmos avanzados de balanceo (rr, lc, sh), soporta decenas de miles de Services.

5. **Sí**, múltiples Services pueden usar el mismo selector. Casos comunes:
   - Service interno (ClusterIP) + externo (LoadBalancer)
   - Diferentes puertos para diferentes propósitos
   - Servicios en múltiples namespaces
</details>

**Ejercicio Mental**:
```
Escenario: Base de datos MongoDB con 3 réplicas (primary + 2 secondary)
- ¿Qué tipo de Service usarías? ¿Por qué?
- ¿Necesitas un Service headless?
- ¿Usarías StatefulSet o Deployment?
```

<details>
<summary>Respuesta sugerida</summary>

- **Headless Service** para acceso directo a cada replica
- **StatefulSet** para identidad de Pod persistente (mongo-0, mongo-1, mongo-2)
- DNS: `mongo-0.mongo.default.svc.cluster.local` para conectarse al primary
- Possibly un segundo Service ClusterIP para reads balanceados
</details>

**Si dominas estos conceptos avanzados, ¡estás listo para best practices de producción!**

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

## ✅ Checkpoint Final: Integración de Conceptos

**¡Felicitaciones!** Has completado todo el contenido teórico. Ahora integra lo aprendido:

**Desafío de Diseño**:

Imagina que debes diseñar la arquitectura de networking para una aplicación de e-commerce:
- **Frontend** (React SPA) - necesita acceso público
- **API Gateway** - enruta requests al backend
- **Auth Service** - autenticación de usuarios
- **Product Service** - gestión de productos
- **Order Service** - procesamiento de órdenes
- **PostgreSQL** - base de datos (StatefulSet, 3 replicas)
- **Redis** - cache

**Diseña**:
1. ¿Qué tipo de Service usarías para cada componente?
2. ¿Cuáles necesitan acceso externo vs interno?
3. ¿Cómo configurarías la base de datos?
4. ¿Qué configuraciones avanzadas aplicarías (session affinity, traffic policy, etc.)?

<details>
<summary>Solución Sugerida</summary>

```yaml
# Frontend - Acceso público
---
kind: Service
spec:
  type: LoadBalancer  # O Ingress en producción real
  sessionAffinity: ClientIP  # Mantener sesión del browser
  
# API Gateway - Interno + externo
---
kind: Service
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local  # Preservar IPs para logs
  
# Auth, Product, Order Services - Solo interno
---
kind: Service
spec:
  type: ClusterIP  # Default, comunicación interna
  
# PostgreSQL - Headless para identidad de Pods
---
kind: Service
spec:
  clusterIP: None  # Headless
  # Usado por StatefulSet
  # DNS: postgres-0.postgres, postgres-1.postgres, etc.

# Redis - ClusterIP simple
---
kind: Service
spec:
  type: ClusterIP
  # Cache distribuido
```

**Configuraciones adicionales**:
- NetworkPolicies para restringir tráfico
- Readiness/Liveness probes en todos los Pods
- Prometheus annotations para monitoring
- TLS en Ingress (no en Services)
</details>

**Checklist de Dominio del Módulo**:
- [ ] Puedo explicar los 4 tipos de Services y cuándo usar cada uno
- [ ] Entiendo la relación Service → Endpoints → Pods
- [ ] Sé configurar Services internos (ClusterIP) y externos (NodePort/LB)
- [ ] Puedo diagnosticar problemas comunes (Endpoints vacíos, DNS issues)
- [ ] Conozco configuraciones avanzadas (headless, session affinity, traffic policy)
- [ ] He completado los 3 laboratorios prácticos
- [ ] Puedo diseñar arquitecturas de Services para aplicaciones reales

**Si marcaste todo, ¡estás listo para el siguiente módulo!** 🎉

## Resumen del Capítulo

Este capítulo cubrió los conceptos fundamentales de services y service discovery, desde la teoría hasta la práctica con ejemplos y manifiestos YAML aplicables en entornos reales. Los laboratorios en el directorio `laboratorios/` permiten practicar cada concepto, y el `RESUMEN-MODULO.md` sirve como guía de repaso rápido.
