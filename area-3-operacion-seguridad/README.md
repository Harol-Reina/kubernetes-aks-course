# Área 3 - Operación, Seguridad y Almacenamiento

**Duración**: 9 horas  
**Modalidad**: Teórico – Práctico

## 🎯 Objetivos de Aprendizaje

Al completar esta área, serás capaz de:

- Administrar clústeres AKS usando Azure Portal y CLI
- Implementar RBAC y control de acceso granular
- Configurar Network Policies para seguridad de red
- Gestionar almacenamiento persistente con Azure Disk y Files
- Integrar con Azure Key Vault para gestión de secretos
- Configurar autenticación con Azure Active Directory
- Realizar backups y snapshots de volúmenes

---

## 📚 Módulo 1: Gestión de Clústeres AKS (2.5 horas)

### Administración a través de Azure Portal

#### Acceso al Portal

1. **Navegación**: Azure Portal → Kubernetes services
2. **Overview**: Estado general del clúster
3. **Node pools**: Gestión de grupos de nodos
4. **Networking**: Configuración de red
5. **Security**: Configuraciones de seguridad
6. **Monitoring**: Métricas y logs

#### Operaciones Básicas en Portal

**Scaling del Clúster:**
```
Portal → AKS → Node pools → Scale
- Manual scaling
- Auto-scaling configuration
- Node pool settings
```

**Upgrade del Clúster:**
```
Portal → AKS → Upgrade
- Kubernetes version
- Rolling upgrade
- Maintenance windows
```

### Administración con Azure CLI

#### Comandos Fundamentales

```bash
# Listar clústeres AKS
az aks list --output table

# Obtener información detallada
az aks show \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course

# Estado del clúster
az aks get-credentials \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course

# Verificar versiones disponibles
az aks get-versions --location eastus --output table
```

#### Scaling y Actualización

```bash
# Escalar node pool
az aks scale \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --node-count 3

# Habilitar autoscaling
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5

# Actualizar versión de Kubernetes
az aks upgrade \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --kubernetes-version 1.28.0
```

#### Node Pools Adicionales

```bash
# Crear node pool adicional
az aks nodepool add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name workerpool \
  --node-count 2 \
  --node-vm-size Standard_D2s_v3 \
  --node-taints dedicated=worker:NoSchedule

# Listar node pools
az aks nodepool list \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --output table

# Eliminar node pool
az aks nodepool delete \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name workerpool
```

### Integración con Azure Container Registry

#### Configuración de ACR

```bash
# Attach ACR al clúster AKS
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --attach-acr acrk8scourse

# Verificar integración
az aks check-acr \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --acr acrk8scourse
```

#### Usar Imágenes desde ACR

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-from-acr
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: acrk8scourse.azurecr.io/mi-app-nodejs:latest
        ports:
        - containerPort: 3000
```

---

## 📚 Módulo 2: RBAC y Control de Acceso (2.5 horas)

### Conceptos de RBAC

**Role-Based Access Control (RBAC)** permite definir quién puede realizar qué acciones en qué recursos.

#### Componentes de RBAC

```
User/Group/ServiceAccount → RoleBinding → Role → Resources
                         ↘ ClusterRoleBinding → ClusterRole → Cluster Resources
```

**Elementos principales:**
- **Subject**: Usuario, grupo o service account
- **Role/ClusterRole**: Conjunto de permisos
- **RoleBinding/ClusterRoleBinding**: Vincula subjects con roles

### Roles y ClusterRoles

#### Role (Namespace-scoped)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: desarrollo
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

#### ClusterRole (Cluster-scoped)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["nodes", "pods"]
  verbs: ["get", "list"]
```

### RoleBindings y ClusterRoleBindings

#### RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: desarrollo
subjects:
- kind: User
  name: juan@empresa.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

#### ClusterRoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-nodes
subjects:
- kind: Group
  name: infrastructure-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

### Service Accounts

#### Crear Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: desarrollo
```

#### Usar Service Account en Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  namespace: desarrollo
spec:
  serviceAccountName: app-service-account
  containers:
  - name: app
    image: nginx:1.21
```

### 🧪 Laboratorio 3.1: Configurar RBAC

#### Paso 1: Crear Usuarios de Prueba

```bash
# Crear namespace para pruebas
kubectl create namespace rbac-test

# Crear service accounts
kubectl create serviceaccount developer -n rbac-test
kubectl create serviceaccount viewer -n rbac-test
```

#### Paso 2: Crear Roles

```bash
# Role para desarrolladores (permisos completos en namespace)
cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: rbac-test
  name: developer-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF

# Role para viewers (solo lectura)
cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: rbac-test
  name: viewer-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
EOF
```

#### Paso 3: Crear RoleBindings

```bash
# RoleBinding para developer
cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: rbac-test
subjects:
- kind: ServiceAccount
  name: developer
  namespace: rbac-test
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
EOF

# RoleBinding para viewer
cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: viewer-binding
  namespace: rbac-test
subjects:
- kind: ServiceAccount
  name: viewer
  namespace: rbac-test
roleRef:
  kind: Role
  name: viewer-role
  apiGroup: rbac.authorization.k8s.io
EOF
```

#### Paso 4: Probar Permisos

```bash
# Crear token para developer
DEVELOPER_TOKEN=$(kubectl create token developer -n rbac-test)

# Crear token para viewer
VIEWER_TOKEN=$(kubectl create token viewer -n rbac-test)

# Probar permisos de developer
kubectl auth can-i create pods --namespace=rbac-test --token=$DEVELOPER_TOKEN
kubectl auth can-i delete pods --namespace=rbac-test --token=$DEVELOPER_TOKEN

# Probar permisos de viewer
kubectl auth can-i create pods --namespace=rbac-test --token=$VIEWER_TOKEN
kubectl auth can-i get pods --namespace=rbac-test --token=$VIEWER_TOKEN

# Probar crear pod como developer
kubectl run test-pod --image=nginx --namespace=rbac-test --token=$DEVELOPER_TOKEN

# Intentar crear pod como viewer (debería fallar)
kubectl run test-pod-2 --image=nginx --namespace=rbac-test --token=$VIEWER_TOKEN
```

---

## 📚 Módulo 3: Network Policies y Seguridad de Red (2 horas)

### Conceptos de Network Policies

Las **Network Policies** son un mecanismo para controlar el tráfico de red entre Pods usando reglas similares a firewalls.

#### Tipos de Políticas

1. **Ingress**: Tráfico entrante al Pod
2. **Egress**: Tráfico saliente del Pod

#### Requisitos

- **CNI Plugin** compatible (ej: Calico, Cilium)
- **Azure CNI** con Network Policies habilitadas

### Anatomía de una Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: example-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: allowed
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

### Ejemplos de Network Policies

#### Denegar Todo el Tráfico

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: secure-namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

#### Permitir Tráfico entre Tiers

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-to-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: web
    ports:
    - protocol: TCP
      port: 8080
```

#### Permitir Tráfico desde Namespace Específico

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-monitoring
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090
```

### Configurar Azure CNI con Network Policies

```bash
# Crear AKS con Azure CNI y Network Policies
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-network-policies \
  --network-plugin azure \
  --network-policy azure \
  --node-count 2
```

### 🧪 Laboratorio 3.2: Implementar Network Policies

#### Paso 1: Preparar Ambiente

```bash
# Crear namespaces
kubectl create namespace frontend
kubectl create namespace backend
kubectl create namespace database

# Label namespaces
kubectl label namespace frontend tier=frontend
kubectl label namespace backend tier=backend
kubectl label namespace database tier=database
```

#### Paso 2: Desplegar Aplicaciones

```bash
# Frontend
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
EOF

# Backend
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
        tier: backend
    spec:
      containers:
      - name: backend
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
EOF

# Database
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
        tier: database
    spec:
      containers:
      - name: database
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: myapp
        - name: POSTGRES_USER
          value: user
        - name: POSTGRES_PASSWORD
          value: password
        ports:
        - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: database-service
  namespace: database
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
EOF
```

#### Paso 3: Probar Conectividad Inicial

```bash
# Probar conectividad frontend → backend
kubectl exec -n frontend deployment/frontend -- curl -s backend-service.backend.svc.cluster.local

# Probar conectividad backend → database
kubectl exec -n backend deployment/backend -- nc -zv database-service.database.svc.cluster.local 5432
```

#### Paso 4: Implementar Network Policies

```bash
# Política: Solo frontend puede acceder a backend
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
EOF

# Política: Solo backend puede acceder a database
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
  namespace: database
spec:
  podSelector:
    matchLabels:
      app: database
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
EOF

# Política: Frontend solo puede salir a backend
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 80
  # Permitir DNS
  - to: []
    ports:
    - protocol: UDP
      port: 53
EOF
```

#### Paso 5: Verificar Políticas

```bash
# Verificar que frontend → backend funciona
kubectl exec -n frontend deployment/frontend -- curl -s backend-service.backend.svc.cluster.local

# Verificar que frontend → database está bloqueado
kubectl exec -n frontend deployment/frontend -- nc -zv database-service.database.svc.cluster.local 5432

# Verificar que backend → database funciona
kubectl exec -n backend deployment/backend -- nc -zv database-service.database.svc.cluster.local 5432
```

---

## 📚 Módulo 4: Almacenamiento Persistente (2 horas)

### Conceptos de Almacenamiento en Kubernetes

#### Tipos de Volúmenes

1. **Ephemeral**: Temporales, se eliminan con el Pod
2. **Persistent**: Sobreviven al ciclo de vida del Pod

#### Componentes Principales

- **PersistentVolume (PV)**: Recurso de almacenamiento en el clúster
- **PersistentVolumeClaim (PVC)**: Solicitud de almacenamiento por un usuario
- **StorageClass**: Define tipos de almacenamiento disponibles

### Azure Storage en AKS

#### Azure Disk

**Características:**
- **ReadWriteOnce**: Solo un Pod puede montar el disco
- **Rendimiento**: Standard HDD, Standard SSD, Premium SSD
- **Snapshots**: Soporte nativo
- **Encryption**: Azure Disk Encryption

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-disk-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: managed-premium
```

#### Azure Files

**Características:**
- **ReadWriteMany**: Múltiples Pods pueden montar el volumen
- **Protocolos**: SMB y NFS
- **Compartido**: Entre múltiples nodos
- **Backup**: Azure Backup integration

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-files-pvc
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: azurefile
```

### StorageClasses en AKS

#### StorageClasses por Defecto

```bash
# Listar StorageClasses
kubectl get storageclass

# Describir StorageClass
kubectl describe storageclass managed-premium
```

**StorageClasses principales:**
- **default**: Standard SSD (ReadWriteOnce)
- **managed-premium**: Premium SSD (ReadWriteOnce)
- **azurefile**: Azure Files (ReadWriteMany)
- **azurefile-premium**: Azure Files Premium

#### StorageClass Personalizada

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS
  cachingmode: ReadOnly
  kind: Managed
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

### 🧪 Laboratorio 3.3: Configurar Almacenamiento Persistente

#### Paso 1: Azure Disk con StatefulSet

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database-statefulset
  namespace: desarrollo
spec:
  serviceName: database-headless
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: myapp
        - name: POSTGRES_USER
          value: appuser
        - name: POSTGRES_PASSWORD
          value: secretpassword
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
          name: postgres
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
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
  name: database-headless
  namespace: desarrollo
spec:
  clusterIP: None
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
EOF

# Verificar StatefulSet y PVC
kubectl get statefulset -n desarrollo
kubectl get pvc -n desarrollo
kubectl get pv
```

#### Paso 2: Azure Files Compartido

```bash
# Crear PVC para Azure Files
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-storage
  namespace: desarrollo
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: azurefile
EOF

# Deployment que usa Azure Files
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: file-share-app
  namespace: desarrollo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: file-share
  template:
    metadata:
      labels:
        app: file-share
    spec:
      containers:
      - name: app
        image: nginx:1.21
        volumeMounts:
        - name: shared-data
          mountPath: /usr/share/nginx/html
        - name: logs
          mountPath: /var/log/nginx
      volumes:
      - name: shared-data
        persistentVolumeClaim:
          claimName: shared-storage
      - name: logs
        persistentVolumeClaim:
          claimName: shared-storage
EOF

# Verificar que múltiples pods comparten el volumen
kubectl get pods -n desarrollo -l app=file-share
kubectl exec -n desarrollo deployment/file-share-app -- ls -la /usr/share/nginx/html
```

#### Paso 3: Probar Persistencia

```bash
# Escribir datos en el StatefulSet
kubectl exec -n desarrollo database-statefulset-0 -- psql -U appuser -d myapp -c "CREATE TABLE test (id SERIAL PRIMARY KEY, data TEXT);"
kubectl exec -n desarrollo database-statefulset-0 -- psql -U appuser -d myapp -c "INSERT INTO test (data) VALUES ('Datos persistentes');"

# Eliminar pod para probar persistencia
kubectl delete pod database-statefulset-0 -n desarrollo

# Esperar a que se recree y verificar datos
kubectl wait --for=condition=ready pod database-statefulset-0 -n desarrollo --timeout=60s
kubectl exec -n desarrollo database-statefulset-0 -- psql -U appuser -d myapp -c "SELECT * FROM test;"
```

#### Paso 4: Snapshots de Volúmenes

```bash
# Crear VolumeSnapshot
cat << 'EOF' | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: postgres-snapshot
  namespace: desarrollo
spec:
  volumeSnapshotClassName: csi-azuredisk-vsc
  source:
    persistentVolumeClaimName: postgres-storage-database-statefulset-0
EOF

# Verificar snapshot
kubectl get volumesnapshot -n desarrollo
kubectl describe volumesnapshot postgres-snapshot -n desarrollo

# Restaurar desde snapshot
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-postgres-pvc
  namespace: desarrollo
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: managed-premium
  dataSource:
    name: postgres-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOF
```

---

## 📚 Módulo 5: Integración con Azure Key Vault (1 hora)

### Azure Key Vault Provider for Secrets Store CSI Driver

Esta integración permite montar secretos, claves y certificados de Azure Key Vault como volúmenes en Pods.

#### Instalación del Provider

```bash
# Agregar repositorio Helm
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts

# Instalar CSI Secrets Store Driver
helm install csi-secrets-store-provider-azure csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system

# Verificar instalación
kubectl get pods -n kube-system -l app=secrets-store-csi-driver
```

#### Configurar Azure Key Vault

```bash
# Crear Key Vault
az keyvault create \
  --name kv-k8s-course \
  --resource-group rg-kubernetes-course \
  --location eastus

# Agregar secretos
az keyvault secret set \
  --vault-name kv-k8s-course \
  --name database-password \
  --value "SuperSecret123!"

az keyvault secret set \
  --vault-name kv-k8s-course \
  --name api-key \
  --value "abcd1234-ef56-7890-abcd-1234567890ab"
```

#### Configurar Identidad Gestionada

```bash
# Crear managed identity
az identity create \
  --resource-group rg-kubernetes-course \
  --name aks-keyvault-identity

# Obtener client ID e identity ID
IDENTITY_CLIENT_ID=$(az identity show --resource-group rg-kubernetes-course --name aks-keyvault-identity --query clientId -o tsv)
IDENTITY_RESOURCE_ID=$(az identity show --resource-group rg-kubernetes-course --name aks-keyvault-identity --query id -o tsv)

# Asignar permisos al Key Vault
az keyvault set-policy \
  --name kv-k8s-course \
  --object-id $(az identity show --resource-group rg-kubernetes-course --name aks-keyvault-identity --query principalId -o tsv) \
  --secret-permissions get list

# Asignar identity al AKS
az aks pod-identity add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --namespace desarrollo \
  --name keyvault-identity \
  --identity-resource-id $IDENTITY_RESOURCE_ID
```

### 🧪 Laboratorio 3.4: Usar Azure Key Vault

#### Paso 1: Crear SecretProviderClass

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secret
  namespace: desarrollo
spec:
  provider: azure
  parameters:
    usePodIdentity: "true"
    keyvaultName: kv-k8s-course
    cloudName: ""
    objects: |
      array:
        - |
          objectName: database-password
          objectType: secret
          objectVersion: ""
        - |
          objectName: api-key
          objectType: secret
          objectVersion: ""
    tenantId: $(az account show --query tenantId -o tsv)
  secretObjects:
  - secretName: app-secrets
    type: Opaque
    data:
    - objectName: database-password
      key: db-password
    - objectName: api-key
      key: api-key
EOF
```

#### Paso 2: Crear Pod que use Key Vault

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: keyvault-app
  namespace: desarrollo
  labels:
    aadpodidbinding: keyvault-identity
spec:
  containers:
  - name: app
    image: nginx:1.21
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: db-password
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: api-key
    volumeMounts:
    - name: secrets-store
      mountPath: "/mnt/secrets"
      readOnly: true
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: azure-keyvault-secret
EOF

# Verificar que el pod puede acceder a los secretos
kubectl exec keyvault-app -n desarrollo -- env | grep -E "(DB_PASSWORD|API_KEY)"
kubectl exec keyvault-app -n desarrollo -- ls -la /mnt/secrets
kubectl exec keyvault-app -n desarrollo -- cat /mnt/secrets/database-password
```

---

## 📝 Resumen del Área 3

### Conceptos Clave Aprendidos

1. **Gestión de Clústeres AKS**
   - Administración via Portal y CLI
   - Scaling y actualización de clústeres
   - Node pools y configuraciones avanzadas

2. **RBAC y Seguridad**
   - Roles, ClusterRoles y bindings
   - Service Accounts
   - Principio de menor privilegio

3. **Network Policies**
   - Aislamiento de tráfico entre Pods
   - Políticas de ingress y egress
   - Seguridad de red por capas

4. **Almacenamiento Persistente**
   - Azure Disk vs Azure Files
   - StatefulSets y PersistentVolumes
   - Snapshots y backup

5. **Integración con Azure Key Vault**
   - Gestión segura de secretos
   - CSI Secrets Store Driver
   - Managed Identity para autenticación

### Habilidades Prácticas Desarrolladas

✅ Administrar clústeres AKS en producción  
✅ Implementar control de acceso granular  
✅ Configurar políticas de red para seguridad  
✅ Gestionar almacenamiento persistente  
✅ Integrar servicios de Azure para seguridad  
✅ Realizar backups y restauración  

### Preparación para el Área 4

En el siguiente módulo abordaremos:
- Observabilidad y monitoreo con Prometheus/Grafana
- Logging centralizado
- Alta disponibilidad y autoescalado
- CI/CD y GitOps
- Troubleshooting avanzado

---

## 🔗 Enlaces Útiles

- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Azure Key Vault Provider](https://azure.github.io/secrets-store-csi-driver-provider-azure/)

## ▶️ Siguiente: [Área 4 - Observabilidad, Alta Disponibilidad e Integración](../area-4-observabilidad-ha/README.md)