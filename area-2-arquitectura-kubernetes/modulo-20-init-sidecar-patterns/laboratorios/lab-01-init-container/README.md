# 🧪 Lab 1: Init Containers - Wait for Database

> **Duración estimada**: 30 minutos  
> **Nivel**: 🟢 Básico  
> **Objetivos**: Dominar init containers y wait-for patterns

---

## 🎯 Objetivos del Laboratorio

Al completar este lab serás capaz de:

1. ✅ Crear Pods con init containers
2. ✅ Implementar wait-for pattern con timeout
3. ✅ Troubleshootear init containers que fallan
4. ✅ Ver logs de init containers
5. ✅ Entender orden de ejecución (init → main)

---

## 📋 Prerrequisitos

```bash
# Verificar cluster disponible
kubectl cluster-info

# Verificar permisos
kubectl auth can-i create pods

# Limpiar resources previos (si existen)
kubectl delete pod --all --force --grace-period=0 2>/dev/null || true
```

---

## 🔨 Parte 1: Init Container Básico (5 min)

### Paso 1.1: Crear Init Container Simple

Crea un archivo `init-basic.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  initContainers:
  - name: init-setup
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      echo "Init container ejecutando..."
      echo "Realizando setup..."
      sleep 5
      echo "Setup completado!"
  
  containers:
  - name: main-app
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
```

**Aplicar:**

```bash
# Aplicar Pod
kubectl apply -f init-basic.yaml

# Ver progreso en tiempo real
kubectl get pod init-demo -w
```

---

### Paso 1.2: Observar Ejecución

```bash
# Ver status del Pod
kubectl get pod init-demo

# Expected output:
# NAME        READY   STATUS    RESTARTS   AGE
# init-demo   1/1     Running   0          10s

# Ver logs del init container
kubectl logs init-demo -c init-setup

# Expected output:
# Init container ejecutando...
# Realizando setup...
# Setup completado!

# Ver logs del main container
kubectl logs init-demo -c main-app
```

---

### Paso 1.3: Inspeccionar Pod

```bash
# Ver init containers en el Pod
kubectl get pod init-demo -o jsonpath='{.spec.initContainers[*].name}'
# Output: init-setup

# Ver main containers
kubectl get pod init-demo -o jsonpath='{.spec.containers[*].name}'
# Output: main-app

# Ver estado de init container (debe estar Terminated)
kubectl get pod init-demo -o jsonpath='{.status.initContainerStatuses[0].state}'
# Output: {"terminated":{"exitCode":0,...}}

# Describe completo
kubectl describe pod init-demo
```

---

### ✅ Checkpoint 1

Verifica que entiendes:

- [ ] Init container ejecuta ANTES de main container
- [ ] Init debe completar exitosamente (exit 0)
- [ ] Init container status es "Terminated" cuando completa
- [ ] Main container inicia solo después de init

---

## 🗄️ Parte 2: Wait-for Database Pattern (10 min)

### Paso 2.1: Crear PostgreSQL

```bash
# Crear PostgreSQL Pod
kubectl run postgres \
  --image=postgres:15-alpine \
  --env="POSTGRES_PASSWORD=secret" \
  --port=5432

# Esperar a que esté Running
kubectl wait --for=condition=Ready pod/postgres --timeout=60s

# Exponer como Service
kubectl expose pod postgres --port=5432

# Verificar servicio
kubectl get service postgres
```

---

### Paso 2.2: Aplicación que Espera a DB

Crea `app-wait-db.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-wait-db
spec:
  initContainers:
  - name: wait-for-postgres
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      echo "Esperando a PostgreSQL..."
      TIMEOUT=120
      ELAPSED=0
      
      until nc -z postgres.default.svc.cluster.local 5432 || [ $ELAPSED -ge $TIMEOUT ]; do
        echo "PostgreSQL no disponible (${ELAPSED}s/${TIMEOUT}s)..."
        sleep 2
        ELAPSED=$((ELAPSED + 2))
      done
      
      if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "TIMEOUT: PostgreSQL no disponible"
        exit 1
      fi
      
      echo "✅ PostgreSQL listo!"
  
  containers:
  - name: app
    image: postgres:15-alpine
    command:
    - sh
    - -c
    - |
      echo "Aplicación iniciando..."
      export PGPASSWORD=secret
      if psql -h postgres -U postgres -c "SELECT version();" > /dev/null 2>&1; then
        echo "✅ Conexión a DB exitosa!"
      else
        echo "❌ Falló conexión a DB"
        exit 1
      fi
      tail -f /dev/null
```

---

### Paso 2.3: Aplicar y Verificar

```bash
# Aplicar Pod
kubectl apply -f app-wait-db.yaml

# Ver progreso (debería completar rápido porque DB ya existe)
kubectl get pod app-wait-db -w

# Ver logs del init container
kubectl logs app-wait-db -c wait-for-postgres

# Expected output:
# Esperando a PostgreSQL...
# ✅ PostgreSQL listo!

# Ver logs de la app
kubectl logs app-wait-db -c app

# Expected output:
# Aplicación iniciando...
# ✅ Conexión a DB exitosa!
```

---

### ✅ Checkpoint 2

- [ ] Init container espera hasta que DB esté disponible
- [ ] Wait-for loop tiene timeout de 120 segundos
- [ ] App inicia solo cuando init completa
- [ ] Conexión a DB es exitosa

---

## 🔥 Parte 3: Simular Escenarios de Fallo (10 min)

### Paso 3.1: DB No Disponible (Timeout)

```bash
# Eliminar PostgreSQL
kubectl delete pod postgres
kubectl delete service postgres

# Eliminar Pod de app (para que reinicie wait-for)
kubectl delete pod app-wait-db --force

# Aplicar Pod sin DB disponible
kubectl apply -f app-wait-db.yaml

# Ver que init container se queda esperando
kubectl get pod app-wait-db -w
# STATUS: Init:0/1

# Ver logs mostrando reintentos
kubectl logs app-wait-db -c wait-for-postgres -f

# Expected output:
# Esperando a PostgreSQL...
# PostgreSQL no disponible (0s/120s)...
# PostgreSQL no disponible (2s/120s)...
# PostgreSQL no disponible (4s/120s)...
# ... (continuará hasta timeout)
```

---

### Paso 3.2: Crear DB Mientras Espera

**Abre otra terminal** y crea PostgreSQL mientras init espera:

```bash
# Terminal 2: Crear PostgreSQL
kubectl run postgres \
  --image=postgres:15-alpine \
  --env="POSTGRES_PASSWORD=secret"

kubectl expose pod postgres --port=5432

# Terminal 1: Observa que init completa inmediatamente
kubectl get pod app-wait-db -w
# STATUS: Init:0/1 → Running
```

---

### Paso 3.3: Init Container Falla

Modifica timeout a 10 segundos en `app-wait-db.yaml`:

```yaml
initContainers:
- name: wait-for-postgres
  command:
  - sh
  - -c
  - |
    TIMEOUT=10  # ← Solo 10 segundos
    # ... resto igual
```

```bash
# Eliminar DB y Pod
kubectl delete pod postgres app-wait-db --force
kubectl delete service postgres

# Aplicar con timeout corto
kubectl apply -f app-wait-db.yaml

# Esperar 10 segundos y ver que falla
kubectl get pod app-wait-db -w

# STATUS después de 10s: Init:CrashLoopBackOff

# Ver logs del init fallido
kubectl logs app-wait-db -c wait-for-postgres --previous

# Expected output:
# Esperando a PostgreSQL...
# PostgreSQL no disponible (0s/10s)...
# ...
# TIMEOUT: PostgreSQL no disponible
```

---

### ✅ Checkpoint 3

- [ ] Init container espera indefinidamente si no hay timeout
- [ ] Con timeout, init falla después del tiempo límite
- [ ] Pod entra en CrashLoopBackOff cuando init falla
- [ ] Flag `--previous` muestra logs del container anterior

---

## 🐛 Parte 4: Troubleshooting (5 min)

### Paso 4.1: Comandos de Diagnóstico

```bash
# Ver status del Pod
kubectl get pod app-wait-db

# Ver describe para eventos
kubectl describe pod app-wait-db | grep -A 20 "Events:"

# Ver init container status
kubectl get pod app-wait-db -o jsonpath='{.status.initContainerStatuses[*].state}'

# Ver exit code del init container
kubectl get pod app-wait-db -o jsonpath='{.status.initContainerStatuses[0].lastState.terminated.exitCode}'
# Si falló: 1
# Si exitoso: 0

# Ver razón del fallo
kubectl get pod app-wait-db -o jsonpath='{.status.initContainerStatuses[0].lastState.terminated.reason}'

# Ver mensaje de fallo
kubectl get pod app-wait-db -o jsonpath='{.status.initContainerStatuses[0].lastState.terminated.message}'
```

---

### Paso 4.2: Soluciones Comunes

#### Problema: Init nunca completa

```bash
# Verificar que servicio existe
kubectl get service postgres

# Verificar DNS
kubectl run -it --rm debug --image=busybox --restart=Never \
  -- nslookup postgres.default.svc.cluster.local

# Verificar conectividad TCP
kubectl run -it --rm debug --image=busybox --restart=Never \
  -- nc -zv postgres.default.svc.cluster.local 5432
```

#### Problema: Init falla por timeout

```yaml
# Aumentar timeout en app-wait-db.yaml
TIMEOUT=300  # 5 minutos en lugar de 10 segundos
```

#### Problema: Init crashea por error en script

```bash
# Ver logs exactos
kubectl logs app-wait-db -c wait-for-postgres --previous

# Verificar sintaxis del script
# Agregar set -x para debugging:
command:
- sh
- -c
- |
  set -x  # ← Debug mode
  echo "Esperando..."
  # ... resto del script
```

---

## 🎯 Desafíos Adicionales (Opcional)

### Desafío 1: Múltiples Init Containers

Crea Pod con 2 init containers que ejecutan secuencialmente:

```yaml
initContainers:
- name: init-1
  image: busybox
  command: ['sh', '-c', 'echo "Init 1"; sleep 3']

- name: init-2
  image: busybox
  command: ['sh', '-c', 'echo "Init 2"; sleep 3']
```

**Objetivo**: Ver que ejecutan uno después del otro (6 segundos total).

---

### Desafío 2: Init con Shared Volume

Init container que crea archivo, main container que lo lee:

```yaml
initContainers:
- name: create-config
  image: busybox
  command:
  - sh
  - -c
  - echo "config_value=123" > /config/app.conf
  volumeMounts:
  - name: config
    mountPath: /config

containers:
- name: app
  image: busybox
  command: ['sh', '-c', 'cat /config/app.conf; tail -f /dev/null']
  volumeMounts:
  - name: config
    mountPath: /config

volumes:
- name: config
  emptyDir: {}
```

---

### Desafío 3: Wait-for Múltiples Servicios

Init container que espera a PostgreSQL Y Redis:

```yaml
initContainers:
- name: wait-postgres
  command: ['sh', '-c', 'until nc -z postgres 5432; do sleep 2; done']

- name: wait-redis
  command: ['sh', '-c', 'until nc -z redis 6379; do sleep 2; done']
```

---

## 📝 Limpieza

```bash
# Eliminar todos los resources del lab
kubectl delete pod init-demo app-wait-db postgres --force
kubectl delete service postgres

# Verificar limpieza
kubectl get pods
```

---

## ✅ Auto-Evaluación

Marca cuando completes cada objetivo:

- [ ] Creé Pod con init container básico
- [ ] Implementé wait-for pattern con timeout
- [ ] Vi logs de init containers
- [ ] Entendí orden de ejecución secuencial
- [ ] Troubleshoot init container que falló
- [ ] Usé `--previous` para ver logs de container anterior
- [ ] Simulé escenario de timeout
- [ ] Creé múltiples init containers secuenciales
- [ ] Compartí datos entre init y main via volume

---

## 🎓 Conceptos Clave Aprendidos

```
INIT CONTAINERS
├─ Ejecutan ANTES de main containers
├─ Secuenciales (uno por uno)
├─ Deben completar (exit 0)
├─ Ideal para: setup, wait-for, migrations
└─ Si fallan → CrashLoopBackOff

WAIT-FOR PATTERN
├─ Loop until condition || timeout
├─ SIEMPRE usar timeout
├─ Herramientas: nc, nslookup, wget, curl
└─ Exit 1 si timeout

TROUBLESHOOTING
├─ kubectl logs <pod> -c <init-name>
├─ kubectl logs ... --previous (logs anteriores)
├─ kubectl describe pod (eventos)
└─ kubectl get pod -o jsonpath (status detallado)
```

---

## 🚀 Próximos Pasos

1. ✅ Completa **Lab 2**: Sidecar Logging
2. ✅ Revisa ejemplos en `/ejemplos/init-*.yaml`
3. ✅ Practica wait-for pattern en tus propios Pods

---

**¡Felicidades!** 🎉  
Has completado el Lab 1 sobre Init Containers.

---

*Tiempo completado*: _____ minutos  
*Dificultad percibida*: ⭐⭐⭐☆☆  
*Fecha*: _____