# 🎯 Módulo 05: Gestión Avanzada de Pods

> **De la Teoría a la Práctica**: Gestionar Pods en producción con resource limits, restart policies, y security contexts.

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo serás capaz de:

### 🎓 Objetivos Conceptuales
- **Ciclo de vida completo**: Entender cada fase del Pod (Pending, Running, Succeeded, Failed)
- **Resource management**: Por qué son críticos requests y limits
- **Restart policies**: Always, OnFailure, Never y cuándo usar cada una
- **Security contexts**: Privilegios, capabilities, user/group IDs
- **QoS classes**: Guaranteed, Burstable, BestEffort

### 🛠️ Objetivos Técnicos
- **Manifiestos YAML production-ready**: Configuración completa de Pods
- **Resource requests/limits**: CPU, memoria, ephemeral storage
- **Security contexts**: runAsUser, fsGroup, capabilities
- **Init containers**: Preparación antes de contenedor principal
- **Lifecycle hooks**: postStart, preStop para gestión avanzada
- **Pod priority**: PriorityClass para scheduling crítico

### 🔍 Objetivos de Troubleshooting
- **Diagnosticar OOMKilled**: Pods matados por falta de memoria
- **Resolver CrashLoopBackOff**: Análisis de logs y eventos
- **Debugging con ephemeral containers**: Contenedores temporales de debug
- **Entender eviction**: Cuándo y por qué K8s expulsa Pods
- **Analizar resource usage**: kubectl top, métricas reales

### 🏢 Objetivos Profesionales
- **Production-ready Pods**: Configuración enterprise con límites y health checks
- **Cost optimization**: Dimensionar recursos correctamente
- **Security hardening**: Aplicar principio de mínimo privilegio
- **Preparación CKA/CKAD**: 30-40% del examen sobre gestión de Pods

---

## ✅ Prerrequisitos

### Conocimientos Previos
- ✅ **Módulo 04 completado**: Entender qué es un Pod y namespaces compartidos
- ✅ **YAML intermedio**: Sintaxis, listas, mapas, multiline strings
- ✅ **Linux resources**: CPU, memoria, procesos, signals
- ✅ **Security básica**: Users, grupos, permisos

### Herramientas Necesarias
- 🔧 **Minikube activo**: Con metrics-server habilitado
- 🔧 **kubectl configurado**: Autocompletado funcionando
- 🔧 **Editor**: VS Code con extensión Kubernetes (recomendado)

### Verificación
```bash
# Verificar metrics-server (para kubectl top)
kubectl top nodes
# Si falla, habilitar: minikube addons enable metrics-server

# Verificar recursos disponibles
kubectl describe node minikube | grep -A 5 "Allocated resources"

# Probar creación de Pod
kubectl run test --image=nginx --restart=Never
kubectl get pod test
kubectl delete pod test
```

---

## 🗺️ Estructura del Módulo

### Contenido Teórico (90 minutos)
1. **Resource Management** (30 min) - Requests, limits, QoS
2. **Restart Policies** (15 min) - Always, OnFailure, Never
3. **Security Contexts** (25 min) - Users, capabilities, SELinux
4. **Lifecycle Hooks** (20 min) - postStart, preStop

### Contenido Práctico (180-240 minutos)
1. **Manifiestos completos** (40 min) - YAML production-ready
2. **Resource limits** (30 min) - CPU, memoria
3. **Init containers** (30 min) - Preparación de entorno
4. **Security hardening** (40 min) - Privilegios mínimos
5. **Troubleshooting avanzado** (40 min) - OOMKilled, eviction
6. **Proyecto final** (30 min) - Pod enterprise completo

### Ejemplos Prácticos
- 📁 **01-resource-management/** - Requests, limits, QoS
- 📁 **02-restart-policies/** - Always, OnFailure, Never
- 📁 **03-init-containers/** - Preparación de datos
- 📁 **04-security-contexts/** - runAsUser, capabilities
- 📁 **05-lifecycle-hooks/** - postStart, preStop
- 📁 **06-priority-preemption/** - PriorityClass
- 📁 **07-ephemeral-containers/** - Debugging avanzado
- 📁 **08-troubleshooting/** - Diagnóstico práctico

### Laboratorios
- 🔬 **Lab 01**: Configurar resource requests y limits
- 🔬 **Lab 02**: Implementar security context
- 🔬 **Lab 03**: Usar init containers para setup
- 🔬 **Lab 04**: Diagnosticar OOMKilled
- 🔬 **Lab 05**: Pod production-ready completo

---

## 📚 Rutas de Estudio Recomendadas

### 🟢 Ruta Principiante (Nuevo en gestión avanzada)
**Tiempo**: 6-8 horas
```
Día 1: Resource Management (3 horas)
  ├─ Teoría: Requests vs Limits (45 min)
  ├─ Lab 01: Configurar CPU y memoria (60 min)
  ├─ Sección QoS classes (30 min)
  └─ Experimentar con límites (45 min)

Día 2: Security y Lifecycle (3 horas)
  ├─ Teoría: Security contexts (45 min)
  ├─ Lab 02: runAsUser, capabilities (60 min)
  ├─ Teoría: Init containers (30 min)
  └─ Lab 03: Setup con init container (45 min)

Día 3: Troubleshooting (2 horas)
  ├─ Lab 04: Diagnosticar OOMKilled (60 min)
  ├─ Lab 05: Pod production-ready (60 min)
  └─ RESUMEN-MODULO.md (30 min)
```

### 🟡 Ruta Intermedia (Experiencia con Pods)
**Tiempo**: 3-4 horas
```
Sesión 1: Teoría concentrada (60 min)
  ├─ Resource management (20 min)
  ├─ Security contexts (20 min)
  └─ Lifecycle hooks (20 min)

Sesión 2: Práctica (120 min)
  ├─ Labs 01-03 (resource + security + init) (90 min)
  └─ Lab 04-05 (troubleshooting + final) (30 min)

Sesión 3: Consolidación (30 min)
  └─ RESUMEN-MODULO.md + ejercicios
```

### 🔴 Ruta Certificación (CKA/CKAD)
**Tiempo**: 90-120 minutos
```
Estrategia Examen:
  ├─ RESUMEN-MODULO.md primero (30 min)
  │   ├─ Resource requests/limits YAML
  │   ├─ Security context común
  │   └─ Init containers pattern
  │
  ├─ Práctica intensiva (60 min)
  │   ├─ Crear Pod con resources (10 min)
  │   ├─ Añadir security context (10 min)
  │   ├─ Init container setup (15 min)
  │   ├─ Troubleshooting (15 min)
  │   └─ Pod completo desde cero (10 min)
  │
  └─ Cheat sheet personalizado (10 min)
      └─ Snippets YAML para copiar rápido

CKAD: 40% del examen (Pod design, configuration)
CKA: 30% del examen (Troubleshooting, workloads)
```

---

## 📁 Organización de Recursos

### Carpeta `ejemplos/` (8 directorios)
```
ejemplos/
├── 01-resource-management/
│   ├── README.md
│   ├── pod-with-requests.yaml        # Solo requests
│   ├── pod-with-limits.yaml          # Solo limits
│   ├── pod-requests-limits.yaml      # Ambos
│   └── qos-classes.yaml              # Guaranteed, Burstable, BestEffort
│
├── 02-restart-policies/
│   ├── README.md
│   ├── pod-always.yaml               # restartPolicy: Always
│   ├── pod-on-failure.yaml           # restartPolicy: OnFailure
│   └── pod-never.yaml                # restartPolicy: Never
│
├── 03-init-containers/
│   ├── README.md
│   ├── pod-init-setup.yaml           # Preparar archivos
│   ├── pod-init-wait.yaml            # Esperar servicio
│   └── pod-multi-init.yaml           # Múltiples inits
│
├── 04-security-contexts/
│   ├── README.md
│   ├── pod-run-as-user.yaml          # Usuario no-root
│   ├── pod-capabilities.yaml         # Añadir/eliminar capabilities
│   ├── pod-read-only-fs.yaml         # Filesystem read-only
│   └── pod-privileged.yaml           # Privileged (evitar)
│
├── 05-lifecycle-hooks/
│   ├── README.md
│   ├── pod-post-start.yaml           # postStart hook
│   ├── pod-pre-stop.yaml             # preStop hook
│   └── pod-graceful-shutdown.yaml    # Shutdown completo
│
├── 06-priority-preemption/
│   ├── README.md
│   ├── priority-class.yaml           # Definir prioridad
│   ├── pod-high-priority.yaml        # Pod crítico
│   └── pod-low-priority.yaml         # Pod normal
│
├── 07-ephemeral-containers/
│   ├── README.md
│   ├── pod-to-debug.yaml             # Pod problemático
│   └── debug-commands.md             # kubectl debug
│
└── 08-troubleshooting/
    ├── README.md
    ├── pod-oomkilled.yaml            # Falla por memoria
    ├── pod-crashloop.yaml            # CrashLoopBackOff
    ├── diagnose-commands.md          # Comandos troubleshooting
    └── events-analysis.md            # Interpretar eventos
```

---

## 🎯 Metodología de Aprendizaje

Este módulo es **30% teórico, 70% práctico**:

### Distribución de Contenido
```
💻 Configuración práctica   50%  ██████████▓░░░░░░░░░
🔍 Troubleshooting          20%  ████▓░░░░░░░░░░░░░░░
📖 Teoría y conceptos       20%  ████▓░░░░░░░░░░░░░░░
🎯 Ejercicios avanzados     10%  ██▓░░░░░░░░░░░░░░░░░
```

### Enfoque Pedagógico
1. **Iteración incremental**: Empezar con Pod simple, añadir complejidad
2. **Troubleshooting integrado**: Romper intencionalmente, diagnosticar, reparar
3. **Production mindset**: Cada ejercicio con estándares enterprise
4. **Hands-on validation**: Verificar CADA cambio inmediatamente

### Flujo de Trabajo
```
1. Pod simple → 2. Añadir requests → 3. Verificar QoS
                ↓
4. Añadir security context → 5. Probar permisos → 6. Ajustar
                ↓
7. Init container → 8. Lifecycle hooks → 9. Pod completo
```

---

## 🔗 Conexión con Otros Módulos

### Este Módulo te Prepara Para
- ➡️ **Módulo 06**: ReplicaSets (gestionar múltiples Pods idénticos)
- ➡️ **Módulo 11**: Resource Limits (LimitRange, ResourceQuota)
- ➡️ **Módulo 12**: Health Checks (liveness, readiness)
- ➡️ **Módulo 17-18**: RBAC (security avanzada)

### Relación con Módulos Anteriores
```
Módulo 04: Pods básicos (qué son)
    ↓
Módulo 05: Pods avanzados (cómo gestionarlos) ← ESTÁS AQUÍ
    ↓
Módulo 06-07: Múltiples Pods (ReplicaSets, Deployments)
```

---

## 💡 Conceptos Clave Previos

### Resource Requests vs Limits

```yaml
resources:
  requests:          # LO MÍNIMO que necesita (scheduling)
    cpu: "100m"      # 0.1 CPU cores
    memory: "128Mi"  # 128 mebibytes
  limits:            # LO MÁXIMO que puede usar (enforcement)
    cpu: "500m"      # 0.5 CPU cores
    memory: "512Mi"  # 512 mebibytes
```

**QoS resultantes**:
| Requests | Limits | QoS Class |
|----------|--------|-----------|
| ✅ Sí | ✅ Sí (igual) | **Guaranteed** (alta prioridad) |
| ✅ Sí | ✅ Sí (diferente) | **Burstable** (media prioridad) |
| ❌ No | ❌ No | **BestEffort** (baja prioridad, evictado primero) |

---

## 🎯 Objetivos del Módulo (Expandido)

Al completar este módulo serás capaz de:

- ✅ **Escribir manifiestos YAML production-ready** con todas las secciones críticas
- ✅ **Configurar resource requests y limits** correctamente según workload
- ✅ **Aplicar security contexts** con usuario no-root, capabilities mínimas
- ✅ **Usar init containers** para setup y validación pre-ejecución
- ✅ **Implementar lifecycle hooks** para graceful shutdown
- ✅ **Gestionar restart policies** según tipo de aplicación
- ✅ **Diagnosticar OOMKilled** y problemas de recursos
- ✅ **Crear Pods enterprise** con todas las best practices
- ✅ Implementar health checks (liveness, readiness, startup)
- ✅ Organizar recursos con labels, selectors y annotations

### 🔍 Debugging y Troubleshooting
- ✅ Diagnosticar problemas comunes de Pods
- ✅ Usar herramientas avanzadas de debugging
- ✅ Interpretar eventos y logs efectivamente

### 🎨 Casos de Uso Avanzados
- ✅ Optimizar recursos según QoS classes
- ✅ Aplicar best practices de producción
- ✅ Integrar patterns de observabilidad

---

## 📚 Prerequisitos

### Conocimientos Previos
- ✅ Completado [Módulo 04: Pods vs Contenedores](../modulo-04-pods-vs-contenedores/)
- ✅ Comprensión de qué es un Pod y sus namespaces
- ✅ Familiaridad con patrones multi-contenedor (Sidecar, Init, Ambassador)
- ✅ Conocimientos básicos de YAML
- ✅ Experiencia básica con línea de comandos

### Entorno Técnico
```bash
# Verificar Minikube
minikube version  # ≥ v1.32.0

# Verificar Docker
docker --version  # ≥ 24.0.0

# Verificar kubectl
kubectl version --client  # ≥ v1.28.0

# Cluster debe estar corriendo
minikube status
# Expected: Running
```

### ⚠️ Importante: Separación con Módulo 04

| Aspecto | Módulo 04 (Prerequisito) | **Módulo 05 (Este)** |
|---------|--------------------------|----------------------|
| **Enfoque** | ¿Qué es un Pod? | ¿Cómo gestionarlo? |
| **Nivel** | Conceptual/Arquitectónico | Operacional/Práctico |
| **Contenido** | Namespaces, Patrones básicos | Manifiestos, Resources, Probes |
| **Objetivo** | Entender arquitectura interna | Dominar configuración y operación |

Si no has completado el Módulo 04, **hazlo primero** para comprender los fundamentos arquitectónicos de los Pods.

---

## 🗺️ Estructura del Módulo

Este módulo sigue la progresión **Teoría → Ejemplo → Laboratorio**:

| Sección | Tema | Contenido |
|---------|------|-----------|
| **1** | [Manifiestos YAML](#-1-manifiestos-yaml-production-ready) | Estructura completa, campos obligatorios, mejores prácticas |
| **2** | [Gestión del Ciclo de Vida](#-2-gestión-del-ciclo-de-vida) | Estados, transiciones, comandos de gestión |
| **3** | [Labels y Selectors](#-3-labels-selectors-y-annotations) | Organización, filtrado, casos de uso |
| **4** | [Resource Management](#-4-resource-management) | Requests, Limits, QoS classes |
| **5** | [Health Checks](#-5-health-checks-y-probes) | Liveness, Readiness, Startup probes |
| **6** | [Security Contexts](#-6-security-contexts) | runAsUser, capabilities, políticas |
| **7** | [Debugging Avanzado](#-7-debugging-y-troubleshooting) | Herramientas, patterns, eventos |
| **8** | [Best Practices](#-8-best-practices-de-producción) | Patrones, antipatrones, optimización |

---

## 🎓 Recursos de Aprendizaje

### Ejemplos Prácticos
📁 **Carpeta**: [`ejemplos/`](./ejemplos/)
- 50+ archivos YAML production-ready
- Organizado por tema y complejidad
- Cada ejemplo incluye comentarios explicativos

### Laboratorios Guiados
📁 **Carpeta**: [`laboratorios/`](./laboratorios/)
- Laboratorios hands-on con verificaciones
- Duración total: ~3-4 horas de práctica
- Incluyen troubleshooting y cleanup

### Documentación de Referencia
- 📖 [`ejemplos/README.md`](./ejemplos/README.md) - Índice completo de ejemplos
- 📖 [`laboratorios/README.md`](./laboratorios/README.md) - Guía de laboratorios
- 📘 **[`RESUMEN-MODULO.md`](./RESUMEN-MODULO.md)** - **Guía de estudio estructurada** (RECOMENDADO)

---

## 🎓 Guía de Estudio Recomendada

Para maximizar tu aprendizaje, sigue esta ruta estructurada:

```
Fase 1: Manifiestos YAML (60-90 min)
├─ Estructura básica
├─ Campos obligatorios y opcionales
├─ Mejores prácticas de escritura
└─ Lab 01: Crear manifiestos

Fase 2: Resources y Health Checks (90-120 min)
├─ Resource requests y limits
├─ QoS classes
├─ Probes (liveness, readiness, startup)
└─ Lab 02: Optimización de recursos

Fase 3: Seguridad y Labels (60-90 min)
├─ Security contexts
├─ Labels y selectors avanzados
├─ Annotations y metadata
└─ Lab 03: Hardening de Pods

Fase 4: Debugging y Production (60-90 min)
├─ Herramientas de debugging
├─ Troubleshooting patterns
├─ Best practices
└─ Lab 04: Resolución de problemas
```

👉 **[ABRIR GUÍA DE ESTUDIO](./RESUMEN-MODULO.md)**

---

---

## � 1. Manifiestos YAML Production-Ready

> **Objetivo**: Dominar la escritura de manifiestos Pod completos y optimizados para producción

### 1.1. Anatomía de un Manifiesto Pod

#### **Estructura de 4 Niveles**

Todo manifiesto Pod en Kubernetes tiene 4 secciones raíz obligatorias:

```yaml
apiVersion: v1      # 1. Versión de la API K8s
kind: Pod           # 2. Tipo de recurso
metadata:           # 3. Información identificativa
  name: mi-pod
  labels:
    app: frontend
spec:               # 4. Especificación deseada
  containers:
  - name: nginx
    image: nginx:alpine
```

**📖 Explicación de cada nivel:**

| Campo | Descripción | Valores típicos |
|-------|-------------|-----------------|
| `apiVersion` | API version del recurso | `v1` para Pods |
| `kind` | Tipo de objeto K8s | `Pod`, `Deployment`, `Service` |
| `metadata` | Información del objeto | name, labels, annotations |
| `spec` | Estado deseado | containers, volumes, etc |

---

#### **1.1.1. Metadata: Identificación y Organización**

**Campos principales**:

```yaml
metadata:
  name: frontend-web               # Obligatorio: nombre único
  namespace: production            # Opcional: default si se omite
  labels:                          # Opcional pero ALTAMENTE recomendado
    app: frontend
    version: v1.2.0
    tier: web
    environment: production
  annotations:                     # Opcional: metadata no identificativa
    description: "Frontend web server"
    maintainer: "devops@company.com"
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
```

**Diferencias clave: Labels vs Annotations**

| Aspecto | Labels | Annotations |
|---------|--------|-------------|
| **Propósito** | Identificación y selección | Metadata adicional |
| **Usado por** | Selectors, Services, ReplicaSets | Herramientas, usuarios |
| **Filtrado** | ✅ Sí (`-l app=frontend`) | ❌ No |
| **Límite** | 63 caracteres | Sin límite práctico |
| **Ejemplos** | app, tier, env, version | URLs, descriptions, configs |

💡 **Ejemplo inline**:

```yaml
metadata:
  name: web-app
  labels:
    app: web              # Usado para selectors
    tier: frontend        # Agrupación lógica
  annotations:
    git-commit: "abc123"  # Info de deployment
```

```bash
# Filtrar por labels
kubectl get pods -l app=web
kubectl get pods -l tier=frontend
kubectl get pods -l 'environment in (production,staging)'
```

📄 **Ver ejemplo completo**: [`ejemplos/basicos/01-pod-con-labels.yaml`](./ejemplos/basicos/01-pod-con-labels.yaml)

---

#### **1.1.2. Spec: Configuración de Contenedores**

**Campos esenciales**:

```yaml
spec:
  containers:                    # Lista de contenedores (mínimo 1)
  - name: nginx                  # Nombre único en el Pod
    image: nginx:1.25-alpine     # Imagen (preferir tags específicos)
    imagePullPolicy: IfNotPresent  # Always, Never, IfNotPresent
    
    ports:                       # Puertos a exponer
    - containerPort: 80
      name: http                 # Nombre opcional para referencia
      protocol: TCP              # TCP, UDP, SCTP
    
    env:                         # Variables de entorno
    - name: ENVIRONMENT
      value: "production"
    - name: LOG_LEVEL
      value: "info"
    
    command: ["nginx"]           # Sobrescribe ENTRYPOINT
    args: ["-g", "daemon off;"]  # Sobrescribe CMD
```

**🔑 Mejores prácticas**:

1. ✅ **Tags específicos** en producción (evitar `latest`)
2. ✅ **Nombrar puertos** para facilitar referencias
3. ✅ **imagePullPolicy: IfNotPresent** para optimizar
4. ✅ **Un contenedor principal** por Pod (salvo patterns)

💡 **Ejemplo inline - Pod básico**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-basic
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
      name: http
```

```bash
# Aplicar
kubectl apply -f ejemplos/basicos/02-pod-simple.yaml

# Verificar
kubectl get pods
kubectl describe pod nginx-basic
```

📄 **Ver ejemplo completo**: [`ejemplos/basicos/02-pod-simple.yaml`](./ejemplos/basicos/02-pod-simple.yaml)

---

### 1.2. Variables de Entorno y ConfigMaps

#### **1.2.1. Variables directas**

```yaml
spec:
  containers:
  - name: app
    image: myapp
    env:
    - name: DATABASE_URL
      value: "postgres://db:5432/mydb"
    - name: API_KEY
      value: "hardcoded-key"          # ❌ NO recomendado para producción
```

#### **1.2.2. Variables desde ConfigMap**

```yaml
env:
- name: DATABASE_URL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: database-url
```

💡 **Ejemplo inline completo**:

```yaml
# ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  environment: "production"
  log-level: "info"
  database-url: "postgres://db:5432"

---
# Pod usando ConfigMap
apiVersion: v1
kind: Pod
metadata:
  name: app-with-config
spec:
  containers:
  - name: app
    image: myapp
    envFrom:
    - configMapRef:
        name: app-config     # Carga TODAS las keys como env vars
```

```bash
# Aplicar
kubectl apply -f ejemplos/basicos/03-pod-con-configmap.yaml

# Ver env vars del Pod
kubectl exec app-with-config -- env | grep -E "environment|log-level"
```

📄 **Ver ejemplo completo**: [`ejemplos/basicos/03-pod-con-configmap.yaml`](./ejemplos/basicos/03-pod-con-configmap.yaml)

---

### 1.3. Volumes: Compartir Datos Entre Contenedores

#### **1.3.1. EmptyDir - Volume temporal**

```yaml
spec:
  volumes:
  - name: shared-data
    emptyDir: {}              # Se crea al iniciar Pod, se borra al eliminarlo
  
  containers:
  - name: writer
    image: busybox
    command: ["sh", "-c", "echo 'Hello' > /data/message.txt && sleep 3600"]
    volumeMounts:
    - name: shared-data
      mountPath: /data
  
  - name: reader
    image: busybox
    command: ["sh", "-c", "cat /data/message.txt && sleep 3600"]
    volumeMounts:
    - name: shared-data
      mountPath: /data
```

💡 **Ejemplo inline - Multi-contenedor con volume compartido**:

```bash
# Aplicar
kubectl apply -f ejemplos/multi-contenedor/01-shared-volume.yaml

# Verificar que ambos contenedores comparten datos
kubectl exec shared-volume -c reader -- cat /data/message.txt
# Output: Hello
```

📄 **Ver ejemplo completo**: [`ejemplos/multi-contenedor/01-shared-volume.yaml`](./ejemplos/multi-contenedor/01-shared-volume.yaml)

---

### 1.4. Resources: Requests y Limits

> **Nota**: Esta sección es introductoria. Profundizaremos en [Sección 4: Resource Management](#-4-resource-management)

```yaml
spec:
  containers:
  - name: app
    image: myapp
    resources:
      requests:              # Garantizado (usado por scheduler)
        memory: "128Mi"
        cpu: "250m"          # 250 millicores = 0.25 CPU
      limits:                # Máximo permitido
        memory: "256Mi"
        cpu: "500m"
```

**Comportamiento**:
- **Memory limit excedido** → OOMKilled (restart)
- **CPU limit excedido** → Throttling (más lento, no restart)

💡 **Ejemplo inline**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-resources
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
```

```bash
# Aplicar
kubectl apply -f ejemplos/production-ready/01-with-resources.yaml

# Ver recursos asignados
kubectl describe pod app-with-resources | grep -A 5 "Limits\|Requests"
```

📄 **Ver ejemplo completo**: [`ejemplos/production-ready/01-with-resources.yaml`](./ejemplos/production-ready/01-with-resources.yaml)

---

### 1.5. Manifiesto Production-Ready Completo

**Checklist mínimo para producción**:
- ✅ Tags específicos de imagen
- ✅ Labels organizadas
- ✅ Resources definidos
- ✅ Health probes configurados (ver Sección 5)
- ✅ Security context aplicado (ver Sección 6)

💡 **Ejemplo inline - Pod production-ready**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-prod
  labels:
    app: frontend
    version: v1.2.0
    environment: production
  annotations:
    description: "Frontend web server"
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine      # Tag específico
    ports:
    - containerPort: 80
      name: http
    resources:
      requests:
        memory: "128Mi"
        cpu: "250m"
      limits:
        memory: "256Mi"
        cpu: "500m"
    livenessProbe:                # Ver Sección 5
      httpGet:
        path: /healthz
        port: 80
      initialDelaySeconds: 30
    readinessProbe:
      httpGet:
        path: /ready
        port: 80
      initialDelaySeconds: 5
```

📄 **Ver ejemplo completo**: [`ejemplos/production-ready/02-complete-pod.yaml`](./ejemplos/production-ready/02-complete-pod.yaml)

---

### 1.6. Comandos Útiles para Manifiestos

```bash
# Generar manifiesto desde comando imperativo
kubectl run nginx --image=nginx:alpine --dry-run=client -o yaml > pod.yaml

# Aplicar manifiesto
kubectl apply -f pod.yaml

# Ver manifiesto aplicado
kubectl get pod nginx -o yaml

# Explicar campos de un recurso
kubectl explain pod
kubectl explain pod.spec
kubectl explain pod.spec.containers

# Validar sintaxis sin aplicar
kubectl apply -f pod.yaml --dry-run=client

# Ver diferencias antes de aplicar
kubectl diff -f pod.yaml
```

---

### ✅ Checkpoint Sección 1

Antes de continuar, verifica que puedes:
- [ ] Explicar los 4 campos raíz obligatorios de un manifiesto
- [ ] Distinguir entre labels y annotations
- [ ] Escribir un Pod con variables de entorno
- [ ] Crear un Pod con volume compartido entre contenedores
- [ ] Configurar resources básicos (requests/limits)

---

### 🧪 Laboratorio 01: Crear Manifiestos YAML

**Duración**: 45 minutos

📁 **Laboratorio**: [`laboratorios/lab-01-crear-pods.md`](./laboratorios/lab-01-crear-pods.md)

**Objetivos**:
1. Crear Pod desde cero con todas las secciones
2. Agregar labels y annotations
3. Configurar variables de entorno
4. Implementar volume compartido
5. Aplicar resources básicos

---

## 🔄 2. Gestión del Ciclo de Vida
curl http://localhost:8080
# Verás una página HTML con información del Pod
```

**Características**:
- Servidor HTTP simple con Python
- Puerto 8080
- Genera contenido HTML dinámico con hostname y fecha
- Ideal para testing de networking

---

#### **2. Pod con Variables de Entorno**

📄 **Archivo**: [`ejemplos/basicos/pod-con-env.yaml`](./ejemplos/basicos/pod-con-env.yaml)

```bash
# Crear Pod
kubectl apply -f ejemplos/basicos/pod-con-env.yaml

# Verificar que está corriendo
kubectl get pod env-demo

# Ver variables de entorno configuradas
kubectl exec env-demo -- env | grep -E "ENV|APP_NAME|VERSION|LOG_LEVEL"

# Ver logs con el output
kubectl logs env-demo
```

**Características**:
- Variables de entorno estándar
- Variables desde metadatos del Pod
- Útil para configuración de aplicaciones

---

#### **3. Pod con Volúmenes**

📄 **Archivo**: [`ejemplos/basicos/pod-volumenes.yaml`](./ejemplos/basicos/pod-volumenes.yaml)

```bash
# Crear ConfigMap y Secret primero (están en el YAML)
kubectl apply -f ejemplos/basicos/pod-volumenes.yaml

# Verificar que está corriendo
kubectl get pod pod-volumenes

# Explorar volúmenes montados
kubectl exec -it pod-volumenes -- ls -la /data
kubectl exec -it pod-volumenes -- cat /config/app.conf
kubectl exec -it pod-volumenes -- cat /secrets/username

# Ver logs con demostración
kubectl logs pod-volumenes
```

**Características**:
- EmptyDir: almacenamiento temporal
- ConfigMap: archivos de configuración
- Secret: credenciales sensibles
- Demuestra 3 tipos de volúmenes en un solo Pod

---

#### **4. Pod NGINX básico**

📄 **Archivo**: [`ejemplos/basicos/pod-nginx.yaml`](./ejemplos/basicos/pod-nginx.yaml)

```bash
# Crear Pod
kubectl apply -f ejemplos/basicos/pod-nginx.yaml

# Verificar estado
kubectl get pod nginx-simple

# Port-forward
kubectl port-forward pod/nginx-simple 8080:80

# En otra terminal:
curl http://localhost:8080
```

**Características**:
- NGINX Alpine (imagen ligera)
- Recursos definidos (requests/limits)
- Puerto 80
- Ideal para testing rápido

---

### **💡 Comandos Útiles para Estos Ejemplos**

```bash
# Aplicar todos los ejemplos básicos
kubectl apply -f ejemplos/basicos/

# Ver todos los Pods con labels
kubectl get pods --show-labels

# Filtrar solo ejemplos básicos
kubectl get pods -l category=basico

# Ver detalles de recursos
kubectl describe pod python-server
kubectl describe pod env-demo
kubectl describe pod pod-volumenes
kubectl describe pod nginx-simple

# Limpiar todos los ejemplos
kubectl delete -f ejemplos/basicos/
```

---

### **💡 Práctica Recomendada**

🧪 **Laboratorio práctico**: [`laboratorios/lab-01-crear-pods.md`](./laboratorios/lab-01-crear-pods.md)

Este laboratorio te guía paso a paso en la creación de Pods usando métodos imperativos y declarativos con ejercicios prácticos.

---

## 🔍 3. Inspección y Debugging

### **3.1 Ver información de Pods**

```bash
# Listar todos los Pods
kubectl get pods

# Más detalles (IP, nodo, etc.)
kubectl get pods -o wide

# Ver con labels
kubectl get pods --show-labels

# Filtrar por label
kubectl get pods -l app=nginx

# Watch mode (actualización en tiempo real)
kubectl get pods --watch

# Ver todos los recursos
kubectl get all
```

### **3.2 Describir un Pod (troubleshooting)**

```bash
# Ver detalles completos del Pod
kubectl describe pod nginx-pod
```

**Salida importante**:
```
Name:         nginx-pod
Namespace:    default
Node:         minikube/192.168.49.2
Status:       Running
IP:           10.244.0.5
Containers:
  nginx:
    Image:        nginx:1.25-alpine
    Port:         80/TCP
    State:        Running
      Started:    Sat, 09 Nov 2025 14:30:00 -0500

Events:         # ← MUY IMPORTANTE para debugging
  Type    Reason     Message
  ----    ------     -------
  Normal  Scheduled  Successfully assigned default/nginx-pod to minikube
  Normal  Pulling    Pulling image "nginx:1.25-alpine"
  Normal  Pulled     Successfully pulled image
  Normal  Created    Created container nginx
  Normal  Started    Started container nginx
```

**Casos de error comunes**:

#### **Error: ImagePullBackOff**

```bash
# Crear Pod con imagen inexistente
kubectl run error-pod --image=nginx:version-que-no-existe

# Ver el error
kubectl describe pod error-pod
```

**Eventos mostrarán**:
```
Events:
  Normal   Scheduled  pod/error-pod
  Normal   Pulling    pulling image "nginx:version-que-no-existe"
  Warning  Failed     Failed to pull image: rpc error: code = NotFound
  Warning  Failed     Error: ErrImagePull
  Normal   BackOff    Back-off pulling image
```

**Solución**:
```bash
# Eliminar Pod con error
kubectl delete pod error-pod

# Crear con imagen correcta
kubectl run nginx-ok --image=nginx:alpine
```

### **3.3 Ver Logs de un Pod**

```bash
# Ver logs del Pod
kubectl logs nginx-pod

# Seguir logs en tiempo real (-f = follow)
kubectl logs nginx-pod -f

# Ver últimas 20 líneas
kubectl logs nginx-pod --tail=20

# Logs desde hace 1 hora
kubectl logs nginx-pod --since=1h

# Logs de un contenedor específico (si hay múltiples)
kubectl logs nginx-pod -c nginx

# Logs del Pod anterior (si se reinició)
kubectl logs nginx-pod --previous
```

**Ejemplo con aplicación que loguea**:

```bash
# Crear Pod que genera logs
kubectl run log-generator --image=busybox -- sh -c \
  'while true; do echo "Log mensaje: $(date)"; sleep 2; done'

# Ver logs en tiempo real
kubectl logs log-generator -f

# Salida:
# Log mensaje: Sat Nov 9 19:30:00 UTC 2025
# Log mensaje: Sat Nov 9 19:30:02 UTC 2025
# ...
```

### **3.4 Ejecutar comandos en un Pod**

```bash
# Ejecutar comando simple
kubectl exec nginx-pod -- ls -la /usr/share/nginx/html

# Modo interactivo (-it)
kubectl exec -it nginx-pod -- sh

# Dentro del Pod:
# / # hostname
# nginx-pod
# / # cat /etc/os-release
# / # exit
```

**Ejemplo: Modificar contenido de nginx**:

```bash
# Entrar al Pod
kubectl exec -it nginx-pod -- sh

# Dentro del Pod:
cd /usr/share/nginx/html
echo "<h1>Hola desde Kubernetes!</h1>" > index.html
exit

# Verificar cambios (usando port-forward)
kubectl port-forward pod/nginx-pod 8080:80

# En otra terminal:
curl http://localhost:8080
# <h1>Hola desde Kubernetes!</h1>
```

### **3.5 Ver recursos utilizados**

```bash
# Instalar metrics-server en minikube
minikube addons enable metrics-server

# Esperar unos segundos y ver métricas


> **Objetivo**: Comprender y gestionar eficientemente los estados y transiciones de los Pods

### 2.1. Estados del Pod (Pod Phases)

Un Pod pasa por diferentes **fases** durante su ciclo de vida:

```
┌──────────────────────────────────────────────────┐
│         ESTADOS DEL CICLO DE VIDA                │
├──────────────────────────────────────────────────┤
│                                                  │
│  1. Pending      → Esperando scheduling         │
│  2. Running      → Ejecutándose normalmente     │
│  3. Succeeded    → Terminó exitosamente         │
│  4. Failed       → Terminó con error            │
│  5. Unknown      → Estado desconocido           │
│                                                  │
└──────────────────────────────────────────────────┘
```

#### **2.1.1. Pending**

**Descripción**: Pod aceptado por K8s pero contenedores no están corriendo todavía.

**Causas comunes**:
- ⏳ Scheduler buscando nodo apropiado
- 📥 Descargando imágenes
- ❌ Recursos insuficientes
- ❌ PersistentVolumeClaim no disponible

💡 **Ejemplo inline**:

```bash
# Crear Pod que permanecerá en Pending (recursos imposibles)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pending-pod
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    resources:
      requests:
        memory: "1000Gi"  # Imposible en cluster local
EOF

# Verificar estado
kubectl get pod pending-pod
# STATUS: Pending

# Ver razón específica
kubectl describe pod pending-pod | grep -A 5 "Events:"
# Insufficient memory
```

---

#### **2.1.2. Running**

**Descripción**: Pod asignado a nodo, al menos un contenedor corriendo.

**Condiciones**:
- ✅ Pod bound a un nodo
- ✅ Todos los containers creados
- ✅ Al menos 1 contenedor en estado Running

💡 **Ejemplo inline**:

```bash
# Pod simple que alcanza Running rápidamente
kubectl run healthy-pod --image=nginx:alpine

# Ver estado y detalles
kubectl get pod healthy-pod -o wide
# STATUS: Running, NODE: minikube, IP: 10.244.0.x

# Ver condiciones específicas
kubectl get pod healthy-pod -o jsonpath='{.status.conditions}' | jq
```

---

#### **2.1.3. Succeeded**

**Descripción**: Todos los contenedores terminaron exitosamente (exit code 0).

**Típico en**:
- Jobs
- Batch processing
- Scripts one-time

💡 **Ejemplo inline**:

```bash
# Pod que ejecuta script y termina
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: success-pod
spec:
  restartPolicy: Never  # No reiniciar
  containers:
  - name: task
    image: busybox
    command: ["sh", "-c", "echo 'Task completed'; exit 0"]
EOF

# Esperar y verificar
sleep 5
kubectl get pod success-pod
# STATUS: Completed (Succeeded)

# Ver logs
kubectl logs success-pod
# Output: Task completed
```

📄 **Ver ejemplo completo**: [`ejemplos/patterns/01-job-pod.yaml`](./ejemplos/patterns/01-job-pod.yaml)

---

#### **2.1.4. Failed**

**Descripción**: Al menos un contenedor terminó con error (exit code ≠ 0).

**Causas comunes**:
- 💥 Aplicación crasheó
- ❌ Command incorrecto
- ❌ OOMKilled (excedió memory limit)
- ❌ Error en código

💡 **Ejemplo inline**:

```bash
# Pod que falla intencionalmente
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: failed-pod
spec:
  restartPolicy: Never
  containers:
  - name: task
    image: busybox
    command: ["sh", "-c", "echo 'Starting...'; sleep 2; exit 1"]
EOF

# Verificar estado
sleep 5
kubectl get pod failed-pod
# STATUS: Error (Failed)

# Ver razón
kubectl describe pod failed-pod | grep -A 3 "State:"
# State: Terminated
# Exit Code: 1
```

---

#### **2.1.5. Unknown**

**Descripción**: No se puede determinar el estado (usualmente problema de comunicación).

**Causas comunes**:
- 🔌 Nodo perdió conectividad
- 💀 Kubelet no responde
- 🌐 Problemas de red

```bash
# Simular: detener minikube sin eliminar Pods
# (Solo para demostración, NO en producción)

# Ver estado
kubectl get pods
# STATUS: Unknown
```

---

### 2.2. Restart Policies

Control de cómo K8s maneja reintentos de contenedores:

```yaml
spec:
  restartPolicy: Always  # Opciones: Always, OnFailure, Never
```

| Policy | Comportamiento | Uso típico |
|--------|----------------|------------|
| `Always` | Siempre reinicia (default) | Services, long-running apps |
| `OnFailure` | Solo si exit code ≠ 0 | Jobs, batch processing |
| `Never` | Nunca reinicia | One-time tasks |

💡 **Ejemplo comparativo**:

```yaml
# Always (default)
apiVersion: v1
kind: Pod
metadata:
  name: always-restart
spec:
  restartPolicy: Always
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo 'Running'; sleep 10; exit 1"]
# Reiniciará indefinidamente

---
# OnFailure
apiVersion: v1
kind: Pod
metadata:
  name: onfailure-restart
spec:
  restartPolicy: OnFailure
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "exit 1"]
# Reiniciará solo si falla

---
# Never
apiVersion: v1
kind: Pod
metadata:
  name: never-restart
spec:
  restartPolicy: Never
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "exit 1"]
# No reiniciará, quedará en Failed
```

📄 **Ver ejemplos completos**: [`ejemplos/patterns/02-restart-policies.yaml`](./ejemplos/patterns/02-restart-policies.yaml)

---

### 2.3. Container States

Cada contenedor dentro de un Pod tiene su propio estado:

```
┌────────────────────────────────────┐
│       ESTADOS DE CONTAINER         │
├────────────────────────────────────┤
│  Waiting     → Preparándose        │
│  Running     → Ejecutándose        │
│  Terminated  → Finalizó            │
└────────────────────────────────────┘
```

```bash
# Ver estado detallado de containers
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses}' | jq

# Output ejemplo:
# {
#   "state": {
#     "running": {
#       "startedAt": "2025-11-12T10:30:00Z"
#     }
#   },
#   "ready": true,
#   "restartCount": 0
# }
```

---

### 2.4. Comandos de Gestión

#### **Crear Pods**

```bash
# Imperativo (rápido para testing)
kubectl run nginx --image=nginx:alpine

# Declarativo (recomendado para producción)
kubectl apply -f pod.yaml

# Crear desde stdin
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: quick-pod
spec:
  containers:
  - name: nginx
    image: nginx:alpine
EOF
```

#### **Actualizar Pods**

⚠️ **IMPORTANTE**: Pods son **inmutables**. Solo algunos campos se pueden modificar:

**Campos modificables**:
- `spec.containers[*].image` (solo imagen)
- `spec.activeDeadlineSeconds`
- `spec.tolerations`

**Campos NO modificables**:
- `spec.containers[*].resources`
- `spec.containers[*].command`
- `spec.containers[*].env`
- La mayoría de campos en `spec`

**Solución: Recrear**

```bash
# Opción 1: Delete + Apply
kubectl delete pod nginx-pod
kubectl apply -f pod-updated.yaml

# Opción 2: Replace --force (automático)
kubectl replace --force -f pod-updated.yaml
# Elimina y recrea en un comando
```

#### **Eliminar Pods**

```bash
# Eliminar por nombre
kubectl delete pod nginx-pod

# Eliminar por archivo
kubectl delete -f pod.yaml

# Eliminar por label
kubectl delete pods -l app=nginx

# Eliminar con grace period
kubectl delete pod nginx-pod --grace-period=30

# Forzar eliminación (⚠️ peligroso)
kubectl delete pod nginx-pod --force --grace-period=0
```

#### **Observar transiciones**

```bash
# Watch en tiempo real
kubectl get pods --watch

# Ver eventos de un Pod
kubectl get events --field-selector involvedObject.name=<pod-name> --sort-by='.lastTimestamp'

# Ver historial de reinicios
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[*].restartCount}'
```

---

### 2.5. Debugging de Estados

#### **CrashLoopBackOff**

**Síntoma**: Pod reinicia repetidamente

```bash
# Identificar problema
kubectl describe pod <pod-name>

# Ver logs del intento actual
kubectl logs <pod-name>

# Ver logs del intento anterior (crucial)
kubectl logs <pod-name> --previous

# Ver eventos
kubectl get events --field-selector involvedObject.name=<pod-name>
```

**Causas comunes**:
1. Aplicación crashea al inicio
2. Liveness probe fallando
3. Command/args incorrectos
4. Permisos insuficientes

💡 **Ejemplo inline - Pod que crashea**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: crashloop-demo
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo 'Crashing...'; exit 1"]
# STATUS: CrashLoopBackOff después de algunos segundos
```

📄 **Ver ejemplos de troubleshooting**: [`ejemplos/troubleshooting/01-crashloop.yaml`](./ejemplos/troubleshooting/01-crashloop.yaml)

---

#### **ImagePullBackOff**

**Síntoma**: No puede descargar imagen

```bash
# Ver detalles
kubectl describe pod <pod-name> | grep -A 5 "Events:"

# Causas:
# - Imagen no existe
# - Tag incorrecto
# - Registry privado sin credentials
```

---

### ✅ Checkpoint Sección 2

Antes de continuar, verifica que puedes:
- [ ] Explicar los 5 estados de un Pod
- [ ] Distinguir entre Succeeded y Failed
- [ ] Configurar restart policies apropiadamente
- [ ] Identificar por qué un Pod está en Pending
- [ ] Debuggear un CrashLoopBackOff
- [ ] Recrear un Pod para modificarlo

---

### 🧪 Laboratorio 02: Gestión del Ciclo de Vida

**Duración**: 40 minutos

📁 **Laboratorio**: [`laboratorios/lab-02-multi-contenedor-labels.md`](./laboratorios/lab-02-multi-contenedor-labels.md) *(adaptar para ciclo de vida)* o **propuesto**: `lab-02-ciclo-vida.md`

**Objetivos**:
1. Observar transiciones de estados
2. Experimentar con restart policies
3. Simular y resolver CrashLoopBackOff
4. Practicar recreación de Pods
5. Analizar eventos y logs

---

## 🏷️ 3. Labels, Selectors y Annotations

> **Objetivo**: Dominar la organización y selección de Pods mediante metadata

### 3.1. ¿Qué son los Labels?

**Labels** son pares `clave=valor` adjuntos a objetos K8s para:
- 🏷️ Organizar recursos lógicamente
- 🔍 Filtrar y buscar eficientemente
- 🎯 Permitir que Deployments/Services/ReplicaSets seleccionen Pods

```
┌─────────────────────────────────────────┐
│        LABELS vs ANNOTATIONS            │
├─────────────────────────────────────────┤
│ Labels                                  │
│  ✅ Usadas para selección               │
│  ✅ Indexadas (búsqueda rápida)         │
│  ❌ Limitadas (63 chars max value)      │
│                                         │
│ Annotations                             │
│  ❌ NO usadas para selección            │
│  ✅ Sin límite de tamaño                │
│  ✅ Metadata descriptiva                │
└─────────────────────────────────────────┘
```

**Sintaxis de labels**:
- **Clave**: `[prefijo/]nombre`
  - `prefijo` (opcional): dominio DNS (max 253 chars)
  - `nombre`: requerido (max 63 chars), alfanumérico + `-` `_` `.`
- **Valor**: max 63 chars, alfanumérico + `-` `_` `.`

💡 **Ejemplo inline - Labels comunes**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-prod
  labels:
    # Organización básica
    app: nginx                    # ¿Qué aplicación?
    environment: production       # ¿Qué ambiente?
    tier: frontend               # ¿Qué capa?
    version: "1.0.5"             # ¿Qué versión?
    
    # Gestión operacional
    team: platform               # ¿Quién es responsable?
    cost-center: marketing       # ¿Quién paga?
    
    # Release management
    release: stable              # ¿Qué canal?
    track: daily                 # ¿Qué track?
```

```bash
# Crear Pod con labels
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: labeled-pod
  labels:
    app: nginx
    environment: production
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx:alpine
EOF

# Ver labels
kubectl get pod labeled-pod --show-labels
# NAME          READY   STATUS    LABELS
# labeled-pod   1/1     Running   app=nginx,environment=production,tier=frontend
```

---

### 3.2. Selectors (Filtrado)

#### **3.2.1. Equality-based (Igualdad)**

```bash
# app = frontend
kubectl get pods -l app=frontend

# app != frontend
kubectl get pods -l app!=frontend

# environment = production
kubectl get pods -l environment=production
```

#### **3.2.2. Set-based (Conjuntos)**

```bash
# environment IN (production, staging)
kubectl get pods -l 'environment in (production,staging)'

# tier NOT IN (backend)
kubectl get pods -l 'tier notin (backend)'

# EXISTS: tiene label "version"
kubectl get pods -l version

# NOT EXISTS: NO tiene label "version"
kubectl get pods -l '!version'
```

#### **3.2.3. Combinación (AND)**

```bash
# app=frontend AND environment=production
kubectl get pods -l 'app=frontend,environment=production'

# tier=frontend AND version in (1.0, 2.0)
kubectl get pods -l 'tier=frontend,version in (1.0,2.0)'
```

💡 **Ejemplo práctico - Filtrado avanzado**:

```bash
# Crear conjunto de Pods para demostración
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: frontend-prod
  labels:
    app: frontend
    environment: production
    tier: web
    version: "1.0"
spec:
  containers:
  - name: nginx
    image: nginx:alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend-dev
  labels:
    app: frontend
    environment: development
    tier: web
    version: "1.1"
spec:
  containers:
  - name: nginx
    image: nginx:alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: backend-prod
  labels:
    app: backend
    environment: production
    tier: api
    version: "2.0"
spec:
  containers:
  - name: nginx
    image: nginx:alpine
EOF

# Filtros prácticos
kubectl get pods -l app=frontend
# Resultado: frontend-prod, frontend-dev

kubectl get pods -l environment=production
# Resultado: frontend-prod, backend-prod

kubectl get pods -l 'app=frontend,environment=production'
# Resultado: solo frontend-prod

kubectl get pods -l 'tier in (web,api),environment=production'
# Resultado: frontend-prod, backend-prod

# Mostrar labels como columnas
kubectl get pods -L app,environment,tier,version
```

📄 **Ver ejemplos completos**: [`ejemplos/basicos/pods-con-labels.yaml`](./ejemplos/basicos/pods-con-labels.yaml)

---

### 3.3. Gestión de Labels

#### **Agregar labels**

```bash
# Agregar label a Pod existente
kubectl label pod frontend-prod team=platform

# Agregar múltiples labels
kubectl label pod frontend-prod cost-center=marketing release=stable

# Ver cambio
kubectl get pod frontend-prod --show-labels
```

#### **Modificar labels**

```bash
# Sobrescribir valor (requiere --overwrite)
kubectl label pod frontend-prod version=1.1 --overwrite

# Sin --overwrite falla
kubectl label pod frontend-prod version=1.2
# Error: already has a value (1.1)
```

#### **Eliminar labels**

```bash
# Eliminar label específico (usar -)
kubectl label pod frontend-prod team-

# Verificar eliminación
kubectl get pod frontend-prod --show-labels
```

#### **Labels en selección de recursos**

```bash
# Eliminar todos los Pods con label app=frontend
kubectl delete pods -l app=frontend

# Eliminar Pods en development
kubectl delete pods -l environment=development

# Ver recursos sin eliminación (dry-run)
kubectl delete pods -l tier=web --dry-run=client
```

---

### 3.4. Annotations

**Annotations** son metadata NO usada para selección. Útiles para:
- 📝 Documentación
- 🔧 Información de tooling
- 📊 Tracking de cambios
- 🔗 URLs de dashboards

💡 **Ejemplo inline - Annotations vs Labels**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: annotated-pod
  labels:
    # Labels: PARA SELECCIÓN
    app: nginx
    environment: production
  
  annotations:
    # Annotations: METADATA DESCRIPTIVA
    description: "Frontend web server for product catalog"
    buildVersion: "build-1234"
    imageRepository: "https://hub.docker.com/_/nginx"
    lastModified: "2025-01-15T10:30:00Z"
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    contact: "platform-team@company.com"
spec:
  containers:
  - name: nginx
    image: nginx:alpine
```

```bash
# Crear Pod con annotations
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: annotated-pod
  labels:
    app: nginx
  annotations:
    description: "Production nginx server"
    buildVersion: "v1.2.3"
    contact: "devops@company.com"
spec:
  containers:
  - name: nginx
    image: nginx:alpine
EOF

# Ver annotations
kubectl describe pod annotated-pod | grep -A 10 "Annotations:"

# Agregar annotation
kubectl annotate pod annotated-pod lastRestart="2025-01-15T14:00:00Z"

# Modificar annotation (requiere --overwrite)
kubectl annotate pod annotated-pod buildVersion="v1.2.4" --overwrite

# Eliminar annotation
kubectl annotate pod annotated-pod contact-
```

**¿Cuándo usar annotations vs labels?**

| Criterio | Labels | Annotations |
|----------|--------|-------------|
| **Selección por Services/Deployments** | ✅ Sí | ❌ No |
| **Filtrar con `-l`** | ✅ Sí | ❌ No |
| **Límite de tamaño** | 63 chars | Sin límite práctico |
| **Documentación extensa** | ❌ No | ✅ Sí |
| **URLs/JSON/metadata compleja** | ❌ No | ✅ Sí |

---

### 3.5. Use Cases Prácticos

#### **Caso 1: Deployment que selecciona Pods**

```yaml
# Pod con labels específicos
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  labels:
    app: webserver    # ← Deployment seleccionará esto
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx:alpine
---
# Deployment que usa selector
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webserver  # ← Coincide con Pod labels
  template:
    metadata:
      labels:
        app: webserver
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
```

#### **Caso 2: Segregación por ambientes**

```bash
# Crear Pods en diferentes ambientes
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: db-prod
  labels:
    app: database
    environment: production
spec:
  containers:
  - name: postgres
    image: postgres:alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: db-dev
  labels:
    app: database
    environment: development
spec:
  containers:
  - name: postgres
    image: postgres:alpine
EOF

# Operaciones selectivas
kubectl get pods -l environment=production
kubectl delete pods -l environment=development

# Escalar solo production
# (usado en Deployments/ReplicaSets)
```

#### **Caso 3: Canary deployments**

```yaml
# 95% de tráfico a stable
apiVersion: v1
kind: Pod
metadata:
  name: app-stable
  labels:
    app: myapp
    track: stable    # ← Service selecciona esto
spec:
  containers:
  - name: app
    image: myapp:v1.0
---
# 5% de tráfico a canary
apiVersion: v1
kind: Pod
metadata:
  name: app-canary
  labels:
    app: myapp
    track: canary    # ← Service también selecciona esto
spec:
  containers:
  - name: app
    image: myapp:v2.0-beta
```

📄 **Ver ejemplos avanzados**: [`ejemplos/patterns/03-labels-advanced.yaml`](./ejemplos/patterns/03-labels-advanced.yaml)

---

### ✅ Checkpoint Sección 3

Antes de continuar, verifica que puedes:
- [ ] Explicar diferencia entre labels y annotations
- [ ] Crear Pods con labels específicos
- [ ] Filtrar Pods con equality-based selectors
- [ ] Filtrar Pods con set-based selectors
- [ ] Combinar múltiples condiciones (AND)
- [ ] Agregar/modificar/eliminar labels dinámicamente
- [ ] Decidir cuándo usar label vs annotation
- [ ] Entender cómo Deployments seleccionan Pods

---

### 🧪 Laboratorio 03: Labels y Selectors

**Duración**: 30 minutos

📁 **Laboratorio**: [`laboratorios/lab-02-multi-contenedor-labels.md`](./laboratorios/lab-02-multi-contenedor-labels.md) *(incluye labels)* o **propuesto**: `lab-03-labels-selectors.md`

**Objetivos**:
1. Crear Pods con estrategia de labels multi-dimensionales
2. Practicar filtrado avanzado con selectors
3. Simular canary deployment con labels
4. Gestionar labels dinámicamente
5. Diferenciar annotations de labels en casos reales

---

## ⚙️ 4. Resource Management: Requests y Limits

> **Objetivo**: Optimizar uso de recursos y garantizar estabilidad mediante requests y limits

### 4.1. ¿Por qué gestionar recursos?

**Sin límites**:
- 💥 Un Pod puede consumir todos los recursos del nodo
- 💥 Otros Pods mueren por falta de recursos (OOMKilled)
- 💥 Nodo completo puede volverse inestable

**Con límites**:
- ✅ Recursos garantizados (requests)
- ✅ Protección contra consumo excesivo (limits)
- ✅ Scheduler puede decidir placement óptimo
- ✅ QoS (Quality of Service) classes automáticas

```
┌────────────────────────────────────────────┐
│        REQUESTS vs LIMITS                  │
├────────────────────────────────────────────┤
│                                            │
│  Requests                                  │
│  • Recursos GARANTIZADOS                   │
│  • Scheduler usa esto para placement       │
│  • Pod puede usar MÁS si hay disponible    │
│                                            │
│  Limits                                    │
│  • Recursos MÁXIMOS                        │
│  • CPU: throttling                         │
│  • Memory: OOMKilled si excede             │
│                                            │
└────────────────────────────────────────────┘
```

---

### 4.2. Requests (Garantías)

**Requests** = mínimo garantizado que el Pod necesita.

💡 **Ejemplo inline - Requests básico**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-requests
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        memory: "64Mi"   # 64 mebibytes garantizados
        cpu: "250m"      # 250 millicores = 0.25 CPU garantizados
```

```bash
# Crear Pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-requests
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
EOF

# Ver recursos asignados
kubectl describe pod pod-with-requests | grep -A 5 "Requests:"

# Output:
#   Requests:
#     cpu:        250m
#     memory:     64Mi
```

**Unidades de medida**:

| Recurso | Unidades | Ejemplos |
|---------|----------|----------|
| **CPU** | millicores (m) | `100m` = 0.1 CPU<br>`500m` = 0.5 CPU<br>`1` = 1 CPU<br>`2` = 2 CPUs |
| **Memory** | bytes, Ki, Mi, Gi | `128Mi` = 128 mebibytes<br>`1Gi` = 1 gibibyte<br>`512000000` = 512 MB |

**Comportamiento del Scheduler**:

```bash
# Si nodo tiene solo 1 CPU disponible
# Pod con request 500m ✅ se programa
# Pod con request 1500m ❌ queda Pending
```

💡 **Ejemplo - Pod que no cabe**:

```bash
# Crear Pod con request imposible
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: impossible-request
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        memory: "1000Gi"  # 1 TB - imposible en minikube
        cpu: "100"        # 100 CPUs - imposible
EOF

# Ver estado
kubectl get pod impossible-request
# STATUS: Pending

# Ver razón
kubectl describe pod impossible-request | grep -A 5 "Events:"
# Warning: FailedScheduling - Insufficient cpu/memory
```

---

### 4.3. Limits (Restricciones)

**Limits** = máximo que el Pod puede consumir.

💡 **Ejemplo inline - Limits básico**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-limits
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"   # Máximo 128Mi (si excede → OOMKilled)
        cpu: "500m"       # Máximo 0.5 CPU (si excede → throttling)
```

**Comportamiento al exceder limits**:

| Recurso | Comportamiento |
|---------|----------------|
| **CPU** | 🐢 **Throttling** - se ralentiza, NO se mata |
| **Memory** | 💀 **OOMKilled** - se termina el contenedor |

💡 **Ejemplo - Memory OOMKilled**:

```bash
# Crear Pod con memory limit bajo
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: oom-demo
spec:
  containers:
  - name: memory-hog
    image: polinux/stress
    resources:
      requests:
        memory: "50Mi"
      limits:
        memory: "100Mi"
    command: ["stress"]
    args:
    - "--vm"
    - "1"
    - "--vm-bytes"
    - "150M"  # ← Intenta usar 150Mi, limit es 100Mi
    - "--vm-hang"
    - "1"
EOF

# Observar estado
kubectl get pod oom-demo --watch
# Verás: Running → OOMKilled → CrashLoopBackOff

# Ver razón
kubectl describe pod oom-demo | grep -A 3 "Last State:"
# Last State:     Terminated
#   Reason:       OOMKilled
#   Exit Code:    137
```

📄 **Ver ejemplo completo**: [`ejemplos/production-ready/02-resources.yaml`](./ejemplos/production-ready/02-resources.yaml)

---

### 4.4. QoS Classes (Quality of Service)

Kubernetes asigna automáticamente una **QoS class** según requests/limits:

```
┌───────────────────────────────────────────────────┐
│              QoS CLASSES                          │
├───────────────────────────────────────────────────┤
│                                                   │
│  1. Guaranteed (más prioritario)                 │
│     requests = limits (ambos CPU y Memory)       │
│     Último en ser evicted                        │
│                                                   │
│  2. Burstable (prioridad media)                  │
│     requests < limits (o solo requests)          │
│     Evicted si nodo bajo presión                 │
│                                                   │
│  3. BestEffort (menos prioritario)               │
│     Sin requests ni limits                       │
│     Primer en ser evicted                        │
│                                                   │
└───────────────────────────────────────────────────┘
```

💡 **Ejemplo inline - QoS classes**:

```yaml
# 1. Guaranteed
apiVersion: v1
kind: Pod
metadata:
  name: guaranteed-pod
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        memory: "128Mi"
        cpu: "500m"
      limits:
        memory: "128Mi"  # ← Igual a requests
        cpu: "500m"      # ← Igual a requests
# QoS Class: Guaranteed

---
# 2. Burstable
apiVersion: v1
kind: Pod
metadata:
  name: burstable-pod
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"  # ← Mayor a requests
        cpu: "500m"      # ← Mayor a requests
# QoS Class: Burstable

---
# 3. BestEffort
apiVersion: v1
kind: Pod
metadata:
  name: besteffort-pod
spec:
  containers:
  - name: app
    image: nginx:alpine
    # Sin resources
# QoS Class: BestEffort
```

```bash
# Crear los 3 Pods
kubectl apply -f - <<EOF
[copiar YAMLs de arriba]
EOF

# Ver QoS class
kubectl get pod guaranteed-pod -o jsonpath='{.status.qosClass}'
# Output: Guaranteed

kubectl get pod burstable-pod -o jsonpath='{.status.qosClass}'
# Output: Burstable

kubectl get pod besteffort-pod -o jsonpath='{.status.qosClass}'
# Output: BestEffort

# Ver en describe
kubectl describe pod guaranteed-pod | grep "QoS Class:"
```

**Orden de eviction** (cuando nodo sin recursos):
1. BestEffort primero 💥
2. Burstable después 💥
3. Guaranteed último 💥

---

### 4.5. Monitoring de Recursos

```bash
# Ver consumo actual de CPU/Memory
kubectl top pods

# Output:
# NAME        CPU(cores)   MEMORY(bytes)
# nginx-pod   1m           3Mi

# Ver recursos configurados vs consumo
kubectl describe pod nginx-pod | grep -A 10 "Limits:"

# Comparar request vs limit vs actual
kubectl get pod nginx-pod -o json | jq '.spec.containers[0].resources'
kubectl top pod nginx-pod
```

**Instalar Metrics Server** (si no está disponible):

```bash
# Verificar si existe
kubectl top nodes

# Si falla, instalar en minikube
minikube addons enable metrics-server

# Esperar 30 segundos y probar
kubectl top pods
```

---

### 4.6. Best Practices - Resource Management

#### **1. SIEMPRE define requests**

```yaml
# ❌ MAL - Sin requests
spec:
  containers:
  - name: app
    image: myapp

# ✅ BIEN - Con requests
spec:
  containers:
  - name: app
    image: myapp
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
```

**Razón**: Scheduler necesita requests para placement óptimo.

---

#### **2. Define limits para evitar resource hogging**

```yaml
# ✅ RECOMENDADO - Requests + Limits
spec:
  containers:
  - name: app
    image: myapp
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"  # 2x requests
        cpu: "500m"      # 5x requests (permite bursting)
```

---

#### **3. Calcular requests apropiados**

```bash
# Método empírico:
# 1. Desplegar sin limits
# 2. Observar consumo real con load
kubectl top pods --containers
# 3. Configurar:
#    requests = consumo promedio
#    limits = consumo pico + 20% buffer
```

---

#### **4. Memory: límites conservadores**

```yaml
# Memory:
# - Exceder limit = OOMKilled (servicio muere)
# - Usar limits realistas
resources:
  requests:
    memory: "256Mi"
  limits:
    memory: "512Mi"  # Solo 2x, no 10x
```

---

#### **5. CPU: límites generosos**

```yaml
# CPU:
# - Exceder limit = throttling (solo lentitud)
# - Permitir bursting para picos de tráfico
resources:
  requests:
    cpu: "100m"      # Normal load
  limits:
    cpu: "1"         # 10x para picos (OK)
```

---

### 4.7. Troubleshooting Resources

#### **Pending por recursos insuficientes**

```bash
# Síntoma
kubectl get pods
# STATUS: Pending

# Diagnóstico
kubectl describe pod <pod-name> | grep -A 5 "Events:"
# Warning: FailedScheduling - Insufficient cpu/memory

# Soluciones:
# 1. Reducir requests del Pod
# 2. Agregar más nodos al cluster
# 3. Escalar down otros Pods
```

---

#### **OOMKilled repetidamente**

```bash
# Síntoma
kubectl get pods
# STATUS: CrashLoopBackOff

# Diagnóstico
kubectl describe pod <pod-name> | grep "Reason:"
# Reason: OOMKilled

# Ver memory actual vs limit
kubectl top pod <pod-name>
kubectl describe pod <pod-name> | grep -A 3 "Limits:"

# Solución: Incrementar memory limit
# requests:
#   memory: "256Mi"
# limits:
#   memory: "512Mi"  ← Incrementar esto
```

---

#### **CPU Throttling**

```bash
# Diagnóstico
kubectl top pods
# CPU(cores) cerca de limit pero pod lento

# Ver throttling metrics (requiere monitoring avanzado)
# Solución: Incrementar CPU limit
```

---

### ✅ Checkpoint Sección 4

Antes de continuar, verifica que puedes:
- [ ] Explicar diferencia entre requests y limits
- [ ] Configurar resources en un Pod
- [ ] Entender unidades (millicores, Mi, Gi)
- [ ] Predecir comportamiento al exceder limit (CPU vs Memory)
- [ ] Identificar las 3 QoS classes
- [ ] Diagnosticar un Pod Pending por recursos
- [ ] Resolver un OOMKilled ajustando limits
- [ ] Usar `kubectl top` para monitoring

---

### 🧪 Laboratorio 04: Resource Management

**Duración**: 50 minutos

📁 **Laboratorio propuesto**: `laboratorios/lab-04-resources.md` *(pendiente de crear)*

**Objetivos**:
1. Configurar requests y limits apropiados
2. Observar comportamiento de QoS classes
3. Simular y resolver OOMKilled
4. Practicar cálculo de recursos óptimos
5. Implementar resource quotas a nivel namespace

---

## 💊 5. Health Checks: Probes

> **Objetivo**: Garantizar que Kubernetes solo envíe tráfico a Pods sanos y reinicie Pods problemáticos automáticamente

### 5.1. ¿Por qué necesitamos Health Checks?

**Sin probes**:
- 💥 Pod puede estar "Running" pero app crasheada internamente
- 💥 Traffic enviado a Pods que no están listos
- 💥 Pods muertos que K8s cree que están sanos
- 💥 Deadlocks no detectados

**Con probes**:
- ✅ Detección automática de problemas
- ✅ Restart automático de Pods enfermos
- ✅ Traffic solo a Pods completamente listos
- ✅ Tiempo de recuperación optimizado

```
┌───────────────────────────────────────────────────┐
│           TIPOS DE PROBES                         │
├───────────────────────────────────────────────────┤
│                                                   │
│  1. Liveness Probe                               │
│     ¿Está VIVO el contenedor?                    │
│     Si falla → Kubernetes REINICIA el Pod        │
│                                                   │
│  2. Readiness Probe                              │
│     ¿Está LISTO para recibir tráfico?           │
│     Si falla → Se ELIMINA de endpoints           │
│                                                   │
│  3. Startup Probe                                │
│     ¿Completó el arranque inicial?              │
│     Protege apps con startup lento               │
│                                                   │
└───────────────────────────────────────────────────┘
```

---

### 5.2. Liveness Probe (¿Está vivo?)

**Propósito**: Detectar si el contenedor está muerto/bloqueado y necesita reiniciarse.

**Cuándo falla**: K8s **mata y reinicia** el contenedor.

💡 **Ejemplo inline - HTTP Liveness Probe**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-http
spec:
  containers:
  - name: web
    image: nginx:alpine
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /         # ← Endpoint a verificar
        port: 80
      initialDelaySeconds: 5   # Esperar 5s antes de primera prueba
      periodSeconds: 10        # Probar cada 10s
      timeoutSeconds: 1        # Timeout de 1s
      failureThreshold: 3      # 3 fallos consecutivos = reiniciar
```

```bash
# Crear Pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: liveness-http
spec:
  containers:
  - name: web
    image: nginx:alpine
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
      timeoutSeconds: 1
      failureThreshold: 3
EOF

# Ver eventos de liveness
kubectl describe pod liveness-http | grep -A 10 "Liveness:"

# Simular fallo: detener nginx dentro del contenedor
kubectl exec liveness-http -- sh -c "killall nginx"

# Observar reinicio automático
kubectl get pod liveness-http --watch
# Verás RESTARTS incrementar
```

---

#### **5.2.1. Tipos de Liveness Probes**

**A. HTTP GET**

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
    httpHeaders:
    - name: Custom-Header
      value: Awesome
  initialDelaySeconds: 3
  periodSeconds: 3
```

**Uso**: APIs REST, web servers.

---

**B. TCP Socket**

```yaml
livenessProbe:
  tcpSocket:
    port: 3306
  initialDelaySeconds: 15
  periodSeconds: 10
```

**Uso**: Databases (MySQL, PostgreSQL), servicios que no tienen HTTP.

---

**C. Exec Command**

```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  initialDelaySeconds: 5
  periodSeconds: 5
```

**Uso**: Custom health checks, file-based readiness.

💡 **Ejemplo práctico - Exec Liveness**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
EOF

# Observar comportamiento
kubectl get pod liveness-exec --watch

# Después de 30s, archivo se elimina → probe falla → Pod reinicia
# RESTARTS: 0 → 1 → 2 → ...
```

📄 **Ver ejemplos completos**: [`ejemplos/production-ready/03-health-checks.yaml`](./ejemplos/production-ready/03-health-checks.yaml)

---

### 5.3. Readiness Probe (¿Está listo?)

**Propósito**: Determinar si el Pod está listo para recibir tráfico.

**Cuándo falla**: K8s **NO envía tráfico** al Pod (se elimina de Service endpoints).

💡 **Diferencia clave con Liveness**:

| Probe | Si falla... |
|-------|-------------|
| **Liveness** | 💀 Contenedor se REINICIA |
| **Readiness** | 🚫 Pod se ELIMINA de endpoints (sin reinicio) |

💡 **Ejemplo inline - Readiness Probe**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-demo
  labels:
    app: web
spec:
  containers:
  - name: web
    image: nginx:alpine
    ports:
    - containerPort: 80
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 3
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 15
      periodSeconds: 10
```

```bash
# Crear Pod con readiness
kubectl apply -f - <<EOF
[usar YAML de arriba]
EOF

# Ver estado READY
kubectl get pod readiness-demo
# NAME             READY   STATUS    RESTARTS
# readiness-demo   1/1     Running   0

# Simular fallo de readiness (detener nginx)
kubectl exec readiness-demo -- sh -c "killall nginx"

# Ver estado cambia a NOT READY
kubectl get pod readiness-demo
# NAME             READY   STATUS    RESTARTS
# readiness-demo   0/1     Running   0

# Readiness falla, pero Pod NO se reinicia
# Solo se marca como "Not Ready"
```

**Caso de uso típico**: App necesita cargar configuración, conectar a DB, etc.

```yaml
readinessProbe:
  httpGet:
    path: /api/ready  # ← Endpoint que verifica: DB conectada, configs cargadas
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
```

---

### 5.4. Startup Probe (¿Completó el inicio?)

**Propósito**: Proteger apps con **startup lento** (30s+) de ser matadas prematuramente.

**Comportamiento**:
- ✅ Startup Probe se ejecuta **primero**
- ⏸️ Liveness/Readiness se **pausan** hasta que Startup tenga éxito
- ⏰ Permite más tiempo para arranque inicial

💡 **Ejemplo inline - App con startup lento**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: slow-startup
spec:
  containers:
  - name: app
    image: myapp:v1
    ports:
    - containerPort: 8080
    
    # Startup probe: permite hasta 5 min para arrancar
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 0
      periodSeconds: 10
      failureThreshold: 30     # 30 intentos × 10s = 5 minutos máximo
    
    # Liveness: una vez started, verificar cada 10s
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 10
      failureThreshold: 3      # Solo 30s después de startup
    
    # Readiness: verificar si listo para tráfico
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      periodSeconds: 5
```

**Flujo temporal**:

```
t=0s    → Startup probe inicia (cada 10s, hasta 30 intentos)
        → Liveness/Readiness PAUSADOS

t=120s  → Startup probe OK (app finalmente arrancó)
        → Liveness probe ACTIVO (cada 10s)
        → Readiness probe ACTIVO (cada 5s)

t=130s  → Si liveness falla 3 veces consecutivas → REINICIO
        → Si readiness falla → eliminar de endpoints
```

📄 **Ver ejemplo completo**: [`ejemplos/production-ready/04-startup-probe.yaml`](./ejemplos/production-ready/04-startup-probe.yaml)

---

### 5.5. Configuración de Probes

#### **Parámetros clave**

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  
  initialDelaySeconds: 10    # ⏰ Esperar antes de primera prueba
  periodSeconds: 10          # 🔁 Frecuencia de pruebas
  timeoutSeconds: 1          # ⏱️ Timeout por prueba
  successThreshold: 1        # ✅ Éxitos consecutivos para "healthy"
  failureThreshold: 3        # ❌ Fallos consecutivos para "unhealthy"
```

| Parámetro | Liveness | Readiness | Startup |
|-----------|----------|-----------|---------|
| `initialDelaySeconds` | ✅ Sí | ✅ Sí | ✅ Sí |
| `periodSeconds` | ✅ Sí | ✅ Sí | ✅ Sí |
| `timeoutSeconds` | ✅ Sí | ✅ Sí | ✅ Sí |
| `successThreshold` | ❌ Siempre 1 | ✅ Sí | ❌ Siempre 1 |
| `failureThreshold` | ✅ Sí | ✅ Sí | ✅ Sí |

---

#### **5.5.1. Cálculo de tiempos**

**Tiempo máximo hasta reinicio (Liveness)**:

```
Tiempo = initialDelaySeconds + (periodSeconds × failureThreshold)

Ejemplo:
initialDelaySeconds: 10
periodSeconds: 5
failureThreshold: 3

Tiempo = 10 + (5 × 3) = 25 segundos
```

**Tiempo máximo de startup (Startup)**:

```
Tiempo = initialDelaySeconds + (periodSeconds × failureThreshold)

Ejemplo:
initialDelaySeconds: 0
periodSeconds: 10
failureThreshold: 30

Tiempo = 0 + (10 × 30) = 300 segundos (5 minutos)
```

---

### 5.6. Best Practices - Health Checks

#### **1. SIEMPRE define readiness probe**

```yaml
# ✅ BIEN
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

**Razón**: Evita tráfico a Pods no listos durante deploys.

---

#### **2. Liveness probe diferente de readiness**

```yaml
# ❌ MAL - mismo endpoint
livenessProbe:
  httpGet:
    path: /healthz
readinessProbe:
  httpGet:
    path: /healthz  # ← Mismo endpoint

# ✅ BIEN - endpoints diferentes
livenessProbe:
  httpGet:
    path: /healthz/live   # ← Solo verifica si proceso vive
readinessProbe:
  httpGet:
    path: /healthz/ready  # ← Verifica DB, cache, etc.
```

---

#### **3. Liveness: checks simples y rápidos**

```yaml
# ❌ MAL - liveness que verifica DB
livenessProbe:
  httpGet:
    path: /api/check-db  # ← Si DB falla, reinicia Pod innecesariamente
  
# ✅ BIEN - liveness simple
livenessProbe:
  httpGet:
    path: /ping  # ← Solo verifica si app responde
```

**Razón**: Liveness debe verificar si el **proceso está vivo**, no dependencias externas.

---

#### **4. Readiness: checks comprehensivos**

```yaml
# ✅ BIEN - readiness verifica dependencias
readinessProbe:
  httpGet:
    path: /api/ready  # ← Verifica: DB conectada, cache ready, configs cargadas
```

---

#### **5. Usar startup probe para apps lentas**

```yaml
# App que tarda 2 minutos en arrancar

# ❌ MAL - sin startup probe
livenessProbe:
  httpGet:
    path: /healthz
  initialDelaySeconds: 120  # ← Delay muy largo para TODO el lifetime
  periodSeconds: 10

# ✅ BIEN - con startup probe
startupProbe:
  httpGet:
    path: /healthz
  periodSeconds: 10
  failureThreshold: 18  # 3 minutos máximo para startup

livenessProbe:
  httpGet:
    path: /healthz
  periodSeconds: 10  # ← Después de startup, checks cada 10s
```

---

#### **6. Valores recomendados**

```yaml
# Fast-starting apps (< 10s)
livenessProbe:
  initialDelaySeconds: 5
  periodSeconds: 10
  timeoutSeconds: 1
  failureThreshold: 3

readinessProbe:
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 1
  failureThreshold: 3

# Slow-starting apps (> 30s)
startupProbe:
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 30  # 5 minutos

livenessProbe:
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  periodSeconds: 5
  failureThreshold: 3
```

---

### 5.7. Debugging Probes

#### **Ver estado de probes**

```bash
# Ver eventos de probes
kubectl describe pod <pod-name> | grep -A 10 "Liveness:"
kubectl describe pod <pod-name> | grep -A 10 "Readiness:"

# Ver eventos recientes
kubectl get events --field-selector involvedObject.name=<pod-name>

# Filtrar solo eventos de probes
kubectl get events --field-selector involvedObject.name=<pod-name> \
  | grep -i "liveness\|readiness\|startup"
```

---

#### **Probe fallando - Diagnóstico**

```bash
# Síntoma: Pod con RESTARTS incrementando
kubectl get pods
# NAME      READY   STATUS    RESTARTS
# my-pod    1/1     Running   5        ← Liveness probe fallando

# Ver razón
kubectl describe pod my-pod | grep -A 5 "Liveness:"
# Liveness: http-get http://:8080/healthz delay=0s timeout=1s period=10s
# Warning  Unhealthy  Liveness probe failed: HTTP probe failed with statuscode: 500

# Probar manualmente el endpoint
kubectl port-forward pod/my-pod 8080:8080
curl http://localhost:8080/healthz
# Analizar respuesta
```

---

#### **Readiness probe fallando**

```bash
# Síntoma: Pod Running pero 0/1 READY
kubectl get pods
# NAME      READY   STATUS    RESTARTS
# my-pod    0/1     Running   0        ← Readiness probe fallando

# Ver endpoints del Service
kubectl get endpoints my-service
# ENDPOINTS: <none>  ← Pod no aparece porque no está "ready"

# Diagnosticar
kubectl describe pod my-pod | grep -A 5 "Readiness:"
# Ver logs
kubectl logs my-pod
```

---

### ✅ Checkpoint Sección 5

Antes de continuar, verifica que puedes:
- [ ] Explicar diferencia entre liveness, readiness, y startup probes
- [ ] Configurar los 3 tipos de probes (HTTP, TCP, Exec)
- [ ] Calcular tiempo máximo hasta reinicio con failureThreshold
- [ ] Decidir cuándo usar startup probe vs solo liveness
- [ ] Diseñar endpoints /healthz/live y /healthz/ready apropiadamente
- [ ] Diagnosticar por qué un Pod reinicia repetidamente
- [ ] Diagnosticar por qué un Pod no recibe tráfico

---

### 🧪 Laboratorio 05: Health Checks y Probes

**Duración**: 60 minutos

📁 **Laboratorio propuesto**: `laboratorios/lab-05-health-checks.md` *(pendiente de crear)*

**Objetivos**:
1. Implementar liveness probe y observar reinicios automáticos
2. Implementar readiness probe y verificar eliminación de endpoints
3. Usar startup probe para app con arranque lento
4. Simular y resolver fallos de probes
5. Optimizar configuración de probes para diferentes escenarios

---

## 🔒 6. Security Contexts

> **Objetivo**: Endurecer Pods mediante configuraciones de seguridad para reducir superficie de ataque

### 6.1. ¿Qué es un Security Context?

**Security Context** = configuraciones de seguridad a nivel de Pod o Container.

**Sin Security Context**:
- 💥 Contenedores corren como root (UID 0)
- 💥 Acceso completo al filesystem
- 💥 Capabilities privilegiadas activadas
- 💥 Mayor superficie de ataque

**Con Security Context**:
- ✅ Contenedores corren como usuario no-root
- ✅ Filesystem read-only
- ✅ Capabilities mínimas necesarias
- ✅ Defensa en profundidad

```
┌─────────────────────────────────────────────────┐
│         NIVELES DE SECURITY CONTEXT             │
├─────────────────────────────────────────────────┤
│                                                 │
│  Pod-level (spec.securityContext)              │
│  ├─ Aplica a TODOS los containers              │
│  ├─ runAsUser, fsGroup, etc.                   │
│  └─ Valores por defecto                        │
│                                                 │
│  Container-level (spec.containers[].securityContext)│
│  ├─ Sobrescribe valores de Pod-level           │
│  ├─ Más específico                             │
│  └─ Prioridad sobre Pod-level                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

### 6.2. runAsUser y runAsGroup

**Problema**: Por defecto, contenedores pueden correr como root (UID 0).

💡 **Ejemplo inline - runAsUser**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000      # ← UID del usuario
    runAsGroup: 3000     # ← GID del grupo
    fsGroup: 2000        # ← GID para volumes
  containers:
  - name: sec-ctx-demo
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
```

```bash
# Crear Pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: security-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
  containers:
  - name: demo
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
EOF

# Verificar UID/GID dentro del contenedor
kubectl exec security-demo -- id
# Output:
# uid=1000 gid=3000 groups=3000

# Comparar con Pod sin securityContext (corre como root)
kubectl run insecure --image=busybox --command -- sleep 3600
kubectl exec insecure -- id
# Output:
# uid=0(root) gid=0(root) groups=0(root)
```

**Niveles de aplicación**:

```yaml
# Pod-level (aplica a todos los containers)
apiVersion: v1
kind: Pod
metadata:
  name: pod-level-security
spec:
  securityContext:
    runAsUser: 1000     # ← Todos los containers como UID 1000
  containers:
  - name: container1
    image: nginx:alpine
  - name: container2
    image: busybox
    command: ["sleep", "3600"]

---
# Container-level (sobrescribe Pod-level)
apiVersion: v1
kind: Pod
metadata:
  name: container-level-security
spec:
  securityContext:
    runAsUser: 1000     # ← Default para todos
  containers:
  - name: container1
    image: nginx:alpine
    # Usa UID 1000 (heredado)
  
  - name: container2
    image: busybox
    command: ["sleep", "3600"]
    securityContext:
      runAsUser: 2000   # ← Sobrescribe, usa UID 2000
```

---

### 6.3. runAsNonRoot

**Forzar ejecución como no-root**: prevenir contenedores que arrancan como root.

💡 **Ejemplo inline - runAsNonRoot**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-root-pod
spec:
  securityContext:
    runAsNonRoot: true   # ← K8s verifica que no sea root
    runAsUser: 1000
  containers:
  - name: app
    image: nginx:alpine
```

```bash
# Pod que FALLA si intenta correr como root
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: must-run-as-nonroot
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - name: nginx
    image: nginx:alpine
    # nginx por defecto corre como root → FALLA
EOF

# Ver error
kubectl describe pod must-run-as-nonroot
# Error: container has runAsNonRoot and image will run as root

# Solución: especificar runAsUser
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: runs-as-nonroot
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000     # ← Especificar usuario no-root
  containers:
  - name: nginx
    image: nginx:alpine
EOF
```

---

### 6.4. allowPrivilegeEscalation

**Prevenir escalada de privilegios**: evitar que procesos obtengan más privilegios que su padre.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: no-privilege-escalation
spec:
  containers:
  - name: app
    image: nginx:alpine
    securityContext:
      allowPrivilegeEscalation: false  # ← No permitir sudo, setuid, etc.
```

💡 **Ejemplo comparativo**:

```bash
# Con privilege escalation (INSEGURO)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: with-escalation
spec:
  containers:
  - name: app
    image: ubuntu
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: true
EOF

# Sin privilege escalation (SEGURO)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: no-escalation
spec:
  containers:
  - name: app
    image: ubuntu
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: false
EOF
```

---

### 6.5. readOnlyRootFilesystem

**Filesystem inmutable**: prevenir escritura en `/` (root filesystem).

💡 **Ejemplo inline - readOnlyRootFilesystem**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readonly-fs
spec:
  containers:
  - name: app
    image: nginx:alpine
    securityContext:
      readOnlyRootFilesystem: true  # ← No se puede escribir en /
    volumeMounts:
    - name: cache-volume
      mountPath: /var/cache/nginx   # ← Excepción: volume writable
    - name: run-volume
      mountPath: /var/run
  volumes:
  - name: cache-volume
    emptyDir: {}
  - name: run-volume
    emptyDir: {}
```

```bash
# Crear Pod con readonly FS
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: readonly-demo
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
    securityContext:
      readOnlyRootFilesystem: true
EOF

# Intentar escribir en / (FALLA)
kubectl exec readonly-demo -- touch /test.txt
# touch: /test.txt: Read-only file system

# Pero se puede escribir en /tmp si montamos volume
kubectl delete pod readonly-demo
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: readonly-with-tmp
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: tmp-volume
      mountPath: /tmp
  volumes:
  - name: tmp-volume
    emptyDir: {}
EOF

# Ahora SÍ funciona
kubectl exec readonly-with-tmp -- touch /tmp/test.txt
kubectl exec readonly-with-tmp -- ls -la /tmp/test.txt
```

---

### 6.6. Linux Capabilities

**Capabilities** = permisos granulares del kernel Linux (en lugar de root completo).

```
┌────────────────────────────────────────────┐
│         CAPABILITIES COMUNES               │
├────────────────────────────────────────────┤
│                                            │
│  CAP_NET_BIND_SERVICE  → Bind a puertos < 1024 │
│  CAP_SYS_TIME          → Cambiar hora del sistema │
│  CAP_CHOWN             → Cambiar ownership de archivos │
│  CAP_SETUID/SETGID     → Cambiar UID/GID  │
│  CAP_NET_RAW           → Usar raw sockets  │
│  CAP_SYS_ADMIN         → Admin del sistema │
│                                            │
└────────────────────────────────────────────┘
```

💡 **Ejemplo inline - Drop ALL Capabilities**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: drop-all-caps
spec:
  containers:
  - name: app
    image: nginx:alpine
    securityContext:
      capabilities:
        drop:
        - ALL              # ← Eliminar TODAS las capabilities
        add:
        - NET_BIND_SERVICE # ← Agregar solo la necesaria
```

```bash
# Pod con capabilities mínimas
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: minimal-caps
spec:
  containers:
  - name: web
    image: nginx:alpine
    ports:
    - containerPort: 80
    securityContext:
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE  # Solo para bind a puerto 80
EOF

# Verificar capabilities
kubectl exec minimal-caps -- cat /proc/1/status | grep Cap
```

📄 **Ver ejemplo completo**: [`ejemplos/production-ready/05-security-context.yaml`](./ejemplos/production-ready/05-security-context.yaml)

---

### 6.7. Pod Security Context Completo

💡 **Ejemplo production-ready - Security Context**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hardened-pod
  labels:
    app: secure-app
spec:
  # Pod-level security
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
    ports:
    - containerPort: 8080  # Puerto > 1024 (no requiere root)
    
    # Container-level security
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    
    # Volumes writable necesarios
    volumeMounts:
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
    
    # Resources
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
    
    # Health checks
    livenessProbe:
      httpGet:
        path: /
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
    
    readinessProbe:
      httpGet:
        path: /
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
  
  volumes:
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
```

---

### 6.8. Best Practices - Security

#### **1. SIEMPRE correr como non-root**

```yaml
# ✅ BIEN
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000

# ❌ MAL - corre como root por defecto
spec:
  containers:
  - name: app
    image: nginx
```

---

#### **2. Drop ALL capabilities**

```yaml
# ✅ BIEN - capabilities mínimas
securityContext:
  capabilities:
    drop:
    - ALL
    add:
    - NET_BIND_SERVICE  # Solo si necesario

# ❌ MAL - capabilities por defecto (muchas)
securityContext: {}
```

---

#### **3. ReadOnly filesystem cuando sea posible**

```yaml
# ✅ BIEN
securityContext:
  readOnlyRootFilesystem: true
volumeMounts:
- name: tmp
  mountPath: /tmp  # Solo /tmp writable
```

---

#### **4. allowPrivilegeEscalation: false**

```yaml
# ✅ BIEN
securityContext:
  allowPrivilegeEscalation: false

# ❌ MAL - permite escalada
securityContext:
  allowPrivilegeEscalation: true
```

---

#### **5. Seccomp profile**

```yaml
# ✅ BIEN - seccomp profile
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault  # Perfil seguro por defecto
```

---

### 6.9. Security Context Template

**Template completo para copiar**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod-template
spec:
  # Pod-level security
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  
  containers:
  - name: app
    image: your-app:tag
    
    # Container-level security
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
        # add:
        # - NET_BIND_SERVICE  # Si necesitas puerto < 1024
    
    # Volumes necesarios para apps que escriben
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: cache
      mountPath: /var/cache
    
    # Siempre incluir resources
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
    
    # Siempre incluir probes
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 10
    
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
  
  volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}
```

---

### 6.10. Verificación de Security Context

```bash
# Ver security context aplicado
kubectl get pod <pod-name> -o jsonpath='{.spec.securityContext}' | jq

# Ver security context de container específico
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].securityContext}' | jq

# Verificar UID/GID dentro del Pod
kubectl exec <pod-name> -- id

# Ver capabilities del proceso
kubectl exec <pod-name> -- cat /proc/1/status | grep Cap

# Ver si filesystem es readonly
kubectl exec <pod-name> -- touch /test.txt
# Si falla: Read-only file system ✅
```

---

### ✅ Checkpoint Sección 6

Antes de continuar, verifica que puedes:
- [ ] Explicar qué es un Security Context
- [ ] Configurar runAsUser y runAsNonRoot
- [ ] Implementar readOnlyRootFilesystem con volumes necesarios
- [ ] Drop ALL capabilities y agregar solo las necesarias
- [ ] Entender allowPrivilegeEscalation
- [ ] Diferenciar Pod-level vs Container-level security
- [ ] Usar el template de security completo

---

### 🧪 Laboratorio 06: Security Contexts

**Duración**: 50 minutos

📁 **Laboratorio propuesto**: `laboratorios/lab-06-security-contexts.md` *(pendiente de crear)*

**Objetivos**:
1. Crear Pod inseguro vs Pod hardened
2. Implementar readOnlyRootFilesystem con volumes
3. Configurar capabilities mínimas
4. Verificar security contexts aplicados
5. Aplicar template de security a aplicación real

---


## 🐛 7. Debugging Avanzado

> **Objetivo**: Dominar troubleshooting de Pods

### 7.1. kubectl debug

```bash
kubectl debug my-pod -it --image=busybox --target=app
```

### 7.2. Checklist

**Pending**: `kubectl describe pod <name>`  
**CrashLoopBackOff**: `kubectl logs <name> --previous`  
**No responde**: `kubectl port-forward pod/<name> 8080:8080`

---

## ✅ 8. Best Practices

| ❌ Evitar | ✅ Hacer |
|-----------|----------|
| `:latest` | Tags específicos |
| Sin resources | Requests + Limits |
| Sin probes | Liveness + Readiness |

---

## 📚 9. Resumen

**Has dominado**: Manifiestos, Ciclo de vida, Labels, Resources, Health Checks, Security, Debugging

**Clave**: Usa **Deployments** en producción, no Pods directos

---

**⬅️ Anterior**: [Módulo 04](../modulo-04-pods-vs-contenedores/README.md)  
**➡️ Siguiente**: [Módulo 06](../modulo-06-replicasets-replicas/README.md)
