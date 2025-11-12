# 📚 RESUMEN-MODULO: ReplicaSets y Gestión de Réplicas

## 🎯 Guía de Estudio del Módulo 06

Este documento es tu **guía de estudio** para dominar **ReplicaSets** en Kubernetes. Contiene:
- ✅ Objetivos de aprendizaje por sección
- ✅ Conceptos clave para memorizar
- ✅ Comandos esenciales
- ✅ Checkpoints de verificación
- ✅ Referencias a teoría, ejemplos y laboratorios

**Duración estimada**: 3-4 horas (teoría + práctica)

---

## 📋 Índice de Contenidos

1. [Fase 1: Fundamentos (60 min)](#fase-1-fundamentos)
2. [Fase 2: Operación Básica (60 min)](#fase-2-operación-básica)
3. [Fase 3: Operación Avanzada (70 min)](#fase-3-operación-avanzada)
4. [Fase 4: Producción (60 min)](#fase-4-producción)
5. [Comandos de Referencia](#comandos-de-referencia)
6. [Conceptos Clave](#conceptos-clave)
7. [Troubleshooting](#troubleshooting)

---

## 🚀 Fase 1: Fundamentos (60 minutos)

### **Objetivos de Aprendizaje**

Al completar esta fase, deberás:
- ✅ Definir qué es un ReplicaSet y su propósito
- ✅ Explicar la diferencia entre Pod y ReplicaSet
- ✅ Entender el reconciliation loop
- ✅ Comprender owner references
- ✅ Identificar componentes de la arquitectura

---

### **Sección 1: ¿Qué es un ReplicaSet?**

**📖 Teoría**: [`README.md - Sección 1`](./README.md#1-qué-es-un-replicaset)

#### **Conceptos Clave**

| Concepto | Definición | Por qué es importante |
|----------|------------|----------------------|
| **ReplicaSet** | Controlador que garantiza N réplicas de Pod corriendo | Base de alta disponibilidad |
| **Reconciliation Loop** | Ciclo continuo (~5s) que compara estado deseado vs actual | Garantiza self-healing automático |
| **Owner References** | Metadata que vincula Pod con su ReplicaSet | Permite cascading deletes |
| **Selector** | Criterio para identificar Pods gestionados | Define scope de gestión |

#### **Comparación Crítica: Pod vs ReplicaSet**

```
┌─────────────────────────────────────────────────────────┐
│                Pod Standalone vs ReplicaSet             │
├─────────────────────────────────────────────────────────┤
│  POD STANDALONE:                                        │
│  - Se crea UNA vez                                      │
│  - Si muere → ❌ NO se recrea                           │
│  - Sin auto-recuperación                                │
│  - Uso: Jobs puntuales, testing                         │
│                                                         │
│  REPLICASET:                                            │
│  - Crea N Pods (replicas: N)                            │
│  - Si 1 muere → ✅ Se recrea automáticamente            │
│  - Self-healing garantizado                             │
│  - Uso: Aplicaciones stateless, alta disponibilidad     │
└─────────────────────────────────────────────────────────┘
```

#### **Arquitectura del ReplicaSet**

```
┌────────────────────────────────────────────────┐
│          CONTROL PLANE                         │
│  ┌──────────────────────────────────────┐      │
│  │  kube-controller-manager             │      │
│  │  ┌────────────────────────────────┐  │      │
│  │  │  ReplicaSet Controller         │  │      │
│  │  │  - Lee spec.replicas = 3       │  │      │
│  │  │  - Cuenta Pods actuales = 2    │  │      │
│  │  │  - Detecta: 2 < 3 ❌           │  │      │
│  │  │  - Acción: Crear 1 Pod más     │  │      │
│  │  └────────────────────────────────┘  │      │
│  └──────────────────────────────────────┘      │
└────────────────────────────────────────────────┘
                    ↓ API Server
┌────────────────────────────────────────────────┐
│          ETCD (Estado Deseado)                 │
│  - ReplicaSet: replicas = 3                    │
│  - Selector: app=webapp                        │
└────────────────────────────────────────────────┘
                    ↓ Kubelet
┌────────────────────────────────────────────────┐
│          WORKER NODES                          │
│  ┌─────┐  ┌─────┐  ┌─────┐                     │
│  │Pod 1│  │Pod 2│  │Pod 3│  ← 3 réplicas       │
│  └─────┘  └─────┘  └─────┘                     │
└────────────────────────────────────────────────┘
```

#### **Reconciliation Loop Detallado**

```
┌─────────────────────────────────────────────────────────┐
│           RECONCILIATION LOOP (cada ~5 segundos)        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. LEER ESTADO DESEADO (ETCD)                          │
│     spec.replicas = 3                                   │
│     spec.selector: app=webapp                           │
│                                                         │
│  2. CONTAR PODS ACTUALES (API Server)                   │
│     kubectl get pods -l app=webapp                      │
│     Resultado: 2 Pods Running                           │
│                                                         │
│  3. COMPARAR                                            │
│     Deseado (3) vs Actual (2)                           │
│     3 > 2 → ❌ DISCREPANCIA                             │
│                                                         │
│  4. ACCIÓN CORRECTIVA                                   │
│     Crear 1 Pod nuevo                                   │
│     POST /api/v1/namespaces/default/pods                │
│                                                         │
│  5. ESPERAR 5 segundos                                  │
│     → Volver al paso 1                                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### **✅ Checkpoint 01: Fundamentos**

Verifica tu comprensión:

- [ ] ¿Qué problema resuelve un ReplicaSet que un Pod solo no puede?
- [ ] ¿Cada cuánto tiempo se ejecuta el reconciliation loop?
- [ ] Si eliminas 1 Pod de un ReplicaSet con 5 réplicas, ¿qué pasa?
- [ ] ¿Qué campo del manifiesto define el número de réplicas?
- [ ] ¿Qué es un owner reference y para qué sirve?

**📁 Práctica**: [`laboratorios/lab-01-conceptos-replicasets.md`](./laboratorios/lab-01-conceptos-replicasets.md)
- Crea tu primer ReplicaSet
- Observa reconciliation loop en acción
- Verifica owner references

**Tiempo estimado**: 30 minutos

---

## ⚙️ Fase 2: Operación Básica (60 minutos)

### **Objetivos de Aprendizaje**

Al completar esta fase, deberás:
- ✅ Crear manifiestos YAML de ReplicaSets
- ✅ Aplicar configuraciones con kubectl
- ✅ Inspeccionar estado de ReplicaSets
- ✅ Usar selectores básicos (matchLabels)
- ✅ Entender el template de Pod

---

### **Sección 2: Manifiestos YAML de ReplicaSets**

**📖 Teoría**: [`README.md - Sección 2`](./README.md#2-manifiestos-yaml-de-replicasets)

#### **Anatomía de un Manifiesto**

```yaml
apiVersion: apps/v1           # ← Versión de API
kind: ReplicaSet              # ← Tipo de recurso

metadata:                     # ← Metadatos del ReplicaSet
  name: webapp-rs
  labels:
    app: webapp

spec:                         # ← Especificación del ReplicaSet
  replicas: 3                 # ← Número de réplicas deseadas
  
  selector:                   # ← Criterio para identificar Pods
    matchLabels:
      app: webapp
  
  template:                   # ← Blueprint del Pod
    metadata:
      labels:
        app: webapp           # ← DEBE coincidir con selector
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
```

#### **4 Secciones Principales**

| Sección | Propósito | Obligatorio |
|---------|-----------|-------------|
| **apiVersion** | Define versión de API de Kubernetes | ✅ Sí |
| **kind** | Tipo de recurso (`ReplicaSet`) | ✅ Sí |
| **metadata** | Nombre, labels, annotations del RS | ✅ Sí |
| **spec** | Configuración: replicas, selector, template | ✅ Sí |

#### **Campos Obligatorios vs Opcionales**

| Campo | Obligatorio | Descripción | Ejemplo |
|-------|-------------|-------------|---------|
| `spec.replicas` | ❌ No (default: 1) | Número de réplicas | `replicas: 3` |
| `spec.selector` | ✅ Sí | Selector de Pods | `matchLabels: {app: webapp}` |
| `spec.template` | ✅ Sí | Blueprint del Pod | (ver ejemplo arriba) |
| `spec.template.metadata.labels` | ✅ Sí | Labels del Pod | `labels: {app: webapp}` |
| `spec.template.spec` | ✅ Sí | Configuración del Pod | `containers: [...]` |

#### **Regla Crítica**

```
┌──────────────────────────────────────────────────────┐
│         REGLA DE ORO: SELECTOR = LABELS             │
├──────────────────────────────────────────────────────┤
│                                                      │
│  spec.selector.matchLabels                           │
│         DEBE coincidir con                           │
│  spec.template.metadata.labels                       │
│                                                      │
│  ❌ SI NO COINCIDEN:                                 │
│  - Error al crear ReplicaSet                         │
│  - Mensaje: "selector does not match template"      │
│                                                      │
│  ✅ CORRECTO:                                        │
│  selector:                                           │
│    matchLabels:                                      │
│      app: webapp  ← IGUAL                            │
│  template:                                           │
│    metadata:                                         │
│      labels:                                         │
│        app: webapp  ← IGUAL                          │
│                                                      │
└──────────────────────────────────────────────────────┘
```

#### **Comandos de Gestión Esenciales**

```bash
# CREAR ReplicaSet
kubectl apply -f replicaset.yaml
kubectl create -f replicaset.yaml

# LISTAR ReplicaSets
kubectl get rs
kubectl get rs -o wide
kubectl get replicasets --show-labels

# INSPECCIONAR
kubectl describe rs webapp-rs
kubectl get rs webapp-rs -o yaml
kubectl get rs webapp-rs -o json

# VER PODS GESTIONADOS
kubectl get pods -l app=webapp
kubectl get pods --selector=app=webapp -o wide

# EDITAR (abre editor)
kubectl edit rs webapp-rs

# ELIMINAR
kubectl delete rs webapp-rs
kubectl delete -f replicaset.yaml

# ELIMINAR SIN borrar Pods (orphan)
kubectl delete rs webapp-rs --cascade=orphan
```

#### **Ejemplo Práctico: Primer ReplicaSet**

📄 **Archivo**: [`ejemplos/01-manifiestos/01-simple-replicaset.yaml`](./ejemplos/01-manifiestos/01-simple-replicaset.yaml)

```bash
# Crear ReplicaSet
kubectl apply -f ejemplos/01-manifiestos/01-simple-replicaset.yaml

# Ver ReplicaSet
kubectl get rs
# NAME        DESIRED   CURRENT   READY   AGE
# webapp-rs   3         3         3       10s

# Ver Pods creados
kubectl get pods -l app=webapp
# NAME             READY   STATUS    RESTARTS   AGE
# webapp-rs-abc    1/1     Running   0          15s
# webapp-rs-def    1/1     Running   0          15s
# webapp-rs-ghi    1/1     Running   0          15s

# Ver detalles
kubectl describe rs webapp-rs
# Replicas:      3 current / 3 desired
# Pods Status:   3 Running / 0 Waiting / 0 Succeeded / 0 Failed
```

#### **✅ Checkpoint 02: Manifiestos YAML**

Verifica tu comprensión:

- [ ] ¿Cuáles son las 4 secciones principales de un manifiesto?
- [ ] ¿Qué pasa si `spec.selector` no coincide con `template.metadata.labels`?
- [ ] ¿Cómo listar todos los Pods gestionados por un ReplicaSet?
- [ ] ¿Qué comando usas para ver eventos de un ReplicaSet?
- [ ] ¿Cómo eliminar un ReplicaSet sin eliminar sus Pods?

**📁 Práctica**: [`laboratorios/lab-02-manifiestos-replicasets.md`](./laboratorios/lab-02-manifiestos-replicasets.md)
- Crea ReplicaSet desde cero
- Practica comandos de inspección
- Experimenta con eliminación cascade/orphan

**Tiempo estimado**: 30 minutos

---

### **Sección 3: Selectors y Gestión de Pods**

**📖 Teoría**: [`README.md - Sección 3`](./README.md#3-selectors-y-gestión-de-pods)

#### **Tipos de Selectores**

| Tipo | Sintaxis | Uso | Complejidad |
|------|----------|-----|-------------|
| **matchLabels** | Igualdad simple | Labels exactos | 🟢 Básico |
| **matchExpressions** | Operadores avanzados | Lógica compleja | 🟡 Avanzado |

#### **matchLabels: Selector Simple**

```yaml
spec:
  selector:
    matchLabels:
      app: webapp
      tier: frontend
      environment: production

# Traducción SQL: 
# SELECT * FROM pods 
# WHERE app='webapp' 
#   AND tier='frontend' 
#   AND environment='production'
```

**Comportamiento**: Todos los labels deben coincidir (**AND lógico**)

#### **matchExpressions: Operadores Avanzados**

| Operador | Descripción | Ejemplo YAML |
|----------|-------------|--------------|
| **In** | Label en lista de valores | `{key: env, operator: In, values: [prod, staging]}` |
| **NotIn** | Label NO en lista | `{key: env, operator: NotIn, values: [dev]}` |
| **Exists** | Label existe (cualquier valor) | `{key: app, operator: Exists}` |
| **DoesNotExist** | Label NO existe | `{key: deprecated, operator: DoesNotExist}` |

#### **Ejemplo Completo: Selector Combinado**

```yaml
spec:
  selector:
    matchLabels:
      app: myapp              # ← Simple: app DEBE ser "myapp"
    
    matchExpressions:
    - key: environment
      operator: In
      values:
      - production
      - staging             # ← environment IN (prod, staging)
    
    - key: tier
      operator: NotIn
      values:
      - legacy              # ← tier NOT IN (legacy)
    
    - key: monitored
      operator: Exists      # ← Label "monitored" EXISTE
    
    - key: deprecated
      operator: DoesNotExist # ← Label "deprecated" NO EXISTE

# Traducción SQL:
# SELECT * FROM pods 
# WHERE app = 'myapp'
#   AND environment IN ('production', 'staging')
#   AND tier NOT IN ('legacy')
#   AND EXISTS (SELECT label FROM labels WHERE key='monitored')
#   AND NOT EXISTS (SELECT label FROM labels WHERE key='deprecated')
```

#### **Flujo de Reconciliation con Selector**

```
┌──────────────────────────────────────────────────────┐
│       RECONCILIATION CON SELECTOR                    │
├──────────────────────────────────────────────────────┤
│                                                      │
│  1. ReplicaSet lee su selector:                      │
│     matchLabels: {app: webapp, env: prod}            │
│                                                      │
│  2. Busca Pods que coincidan:                        │
│     kubectl get pods -l app=webapp,env=prod          │
│                                                      │
│  3. Cuenta Pods encontrados:                         │
│     Pods actuales: 4                                 │
│                                                      │
│  4. Compara con deseado:                             │
│     spec.replicas: 3                                 │
│     4 > 3 → ⚠️ Hay 1 Pod de más                      │
│                                                      │
│  5. Acción correctiva:                               │
│     Eliminar 1 Pod (el más reciente)                 │
│                                                      │
└──────────────────────────────────────────────────────┘
```

#### **⚠️ Peligro: Adopción Accidental de Pods**

```yaml
# ESCENARIO PELIGROSO

# Paso 1: Crear Pod manual
apiVersion: v1
kind: Pod
metadata:
  name: my-manual-pod
  labels:
    app: webapp  # ← Label genérico
spec:
  containers:
  - name: nginx
    image: nginx:alpine

# Paso 2: Crear ReplicaSet con selector genérico
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: webapp-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp  # ← ❌ Mismo label que Pod manual
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx:alpine

# RESULTADO:
# - ReplicaSet "adopta" my-manual-pod
# - Solo crea 2 Pods nuevos (ya tenía 1)
# - Si eliminas ReplicaSet → my-manual-pod se elimina también
```

**Solución**: Selectores específicos

```yaml
# ✅ CORRECTO: Selector único
spec:
  selector:
    matchLabels:
      app: webapp
      managed-by: replicaset-webapp-rs  # ← Label único
      environment: production
```

#### **✅ Checkpoint 03: Selectors**

Verifica tu comprensión:

- [ ] ¿Cuál es la diferencia entre `matchLabels` y `matchExpressions`?
- [ ] Menciona los 4 operadores de `matchExpressions`
- [ ] ¿Cómo combinar `matchLabels` y `matchExpressions`?
- [ ] ¿Qué es la "adopción accidental" de Pods?
- [ ] ¿Cómo inspeccionar el selector de un ReplicaSet en ejecución?

**📁 Práctica**: [`laboratorios/lab-03-selectors-avanzados.md`](./laboratorios/lab-03-selectors-avanzados.md)
- Crea selectores con `matchExpressions`
- Experimenta con adopción de Pods
- Segrega ambientes con selectores

**Tiempo estimado**: 35 minutos

---

## 📈 Fase 3: Operación Avanzada (70 minutos)

### **Objetivos de Aprendizaje**

Al completar esta fase, deberás:
- ✅ Escalar ReplicaSets horizontal
- ✅ Diferenciar escalado declarativo vs imperativo
- ✅ Demostrar auto-recuperación (self-healing)
- ✅ Identificar limitaciones críticas
- ✅ Comparar ReplicaSet vs Deployment

---

### **Sección 4: Escalado Horizontal**

**📖 Teoría**: [`README.md - Sección 4`](./README.md#4-escalado-horizontal)

#### **Escalado Horizontal vs Vertical**

```
┌────────────────────────────────────────────────────────┐
│         HORIZONTAL vs VERTICAL                         │
├────────────────────────────────────────────────────────┤
│                                                        │
│  HORIZONTAL (ReplicaSet ✅):                           │
│  Aumentar número de Pods                               │
│  ┌───┐     →    ┌───┐ ┌───┐ ┌───┐                     │
│  │ 1 │           │ 1 │ │ 2 │ │ 3 │                     │
│  └───┘           └───┘ └───┘ └───┘                     │
│  1 Pod            3 Pods (más réplicas)                │
│                                                        │
│  VERTICAL (ReplicaSet ❌):                             │
│  Aumentar recursos por Pod                             │
│  ┌─────────┐  →  ┌─────────┐                           │
│  │ CPU: 1  │     │ CPU: 2  │                           │
│  │ RAM: 2G │     │ RAM: 4G │                           │
│  └─────────┘     └─────────┘                           │
│  (NO lo hace ReplicaSet, requiere VPA)                 │
│                                                        │
└────────────────────────────────────────────────────────┘
```

#### **Métodos de Escalado**

| Método | Comando | Persistente | Uso |
|--------|---------|-------------|-----|
| **Declarativo** | `kubectl apply -f` (modificar YAML) | ✅ Sí | 🟢 Producción |
| **Imperativo** | `kubectl scale` | ❌ No | 🟡 Testing |

#### **Escalado Declarativo (Recomendado)**

```yaml
# Paso 1: Modificar replicaset.yaml
spec:
  replicas: 5  # ← Cambiar de 3 a 5

# Paso 2: Aplicar
kubectl apply -f replicaset.yaml

# Paso 3: Observar
kubectl get pods -l app=webapp --watch
```

**Ventajas**:
- ✅ Cambios auditables (Git)
- ✅ Reproducible
- ✅ Declarativo (GitOps)

#### **Escalado Imperativo**

```bash
# Escalar a 10 réplicas
kubectl scale rs webapp-rs --replicas=10

# Escalar a 0 (detener todos los Pods)
kubectl scale rs webapp-rs --replicas=0

# Verificar
kubectl get rs webapp-rs
```

**Desventajas**:
- ❌ NO se refleja en YAML
- ❌ Se pierde en próximo `kubectl apply`
- ❌ No auditable

#### **Comandos de Escalado**

```bash
# Escalar declarativamente (editar YAML y aplicar)
kubectl apply -f replicaset.yaml

# Escalar imperativamente
kubectl scale rs webapp-rs --replicas=5

# Escalar con edit interactivo
kubectl edit rs webapp-rs
# (Modificar spec.replicas y guardar)

# Ver estado durante escalado
kubectl get pods -l app=webapp --watch

# Ver historial de eventos
kubectl get events --field-selector involvedObject.kind=ReplicaSet
```

#### **✅ Checkpoint 04: Escalado**

Verifica tu comprensión:

- [ ] ¿Qué diferencia hay entre escalado horizontal y vertical?
- [ ] ¿Qué método de escalado es mejor para producción?
- [ ] ¿Cómo escalar de 3 a 10 réplicas imperativamente?
- [ ] ¿Qué comando observa Pods en tiempo real durante escalado?
- [ ] ¿Qué pasa si escalas a 0 réplicas?

**📁 Práctica**: [`laboratorios/lab-04-escalado-horizontal.md`](./laboratorios/lab-04-escalado-horizontal.md)
- Escala declarativa e imperativamente
- Simula carga y observa distribución
- Escala a cero y recupera

**Tiempo estimado**: 35 minutos

---

### **Sección 5: Auto-recuperación (Self-Healing)**

**📖 Teoría**: [`README.md - Sección 5`](./README.md#5-auto-recuperación-self-healing)

#### **¿Qué es Self-Healing?**

```
┌──────────────────────────────────────────────────────┐
│            SELF-HEALING AUTOMÁTICO                   │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ESTADO INICIAL: 3 Pods Running                      │
│  ┌───┐ ┌───┐ ┌───┐                                   │
│  │ 1 │ │ 2 │ │ 3 │                                   │
│  └───┘ └───┘ └───┘                                   │
│                                                      │
│  ⚠️ Pod 2 FALLA (OOMKilled, crashea, nodo muere)     │
│  ┌───┐   ❌   ┌───┐                                   │
│  │ 1 │        │ 3 │                                   │
│  └───┘        └───┘                                   │
│                                                      │
│  🔄 ReplicaSet DETECTA (reconciliation loop)          │
│     Actual: 2 Pods                                   │
│     Deseado: 3 Pods                                  │
│     Acción: Crear 1 Pod nuevo                        │
│                                                      │
│  ✅ RECUPERADO (~3-7 segundos)                        │
│  ┌───┐ ┌───┐ ┌───┐                                   │
│  │ 1 │ │ 4 │ │ 3 │  ← Pod nuevo                      │
│  └───┘ └───┘ └───┘                                   │
│                                                      │
└──────────────────────────────────────────────────────┘
```

#### **Escenarios de Auto-recuperación**

| Escenario | ReplicaSet | Tiempo Recuperación |
|-----------|------------|---------------------|
| **Pod eliminado** | ✅ Crea nuevo | ~3-5 segundos |
| **Pod crasheado** | ✅ Crea nuevo | ~5-10 segundos |
| **Node falla** | ✅ Migra Pods | ~1-5 minutos |
| **OOMKilled** | ✅ Crea nuevo | ~5-15 segundos |

#### **Limitaciones de Self-Healing**

⚠️ **ReplicaSet NO resuelve**:

| Problema | ¿Se recupera? | Solución |
|----------|---------------|----------|
| **Bug en código** | ❌ Loop infinito (CrashLoopBackOff) | Arreglar código |
| **Config incorrecta** | ❌ Pod reinicia constantemente | Corregir ConfigMap |
| **Falta recursos en cluster** | ❌ Pod queda Pending | Agregar nodos |
| **Image pull error** | ❌ ImagePullBackOff | Corregir imagen |

#### **Demostración Práctica**

```bash
# Terminal 1: Observar Pods en tiempo real
kubectl get pods -l app=demo --watch

# Terminal 2: Eliminar un Pod
POD_NAME=$(kubectl get pods -l app=demo -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME

# Terminal 1 muestra:
# demo-abc12   1/1     Terminating   30s
# demo-xyz99   0/1     Pending       0s   ← NUEVO POD
# demo-xyz99   0/1     ContainerCreating   0s
# demo-xyz99   1/1     Running       2s   ← ✅ RECUPERADO
```

#### **Métricas de Recuperación**

- **Detection time**: 1-2 segundos (reconciliation loop)
- **Recovery time**: 2-5 segundos (pull image + start)
- **Total downtime**: 3-7 segundos típico

#### **✅ Checkpoint 05: Self-Healing**

Verifica tu comprensión:

- [ ] ¿Qué es self-healing?
- [ ] ¿Cuánto tarda ReplicaSet en detectar un Pod caído?
- [ ] ¿Qué pasa si eliminas 2 Pods de un ReplicaSet con 5 réplicas?
- [ ] Menciona 3 escenarios donde self-healing NO funciona
- [ ] ¿Qué es CrashLoopBackOff?

**📁 Práctica**: [`laboratorios/lab-05-self-healing.md`](./laboratorios/lab-05-self-healing.md)
- Simula fallos de Pods
- Mide tiempos de recuperación
- Diagnostica CrashLoopBackOff

**Tiempo estimado**: 40 minutos

---

### **Sección 6: Limitaciones de ReplicaSets**

**📖 Teoría**: [`README.md - Sección 6`](./README.md#6-limitaciones-de-replicasets)

#### **Limitación #1: NO Actualiza Pods Existentes** (CRÍTICO)

```
┌──────────────────────────────────────────────────────┐
│     PROBLEMA: ReplicaSet NO actualiza Pods           │
├──────────────────────────────────────────────────────┤
│                                                      │
│  PASO 1: Manifiesto inicial                          │
│  spec:                                               │
│    replicas: 3                                       │
│    template:                                         │
│      spec:                                           │
│        containers:                                   │
│        - image: nginx:1.20-alpine                    │
│                                                      │
│  PASO 2: Aplicar                                     │
│  kubectl apply -f rs.yaml                            │
│  → Crea 3 Pods con imagen 1.20                       │
│                                                      │
│  PASO 3: Cambiar imagen en manifiesto                │
│  spec:                                               │
│    template:                                         │
│      spec:                                           │
│        containers:                                   │
│        - image: nginx:1.21-alpine  ← CAMBIO          │
│                                                      │
│  PASO 4: Aplicar cambios                             │
│  kubectl apply -f rs.yaml                            │
│  → ❌ Pods SIGUEN con imagen 1.20                    │
│  → ReplicaSet NO los actualiza                       │
│                                                      │
│  WORKAROUND MANUAL (tedioso):                        │
│  kubectl delete pod rs-abc12  ← Eliminar 1 a 1      │
│  kubectl delete pod rs-def34                         │
│  kubectl delete pod rs-ghi56                         │
│  → ⚠️ DOWNTIME durante eliminación                   │
│                                                      │
└──────────────────────────────────────────────────────┘
```

#### **Comparación: ReplicaSet vs Deployment**

| Característica | ReplicaSet | Deployment |
|----------------|------------|------------|
| **Auto-recuperación** | ✅ Sí | ✅ Sí |
| **Escalado** | ✅ Sí | ✅ Sí |
| **Rolling Updates** | ❌ No | ✅ Sí |
| **Rollback** | ❌ No | ✅ Sí |
| **Historial de versiones** | ❌ No | ✅ Sí |
| **Estrategias de deploy** | ❌ No | ✅ Sí (RollingUpdate, Recreate) |
| **Pause/Resume** | ❌ No | ✅ Sí |
| **Uso recomendado** | 🟡 Aprendizaje | 🟢 **Producción** |

#### **4 Limitaciones Principales**

| # | Limitación | Impacto | Solución |
|---|------------|---------|----------|
| 1️⃣ | NO actualiza Pods existentes | Requiere eliminación manual | Usar Deployment |
| 2️⃣ | Sin rolling updates | Downtime durante updates | Usar Deployment |
| 3️⃣ | Sin historial de versiones | No hay rollback | Usar Deployment |
| 4️⃣ | Sin estrategias de deploy | Solo escalado básico | Usar Deployment |

#### **Conclusión Crítica**

```
┌──────────────────────────────────────────────────────┐
│              CUÁNDO USAR QUÉ                         │
├──────────────────────────────────────────────────────┤
│                                                      │
│  🟡 REPLICASET:                                      │
│  - Aprendizaje de Kubernetes                         │
│  - Entender arquitectura interna                     │
│  - Testing rápido de escalado                        │
│  - ❌ NO para producción                             │
│                                                      │
│  🟢 DEPLOYMENT:                                      │
│  - ✅ SIEMPRE en producción                          │
│  - Aplicaciones stateless                            │
│  - Apps con updates frecuentes                       │
│  - Necesitas rollback automático                     │
│                                                      │
│  Nota: Deployment INTERNAMENTE usa ReplicaSet        │
│  (crea uno por cada versión)                         │
│                                                      │
└──────────────────────────────────────────────────────┘
```

#### **✅ Checkpoint 06: Limitaciones**

Verifica tu comprensión:

- [ ] ¿Por qué ReplicaSet NO actualiza Pods existentes?
- [ ] Menciona las 4 limitaciones principales de ReplicaSets
- [ ] ¿Cuándo usar ReplicaSet vs Deployment?
- [ ] ¿Qué es un rolling update?
- [ ] ¿Por qué Deployments son mejores para producción?

**📁 Práctica**: [`laboratorios/lab-06-limitaciones-replicasets.md`](./laboratorios/lab-06-limitaciones-replicasets.md)
- Experimenta con problema de actualización
- Compara ReplicaSet vs Deployment
- Practica update manual

**Tiempo estimado**: 35 minutos

---

## 🏭 Fase 4: Producción (60 minutos)

### **Objetivos de Aprendizaje**

Al completar esta fase, deberás:
- ✅ Aplicar naming conventions
- ✅ Definir resources y limits
- ✅ Implementar health checks
- ✅ Aplicar security contexts
- ✅ Identificar antipatrones
- ✅ Crear template production-ready

---

### **Sección 7: Best Practices de Producción**

**📖 Teoría**: [`README.md - Sección 7`](./README.md#7-best-practices-de-producción)

#### **Naming Conventions**

```yaml
# Patrón recomendado
metadata:
  name: <app>-<component>-<environment>-rs

# Ejemplos:
# - myapp-frontend-prod-rs
# - myapp-backend-staging-rs
# - myapp-cache-dev-rs
```

#### **Labels Obligatorias**

```yaml
metadata:
  labels:
    app: myapp              # Nombre aplicación
    component: frontend     # Componente
    environment: production # Ambiente
    tier: web              # Capa arquitectónica
    version: v2.1.0        # Versión
    managed-by: kubectl    # Herramienta
```

#### **Resources (Requests & Limits)**

**SIEMPRE define resources**:

```yaml
resources:
  requests:
    memory: "128Mi"  # ← Mínimo garantizado
    cpu: "250m"
  limits:
    memory: "256Mi"  # ← Máximo permitido
    cpu: "500m"
```

**Guía de sizing**:

| Tipo App | CPU Request | CPU Limit | Memory Request | Memory Limit |
|----------|-------------|-----------|----------------|--------------|
| Web estático | 100m | 200m | 64Mi | 128Mi |
| API REST | 250m | 500m | 128Mi | 256Mi |
| App pesada | 500m | 1000m | 512Mi | 1Gi |

#### **Health Checks (Obligatorio)**

```yaml
# Liveness: ¿Está vivo?
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

# Readiness: ¿Está listo?
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
  failureThreshold: 30  # 30*5s = 150s max
```

#### **Security Context**

```yaml
# Pod-level
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000

# Container-level
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
```

#### **4 Antipatrones Comunes**

| # | Antipatrón | Por qué es malo | Solución |
|---|------------|-----------------|----------|
| 1️⃣ | ReplicaSet en producción | Sin rolling updates | Usar Deployment |
| 2️⃣ | Selector genérico | Adopción accidental | Selectores específicos |
| 3️⃣ | Sin resources | OOM en nodo | Definir requests/limits |
| 4️⃣ | Sin probes | Tráfico a Pods no listos | Implementar liveness/readiness |

#### **Template Production-Ready**

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
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
      - name: webapp
        image: nginx:alpine
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
```

#### **✅ Checkpoint 07: Production Ready**

Verifica tu comprensión:

- [ ] ¿Qué naming convention recomiendas?
- [ ] ¿Qué labels son obligatorias?
- [ ] ¿Por qué es crítico definir resources?
- [ ] Menciona los 3 tipos de probes
- [ ] ¿Qué security contexts debes aplicar?
- [ ] Menciona 3 antipatrones comunes

**📁 Práctica**: [`laboratorios/lab-07-production-ready.md`](./laboratorios/lab-07-production-ready.md)
- Crea ReplicaSet production-ready
- Aplica todas las best practices
- Valida con checklist

**Tiempo estimado**: 50 minutos

---

## 🎓 Comandos de Referencia

### **Gestión de ReplicaSets**

```bash
# CREAR
kubectl apply -f replicaset.yaml
kubectl create -f replicaset.yaml

# LISTAR
kubectl get rs
kubectl get rs -o wide
kubectl get rs --show-labels
kubectl get rs -A  # Todos los namespaces

# INSPECCIONAR
kubectl describe rs <nombre>
kubectl get rs <nombre> -o yaml
kubectl get rs <nombre> -o json

# EDITAR
kubectl edit rs <nombre>
kubectl apply -f replicaset.yaml  # Declarativo

# ELIMINAR
kubectl delete rs <nombre>
kubectl delete -f replicaset.yaml
kubectl delete rs <nombre> --cascade=orphan
```

### **Gestión de Pods**

```bash
# LISTAR PODS DE UN REPLICASET
kubectl get pods -l app=webapp
kubectl get pods --selector=app=webapp,env=prod
kubectl get pods -l app=webapp -o wide

# OBSERVAR EN TIEMPO REAL
kubectl get pods -l app=webapp --watch

# ELIMINAR POD (self-healing)
kubectl delete pod <pod-name>
kubectl delete pods -l app=webapp  # Todos
```

### **Escalado**

```bash
# ESCALAR IMPERATIVAMENTE
kubectl scale rs <nombre> --replicas=<N>

# ESCALAR DECLARATIVAMENTE
# (Editar spec.replicas en YAML y aplicar)
kubectl apply -f replicaset.yaml

# ESCALAR A CERO
kubectl scale rs <nombre> --replicas=0
```

### **Inspección y Debugging**

```bash
# VER EVENTOS
kubectl get events --field-selector involvedObject.kind=ReplicaSet
kubectl get events --field-selector involvedObject.name=<rs-name>

# VER SELECTOR
kubectl get rs <nombre> -o jsonpath='{.spec.selector}'

# VER OWNER REFERENCES DE UN POD
kubectl get pod <pod-name> -o yaml | grep -A 10 ownerReferences

# VER LOGS DE PODS
kubectl logs -l app=webapp  # Todos los Pods
kubectl logs <pod-name>
kubectl logs <pod-name> -f  # Follow
```

---

## 💡 Conceptos Clave

### **7 Puntos Críticos para Memorizar**

| # | Concepto | Punto Clave |
|---|----------|-------------|
| 1️⃣ | **ReplicaSet** | Garantiza **número** de réplicas, NO configuración |
| 2️⃣ | **Reconciliation** | Loop continuo cada ~5s: desired vs actual |
| 3️⃣ | **Selector** | Debe ser específico para evitar adopciones |
| 4️⃣ | **Self-healing** | Automático para Pod failures, NO para bugs |
| 5️⃣ | **Escalado** | Horizontal = más Pods, Vertical = más recursos |
| 6️⃣ | **Limitación #1** | NO actualiza Pods existentes (problema crítico) |
| 7️⃣ | **Producción** | **SIEMPRE usa Deployments**, NO ReplicaSets |

### **Comparación Rápida**

| Aspecto | Pod | ReplicaSet | Deployment |
|---------|-----|------------|------------|
| **Auto-recuperación** | ❌ | ✅ | ✅ |
| **Escalado** | ❌ | ✅ | ✅ |
| **Rolling Updates** | ❌ | ❌ | ✅ |
| **Rollback** | ❌ | ❌ | ✅ |
| **Historial** | ❌ | ❌ | ✅ |
| **Producción** | ❌ | ❌ | ✅ |

---

## 🔧 Troubleshooting

### **Problema 1: ReplicaSet no crea Pods**

```bash
# Síntomas
kubectl get rs
# DESIRED   CURRENT   READY
# 3         0         0

# Diagnóstico
kubectl describe rs <nombre>
# Mirar sección Events

# Causas comunes:
# - Selector no coincide con labels
# - Recursos insuficientes en cluster
# - Image pull error
```

### **Problema 2: Pods en CrashLoopBackOff**

```bash
# Síntomas
kubectl get pods
# NAME        READY   STATUS              RESTARTS
# pod-abc     0/1     CrashLoopBackOff    5

# Diagnóstico
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>

# Causas comunes:
# - Bug en código
# - ConfigMap incorrecta
# - Recursos insuficientes
```

### **Problema 3: ReplicaSet adopta Pods no deseados**

```bash
# Síntomas
kubectl get pods -l app=myapp
# Más Pods de los esperados

# Diagnóstico
kubectl get pods -l app=myapp -o yaml | grep -A 5 ownerReferences

# Solución
# - Hacer selector más específico
# - Agregar labels únicos
```

### **Problema 4: Pods en Pending**

```bash
# Síntomas
kubectl get pods
# NAME        READY   STATUS    RESTARTS
# pod-abc     0/1     Pending   0

# Diagnóstico
kubectl describe pod <pod-name>
# Mirar eventos: "insufficient cpu", "insufficient memory"

# Soluciones:
# - Agregar nodos al cluster
# - Reducir resources.requests
# - Eliminar Pods no necesarios
```

---

## 🎯 Verificación Final

### **Checklist de Conocimientos**

#### Conceptos Fundamentales
- [ ] Definir ReplicaSet y su propósito
- [ ] Explicar reconciliation loop
- [ ] Entender owner references
- [ ] Diferenciar Pod vs ReplicaSet vs Deployment
- [ ] Explicar self-healing

#### Operaciones Básicas
- [ ] Crear manifiesto YAML de ReplicaSet
- [ ] Aplicar configuración con kubectl
- [ ] Listar e inspeccionar ReplicaSets
- [ ] Ver Pods gestionados por ReplicaSet
- [ ] Eliminar ReplicaSet (cascade y orphan)

#### Selectores y Labels
- [ ] Usar matchLabels
- [ ] Usar matchExpressions (4 operadores)
- [ ] Combinar matchLabels y matchExpressions
- [ ] Evitar adopción accidental de Pods
- [ ] Inspeccionar selectores en ejecución

#### Escalado
- [ ] Escalar declarativamente (modificar YAML)
- [ ] Escalar imperativamente (kubectl scale)
- [ ] Observar escalado en tiempo real
- [ ] Escalar a cero
- [ ] Diferenciar horizontal vs vertical

#### Auto-recuperación
- [ ] Demostrar self-healing eliminando Pod
- [ ] Medir tiempos de recuperación
- [ ] Identificar limitaciones de self-healing
- [ ] Diagnosticar CrashLoopBackOff
- [ ] Interpretar eventos de recreación

#### Limitaciones
- [ ] Explicar por qué NO actualiza Pods existentes
- [ ] Mencionar 4 limitaciones principales
- [ ] Comparar ReplicaSet vs Deployment
- [ ] Justificar uso de Deployments en producción

#### Best Practices
- [ ] Aplicar naming conventions
- [ ] Crear selectores específicos
- [ ] Definir resources (requests/limits)
- [ ] Implementar health checks (liveness/readiness)
- [ ] Aplicar security contexts
- [ ] Identificar 4 antipatrones
- [ ] Crear template production-ready completo

---

## 📚 Recursos Adicionales

### **Documentación Oficial**
- 📖 [ReplicaSets - Kubernetes Docs](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
- 📖 [Owner References](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/)
- 📖 [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)

### **Estructura del Módulo**
- 📄 [`README.md`](./README.md) - Teoría completa
- 📁 [`ejemplos/`](./ejemplos/) - Manifiestos YAML de ejemplo
- 📁 [`laboratorios/`](./laboratorios/) - Prácticas guiadas

### **Próximos Pasos**

**➡️ Módulo 07: Deployments y Rolling Updates**

En el próximo módulo aprenderás:
- ✅ Rolling updates automáticos sin downtime
- ✅ Rollback a versiones anteriores
- ✅ Estrategias de despliegue (RollingUpdate, Recreate)
- ✅ Historial de versiones y revisiones
- ✅ Pause/Resume de deployments
- ✅ Blue-Green y Canary deployments

**Diferencia clave**:
- **Módulo 06** (este): Gestión de **réplicas** y escalado
- **Módulo 07**: Gestión de **versiones** y actualizaciones

---

**📅 Fecha de actualización**: Noviembre 2025  
**🔖 Versión**: 2.0  
**👨‍💻 Autor**: Curso Kubernetes AKS

---

**⬅️ Volver al README**: [README.md](./README.md)  
**➡️ Siguiente**: [Módulo 07 - Deployments](../modulo-07-deployments-rollouts/README.md)
