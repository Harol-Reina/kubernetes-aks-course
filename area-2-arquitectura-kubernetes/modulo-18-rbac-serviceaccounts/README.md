# Módulo 18: RBAC - Service Accounts en Kubernetes

## Tabla de Contenidos

1. [Introducción al Módulo](#introducción-al-módulo)
2. [¿Qué son los Service Accounts?](#1-qué-son-los-service-accounts)
3. [Service Accounts vs Usuarios: Diferencias Clave](#2-service-accounts-vs-usuarios-diferencias-clave)
4. [Anatomía de un Service Account](#3-anatomía-de-un-service-account)
5. [Creación y Gestión de Service Accounts](#4-creación-y-gestión-de-service-accounts)
6. [Tokens y Autenticación](#5-tokens-y-autenticación)
7. [Asignación de Permisos con Roles](#6-asignación-de-permisos-con-roles)
8. [Service Accounts en Pods](#7-service-accounts-en-pods)
9. [Casos de Uso Prácticos](#8-casos-de-uso-prácticos)
10. [Mejores Prácticas y Seguridad](#9-mejores-prácticas-y-seguridad)
11. [Troubleshooting](#10-troubleshooting)
12. [Conclusiones y Próximos Pasos](#conclusiones-y-próximos-pasos)

---

## Introducción al Módulo

Bienvenidos al módulo 18, donde profundizaremos en **Service Accounts**, un componente fundamental de RBAC diseñado específicamente para **identidades de aplicaciones y procesos** dentro de Kubernetes.

### ¿Qué cubriremos en este módulo?

En este módulo nos enfocaremos exclusivamente en:
- **Service Accounts**: Identidades para pods y aplicaciones
- **Tokens automáticos**: Mecanismo de autenticación para procesos
- **Asignación de permisos a aplicaciones**: Usando Roles y RoleBindings
- **Integración con pods**: Cómo las aplicaciones usan Service Accounts
- **Gestión del ciclo de vida**: Creación, actualización y eliminación

### ¿En qué se diferencia del Módulo 17?

| Aspecto | Módulo 17 (Usuarios y Grupos) | Módulo 18 (Service Accounts) |
|---------|-------------------------------|------------------------------|
| **Para quién** | Personas (desarrolladores, admins) | Aplicaciones y pods |
| **Autenticación** | Certificados X.509 | Tokens JWT |
| **Gestión** | Manual (externa a Kubernetes) | Automática (API de Kubernetes) |
| **Ubicación** | Acceso externo (kubectl) | Dentro del cluster |
| **Scope** | Global al cluster | Por namespace |

> **💡 Regla de oro**: Si necesitas dar acceso a una **persona**, usa usuarios y grupos (Módulo 17). Si necesitas dar acceso a un **pod o aplicación**, usa Service Accounts (este módulo).

### Prerrequisitos

Antes de comenzar este módulo, deberías:
- ✅ Haber completado el Módulo 17 (RBAC: Usuarios y Grupos)
- ✅ Tener un cluster de Kubernetes funcionando
- ✅ Conocer los conceptos de Roles y RoleBindings
- ✅ Entender qué son los pods y deployments

### Estructura del Módulo

Este módulo incluye:
- 📖 **Documentación teórica**: Esta guía completa con ejemplos inline
- 💾 **Ejemplos prácticos**: Carpeta [`ejemplos/`](./ejemplos/) con manifiestos YAML
- 🔬 **Laboratorios guiados**: Carpeta [`laboratorios/`](./laboratorios/) con ejercicios hands-on

---

## 1. ¿Qué son los Service Accounts?

### El Problema que Resuelven

Imagina que tienes una aplicación de monitoreo corriendo dentro de tu cluster de Kubernetes. Esta aplicación necesita:
- Listar todos los pods del cluster
- Obtener métricas de CPU y memoria
- Ver el estado de los deployments

**Pregunta clave**: ¿Cómo puede esta aplicación autenticarse con la API de Kubernetes?

```
┌─────────────────────────────────────────────────────┐
│           Cluster Kubernetes                        │
│                                                     │
│  ┌──────────────┐              ┌──────────────┐   │
│  │ Pod: Monitor │─────?────────>│  API Server  │   │
│  │              │              │              │   │
│  │ "¿Qué pods   │              │ "¿Quién      │   │
│  │  existen?"   │              │  eres?"      │   │
│  └──────────────┘              └──────────────┘   │
│                                                     │
│  ¿Cómo se autentica el pod?                        │
└─────────────────────────────────────────────────────┘
```

**La respuesta**: Service Accounts

### Definición

Un **Service Account** es una identidad gestionada por Kubernetes que permite a los pods y aplicaciones autenticarse con la API del cluster.

**Características principales**:
- 🤖 **Identidad para procesos**: No para humanos
- 🔑 **Token automático**: Kubernetes genera y monta el token
- 📦 **Namespace-scoped**: Cada Service Account pertenece a un namespace
- 🔄 **Gestionado por API**: Creación y gestión mediante kubectl/API

### Ejemplo Conceptual

```
┌─────────────────────────────────────────────────────┐
│           Namespace: monitoring                     │
│                                                     │
│  ┌──────────────┐              ┌──────────────┐   │
│  │ Pod: Monitor │──────────────>│  API Server  │   │
│  │              │  Token: xyz   │              │   │
│  │ SA: monitor  │◄─────────────│ "Autenticado"│   │
│  └──────────────┘              └──────────────┘   │
│         ▲                                           │
│         │ Usa                                       │
│         │                                           │
│  ┌──────┴───────┐                                  │
│  │ServiceAccount│                                  │
│  │ Name: monitor│                                  │
│  │ Token: xyz   │                                  │
│  └──────────────┘                                  │
└─────────────────────────────────────────────────────┘
```

---

## 2. Service Accounts vs Usuarios: Diferencias Clave

Es crucial entender que Service Accounts y Usuarios son conceptos **completamente diferentes** en Kubernetes.

### Comparación Detallada

#### Service Accounts (Este Módulo)

```yaml
# Son recursos de Kubernetes
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mi-app
  namespace: produccion
```

**Características**:
- ✅ Gestionados por la API de Kubernetes
- ✅ Tienen representación como objetos (puedes hacer `kubectl get sa`)
- ✅ Tokens generados automáticamente
- ✅ Montados automáticamente en pods
- ✅ Scope por namespace
- ✅ Para aplicaciones dentro del cluster

#### Usuarios (Módulo 17)

```bash
# NO son recursos de Kubernetes
# Se gestionan con certificados externos
openssl genrsa -out usuario.key 2048
```

**Características**:
- ❌ NO son objetos de Kubernetes
- ❌ NO se crean con kubectl
- ❌ Certificados gestionados manualmente
- ❌ Para acceso externo (kubectl)
- ❌ Scope global al cluster
- ✅ Para personas

### Analogía del Mundo Real

Piensa en una empresa:

**Usuarios (Módulo 17)** = **Empleados con tarjeta de identificación**
- Entran al edificio desde afuera
- Usan credenciales personales (certificado)
- Gestión manual de credenciales
- Ejemplo: "Juan Pérez, Desarrollador"

**Service Accounts (Módulo 18)** = **Sistemas automatizados internos**
- Operan dentro del edificio
- Credenciales generadas automáticamente
- Sistema de gestión centralizado
- Ejemplo: "Sistema de monitoreo, Sala de servidores A"

### Tabla Comparativa Visual

| Característica | Usuarios y Grupos | Service Accounts |
|----------------|-------------------|------------------|
| **Tipo de identidad** | Humana | Aplicación/Proceso |
| **¿Objeto de K8s?** | ❌ No | ✅ Sí |
| **Creación** | Manual (certificados) | API (`kubectl create sa`) |
| **Autenticación** | Certificado X.509 | Token JWT |
| **Gestión de tokens** | Manual | Automática |
| **Namespace** | No aplica | Sí (namespace-scoped) |
| **Montaje en pods** | ❌ No | ✅ Sí (automático) |
| **Uso típico** | kubectl desde laptop | API calls desde pods |
| **Ejemplo** | DevOps team, Developer | monitoring-app, ci-runner |

---

## 3. Anatomía de un Service Account

### Componentes de un Service Account

Un Service Account está compuesto por varios elementos que trabajan juntos:

```
Service Account
    ├── Metadata (nombre, namespace, labels)
    ├── Secrets (tokens de autenticación)
    ├── ImagePullSecrets (opcional)
    └── AutomountServiceAccountToken (configuración)
```

### Manifest YAML Básico

```yaml
# Ejemplo básico de Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-account
  namespace: default
  labels:
    app: mi-aplicacion
    team: backend
  annotations:
    description: "Service Account para la aplicación de backend"

# Opcional: Secretos para pull de imágenes privadas
imagePullSecrets:
  - name: docker-registry-secret

# Opcional: Control de montaje automático del token
automountServiceAccountToken: true
```

**Explicación de campos**:

- **`metadata.name`**: Nombre único del Service Account en el namespace
- **`metadata.namespace`**: Namespace donde existe (si se omite, usa `default`)
- **`imagePullSecrets`**: Referencias a secretos para descargar imágenes de registros privados
- **`automountServiceAccountToken`**: Si es `true`, monta automáticamente el token en pods

### El Service Account por Defecto

**Dato importante**: Cada namespace tiene un Service Account llamado `default` creado automáticamente.

```bash
# Ver el Service Account default
kubectl get serviceaccount default -n default
```

```
NAME      SECRETS   AGE
default   1         30d
```

Si no especificas un Service Account en un pod, Kubernetes usa el `default` automáticamente.

### Estructura Completa con Ejemplo Inline

```yaml
# ejemplos/01-serviceaccount-completo.yaml
# Service Account con todas las configuraciones posibles
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aplicacion-backend
  namespace: produccion
  labels:
    app: backend
    environment: production
    team: platform
  annotations:
    description: "SA para backend API con acceso a ConfigMaps y Secrets"
    contact: "backend-team@empresa.com"

# Secretos para descargar imágenes de Azure Container Registry
imagePullSecrets:
  - name: acr-secret

# Permitir montaje automático del token en pods
automountServiceAccountToken: true

---
# Secret para Azure Container Registry (ejemplo complementario)
apiVersion: v1
kind: Secret
metadata:
  name: acr-secret
  namespace: produccion
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
```

> 📝 **Nota**: Este ejemplo está disponible en [`ejemplos/01-serviceaccount-completo.yaml`](./ejemplos/01-serviceaccount-completo.yaml)

---

## 4. Creación y Gestión de Service Accounts

### Método 1: Usando kubectl (Imperativo)

La forma más rápida de crear un Service Account:

```bash
# Crear un Service Account básico
kubectl create serviceaccount mi-app

# Crear en un namespace específico
kubectl create serviceaccount mi-app -n produccion

# Con dry-run para ver el YAML generado
kubectl create serviceaccount mi-app --dry-run=client -o yaml
```

**Salida del comando dry-run**:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mi-app
  namespace: default
```

### Método 2: Usando Manifiestos YAML (Declarativo)

**Recomendado para producción** - permite control de versiones y reproducibilidad.

```yaml
# ejemplos/02-serviceaccount-basico.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-reader
  namespace: desarrollo
  labels:
    purpose: read-only
    team: developers
```

```bash
# Aplicar el manifest
kubectl apply -f ejemplos/02-serviceaccount-basico.yaml
```

### Verificación y Consulta

```bash
# Listar todos los Service Accounts en el namespace actual
kubectl get serviceaccounts
# Atajo: kubectl get sa

# Listar en todos los namespaces
kubectl get sa --all-namespaces

# Ver detalles de un Service Account específico
kubectl describe sa mi-app

# Ver en formato YAML
kubectl get sa mi-app -o yaml
```

**Salida de ejemplo de `describe`**:
```
Name:                mi-app
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   mi-app-token-x7k9m
Tokens:              mi-app-token-x7k9m
Events:              <none>
```

### Actualización de Service Accounts

```bash
# Editar interactivamente
kubectl edit sa mi-app

# O aplicar cambios desde archivo
kubectl apply -f ejemplos/02-serviceaccount-basico.yaml
```

### Eliminación de Service Accounts

```bash
# Eliminar un Service Account
kubectl delete sa mi-app

# Eliminar desde archivo
kubectl delete -f ejemplos/02-serviceaccount-basico.yaml
```

⚠️ **Advertencia**: Si eliminas un Service Account que está siendo usado por pods en ejecución, esos pods perderán acceso a la API hasta que se reinicien con un SA válido.

### Ejemplo Práctico Inline: Service Account para Diferentes Entornos

```yaml
# ejemplos/03-serviceaccounts-por-ambiente.yaml
# Service Accounts organizados por ambiente

# Desarrollo - permisos amplios
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-dev
  namespace: desarrollo
  labels:
    environment: dev
---
# Staging - permisos intermedios
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-staging
  namespace: staging
  labels:
    environment: staging
---
# Producción - permisos mínimos
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-prod
  namespace: produccion
  labels:
    environment: production
```

> 🔬 **Laboratorio**: Para practicar la creación y gestión de Service Accounts, consulta [`laboratorios/lab-01-crear-serviceaccounts.md`](./laboratorios/lab-01-crear-serviceaccounts.md)

---

## 5. Tokens y Autenticación

### ¿Qué es un Token de Service Account?

Un token es una credencial JWT (JSON Web Token) que Kubernetes genera automáticamente para cada Service Account. Este token permite que los pods se autentiquen con la API.

### Generación Automática de Tokens

Cuando creas un Service Account, Kubernetes automáticamente:

1. **Crea un Secret** que contiene el token
2. **Asocia el Secret** al Service Account
3. **Monta el token** en los pods que usan ese SA

```
Crear SA → Kubernetes crea Secret → Secret contiene Token JWT
```

### Inspección de Tokens

```bash
# Ver el Secret asociado al Service Account
kubectl get sa mi-app -o yaml

# Output mostrará algo como:
# secrets:
# - name: mi-app-token-abc123

# Ver el contenido del Secret
kubectl get secret mi-app-token-abc123 -o yaml
```

**Estructura del Secret**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mi-app-token-abc123
  namespace: default
  annotations:
    kubernetes.io/service-account.name: mi-app
type: kubernetes.io/service-account-token
data:
  ca.crt: <base64-encoded-ca-certificate>
  namespace: ZGVmYXVsdA==  # "default" en base64
  token: <base64-encoded-jwt-token>
```

### Decodificar el Token

```bash
# Obtener el token decodificado
kubectl get secret mi-app-token-abc123 -o jsonpath='{.data.token}' | base64 -d

# Examinar el contenido del JWT (requiere jwt-cli o similar)
# El token es un JWT con claims sobre el Service Account
```

**Estructura de un JWT de Service Account**:
```json
{
  "iss": "kubernetes/serviceaccount",
  "kubernetes.io/serviceaccount/namespace": "default",
  "kubernetes.io/serviceaccount/service-account.name": "mi-app",
  "kubernetes.io/serviceaccount/service-account.uid": "abc-123-def",
  "sub": "system:serviceaccount:default:mi-app"
}
```

### Ubicación del Token en Pods

Cuando un pod usa un Service Account, Kubernetes monta automáticamente el token en:

```
/var/run/secrets/kubernetes.io/serviceaccount/
    ├── ca.crt          # Certificado CA del cluster
    ├── namespace       # Namespace del pod
    └── token           # El token JWT
```

### Ejemplo: Verificar Token desde un Pod

```yaml
# ejemplos/04-pod-con-serviceaccount.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-sa-pod
  namespace: default
spec:
  # Especificar el Service Account a usar
  serviceAccountName: mi-app
  
  containers:
  - name: test-container
    image: busybox:1.36
    command:
      - sleep
      - "3600"
```

```bash
# Aplicar el pod
kubectl apply -f ejemplos/04-pod-con-serviceaccount.yaml

# Ejecutar comandos dentro del pod
kubectl exec -it test-sa-pod -- sh

# Dentro del pod, ver el token
cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Ver el namespace
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace

# Ver el certificado CA
ls -la /var/run/secrets/kubernetes.io/serviceaccount/
```

### Tokens Proyectados (Token Request API)

Desde Kubernetes 1.20+, se recomienda usar **tokens proyectados** que:
- ✅ Tienen tiempo de expiración
- ✅ Son específicos de la audiencia
- ✅ Se renuevan automáticamente
- ✅ Son más seguros

```yaml
# ejemplos/05-pod-token-proyectado.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-token-seguro
spec:
  serviceAccountName: mi-app
  containers:
  - name: app
    image: nginx:alpine
    volumeMounts:
    - name: token
      mountPath: /var/run/secrets/tokens
      readOnly: true
  
  volumes:
  - name: token
    projected:
      sources:
      - serviceAccountToken:
          path: token
          expirationSeconds: 3600      # Token expira en 1 hora
          audience: api                # Audiencia específica
```

### Deshabilitar Montaje Automático

A veces no quieres que un pod tenga acceso a la API:

```yaml
# En el Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: no-api-access
automountServiceAccountToken: false

---
# O en el Pod específico
apiVersion: v1
kind: Pod
metadata:
  name: pod-sin-token
spec:
  serviceAccountName: mi-app
  automountServiceAccountToken: false  # Override SA config
  containers:
  - name: app
    image: nginx:alpine
```

---

## 6. Asignación de Permisos con Roles

### El Modelo RBAC para Service Accounts

Los Service Accounts por sí solos **NO tienen permisos**. Necesitas asignarles permisos usando:

1. **Role** o **ClusterRole**: Define QUÉ permisos
2. **RoleBinding** o **ClusterRoleBinding**: Asigna permisos A QUIÉN

```
ServiceAccount + Role + RoleBinding = Permisos efectivos
```

### Diagrama de Flujo

```
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│ ServiceAccount   │      │      Role        │      │   RoleBinding    │
│                  │      │                  │      │                  │
│ name: mi-app     │      │ Permisos:        │◄─────│ Role: pod-reader│
│ namespace: dev   │◄─────│ - get pods       │      │ Subject:         │
│                  │      │ - list pods      │      │   - mi-app       │
└──────────────────┘      └──────────────────┘      └──────────────────┘
        │
        │ Usa este SA
        ▼
┌──────────────────┐
│      Pod         │
│                  │
│ Tiene permisos   │
│ para get/list    │
│ pods             │
└──────────────────┘
```

### Ejemplo Completo: Lectura de Pods

#### Paso 1: Crear el Service Account

```yaml
# ejemplos/06-rbac-completo/01-serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-reader
  namespace: desarrollo
  labels:
    purpose: monitoring
```

#### Paso 2: Crear el Role con Permisos

```yaml
# ejemplos/06-rbac-completo/02-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader-role
  namespace: desarrollo
rules:
  # Permiso para leer pods
  - apiGroups: [""]           # "" indica el core API group
    resources: ["pods"]       # Recurso: pods
    verbs: ["get", "list"]    # Operaciones permitidas
  
  # Permiso adicional para leer logs
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
```

**Explicación de `verbs`**:
- `get`: Obtener un recurso específico por nombre
- `list`: Listar todos los recursos de ese tipo
- `watch`: Ver cambios en tiempo real
- `create`: Crear nuevos recursos
- `update`: Actualizar recursos existentes
- `patch`: Modificar parcialmente recursos
- `delete`: Eliminar recursos

#### Paso 3: Crear el RoleBinding

```yaml
# ejemplos/06-rbac-completo/03-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: desarrollo
subjects:
  # El Service Account que recibe los permisos
  - kind: ServiceAccount
    name: pod-reader
    namespace: desarrollo
roleRef:
  # El Role que contiene los permisos
  kind: Role
  name: pod-reader-role
  apiGroup: rbac.authorization.k8s.io
```

#### Paso 4: Aplicar Todo

```bash
# Aplicar todo el conjunto
kubectl apply -f ejemplos/06-rbac-completo/

# Verificar
kubectl get sa pod-reader -n desarrollo
kubectl get role pod-reader-role -n desarrollo
kubectl get rolebinding pod-reader-binding -n desarrollo
```

### Ejemplo con ClusterRole (Permisos Globales)

Para dar permisos en **todos los namespaces**:

```yaml
# ejemplos/07-clusterrole-serviceaccount.yaml
# Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-monitor
  namespace: monitoring
---
# ClusterRole - permisos en todo el cluster
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods", "namespaces"]
    verbs: ["get", "list", "watch"]
---
# ClusterRoleBinding - asocia SA con ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-monitor-binding
subjects:
  - kind: ServiceAccount
    name: cluster-monitor
    namespace: monitoring
roleRef:
  kind: ClusterRole
  name: cluster-pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Permisos Comunes para Service Accounts

#### Solo lectura (read-only)

```yaml
rules:
  - apiGroups: [""]
    resources: ["pods", "configmaps", "services"]
    verbs: ["get", "list", "watch"]
```

#### Gestión de Deployments

```yaml
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
```

#### Acceso a Secrets (usar con precaución)

```yaml
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list"]
```

> 🔬 **Laboratorio**: Para practicar la asignación de permisos, consulta [`laboratorios/lab-02-permisos-serviceaccounts.md`](./laboratorios/lab-02-permisos-serviceaccounts.md)

---

## 7. Service Accounts en Pods

### Asignación de Service Account a un Pod

Hay dos formas principales de usar Service Accounts en pods:

#### 1. Uso del Service Account por Defecto

Si no especificas nada, el pod usa el SA `default`:

```yaml
# El pod usará automáticamente el SA "default"
apiVersion: v1
kind: Pod
metadata:
  name: pod-default-sa
spec:
  containers:
  - name: nginx
    image: nginx:alpine
```

#### 2. Especificar un Service Account Personalizado

```yaml
# ejemplos/08-pod-custom-sa.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-custom-sa
  namespace: desarrollo
spec:
  # Especificar el Service Account
  serviceAccountName: pod-reader
  
  containers:
  - name: app
    image: busybox:1.36
    command:
      - sleep
      - "3600"
```

### Service Accounts en Deployments

La práctica común es especificar el SA en el template del Deployment:

```yaml
# ejemplos/09-deployment-con-sa.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
  namespace: produccion
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      # Service Account para todos los pods del deployment
      serviceAccountName: aplicacion-backend
      
      containers:
      - name: api
        image: miapp/backend:v1.0
        ports:
        - containerPort: 8080
        
        # Opcional: variables de entorno con info del SA
        env:
        - name: MY_POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: MY_POD_SA
          valueFrom:
            fieldRef:
              fieldPath: spec.serviceAccountName
```

### Acceder a la API desde un Pod

Una vez que un pod tiene un Service Account con permisos, puede acceder a la API:

```yaml
# ejemplos/10-pod-api-access.yaml
apiVersion: v1
kind: Pod
metadata:
  name: api-client
  namespace: desarrollo
spec:
  serviceAccountName: pod-reader
  
  containers:
  - name: kubectl-container
    image: bitnami/kubectl:latest
    command:
      - sleep
      - "3600"
```

```bash
# Aplicar el pod
kubectl apply -f ejemplos/10-pod-api-access.yaml

# Ejecutar comandos dentro del pod
kubectl exec -it api-client -n desarrollo -- bash

# Dentro del pod, usar kubectl
kubectl get pods
kubectl get pods --all-namespaces  # Fallará si no tiene permisos cluster-wide
```

### Ejemplo con curl: Acceso Directo a la API

```bash
# Dentro de un pod con Service Account
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

# Hacer request a la API
curl --cacert $CACERT \
     --header "Authorization: Bearer $TOKEN" \
     https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods
```

### Ejemplo Aplicación Python con Service Account

```yaml
# ejemplos/11-python-api-client/deployment.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: python-api-client
  namespace: desarrollo
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-lister
  namespace: desarrollo
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: python-api-client-binding
  namespace: desarrollo
subjects:
  - kind: ServiceAccount
    name: python-api-client
    namespace: desarrollo
roleRef:
  kind: Role
  name: pod-lister
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-api-client
  namespace: desarrollo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: python-client
  template:
    metadata:
      labels:
        app: python-client
    spec:
      serviceAccountName: python-api-client
      containers:
      - name: python
        image: python:3.11-slim
        command:
          - sleep
          - "infinity"
```

**Script Python de ejemplo** (ver [`ejemplos/11-python-api-client/app.py`](./ejemplos/11-python-api-client/app.py)):
```python
# Usar la librería oficial de Kubernetes
from kubernetes import client, config

# Cargar config desde el pod (usa el SA token automáticamente)
config.load_incluster_config()

# Crear cliente de la API
v1 = client.CoreV1Api()

# Listar pods en el namespace actual
pods = v1.list_namespaced_pod(namespace="desarrollo")
for pod in pods.items:
    print(f"Pod: {pod.metadata.name}")
```

> 🔬 **Laboratorio**: Para practicar el uso de Service Accounts en pods, consulta [`laboratorios/lab-03-pods-con-serviceaccounts.md`](./laboratorios/lab-03-pods-con-serviceaccounts.md)

---

## 8. Casos de Uso Prácticos

### Caso 1: Aplicación de Monitoreo

**Escenario**: Prometheus necesita descubrir pods y servicios automáticamente.

```yaml
# ejemplos/12-caso-uso-monitoreo.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus-reader
rules:
  # Descubrir servicios y endpoints
  - apiGroups: [""]
    resources: ["services", "endpoints", "pods", "nodes"]
    verbs: ["get", "list", "watch"]
  
  # Leer config de Ingresses
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus-reader-binding
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: monitoring
roleRef:
  kind: ClusterRole
  name: prometheus-reader
  apiGroup: rbac.authorization.k8s.io
```

### Caso 2: CI/CD Runner

**Escenario**: GitLab Runner o Jenkins necesita desplegar aplicaciones.

```yaml
# ejemplos/13-caso-uso-cicd.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gitlab-runner
  namespace: ci-cd
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer
  namespace: staging
rules:
  # Gestión completa de Deployments
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
  
  # Gestión de Services
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list", "create", "update", "patch"]
  
  # Lectura de Pods para verificar estado
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: gitlab-runner-deployer
  namespace: staging
subjects:
  - kind: ServiceAccount
    name: gitlab-runner
    namespace: ci-cd
roleRef:
  kind: Role
  name: deployer
  apiGroup: rbac.authorization.k8s.io
```

### Caso 3: Aplicación con Acceso a ConfigMaps

**Escenario**: Aplicación que lee configuración dinámica.

```yaml
# ejemplos/14-caso-uso-config-reader.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: config-reader-app
  namespace: produccion
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: configmap-reader
  namespace: produccion
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]
  
  # NO incluir secrets - principio de mínimo privilegio
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: config-reader-binding
  namespace: produccion
subjects:
  - kind: ServiceAccount
    name: config-reader-app
    namespace: produccion
roleRef:
  kind: Role
  name: configmap-reader
  apiGroup: rbac.authorization.k8s.io
```

### Caso 4: Operador de Kubernetes

**Escenario**: Custom operator que gestiona recursos personalizados.

```yaml
# ejemplos/15-caso-uso-operator.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: database-operator
  namespace: operators
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: database-operator-role
rules:
  # Gestión de CRDs
  - apiGroups: ["apiextensions.k8s.io"]
    resources: ["customresourcedefinitions"]
    verbs: ["get", "list", "watch"]
  
  # Gestión de recursos propios
  - apiGroups: ["databases.example.com"]
    resources: ["databases", "databases/status"]
    verbs: ["*"]
  
  # Crear StatefulSets y Services
  - apiGroups: ["apps"]
    resources: ["statefulsets"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
  
  - apiGroups: [""]
    resources: ["services", "persistentvolumeclaims"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: database-operator-binding
subjects:
  - kind: ServiceAccount
    name: database-operator
    namespace: operators
roleRef:
  kind: ClusterRole
  name: database-operator-role
  apiGroup: rbac.authorization.k8s.io
```

### Caso 5: Service Account con Azure Workload Identity

**Escenario**: Integración con Azure AD para acceder a recursos de Azure.

```yaml
# ejemplos/16-caso-uso-azure-workload-identity.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: azure-storage-app
  namespace: produccion
  annotations:
    # Federated identity con Azure AD
    azure.workload.identity/client-id: "12345678-1234-1234-1234-123456789012"
    azure.workload.identity/tenant-id: "87654321-4321-4321-4321-210987654321"
  labels:
    azure.workload.identity/use: "true"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-storage-app
  namespace: produccion
spec:
  replicas: 2
  selector:
    matchLabels:
      app: storage-app
  template:
    metadata:
      labels:
        app: storage-app
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: azure-storage-app
      containers:
      - name: app
        image: myapp/azure-client:v1.0
        env:
        - name: AZURE_CLIENT_ID
          value: "12345678-1234-1234-1234-123456789012"
        - name: AZURE_TENANT_ID
          value: "87654321-4321-4321-4321-210987654321"
        - name: AZURE_FEDERATED_TOKEN_FILE
          value: /var/run/secrets/azure/tokens/azure-identity-token
        volumeMounts:
        - name: azure-identity-token
          mountPath: /var/run/secrets/azure/tokens
          readOnly: true
      volumes:
      - name: azure-identity-token
        projected:
          sources:
          - serviceAccountToken:
              path: azure-identity-token
              expirationSeconds: 3600
              audience: api://AzureADTokenExchange
```

> 🔬 **Laboratorio**: Para implementar estos casos de uso, consulta [`laboratorios/lab-04-casos-uso-practicos.md`](./laboratorios/lab-04-casos-uso-practicos.md)

---

## 9. Mejores Prácticas y Seguridad

### Principios Fundamentales

#### 1. Principio de Mínimo Privilegio

**❌ MAL - Permisos excesivos**:
```yaml
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
```

**✅ BIEN - Permisos específicos**:
```yaml
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```

#### 2. Service Accounts Dedicados

**❌ MAL - Reutilizar el SA default**:
```yaml
spec:
  # Usa default implícitamente - no recomendado
  containers:
  - name: app
    image: myapp:v1
```

**✅ BIEN - SA específico por aplicación**:
```yaml
spec:
  serviceAccountName: monitoring-app
  containers:
  - name: app
    image: myapp:v1
```

#### 3. Namespaces para Aislamiento

```yaml
# Separar por namespace y entorno
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-api
  namespace: produccion  # Aislado por namespace
```

### Checklist de Seguridad

✅ **Hacer**:
- Crear un Service Account por aplicación
- Usar Roles (namespace-scoped) en lugar de ClusterRoles cuando sea posible
- Revisar permisos regularmente
- Usar tokens proyectados con expiración
- Auditar el uso de Service Accounts
- Deshabilitar `automountServiceAccountToken` cuando no se necesite
- Usar labels y annotations para documentar propósito

❌ **No hacer**:
- Dar permisos de `cluster-admin` a Service Accounts
- Usar el Service Account `default` para aplicaciones
- Dar acceso a Secrets sin necesidad
- Usar verbos `*` (todos) en Rules
- Compartir Service Accounts entre aplicaciones no relacionadas

### Auditoría de Permisos

```bash
# Ver qué puede hacer un Service Account
kubectl auth can-i --list --as=system:serviceaccount:default:mi-app

# Verificar permiso específico
kubectl auth can-i get pods \
  --as=system:serviceaccount:desarrollo:pod-reader \
  -n desarrollo

# Listar todos los RoleBindings de un Service Account
kubectl get rolebindings --all-namespaces \
  -o json | jq '.items[] | select(.subjects[]?.name=="mi-app")'
```

### Rotación de Tokens

```bash
# Eliminar Secret antiguo (Kubernetes creará uno nuevo)
kubectl delete secret mi-app-token-abc123

# Verificar nuevo secret generado
kubectl get sa mi-app -o yaml

# Reiniciar pods para que usen el nuevo token
kubectl rollout restart deployment mi-deployment
```

### Deshabilitar Service Account cuando no se necesita

```yaml
# ejemplos/17-pod-sin-sa.yaml
# Para pods que NO necesitan acceder a la API
apiVersion: v1
kind: Pod
metadata:
  name: aplicacion-estatica
spec:
  # Deshabilitar completamente el Service Account
  automountServiceAccountToken: false
  
  containers:
  - name: nginx
    image: nginx:alpine
```

### Network Policies para Mayor Seguridad

Combinar Service Accounts con Network Policies:

```yaml
# ejemplos/18-networkpolicy-sa.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-api-access
  namespace: produccion
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Egress
  egress:
  # Permitir DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Bloquear acceso a API server
  # (frontend no necesita acceder a la API)
```

### Pod Security Standards

```yaml
# ejemplos/19-pod-security-standards.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: aplicaciones-restringidas
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
# Los pods en este namespace tendrán restricciones adicionales
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-restricted
  namespace: aplicaciones-restringidas
```

### Ejemplo: Configuración Segura Completa

```yaml
# ejemplos/20-configuracion-segura-completa.yaml
# Service Account con configuración de seguridad completa
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secure-app
  namespace: produccion
  labels:
    app: secure-app
    security-level: high
  annotations:
    description: "SA para aplicación crítica con permisos mínimos"
automountServiceAccountToken: true
---
# Role con permisos mínimos necesarios
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secure-app-role
  namespace: produccion
rules:
  # Solo lo necesario - lectura de ConfigMaps específicos
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["app-config"]  # Solo este ConfigMap específico
    verbs: ["get"]
---
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secure-app-binding
  namespace: produccion
subjects:
  - kind: ServiceAccount
    name: secure-app
    namespace: produccion
roleRef:
  kind: Role
  name: secure-app-role
  apiGroup: rbac.authorization.k8s.io
---
# Deployment con todas las mejores prácticas
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: produccion
spec:
  replicas: 3
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      serviceAccountName: secure-app
      
      # Security Context a nivel de pod
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
        seccompProfile:
          type: RuntimeDefault
      
      containers:
      - name: app
        image: myapp/secure:v1.0
        
        # Security Context a nivel de contenedor
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        # Token proyectado con expiración
        volumeMounts:
        - name: token
          mountPath: /var/run/secrets/tokens
          readOnly: true
        
        # Resources limits
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      
      volumes:
      - name: token
        projected:
          sources:
          - serviceAccountToken:
              path: token
              expirationSeconds: 3600
              audience: api
```

---

## 10. Troubleshooting

### Problemas Comunes y Soluciones

#### Problema 1: "Error: Forbidden"

**Síntoma**:
```
Error from server (Forbidden): pods is forbidden: 
User "system:serviceaccount:default:mi-app" cannot list resource "pods"
```

**Causa**: El Service Account no tiene permisos.

**Solución**:
```bash
# Verificar permisos actuales
kubectl auth can-i list pods --as=system:serviceaccount:default:mi-app

# Verificar RoleBindings
kubectl get rolebindings -o wide | grep mi-app
kubectl get clusterrolebindings -o wide | grep mi-app

# Si no existe, crear Role y RoleBinding
kubectl create role pod-reader --verb=get,list --resource=pods
kubectl create rolebinding mi-app-binding \
  --role=pod-reader \
  --serviceaccount=default:mi-app
```

#### Problema 2: Token No Montado en el Pod

**Síntoma**:
```bash
# Dentro del pod
ls /var/run/secrets/kubernetes.io/serviceaccount/
# No existe o está vacío
```

**Causas posibles**:
1. `automountServiceAccountToken: false` en SA o Pod
2. El pod no especifica un SA válido

**Solución**:
```bash
# Verificar configuración del SA
kubectl get sa mi-app -o yaml | grep automount

# Verificar configuración del pod
kubectl get pod mi-pod -o yaml | grep -A5 serviceAccount

# Recrear pod con configuración correcta
kubectl delete pod mi-pod
kubectl apply -f pod-correcto.yaml
```

#### Problema 3: Service Account No Existe

**Síntoma**:
```
Error: error when creating pod: serviceaccounts "mi-app" not found
```

**Solución**:
```bash
# Verificar si existe
kubectl get sa mi-app -n mi-namespace

# Crear si no existe
kubectl create serviceaccount mi-app -n mi-namespace

# O aplicar desde manifest
kubectl apply -f serviceaccount.yaml
```

#### Problema 4: Token Expirado

**Síntoma**:
```
Unauthorized: Token has expired
```

**Solución**:
```bash
# Para tokens proyectados, se renuevan automáticamente
# Para tokens legacy, eliminar el secret
kubectl delete secret mi-app-token-xyz

# Reiniciar pods
kubectl rollout restart deployment mi-deployment
```

#### Problema 5: Permisos en Namespace Incorrecto

**Síntoma**: Los permisos funcionan en un namespace pero no en otro.

**Causa**: RoleBinding está en namespace diferente.

**Solución**:
```bash
# Verificar namespace del RoleBinding
kubectl get rolebinding -A | grep mi-app

# Role y RoleBinding deben estar en el mismo namespace
# O usar ClusterRole + ClusterRoleBinding para permisos globales
```

### Comandos de Diagnóstico

```bash
# Ver todos los Service Accounts
kubectl get sa --all-namespaces

# Describir Service Account con detalles
kubectl describe sa mi-app

# Ver secrets asociados
kubectl get sa mi-app -o jsonpath='{.secrets[*].name}'

# Ver YAML completo del SA
kubectl get sa mi-app -o yaml

# Listar todos los Roles
kubectl get roles --all-namespaces

# Listar todos los RoleBindings
kubectl get rolebindings --all-namespaces

# Ver qué puede hacer un SA específico
kubectl auth can-i --list \
  --as=system:serviceaccount:default:mi-app \
  -n default

# Probar permiso específico
kubectl auth can-i create deployments \
  --as=system:serviceaccount:default:mi-app \
  -n default

# Ver eventos relacionados con autenticación
kubectl get events --sort-by='.lastTimestamp' | grep -i auth
```

### Debug desde un Pod

```yaml
# ejemplos/21-debug-pod.yaml
# Pod de debug con herramientas útiles
apiVersion: v1
kind: Pod
metadata:
  name: debug-sa
  namespace: default
spec:
  serviceAccountName: mi-app
  containers:
  - name: debug
    image: nicolaka/netshoot:latest
    command:
      - sleep
      - "3600"
```

```bash
# Ejecutar comandos de debug
kubectl exec -it debug-sa -- bash

# Dentro del pod:
# Ver token
cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Probar acceso a la API
curl -k -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  https://kubernetes.default.svc/api/v1/namespaces/default/pods

# Instalar kubectl en el pod
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
./kubectl get pods
```

### Logs y Auditoría

```bash
# Ver logs del API server (en clusters gestionados puede no estar disponible)
kubectl logs -n kube-system kube-apiserver-xxx | grep -i "serviceaccount"

# En AKS, revisar logs de diagnóstico
# (requiere configuración de Azure Monitor)

# Ver eventos de autorizacion fallida
kubectl get events --all-namespaces --field-selector type=Warning | grep Forbidden
```

> 🔬 **Laboratorio**: Para practicar troubleshooting, consulta [`laboratorios/lab-05-troubleshooting.md`](./laboratorios/lab-05-troubleshooting.md)

---

## Conclusiones y Próximos Pasos

### Resumen del Módulo

En este módulo hemos aprendido:

✅ **Conceptos fundamentales**:
- Qué son los Service Accounts y por qué son diferentes de los usuarios
- Cómo Kubernetes gestiona automáticamente tokens para aplicaciones
- La arquitectura de autenticación y autorización para pods

✅ **Implementación práctica**:
- Crear y gestionar Service Accounts
- Asignar permisos usando Roles y RoleBindings
- Configurar pods y deployments con Service Accounts
- Trabajar con tokens y acceso a la API

✅ **Seguridad y mejores prácticas**:
- Principio de mínimo privilegio
- Auditoría de permisos
- Configuración segura de Service Accounts
- Troubleshooting de problemas comunes

### Diferencias Clave: Módulo 17 vs Módulo 18

| Concepto | Módulo 17 | Módulo 18 |
|----------|-----------|-----------|
| **Identidad** | Usuarios y Grupos | Service Accounts |
| **Para** | Personas | Aplicaciones/Pods |
| **Autenticación** | Certificados | Tokens JWT |
| **Gestión** | Manual | API de Kubernetes |
| **Uso** | kubectl externo | Dentro del cluster |

### Integración de Conceptos

```
RBAC Completo = Módulo 17 + Módulo 18

┌─────────────────────────────────────────┐
│     Acceso al Cluster Kubernetes        │
│                                          │
│  Externo              │      Interno     │
│  (Módulo 17)          │    (Módulo 18)   │
│                       │                  │
│  Usuarios ────────────┼─── Service       │
│  Grupos               │    Accounts      │
│         │             │        │         │
│         │             │        │         │
│         ▼             │        ▼         │
│    Certificados       │     Tokens       │
│         │             │        │         │
│         └─────────────┴────────┘         │
│                 │                         │
│                 ▼                         │
│         Roles/ClusterRoles                │
│                 │                         │
│                 ▼                         │
│         RoleBindings                      │
│                 │                         │
│                 ▼                         │
│         Permisos Efectivos                │
└─────────────────────────────────────────┘
```

### Próximos Pasos

Después de completar este módulo, estás preparado para:

1. **Implementar seguridad en aplicaciones reales**:
   - Configurar Service Accounts para tus deployments
   - Establecer políticas de seguridad en tu cluster
   - Auditar y monitorear accesos

2. **Explorar temas avanzados**:
   - Pod Security Policies / Pod Security Standards
   - Azure Workload Identity para integración con Azure AD
   - OPA (Open Policy Agent) para políticas avanzadas
   - Service Mesh (Istio, Linkerd) para autenticación mTLS

3. **Mejores prácticas de DevOps**:
   - Automatizar creación de Service Accounts con GitOps
   - Integrar RBAC en pipelines de CI/CD
   - Implementar políticas como código

### Recursos Adicionales

**Documentación oficial**:
- [Service Accounts - Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [RBAC Authorization - Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Managing Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)

**Azure específico**:
- [Azure Workload Identity](https://azure.github.io/azure-workload-identity/)
- [AKS Security Best Practices](https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-cluster-security)

**Herramientas útiles**:
- [kubectl-who-can](https://github.com/aquasecurity/kubectl-who-can): Plugin para auditar permisos
- [rbac-lookup](https://github.com/FairwindsOps/rbac-lookup): Herramienta de análisis de RBAC
- [kube-bench](https://github.com/aquasecurity/kube-bench): Auditoría de seguridad de clusters

### Estructura de Archivos del Módulo

```
modulo-18-rbac-serviceaccounts/
├── README.md (este archivo)
├── ejemplos/
│   ├── 01-serviceaccount-completo.yaml
│   ├── 02-serviceaccount-basico.yaml
│   ├── 03-serviceaccounts-por-ambiente.yaml
│   ├── 04-pod-con-serviceaccount.yaml
│   ├── 05-pod-token-proyectado.yaml
│   ├── 06-rbac-completo/
│   │   ├── 01-serviceaccount.yaml
│   │   ├── 02-role.yaml
│   │   └── 03-rolebinding.yaml
│   ├── 07-clusterrole-serviceaccount.yaml
│   ├── 08-pod-custom-sa.yaml
│   ├── 09-deployment-con-sa.yaml
│   ├── 10-pod-api-access.yaml
│   ├── 11-python-api-client/
│   │   ├── deployment.yaml
│   │   └── app.py
│   ├── 12-caso-uso-monitoreo.yaml
│   ├── 13-caso-uso-cicd.yaml
│   ├── 14-caso-uso-config-reader.yaml
│   ├── 15-caso-uso-operator.yaml
│   ├── 16-caso-uso-azure-workload-identity.yaml
│   ├── 17-pod-sin-sa.yaml
│   ├── 18-networkpolicy-sa.yaml
│   ├── 19-pod-security-standards.yaml
│   ├── 20-configuracion-segura-completa.yaml
│   └── 21-debug-pod.yaml
└── laboratorios/
    ├── lab-01-crear-serviceaccounts.md
    ├── lab-02-permisos-serviceaccounts.md
    ├── lab-03-pods-con-serviceaccounts.md
    ├── lab-04-casos-uso-practicos.md
    └── lab-05-troubleshooting.md
```

---

## Glosario Específico del Módulo

- **Service Account (SA)**: Identidad para procesos y aplicaciones dentro de Kubernetes
- **Token JWT**: JSON Web Token usado para autenticar Service Accounts
- **Projected Token**: Token con expiración y audiencia específica (más seguro)
- **automountServiceAccountToken**: Configuración que controla si el token se monta automáticamente
- **imagePullSecrets**: Secrets usados para autenticar con registros de imágenes privados
- **system:serviceaccount**: Prefijo usado en identificadores de Service Accounts
- **In-cluster config**: Configuración que permite a pods acceder a la API desde dentro del cluster

---

## Agradecimientos

Gracias por completar el Módulo 18. Ahora tienes los conocimientos necesarios para implementar autenticación y autorización robusta para tus aplicaciones en Kubernetes.

**¡No olvides practicar con los laboratorios!** La mejor forma de aprender es experimentando con ejemplos reales.

---

**Última actualización**: Noviembre 2025  
**Autor**: Curso Kubernetes - Arquitectura y Operaciones  
**Licencia**: Uso educativo
