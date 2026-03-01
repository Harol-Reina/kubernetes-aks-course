# Capítulo 30: RBAC y Control de Acceso

El cluster AKS está configurado y operativo. Ahora aseguramos el acceso: RBAC (Role-Based Access Control) define quién puede hacer qué sobre qué recursos. En entornos multi-equipo, esto es indispensable.

---

## Conceptos de RBAC

**Role-Based Access Control (RBAC)** permite definir quién puede realizar qué acciones en qué recursos.

### Componentes de RBAC

```
User/Group/ServiceAccount → RoleBinding → Role → Resources
                         ↘ ClusterRoleBinding → ClusterRole → Cluster Resources
```

**Elementos principales:**
- **Subject**: Usuario, grupo o service account
- **Role/ClusterRole**: Conjunto de permisos
- **RoleBinding/ClusterRoleBinding**: Vincula subjects con roles

## Roles y ClusterRoles

### Role (Namespace-scoped)

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

### ClusterRole (Cluster-scoped)

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

## RoleBindings y ClusterRoleBindings

### RoleBinding

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

### ClusterRoleBinding

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

## Service Accounts

### Crear Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: desarrollo
```

### Usar Service Account en Pod

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

## Laboratorio 3.1: Configurar RBAC

### Paso 1: Crear Usuarios de Prueba

```bash
# Crear namespace para pruebas
kubectl create namespace rbac-test

# Crear service accounts
kubectl create serviceaccount developer -n rbac-test
kubectl create serviceaccount viewer -n rbac-test
```

### Paso 2: Crear Roles

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

### Paso 3: Crear RoleBindings

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

### Paso 4: Probar Permisos

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

## Resumen del Capítulo

RBAC es el mecanismo central de autorización en Kubernetes. Aprendimos a crear Roles y ClusterRoles que definen permisos, vincularlos a usuarios y ServiceAccounts mediante Bindings, y verificar permisos con `kubectl auth can-i`. El principio de menor privilegio guía todas las decisiones: otorgar solo los permisos estrictamente necesarios.
