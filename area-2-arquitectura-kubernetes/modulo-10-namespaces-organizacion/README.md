# Módulo 10: Namespaces y Organización

## Índice

1. [Introducción](#introducción)
2. [¿Qué son los Namespaces?](#qué-son-los-namespaces)
3. [Namespaces del Sistema](#namespaces-del-sistema)
4. [Cuándo Usar Namespaces](#cuándo-usar-namespaces)
5. [Gestión de Namespaces](#gestión-de-namespaces)
6. [Contextos y Kubeconfig](#contextos-y-kubeconfig)
7. [DNS en Namespaces](#dns-en-namespaces)
8. [Recursos Namespaced vs Cluster-Scoped](#recursos-namespaced-vs-cluster-scoped)
9. [ResourceQuota](#resourcequota)
10. [LimitRange](#limitrange)
11. [Aislamiento y Seguridad](#aislamiento-y-seguridad)
12. [Patrones de Organización](#patrones-de-organización)
13. [Best Practices](#best-practices)
14. [Troubleshooting](#troubleshooting)
15. [Ejemplos Prácticos](#ejemplos-prácticos)
16. [Laboratorios](#laboratorios)
17. [Recursos Adicionales](#recursos-adicionales)

---

## Introducción

Los **Namespaces** son una característica fundamental de Kubernetes que permite dividir un **clúster físico** en múltiples **clústeres virtuales**. Son esenciales para:

✅ **Organizar recursos** por equipo, proyecto o entorno  
✅ **Aislar lógicamente** aplicaciones y equipos  
✅ **Aplicar cuotas de recursos** (CPU, memoria, storage)  
✅ **Gestionar permisos** con RBAC por namespace  
✅ **Multi-tenancy**: Compartir un clúster entre múltiples usuarios/equipos

> **Analogía**: Un namespace es como una "carpeta" o "directorio" que agrupa recursos relacionados, pero con capacidad de aplicar políticas, cuotas y permisos.

### Diagrama ASCII: Clúster con Namespaces

```
┌────────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                          │
│                                                                │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │  Namespace:      │  │  Namespace:      │  │  Namespace:  │  │
│  │  development     │  │  staging         │  │  production  │  │
│  │                  │  │                  │  │              │  │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────┐ │  │
│  │ │ Deployment   │ │  │ │ Deployment   │ │  │ │Deployment│ │  │
│  │ │ app-v1       │ │  │ │ app-v1       │ │  │ │ app-v2   │ │  │
│  │ │ replicas: 1  │ │  │ │ replicas: 2  │ │  │ │replicas:5│ │  │
│  │ └──────────────┘ │  │ └──────────────┘ │  │ └──────────┘ │  │
│  │                  │  │                  │  │              │  │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────┐ │  │
│  │ │ Service      │ │  │ │ Service      │ │  │ │ Service  │ │  │
│  │ │ app-service  │ │  │ │ app-service  │ │  │ │app-svc   │ │  │
│  │ └──────────────┘ │  │ └──────────────┘ │  │ └──────────┘ │  │
│  │                  │  │                  │  │              │  │
│  │ ResourceQuota:   │  │ ResourceQuota:   │  │ResourceQuota │  │
│  │ CPU: 2 cores     │  │ CPU: 4 cores     │  │CPU:10 cores  │  │
│  │ Memory: 4Gi      │  │ Memory: 8Gi      │  │Memory: 20Gi  │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Namespace: kube-system (sistema)                        │  │
│  │  - kube-apiserver, kube-scheduler, etcd, etc.            │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

---

## ¿Qué son los Namespaces?

### Definición

Un **Namespace** es un mecanismo de **particionado virtual** que proporciona:

1. **Alcance de nombres** (name scope): Los nombres de recursos deben ser únicos **dentro** del namespace, pero pueden repetirse **entre** namespaces
2. **Aislamiento lógico**: Separación conceptual de recursos
3. **Punto de aplicación de políticas**: ResourceQuotas, LimitRanges, NetworkPolicies, RBAC

### ¿Qué hace un Namespace?

✅ **Organiza recursos**: Agrupa Pods, Services, Deployments, etc.  
✅ **Permite cuotas**: Limita CPU, memoria, storage por namespace  
✅ **Facilita RBAC**: Permisos por namespace (usuarios/equipos)  
✅ **DNS scoping**: Resolución DNS scoped al namespace  
✅ **Multi-tenancy**: Equipos/proyectos comparten clúster de forma aislada

### ¿Qué NO hace un Namespace?

❌ **NO es una barrera de seguridad completa**: Por defecto, los Pods de diferentes namespaces pueden comunicarse entre sí  
❌ **NO aísla la red automáticamente**: Se necesitan NetworkPolicies  
❌ **NO separa nodos físicos**: Todos los namespaces usan los mismos nodos  
❌ **NO es un clúster separado**: Comparten mismo API server, etcd, etc.

> **Importante**: Para aislamiento de red real, combina Namespaces con **NetworkPolicies**. Para aislamiento de seguridad, usa **RBAC**.

---

## Namespaces del Sistema

Kubernetes crea **4 namespaces** por defecto al iniciar un clúster:

### 1. `default`

**Propósito**: Namespace predeterminado para objetos sin namespace especificado.

```bash
# Crear un Pod sin especificar namespace → va a 'default'
kubectl run nginx --image=nginx
```

**Características**:
- Namespace por defecto para `kubectl` si no se especifica `-n`
- **Recomendación**: NO usar en producción, crear namespaces específicos

### 2. `kube-system`

**Propósito**: Para objetos creados por el **sistema de Kubernetes**.

**Contiene**:
- `kube-apiserver`: API server
- `kube-scheduler`: Scheduler
- `kube-controller-manager`: Controller manager
- `etcd`: Base de datos del clúster
- `kube-proxy`: Proxy de red
- `coredns`: DNS del clúster

```bash
kubectl get pods -n kube-system
```

⚠️ **Precaución**: **NO crear recursos propios** en `kube-system`. Está reservado para componentes del sistema.

### 3. `kube-public`

**Propósito**: Namespace **legible públicamente** por todos (incluso usuarios no autenticados).

**Uso**: Recursos que deben ser públicamente visibles en el clúster.

**Características**:
- Contiene ConfigMap `cluster-info` con información del clúster
- Poco usado en la práctica

### 4. `kube-node-lease`

**Propósito**: Para objetos **Lease** asociados a cada nodo (heartbeat).

**Uso**: Mecanismo de detección de fallos de nodos (introducido en K8s 1.14+).

**Características**:
- Mejora el rendimiento del heartbeat de nodos
- Cada nodo tiene un Lease que actualiza periódicamente

---

## Cuándo Usar Namespaces

### ✅ Usar Namespaces cuando:

| Escenario | Ejemplo |
|-----------|---------|
| **Múltiples equipos** | `team-frontend`, `team-backend`, `team-data` |
| **Múltiples entornos** | `development`, `staging`, `production` |
| **Múltiples proyectos** | `project-alpha`, `project-beta` |
| **Multi-tenancy** | `tenant-companyA`, `tenant-companyB` |
| **Separación por ciclo de vida** | `ci-cd`, `monitoring`, `logging` |

### ❌ NO usar Namespaces para:

| Caso | Solución Correcta |
|------|-------------------|
| Separar **versiones** de la misma app | Usar **Labels** (`version: v1`, `version: v2`) |
| Clúster con **pocos usuarios** (<10) | Usar Labels para organización simple |
| Separar **recursos muy relacionados** | Mantener en mismo namespace con Labels |

### Ejemplo: Namespaces por Entorno

```bash
# Estructura típica
development/
  ├── app-deployment
  ├── app-service
  └── database-statefulset

staging/
  ├── app-deployment
  ├── app-service
  └── database-statefulset

production/
  ├── app-deployment
  ├── app-service
  └── database-statefulset
```

---

## Gestión de Namespaces

### Listar Namespaces

```bash
# Listar todos los namespaces
kubectl get namespaces
# o abreviado:
kubectl get ns

# Con labels
kubectl get ns --show-labels

# Salida ejemplo:
# NAME              STATUS   AGE
# default           Active   10d
# kube-system       Active   10d
# kube-public       Active   10d
# kube-node-lease   Active   10d
```

### Crear Namespaces

#### Método 1: Imperativo (kubectl)

```bash
# Crear namespace
kubectl create namespace development
# o abreviado:
kubectl create ns development

# Crear con labels
kubectl create ns staging --labels=env=staging,team=backend
```

#### Método 2: Declarativo (YAML)

Ver: [`ejemplos/01-basico/namespace-basic.yaml`](ejemplos/01-basico/namespace-basic.yaml)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    environment: dev
    team: frontend
```

```bash
kubectl apply -f namespace-basic.yaml
```

### Describir Namespace

```bash
kubectl describe namespace development

# Salida incluye:
# - Labels
# - Status
# - ResourceQuota (si existe)
# - LimitRange (si existe)
```

### Eliminar Namespace

```bash
kubectl delete namespace development

# ⚠️ ATENCIÓN: Elimina TODOS los recursos dentro del namespace
# Confirmación automática no requerida, ¡cuidado!
```

**Comportamiento al eliminar**:
1. Namespace entra en estado `Terminating`
2. Se eliminan **todos los recursos** del namespace (Pods, Services, etc.)
3. Finalizers se ejecutan
4. Namespace se elimina completamente

### Trabajar en un Namespace Específico

```bash
# Opción 1: Flag -n en cada comando
kubectl get pods -n development
kubectl create deployment app --image=nginx -n development

# Opción 2: Establecer namespace por defecto para el contexto actual
kubectl config set-context --current --namespace=development

# Verificar
kubectl config view --minify | grep namespace:

# Ahora todos los comandos usan 'development' por defecto
kubectl get pods  # Lista pods de 'development'
```

---

## Contextos y Kubeconfig

### ¿Qué es un Contexto?

Un **contexto** en Kubernetes es una combinación de:
1. **Cluster**: Qué clúster de Kubernetes usar (URL del API server)
2. **User**: Qué credenciales usar (certificados, tokens)
3. **Namespace**: Namespace por defecto

```
Contexto = Cluster + User + Namespace (opcional)
```

### Archivo Kubeconfig

Ubicación: `~/.kube/config`

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://192.168.1.100:6443
  name: my-cluster
users:
- name: admin
  user:
    client-certificate: /path/to/cert
    client-key: /path/to/key
contexts:
- context:
    cluster: my-cluster
    user: admin
    namespace: development  # Namespace por defecto
  name: dev-context
current-context: dev-context
```

### Gestión de Contextos

```bash
# Ver contextos disponibles
kubectl config get-contexts

# Ver contexto actual
kubectl config current-context

# Cambiar de contexto
kubectl config use-context dev-context

# Crear nuevo contexto
kubectl config set-context staging-context \
  --cluster=my-cluster \
  --user=admin \
  --namespace=staging

# Establecer namespace para contexto actual
kubectl config set-context --current --namespace=production

# Eliminar un contexto
kubectl config delete-context old-context
```

### Herramientas Útiles

#### kubectx / kubens

```bash
# Instalar (Linux)
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Uso
kubectx                    # Listar contextos
kubectx dev-context        # Cambiar a contexto
kubectx -                  # Volver al contexto anterior

kubens                     # Listar namespaces
kubens development         # Cambiar a namespace
kubens -                   # Volver al namespace anterior
```

---

## DNS en Namespaces

### Resolución DNS Interna

Cuando creas un **Service** en Kubernetes, se crea una entrada DNS automática:

```
<service-name>.<namespace-name>.svc.cluster.local
```

#### Ejemplo

```yaml
# Service en namespace 'development'
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: development
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
```

**DNS generado**:
- **FQDN**: `database.development.svc.cluster.local`
- **Desde mismo namespace**: `database`
- **Desde otro namespace**: `database.development` o FQDN completo

### Escenarios de Resolución DNS

#### Escenario 1: Mismo Namespace

```bash
# Pod en 'development' accede a Service en 'development'
curl http://database:5432  # ✅ Funciona (short name)
```

#### Escenario 2: Diferente Namespace

```bash
# Pod en 'production' accede a Service en 'development'
curl http://database:5432                              # ❌ No funciona
curl http://database.development:5432                  # ✅ Funciona
curl http://database.development.svc.cluster.local:5432  # ✅ Funciona (FQDN)
```

### Tabla de Resolución DNS

| Desde Namespace | A Service | DNS a usar | ¿Funciona? |
|-----------------|-----------|------------|------------|
| development | database (development) | `database` | ✅ Sí |
| development | database (development) | `database.development` | ✅ Sí |
| production | database (development) | `database` | ❌ No |
| production | database (development) | `database.development` | ✅ Sí |
| Cualquiera | database (development) | `database.development.svc.cluster.local` | ✅ Sí (FQDN) |

### Diagrama ASCII: DNS en Namespaces

```
Namespace: development
├── Service: api
│   DNS: api.development.svc.cluster.local
├── Service: database
│   DNS: database.development.svc.cluster.local

Namespace: production
├── Service: api
│   DNS: api.production.svc.cluster.local
├── Service: database
│   DNS: database.production.svc.cluster.local

Comunicación:
development/api → database          ✅ (mismo namespace)
development/api → database.production  ✅ (cross-namespace)
production/api → database.development  ✅ (cross-namespace)
```

---

## Recursos Namespaced vs Cluster-Scoped

No todos los recursos de Kubernetes están en un namespace.

### Recursos Namespaced (en un namespace)

```bash
# Listar recursos namespaced
kubectl api-resources --namespaced=true

# Ejemplos:
- Pods
- Services
- Deployments
- ReplicaSets
- ConfigMaps
- Secrets
- PersistentVolumeClaims (PVC)
- ServiceAccounts
- Ingress
- Jobs
- CronJobs
```

### Recursos Cluster-Scoped (sin namespace)

```bash
# Listar recursos cluster-scoped
kubectl api-resources --namespaced=false

# Ejemplos:
- Nodes
- Namespaces
- PersistentVolumes (PV)
- StorageClasses
- ClusterRoles
- ClusterRoleBindings
- CustomResourceDefinitions (CRD)
```

### ¿Por qué algunos recursos no están en namespaces?

| Recurso | Razón |
|---------|-------|
| **Nodes** | Son recursos físicos del clúster, no lógicos |
| **PersistentVolumes** | Pueden ser reclamados desde cualquier namespace |
| **Namespaces** | Son contenedores de recursos, no pueden estar dentro de sí mismos |
| **ClusterRoles** | Permisos que aplican a todo el clúster |

---

## ResourceQuota

### ¿Qué es ResourceQuota?

**ResourceQuota** es un objeto que **limita el consumo agregado de recursos** en un namespace. Permite:

✅ Limitar **CPU y memoria** total  
✅ Limitar **número de objetos** (Pods, Services, etc.)  
✅ Limitar **storage** (PVCs)  
✅ Prevenir que un namespace consuma **todos los recursos del clúster**

### Ejemplo de ResourceQuota

Ver: [`ejemplos/03-quotas/resourcequota-basic.yaml`](ejemplos/03-quotas/resourcequota-basic.yaml)

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: development
spec:
  hard:
    # CPU y Memoria
    requests.cpu: "4"        # Max 4 CPU cores solicitados
    requests.memory: 8Gi     # Max 8Gi memoria solicitada
    limits.cpu: "8"          # Max 8 CPU cores límite
    limits.memory: 16Gi      # Max 16Gi memoria límite
    
    # Número de objetos
    pods: "10"               # Max 10 Pods
    services: "5"            # Max 5 Services
    persistentvolumeclaims: "4"  # Max 4 PVCs
    
    # Storage
    requests.storage: 100Gi  # Max 100Gi storage total
```

### Aplicar ResourceQuota

```bash
kubectl apply -f resourcequota-basic.yaml

# Verificar
kubectl get resourcequota -n development
kubectl describe resourcequota compute-quota -n development
```

### Ver Uso de Recursos

```bash
kubectl describe ns development

# Salida incluye:
# Resource Quotas
#  Name:            compute-quota
#  Resource         Used  Hard
#  --------         ----  ----
#  limits.cpu       2     8
#  limits.memory    4Gi   16Gi
#  pods             3     10
#  requests.cpu     1     4
#  requests.memory  2Gi   8Gi
```

### Tipos de Límites en ResourceQuota

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| **requests.cpu** | CPU solicitada total | `requests.cpu: "4"` |
| **requests.memory** | Memoria solicitada total | `requests.memory: 8Gi` |
| **limits.cpu** | CPU límite total | `limits.cpu: "8"` |
| **limits.memory** | Memoria límite total | `limits.memory: 16Gi` |
| **requests.storage** | Storage total | `requests.storage: 100Gi` |
| **persistentvolumeclaims** | Número de PVCs | `persistentvolumeclaims: "4"` |
| **pods** | Número de Pods | `pods: "10"` |
| **services** | Número de Services | `services: "5"` |
| **count/deployments.apps** | Número de Deployments | `count/deployments.apps: "5"` |

### Comportamiento con ResourceQuota

⚠️ **Importante**: Si un namespace tiene ResourceQuota, **todos los Pods deben especificar** `requests` y `limits` de CPU/memoria. De lo contrario, la creación falla.

```yaml
# ❌ Falla si hay ResourceQuota (falta requests/limits)
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx

# ✅ Funciona (especifica requests/limits)
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
```

---

## LimitRange

### ¿Qué es LimitRange?

**LimitRange** define **valores por defecto y rangos permitidos** para recursos individuales (Pods, Containers) en un namespace.

**Diferencia con ResourceQuota**:
- **ResourceQuota**: Límites **agregados** (total del namespace)
- **LimitRange**: Límites **por objeto** (por Pod/Container)

### Ejemplo de LimitRange

Ver: [`ejemplos/04-limits/limitrange-basic.yaml`](ejemplos/04-limits/limitrange-basic.yaml)

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: compute-limits
  namespace: development
spec:
  limits:
  # Límites para Pods
  - type: Pod
    max:
      cpu: "2"
      memory: "4Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
  
  # Límites para Containers
  - type: Container
    max:
      cpu: "1"
      memory: "2Gi"
    min:
      cpu: "10m"
      memory: "16Mi"
    default:  # Límites por defecto
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:  # Requests por defecto
      cpu: "100m"
      memory: "128Mi"
  
  # Límites para PVCs
  - type: PersistentVolumeClaim
    max:
      storage: "10Gi"
    min:
      storage: "1Gi"
```

### Aplicar LimitRange

```bash
kubectl apply -f limitrange-basic.yaml

# Verificar
kubectl get limitrange -n development
kubectl describe limitrange compute-limits -n development
```

### Funcionamiento de LimitRange

1. **Validación**: Rechaza Pods que excedan max o estén por debajo de min
2. **Defaults**: Aplica valores por defecto si no se especifican
3. **Enforcement**: Se aplica al crear el Pod (no retroactivo)

#### Ejemplo: Pod sin recursos especificados

```yaml
# Pod sin requests/limits
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: development
spec:
  containers:
  - name: nginx
    image: nginx

# ↓ LimitRange aplica valores por defecto ↓

# Pod después de aplicar LimitRange:
# resources:
#   requests:
#     cpu: "100m"
#     memory: "128Mi"
#   limits:
#     cpu: "500m"
#     memory: "512Mi"
```

---

## Aislamiento y Seguridad

### Niveles de Aislamiento

| Nivel | Mecanismo | Descripción |
|-------|-----------|-------------|
| **Lógico** | Namespaces | Separación de nombres y recursos |
| **Recursos** | ResourceQuota + LimitRange | Límites de CPU, memoria, storage |
| **Red** | NetworkPolicies | Aislamiento de tráfico entre Pods |
| **Acceso** | RBAC | Permisos por usuario/grupo/namespace |

### NetworkPolicies (Vista Previa)

Por defecto, **todos los Pods pueden comunicarse entre namespaces**. Para aislamiento de red:

```yaml
# Denegar todo el tráfico entrante en namespace 'production'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: production
spec:
  podSelector: {}  # Aplica a todos los Pods
  policyTypes:
  - Ingress
```

> **Nota**: NetworkPolicies se cubrirán en detalle en módulos posteriores.

### RBAC (Role-Based Access Control)

Limitar quién puede hacer qué en un namespace:

```yaml
# Role: permisos en namespace 'development'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: development
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments"]
  verbs: ["get", "list", "create", "update", "delete"]

---
# RoleBinding: asignar Role a usuario
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: development
subjects:
- kind: User
  name: john@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

> **Nota**: RBAC se cubrirá en profundidad en módulo 19.

---

## Patrones de Organización

### 1. Por Entorno

```
development/
  ├── app-deployment
  ├── app-service
  └── database

staging/
  ├── app-deployment
  ├── app-service
  └── database

production/
  ├── app-deployment (5 réplicas)
  ├── app-service
  └── database (HA)
```

**Ventajas**:
✅ Separación clara de entornos  
✅ Fácil promoción de código (dev → staging → prod)  
✅ Diferentes ResourceQuotas por entorno

**Desventajas**:
❌ Duplicación de manifiestos  
❌ Necesita estrategia de sincronización

### 2. Por Equipo

```
team-frontend/
  ├── web-app
  ├── api-gateway
  └── cdn-config

team-backend/
  ├── user-service
  ├── order-service
  └── payment-service

team-data/
  ├── etl-jobs
  ├── ml-models
  └── analytics
```

**Ventajas**:
✅ Autonomía de equipos  
✅ RBAC por equipo  
✅ Cuotas por equipo

**Desventajas**:
❌ Comunicación cross-namespace más compleja  
❌ Shared services requieren namespace compartido

### 3. Por Proyecto/Cliente (Multi-tenancy)

```
tenant-companyA/
  ├── app-deployment
  ├── database
  └── storage

tenant-companyB/
  ├── app-deployment
  ├── database
  └── storage
```

**Ventajas**:
✅ Aislamiento completo por cliente  
✅ Facturación por tenant (ResourceQuota)  
✅ Seguridad mejorada (NetworkPolicies + RBAC)

**Desventajas**:
❌ Mayor complejidad operativa  
❌ Requiere NetworkPolicies estrictas

### 4. Híbrido

```
# Namespaces de infraestructura
monitoring/     # Prometheus, Grafana
logging/        # ELK stack
ingress-nginx/  # Ingress controllers

# Namespaces de aplicación
prod-frontend/
prod-backend/
staging-frontend/
staging-backend/
```

---

## Best Practices

### ✅ Hacer

1. **Usar namespaces para organización lógica**
   ```bash
   # Crear namespaces por entorno/equipo/proyecto
   kubectl create ns development
   kubectl create ns staging
   kubectl create ns production
   ```

2. **Aplicar ResourceQuotas en todos los namespaces**
   ```yaml
   # Prevenir consumo excesivo de recursos
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: compute-quota
     namespace: development
   spec:
     hard:
       requests.cpu: "10"
       requests.memory: 20Gi
   ```

3. **Usar LimitRanges para defaults**
   ```yaml
   # Asegurar que todos los Pods tienen límites
   apiVersion: v1
   kind: LimitRange
   metadata:
     name: defaults
     namespace: development
   spec:
     limits:
     - type: Container
       default:
         cpu: "500m"
         memory: "512Mi"
   ```

4. **Labels consistentes**
   ```yaml
   metadata:
     name: development
     labels:
       environment: dev
       team: platform
       cost-center: engineering
   ```

5. **Documentar estructura de namespaces**
   ```markdown
   # Namespaces del Clúster
   
   ## Aplicación
   - `app-dev`: Desarrollo de aplicación
   - `app-staging`: Staging
   - `app-prod`: Producción
   
   ## Infraestructura
   - `monitoring`: Prometheus/Grafana
   - `logging`: ELK
   ```

### ❌ Evitar

1. **NO usar namespace 'default' en producción**
   ```bash
   # Mal
   kubectl run app --image=nginx  # va a 'default'
   
   # Bien
   kubectl run app --image=nginx -n production
   ```

2. **NO crear demasiados namespaces**
   ```bash
   # Mal: namespace por microservicio (excesivo)
   user-service-ns
   order-service-ns
   payment-service-ns
   
   # Bien: namespace por entorno o equipo
   backend-services-prod
   ```

3. **NO olvidar NetworkPolicies**
   ```yaml
   # Siempre combinar namespaces con NetworkPolicies para aislamiento real
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   # ...
   ```

4. **NO mezclar entornos en mismo namespace**
   ```bash
   # Mal
   app-dev-deployment
   app-prod-deployment  # ¡en el mismo namespace!
   
   # Bien
   development/app-deployment
   production/app-deployment
   ```

---

## Troubleshooting

### Problema 1: Pods no se crean (ResourceQuota)

**Síntoma**:
```bash
kubectl create deployment app --image=nginx -n development
# Error: exceeded quota: compute-quota
```

**Diagnóstico**:
```bash
kubectl describe ns development
# Ver: Resource Quotas - Used vs Hard

kubectl describe resourcequota -n development
```

**Solución**:
1. Eliminar Pods/recursos innecesarios
2. Aumentar quota
3. Especificar requests/limits más bajos

### Problema 2: Pods fallan al crear (LimitRange)

**Síntoma**:
```bash
# Error: Pod "nginx" is invalid: spec.containers[0].resources.requests: Invalid value
```

**Diagnóstico**:
```bash
kubectl describe limitrange -n development
```

**Solución**:
```yaml
# Ajustar recursos del Pod para cumplir con LimitRange
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "100m"  # Dentro del min/max
        memory: "128Mi"
```

### Problema 3: Service no resuelve DNS

**Síntoma**:
```bash
# Desde Pod en namespace 'production'
curl http://database:5432
# Error: could not resolve host
```

**Diagnóstico**:
```bash
# Verificar que el Service existe
kubectl get svc -n development

# Probar DNS completo
nslookup database.development.svc.cluster.local
```

**Solución**:
```bash
# Usar nombre correcto cross-namespace
curl http://database.development:5432
# o FQDN:
curl http://database.development.svc.cluster.local:5432
```

### Problema 4: Permisos denegados (RBAC)

**Síntoma**:
```bash
kubectl get pods -n production
# Error: User "john" cannot list pods in namespace "production"
```

**Diagnóstico**:
```bash
kubectl auth can-i list pods -n production --as=john
# no
```

**Solución**:
```yaml
# Crear Role y RoleBinding apropiados
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
# ...
```

---

## Ejemplos Prácticos

### Estructura de Ejemplos

```
ejemplos/
├── 01-basico/
│   ├── namespace-basic.yaml
│   ├── namespace-with-labels.yaml
│   └── deployment-multi-namespace.yaml
├── 02-contextos/
│   ├── kubeconfig-example.yaml
│   └── context-switching.sh
├── 03-quotas/
│   ├── resourcequota-basic.yaml
│   ├── resourcequota-advanced.yaml
│   └── quota-scope-example.yaml
├── 04-limits/
│   ├── limitrange-basic.yaml
│   ├── limitrange-container.yaml
│   └── limitrange-pvc.yaml
├── 05-organizacion/
│   ├── namespace-by-environment.yaml
│   ├── namespace-by-team.yaml
│   └── namespace-multi-tenant.yaml
└── README.md
```

Ver índice completo: [`ejemplos/README.md`](ejemplos/README.md)

---

## Laboratorios

### Lab 01: Fundamentos de Namespaces (35-40 min)

**Nivel**: Básico

**Objetivos**:
- Crear y gestionar namespaces
- Trabajar con contextos de kubectl
- Despliegue multi-namespace
- DNS resolution entre namespaces

📄 Ver laboratorio: [`laboratorios/lab-01-namespaces-basico.md`](laboratorios/lab-01-namespaces-basico.md)

### Lab 02: ResourceQuota y LimitRange (45-50 min)

**Nivel**: Intermedio

**Objetivos**:
- Configurar ResourceQuotas
- Implementar LimitRanges
- Testing de límites
- Monitoreo de uso de recursos

📄 Ver laboratorio: [`laboratorios/lab-02-quotas-limits.md`](laboratorios/lab-02-quotas-limits.md)

### Lab 03: Multi-Tenancy y Aislamiento (50-60 min)

**Nivel**: Avanzado

**Objetivos**:
- Arquitectura multi-tenant
- RBAC por namespace
- NetworkPolicies para aislamiento
- Monitoreo y auditoría

📄 Ver laboratorio: [`laboratorios/lab-03-multi-tenancy.md`](laboratorios/lab-03-multi-tenancy.md)

---

## Recursos Adicionales

### Documentación Oficial

- [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Configure Memory and CPU Quotas](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/quota-memory-cpu-namespace/)
- [Configure Default Memory/CPU Requests/Limits](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/)

### Herramientas

| Herramienta | Descripción | Instalación |
|-------------|-------------|-------------|
| **kubectx/kubens** | Cambio rápido de contextos/namespaces | `brew install kubectx` |
| **k9s** | CLI interactiva con soporte de namespaces | `brew install k9s` |
| **Lens** | IDE de Kubernetes con gestión visual | [https://k8slens.dev](https://k8slens.dev) |

### Comandos Útiles

```bash
# Listar todos los recursos en un namespace
kubectl get all -n development

# Contar objetos por namespace
kubectl get pods --all-namespaces --no-headers | awk '{print $1}' | sort | uniq -c

# Eliminar todos los recursos de un namespace (sin eliminar el namespace)
kubectl delete all --all -n development

# Ver eventos de un namespace
kubectl get events -n development --sort-by='.lastTimestamp'

# Comparar recursos entre namespaces
diff <(kubectl get pods -n dev -o name | sort) <(kubectl get pods -n prod -o name | sort)
```

---

## Conclusión

En este módulo has aprendido:

✅ **Conceptos fundamentales** de Namespaces  
✅ **Namespaces del sistema** (default, kube-system, etc.)  
✅ **Gestión** con kubectl (crear, listar, eliminar)  
✅ **Contextos** y kubeconfig  
✅ **DNS** en namespaces (resolución cross-namespace)  
✅ **ResourceQuota** para limitar recursos agregados  
✅ **LimitRange** para defaults y rangos por objeto  
✅ **Patrones de organización** (por entorno, equipo, proyecto)  
✅ **Best practices** y troubleshooting

### Próximos Pasos

1. **Práctica**: Completa los 3 laboratorios
2. **Profundizar**: Módulo 11 - Resource Limits en Pods
3. **Avanzar**: Módulo 12 - LimitRange (detalle)
4. **Módulo 13**: ResourceQuota (profundización)

---

**📚 Navegación del Curso**:
- ⬅️ Anterior: [Módulo 09 - Ingress y Acceso Externo](../modulo-09-ingress-external-access/README.md)
- ➡️ Siguiente: [Módulo 11 - Resource Limits en Pods](../modulo-11-resource-limits-pods/README.md)
- 🏠 [Volver al índice del curso](../../README.md)

---

**Autor**: Curso Kubernetes Avanzado  
**Última actualización**: Noviembre 2025  
**Versión**: Kubernetes 1.28+
