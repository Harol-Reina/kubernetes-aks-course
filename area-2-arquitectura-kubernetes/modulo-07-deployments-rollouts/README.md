# Capítulo 9: Deployments y Rollouts

Los ReplicaSets mantienen Pods vivos, pero no gestionan actualizaciones. Los Deployments añaden rolling updates, rollbacks y estrategias de despliegue declarativas.

---

## 📚 Estructura del Módulo

Este módulo está organizado en **8 secciones temáticas**:

| # | Sección | Duración | Contenido |
|---|---------|----------|-----------|
| **1** | ¿Qué es un Deployment? | 30 min | Definición, arquitectura, comparación vs ReplicaSet |
| **2** | Creación de Deployments | 35 min | Manifiestos YAML, anatomía, comandos kubectl |
| **3** | Rolling Updates | 45 min | Actualizaciones sin downtime, maxSurge, maxUnavailable |
| **4** | Rollback y Versiones | 40 min | Historial de revisiones, undo, rollback automático |
| **5** | Estrategias de Despliegue | 50 min | RollingUpdate vs Recreate, parámetros avanzados |
| **6** | Técnicas Avanzadas | 45 min | Blue-Green, Canary, pause/resume |
| **7** | Monitoreo y Troubleshooting | 35 min | Status, events, debugging common issues |
| **8** | Best Practices | 50 min | Producción-ready, security, anti-patterns |

**Total**: ~4.5 horas (teoría + práctica)

---

## 🗂️ Recursos de Aprendizaje

### **Archivos del Módulo**

```
modulo-07-deployments-rollouts/
├── README.md                          # ← Teoría completa (este archivo)
├── RESUMEN-MODULO.md                  # Guía de estudio y referencia rápida
├── ejemplos/                          # Manifiestos YAML de ejemplo
│   ├── 01-basico/
│   │   ├── 01-deployment-simple.yaml
│   │   ├── 02-deployment-production.yaml
│   │   └── 03-deployment-multi-container.yaml
│   ├── 02-rolling-updates/
│   │   ├── 01-rolling-update-demo.yaml
│   │   ├── 02-max-surge-unavailable.yaml
│   │   └── 03-progressive-rollout.yaml
│   ├── 03-strategies/
│   │   ├── 01-recreate-strategy.yaml
│   │   ├── 02-rollingupdate-strategy.yaml
│   │   └── 03-blue-green-deployment.yaml
│   ├── 04-canary/
│   │   ├── 01-canary-v1.yaml
│   │   ├── 02-canary-v2.yaml
│   │   └── 03-canary-service.yaml
│   └── 05-best-practices/
│       └── production-ready-deployment.yaml
└── laboratorios/                      # Prácticas guiadas
    ├── lab-01-crear-primer-deployment.md
    ├── lab-02-rolling-updates.md
    ├── lab-03-rollback-versiones.md
    ├── lab-04-estrategias-despliegue.md
    ├── lab-05-blue-green-deployment.md
    ├── lab-06-canary-deployment.md
    ├── lab-07-troubleshooting.md
    └── lab-08-production-ready.md
```

### **Metodología de Estudio**

Este módulo sigue la metodología **Teoría → Ejemplo → Práctica**:

1. **Teoría**: Lee la explicación conceptual en este README
2. **Ejemplo inline**: Observa ejemplos de código comentados
3. **Archivo de referencia**: Consulta manifiestos en `ejemplos/`
4. **Checkpoint**: Verifica tu comprensión
5. **Laboratorio**: Practica hands-on en `laboratorios/`

---

## 🚀 Guía de Estudio Recomendada

### **Fase 1: Fundamentos (Día 1 - 2 horas)**
- Leer Secciones 1-2
- Completar Labs 1-2
- **Objetivo**: Crear y gestionar Deployments básicos

### **Fase 2: Actualizaciones (Día 2 - 2 horas)**
- Leer Secciones 3-4
- Completar Labs 3-4
- **Objetivo**: Dominar rolling updates y rollbacks

### **Fase 3: Estrategias Avanzadas (Día 3 - 2.5 horas)**
- Leer Secciones 5-6
- Completar Labs 5-6
- **Objetivo**: Implementar Blue-Green y Canary

### **Fase 4: Producción (Día 4 - 2 horas)**
- Leer Secciones 7-8
- Completar Labs 7-8
- **Objetivo**: Production-ready deployments

### **Fase 5: Consolidación (Día 5 - 1 hora)**
- Repasar RESUMEN-MODULO.md
- Proyecto final: Deploy full-stack app
- **Objetivo**: Aplicar todo lo aprendido

---

## � 1. ¿Qué es un Deployment?

### **1.1 El Problema que Resuelven los Deployments**

Recordemos el **problema crítico de ReplicaSets** del Módulo 06:

```yaml
# ESCENARIO: Tienes un ReplicaSet con nginx:1.20
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
        image: nginx:1.20-alpine  # ← Versión 1.20
        ports:
        - containerPort: 80
```

**Paso 1**: Aplicar manifiesto
```bash
kubectl apply -f replicaset.yaml
# replicaset.apps/webapp-rs created

kubectl get pods
# NAME             READY   STATUS    IMAGE
# webapp-rs-abc    1/1     Running   nginx:1.20-alpine ✅
# webapp-rs-def    1/1     Running   nginx:1.20-alpine ✅
# webapp-rs-ghi    1/1     Running   nginx:1.20-alpine ✅
```

**Paso 2**: Actualizar imagen a nginx:1.21
```yaml
spec:
  template:
    spec:
      containers:
      - image: nginx:1.21-alpine  # ← CAMBIO DE VERSIÓN
```

**Paso 3**: Aplicar cambios
```bash
kubectl apply -f replicaset.yaml
# replicaset.apps/webapp-rs configured ✅

# ❌ PERO... Los Pods SIGUEN con versión vieja
kubectl get pods -o jsonpath='{.items[*].spec.containers[0].image}'
# nginx:1.20-alpine nginx:1.20-alpine nginx:1.20-alpine
# ❌ NO SE ACTUALIZARON
```

**¿Por qué?**
- ReplicaSet solo garantiza **número** de réplicas
- NO verifica ni actualiza **configuración** de Pods existentes
- Solo Pods **nuevos** usarían el template actualizado

**Workaround manual** (tedioso y peligroso):
```bash
# Eliminar Pods uno por uno manualmente
kubectl delete pod webapp-rs-abc  # ⚠️ DOWNTIME
# Esperar que se cree con nueva imagen...
kubectl delete pod webapp-rs-def  # ⚠️ MÁS DOWNTIME
kubectl delete pod webapp-rs-ghi  # ⚠️ AÚN MÁS DOWNTIME
```

**Problemas**:
- ❌ **Downtime** durante eliminación
- ❌ Manual y propenso a errores
- ❌ No escalable (100 Pods = 100 eliminaciones)
- ❌ Sin rollback si algo falla
- ❌ Sin historial de versiones

---

### **1.2 La Solución: Deployments**

```yaml
# MISMO ESCENARIO: Pero con Deployment
apiVersion: apps/v1
kind: Deployment  # ← Cambio de ReplicaSet a Deployment
metadata:
  name: webapp-deploy
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
        image: nginx:1.20-alpine  # ← Versión 1.20
        ports:
        - containerPort: 80
```

**Paso 1**: Aplicar Deployment
```bash
kubectl apply -f deployment.yaml
# deployment.apps/webapp-deploy created

kubectl get pods
# NAME                            READY   STATUS    IMAGE
# webapp-deploy-5d7f8c9b-abc      1/1     Running   nginx:1.20-alpine ✅
# webapp-deploy-5d7f8c9b-def      1/1     Running   nginx:1.20-alpine ✅
# webapp-deploy-5d7f8c9b-ghi      1/1     Running   nginx:1.20-alpine ✅
```

**Paso 2**: Actualizar imagen a nginx:1.21
```yaml
spec:
  template:
    spec:
      containers:
      - image: nginx:1.21-alpine  # ← CAMBIO DE VERSIÓN
```

**Paso 3**: Aplicar cambios
```bash
kubectl apply -f deployment.yaml
# deployment.apps/webapp-deploy configured ✅

# ✅ MAGIA: Rolling update automático
kubectl get pods --watch
# NAME                            READY   STATUS              AGE
# webapp-deploy-5d7f8c9b-abc      1/1     Running             2m
# webapp-deploy-5d7f8c9b-def      1/1     Running             2m
# webapp-deploy-5d7f8c9b-ghi      1/1     Running             2m
# webapp-deploy-7c8d9e0f-xyz      0/1     ContainerCreating   0s   ← NUEVO v1.21
# webapp-deploy-7c8d9e0f-xyz      1/1     Running             2s
# webapp-deploy-5d7f8c9b-abc      1/1     Terminating         2m   ← VIEJO eliminado
# webapp-deploy-7c8d9e0f-mno      0/1     ContainerCreating   0s   ← NUEVO v1.21
# webapp-deploy-7c8d9e0f-mno      1/1     Running             2s
# webapp-deploy-5d7f8c9b-def      1/1     Terminating         2m   ← VIEJO eliminado
# webapp-deploy-7c8d9e0f-pqr      0/1     ContainerCreating   0s   ← NUEVO v1.21
# webapp-deploy-7c8d9e0f-pqr      1/1     Running             2s
# webapp-deploy-5d7f8c9b-ghi      1/1     Terminating         2m   ← VIEJO eliminado
# ✅ ACTUALIZACIÓN COMPLETA SIN DOWNTIME

# Verificar versiones
kubectl get pods -o jsonpath='{.items[*].spec.containers[0].image}'
# nginx:1.21-alpine nginx:1.21-alpine nginx:1.21-alpine ✅
```

**Ventajas**:
- ✅ **Zero downtime**: Siempre hay Pods disponibles
- ✅ **Automático**: No intervención manual
- ✅ **Gradual**: Un Pod a la vez (configurable)
- ✅ **Rollback**: Si falla, vuelve atrás automáticamente
- ✅ **Historial**: Guarda versiones anteriores

---

### **1.3 Definición Formal**

Un **Deployment** es un **controlador de alto nivel** en Kubernetes que:

| Capacidad | Descripción | Beneficio |
|-----------|-------------|-----------|
| **Gestión de ReplicaSets** | Crea y gestiona ReplicaSets automáticamente | Abstracción sobre complejidad |
| **Rolling Updates** | Actualiza Pods gradualmente sin downtime | Alta disponibilidad |
| **Rollback** | Vuelve a versiones anteriores si algo falla | Recuperación rápida |
| **Historial de revisiones** | Mantiene hasta 10 versiones por defecto | Auditoría y troubleshooting |
| **Escalado declarativo** | Define réplicas deseadas, Kubernetes lo cumple | Simplicidad operacional |
| **Pause/Resume** | Pausa updates para hacer cambios batch | Control fino |
| **Estrategias configurables** | RollingUpdate, Recreate | Flexibilidad según caso de uso |

---

### **1.4 Deployment vs ReplicaSet: Comparación Completa**

```
┌──────────────────────────────────────────────────────────────────┐
│                 REPLICASET vs DEPLOYMENT                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  🟡 REPLICASET (Gestión de Réplicas)                             │
│  ┌────────────────────────────────────────────────────┐          │
│  │                                                    │          │
│  │  ┌─────┐  ┌─────┐  ┌─────┐                        │          │
│  │  │Pod 1│  │Pod 2│  │Pod 3│  ← Mantiene N réplicas │          │
│  │  │v1.20│  │v1.20│  │v1.20│                        │          │
│  │  └─────┘  └─────┘  └─────┘                        │          │
│  │                                                    │          │
│  │  Actualizar imagen a v1.21:                        │          │
│  │  ❌ Pods NO se actualizan automáticamente          │          │
│  │  ❌ Requiere eliminación manual                    │          │
│  │  ❌ Sin rollback                                   │          │
│  │  ❌ Sin historial                                  │          │
│  │                                                    │          │
│  └────────────────────────────────────────────────────┘          │
│                                                                  │
│  🟢 DEPLOYMENT (Gestión de Versiones)                            │
│  ┌────────────────────────────────────────────────────┐          │
│  │                                                    │          │
│  │  ReplicaSet v1 (histórico)   ReplicaSet v2 (activo)│         │
│  │  replicas: 0                 replicas: 3          │          │
│  │  ┌─────┐                      ┌─────┐  ┌─────┐  ┌─────┐│     │
│  │  │     │  (ningún Pod)        │Pod 4│  │Pod 5│  │Pod 6││     │
│  │  │v1.20│                      │v1.21│  │v1.21│  │v1.21││     │
│  │  └─────┘                      └─────┘  └─────┘  └─────┘│     │
│  │                                                    │          │
│  │  Actualizar imagen a v1.21:                        │          │
│  │  ✅ Crea nuevo ReplicaSet (v2)                     │          │
│  │  ✅ Escala v2 UP, v1 DOWN gradualmente             │          │
│  │  ✅ Zero downtime                                  │          │
│  │  ✅ Rollback disponible (undo)                     │          │
│  │  ✅ Historial de versiones                         │          │
│  │                                                    │          │
│  └────────────────────────────────────────────────────┘          │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Tabla Comparativa**:

| Característica | ReplicaSet | Deployment |
|----------------|------------|------------|
| **Auto-recuperación** | ✅ Sí | ✅ Sí (vía ReplicaSets) |
| **Escalado horizontal** | ✅ Sí | ✅ Sí (mejor integrado) |
| **Actualizar configuración** | ❌ Manual | ✅ Automático (rolling update) |
| **Rolling updates** | ❌ No | ✅ Sí (configurable) |
| **Rollback** | ❌ No | ✅ Sí (a cualquier revisión) |
| **Historial de versiones** | ❌ No | ✅ Sí (hasta 10 por defecto) |
| **Estrategias de deploy** | ❌ No | ✅ RollingUpdate, Recreate |
| **Pause/Resume** | ❌ No | ✅ Sí (para cambios batch) |
| **Change causes** | ❌ No | ✅ Sí (auditoría) |
| **Uso recomendado** | 🟡 Aprendizaje | 🟢 **PRODUCCIÓN** |

---

### **1.5 Cuándo Usar Deployment vs Otros Controladores**

| Tipo de Aplicación | Controlador Recomendado | Por qué |
|--------------------|------------------------|---------|
| **Web app stateless** (frontend, API REST) | ✅ **Deployment** | No guarda estado, necesita rolling updates |
| **Background workers** (procesamiento async) | ✅ **Deployment** | Stateless, necesita escalado |
| **Bases de datos** (MySQL, PostgreSQL) | ❌ StatefulSet | Necesita identidad persistente y orden |
| **Cache distribuido** (Redis cluster) | ❌ StatefulSet | Requiere networking estable |
| **Jobs puntuales** (migrations, backups) | ❌ Job/CronJob | Tarea finita, no long-running |
| **Daemonset** (log collector, monitoring) | ❌ DaemonSet | Un Pod por nodo |

**Regla de oro**:

```
┌────────────────────────────────────────────────────────┐
│  ¿Tu aplicación es STATELESS (sin estado)?            │
│  ¿Necesitas actualizaciones frecuentes?               │
│  ¿Requieres alta disponibilidad?                      │
│                                                        │
│  SI a las 3 preguntas → ✅ USA DEPLOYMENT              │
│                                                        │
│  ¿Tu aplicación necesita persistencia de identidad?   │
│  ¿Requiere orden en inicio/apagado?                   │
│                                                        │
│  SI a alguna → ❌ USA STATEFULSET                      │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

### **1.6 Arquitectura Interna de un Deployment**

```
┌───────────────────────────────────────────────────────────────────┐
│                    JERARQUÍA DE OBJETOS                           │
└───────────────────────────────────────────────────────────────────┘

                     ┌─────────────────────────┐
                     │      DEPLOYMENT         │
                     │   (Controlador Alto)    │
                     │                         │
                     │  spec:                  │
                     │    replicas: 3          │
                     │    strategy:            │
                     │      type: RollingUpdate│
                     │      rollingUpdate:     │
                     │        maxSurge: 1      │
                     │        maxUnavailable: 0│
                     └────────────┬────────────┘
                                  │
                      ┌───────────┴───────────┐
                      │   Gestiona            │
                      ▼                       ▼
            ┌──────────────────┐    ┌──────────────────┐
            │  ReplicaSet v1   │    │  ReplicaSet v2   │
            │  (histórico)     │    │  (activo)        │
            │                  │    │                  │
            │  replicas: 0     │    │  replicas: 3     │
            │  image: v1.20    │    │  image: v1.21    │
            │  revision: 1     │    │  revision: 2     │
            └──────────────────┘    └────────┬─────────┘
                                              │
                                   ┌──────────┼──────────┐
                                   │          │          │
                                   ▼          ▼          ▼
                            ┌────────┐  ┌────────┐  ┌────────┐
                            │ Pod 1  │  │ Pod 2  │  │ Pod 3  │
                            │ v1.21  │  │ v1.21  │  │ v1.21  │
                            └────────┘  └────────┘  └────────┘

Flujo de Actualización:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Usuario actualiza spec.template (cambia imagen)
2. Deployment detecta cambio → Crea nuevo ReplicaSet (v2)
3. Deployment Controller:
   - Escala ReplicaSet v2 de 0 → 1 (crea 1 Pod nuevo)
   - Espera que Pod esté Ready
   - Escala ReplicaSet v1 de 3 → 2 (elimina 1 Pod viejo)
   - Repite hasta que v2=3 y v1=0
4. ReplicaSet v1 queda con replicas: 0 (historial)
5. ReplicaSet v2 tiene replicas: 3 (activo)
```

**Owner References (Propiedad)**:

```yaml
# Deployment
metadata:
  name: webapp-deploy
  uid: abc-123-def

---
# ReplicaSet (hijo del Deployment)
metadata:
  name: webapp-deploy-7c8d9e0f
  ownerReferences:
  - apiVersion: apps/v1
    kind: Deployment
    name: webapp-deploy
    uid: abc-123-def  # ← Mismo UID del padre

---
# Pod (hijo del ReplicaSet)
metadata:
  name: webapp-deploy-7c8d9e0f-xyz12
  ownerReferences:
  - apiVersion: apps/v1
    kind: ReplicaSet
    name: webapp-deploy-7c8d9e0f
```

**Cadena de propiedad**:
```
Deployment → ReplicaSet → Pod
 (abuelo)     (padre)    (hijo)
```

**Implicaciones**:
- Si eliminas Deployment → se eliminan ReplicaSets y Pods (cascade delete)
- Si eliminas ReplicaSet → se eliminan Pods
- Si eliminas Pod → ReplicaSet lo recrea (self-healing)

---

### **✅ Checkpoint 01: Fundamentos de Deployments**

Antes de continuar, asegúrate de poder:

- [ ] Explicar el problema que tienen los ReplicaSets con updates
- [ ] Describir cómo Deployments resuelven ese problema
- [ ] Mencionar 5 ventajas de Deployments sobre ReplicaSets
- [ ] Identificar cuándo usar Deployment vs StatefulSet
- [ ] Dibujar la jerarquía: Deployment → ReplicaSet → Pod
- [ ] Explicar qué es un rolling update

📁 **Laboratorio**: [`laboratorios/lab-01-crear-primer-deployment.md`](./laboratorios/lab-01-crear-primer-deployment.md)
- Duración: 30 minutos
- Crea tu primer Deployment
- Observa rolling update en acción
- Compara comportamiento vs ReplicaSet

---

## 🏗️ 2. Creación y Gestión de Deployments

### **3.1 Jerarquía de Objetos**

```
┌──────────────────────────────────────────────────────────┐
│                 ARQUITECTURA DEPLOYMENT                  │
└──────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │   DEPLOYMENT    │
                    │  replicas: 3    │
                    │  strategy:      │
                    │  RollingUpdate  │
                    └────────┬────────┘
                             │ gestiona
                    ┌────────┴────────┐
                    │                 │
                    ▼                 ▼
           ┌────────────────┐  ┌────────────────┐
           │ ReplicaSet v1  │  │ ReplicaSet v2  │
           │  replicas: 0   │  │  replicas: 3   │ ← ACTIVO
           │  (histórico)   │  │  (actual)      │
           └────────┬───────┘  └────────┬───────┘
                    │                   │
                    │          ┌────────┼────────┐
                    │          │        │        │
                    ▼          ▼        ▼        ▼
               (ningún Pod) ┌────┐  ┌────┐  ┌────┐
                           │Pod1│  │Pod2│  │Pod3│
                           │v2  │  │v2  │  │v2  │
                           └────┘  └────┘  └────┘

Flujo:
1. Usuario actualiza Deployment (nueva imagen)
2. Deployment crea nuevo ReplicaSet (v2)
3. Deployment escala v2 UP y v1 DOWN gradualmente
4. ReplicaSet v1 queda con 0 réplicas (historial)
5. ReplicaSet v2 tiene todas las réplicas (activo)
```

### **3.2 Componentes Clave**

**1. Deployment (Controller)**
- Gestiona todo el proceso de actualización
- Decide cuándo crear/eliminar ReplicaSets
- Controla el ritmo del rolling update

**2. ReplicaSets (Versiones)**
- Deployment crea un ReplicaSet por cada versión
- ReplicaSet activo: `replicas: N`
- ReplicaSets históricos: `replicas: 0`

**3. Pods (Workload)**
- Gestionados por ReplicaSet activo
- Actualizados gradualmente durante rolling update

### **3.3 Owner References**

```yaml
# Deployment
metadata:
  name: my-deployment
  uid: abc-123-def

---
# ReplicaSet (creado por Deployment)
metadata:
  name: my-deployment-5d7f8c9b
  ownerReferences:
  - apiVersion: apps/v1

### **2.1 Anatomía de un Manifiesto Deployment**

```yaml
apiVersion: apps/v1          # ← API version (siempre apps/v1)
kind: Deployment             # ← Tipo de recurso

metadata:                    # ← Metadatos del Deployment
  name: webapp-deploy
  namespace: default         # ← Namespace (default si se omite)
  labels:
    app: webapp
    tier: frontend
    environment: production
  annotations:
    kubernetes.io/change-cause: "Initial deployment v1.0"

spec:                        # ← Especificación del Deployment
  replicas: 3                # ← Número de réplicas deseadas
  
  selector:                  # ← Selector de Pods (DEBE coincidir con template.labels)
    matchLabels:
      app: webapp
      tier: frontend
  
  strategy:                  # ← Estrategia de actualización
    type: RollingUpdate      # ← RollingUpdate o Recreate
    rollingUpdate:
      maxSurge: 1            # ← Máximo de Pods extras durante update
      maxUnavailable: 0      # ← Máximo de Pods no disponibles
  
  revisionHistoryLimit: 10   # ← Número de ReplicaSets históricos a mantener
  progressDeadlineSeconds: 600  # ← Timeout para updates (default: 600s)
  
  template:                  # ← Template del Pod (IDENTICAL al spec de Pod)
    metadata:
      labels:
        app: webapp          # ← DEBE coincidir con selector
        tier: frontend
        version: "v1.0"
    
    spec:                    # ← Especificación del Pod
      containers:
      - name: nginx
        image: nginx:alpine
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
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
```

**4 Secciones Principales**:

| Sección | Propósito | Obligatorio |
|---------|-----------|-------------|
| **apiVersion** | Versión de API de Kubernetes | ✅ Sí (`apps/v1`) |
| **kind** | Tipo de recurso (`Deployment`) | ✅ Sí |
| **metadata** | Nombre, labels, annotations | ✅ Sí |
| **spec** | Configuración: replicas, strategy, template | ✅ Sí |

---

### **2.2 Campos Obligatorios vs Opcionales**

| Campo | Obligatorio | Default | Descripción |
|-------|-------------|---------|-------------|
| `spec.replicas` | ❌ No | `1` | Número de réplicas |
| `spec.selector` | ✅ Sí | - | Selector de Pods (DEBE coincidir) |
| `spec.template` | ✅ Sí | - | Template del Pod |
| `spec.template.metadata.labels` | ✅ Sí | - | Labels del Pod |
| `spec.strategy.type` | ❌ No | `RollingUpdate` | Estrategia de actualización |
| `spec.strategy.rollingUpdate.maxSurge` | ❌ No | `25%` | Pods extras durante update |
| `spec.strategy.rollingUpdate.maxUnavailable` | ❌ No | `25%` | Pods no disponibles |
| `spec.revisionHistoryLimit` | ❌ No | `10` | Historial de ReplicaSets |
| `spec.progressDeadlineSeconds` | ❌ No | `600` | Timeout para updates |

---

### **2.3 Crear Tu Primer Deployment**

#### **Ejemplo 1: Deployment Simple**

📄 **Archivo**: [`ejemplos/01-basico/01-deployment-simple.yaml`](./ejemplos/01-basico/01-deployment-simple.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-simple
  labels:
    app: webapp
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
        ports:
        - containerPort: 80
```

**Aplicar**:

```bash
# Crear Deployment
kubectl apply -f ejemplos/01-basico/01-deployment-simple.yaml
# deployment.apps/webapp-simple created

# Ver Deployment
kubectl get deployments
# NAME            READY   UP-TO-DATE   AVAILABLE   AGE
# webapp-simple   3/3     3            3           10s

# Ver ReplicaSets creados por el Deployment
kubectl get rs
# NAME                      DESIRED   CURRENT   READY   AGE
# webapp-simple-5d7f8c9b    3         3         3       15s

# Ver Pods
kubectl get pods
# NAME                            READY   STATUS    RESTARTS   AGE
# webapp-simple-5d7f8c9b-abc12    1/1     Running   0          20s
# webapp-simple-5d7f8c9b-def34    1/1     Running   0          20s
# webapp-simple-5d7f8c9b-ghi56    1/1     Running   0          20s

# Ver detalles del Deployment
kubectl describe deployment webapp-simple
# Name:                   webapp-simple
# Namespace:              default
# Selector:               app=webapp
# Replicas:               3 desired | 3 updated | 3 total | 3 available
# StrategyType:           RollingUpdate
# RollingUpdateStrategy:  25% max unavailable, 25% max surge
# Pod Template:
#   Labels:  app=webapp
#   Containers:
#    nginx:
#     Image:        nginx:alpine
#     Port:         80/TCP
# Conditions:
#   Type           Status  Reason
#   ----           ------  ------
#   Available      True    MinimumReplicasAvailable
#   Progressing    True    NewReplicaSetAvailable
# Events:
#   Type    Reason             Age   Message
#   ----    ------             ----  -------
#   Normal  ScalingReplicaSet  30s   Scaled up replica set webapp-simple-5d7f8c9b to 3
```

---

#### **Ejemplo 2: Deployment Production-Ready**

📄 **Archivo**: [`ejemplos/01-basico/02-deployment-production.yaml`](./ejemplos/01-basico/02-deployment-production.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-prod
  labels:
    app: webapp
    tier: frontend
    environment: production
    version: "v1.0"
  annotations:
    kubernetes.io/change-cause: "Initial production deployment"
spec:
  replicas: 5
  
  selector:
    matchLabels:
      app: webapp
      tier: frontend
      environment: production
  
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2           # ← Permite 2 Pods extras (total: 7 durante update)
      maxUnavailable: 0     # ← Siempre mantiene mínimo 5 disponibles
  
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600
  
  template:
    metadata:
      labels:
        app: webapp
        tier: frontend
        environment: production
        version: "v1.0"
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
        
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
        
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
      
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

**Características production-ready**:
- ✅ **5 réplicas** para alta disponibilidad
- ✅ **maxUnavailable: 0** → Zero downtime garantizado
- ✅ **Resources** definidos (requests & limits)
- ✅ **Health checks** (liveness & readiness)
- ✅ **Anti-affinity** para distribuir Pods en nodos
- ✅ **Change cause** para auditoría
- ✅ **Environment variables** con fieldRef

---

### **2.4 Comandos de Gestión de Deployments**

#### **Creación**

```bash
# Crear desde archivo YAML
kubectl apply -f deployment.yaml

# Crear imperativamente (no recomendado para producción)
kubectl create deployment webapp --image=nginx:alpine --replicas=3

# Crear con comando completo
kubectl create deployment webapp \
  --image=nginx:alpine \
  --replicas=5 \
  --port=80
```

#### **Lectura (Get)**

```bash
# Listar Deployments
kubectl get deployments
kubectl get deploy              # Alias
kubectl get deploy -o wide      # Más info (imágenes, selector)
kubectl get deploy --show-labels

# Listar en todos los namespaces
kubectl get deploy -A

# Ver como YAML/JSON
kubectl get deploy webapp -o yaml
kubectl get deploy webapp -o json

# Filtrar por labels
kubectl get deploy -l app=webapp
kubectl get deploy -l tier=frontend,environment=production
```

#### **Inspección (Describe)**

```bash
# Ver detalles completos
kubectl describe deployment webapp

# Ver sección específica
kubectl describe deploy webapp | grep -A 10 "Pod Template"
kubectl describe deploy webapp | grep -A 5 "Events"

# Ver status
kubectl get deploy webapp -o jsonpath='{.status}'

# Ver condiciones
kubectl get deploy webapp -o jsonpath='{.status.conditions[*].type}'
# Available Progressing
```

#### **Actualización (Edit)**

```bash
# Editar interactivamente (abre editor)
kubectl edit deployment webapp

# Actualizar imagen imperativamente
kubectl set image deployment/webapp nginx=nginx:1.21-alpine

# Actualizar múltiples contenedores
kubectl set image deployment/webapp \
  nginx=nginx:1.21-alpine \
  sidecar=sidecar:v2.0

# Actualizar resources
kubectl set resources deployment webapp \
  -c=nginx \
  --requests=cpu=200m,memory=256Mi \
  --limits=cpu=500m,memory=512Mi

# Actualizar con patch
kubectl patch deployment webapp -p '{"spec":{"replicas":5}}'
```

#### **Escalado**

```bash
# Escalar imperativamente
kubectl scale deployment webapp --replicas=10

# Escalar declarativamente (editar YAML y aplicar)
kubectl apply -f deployment.yaml

# Autoscaling (HPA - tema avanzado)
kubectl autoscale deployment webapp --min=3 --max=10 --cpu-percent=80
```

#### **Eliminación**

```bash
# Eliminar Deployment (y sus ReplicaSets y Pods)
kubectl delete deployment webapp
kubectl delete -f deployment.yaml

# Eliminar múltiples
kubectl delete deployment webapp1 webapp2

# Eliminar todos del namespace
kubectl delete deployments --all

# Eliminar con grace period
kubectl delete deployment webapp --grace-period=30

# Eliminar sin esperar (force)
kubectl delete deployment webapp --force --grace-period=0
```

---

### **2.5 Inspeccionar ReplicaSets Gestionados**

```bash
# Listar ReplicaSets
kubectl get rs

# Ver ReplicaSets de un Deployment específico
kubectl get rs -l app=webapp

# Ver ReplicaSets con owner references
kubectl get rs -o yaml | grep -A 5 ownerReferences

# Ver historial de ReplicaSets (versiones)
kubectl get rs --sort-by=.metadata.creationTimestamp

# Ver ReplicaSet activo vs históricos
kubectl get rs
# NAME                  DESIRED   CURRENT   READY
# webapp-5d7f8c9b       0         0         0       ← Histórico (v1)
# webapp-7c8d9e0f       3         3         3       ← Activo (v2)
```

---

### **2.6 Ver Pods Gestionados por un Deployment**

```bash
# Listar Pods del Deployment
kubectl get pods -l app=webapp

# Ver Pods con más info
kubectl get pods -l app=webapp -o wide
# NAME                      NODE        IMAGE
# webapp-7c8d9e0f-abc       minikube    nginx:alpine

# Ver Pods con owner references
kubectl get pods -l app=webapp -o yaml | grep -A 10 ownerReferences

# Ver qué ReplicaSet gestiona cada Pod
kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.ownerReferences[0].name}{"\n"}{end}'
# webapp-7c8d9e0f-abc12    webapp-7c8d9e0f
# webapp-7c8d9e0f-def34    webapp-7c8d9e0f

# Observar Pods en tiempo real
kubectl get pods -l app=webapp --watch
```

---

### **2.7 Ver Estado y Condiciones**

```bash
# Ver status del Deployment
kubectl get deployment webapp -o jsonpath='{.status}' | jq

# Ver condiciones
kubectl get deployment webapp -o jsonpath='{.status.conditions[*]}' | jq

# Tipos de condiciones:
# - Available:    Pods disponibles >= replicas
# - Progressing:  Update en progreso
# - ReplicaFailure: Fallo al crear Pods

# Ver si Deployment está Available
kubectl get deploy webapp -o jsonpath='{.status.conditions[?(@.type=="Available")].status}'
# True

# Ver réplicas
kubectl get deploy webapp -o jsonpath='{.status.replicas}'           # Total
kubectl get deploy webapp -o jsonpath='{.status.readyReplicas}'      # Listos
kubectl get deploy webapp -o jsonpath='{.status.availableReplicas}'  # Disponibles
kubectl get deploy webapp -o jsonpath='{.status.updatedReplicas}'    # Actualizados
```

---

### **2.8 Ver Eventos**

```bash
# Ver eventos del Deployment
kubectl get events --field-selector involvedObject.kind=Deployment,involvedObject.name=webapp

# Ver eventos de creación de ReplicaSets
kubectl get events --field-selector involvedObject.kind=ReplicaSet,reason=SuccessfulCreate

# Ver eventos recientes
kubectl get events --sort-by=.metadata.creationTimestamp

# Ver eventos con watch
kubectl get events -w
```

---

### **✅ Checkpoint 02: Creación y Gestión**

Antes de continuar, asegúrate de poder:

- [ ] Crear un Deployment desde un manifiesto YAML
- [ ] Identificar las 4 secciones principales del manifiesto
- [ ] Explicar la diferencia entre `spec.replicas` y `spec.template`
- [ ] Listar Deployments, ReplicaSets y Pods relacionados
- [ ] Inspeccionar el estado de un Deployment con `describe`
- [ ] Ver eventos de creación y escalado
- [ ] Escalar un Deployment imperativamente
- [ ] Explicar qué es `spec.selector` y por qué debe coincidir con `template.labels`

📁 **Laboratorio**: [`laboratorios/lab-02-gestion-deployments.md`](./laboratorios/lab-02-gestion-deployments.md)
- Duración: 35 minutos
- Crea Deployments simple y production-ready
- Practica comandos de gestión (get, describe, scale)
- Inspecciona ReplicaSets y Pods gestionados
- Observa owner references

---

## 🔄 3. Rolling Updates: Actualizaciones Sin Downtime

### **3.1 ¿Qué es un Rolling Update?**

**Rolling Update** = Actualización **gradual** de Pods, reemplazando versión vieja por nueva **sin downtime**.

```
┌──────────────────────────────────────────────────────────────┐
│              ROLLING UPDATE FLOW                             │
└──────────────────────────────────────────────────────────────┘

ESTADO INICIAL (Versión v1.20):
┌────────────────────────────────────────────────────────┐
│ ReplicaSet v1 (replicas: 3)                            │
│ ┌─────────┐  ┌─────────┐  ┌─────────┐                │
│ │ Pod v1  │  │ Pod v1  │  │ Pod v1  │                │
│ │ READY   │  │ READY   │  │ READY   │                │
│ └─────────┘  └─────────┘  └─────────┘                │
└────────────────────────────────────────────────────────┘

Usuario actualiza imagen a v1.21 → kubectl apply

PASO 1: Crear nuevo ReplicaSet
┌────────────────────────────────────────────────────────┐
│ ReplicaSet v1 (replicas: 3)   ReplicaSet v2 (replicas: 0)│
│ ┌─────────┐  ┌─────────┐  ┌─────────┐                │
│ │ Pod v1  │  │ Pod v1  │  │ Pod v1  │  (ningún Pod)  │
│ │ READY   │  │ READY   │  │ READY   │                │
│ └─────────┘  └─────────┘  └─────────┘                │
└────────────────────────────────────────────────────────┘

PASO 2: Escalar v2 UP (1 Pod), v1 DOWN (1 Pod)
┌────────────────────────────────────────────────────────┐
│ ReplicaSet v1 (replicas: 2)   ReplicaSet v2 (replicas: 1)│
│ ┌─────────┐  ┌─────────┐      ┌─────────┐            │
│ │ Pod v1  │  │ Pod v1  │      │ Pod v2  │            │
│ │ READY   │  │ READY   │      │ READY   │            │
│ └─────────┘  └─────────┘      └─────────┘            │
│                               ↑ NUEVO                  │
└────────────────────────────────────────────────────────┘

PASO 3: Escalar v2 UP (1 Pod), v1 DOWN (1 Pod)
┌────────────────────────────────────────────────────────┐
│ ReplicaSet v1 (replicas: 1)   ReplicaSet v2 (replicas: 2)│
│ ┌─────────┐                  ┌─────────┐  ┌─────────┐│
│ │ Pod v1  │                  │ Pod v2  │  │ Pod v2  ││
│ │ READY   │                  │ READY   │  │ READY   ││
│ └─────────┘                  └─────────┘  └─────────┘│
└────────────────────────────────────────────────────────┘

PASO 4: Escalar v2 UP (1 Pod), v1 DOWN (0 Pods)
┌────────────────────────────────────────────────────────┐
│ ReplicaSet v1 (replicas: 0)   ReplicaSet v2 (replicas: 3)│
│ (ningún Pod)                 ┌─────────┐  ┌─────────┐  ┌─────────┐│
│                              │ Pod v2  │  │ Pod v2  │  │ Pod v2  ││
│                              │ READY   │  │ READY   │  │ READY   ││
│                              └─────────┘  └─────────┘  └─────────┘│
└────────────────────────────────────────────────────────┘
                    ✅ UPDATE COMPLETADO
```

**Ventajas**:
- ✅ **Zero downtime**: Siempre hay Pods disponibles
- ✅ **Gradual**: Detecta problemas antes de afectar todos los Pods
- ✅ **Automático**: Kubernetes lo gestiona
- ✅ **Rollback automático**: Si falla, vuelve atrás

---

### **3.2 Triggers de Rolling Update**

Un Rolling Update se **activa automáticamente** cuando cambias:

| Campo modificado | Activa Rolling Update | Ejemplo |
|------------------|----------------------|---------|
| `spec.template.spec.containers[].image` | ✅ Sí | Cambiar versión de imagen |
| `spec.template.metadata.labels` | ✅ Sí | Agregar/modificar labels del Pod |
| `spec.template.spec.containers[].env` | ✅ Sí | Cambiar variables de entorno |
| `spec.template.spec.containers[].resources` | ✅ Sí | Cambiar requests/limits |
| `spec.template.spec.containers[].ports` | ✅ Sí | Cambiar puertos |
| `spec.template.spec.volumes` | ✅ Sí | Cambiar volumes |
| `spec.replicas` | ❌ No | Solo escala (sin recrear Pods) |
| `spec.strategy` | ❌ No | Afecta próximo rolling update |
| `metadata.labels` | ❌ No | Labels del Deployment, no del Pod |

**Regla**: Rolling Update se activa si cambias **`spec.template`** (el blueprint del Pod).

---

### **3.3 Demostración Práctica de Rolling Update**

📄 **Archivo**: [`ejemplos/02-rolling-updates/01-rolling-update-demo.yaml`](./ejemplos/02-rolling-updates/01-rolling-update-demo.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-demo
  annotations:
    kubernetes.io/change-cause: "Deployment inicial con nginx:1.20"
spec:
  replicas: 5
  selector:
    matchLabels:
      app: rolling-demo
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: rolling-demo
        version: "v1"
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine  # ← Versión inicial
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Paso 1**: Aplicar versión inicial
```bash
kubectl apply -f ejemplos/02-rolling-updates/01-rolling-update-demo.yaml

# Ver Pods creados
kubectl get pods -l app=rolling-demo
# NAME                          READY   STATUS    AGE
# rolling-demo-5d7f8c9b-abc     1/1     Running   10s
# rolling-demo-5d7f8c9b-def     1/1     Running   10s
# rolling-demo-5d7f8c9b-ghi     1/1     Running   10s
# rolling-demo-5d7f8c9b-jkl     1/1     Running   10s
# rolling-demo-5d7f8c9b-mno     1/1     Running   10s

# Ver imagen actual
kubectl get pods -l app=rolling-demo -o jsonpath='{.items[0].spec.containers[0].image}'
# nginx:1.20-alpine ✅
```

**Paso 2**: Actualizar imagen a nginx:1.21

```yaml
# Modificar en el archivo
spec:
  template:
    metadata:
      labels:
        version: "v2"  # ← Cambiar versión
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine  # ← NUEVA VERSIÓN
```

```bash
# Actualizar annotation change-cause
kubectl annotate deployment rolling-demo \
  kubernetes.io/change-cause="Actualizar a nginx:1.21" \
  --overwrite

# Aplicar cambios
kubectl apply -f ejemplos/02-rolling-updates/01-rolling-update-demo.yaml
# deployment.apps/rolling-demo configured
```

**Paso 3**: Observar Rolling Update en tiempo real

```bash
# Terminal 1: Observar Pods
kubectl get pods -l app=rolling-demo --watch

# Terminal 2: Observar ReplicaSets
kubectl get rs -l app=rolling-demo --watch

# Terminal 3: Ver progreso del rollout
kubectl rollout status deployment/rolling-demo
# Waiting for deployment "rolling-demo" rollout to finish: 1 out of 5 new replicas have been updated...
# Waiting for deployment "rolling-demo" rollout to finish: 2 out of 5 new replicas have been updated...
# Waiting for deployment "rolling-demo" rollout to finish: 3 out of 5 new replicas have been updated...
# Waiting for deployment "rolling-demo" rollout to finish: 4 out of 5 new replicas have been updated...
# Waiting for deployment "rolling-demo" rollout to finish: 1 old replicas are pending termination...
# deployment "rolling-demo" successfully rolled out ✅
```

**Salida esperada en Terminal 1**:

```
NAME                          READY   STATUS              AGE
rolling-demo-5d7f8c9b-abc     1/1     Running             2m
rolling-demo-5d7f8c9b-def     1/1     Running             2m
rolling-demo-5d7f8c9b-ghi     1/1     Running             2m
rolling-demo-5d7f8c9b-jkl     1/1     Running             2m
rolling-demo-5d7f8c9b-mno     1/1     Running             2m
rolling-demo-7c8d9e0f-xyz     0/1     ContainerCreating   0s   ← NUEVO v1.21
rolling-demo-7c8d9e0f-xyz     1/1     Running             3s
rolling-demo-5d7f8c9b-abc     1/1     Terminating         2m   ← VIEJO eliminado
rolling-demo-7c8d9e0f-pqr     0/1     ContainerCreating   0s   ← NUEVO v1.21
rolling-demo-7c8d9e0f-pqr     1/1     Running             3s
rolling-demo-5d7f8c9b-def     1/1     Terminating         2m
rolling-demo-7c8d9e0f-rst     0/1     ContainerCreating   0s
rolling-demo-7c8d9e0f-rst     1/1     Running             3s
rolling-demo-5d7f8c9b-ghi     1/1     Terminating         2m
rolling-demo-7c8d9e0f-uvw     0/1     ContainerCreating   0s
rolling-demo-7c8d9e0f-uvw     1/1     Running             3s
rolling-demo-5d7f8c9b-jkl     1/1     Terminating         2m
rolling-demo-7c8d9e0f-xyz2    0/1     ContainerCreating   0s
rolling-demo-7c8d9e0f-xyz2    1/1     Running             3s
rolling-demo-5d7f8c9b-mno     1/1     Terminating         2m
# ✅ TODOS LOS PODS ACTUALIZADOS
```

**Paso 4**: Verificar actualización completa

```bash
# Ver Pods con nueva imagen
kubectl get pods -l app=rolling-demo -o jsonpath='{.items[*].spec.containers[0].image}'
# nginx:1.21-alpine nginx:1.21-alpine nginx:1.21-alpine nginx:1.21-alpine nginx:1.21-alpine ✅

# Ver ReplicaSets
kubectl get rs -l app=rolling-demo
# NAME                    DESIRED   CURRENT   READY   AGE
# rolling-demo-5d7f8c9b   0         0         0       5m   ← Histórico (v1.20)
# rolling-demo-7c8d9e0f   5         5         5       2m   ← Activo (v1.21)
```

---

### **3.4 Parámetros de Rolling Update: maxSurge y maxUnavailable**

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1            # ← Pods EXTRAS permitidos
      maxUnavailable: 0      # ← Pods NO DISPONIBLES permitidos
```

#### **maxSurge**

**Definición**: Número **máximo de Pods extras** que pueden existir **sobre** `spec.replicas` durante el rolling update.

```
replicas: 5
maxSurge: 2

Durante update:
- Máximo permitido: 5 + 2 = 7 Pods
- Crea 2 nuevos antes de eliminar viejos
```

**Valores**:
- **Número entero**: `maxSurge: 2` → 2 Pods extras
- **Porcentaje**: `maxSurge: 25%` → 25% de replicas (redondeado arriba)
- **Default**: `25%`

**Ejemplo**:
```yaml
spec:
  replicas: 10
  strategy:
    rollingUpdate:
      maxSurge: 3  # ← Permite hasta 13 Pods durante update (10 + 3)
```

#### **maxUnavailable**

**Definición**: Número **máximo de Pods no disponibles** (Terminating o Not Ready) durante el rolling update.

```
replicas: 5
maxUnavailable: 1

Durante update:
- Mínimo disponible: 5 - 1 = 4 Pods
- Puede tener 1 Pod no disponible temporalmente
```

**Valores**:
- **Número entero**: `maxUnavailable: 1` → 1 Pod no disponible
- **Porcentaje**: `maxUnavailable: 25%` → 25% de replicas (redondeado abajo)
- **Default**: `25%`
- **⚠️ Importante**: `maxUnavailable: 0` → **Zero downtime** garantizado

**Ejemplo**:
```yaml
spec:
  replicas: 10
  strategy:
    rollingUpdate:
      maxUnavailable: 0  # ← SIEMPRE 10 Pods disponibles (zero downtime)
      maxSurge: 1        # ← Crea 1 nuevo antes de eliminar viejo
```

---

### **3.5 Escenarios de Configuración**

#### **Escenario 1: Zero Downtime (Producción)**

```yaml
spec:
  replicas: 10
  strategy:
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0  # ← Zero downtime
```

**Comportamiento**:
- Siempre 10 Pods disponibles
- Crea 2 nuevos (total: 12)
- Espera que estén Ready
- Elimina 2 viejos (vuelve a 10)
- Repite hasta completar

**Uso**: Aplicaciones críticas en producción

---

#### **Escenario 2: Update Rápido (Dev/Staging)**

```yaml
spec:
  replicas: 10
  strategy:
    rollingUpdate:
      maxSurge: 5
      maxUnavailable: 5
```

**Comportamiento**:
- Crea 5 nuevos (total: 15)
- Elimina 5 viejos simultáneamente
- Update más rápido (menos iteraciones)
- ⚠️ Puede tener downtime momentáneo

**Uso**: Ambientes no críticos, prioridad en velocidad

---

#### **Escenario 3: Conservar Recursos**

```yaml
spec:
  replicas: 10
  strategy:
    rollingUpdate:
      maxSurge: 0        # ← Sin Pods extras
      maxUnavailable: 1
```

**Comportamiento**:
- Elimina 1 viejo primero (quedan 9)
- Crea 1 nuevo (vuelve a 10)
- Repite Pod por Pod
- ⚠️ Update lento
- ⚠️ Puede tener micro-downtimes

**Uso**: Clusters con recursos limitados

---

### **3.6 Ejemplo Práctico: maxSurge y maxUnavailable**

📄 **Archivo**: [`ejemplos/02-rolling-updates/02-max-surge-unavailable.yaml`](./ejemplos/02-rolling-updates/02-max-surge-unavailable.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: surge-demo
spec:
  replicas: 5
  selector:
    matchLabels:
      app: surge-demo
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2          # ← Permite hasta 7 Pods (5+2)
      maxUnavailable: 0    # ← Siempre mínimo 5 disponibles
  template:
    metadata:
      labels:
        app: surge-demo
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
```

**Probar**:

```bash
# Aplicar
kubectl apply -f ejemplos/02-rolling-updates/02-max-surge-unavailable.yaml

# Actualizar imagen
kubectl set image deployment/surge-demo nginx=nginx:1.21-alpine

# Observar en tiempo real
kubectl get pods -l app=surge-demo --watch

# Ver rollout status
kubectl rollout status deployment/surge-demo
```

**Observarás**:
1. Se crean 2 Pods nuevos primero (total: 7)
2. Esperan estar Ready
3. Eliminan 2 Pods viejos (vuelve a 5)
4. Repite hasta completar

---

### **✅ Checkpoint 03: Rolling Updates**

Antes de continuar, asegúrate de poder:

- [ ] Explicar qué es un rolling update
- [ ] Describir el flujo: crear ReplicaSet v2 → escalar UP/DOWN gradualmente
- [ ] Mencionar 5 cambios que activan rolling update
- [ ] Explicar `maxSurge` y `maxUnavailable` con ejemplos
- [ ] Configurar zero downtime (maxUnavailable: 0)
- [ ] Usar `kubectl rollout status` para ver progreso
- [ ] Observar rolling update en tiempo real con `--watch`
- [ ] Identificar ReplicaSets históricos vs activos

📁 **Laboratorio**: [`laboratorios/lab-03-rolling-updates.md`](./laboratorios/lab-03-rolling-updates.md)
- Duración: 45 minutos
- Practica rolling updates con diferentes configuraciones
- Experimenta con maxSurge y maxUnavailable
- Simula escenarios: zero downtime, update rápido, recursos limitados
- Monitorea progreso del rollout

---

## ⏪ 4. Rollback y Gestión de Versiones

### **4.1 Historial de Revisiones**

Kubernetes **guarda automáticamente** las versiones previas de tu Deployment mediante ReplicaSets históricos.

```bash
# Ver historial de rollout
kubectl rollout history deployment/webapp
# REVISION  CHANGE-CAUSE
# 1         Initial deployment v1.0
# 2         Actualizar a nginx:1.21
# 3         Aumentar replicas a 10
# 4         Actualizar resources (CPU/RAM)
```

**Conceptos**:
- **Revision**: Número secuencial de cada cambio en `spec.template`
- **Change-Cause**: Anotación `kubernetes.io/change-cause` (opcional pero recomendada)
- **ReplicaSet histórico**: ReplicaSet con `replicas: 0`

---

### **4.2 Configurar revisionHistoryLimit**

```yaml
spec:
  revisionHistoryLimit: 10  # ← Mantiene 10 ReplicaSets históricos (default: 10)
```

**Valores**:
- `revisionHistoryLimit: 10` → Mantiene últimas 10 revisiones
- `revisionHistoryLimit: 3` → Mantiene últimas 3 (menos recursos)
- `revisionHistoryLimit: 0` → NO mantiene historial (⚠️ no podrás hacer rollback)

**Trade-off**:
- ✅ **Más revisiones** = Más opciones de rollback, más recursos consumidos
- ✅ **Menos revisiones** = Menos recursos, menos opciones de rollback

---

### **4.3 Ver Detalles de una Revisión**

```bash
# Ver detalles de revisión específica
kubectl rollout history deployment/webapp --revision=2

# Salida esperada:
# deployment.apps/webapp with revision #2
# Pod Template:
#   Labels:       app=webapp
#                 pod-template-hash=7c8d9e0f
#                 version=v2
#   Annotations:  kubernetes.io/change-cause: Actualizar a nginx:1.21
#   Containers:
#    nginx:
#     Image:      nginx:1.21-alpine
#     Port:       80/TCP
#     Host Port:  0/TCP
#     Environment:        <none>
#     Mounts:     <none>
#   Volumes:      <none>
```

**Uso**: Comparar diferencias entre versiones antes de hacer rollback.

---

### **4.4 Rollback Manual**

#### **Rollback a Revisión Anterior (Undo)**

```bash
# Rollback a la revisión inmediatamente anterior
kubectl rollout undo deployment/webapp
# deployment.apps/webapp rolled back

# Ver progreso
kubectl rollout status deployment/webapp
# Waiting for deployment "webapp" rollout to finish: 1 out of 5 new replicas have been updated...
# deployment "webapp" successfully rolled out ✅
```

#### **Rollback a Revisión Específica**

```bash
# Rollback a revisión #2
kubectl rollout undo deployment/webapp --to-revision=2
# deployment.apps/webapp rolled back

# Verificar
kubectl rollout history deployment/webapp
# REVISION  CHANGE-CAUSE
# 1         Initial deployment v1.0
# 3         Aumentar replicas a 10
# 4         Actualizar resources (CPU/RAM)
# 5         Actualizar a nginx:1.21  ← Ahora es la revisión 5 (rollback crea nueva revisión)
```

**⚠️ Importante**: Rollback **crea una nueva revisión**, NO restaura el número anterior.

---

### **4.5 Ejemplo Práctico de Rollback**

📄 **Archivo**: [`ejemplos/03-rollback/01-rollback-demo.yaml`](./ejemplos/03-rollback/01-rollback-demo.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rollback-demo
  annotations:
    kubernetes.io/change-cause: "v1.0: Deployment inicial"
spec:
  replicas: 5
  revisionHistoryLimit: 5  # ← Mantiene últimas 5 revisiones
  selector:
    matchLabels:
      app: rollback-demo
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: rollback-demo
        version: "v1.0"
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Paso 1**: Aplicar versión inicial
```bash
kubectl apply -f ejemplos/03-rollback/01-rollback-demo.yaml

# Verificar
kubectl get deployment rollback-demo
kubectl rollout history deployment/rollback-demo
# REVISION  CHANGE-CAUSE
# 1         v1.0: Deployment inicial
```

**Paso 2**: Actualizar a v1.21 (OK)
```bash
# Actualizar change-cause
kubectl annotate deployment rollback-demo \
  kubernetes.io/change-cause="v1.1: Actualizar a nginx:1.21" \
  --overwrite

# Actualizar imagen
kubectl set image deployment/rollback-demo nginx=nginx:1.21-alpine

# Verificar
kubectl rollout status deployment/rollback-demo
# deployment "rollback-demo" successfully rolled out ✅

kubectl rollout history deployment/rollback-demo
# REVISION  CHANGE-CAUSE
# 1         v1.0: Deployment inicial
# 2         v1.1: Actualizar a nginx:1.21
```

**Paso 3**: Actualizar a v1.22 (FALLA - simular error)
```bash
# Actualizar change-cause
kubectl annotate deployment rollback-demo \
  kubernetes.io/change-cause="v1.2: Actualizar a nginx:1.22 (BUGGY)" \
  --overwrite

# Actualizar a versión problemática (simulamos con imagen incorrecta)
kubectl set image deployment/rollback-demo nginx=nginx:1.22-alpine-WRONG

# Observar FALLO
kubectl rollout status deployment/rollback-demo
# Waiting for deployment "rollback-demo" rollout to finish: 1 out of 5 new replicas have been updated...
# Waiting for deployment "rollback-demo" rollout to finish: 1 old replicas are pending termination...
# (⚠️ Se queda bloqueado porque la imagen no existe)

# Ver Pods con error
kubectl get pods -l app=rollback-demo
# NAME                             READY   STATUS             RESTARTS   AGE
# rollback-demo-5d7f8c9b-abc       1/1     Running            0          5m   ← v1.21 (viejo, todavía activo)
# rollback-demo-7c8d9e0f-xyz       0/1     ImagePullBackOff   0          30s  ← v1.22 (nuevo, FALLA)
```

**Paso 4**: Rollback a versión anterior (v1.21)
```bash
# Rollback inmediato
kubectl rollout undo deployment/rollback-demo
# deployment.apps/rollback-demo rolled back

# Ver progreso
kubectl rollout status deployment/rollback-demo
# deployment "rollback-demo" successfully rolled out ✅

# Verificar Pods
kubectl get pods -l app=rollback-demo
# NAME                             READY   STATUS    RESTARTS   AGE
# rollback-demo-5d7f8c9b-abc       1/1     Running   0          6m  ← v1.21 (restaurado)
# rollback-demo-5d7f8c9b-def       1/1     Running   0          6m
# (Todos los Pods vuelven a estar Running)

# Ver historial
kubectl rollout history deployment/rollback-demo
# REVISION  CHANGE-CAUSE
# 1         v1.0: Deployment inicial
# 3         v1.2: Actualizar a nginx:1.22 (BUGGY)  ← Fallo
# 4         v1.1: Actualizar a nginx:1.21          ← Rollback (nueva revisión)
```

---

### **4.6 Rollback Automático (progressDeadlineSeconds)**

```yaml
spec:
  progressDeadlineSeconds: 600  # ← Timeout de 600s (default: 600s = 10 min)
```

**Comportamiento**:
- Si el rolling update no completa en `progressDeadlineSeconds`, Kubernetes marca el Deployment como **Progressing=False**
- ⚠️ **NO hace rollback automático**, solo marca como fallido
- Tú decides si hacer rollback manual

**Ver condiciones**:
```bash
kubectl get deployment webapp -o jsonpath='{.status.conditions[?(@.type=="Progressing")]}'

# Si timeout excedido:
# {
#   "type": "Progressing",
#   "status": "False",
#   "reason": "ProgressDeadlineExceeded",
#   "message": "ReplicaSet \"webapp-7c8d9e0f\" has timed out progressing."
# }
```

**Ejemplo**: Update lento que excede timeout
```yaml
spec:
  progressDeadlineSeconds: 60  # ← Solo 60 segundos
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 90  # ← Tarda 90s en estar Ready (excede timeout)
```

---

### **4.7 Pausar y Reanudar Rolling Updates**

Permite **detener temporalmente** un rolling update en progreso.

#### **Pausar Deployment**

```bash
# Pausar rollout
kubectl rollout pause deployment/webapp
# deployment.apps/webapp paused

# Hacer múltiples cambios sin activar rolling update
kubectl set image deployment/webapp nginx=nginx:1.22-alpine
kubectl set resources deployment/webapp -c=nginx --limits=cpu=1,memory=1Gi

# Reanudar rollout (aplica TODOS los cambios juntos)
kubectl rollout resume deployment/webapp
# deployment.apps/webapp resumed

# Ver progreso
kubectl rollout status deployment/webapp
```

**Uso**:
- Aplicar múltiples cambios como una sola actualización
- Reducir número de rolling updates (menos interrupciones)
- Testing incremental en producción (Canary)

---

### **4.8 Ejemplo Avanzado: Pause/Resume**

📄 **Archivo**: [`ejemplos/03-rollback/02-pause-resume.yaml`](./ejemplos/03-rollback/02-pause-resume.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pause-demo
spec:
  replicas: 10
  selector:
    matchLabels:
      app: pause-demo
  template:
    metadata:
      labels:
        app: pause-demo
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

**Probar**:
```bash
# Aplicar
kubectl apply -f ejemplos/03-rollback/02-pause-resume.yaml

# Pausar
kubectl rollout pause deployment/pause-demo

# Hacer 3 cambios
kubectl set image deployment/pause-demo nginx=nginx:1.21-alpine
kubectl scale deployment pause-demo --replicas=15
kubectl set resources deployment pause-demo -c=nginx --limits=cpu=500m,memory=512Mi

# Ver que NO se activa rolling update (Deployment pausado)
kubectl get rs -l app=pause-demo
# (Solo 1 ReplicaSet activo, sin nuevos)

# Reanudar (aplica los 3 cambios juntos)
kubectl rollout resume deployment/pause-demo

# Ver rollout
kubectl rollout status deployment/pause-demo
# deployment "pause-demo" successfully rolled out ✅

# Verificar cambios aplicados
kubectl get deployment pause-demo -o jsonpath='{.spec.replicas}'  # 15
kubectl get pods -l app=pause-demo -o jsonpath='{.items[0].spec.containers[0].image}'  # nginx:1.21-alpine
```

---

### **4.9 Troubleshooting: Rollout Bloqueado**

#### **Síntoma**: Rolling update se queda "stuck"

```bash
kubectl rollout status deployment/webapp
# Waiting for deployment "webapp" rollout to finish: 1 out of 5 new replicas have been updated...
# (Se queda aquí indefinidamente)
```

#### **Causas Comunes**:

| Causa | Síntoma | Solución |
|-------|---------|----------|
| **Imagen no existe** | `ImagePullBackOff` | Verificar nombre/tag imagen |
| **Readiness probe falla** | Pod nunca Ready | Revisar probe config |
| **Resources insuficientes** | `Pending` (no schedule) | Revisar requests/limits |
| **Node selector no match** | `Pending` | Revisar nodeSelector/affinity |
| **PVC no bound** | `Pending` | Verificar PersistentVolumeClaims |

#### **Debugging**:

```bash
# Ver Pods con problemas
kubectl get pods -l app=webapp

# Describir Pod con error
kubectl describe pod <pod-name>

# Ver logs del contenedor
kubectl logs <pod-name> -c <container-name>

# Ver eventos del Deployment
kubectl describe deployment webapp

# Ver ReplicaSets
kubectl get rs -l app=webapp

# Ver condiciones
kubectl get deployment webapp -o jsonpath='{.status.conditions[*]}'
```

#### **Soluciones**:

```bash
# Opción 1: Rollback inmediato
kubectl rollout undo deployment/webapp

# Opción 2: Corregir problema y re-aplicar
kubectl set image deployment/webapp nginx=nginx:1.21-alpine  # Imagen correcta

# Opción 3: Eliminar y recrear
kubectl delete deployment webapp
kubectl apply -f deployment.yaml
```

---

### **✅ Checkpoint 04: Rollback y Versiones**

Antes de continuar, asegúrate de poder:

- [ ] Ver historial de revisiones con `kubectl rollout history`
- [ ] Explicar qué es `revisionHistoryLimit` y su impacto
- [ ] Ver detalles de una revisión específica
- [ ] Hacer rollback a la revisión anterior con `undo`
- [ ] Hacer rollback a revisión específica con `--to-revision`
- [ ] Explicar que rollback crea una nueva revisión
- [ ] Configurar `progressDeadlineSeconds` para timeout
- [ ] Pausar y reanudar rolling updates
- [ ] Diagnosticar rollout bloqueado (ImagePullBackOff, Pending, etc.)

📁 **Laboratorio**: [`laboratorios/lab-04-rollback-versiones.md`](./laboratorios/lab-04-rollback-versiones.md)
- Duración: 40 minutos
- Practica rollback manual y automático
- Simula fallos de despliegue (imagen incorrecta)
- Experimenta con pause/resume
- Troubleshooting de rollouts bloqueados

---

## 🚀 5. Estrategias de Deployment Avanzadas

### **5.1 RollingUpdate vs Recreate: Comparación**

```yaml
# Estrategia 1: RollingUpdate (DEFAULT)
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0

# Estrategia 2: Recreate
spec:
  strategy:
    type: Recreate
```

| Aspecto | RollingUpdate | Recreate |
|---------|---------------|----------|
| **Downtime** | ✅ Zero downtime (si maxUnavailable: 0) | ❌ Downtime total (elimina todos los Pods) |
| **Velocidad** | 🐢 Más lento (gradual) | 🚀 Más rápido (instantáneo) |
| **Uso de recursos** | 📈 Requiere recursos extras (maxSurge) | 📉 Usa solo recursos necesarios |
| **Rollback** | ✅ Automático (parcial si falla) | ❌ Manual (todo o nada) |
| **Versiones simultáneas** | ✅ Sí (v1 y v2 coexisten) | ❌ No (solo v2) |
| **Casos de uso** | Web apps, APIs stateless, microservicios | Bases de datos, apps con estado compartido |

---

### **5.2 Estrategia Recreate: Cuándo Usarla**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  strategy:
    type: Recreate  # ← Elimina TODOS los Pods antes de crear nuevos
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:14-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "secretpassword"
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: postgres-pvc
```

**Comportamiento**:
1. Escala ReplicaSet viejo a 0 (elimina todos los Pods)
2. Espera que todos estén Terminated
3. Crea ReplicaSet nuevo
4. Escala a `replicas` deseadas

**Cuándo usar Recreate**:
- ✅ **Aplicaciones con estado compartido** (bases de datos, Kafka)
- ✅ **Incompatibilidad entre versiones** (v1 y v2 no pueden coexistir)
- ✅ **Recursos limitados** (no hay espacio para Pods extras)
- ✅ **Single replica** (replicas: 1)

**⚠️ Downtime**: Durante 10-30 segundos (tiempo de terminar Pods + crear nuevos).

---

### **5.3 Blue-Green Deployment**

**Concepto**: Mantener 2 entornos completos (**Blue** = actual, **Green** = nuevo), cambiar tráfico instantáneamente.

```
┌──────────────────────────────────────────────────────┐
│              BLUE-GREEN DEPLOYMENT                   │
└──────────────────────────────────────────────────────┘

PASO 1: Entorno Blue (v1) activo
┌───────────────────────────────────────────┐
│ Service (app=webapp, version=blue)        │  ← Apunta a Blue
│        ↓                                   │
│ Deployment Blue (v1)                      │
│ ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│ │ Pod v1  │  │ Pod v1  │  │ Pod v1  │   │
│ └─────────┘  └─────────┘  └─────────┘   │
└───────────────────────────────────────────┘

PASO 2: Crear entorno Green (v2) en paralelo
┌───────────────────────────────────────────┐
│ Service (app=webapp, version=blue)        │  ← Todavía apunta a Blue
│        ↓                                   │
│ Deployment Blue (v1)                      │
│ ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│ │ Pod v1  │  │ Pod v1  │  │ Pod v1  │   │
│ └─────────┘  └─────────┘  └─────────┘   │
│                                            │
│ Deployment Green (v2)                     │  ← Nuevo (testing)
│ ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│ │ Pod v2  │  │ Pod v2  │  │ Pod v2  │   │
│ └─────────┘  └─────────┘  └─────────┘   │
└───────────────────────────────────────────┘

PASO 3: Cambiar Service a Green (switch instantáneo)
┌───────────────────────────────────────────┐
│ Service (app=webapp, version=green)       │  ← Cambió a Green
│        ↓                                   │
│ Deployment Green (v2)                     │  ← ACTIVO
│ ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│ │ Pod v2  │  │ Pod v2  │  │ Pod v2  │   │
│ └─────────┘  └─────────┘  └─────────┘   │
│                                            │
│ Deployment Blue (v1)                      │  ← Standby (rollback rápido)
│ ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│ │ Pod v1  │  │ Pod v1  │  │ Pod v1  │   │
│ └─────────┘  └─────────┘  └─────────┘   │
└───────────────────────────────────────────┘

PASO 4 (Opcional): Eliminar Blue después de validación
```

**Implementación en Kubernetes**:

📄 **Archivos**:
- [`ejemplos/04-estrategias/01-blue-deployment.yaml`](./ejemplos/04-estrategias/01-blue-deployment.yaml)
- [`ejemplos/04-estrategias/02-green-deployment.yaml`](./ejemplos/04-estrategias/02-green-deployment.yaml)
- [`ejemplos/04-estrategias/03-service.yaml`](./ejemplos/04-estrategias/03-service.yaml)

**Blue Deployment (v1)**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-blue
  labels:
    app: webapp
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
      version: blue
  template:
    metadata:
      labels:
        app: webapp
        version: blue
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
```

**Green Deployment (v2)**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-green
  labels:
    app: webapp
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
      version: green
  template:
    metadata:
      labels:
        app: webapp
        version: green
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine  # ← NUEVA VERSIÓN
        ports:
        - containerPort: 80
```

**Service** (controla tráfico):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  selector:
    app: webapp
    version: blue  # ← Cambia a 'green' para switch
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

**Proceso**:
```bash
# 1. Crear Blue (v1)
kubectl apply -f ejemplos/04-estrategias/01-blue-deployment.yaml

# 2. Crear Service apuntando a Blue
kubectl apply -f ejemplos/04-estrategias/03-service.yaml

# 3. Verificar tráfico a Blue
kubectl get svc webapp-service
kubectl get endpoints webapp-service

# 4. Crear Green (v2) en paralelo
kubectl apply -f ejemplos/04-estrategias/02-green-deployment.yaml

# 5. Testing en Green (sin tráfico público)
kubectl port-forward deployment/webapp-green 8080:80
# curl localhost:8080  (verificar que funciona)

# 6. SWITCH: Cambiar Service a Green (editar YAML)
# Cambiar selector de 'version: blue' a 'version: green'
kubectl apply -f ejemplos/04-estrategias/03-service.yaml

# 7. Verificar tráfico a Green
kubectl get endpoints webapp-service

# 8. Rollback inmediato (si hay problemas)
# Cambiar selector a 'version: blue'
kubectl apply -f ejemplos/04-estrategias/03-service.yaml

# 9. Eliminar Blue (después de validación)
kubectl delete deployment webapp-blue
```

**Ventajas**:
- ✅ **Rollback instantáneo** (cambiar selector del Service)
- ✅ **Zero downtime**
- ✅ **Testing completo** antes de switch

**Desventajas**:
- ❌ **Requiere 2x recursos** (Blue + Green simultáneos)
- ❌ **Complejidad**: Gestionar 2 Deployments

---

### **5.4 Canary Deployment**

**Concepto**: Enviar un **porcentaje pequeño** de tráfico a la nueva versión (canary) antes de rollout completo.

```
┌──────────────────────────────────────────────────────┐
│              CANARY DEPLOYMENT                       │
└──────────────────────────────────────────────────────┘

PASO 1: Versión Stable (v1) con 100% tráfico
┌───────────────────────────────────────────┐
│ Service (app=webapp)                      │  ← 100% tráfico
│        ↓                                   │
│ Deployment Stable (v1) - replicas: 10    │
│ ┌─────────┐  ┌─────────┐  ...            │
│ │ Pod v1  │  │ Pod v1  │  (10 Pods)      │
│ └─────────┘  └─────────┘                  │
└───────────────────────────────────────────┘

PASO 2: Desplegar Canary (v2) con 10% tráfico
┌───────────────────────────────────────────┐
│ Service (app=webapp)                      │  ← 90% v1 + 10% v2
│        ↓                                   │
│ Deployment Stable (v1) - replicas: 9     │  ← Reducido a 9
│ ┌─────────┐  ┌─────────┐  ...            │
│ │ Pod v1  │  │ Pod v1  │  (9 Pods)       │
│ └─────────┘  └─────────┘                  │
│                                            │
│ Deployment Canary (v2) - replicas: 1     │  ← 1 Pod nuevo
│ ┌─────────┐                               │
│ │ Pod v2  │                               │
│ └─────────┘                               │
└───────────────────────────────────────────┘

PASO 3: Aumentar tráfico a Canary (50%)
┌───────────────────────────────────────────┐
│ Service (app=webapp)                      │  ← 50% v1 + 50% v2
│        ↓                                   │
│ Deployment Stable (v1) - replicas: 5     │
│ ┌─────────┐  ...                          │
│ │ Pod v1  │  (5 Pods)                     │
│ └─────────┘                               │
│                                            │
│ Deployment Canary (v2) - replicas: 5     │
│ ┌─────────┐  ...                          │
│ │ Pod v2  │  (5 Pods)                     │
│ └─────────┘                               │
└───────────────────────────────────────────┘

PASO 4: Promover Canary a 100% (eliminar Stable)
┌───────────────────────────────────────────┐
│ Service (app=webapp)                      │  ← 100% v2
│        ↓                                   │
│ Deployment Canary (v2) - replicas: 10    │
│ ┌─────────┐  ┌─────────┐  ...            │
│ │ Pod v2  │  │ Pod v2  │  (10 Pods)      │
│ └─────────┘  └─────────┘                  │
└───────────────────────────────────────────┘
```

**Implementación**:

📄 **Archivos**:
- [`ejemplos/04-estrategias/04-stable-deployment.yaml`](./ejemplos/04-estrategias/04-stable-deployment.yaml)
- [`ejemplos/04-estrategias/05-canary-deployment.yaml`](./ejemplos/04-estrategias/05-canary-deployment.yaml)
- [`ejemplos/04-estrategias/06-service-canary.yaml`](./ejemplos/04-estrategias/06-service-canary.yaml)

**Stable Deployment**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-stable
spec:
  replicas: 10  # ← 100% inicialmente
  selector:
    matchLabels:
      app: webapp
      track: stable
  template:
    metadata:
      labels:
        app: webapp
        track: stable
        version: "v1"
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
```

**Canary Deployment**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-canary
spec:
  replicas: 1  # ← 10% (1 de 10 Pods totales)
  selector:
    matchLabels:
      app: webapp
      track: canary
  template:
    metadata:
      labels:
        app: webapp
        track: canary
        version: "v2"
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine  # ← NUEVA VERSIÓN
        ports:
        - containerPort: 80
```

**Service** (balancea entre Stable y Canary):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  selector:
    app: webapp  # ← Matchea AMBOS (stable y canary)
  ports:
  - port: 80
    targetPort: 80
```

**Proceso**:
```bash
# 1. Desplegar Stable (v1)
kubectl apply -f ejemplos/04-estrategias/04-stable-deployment.yaml
kubectl apply -f ejemplos/04-estrategias/06-service-canary.yaml

# 2. Verificar 100% tráfico a v1
kubectl get endpoints webapp-service
# (10 Pods de stable)

# 3. Desplegar Canary (v2) con 10% tráfico
kubectl apply -f ejemplos/04-estrategias/05-canary-deployment.yaml

# 4. Reducir Stable a 9 Pods (mantener total: 10)
kubectl scale deployment webapp-stable --replicas=9

# 5. Verificar distribución 90/10
kubectl get endpoints webapp-service
# (9 Pods stable + 1 Pod canary)

# 6. Monitorear métricas de Canary
# (Errores, latencia, tráfico, etc.)

# 7a. Si Canary OK → Aumentar a 50%
kubectl scale deployment webapp-stable --replicas=5
kubectl scale deployment webapp-canary --replicas=5

# 7b. Si Canary OK → Promover a 100%
kubectl scale deployment webapp-canary --replicas=10
kubectl delete deployment webapp-stable

# 8. Rollback si falla
kubectl delete deployment webapp-canary
kubectl scale deployment webapp-stable --replicas=10
```

**Ventajas**:
- ✅ **Riesgo reducido** (solo 10% usuarios afectados)
- ✅ **Testing en producción** con tráfico real
- ✅ **Rollback rápido** (delete canary)

**Desventajas**:
- ❌ **Complejidad**: Gestionar 2 Deployments + métricas
- ❌ **Requiere balanceo manual** (scaling)

---

### **5.5 Progressive Delivery con Flagger (Avanzado)**

**Flagger** = Herramienta para automatizar Canary deployments con métricas.

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: webapp
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
    - name: request-duration
      thresholdRange:
        max: 500
```

**Comportamiento**:
1. Detecta cambio en Deployment
2. Crea Canary con 10% tráfico
3. Monitorea métricas cada 1 minuto
4. Si métricas OK → Aumenta 10% (stepWeight)
5. Si métricas fallan → Rollback automático
6. Repite hasta 50% (maxWeight)

**⚠️ Requiere**: Service mesh (Istio, Linkerd) o Ingress Controller (NGINX, Traefik).

---

### **✅ Checkpoint 05: Estrategias Avanzadas**

Antes de continuar, asegúrate de poder:

- [ ] Comparar RollingUpdate vs Recreate (downtime, velocidad, recursos)
- [ ] Explicar cuándo usar Recreate (bases de datos, incompatibilidad)
- [ ] Describir Blue-Green deployment (2 entornos, switch instantáneo)
- [ ] Implementar Blue-Green con 2 Deployments + Service selector
- [ ] Describir Canary deployment (porcentaje gradual)
- [ ] Implementar Canary con scaling manual de replicas
- [ ] Calcular porcentajes: 1 canary + 9 stable = 10% canary
- [ ] Explicar ventajas/desventajas de cada estrategia

📁 **Laboratorio**: [`laboratorios/lab-05-estrategias-avanzadas.md`](./laboratorios/lab-05-estrategias-avanzadas.md)
- Duración: 60 minutos
- Implementa Blue-Green deployment
- Practica Canary con diferentes porcentajes (10%, 50%, 100%)
- Simula rollback de Canary
- Compara tiempos y recursos de cada estrategia

---

## ✨ 6. Best Practices para Deployments

### **6.1 Naming Conventions**

```yaml
metadata:
  name: webapp-frontend-prod  # ← Descriptivo: app-component-environment
  labels:
    app: webapp              # ← Nombre aplicación
    component: frontend      # ← Componente específico
    tier: web                # ← Capa arquitectónica
    environment: production  # ← Ambiente
    version: "v2.1.0"        # ← Versión semántica
    managed-by: helm         # ← Herramienta de gestión (opcional)
```

**Convenciones recomendadas**:
- **Lowercase**: Siempre minúsculas (obligatorio en Kubernetes)
- **Separadores**: Usar `-` (no `_`)
- **Máximo 63 caracteres**
- **Labels estándar**: `app`, `component`, `version`, `environment`

---

### **6.2 Resources: Requests y Limits**

**⚠️ SIEMPRE define resources en producción**:

```yaml
spec:
  template:
    spec:
      containers:
      - name: nginx
        resources:
          requests:          # ← Reserva garantizada
            memory: "256Mi"
            cpu: "500m"      # ← 0.5 CPU
          limits:            # ← Máximo permitido
            memory: "512Mi"
            cpu: "1000m"     # ← 1 CPU
```

**Cálculo de requests**:
1. **Medir consumo real** en staging/producción
2. **Requests** = Promedio + 20% margen
3. **Limits** = Requests × 2 (permite picos)

**Ejemplo**:
- Promedio: 200Mi RAM, 300m CPU
- Requests: 250Mi RAM, 400m CPU (20% margen)
- Limits: 500Mi RAM, 800m CPU (2x)

**⚠️ Consecuencias sin resources**:
- Sin requests → Pods compiten por recursos (problemas de rendimiento)
- Sin limits → Un Pod puede consumir todos los recursos del nodo (OOMKilled)

---

### **6.3 Health Checks: Liveness y Readiness**

```yaml
spec:
  template:
    spec:
      containers:
      - name: webapp
        image: webapp:v2
        ports:
        - containerPort: 8080
        
        # ¿Está VIVO el proceso?
        livenessProbe:
          httpGet:
            path: /healthz      # ← Endpoint simple (debe responder rápido)
            port: 8080
          initialDelaySeconds: 30  # ← Espera inicial (startup time)
          periodSeconds: 10        # ← Cada 10s
          timeoutSeconds: 5        # ← Timeout por request
          failureThreshold: 3      # ← Reinicia después de 3 fallos
        
        # ¿Está LISTO para recibir tráfico?
        readinessProbe:
          httpGet:
            path: /ready        # ← Endpoint más complejo (DB, cache, etc.)
            port: 8080
          initialDelaySeconds: 5   # ← Más corto que liveness
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3      # ← Saca del Service después de 3 fallos
```

**Diferencias clave**:

| Aspecto | Liveness | Readiness |
|---------|----------|-----------|
| **Propósito** | Detectar procesos muertos/bloqueados | Detectar si está listo para tráfico |
| **Acción** | **Reinicia** el Pod | **Saca** del Service (sin reiniciar) |
| **Endpoint** | Simple (`/healthz` → 200 OK) | Complejo (`/ready` → verifica DB, cache) |
| **initialDelaySeconds** | Más largo (30-60s) | Más corto (5-10s) |
| **Cuándo falla** | Proceso bloqueado, deadlock | DB desconectada, cache lleno |

**Ejemplo endpoints**:

```go
// Liveness: Solo verifica que el servidor responde
func healthz(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
}

// Readiness: Verifica dependencias
func ready(w http.ResponseWriter, r *http.Request) {
    if dbConnected() && cacheAvailable() {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("Ready"))
    } else {
        w.WriteHeader(http.StatusServiceUnavailable)
        w.Write([]byte("Not Ready"))
    }
}
```

---

### **6.4 Security Contexts**

```yaml
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true           # ← NO ejecutar como root
        runAsUser: 1000              # ← UID específico
        fsGroup: 2000                # ← GID para volumes
        seccompProfile:
          type: RuntimeDefault       # ← Seccomp profile
      
      containers:
      - name: nginx
        image: nginx:alpine
        securityContext:
          allowPrivilegeEscalation: false  # ← No permitir escalada
          capabilities:
            drop:
            - ALL                    # ← Eliminar todas las capabilities
            add:
            - NET_BIND_SERVICE       # ← Solo agregar las necesarias
          readOnlyRootFilesystem: true     # ← Filesystem de solo lectura
        
        volumeMounts:
        - name: tmp
          mountPath: /tmp            # ← Directorio writable
        - name: cache
          mountPath: /var/cache/nginx
      
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
```

**Principios de seguridad**:
- ✅ **No root**: Ejecutar con usuario no privilegiado
- ✅ **Read-only filesystem**: Previene modificación de binarios
- ✅ **Drop capabilities**: Eliminar permisos innecesarios
- ✅ **Seccomp profile**: Filtrar syscalls peligrosas

---

### **6.5 Anti-Patterns: Qué NO Hacer**

#### **❌ Anti-Pattern 1: Omitir readinessProbe**

```yaml
# ❌ MAL: Sin readiness probe
spec:
  template:
    spec:
      containers:
      - name: webapp
        image: webapp:v2
# Problema: Pod recibe tráfico ANTES de estar listo (errores 500)
```

```yaml
# ✅ BIEN: Con readiness probe
spec:
  template:
    spec:
      containers:
      - name: webapp
        image: webapp:v2
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
```

---

#### **❌ Anti-Pattern 2: maxUnavailable alto sin testing**

```yaml
# ❌ MAL: Permite 50% downtime
spec:
  strategy:
    rollingUpdate:
      maxUnavailable: 50%
# Problema: Si hay error, 50% de Pods caen simultáneamente
```

```yaml
# ✅ BIEN: Zero downtime
spec:
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # ← Siempre mínimo replicas disponibles
```

---

#### **❌ Anti-Pattern 3: No usar change-cause**

```yaml
# ❌ MAL: Sin annotation
metadata:
  name: webapp
# Problema: No sabes qué cambió en cada revisión
```

```yaml
# ✅ BIEN: Con change-cause
metadata:
  name: webapp
  annotations:
    kubernetes.io/change-cause: "v2.1.0: Actualizar nginx + agregar health checks"
```

---

#### **❌ Anti-Pattern 4: Usar :latest**

```yaml
# ❌ MAL: Tag latest (no determinístico)
spec:
  template:
    spec:
      containers:
      - name: webapp
        image: webapp:latest  # ← ¿Qué versión es?
```

```yaml
# ✅ BIEN: Tag específico (semantic versioning)
spec:
  template:
    spec:
      containers:
      - name: webapp
        image: webapp:v2.1.0  # ← Versión exacta
```

---

#### **❌ Anti-Pattern 5: replicas: 1 en producción**

```yaml
# ❌ MAL: Single replica
spec:
  replicas: 1  # ← Single point of failure
```

```yaml
# ✅ BIEN: Múltiples replicas + anti-affinity
spec:
  replicas: 3
  template:
    spec:
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

### **6.6 Production-Ready Deployment Template**

📄 **Archivo**: [`ejemplos/05-best-practices/production-template.yaml`](./ejemplos/05-best-practices/production-template.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-frontend-prod
  labels:
    app: webapp
    component: frontend
    tier: web
    environment: production
    version: "v2.1.0"
  annotations:
    kubernetes.io/change-cause: "v2.1.0: Production deployment with security hardening"
spec:
  replicas: 5
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600
  
  selector:
    matchLabels:
      app: webapp
      component: frontend
      environment: production
  
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0  # ← Zero downtime
  
  template:
    metadata:
      labels:
        app: webapp
        component: frontend
        tier: web
        environment: production
        version: "v2.1.0"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    
    spec:
      # Security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
        seccompProfile:
          type: RuntimeDefault
      
      # Anti-affinity (distribuir en nodos diferentes)
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
      
      containers:
      - name: webapp
        image: webapp:v2.1.0  # ← Tag específico (NO latest)
        imagePullPolicy: IfNotPresent
        
        ports:
        - name: http
          containerPort: 8080
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
            path: /healthz
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # Security context
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
          readOnlyRootFilesystem: true
        
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
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        
        # Volumes
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /var/cache
        - name: config
          mountPath: /etc/config
          readOnly: true
      
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
      - name: config
        configMap:
          name: webapp-config
```

**Características production-ready**:
- ✅ **5 replicas** + anti-affinity (alta disponibilidad)
- ✅ **Zero downtime** (maxUnavailable: 0)
- ✅ **Resources** definidos (requests + limits)
- ✅ **Health checks** (liveness + readiness)
- ✅ **Security hardening** (runAsNonRoot, readOnlyRootFilesystem, drop capabilities)
- ✅ **Semantic versioning** (v2.1.0)
- ✅ **Change cause** para auditoría
- ✅ **Prometheus annotations** para monitoreo
- ✅ **ConfigMap** para configuración externa

---

### **✅ Checkpoint 06: Best Practices**

Antes de continuar, asegúrate de poder:

- [ ] Aplicar naming conventions (app-component-environment)
- [ ] Definir resources (requests + limits) con cálculos apropiados
- [ ] Configurar liveness y readiness probes correctamente
- [ ] Explicar diferencia entre liveness y readiness
- [ ] Implementar security contexts (runAsNonRoot, readOnlyRootFilesystem, capabilities)
- [ ] Identificar 5 anti-patterns comunes
- [ ] Usar semantic versioning (NO :latest)
- [ ] Configurar zero downtime (maxUnavailable: 0)
- [ ] Agregar change-cause annotations

📁 **Laboratorio**: [`laboratorios/lab-06-best-practices.md`](./laboratorios/lab-06-best-practices.md)
- Duración: 50 minutos
- Transforma un Deployment básico a production-ready
- Implementa todos los best practices
- Testing de health checks (simula fallos)
- Valida security contexts

---

## 📊 7. Monitoreo y Troubleshooting

### **7.1 Comandos de Diagnóstico Rápido**

```bash
# Ver estado general
kubectl get deployment webapp -o wide

# Ver condiciones del Deployment
kubectl get deployment webapp -o jsonpath='{.status.conditions[*]}'

# Ver eventos recientes (últimos 10 minutos)
kubectl get events --field-selector involvedObject.kind=Deployment,involvedObject.name=webapp --sort-by='.metadata.creationTimestamp'

# Ver Pods con problemas
kubectl get pods -l app=webapp --field-selector status.phase!=Running

# Describir Deployment completo
kubectl describe deployment webapp

# Ver logs de todos los Pods
kubectl logs -l app=webapp --tail=50 --prefix=true

# Ver recursos consumidos (requiere Metrics Server)
kubectl top pods -l app=webapp
```

---

### **7.2 Debugging Common Issues**

#### **Issue 1: ImagePullBackOff**

```bash
# Síntoma
kubectl get pods -l app=webapp
# NAME                     READY   STATUS             RESTARTS   AGE
# webapp-7c8d9e0f-abc      0/1     ImagePullBackOff   0          2m

# Diagnóstico
kubectl describe pod webapp-7c8d9e0f-abc | grep -A 10 "Events"
# Events:
#   Type     Reason     Message
#   ----     ------     -------
#   Normal   Pulling    Pulling image "webapp:v2.1.0-WRONG"
#   Warning  Failed     Failed to pull image "webapp:v2.1.0-WRONG": rpc error: ...
#   Warning  Failed     Error: ErrImagePull

# Solución
# 1. Verificar nombre/tag de imagen
kubectl get deployment webapp -o jsonpath='{.spec.template.spec.containers[0].image}'
# 2. Corregir imagen
kubectl set image deployment/webapp webapp=webapp:v2.1.0  # Tag correcto
```

---

#### **Issue 2: CrashLoopBackOff**

```bash
# Síntoma
kubectl get pods -l app=webapp
# NAME                     READY   STATUS             RESTARTS   AGE
# webapp-7c8d9e0f-abc      0/1     CrashLoopBackOff   5          5m

# Diagnóstico
# Ver logs del contenedor
kubectl logs webapp-7c8d9e0f-abc
# Error: Cannot connect to database at db:5432

# Ver logs del contenedor anterior (si reinició)
kubectl logs webapp-7c8d9e0f-abc --previous

# Ver eventos
kubectl describe pod webapp-7c8d9e0f-abc | grep -A 10 "Events"

# Solución
# 1. Verificar variables de entorno
kubectl get deployment webapp -o jsonpath='{.spec.template.spec.containers[0].env[*]}'
# 2. Verificar dependencias (DB, cache, etc.)
# 3. Revisar health checks (¿demasiado agresivos?)
```

---

#### **Issue 3: Pods Pending (No Schedule)**

```bash
# Síntoma
kubectl get pods -l app=webapp
# NAME                     READY   STATUS    RESTARTS   AGE
# webapp-7c8d9e0f-abc      0/1     Pending   0          5m

# Diagnóstico
kubectl describe pod webapp-7c8d9e0f-abc | grep -A 10 "Events"
# Events:
#   Type     Reason            Message
#   ----     ------            -------
#   Warning  FailedScheduling  0/1 nodes are available: 1 Insufficient cpu.

# Solución
# Caso 1: Resources insuficientes
kubectl top nodes  # Ver recursos disponibles
# Reducir requests o agregar nodos

# Caso 2: Node selector no match
kubectl get nodes --show-labels
kubectl get deployment webapp -o jsonpath='{.spec.template.spec.nodeSelector}'
```

---

#### **Issue 4: Readiness Probe Failing**

```bash
# Síntoma
kubectl get pods -l app=webapp
# NAME                     READY   STATUS    RESTARTS   AGE
# webapp-7c8d9e0f-abc      0/1     Running   0          2m

# Diagnóstico
kubectl describe pod webapp-7c8d9e0f-abc | grep -A 10 "Readiness"
# Readiness probe failed: Get "http://10.244.0.5:8080/ready": dial tcp 10.244.0.5:8080: connect: connection refused

# Ver logs
kubectl logs webapp-7c8d9e0f-abc

# Solución
# 1. Verificar endpoint de readiness
kubectl exec webapp-7c8d9e0f-abc -- curl -v localhost:8080/ready
# 2. Aumentar initialDelaySeconds
# 3. Revisar lógica de /ready (¿falla dependencia?)
```

---

### **7.3 Métricas Clave a Monitorear**

**Con Prometheus + Grafana**:

```promql
# Disponibilidad de Pods
sum(kube_deployment_status_replicas_available{deployment="webapp"}) 
  / 
sum(kube_deployment_spec_replicas{deployment="webapp"}) * 100

# Tasa de reintentos (rolling update fallido)
rate(kube_pod_container_status_restarts_total{namespace="default", pod=~"webapp-.*"}[5m])

# Latencia de rolling update (tiempo desde start hasta available)
histogram_quantile(0.99, 
  rate(kube_deployment_status_condition_progressing_duration_seconds_bucket[5m])
)

# Pods no listos (readiness probe failing)
sum(kube_pod_status_ready{condition="false", namespace="default", pod=~"webapp-.*"})
```

**Alertas recomendadas**:
- ✅ **Deployment not available**: `replicas_available < replicas_desired` por > 5 minutos
- ✅ **High restart rate**: > 5 restarts en 5 minutos
- ✅ **Rollout stuck**: Progressing=False por > 10 minutos
- ✅ **Pod not ready**: > 20% Pods con readiness=false

---

### **✅ Checkpoint 07: Monitoreo y Troubleshooting**

Antes de continuar, asegúrate de poder:

- [ ] Usar comandos de diagnóstico rápido (get, describe, events, logs)
- [ ] Diagnosticar ImagePullBackOff (imagen incorrecta)
- [ ] Diagnosticar CrashLoopBackOff (logs, previous logs)
- [ ] Diagnosticar Pods Pending (resources, node selector)
- [ ] Diagnosticar readiness probe failing
- [ ] Identificar métricas clave de disponibilidad
- [ ] Configurar alertas básicas (Deployment not available)

📁 **Laboratorio**: [`laboratorios/lab-07-troubleshooting.md`](./laboratorios/lab-07-troubleshooting.md)
- Duración: 45 minutos
- Simula 5 problemas comunes y resuélvelos
- Practica debugging con kubectl logs/describe/events
- Configura alertas básicas

---

## 🎯 Resumen del Módulo

### **Conceptos Clave Aprendidos**

1. **Deployments** = Controlador que gestiona ReplicaSets y rolling updates automáticos
2. **Rolling Update** = Actualización gradual (v1 → v2) sin downtime
3. **maxSurge** = Pods extras permitidos durante update
4. **maxUnavailable** = Pods no disponibles permitidos (0 = zero downtime)
5. **Rollback** = Volver a versión anterior con `kubectl rollout undo`
6. **Estrategias avanzadas**: Blue-Green (switch instantáneo), Canary (% gradual)
7. **Best practices**: Resources, health checks, security contexts, semantic versioning

---

### **Comandos Esenciales**

```bash
# Gestión básica
kubectl apply -f deployment.yaml
kubectl get deployments
kubectl describe deployment webapp
kubectl delete deployment webapp

# Rolling updates
kubectl set image deployment/webapp nginx=nginx:1.21
kubectl rollout status deployment/webapp
kubectl rollout pause deployment/webapp
kubectl rollout resume deployment/webapp

# Rollback
kubectl rollout history deployment/webapp
kubectl rollout undo deployment/webapp
kubectl rollout undo deployment/webapp --to-revision=2

# Escalado
kubectl scale deployment webapp --replicas=10

# Troubleshooting
kubectl get pods -l app=webapp
kubectl logs <pod-name>
kubectl describe pod <pod-name>
kubectl get events --field-selector involvedObject.kind=Deployment
```

---

### **Flujo de Trabajo Completo**

```
1. Diseño
   ↓
2. Crear manifiesto YAML (con best practices)
   ↓
3. Aplicar: kubectl apply -f deployment.yaml
   ↓
4. Verificar: kubectl get deploy, kubectl rollout status
   ↓
5. Monitorear: Prometheus/Grafana, kubectl top pods
   ↓
6. Actualizar: kubectl set image o editar YAML
   ↓
7. Rolling update automático (gradual)
   ↓
8a. Si OK → Continuar
8b. Si falla → Rollback: kubectl rollout undo
   ↓
9. Iterar (CI/CD pipeline)
```

---

### **Decisiones Clave**

| Decisión | Opción A | Opción B | Cuándo usar A | Cuándo usar B |
|----------|----------|----------|---------------|---------------|
| **Estrategia** | RollingUpdate | Recreate | Apps stateless | Apps stateful, incompatibilidad |
| **maxUnavailable** | 0 | > 0 | Producción (zero downtime) | Dev/Staging (velocidad) |
| **maxSurge** | Alto (2-5) | Bajo (1) | Recursos abundantes | Recursos limitados |
| **Deployment avanzado** | Blue-Green | Canary | Rollback instantáneo | Testing gradual |
| **revisionHistoryLimit** | 10 | 3 | Muchas opciones de rollback | Conservar recursos |

---

### **Checklist Production-Ready**

- [ ] **Replicas**: ≥ 3 para alta disponibilidad
- [ ] **Resources**: requests + limits definidos
- [ ] **Health checks**: liveness + readiness probes
- [ ] **Strategy**: maxUnavailable: 0 (zero downtime)
- [ ] **Security**: runAsNonRoot, readOnlyRootFilesystem, drop capabilities
- [ ] **Versioning**: Semantic versioning (NO :latest)
- [ ] **Annotations**: kubernetes.io/change-cause
- [ ] **Anti-affinity**: Distribuir Pods en nodos diferentes
- [ ] **Monitoring**: Métricas + alertas configuradas
- [ ] **Rollback**: revisionHistoryLimit > 0

---

### **Próximos Pasos**

🎓 **Has completado el Módulo 07: Deployments y Rolling Updates**

**Siguientes módulos**:
- **Módulo 08**: [Services y Endpoints](../modulo-08-services-endpoints/README.md) → Exponer Deployments
- **Módulo 09**: [Ingress](../modulo-09-ingress-external-access/README.md) → Acceso externo HTTP/HTTPS
- **Módulo 10**: [Namespaces](../modulo-10-namespaces-organizacion/README.md) → Organización multi-tenant

**Recursos adicionales**:
- 📖 [Documentación oficial de Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- 📖 [Best practices de Google](https://cloud.google.com/architecture/best-practices-for-operating-containers)
- 📖 [Flagger (Progressive Delivery)](https://flagger.app/)
- 🎥 [KubeCon talks sobre Deployments](https://www.youtube.com/kubecon)

---

### **✅ Checkpoint Final**

Autoevaluación completa del módulo:

**Conceptos (Sección 1)**:
- [ ] Explicar el problema que resuelven los Deployments
- [ ] Describir la arquitectura: Deployment → ReplicaSet → Pods
- [ ] Comparar Deployment vs ReplicaSet (cuándo usar cada uno)

**Gestión (Sección 2)**:
- [ ] Crear Deployment desde manifiesto YAML
- [ ] Usar kubectl para gestionar Deployments (get, describe, scale, delete)
- [ ] Inspeccionar ReplicaSets y Pods gestionados

**Rolling Updates (Sección 3)**:
- [ ] Explicar flujo de rolling update (crear RS v2, escalar gradualmente)
- [ ] Configurar maxSurge y maxUnavailable apropiadamente
- [ ] Observar rolling update en tiempo real con --watch

**Rollback (Sección 4)**:
- [ ] Ver historial de revisiones
- [ ] Hacer rollback a versión anterior o específica
- [ ] Pausar/reanudar rolling updates
- [ ] Troubleshoot rollouts bloqueados

**Estrategias (Sección 5)**:
- [ ] Implementar Blue-Green deployment
- [ ] Implementar Canary deployment
- [ ] Elegir estrategia apropiada según caso de uso

**Best Practices (Sección 6)**:
- [ ] Aplicar naming conventions
- [ ] Definir resources apropiadamente
- [ ] Configurar health checks (liveness + readiness)
- [ ] Implementar security contexts
- [ ] Evitar anti-patterns comunes

**Troubleshooting (Sección 7)**:
- [ ] Diagnosticar problemas comunes (ImagePullBackOff, CrashLoopBackOff, Pending)
- [ ] Usar comandos de debugging efectivamente
- [ ] Configurar monitoreo y alertas

---

## 📚 Recursos del Módulo

### **Ejemplos Disponibles**

```
ejemplos/
├── 01-basico/
│   ├── 01-deployment-simple.yaml          # Deployment básico
│   └── 02-deployment-production.yaml      # Production-ready
├── 02-rolling-updates/
│   ├── 01-rolling-update-demo.yaml        # Demo de rolling update
│   └── 02-max-surge-unavailable.yaml      # Configuración maxSurge/maxUnavailable
├── 03-rollback/
│   ├── 01-rollback-demo.yaml              # Demo de rollback
│   └── 02-pause-resume.yaml               # Pause/resume
├── 04-estrategias/
│   ├── 01-blue-deployment.yaml            # Blue-Green: Blue
│   ├── 02-green-deployment.yaml           # Blue-Green: Green
│   ├── 03-service.yaml                    # Blue-Green: Service
│   ├── 04-stable-deployment.yaml          # Canary: Stable
│   ├── 05-canary-deployment.yaml          # Canary: Canary
│   └── 06-service-canary.yaml             # Canary: Service
└── 05-best-practices/
    └── production-template.yaml           # Template completo
```

### **Laboratorios Disponibles**

```
laboratorios/
├── lab-01-introduccion-deployments.md     # 30 min
├── lab-02-gestion-deployments.md          # 35 min
├── lab-03-rolling-updates.md              # 45 min
├── lab-04-rollback-versiones.md           # 40 min
├── lab-05-estrategias-avanzadas.md        # 60 min
├── lab-06-best-practices.md               # 50 min
├── lab-07-troubleshooting.md              # 45 min
└── lab-08-proyecto-integrador.md          # 90 min (FINAL)
```

**Tiempo total de laboratorios**: ~6 horas prácticas

---

## 🎓 Certificación de Conocimientos

**Has completado exitosamente el Módulo 07** si puedes:

1. ✅ Crear y gestionar Deployments con kubectl
2. ✅ Configurar rolling updates con zero downtime (maxUnavailable: 0)
3. ✅ Hacer rollback a versiones anteriores
4. ✅ Implementar estrategias avanzadas (Blue-Green, Canary)
5. ✅ Aplicar best practices de producción
6. ✅ Troubleshoot problemas comunes de Deployments
7. ✅ Configurar health checks y security contexts
8. ✅ Diseñar Deployments production-ready siguiendo el template

**Tiempo de dominio estimado**: 4-5 horas de estudio + 6 horas de labs = **10-11 horas totales**

---

### **📖 Continúa tu aprendizaje**

➡️ **Siguiente módulo**: [Módulo 08 - Services y Endpoints](../modulo-08-services-endpoints/README.md)

💬 **¿Dudas o feedback?**: Consulta con tu instructor o en los canales de Slack del curso.

🎉 **¡Felicitaciones por completar este módulo!**

---

**Última actualización**: 2024  
**Versión del documento**: 2.0  
**Autor**: Curso Kubernetes Completo

## Resumen del Capítulo

Este capítulo cubrió los conceptos fundamentales de deployments y rollouts, desde la teoría hasta la práctica con ejemplos y manifiestos YAML aplicables en entornos reales. Los laboratorios en el directorio `laboratorios/` permiten practicar cada concepto, y el `RESUMEN-MODULO.md` sirve como guía de repaso rápido.
