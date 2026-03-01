# Capítulo 8: ReplicaSets y Escalado

Gestionar Pods individuales no escala. Los ReplicaSets garantizan que el número deseado de réplicas esté siempre corriendo, proporcionando auto-healing y escalado horizontal.

---

## 🎓 Guía de Estudio Recomendada

Para maximizar tu aprendizaje, sigue esta ruta estructurada:

```
Fase 1: Conceptos de ReplicaSets (45-60 min)
├─ ¿Qué es un ReplicaSet?
├─ Arquitectura y reconciliación
├─ Diferencias con Pods y Deployments
└─ Lab 01: Crear primer ReplicaSet

Fase 2: Manifiestos y Selectors (60-90 min)
├─ Estructura de manifiestos YAML
├─ Selectors: matchLabels y matchExpressions
├─ Template de Pods
└─ Lab 02: Manifiestos avanzados

Fase 3: Escalado y Auto-recuperación (60-90 min)
├─ Escalado manual vs declarativo
├─ Auto-recuperación (self-healing)
├─ Ownership y referencias
└─ Lab 03: Escalado bajo carga

Fase 4: Limitaciones y Producción (45-60 min)
├─ Limitaciones de ReplicaSets
├─ Cuándo usar Deployments
├─ Best practices de producción
└─ Lab 04: Migración a Deployments
```

👉 **[ABRIR GUÍA DE ESTUDIO](./RESUMEN-MODULO.md)**

---

---

## 🔍 1. ¿Qué es un ReplicaSet?

### **1.1 Definición y Propósito**

Un **ReplicaSet** es un **controlador de Kubernetes** que:

> **Garantiza** que un **número específico** de réplicas de Pod estén **corriendo en todo momento**

**Características principales**:
- 🔄 **Auto-recuperación**: Recrea Pods que fallan automáticamente
- 📈 **Escalado horizontal**: Gestiona múltiples réplicas de la misma aplicación
- 🎯 **Gestión declarativa**: Defines el estado deseado, Kubernetes lo mantiene
- 🏷️ **Selector-based**: Usa labels para identificar qué Pods gestionar

---

### **1.2 ¿Por qué necesitamos ReplicaSets?**

Imagina este escenario **sin** ReplicaSet:

```bash
# Crear un Pod manualmente
kubectl run my-app --image=nginx:alpine

# Pod se ejecuta normalmente
kubectl get pods
# NAME      READY   STATUS    RESTARTS   AGE
# my-app    1/1     Running   0          10s

# ❌ PROBLEMA: Pod es eliminado (fallo de nodo, eliminación accidental, etc.)
kubectl delete pod my-app

# Pod desaparece permanentemente
kubectl get pods
# No resources found
# ❌ Aplicación CAÍDA - requiere intervención manual
```

**Con** ReplicaSet:

```bash
# Crear ReplicaSet con 1 réplica
kubectl apply -f replicaset.yaml

# Pod se ejecuta
kubectl get pods
# NAME           READY   STATUS    RESTARTS   AGE
# my-app-abc12   1/1     Running   0          10s

# Pod es eliminado
kubectl delete pod my-app-abc12

# ✅ ReplicaSet lo recrea AUTOMÁTICAMENTE
kubectl get pods
# NAME           READY   STATUS    RESTARTS   AGE
# my-app-xyz34   1/1     Running   0          2s  ← Nuevo Pod creado
# ✅ Aplicación sigue disponible - CERO intervención manual
```

**Conclusión**: ReplicaSets proporcionan **resiliencia automática**

---

### **1.3 ReplicaSet vs Pod: Comparación Detallada**

| Aspecto | Pod (Nivel Bajo) | ReplicaSet (Nivel Alto) |
|---------|------------------|-------------------------|
| **Propósito** | Ejecutar contenedores | Gestionar múltiples Pods |
| **Auto-recuperación** | ❌ No | ✅ Sí |
| **Escalado** | ❌ Manual (crear/eliminar Pods) | ✅ Automático (cambiar replicas) |
| **Alta disponibilidad** | ❌ Single point of failure | ✅ Múltiples réplicas |
| **Gestión** | Imperativa | Declarativa |
| **Uso típico** | Testing, Jobs únicos | Aplicaciones stateless en producción |
| **Complejidad** | Baja | Media |

**Visualización**:

```
🔴 POD (Nivel Bajo)
┌─────────────────┐
│   Pod: my-app   │
│   image: nginx  │
└─────────────────┘
     ↓
  Falla (node crash, OOM, etc.)
     ↓
  ❌ CAÍDA PERMANENTE
  Requiere creación manual


🟢 REPLICASET (Nivel Alto)
┌──────────────────────┐
│    ReplicaSet        │
│    replicas: 3       │
│    selector:         │
│      app: my-app     │
└──────────┬───────────┘
           │
    ┌──────┴──────┬─────────┐
    ▼             ▼         ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Pod 1   │  │ Pod 2   │  │ Pod 3   │
│ Running │  │ Running │  │ Running │
└─────────┘  └─────────┘  └─────────┘
     ↓ Falla
┌─────────┐  ┌─────────┐  ┌─────────┐
│ DELETED │  │ Running │  │ Running │
└─────────┘  └─────────┘  └─────────┘
     ↓ ReplicaSet detecta (replicas: 2 < desired: 3)
     ↓ Crea nuevo Pod automáticamente
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Pod 4   │  │ Pod 2   │  │ Pod 3   │
│ Running │  │ Running │  │ Running │
└─────────┘  └─────────┘  └─────────┘
✅ RECUPERACIÓN AUTOMÁTICA - CERO downtime
```

---

### **1.4 Arquitectura de un ReplicaSet**

#### **Componentes Clave**

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: webapp-rs            # 1️⃣ Nombre del ReplicaSet
spec:
  replicas: 3                # 2️⃣ Estado deseado (3 Pods)
  selector:                  # 3️⃣ Cómo identificar Pods
    matchLabels:
      app: webapp
  template:                  # 4️⃣ Plantilla para crear Pods
    metadata:
      labels:
        app: webapp          # DEBE coincidir con selector
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
```

**Explicación componente por componente**:

| # | Componente | Función | Ejemplo |
|---|------------|---------|---------|
| 1️⃣ | **metadata.name** | Identifica el ReplicaSet | `webapp-rs` |
| 2️⃣ | **spec.replicas** | Número de Pods deseados | `3` |
| 3️⃣ | **spec.selector** | Filtro de labels para encontrar Pods | `app: webapp` |
| 4️⃣ | **spec.template** | Blueprint para crear nuevos Pods | Pod completo con containers, volumes, etc. |

#### **Flujo de Control (Reconciliation Loop)**

```
┌───────────────────────────────────────────────────────────────┐
│          RECONCILIATION LOOP DE REPLICASET                    │
└───────────────────────────────────────────────────────────────┘

Paso 1: Leer manifiesto
   ┌──────────────────────┐
   │ Estado Deseado:      │
   │ replicas: 3          │
   │ selector: app=webapp │
   └──────────────────────┘
           ↓
Paso 2: Query al API Server
   ┌──────────────────────┐
   │ kubectl get pods     │
   │ -l app=webapp        │
   └──────────────────────┘
           ↓
Paso 3: Contar Pods actuales
   ┌──────────────────────┐
   │ Estado Actual:       │
   │ Pods encontrados: 2  │
   └──────────────────────┘
           ↓
Paso 4: Comparar (desired vs actual)
   ┌──────────────────────┐
   │ Desired: 3           │
   │ Actual:  2           │
   │ Diff:   +1 (falta 1) │
   └──────────────────────┘
           ↓
Paso 5: Reconciliar (crear/eliminar Pods)
   ┌──────────────────────┐
   │ Acción:              │
   │ Crear 1 Pod nuevo    │
   │ usando template      │
   └──────────────────────┘
           ↓
Paso 6: Verificar
   ┌──────────────────────┐
   │ Estado Actual:       │
   │ Pods: 3              │
   │ ✅ Reconciliado      │
   └──────────────────────┘
           ↓
   Esperar 5s → Repetir desde Paso 2 (loop infinito)
```

**Este loop corre continuamente** cada ~5 segundos

---

### **1.5 Ejemplo Práctico: Observar Reconciliación**

Vamos a **ver en vivo** cómo funciona el loop de reconciliación:

```bash
# Terminal 1: Observar Pods en tiempo real
kubectl get pods -l app=nginx-demo --watch

# Terminal 2: Crear ReplicaSet
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
EOF

# Observa en Terminal 1: Pods creándose uno por uno
# nginx-demo-abc12   0/1     ContainerCreating   0          0s
# nginx-demo-abc12   1/1     Running             0          2s
# nginx-demo-def34   0/1     ContainerCreating   0          0s
# nginx-demo-def34   1/1     Running             0          2s
# nginx-demo-ghi56   0/1     ContainerCreating   0          0s
# nginx-demo-ghi56   1/1     Running             0          2s

# Terminal 2: Eliminar un Pod manualmente
POD_NAME=$(kubectl get pods -l app=nginx-demo -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME

# Observa en Terminal 1: Reconciliación automática
# nginx-demo-abc12   1/1     Terminating   0          30s
# nginx-demo-xyz99   0/1     Pending       0          0s   ← Nuevo Pod creado
# nginx-demo-xyz99   0/1     ContainerCreating   0    0s
# nginx-demo-xyz99   1/1     Running             0    2s
# ✅ ReplicaSet detectó (2 < 3) y creó nuevo Pod automáticamente
```

📄 **Ver ejemplo completo**: [`ejemplos/01-conceptos/demo-reconciliacion.yaml`](./ejemplos/01-conceptos/demo-reconciliacion.yaml)

---

### **1.6 Ownership: ¿Quién posee qué?**

Los Pods creados por un ReplicaSet tienen una relación de **ownership** (propiedad):

```bash
# Ver owner del Pod
kubectl get pod nginx-demo-abc12 -o yaml | grep -A 5 ownerReferences
```

**Salida**:
```yaml
ownerReferences:
- apiVersion: apps/v1
  kind: ReplicaSet           # ← Tipo del dueño
  name: nginx-demo           # ← Nombre del ReplicaSet dueño
  uid: 12345-67890-abcde     # ← ID único del ReplicaSet
  controller: true           # ← Este ReplicaSet CONTROLA el Pod
  blockOwnerDeletion: true   # ← No puedes eliminar el RS si el Pod existe
```

**Implicaciones**:

| Acción | Resultado | Explicación |
|--------|-----------|-------------|
| Eliminar Pod | ✅ Pod se recrea | RS detecta falta de réplica |
| Eliminar ReplicaSet | ❌ Pods también se eliminan | Owner deletion cascade |
| Eliminar RS con `--cascade=orphan` | ✅ Pods sobreviven | Pods quedan huérfanos |
| Cambiar label de Pod | Pod ya NO es gestionado | RS crea nuevo Pod |

---

### **✅ Checkpoint 01: Verificación de Conceptos**

Antes de continuar, asegúrate de poder responder:

- [ ] ¿Qué problema resuelven los ReplicaSets?
- [ ] ¿Cuál es la diferencia clave entre un Pod y un ReplicaSet?
- [ ] ¿Qué es el "reconciliation loop"?
- [ ] ¿Qué son los "owner references"?
- [ ] ¿Qué pasa si eliminas un Pod gestionado por un ReplicaSet?

📁 **Laboratorio**: [`laboratorios/lab-01-conceptos-replicasets.md`](./laboratorios/lab-01-conceptos-replicasets.md)
- Duración: 30 minutos
- Experimenta con reconciliación y ownership

---

## 🚀 2. Manifiestos YAML de ReplicaSets

### **2.1 Anatomía de un Manifiesto ReplicaSet**

Un manifiesto de ReplicaSet tiene **4 secciones principales**:

```yaml
# 1️⃣ API VERSION Y KIND
apiVersion: apps/v1      # API Group específico para controladores
kind: ReplicaSet         # Tipo de recurso

# 2️⃣ METADATA
metadata:
  name: webapp-rs        # Nombre único en el namespace
  namespace: default     # Namespace (opcional, default: "default")
  labels:                # Labels del REPLICASET (opcional)
    app: webapp
    tier: frontend
    managed-by: ops-team

# 3️⃣ SPEC (Especificación)
spec:
  replicas: 3            # Estado deseado: 3 Pods

  # 3️⃣.1 SELECTOR (¿Qué Pods gestionar?)
  selector:
    matchLabels:
      app: webapp        # DEBE coincidir con template.metadata.labels
      version: v1

  # 3️⃣.2 TEMPLATE (Blueprint para crear Pods)
  template:
    metadata:
      labels:
        app: webapp      # ⚠️ DEBE incluir todos los labels del selector
        version: v1
        pod-label: custom  # Puede tener labels adicionales
    spec:
      # Aquí va la especificación COMPLETA del Pod
      containers:
      - name: webapp
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

---

### **2.2 Campos Obligatorios vs Opcionales**

| Campo | Obligatorio | Descripción | Ejemplo |
|-------|-------------|-------------|---------|
| **apiVersion** | ✅ Sí | Siempre `apps/v1` para ReplicaSets | `apps/v1` |
| **kind** | ✅ Sí | Siempre `ReplicaSet` | `ReplicaSet` |
| **metadata.name** | ✅ Sí | Nombre único (DNS-1123) | `webapp-rs` |
| **metadata.namespace** | ❌ No | Namespace donde crear el RS | `default` (si omitido) |
| **metadata.labels** | ❌ No | Labels del ReplicaSet mismo | `{app: webapp}` |
| **spec.replicas** | ✅ Sí | Número de Pods deseados | `3` |
| **spec.selector** | ✅ Sí | Cómo identificar Pods | `matchLabels: {app: webapp}` |
| **spec.template** | ✅ Sí | Blueprint completo del Pod | Ver estructura de Pod |
| **spec.template.metadata.labels** | ✅ Sí | DEBE incluir selector labels | Mismo que selector |

**⚠️ Regla CRÍTICA**:

```
spec.selector.matchLabels  ⊆  spec.template.metadata.labels
       (subconjunto)              (superconjunto)

Los labels del selector DEBEN estar incluidos en los labels del template
```

**Ejemplo válido**:
```yaml
selector:
  matchLabels:
    app: webapp        # ✅ Incluido en template
template:
  metadata:
    labels:
      app: webapp      # ✅ Coincide
      version: v1      # ✅ Label adicional permitido
```

**Ejemplo INVÁLIDO**:
```yaml
selector:
  matchLabels:
    app: webapp        # ❌ NO está en template
template:
  metadata:
    labels:
      application: webapp  # ❌ Label diferente
# Error: selector doesn't match template labels
```

---

### **2.3 Crear tu Primer ReplicaSet**

#### **Ejemplo 1: ReplicaSet Simple**

📄 **Archivo**: [`ejemplos/01-basico/01-replicaset-simple.yaml`](./ejemplos/01-basico/01-replicaset-simple.yaml)

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-simple
  labels:
    app: nginx
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
```

**Crear y verificar**:

```bash
# Aplicar manifiesto
kubectl apply -f ejemplos/01-basico/01-replicaset-simple.yaml

# Ver ReplicaSet
kubectl get rs nginx-simple
# NAME            DESIRED   CURRENT   READY   AGE
# nginx-simple    3         3         3       10s

# Ver Pods creados (con labels)
kubectl get pods -l app=nginx --show-labels
# NAME                  READY   STATUS    LABELS
# nginx-simple-abc12    1/1     Running   app=nginx
# nginx-simple-def34    1/1     Running   app=nginx
# nginx-simple-ghi56    1/1     Running   app=nginx

# Ver detalles del ReplicaSet
kubectl describe rs nginx-simple
```

**Salida de `describe`**:
```
Name:         nginx-simple
Namespace:    default
Selector:     app=nginx
Labels:       app=nginx
              tier=frontend
Replicas:     3 current / 3 desired  ← Estado actual vs deseado
Pods Status:  3 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:        nginx:alpine
    Port:         80/TCP
Events:
  Type    Reason            Age   From                   Message
  ----    ------            ----  ----                   -------
  Normal  SuccessfulCreate  30s   replicaset-controller  Created pod: nginx-simple-abc12
  Normal  SuccessfulCreate  30s   replicaset-controller  Created pod: nginx-simple-def34
  Normal  SuccessfulCreate  30s   replicaset-controller  Created pod: nginx-simple-ghi56
```

---

#### **Ejemplo 2: ReplicaSet con Configuración de Producción**

📄 **Archivo**: [`ejemplos/01-basico/02-replicaset-production.yaml`](./ejemplos/01-basico/02-replicaset-production.yaml)

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: webapp-prod
  labels:
    app: webapp
    environment: production
    managed-by: ops
spec:
  replicas: 5
  selector:
    matchLabels:
      app: webapp
      environment: production
  template:
    metadata:
      labels:
        app: webapp
        environment: production
        version: v1.2.0
    spec:
      containers:
      - name: webapp
        image: nginx:alpine
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        
        # Resource management
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
        
        # Environment variables
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "info"
      
      # Security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
```

**Aplicar**:
```bash
kubectl apply -f ejemplos/01-basico/02-replicaset-production.yaml

# Ver recursos de los Pods
kubectl top pods -l app=webapp

# Ver eventos en tiempo real
kubectl get events --watch --field-selector involvedObject.kind=ReplicaSet
```

---

### **2.4 Template: El Blueprint del Pod**

El campo `spec.template` es **exactamente** lo que pondrías en un manifiesto de Pod:

```yaml
template:
  # Aquí va UN POD COMPLETO (sin apiVersion/kind)
  metadata:
    labels: {...}
    annotations: {...}
  spec:
    containers: [...]
    volumes: [...]
    initContainers: [...]
    securityContext: {...}
    # ... TODO lo que pondrias en un Pod
```

**Equivalencia**:

```yaml
# Pod standalone
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  labels:
    app: webapp
spec:
  containers:
  - name: nginx
    image: nginx:alpine

# Template en ReplicaSet (MISMO contenido)
template:
  metadata:
    labels:
      app: webapp
  spec:
    containers:
    - name: nginx
      image: nginx:alpine
```

---

### **2.5 Nombrado de Pods Generados**

Los Pods creados por un ReplicaSet tienen nombres generados automáticamente:

```
<replicaset-name>-<random-suffix>
```

**Ejemplo**:
```bash
# ReplicaSet llamado: webapp-rs
kubectl get pods
# NAME                READY
# webapp-rs-abc12     1/1    ← webapp-rs + sufijo aleatorio
# webapp-rs-def34     1/1    ← webapp-rs + sufijo aleatorio
# webapp-rs-ghi56     1/1    ← webapp-rs + sufijo aleatorio
```

**Características del sufijo**:
- 5 caracteres alfanuméricos lowercase
- Generado aleatoriamente por Kubernetes
- Garantiza unicidad
- **NO** puedes controlarlo

---

### **2.6 Ejemplo Práctico: Multi-Contenedor en ReplicaSet**

📄 **Archivo**: [`ejemplos/01-basico/03-replicaset-multi-container.yaml`](./ejemplos/01-basico/03-replicaset-multi-container.yaml)

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: app-with-sidecar
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
      pattern: sidecar
  template:
    metadata:
      labels:
        app: webapp
        pattern: sidecar
    spec:
      # Shared volume para comunicación
      volumes:
      - name: shared-logs
        emptyDir: {}
      
      containers:
      # Contenedor principal
      - name: app
        image: nginx:alpine
        volumeMounts:
        - name: shared-logs
          mountPath: /var/log/nginx
        ports:
        - containerPort: 80
      
      # Sidecar para procesar logs
      - name: log-processor
        image: busybox
        command: ["/bin/sh"]
        args:
        - -c
        - |
          while true; do
            echo "Processing logs..."
            tail -f /logs/access.log 2>/dev/null || sleep 5
          done
        volumeMounts:
        - name: shared-logs
          mountPath: /logs
```

**Aplicar y verificar**:
```bash
kubectl apply -f ejemplos/01-basico/03-replicaset-multi-container.yaml

# Ver Pods con múltiples contenedores
kubectl get pods -l pattern=sidecar
# NAME                      READY   STATUS
# app-with-sidecar-abc12    2/2     Running  ← 2 contenedores

# Ver logs del sidecar
kubectl logs app-with-sidecar-abc12 -c log-processor

# Exec en contenedor específico
kubectl exec app-with-sidecar-abc12 -c app -- ls /var/log/nginx
```

---

### **2.7 Comandos de Gestión**

```bash
# CREAR
kubectl apply -f replicaset.yaml
kubectl create -f replicaset.yaml

# LISTAR
kubectl get rs
kubectl get rs -o wide
kubectl get rs --show-labels
kubectl get rs -n <namespace>

# INSPECCIONAR
kubectl describe rs <nombre>
kubectl get rs <nombre> -o yaml
kubectl get rs <nombre> -o json | jq

# EDITAR
kubectl edit rs <nombre>
kubectl apply -f replicaset-updated.yaml

# ELIMINAR
kubectl delete rs <nombre>
kubectl delete rs <nombre> --cascade=orphan  # Mantener Pods
kubectl delete -f replicaset.yaml

# VER PODS DEL REPLICASET
kubectl get pods -l <selector>
kubectl get pods --selector=app=webapp

# VER EVENTOS
kubectl get events --field-selector involvedObject.kind=ReplicaSet
kubectl get events --field-selector involvedObject.name=<rs-name>
```

---

### **✅ Checkpoint 02: Verificación de Manifiestos**

Antes de continuar, asegúrate de poder:

- [ ] Escribir un manifiesto básico de ReplicaSet
- [ ] Identificar los 4 campos obligatorios
- [ ] Explicar la regla selector ⊆ template.labels
- [ ] Crear un ReplicaSet con template de Pod completo
- [ ] Usar kubectl para crear y gestionar ReplicaSets

📁 **Laboratorio**: [`laboratorios/lab-02-manifiestos-replicasets.md`](./laboratorios/lab-02-manifiestos-replicasets.md)
- Duración: 40 minutos
- Crea ReplicaSets con configuraciones progresivamente complejas

## 🏷️ 3. Selectors y Gestión de Pods

### **3.1 El Rol del Selector**

El **selector** es el mecanismo que ReplicaSet usa para **identificar qué Pods gestionar**:

```yaml
spec:
  selector:
    matchLabels:      # ← Búsqueda de Pods
      app: webapp
```

**Flujo de operación**:

```
1. ReplicaSet lee su selector
   ↓
2. Query al API Server: "Dame todos los Pods con labels: app=webapp"
   ↓
3. Kubernetes devuelve lista de Pods que coinciden
   ↓
4. ReplicaSet cuenta Pods (ejemplo: 2 encontrados)
   ↓
5. Compara con desired state (replicas: 3)
   ↓
6. Acción: Crear 1 Pod adicional (2 < 3)
```

---

### **3.2 matchLabels: Selector Simple**

**Uso**: Cuando necesitas coincidencia **exacta** de labels

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: webapp-basic
spec:
  replicas: 3
  selector:
    matchLabels:      # Coincidencia AND (todas deben coincidir)
      app: webapp
      tier: frontend
      environment: prod
  template:
    metadata:
      labels:
        app: webapp
        tier: frontend
        environment: prod
        version: v1.0    # ← Label adicional permitido
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
```

**Comportamiento**:
- Busca Pods con **TODOS** los labels especificados
- Operador lógico: **AND**
- Coincidencia **exacta** de valores

**Ejemplo**:
```bash
# Estos Pods SÍ son gestionados
Labels: {app=webapp, tier=frontend, environment=prod}           ✅
Labels: {app=webapp, tier=frontend, environment=prod, ver=v1.0} ✅

# Estos Pods NO son gestionados
Labels: {app=webapp, tier=frontend}                             ❌ Falta environment
Labels: {app=webapp, tier=backend, environment=prod}            ❌ tier diferente
Labels: {app=other, tier=frontend, environment=prod}            ❌ app diferente
```

---

### **3.3 matchExpressions: Selector Avanzado**

**Uso**: Cuando necesitas **condiciones flexibles**

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: webapp-advanced
spec:
  replicas: 3
  selector:
    matchExpressions:
    - key: app
      operator: In
      values: [webapp, webapi]    # app=webapp OR app=webapi
    - key: tier
      operator: NotIn
      values: [database]           # tier != database
    - key: environment
      operator: Exists             # Debe tener label "environment" (cualquier valor)
  template:
    metadata:
      labels:
        app: webapp
        tier: frontend
        environment: production
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
```

**Operadores disponibles**:

| Operador | Descripción | Ejemplo | Coincide con |
|----------|-------------|---------|--------------|
| **In** | Valor está en la lista | `key: app, values: [web, api]` | `app=web` o `app=api` |
| **NotIn** | Valor NO está en la lista | `key: tier, values: [db]` | `tier=frontend`, `tier=cache` (NO `tier=db`) |
| **Exists** | Label existe (cualquier valor) | `key: environment` | `environment=prod`, `environment=dev` |
| **DoesNotExist** | Label NO existe | `key: deprecated` | Pods sin label "deprecated" |

📄 **Ver ejemplo**: [`ejemplos/02-selectors/01-match-expressions.yaml`](./ejemplos/02-selectors/01-match-expressions.yaml)

---

### **3.4 Combinando matchLabels y matchExpressions**

Puedes combinar ambos métodos (operador lógico: **AND**):

```yaml
spec:
  selector:
    matchLabels:              # Todas deben coincidir (AND)
      app: webapp
      tier: frontend
    matchExpressions:         # Todas deben cumplirse (AND)
    - key: environment
      operator: In
      values: [prod, staging]
    - key: deprecated
      operator: DoesNotExist
```

**Lógica resultante**:
```
(app=webapp)  
AND  
(tier=frontend)  
AND  
(environment IN [prod, staging])  
AND  
(deprecated DOES NOT EXIST)
```

**Pods que coinciden**:
```yaml
# ✅ Coincide
labels:
  app: webapp
  tier: frontend
  environment: prod

# ✅ Coincide
labels:
  app: webapp
  tier: frontend
  environment: staging
  version: v2.0

# ❌ NO coincide (environment=dev no está en [prod, staging])
labels:
  app: webapp
  tier: frontend
  environment: dev

# ❌ NO coincide (tiene label "deprecated")
labels:
  app: webapp
  tier: frontend
  environment: prod
  deprecated: "true"
```

📄 **Ver ejemplo**: [`ejemplos/02-selectors/02-combined-selectors.yaml`](./ejemplos/02-selectors/02-combined-selectors.yaml)

---

### **3.5 Caso de Uso: Adopción de Pods Existentes**

⚠️ **PELIGRO**: ReplicaSet puede **adoptar** Pods existentes si coinciden con su selector

**Escenario problemático**:

```bash
# Paso 1: Crear Pods manualmente
kubectl run manual-pod-1 --image=nginx:alpine --labels="app=webapp"
kubectl run manual-pod-2 --image=nginx:alpine --labels="app=webapp"
kubectl run manual-pod-3 --image=nginx:alpine --labels="app=webapp"

# Ver Pods creados
kubectl get pods -l app=webapp
# NAME           READY   STATUS
# manual-pod-1   1/1     Running
# manual-pod-2   1/1     Running
# manual-pod-3   1/1     Running

# Paso 2: Crear ReplicaSet con replicas: 3 y selector app=webapp
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: webapp-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
EOF

# Ver resultado
kubectl get pods -l app=webapp --show-labels
# NAME           READY   LABELS         OWNER
# manual-pod-1   1/1     app=webapp     webapp-rs  ← ❌ ADOPTADO
# manual-pod-2   1/1     app=webapp     webapp-rs  ← ❌ ADOPTADO
# manual-pod-3   1/1     app=webapp     webapp-rs  ← ❌ ADOPTADO

# ReplicaSet ve 3 Pods, no crea nuevos
kubectl get rs webapp-rs
# NAME        DESIRED   CURRENT   READY
# webapp-rs   3         3         3      ← ✅ Ya tiene 3 (adoptó los manuales)
```

**¿Por qué es problemático?**
- Los Pods manuales pueden tener **configuración diferente**
- No fueron creados con el template del ReplicaSet
- Crea **inconsistencias** en el cluster

**Solución**: Eliminar Pods manuales antes de crear ReplicaSet

```bash
# Eliminar Pods manuales
kubectl delete pod manual-pod-1 manual-pod-2 manual-pod-3

# ReplicaSet creará Pods con su template
kubectl get pods -l app=webapp
# NAME               READY   STATUS
# webapp-rs-abc12    1/1     Running  ← Creado por RS
# webapp-rs-def34    1/1     Running  ← Creado por RS
# webapp-rs-ghi56    1/1     Running  ← Creado por RS
```

📄 **Ver ejemplo**: [`ejemplos/02-selectors/03-pod-adoption-danger.yaml`](./ejemplos/02-selectors/03-pod-adoption-danger.yaml)

---

### **3.6 Ejemplo Práctico: Segregación de Ambientes**

Usa selectores para segregar ambientes (dev, staging, prod):

📄 **Archivo**: [`ejemplos/02-selectors/04-environment-segregation.yaml`](./ejemplos/02-selectors/04-environment-segregation.yaml)

```yaml
# ReplicaSet para PRODUCCIÓN
---
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: webapp-prod
  namespace: production
spec:
  replicas: 5
  selector:
    matchLabels:
      app: webapp
      environment: production
  template:
    metadata:
      labels:
        app: webapp
        environment: production
        version: v2.1.0
    spec:
      containers:
      - name: webapp
        image: nginx:alpine
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"

---
# ReplicaSet para STAGING
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: webapp-staging
  namespace: staging
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
      environment: staging
  template:
    metadata:
      labels:
        app: webapp
        environment: staging
        version: v2.2.0-rc1
    spec:
      containers:
      - name: webapp
        image: nginx:alpine
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
```

**Aplicar y verificar**:
```bash
# Crear namespaces
kubectl create namespace production
kubectl create namespace staging

# Aplicar ambos ReplicaSets
kubectl apply -f ejemplos/02-selectors/04-environment-segregation.yaml

# Ver Pods de producción
kubectl get pods -n production -l environment=production
# NAME                READY   LABELS
# webapp-prod-abc12   1/1     app=webapp,environment=production,version=v2.1.0
# webapp-prod-def34   1/1     ...
# ... (5 Pods)

# Ver Pods de staging
kubectl get pods -n staging -l environment=staging
# NAME                  READY   LABELS
# webapp-staging-xyz12  1/1     app=webapp,environment=staging,version=v2.2.0-rc1
# webapp-staging-uvw34  1/1     ...
# ... (2 Pods)
```

---

### **3.7 Inspeccionar Selector de un ReplicaSet**

```bash
# Ver selector del ReplicaSet
kubectl get rs webapp-rs -o jsonpath='{.spec.selector}'
# Output: {"matchLabels":{"app":"webapp","tier":"frontend"}}

# Ver selector formateado
kubectl get rs webapp-rs -o jsonpath='{.spec.selector}' | jq
# {
#   "matchLabels": {
#     "app": "webapp",
#     "tier": "frontend"
#   }
# }

# Listar Pods que coinciden con el selector
kubectl get pods -l app=webapp,tier=frontend

# Verificar owner de un Pod
kubectl get pod webapp-rs-abc12 -o jsonpath='{.metadata.ownerReferences[0].name}'
# Output: webapp-rs
```

---

### **✅ Checkpoint 03: Verificación de Selectors**

Antes de continuar, asegúrate de poder:

- [ ] Explicar qué es un selector y su función
- [ ] Usar `matchLabels` para selección simple
- [ ] Usar `matchExpressions` con los 4 operadores
- [ ] Combinar `matchLabels` y `matchExpressions`
- [ ] Identificar el peligro de adopción de Pods
- [ ] Segregar ambientes usando selectores

📁 **Laboratorio**: [`laboratorios/lab-03-selectors-avanzados.md`](./laboratorios/lab-03-selectors-avanzados.md)
## 📊 4. Escalado Horizontal

### **4.1 ¿Qué es el Escalado Horizontal?**

**Escalado horizontal** = Aumentar/disminuir el **número de réplicas** (Pods)

```
Escalado VERTICAL (NO lo hace ReplicaSet)
┌────────────┐        ┌────────────┐
│  Pod: 2 GB │   →    │  Pod: 4 GB │   Más recursos por Pod
│  CPU: 1    │        │  CPU: 2    │
└────────────┘        └────────────┘

Escalado HORIZONTAL (SÍ lo hace ReplicaSet)
┌────────────┐        ┌────────────┐  ┌────────────┐  ┌────────────┐
│  Pod: 2 GB │   →    │  Pod: 2 GB │  │  Pod: 2 GB │  │  Pod: 2 GB │
│  CPU: 1    │        │  CPU: 1    │  │  CPU: 1    │  │  CPU: 1    │
└────────────┘        └────────────┘  └────────────┘  └────────────┘
  1 réplica               3 réplicas (más Pods)
```

**Ventajas del escalado horizontal**:
- ✅ Alta disponibilidad (si 1 Pod falla, hay otros)
- ✅ Distribución de carga
- ✅ Sin downtime durante escalado
- ✅ Costo-efectivo (escala bajo demanda)

---

### **4.2 Escalado Declarativo (Recomendado)**

**Método**: Modificar el manifiesto YAML y aplicar

```yaml
# Archivo: replicaset.yaml (original)
spec:
  replicas: 3  # ← Estado actual

# Modificar a:
spec:
  replicas: 5  # ← Nuevo estado deseado
```

```bash
# Aplicar cambios
kubectl apply -f replicaset.yaml
# replicaset.apps/webapp-rs configured

# Observar escalado en tiempo real
kubectl get pods -l app=webapp --watch
# NAME             READY   STATUS              AGE
# webapp-rs-abc    1/1     Running             2m
# webapp-rs-def    1/1     Running             2m
# webapp-rs-ghi    1/1     Running             2m
# webapp-rs-jkl    0/1     ContainerCreating   0s  ← Nuevo
# webapp-rs-mno    0/1     ContainerCreating   0s  ← Nuevo
# webapp-rs-jkl    1/1     Running             3s
# webapp-rs-mno    1/1     Running             3s
```

**✅ Ventajas**:
- Auditable (cambios en Git)
- Reproducible
- Declarativo (estado deseado)
- Mejor para producción

📄 **Ver ejemplo**: [`ejemplos/03-escalado/01-escalado-declarativo.yaml`](./ejemplos/03-escalado/01-escalado-declarativo.yaml)

---

### **4.3 Escalado Imperativo**

**Método**: Comando `kubectl scale` directo

```bash
# Escalar a 5 réplicas
kubectl scale rs webapp-rs --replicas=5
# replicaset.apps/webapp-rs scaled

# Verificar
kubectl get rs webapp-rs
# NAME        DESIRED   CURRENT   READY   AGE
# webapp-rs   5         5         5       5m

# Ver nuevos Pods
kubectl get pods -l app=webapp
# NAME             READY   STATUS    AGE
# webapp-rs-abc    1/1     Running   5m
# webapp-rs-def    1/1     Running   5m
# webapp-rs-ghi    1/1     Running   5m
# webapp-rs-jkl    1/1     Running   10s  ← Nuevo
# webapp-rs-mno    1/1     Running   10s  ← Nuevo
```

**⚠️ Desventajas**:
- Cambios NO se reflejan en manifiesto
- No auditable
- Se pierde en próximo `kubectl apply`

**Uso recomendado**: Solo para testing rápido

---

### **4.4 Reducir Réplicas (Scale Down)**

```bash
# Reducir de 5 a 2 réplicas
kubectl scale rs webapp-rs --replicas=2

# Observar eliminación
kubectl get pods -l app=webapp --watch
# NAME             READY   STATUS        AGE
# webapp-rs-abc    1/1     Running       10m
# webapp-rs-def    1/1     Running       10m
# webapp-rs-ghi    1/1     Terminating   5m   ← Eliminando
# webapp-rs-jkl    1/1     Terminating   5m   ← Eliminando
# webapp-rs-mno    1/1     Terminating   5m   ← Eliminando
```

**¿Qué Pods se eliminan?**
- Kubernetes elige **automáticamente**
- Generalmente: **más recientes primero**
- Garantiza **terminación graceful** (grace period: 30s)
- No puedes controlar cuáles se eliminan

---

### **4.5 Ejemplo Práctico: Escalar bajo Carga**

📄 **Archivo**: [`ejemplos/03-escalado/02-escalado-bajo-carga.yaml`](./ejemplos/03-escalado/02-escalado-bajo-carga.yaml)

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-load-test
spec:
  replicas: 2  # Empezar con 2
  selector:
    matchLabels:
      app: web
      test: load
  template:
    metadata:
      labels:
        app: web
        test: load
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
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-load-svc
spec:
  selector:
    app: web
    test: load
  ports:
  - port: 80
    targetPort: 80
```

**Escenario de prueba**:

```bash
# Paso 1: Crear ReplicaSet y Service
kubectl apply -f ejemplos/03-escalado/02-escalado-bajo-carga.yaml

# Paso 2: Generar carga (en terminal separado)
kubectl run load-generator \
  --image=busybox \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://web-load-svc; done"

# Paso 3: Monitorear recursos
kubectl top pods -l app=web

# Paso 4: Escalar para manejar carga
kubectl scale rs web-load-test --replicas=10

# Paso 5: Ver distribución de carga
kubectl top pods -l app=web
# NAME                  CPU(cores)   MEMORY(bytes)
# web-load-test-abc     45m          32Mi
# web-load-test-def     48m          34Mi
# web-load-test-ghi     42m          31Mi
# ... (distribución entre 10 Pods)

# Cleanup
kubectl delete pod load-generator
kubectl delete -f ejemplos/03-escalado/02-escalado-bajo-carga.yaml
```

---

### **4.6 Escalar a Cero (Scale to Zero)**

```bash
# Escalar a 0 réplicas
kubectl scale rs webapp-rs --replicas=0

# Ver resultado
kubectl get rs webapp-rs
# NAME        DESIRED   CURRENT   READY   AGE
# webapp-rs   0         0         0       10m

kubectl get pods -l app=webapp
# No resources found
```

**Uso**:
- Detener temporalmente la aplicación
- Ahorrar recursos en ambientes no productivos
- Mantenimiento programado

**⚠️ Importante**: El ReplicaSet sigue existiendo (solo sin Pods)

---

### **✅ Checkpoint 04: Verificación de Escalado**

Antes de continuar, asegúrate de poder:

- [ ] Explicar la diferencia entre escalado horizontal y vertical
- [ ] Escalar un ReplicaSet de forma declarativa
- [ ] Escalar un ReplicaSet de forma imperativa
- [ ] Reducir réplicas y observar terminación de Pods
- [ ] Escalar a cero y volver a escalar
- [ ] Simular escalado bajo carga

📁 **Laboratorio**: [`laboratorios/lab-04-escalado-horizontal.md`](./laboratorios/lab-04-escalado-horizontal.md)
- Duración: 35 minutos
- Practica escalado en escenarios reales

---

## 🔄 5. Auto-recuperación (Self-Healing)

### **5.1 ¿Qué es Self-Healing?**

**Self-healing** = Capacidad de Kubernetes de **detectar y corregir fallos automáticamente**

```
Sin ReplicaSet:
┌─────────┐
│  Pod 1  │  ← Falla
└─────────┘
     ↓
  ❌ CAÍDO
  Requiere intervención manual

Con ReplicaSet:
┌────────────────────────┐
│     ReplicaSet         │
│     replicas: 3        │
└───────┬────────────────┘
        │
   ┌────┼────┐
   ▼    ▼    ▼
┌───┐ ┌───┐ ┌───┐
│ 1 │ │ 2 │ │ 3 │
└───┘ └───┘ └───┘
   ↓ Pod 2 falla
┌───┐       ┌───┐
│ 1 │   X   │ 3 │
└───┘       └───┘
   ↓ ReplicaSet detecta (2 < 3)
   ↓ Crea nuevo Pod automáticamente
┌───┐ ┌───┐ ┌───┐
│ 1 │ │ 4 │ │ 3 │  ← ✅ Recuperado
└───┘ └───┘ └───┘
```

---

### **5.2 Demostración de Auto-recuperación**

📄 **Archivo**: [`ejemplos/04-self-healing/01-auto-recuperacion.yaml`](./ejemplos/04-self-healing/01-auto-recuperacion.yaml)

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: self-healing-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo
      test: self-healing
  template:
    metadata:
      labels:
        app: demo
        test: self-healing
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
```

**Prueba práctica**:

```bash
# Terminal 1: Observar Pods en tiempo real
kubectl get pods -l test=self-healing --watch

# Terminal 2: Crear ReplicaSet
kubectl apply -f ejemplos/04-self-healing/01-auto-recuperacion.yaml

# Observa en Terminal 1: 3 Pods creándose
# self-healing-demo-abc12   0/1     ContainerCreating   0s
# self-healing-demo-abc12   1/1     Running             2s
# self-healing-demo-def34   0/1     ContainerCreating   0s
# self-healing-demo-def34   1/1     Running             2s
# self-healing-demo-ghi56   0/1     ContainerCreating   0s
# self-healing-demo-ghi56   1/1     Running             2s

# Terminal 2: Eliminar un Pod
POD_NAME=$(kubectl get pods -l test=self-healing -o jsonpath='{.items[0].metadata.name}')
echo "Eliminando Pod: $POD_NAME"
kubectl delete pod $POD_NAME

# Observa en Terminal 1: Recuperación INMEDIATA
# self-healing-demo-abc12   1/1     Terminating         30s
# self-healing-demo-xyz99   0/1     Pending             0s   ← NUEVO POD CREADO
# self-healing-demo-xyz99   0/1     ContainerCreating   0s
# self-healing-demo-xyz99   1/1     Running             2s
# ✅ TIEMPO DE RECUPERACIÓN: ~2 segundos
```

**Métricas observadas**:
- **Detection time**: ~1-2 segundos (reconciliation loop)
- **Recovery time**: ~2-5 segundos (dependiendo de imagen)
- **Total downtime**: ~3-7 segundos

---

### **5.3 Escenarios de Auto-recuperación**

#### **Escenario 1: Pod Crasheado**

```bash
# Crear Pod que crashea después de 10 segundos
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: crash-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: crash-test
  template:
    metadata:
      labels:
        app: crash-test
    spec:
      containers:
      - name: crasher
        image: busybox
        command: ["sh", "-c"]
        args:
        - |
          echo "Starting..."
          sleep 10
          echo "Crashing now!"
          exit 1
EOF

# Observar comportamiento
kubectl get pods -l app=crash-test --watch
# crash-demo-abc   1/1     Running             0s
# crash-demo-abc   0/1     Error               11s  ← Crasheó
# crash-demo-xyz   0/1     Pending             0s   ← Nuevo Pod
# crash-demo-xyz   0/1     ContainerCreating   0s
# crash-demo-xyz   1/1     Running             2s   ← Recuperado

# Ver historial de restarts
kubectl get pods -l app=crash-test
# NAME             READY   STATUS    RESTARTS   AGE
# crash-demo-abc   1/1     Running   0          15s  ← Nuevo Pod
# crash-demo-def   1/1     Running   0          30s
```

#### **Escenario 2: Node Failure**

```bash
# Simular fallo de nodo (en minikube)
minikube ssh "sudo systemctl stop kubelet"

# Ver Pods migrando a nodos disponibles
kubectl get pods -l app=demo -o wide --watch
# NAME           READY   STATUS        NODE
# demo-abc       1/1     Running       node1
# demo-def       1/1     Running       node1   ← Node1 cayó
# demo-ghi       1/1     Running       node2
# demo-def       1/1     Terminating   node1   ← Detectado como caído
# demo-xyz       0/1     Pending       <none>  ← Recreando
# demo-xyz       0/1     Running       node2   ← Movido a node2
```

#### **Escenario 3: OOMKilled (Out of Memory)**

```bash
# Crear ReplicaSet con límite de memoria bajo
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: oom-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: oom-test
  template:
    metadata:
      labels:
        app: oom-test
    spec:
      containers:
      - name: memory-hog
        image: progrium/stress
        args: ["--vm", "1", "--vm-bytes", "200M"]
        resources:
          limits:
            memory: "150Mi"  # ← Límite < consumo
EOF

# Ver Pods siendo OOMKilled y recreados
kubectl get pods -l app=oom-test --watch
# oom-demo-abc   0/1     OOMKilled           10s
# oom-demo-xyz   0/1     Pending             0s   ← Nuevo Pod
# oom-demo-xyz   0/1     OOMKilled           12s  ← También OOMKilled
# ... (loop infinito hasta ajustar recursos)
```

---

### **5.4 Monitorear Auto-recuperación**

```bash
# Ver eventos de recreación
kubectl get events --field-selector involvedObject.kind=ReplicaSet,reason=SuccessfulCreate
# LAST SEEN   TYPE     REASON              MESSAGE
# 30s         Normal   SuccessfulCreate    Created pod: demo-abc12
# 15s         Normal   SuccessfulCreate    Created pod: demo-xyz34

# Ver historial de Pods eliminados
kubectl get events --field-selector involvedObject.kind=Pod,reason=Killing
# LAST SEEN   TYPE     REASON   MESSAGE
# 20s         Normal   Killing  Stopping container nginx

# Ver estado del ReplicaSet
kubectl describe rs demo
# Events:
#   Type    Reason            Age   Message
#   ----    ------            ----  -------
#   Normal  SuccessfulCreate  5m    Created pod: demo-abc12
#   Normal  SuccessfulCreate  3m    Created pod: demo-def34
#   Normal  SuccessfulCreate  1m    Created pod: demo-ghi56
#   Normal  SuccessfulCreate  30s   Created pod: demo-xyz99 ← Recuperación
```

---

### **5.5 Limitaciones de Self-Healing**

⚠️ **ReplicaSet NO puede resolver**:

| Problema | ReplicaSet | Solución |
|----------|------------|----------|
| **App crashea por bug de código** | ❌ Recreará Pod infinitamente | Arreglar código |
| **Configuración incorrecta** | ❌ Pod reinicia constantemente (CrashLoopBackOff) | Corregir ConfigMap/Secret |
| **Recursos insuficientes en cluster** | ❌ Pod queda en Pending | Agregar nodos o liberar recursos |
| **Image pull error** | ❌ Pod queda en ImagePullBackOff | Corregir imagen o registry |
| **Bug en init container** | ❌ Pod queda en Init:Error | Arreglar init container |

**CrashLoopBackOff**: ReplicaSet recrea Pod → Pod crashea → ReplicaSet recrea → ... (loop)

---

### **✅ Checkpoint 05: Verificación de Self-Healing**

Antes de continuar, asegúrate de poder:

- [ ] Explicar qué es self-healing
- [ ] Demostrar auto-recuperación eliminando un Pod
- [ ] Identificar tiempo de detección y recuperación
- [ ] Reconocer escenarios donde self-healing NO funciona
- [ ] Interpretar eventos de recreación de Pods
- [ ] Diagnosticar CrashLoopBackOff

📁 **Laboratorio**: [`laboratorios/lab-05-self-healing.md`](./laboratorios/lab-05-self-healing.md)
- Duración: 40 minutos
- Simula fallos y observa recuperación automática

---

## ⚠️ 6. Limitaciones de ReplicaSets

### **6.1 Problema #1: No Actualiza Pods Existentes**

**El problema más crítico de ReplicaSets**:

```yaml
# Manifiesto INICIAL
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: nginx:1.20-alpine  # ← Versión 1.20
```

```bash
# Aplicar manifiesto inicial
kubectl apply -f replicaset.yaml

# Ver Pods con imagen 1.20
kubectl get pods -o jsonpath='{.items[*].spec.containers[0].image}'
# nginx:1.20-alpine nginx:1.20-alpine nginx:1.20-alpine ✅
```

**Ahora actualizar la imagen**:

```yaml
# Manifiesto ACTUALIZADO
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine  # ← Cambiar a 1.21
```

```bash
# Aplicar cambios
kubectl apply -f replicaset.yaml
# replicaset.apps/webapp configured ✅

# Ver Pods... ❌ SIGUEN CON VERSIÓN VIEJA
kubectl get pods -o jsonpath='{.items[*].spec.containers[0].image}'
# nginx:1.20-alpine nginx:1.20-alpine nginx:1.20-alpine
# ❌ NO SE ACTUALIZARON
```

**¿Por qué?**
- ReplicaSet solo garantiza **NÚMERO** de réplicas
- NO verifica ni actualiza **CONFIGURACIÓN** de Pods existentes
- Pods existentes NO se tocan
- Solo Pods **nuevos** usan el template actualizado

**Workaround manual** (tedioso):

```bash
# Eliminar Pods UNO POR UNO manualmente
kubectl delete pod webapp-abc12
# ReplicaSet crea nuevo Pod con imagen 1.21 ✅

kubectl delete pod webapp-def34
# ReplicaSet crea nuevo Pod con imagen 1.21 ✅

kubectl delete pod webapp-ghi56
# ReplicaSet crea nuevo Pod con imagen 1.21 ✅

# Ahora TODOS tienen imagen 1.21
kubectl get pods -o jsonpath='{.items[*].spec.containers[0].image}'
# nginx:1.21-alpine nginx:1.21-alpine nginx:1.21-alpine ✅
```

**❌ Problemas de este approach**:
- Manual y tedioso
- Propenso a errores
- **Downtime** (mientras eliminas Pods)
- No escalable (imagina 100 Pods)

---

### **6.2 Problema #2: Sin Rolling Updates**

```
┌──────────────────────────────────────────────────────────┐
│        COMPARACIÓN: REPLICASET vs DEPLOYMENT             │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ❌ REPLICASET (Update Manual):                         │
│  ┌─────────────────────────────────────┐                │
│  │ Step 1: Cambiar manifiesto          │                │
│  │ Step 2: kubectl apply               │                │
│  │ Step 3: Template actualizado ✅     │                │
│  │ Step 4: Pods VIEJOS siguen corriendo│                │
│  │ Step 5: Eliminar Pod 1 manualmente  │                │
│  │ Step 6: Esperar que se cree         │                │
│  │ Step 7: Repetir para Pod 2, 3, 4... │                │
│  │ Step 8: ⚠️ DOWNTIME durante proceso│                │
│  └─────────────────────────────────────┘                │
│                                                          │
│  ✅ DEPLOYMENT (Update Automático):                     │
│  ┌─────────────────────────────────────┐                │
│  │ Step 1: Cambiar manifiesto          │                │
│  │ Step 2: kubectl apply               │                │
│  │ Step 3: Rolling update AUTOMÁTICO   │                │
│  │         ├─ Crea Pod nuevo (v2)      │                │
│  │         ├─ Espera que esté Ready    │                │
│  │         ├─ Elimina Pod viejo (v1)   │                │
│  │         └─ Repite para todos        │                │
│  │ Step 4: ✅ ZERO downtime            │                │
│  │ Step 5: ✅ Rollback automático      │                │
│  └─────────────────────────────────────┘                │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

### **6.3 Problema #3: Sin Historial de Versiones**

```bash
# Intentar ver historial
kubectl rollout history rs webapp-rs
# error: replicasets.apps "webapp-rs" is not a valid rollout target

# Intentar rollback
kubectl rollout undo rs webapp-rs
# error: replicasets.apps "webapp-rs" is not a valid rollout target

# ❌ NO HAY ROLLBACK con ReplicaSets
```

---

### **6.4 Problema #4: Sin Estrategias de Despliegue**

**Deployments ofrecen**:
- ✅ **RollingUpdate**: Actualizar gradualmente (default)
- ✅ **Recreate**: Eliminar todos, crear todos (downtime aceptado)
- ✅ **Blue-Green**: Dos ambientes paralelos
- ✅ **Canary**: Desplegar gradualmente a porcentaje de usuarios

**ReplicaSets**:
- ❌ Solo escalado básico
- ❌ Sin control de updates
- ❌ Sin estrategias avanzadas

---

### **6.5 Cuándo Usar ReplicaSet vs Deployment**

| Característica | ReplicaSet | Deployment |
|----------------|------------|------------|
| **Auto-recuperación** | ✅ Sí | ✅ Sí |
| **Escalado horizontal** | ✅ Sí | ✅ Sí |
| **Rolling updates** | ❌ No | ✅ Sí |
| **Rollback** | ❌ No | ✅ Sí |
| **Historial de versiones** | ❌ No | ✅ Sí |
| **Estrategias de deploy** | ❌ No | ✅ Sí (RollingUpdate, Recreate) |
| **Pause/Resume** | ❌ No | ✅ Sí |
| **Status de rollout** | ❌ No | ✅ Sí |
| **Uso recomendado** | 🟡 Aprendizaje, testing | �� **Producción** |

**Conclusión**:

```
┌─────────────────────────────────────────────────────┐
│  🟡 REPLICASET: Útil para...                        │
│  ├─ Aprender arquitectura de Kubernetes             │
│  ├─ Entender reconciliation loop                    │
│  ├─ Testing rápido de escalado                      │
│  └─ Base teórica (Deployments usan ReplicaSets)     │
│                                                     │
│  🟢 DEPLOYMENT: SIEMPRE úsalo para...               │
│  ├─ Aplicaciones en PRODUCCIÓN                      │
│  ├─ Cualquier aplicación stateless                  │
│  ├─ Aplicaciones que requieren updates frecuentes   │
│  └─ Aplicaciones que necesitan rollback             │
└─────────────────────────────────────────────────────┘
```

---

### **✅ Checkpoint 06: Verificación de Limitaciones**

Antes de continuar, asegúrate de poder:

- [ ] Explicar por qué ReplicaSets NO actualizan Pods existentes
- [ ] Demostrar el problema de actualización manual
- [ ] Comparar ReplicaSet vs Deployment
- [ ] Identificar 4 limitaciones clave de ReplicaSets
- [ ] Decidir cuándo usar ReplicaSet vs Deployment
- [ ] Justificar por qué Deployments son mejores para producción

📁 **Laboratorio**: [`laboratorios/lab-06-limitaciones-replicasets.md`](./laboratorios/lab-06-limitaciones-replicasets.md)
- Duración: 35 minutos
- Experimenta con problemas de actualización

---

## ✅ 7. Best Practices de Producción

### **7.1 Naming Conventions**

**Patrón recomendado**:

```yaml
metadata:
  name: <app>-<component>-<environment>-rs

# Ejemplos:
# myapp-frontend-prod-rs
# myapp-backend-staging-rs
# myapp-cache-dev-rs
```

**Labels consistentes**:

```yaml
metadata:
  labels:
    app: myapp              # Nombre de la aplicación
    component: frontend     # Componente (frontend, backend, cache, db)
    environment: production # Ambiente (prod, staging, dev)
    tier: web              # Capa arquitectónica (web, api, data)
    version: v2.1.0        # Versión de la aplicación
    managed-by: kubectl    # Herramienta de gestión
```

---

### **7.2 Selector Best Practices**

**✅ Hacer**:

```yaml
# Selector específico y único
spec:
  selector:
    matchLabels:
      app: myapp
      component: frontend
      environment: production  # ← Segregar por ambiente
```

**❌ NO Hacer**:

```yaml
# Selector demasiado genérico
spec:
  selector:
    matchLabels:
      app: myapp  # ← ❌ Puede adoptar Pods de otros componentes
```

**Regla de oro**:
> Selector debe ser **suficientemente específico** para evitar adopciones accidentales

---

### **7.3 Resource Management**

**SIEMPRE define requests y limits**:

```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        image: nginx:alpine
        resources:
          requests:
            memory: "128Mi"  # ← Mínimo garantizado
            cpu: "250m"
          limits:
            memory: "256Mi"  # ← Máximo permitido
            cpu: "500m"
```

**Guía de sizing**:

| Tipo de App | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-------------|-------------|-----------|----------------|--------------|
| Web estático | 100m | 200m | 64Mi | 128Mi |
| API REST | 250m | 500m | 128Mi | 256Mi |
| App pesada | 500m | 1000m | 512Mi | 1Gi |

---

### **7.4 Health Checks (Probes)**

**SIEMPRE implementa probes**:

```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        
        # Liveness: ¿Está vivo?
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
        
        # Readiness: ¿Está listo para tráfico?
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 3
        
        # Startup: ¿Ya arrancó? (apps lentas)
        startupProbe:
          httpGet:
            path: /startup
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 5
          failureThreshold: 30  # 30*5s = 150s máximo
```

---

### **7.5 Security Context**

```yaml
spec:
  template:
    spec:
      # Security context a nivel Pod
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      
      containers:
      - name: app
        image: myapp:latest
        
        # Security context a nivel Container
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE  # Solo si necesita port < 1024
```

---

### **7.6 Antipatrones Comunes**

#### **❌ Antipatrón 1: ReplicaSet en Producción**

```yaml
# ❌ NO USES ESTO EN PRODUCCIÓN
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: myapp-prod
```

**Solución**:

```yaml
# ✅ USA DEPLOYMENT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-prod
```

---

#### **❌ Antipatrón 2: Selector Genérico**

```yaml
# ❌ PELIGROSO: Puede adoptar Pods no deseados
spec:
  selector:
    matchLabels:
      app: myapp  # Solo 1 label
```

**Solución**:

```yaml
# ✅ ESPECÍFICO: Reduce riesgo
spec:
  selector:
    matchLabels:
      app: myapp
      component: frontend
      environment: production
```

---

#### **❌ Antipatrón 3: Sin Resource Limits**

```yaml
# ❌ SIN LÍMITES: Pod puede consumir todo el nodo
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        # ❌ Sin resources definidos
```

**Consecuencias**:
- Pod puede causar OOM en el nodo
- Afecta a otros Pods
- Cluster inestable

---

#### **❌ Antipatrón 4: Sin Health Checks**

```yaml
# ❌ SIN PROBES: ReplicaSet no sabe si app está sana
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        # ❌ Sin livenessProbe ni readinessProbe
```

**Consecuencias**:
- Pods "Running" pero app crasheada
- Tráfico enviado a Pods no listos
- Debugging complicado

---

### **7.7 Template de Producción Completo**

📄 **Archivo**: [`ejemplos/05-best-practices/production-ready-replicaset.yaml`](./ejemplos/05-best-practices/production-ready-replicaset.yaml)

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: webapp-frontend-prod-rs
  labels:
    app: webapp
    component: frontend
    environment: production
    version: v2.1.0
    managed-by: kubectl
spec:
  replicas: 5
  
  selector:
    matchLabels:
      app: webapp
      component: frontend
      environment: production
  
  template:
    metadata:
      labels:
        app: webapp
        component: frontend
        environment: production
        version: v2.1.0
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
    
    spec:
      # Security context a nivel Pod
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      
      containers:
      - name: webapp
        image: nginx:alpine
        
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        - name: metrics
          containerPort: 9090
          protocol: TCP
        
        # Resources
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        startupProbe:
          httpGet:
            path: /startup
            port: http
          initialDelaySeconds: 0
          periodSeconds: 5
          failureThreshold: 30
        
        # Environment variables
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "info"
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        
        # Security context
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        # Volume mounts (para readOnlyRootFilesystem)
        volumeMounts:
        - name: cache
          mountPath: /var/cache/nginx
        - name: run
          mountPath: /var/run
      
      # Volumes
      volumes:
      - name: cache
        emptyDir: {}
      - name: run
        emptyDir: {}
      
      # Node affinity (opcional)
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - webapp
              topologyKey: kubernetes.io/hostname
```

---

### **✅ Checkpoint 07: Verificación de Best Practices**

Antes de continuar, asegúrate de poder:

- [ ] Aplicar naming conventions consistentes
- [ ] Crear selectores específicos y seguros
- [ ] Definir resources (requests/limits) apropiados
- [ ] Implementar health checks (liveness/readiness/startup)
- [ ] Aplicar security contexts
- [ ] Identificar 4 antipatrones comunes
- [ ] Crear un template production-ready completo

📁 **Laboratorio**: [`laboratorios/lab-07-production-ready.md`](./laboratorios/lab-07-production-ready.md)
- Duración: 50 minutos
- Crea ReplicaSet production-ready desde cero

---

## 🎓 Resumen del Módulo

### **Lo que aprendiste**

✅ **Conceptos fundamentales**:
- Qué es un ReplicaSet y su arquitectura
- Reconciliation loop y owner references
- Diferencias entre Pod y ReplicaSet

✅ **Gestión operacional**:
- Crear manifiestos YAML completos
- Usar selectores (matchLabels y matchExpressions)
- Escalar horizontal (declarativo e imperativo)
- Auto-recuperación (self-healing)

✅ **Limitaciones críticas**:
- ReplicaSets NO actualizan Pods existentes
- Sin rolling updates ni rollback
- Sin historial de versiones
- **Usa Deployments en producción**

✅ **Best practices**:
- Naming conventions y labels consistentes
- Resources y health checks obligatorios
- Security contexts y hardening
- Template production-ready

---

### **Puntos Clave para Recordar**

| # | Concepto | Punto Clave |
|---|----------|-------------|
| 1️⃣ | **ReplicaSet** | Garantiza **número** de réplicas, NO configuración |
| 2️⃣ | **Reconciliation** | Loop continuo cada ~5s: desired vs actual |
| 3️⃣ | **Selector** | Debe ser específico para evitar adopciones |
| 4️⃣ | **Self-healing** | Automático para Pod failures, NO para bugs |
| 5️⃣ | **Escalado** | Horizontal = más Pods, Vertical = más recursos |
| 6️⃣ | **Limitación #1** | NO actualiza Pods existentes (problema crítico) |
| 7️⃣ | **Producción** | **SIEMPRE usa Deployments**, NO ReplicaSets |

---

### **Comandos de Referencia Rápida**

```bash
# CREAR
kubectl apply -f replicaset.yaml
kubectl create -f replicaset.yaml

# LISTAR
kubectl get rs
kubectl get rs -o wide
kubectl get rs --show-labels

# INSPECCIONAR
kubectl describe rs <nombre>
kubectl get rs <nombre> -o yaml

# ESCALAR
kubectl scale rs <nombre> --replicas=<N>
kubectl edit rs <nombre>

# VER PODS
kubectl get pods -l <selector>
kubectl get pods --selector=app=webapp

# ELIMINAR
kubectl delete rs <nombre>
kubectl delete rs <nombre> --cascade=orphan  # Mantener Pods

# EVENTOS
kubectl get events --field-selector involvedObject.kind=ReplicaSet
kubectl get events --field-selector involvedObject.name=<rs-name>
```

---

## 📚 Recursos Adicionales

### **Documentación Oficial**
- 📖 [ReplicaSets - Kubernetes Docs](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
- 📖 [Owner References](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/)
- 📖 [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)

### **Próximo Módulo**

En el **Módulo 07: Deployments y Rolling Updates**, aprenderás:
- ✅ **Rolling updates** automáticos sin downtime
- ✅ **Rollback** a versiones anteriores
- ✅ **Estrategias de despliegue** (RollingUpdate, Recreate)
- ✅ **Historial de versiones** y revisiones
- ✅ **Pause/Resume** de deployments
- ✅ **Blue-Green** y **Canary** deployments

**Diferencia clave**:
- **Módulo 06** (este): Gestión de **réplicas** y escalado
- **Módulo 07**: Gestión de **versiones** y actualizaciones

---

## 🏆 Verificación Final de Conocimientos

Antes de continuar al Módulo 07, deberías poder responder:

### Conceptos
- [ ] ¿Qué problema resuelven los ReplicaSets?
- [ ] ¿Cómo funciona el reconciliation loop?
- [ ] ¿Qué son los owner references?
- [ ] ¿Cuál es la diferencia entre escalado horizontal y vertical?

### Operaciones
- [ ] ¿Cómo crear un ReplicaSet production-ready?
- [ ] ¿Cómo escalar un ReplicaSet de 3 a 10 réplicas?
- [ ] ¿Cómo verificar que self-healing funciona?
- [ ] ¿Cómo usar matchExpressions para selectors complejos?

### Limitaciones
- [ ] ¿Por qué ReplicaSets NO actualizan Pods existentes?
- [ ] ¿Cuáles son las 4 limitaciones principales?
- [ ] ¿Cuándo usar ReplicaSet vs Deployment?
- [ ] ¿Por qué Deployments son mejores para producción?

### Best Practices
- [ ] ¿Qué labels debe tener un Pod production-ready?
- [ ] ¿Qué probes son obligatorias?
- [ ] ¿Qué security contexts debe aplicar?
- [ ] Menciona 3 antipatrones comunes

---

**📅 Fecha de actualización**: Noviembre 2025  
**🔖 Versión**: 2.0  
**👨‍💻 Autor**: Curso Kubernetes AKS

---

**⬅️ Anterior**: [Módulo 05 - Gestión de Pods](../modulo-05-gestion-pods/README.md)  

## Resumen del Capítulo

Este capítulo cubrió los conceptos fundamentales de replicasets y escalado, desde la teoría hasta la práctica con ejemplos y manifiestos YAML aplicables en entornos reales. Los laboratorios en el directorio `laboratorios/` permiten practicar cada concepto, y el `RESUMEN-MODULO.md` sirve como guía de repaso rápido.
