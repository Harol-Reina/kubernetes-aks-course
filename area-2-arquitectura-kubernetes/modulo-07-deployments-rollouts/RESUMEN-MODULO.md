# 📖 Resumen del Módulo 07: Deployments y Rolling Updates

> **Guía de Estudio Estructurada para Dominar Deployments en Kubernetes**

---

## 🎯 Visión General del Módulo

### **¿Qué aprenderás?**

Este módulo te enseña a gestionar aplicaciones en Kubernetes usando **Deployments**, el controlador más importante para aplicaciones stateless. Aprenderás a:

- Desplegar aplicaciones con **zero downtime** usando rolling updates
- Hacer **rollback** a versiones anteriores cuando algo sale mal
- Implementar estrategias avanzadas: **Blue-Green** y **Canary**
- Aplicar **best practices** de producción (resources, health checks, security)
- **Troubleshoot** problemas comunes de deployments

### **Tiempo de Estudio**

| Fase | Duración | Tipo |
|------|----------|------|
| **Teoría** | 4-5 horas | Lectura + comprensión |
| **Práctica (Labs)** | 6 horas | Hands-on exercises |
| **Proyecto Final** | 1.5 horas | Integración completa |
| **Total** | **11-12.5 horas** | Dominio completo |

---

## 📚 Guía de Estudio Recomendada (5 Fases)

### **Fase 1: Fundamentos (Día 1 - 2 horas)**

#### **Sección del README**: 1. ¿Qué es un Deployment?

#### **Objetivos de Aprendizaje**:
- [ ] Comprender por qué ReplicaSets solos NO son suficientes
- [ ] Entender cómo Deployments resuelven el problema de actualizaciones
- [ ] Explicar la arquitectura: Deployment → ReplicaSet → Pod
- [ ] Identificar cuándo usar Deployment vs ReplicaSet vs StatefulSet

#### **Conceptos Clave**:

**1. El Problema sin Deployments**:
```yaml
# ReplicaSet v1 con nginx:1.20
# ❌ Para actualizar a nginx:1.21:
# - Manualmente eliminar Pods uno por uno
# - Riesgo de downtime
# - Proceso manual y propenso a errores
```

**2. La Solución: Deployments**:
```yaml
# Deployment gestiona automáticamente:
# ✅ Crea nuevo ReplicaSet (v2)
# ✅ Escala gradualmente: v1 DOWN, v2 UP
# ✅ Zero downtime
# ✅ Rollback automático si falla
```

**3. Arquitectura**:
```
Deployment (especifica estado deseado)
    ↓ gestiona
ReplicaSet v1 (0 réplicas)    ReplicaSet v2 (3 réplicas) ← ACTIVO
    ↓ gestiona                      ↓ gestiona
Pods v1 (históricos)          Pods v2 (actuales)
```

**4. Diferencia clave**:
- **ReplicaSet**: Mantiene N réplicas idénticas (versión fija)
- **Deployment**: Gestiona MÚLTIPLES ReplicaSets (versiones diferentes)

#### **Actividades**:
1. ✅ Leer sección 1 completa del README
2. ✅ Hacer **Checkpoint 01** (autoevaluación)
3. ✅ Completar **Lab 01** (30 min): Crear primer Deployment
4. ✅ Dibujar diagrama: Deployment → RS → Pods

#### **Comandos Esenciales**:
```bash
# Ver Deployments
kubectl get deployments
kubectl describe deployment <name>

# Ver jerarquía completa
kubectl get deploy,rs,pods -l app=webapp

# Ver owner references
kubectl get pod <pod-name> -o yaml | grep -A 5 ownerReferences
```

---

### **Fase 2: Gestión Básica (Día 2 - 2.5 horas)**

#### **Sección del README**: 2. Creación y Gestión de Deployments

#### **Objetivos de Aprendizaje**:
- [ ] Crear Deployments desde manifiestos YAML
- [ ] Dominar comandos kubectl para Deployments
- [ ] Inspeccionar estado, condiciones y eventos
- [ ] Escalar Deployments horizontalmente
- [ ] Entender campos obligatorios vs opcionales

#### **Conceptos Clave**:

**1. Anatomía del Manifiesto**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  annotations:
    kubernetes.io/change-cause: "Initial v1.0"
spec:
  replicas: 3                    # Cuántos Pods
  selector:                      # DEBE coincidir con template.labels
    matchLabels:
      app: webapp
  strategy:                      # Cómo actualizar
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:                      # Blueprint del Pod
    metadata:
      labels:
        app: webapp              # DEBE coincidir con selector
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /
            port: 80
```

**2. Campos Críticos**:
- `spec.selector`: **DEBE** coincidir con `template.metadata.labels`
- `spec.replicas`: Default = 1 (siempre poner ≥3 en producción)
- `spec.strategy`: Default = RollingUpdate
- `spec.revisionHistoryLimit`: Default = 10 (cuántos ReplicaSets históricos)

**3. Comandos CRUD**:
```bash
# CREATE
kubectl apply -f deployment.yaml

# READ
kubectl get deploy webapp
kubectl get deploy webapp -o yaml
kubectl describe deploy webapp

# UPDATE
kubectl set image deploy/webapp nginx=nginx:1.21
kubectl edit deploy webapp

# DELETE
kubectl delete deploy webapp
```

**4. Inspección Avanzada**:
```bash
# Ver ReplicaSets gestionados
kubectl get rs -l app=webapp

# Ver Pods gestionados
kubectl get pods -l app=webapp

# Ver condiciones
kubectl get deploy webapp -o jsonpath='{.status.conditions[*].type}'
# Output: Available Progressing

# Ver eventos
kubectl get events --field-selector involvedObject.kind=Deployment
```

#### **Actividades**:
1. ✅ Leer sección 2 completa del README
2. ✅ Crear Deployment simple (3 réplicas)
3. ✅ Crear Deployment production-ready (con resources, probes, anti-affinity)
4. ✅ Hacer **Checkpoint 02**
5. ✅ Completar **Lab 02** (35 min): Gestión con kubectl

#### **Ejercicios Prácticos**:
```bash
# Ejercicio 1: Crear y escalar
kubectl create deployment webapp --image=nginx:alpine --replicas=3
kubectl scale deployment webapp --replicas=5
kubectl get pods -w  # Observar creación

# Ejercicio 2: Inspeccionar jerarquía
kubectl get rs -l app=webapp
kubectl describe rs <replicaset-name>

# Ejercicio 3: Ver estado
kubectl get deploy webapp -o jsonpath='{.status.replicas}'
kubectl get deploy webapp -o jsonpath='{.status.availableReplicas}'
```

---

### **Fase 3: Rolling Updates y Rollback (Día 3 - 3 horas)**

#### **Secciones del README**: 3. Rolling Updates + 4. Rollback y Versiones

#### **Objetivos de Aprendizaje**:
- [ ] Entender el flujo completo de rolling update
- [ ] Configurar maxSurge y maxUnavailable apropiadamente
- [ ] Hacer rollback a versiones anteriores
- [ ] Ver historial de revisiones
- [ ] Pausar/reanudar deployments
- [ ] Troubleshoot rollouts bloqueados

#### **Conceptos Clave**:

**1. Rolling Update Flow**:
```
ESTADO INICIAL: 3 Pods v1.20 (ReplicaSet v1)
    ↓
Actualizar imagen a v1.21
    ↓
Kubernetes crea ReplicaSet v2 (0 réplicas)
    ↓
ITERACIÓN 1: v2 scale UP (1 Pod), v1 scale DOWN (1 Pod)
Estado: 2 Pods v1 + 1 Pod v2 = 3 total
    ↓
ITERACIÓN 2: v2 scale UP (1 Pod), v1 scale DOWN (1 Pod)
Estado: 1 Pod v1 + 2 Pods v2 = 3 total
    ↓
ITERACIÓN 3: v2 scale UP (1 Pod), v1 scale DOWN (0 Pods)
Estado: 0 Pods v1 + 3 Pods v2 = 3 total
    ↓
✅ UPDATE COMPLETADO: Solo ReplicaSet v2 activo
```

**2. Parámetros Críticos**:

```yaml
strategy:
  rollingUpdate:
    maxSurge: 1           # Máximo de Pods EXTRAS
    maxUnavailable: 0     # Máximo de Pods NO disponibles
```

**Cálculo**:
- `replicas: 5`, `maxSurge: 2`, `maxUnavailable: 0`
- Durante update: **Máximo 7 Pods** (5 + 2), **Mínimo 5 disponibles**

**Escenarios**:

| Escenario | maxSurge | maxUnavailable | Comportamiento |
|-----------|----------|----------------|----------------|
| **Production (zero downtime)** | 1-2 | 0 | Siempre N disponibles |
| **Dev (velocidad)** | 50% | 50% | Update rápido, puede tener downtime |
| **Recursos limitados** | 0 | 1 | Sin Pods extras, update lento |

**3. Rollback**:

```bash
# Ver historial
kubectl rollout history deploy/webapp
# REVISION  CHANGE-CAUSE
# 1         Initial v1.0
# 2         Update to v1.21
# 3         Update to v1.22 (BUGGY)

# Rollback a versión anterior
kubectl rollout undo deploy/webapp

# Rollback a revisión específica
kubectl rollout undo deploy/webapp --to-revision=2

# Ver progreso
kubectl rollout status deploy/webapp
```

**⚠️ Importante**: Rollback **crea nueva revisión** (no restaura número):
```
ANTES del rollback:
REVISION 1, 2, 3 (actual: v1.22 buggy)

DESPUÉS del rollback a revision 2:
REVISION 1, 3 (v1.22 buggy), 4 (v1.21 restaurado) ← Nueva revisión
```

**4. Troubleshooting: Rollout Bloqueado**:

| Problema | Síntoma | Comando de Diagnóstico | Solución |
|----------|---------|------------------------|----------|
| **ImagePullBackOff** | Pod no inicia | `kubectl describe pod` | Verificar nombre/tag imagen |
| **CrashLoopBackOff** | Pod reinicia continuamente | `kubectl logs <pod> --previous` | Ver logs, revisar health checks |
| **Pending** | Pod no se programa | `kubectl describe pod` | Verificar resources, node selector |
| **Readiness failing** | Pod Running pero 0/1 Ready | `kubectl describe pod` | Aumentar initialDelaySeconds |

#### **Actividades**:
1. ✅ Leer secciones 3 y 4 del README
2. ✅ Hacer rolling update con observación en tiempo real (`--watch`)
3. ✅ Simular fallo y hacer rollback
4. ✅ Practicar pause/resume
5. ✅ Hacer **Checkpoint 03** y **Checkpoint 04**
6. ✅ Completar **Lab 03** (45 min) y **Lab 04** (40 min)

#### **Ejercicios Prácticos**:

```bash
# Ejercicio 1: Rolling update con diferentes configuraciones
# Escenario A: Zero downtime (production)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-prod
spec:
  replicas: 5
  strategy:
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0
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
        image: nginx:1.20-alpine
EOF

# Actualizar y observar
kubectl set image deploy/webapp-prod nginx=nginx:1.21-alpine
kubectl get pods -l app=webapp --watch

# Ejercicio 2: Rollback
kubectl rollout history deploy/webapp-prod
kubectl rollout undo deploy/webapp-prod
kubectl rollout status deploy/webapp-prod

# Ejercicio 3: Pause/Resume
kubectl rollout pause deploy/webapp-prod
kubectl set image deploy/webapp-prod nginx=nginx:1.22-alpine
kubectl scale deploy webapp-prod --replicas=10
kubectl rollout resume deploy/webapp-prod  # Aplica ambos cambios juntos
```

---

### **Fase 4: Estrategias Avanzadas (Día 4 - 2.5 horas)**

#### **Sección del README**: 5. Estrategias de Deployment Avanzadas

#### **Objetivos de Aprendizaje**:
- [ ] Comparar RollingUpdate vs Recreate
- [ ] Implementar Blue-Green deployment
- [ ] Implementar Canary deployment
- [ ] Elegir estrategia apropiada según caso de uso

#### **Conceptos Clave**:

**1. RollingUpdate vs Recreate**:

| Aspecto | RollingUpdate | Recreate |
|---------|---------------|----------|
| **Downtime** | ✅ Zero (si maxUnavailable: 0) | ❌ Sí (10-30 segundos) |
| **Velocidad** | Más lento (gradual) | Más rápido (instantáneo) |
| **Recursos** | Requiere extras (maxSurge) | Solo necesarios |
| **Versiones simultáneas** | Sí (v1 y v2 coexisten) | No (solo v2) |
| **Uso** | Web apps, APIs, microservicios | Bases de datos, apps con estado |

```yaml
# Recreate: Para aplicaciones stateful
spec:
  replicas: 1
  strategy:
    type: Recreate  # Elimina TODOS los Pods antes de crear nuevos
```

**2. Blue-Green Deployment**:

**Concepto**: Mantener 2 entornos completos, cambiar tráfico instantáneamente.

```
PASO 1: Blue (v1) activo
Service → Blue Deployment (3 Pods v1)
Green Deployment (no existe)

PASO 2: Crear Green (v2)
Service → Blue Deployment (3 Pods v1) ← Tráfico aquí
Green Deployment (3 Pods v2) ← Testing

PASO 3: Switch (cambiar selector del Service)
Service → Green Deployment (3 Pods v2) ← Tráfico cambiado
Blue Deployment (3 Pods v1) ← Standby (rollback rápido)

PASO 4: Eliminar Blue (después de validación)
Service → Green Deployment (3 Pods v2)
```

**Implementación**:
```yaml
# Blue Deployment
metadata:
  name: webapp-blue
  labels:
    version: blue
spec:
  selector:
    matchLabels:
      app: webapp
      version: blue

# Green Deployment
metadata:
  name: webapp-green
  labels:
    version: green
spec:
  selector:
    matchLabels:
      app: webapp
      version: green

# Service (controla tráfico)
spec:
  selector:
    app: webapp
    version: blue  # ← Cambiar a 'green' para switch
```

**3. Canary Deployment**:

**Concepto**: Enviar % pequeño de tráfico a nueva versión antes de rollout completo.

```
PASO 1: 100% tráfico a Stable (v1)
Service → Stable (10 Pods v1)

PASO 2: 10% tráfico a Canary (v2)
Service → Stable (9 Pods v1) + Canary (1 Pod v2)
         90% v1           10% v2

PASO 3: 50% tráfico a Canary
Service → Stable (5 Pods v1) + Canary (5 Pods v2)
         50% v1           50% v2

PASO 4: 100% tráfico a Canary
Service → Canary (10 Pods v2)
```

**Cálculo de %**:
- 10 Pods totales
- 1 Canary + 9 Stable = 10% Canary
- 5 Canary + 5 Stable = 50% Canary

#### **Actividades**:
1. ✅ Leer sección 5 del README
2. ✅ Implementar Blue-Green con 2 Deployments + Service
3. ✅ Implementar Canary con scaling manual
4. ✅ Simular rollback de Canary
5. ✅ Hacer **Checkpoint 05**
6. ✅ Completar **Lab 05** (60 min): Estrategias avanzadas

#### **Decisión: Cuándo Usar Cada Estrategia**:

```
¿Tu app es stateless?
    ├─ Sí → ¿Necesitas rollback instantáneo?
    │         ├─ Sí → Blue-Green
    │         └─ No → ¿Necesitas testing gradual?
    │                   ├─ Sí → Canary
    │                   └─ No → RollingUpdate
    └─ No (stateful) → ¿v1 y v2 compatibles?
                         ├─ No → Recreate
                         └─ Sí → StatefulSet (otro módulo)
```

---

### **Fase 5: Production-Ready y Troubleshooting (Día 5 - 3 horas)**

#### **Secciones del README**: 6. Best Practices + 7. Monitoreo y Troubleshooting

#### **Objetivos de Aprendizaje**:
- [ ] Aplicar naming conventions consistentes
- [ ] Definir resources apropiadamente
- [ ] Configurar liveness y readiness probes
- [ ] Implementar security contexts
- [ ] Evitar anti-patterns comunes
- [ ] Diagnosticar problemas comunes

#### **Conceptos Clave**:

**1. Resources: Requests y Limits**:

```yaml
resources:
  requests:          # Garantizado (scheduling)
    memory: "256Mi"
    cpu: "500m"      # 0.5 CPU
  limits:            # Máximo permitido
    memory: "512Mi"
    cpu: "1000m"     # 1 CPU
```

**Cálculo**:
1. Medir consumo real en staging
2. **Requests** = Promedio + 20% margen
3. **Limits** = Requests × 2

**Ejemplo**:
- Promedio medido: 200Mi RAM, 300m CPU
- Requests: 250Mi, 400m
- Limits: 500Mi, 800m

**2. Health Checks**:

| Probe | Propósito | Acción si Falla | Endpoint |
|-------|-----------|-----------------|----------|
| **Liveness** | ¿Está VIVO? | **Reinicia** Pod | `/healthz` (simple) |
| **Readiness** | ¿Listo para tráfico? | **Saca** del Service | `/ready` (complejo) |

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30  # Startup time
  periodSeconds: 10        # Cada 10s
  failureThreshold: 3      # Reinicia después de 3 fallos

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5   # Más corto
  periodSeconds: 5
  failureThreshold: 3      # Saca del Service después de 3 fallos
```

**3. Security Context**:

```yaml
spec:
  securityContext:
    runAsNonRoot: true      # NO ejecutar como root
    runAsUser: 1000         # UID específico
  
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL               # Eliminar todas
        add:
        - NET_BIND_SERVICE  # Solo agregar necesarias
      readOnlyRootFilesystem: true
```

**4. Anti-Patterns (Qué NO Hacer)**:

| ❌ Anti-Pattern | ✅ Correcto | Impacto |
|----------------|------------|---------|
| `image: webapp:latest` | `image: webapp:v2.1.0` | No determinístico |
| `replicas: 1` en prod | `replicas: 3` + anti-affinity | Single point of failure |
| Sin readinessProbe | Con readinessProbe | Errores 500 en startup |
| `maxUnavailable: 50%` | `maxUnavailable: 0` | 50% downtime en error |
| Sin change-cause | Con `kubernetes.io/change-cause` | No sabes qué cambió |

**5. Troubleshooting Rápido**:

```bash
# Diagnóstico rápido
kubectl get deploy,rs,pods -l app=webapp
kubectl describe deploy webapp
kubectl get events --field-selector involvedObject.kind=Deployment

# Issue 1: ImagePullBackOff
kubectl describe pod <pod> | grep -A 10 "Events"
# Solución: Verificar nombre/tag imagen

# Issue 2: CrashLoopBackOff
kubectl logs <pod>
kubectl logs <pod> --previous  # Ver logs anteriores
# Solución: Revisar código, variables de entorno

# Issue 3: Readiness failing
kubectl describe pod <pod> | grep -A 10 "Readiness"
# Solución: Aumentar initialDelaySeconds, revisar endpoint

# Issue 4: Recursos insuficientes
kubectl describe pod <pod> | grep -A 10 "Events"
# "0/1 nodes available: Insufficient cpu"
# Solución: Reducir requests o agregar nodos
```

#### **Actividades**:
1. ✅ Leer secciones 6 y 7 del README
2. ✅ Transformar Deployment básico a production-ready
3. ✅ Simular 5 problemas y resolverlos
4. ✅ Hacer **Checkpoint 06** y **Checkpoint 07**
5. ✅ Completar **Lab 06** (50 min) y **Lab 07** (45 min)

#### **Checklist Production-Ready**:

```yaml
# Template production-ready completo
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-frontend-prod
  labels:
    app: webapp
    component: frontend
    environment: production
    version: "v2.1.0"
  annotations:
    kubernetes.io/change-cause: "v2.1.0: Production deployment"
spec:
  replicas: 5                     # ✅ ≥3 para HA
  revisionHistoryLimit: 10
  
  strategy:
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0           # ✅ Zero downtime
  
  template:
    spec:
      securityContext:
        runAsNonRoot: true        # ✅ Security
      
      affinity:
        podAntiAffinity:          # ✅ Distribuir en nodos
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values: [webapp]
              topologyKey: kubernetes.io/hostname
      
      containers:
      - name: webapp
        image: webapp:v2.1.0      # ✅ Semantic versioning
        
        resources:                # ✅ Resources definidos
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
        
        livenessProbe:            # ✅ Health checks
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
        
        securityContext:          # ✅ Security
          readOnlyRootFilesystem: true
          capabilities:
            drop: [ALL]
```

---

## 🎯 Proyecto Final: Deployment Production-Ready (Lab 08 - 90 min)

### **Objetivo**
Crear un Deployment completo de una aplicación web que implemente TODOS los best practices aprendidos.

### **Requisitos**:

1. **Deployment principal**:
   - 5 réplicas
   - Semantic versioning (v1.0.0)
   - Zero downtime (maxUnavailable: 0)
   - Resources requests & limits
   - Liveness + Readiness probes
   - Security context (runAsNonRoot, readOnlyRootFilesystem)
   - Anti-affinity

2. **Service**:
   - ClusterIP para acceso interno
   - Selector correcto

3. **ConfigMap**:
   - Variables de configuración externa

4. **Actualización simulada**:
   - Rolling update de v1.0.0 a v2.0.0
   - Observar en tiempo real
   - Verificar zero downtime

5. **Rollback simulado**:
   - Simular error en v2.0.0
   - Rollback a v1.0.0
   - Verificar recuperación

6. **Estrategia avanzada (bonus)**:
   - Implementar Blue-Green O Canary

### **Criterios de Éxito**:
- [ ] Deployment pasa todos los checks del checklist production-ready
- [ ] Rolling update completa sin downtime
- [ ] Rollback funciona correctamente
- [ ] Security context implementado
- [ ] Health checks configurados apropiadamente

---

## 📝 Comandos de Referencia Rápida

### **Gestión Básica**
```bash
# Crear
kubectl apply -f deployment.yaml
kubectl create deployment webapp --image=nginx:alpine --replicas=3

# Listar
kubectl get deployments
kubectl get deploy webapp -o wide
kubectl get deploy,rs,pods -l app=webapp

# Inspeccionar
kubectl describe deployment webapp
kubectl get deploy webapp -o yaml

# Actualizar
kubectl set image deploy/webapp nginx=nginx:1.21
kubectl edit deploy webapp
kubectl scale deploy webapp --replicas=10

# Eliminar
kubectl delete deployment webapp
kubectl delete -f deployment.yaml
```

### **Rolling Updates**
```bash
# Ver progreso
kubectl rollout status deploy/webapp
kubectl get pods -l app=webapp --watch

# Pausar/Reanudar
kubectl rollout pause deploy/webapp
kubectl rollout resume deploy/webapp
```

### **Rollback**
```bash
# Ver historial
kubectl rollout history deploy/webapp
kubectl rollout history deploy/webapp --revision=2

# Rollback
kubectl rollout undo deploy/webapp
kubectl rollout undo deploy/webapp --to-revision=2
```

### **Troubleshooting**
```bash
# Diagnóstico
kubectl get pods -l app=webapp
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Eventos
kubectl get events --field-selector involvedObject.kind=Deployment,involvedObject.name=webapp

# Condiciones
kubectl get deploy webapp -o jsonpath='{.status.conditions[*]}'

# Recursos
kubectl top pods -l app=webapp
```

---

## ✅ Autoevaluación Final

### **Conceptos (20 puntos)**
- [ ] Explicar por qué Deployments son mejores que ReplicaSets solos (2 puntos)
- [ ] Describir arquitectura: Deployment → ReplicaSet → Pod (2 puntos)
- [ ] Explicar rolling update flow completo (4 pasos) (3 puntos)
- [ ] Calcular: replicas=10, maxSurge=3, maxUnavailable=2 → ¿Cuántos Pods máximo/mínimo? (3 puntos)
- [ ] Diferenciar liveness vs readiness probe (2 puntos)
- [ ] Comparar Blue-Green vs Canary vs RollingUpdate (3 puntos)
- [ ] Explicar cuándo usar Recreate strategy (2 puntos)
- [ ] Describir qué hace rollback (crea nueva revisión o restaura número) (3 puntos)

### **Comandos (15 puntos)**
- [ ] Crear Deployment con kubectl create (1 punto)
- [ ] Ver historial de revisiones (1 punto)
- [ ] Hacer rollback a versión anterior (1 punto)
- [ ] Ver progreso de rolling update (1 punto)
- [ ] Pausar/reanudar deployment (2 puntos)
- [ ] Escalar deployment (1 punto)
- [ ] Actualizar imagen (2 puntos)
- [ ] Ver eventos de Deployment (2 puntos)
- [ ] Troubleshoot: ImagePullBackOff (2 puntos)
- [ ] Ver condiciones del Deployment (2 puntos)

### **Práctica (65 puntos)**
- [ ] Crear Deployment production-ready desde YAML (10 puntos)
- [ ] Implementar rolling update con zero downtime (10 puntos)
- [ ] Hacer rollback exitoso (5 puntos)
- [ ] Configurar health checks correctamente (10 puntos)
- [ ] Implementar security context (10 puntos)
- [ ] Implementar Blue-Green O Canary (15 puntos)
- [ ] Troubleshoot 3 problemas comunes (5 puntos cada = 15 puntos)

**Total**: 100 puntos

**Criterio de aprobación**: ≥ 75 puntos

---

## 📚 Recursos Adicionales

### **Documentación Oficial**
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

### **Herramientas**
- [k9s](https://k9scli.io/): Terminal UI para Kubernetes
- [kubectl-tree](https://github.com/ahmetb/kubectl-tree): Ver jerarquía de recursos
- [Flagger](https://flagger.app/): Progressive Delivery automatizado

### **Blogs Recomendados**
- [Google Cloud - Best Practices for Deployments](https://cloud.google.com/architecture/best-practices-for-operating-containers)
- [CNCF - Deployment Strategies](https://www.weave.works/blog/kubernetes-deployment-strategies)

---

## 🎓 Certificado de Dominio

**Has completado exitosamente el Módulo 07** si puedes:

✅ Crear y gestionar Deployments con kubectl  
✅ Configurar rolling updates con zero downtime  
✅ Hacer rollback a versiones anteriores  
✅ Implementar Blue-Green y Canary deployments  
✅ Aplicar best practices de producción  
✅ Troubleshoot problemas comunes  
✅ Diseñar Deployments production-ready  

**Tiempo invertido**: 11-12.5 horas  
**Nivel alcanzado**: Intermedio-Avanzado  

---

### **📖 Próximo Módulo**

➡️ **Módulo 08: Services y Endpoints**
- Exponer Deployments internamente y externamente
- ClusterIP, NodePort, LoadBalancer
- Endpoints y DNS de Kubernetes
- Service discovery

---

**Última actualización**: 2024  
**Versión**: 2.0  
**Autor**: Curso Kubernetes Completo
