# Módulo 12: Health Checks y Probes en Kubernetes

## Introducción

Los **Health Checks** (verificaciones de salud) son mecanismos fundamentales en Kubernetes para garantizar la disponibilidad y confiabilidad de las aplicaciones. Permiten al sistema detectar y recuperarse automáticamente de fallos sin intervención manual.

### ¿Por qué necesitamos Health Checks?

Imagina estos escenarios reales:

❌ **Sin Probes**:
- Aplicación colgada (deadlock) pero el proceso sigue corriendo → No se detecta
- Servidor web arriba pero sin conexión a BD → Sigue recibiendo tráfico
- Aplicación con fuga de memoria → Sigue en servicio hasta que falla completamente
- Pod arrancando → Recibe tráfico antes de estar listo

✅ **Con Probes**:
- Detección automática de problemas
- Reinicio automático de contenedores fallidos
- Tráfico solo a Pods listos
- Tiempo de inactividad minimizado

### Tipos de Probes

Kubernetes proporciona **tres tipos de probes** que trabajan en conjunto:

| Probe | ¿Qué verifica? | ¿Cuándo falla? | Acción de Kubernetes |
|-------|----------------|----------------|----------------------|
| **Startup** | ¿El contenedor ha arrancado? | Pod lento iniciando | Reinicia el Pod |
| **Liveness** | ¿El contenedor está vivo? | Aplicación colgada/deadlock | Reinicia el contenedor |
| **Readiness** | ¿El contenedor está listo? | No puede servir tráfico | Elimina del endpoint del Service |

---

## Ciclo de Vida de un Pod y Probes

Entender cómo y cuándo se ejecutan las probes es crucial:

```
┌─────────────────────────────────────────────────────────────┐
│                    CICLO DE VIDA DEL POD                    │
└─────────────────────────────────────────────────────────────┘

  Pod Creado
      │
      ▼
  ┌─────────┐
  │ Pending │ ← Asignado a nodo, descargando imagen
  └─────────┘
      │
      ▼
  ┌─────────┐
  │ Running │ ← Contenedor iniciado
  └─────────┘
      │
      ├──→ [STARTUP PROBE] ◄─── Se ejecuta PRIMERO
      │         │
      │         ├─ ❌ Falla → Reinicia Pod
      │         │
      │         └─ ✅ Éxito
      │              │
      │              ▼
      ├──→ [LIVENESS PROBE] ◄─── Se ejecuta periódicamente
      │         │
      │         ├─ ❌ Falla → Reinicia contenedor
      │         │
      │         └─ ✅ Éxito → Contenedor vivo
      │
      └──→ [READINESS PROBE] ◄─── Se ejecuta periódicamente
                │
                ├─ ❌ Falla → Quita del Service (no recibe tráfico)
                │
                └─ ✅ Éxito → Agrega al Service (recibe tráfico)
```

### Orden de Ejecución

1. **Startup Probe** (si está configurada):
   - Se ejecuta **PRIMERO** al iniciar el contenedor
   - Bloquea Liveness y Readiness hasta que tenga éxito
   - Solo se ejecuta **una vez** al inicio

2. **Liveness y Readiness** (después de Startup exitosa):
   - Se ejecutan **periódicamente** y **en paralelo**
   - Continúan durante toda la vida del Pod

---

## 1. Startup Probe

### ¿Qué es?

Probe que verifica si la aplicación ha **arrancado correctamente**. Ideal para aplicaciones que tardan mucho tiempo en iniciar.

### ¿Cuándo usarla?

✅ Aplicaciones con arranque lento:
- Aplicaciones legacy (WebLogic, JBoss, etc.)
- Bases de datos grandes
- Aplicaciones que cargan muchos datos en memoria
- Microservicios con muchas dependencias

❌ No es necesaria para:
- Aplicaciones que arrancan rápido (< 5 segundos)
- Contenedores stateless simples

### Configuración

Ver: [`ejemplos/03-startup/startup-slow-app.yaml`](ejemplos/03-startup/startup-slow-app.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: slow-startup-pod
  labels:
    app: slow-app
spec:
  containers:
  - name: app
    image: nginx:1.27-alpine
    ports:
    - containerPort: 80
    
    # Startup Probe: Permite hasta 5 minutos para arrancar
    startupProbe:
      httpGet:
        path: /healthz
        port: 80
      initialDelaySeconds: 10    # Espera 10s antes de la primera prueba
      periodSeconds: 10           # Prueba cada 10s
      failureThreshold: 30        # Permite 30 fallos (10s × 30 = 300s = 5min)
      timeoutSeconds: 3           # Timeout por prueba
```

**Cálculo del tiempo máximo de arranque**:
```
Tiempo máximo = failureThreshold × periodSeconds
              = 30 × 10s
              = 300 segundos (5 minutos)
```

### Ejemplo Práctico

Ver: [`ejemplos/03-startup/startup-database.yaml`](ejemplos/03-startup/startup-database.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgres-slow
spec:
  containers:
  - name: postgres
    image: postgres:16-alpine
    env:
    - name: POSTGRES_PASSWORD
      value: "password123"
    
    startupProbe:
      exec:
        command:
        - pg_isready      # Comando de PostgreSQL
        - -U
        - postgres
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 60  # 60 × 5s = 300s = 5min
```

### ⚠️ Importante

- Mientras Startup Probe no tenga éxito, **Liveness y Readiness NO se ejecutan**
- Si falla después de todos los intentos → **Pod se reinicia**
- Una vez tiene éxito → **Se desactiva** y activa las otras probes

---

## 2. Liveness Probe

### ¿Qué es?

Probe que verifica si el contenedor está **vivo y funcionando correctamente**. Si falla, Kubernetes **reinicia el contenedor**.

### ¿Cuándo usarla?

✅ Detectar y recuperar de:
- **Deadlocks**: Aplicación colgada sin poder avanzar
- **Memory leaks**: Aplicación degradada por fuga de memoria
- **Bugs severos**: Aplicación en estado inconsistente
- **Dependencias caídas**: Sin conexión a recursos críticos

### Casos de Uso Reales

#### Aplicación Web con Deadlock

Ver: [`ejemplos/01-liveness/liveness-http-deadlock.yaml`](ejemplos/01-liveness/liveness-http-deadlock.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp-with-liveness
spec:
  containers:
  - name: webapp
    image: registry.k8s.io/e2e-test-images/agnhost:2.40
    args:
    - liveness
    ports:
    - containerPort: 8080
    
    livenessProbe:
      httpGet:
        path: /healthz      # Endpoint de salud
        port: 8080
        httpHeaders:
        - name: Custom-Header
          value: Awesome
      initialDelaySeconds: 3
      periodSeconds: 3      # Verifica cada 3 segundos
      timeoutSeconds: 1     # Timeout de 1 segundo
      failureThreshold: 3   # 3 fallos consecutivos = reinicio
```

**Comportamiento**:
- Primeros 10 segundos: `/healthz` devuelve `200 OK` ✅
- Después de 10 segundos: `/healthz` devuelve `500 Error` ❌
- Kubernetes detecta 3 fallos consecutivos → **Reinicia el contenedor**

#### Aplicación con Comando

Ver: [`ejemplos/01-liveness/liveness-exec-file.yaml`](ejemplos/01-liveness/liveness-exec-file.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-exec
  labels:
    test: liveness
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/busybox:1.27.2
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy    # Verifica existencia del archivo
      initialDelaySeconds: 5
      periodSeconds: 5
```

**Flujo temporal**:
```
Segundo 0-30:  Archivo existe → cat devuelve 0 → ✅ Probe OK
Segundo 30:    Archivo eliminado
Segundo 35:    cat falla (archivo no existe) → ❌ Probe FALLA
Segundo 40:    cat falla nuevamente → ❌ Probe FALLA
Segundo 45:    cat falla (3er fallo) → ❌ REINICIA CONTENEDOR
```

### ⚠️ Precauciones con Liveness

```yaml
# ❌ MAL: Liveness muy agresiva
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 1
  periodSeconds: 2
  failureThreshold: 1  # ← PELIGROSO: Un solo fallo reinicia

# ✅ BIEN: Liveness tolerante
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3  # ← Permite fallos temporales
  timeoutSeconds: 5
```

**⚠️ IMPORTANTE**: Liveness Probe mal configurada puede causar **cascading failures**:
1. Alta carga → Aplicación responde lento
2. Liveness timeout → Reinicia Pods
3. Menos Pods → Más carga en los restantes
4. Más timeouts → Más reinicios → **Fallo en cascada**

---

## 3. Readiness Probe

### ¿Qué es?

Probe que verifica si el contenedor está **listo para recibir tráfico**. Si falla, el Pod se **quita del Service** pero **NO se reinicia**.

### ¿Cuándo usarla?

✅ Garantizar que:
- Pod completó carga inicial (datos, configuración)
- Conexiones a BD/cache están listas
- Dependencias externas están disponibles
- Aplicación calentó caches

### Diferencia Clave: Liveness vs Readiness

| Aspecto | Liveness | Readiness |
|---------|----------|-----------|
| **Pregunta** | ¿Está vivo? | ¿Está listo? |
| **Acción al fallar** | **Reinicia** contenedor | **Quita** del Service |
| **Propósito** | Recuperar de deadlocks | Controlar tráfico |
| **Uso típico** | Detección de bugs críticos | Manejo de dependencias |

### Ejemplo: Aplicación con Base de Datos

Ver: [`ejemplos/02-readiness/readiness-database-check.yaml`](ejemplos/02-readiness/readiness-database-check.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: backend-api
  labels:
    app: backend
spec:
  containers:
  - name: api
    image: mycompany/api:v1.0
    ports:
    - containerPort: 8080
    
    readinessProbe:
      httpGet:
        path: /ready      # Endpoint que verifica BD
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      successThreshold: 1  # Un éxito = Listo
      failureThreshold: 3  # 3 fallos = No listo
```

**Endpoint `/ready` verifica**:
```javascript
// Pseudocódigo del endpoint /ready
app.get('/ready', async (req, res) => {
  try {
    // Verifica conexión a BD
    await database.ping();
    
    // Verifica conexión a cache
    await redis.ping();
    
    // Verifica API externa crítica
    await fetch('https://critical-service/ping');
    
    // Todo OK → Listo para tráfico
    res.status(200).send('OK');
  } catch (error) {
    // Alguna dependencia falla → No recibir tráfico
    res.status(500).send('Not Ready');
  }
});
```

### Ejemplo: TCP Socket

Ver: [`ejemplos/02-readiness/readiness-tcp-socket.yaml`](ejemplos/02-readiness/readiness-tcp-socket.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: goproxy
  labels:
    app: goproxy
spec:
  containers:
  - name: goproxy
    image: registry.k8s.io/goproxy:0.1
    ports:
    - containerPort: 8080
    
    readinessProbe:
      tcpSocket:
        port: 8080        # Verifica que el puerto esté abierto
      initialDelaySeconds: 5
      periodSeconds: 10
```

**Cómo funciona TCP Probe**:
1. Kubelet intenta abrir conexión TCP al puerto 8080
2. ✅ Conexión exitosa → Ready
3. ❌ Conexión falla → Not Ready (sin tráfico del Service)

---

## 4. Tipos de Verificaciones

Kubernetes soporta **4 mecanismos** para ejecutar probes:

### 4.1. HTTP GET (`httpGet`)

**Uso**: APIs REST, aplicaciones web

Ver: [`ejemplos/05-http/http-get-custom-headers.yaml`](ejemplos/05-http/http-get-custom-headers.yaml)

```yaml
livenessProbe:
  httpGet:
    path: /healthz          # Ruta a verificar
    port: 8080              # Puerto
    scheme: HTTP            # HTTP o HTTPS
    httpHeaders:            # Headers personalizados
    - name: X-Custom-Header
      value: MyValue
    - name: Authorization
      value: Bearer token123
  initialDelaySeconds: 10
  periodSeconds: 5
```

**Códigos de estado**:
- ✅ **Éxito**: 200-399
- ❌ **Fallo**: < 200 o ≥ 400

**⚠️ Limitaciones**:
- Kubelet lee solo los primeros **10 KiB** del response body
- Para respuestas grandes, usar endpoint dedicado de health check

### 4.2. TCP Socket (`tcpSocket`)

**Uso**: Bases de datos, servidores TCP puros

Ver: [`ejemplos/06-tcp/tcp-socket-redis.yaml`](ejemplos/06-tcp/tcp-socket-redis.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis-server
spec:
  containers:
  - name: redis
    image: redis:7-alpine
    ports:
    - containerPort: 6379
    
    livenessProbe:
      tcpSocket:
        port: 6379          # Puerto de Redis
      initialDelaySeconds: 15
      periodSeconds: 20
```

**Cómo funciona**:
- Kubelet intenta abrir socket TCP
- ✅ Conexión exitosa = Probe pasa
- ❌ Conexión rechazada/timeout = Probe falla

### 4.3. Comando (`exec`)

**Uso**: Verificaciones personalizadas, scripts complejos

Ver: [`ejemplos/07-exec/exec-custom-script.yaml`](ejemplos/07-exec/exec-custom-script.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgres-db
spec:
  containers:
  - name: postgres
    image: postgres:16-alpine
    env:
    - name: POSTGRES_PASSWORD
      value: secretpassword
    
    livenessProbe:
      exec:
        command:
        - sh
        - -c
        - pg_isready -U postgres && psql -U postgres -c 'SELECT 1'
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
```

**Códigos de salida**:
- ✅ **Éxito**: Exit code = `0`
- ❌ **Fallo**: Exit code ≠ `0`

### 4.4. gRPC (`grpc`)

⚙️ **Feature State**: Kubernetes v1.27+ (Stable)

**Uso**: Aplicaciones gRPC con gRPC Health Checking Protocol

Ver: [`ejemplos/05-http/grpc-etcd-probe.yaml`](ejemplos/05-http/grpc-etcd-probe.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: etcd-grpc
spec:
  containers:
  - name: etcd
    image: registry.k8s.io/etcd:3.5.1-0
    command:
    - /usr/local/bin/etcd
    - --listen-client-urls=http://0.0.0.0:2379
    ports:
    - containerPort: 2379
    
    livenessProbe:
      grpc:
        port: 2379
        service: liveness   # Nombre del servicio gRPC (opcional)
      initialDelaySeconds: 10
      periodSeconds: 5
```

---

## 5. Parámetros de Configuración

Todas las probes comparten estos parámetros:

| Parámetro | Descripción | Default | Mínimo |
|-----------|-------------|---------|--------|
| **`initialDelaySeconds`** | Segundos antes de la primera probe | `0` | `0` |
| **`periodSeconds`** | Intervalo entre probes | `10` | `1` |
| **`timeoutSeconds`** | Timeout por probe | `1` | `1` |
| **`successThreshold`** | Éxitos consecutivos para considerar OK | `1` | `1` |
| **`failureThreshold`** | Fallos consecutivos para considerar KO | `3` | `1` |
| **`terminationGracePeriodSeconds`** | Tiempo para shutdown graceful | `30` | `1` |

### Ejemplos de Configuración

#### Aplicación de Arranque Rápido

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 5   # Arranca rápido
  periodSeconds: 10
  timeoutSeconds: 2
  failureThreshold: 3      # Tolerante
```

#### Aplicación de Arranque Lento

```yaml
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 30     # 30 × 10s = 5 min max

livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 10
  failureThreshold: 3
```

#### Aplicación Crítica (Alta Disponibilidad)

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5         # Verifica frecuentemente
  successThreshold: 1      # Rápido para marcar como Ready
  failureThreshold: 2      # Rápido para quitar del Service

livenessProbe:
  httpGet:
    path: /live
    port: 8080
  periodSeconds: 30        # Menos frecuente
  failureThreshold: 5      # Muy tolerante a fallos temporales
```

---

## 6. Probes Combinadas

### Patrón Recomendado

Ver: [`ejemplos/04-combinados/probes-completas.yaml`](ejemplos/04-combinados/probes-completas.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: production
  template:
    metadata:
      labels:
        app: production
    spec:
      containers:
      - name: app
        image: mycompany/app:v2.0
        ports:
        - name: http
          containerPort: 8080
        
        # 1. Startup: Permite arranque lento
        startupProbe:
          httpGet:
            path: /startup
            port: http
          initialDelaySeconds: 0
          periodSeconds: 10
          failureThreshold: 30    # Hasta 5 minutos
        
        # 2. Readiness: Controla tráfico
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        
        # 3. Liveness: Detecta deadlocks
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
          timeoutSeconds: 5
```

### Endpoints de Ejemplo

```go
// Pseudocódigo de los endpoints

// /startup - Verifica que la app haya arrancado
GET /startup
  if app.isInitialized() {
    return 200 OK
  } else {
    return 503 Service Unavailable
  }

// /ready - Verifica dependencias
GET /ready
  if database.isConnected() && 
     cache.isConnected() && 
     externalAPI.isAvailable() {
    return 200 OK
  } else {
    return 503 Service Unavailable
  }

// /health - Verifica que la app esté viva
GET /health
  if app.canProcessRequests() {
    return 200 OK
  } else {
    return 500 Internal Server Error
  }
```

---

## 7. Named Ports

Puedes usar **nombres de puerto** en lugar de números para mayor claridad:

Ver: [`ejemplos/05-http/named-ports.yaml`](ejemplos/05-http/named-ports.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-named-ports
spec:
  containers:
  - name: nginx
    image: nginx:1.27-alpine
    ports:
    - name: http-port     # ← Nombre del puerto
      containerPort: 80
    - name: metrics-port
      containerPort: 9090
    
    livenessProbe:
      httpGet:
        path: /
        port: http-port   # ← Usa el nombre
      periodSeconds: 10
    
    readinessProbe:
      httpGet:
        path: /metrics
        port: metrics-port  # ← Usa el nombre
      periodSeconds: 5
```

**Ventajas**:
- ✅ Más legible
- ✅ Fácil de cambiar puerto sin modificar probes
- ✅ Auto-documentación

---

## 8. Buenas Prácticas

### 8.1. Diseño de Endpoints de Health

✅ **DO**:
```yaml
# Endpoint dedicado y ligero
GET /health
  - Verifica componentes críticos
  - Respuesta < 1 KB
  - Timeout < 1 segundo
  - Sin efectos secundarios
```

❌ **DON'T**:
```yaml
# Endpoint pesado
GET /health
  - Consulta BD compleja ❌
  - Genera reportes ❌
  - Response > 10 KB ❌
  - Timeout > 5 segundos ❌
```

### 8.2. Configuración de Timeouts

```yaml
# ✅ BIEN: Timeouts progresivos
startupProbe:
  periodSeconds: 10
  failureThreshold: 30   # 5 min total

livenessProbe:
  periodSeconds: 10
  failureThreshold: 3    # 30s total

readinessProbe:
  periodSeconds: 5
  failureThreshold: 2    # 10s total
```

### 8.3. Liveness vs Readiness

| Situación | Liveness | Readiness |
|-----------|----------|-----------|
| **Deadlock/colgado** | ✅ Sí | Opcional |
| **Dependencia caída** | ❌ No | ✅ Sí |
| **Alta carga temporal** | ❌ No | ✅ Sí |
| **Bug crítico** | ✅ Sí | ✅ Sí |
| **Calentando cache** | ❌ No | ✅ Sí |

### 8.4. Evitar Cascading Failures

```yaml
# ❌ MAL: Liveness muy sensible
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 2
  failureThreshold: 1     # ← PELIGRO
  timeoutSeconds: 1

# ✅ BIEN: Liveness tolerante
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 10
  failureThreshold: 5     # ← Permite transitorios
  timeoutSeconds: 3
```

### 8.5. Startup para Apps Legacy

```yaml
# App que tarda 10 minutos en arrancar
startupProbe:
  httpGet:
    path: /started
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 30
  failureThreshold: 20    # 30s × 20 = 10 min
  
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 60
  failureThreshold: 3
```

---

## 9. Troubleshooting

### Problema 1: Pod en CrashLoopBackOff

**Síntoma**:
```bash
kubectl get pods
# NAME       READY   STATUS             RESTARTS   AGE
# myapp-abc  0/1     CrashLoopBackOff   5          3m
```

**Diagnóstico**:
```bash
# Ver eventos del Pod
kubectl describe pod myapp-abc

# Salida típica:
# Warning  Unhealthy  1m (x6 over 3m)  kubelet  Liveness probe failed: HTTP probe failed with statuscode: 500
# Normal   Killing    1m (x3 over 3m)  kubelet  Container myapp failed liveness probe, will be restarted
```

**Soluciones**:
1. Incrementar `initialDelaySeconds`
2. Incrementar `failureThreshold`
3. Revisar logs del contenedor: `kubectl logs myapp-abc`
4. Agregar Startup Probe si el arranque es lento

### Problema 2: Pod Ready pero sin Tráfico

**Síntoma**:
```bash
kubectl get pods
# NAME       READY   STATUS    RESTARTS   AGE
# myapp-abc  1/1     Running   0          5m

# Pero no recibe tráfico del Service
```

**Diagnóstico**:
```bash
# Ver endpoints del Service
kubectl get endpoints myservice

# Si está vacío o sin la IP del Pod:
# NAME        ENDPOINTS   AGE
# myservice   <none>      10m
```

**Causas**:
- Readiness Probe fallando
- Labels del Pod no coinciden con selector del Service
- Puerto incorrecto en Readiness Probe

**Solución**:
```bash
# Ver estado de Readiness
kubectl describe pod myapp-abc | grep -A10 "Readiness"

# Verificar labels
kubectl get pod myapp-abc --show-labels
kubectl get service myservice -o yaml | grep selector -A5
```

### Problema 3: Probes con Timeout

**Síntoma**:
```bash
kubectl describe pod myapp-abc
# Warning  Unhealthy  1m  kubelet  Readiness probe failed: Get "http://10.244.0.5:8080/ready": context deadline exceeded
```

**Causas**:
- Endpoint muy lento
- `timeoutSeconds` muy bajo
- Red lenta/congestionada

**Solución**:
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  timeoutSeconds: 5      # ← Incrementar
  periodSeconds: 10      # ← Menos frecuente
```

### Problema 4: Reiniciar al Iniciar bajo Carga

**Síntoma**: Pods se reinician al recibir tráfico inicial

**Causa**: Liveness Probe falla mientras la app está procesando requests iniciales

**Solución**: Usar Startup Probe
```yaml
startupProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 5
  failureThreshold: 12   # 1 minuto de gracia

livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 30      # Menos agresiva
```

---

## 10. Comandos Útiles

### Verificar Estado de Probes

```bash
# Ver eventos relacionados con probes
kubectl describe pod <pod-name> | grep -A10 "Liveness\|Readiness\|Startup"

# Ver solo eventos de probes fallidas
kubectl get events --field-selector involvedObject.name=<pod-name>,reason=Unhealthy

# Ver configuración de probes
kubectl get pod <pod-name> -o yaml | grep -A15 "livenessProbe\|readinessProbe\|startupProbe"
```

### Monitorear Probes en Tiempo Real

```bash
# Watch de Pods
kubectl get pods -w

# Watch de eventos
kubectl get events --watch | grep probe

# Logs del kubelet (en el nodo)
journalctl -u kubelet -f | grep probe
```

### Debugging de Probes

```bash
# Ejecutar comando de exec probe manualmente
kubectl exec <pod-name> -- cat /tmp/healthy

# Probar HTTP probe manualmente
kubectl exec <pod-name> -- wget -O- http://localhost:8080/health

# Probar TCP probe manualmente
kubectl exec <pod-name> -- nc -zv localhost 8080
```

---

## 11. Ejemplos Completos por Tecnología

### Node.js + Express

Ver: [`ejemplos/04-combinados/nodejs-express-probes.yaml`](ejemplos/04-combinados/nodejs-express-probes.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nodejs
  template:
    metadata:
      labels:
        app: nodejs
    spec:
      containers:
      - name: app
        image: mycompany/nodejs-app:1.0
        ports:
        - name: http
          containerPort: 3000
        
        startupProbe:
          httpGet:
            path: /startup
            port: http
          failureThreshold: 30
          periodSeconds: 10
        
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Código de endpoints** (`server.js`):
```javascript
const express = require('express');
const app = express();

let isStarted = false;
let isReady = false;

// Simula inicialización
setTimeout(() => {
  isStarted = true;
  isReady = true;
}, 5000);

app.get('/startup', (req, res) => {
  if (isStarted) {
    res.status(200).send('Started');
  } else {
    res.status(503).send('Starting...');
  }
});

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.get('/ready', async (req, res) => {
  try {
    // Verifica BD
    await db.ping();
    res.status(200).send('Ready');
  } catch (error) {
    res.status(503).send('Not Ready');
  }
});

app.listen(3000);
```

### Python + Flask

Ver: [`ejemplos/04-combinados/python-flask-probes.yaml`](ejemplos/04-combinados/python-flask-probes.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: python
  template:
    metadata:
      labels:
        app: python
    spec:
      containers:
      - name: app
        image: mycompany/python-app:1.0
        ports:
        - name: http
          containerPort: 5000
        
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Código de endpoints** (`app.py`):
```python
from flask import Flask, jsonify
import psycopg2

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/ready')
def ready():
    try:
        # Verifica conexión a PostgreSQL
        conn = psycopg2.connect(
            host="postgres",
            database="mydb",
            user="user",
            password="password"
        )
        conn.close()
        return jsonify({"status": "ready"}), 200
    except Exception as e:
        return jsonify({"status": "not ready", "error": str(e)}), 503

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

---

## 12. Checklist de Configuración

### ✅ Antes de Producción

```yaml
# 1. ¿Necesitas Startup Probe?
[ ] Aplicación tarda > 30s en arrancar
[ ] Aplicación legacy con arranque variable
→ Agregar startupProbe con failureThreshold alto

# 2. ¿Liveness Probe configurada?
[ ] Endpoint /health implementado
[ ] initialDelaySeconds > tiempo de arranque
[ ] failureThreshold ≥ 3 (tolerante)
[ ] timeoutSeconds adecuado

# 3. ¿Readiness Probe configurada?
[ ] Endpoint /ready verifica dependencias
[ ] periodSeconds entre 5-10s
[ ] Pod solo recibe tráfico cuando está listo

# 4. ¿Endpoints eficientes?
[ ] Respuesta < 1 KB
[ ] Timeout < 1 segundo
[ ] Sin efectos secundarios
[ ] No consultas pesadas a BD

# 5. ¿Configuración probada?
[ ] Testear en staging
[ ] Simular fallos (matar BD, etc.)
[ ] Verificar comportamiento bajo carga
[ ] Monitorear métricas de probes
```

---

## Recursos Adicionales

### Documentación Oficial

- **Kubernetes Probes**: [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- **Pod Lifecycle**: [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- **Container Probes**: [Container Probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)

### Módulos Relacionados

- **[Módulo 11 - Resource Limits](../modulo-11-resource-limits-pods/)**: Configuración de recursos de Pods
- **[Módulo 13 - ConfigMaps y Variables](../modulo-13-configmaps-variables/)**: Configuración de aplicaciones
- **[Módulo 14 - Secrets](../modulo-14-secrets-data-sensible/)**: Gestión de credenciales

### Herramientas

- **k9s**: Monitor de recursos en tiempo real con probes
- **Lens**: IDE de Kubernetes con visualización de probes
- **Prometheus**: Métricas de probes y alertas

---

## Siguientes Pasos

1. ✅ Completar **[Laboratorio 1](laboratorios/lab-01-probes-basico.md)**: Configuración básica de Liveness y Readiness
2. ✅ Completar **[Laboratorio 2](laboratorios/lab-02-startup-avanzado.md)**: Startup Probes y casos avanzados
3. ✅ Completar **[Laboratorio 3](laboratorios/lab-03-troubleshooting.md)**: Debugging y troubleshooting de probes
4. 📖 Leer **[Módulo 13 - ConfigMaps](../modulo-13-configmaps-variables/)**: Para externalizar configuración de endpoints

---

**✅ Checklist de Conceptos**:
- [ ] Entiendes la diferencia entre Liveness, Readiness y Startup
- [ ] Sabes cuándo usar cada tipo de probe
- [ ] Conoces los 4 mecanismos de verificación (HTTP, TCP, exec, gRPC)
- [ ] Puedes configurar parámetros (initialDelay, period, timeout, thresholds)
- [ ] Sabes diagnosticar problemas comunes con probes
- [ ] Has implementado probes en tus aplicaciones

**🎯 Objetivo**: Aplicaciones resilientes con auto-recuperación y control de tráfico inteligente.
