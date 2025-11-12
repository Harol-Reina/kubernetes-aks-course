# 📚 Guía de Estudio: Módulo 05 - Gestión Avanzada de Pods

> **Ruta estructurada para dominar la gestión práctica de Pods en producción**

---

## 🎯 Cómo Usar Esta Guía

Esta guía complementa el README principal con una progresión pedagógica optimizada:

1. **Lee la teoría** en cada sección del README
2. **Analiza los ejemplos inline** con explicaciones detalladas
3. **Ejecuta los ejemplos** de la carpeta `ejemplos/`
4. **Completa el laboratorio** para consolidar conocimientos
5. **Verifica tu comprensión** con los checkpoints

---

## 📖 Prerequisito: Módulo 04 Completado

Antes de continuar, asegúrate de haber completado el [Módulo 04: Pods vs Contenedores](../modulo-04-pods-vs-contenedores/).

**Lo que ya deberías saber del Módulo 04:**
- ✅ Qué es un Pod y por qué existe
- ✅ Los 7 namespaces Linux y cuáles se comparten
- ✅ Patrones multi-contenedor (Sidecar, Init, Ambassador)
- ✅ Cuándo usar un Pod multi-contenedor vs múltiples Pods

**Lo que aprenderás AHORA en Módulo 05:**
- 🎯 Cómo escribir manifiestos YAML completos
- 🎯 Cómo configurar recursos y health checks
- 🎯 Cómo aplicar seguridad y debugging
- 🎯 Cómo optimizar para producción

---

## 📖 Ruta de Aprendizaje Recomendada

### Fase 1: Manifiestos YAML Production-Ready (60-90 min)

#### 1.1. Anatomía de un Manifiesto Pod
📖 **Leer**: [README.md - Sección 1](./README.md#-1-manifiestos-yaml-production-ready)

🔑 **Estructura básica**:
```yaml
apiVersion: v1      # API version (siempre v1 para Pods)
kind: Pod           # Tipo de recurso
metadata:           # Información identificativa
  name: mi-pod
  labels:
    app: frontend
spec:               # Especificación deseada
  containers:
  - name: nginx
    image: nginx
```

💡 **Campos obligatorios**:
- `apiVersion`: Define la versión de la API K8s
- `kind`: Tipo de objeto (Pod en este caso)
- `metadata.name`: Nombre único del Pod
- `spec.containers`: Al menos un contenedor

✅ **Checkpoint**:
- ¿Cuáles son los 4 campos raíz obligatorios de un manifiesto?
- ¿Qué diferencia hay entre `metadata` y `spec`?
- ¿Puedes crear un Pod sin labels?

---

#### 1.2. Metadata: Labels y Annotations
📖 **Leer**: [README.md - Labels y Selectors](./README.md#-3-labels-selectors-y-annotations)

🔑 **Conceptos clave**:

**Labels** (key-value pairs para identificación):
```yaml
metadata:
  labels:
    app: frontend           # Aplicación
    tier: web              # Capa arquitectónica
    environment: production # Entorno
    version: v1.2.0        # Versión
```

**Annotations** (metadata no identificativa):
```yaml
metadata:
  annotations:
    description: "Frontend web server"
    maintainer: "devops@example.com"
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
```

💡 **Diferencias clave**:

| Aspecto | Labels | Annotations |
|---------|--------|-------------|
| **Uso** | Identificación y selección | Metadata adicional |
| **Filtrado** | ✅ Sí (selectors) | ❌ No |
| **Limitación** | 63 caracteres | Sin límite práctico |
| **Ejemplos** | app, tier, env | URLs, hashes, config |

📁 **Ejemplo práctico**:
```bash
kubectl apply -f ejemplos/basicos/01-pod-con-labels.yaml
kubectl get pods --show-labels
kubectl get pods -l app=frontend
kubectl get pods -l 'environment in (production,staging)'
```

✅ **Checkpoint**:
- ¿Cuándo usarías labels vs annotations?
- ¿Cómo filtrarías Pods por múltiples labels?
- Menciona 3 casos de uso de annotations

---

#### 1.3. Spec: Configuración de Contenedores
📖 **Leer**: [README.md - Spec de Contenedores](./README.md#-1-manifiestos-yaml-production-ready)

🔑 **Configuración básica**:
```yaml
spec:
  containers:
  - name: nginx               # Nombre único en el Pod
    image: nginx:alpine       # Imagen (preferir tags específicos)
    ports:
    - containerPort: 80       # Puerto que expone
      name: http              # Nombre opcional
      protocol: TCP           # Protocolo (TCP/UDP/SCTP)
    env:                      # Variables de entorno
    - name: ENV_VAR
      value: "production"
```

💡 **Mejores prácticas**:
- ✅ **Usar tags específicos** en producción (evitar `latest`)
- ✅ **Nombrar puertos** para referencia fácil
- ✅ **Documentar con comments** en YAML
- ✅ **Un contenedor principal** por Pod (salvo patterns específicos)

📁 **Ejemplos progresivos**:
```bash
# Ejemplo 1: Pod básico
kubectl apply -f ejemplos/basicos/01-pod-simple.yaml

# Ejemplo 2: Pod con configuración avanzada
kubectl apply -f ejemplos/basicos/02-pod-avanzado.yaml

# Ejemplo 3: Pod multi-contenedor
kubectl apply -f ejemplos/multi-contenedor/01-shared-volume.yaml
```

✅ **Checkpoint**:
- ¿Por qué evitar `image: nginx:latest` en producción?
- ¿Cuántos contenedores mínimo debe tener un Pod?
- ¿Qué información proporciona `containerPort`?

---

### Fase 2: Resource Management (90-120 min)

#### 2.1. Requests vs Limits
📖 **Leer**: [README.md - Resource Management](./README.md#-4-resource-management)

🔑 **Conceptos fundamentales**:

**Requests** (garantizado):
- Cantidad **mínima** de recursos garantizados
- Scheduler usa esto para decidir placement
- Pod NO se programa si no hay requests disponibles

**Limits** (máximo permitido):
- Cantidad **máxima** que puede usar
- Si excede memory limit → OOMKilled
- Si excede CPU limit → Throttling (no kill)

```yaml
spec:
  containers:
  - name: app
    resources:
      requests:        # Garantizado
        memory: "128Mi"
        cpu: "250m"    # 250 millicores = 0.25 CPU
      limits:          # Máximo
        memory: "256Mi"
        cpu: "500m"
```

💡 **Unidades**:
- **CPU**: `1` = 1 vCPU, `100m` = 0.1 vCPU
- **Memory**: `128Mi` = 128 MiB, `1Gi` = 1 GiB

📊 **Comportamiento por exceso**:
| Recurso | Excede Limit | Resultado |
|---------|--------------|-----------|
| **Memory** | Sí | OOMKilled (restart) |
| **CPU** | Sí | Throttling (más lento) |

📁 **Ejemplos prácticos**:
```bash
# Pod con resources configurados
kubectl apply -f ejemplos/production-ready/01-with-resources.yaml

# Ver recursos asignados
kubectl describe pod <pod-name> | grep -A 10 "Requests\|Limits"

# Monitorear uso real
kubectl top pod <pod-name>
```

✅ **Checkpoint**:
- ¿Qué pasa si no defines requests?
- ¿Qué diferencia hay entre un Pod con 500m CPU request vs 500m limit?
- ¿Por qué Memory limit puede causar restart pero CPU limit no?

---

#### 2.2. Quality of Service (QoS) Classes
📖 **Leer**: [README.md - QoS Classes](./README.md#-4-resource-management)

🔑 **Las 3 clases QoS**:

**1. Guaranteed** (máxima prioridad):
```yaml
# Requests == Limits para TODOS los contenedores
resources:
  requests:
    memory: "256Mi"
    cpu: "500m"
  limits:
    memory: "256Mi"  # Igual a request
    cpu: "500m"      # Igual a request
```

**2. Burstable** (prioridad media):
```yaml
# Al menos un request definido, pero requests < limits
resources:
  requests:
    memory: "128Mi"
    cpu: "250m"
  limits:
    memory: "256Mi"  # Mayor que request
    cpu: "500m"
```

**3. BestEffort** (prioridad baja):
```yaml
# Sin requests ni limits definidos
resources: {}  # o simplemente omitido
```

📊 **Comportamiento en presión de recursos**:

```
Alta presión de memoria en el nodo:
1. Primero se eliminan: BestEffort Pods
2. Luego: Burstable Pods (que excedan requests)
3. Último recurso: Guaranteed Pods
```

💡 **Recomendaciones**:
- **Producción crítica**: Guaranteed
- **Producción estándar**: Burstable
- **Testing/dev**: BestEffort (aceptable)

📁 **Ejemplos comparativos**:
```bash
# Guaranteed
kubectl apply -f ejemplos/production-ready/02-guaranteed-qos.yaml

# Burstable
kubectl apply -f ejemplos/production-ready/03-burstable-qos.yaml

# BestEffort
kubectl apply -f ejemplos/basicos/01-pod-simple.yaml  # Sin resources

# Ver QoS class asignada
kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
```

✅ **Checkpoint**:
- ¿Qué clase QoS se asigna si requests = limits?
- ¿Qué Pods se eliminan primero bajo presión de memoria?
- ¿Cuándo usarías BestEffort en producción?

🧪 **Lab 01**: [`laboratorios/lab-01-resource-management.md`](./laboratorios/lab-01-resource-management.md)
- Duración: 60 min
- Experimenta con QoS classes y limits

---

### Fase 3: Health Checks y Probes (90-120 min)

#### 3.1. Los 3 Tipos de Probes
📖 **Leer**: [README.md - Health Checks](./README.md#-5-health-checks-y-probes)

🔑 **Conceptos clave**:

**Liveness Probe** (¿Está vivo?):
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
  failureThreshold: 3
```
- **Propósito**: Detectar aplicaciones "congeladas" o deadlocks
- **Acción si falla**: **Reinicia el contenedor**
- **Cuándo usar**: Detectar estados irrecuperables

**Readiness Probe** (¿Está listo?):
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```
- **Propósito**: Determinar si puede recibir tráfico
- **Acción si falla**: **Quita de Service** (no restart)
- **Cuándo usar**: Procesos de inicialización lentos, dependencias

**Startup Probe** (¿Ya inició?):
```yaml
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```
- **Propósito**: Proteger apps con inicio MUY lento
- **Acción**: Deshabilita liveness/readiness hasta que pase
- **Cuándo usar**: Legacy apps, inicializaciones largas (>1 min)

📊 **Comparación de Probes**:

| Probe | Pregunta | Si Falla | Casos de Uso |
|-------|----------|----------|--------------|
| **Liveness** | ¿Vivo? | Restart | Deadlocks, hangs |
| **Readiness** | ¿Listo? | Remove tráfico | Cache loading, DB connections |
| **Startup** | ¿Iniciado? | Wait (luego restart) | Apps lentas al iniciar |

---

#### 3.2. Tipos de Checks
📖 **Leer**: [README.md - Probe Types](./README.md#-5-health-checks-y-probes)

**1. HTTP GET** (más común):
```yaml
httpGet:
  path: /healthz
  port: 8080
  httpHeaders:
  - name: Custom-Header
    value: Awesome
```

**2. TCP Socket**:
```yaml
tcpSocket:
  port: 3306
```

**3. Exec Command**:
```yaml
exec:
  command:
  - cat
  - /tmp/healthy
```

💡 **Mejores prácticas**:
- ✅ **Liveness**: Simple y rápido (<1 seg)
- ✅ **Readiness**: Verifica dependencias (DB, cache)
- ✅ **Startup**: Threshold alto para apps lentas
- ✅ **Evita** checks costosos en liveness (causan cascada de restarts)

📁 **Ejemplos progresivos**:
```bash
# 1. Solo Liveness
kubectl apply -f ejemplos/production-ready/04-liveness-only.yaml

# 2. Liveness + Readiness
kubectl apply -f ejemplos/production-ready/05-liveness-readiness.yaml

# 3. Los 3 tipos
kubectl apply -f ejemplos/production-ready/06-all-probes.yaml

# Ver estado de probes
kubectl describe pod <pod-name> | grep -A 5 "Liveness\|Readiness\|Startup"
```

✅ **Checkpoint**:
- ¿Cuál es la diferencia principal entre liveness y readiness?
- ¿Por qué startup probe deshabilita los otros temporalmente?
- ¿Qué pasa si liveness falla 3 veces?

---

#### 3.3. Configuración de Timings
📖 **Leer**: [README.md - Probe Configuration](./README.md#-5-health-checks-y-probes)

🔑 **Parámetros importantes**:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30   # Espera inicial antes del primer check
  periodSeconds: 10         # Frecuencia de checks
  timeoutSeconds: 5         # Timeout por check
  successThreshold: 1       # Éxitos consecutivos para OK
  failureThreshold: 3       # Fallos consecutivos para FAIL
```

💡 **Cálculo de tiempo hasta restart**:
```
Tiempo = initialDelaySeconds + (failureThreshold × periodSeconds)

Ejemplo:
initialDelaySeconds: 30
periodSeconds: 10
failureThreshold: 3

Tiempo hasta restart = 30 + (3 × 10) = 60 segundos
```

📊 **Recomendaciones por entorno**:

| Entorno | initialDelay | period | failure | Rationale |
|---------|--------------|--------|---------|-----------|
| **Dev** | 5s | 5s | 1 | Feedback rápido |
| **Staging** | 15s | 10s | 2 | Balance |
| **Production** | 30s | 10s | 3 | Evitar false positives |

✅ **Checkpoint**:
- ¿Qué hace `failureThreshold: 3`?
- ¿Cómo calcularías el tiempo hasta reinicio?
- ¿Por qué `initialDelaySeconds` mayor en producción?

🧪 **Lab 02**: [`laboratorios/lab-02-health-checks.md`](./laboratorios/lab-02-health-checks.md)
- Duración: 70 min
- Implementa probes con app real

---

### Fase 4: Security Contexts (60-90 min)

#### 4.1. Fundamentos de Security Context
📖 **Leer**: [README.md - Security Contexts](./README.md#-6-security-contexts)

🔑 **Dos niveles de seguridad**:

**Pod-level** (aplica a todos los contenedores):
```yaml
spec:
  securityContext:
    runAsUser: 1000        # UID del usuario
    runAsGroup: 3000       # GID del grupo
    fsGroup: 2000          # Grupo para volumes
    fsGroupChangePolicy: "OnRootMismatch"
```

**Container-level** (sobrescribe pod-level):
```yaml
spec:
  containers:
  - name: app
    securityContext:
      runAsUser: 2000          # Sobrescribe pod-level
      runAsNonRoot: true       # Falla si root
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
```

💡 **Prioridad**: Container > Pod

---

#### 4.2. Capabilities
📖 **Leer**: [README.md - Capabilities](./README.md#-6-security-contexts)

🔑 **Drop y Add capabilities**:
```yaml
securityContext:
  capabilities:
    drop:
    - ALL                    # Quita todas
    add:
    - NET_BIND_SERVICE      # Solo lo necesario
```

📊 **Capabilities comunes**:
| Capability | Propósito | Cuándo agregar |
|------------|-----------|----------------|
| `NET_BIND_SERVICE` | Bind puertos < 1024 | Web servers |
| `SYS_TIME` | Cambiar hora sistema | NTP |
| `NET_ADMIN` | Config de red | Network tools |

💡 **Principio**: **Drop ALL, add solo lo necesario**

📁 **Ejemplo hardened**:
```bash
kubectl apply -f ejemplos/production-ready/07-hardened-security.yaml
```

```yaml
# Máxima seguridad
securityContext:
  runAsNonRoot: true
  runAsUser: 10000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
```

✅ **Checkpoint**:
- ¿Qué hace `runAsNonRoot: true`?
- ¿Por qué "drop ALL, add mínimo"?
- ¿Cuándo usarías `readOnlyRootFilesystem`?

🧪 **Lab 03**: [`laboratorios/lab-03-security-hardening.md`](./laboratorios/lab-03-security-hardening.md)
- Duración: 50 min
- Hardening de un Pod vulnerable

---

### Fase 5: Debugging y Troubleshooting (60-90 min)

#### 5.1. Herramientas Esenciales de Debugging
📖 **Leer**: [README.md - Debugging](./README.md#-7-debugging-y-troubleshooting)

🔑 **Comandos fundamentales**:

**1. Inspeccionar Pod**:
```bash
# Descripción completa
kubectl describe pod <pod-name>

# Ver solo eventos
kubectl get events --field-selector involvedObject.name=<pod-name>

# Estado actual
kubectl get pod <pod-name> -o yaml
```

**2. Logs**:
```bash
# Logs actuales
kubectl logs <pod-name>

# Con seguimiento (like tail -f)
kubectl logs -f <pod-name>

# Logs anteriores (si reinició)
kubectl logs <pod-name> --previous

# Multi-contenedor
kubectl logs <pod-name> -c <container-name>

# Todas las líneas
kubectl logs <pod-name> --tail=-1
```

**3. Ejecutar comandos**:
```bash
# Shell interactivo
kubectl exec -it <pod-name> -- /bin/bash

# Comando único
kubectl exec <pod-name> -- ls -la /app

# Multi-contenedor
kubectl exec -it <pod-name> -c <container-name> -- bash
```

**4. Port Forwarding**:
```bash
# Acceder a un Pod directamente
kubectl port-forward pod/<pod-name> 8080:80

# Ahora accesible en http://localhost:8080
```

---

#### 5.2. Debugging Avanzado: Ephemeral Containers
📖 **Leer**: [README.md - Ephemeral Containers](./README.md#-7-debugging-y-troubleshooting)

🔑 **kubectl debug** (K8s 1.23+):
```bash
# Crear debugging container temporal
kubectl debug <pod-name> -it --image=busybox --target=<container-name>

# Con herramientas avanzadas
kubectl debug <pod-name> -it --image=nicolaka/netshoot

# Copy del Pod con debugging
kubectl debug <pod-name> -it --copy-to=<new-name> --container=debugger --image=busybox
```

💡 **Ventajas**:
- ✅ No requiere shell en imagen original
- ✅ Agrega herramientas sin rebuild
- ✅ No persiste (temporal)

---

#### 5.3. Troubleshooting Patterns
📖 **Leer**: [README.md - Common Issues](./README.md#-7-debugging-y-troubleshooting)

📊 **Problemas comunes**:

**1. ImagePullBackOff**:
```bash
# Síntomas
STATUS: ImagePullBackOff o ErrImagePull

# Diagnóstico
kubectl describe pod <pod-name> | grep -A 5 "Events:"

# Causas comunes
- Imagen no existe
- Tag incorrecto
- Registry privado sin credenciales
```

**2. CrashLoopBackOff**:
```bash
# Síntomas
STATUS: CrashLoopBackOff, RESTARTS: >0

# Diagnóstico
kubectl logs <pod-name> --previous

# Causas comunes
- App crashea al inicio
- Liveness probe fallando
- Command incorrecto
```

**3. Pending**:
```bash
# Síntomas
STATUS: Pending por tiempo prolongado

# Diagnóstico
kubectl describe pod <pod-name>

# Causas comunes
- Recursos insuficientes
- PVC no bound
- Node selector no match
```

📁 **Ejemplos de debugging**:
```bash
# Pod con problemas intencionales
kubectl apply -f ejemplos/troubleshooting/01-crashloop.yaml
kubectl apply -f ejemplos/troubleshooting/02-imagepull-error.yaml
kubectl apply -f ejemplos/troubleshooting/03-oom-killed.yaml

# Practicar diagnóstico
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
kubectl get events --sort-by='.lastTimestamp'
```

✅ **Checkpoint**:
- ¿Cómo ves logs de un Pod que reinició?
- ¿Qué herramienta usarías si la imagen no tiene shell?
- Menciona 3 causas de CrashLoopBackOff

🧪 **Lab 04**: [`laboratorios/lab-04-troubleshooting.md`](./laboratorios/lab-04-troubleshooting.md)
- Duración: 60 min
- Resuelve 5 problemas reales

---

### Fase 6: Best Practices de Producción (45-60 min)

#### 6.1. Checklist de Production-Ready Pod
📖 **Leer**: [README.md - Best Practices](./README.md#-8-best-practices-de-producción)

✅ **Configuración obligatoria**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: production-app
  labels:
    app: myapp
    version: v1.2.0
    environment: production
  annotations:
    description: "Frontend web server"
spec:
  # 1. Resources SIEMPRE definidos
  containers:
  - name: app
    image: myapp:1.2.0  # Tag específico
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
    
    # 2. Health checks configurados
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
    
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
    
    # 3. Security context
    securityContext:
      runAsNonRoot: true
      runAsUser: 10000
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

---

#### 6.2. Antipatrones Comunes
📖 **Leer**: [README.md - Anti-patterns](./README.md#-8-best-practices-de-producción)

❌ **Qué EVITAR**:

**1. Sin resource limits**:
```yaml
# ❌ MALO
spec:
  containers:
  - name: app
    image: myapp
    # Sin resources definidos
```

**2. Usar `latest` tag**:
```yaml
# ❌ MALO
image: nginx:latest  # No reproducible
```

**3. Sin health checks**:
```yaml
# ❌ MALO
spec:
  containers:
  - name: app
    image: myapp
    # Sin probes
```

**4. Corriendo como root**:
```yaml
# ❌ MALO
securityContext:
  runAsUser: 0  # root
```

✅ **Checkpoint**:
- ¿Por qué evitar `image:latest` en producción?
- ¿Qué pasa si no defines resource limits?
- Menciona 3 elementos obligatorios de un Pod production-ready

---

## 🎯 Verificación Final de Conocimientos

Antes de continuar al siguiente módulo, asegúrate de poder responder:

### Manifiestos y Configuración
- [ ] ¿Cuáles son los 4 campos raíz obligatorios de un manifiesto Pod?
- [ ] ¿Qué diferencia hay entre labels y annotations?
- [ ] ¿Cómo defines variables de entorno en un contenedor?

### Resource Management
- [ ] ¿Qué diferencia hay entre requests y limits?
- [ ] ¿Cuáles son las 3 QoS classes y cómo se determinan?
- [ ] ¿Qué pasa cuando un Pod excede memory limit?

### Health Checks
- [ ] ¿Cuál es la diferencia entre liveness y readiness probe?
- [ ] ¿Cuándo usarías startup probe?
- [ ] ¿Qué tipos de probes existen?

### Security
- [ ] ¿Qué hace `runAsNonRoot: true`?
- [ ] ¿Por qué "drop ALL capabilities, add solo necesarias"?
- [ ] ¿Qué es `readOnlyRootFilesystem`?

### Debugging
- [ ] ¿Cómo ves logs de un Pod que reinició?
- [ ] ¿Qué comando usas para shell interactivo en un Pod?
- [ ] ¿Cómo diagnosti CrashLoopBackOff?

---

## 📚 Recursos Adicionales

### Documentación
- 📖 [README Principal](./README.md) - Teoría completa
- 📖 [Ejemplos README](./ejemplos/README.md) - Guía de ejemplos
- 📖 [Laboratorios README](./laboratorios/README.md) - Guía de labs

### Comandos de Referencia Rápida
```bash
# Inspección
kubectl get pods
kubectl describe pod <name>
kubectl logs <name> [-c container]
kubectl exec -it <name> -- bash

# Debugging
kubectl debug <name> -it --image=busybox
kubectl get events --sort-by='.lastTimestamp'
kubectl top pod <name>

# Gestión
kubectl apply -f <file>
kubectl delete pod <name>
kubectl port-forward pod/<name> 8080:80
```

---

## ⏭️ Siguiente Paso

Una vez completado este módulo, continúa con:

**Módulo 06: ReplicaSets y Replicación**
- Controllers de alto nivel
- Self-healing automático
- Escalado de réplicas
- Actualización declarativa

**Diferencia clave con Módulo 05**:
- **Módulo 05**: Gestión de Pods **individuales**
- **Módulo 06**: Gestión de **conjuntos de Pods** con auto-recovery

---

## 🏆 Checklist de Finalización

Marca cada item a medida que avanzas:

### Teoría
- [ ] Leí sobre estructura de manifiestos YAML
- [ ] Entiendo requests vs limits
- [ ] Comprendo las 3 QoS classes
- [ ] Conozco los 3 tipos de probes
- [ ] Entiendo security contexts
- [ ] Conozco herramientas de debugging

### Ejemplos
- [ ] Probé ejemplos básicos
- [ ] Probé ejemplos con resources
- [ ] Probé ejemplos con probes
- [ ] Probé ejemplos con security
- [ ] Probé ejemplos de troubleshooting

### Laboratorios
- [ ] Completé Lab 01 (Resource Management)
- [ ] Completé Lab 02 (Health Checks)
- [ ] Completé Lab 03 (Security)
- [ ] Completé Lab 04 (Troubleshooting)

### Verificación
- [ ] Puedo escribir un manifiesto production-ready
- [ ] Sé configurar QoS classes apropiadamente
- [ ] Puedo implementar health checks correctamente
- [ ] Puedo aplicar security hardening
- [ ] Puedo debuggear problemas comunes

---

**🎉 ¡Felicitaciones!** Si completaste todos los checkpoints, estás listo para gestionar Pods en producción.
