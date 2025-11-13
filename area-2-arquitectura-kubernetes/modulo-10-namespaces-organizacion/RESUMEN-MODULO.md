# 📚 RESUMEN - Módulo 10: Namespaces y Organización

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre **Namespaces** - la herramienta fundamental de Kubernetes para organizar recursos, implementar multi-tenancy y aplicar cuotas. Los namespaces dividen un clúster físico en múltiples clústeres virtuales, permitiendo aislamiento lógico, control de recursos y gestión de permisos.

**Duración**: 5 horas (teoría + labs)  
**Nivel**: Intermedio  
**Prerequisitos**: Pods, Deployments, Services

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo serás capaz de:

### Fundamentos
- ✅ Explicar qué son namespaces y por qué son necesarios
- ✅ Identificar namespaces del sistema y su propósito
- ✅ Diferenciar aislamiento lógico vs físico
- ✅ Entender casos de uso (multi-tenancy, entornos, equipos)

### Técnico
- ✅ Crear, listar y eliminar namespaces
- ✅ Configurar contextos de kubeconfig
- ✅ Trabajar con recursos en namespaces específicos
- ✅ Comprender DNS cross-namespace
- ✅ Diferenciar recursos namespaced vs cluster-scoped

### Avanzado
- ✅ Implementar ResourceQuotas (CPU, memoria, storage)
- ✅ Configurar LimitRanges (defaults, min, max)
- ✅ Aplicar NetworkPolicies para aislamiento
- ✅ Integrar RBAC con namespaces
- ✅ Diseñar arquitecturas multi-tenant

---

## 🗺️ Estructura de Aprendizaje

### Fase 1: Conceptos Fundamentales (30 min)
**Teoría**: Secciones 1-4 del README

**¿Qué son los Namespaces?**
- **Definición**: Particionado virtual del clúster
- **Propósito**: Organización, aislamiento lógico, aplicación de políticas
- **Alcance de nombres**: Nombres únicos dentro del namespace, pueden repetirse entre namespaces

**Analogía**: Namespace = "Carpeta" con capacidad de aplicar políticas, cuotas y permisos.

**Qué hace un Namespace**:
- ✅ Organiza recursos (Pods, Services, Deployments)
- ✅ Permite cuotas de recursos (CPU, memoria)
- ✅ Facilita RBAC (permisos por namespace)
- ✅ DNS scoping
- ✅ Multi-tenancy (equipos/proyectos aislados)

**Qué NO hace**:
- ❌ NO es barrera de seguridad completa (se necesita NetworkPolicy)
- ❌ NO aísla la red automáticamente
- ❌ NO separa nodos físicos
- ❌ NO es un clúster separado

**Namespaces del Sistema**:
```bash
kubectl get namespaces

# NAME              STATUS   AGE
# default           Active   10d    # Namespace por defecto
# kube-system       Active   10d    # Componentes del sistema (API, DNS, etc.)
# kube-public       Active   10d    # Recursos públicos (info del cluster)
# kube-node-lease   Active   10d    # Heartbeats de nodos
```

**Cuándo usar Namespaces**:
- ✅ Múltiples equipos/proyectos en el mismo clúster
- ✅ Separar entornos (dev, staging, prod) **si no hay clústers separados**
- ✅ Implementar multi-tenancy
- ✅ Aplicar cuotas de recursos por equipo
- ✅ Control de acceso RBAC granular

**Cuándo NO usar**:
- ❌ Clúster con <10 recursos (overkill)
- ❌ Solo 1 equipo/proyecto pequeño
- ❌ Separar entornos críticos (mejor clústers separados)

**Diagrama Mental**:
```
Clúster Kubernetes
├── namespace: development
│   ├── Pods: app-dev-*
│   ├── Services: app-svc
│   └── ResourceQuota: CPU 2 cores, RAM 4Gi
├── namespace: staging
│   ├── Pods: app-staging-*
│   ├── Services: app-svc
│   └── ResourceQuota: CPU 4 cores, RAM 8Gi
└── namespace: production
    ├── Pods: app-prod-*
    ├── Services: app-svc
    └── ResourceQuota: CPU 10 cores, RAM 20Gi
```

---

### Fase 2: Gestión de Namespaces (40 min)
**Teoría**: Secciones 5-6 del README

#### Comandos Básicos

**Listar Namespaces**:
```bash
# Listar todos
kubectl get namespaces
kubectl get ns  # Alias

# Con más detalles
kubectl get ns -o wide

# Ver en YAML
kubectl get ns default -o yaml
```

**Crear Namespace**:
```bash
# Imperativo
kubectl create namespace development
kubectl create ns staging

# Declarativo (YAML)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: prod
    team: platform
EOF
```

**Ver detalles**:
```bash
kubectl describe namespace development
```

**Eliminar Namespace**:
```bash
# ⚠️ ELIMINA TODOS LOS RECURSOS DENTRO
kubectl delete namespace development

# Forzar eliminación si se queda en Terminating
kubectl delete ns development --force --grace-period=0
```

#### Trabajar con Recursos en Namespaces

**Especificar namespace con -n**:
```bash
# Listar pods en namespace específico
kubectl get pods -n development

# Crear deployment en namespace
kubectl create deployment nginx --image=nginx -n staging

# Aplicar YAML en namespace
kubectl apply -f deployment.yaml -n production

# Ver todos los recursos en un namespace
kubectl get all -n development
```

**Listar recursos en todos los namespaces**:
```bash
kubectl get pods --all-namespaces
kubectl get pods -A  # Alias

# Con namespace en columna
kubectl get pods -A -o wide
```

#### Contextos y Kubeconfig

**Problema**: Escribir `-n namespace` cada vez es tedioso.

**Solución**: Cambiar el namespace por defecto del contexto.

**Ver contexto actual**:
```bash
kubectl config current-context
# minikube

kubectl config get-contexts
# *  minikube   minikube   minikube   default
```

**Cambiar namespace por defecto**:
```bash
# Cambiar a namespace 'development'
kubectl config set-context --current --namespace=development

# Verificar
kubectl config view --minify | grep namespace:
```

**Ahora todos los comandos usan 'development' por defecto**:
```bash
# Estos son equivalentes ahora:
kubectl get pods
kubectl get pods -n development
```

**Crear nuevo contexto con namespace específico**:
```bash
# Crear contexto 'dev' apuntando a namespace 'development'
kubectl config set-context dev \
  --cluster=minikube \
  --user=minikube \
  --namespace=development

# Cambiar a ese contexto
kubectl config use-context dev
```

**Plugins útiles**:
```bash
# kubens - Cambiar namespace fácilmente
brew install kubectx  # Instala kubectx y kubens

# Uso
kubens                    # Listar namespaces
kubens development        # Cambiar a development
kubens -                  # Volver al anterior
```

**Lab 1**: [Namespaces Básico](laboratorios/lab-01-namespaces-basico.md) - 40 min

---

### Fase 3: DNS en Namespaces (30 min)
**Teoría**: Sección 7 del README

**DNS Interno de Kubernetes**:

**Formato**:
```
<service>.<namespace>.svc.<cluster-domain>
```

**Default cluster domain**: `cluster.local`

**Ejemplos**:

**Mismo namespace**:
```bash
# Service 'backend' en namespace 'development'
# Desde otro Pod en 'development':
curl http://backend
curl http://backend.development
curl http://backend.development.svc.cluster.local  # FQDN completo
```

**Otro namespace**:
```bash
# Service 'api' en namespace 'production'
# Desde Pod en 'development':
curl http://api.production
curl http://api.production.svc.cluster.local
```

**Tabla de resolución**:
| Desde Namespace | A Service | URL Corta | URL Completa |
|-----------------|-----------|-----------|--------------|
| development | backend (development) | `backend` | `backend.development.svc.cluster.local` |
| development | api (production) | `api.production` | `api.production.svc.cluster.local` |
| staging | database (staging) | `database` | `database.staging.svc.cluster.local` |

**Test de DNS**:
```bash
# Crear pod temporal
kubectl run test --image=busybox -it --rm -- sh

# Dentro del pod
nslookup backend
nslookup backend.development
nslookup api.production.svc.cluster.local
```

---

### Fase 4: Recursos Namespaced vs Cluster-Scoped (20 min)
**Teoría**: Sección 8 del README

**Recursos Namespaced** (pertenecen a un namespace):
- Pods
- Services
- Deployments
- ReplicaSets
- ConfigMaps
- Secrets
- Ingress
- PersistentVolumeClaims

**Recursos Cluster-Scoped** (globales al clúster):
- Namespaces
- Nodes
- PersistentVolumes
- StorageClasses
- ClusterRoles
- ClusterRoleBindings

**Listar todos los tipos de recursos**:
```bash
# Recursos namespaced
kubectl api-resources --namespaced=true

# Recursos cluster-scoped
kubectl api-resources --namespaced=false
```

**Comandos**:
```bash
# Namespaced resources requieren -n
kubectl get pods -n development
kubectl get configmaps -n staging

# Cluster-scoped NO usan -n
kubectl get nodes
kubectl get namespaces
kubectl get persistentvolumes
```

---

### Fase 5: ResourceQuota (60 min)
**Teoría**: Sección 9 del README

**¿Qué es ResourceQuota?**
- Limita recursos agregados que un namespace puede consumir
- Previene que un namespace monopolice el clúster
- Esencial para multi-tenancy

**Tipos de límites**:
1. **Compute**: CPU, memoria
2. **Storage**: PersistentVolumeClaims, storage total
3. **Objects**: Número de Pods, Services, ConfigMaps, etc.

**Ejemplo básico**:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: development
spec:
  hard:
    # Compute
    requests.cpu: "4"          # Total CPU requests max 4 cores
    requests.memory: 8Gi       # Total memory requests max 8Gi
    limits.cpu: "8"            # Total CPU limits max 8 cores
    limits.memory: 16Gi        # Total memory limits max 16Gi
    
    # Objects
    pods: "10"                 # Max 10 Pods
    services: "5"              # Max 5 Services
    persistentvolumeclaims: "4" # Max 4 PVCs
```

**Aplicar**:
```bash
kubectl apply -f resource-quota.yaml -n development
```

**Ver cuota**:
```bash
kubectl get resourcequota -n development

# NAME            AGE   REQUEST                                    LIMIT
# compute-quota   5m    requests.cpu: 1/4, requests.memory: 2Gi/8Gi  ...
```

**Ver uso detallado**:
```bash
kubectl describe resourcequota compute-quota -n development
```

**Ejemplo: Storage Quota**:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: storage-quota
  namespace: staging
spec:
  hard:
    persistentvolumeclaims: "10"
    requests.storage: "100Gi"
```

**Ejemplo: Object Quota**:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-quota
  namespace: production
spec:
  hard:
    configmaps: "10"
    secrets: "10"
    services: "20"
    services.loadbalancers: "2"
    services.nodeports: "5"
```

**Importante**: Si hay ResourceQuota, los Pods DEBEN especificar `resources.requests` y `resources.limits`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  namespace: development
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
```

---

### Fase 6: LimitRange (50 min)
**Teoría**: Sección 10 del README

**¿Qué es LimitRange?**
- Define valores **por defecto**, **mínimos** y **máximos** para recursos de contenedores y Pods
- Complementa ResourceQuota (quota = total namespace, limitrange = por contenedor/pod)

**Para qué sirve**:
- ✅ Aplicar defaults si no se especifican resources
- ✅ Prevenir Pods muy grandes o muy pequeños
- ✅ Garantizar mínimos de performance

**Ejemplo básico**:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: container-limits
  namespace: development
spec:
  limits:
  - type: Container
    default:               # Limits por defecto si no se especifican
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:        # Requests por defecto si no se especifican
      cpu: "100m"
      memory: "128Mi"
    min:                   # Mínimo permitido
      cpu: "50m"
      memory: "64Mi"
    max:                   # Máximo permitido
      cpu: "2"
      memory: "2Gi"
```

**Aplicar**:
```bash
kubectl apply -f limit-range.yaml -n development
```

**Ver LimitRange**:
```bash
kubectl get limitranges -n development
kubectl describe limitrange container-limits -n development
```

**Comportamiento**:

**Caso 1: Pod sin resources**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  namespace: development
spec:
  containers:
  - name: app
    image: nginx
    # No resources especificados
```

**Resultado**: Se aplican `default` y `defaultRequest` del LimitRange automáticamente.

**Caso 2: Pod con resources muy grandes**:
```yaml
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "3"  # > max (2)
```

**Resultado**: Error al crear el Pod (excede max del LimitRange).

**Ejemplo: LimitRange para Pods**:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: pod-limits
  namespace: staging
spec:
  limits:
  - type: Pod
    max:
      cpu: "4"
      memory: "8Gi"
    min:
      cpu: "100m"
      memory: "128Mi"
```

**Ejemplo: PVC Limits**:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: storage-limits
  namespace: production
spec:
  limits:
  - type: PersistentVolumeClaim
    max:
      storage: "50Gi"
    min:
      storage: "1Gi"
```

**Lab 2**: [Quotas y Limits](laboratorios/lab-02-quotas-limits.md) - 50 min

---

### Fase 7: Aislamiento y Seguridad (40 min)
**Teoría**: Sección 11 del README

**Niveles de aislamiento**:

**1. Aislamiento lógico (Namespace solo)**:
- ❌ Pods de diferentes namespaces PUEDEN comunicarse por defecto
- ❌ NO hay aislamiento de red

**2. Aislamiento de red (NetworkPolicy)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-other-namespaces
  namespace: production
spec:
  podSelector: {}  # Aplica a todos los Pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}  # Solo Pods del mismo namespace
```

**3. Aislamiento de RBAC (permisos)**:
```yaml
# Role: Solo dentro del namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: development
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments", "services"]
  verbs: ["get", "list", "create", "update", "delete"]
---
# RoleBinding: Asignar Role a usuario
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: development
subjects:
- kind: User
  name: john
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

**Resultado**: Usuario `john` solo puede trabajar en namespace `development`.

**Lab 3**: [Multi-Tenancy](laboratorios/lab-03-multi-tenancy.md) - 60 min

---

### Fase 8: Patrones de Organización (30 min)
**Teoría**: Sección 12 del README

**Patrón 1: Por Entorno**:
```
Clúster: shared-dev-staging
├── namespace: development
├── namespace: staging
└── namespace: testing
```

**Pros**: Simplicidad, ahorro de costos  
**Cons**: Prod debe estar en clúster separado

---

**Patrón 2: Por Equipo**:
```
Clúster: company-cluster
├── namespace: team-backend
├── namespace: team-frontend
├── namespace: team-data
└── namespace: team-platform
```

**Pros**: Aislamiento por equipo, RBAC claro  
**Cons**: Requiere coordinación para recursos compartidos

---

**Patrón 3: Por Proyecto/Aplicación**:
```
Clúster: projects
├── namespace: project-ecommerce
├── namespace: project-analytics
└── namespace: project-crm
```

**Pros**: Aislamiento completo por proyecto  
**Cons**: Puede tener muchos namespaces

---

**Patrón 4: Híbrido (Equipo + Entorno)**:
```
Clúster: company-dev
├── namespace: backend-dev
├── namespace: backend-staging
├── namespace: frontend-dev
└── namespace: frontend-staging
```

**Pros**: Flexibilidad, granularidad  
**Cons**: Complejidad de naming

---

### Fase 9: Best Practices (30 min)
**Teoría**: Sección 13 del README

**Naming Conventions**:
```bash
# Formato recomendado: <equipo>-<entorno>
backend-dev
backend-staging
backend-prod

# O: <proyecto>-<componente>
ecommerce-api
ecommerce-web
ecommerce-database
```

**Evitar**: `ns1`, `test123`, `myapp`

**Labels estándar**:
```yaml
metadata:
  labels:
    environment: production
    team: backend
    project: ecommerce
    cost-center: engineering
```

**Siempre usar**:
- ✅ ResourceQuotas en todos los namespaces
- ✅ LimitRanges para defaults
- ✅ NetworkPolicies para aislamiento
- ✅ RBAC para control de acceso
- ✅ Monitoreo por namespace (Prometheus labels)

**Evitar**:
- ❌ Namespace `default` para apps de producción
- ❌ Muchos namespaces pequeños (overhead)
- ❌ Nombres sin convención
- ❌ Namespaces sin ResourceQuota

---

## 📝 Comandos Esenciales

### Gestión Básica

```bash
# Listar namespaces
kubectl get namespaces
kubectl get ns

# Crear namespace
kubectl create namespace <name>

# Ver detalles
kubectl describe namespace <name>

# Eliminar namespace (⚠️ elimina todo dentro)
kubectl delete namespace <name>

# Ver recursos en namespace
kubectl get all -n <namespace>

# Ver recursos en todos los namespaces
kubectl get pods --all-namespaces
kubectl get pods -A
```

### Trabajar con Namespaces

```bash
# Especificar namespace con -n
kubectl get pods -n development
kubectl apply -f app.yaml -n staging
kubectl logs <pod> -n production

# Cambiar namespace por defecto del contexto
kubectl config set-context --current --namespace=<namespace>

# Verificar namespace actual
kubectl config view --minify | grep namespace:
```

### Contextos

```bash
# Ver contextos
kubectl config get-contexts

# Crear contexto con namespace
kubectl config set-context <context-name> \
  --cluster=<cluster> \
  --user=<user> \
  --namespace=<namespace>

# Cambiar contexto
kubectl config use-context <context-name>

# Ver contexto actual
kubectl config current-context
```

### ResourceQuota

```bash
# Crear quota
kubectl apply -f resource-quota.yaml -n <namespace>

# Ver quotas
kubectl get resourcequota -n <namespace>
kubectl get quota -n <namespace>  # Alias

# Ver detalles de uso
kubectl describe resourcequota <name> -n <namespace>

# Eliminar quota
kubectl delete resourcequota <name> -n <namespace>
```

### LimitRange

```bash
# Crear LimitRange
kubectl apply -f limit-range.yaml -n <namespace>

# Ver LimitRanges
kubectl get limitrange -n <namespace>
kubectl get limits -n <namespace>  # Alias

# Ver detalles
kubectl describe limitrange <name> -n <namespace>

# Eliminar
kubectl delete limitrange <name> -n <namespace>
```

### Troubleshooting

```bash
# Verificar recursos en namespace
kubectl get all -n <namespace>

# Ver eventos del namespace
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Verificar quotas y uso
kubectl describe namespace <namespace>
kubectl describe resourcequota -n <namespace>

# Ver límites aplicados
kubectl describe limitrange -n <namespace>

# Pods que no pueden crearse (por quota)
kubectl get events -n <namespace> | grep -i "exceeded quota"
```

---

## 🎯 Conceptos Clave para Recordar

### Namespace = Clúster Virtual

```
1 Clúster Físico
    → N Namespaces (clústeres virtuales)
        → Aislamiento lógico
        → Cuotas de recursos
        → RBAC
        → DNS scoping
```

### DNS Cross-Namespace

```
<service>.<namespace>.svc.<cluster-domain>

Mismo namespace:     backend
Otro namespace:      api.production
FQDN completo:       api.production.svc.cluster.local
```

### ResourceQuota vs LimitRange

| Aspecto | ResourceQuota | LimitRange |
|---------|---------------|------------|
| **Alcance** | Total del namespace | Por contenedor/pod |
| **Límites** | Agregados (suma total) | Individuales (min/max) |
| **Defaults** | No aplica | Sí (default/defaultRequest) |
| **Uso** | Prevenir monopolio | Garantizar mínimos/máximos |

### Aislamiento Completo

```
Namespace solo:              Aislamiento lógico (no red)
+ NetworkPolicy:             Aislamiento de red
+ RBAC (Role/RoleBinding):   Aislamiento de permisos
= Multi-tenancy seguro
```

---

## ✅ Checklist de Dominio

Marca cuando domines cada concepto:

### Fundamentos
- [ ] Puedo explicar qué es un namespace
- [ ] Entiendo cuándo usar namespaces
- [ ] Conozco los namespaces del sistema
- [ ] Sé diferenciar aislamiento lógico vs físico

### Gestión
- [ ] Puedo crear y eliminar namespaces
- [ ] Sé trabajar con recursos en namespaces (-n)
- [ ] Puedo listar recursos en todos los namespaces (-A)
- [ ] Entiendo cómo cambiar el namespace por defecto

### Contextos
- [ ] Sé ver el contexto actual
- [ ] Puedo crear contextos con namespaces específicos
- [ ] Puedo cambiar entre contextos
- [ ] Entiendo la estructura de kubeconfig

### DNS
- [ ] Conozco el formato DNS de services
- [ ] Puedo acceder a services en otro namespace
- [ ] Entiendo mismo-namespace vs cross-namespace

### Quotas y Limits
- [ ] Sé crear ResourceQuotas
- [ ] Puedo configurar límites de CPU y memoria
- [ ] Entiendo object quotas (pods, services, etc.)
- [ ] Puedo ver el uso de quotas

### LimitRange
- [ ] Sé crear LimitRanges
- [ ] Entiendo default vs defaultRequest
- [ ] Puedo configurar min/max por contenedor
- [ ] Conozco limits para PVCs

### Aislamiento
- [ ] Sé aplicar NetworkPolicies por namespace
- [ ] Entiendo RBAC con Roles y RoleBindings
- [ ] Puedo implementar multi-tenancy básico
- [ ] Conozco mejores prácticas de seguridad

### Organización
- [ ] Conozco patrones de organización (entorno, equipo, proyecto)
- [ ] Aplico naming conventions
- [ ] Uso labels estándar
- [ ] Sigo best practices

### Troubleshooting
- [ ] Puedo diagnosticar problemas de quota
- [ ] Sé verificar LimitRange aplicado
- [ ] Puedo ver eventos por namespace
- [ ] Entiendo errores comunes

### Práctica
- [ ] Completé Lab 01: Namespaces Básico
- [ ] Completé Lab 02: Quotas y Limits
- [ ] Completé Lab 03: Multi-Tenancy
- [ ] Puedo diseñar arquitecturas con namespaces

---

## 🎓 Evaluación Final

### Preguntas Clave
1. ¿Cuál es la diferencia entre namespace y clúster separado?
2. ¿Cómo acceder a un service en otro namespace?
3. ¿Qué sucede si un namespace tiene ResourceQuota pero los Pods no especifican resources?
4. ¿Cuál es la diferencia entre ResourceQuota y LimitRange?
5. ¿Por qué los namespaces solos NO proporcionan aislamiento de red?

<details>
<summary>Ver Respuestas</summary>

1. **Namespace vs Clúster**:
   - **Namespace**: Aislamiento lógico dentro del mismo clúster físico. Comparte nodos, API server, etcd.
   - **Clúster separado**: Aislamiento físico completo. Infraestructura independiente.

2. **Acceso cross-namespace**:
   ```bash
   # Formato DNS
   <service>.<namespace>.svc.cluster.local
   
   # Ejemplo
   curl http://api.production.svc.cluster.local
   ```

3. **ResourceQuota sin resources**: El Pod NO se puede crear. Error: "failed quota: must specify requests/limits".

4. **ResourceQuota vs LimitRange**:
   - **ResourceQuota**: Límite **total** del namespace (suma de todos los Pods)
   - **LimitRange**: Límite **individual** por contenedor/pod + defaults

5. **Aislamiento de red**: Por defecto, Pods de diferentes namespaces PUEDEN comunicarse. Se necesita NetworkPolicy para restringir.

</details>

### Escenario Práctico
Diseña namespaces para:
- Equipo Backend (3 developers, 10 microservicios)
- Equipo Frontend (2 developers, 2 apps)
- Entornos: dev y staging (prod en clúster separado)

Incluye: Naming, ResourceQuotas, RBAC básico

<details>
<summary>Ver Solución</summary>

**Estructura**:
```
Clúster: company-nonprod
├── backend-dev
├── backend-staging
├── frontend-dev
└── frontend-staging
```

**Namespaces + ResourceQuota**:
```yaml
# backend-dev
apiVersion: v1
kind: Namespace
metadata:
  name: backend-dev
  labels:
    team: backend
    environment: dev
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: backend-dev-quota
  namespace: backend-dev
spec:
  hard:
    requests.cpu: "8"
    requests.memory: "16Gi"
    limits.cpu: "16"
    limits.memory: "32Gi"
    pods: "50"
    services: "20"
---
# backend-staging (más recursos)
apiVersion: v1
kind: Namespace
metadata:
  name: backend-staging
  labels:
    team: backend
    environment: staging
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: backend-staging-quota
  namespace: backend-staging
spec:
  hard:
    requests.cpu: "12"
    requests.memory: "24Gi"
    limits.cpu: "24"
    limits.memory: "48Gi"
    pods: "100"
---
# frontend-dev (menos recursos)
apiVersion: v1
kind: Namespace
metadata:
  name: frontend-dev
  labels:
    team: frontend
    environment: dev
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: frontend-dev-quota
  namespace: frontend-dev
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    pods: "20"
```

**RBAC**:
```yaml
# Role para developers del backend
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: backend-dev
rules:
- apiGroups: ["", "apps", "networking.k8s.io"]
  resources: ["pods", "deployments", "services", "ingress", "configmaps", "secrets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
---
# RoleBinding para equipo backend
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: backend-developers
  namespace: backend-dev
subjects:
- kind: User
  name: john
- kind: User
  name: jane
- kind: User
  name: bob
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

**NetworkPolicy** (opcional):
```yaml
# Solo permitir comunicación dentro del mismo namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-namespace
  namespace: backend-dev
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
```

</details>

---

## 🔗 Recursos Adicionales

### Documentación Oficial
- [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Limit Ranges](https://kubernetes.io/docs/concepts/policy/limit-range/)

### Labs del Módulo
1. [Lab 01 - Namespaces Básico](laboratorios/lab-01-namespaces-basico.md) - 40 min
2. [Lab 02 - Quotas y Limits](laboratorios/lab-02-quotas-limits.md) - 50 min
3. [Lab 03 - Multi-Tenancy](laboratorios/lab-03-multi-tenancy.md) - 60 min

### Ejemplos Prácticos
- [`ejemplos/01-basico/`](ejemplos/01-basico/) - Creación básica
- [`ejemplos/02-contextos/`](ejemplos/02-contextos/) - Kubeconfig
- [`ejemplos/03-quotas/`](ejemplos/03-quotas/) - ResourceQuotas
- [`ejemplos/04-limits/`](ejemplos/04-limits/) - LimitRanges
- [`ejemplos/05-organizacion/`](ejemplos/05-organizacion/) - Patrones

### Herramientas
- [kubens](https://github.com/ahmetb/kubectx) - Cambiar namespace fácilmente
- [kubectx](https://github.com/ahmetb/kubectx) - Cambiar contexto fácilmente
- [k9s](https://k9scli.io/) - UI para gestionar recursos por namespace

### Siguiente Módulo
➡️ Módulo 11: Resource Limits y Configuración de Pods

---

## 🎉 ¡Felicitaciones!

Has completado el Módulo 10 de Namespaces y Organización. Ahora puedes:

- ✅ Organizar clústeres con namespaces
- ✅ Implementar multi-tenancy
- ✅ Aplicar cuotas de recursos
- ✅ Configurar límites por defecto
- ✅ Diseñar arquitecturas escalables

**Próximos pasos**:
1. Revisar este resumen periódicamente
2. Practicar con los 3 laboratorios
3. Aplicar namespaces en proyectos reales
4. Explorar RBAC avanzado
5. Continuar con Módulo 11

¡Sigue adelante! 🚀
