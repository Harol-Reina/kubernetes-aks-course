# 📚 RESUMEN - Módulo 12: Health Checks y Probes

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre **Health Checks** - las verificaciones automáticas de salud que permiten a Kubernetes detectar y recuperarse de fallos sin intervención manual. Aprenderás a configurar las tres probes (Startup, Liveness, Readiness) y cuándo usar cada una.

**Duración**: 5.5 horas (teoría + labs)  
**Nivel**: Intermedio  
**Prerequisitos**: Pods, Deployments, Services

---

## 📋 Objetivos de Aprendizaje

Al completar este módulo serás capaz de:

### Fundamentos
- ✅ Diferenciar entre **Startup**, **Liveness** y **Readiness** probes
- ✅ Explicar el ciclo de vida de un Pod
- ✅ Identificar cuándo usar cada tipo de probe
- ✅ Entender las acciones de Kubernetes al fallar cada probe

### Técnico
- ✅ Configurar HTTP, TCP y Exec probes
- ✅ Ajustar parámetros (delays, timeouts, thresholds)
- ✅ Combinar múltiples probes
- ✅ Diagnosticar fallos con `kubectl describe`
- ✅ Usar named ports

### Avanzado
- ✅ Diseñar endpoints `/health` y `/ready` en apps
- ✅ Optimizar startup para aplicaciones lentas
- ✅ Implementar graceful shutdown
- ✅ Aplicar best practices en producción
- ✅ Troubleshoot availability issues

---

## 🗺️ Estructura de Aprendizaje

### Fase 1: Conceptos Fundamentales (30 min)
**Teoría**: Secciones 1-2 del README

#### ¿Qué son las Probes?

**Probes** = Verificaciones automáticas de salud que Kubernetes ejecuta periódicamente en contenedores.

**¿Por qué son necesarias?**

❌ **Sin probes**:
- App colgada pero proceso corriendo → No se detecta
- App arrancando → Recibe tráfico antes de estar lista
- Servidor con BD desconectada → Sigue recibiendo requests
- Memory leak → Sigue funcionando hasta colapsar

✅ **Con probes**:
- Detección automática de problemas
- Reinicio automático de contenedores fallidos
- Tráfico solo a Pods listos
- Alta disponibilidad sin intervención manual

#### Las 3 Probes

**1. Startup Probe** (¿Ha arrancado?)
- **Cuándo**: Durante el inicio del contenedor
- **Propósito**: Dar tiempo extra a apps lentas para arrancar
- **Fallo**: Reinicia el Pod
- **Uso**: Apps con startup lento (Java, ML models, migración BD)

**2. Liveness Probe** (¿Está vivo?)
- **Cuándo**: Después del startup, durante toda la vida del contenedor
- **Propósito**: Detectar deadlocks, hangs, procesos zombies
- **Fallo**: Reinicia el contenedor
- **Uso**: Detectar app "congelada" que necesita restart

**3. Readiness Probe** (¿Está listo?)
- **Cuándo**: Durante toda la vida del contenedor
- **Propósito**: Controlar si el Pod debe recibir tráfico
- **Fallo**: Elimina del Service (no reinicia)
- **Uso**: Control de tráfico (sobrecarga temporal, dependencias caídas)

#### Tabla Comparativa

| Aspecto | Startup | Liveness | Readiness |
|---------|---------|----------|-----------|
| **¿Cuándo?** | Solo al inicio | Toda la vida | Toda la vida |
| **¿Qué verifica?** | Arrancó | Está vivo | Está listo |
| **Al fallar** | Reinicia Pod | Reinicia contenedor | Elimina de Service |
| **Se deshabilita** | Tras 1er éxito | Nunca | Nunca |
| **Uso típico** | Apps lentas | Deadlocks | Control tráfico |

#### Ciclo de Vida con Probes

```
Pod creado
    ↓
Contenedor inicia
    ↓
[STARTUP PROBE] ← Si falla: reinicia
    ↓ (éxito)
Startup se deshabilita
    ↓
[LIVENESS PROBE] ← Si falla: reinicia contenedor
[READINESS PROBE] ← Si falla: elimina de Service
    ↓ (ambas exitosas)
Pod recibe tráfico del Service
```

#### Ejemplo Mental

**Restaurante**:
- **Startup**: ¿El chef llegó y encendió la estufa?
- **Liveness**: ¿El chef sigue despierto? (no está desmayado)
- **Readiness**: ¿El chef puede cocinar ahora? (tiene ingredientes, estufa caliente)

Si chef no llegó (startup fail) → Contratar otro chef  
Si chef se desmayó (liveness fail) → Despertarlo/reemplazarlo  
Si chef sin ingredientes (readiness fail) → No tomar pedidos hasta que lleguen

---

### Fase 2: Startup Probe - Apps Lentas (30 min)
**Teoría**: Sección 2 del README

#### ¿Cuándo usar Startup Probe?

**Problema**: App tarda 2 minutos en arrancar (ej: Java con Spring Boot, cargar ML model)

**Sin Startup Probe**:
- Liveness probe empieza inmediatamente
- Falla porque app aún no respondió
- Kubernetes reinicia el Pod
- Loop infinito de reinicios (CrashLoopBackOff)

**Con Startup Probe**:
- Startup probe verifica periódicamente
- Liveness/Readiness NO se ejecutan hasta que Startup tenga éxito
- Le da tiempo suficiente a la app para arrancar

#### Configuración Básica

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: slow-app
spec:
  containers:
  - name: app
    image: slow-java-app:1.0
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 10   # Esperar 10s antes de empezar
      periodSeconds: 10          # Verificar cada 10s
      failureThreshold: 30       # Fallar tras 30 intentos
      # Total: 10 + (10 * 30) = 310 segundos = 5 min 10s
```

**Cálculo de tiempo máximo**:
```
Tiempo máximo = initialDelaySeconds + (periodSeconds * failureThreshold)
Ejemplo: 10 + (10 * 30) = 310 segundos
```

#### Estrategia para Apps Lentas

**Opción 1: Startup Probe generosa**
```yaml
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  periodSeconds: 5
  failureThreshold: 60  # 5 * 60 = 5 minutos
```

**Opción 2: Startup + Liveness separadas**
```yaml
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  periodSeconds: 10
  failureThreshold: 30  # 5 minutos

livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  periodSeconds: 10
  failureThreshold: 3   # Solo 30s después del startup
```

**Lab 2**: [Startup Avanzado](laboratorios/lab-02-startup-avanzado.md) - 50 min

---

### Fase 3: Liveness Probe - Detección de Fallos (30 min)
**Teoría**: Sección 3 del README

#### ¿Cuándo usar Liveness Probe?

**Liveness** detecta cuando la app está en un estado irrecuperable y necesita **reinicio**.

**Escenarios típicos**:
- **Deadlock**: Threads bloqueados esperándose mutuamente
- **Memory leak**: App consumió toda la memoria y no responde
- **Infinite loop**: Proceso atascado en loop sin fin
- **Dependency failure**: Cliente HTTP colgado esperando respuesta

**Ejemplo: Deadlock**
```python
# App en Python con deadlock
lock1.acquire()
lock2.acquire()  # Otro thread tiene lock2 esperando lock1
# → App congelada, proceso vivo pero no responde
```

**Liveness probe lo detecta**:
- Intenta HTTP GET `/health`
- No hay respuesta (timeout)
- Tras 3 fallos → Kubernetes reinicia el contenedor

#### Configuración Básica

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-liveness
spec:
  containers:
  - name: app
    image: myapp:1.0
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 30  # Esperar 30s tras inicio
      periodSeconds: 10        # Verificar cada 10s
      timeoutSeconds: 5        # Timeout de request: 5s
      failureThreshold: 3      # Fallar tras 3 intentos
      # Reinicia tras: 30s + (10s * 3) = 60s desde inicio
```

#### Tipos de Verificaciones

**HTTP GET** (más común):
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
    httpHeaders:
    - name: Custom-Header
      value: MyValue
```

**TCP Socket** (para apps no-HTTP):
```yaml
livenessProbe:
  tcpSocket:
    port: 3306  # Ej: MySQL
  periodSeconds: 10
```

**Exec Command**:
```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  periodSeconds: 5
```

#### ⚠️ Errores Comunes con Liveness

**Error 1: Liveness muy sensible**
```yaml
# ❌ MALO
livenessProbe:
  httpGet:
    path: /health
  periodSeconds: 5
  failureThreshold: 1  # Reinicia tras 1 fallo
  # Problema: Un spike temporal reinicia el Pod
```

```yaml
# ✅ BUENO
livenessProbe:
  httpGet:
    path: /health
  periodSeconds: 10
  failureThreshold: 3  # Reinicia tras 3 fallos (30s)
  # Tolera problemas temporales
```

**Error 2: Liveness dependiente de servicios externos**
```yaml
# ❌ MALO: Verifica BD externa
livenessProbe:
  httpGet:
    path: /health-with-db
  # Si BD cae, reinicia todos los Pods → Empeora el problema
```

```yaml
# ✅ BUENO: Solo verifica el proceso
livenessProbe:
  httpGet:
    path: /health-internal
  # Solo verifica que el proceso responda
```

**Regla de oro**: Liveness debe verificar **solo el proceso local**, no dependencias externas.

---

### Fase 4: Readiness Probe - Control de Tráfico (30 min)
**Teoría**: Sección 4 del README

#### ¿Cuándo usar Readiness Probe?

**Readiness** controla si el Pod debe **recibir tráfico**, pero NO lo reinicia.

**Escenarios típicos**:
- **Startup**: App arrancando (cache cargando, conexiones a BD)
- **Sobrecarga temporal**: CPU alto, muchas requests en cola
- **Dependencia caída**: BD temporalmente no disponible
- **Mantenimiento**: Drenando requests antes de shutdown

**Diferencia clave con Liveness**:
- **Liveness**: Problema permanente → Reiniciar
- **Readiness**: Problema temporal → Pausar tráfico

#### Ejemplo: Aplicación con Cache

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-cache
spec:
  containers:
  - name: app
    image: myapp:1.0
    readinessProbe:
      httpGet:
        path: /ready    # Diferente de /health
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 2
    livenessProbe:
      httpGet:
        path: /health   # Solo verifica proceso
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
```

**Endpoint `/ready`** (lógica en la app):
```python
@app.route('/ready')
def ready():
    if cache_loaded and db_connected:
        return "OK", 200
    else:
        return "Not Ready", 503  # No recibir tráfico aún
```

**Endpoint `/health`** (lógica en la app):
```python
@app.route('/health')
def health():
    # Solo verifica que el proceso responda
    return "OK", 200
```

#### Comportamiento en Service

**Pod con Readiness passing**:
```bash
kubectl get pod myapp
# NAME    READY   STATUS    RESTARTS   AGE
# myapp   1/1     Running   0          5m

kubectl get endpoints myservice
# NAME        ENDPOINTS           AGE
# myservice   10.244.0.5:8080     5m
# ↑ Pod en el endpoint del Service (recibe tráfico)
```

**Pod con Readiness failing**:
```bash
kubectl get pod myapp
# NAME    READY   STATUS    RESTARTS   AGE
# myapp   0/1     Running   0          5m
#         ↑ 0/1 = No ready

kubectl get endpoints myservice
# NAME        ENDPOINTS   AGE
# myservice   <none>      5m
# ↑ Sin endpoints (NO recibe tráfico)
```

**Importante**: Pod sigue corriendo (no se reinicia), solo se elimina del Service.

#### Estrategia para Graceful Shutdown

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: myapp:1.0
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          periodSeconds: 5
        lifecycle:
          preStop:
            exec:
              command:
              - sh
              - -c
              - sleep 15  # Dar tiempo a que readiness falle
```

**Flujo de shutdown**:
1. Kubernetes envía SIGTERM al Pod
2. Readiness empieza a fallar → Se elimina del Service
3. preStop espera 15s (requests en progreso finalizan)
4. Pod se termina gracefully

**Lab 1**: [Probes Básico](laboratorios/lab-01-probes-basico.md) - 45 min

---

### Fase 5: Tipos de Verificaciones (30 min)
**Teoría**: Sección 5 del README

#### 1. HTTP GET Probe (más común)

**Cómo funciona**:
1. Kubernetes hace HTTP GET a `http://<pod-ip>:<port><path>`
2. Status code `200-399` → Éxito
3. Otro status code o timeout → Fallo

**Configuración completa**:
```yaml
httpGet:
  path: /health           # Ruta del endpoint
  port: 8080              # Puerto (number o name)
  host: 127.0.0.1         # Opcional (default: pod IP)
  scheme: HTTP            # HTTP o HTTPS
  httpHeaders:            # Headers personalizados
  - name: X-Custom-Header
    value: MyValue
```

**Ejemplo: HTTPS con custom header**:
```yaml
readinessProbe:
  httpGet:
    path: /api/health
    port: 8443
    scheme: HTTPS
    httpHeaders:
    - name: Authorization
      value: Bearer token123
```

---

#### 2. TCP Socket Probe

**Cómo funciona**:
1. Kubernetes intenta abrir conexión TCP a `<pod-ip>:<port>`
2. Conexión exitosa → Éxito
3. Timeout o conexión rechazada → Fallo

**Cuándo usar**:
- Servicios sin HTTP (MySQL, Redis, PostgreSQL)
- Verificar solo que el puerto esté abierto

**Ejemplo: PostgreSQL**:
```yaml
livenessProbe:
  tcpSocket:
    port: 5432
  initialDelaySeconds: 30
  periodSeconds: 10
```

**Ejemplo: Redis**:
```yaml
readinessProbe:
  tcpSocket:
    port: 6379
  periodSeconds: 5
```

---

#### 3. Exec Command Probe

**Cómo funciona**:
1. Kubernetes ejecuta comando dentro del contenedor
2. Exit code `0` → Éxito
3. Exit code diferente → Fallo

**Cuándo usar**:
- Verificaciones custom complejas
- Servicios sin HTTP/TCP standard
- Scripts de validación

**Ejemplo: Verificar archivo**:
```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  periodSeconds: 5
```

**Ejemplo: Script custom**:
```yaml
readinessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - |
      redis-cli ping | grep PONG &&
      redis-cli get test_key | grep -q value
  periodSeconds: 10
```

**Ejemplo: PostgreSQL con pg_isready**:
```yaml
livenessProbe:
  exec:
    command:
    - pg_isready
    - -U
    - postgres
  periodSeconds: 10
```

**⚠️ Cuidado**: Exec probe tiene overhead (crea proceso, ejecuta comando). Preferir HTTP o TCP si es posible.

---

### Fase 6: Parámetros de Configuración (20 min)
**Teoría**: Sección 6 del README

#### Parámetros Disponibles

```yaml
probe:
  initialDelaySeconds: 30   # Espera antes de la 1ra verificación
  periodSeconds: 10         # Frecuencia de verificación
  timeoutSeconds: 5         # Timeout por request
  successThreshold: 1       # Éxitos consecutivos para considerar OK
  failureThreshold: 3       # Fallos consecutivos para considerar failed
```

#### 1. initialDelaySeconds

**¿Qué hace?**: Espera X segundos después de que el contenedor inicie antes de empezar a verificar.

**Cuándo ajustar**:
- App tarda en arrancar → Aumentar
- App arranca rápido → Disminuir (menos latencia)

**Ejemplos**:
```yaml
# App rápida (Node.js simple)
initialDelaySeconds: 5

# App media (Python/Flask)
initialDelaySeconds: 15

# App lenta (Java/Spring Boot)
initialDelaySeconds: 60

# App muy lenta (ML model loading)
initialDelaySeconds: 120
```

---

#### 2. periodSeconds

**¿Qué hace?**: Cada cuántos segundos se ejecuta la verificación.

**Trade-off**:
- **Más frecuente** (ej: 5s): Detección rápida de fallos, más carga
- **Menos frecuente** (ej: 30s): Menos carga, detección más lenta

**Recomendaciones**:
```yaml
# Liveness (no crítico detectar rápido)
periodSeconds: 10-30

# Readiness (crítico para tráfico)
periodSeconds: 5-10

# Startup (más frecuente al inicio)
periodSeconds: 5
```

---

#### 3. timeoutSeconds

**¿Qué hace?**: Tiempo máximo que espera una respuesta antes de considerar fallo.

**Recomendaciones**:
```yaml
# HTTP GET rápido
timeoutSeconds: 1-3

# Exec command complejo
timeoutSeconds: 5-10

# TCP socket
timeoutSeconds: 1
```

**⚠️ Error común**: `timeoutSeconds` muy bajo → fallos falsos positivos.

---

#### 4. failureThreshold

**¿Qué hace?**: Cuántos fallos consecutivos antes de tomar acción (reiniciar o eliminar de Service).

**Recomendaciones**:
```yaml
# Liveness (tolerante a problemas temporales)
failureThreshold: 3-5

# Readiness (más sensible)
failureThreshold: 2-3

# Startup (generoso)
failureThreshold: 30-60
```

**Cálculo de tiempo hasta acción**:
```
Tiempo = periodSeconds * failureThreshold
Ejemplo: 10s * 3 = 30s hasta reinicio
```

---

#### 5. successThreshold

**¿Qué hace?**: Cuántos éxitos consecutivos para considerar OK después de un fallo.

**Valores**:
- `successThreshold: 1` (default) → 1 éxito es suficiente
- `successThreshold: 3` → Requiere 3 éxitos consecutivos

**Cuándo aumentar**:
- App con flapping (sube/baja rápidamente)
- Necesitas estabilidad antes de recibir tráfico

```yaml
# Readiness con estabilidad requerida
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  periodSeconds: 5
  successThreshold: 3  # 3 éxitos = 15s estable
```

---

### Fase 7: Probes Combinadas (20 min)
**Teoría**: Sección 7 del README

#### Combinando las 3 Probes

**Configuración completa**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: full-probes-example
spec:
  containers:
  - name: app
    image: myapp:1.0
    ports:
    - name: http
      containerPort: 8080
    
    # 1. STARTUP: App lenta (2 min para arrancar)
    startupProbe:
      httpGet:
        path: /healthz
        port: http        # Named port
      initialDelaySeconds: 10
      periodSeconds: 5
      failureThreshold: 24  # 10 + (5 * 24) = 130s max
    
    # 2. LIVENESS: Detectar deadlocks
    livenessProbe:
      httpGet:
        path: /healthz
        port: http
      initialDelaySeconds: 0  # No necesario (startup lo cubre)
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3     # 30s para reiniciar
    
    # 3. READINESS: Control de tráfico
    readinessProbe:
      httpGet:
        path: /ready      # Endpoint diferente
        port: http
      initialDelaySeconds: 0
      periodSeconds: 5
      failureThreshold: 2     # 10s para quitar de Service
```

#### Timeline de Ejecución

```
t=0s:   Pod inicia
t=10s:  Startup probe 1ra verificación
t=15s:  Startup probe 2da verificación
...
t=50s:  Startup probe éxito → Se deshabilita

t=50s:  Liveness probe inicia (cada 10s)
t=50s:  Readiness probe inicia (cada 5s)

t=55s:  Readiness éxito → Pod agregado al Service
        (empieza a recibir tráfico)

t=60s:  Liveness verifica (OK)
t=70s:  Liveness verifica (OK)
...
        (Continúan indefinidamente)
```

#### Named Ports

**Beneficio**: Más legible y portable.

```yaml
ports:
- name: http
  containerPort: 8080
- name: metrics
  containerPort: 9090

livenessProbe:
  httpGet:
    path: /health
    port: http      # Usa nombre en vez de número

readinessProbe:
  httpGet:
    path: /metrics
    port: metrics
```

**Lab 3**: [Troubleshooting](laboratorios/lab-03-troubleshooting.md) - 60 min

---

### Fase 8: Best Practices (30 min)
**Teoría**: Sección 8 del README

#### 1. Implementar Endpoints Dedicados

**En tu aplicación**:

**✅ BUENO: Endpoints separados**
```python
# Flask example
@app.route('/health')
def health():
    """Liveness: Solo verifica proceso"""
    return "OK", 200

@app.route('/ready')
def ready():
    """Readiness: Verifica dependencias"""
    try:
        # Check cache
        if not cache.is_loaded():
            return "Cache not loaded", 503
        
        # Check DB
        db.execute("SELECT 1")
        
        return "OK", 200
    except:
        return "Not ready", 503
```

**❌ MALO: Un solo endpoint para todo**
```python
@app.route('/health')
def health():
    # Verifica DB → Si DB cae, reinicia todos los Pods
    db.execute("SELECT 1")
    return "OK", 200
```

---

#### 2. Liveness Ligera, Readiness Completa

| Probe | Verifica | Tiempo |
|-------|----------|--------|
| **Liveness** | Solo proceso local | <100ms |
| **Readiness** | Proceso + dependencias | <500ms |

**Liveness** (`/health`):
```python
@app.route('/health')
def health():
    # Rápido y simple
    return {"status": "ok"}, 200
```

**Readiness** (`/ready`):
```python
@app.route('/ready')
def ready():
    checks = {
        "database": check_db(),
        "cache": check_cache(),
        "queue": check_queue()
    }
    
    if all(checks.values()):
        return {"status": "ready", "checks": checks}, 200
    else:
        return {"status": "not ready", "checks": checks}, 503
```

---

#### 3. Parámetros por Tipo de Aplicación

**Apps rápidas (Node.js, Go)**:
```yaml
startupProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 3
  failureThreshold: 10  # 30s max

livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  periodSeconds: 5
  failureThreshold: 2
```

**Apps lentas (Java, Python)**:
```yaml
startupProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 30  # 5 min max

livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 15
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  periodSeconds: 10
  failureThreshold: 3
```

**Bases de datos**:
```yaml
startupProbe:
  exec:
    command:
    - pg_isready
    - -U
    - postgres
  periodSeconds: 10
  failureThreshold: 30

livenessProbe:
  exec:
    command:
    - pg_isready
  periodSeconds: 30
  failureThreshold: 3

readinessProbe:
  exec:
    command:
    - psql
    - -U
    - postgres
    - -c
    - SELECT 1
  periodSeconds: 10
  failureThreshold: 3
```

---

#### 4. Evitar Dependencias Circulares

**❌ MALO: Service A depende de Service B**
```yaml
# Service A readiness verifica Service B
readinessProbe:
  httpGet:
    path: /health  # Llama a Service B
# Service B readiness verifica Service A
# → Ninguno se vuelve ready
```

**✅ BUENO: Readiness solo verifica local**
```yaml
readinessProbe:
  httpGet:
    path: /ready  # Solo verifica conexiones locales
```

---

#### 5. Tolerancia a Problemas Temporales

**❌ Muy sensible**:
```yaml
livenessProbe:
  httpGet:
    path: /health
  periodSeconds: 5
  failureThreshold: 1  # Reinicia tras 5s
```

**✅ Tolerante**:
```yaml
livenessProbe:
  httpGet:
    path: /health
  periodSeconds: 10
  failureThreshold: 3  # Reinicia tras 30s
```

---

### Fase 9: Troubleshooting (30 min)
**Teoría**: Sección 9 del README

#### Problema 1: CrashLoopBackOff

**Síntoma**:
```bash
kubectl get pods
# NAME    READY   STATUS             RESTARTS   AGE
# myapp   0/1     CrashLoopBackOff   5          5m
```

**Causa común**: Liveness probe falla repetidamente

**Diagnóstico**:
```bash
# Ver eventos
kubectl describe pod myapp

# Events:
# Liveness probe failed: HTTP probe failed with statuscode: 503
# Container will be restarted
```

**Soluciones**:
1. **Aumentar initialDelaySeconds** (app no tuvo tiempo de arrancar)
```yaml
livenessProbe:
  initialDelaySeconds: 60  # Era 30, ahora 60
```

2. **Aumentar failureThreshold** (más tolerante)
```yaml
livenessProbe:
  failureThreshold: 5  # Era 3, ahora 5
```

3. **Verificar endpoint** (hace el request manualmente)
```bash
kubectl exec myapp -- curl localhost:8080/health
```

---

#### Problema 2: Pod Running pero 0/1 Ready

**Síntoma**:
```bash
kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# myapp   0/1     Running   0          10m
#         ↑ No ready
```

**Causa**: Readiness probe fallando

**Diagnóstico**:
```bash
kubectl describe pod myapp

# Readiness probe failed: HTTP probe failed with statuscode: 503
```

**Soluciones**:
1. **Verificar endpoint `/ready`**
```bash
kubectl exec myapp -- curl localhost:8080/ready
# {"status": "not ready", "db": false}
# ↑ DB no conectada
```

2. **Ver logs**
```bash
kubectl logs myapp
# Error: Cannot connect to database
```

3. **Ajustar lógica de readiness** (menos estricta)
```python
@app.route('/ready')
def ready():
    # Era: requiere DB
    # Ahora: tolera DB temporal
    try:
        db.ping()
        return "OK", 200
    except:
        if startup_complete:  # Al menos arrancó
            return "OK", 200
        return "Not ready", 503
```

---

#### Problema 3: Service sin Endpoints

**Síntoma**:
```bash
kubectl get endpoints myservice
# NAME        ENDPOINTS   AGE
# myservice   <none>      10m
```

**Causa**: Ningún Pod está ready (readiness fallando)

**Diagnóstico**:
```bash
# Ver Pods del Deployment
kubectl get pods -l app=myapp

# NAME         READY   STATUS    RESTARTS   AGE
# myapp-abc    0/1     Running   0          10m
# myapp-def    0/1     Running   0          10m
# myapp-ghi    0/1     Running   0          10m
# ↑ Todos 0/1

# Describir uno
kubectl describe pod myapp-abc
# Readiness probe failed: ...
```

**Soluciones**:
1. Arreglar el problema de readiness (ver Problema 2)
2. Verificar selector del Service
```bash
kubectl get service myservice -o yaml | grep selector:
```

---

#### Problema 4: Reinicios Frecuentes

**Síntoma**:
```bash
kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# myapp   1/1     Running   15         30m
#                           ↑ Muchos restarts
```

**Causa**: Liveness probe muy sensible

**Diagnóstico**:
```bash
kubectl describe pod myapp

# Liveness probe failed: Get http://10.244.0.5:8080/health: dial tcp 10.244.0.5:8080: connect: connection refused
```

**Soluciones**:
1. **Aumentar timeout**
```yaml
livenessProbe:
  timeoutSeconds: 5  # Era 1, ahora 5
```

2. **Aumentar failureThreshold**
```yaml
livenessProbe:
  failureThreshold: 5  # Era 3
```

3. **Verificar endpoint no dependa de externos**
```python
# ❌ MALO
@app.route('/health')
def health():
    check_database()  # DB cae → liveness falla → reinicia
    
# ✅ BUENO
@app.route('/health')
def health():
    return "OK", 200  # Solo proceso
```

---

## 📝 Comandos Esenciales - Cheat Sheet

### Ver Estado de Probes

```bash
# Ver Pods con estado READY
kubectl get pods

# Describir Pod (ver eventos de probes)
kubectl describe pod <pod-name>

# Ver eventos recientes
kubectl get events --sort-by='.lastTimestamp' | grep -i probe

# Ver logs del contenedor
kubectl logs <pod-name>
```

### Configurar Probes

```bash
# Aplicar Pod con probes
kubectl apply -f pod-with-probes.yaml

# Editar probes de Deployment
kubectl edit deployment <deployment-name>

# Ver configuración de probes
kubectl get pod <pod-name> -o yaml | grep -A 10 "livenessProbe:"
```

### Troubleshooting

```bash
# Ver por qué Pod no está ready
kubectl describe pod <pod-name> | grep -A 5 "Readiness:"

# Ver por qué Pod se reinicia
kubectl describe pod <pod-name> | grep -A 5 "Liveness:"

# Ver endpoints del Service
kubectl get endpoints <service-name>

# Ejecutar curl manual dentro del Pod
kubectl exec <pod-name> -- curl localhost:8080/health

# Ver eventos de todos los Pods
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

---

## 🎯 Conceptos Clave para Recordar

### Las 3 Probes

```
STARTUP:   ¿Ha arrancado? → Reinicia si falla
LIVENESS:  ¿Está vivo? → Reinicia contenedor
READINESS: ¿Está listo? → Elimina de Service
```

### Cuándo Usar Cada Una

```
STARTUP:   Apps lentas (Java, ML, migraciones)
LIVENESS:  Detección de deadlocks, hangs
READINESS: Control de tráfico, dependencias
```

### Reglas de Oro

```
1. Liveness: Solo proceso local (no dependencias)
2. Readiness: Proceso + dependencias (puede fallar temporalmente)
3. Startup: Generoso con failureThreshold
4. Preferir HTTP sobre Exec (menos overhead)
5. Endpoints separados: /health vs /ready
```

### Parámetros Típicos

```yaml
# Liveness (tolerante)
periodSeconds: 10
failureThreshold: 3

# Readiness (sensible)
periodSeconds: 5
failureThreshold: 2

# Startup (generoso)
periodSeconds: 5
failureThreshold: 30
```

---

## ✅ Checklist de Dominio

Marca cuando domines cada concepto:

### Fundamentos
- [ ] Puedo explicar la diferencia entre Startup, Liveness y Readiness
- [ ] Sé cuándo usar cada tipo de probe
- [ ] Entiendo qué pasa cuando cada probe falla
- [ ] Conozco el ciclo de vida del Pod con probes

### Tipos de Verificaciones
- [ ] Sé configurar HTTP GET probes
- [ ] Sé configurar TCP Socket probes
- [ ] Sé configurar Exec Command probes
- [ ] Puedo elegir el tipo apropiado según la app

### Parámetros
- [ ] Entiendo initialDelaySeconds
- [ ] Sé ajustar periodSeconds según necesidad
- [ ] Puedo calcular tiempo hasta acción (period * threshold)
- [ ] Sé usar timeoutSeconds apropiadamente
- [ ] Entiendo failureThreshold vs successThreshold

### Configuración
- [ ] Puedo configurar las 3 probes en un Pod
- [ ] Sé usar named ports
- [ ] Puedo combinar probes efectivamente
- [ ] Entiendo cuándo startup se deshabilita

### Best Practices
- [ ] Implemento endpoints `/health` y `/ready` separados
- [ ] Liveness solo verifica proceso local
- [ ] Readiness verifica dependencias
- [ ] Ajusto parámetros según tipo de app
- [ ] Evito dependencias circulares

### Troubleshooting
- [ ] Diagnostico CrashLoopBackOff (liveness fallando)
- [ ] Resuelvo Pod 0/1 Ready (readiness fallando)
- [ ] Investigo Service sin endpoints
- [ ] Identifico reinicios frecuentes (liveness sensible)
- [ ] Uso `kubectl describe` efectivamente

### Práctica
- [ ] Completé Lab 01: Probes Básico
- [ ] Completé Lab 02: Startup Avanzado
- [ ] Completé Lab 03: Troubleshooting
- [ ] Implementé probes en apps propias

---

## 🎓 Evaluación Final

### Preguntas Clave
1. ¿Cuál es la diferencia entre Liveness y Readiness probe?
2. ¿Cuándo debería usar Startup probe?
3. ¿Qué sucede si Liveness probe falla 3 veces?
4. ¿Por qué Liveness no debe verificar dependencias externas?
5. ¿Cómo se calcula el tiempo máximo de startup?

<details>
<summary>Ver Respuestas</summary>

1. **Liveness vs Readiness**:
   - **Liveness**: Detecta app "muerta" → **Reinicia** contenedor
   - **Readiness**: Controla si recibe tráfico → **Elimina de Service** (no reinicia)

2. **Cuándo usar Startup**:
   - Apps con startup lento (>30s): Java, ML models, migraciones BD
   - Evita que Liveness reinicie durante arranque
   - Se deshabilita tras primer éxito

3. **Liveness falla 3 veces**:
   - Kubernetes **reinicia el contenedor**
   - RESTARTS counter incrementa
   - Puede llevar a CrashLoopBackOff si persiste

4. **Liveness solo local**:
   - Si verifica BD externa y BD cae → reinicia todos los Pods
   - Empeora el problema (thunder herd)
   - Mejor: Readiness verifica dependencias, Liveness solo proceso

5. **Tiempo máximo startup**:
   ```
   Tiempo = initialDelaySeconds + (periodSeconds * failureThreshold)
   Ejemplo: 10 + (5 * 30) = 160 segundos
   ```

</details>

### Escenario Práctico
Tienes un Deployment que no recibe tráfico. Los Pods están `0/1 Running`.

**Diagnóstico**:
```bash
kubectl describe pod myapp-abc
# Readiness probe failed: HTTP probe failed with statuscode: 503
```

**¿Qué harías?**

<details>
<summary>Ver Solución</summary>

**Análisis**:
- Pods corriendo (no problema de Liveness)
- 0/1 = Readiness fallando
- No en Service endpoints → Sin tráfico

**Pasos**:

**1. Verificar endpoint readiness manualmente**:
```bash
kubectl exec myapp-abc -- curl -v localhost:8080/ready
# < HTTP/1.1 503 Service Unavailable
# {"status": "not ready", "database": false}
```

**2. Ver logs**:
```bash
kubectl logs myapp-abc
# Error: Cannot connect to database at postgres:5432
```

**3. Verificar BD existe**:
```bash
kubectl get service postgres
# Error from server (NotFound): services "postgres" not found
```

**4. Solución**: Crear Service de BD
```bash
kubectl apply -f postgres-service.yaml
```

**5. Verificar recuperación**:
```bash
# Esperar unos segundos
kubectl get pods
# NAME         READY   STATUS    RESTARTS   AGE
# myapp-abc    1/1     Running   0          10m
#              ↑ Ahora ready

kubectl get endpoints myservice
# NAME        ENDPOINTS           AGE
# myservice   10.244.0.5:8080     10m
# ↑ Ahora tiene endpoints
```

**Alternativa**: Si BD no es crítica al inicio:
```python
# Ajustar lógica de readiness
@app.route('/ready')
def ready():
    # Tolerar BD temporal
    if not startup_phase:
        return "OK", 200
    
    try:
        db.ping()
        return "OK", 200
    except:
        return "Starting up", 503
```

</details>

---

## 🔗 Recursos Adicionales

### Documentación Oficial
- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)

### Labs del Módulo
1. [Lab 01 - Probes Básico](laboratorios/lab-01-probes-basico.md) - 45 min
2. [Lab 02 - Startup Avanzado](laboratorios/lab-02-startup-avanzado.md) - 50 min
3. [Lab 03 - Troubleshooting](laboratorios/lab-03-troubleshooting.md) - 60 min

### Ejemplos Prácticos
- [`ejemplos/01-liveness/`](ejemplos/01-liveness/) - Liveness básica
- [`ejemplos/02-readiness/`](ejemplos/02-readiness/) - Readiness básica
- [`ejemplos/03-startup/`](ejemplos/03-startup/) - Startup para apps lentas
- [`ejemplos/04-combinados/`](ejemplos/04-combinados/) - Las 3 probes
- [`ejemplos/05-http/`](ejemplos/05-http/) - HTTP GET probes
- [`ejemplos/06-tcp/`](ejemplos/06-tcp/) - TCP Socket probes
- [`ejemplos/07-exec/`](ejemplos/07-exec/) - Exec command probes

### Siguiente Módulo
➡️ Módulo 13: ConfigMaps y Variables de Entorno

---

## 🎉 ¡Felicitaciones!

Has completado el Módulo 12 de Health Checks y Probes. Ahora puedes:

- ✅ Configurar Startup, Liveness y Readiness probes
- ✅ Elegir el tipo de probe apropiado (HTTP, TCP, Exec)
- ✅ Ajustar parámetros para diferentes aplicaciones
- ✅ Implementar endpoints `/health` y `/ready` en apps
- ✅ Diagnosticar y resolver problemas de availability

**Próximos pasos**:
1. Revisar este resumen periódicamente
2. Completar los 3 laboratorios prácticos
3. Auditar probes en tus aplicaciones actuales
4. Implementar health checks en todos los Deployments
5. Continuar con Módulo 13: ConfigMaps

¡Sigue adelante! 🚀
