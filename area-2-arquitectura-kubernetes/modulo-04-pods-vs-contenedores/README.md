# 🐳 Módulo 04: Pods vs Contenedores - De LXC a Kubernetes

**Duración**: 45 minutos  
**Modalidad**: Teórico-Práctico  
**Dificultad**: Intermedio

## 🎯 Objetivos del Módulo

Al completar este módulo serás capaz de:

- ✅ **Entender la evolución** de LXC → Docker → Kubernetes Pods
- ✅ **Explicar qué es un Pod** y cómo funciona internamente
- ✅ **Comprender los namespaces compartidos** en un Pod
- ✅ **Identificar cuándo usar** un Pod vs múltiples Pods
- ✅ **Diseñar arquitecturas multi-contenedor** efectivas
- ✅ **Migrar de Docker Compose** a Kubernetes Pods

---

## � 1. La Evolución de los Contenedores

### **� Línea de Tiempo: LXC → Docker → Kubernetes**

```
2008: LXC (Linux Containers)
├─ Contenedores completamente aislados
├─ Cada uno con su propia red, PID, IPC
└─ Comunicación entre contenedores muy compleja

2013: Docker 
├─ Simplifica la gestión de contenedores
├─ Introduce la red bridge para comunicación
└─ Facilita compartir recursos entre contenedores

2014: Kubernetes
├─ Introduce el concepto de "Pod"
├─ Agrupa contenedores relacionados
└─ Comparte namespaces automáticamente
```

### **🏗️ El Problema Original (LXC)**

```
┌─────────────────┐    ┌─────────────────┐
│   Contenedor 1  │    │   Contenedor 2  │
│                 │    │                 │
│  🌐 Red: IP1    │ ❌ │  🌐 Red: IP2    │
│  🔄 PID: NS1    │ ❌ │  🔄 PID: NS2    │  
│  💬 IPC: NS1    │ ❌ │  💬 IPC: NS2    │
│  🏷️ UTS: NS1    │ ❌ │  🏷️ UTS: NS2    │
└─────────────────┘    └─────────────────┘

❌ Problema: Aislamiento total = Comunicación compleja
```

### **🌉 La Solución Docker (Red Bridge)**

```
┌─────────────────┐    ┌─────────────────┐
│   Contenedor 1  │    │   Contenedor 2  │
│   IP: 172.17.2  │    │   IP: 172.17.3  │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────┬───────────────┘
                 │
        ┌────────▼────────┐
        │   Docker Bridge │
        │   (docker0)     │
        └─────────────────┘

✅ Solución: Red compartida para comunicación
```

---

## 🧩 2. ¿Qué es un Pod? (La Evolución Final)

### **📖 Definición Técnica:**

> **Pod = Wrapper que comparte Linux namespaces entre contenedores**

### **🔬 Cómo Funciona Internamente:**

Cuando Kubernetes crea un Pod, internamente sigue estos pasos:

```
Paso 1: Kubernetes crea un "contenedor pausa" (dummy)
┌─────────────────────────────────────────┐
│     Contenedor Pausa (k8s.gcr.io/pause) │
│                                         │
│  🌐 Network Namespace: 10.244.1.15      │
│  🔄 PID Namespace: 1001                 │
│  💬 IPC Namespace: 1001                 │
│  🏷️ UTS Namespace: pod-xyz              │
└─────────────────────────────────────────┘

Paso 2: Otros contenedores "heredan" estos namespaces
┌──────────────────┐  ┌──────────────────┐
│   App Container  │  │Sidecar Container │
│                  │  │                  │
│ 🌐 Hereda: ──────┼──┼─→ 10.244.1.15    │
│ 🔄 Hereda: ──────┼──┼─→ PID NS: 1001   │
│ 💬 Hereda: ──────┼──┼─→ IPC NS: 1001   │
│ 🏷️ Hereda: ──────┼──┼─→ UTS: pod-xyz   │
│                  │  │                  │
│ ❌ NO comparten: │  │ ❌ NO comparten: │
│ 📁 Mount NS      │  │ 📁 Mount NS      │
│ 👤 User NS       │  │ � User NS        │
│ ⚙️ Cgroup        │  │ ⚙️ Cgroup        │
└──────────────────┘  └──────────────────┘

Resultado: Pod con comunicación optimizada
```

### **🎯 Los 3 Namespaces Compartidos:**

#### **1. 🌐 Network Namespace**
```bash
# Todos los contenedores del Pod comparten la misma IP
IP_DEL_POD="10.244.1.15"

# Comunicación interna vía localhost
Container1 → localhost:8080 → Container2
Container2 → localhost:9090 → Container1
```

#### **2. 🔄 PID Namespace (Inter-Process Communication)**
```bash
# Los contenedores pueden ver procesos de otros contenedores
kubectl exec -it my-pod -c container1 -- ps aux
# ↑ Verá procesos de container1 Y container2
```

#### **3. 🏷️ UTS Namespace (Hostname)**
```bash
# Todos los contenedores comparten el mismo hostname
kubectl exec -it my-pod -c container1 -- hostname
# → pod-xyz-12345

kubectl exec -it my-pod -c container2 -- hostname  
# → pod-xyz-12345 (mismo hostname)
```

### **❌ Los Namespaces NO Compartidos:**

#### **📁 Mount Namespace (Volumes independientes)**
```yaml
# Cada contenedor puede tener sus propios volumes
volumes:
- name: shared-data
- name: container1-only
- name: container2-only
```

#### **⚙️ Cgroups (Recursos independientes)**
```yaml
# Control independiente de CPU/Memory por contenedor
containers:
- name: web
  resources:
    limits:
      cpu: "500m"
      memory: "512Mi"
- name: sidecar
  resources:
    limits:
      cpu: "100m" 
      memory: "128Mi"
```

---

## 🆚 3. Docker vs Pods: Evolución Práctica

### **📊 Comparación Visual:**

#### **🐳 Docker Approach (Manual)**
```bash
# Crear red personalizada
docker network create app-network

# Ejecutar contenedores en la red
docker run -d --name web --network app-network nginx
docker run -d --name api --network app-network node-app
docker run -d --name db --network app-network postgres

# Comunicación: web → api.app-network → db.app-network
```

#### **☸️ Kubernetes Approach (Automático)**
```yaml
# Pod automáticamente maneja networking
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: web
    image: nginx
    ports:
    - containerPort: 80
  - name: api
    image: node-app  
    ports:
    - containerPort: 3000

# Comunicación: web → localhost:3000 → api (automática)
```

### **🔄 Migration Path: Compose → Kubernetes**

#### **Before: docker-compose.yml**
```yaml
version: '3.8'
services:
  web:
    image: nginx
    ports:
      - "8080:80"
    depends_on:
      - api
      
  api:
    image: node-app
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=db
      
  db:
    image: postgres
    environment:
      - POSTGRES_DB=myapp
```

#### **After: Kubernetes Strategy**

**Option A: Multi-Pod (Recommended)**
```yaml
# web-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 2
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
        image: nginx
        ports:
        - containerPort: 80

---
# api-deployment.yaml  
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: node-app
        image: node-app
        ports:
        - containerPort: 3000
        env:
        - name: DB_HOST
          value: "db-service"

---
# db-deployment.yaml
apiVersion: apps/v1  
kind: Deployment
metadata:
  name: db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: postgres
        image: postgres
        env:
        - name: POSTGRES_DB
          value: "myapp"
```

**Option B: Single Pod (Edge cases only)**
```yaml
# Only if tightly coupled (rare)
apiVersion: v1
kind: Pod
metadata:
  name: tightly-coupled-app
spec:
  containers:
  - name: main-app
    image: my-app
    ports:
    - containerPort: 8080
  - name: log-processor
    image: log-processor
    # Processes logs from main-app via shared volume
    volumeMounts:
    - name: log-volume
      mountPath: /logs
  volumes:
  - name: log-volume
    emptyDir: {}
```

### **🔄 Patrón 1: Sidecar Container**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-with-logging
spec:
  containers:
  # Main application container
  - name: web-app
    image: nginx:1.20
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
  
  # Sidecar for log processing
  - name: log-processor
    image: fluent/fluent-bit:1.8
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
      readOnly: true
    - name: fluent-config
      mountPath: /fluent-bit/etc
  
  volumes:
  - name: shared-logs
    emptyDir: {}
  - name: fluent-config
    configMap:
      name: fluent-config
```

**Casos de uso Sidecar:**
- 📊 **Logging**: Fluentd, Logstash, Filebeat
- 📈 **Monitoring**: Prometheus exporters
- 🔐 **Security**: Policy enforcement, cert management
- 🌐 **Networking**: Service mesh proxies (Istio, Linkerd)

### **🚀 Patrón 2: Init Container**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-with-init
spec:
  # Init containers run BEFORE main containers
  initContainers:
  - name: database-migration
    image: migrate/migrate:v4.15.1
    command: ['migrate', '-path', '/migrations', '-database', 'postgres://...', 'up']
    volumeMounts:
    - name: migrations
      mountPath: /migrations
  
  - name: config-setup
    image: busybox:1.35
    command: ['sh', '-c', 'echo "Preparing config..." && cp /tmp/config/* /app/config/']
    volumeMounts:
    - name: config-source
      mountPath: /tmp/config
    - name: app-config
      mountPath: /app/config
  
  # Main application starts AFTER init containers complete
  containers:
  - name: web-app
    image: my-app:v1.0
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: app-config
      mountPath: /app/config
  
  volumes:
  - name: migrations
    configMap:
      name: db-migrations
  - name: config-source
    secret:
      secretName: app-secrets
  - name: app-config
    emptyDir: {}
```

**Casos de uso Init Containers:**
- 🗄️ **Database migrations**: Schema updates antes del deploy
- ⬇️ **Data downloading**: Fetch assets o dependencies
- ⏳ **Wait for dependencies**: Esperar DB, APIs externas
- 🔧 **Configuration setup**: Generate configs dinámicamente

### **🔗 Patrón 3: Ambassador Container**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-ambassador
spec:
  containers:
  # Main application
  - name: app
    image: my-app:v1.0
    ports:
    - containerPort: 8080
    env:
    - name: DATABASE_URL
      value: "localhost:5432"  # ← Apunta al ambassador
  
  # Ambassador proxy
  - name: db-ambassador
    image: haproxy:2.4
    ports:
    - containerPort: 5432
    volumeMounts:
    - name: ambassador-config
      mountPath: /usr/local/etc/haproxy
    # Ambassador maneja:
    # - Connection pooling
    # - Load balancing to multiple DB replicas
    # - Circuit breaking
    # - SSL termination
  
  volumes:
  - name: ambassador-config
    configMap:
      name: haproxy-config
```

---

## 🛠️ 5. Migración: Docker Compose → Kubernetes

### **🐳 Docker Compose Original:**

```yaml
# docker-compose.yml
version: '3.8'
services:
  web:
    image: nginx:1.20
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - api
  
  api:
    image: my-api:v1.0
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/myapp
    depends_on:
      - db
  
  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

### **☸️ Kubernetes Equivalent:**

#### **Opción 1: Pods Separados (Recomendado)**

```yaml
# web-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  labels:
    app: web
spec:
  containers:
  - name: nginx
    image: nginx:1.20
    ports:
    - containerPort: 80
    volumeMounts:
    - name: nginx-config
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
  volumes:
  - name: nginx-config
    configMap:
      name: nginx-config

---
# api-pod.yaml  
apiVersion: v1
kind: Pod
metadata:
  name: api-pod
  labels:
    app: api
spec:
  containers:
  - name: api
    image: my-api:v1.0
    ports:
    - containerPort: 3000
    env:
    - name: DATABASE_URL
      value: "postgres://user:pass@db-service:5432/myapp"

---
# db-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: db-pod
  labels:
    app: db
spec:
  containers:
  - name: postgres
    image: postgres:13
    ports:
    - containerPort: 5432
    env:
    - name: POSTGRES_DB
      value: myapp
    - name: POSTGRES_USER
      value: user
    - name: POSTGRES_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
    volumeMounts:
    - name: db-storage
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: db-storage
    persistentVolumeClaim:
      claimName: db-pvc
```

#### **Opción 2: Multi-Container Pod (Casos específicos)**

```yaml
  # Solo cuando los contenedores están FUERTEMENTE acoplados
apiVersion: v1
kind: Pod
metadata:
  name: tightly-coupled-app
spec:
  containers:
  # Main web app
  - name: web-app
    image: my-web-app:v1.0
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: shared-data
      mountPath: /app/data
    
  # Real-time data processor (tightly coupled)
  - name: data-processor
    image: data-processor:v1.0
    volumeMounts:
    - name: shared-data
      mountPath: /processor/input
    # Nota: Solo cuando necesitas:
    # - Procesamiento en tiempo real de datos compartidos
    # - IPC communication
    # - Shared memory patterns
    
  volumes:
  - name: shared-data
    emptyDir: {}
```

### **🎯 Decisión Matrix: ¿Un Pod o Múltiples Pods?**

```
┌─────────────────────────────────────────────────────────┐
│                  DECISIÓN ARCHITECTURE                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  🟢 UN SOLO POD cuando:                                 │
│  ├─ Comunicación muy frecuente (microsegundos)          │
│  ├─ Shared memory o IPC necesario                       │
│  ├─ Mismo ciclo de vida ESTRICTO                        │
│  ├─ Datos compartidos en tiempo real                    │
│  └─ Imposible separar funcionalmente                    │
│                                                         │
│  🔴 PODS SEPARADOS cuando:                              │
│  ├─ Escalado independiente necesario                    │
│  ├─ Actualizaciones independientes                      │
│  ├─ Comunicación vía HTTP/gRPC                          │
│  ├─ Diferentes equipos o ownership                      │
│  ├─ Diferentes resource requirements                    │
│  └─ Fault isolation deseado                             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🧪 6. Laboratorios Prácticos Mejorados

### **🚀 Lab 1: Evolución Histórica Práctica**

**Objetivo**: Experimentar la diferencia entre enfoques LXC, Docker y Kubernetes.

```bash
# Crear directorio para el lab
mkdir -p ~/labs/modulo-04/evolution-demo && cd ~/labs/modulo-04/evolution-demo

echo "🎯 DEMO: Evolución LXC → Docker → Kubernetes"
echo "=============================================="

# Paso 1: Simular problema LXC (containers completamente aislados)
echo ""
echo "📦 PASO 1: Enfoque LXC (Aislamiento total)"
echo "├─ Crear 2 contenedores Docker aislados"
echo "├─ Intentar comunicación directa"
echo "└─ Observar complejidad"

# Crear dos contenedores sin network bridge
docker run -d --name lxc-app1 --network none nginx:alpine
docker run -d --name lxc-app2 --network none nginx:alpine

# Verificar aislamiento total
echo "❌ Contenedores sin networking:"
docker exec lxc-app1 ip addr show
docker exec lxc-app2 ip addr show

# Cleanup
docker stop lxc-app1 lxc-app2 && docker rm lxc-app1 lxc-app2

# Paso 2: Enfoque Docker (Bridge network)
echo ""
echo "🌉 PASO 2: Enfoque Docker (Bridge Network)"  
echo "├─ Crear red bridge personalizada"
echo "├─ Contenedores se comunican vía IP interna"
echo "└─ Comunicación funcional pero manual"

# Crear red bridge
docker network create evolution-demo

# Crear contenedores en la red
docker run -d --name docker-web --network evolution-demo nginx:alpine
docker run -d --name docker-api --network evolution-demo httpd:alpine

# Probar comunicación
echo "✅ Comunicación Docker bridge:"
docker exec docker-web nslookup docker-api
docker exec docker-web wget -qO- http://docker-api

# Cleanup
docker stop docker-web docker-api && docker rm docker-web docker-api
docker network rm evolution-demo

# Paso 3: Enfoque Kubernetes (Pod shared networking)
echo ""
echo "☸️ PASO 3: Enfoque Kubernetes (Pod Networking)"
echo "├─ Crear Pod multi-container"
echo "├─ Comunicación vía localhost"
echo "└─ Networking automático"

cat > evolution-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: evolution-demo
  labels:
    demo: evolution
spec:
  containers:
  - name: web
    image: nginx:alpine
    ports:
    - containerPort: 80
    
  - name: api
    image: httpd:alpine
    ports:
    - containerPort: 80
    # httpd usa puerto 80 por defecto
    # nginx también usa 80, pero en el Pod solo uno puede usar cada puerto
    # Cambiaremos httpd a puerto 8080
    command: ["/bin/sh"]
    args: ["-c", "sed 's/Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf > /tmp/httpd.conf && httpd -f /tmp/httpd.conf -D FOREGROUND"]
EOF

# Aplicar Pod
kubectl apply -f evolution-pod.yaml

# Esperar a que esté listo
kubectl wait --for=condition=Ready pod/evolution-demo --timeout=60s

# Probar comunicación localhost
echo "✅ Comunicación Kubernetes (localhost):"
kubectl exec evolution-demo -c web -- wget -qO- http://localhost:8080
kubectl exec evolution-demo -c api -- wget -qO- http://localhost:80

# Ver información del Pod
kubectl describe pod evolution-demo | grep IP

# Cleanup
kubectl delete pod evolution-demo

echo ""
echo "📊 RESUMEN DE LA EVOLUCIÓN:"
echo "├─ LXC: Aislamiento total = Comunicación imposible"
echo "├─ Docker: Bridge network = Comunicación por IP/nombre"
echo "└─ Kubernetes: Shared networking = Comunicación localhost"
```

### **🔬 Lab 2: Namespace Sharing Deep Dive**

**Objetivo**: Explorar qué namespaces comparten los contenedores en un Pod.

```bash
mkdir -p ~/labs/modulo-04/namespace-demo && cd ~/labs/modulo-04/namespace-demo

echo "🔬 NAMESPACE SHARING ANALYSIS"
echo "=============================="

# Crear Pod multi-container para análisis
cat > namespace-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: namespace-demo
spec:
  containers:
  - name: container1
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo 'Container 1 running'; sleep 30; done"]
    
  - name: container2
    image: busybox  
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo 'Container 2 running'; sleep 30; done"]
EOF

kubectl apply -f namespace-pod.yaml
kubectl wait --for=condition=Ready pod/namespace-demo --timeout=60s

echo ""
echo "🌐 1. NETWORK NAMESPACE (Compartido)"
echo "├─ Ambos contenedores tienen la misma IP"

kubectl exec namespace-demo -c container1 -- ip addr show eth0
kubectl exec namespace-demo -c container2 -- ip addr show eth0

echo ""
echo "🔄 2. PID NAMESPACE (Compartido)"
echo "├─ Los contenedores pueden ver procesos entre sí"

echo "Procesos en container1:"
kubectl exec namespace-demo -c container1 -- ps aux
echo ""
echo "Procesos en container2 (nota que ve ambos):"
kubectl exec namespace-demo -c container2 -- ps aux

echo ""
echo "🏷️ 3. UTS NAMESPACE (Compartido - Hostname)"
echo "├─ Ambos contenedores tienen el mismo hostname"

echo "Hostname container1:"
kubectl exec namespace-demo -c container1 -- hostname
echo "Hostname container2:"
kubectl exec namespace-demo -c container2 -- hostname

echo ""
echo "💬 4. IPC NAMESPACE (Compartido)"
echo "├─ Pueden comunicarse via IPC"

kubectl exec namespace-demo -c container1 -- ipcs
kubectl exec namespace-demo -c container2 -- ipcs

echo ""
echo "📁 5. MOUNT NAMESPACE (NO compartido)"
echo "├─ Cada contenedor tiene su propio filesystem"

echo "Filesystem container1:"
kubectl exec namespace-demo -c container1 -- df -h
echo ""
echo "Filesystem container2:"
kubectl exec namespace-demo -c container2 -- df -h

echo ""
echo "👤 6. USER NAMESPACE (NO compartido)"
echo "├─ Pueden tener diferentes users"

echo "User container1:"
kubectl exec namespace-demo -c container1 -- id
echo "User container2:"  
kubectl exec namespace-demo -c container2 -- id

echo ""
echo "📊 RESUMEN NAMESPACE SHARING:"
echo "├─ ✅ Network: Misma IP, comunicación localhost"
echo "├─ ✅ PID: Procesos visibles entre contenedores"
echo "├─ ✅ UTS: Mismo hostname"
echo "├─ ✅ IPC: Pueden usar shared memory"
echo "├─ ❌ Mount: Filesystem independiente"
echo "└─ ❌ User: Users independientes"

# Cleanup
kubectl delete pod namespace-demo
```

### **🏗️ Lab 3: Sidecar Pattern Real-World**

**Objetivo**: Implementar logging sidecar con aplicación real.

```bash
mkdir -p ~/labs/modulo-04/sidecar-real && cd ~/labs/modulo-04/sidecar-real

echo "🏗️ SIDECAR PATTERN: Real-World Logging"
echo "======================================"

# 1. Crear aplicación web que genera logs
cat > web-app.py << 'EOF'
from flask import Flask, request, jsonify
import logging
import json
import time
from datetime import datetime

app = Flask(__name__)

# Configurar logging para escribir JSON estructurado
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s',
    handlers=[
        logging.FileHandler('/var/log/app/access.log'),
        logging.StreamHandler()
    ]
)

@app.route('/')
def home():
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'method': request.method,
        'path': request.path,
        'user_agent': request.headers.get('User-Agent'),
        'ip': request.remote_addr,
        'message': 'Home page accessed'
    }
    app.logger.info(json.dumps(log_entry))
    return jsonify({'message': '🏠 Welcome to Sidecar Demo', 'status': 'ok'})

@app.route('/api/users')
def users():
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'method': request.method,
        'path': request.path,
        'user_agent': request.headers.get('User-Agent'),
        'ip': request.remote_addr,
        'message': 'Users API accessed'
    }
    app.logger.info(json.dumps(log_entry))
    return jsonify([{'id': 1, 'name': 'Alice'}, {'id': 2, 'name': 'Bob'}])

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# 2. Crear Dockerfile para la app
cat > Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY web-app.py .
RUN pip install flask && mkdir -p /var/log/app
EXPOSE 5000
CMD ["python", "web-app.py"]
EOF

# 3. Build imagen
docker build -t sidecar-webapp:v1 .

# 4. Crear log processor (Fluent Bit config)
cat > fluent-bit.conf << 'EOF'
[SERVICE]
    Flush         1
    Log_Level     info
    Daemon        off

[INPUT]
    Name              tail
    Path              /var/log/app/access.log
    Tag               app.access
    Refresh_Interval  1
    Read_from_Head    true

[FILTER]
    Name   parser
    Match  app.access
    Key_Name log
    Parser json

[OUTPUT]
    Name   file
    Match  *
    Path   /var/log/processed/
    File   processed.log
    Format json_lines

[OUTPUT]
    Name   stdout
    Match  *
    Format json_lines
EOF

# 5. Crear Pod con sidecar
cat > sidecar-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: webapp-sidecar
  labels:
    app: webapp
    pattern: sidecar
spec:
  containers:
  # Main application container
  - name: webapp
    image: sidecar-webapp:v1
    ports:
    - containerPort: 5000
    volumeMounts:
    - name: log-volume
      mountPath: /var/log/app
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
        
  # Sidecar container for log processing
  - name: log-processor
    image: fluent/fluent-bit:2.0
    volumeMounts:
    - name: log-volume
      mountPath: /var/log/app
      readOnly: true
    - name: fluent-config
      mountPath: /fluent-bit/etc/fluent-bit.conf
      subPath: fluent-bit.conf
    - name: processed-logs
      mountPath: /var/log/processed
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "128Mi"
        cpu: "100m"
        
  volumes:
  - name: log-volume
    emptyDir: {}
  - name: processed-logs
    emptyDir: {}
  - name: fluent-config
    configMap:
      name: fluent-config
EOF

# 6. Crear ConfigMap para Fluent Bit
kubectl create configmap fluent-config --from-file=fluent-bit.conf

# 7. Desplegar Pod
kubectl apply -f sidecar-pod.yaml
kubectl wait --for=condition=Ready pod/webapp-sidecar --timeout=120s

# 8. Generar tráfico para crear logs
kubectl port-forward pod/webapp-sidecar 8080:5000 &
sleep 3

echo ""
echo "🚦 Generando tráfico para demostrar sidecar..."
curl -s http://localhost:8080/ | jq
curl -s http://localhost:8080/api/users | jq  
curl -s http://localhost:8080/health | jq
curl -s http://localhost:8080/
curl -s http://localhost:8080/api/users

sleep 5

# 9. Verificar logs originales
echo ""
echo "📝 LOGS ORIGINALES (webapp container):"
kubectl exec webapp-sidecar -c webapp -- cat /var/log/app/access.log

# 10. Verificar logs procesados por sidecar
echo ""
echo "⚙️ LOGS PROCESADOS (sidecar container):"
kubectl exec webapp-sidecar -c log-processor -- cat /var/log/processed/processed.log

# 11. Ver logs de contenedores
echo ""
echo "📊 CONTAINER LOGS:"
echo "--- WebApp Container ---"
kubectl logs webapp-sidecar -c webapp --tail=5

echo ""
echo "--- Log Processor Container ---"
kubectl logs webapp-sidecar -c log-processor --tail=10

# 12. Análisis de recursos
echo ""
echo "💾 RESOURCE USAGE:"
kubectl top pod webapp-sidecar --containers

# Stop port-forward
kill %1 2>/dev/null

echo ""
echo "✅ SIDECAR PATTERN BENEFITS DEMONSTRATED:"
echo "├─ 🔄 Separación de responsabilidades"
echo "├─ 🌐 Comunicación via shared volume"
echo "├─ 📊 Procesamiento en tiempo real"
echo "├─ 🔍 Logs estructurados y enriquecidos"
echo "└─ ⚖️ Resource isolation entre funciones"

# Cleanup
kubectl delete pod webapp-sidecar
kubectl delete configmap fluent-config
```

### **🚀 Lab 4: Init Container Migration Pattern**

**Objetivo**: Migrar setup complejo de Docker a Init Containers.

```bash
mkdir -p ~/labs/modulo-04/init-migration && cd ~/labs/modulo-04/init-migration

echo "🚀 INIT CONTAINER: Migration from Docker Setup"
echo "=============================================="

# 1. Simular setup Docker complejo (ANTES)
echo ""
echo "🐳 SETUP DOCKER TRADICIONAL (Complejo):"
echo "├─ Múltiples contenedores para setup"
echo "├─ Orquestación manual de dependencias"
echo "└─ Scripts complejos de inicialización"

cat > docker-setup.sh << 'EOF'
#!/bin/bash
echo "🐳 Docker Traditional Setup (Complex)"

# 1. Create network
docker network create app-setup

# 2. Database setup
docker run -d --name db --network app-setup \
  -e POSTGRES_DB=myapp \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=pass \
  postgres:13

# 3. Wait for DB (manual orchestration)
echo "⏳ Waiting for database..."
sleep 10

# 4. Run migrations (separate container)
docker run --rm --network app-setup \
  -e DATABASE_URL=postgres://user:pass@db:5432/myapp \
  migrate/migrate:v4.15.1 \
  -path /migrations -database postgres://user:pass@db:5432/myapp up

# 5. Seed data (another container)
docker run --rm --network app-setup \
  -e DATABASE_URL=postgres://user:pass@db:5432/myapp \
  my-seed-image:v1

# 6. Download assets (yet another container)  
docker run --rm -v $(pwd)/assets:/output \
  busybox wget -O /output/app.js https://cdn.example.com/app.js

# 7. Finally start main app
docker run -d --name app --network app-setup \
  -v $(pwd)/assets:/app/static \
  -e DATABASE_URL=postgres://user:pass@db:5432/myapp \
  my-app:v1

echo "❌ Problems with this approach:"
echo "├─ Manual orchestration"
echo "├─ Complex dependency management"  
echo "├─ Multiple network/volume setups"
echo "└─ Hard to reproduce consistently"
EOF

chmod +x docker-setup.sh

# 2. Crear aplicación simple que requiere setup
cat > app.py << 'EOF'
from flask import Flask, jsonify
import os
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

def get_db_connection():
    return psycopg2.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        database=os.environ.get('DB_NAME', 'myapp'),
        user=os.environ.get('DB_USER', 'user'),
        password=os.environ.get('DB_PASSWORD', 'pass')
    )

@app.route('/')
def home():
    return jsonify({
        'message': '🚀 App with Init Containers',
        'status': 'running',
        'setup_complete': os.path.exists('/app/setup/complete')
    })

@app.route('/data')
def data():
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT * FROM users LIMIT 5')
        users = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify({'users': users})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/config')
def config():
    config_file = '/app/config/app.json'
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            import json
            config = json.load(f)
        return jsonify(config)
    return jsonify({'error': 'Config not found'}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# 3. Crear scripts de inicialización
mkdir -p setup-scripts

cat > setup-scripts/migrate.sql << 'EOF'
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES 
('Alice Johnson', 'alice@example.com'),
('Bob Smith', 'bob@example.com'),
('Charlie Brown', 'charlie@example.com')
ON CONFLICT (email) DO NOTHING;
EOF

cat > setup-scripts/download-config.sh << 'EOF'
#!/bin/sh
echo "📥 Downloading configuration..."
mkdir -p /app/config

# Simulate downloading config
cat > /app/config/app.json << 'CONFIG'
{
  "app_name": "My Application",
  "version": "1.0.0",
  "features": {
    "logging": true,
    "metrics": true,
    "debug": false
  },
  "database": {
    "pool_size": 10,
    "timeout": 30
  }
}
CONFIG

echo "✅ Configuration downloaded successfully"
echo "complete" > /app/setup/complete
EOF

chmod +x setup-scripts/download-config.sh

# 4. Crear Kubernetes solution con Init Containers
cat > init-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: app-with-init
  labels:
    app: myapp
    pattern: init-containers
spec:
  # Init containers run sequentially BEFORE main containers
  initContainers:
  
  # Init 1: Wait for database to be ready
  - name: wait-for-db
    image: postgres:13
    command: ['sh', '-c']
    args:
      - |
        echo "⏳ Waiting for database to be ready..."
        until pg_isready -h db-service -p 5432 -U user; do
          echo "Database not ready, waiting..."
          sleep 2
        done
        echo "✅ Database is ready!"
    env:
    - name: PGPASSWORD
      value: "pass"
      
  # Init 2: Run database migrations
  - name: db-migration
    image: postgres:13
    command: ['sh', '-c']
    args:
      - |
        echo "🗄️ Running database migrations..."
        psql -h db-service -U user -d myapp -f /migrations/migrate.sql
        echo "✅ Migrations completed!"
    env:
    - name: PGPASSWORD
      value: "pass"
    volumeMounts:
    - name: migration-scripts
      mountPath: /migrations
      
  # Init 3: Download configuration
  - name: config-setup
    image: busybox
    command: ['/setup/download-config.sh']
    volumeMounts:
    - name: setup-scripts
      mountPath: /setup
    - name: app-config
      mountPath: /app/config
    - name: setup-status
      mountPath: /app/setup
      
  # Main application container (starts AFTER all init containers complete)
  containers:
  - name: app
    image: python:3.9-slim
    command: ['sh', '-c']
    args:
      - |
        pip install flask psycopg2-binary
        python /app/app.py
    ports:
    - containerPort: 5000
    env:
    - name: DB_HOST
      value: "db-service"
    - name: DB_NAME
      value: "myapp"
    - name: DB_USER
      value: "user"
    - name: DB_PASSWORD
      value: "pass"
    volumeMounts:
    - name: app-code
      mountPath: /app
    - name: app-config
      mountPath: /app/config
    - name: setup-status
      mountPath: /app/setup
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "500m"
        
  volumes:
  - name: app-code
    configMap:
      name: app-code
  - name: migration-scripts
    configMap:
      name: migration-scripts
  - name: setup-scripts
    configMap:
      name: setup-scripts
      defaultMode: 0755
  - name: app-config
    emptyDir: {}
  - name: setup-status
    emptyDir: {}
EOF

# 5. Crear ConfigMaps necesarios
kubectl create configmap app-code --from-file=app.py
kubectl create configmap migration-scripts --from-file=setup-scripts/migrate.sql
kubectl create configmap setup-scripts --from-file=setup-scripts/download-config.sh

# 6. Crear base de datos (simulada con PostgreSQL simple)
cat > postgres-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: db
  labels:
    app: database
spec:
  containers:
  - name: postgres
    image: postgres:13
    ports:
    - containerPort: 5432
    env:
    - name: POSTGRES_DB
      value: myapp
    - name: POSTGRES_USER
      value: user
    - name: POSTGRES_PASSWORD
      value: pass

---
apiVersion: v1
kind: Service
metadata:
  name: db-service
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
EOF

# 7. Desplegar database primero
kubectl apply -f postgres-pod.yaml
kubectl wait --for=condition=Ready pod/db --timeout=60s

# 8. Desplegar aplicación con init containers
kubectl apply -f init-pod.yaml

# 9. Observar la secuencia de inicialización
echo ""
echo "👀 OBSERVANDO SECUENCIA DE INIT CONTAINERS:"
echo "├─ Watching pod initialization..."

# Mostrar progreso de init containers
kubectl get pods app-with-init -w &
WATCH_PID=$!
sleep 20
kill $WATCH_PID 2>/dev/null

# 10. Verificar logs de init containers
echo ""
echo "📋 LOGS DE INIT CONTAINERS:"

echo "--- Wait for DB ---"
kubectl logs app-with-init -c wait-for-db

echo ""
echo "--- DB Migration ---"
kubectl logs app-with-init -c db-migration

echo ""
echo "--- Config Setup ---"
kubectl logs app-with-init -c config-setup

# 11. Verificar aplicación principal
echo ""
echo "--- Main Application ---"
kubectl logs app-with-init -c app

# 12. Probar la aplicación
kubectl wait --for=condition=Ready pod/app-with-init --timeout=120s
kubectl port-forward pod/app-with-init 8080:5000 &
sleep 3

echo ""
echo "🧪 TESTING APPLICATION:"
curl -s http://localhost:8080/ | jq
curl -s http://localhost:8080/data | jq
curl -s http://localhost:8080/config | jq

kill %1 2>/dev/null

echo ""
echo "✅ INIT CONTAINER BENEFITS:"
echo "├─ 🔄 Sequential execution guaranteed"
echo "├─ 🛠️ Setup separation from main app"
echo "├─ 🎯 Single Pod = atomic deployment"
echo "├─ 📋 Declarative dependency management"
echo "├─ 🔁 Automatic retry on failure"
echo "└─ 🧹 Clean resource management"

echo ""
echo "🆚 COMPARISON: Docker vs Init Containers"
echo "├─ Docker: Manual orchestration, complex scripts"
echo "└─ K8s: Declarative, automatic, reliable"

# Cleanup
kubectl delete pod app-with-init db
kubectl delete service db-service
kubectl delete configmap app-code migration-scripts setup-scripts
```

---

## 🎓 7. Evaluación y Ejercicios
    - containerPort: 8080
    volumeMounts:
    - name: shared-data
      mountPath: /app/data
  
  # Data processor (tightly coupled)
  - name: data-processor
    image: my-processor:v1.0
    volumeMounts:
    - name: shared-data
      mountPath: /processor/input
    # Estos dos contenedores:
    # - Comparten archivos constantemente
    # - Deben escalarse juntos
    # - Tienen el mismo lifecycle
  
  volumes:
  - name: shared-data
    emptyDir: {}
```

---

## 🔄 6. Ciclo de Vida de Pods

### **📊 Pod Lifecycle:**

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Pending   │───►│   Running   │───►│ Succeeded/  │
│             │    │             │    │   Failed    │
└─────────────┘    └─────────────┘    └─────────────┘
       │                                       │
       └─────────────────┬─────────────────────┘
                         ▼
                  ┌─────────────┐
                  │   Unknown   │
                  └─────────────┘
```

### **🔍 Estados Detallados:**

```yaml
# kubectl describe pod my-pod
Status:           Running
Phase:            Running
Conditions:
  Type              Status
  Initialized       True
  Ready             True  
  ContainersReady   True
  PodScheduled      True

Init Containers:
  init-migration:
    State:          Terminated
    Reason:         Completed
    Exit Code:      0

Containers:
  web-app:
    State:          Running
    Started:        2023-11-02T10:00:00Z
    Ready:          True
    Restart Count:  0
  
  sidecar:
    State:          Running
    Started:        2023-11-02T10:00:05Z
    Ready:          True
    Restart Count:  1
```

### **⚡ Container Restart Policies:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restart-policy-demo
spec:
  restartPolicy: Always  # Always, OnFailure, Never
  containers:
  - name: app
    image: my-app:v1.0
    # Si el container falla:
    # Always: Restart siempre
    # OnFailure: Restart solo si exit code != 0
    # Never: Nunca restart
```

---

## 🧪 7. Ejemplos Prácticos Disponibles

### **� [Ver Todos los Ejemplos](./ejemplos/README.md)**

Todos los ejemplos YAML están disponibles en la carpeta `ejemplos/` organizados por concepto:

### **🚀 Ejemplos Disponibles:**

1. **[01-evolucion/](./ejemplos/01-evolucion/)** - Evolución LXC → Docker → Kubernetes
   - `evolution-pod.yaml` - Demo de networking compartido

2. **[02-namespaces/](./ejemplos/02-namespaces/)** - Exploración de namespace sharing
   - `namespace-pod.yaml` - Análisis de Network, PID, IPC, UTS namespaces

3. **[03-multi-container/](./ejemplos/03-multi-container/)** - Patrones multi-contenedor
   - `sidecar-pod.yaml` - Aplicación web + Log processor sidecar

4. **[04-init-containers/](./ejemplos/04-init-containers/)** - Init containers
   - `postgres-pod.yaml` - Database para la demo
   - `init-pod.yaml` - App con 3 init containers (wait-db, migrations, config)

5. **[05-migracion-compose/](./ejemplos/05-migracion-compose/)** - Migración Docker Compose
   - `docker-compose.yml` - Configuración original
   - `web-deployment.yaml` - Frontend Nginx
   - `api-deployment.yaml` - Backend Node.js
   - `db-deployment.yaml` - Database PostgreSQL

### **🎯 Inicio Rápido:**

```bash
# 1. Explorar la evolución LXC → Docker → K8s
kubectl apply -f ejemplos/01-evolucion/evolution-pod.yaml
kubectl exec evolution-demo -c web -- wget -qO- http://localhost:8080

# 2. Analizar namespace sharing
kubectl apply -f ejemplos/02-namespaces/namespace-pod.yaml
kubectl exec namespace-demo -c container1 -- ip addr
kubectl exec namespace-demo -c container2 -- ps aux

# 3. Probar patrón sidecar
kubectl apply -f ejemplos/03-multi-container/sidecar-pod.yaml
kubectl logs webapp-sidecar -c log-processor -f

# 4. Ver init containers en acción
kubectl apply -f ejemplos/04-init-containers/postgres-pod.yaml
kubectl apply -f ejemplos/04-init-containers/init-pod.yaml
kubectl get pods app-with-init --watch

# 5. Migrar de Docker Compose
kubectl apply -f ejemplos/05-migracion-compose/
kubectl get all
```

### **📖 Documentación de Ejemplos:**

Consulta **[ejemplos/README.md](./ejemplos/README.md)** para:
- Descripción detallada de cada ejemplo
- Comandos de uso y testing
- Conceptos que demuestra cada ejemplo
- Instrucciones de limpieza


```bash
# Aplicar y probar
kubectl apply -f multi-container-pod.yaml
kubectl get pods
kubectl logs web-with-sidecar -c nginx
kubectl logs web-with-sidecar -c log-reader -f
kubectl exec -it web-with-sidecar -c nginx -- bash
```

---

## 🚨 8. Antipatrones y Mejores Prácticas

### **❌ Antipatrones Comunes:**

#### **1. "Fat Pods" - Demasiados contenedores**
```yaml
# ❌ MALO: Pod con demasiada responsabilidad
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: web
    image: nginx
  - name: api
    image: node-app
  - name: worker
    image: python-worker  
  - name: scheduler
    image: cron-scheduler
  - name: monitoring
    image: prometheus-exporter
  # ↑ Demasiados contenedores no relacionados
```

```yaml
# ✅ BUENO: Separar responsabilidades
# web-pod.yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: nginx
    image: nginx
  - name: log-processor  # Related sidecar only
    image: fluentd

# api-pod.yaml  
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: api
    image: node-app
  - name: metrics-exporter  # Related sidecar only
    image: prometheus-exporter
```

#### **2. "Singleton Services" - Un Pod para todo**
```yaml
# ❌ MALO: Una réplica para todo
apiVersion: v1
kind: Pod
metadata:
  name: monolith-pod  # Single point of failure
spec:
  containers:
  - name: everything
    image: my-monolith
```

```yaml
# ✅ BUENO: Usar Deployments para réplicas
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 3  # High availability
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
        image: nginx
```

#### **3. "Shared Volumes Abuse" - Volúmenes para comunicación**
```yaml
# ❌ MALO: Usar shared volume para API communication
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: producer
    image: data-producer
    volumeMounts:
    - name: shared-data
      mountPath: /data
    # ↑ Writes files to communicate
  
  - name: consumer
    image: data-consumer
    volumeMounts:
    - name: shared-data
      mountPath: /data
    # ↑ Reads files to get data
```

```yaml
# ✅ BUENO: Usar HTTP/gRPC para comunicación
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: producer
    image: data-producer
    ports:
    - containerPort: 8080
  
  - name: consumer
    image: data-consumer
    env:
    - name: PRODUCER_URL
      value: "http://localhost:8080"
    # ↑ HTTP communication via localhost
```

### **✅ Mejores Prácticas:**

1. **Un Pod = Una responsabilidad principal**
2. **Sidecar solo si es esencial** para la función principal
3. **Init containers para setup** que debe completarse antes
4. **Shared volumes solo para datos compartidos** reales
5. **Use Deployments**, no Pods directos en producción

---

## 🔧 9. Debugging y Troubleshooting

### **🔍 Comandos Esenciales:**

```bash
# Información general del Pod
kubectl get pods
kubectl get pods -o wide
kubectl describe pod my-pod

# Logs de contenedores
kubectl logs my-pod                    # Single container
kubectl logs my-pod -c container-name  # Multi-container
kubectl logs my-pod --previous         # Previous instance
kubectl logs my-pod -f                 # Follow logs

# Ejecutar comandos en contenedores
kubectl exec -it my-pod -- bash                    # Single container
kubectl exec -it my-pod -c container-name -- bash  # Multi-container

# Debug de networking
kubectl exec -it my-pod -- wget -qO- localhost:8080
kubectl exec -it my-pod -- netstat -tlnp
kubectl exec -it my-pod -- ps aux

# Información de recursos
kubectl top pod my-pod
kubectl get events --field-selector involvedObject.name=my-pod
```

### **🚨 Problemas Comunes:**

| Síntoma | Causa Probable | Solución |
|---------|----------------|----------|
| Pod "Pending" | Resources insuficientes | `kubectl describe pod` → Check events |
| Pod "CrashLoopBackOff" | App falla al iniciar | `kubectl logs pod --previous` |
| Pod "ImagePullBackOff" | Imagen no existe | Check image name/registry |
| Container "OOMKilled" | Out of memory | Increase memory limits |
| Pod "Evicted" | Node pressure | Check node resources |

---

## ✅ Resumen del Módulo

### **🎯 Conceptos Clave Aprendidos:**

1. **Pod = Unidad mínima** en Kubernetes (no contenedor individual)
2. **Shared resources** entre contenedores del mismo Pod
3. **Patrones de diseño** (Sidecar, Init, Ambassador)
4. **Migración estratégica** de Docker Compose
5. **Mejores prácticas** para diseño de Pods

### **🔄 Diferencias Fundamentales:**

| Docker Compose | Kubernetes Pods |
|----------------|-----------------|
| Service-oriented | Pod-oriented |
| File-based networking | IP-based networking |
| Manual scaling | Declarative scaling |
| Single-host | Multi-host capable |
| External orchestration | Built-in orchestration |

### **💡 Key Takeaways:**

- **No uses Pods directamente** en producción → Usa Deployments
- **Multi-container Pods** solo cuando estén fuertemente acoplados
- **Sidecar pattern** es poderoso para cross-cutting concerns
- **Init containers** son perfectos para setup tasks
- **Shared networking** simplifica comunicación localhost

---

## ⏭️ Siguiente Paso

**¡Ahora que entiendes Pods, vamos a gestionarlos como un pro!**

🎯 **Próximo módulo**: **[M05: Gestión Avanzada de Pods](../modulo-05-gestion-pods/README.md)**

Donde aprenderás:
- Pod specs avanzadas
- Resource management
- Health checks y probes
- Pod lifecycle hooks
- Debugging avanzado

---

## 🏠 Navegación

- **[⬅️ M03: Instalación Minikube](../modulo-03-instalacion-minikube/README.md)**
- **[🏠 Área 2: Índice Principal](../README-NUEVO.md)**
- **[➡️ M05: Gestión de Pods](../modulo-05-gestion-pods/README.md)**