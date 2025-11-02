# Proyecto Final - Aplicación de 3 Capas en AKS

**Objetivo**: Consolidar todos los conocimientos adquiridos en el curso mediante la implementación de una aplicación completa de 3 capas con todas las mejores prácticas.

## 🎯 Descripción del Proyecto

Implementarás **"ECommerce Cloud"**, una aplicación de comercio electrónico que demuestra:

- **Arquitectura de microservicios** con 3 capas
- **Gestión completa de infraestructura** en Azure
- **Seguridad de extremo a extremo**
- **Observabilidad y monitoreo**
- **Alta disponibilidad y escalabilidad**
- **CI/CD automatizado**

### Arquitectura de la Aplicación

```
┌─────────────────────────────────────────────────────────────┐
│                     INTERNET                                │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                AZURE LOAD BALANCER                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│               INGRESS CONTROLLER                            │
│                (Azure App Gateway)                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼────┐     ┌─────▼─────┐     ┌─────▼─────┐
│FRONTEND│     │    API    │     │  ADMIN    │
│  (SPA) │     │ GATEWAY   │     │   PANEL   │
│ React  │     │  Node.js  │     │  Vue.js   │
└───┬────┘     └─────┬─────┘     └─────┬─────┘
    │                │                 │
    └─────────────────┼─────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼────┐     ┌─────▼─────┐     ┌─────▼─────┐
│PRODUCT │     │  USER     │     │  ORDER    │
│SERVICE │     │ SERVICE   │     │ SERVICE   │
│Node.js │     │  Python   │     │   Java    │
└───┬────┘     └─────┬─────┘     └─────┬─────┘
    │                │                 │
    └─────────────────┼─────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                   DATABASE LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  POSTGRES   │  │    REDIS    │  │  MONGODB    │         │
│  │ (Products)  │  │   (Cache)   │  │  (Logs)     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Requisitos del Proyecto

### Funcionales

1. **Frontend (Capa de Presentación)**
   - SPA React para usuarios finales
   - Panel administrativo Vue.js
   - Responsive design
   - Autenticación OAuth2

2. **Backend (Capa de Lógica de Negocio)**
   - API Gateway para enrutamiento
   - Microservicio de productos
   - Microservicio de usuarios
   - Microservicio de pedidos

3. **Base de Datos (Capa de Datos)**
   - PostgreSQL para datos transaccionales
   - Redis para caché y sesiones
   - MongoDB para logs y análisis

### No Funcionales

1. **Seguridad**
   - HTTPS end-to-end
   - RBAC granular
   - Network Policies
   - Secrets management con Azure Key Vault

2. **Alta Disponibilidad**
   - Minimum 99.9% uptime
   - Multi-replica deployments
   - Autoscaling horizontal y vertical
   - Health checks y circuit breakers

3. **Observabilidad**
   - Logging centralizado
   - Métricas en tiempo real
   - Alertas proactivas
   - Distributed tracing

4. **DevOps**
   - GitOps workflow
   - CI/CD automated pipelines
   - Infrastructure as Code
   - Blue-green deployments

---

## 🚀 Implementación Paso a Paso

### Fase 1: Infraestructura Base (2 horas)

#### Paso 1: Configurar Ambiente Azure

```bash
# Variables de configuración
RESOURCE_GROUP="rg-ecommerce-final"
LOCATION="eastus"
AKS_NAME="aks-ecommerce"
ACR_NAME="acrecommerce$RANDOM"
KEYVAULT_NAME="kv-ecommerce-$RANDOM"

# Crear grupo de recursos
az group create --name $RESOURCE_GROUP --location $LOCATION

# Crear Azure Container Registry
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Premium \
  --admin-enabled true

# Crear Azure Key Vault
az keyvault create \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --enable-soft-delete \
  --retention-days 7

# Crear AKS cluster con todas las características
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --node-count 3 \
  --node-vm-size Standard_D2s_v3 \
  --enable-addons monitoring,azure-keyvault-secrets-provider \
  --enable-managed-identity \
  --attach-acr $ACR_NAME \
  --network-plugin azure \
  --network-policy azure \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 10 \
  --generate-ssh-keys

# Obtener credenciales
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME
```

#### Paso 2: Configurar Namespaces y Estructura

```bash
# Crear namespaces
kubectl create namespace frontend
kubectl create namespace backend
kubectl create namespace database
kubectl create namespace monitoring
kubectl create namespace ingress

# Labels para namespaces
kubectl label namespace frontend tier=frontend env=production
kubectl label namespace backend tier=backend env=production
kubectl label namespace database tier=database env=production

# Crear service accounts
kubectl create serviceaccount app-frontend -n frontend
kubectl create serviceaccount app-backend -n backend
kubectl create serviceaccount app-database -n database
```

### Fase 2: Base de Datos (1.5 horas)

#### Paso 1: PostgreSQL con Alta Disponibilidad

```yaml
# postgresql-deployment.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql
  namespace: database
spec:
  serviceName: postgresql-headless
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      serviceAccountName: app-database
      containers:
      - name: postgresql
        image: postgres:15
        env:
        - name: POSTGRES_DB
          value: ecommerce
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
          name: postgresql
        volumeMounts:
        - name: postgresql-storage
          mountPath: /var/lib/postgresql/data
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U $POSTGRES_USER -d $POSTGRES_DB
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U $POSTGRES_USER -d $POSTGRES_DB
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: postgresql-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: managed-premium
      resources:
        requests:
          storage: 20Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql
  namespace: database
spec:
  selector:
    app: postgresql
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql-headless
  namespace: database
spec:
  clusterIP: None
  selector:
    app: postgresql
  ports:
  - port: 5432
    targetPort: 5432
```

#### Paso 2: Redis para Caché

```yaml
# redis-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        command: ["redis-server"]
        args: ["--requirepass", "$(REDIS_PASSWORD)"]
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-secret
              key: password
        volumeMounts:
        - name: redis-storage
          mountPath: /data
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
      volumes:
      - name: redis-storage
        persistentVolumeClaim:
          claimName: redis-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: database
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc
  namespace: database
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: managed-premium
```

#### Paso 3: Secrets de Base de Datos

```bash
# Crear secrets para las bases de datos
kubectl create secret generic postgresql-secret \
  --from-literal=username=ecommerce_user \
  --from-literal=password=SuperSecure123! \
  --namespace=database

kubectl create secret generic redis-secret \
  --from-literal=password=RedisSecret456! \
  --namespace=database

# Aplicar configuraciones de BD
kubectl apply -f postgresql-deployment.yaml
kubectl apply -f redis-deployment.yaml
```

### Fase 3: Microservicios Backend (2 horas)

#### Paso 1: API Gateway

```yaml
# api-gateway-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      serviceAccountName: app-backend
      containers:
      - name: api-gateway
        image: acrecommerce.azurecr.io/api-gateway:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        - name: PRODUCT_SERVICE_URL
          value: "http://product-service.backend.svc.cluster.local:3001"
        - name: USER_SERVICE_URL
          value: "http://user-service.backend.svc.cluster.local:3002"
        - name: ORDER_SERVICE_URL
          value: "http://order-service.backend.svc.cluster.local:3003"
        - name: REDIS_HOST
          value: "redis.database.svc.cluster.local"
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-secret
              key: password
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: backend
spec:
  selector:
    app: api-gateway
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
```

#### Paso 2: Product Service

```yaml
# product-service-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
    spec:
      serviceAccountName: app-backend
      containers:
      - name: product-service
        image: acrecommerce.azurecr.io/product-service:latest
        ports:
        - containerPort: 3001
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3001"
        - name: DB_HOST
          value: "postgresql.database.svc.cluster.local"
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: "ecommerce"
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: password
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3001
          initialDelaySeconds: 10
          periodSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: backend
spec:
  selector:
    app: product-service
  ports:
  - port: 3001
    targetPort: 3001
  type: ClusterIP
```

#### Paso 3: Configurar HPA para Microservicios

```yaml
# hpa-backend.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-gateway-hpa
  namespace: backend
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-gateway
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: product-service-hpa
  namespace: backend
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: product-service
  minReplicas: 2
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Fase 4: Frontend y Ingress (1.5 horas)

#### Paso 1: React Frontend

```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: frontend
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
      serviceAccountName: app-frontend
      containers:
      - name: frontend
        image: acrecommerce.azurecr.io/frontend:latest
        ports:
        - containerPort: 80
        env:
        - name: REACT_APP_API_URL
          value: "/api"
        - name: REACT_APP_ENV
          value: "production"
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
  name: frontend
  namespace: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

#### Paso 2: Configurar Ingress con TLS

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  namespace: frontend
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - ecommerce.example.com
    secretName: ecommerce-tls
  rules:
  - host: ecommerce.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 80
        # Proxy to backend namespace
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

### Fase 5: Seguridad y Network Policies (1 hora)

#### Paso 1: RBAC Configuration

```yaml
# rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: frontend
  name: frontend-role
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: frontend-rolebinding
  namespace: frontend
subjects:
- kind: ServiceAccount
  name: app-frontend
  namespace: frontend
roleRef:
  kind: Role
  name: frontend-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: backend
  name: backend-role
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: backend-rolebinding
  namespace: backend
subjects:
- kind: ServiceAccount
  name: app-backend
  namespace: backend
roleRef:
  kind: Role
  name: backend-role
  apiGroup: rbac.authorization.k8s.io
```

#### Paso 2: Network Policies

```yaml
# network-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-netpol
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 80
  # Allow DNS
  - to: []
    ports:
    - protocol: UDP
      port: 53
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-netpol
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: frontend
    - namespaceSelector:
        matchLabels:
          name: ingress
    ports:
    - protocol: TCP
      port: 3000
    - protocol: TCP
      port: 3001
    - protocol: TCP
      port: 3002
    - protocol: TCP
      port: 3003
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
    - protocol: TCP
      port: 6379
  # Allow DNS
  - to: []
    ports:
    - protocol: UDP
      port: 53
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-netpol
  namespace: database
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
    - protocol: TCP
      port: 6379
```

### Fase 6: Observabilidad (1 hora)

#### Paso 1: Prometheus y Grafana

```bash
# Instalar Prometheus Stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=15d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes=["ReadWriteOnce"] \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set grafana.adminPassword=EcommerceAdmin123! \
  --set grafana.service.type=LoadBalancer \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.accessModes=["ReadWriteOnce"] \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=10Gi
```

#### Paso 2: ServiceMonitors Personalizados

```yaml
# servicemonitors.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ecommerce-backend
  namespace: backend
  labels:
    app: ecommerce-backend
spec:
  selector:
    matchLabels:
      app: api-gateway
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ecommerce-frontend
  namespace: frontend
  labels:
    app: ecommerce-frontend
spec:
  selector:
    matchLabels:
      app: frontend
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

### Fase 7: CI/CD Pipeline (1 hora)

#### Paso 1: Azure DevOps Pipeline

```yaml
# azure-pipelines.yml
trigger:
- main

variables:
  dockerRegistryServiceConnection: 'acrConnection'
  containerRegistry: 'acrecommerce.azurecr.io'
  kubernetesServiceConnection: 'aksConnection'
  tag: '$(Build.BuildId)'

stages:
- stage: Build
  displayName: Build and Test
  jobs:
  - job: BuildFrontend
    displayName: Build Frontend
    steps:
    - task: NodeTool@0
      inputs:
        versionSpec: '18.x'
    - script: |
        cd frontend
        npm ci
        npm run test
        npm run build
      displayName: 'Build and Test Frontend'
    - task: Docker@2
      displayName: Build and push Frontend image
      inputs:
        command: buildAndPush
        repository: frontend
        dockerfile: frontend/Dockerfile
        containerRegistry: $(dockerRegistryServiceConnection)
        tags: |
          $(tag)
          latest

  - job: BuildBackend
    displayName: Build Backend Services
    strategy:
      matrix:
        apiGateway:
          serviceName: 'api-gateway'
        productService:
          serviceName: 'product-service'
        userService:
          serviceName: 'user-service'
        orderService:
          serviceName: 'order-service'
    steps:
    - task: Docker@2
      displayName: Build and push $(serviceName) image
      inputs:
        command: buildAndPush
        repository: $(serviceName)
        dockerfile: backend/$(serviceName)/Dockerfile
        containerRegistry: $(dockerRegistryServiceConnection)
        tags: |
          $(tag)
          latest

- stage: Deploy
  displayName: Deploy to AKS
  dependsOn: Build
  jobs:
  - deployment: DeployToAKS
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: HelmDeploy@0
            displayName: Deploy with Helm
            inputs:
              connectionType: 'Kubernetes Service Connection'
              kubernetesServiceConnection: $(kubernetesServiceConnection)
              command: 'upgrade'
              chartType: 'FilePath'
              chartPath: 'helm/ecommerce'
              releaseName: 'ecommerce'
              overrideValues: |
                image.tag=$(tag)
                image.repository=$(containerRegistry)
```

---

## 🧪 Testing y Validación

### Pruebas de Funcionalidad

```bash
# Verificar todos los pods están running
kubectl get pods --all-namespaces

# Verificar servicios
kubectl get services --all-namespaces

# Probar conectividad frontend
curl -k https://ecommerce.example.com

# Probar API
curl -k https://ecommerce.example.com/api/health

# Verificar base de datos
kubectl exec -it postgresql-0 -n database -- psql -U ecommerce_user -d ecommerce -c "SELECT version();"
```

### Pruebas de Rendimiento

```bash
# Load testing con artillery
npm install -g artillery

# Crear script de carga
cat > load-test.yml << 'EOF'
config:
  target: 'https://ecommerce.example.com'
  phases:
    - duration: 60
      arrivalRate: 10
scenarios:
  - name: "Browse products"
    requests:
      - get:
          url: "/"
      - get:
          url: "/api/products"
EOF

# Ejecutar pruebas de carga
artillery run load-test.yml
```

### Validación de Seguridad

```bash
# Verificar Network Policies
kubectl get networkpolicies --all-namespaces

# Verificar RBAC
kubectl auth can-i create pods --as=system:serviceaccount:frontend:app-frontend -n frontend

# Verificar certificados TLS
kubectl get certificate -n frontend

# Scan de vulnerabilidades con Trivy
trivy image acrecommerce.azurecr.io/frontend:latest
```

---

## 📊 Métricas y KPIs del Proyecto

### Métricas Técnicas

1. **Disponibilidad**: > 99.9%
2. **Latencia P95**: < 500ms
3. **Throughput**: > 1000 req/min
4. **MTTR**: < 5 minutos
5. **Error Rate**: < 0.1%

### Métricas de Negocio

1. **Time to Market**: Despliegue en < 10 minutos
2. **Escalabilidad**: 0-1000 usuarios concurrentes
3. **Costo**: Optimización de recursos Azure
4. **Seguridad**: Zero vulnerabilidades críticas

---

## 📝 Entregables

### Documentación Técnica

1. **README.md** completo del proyecto
2. **Diagrama de arquitectura** detallado
3. **Guía de despliegue** paso a paso
4. **Manual de operaciones** y troubleshooting
5. **Documentación de APIs**

### Código y Configuración

1. **Código fuente** de todos los microservicios
2. **Dockerfiles** optimizados
3. **Manifiestos YAML** de Kubernetes
4. **Helm charts** para despliegue
5. **Scripts de automatización**

### Evidencias

1. **Screenshots** de todas las interfaces
2. **Logs** de despliegue exitoso
3. **Métricas** de Grafana dashboards
4. **Reportes** de pruebas de carga
5. **Certificados** de seguridad

---

## 🏆 Criterios de Evaluación

### Funcionalidad (25%)
- ✅ Aplicación completamente funcional
- ✅ Todas las capas comunicándose correctamente
- ✅ Frontend responsive y usable
- ✅ APIs RESTful bien diseñadas

### Infraestructura (25%)
- ✅ AKS configurado según mejores prácticas
- ✅ Alta disponibilidad implementada
- ✅ Autoescalado funcionando
- ✅ Almacenamiento persistente configurado

### Seguridad (20%)
- ✅ HTTPS end-to-end
- ✅ RBAC implementado
- ✅ Network Policies aplicadas
- ✅ Secrets management con Key Vault

### Observabilidad (15%)
- ✅ Logging centralizado
- ✅ Métricas completas
- ✅ Alertas configuradas
- ✅ Dashboards informativos

### DevOps (15%)
- ✅ CI/CD pipeline funcional
- ✅ GitOps workflow
- ✅ Infrastructure as Code
- ✅ Automatización completa

---

## 🎓 Consejos para el Éxito

### Planificación
1. **Divide y vencerás**: Implementa una fase a la vez
2. **Prueba continuamente**: Valida cada componente antes de continuar
3. **Documenta todo**: Cada decisión y configuración
4. **Versiona todo**: Git para código, tags para imágenes

### Mejores Prácticas
1. **12-Factor App**: Sigue estos principios
2. **Observability First**: Implementa métricas desde el inicio
3. **Security by Design**: No dejes seguridad para el final
4. **Fail Fast**: Implementa health checks robustos

### Troubleshooting
1. **Logs son tu amigo**: kubectl logs es tu mejor herramienta
2. **Describe everything**: kubectl describe para entender problemas
3. **Check resources**: CPU/memoria pueden ser limitantes
4. **Network debugging**: Usa herramientas de red para conectividad

---

## 🚀 Extensiones Opcionales

### Para Puntos Extra

1. **Service Mesh** con Istio
2. **Advanced Monitoring** con Jaeger tracing
3. **Chaos Engineering** con Chaos Monkey
4. **Multi-region deployment**
5. **Blue-Green deployments**
6. **Canary releases**
7. **Policy enforcement** con OPA Gatekeeper

---

¡Felicidades por llegar hasta aquí! Este proyecto final te permitirá demostrar todo lo aprendido y simular un entorno de producción real. **¡Éxito en tu implementación!** 🎉