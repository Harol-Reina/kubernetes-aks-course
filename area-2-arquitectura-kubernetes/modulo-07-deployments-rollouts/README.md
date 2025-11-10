# 🚀 Módulo 07: Deployments y Rolling Updates

**Duración**: 120 minutos  
**Modalidad**: Práctico-Intensivo  
**Dificultad**: Intermedio-Avanzado  
**Versión Kubernetes**: 1.28+ (Noviembre 2025)

## 🎯 Objetivos del Módulo

Al completar este módulo serás capaz de:

- ✅ **Comprender Deployments** y su arquitectura en Kubernetes
- ✅ **Crear y gestionar Deployments** usando manifiestos YAML
- ✅ **Implementar Rolling Updates** sin downtime
- ✅ **Realizar Rollbacks** a versiones anteriores
- ✅ **Configurar estrategias de despliegue** (RollingUpdate, Recreate)
- ✅ **Gestionar historial de revisiones** y change causes
- ✅ **Aplicar best practices** para despliegues en producción

---

## 📋 Tabla de Contenidos

1. [Prerequisitos](#-1-prerequisitos)
2. [¿Qué es un Deployment?](#-2-qué-es-un-deployment)
3. [Arquitectura de Deployments](#-3-arquitectura-de-deployments)
4. [Creación de Deployments](#-4-creación-de-deployments)
5. [Rolling Updates](#-5-rolling-updates)
6. [Estrategias de Despliegue](#-6-estrategias-de-despliegue)
7. [Rollback y Gestión de Versiones](#-7-rollback-y-gestión-de-versiones)
8. [Historial y Change Causes](#-8-historial-y-change-causes)
9. [Pausar y Reanudar Deployments](#-9-pausar-y-reanudar-deployments)
10. [Mejores Prácticas](#-10-mejores-prácticas)
11. [Ejemplos y Laboratorios](#-ejemplos-y-laboratorios-prácticos)
12. [Recursos Adicionales](#-11-recursos-adicionales)

---

## 🔧 1. Prerequisitos

### **1.1 Verificar Cluster**

```bash
# Verificar minikube
minikube status

# Verificar conexión
kubectl cluster-info

# Limpiar recursos previos del módulo 06
kubectl delete rs --all
kubectl delete pods --all
```

### **1.2 Conceptos Previos Requeridos**

Debes dominar:
- ✅ **Pods** - Creación y gestión (Módulo 05)
- ✅ **ReplicaSets** - Auto-recuperación y escalado (Módulo 06)
- ✅ **Labels y Selectors** - Filtrado y selección
- ✅ **Limitaciones de ReplicaSets** - Por qué no actualizan Pods

### **1.3 ¿Por Qué Deployments?**

**Problema con ReplicaSets**:
```yaml
# ReplicaSet con nginx:1.20
spec:
  template:
    spec:
      containers:
      - image: nginx:1.20-alpine

# ❌ Si cambias a nginx:1.21 y aplicas:
# - ReplicaSet se actualiza ✅
# - Pods NO se actualizan ❌
# - Tienes que eliminar Pods manualmente ❌
```

**Solución: Deployments**
```yaml
# Deployment con nginx:1.20
spec:
  template:
    spec:
      containers:
      - image: nginx:1.20-alpine

# ✅ Si cambias a nginx:1.21 y aplicas:
# - Deployment se actualiza ✅
# - Rolling update automático ✅
# - Zero downtime ✅
# - Rollback disponible ✅
```

---

## 🔍 2. ¿Qué es un Deployment?

### **2.1 Definición**

Un **Deployment** es un controlador de Kubernetes que:
- Gestiona ReplicaSets automáticamente
- Proporciona actualizaciones declarativas para Pods
- Implementa Rolling Updates sin downtime
- Permite Rollback a versiones anteriores
- Mantiene historial de revisiones
- Escala horizontal automáticamente

### **2.2 Deployment vs ReplicaSet**

```
┌─────────────────────────────────────────────────────────────┐
│              DEPLOYMENT vs REPLICASET                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🟡 REPLICASET (Nivel Medio)                                │
│  ├─ Mantiene N réplicas de Pods                            │
│  ├─ Auto-recuperación                                      │
│  ├─ Escalado horizontal                                    │
│  ├─ ❌ NO actualiza Pods existentes                        │
│  ├─ ❌ NO rolling updates                                  │
│  ├─ ❌ NO rollback                                         │
│  └─ Ideal para: Testing, aprendizaje                       │
│                                                             │
│  🟢 DEPLOYMENT (Nivel Alto - PRODUCCIÓN)                    │
│  ├─ Gestiona ReplicaSets automáticamente                   │
│  ├─ Auto-recuperación (vía ReplicaSets)                    │
│  ├─ Escalado horizontal                                    │
│  ├─ ✅ Rolling updates automáticos                         │
│  ├─ ✅ Rollback a cualquier revisión                       │
│  ├─ ✅ Historial de versiones                              │
│  ├─ ✅ Estrategias de despliegue                           │
│  ├─ ✅ Pausar/Reanudar updates                             │
│  └─ Ideal para: **PRODUCCIÓN**                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### **2.3 Cuándo Usar Deployments**

| Escenario | ReplicaSet | Deployment |
|-----------|------------|------------|
| Aplicación stateless (web, API) | ❌ | ✅ |
| Necesitas actualizar versiones | ❌ | ✅ |
| Requieres zero downtime | ❌ | ✅ |
| Producción | ❌ | ✅ |
| Testing/Learning | ✅ | ✅ |
| Aplicación stateful | ❌ | ❌ (usa StatefulSet) |

**Regla de oro**: 🔑 **Siempre usa Deployments para aplicaciones stateless en producción**

---

## 🏗️ 3. Arquitectura de Deployments

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
    kind: Deployment        # ← Dueño
    name: my-deployment
    uid: abc-123-def        # ← Mismo UID

---
# Pod (creado por ReplicaSet)
metadata:
  name: my-deployment-5d7f8c9b-xyz12
  ownerReferences:
  - apiVersion: apps/v1
    kind: ReplicaSet        # ← Dueño inmediato
    name: my-deployment-5d7f8c9b
```

**Cadena de propiedad**:
```
Deployment → ReplicaSet → Pod
   (abuelo)    (padre)    (hijo)
```

---

## 🚀 4. Creación de Deployments

### **4.1 Estructura Básica**

📄 **Ver ejemplo**: [`ejemplos/01-basico/deployment-simple.yaml`](./ejemplos/01-basico/deployment-simple.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment         # ← Tipo: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3            # ← Número de Pods deseados
  
  # Selector: qué Pods gestiona
  selector:
    matchLabels:
      app: nginx
  
  # Template: plantilla de Pod
  template:
    metadata:
      labels:
        app: nginx       # ← DEBE coincidir con selector
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
```

### **4.2 Crear Deployment**

```bash
# Crear desde archivo
kubectl apply -f ejemplos/01-basico/deployment-simple.yaml

# Verificar creación
kubectl get deployments
# o forma corta:
kubectl get deploy

# Ver ReplicaSets creados automáticamente
kubectl get rs

# Ver Pods
kubectl get pods
```

**Salida esperada**:
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           30s

NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-5d7f8c9b     3         3         3       30s

NAME                          READY   STATUS    RESTARTS   AGE
nginx-deployment-5d7f8c9b-a   1/1     Running   0          30s
nginx-deployment-5d7f8c9b-b   1/1     Running   0          30s
nginx-deployment-5d7f8c9b-c   1/1     Running   0          30s
```

### **4.3 Inspeccionar Deployment**

```bash
# Ver detalles completos
kubectl describe deploy nginx-deployment

# Ver manifiesto en YAML
kubectl get deploy nginx-deployment -o yaml

# Ver estado de rollout
kubectl rollout status deployment nginx-deployment
```

### **4.4 Crear Deployment Imperativo**

```bash
# Crear Deployment rápido
kubectl create deployment webapp --image=nginx:alpine --replicas=3

# Con dry-run para generar YAML
kubectl create deployment webapp --image=nginx:alpine --replicas=3 \
  --dry-run=client -o yaml > deployment.yaml
```

---

## 🔄 5. Rolling Updates

### **5.1 ¿Qué es un Rolling Update?**

**Rolling Update** = Actualización gradual sin downtime

**Proceso**:
1. Deployment crea nuevo ReplicaSet (versión nueva)
2. Escala nuevo ReplicaSet UP (crea Pods nuevos)
3. Escala viejo ReplicaSet DOWN (elimina Pods viejos)
4. Repite hasta completar
5. Viejo ReplicaSet queda en 0 (historial)

### **5.2 Parámetros de Control**

📄 **Ver ejemplo**: [`ejemplos/02-rolling-updates/deployment-rolling-params.yaml`](./ejemplos/02-rolling-updates/deployment-rolling-params.yaml)

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1    # ← Máx Pods down simultáneamente
      maxSurge: 1          # ← Máx Pods extra durante update
```

**Explicación**:

| Parámetro | Descripción | Valor | Efecto |
|-----------|-------------|-------|--------|
| `maxUnavailable` | Máx Pods que pueden estar down | `25%` o `1` | Garantiza disponibilidad mínima |
| `maxSurge` | Máx Pods adicionales durante update | `25%` o `1` | Controla uso de recursos |

**Ejemplo con 4 réplicas**:
```
maxUnavailable: 1, maxSurge: 1

Inicial:  [v1] [v1] [v1] [v1]           = 4 Pods v1

Step 1:   [v1] [v1] [v1] [v1] [v2]      = 5 Pods (surge +1)
Step 2:   [v1] [v1] [v1] [v2]           = 4 Pods (down -1)
Step 3:   [v1] [v1] [v1] [v2] [v2]      = 5 Pods (surge +1)
Step 4:   [v1] [v1] [v2] [v2]           = 4 Pods (down -1)
Step 5:   [v1] [v1] [v2] [v2] [v2]      = 5 Pods (surge +1)
Step 6:   [v1] [v2] [v2] [v2]           = 4 Pods (down -1)
Step 7:   [v1] [v2] [v2] [v2] [v2]      = 5 Pods (surge +1)
Step 8:   [v2] [v2] [v2] [v2]           = 4 Pods v2 (completo)
```

### **5.3 Ejecutar Rolling Update**

**Método 1: Editar manifiesto**
```bash
# Editar deployment.yaml
# Cambiar: image: nginx:1.22-alpine

# Aplicar
kubectl apply -f deployment.yaml

# Observar en tiempo real
kubectl rollout status deployment nginx-deployment
```

**Método 2: Comando imperativo**
```bash
# Actualizar imagen directamente
kubectl set image deployment/nginx-deployment \
  nginx=nginx:1.22-alpine

# Observar rollout
kubectl rollout status deployment nginx-deployment
```

**Método 3: Editar en vivo**
```bash
# Editar Deployment directamente en cluster
kubectl edit deployment nginx-deployment
# Cambiar image, guardar (:wq)

# Ver progreso
kubectl rollout status deployment nginx-deployment
```

### **5.4 Monitorear Rolling Update**

```bash
# Ver estado en tiempo real
kubectl rollout status deployment nginx-deployment

# Ver Pods durante update
kubectl get pods --watch

# Ver ReplicaSets
kubectl get rs

# Ver eventos
kubectl describe deployment nginx-deployment
```

**Durante el update verás**:
```
NAME                          READY   STATUS              RESTARTS   AGE
nginx-deployment-5d7f8c9b-a   1/1     Running             0          5m
nginx-deployment-5d7f8c9b-b   1/1     Running             0          5m
nginx-deployment-5d7f8c9b-c   1/1     Running             0          5m
nginx-deployment-7f9d8e6a-x   0/1     ContainerCreating   0          2s  ← NUEVO
nginx-deployment-7f9d8e6a-x   1/1     Running             0          5s  ← LISTO
nginx-deployment-5d7f8c9b-a   1/1     Terminating         0          5m  ← VIEJO sale
nginx-deployment-7f9d8e6a-y   0/1     ContainerCreating   0          1s  ← NUEVO
...
```

---

## 🎯 6. Estrategias de Despliegue

### **6.1 Estrategia: RollingUpdate (Default)**

📄 **Ver ejemplo**: [`ejemplos/03-estrategias/deployment-rolling-update.yaml`](./ejemplos/03-estrategias/deployment-rolling-update.yaml)

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
```

**Características**:
- ✅ Zero downtime
- ✅ Actualización gradual
- ✅ Rollback fácil
- ✅ **Recomendado para producción**

**Uso**:
- Aplicaciones web
- APIs
- Microservicios
- Cualquier app stateless

### **6.2 Estrategia: Recreate**

📄 **Ver ejemplo**: [`ejemplos/03-estrategias/deployment-recreate.yaml`](./ejemplos/03-estrategias/deployment-recreate.yaml)

```yaml
spec:
  strategy:
    type: Recreate
```

**Características**:
- ❌ Downtime (todos los Pods down primero)
- ✅ Garantiza que NO hay 2 versiones simultáneas
- ✅ Útil para migraciones de DB

**Proceso**:
```
Inicial:  [v1] [v1] [v1]

Step 1:   (elimina todos)
          [ ] [ ] [ ]      ← DOWNTIME

Step 2:   [v2] [v2] [v2]  ← Crea todos nuevos
```

**Uso**:
- Migraciones de base de datos
- Cuando 2 versiones no pueden coexistir
- Aplicaciones que requieren downtime

### **6.3 Comparación de Estrategias**

| Característica | RollingUpdate | Recreate |
|----------------|---------------|----------|
| **Downtime** | ❌ No | ✅ Sí |
| **Velocidad** | Gradual | Rápida |
| **Coexistencia de versiones** | ✅ Sí (temporal) | ❌ No |
| **Uso de recursos** | Más (surge) | Menos |
| **Complejidad** | Mayor | Menor |
| **Uso típico** | **Producción** | Migraciones |

---

## ⏮️ 7. Rollback y Gestión de Versiones

### **7.1 Historial de Revisiones**

```bash
# Ver historial de deployments
kubectl rollout history deployment nginx-deployment

# Salida:
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         kubectl set image deployment/nginx nginx=nginx:1.22
# 3         kubectl apply --filename=deployment.yaml
```

### **7.2 Ver Detalles de una Revisión**

```bash
# Ver configuración de revisión específica
kubectl rollout history deployment nginx-deployment --revision=2

# Salida muestra:
# - Imagen usada
# - Configuración de contenedores
# - Recursos
# - etc.
```

### **7.3 Rollback a Revisión Anterior**

```bash
# Rollback a revisión inmediatamente anterior
kubectl rollout undo deployment nginx-deployment

# Ver estado
kubectl rollout status deployment nginx-deployment
```

### **7.4 Rollback a Revisión Específica**

```bash
# Rollback a revisión número 2
kubectl rollout undo deployment nginx-deployment --to-revision=2

# Verificar
kubectl rollout history deployment nginx-deployment
kubectl get pods -o jsonpath='{.items[0].spec.containers[0].image}'
```

### **7.5 Historial de Revisiones (Límite)**

📄 **Ver ejemplo**: [`ejemplos/04-rollback/deployment-revision-history.yaml`](./ejemplos/04-rollback/deployment-revision-history.yaml)

```yaml
spec:
  # Mantener solo 5 revisiones (default: 10)
  revisionHistoryLimit: 5
```

**Por defecto**: Kubernetes mantiene **10 revisiones**

```bash
# Ver ReplicaSets históricos
kubectl get rs

# Salida:
# NAME                    DESIRED   CURRENT   READY   AGE
# nginx-deployment-v1     0         0         0       10m  ← Histórico
# nginx-deployment-v2     0         0         0       8m   ← Histórico
# nginx-deployment-v3     3         3         3       2m   ← ACTIVO
```

---

## 📝 8. Historial y Change Causes

### **8.1 Problema: Change Cause Vacío**

```bash
kubectl rollout history deployment nginx-deployment

# REVISION  CHANGE-CAUSE
# 1         <none>        ← ❌ No sabemos qué cambió
# 2         <none>        ← ❌ No sabemos qué cambió
```

### **8.2 Solución 1: Flag --record (Deprecado)**

⚠️ **DEPRECADO en Kubernetes 1.28+** - No usar

```bash
# NO USAR - Deprecado
kubectl apply -f deployment.yaml --record
```

### **8.3 Solución 2: Anotación kubernetes.io/change-cause**

📄 **Ver ejemplo**: [`ejemplos/05-change-cause/deployment-annotated.yaml`](./ejemplos/05-change-cause/deployment-annotated.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  annotations:
    kubernetes.io/change-cause: "Actualizar nginx a 1.22-alpine"
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.22-alpine
```

```bash
# Aplicar
kubectl apply -f deployment.yaml

# Ver historial
kubectl rollout history deployment nginx-deployment

# REVISION  CHANGE-CAUSE
# 1         Actualizar nginx a 1.22-alpine  ← ✅ Descriptivo
```

### **8.4 Solución 3: Comando kubectl annotate**

```bash
# Añadir anotación imperativa
kubectl annotate deployment nginx-deployment \
  kubernetes.io/change-cause="Cambiar puerto a 8080"

# Aplicar cambios
kubectl apply -f deployment.yaml

# Ver historial
kubectl rollout history deployment nginx-deployment
```

### **8.5 Best Practice: Change Cause**

```yaml
# ✅ SIEMPRE incluir change-cause
metadata:
  annotations:
    kubernetes.io/change-cause: "v1.0.5 - Fix security vulnerability CVE-2024-1234"

# Formato recomendado:
# - Versión semántica
# - Descripción breve del cambio
# - Issue/Ticket ID si aplica
```

---

## ⏸️ 9. Pausar y Reanudar Deployments

### **9.1 ¿Por Qué Pausar?**

**Casos de uso**:
- Aplicar múltiples cambios en una sola actualización
- Testing de configuración antes de rollout
- Mantenimiento programado

### **9.2 Pausar Deployment**

```bash
# Pausar deployment
kubectl rollout pause deployment nginx-deployment

# Ahora puedes hacer múltiples cambios SIN que se apliquen
kubectl set image deployment/nginx-deployment nginx=nginx:1.23-alpine
kubectl set resources deployment/nginx-deployment -c nginx --limits=cpu=200m,memory=256Mi

# Verificar que NO se aplicaron
kubectl get pods  # Siguen con versión vieja
```

### **9.3 Reanudar Deployment**

```bash
# Reanudar - AHORA se aplican TODOS los cambios juntos
kubectl rollout resume deployment nginx-deployment

# Ver rollout
kubectl rollout status deployment nginx-deployment
```

### **9.4 Ejemplo Práctico**

📄 **Ver ejemplo**: [`ejemplos/06-pause-resume/deployment-multiple-changes.yaml`](./ejemplos/06-pause-resume/deployment-multiple-changes.yaml)

```bash
# 1. Pausar
kubectl rollout pause deployment nginx-deployment

# 2. Cambiar imagen
kubectl set image deployment/nginx-deployment nginx=nginx:1.23-alpine

# 3. Cambiar recursos
kubectl set resources deployment/nginx-deployment -c nginx \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=200m,memory=256Mi

# 4. Cambiar réplicas
kubectl scale deployment nginx-deployment --replicas=5

# 5. Reanudar - TODO se aplica en UN solo rollout
kubectl rollout resume deployment nginx-deployment
```

---

## ✅ 10. Mejores Prácticas

### **10.1 Configuración de Deployment**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-app
  labels:
    app: production
    version: "v1.0"
  annotations:
    kubernetes.io/change-cause: "v1.0.0 - Initial production release"
spec:
  replicas: 3
  
  # ✅ Estrategia de update
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1      # Nunca más de 1 Pod down
      maxSurge: 1            # Permite 1 Pod extra
  
  # ✅ Historial razonable
  revisionHistoryLimit: 10    # Mantener 10 revisiones
  
  # ✅ Timeout para updates
  progressDeadlineSeconds: 600  # 10 minutos máximo
  
  selector:
    matchLabels:
      app: production
  
  template:
    metadata:
      labels:
        app: production
        version: "v1.0"
    spec:
      containers:
      - name: app
        image: myapp:v1.0.0    # ✅ Tag específico (NO :latest)
        
        ports:
        - containerPort: 8080
        
        # ✅ Resources definidos
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        
        # ✅ Liveness probe
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # ✅ Readiness probe
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # ✅ Lifecycle hooks
        lifecycle:
          preStop:
            exec:
              command:
              - sh
              - -c
              - sleep 15  # Grace period para terminar conexiones
```

### **10.2 Versionado de Imágenes**

```yaml
# ❌ MAL - Tag mutable
containers:
- image: nginx:latest       # Puede cambiar sin aviso

# ❌ MAL - Sin tag
containers:
- image: nginx              # Usa :latest implícitamente

# ✅ BIEN - Tag específico
containers:
- image: nginx:1.21-alpine  # Versión fija

# ✅ MEJOR - Digest SHA256
containers:
- image: nginx@sha256:abc123...  # Inmutable
```

### **10.3 Estrategia de Rollout**

```yaml
# ✅ Producción - Alta disponibilidad
rollingUpdate:
  maxUnavailable: 0    # NUNCA bajar pods
  maxSurge: 1          # Crear nuevos primero

# ✅ Staging - Balanceado
rollingUpdate:
  maxUnavailable: 1
  maxSurge: 1

# ✅ Dev - Rápido
rollingUpdate:
  maxUnavailable: 50%
  maxSurge: 50%
```

### **10.4 Health Checks Críticos**

```yaml
# ✅ Liveness: Detectar app rota
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30     # Esperar startup
  periodSeconds: 10
  failureThreshold: 3         # 3 fallos = restart

# ✅ Readiness: Detectar app no lista
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3         # 3 fallos = sacar del Service
```

### **10.5 Checklist Pre-Producción**

- [ ] ✅ Tag de imagen específico (no `:latest`)
- [ ] ✅ Resources requests/limits definidos
- [ ] ✅ Liveness probe configurado
- [ ] ✅ Readiness probe configurado
- [ ] ✅ `maxUnavailable: 0` para alta disponibilidad
- [ ] ✅ Change-cause annotation incluida
- [ ] ✅ `revisionHistoryLimit` apropiado (5-10)
- [ ] ✅ Labels y selectors correctos
- [ ] ✅ Namespace apropiado
- [ ] ✅ Security context configurado

---

## 🧪 Ejemplos y Laboratorios Prácticos

### **📁 Ejemplos YAML Disponibles**

Todos los ejemplos en [`ejemplos/`](./ejemplos/):

#### **01-basico/** - Fundamentos
| Archivo | Descripción | Conceptos |
|---------|-------------|-----------|
| `deployment-simple.yaml` | Deployment básico 3 réplicas | Estructura básica |
| `deployment-multi-container.yaml` | Multi-container | Sidecar pattern |

#### **02-rolling-updates/** - Actualizaciones
| Archivo | Descripción | Demuestra |
|---------|-------------|-----------|
| `deployment-rolling-params.yaml` | Control de rolling update | maxSurge, maxUnavailable |
| `deployment-update-demo.yaml` | Demo paso a paso | Proceso completo |

#### **03-estrategias/** - Estrategias de Despliegue
| Archivo | Descripción | Estrategia |
|---------|-------------|------------|
| `deployment-rolling-update.yaml` | RollingUpdate | Zero downtime |
| `deployment-recreate.yaml` | Recreate | Con downtime |

#### **04-rollback/** - Rollback y Versiones
| Archivo | Descripción | Demuestra |
|---------|-------------|-----------|
| `deployment-revision-history.yaml` | Gestión de historial | revisionHistoryLimit |
| `deployment-rollback-demo.yaml` | Demo de rollback | Volver a v anterior |

#### **05-change-cause/** - Anotaciones
| Archivo | Descripción | Tema |
|---------|-------------|------|
| `deployment-annotated.yaml` | Con change-cause | Historial descriptivo |

#### **06-pause-resume/** - Control Avanzado
| Archivo | Descripción | Uso |
|---------|-------------|-----|
| `deployment-multiple-changes.yaml` | Múltiples cambios | Pause/Resume |

#### **07-produccion/** - Production-Ready
| Archivo | Descripción | Features |
|---------|-------------|----------|
| `deployment-production-ready.yaml` | Configuración completa | All best practices |

**Ver guía completa**: [`ejemplos/README.md`](./ejemplos/README.md)

---

### **🎓 Laboratorios Hands-On**

| # | Laboratorio | Duración | Nivel | Temas |
|---|-------------|----------|-------|-------|
| 1 | [Crear y Gestionar Deployments](./laboratorios/lab-01-crear-deployments.md) | 40 min | Básico | Crear, inspeccionar, escalar |
| 2 | [Rolling Updates y Estrategias](./laboratorios/lab-02-rolling-updates.md) | 50 min | Intermedio | Updates, estrategias, monitoring |
| 3 | [Rollback y Gestión de Versiones](./laboratorios/lab-03-rollback-versiones.md) | 60 min | Avanzado | Rollback, historial, production |

---

## 📚 11. Recursos Adicionales

### **11.1 Comandos de Referencia Rápida**

```bash
# CREAR
kubectl create deployment nginx --image=nginx:alpine --replicas=3
kubectl apply -f deployment.yaml

# LISTAR
kubectl get deployments
kubectl get deploy -o wide
kubectl get rs  # Ver ReplicaSets

# INSPECCIONAR
kubectl describe deploy nginx-deployment
kubectl get deploy nginx-deployment -o yaml

# ACTUALIZAR
kubectl set image deployment/nginx nginx=nginx:1.22-alpine
kubectl edit deployment nginx
kubectl apply -f deployment.yaml

# ESCALAR
kubectl scale deployment nginx --replicas=5
kubectl autoscale deployment nginx --min=2 --max=10 --cpu-percent=80

# ROLLOUT
kubectl rollout status deployment nginx
kubectl rollout history deployment nginx
kubectl rollout history deployment nginx --revision=2
kubectl rollout undo deployment nginx
kubectl rollout undo deployment nginx --to-revision=2
kubectl rollout pause deployment nginx
kubectl rollout resume deployment nginx
kubectl rollout restart deployment nginx  # Restart todos los Pods

# ELIMINAR
kubectl delete deployment nginx
```

### **11.2 Troubleshooting**

```bash
# Ver eventos del Deployment
kubectl describe deployment nginx

# Ver estado de rollout
kubectl rollout status deployment nginx

# Ver Pods con problemas
kubectl get pods | grep -v Running

# Logs de Pods
kubectl logs -l app=nginx --all-containers --tail=100

# Ver ReplicaSets
kubectl get rs -l app=nginx

# Ver qué imagen están usando los Pods
kubectl get pods -o jsonpath='{.items[*].spec.containers[0].image}'
```

### **11.3 Recursos de Aprendizaje**

- 📖 [Documentación oficial - Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- 📖 [Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- 📖 [Deployments en pabpereza.dev](https://pabpereza.dev/docs/cursos/kubernetes/deployments_en_kubernetes_rolling_updates_y_gestion_de_aplicaciones)
- 🎥 [Kubernetes Deployment Strategies](https://kubernetes.io/blog/)

### **11.4 Próximos Pasos**

En el **Módulo 08: Services y Networking**, aprenderás:
- ✅ Exponer Deployments con Services
- ✅ ClusterIP, NodePort, LoadBalancer
- ✅ Ingress Controllers
- ✅ Network Policies

---

## 🎓 Resumen del Módulo

Has aprendido:

✅ **Qué son los Deployments** y su arquitectura  
✅ **Crear y gestionar Deployments** con YAML  
✅ **Rolling Updates automáticos** sin downtime  
✅ **Estrategias de despliegue** (RollingUpdate, Recreate)  
✅ **Rollback** a versiones anteriores  
✅ **Gestión de historial** y change causes  
✅ **Pausar/Reanudar** deployments  
✅ **Best practices** para producción  

**Puntos clave**:
- 🔑 **Deployments gestionan ReplicaSets** automáticamente
- 🔑 **Rolling updates** = zero downtime
- 🔑 **Rollback** fácil a cualquier revisión
- 🔑 **Change-cause** mantiene historial descriptivo
- 🔑 En producción: **siempre Deployments**, nunca ReplicaSets directos

---

**📅 Fecha de actualización**: Noviembre 2025  
**🔖 Versión**: 1.0  
**👨‍💻 Autor**: Curso Kubernetes AKS

---

**⬅️ Anterior**: [Módulo 06 - ReplicaSets y Réplicas](../modulo-06-replicasets-replicas/README.md)  
**➡️ Siguiente**: [Módulo 08 - Services y Networking](../modulo-08-services/README.md)
