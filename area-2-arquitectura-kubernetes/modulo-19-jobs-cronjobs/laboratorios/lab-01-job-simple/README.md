# 🧪 Laboratorio 1: Job Simple - Cálculo de Pi

## 📋 Información del Laboratorio

| Atributo | Valor |
|----------|-------|
| **Dificultad** | 🟢 Principiante |
| **Duración** | 15-20 minutos |
| **Objetivos** | Crear y gestionar un Job básico en Kubernetes |
| **Prerequisitos** | Cluster Kubernetes funcionando, kubectl configurado |

---

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio serás capaz de:

1. ✅ Crear un Job usando `kubectl create` (imperativo)
2. ✅ Crear un Job desde archivo YAML (declarativo)
3. ✅ Monitorear el progreso de un Job
4. ✅ Ver logs de Pods creados por Jobs
5. ✅ Entender el ciclo de vida de un Job
6. ✅ Limpiar recursos después de completar

---

## 📝 Escenario

Eres DevOps Engineer en una startup tech. El equipo de data science necesita calcular Pi con alta precisión para validar un algoritmo. En lugar de mantener un servidor corriendo 24/7, decides usar un **Job de Kubernetes** que:

- Ejecuta el cálculo una sola vez
- Se auto-limpia después de completar
- Puede ser monitoreado fácilmente
- Es reproducible y versionado

---

## 🚀 Parte 1: Crear Job de Forma Imperativa

### Paso 1.1: Verificar cluster activo

```bash
# Verificar conexión al cluster
kubectl cluster-info

# Ver nodos disponibles
kubectl get nodes

# Verificar namespace actual
kubectl config view --minify | grep namespace
```

**✅ Checkpoint**: Deberías ver información del cluster y al menos un nodo `Ready`.

---

### Paso 1.2: Crear Job imperativo (método rápido)

```bash
# Crear Job simple que imprime "Hello from Kubernetes Job!"
kubectl create job hello-job --image=busybox:1.35 -- echo "Hello from Kubernetes Job!"
```

**Salida esperada:**
```
job.batch/hello-job created
```

---

### Paso 1.3: Verificar creación del Job

```bash
# Ver el Job recién creado
kubectl get jobs

# Ver con más detalles
kubectl get jobs -o wide
```

**Salida esperada:**
```
NAME        COMPLETIONS   DURATION   AGE
hello-job   1/1           5s         10s
```

**📚 Explicación de columnas:**
- `COMPLETIONS`: `1/1` significa "1 de 1 completado"
- `DURATION`: Tiempo que tardó en completar
- `AGE`: Tiempo desde que fue creado

---

### Paso 1.4: Ver el Pod creado por el Job

```bash
# Los Jobs crean Pods con label job-name
kubectl get pods -l job-name=hello-job

# Ver detalles del Pod
kubectl get pods -l job-name=hello-job -o wide
```

**Salida esperada:**
```
NAME              READY   STATUS      RESTARTS   AGE
hello-job-xxxxx   0/1     Completed   0          15s
```

**🔍 Nota**: `STATUS: Completed` indica que el Job terminó exitosamente.

---

### Paso 1.5: Ver logs del Job

```bash
# Ver logs usando el nombre del Job (Kubernetes encuentra el Pod automáticamente)
kubectl logs job/hello-job

# Alternativa: Ver logs por label
kubectl logs -l job-name=hello-job
```

**Salida esperada:**
```
Hello from Kubernetes Job!
```

---

### Paso 1.6: Inspeccionar detalles del Job

```bash
# Ver descripción completa con eventos
kubectl describe job hello-job
```

**🔍 Observa:**
- `Pods Statuses`: Cuántos Pods completaron, fallaron o están corriendo
- `Events`: Historial de lo que pasó (Pod creado, completado, etc.)
- `Parallelism`: Cuántos Pods corren simultáneamente
- `Completions`: Cuántas ejecuciones exitosas se requieren

---

### Paso 1.7: Limpiar el Job

```bash
# Eliminar el Job (también elimina los Pods asociados)
kubectl delete job hello-job

# Verificar que se eliminó
kubectl get jobs
kubectl get pods -l job-name=hello-job
```

**✅ Checkpoint**: No deberías ver ni el Job ni sus Pods.

---

## 📄 Parte 2: Crear Job desde YAML (Método Declarativo)

### Paso 2.1: Crear archivo YAML para Job de cálculo de Pi

Crea un archivo llamado `pi-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi-calculation
  labels:
    app: math-tools
    type: calculation
spec:
  # Configuración del Job
  completions: 1          # Ejecutar una sola vez
  parallelism: 1          # Un Pod a la vez
  backoffLimit: 4         # Máximo 4 reintentos si falla
  
  # Template del Pod
  template:
    metadata:
      labels:
        job-name: pi-calculation
        app: math-tools
    spec:
      containers:
      - name: pi-calculator
        image: perl:5.34
        command:
        - perl
        - -Mbignum=bpi
        - -wle
        - print bpi(2000)  # Calcular Pi con 2000 decimales
        
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
      
      # CRÍTICO: Never o OnFailure (NUNCA Always)
      restartPolicy: Never
```

**💾 Guarda el archivo**: `pi-job.yaml`

---

### Paso 2.2: Aplicar el Job

```bash
# Crear el Job desde el archivo YAML
kubectl apply -f pi-job.yaml

# Verificar creación
kubectl get jobs
```

**Salida esperada:**
```
NAME             COMPLETIONS   DURATION   AGE
pi-calculation   0/1           0s         1s
```

---

### Paso 2.3: Monitorear en tiempo real

```bash
# Watch en tiempo real (presiona Ctrl+C para salir)
kubectl get jobs -w
```

**Deberías ver:**
```
NAME             COMPLETIONS   DURATION   AGE
pi-calculation   0/1           0s         5s
pi-calculation   1/1           10s        15s  # ← Completado!
```

---

### Paso 2.4: Ver el Pod en acción

```bash
# Ver Pods del Job
kubectl get pods -l job-name=pi-calculation

# Si el Job aún está corriendo, puedes ver logs en tiempo real
kubectl logs -f -l job-name=pi-calculation
```

**Salida esperada (primeras líneas de Pi con 2000 decimales):**
```
3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679...
```

---

### Paso 2.5: Verificar estado completado

```bash
# Ver detalles del Job
kubectl describe job pi-calculation

# Verificar status del Pod
kubectl get pods -l job-name=pi-calculation -o jsonpath='{.items[0].status.phase}'
```

**Salida esperada:** `Succeeded`

---

### Paso 2.6: Extraer los logs completos

```bash
# Guardar resultado en archivo local
kubectl logs job/pi-calculation > pi_result.txt

# Ver primeras 5 líneas
head -c 200 pi_result.txt

# Ver tamaño del archivo
wc -c pi_result.txt
```

**✅ Checkpoint**: Deberías tener un archivo con Pi calculado (aproximadamente 2000 dígitos).

---

## 🔄 Parte 3: Job con Reintentos (Simulación de Fallos)

### Paso 3.1: Crear Job que falla intencionalmente

Crea `failing-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: failing-job
spec:
  backoffLimit: 3  # Máximo 3 reintentos
  template:
    spec:
      containers:
      - name: failer
        image: busybox:1.35
        command:
        - /bin/sh
        - -c
        - |
          echo "Intento de ejecución: $(date)"
          echo "Simulando error aleatorio..."
          # 50% de probabilidad de fallar
          if [ $((RANDOM % 2)) -eq 0 ]; then
            echo "❌ Falló!"
            exit 1
          else
            echo "✅ Éxito!"
            exit 0
          fi
      restartPolicy: Never
```

---

### Paso 3.2: Aplicar y observar comportamiento

```bash
# Aplicar el Job
kubectl apply -f failing-job.yaml

# Monitorear en tiempo real
watch kubectl get jobs failing-job
```

**Observa:**
- Si falla, verás múltiples Pods creados (reintentos)
- Después de 3 fallos, el Job se marca como `Failed`

---

### Paso 3.3: Analizar los reintentos

```bash
# Ver todos los Pods (incluyendo fallidos)
kubectl get pods -l job-name=failing-job

# Ver logs de cada intento
for pod in $(kubectl get pods -l job-name=failing-job -o name); do
  echo "=== $pod ==="
  kubectl logs $pod
  echo ""
done
```

**🔍 Nota**: Verás múltiples Pods, algunos con `Error` y otros posiblemente `Completed`.

---

### Paso 3.4: Ver detalles de fallos

```bash
# Ver descripción con eventos
kubectl describe job failing-job

# Ver estado de Pods
kubectl get pods -l job-name=failing-job -o wide
```

**📚 En `Events` verás:**
- `Created pod: failing-job-xxxxx`
- `Back-off restarting failed container`
- Potencialmente `Job has reached the specified backoff limit`

---

### Paso 3.5: Limpiar Job fallido

```bash
# Eliminar el Job
kubectl delete job failing-job

# Verificar limpieza
kubectl get jobs
kubectl get pods -l job-name=failing-job
```

---

## ⏱️ Parte 4: Job con Timeout (activeDeadlineSeconds)

### Paso 4.1: Crear Job con deadline

Crea `timeout-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: timeout-job
spec:
  activeDeadlineSeconds: 30  # Matar después de 30 segundos
  backoffLimit: 2
  template:
    spec:
      containers:
      - name: slow-task
        image: busybox:1.35
        command:
        - /bin/sh
        - -c
        - |
          echo "Iniciando tarea lenta..."
          for i in $(seq 1 60); do
            echo "Progreso: $i/60"
            sleep 1
          done
          echo "Completado!"
      restartPolicy: Never
```

---

### Paso 4.2: Aplicar y observar timeout

```bash
# Aplicar Job
kubectl apply -f timeout-job.yaml

# Monitorear (esperar ~35 segundos)
kubectl get jobs timeout-job -w
```

**Después de 30 segundos verás:**
```
NAME          COMPLETIONS   DURATION   AGE
timeout-job   0/1           30s        30s
timeout-job   0/1           31s        31s  # ← DeadlineExceeded
```

---

### Paso 4.3: Ver el error de timeout

```bash
# Ver descripción
kubectl describe job timeout-job

# Buscar el mensaje de error
kubectl get job timeout-job -o jsonpath='{.status.conditions[?(@.type=="Failed")].message}'
```

**Salida esperada:**
```
Job was active longer than specified deadline
```

---

### Paso 4.4: Limpiar

```bash
kubectl delete job timeout-job
```

---

## 🧹 Parte 5: Limpieza Automática (TTL)

### Paso 5.1: Crear Job con TTL (K8s 1.21+)

Crea `ttl-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ttl-job
spec:
  ttlSecondsAfterFinished: 60  # Eliminar 60s después de completar
  template:
    spec:
      containers:
      - name: quick-task
        image: busybox:1.35
        command: ["echo", "Este Job se auto-eliminará en 60 segundos!"]
      restartPolicy: Never
```

---

### Paso 5.2: Aplicar y verificar auto-limpieza

```bash
# Aplicar Job
kubectl apply -f ttl-job.yaml

# Verificar que completó
kubectl get jobs ttl-job

# Esperar 60 segundos y verificar
sleep 65
kubectl get jobs ttl-job
```

**Resultado esperado:**
```
Error from server (NotFound): jobs.batch "ttl-job" not found
```

**✅ El Job se eliminó automáticamente!**

---

## 📊 Parte 6: Comandos Útiles de Gestión

### Ver todos los Jobs

```bash
# Todos los Jobs en namespace actual
kubectl get jobs

# Todos los Jobs en todos los namespaces
kubectl get jobs -A

# Jobs con labels específicos
kubectl get jobs -l app=math-tools
```

---

### Limpiar Jobs completados masivamente

```bash
# Eliminar todos los Jobs completados exitosamente
kubectl delete jobs --field-selector status.successful=1

# Eliminar todos los Jobs fallidos
kubectl delete jobs --field-selector status.failed!=0

# Eliminar Jobs más antiguos de 24h (requiere jq)
kubectl get jobs -o json | jq -r '.items[] | select(.status.completionTime != null) | select((now - (.status.completionTime | fromdateiso8601)) > 86400) | .metadata.name' | xargs kubectl delete job
```

---

### Exportar Job a YAML

```bash
# Exportar Job existente a archivo
kubectl get job pi-calculation -o yaml > pi-calculation-backup.yaml

# Exportar sin metadata del cluster
kubectl get job pi-calculation -o yaml --export > pi-calculation-clean.yaml
```

---

## ✅ Verificación de Aprendizaje

### Quiz Rápido

1. **¿Qué valor de `restartPolicy` es válido para Jobs?**
   - [ ] Always
   - [x] Never
   - [x] OnFailure
   - [ ] IfNeeded

2. **¿Qué hace `backoffLimit: 3`?**
   - [ ] Limita el tiempo de ejecución a 3 minutos
   - [x] Permite máximo 3 reintentos si el Pod falla
   - [ ] Crea 3 Pods en paralelo
   - [ ] Limita el Job a 3 completions

3. **¿Cuál comando muestra logs de un Job llamado `my-job`?**
   - [ ] `kubectl get logs my-job`
   - [x] `kubectl logs job/my-job`
   - [ ] `kubectl describe job my-job --logs`
   - [ ] `kubectl log my-job`

4. **¿Qué hace `ttlSecondsAfterFinished: 3600`?**
   - [ ] Mata el Job después de 1 hora
   - [x] Elimina el Job 1 hora después de completar
   - [ ] Reinicia el Job cada hora
   - [ ] Limita ejecución a 1 hora

**Respuestas:** 1: Never y OnFailure | 2: Permite 3 reintentos | 3: `kubectl logs job/my-job` | 4: Elimina después de completar

---

## 🎯 Desafío Extra (Opcional)

### Desafío 1: Job Parameterizado

Crea un Job que:
- Acepta una variable de entorno `ITERATIONS`
- Imprime números del 1 al valor de `ITERATIONS`
- Tiene un `backoffLimit` de 2
- Se auto-limpia después de 5 minutos

<details>
<summary>💡 Ver solución</summary>

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: counter-job
spec:
  backoffLimit: 2
  ttlSecondsAfterFinished: 300
  template:
    spec:
      containers:
      - name: counter
        image: busybox:1.35
        command:
        - /bin/sh
        - -c
        - for i in $(seq 1 $ITERATIONS); do echo "Número: $i"; done
        env:
        - name: ITERATIONS
          value: "10"
      restartPolicy: Never
```

</details>

---

### Desafío 2: Job con Resource Limits

Crea un Job que:
- Calcula suma de números del 1 al 1000
- Tiene límites de CPU (200m) y memoria (128Mi)
- Tiene un deadline de 2 minutos
- Guarda el resultado en un archivo dentro del Pod

<details>
<summary>💡 Ver solución</summary>

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sum-calculator
spec:
  activeDeadlineSeconds: 120
  template:
    spec:
      containers:
      - name: calculator
        image: python:3.11-slim
        command:
        - python3
        - -c
        - |
          result = sum(range(1, 1001))
          print(f"Suma del 1 al 1000: {result}")
          with open('/tmp/result.txt', 'w') as f:
            f.write(str(result))
        resources:
          requests:
            cpu: "100m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
      restartPolicy: Never
```

</details>

---

## 📚 Recursos Adicionales

**Documentación oficial:**
- [Kubernetes Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [Job Patterns](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-patterns)
- [kubectl create job](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_job/)

**Siguientes pasos:**
- [Lab 2: Jobs Paralelos](./lab-02-parallel-jobs.md) - Procesamiento batch en paralelo
- [Lab 3: CronJobs](./lab-03-cronjob-backup.md) - Tareas programadas
- [RESUMEN-MODULO.md](../RESUMEN-MODULO.md) - Quick reference

---

## 🎉 ¡Felicitaciones!

Has completado el Lab 1 y ahora sabes:

✅ Crear Jobs imperativos con `kubectl create`  
✅ Crear Jobs declarativos con YAML  
✅ Monitorear progreso con `kubectl get jobs`  
✅ Ver logs con `kubectl logs job/<name>`  
✅ Configurar reintentos con `backoffLimit`  
✅ Configurar timeouts con `activeDeadlineSeconds`  
✅ Configurar limpieza automática con `ttlSecondsAfterFinished`

**Tiempo completado:** ~15-20 minutos  
**Nivel:** 🟢 Principiante  
**Estado:** ✅ Completo

---

**📅 Última actualización:** Noviembre 2025  
**✍️ Autor:** Curso Kubernetes AKS
