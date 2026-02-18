# 🔄 Lab 5: Migración de Docker Compose a Kubernetes

## 📋 Información del Laboratorio

- **Duración estimada**: 50 minutos
- **Nivel**: Intermedio
- **Prerrequisitos**:
  - Docker Compose instalado
  - kubectl configurado
  - Cluster Kubernetes activo (minikube/kind)
  - Conocimientos de docker-compose.yml

## 🎯 Objetivo

Migrar una **aplicación multi-container** de Docker Compose a Kubernetes, transformando:
- `docker-compose.yml` → Deployments + Services
- Networking Docker → Networking Kubernetes
- Volumes Docker → PersistentVolumeClaims

### Arquitectura de la Aplicación

```
┌─────────────────────────────────────────────────────┐
│                Docker Compose Stack                 │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────┐      ┌─────────┐      ┌──────────┐   │
│  │   Web   │─────►│   API   │─────►│    DB    │   │
│  │  Nginx  │      │  Node.js│      │PostgreSQL│   │
│  │ :8080   │      │  :3000  │      │  :5432   │   │
│  └─────────┘      └─────────┘      └──────────┘   │
│                                                     │
│  Network: app-network (bridge)                      │
│  Volume: db-data                                    │
└─────────────────────────────────────────────────────┘
```

## 🧪 Práctica

### Paso 1: Preparación del Entorno

```bash
mkdir -p ~/labs/modulo-04/compose-migration && cd ~/labs/modulo-04/compose-migration

echo "🔄 Docker Compose → Kubernetes Migration"
echo "========================================="
```

### Paso 2: Probar Aplicación Original en Docker Compose

```bash
# Copiar docker-compose.yml de los ejemplos
cp ~/K8S/area-2-arquitectura-kubernetes/modulo-04-pods-vs-contenedores/ejemplos/05-migracion-compose/docker-compose.yml .

echo "🐳 PASO 1: Probar Docker Compose (Original)"
echo ""

# Levantar stack
docker-compose up -d

# Verificar servicios
docker-compose ps

# Probar conectividad
echo "Testing Web (Nginx):"
curl -s http://localhost:8080 || echo "Nginx OK"

echo ""
echo "Testing API (Node.js):"
curl -s http://localhost:3000 || echo "API running"

# Ver logs
docker-compose logs --tail=5

# Detener stack
docker-compose down
```

**🔍 Características de Docker Compose**:
- **Networking automático**: `app-network` conecta todos los servicios
- **Service discovery**: API puede usar `db` como hostname
- **Volumes**: `db-data` persiste datos de PostgreSQL

### Paso 3: Analizar Componentes a Migrar

```bash
echo ""
echo "📋 COMPONENTES A MIGRAR:"
echo "├─ 3 Services: web, api, db"
echo "├─ 1 Network: app-network → Kubernetes Service"
echo "├─ 1 Volume: db-data → PersistentVolumeClaim"
echo "└─ Environment variables → ConfigMaps/Secrets"
```

### Paso 4: Migrar Base de Datos (PostgreSQL)

```bash
cat > db-deployment.yaml << 'EOF'
# Migración de Docker Compose a Kubernetes - Database
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
data:
  POSTGRES_DB: myapp
  POSTGRES_USER: user

---
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  POSTGRES_PASSWORD: pass

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
  labels:
    app: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:alpine
        ports:
        - containerPort: 5432
        envFrom:
        - configMapRef:
            name: postgres-config
        - secretRef:
            name: postgres-secret
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: db
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
EOF

echo "📦 Deploying PostgreSQL..."
kubectl apply -f db-deployment.yaml
kubectl wait --for=condition=Available deployment/db --timeout=60s
```

**🔍 Cambios Docker Compose → Kubernetes**:
- `volumes: db-data` → `PersistentVolumeClaim`
- `environment` → `ConfigMap` + `Secret`
- `image: postgres:alpine` → `Deployment` + `Service`

### Paso 5: Migrar API Backend (Node.js)

```bash
cat > api-deployment.yaml << 'EOF'
# Migración de Docker Compose a Kubernetes - API Backend
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
data:
  DB_HOST: db
  DB_PORT: "5432"
  DB_NAME: myapp

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: node:alpine
        command: ["sh", "-c", "sleep infinity"]  # Simulación
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: api-config
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"

---
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api
  ports:
  - port: 3000
    targetPort: 3000
EOF

echo "🔧 Deploying API Backend..."
kubectl apply -f api-deployment.yaml
kubectl wait --for=condition=Available deployment/api --timeout=60s
```

**🔍 Cambios Docker Compose → Kubernetes**:
- `depends_on: db` → No necesario (Services manejan DNS)
- `networks: app-network` → Kubernetes networking automático
- `replicas: 2` → Escalabilidad built-in

### Paso 6: Migrar Frontend Web (Nginx)

```bash
cat > web-deployment.yaml << 'EOF'
# Migración de Docker Compose a Kubernetes - Web Frontend
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    events {}
    http {
      upstream api_backend {
        server api:3000;
      }
      
      server {
        listen 80;
        
        location / {
          root /usr/share/nginx/html;
          index index.html;
        }
        
        location /api/ {
          proxy_pass http://api_backend/;
        }
      }
    }

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  labels:
    app: web
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
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config

---
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF

echo "🌐 Deploying Web Frontend..."
kubectl apply -f web-deployment.yaml
kubectl wait --for=condition=Available deployment/web --timeout=60s
```

**🔍 Cambios Docker Compose → Kubernetes**:
- `ports: "8080:80"` → `NodePort: 30080`
- `depends_on: api` → Service discovery via DNS
- Custom nginx.conf → ConfigMap

### Paso 7: Verificar Migración Completa

```bash
echo ""
echo "✅ VERIFICACIÓN DE MIGRACIÓN"
echo "=============================="

# Ver todos los recursos
kubectl get all

# Ver Pods
echo ""
echo "Pods:"
kubectl get pods

# Ver Services
echo ""
echo "Services:"
kubectl get svc

# Ver PVC
echo ""
echo "Persistent Volume Claims:"
kubectl get pvc

# Ver ConfigMaps
echo ""
echo "ConfigMaps:"
kubectl get configmap
```

### Paso 8: Probar Aplicación en Kubernetes

```bash
echo ""
echo "🧪 TESTING APPLICATION IN KUBERNETES"

# Obtener URL de Minikube (si usas minikube)
if command -v minikube &> /dev/null; then
  echo "Web URL (Minikube):"
  minikube service web --url
fi

# Port forward como alternativa
kubectl port-forward service/web 8080:80 &
sleep 3

echo ""
echo "Testing Web Service:"
curl -s http://localhost:8080 | head -n 10

echo ""
echo "Testing API via Web proxy:"
curl -s http://localhost:8080/api/ | head -n 10

# Stop port-forward
kill %1 2>/dev/null
```

### Paso 9: Verificar Networking

```bash
echo ""
echo "🌐 VERIFICAR KUBERNETES NETWORKING"

# Desde un Pod, probar DNS interno
kubectl run test-pod --image=busybox --restart=Never --rm -it -- sh -c "
  echo 'Testing DNS resolution:'
  nslookup db
  nslookup api
  nslookup web
"
```

**🔍 Observaciones**:
- Todos los servicios son accesibles por nombre
- Kubernetes DNS automáticamente resuelve `db`, `api`, `web`
- No se requiere configuración de red manual

### Paso 10: Comparar Recursos

```bash
echo ""
echo "📊 COMPARACIÓN DOCKER COMPOSE vs KUBERNETES"
echo ""

cat << 'TABLE'
┌───────────────────┬────────────────────┬──────────────────────┐
│   Componente      │  Docker Compose    │  Kubernetes          │
├───────────────────┼────────────────────┼──────────────────────┤
│  Services         │  3 services        │  3 Deployments       │
│  Networking       │  app-network       │  ClusterIP Services  │
│  Service Discovery│  DNS interno       │  kube-dns            │
│  Volumes          │  db-data           │  PersistentVolumeClaim│
│  Scaling          │  ❌ Manual         │  ✅ replicas: 2      │
│  Load Balancing   │  ❌ No             │  ✅ Service          │
│  Health Checks    │  ❌ No             │  ✅ Readiness/Liveness│
│  Config           │  environment vars  │  ConfigMaps/Secrets  │
└───────────────────┴────────────────────┴──────────────────────┘
TABLE
```

## 📊 Diagrama de Migración

### Docker Compose (ANTES)

```
docker-compose.yml (1 file)
├─ service: web
├─ service: api
├─ service: db
├─ network: app-network
└─ volume: db-data
```

### Kubernetes (DESPUÉS)

```
db-deployment.yaml
├─ PersistentVolumeClaim: postgres-pvc
├─ ConfigMap: postgres-config
├─ Secret: postgres-secret
├─ Deployment: db (1 replica)
└─ Service: db (ClusterIP)

api-deployment.yaml
├─ ConfigMap: api-config
├─ Deployment: api (2 replicas) ← Escalado
└─ Service: api (ClusterIP)

web-deployment.yaml
├─ ConfigMap: nginx-config
├─ Deployment: web (2 replicas) ← Escalado
└─ Service: web (NodePort)
```

## ✅ Mejoras Obtenidas con Kubernetes

```
✅ KUBERNETES BENEFITS:
├─ 📈 Escalabilidad: web y api con 2 réplicas
├─ 🔄 Load Balancing: Automático via Services
├─ 🛡️ Self-healing: Pods reinician automáticamente
├─ 🔧 ConfigMaps/Secrets: Gestión centralizada de config
├─ 📊 Resource Limits: CPU y memoria controlados
├─ 🌐 Multi-host: Puede desplegarse en cluster
└─ 🔍 Observability: Logs, métricas, health checks
```

## 🧹 Limpieza

```bash
# Kubernetes cleanup
kubectl delete -f web-deployment.yaml
kubectl delete -f api-deployment.yaml
kubectl delete -f db-deployment.yaml

# Verificar eliminación
kubectl get all
kubectl get pvc
kubectl get configmap

# Docker Compose cleanup (si se ejecutó)
cd ~/labs/modulo-04/compose-migration
docker-compose down -v

# Limpiar archivos locales
rm -rf ~/labs/modulo-04/compose-migration
```

## 🎓 Conceptos Clave Aprendidos

1. **Docker Compose → Deployments**: Services se convierten en Deployments
2. **Networking**: Docker bridge → Kubernetes Services + DNS
3. **Volumes**: Named volumes → PersistentVolumeClaims
4. **Configuration**: Environment variables → ConfigMaps/Secrets
5. **Scaling**: Docker no escala → Kubernetes `replicas`
6. **Service Discovery**: Ambos usan DNS, pero K8s más robusto

## 🚀 Mejoras Adicionales Posibles

### 1. Agregar Ingress (en vez de NodePort)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
spec:
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
```

### 2. Agregar Health Checks

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 5

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 3
```

### 3. Usar Helm Chart

```bash
# Crear Helm chart para gestionar todo junto
helm create myapp
# Editar templates con los YAMLs creados
helm install myapp ./myapp
```

## 📚 Referencias

- [Kubernetes vs Docker Compose](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/)
- [Migrating from Docker Compose](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)
- [Kompose - Automatic Conversion Tool](https://kompose.io/)

## ⏭️ Siguiente Paso

¡Has completado todos los laboratorios! Ahora estás listo para:
- **[Volver al README Principal](../README.md)** para revisar conceptos
- **[Explorar Ejemplos Adicionales](../ejemplos/README.md)** para más patrones
- **[Módulo 05: Gestión Avanzada de Pods](../../modulo-05-gestion-pods/README.md)** para profundizar

---

## 🎉 ¡Felicitaciones!

Has migrado exitosamente una aplicación multi-container de Docker Compose a Kubernetes, aprendiendo:
- ✅ Conversión de Services → Deployments
- ✅ Networking Docker → Kubernetes
- ✅ Volumes → PersistentVolumeClaims
- ✅ Environment vars → ConfigMaps/Secrets
- ✅ Escalabilidad y alta disponibilidad
