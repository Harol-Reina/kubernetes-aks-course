# 📚 Resumen Módulo 18: RBAC - Service Accounts

> **Guía de Estudio Rápida** - Control de acceso para **aplicaciones y pods** usando **tokens JWT automáticos**

---

## 🎯 Conceptos Clave en 5 Minutos

### ¿Qué es un Service Account?
**Service Account (SA)** = Identidad para **aplicaciones y pods** que necesitan interactuar con la API de Kubernetes desde **dentro del cluster**.

### Diferencia Fundamental: Service Accounts vs Usuarios
| Aspecto | Service Accounts (Módulo 18) | Usuarios (Módulo 17) |
|---------|------------------------------|---------------------|
| **Para quién** | 🤖 Aplicaciones (pods, deployments) | 👤 Personas (desarrolladores, admins) |
| **Autenticación** | 🎫 Tokens JWT (automático) | 🔐 Certificados X.509 (manual) |
| **Gestión** | API Kubernetes (kubectl create sa) | OpenSSL + scripts externos |
| **Ubicación** | Interno (dentro del cluster) | Externo (kubectl remoto) |
| **Scope** | Por namespace | Global |

### Componentes Service Account
```
Service Account     →  Identidad con nombre único
        ↓
Token JWT           →  Credential automático (montado en pod)
        ↓
Role/ClusterRole    →  Permisos (qué puede hacer)
        ↓
RoleBinding         →  Conecta SA con Role
        ↓
Pod usa SA          →  Pod tiene permisos del SA
        ↓
ACCESO A API ✅
```

### Token Automático en Pod
```bash
# Cada pod tiene un token montado en:
/var/run/secrets/kubernetes.io/serviceaccount/
├── token       # JWT token para autenticación
├── ca.crt      # Certificado CA del cluster
└── namespace   # Namespace del pod
```

---

## 📋 Práctica 1: Crear Service Account Básico (15 min)

### Método 1: Imperativo (rápido)
```bash
# Crear Service Account
kubectl create serviceaccount monitoring-app -n production

# Verificar creación
kubectl get serviceaccount monitoring-app -n production

# Ver detalles
kubectl describe serviceaccount monitoring-app -n production

# Ver YAML
kubectl get serviceaccount monitoring-app -n production -o yaml
```

### Método 2: Declarativo (recomendado para producción)
```yaml
# serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monitoring-app
  namespace: production
  labels:
    app: monitoring
    environment: production
  annotations:
    description: "SA para aplicación de monitoring"
```

```bash
# Aplicar
kubectl apply -f serviceaccount.yaml

# Verificar
kubectl get sa monitoring-app -n production
```

### ✅ Verificación
```bash
# Listar todos los Service Accounts en un namespace
kubectl get serviceaccounts -n production

# Listar en todos los namespaces
kubectl get serviceaccounts --all-namespaces

# Ver el Service Account por defecto
kubectl get sa default -n production -o yaml
```

---

## 📋 Práctica 2: Asignar Permisos RBAC a Service Account (25 min)

### Paso 1: Crear Role con Permisos
```yaml
# role-pod-reader.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
```

```bash
# Aplicar
kubectl apply -f role-pod-reader.yaml

# Verificar
kubectl get role pod-reader -n production
```

### Paso 2: Crear RoleBinding
```yaml
# rolebinding-monitoring.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: monitoring-pod-reader
  namespace: production
subjects:
- kind: ServiceAccount        # ⬅️ CRITICAL: kind es ServiceAccount
  name: monitoring-app        # ⬅️ Nombre del SA
  namespace: production       # ⬅️ Namespace del SA
roleRef:
  kind: Role
  name: pod-reader            # ⬅️ Role a asignar
  apiGroup: rbac.authorization.k8s.io
```

```bash
# Aplicar
kubectl apply -f rolebinding-monitoring.yaml

# Verificar
kubectl describe rolebinding monitoring-pod-reader -n production
```

### Método Imperativo Rápido
```bash
# Crear RoleBinding en un comando
kubectl create rolebinding monitoring-pod-reader \
  --role=pod-reader \
  --serviceaccount=production:monitoring-app \
  --namespace=production

# Nota el formato: namespace:serviceaccount-name
```

### ✅ Verificar Permisos
```bash
# Verificar si el SA puede listar pods
kubectl auth can-i list pods \
  --as=system:serviceaccount:production:monitoring-app \
  -n production
# yes

# Verificar si puede borrar pods (no debería)
kubectl auth can-i delete pods \
  --as=system:serviceaccount:production:monitoring-app \
  -n production
# no

# El formato es: system:serviceaccount:<namespace>:<sa-name>
```

---

## 📋 Práctica 3: Usar Service Account en Pod (20 min)

### Paso 1: Pod con Service Account Custom
```yaml
# pod-monitoring.yaml
apiVersion: v1
kind: Pod
metadata:
  name: monitoring-pod
  namespace: production
  labels:
    app: monitoring
spec:
  serviceAccountName: monitoring-app  # ⬅️ Especifica el SA
  containers:
  - name: monitor
    image: busybox:1.35
    command: ['sh', '-c', 'sleep 3600']
```

```bash
# Aplicar
kubectl apply -f pod-monitoring.yaml

# Verificar
kubectl get pod monitoring-pod -n production

# Ver qué SA usa
kubectl get pod monitoring-pod -n production -o jsonpath='{.spec.serviceAccountName}'
# monitoring-app
```

### Paso 2: Verificar Token Montado
```bash
# Acceder al pod
kubectl exec -it monitoring-pod -n production -- sh

# Dentro del pod, ver token
ls -la /var/run/secrets/kubernetes.io/serviceaccount/
# token  ca.crt  namespace

# Ver contenido del token
cat /var/run/secrets/kubernetes.io/serviceaccount/token
# eyJhbGciOiJSUzI1NiIsImtpZCI6Ij... (JWT token)

# Ver namespace
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
# production

# Ver variables de entorno
env | grep KUBERNETES
# KUBERNETES_SERVICE_HOST=10.0.0.1
# KUBERNETES_SERVICE_PORT=443
```

### Paso 3: Acceder a K8s API desde Pod
```bash
# Dentro del pod
# Variables para API
APISERVER=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Listar pods (debe funcionar - tenemos permisos)
curl -s --cacert $CACERT --header "Authorization: Bearer $TOKEN" \
  $APISERVER/api/v1/namespaces/production/pods | head -20

# Listar eventos (debe funcionar)
curl -s --cacert $CACERT --header "Authorization: Bearer $TOKEN" \
  $APISERVER/api/v1/namespaces/production/events

# Intentar crear pod (debe fallar - no tenemos permisos)
curl -s --cacert $CACERT --header "Authorization: Bearer $TOKEN" \
  -X POST $APISERVER/api/v1/namespaces/production/pods \
  -H "Content-Type: application/json"
# Error: Forbidden
```

---

## 📋 Práctica 4: Deployment con Service Account (25 min)

### Deployment Completo
```yaml
# deployment-monitoring.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: monitoring-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: monitoring
  template:
    metadata:
      labels:
        app: monitoring
    spec:
      serviceAccountName: monitoring-app  # ⬅️ Todos los pods usan este SA
      containers:
      - name: monitor
        image: nginx:1.21
        ports:
        - containerPort: 80
```

```bash
# Aplicar
kubectl apply -f deployment-monitoring.yaml

# Verificar pods
kubectl get pods -n production -l app=monitoring

# Verificar que todos usan el mismo SA
kubectl get pods -n production -l app=monitoring \
  -o custom-columns=NAME:.metadata.name,SA:.spec.serviceAccountName
```

### ✅ Verificación
```bash
# Todos los pods del deployment tienen el mismo SA
kubectl get pods -n production -l app=monitoring

# Verificar desde un pod
POD_NAME=$(kubectl get pods -n production -l app=monitoring -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it $POD_NAME -n production -- \
  cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
# production
```

---

## 📋 Práctica 5: ClusterRole para Service Account (30 min)

### Escenario: SA que necesita acceso global
```yaml
# clusterrole-pod-reader-global.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: global-pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list"]
```

```bash
kubectl apply -f clusterrole-pod-reader-global.yaml
```

### ClusterRoleBinding para Service Account
```yaml
# clusterrolebinding-monitoring-global.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-global-access
subjects:
- kind: ServiceAccount
  name: monitoring-app
  namespace: production      # ⬅️ SA está en un namespace específico
roleRef:
  kind: ClusterRole
  name: global-pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
# Aplicar
kubectl apply -f clusterrolebinding-monitoring-global.yaml

# Verificar
kubectl describe clusterrolebinding monitoring-global-access
```

### ✅ Verificación Acceso Global
```bash
# Ahora el SA puede ver pods en TODOS los namespaces
kubectl auth can-i list pods --all-namespaces \
  --as=system:serviceaccount:production:monitoring-app
# yes

# Puede ver pods en kube-system
kubectl auth can-i list pods -n kube-system \
  --as=system:serviceaccount:production:monitoring-app
# yes

# Puede listar namespaces
kubectl auth can-i list namespaces \
  --as=system:serviceaccount:production:monitoring-app
# yes
```

---

## 📋 Práctica 6: Aplicación Python Accediendo a K8s API (45 min)

### Estructura del Proyecto
```
python-api-client/
├── app.py                   # Código Python
├── requirements.txt         # Dependencias
├── Dockerfile              # Container image
├── serviceaccount.yaml     # Service Account
├── role.yaml               # Permisos necesarios
├── rolebinding.yaml        # Binding
└── deployment.yaml         # Deploy completo
```

### 1. Código Python (app.py)
```python
# app.py
from kubernetes import client, config
import os

def main():
    # Cargar configuración in-cluster (usa el token montado)
    config.load_incluster_config()
    
    # Crear cliente API
    v1 = client.CoreV1Api()
    
    # Obtener namespace del pod
    namespace = open('/var/run/secrets/kubernetes.io/serviceaccount/namespace').read()
    
    print(f"Running in namespace: {namespace}")
    
    # Listar pods
    print("\nListing pods in namespace:")
    pods = v1.list_namespaced_pod(namespace)
    
    for pod in pods.items:
        print(f"  - {pod.metadata.name} ({pod.status.phase})")
    
    # Listar eventos
    print("\nListing events:")
    events = v1.list_namespaced_event(namespace)
    
    for event in events.items[:5]:  # Solo primeros 5
        print(f"  - {event.reason}: {event.message}")

if __name__ == '__main__':
    main()
```

### 2. Dependencias (requirements.txt)
```
kubernetes==27.2.0
```

### 3. Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD ["python", "app.py"]
```

### 4. RBAC Completo
```yaml
# serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: k8s-api-client
  namespace: production
---
# role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: api-client-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "events"]
  verbs: ["get", "list"]
---
# rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: api-client-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: k8s-api-client
  namespace: production
roleRef:
  kind: Role
  name: api-client-role
  apiGroup: rbac.authorization.k8s.io
```

### 5. Deployment
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-api-client
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-client
  template:
    metadata:
      labels:
        app: api-client
    spec:
      serviceAccountName: k8s-api-client  # ⬅️ Usa el SA custom
      containers:
      - name: client
        image: <tu-registry>/k8s-api-client:latest
        imagePullPolicy: Always
```

### Desplegar Todo
```bash
# 1. Construir imagen (ajusta registry)
docker build -t <tu-registry>/k8s-api-client:latest .
docker push <tu-registry>/k8s-api-client:latest

# 2. Aplicar RBAC
kubectl apply -f serviceaccount.yaml
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml

# 3. Desplegar aplicación
kubectl apply -f deployment.yaml

# 4. Ver logs
kubectl logs -f deployment/k8s-api-client -n production
```

### ✅ Salida Esperada
```
Running in namespace: production

Listing pods in namespace:
  - monitoring-pod (Running)
  - k8s-api-client-7d8f5b-xk8p2 (Running)
  - nginx-deployment-6b474-qr5zt (Running)

Listing events:
  - Scheduled: Successfully assigned production/k8s-api-client...
  - Pulling: Pulling image "k8s-api-client:latest"
  - Pulled: Successfully pulled image
  - Created: Created container client
  - Started: Started container client
```

---

## 🔍 Práctica 7: Troubleshooting Service Accounts (30 min)

### Problema 1: Pod no tiene permisos
```bash
# Error en logs
Error from server (Forbidden): pods is forbidden: 
User "system:serviceaccount:production:default" cannot list resource "pods"

# Diagnóstico
# 1. Verificar qué SA usa el pod
kubectl get pod <pod-name> -n production -o jsonpath='{.spec.serviceAccountName}'
# default  ⬅️ Problema: usa SA default sin permisos

# 2. Verificar permisos del SA
kubectl auth can-i list pods \
  --as=system:serviceaccount:production:default \
  -n production
# no

# Solución: Crear SA custom y asignar permisos
kubectl create sa my-app -n production
kubectl create role pod-reader --verb=get,list --resource=pods -n production
kubectl create rolebinding my-app-binding \
  --role=pod-reader \
  --serviceaccount=production:my-app \
  -n production

# Actualizar pod para usar nuevo SA
kubectl set serviceaccount deployment/my-app my-app -n production
```

### Problema 2: Token no montado en pod
```bash
# Error
open /var/run/secrets/kubernetes.io/serviceaccount/token: no such file or directory

# Diagnóstico
kubectl get pod <pod-name> -n production -o yaml | grep automountServiceAccountToken
# automountServiceAccountToken: false  ⬅️ Token no se monta

# Solución 1: A nivel de SA
kubectl patch serviceaccount my-app -n production \
  -p '{"automountServiceAccountToken": true}'

# Solución 2: A nivel de Pod
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  serviceAccountName: my-app
  automountServiceAccountToken: true  # ⬅️ Forzar montaje
  containers:
  - name: app
    image: nginx
```

### Problema 3: SA no existe
```bash
# Error al crear pod
Error: pods "my-pod" is forbidden: error looking up service account production/nonexistent: 
serviceaccount "nonexistent" not found

# Diagnóstico
kubectl get sa nonexistent -n production
# Error: serviceaccount "nonexistent" not found

# Solución
kubectl create sa nonexistent -n production
# Luego reintentar crear pod
```

### Problema 4: Permisos insuficientes
```bash
# Error
Error from server (Forbidden): pods is forbidden: 
User "system:serviceaccount:production:my-app" cannot delete resource "pods"

# Diagnóstico
# 1. Verificar Role
kubectl get role -n production
kubectl describe role <role-name> -n production

# 2. Verificar verbs permitidos
kubectl get role <role-name> -n production -o yaml | grep -A 5 verbs
# verbs:
# - get
# - list
# ⬅️ Falta "delete"

# Solución: Actualizar Role
kubectl patch role <role-name> -n production \
  --type='json' \
  -p='[{"op": "add", "path": "/rules/0/verbs/-", "value": "delete"}]'

# O recrear Role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-manager
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "delete"]  # ⬅️ Agregado delete
```

### Comandos de Diagnóstico
```bash
# 1. Listar todos los Service Accounts
kubectl get sa --all-namespaces

# 2. Ver detalles de un SA
kubectl describe sa <sa-name> -n <namespace>

# 3. Ver RoleBindings de un SA
kubectl get rolebindings --all-namespaces -o json | \
  jq '.items[] | select(.subjects[]?.name=="<sa-name>")'

# 4. Verificar permisos
kubectl auth can-i <verb> <resource> \
  --as=system:serviceaccount:<namespace>:<sa-name> \
  -n <namespace>

# 5. Ver token de un SA
kubectl describe sa <sa-name> -n <namespace>
# Ver secret asociado, luego:
kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data.token}' | base64 -d

# 6. Listar pods y sus SAs
kubectl get pods -n <namespace> \
  -o custom-columns=NAME:.metadata.name,SA:.spec.serviceAccountName
```

---

## 🎓 Cheat Sheet de Comandos Service Accounts

### Crear Service Accounts
```bash
# Crear SA básico
kubectl create serviceaccount <sa-name> -n <namespace>

# Crear SA con YAML
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: <sa-name>
  namespace: <namespace>
EOF
```

### Asignar Permisos
```bash
# Crear RoleBinding para SA
kubectl create rolebinding <binding-name> \
  --role=<role-name> \
  --serviceaccount=<namespace>:<sa-name> \
  --namespace=<namespace>

# Crear ClusterRoleBinding para SA
kubectl create clusterrolebinding <binding-name> \
  --clusterrole=<role-name> \
  --serviceaccount=<namespace>:<sa-name>

# Formato importante: namespace:sa-name
```

### Usar en Pods/Deployments
```bash
# Actualizar deployment para usar SA
kubectl set serviceaccount deployment/<deploy-name> <sa-name> -n <namespace>

# Patch pod para usar SA (pods son inmutables, hay que recrear)
kubectl patch pod <pod-name> -n <namespace> \
  -p '{"spec":{"serviceAccountName":"<sa-name>"}}'
```

### Consultas y Diagnóstico
```bash
# Listar SAs
kubectl get serviceaccounts -n <namespace>
kubectl get sa --all-namespaces

# Describir SA
kubectl describe serviceaccount <sa-name> -n <namespace>

# Ver YAML
kubectl get sa <sa-name> -n <namespace> -o yaml

# Verificar permisos
kubectl auth can-i <verb> <resource> \
  --as=system:serviceaccount:<namespace>:<sa-name> \
  -n <namespace>

# Ejemplos
kubectl auth can-i list pods --as=system:serviceaccount:default:my-app -n default
kubectl auth can-i delete services --as=system:serviceaccount:prod:my-app -n prod

# Ver qué SA usa un pod
kubectl get pod <pod-name> -n <namespace> \
  -o jsonpath='{.spec.serviceAccountName}'

# Listar todos los pods con su SA
kubectl get pods -n <namespace> \
  -o custom-columns=NAME:.metadata.name,SA:.spec.serviceAccountName
```

### Gestión de Tokens
```bash
# Ver secret del token (K8s < 1.24)
kubectl get sa <sa-name> -n <namespace> -o jsonpath='{.secrets[0].name}'

# Obtener token (K8s < 1.24)
TOKEN_SECRET=$(kubectl get sa <sa-name> -n <namespace> -o jsonpath='{.secrets[0].name}')
kubectl get secret $TOKEN_SECRET -n <namespace> -o jsonpath='{.data.token}' | base64 -d

# Crear token (K8s 1.24+)
kubectl create token <sa-name> -n <namespace>

# Token con duración específica
kubectl create token <sa-name> -n <namespace> --duration=1h
```

### Eliminar
```bash
# Eliminar SA
kubectl delete serviceaccount <sa-name> -n <namespace>

# Eliminar con cascada (también elimina secrets)
kubectl delete sa <sa-name> -n <namespace> --cascade=true
```

---

## 📊 Comparaciones Prácticas

### Service Account por Defecto vs Custom

```yaml
# SERVICE ACCOUNT POR DEFECTO (automático)
# Cada namespace tiene un SA "default"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
  namespace: production

# Pods sin serviceAccountName especificado usan este
# Generalmente NO tiene permisos adicionales (seguro)

---

# SERVICE ACCOUNT CUSTOM (recomendado)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  namespace: production
  labels:
    app: my-app
  annotations:
    description: "SA para my-app con permisos específicos"

# Pods deben especificar: serviceAccountName: my-app-sa
# Asignas solo permisos necesarios (principio mínimo privilegio)
```

### Role vs ClusterRole para Service Accounts

```yaml
# ROLE - Permisos en UN namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: production    # ⬅️ Solo en production
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-pod-reader
  namespace: production
subjects:
- kind: ServiceAccount
  name: my-app-sa
  namespace: production
roleRef:
  kind: Role
  name: pod-reader

---

# CLUSTERROLE - Permisos GLOBALES
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: global-pod-reader  # ⬅️ Sin namespace
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: app-global-reader
subjects:
- kind: ServiceAccount
  name: my-app-sa
  namespace: production    # ⬅️ SA sigue en namespace específico
roleRef:
  kind: ClusterRole
  name: global-pod-reader  # ⬅️ Pero tiene permisos globales
```

### Casos de Uso

| Necesidad | Solución |
|-----------|----------|
| App monitoring lee pods en su namespace | SA + Role + RoleBinding |
| App monitoring lee pods en TODO el cluster | SA + ClusterRole + ClusterRoleBinding |
| CronJob backup de un namespace | SA + Role (get, list, create) |
| Operator gestiona CRDs globalmente | SA + ClusterRole con permisos amplios |
| CI/CD despliega en múltiples namespaces | SA + ClusterRole + ClusterRoleBinding |
| App simple sin acceso a API | SA default (sin permisos extra) |

---

## ✅ Checklist de Implementación

### Fase 1: Planificación
- [ ] Identificar aplicaciones que necesitan acceso a K8s API
- [ ] Mapear permisos necesarios por aplicación
- [ ] Decidir scope (namespace vs cluster-wide)
- [ ] Diseñar estrategia de Service Accounts (uno por app vs compartido)

### Fase 2: Creación de Service Accounts
- [ ] Crear namespace si no existe
- [ ] Crear Service Account por aplicación
- [ ] Agregar labels y annotations descriptivas
- [ ] Documentar propósito de cada SA

### Fase 3: Definición de Permisos RBAC
- [ ] Crear Roles con permisos mínimos necesarios
- [ ] Crear ClusterRoles si se necesita acceso global
- [ ] Validar resources y verbs correctos
- [ ] Aplicar principio de mínimo privilegio

### Fase 4: Asignación de Permisos
- [ ] Crear RoleBindings conectando SA con Roles
- [ ] Crear ClusterRoleBindings si es necesario
- [ ] Verificar subjects correctos (ServiceAccount + namespace)
- [ ] Confirmar roleRef apunta al Role correcto

### Fase 5: Configuración de Pods/Deployments
- [ ] Especificar serviceAccountName en spec
- [ ] Verificar automountServiceAccountToken (true por defecto)
- [ ] Probar montaje de token en /var/run/secrets
- [ ] Validar variables de entorno KUBERNETES_*

### Fase 6: Pruebas de Acceso
- [ ] Usar kubectl auth can-i para verificar permisos
- [ ] Probar acceso desde pod (kubectl exec)
- [ ] Validar llamadas a API funcionan
- [ ] Verificar errores esperados (permisos denegados)

### Fase 7: Implementación de Aplicación
- [ ] Desarrollar código que use kubernetes client library
- [ ] Usar config.load_incluster_config() (Python)
- [ ] Manejar errores de autenticación y autorización
- [ ] Implementar retry logic para llamadas API

### Fase 8: Monitoreo y Mantenimiento
- [ ] Auditar permisos regularmente
- [ ] Revisar logs de acceso denegado
- [ ] Actualizar Roles según necesidades
- [ ] Eliminar Service Accounts no utilizados
- [ ] Rotar tokens si es necesario (K8s 1.24+)

---

## 🎓 Preguntas de Repaso

### Conceptuales
1. ¿Cuál es la diferencia entre Service Account y Usuario?
2. ¿Por qué Service Accounts usan tokens JWT y no certificados X.509?
3. ¿Qué sucede si un pod no especifica serviceAccountName?
4. ¿Dónde se monta el token JWT en un pod?
5. ¿Cuál es el formato para referenciar un SA en kubectl auth can-i?

### Prácticas
1. ¿Cómo crear un Service Account desde línea de comandos?
2. ¿Cómo asignar un Role a un Service Account con un comando?
3. ¿Cómo verificar qué SA está usando un pod en ejecución?
4. ¿Cómo actualizar un deployment para usar un SA diferente?
5. ¿Cómo obtener el token de un Service Account manualmente?

### Troubleshooting
1. Pod da error "Forbidden" al acceder API - ¿qué verificas?
2. Token no está montado en /var/run/secrets - ¿cuál es la causa?
3. SA tiene permisos pero el pod no puede acceder API - ¿qué revisa?
4. ¿Cómo auditar qué Service Accounts tienen permisos en un namespace?
5. ¿Qué hacer si un SA necesita permisos en múltiples namespaces?

---

## 🔗 Próximos Pasos

### Después de Dominar Este Módulo
✅ Comprendes Service Accounts para **aplicaciones**
✅ Sabes asignar permisos RBAC a SAs
✅ Puedes implementar apps que usan K8s API
✅ Dominas troubleshooting de permisos

### Conexión con Módulo 17
**Ahora tienes el cuadro completo de RBAC**:
- **Módulo 17**: Usuarios y Grupos (personas) → Certificados X.509
- **Módulo 18**: Service Accounts (aplicaciones) → Tokens JWT

### Temas Avanzados para Explorar
- **Pod Security Policies (PSP)**: Restricciones adicionales de seguridad
- **Network Policies**: Control de tráfico de red
- **OPA/Gatekeeper**: Políticas de admisión avanzadas
- **Workload Identity**: Integración con proveedores cloud (AWS IRSA, GCP Workload Identity)

### Recursos Adicionales
- 📖 [Service Accounts Oficial](https://kubernetes.io/docs/concepts/security/service-accounts/)
- 📖 [Configure Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- 📖 [Kubernetes Python Client](https://github.com/kubernetes-client/python)
- 🎥 [Tutorial Service Accounts](https://www.youtube.com/results?search_query=kubernetes+service+accounts)

### Práctica Adicional
- Implementar app de monitoring con SA
- Crear operator simple usando SA con permisos amplios
- Diseñar estrategia de SAs para arquitectura microservicios
- Auditar SAs existentes en cluster de producción

---

## 📝 Notas Finales

**Regla de Oro**:
```
Personas (kubectl externo) = Usuarios (Módulo 17)
Aplicaciones (pods internos) = Service Accounts (Módulo 18)
```

**Mejores Prácticas**:
- ✅ Crear SA específico por aplicación (no compartir)
- ✅ Aplicar principio de mínimo privilegio
- ✅ NO usar SA "default" para apps que acceden API
- ✅ Documentar qué hace cada SA (annotations)
- ✅ Auditar permisos regularmente
- ✅ Usar RoleBindings por namespace cuando sea posible (más seguro que ClusterRoleBindings)

**Diferencias Clave para Recordar**:
| | Service Accounts | Usuarios |
|---|------------------|----------|
| Creación | `kubectl create sa` | Scripts OpenSSL |
| Autenticación | Tokens JWT montados | Certificados X.509 |
| Ubicación | Dentro del cluster | Fuera del cluster |
| Gestión | API de Kubernetes | Externa (manual) |
| Scope | Por namespace | Global |

¡Éxito implementando seguridad de aplicaciones con Service Accounts! 🚀
