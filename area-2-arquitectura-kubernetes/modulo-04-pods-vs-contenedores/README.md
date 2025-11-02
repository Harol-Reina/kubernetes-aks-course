# 🐳 Módulo 04: Pods vs Contenedores Docker

**Duración**: 45 minutos  
**Modalidad**: Teórico-Práctico  
**Dificultad**: Intermedio

## 🎯 Objetivos del Módulo

Al completar este módulo serás capaz de:

- ✅ **Explicar las diferencias fundamentales** entre Pods y contenedores Docker
- ✅ **Entender el concepto de Pod** como unidad mínima en Kubernetes
- ✅ **Diseñar arquitecturas multi-contenedor** en un Pod
- ✅ **Identificar cuándo usar** un Pod vs múltiples Pods
- ✅ **Migrar de Docker Compose** a Kubernetes Pods

---

## 🔄 1. Evolución: Docker → Kubernetes

### **🐳 Recapitulación Docker (Área 1):**

```bash
# Docker - Gestión individual de contenedores
docker run -d --name web nginx:1.20
docker run -d --name api node:16-alpine
docker run -d --name db postgres:13
docker network create app-network
docker run --network app-network ...
```

### **☸️ Kubernetes - Gestión de Pods:**

```yaml
# Kubernetes - Pods como unidad mínima
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.20
  - name: sidecar
    image: busybox
```

---

## 🧩 2. ¿Qué es un Pod?

### **📖 Definición:**

> **Pod = Grupo de uno o más contenedores que comparten recursos y se programan juntos**

### **🎯 Conceptos Clave:**

```
┌─────────────────────────────────────────┐
│                 POD                     │
│  ┌─────────────┐  ┌─────────────────┐  │
│  │ Container 1 │  │   Container 2   │  │
│  │   (main)    │  │   (sidecar)     │  │
│  └─────────────┘  └─────────────────┘  │
│                                         │
│  Shared:                                │
│  ├─ 🌐 Network (IP Address)            │
│  ├─ 💾 Storage (Volumes)               │
│  ├─ 🏷️ Labels & Annotations           │
│  └─ 🔄 Lifecycle                       │
└─────────────────────────────────────────┘
```

### **🔑 Principios Fundamentales:**

1. **Unidad atómica**: No puedes programar contenedores individualmente
2. **Shared fate**: Todos los contenedores viven y mueren juntos
3. **Shared resources**: Network, storage, y context compartido
4. **Single IP**: Un Pod = Una dirección IP
5. **Colocation**: Contenedores siempre en el mismo nodo

---

## 🆚 3. Docker vs Pods: Comparación Detallada

### **📊 Tabla Comparativa:**

| Aspecto | Docker Container | Kubernetes Pod |
|---------|------------------|----------------|
| **Unidad mínima** | Contenedor individual | Pod (1+ contenedores) |
| **Networking** | Bridge/Host/Custom | Shared IP entre contenedores |
| **Storage** | Individual volumes | Shared volumes |
| **Scheduling** | Manual (docker run) | Automático (Scheduler) |
| **Lifecycle** | Individual | Conjunto |
| **Resource limits** | Por contenedor | Por Pod (suma contenedores) |
| **Health checks** | Individual | Pod-level + container-level |
| **Scaling** | Manual (docker scale) | Declarativo (replicas) |

### **🌐 Networking Comparison:**

#### **Docker Networking:**
```bash
# Docker - Contenedores separados
docker run -d --name web -p 8080:80 nginx
docker run -d --name api -p 3000:3000 node-app
# ↑ Cada contenedor tiene su propio puerto mapping
```

#### **Pod Networking:**
```yaml
# Kubernetes - Shared network namespace
apiVersion: v1
kind: Pod
metadata:
  name: web-api-pod
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
# ↑ Ambos contenedores comparten la misma IP
```

**Resultado práctico:**
```bash
# Dentro del Pod, los contenedores se comunican vía localhost
curl localhost:80    # → nginx container
curl localhost:3000  # → node-app container
```

---

## 🎨 4. Patrones de Diseño con Pods

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

## 🧪 7. Laboratorio Práctico

### **[🔬 Lab: Pod Fundamentals](./laboratorios/pod-fundamentals-lab.md)**

En este laboratorio vas a:

1. **Crear tu primer Pod** single-container
2. **Implementar un Pod multi-container** con sidecar
3. **Usar init containers** para setup
4. **Migrar una app Docker Compose** a Pods
5. **Explorar el networking** compartido
6. **Debugging** de Pods problemáticos

**Duración**: 45 minutos  
**Dificultad**: Intermedio

### **🎯 Ejemplo Rápido:**

```yaml
# Crear este archivo: multi-container-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-with-sidecar
spec:
  containers:
  - name: nginx
    image: nginx:1.20
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
  
  - name: log-reader
    image: busybox:1.35
    command: ['sh', '-c', 'tail -f /var/log/nginx/access.log']
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
  
  volumes:
  - name: shared-logs
    emptyDir: {}
```

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