# Área 2 - Fundamentos y Arquitectura de Kubernetes

**Duración**: 8 horas  
**Modalidad**: Teórico – Práctico

## 🎯 Objetivos de Aprendizaje

Al completar esta área, serás capaz de:

- Comprender la arquitectura completa de Kubernetes
- Identificar y configurar componentes del plano de control y nodos trabajadores
- Gestionar objetos principales: Pods, Services, Deployments
- Implementar networking y gestión de configuración
- Desplegar aplicaciones usando controladores
- Configurar Ingress para exposición de servicios

---

## 📚 Módulo 1: Arquitectura de Kubernetes (2 horas)

### ¿Qué es Kubernetes?

**Kubernetes** es una plataforma de código abierto para automatizar el despliegue, escalado y gestión de aplicaciones contenerizadas.

#### Conceptos Fundamentales

```
┌─────────────────────────────────────────────┐
│                 CLUSTER                     │
│  ┌─────────────────┐  ┌─────────────────┐   │
│  │   MASTER NODE   │  │   WORKER NODE   │   │
│  │                 │  │                 │   │
│  │  ┌───────────┐  │  │  ┌───────────┐  │   │
│  │  │   PODS    │  │  │  │   PODS    │  │   │
│  │  │┌─────────┐│  │  │  │┌─────────┐│  │   │
│  │  ││Container││  │  │  ││Container││  │   │
│  │  │└─────────┘│  │  │  │└─────────┘│  │   │
│  │  └───────────┘  │  │  └───────────┘  │   │
│  └─────────────────┘  └─────────────────┘   │
└─────────────────────────────────────────────┘
```

#### Jerarquía de Objetos

```
Cluster
├── Namespaces
│   ├── Pods
│   │   └── Containers
│   ├── Services
│   ├── Deployments
│   ├── ConfigMaps
│   └── Secrets
└── Nodes
    ├── kubelet
    ├── kube-proxy
    └── Container Runtime
```

### Arquitectura del Clúster

#### Plano de Control (Control Plane)

El **plano de control** gestiona el estado del clúster y toma decisiones globales.

**Componentes principales:**

1. **kube-apiserver**
   - API Gateway del clúster
   - Punto de entrada para todas las operaciones
   - Valida y procesa requests REST
   - Almacena estado en etcd

2. **etcd**
   - Base de datos distribuida clave-valor
   - Almacena todo el estado del clúster
   - Fuente de verdad para la configuración
   - Replicación y consistencia

3. **kube-scheduler**
   - Asigna Pods a nodos específicos
   - Considera recursos, afinidad, anti-afinidad
   - Políticas de scheduling personalizables

4. **kube-controller-manager**
   - Ejecuta controladores del sistema
   - Node Controller, Replication Controller
   - Endpoints Controller, Service Account Controller

5. **cloud-controller-manager** (opcional)
   - Interactúa con APIs del proveedor cloud
   - Gestiona Load Balancers, Volúmenes
   - Específico por proveedor (Azure, AWS, GCP)

#### Plano de Datos (Data Plane)

Los **nodos trabajadores** ejecutan las aplicaciones contenerizadas.

**Componentes principales:**

1. **kubelet**
   - Agente principal en cada nodo
   - Comunica con kube-apiserver
   - Gestiona Pods y containers
   - Reporta estado del nodo

2. **kube-proxy**
   - Proxy de red en cada nodo
   - Implementa Services de Kubernetes
   - Balanceo de carga entre Pods
   - Reglas iptables/IPVS

3. **Container Runtime**
   - Ejecuta contenedores
   - Compatible con CRI (Container Runtime Interface)
   - Ejemplos: containerd, CRI-O, Docker

### Flujo de Comunicación

```
kubectl → kube-apiserver → etcd
                    ↓
               kube-scheduler → selecciona nodo
                    ↓
               kubelet → Container Runtime → Pod
```

---

## 📚 Módulo 2: Objetos Principales de Kubernetes (2 horas)

### Pods

Un **Pod** es la unidad básica de despliegue en Kubernetes. Encapsula uno o más contenedores que comparten almacenamiento y red.

#### Características de los Pods

- **Efímeros**: No son permanentes
- **IP única**: Cada Pod tiene su propia IP
- **Almacenamiento compartido**: Volúmenes compartidos entre contenedores
- **Ciclo de vida**: Created → Running → Succeeded/Failed

#### YAML de Pod Básico

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mi-pod
  labels:
    app: mi-aplicacion
    version: "1.0"
spec:
  containers:
  - name: app-container
    image: nginx:1.21
    ports:
    - containerPort: 80
    env:
    - name: ENVIRONMENT
      value: "development"
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

### Deployments

Un **Deployment** proporciona actualizaciones declarativas para Pods y ReplicaSets.

#### Características de Deployments

- **Desired State**: Mantiene el estado deseado
- **Rolling Updates**: Actualizaciones sin tiempo de inactividad
- **Rollback**: Reversión a versiones anteriores
- **Scaling**: Escalado horizontal automático

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mi-aplicacion
  template:
    metadata:
      labels:
        app: mi-aplicacion
    spec:
      containers:
      - name: app-container
        image: nginx:1.21
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Services

Un **Service** define un conjunto lógico de Pods y una política para acceder a ellos.

#### Tipos de Services

1. **ClusterIP** (por defecto)
   - Solo accesible desde dentro del clúster
   - IP virtual interna

2. **NodePort**
   - Expone el servicio en cada nodo
   - Puerto en el rango 30000-32767

3. **LoadBalancer**
   - Crea un load balancer externo
   - Disponible en proveedores cloud

4. **ExternalName**
   - Mapea a un nombre DNS externo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mi-service
spec:
  type: ClusterIP
  selector:
    app: mi-aplicacion
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
```

### Namespaces

Los **Namespaces** proporcionan aislamiento virtual dentro del clúster.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: desarrollo
  labels:
    name: desarrollo
    environment: dev
```

#### Namespaces por Defecto

- **default**: Namespace por defecto para objetos sin namespace específico
- **kube-system**: Para objetos creados por el sistema
- **kube-public**: Legible por todos los usuarios
- **kube-node-lease**: Para heartbeats de nodos

---

## 📚 Módulo 3: Gestión de Configuración (1.5 horas)

### ConfigMaps

Los **ConfigMaps** almacenan datos de configuración no confidenciales en pares clave-valor.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_url: "postgres://db-server:5432/myapp"
  log_level: "info"
  max_connections: "100"
  config.properties: |
    server.port=8080
    server.host=0.0.0.0
    debug=false
```

#### Uso de ConfigMaps en Pods

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: mi-app:latest
    env:
    # Variable individual desde ConfigMap
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_url
    # Todas las claves como variables de entorno
    envFrom:
    - configMapRef:
        name: app-config
    volumeMounts:
    # Archivo desde ConfigMap
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

### Secrets

Los **Secrets** almacenan datos sensibles como contraseñas, tokens OAuth, y claves SSH.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  username: dXNlcm5hbWU=  # base64 encoded
  password: cGFzc3dvcmQ=  # base64 encoded
```

#### Crear Secrets desde línea de comandos

```bash
# Desde literales
kubectl create secret generic app-secrets \
  --from-literal=username=admin \
  --from-literal=password=secretpassword

# Desde archivos
kubectl create secret generic ssl-certs \
  --from-file=tls.crt=server.crt \
  --from-file=tls.key=server.key

# TLS específico
kubectl create secret tls tls-secret \
  --cert=server.crt \
  --key=server.key
```

#### Uso de Secrets en Pods

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
  - name: app
    image: mi-app:latest
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: password
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secrets
```

---

## 📚 Módulo 4: Networking en Kubernetes (2 horas)

### Modelo de Red de Kubernetes

Kubernetes impone los siguientes requerimientos fundamentales:

1. **Pods** pueden comunicarse con otros Pods sin NAT
2. **Nodos** pueden comunicarse con todos los Pods sin NAT
3. **IP** que ve un Pod es la misma que ven otros

#### Arquitectura de Red

```
┌─────────────────────────────────────────────┐
│                 CLUSTER                     │
│                                             │
│  ┌─────────────────┐  ┌─────────────────┐   │
│  │     NODE 1      │  │     NODE 2      │   │
│  │                 │  │                 │   │
│  │ Pod A           │  │ Pod C           │   │
│  │ 10.244.1.2      │  │ 10.244.2.2      │   │
│  │       ↕         │  │       ↕         │   │
│  │ Pod B           │  │ Pod D           │   │
│  │ 10.244.1.3      │  │ 10.244.2.3      │   │
│  │                 │  │                 │   │
│  │  bridge: cbr0   │  │  bridge: cbr0   │   │
│  │  10.244.1.1     │  │  10.244.2.1     │   │
│  └─────────────────┘  └─────────────────┘   │
│          ↕                     ↕            │
│  ┌─────────────────────────────────────────┐ │
│  │           CLUSTER NETWORK               │ │
│  │            (underlay)                   │ │
│  └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### CNI (Container Network Interface)

**CNI** es el estándar para configurar redes en contenedores Linux.

#### Plugins CNI Populares

1. **Flannel**: Overlay network simple
2. **Calico**: Política de red y BGP routing
3. **Weave**: Mesh networking
4. **Cilium**: eBPF-based networking
5. **Azure CNI**: Integración nativa con Azure VNet

### Tipos de Services Detallados

#### ClusterIP Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
```

#### NodePort Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 30080  # Opcional, se asigna automáticamente si se omite
```

#### LoadBalancer Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
  loadBalancerSourceRanges:
  - 10.0.0.0/8
```

### Ingress

**Ingress** gestiona el acceso externo a servicios HTTP y HTTPS, proporcionando balanceo de carga, terminación SSL y hosting virtual basado en nombres.

#### Ingress Controller

Primero necesitas un **Ingress Controller** (ej: NGINX, Traefik, Azure Application Gateway).

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: tls-secret
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

### Azure Application Gateway Ingress Controller (AGIC)

**AGIC** integra Azure Application Gateway con AKS.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: azure-ingress
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
    appgw.ingress.kubernetes.io/connection-draining: "true"
    appgw.ingress.kubernetes.io/connection-draining-timeout: "30"
spec:
  tls:
  - secretName: tls-secret
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

---

## 📚 Módulo 5: Controladores Avanzados (0.5 horas)

### ReplicaSet

Un **ReplicaSet** asegura que un número específico de réplicas de Pod estén ejecutándose en cualquier momento.

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: frontend-replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21
```

### StatefulSet

**StatefulSet** gestiona Pods con identidad persistente y almacenamiento ordenado.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database-statefulset
spec:
  serviceName: database-headless
  replicas: 3
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: database
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: myapp
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
```

### DaemonSet

**DaemonSet** asegura que todos (o algunos) nodos ejecuten una copia de un Pod.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      containers:
      - name: fluentd
        image: fluentd:v1.14
        volumeMounts:
        - name: varlog
          mountPath: /var/log
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
```

---

## 🧪 Laboratorio 2.1: Configurar AKS y Desplegar Primera Aplicación

### Paso 1: Crear Clúster AKS

```bash
# Crear AKS cluster
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-addons monitoring \
  --attach-acr acrk8scourse \
  --generate-ssh-keys

# Obtener credenciales
az aks get-credentials \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course

# Verificar conexión
kubectl get nodes
kubectl cluster-info
```

### Paso 2: Explorar el Clúster

```bash
# Ver namespaces
kubectl get namespaces

# Ver componentes del sistema
kubectl get pods -n kube-system

# Ver servicios del sistema
kubectl get services -n kube-system

# Información detallada del clúster
kubectl describe nodes
```

### Paso 3: Desplegar Aplicación Simple

```bash
# Crear namespace para nuestras aplicaciones
kubectl create namespace desarrollo

# Crear deployment
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: desarrollo
spec:
  replicas: 3
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
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF

# Verificar deployment
kubectl get deployments -n desarrollo
kubectl get pods -n desarrollo
kubectl describe deployment nginx-deployment -n desarrollo
```

### Paso 4: Crear Service

```bash
# Crear service ClusterIP
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: desarrollo
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
EOF

# Verificar service
kubectl get services -n desarrollo
kubectl describe service nginx-service -n desarrollo

# Probar conectividad interna
kubectl run test-pod --image=curlimages/curl -i --rm --restart=Never -- curl http://nginx-service.desarrollo.svc.cluster.local
```

### Paso 5: Exponer con LoadBalancer

```bash
# Crear service LoadBalancer
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
  namespace: desarrollo
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
EOF

# Esperar a que se asigne IP externa
kubectl get services -n desarrollo -w

# Probar acceso externo
EXTERNAL_IP=$(kubectl get service nginx-loadbalancer -n desarrollo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP
```

---

## 🧪 Laboratorio 2.2: ConfigMaps y Secrets

### Paso 1: Crear ConfigMap

```bash
# Crear ConfigMap desde línea de comandos
kubectl create configmap app-config \
  --from-literal=database_url="postgres://db-server:5432/myapp" \
  --from-literal=log_level="info" \
  --from-literal=max_connections="100" \
  --namespace=desarrollo

# Crear ConfigMap desde archivo
cat << 'EOF' > app.properties
server.port=8080
server.host=0.0.0.0
debug=false
cache.enabled=true
EOF

kubectl create configmap app-properties \
  --from-file=app.properties \
  --namespace=desarrollo

# Verificar ConfigMaps
kubectl get configmaps -n desarrollo
kubectl describe configmap app-config -n desarrollo
```

### Paso 2: Crear Secrets

```bash
# Crear Secret para base de datos
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=supersecret123 \
  --namespace=desarrollo

# Crear Secret TLS
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.local/O=myapp"

kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key \
  --namespace=desarrollo

# Verificar secrets
kubectl get secrets -n desarrollo
kubectl describe secret db-secret -n desarrollo
```

### Paso 3: Aplicación que usa ConfigMap y Secrets

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-app
  namespace: desarrollo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: config-app
  template:
    metadata:
      labels:
        app: config-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        env:
        # Variables desde ConfigMap
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database_url
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: log_level
        # Variables desde Secret
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        volumeMounts:
        # ConfigMap como archivo
        - name: config-volume
          mountPath: /etc/config
        # Secret como archivo
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
      volumes:
      - name: config-volume
        configMap:
          name: app-properties
      - name: secret-volume
        secret:
          secretName: db-secret
EOF

# Verificar deployment
kubectl get pods -n desarrollo -l app=config-app

# Verificar variables de entorno
POD_NAME=$(kubectl get pods -n desarrollo -l app=config-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -n desarrollo -- env | grep -E "(DATABASE|LOG|DB_)"

# Verificar archivos montados
kubectl exec $POD_NAME -n desarrollo -- ls -la /etc/config
kubectl exec $POD_NAME -n desarrollo -- cat /etc/config/app.properties
kubectl exec $POD_NAME -n desarrollo -- ls -la /etc/secrets
kubectl exec $POD_NAME -n desarrollo -- cat /etc/secrets/username
```

---

## 🧪 Laboratorio 2.3: Configurar Ingress

### Paso 1: Instalar NGINX Ingress Controller

```bash
# Agregar repositorio Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Instalar NGINX Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.externalTrafficPolicy=Local

# Verificar instalación
kubectl get pods -n ingress-nginx
kubectl get services -n ingress-nginx

# Obtener IP externa del Ingress Controller
INGRESS_IP=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $INGRESS_IP"
```

### Paso 2: Desplegar Aplicaciones de Prueba

```bash
# Aplicación Frontend
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
  namespace: desarrollo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        configMap:
          name: frontend-html
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-html
  namespace: desarrollo
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>Frontend App</title></head>
    <body>
      <h1>Frontend Application</h1>
      <p>Esta es la aplicación frontend.</p>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: desarrollo
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
EOF

# Aplicación Backend
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
  namespace: desarrollo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx:1.21
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        configMap:
          name: backend-html
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-html
  namespace: desarrollo
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>Backend API</title></head>
    <body>
      <h1>Backend API</h1>
      <p>Esta es la API backend.</p>
      <p>Versión: 1.0</p>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: desarrollo
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
EOF
```

### Paso 3: Crear Ingress Resource

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: desarrollo
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
EOF

# Verificar Ingress
kubectl get ingress -n desarrollo
kubectl describe ingress app-ingress -n desarrollo
```

### Paso 4: Probar Ingress

```bash
# Agregar entrada al /etc/hosts (solo para pruebas locales)
echo "$INGRESS_IP myapp.local" | sudo tee -a /etc/hosts

# Probar rutas
curl http://myapp.local/
curl http://myapp.local/api

# Ver logs del Ingress Controller
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

---

## 📝 Resumen del Área 2

### Conceptos Clave Aprendidos

1. **Arquitectura de Kubernetes**
   - Plano de control vs plano de datos
   - Componentes principales y sus funciones
   - Flujo de comunicación entre componentes

2. **Objetos Fundamentales**
   - Pods: unidad básica de despliegue
   - Deployments: gestión declarativa de aplicaciones
   - Services: exposición y descubrimiento de servicios
   - Namespaces: aislamiento lógico

3. **Gestión de Configuración**
   - ConfigMaps para configuración no sensible
   - Secrets para datos confidenciales
   - Inyección como variables de entorno y archivos

4. **Networking**
   - Modelo de red de Kubernetes
   - Tipos de Services y sus casos de uso
   - Ingress para acceso HTTP/HTTPS externo

5. **Controladores**
   - ReplicaSet, StatefulSet, DaemonSet
   - Casos de uso específicos para cada tipo

### Habilidades Prácticas Desarrolladas

✅ Crear y gestionar clústeres AKS  
✅ Desplegar aplicaciones con Deployments  
✅ Configurar Services para comunicación  
✅ Gestionar configuración con ConfigMaps y Secrets  
✅ Implementar Ingress para acceso externo  
✅ Usar kubectl para administración diaria  

### Preparación para el Área 3

En el siguiente módulo abordaremos:
- Administración avanzada de clústeres AKS
- Seguridad y RBAC
- Almacenamiento persistente
- Network Policies
- Integración con servicios Azure

---

## 🔗 Enlaces Útiles

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Helm Documentation](https://helm.sh/docs/)

## ▶️ Siguiente: [Área 3 - Operación, Seguridad y Almacenamiento](../area-3-operacion-seguridad/README.md)