# Laboratorios Prácticos - Ejercicios Hands-on

## Lab 1: Configuración inicial de AKS

### Objetivo
Crear un cluster AKS desde cero con configuraciones de producción.

### Prerequisitos
- Azure CLI instalado y configurado
- kubectl instalado
- Subscription de Azure activa

### Pasos del laboratorio

#### 1. Crear Resource Group
```bash
# Variables de configuración
RESOURCE_GROUP="rg-aks-lab"
LOCATION="East US"
CLUSTER_NAME="aks-lab-cluster"

# Crear resource group
az group create --name $RESOURCE_GROUP --location "$LOCATION"
```

#### 2. Crear AKS Cluster
```bash
# Crear cluster AKS con configuraciones de producción
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 3 \
  --node-vm-size Standard_DS2_v2 \
  --enable-addons monitoring \
  --enable-managed-identity \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5 \
  --kubernetes-version 1.28.0 \
  --network-plugin azure \
  --network-policy azure \
  --generate-ssh-keys

# Obtener credenciales
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

#### 3. Verificar instalación
```bash
# Verificar nodos
kubectl get nodes

# Verificar namespaces del sistema
kubectl get namespaces

# Verificar pods del sistema
kubectl get pods -n kube-system
```

### Tareas adicionales
1. Configurar un node pool adicional para workloads específicos
2. Habilitar Azure Container Registry (ACR)
3. Configurar network policies básicas

---

## Lab 2: Despliegue de aplicación multi-tier

### Objetivo
Desplegar una aplicación completa con frontend, backend y base de datos.

### Estructura de la aplicación
- Frontend: React/Nginx
- Backend: Node.js API
- Base de datos: PostgreSQL
- Cache: Redis

### Paso 1: Crear namespaces
```bash
kubectl create namespace frontend
kubectl create namespace backend
kubectl create namespace database
```

### Paso 2: Desplegar PostgreSQL
```yaml
# postgresql-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:15
        env:
        - name: POSTGRES_DB
          value: "appdb"
        - name: POSTGRES_USER
          value: "appuser"
        - name: POSTGRES_PASSWORD
          value: "secretpassword"
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: postgresql-service
  namespace: database
spec:
  selector:
    app: postgresql
  ports:
  - port: 5432
    targetPort: 5432
```

### Paso 3: Desplegar Redis
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

---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: database
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
```

### Paso 4: Desplegar Backend API
```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
  namespace: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
    spec:
      containers:
      - name: api
        image: node:18-alpine
        command: ["/bin/sh"]
        args: ["-c", "npm start"]
        env:
        - name: NODE_ENV
          value: "production"
        - name: DB_HOST
          value: "postgresql-service.database.svc.cluster.local"
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: "appdb"
        - name: DB_USER
          value: "appuser"
        - name: DB_PASSWORD
          value: "secretpassword"
        - name: REDIS_HOST
          value: "redis-service.database.svc.cluster.local"
        - name: REDIS_PORT
          value: "6379"
        ports:
        - containerPort: 3000
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

---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: backend
spec:
  selector:
    app: backend-api
  ports:
  - port: 80
    targetPort: 3000
```

### Paso 5: Desplegar Frontend
```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
  namespace: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend-app
  template:
    metadata:
      labels:
        app: frontend-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: frontend
data:
  default.conf: |
    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }
        location /api/ {
            proxy_pass http://backend-service.backend.svc.cluster.local/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }

---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: frontend
spec:
  type: LoadBalancer
  selector:
    app: frontend-app
  ports:
  - port: 80
    targetPort: 80
```

### Comandos de despliegue
```bash
# Aplicar todos los manifiestos
kubectl apply -f postgresql-deployment.yaml
kubectl apply -f redis-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml

# Verificar despliegues
kubectl get all -n database
kubectl get all -n backend
kubectl get all -n frontend

# Obtener IP externa del LoadBalancer
kubectl get service frontend-service -n frontend
```

### Ejercicios adicionales
1. Configurar HPA para el backend
2. Implementar network policies entre namespaces
3. Agregar TLS/SSL con cert-manager
4. Configurar Prometheus monitoring

---

## Lab 3: Implementación de CI/CD con Azure DevOps

### Objetivo
Crear un pipeline completo de CI/CD que construya, pruebe y despliegue automáticamente.

### Estructura del proyecto
```
myapp/
├── src/
├── Dockerfile
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── azure-pipelines.yml
└── package.json
```

### Dockerfile de ejemplo
```dockerfile
# Multi-stage build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY src/ ./src/
COPY package*.json ./

USER node
EXPOSE 3000
CMD ["npm", "start"]
```

### Azure Pipeline YAML
```yaml
# azure-pipelines.yml
trigger:
- main

variables:
  dockerRegistryServiceConnection: 'myacr-connection'
  imageRepository: 'myapp'
  containerRegistry: 'myregistry.azurecr.io'
  dockerfilePath: '$(Build.SourcesDirectory)/Dockerfile'
  tag: '$(Build.BuildId)'
  k8sNamespace: 'production'
  
stages:
- stage: Build
  displayName: Build and Push
  jobs:
  - job: Build
    displayName: Build job
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: Docker@2
      displayName: Build and push image
      inputs:
        command: buildAndPush
        repository: $(imageRepository)
        dockerfile: $(dockerfilePath)
        containerRegistry: $(dockerRegistryServiceConnection)
        tags: |
          $(tag)
          latest

- stage: Test
  displayName: Test stage
  dependsOn: Build
  jobs:
  - job: Test
    displayName: Test job
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: NodeTool@0
      inputs:
        versionSpec: '18.x'
    - script: |
        npm install
        npm run test
        npm run lint
      displayName: 'Run tests'

- stage: Deploy
  displayName: Deploy to AKS
  dependsOn: Test
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: Deploy
    displayName: Deploy job
    pool:
      vmImage: 'ubuntu-latest'
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: Deploy to Kubernetes cluster
            inputs:
              action: deploy
              kubernetesServiceConnection: 'aks-connection'
              namespace: $(k8sNamespace)
              manifests: |
                k8s/deployment.yaml
                k8s/service.yaml
                k8s/ingress.yaml
              containers: '$(containerRegistry)/$(imageRepository):$(tag)'
```

### Manifiestos Kubernetes
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
```

### Ejercicios del laboratorio
1. Configurar Azure Container Registry
2. Crear service connections en Azure DevOps
3. Ejecutar el pipeline y verificar despliegue
4. Implementar blue-green deployment
5. Agregar tests de integración

---

## Lab 4: Monitoring y Observabilidad

### Objetivo
Implementar monitoreo completo con Prometheus, Grafana y alerting.

### Paso 1: Instalar Prometheus Operator
```bash
# Agregar Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set grafana.adminPassword=admin123
```

### Paso 2: Configurar ServiceMonitor para aplicación
```yaml
# app-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp-metrics
  namespace: monitoring
  labels:
    app: myapp
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
  namespaceSelector:
    matchNames:
    - production
```

### Paso 3: Configurar alertas personalizadas
```yaml
# app-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: myapp-alerts
  namespace: monitoring
  labels:
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
  - name: myapp.rules
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ $value }} for {{ $labels.instance }}"
    
    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes{pod=~"myapp-.*"} / container_spec_memory_limit_bytes > 0.8
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage"
        description: "Memory usage is {{ $value | humanizePercentage }} for {{ $labels.pod }}"
    
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Pod is crash looping"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is restarting"
```

### Paso 4: Dashboard de Grafana personalizado
```json
{
  "dashboard": {
    "title": "MyApp Dashboard",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (instance)",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (instance)",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "95th percentile"
          }
        ]
      }
    ]
  }
}
```

### Comandos útiles para monitoring
```bash
# Acceder a Prometheus UI
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Acceder a Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Ver alertas activas
kubectl get prometheusrules -n monitoring

# Ver métricas en tiempo real
kubectl top nodes
kubectl top pods -n production
```

### Ejercicios adicionales
1. Configurar Slack notifications para alertas
2. Crear dashboard para métricas de negocio
3. Implementar distributed tracing con Jaeger
4. Configurar log aggregation con ELK stack

---

## Lab 5: Seguridad y RBAC

### Objetivo
Implementar un modelo de seguridad robusto con RBAC, Network Policies y Pod Security Standards.

### Paso 1: Configurar RBAC granular
```yaml
# rbac-config.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-app

---
# ServiceAccount para desarrolladores
apiVersion: v1
kind: ServiceAccount
metadata:
  name: developer-sa
  namespace: secure-app

---
# Role para desarrolladores (solo lectura)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: secure-app
  name: developer-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]

---
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: secure-app
subjects:
- kind: ServiceAccount
  name: developer-sa
  namespace: secure-app
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io

---
# ServiceAccount para CI/CD
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cicd-sa
  namespace: secure-app

---
# Role para CI/CD (permisos de escritura)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: secure-app
  name: cicd-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cicd-binding
  namespace: secure-app
subjects:
- kind: ServiceAccount
  name: cicd-sa
  namespace: secure-app
roleRef:
  kind: Role
  name: cicd-role
  apiGroup: rbac.authorization.k8s.io
```

### Paso 2: Network Policies restrictivas
```yaml
# network-policies.yaml
# Denegar todo el tráfico por defecto
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: secure-app
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# Permitir DNS
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: secure-app
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53

---
# Permitir comunicación entre frontend y backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: secure-app
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080

---
# Permitir acceso desde ingress controller
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-frontend
  namespace: secure-app
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80
```

### Paso 3: Pod Security Standards
```yaml
# secure-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: secure-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure-app
      tier: frontend
  template:
    metadata:
      labels:
        app: secure-app
        tier: frontend
    spec:
      serviceAccountName: developer-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 3000
        fsGroup: 2000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: app
        image: nginx:alpine
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        volumeMounts:
        - name: tmp-volume
          mountPath: /tmp
        - name: var-cache-nginx
          mountPath: /var/cache/nginx
        - name: var-run
          mountPath: /var/run
      volumes:
      - name: tmp-volume
        emptyDir: {}
      - name: var-cache-nginx
        emptyDir: {}
      - name: var-run
        emptyDir: {}
```

### Paso 4: Secrets seguros con Azure Key Vault
```yaml
# keyvault-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: secure-app
type: Opaque
stringData:
  database-url: "postgres://user:pass@host:5432/db"
  api-key: "secret-api-key"

---
# Pod con montaje seguro de secrets
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: secure-app
spec:
  serviceAccountName: developer-sa
  containers:
  - name: app
    image: alpine:latest
    command: ["/bin/sh"]
    args: ["-c", "while true; do sleep 30; done"]
    env:
    - name: DB_URL
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: database-url
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secrets
      defaultMode: 0400
```

### Comandos de testing de seguridad
```bash
# Aplicar configuraciones
kubectl apply -f rbac-config.yaml
kubectl apply -f network-policies.yaml
kubectl apply -f secure-deployment.yaml

# Testear RBAC
kubectl auth can-i get pods --as=system:serviceaccount:secure-app:developer-sa -n secure-app
kubectl auth can-i create deployments --as=system:serviceaccount:secure-app:developer-sa -n secure-app

# Testear Network Policies
kubectl run test-pod --image=busybox --rm -i --tty -- /bin/sh
# Dentro del pod: nc -z <service-ip> <port>

# Escanear vulnerabilidades
kubectl run -i --tty --rm debug --image=aquasec/trivy:latest --restart=Never -- image nginx:alpine

# Verificar Pod Security Standards
kubectl get pods -n secure-app -o jsonpath='{.items[*].spec.securityContext}'
```

### Ejercicios adicionales
1. Integrar con Azure Active Directory
2. Implementar admission controllers
3. Configurar image scanning en CI/CD
4. Implementar mTLS entre servicios
5. Configurar audit logging

---

## Lab 6: Disaster Recovery y Backup

### Objetivo
Implementar estrategias de backup, restore y disaster recovery.

### Paso 1: Instalar Velero para backups
```bash
# Instalar Velero CLI
wget https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
tar -xvf velero-v1.12.0-linux-amd64.tar.gz
sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/

# Crear storage account para backups
AZURE_BACKUP_RESOURCE_GROUP="MC_${RESOURCE_GROUP}_${CLUSTER_NAME}_${LOCATION}"
AZURE_STORAGE_ACCOUNT_ID="velero$(uuidgen | cut -d '-' -f5 | tr '[A-Z]' '[a-z]')"

az storage account create \
    --name $AZURE_STORAGE_ACCOUNT_ID \
    --resource-group $AZURE_BACKUP_RESOURCE_GROUP \
    --sku Standard_GRS \
    --encryption-services blob \
    --https-only true \
    --kind BlobStorage \
    --access-tier Hot

# Instalar Velero en el cluster
velero install \
    --provider azure \
    --plugins velero/velero-plugin-for-microsoft-azure:v1.8.0 \
    --bucket velero \
    --secret-file ./credentials-velero \
    --backup-location-config resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP,storageAccount=$AZURE_STORAGE_ACCOUNT_ID \
    --snapshot-location-config apiTimeout=5m,resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP
```

### Paso 2: Configurar backups programados
```yaml
# backup-schedule.yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-backup
  namespace: velero
spec:
  schedule: "0 2 * * *"  # Diariamente a las 2 AM
  template:
    includedNamespaces:
    - production
    - database
    - monitoring
    excludedResources:
    - events
    - logs
    ttl: 720h  # 30 días
    storageLocation: default
    
---
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: weekly-full-backup
  namespace: velero
spec:
  schedule: "0 1 * * 0"  # Domingos a la 1 AM
  template:
    includedNamespaces:
    - "*"
    ttl: 2160h  # 90 días
    storageLocation: default
```

### Paso 3: Backup de base de datos con hooks
```yaml
# database-backup-with-hooks.yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgresql-backup
  namespace: database
  annotations:
    pre.hook.backup.velero.io/command: '["/bin/bash", "-c", "pg_dump -U $POSTGRES_USER -h localhost $POSTGRES_DB > /backup/db_backup.sql"]'
    pre.hook.backup.velero.io/timeout: 10m
    post.hook.backup.velero.io/command: '["/bin/bash", "-c", "rm -f /backup/db_backup.sql"]'
spec:
  containers:
  - name: postgresql
    image: postgres:15
    env:
    - name: POSTGRES_DB
      value: "myapp"
    - name: POSTGRES_USER
      value: "postgres"
    - name: POSTGRES_PASSWORD
      value: "password"
    volumeMounts:
    - name: backup-volume
      mountPath: /backup
    - name: data-volume
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: backup-volume
    emptyDir: {}
  - name: data-volume
    persistentVolumeClaim:
      claimName: postgresql-pvc
```

### Paso 4: Scripts de restore
```bash
#!/bin/bash
# restore-cluster.sh

# Variables
BACKUP_NAME=$1
NAMESPACE=$2

if [ -z "$BACKUP_NAME" ] || [ -z "$NAMESPACE" ]; then
    echo "Usage: $0 <backup-name> <namespace>"
    exit 1
fi

echo "Iniciando restore del backup: $BACKUP_NAME para namespace: $NAMESPACE"

# Crear restore
velero restore create \
    --from-backup $BACKUP_NAME \
    --include-namespaces $NAMESPACE \
    --wait

# Verificar estado del restore
velero restore describe $(velero restore get | grep $BACKUP_NAME | awk '{print $1}')

# Verificar pods
kubectl get pods -n $NAMESPACE

echo "Restore completado. Verificar la aplicación manualmente."
```

### Comandos útiles de Velero
```bash
# Crear backup manual
velero backup create manual-backup --include-namespaces production

# Listar backups
velero backup get

# Describir backup
velero backup describe <backup-name>

# Crear restore
velero restore create --from-backup <backup-name>

# Monitorear restore
velero restore get

# Ver logs de backup/restore
velero backup logs <backup-name>
velero restore logs <restore-name>

# Verificar ubicación de backup
velero backup-location get
```

### Ejercicios del laboratorio
1. Realizar backup completo del cluster
2. Simular fallo y ejecutar restore
3. Configurar backup incremental
4. Implementar cross-region backup
5. Crear runbook de disaster recovery

---

## Troubleshooting Guide

### Problemas comunes y soluciones

#### Pod no inicia
```bash
# Verificar eventos
kubectl describe pod <pod-name> -n <namespace>

# Ver logs
kubectl logs <pod-name> -n <namespace> --previous

# Verificar recursos
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Verificar límites de recursos
kubectl top pod <pod-name> -n <namespace>
```

#### Problemas de red
```bash
# Testear conectividad DNS
kubectl run -i --tty --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Testear conectividad entre pods
kubectl exec -it <pod-name> -- nc -zv <service-name> <port>

# Verificar network policies
kubectl get networkpolicy -n <namespace>

# Debug de service
kubectl get endpoints <service-name> -n <namespace>
```

#### Problemas de persistencia
```bash
# Verificar PVC
kubectl get pvc -n <namespace>

# Describir PVC
kubectl describe pvc <pvc-name> -n <namespace>

# Verificar storage class
kubectl get storageclass

# Ver eventos de volúmenes
kubectl get events --field-selector involvedObject.kind=PersistentVolumeClaim -n <namespace>
```

### Scripts útiles para debugging
```bash
#!/bin/bash
# debug-pod.sh
POD_NAME=$1
NAMESPACE=$2

echo "=== Pod Status ==="
kubectl get pod $POD_NAME -n $NAMESPACE -o wide

echo "=== Pod Description ==="
kubectl describe pod $POD_NAME -n $NAMESPACE

echo "=== Pod Logs ==="
kubectl logs $POD_NAME -n $NAMESPACE --tail=50

echo "=== Resource Usage ==="
kubectl top pod $POD_NAME -n $NAMESPACE

echo "=== Recent Events ==="
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
```

Estos laboratorios prácticos cubren los aspectos más importantes del curso de Kubernetes y AKS, proporcionando experiencia hands-on con:

1. **Configuración de infraestructura**: Creación y configuración de clusters AKS
2. **Despliegue de aplicaciones**: Aplicaciones multi-tier con mejores prácticas
3. **CI/CD**: Pipelines automatizados con Azure DevOps
4. **Monitoreo**: Observabilidad completa con Prometheus y Grafana
5. **Seguridad**: RBAC, Network Policies y Pod Security Standards
6. **Disaster Recovery**: Backup y restore con Velero

Cada laboratorio incluye ejercicios progresivos que van desde configuraciones básicas hasta implementaciones de producción completas.