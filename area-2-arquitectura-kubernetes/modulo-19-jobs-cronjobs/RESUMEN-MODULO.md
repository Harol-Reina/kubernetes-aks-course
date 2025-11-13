# 📝 RESUMEN: Jobs & CronJobs en Kubernetes

> **Quick Reference Guide** - Comandos esenciales, sintaxis YAML y troubleshooting rápido

---

## 🎯 Concepto en 30 segundos

**Jobs**: Ejecutan tareas **finitas** que deben completarse (batch processing, migrations, backups)  
**CronJobs**: Ejecutan Jobs de forma **programada** según un schedule (tareas recurrentes)

**Cuándo usar**:
- ✅ Procesos que terminan (migraciones, backups, ETL)
- ✅ Tareas programadas (reports diarios, limpieza)
- ❌ Servicios continuos → usa **Deployment**

---

## 🔑 Comandos Esenciales

### Jobs - Comandos Básicos

```bash
# Crear Job imperativo (RÁPIDO para examen)
kubectl create job my-job --image=busybox -- echo "Hello"

# Crear Job desde CronJob (trigger manual)
kubectl create job --from=cronjob/my-cronjob test-run

# Listar Jobs
kubectl get jobs
kubectl get jobs -A  # Todos los namespaces

# Ver detalles
kubectl describe job my-job

# Ver logs
kubectl logs job/my-job
kubectl logs -l job-name=my-job  # Todos los pods del Job

# Eliminar Job
kubectl delete job my-job

# Limpiar Jobs completados
kubectl delete jobs --field-selector status.successful=1
```

### CronJobs - Comandos Básicos

```bash
# Crear CronJob imperativo
kubectl create cronjob backup --image=postgres:15 --schedule="0 2 * * *" -- pg_dump mydb

# Listar CronJobs
kubectl get cronjobs
kubectl get cj  # Abreviado

# Ver detalles (incluye last schedule)
kubectl describe cronjob backup

# Ver Jobs creados por CronJob
kubectl get jobs -l cronjob=backup

# Suspender CronJob (detener ejecución)
kubectl patch cronjob backup -p '{"spec":{"suspend":true}}'

# Reanudar CronJob
kubectl patch cronjob backup -p '{"spec":{"suspend":false}}'

# Eliminar CronJob
kubectl delete cronjob backup
```

### Comandos Avanzados

```bash
# Ver estado de todos los Jobs
kubectl get jobs -o wide

# Ver Jobs fallidos
kubectl get jobs --field-selector status.successful!=1

# Ejecutar comando en Pod de Job (para debugging)
kubectl exec -it $(kubectl get pod -l job-name=my-job -o name) -- /bin/sh

# Ver eventos del Job
kubectl get events --field-selector involvedObject.name=my-job

# Watch en tiempo real
kubectl get jobs -w

# Exportar Job a YAML
kubectl get job my-job -o yaml > job-backup.yaml
```

---

## 📋 Sintaxis YAML Esencial

### Job Básico (Mínimo)

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: simple-job
spec:
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ["echo", "Hello Kubernetes"]
      restartPolicy: Never  # ⚠️ OBLIGATORIO (Never o OnFailure)
```

### Job Completo (Producción)

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: production-job
  labels:
    app: data-processor
spec:
  # Configuración de ejecución
  completions: 5              # Ejecutar 5 veces
  parallelism: 2              # 2 pods simultáneos
  backoffLimit: 3             # Máximo 3 reintentos
  activeDeadlineSeconds: 600  # Timeout 10 minutos
  ttlSecondsAfterFinished: 3600  # Limpiar después de 1h
  
  template:
    metadata:
      labels:
        job-name: production-job
    spec:
      containers:
      - name: processor
        image: data-processor:v1
        command: ["python", "process.py"]
        env:
        - name: BATCH_SIZE
          value: "1000"
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
      restartPolicy: OnFailure  # Reintentar en caso de fallo
```

### CronJob Completo

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-cronjob
spec:
  # Schedule (cron syntax)
  schedule: "0 2 * * *"  # 2:00 AM diario
  timezone: "America/New_York"  # K8s 1.25+
  
  # Políticas de concurrencia
  concurrencyPolicy: Forbid  # Allow | Forbid | Replace
  
  # Gestión de histórico
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  
  # Deadline para iniciar
  startingDeadlineSeconds: 300  # 5 minutos max delay
  
  # Template del Job
  jobTemplate:
    spec:
      backoffLimit: 2
      activeDeadlineSeconds: 1800  # 30 min
      template:
        spec:
          containers:
          - name: backup
            image: postgres:15
            command:
            - /bin/bash
            - -c
            - pg_dump mydb | gzip > /backup/backup-$(date +%Y%m%d).sql.gz
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

---

## ⏰ Sintaxis Cron (Schedule)

### Formato: 5 campos

```
┌───────────── minuto (0 - 59)
│ ┌───────────── hora (0 - 23)
│ │ ┌───────────── día del mes (1 - 31)
│ │ │ ┌───────────── mes (1 - 12)
│ │ │ │ ┌───────────── día de la semana (0 - 6) (0=Domingo)
│ │ │ │ │
* * * * *
```

### Schedules Comunes

```yaml
# Cada 5 minutos
schedule: "*/5 * * * *"

# Cada hora (minuto 0)
schedule: "0 * * * *"

# Diario a las 2:00 AM
schedule: "0 2 * * *"

# Lunes a las 8:00 AM
schedule: "0 8 * * 1"

# Primer día del mes a las 00:00
schedule: "0 0 1 * *"

# Cada 6 horas
schedule: "0 */6 * * *"

# De Lunes a Viernes a las 9:00 AM
schedule: "0 9 * * 1-5"

# Domingos a las 23:30
schedule: "30 23 * * 0"
```

**🔗 Herramientas**: [crontab.guru](https://crontab.guru) | [crontab-generator.org](https://crontab-generator.org)

---

## 🔍 Troubleshooting Rápido

### Job no completa

```bash
# 1. Ver estado del Job
kubectl describe job <job-name>

# 2. Ver logs del Pod
kubectl logs job/<job-name>

# 3. Ver eventos
kubectl get events --sort-by='.lastTimestamp' | grep <job-name>

# 4. Verificar Pods
kubectl get pods -l job-name=<job-name>
```

**Causas comunes**:
- ❌ Imagen incorrecta o no existe
- ❌ Comando falla (exit code != 0)
- ❌ `restartPolicy: Always` (incorrecto)
- ❌ Recursos insuficientes
- ❌ `activeDeadlineSeconds` alcanzado

### CronJob no ejecuta

```bash
# 1. Verificar si está suspendido
kubectl get cronjob <name> -o jsonpath='{.spec.suspend}'

# 2. Ver último schedule
kubectl get cronjob <name> -o jsonpath='{.status.lastScheduleTime}'

# 3. Ver Jobs creados
kubectl get jobs -l cronjob=<name>

# 4. Trigger manual para probar
kubectl create job --from=cronjob/<name> test-run
```

**Causas comunes**:
- ❌ `suspend: true` (CronJob pausado)
- ❌ Schedule incorrecto
- ❌ `startingDeadlineSeconds` muy corto
- ❌ Timezone incorrecta (K8s 1.25+)

### Pods en CrashLoopBackOff

```bash
# Ver logs del Pod fallido
kubectl logs <pod-name> --previous

# Verificar comando y args
kubectl get job <job-name> -o yaml | grep -A5 command

# Ver exit code
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'
```

**Solución**:
- Revisar logs para error específico
- Probar imagen localmente: `docker run <image> <command>`
- Verificar variables de entorno
- Comprobar conectividad (DB, API)

---

## 🔧 Campos Críticos

### restartPolicy

```yaml
restartPolicy: Never      # ✅ No reintentar (fallo = fallo)
restartPolicy: OnFailure  # ✅ Reintentar en el mismo Pod
restartPolicy: Always     # ❌ NUNCA en Jobs (comportamiento indefinido)
```

### completions vs parallelism

```yaml
completions: 10   # Total de ejecuciones exitosas requeridas
parallelism: 3    # Máximo de Pods corriendo simultáneamente

# Ejemplo: Procesar 10 archivos, 3 a la vez
# Crea Pods hasta que 10 completen exitosamente
```

### backoffLimit

```yaml
backoffLimit: 3  # Máximo 3 reintentos de Pods fallidos
# Después de 3 fallos, Job se marca como Failed
```

### activeDeadlineSeconds

```yaml
activeDeadlineSeconds: 600  # Job se termina después de 10 minutos
# Útil para evitar Jobs colgados
```

### ttlSecondsAfterFinished

```yaml
ttlSecondsAfterFinished: 3600  # Eliminar Job 1h después de completar
# Limpieza automática (K8s 1.21+)
```

### concurrencyPolicy (CronJobs)

```yaml
concurrencyPolicy: Allow    # ✅ Permitir ejecuciones simultáneas
concurrencyPolicy: Forbid   # ✅ No crear nuevo si anterior está corriendo
concurrencyPolicy: Replace  # ✅ Cancelar anterior y crear nuevo
```

---

## 💡 Patrones de Diseño

### 1. Job Simple (One-off Task)

```yaml
spec:
  completions: 1
  parallelism: 1
  backoffLimit: 3
```

**Uso**: Migraciones, instalaciones, tareas únicas

---

### 2. Job Paralelo (Fixed Completions)

```yaml
spec:
  completions: 100   # Procesar 100 items
  parallelism: 10    # 10 workers simultáneos
```

**Uso**: Procesamiento batch, rendering, análisis de datos

---

### 3. Work Queue (Worker Pool)

```yaml
spec:
  parallelism: 5  # 5 workers
  # Sin completions definido
```

**Uso**: Consumir cola externa (Redis, RabbitMQ), cada worker toma tareas hasta que la cola esté vacía

---

### 4. Indexed Job (K8s 1.21+)

```yaml
spec:
  completionMode: Indexed
  completions: 10
  parallelism: 3
```

**Uso**: Procesamiento de datos particionados, cada Pod procesa un índice específico

---

## ✅ Best Practices - DO

```yaml
# ✅ Siempre define resource limits
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1000m"
    memory: "1Gi"

# ✅ Usa TTL para limpieza automática
ttlSecondsAfterFinished: 3600

# ✅ Define timeout
activeDeadlineSeconds: 1800

# ✅ Limita reintentos
backoffLimit: 3

# ✅ Labels claros
labels:
  app: data-processor
  environment: production
  version: v1.2.0
```

---

## ❌ Best Practices - DON'T

```yaml
# ❌ NUNCA uses restartPolicy: Always
restartPolicy: Always  # Causa comportamiento indefinido

# ❌ No omitas activeDeadlineSeconds
# (Jobs pueden correr indefinidamente)

# ❌ No uses schedules muy frecuentes sin necesidad
schedule: "* * * * *"  # Cada minuto (probablemente excesivo)

# ❌ No ignores timezone
# Sin timezone explícita, usa UTC (puede ser confuso)

# ❌ No dejes acumular Jobs
# Sin successfulJobsHistoryLimit, acumulación infinita
```

---

## 📊 Cheat Sheet de Troubleshooting

| Síntoma | Diagnóstico | Solución |
|---------|-------------|----------|
| Job no crea Pods | `kubectl describe job` | Verificar imagen, RBAC, resource quotas |
| Pods en Pending | `kubectl describe pod` | Verificar recursos disponibles, PVC |
| CrashLoopBackOff | `kubectl logs <pod> --previous` | Revisar comando, exit code, dependencies |
| Job nunca completa | Verificar `completions` | Ajustar parallelism o backoffLimit |
| CronJob no ejecuta | `kubectl get cj -o yaml` | Verificar `suspend: false`, schedule correcto |
| Múltiples ejecuciones | Verificar `concurrencyPolicy` | Cambiar a `Forbid` si no debe solaparse |
| Jobs acumulados | Ver histórico | Configurar `successfulJobsHistoryLimit` |
| Timeout constante | Ver `activeDeadlineSeconds` | Aumentar deadline o optimizar Job |

---

## 🎓 Para Certificación CKAD

### Peso en Examen
⭐⭐⭐⭐⭐ **18-20% del examen CKAD**

### Comandos Imperativos (Velocidad)

```bash
# Job básico (2 minutos)
kubectl create job test --image=busybox -- echo "test" --dry-run=client -o yaml > job.yaml
# Editar job.yaml y aplicar
kubectl apply -f job.yaml

# CronJob básico
kubectl create cronjob backup --image=postgres:15 --schedule="0 2 * * *" -- pg_dump mydb

# Trigger manual de CronJob
kubectl create job --from=cronjob/backup manual-backup
```

### Qué Memorizar

1. **restartPolicy**: `Never` o `OnFailure` (NUNCA `Always`)
2. **Cron syntax**: `* * * * *` (min hour day month weekday)
3. **concurrencyPolicy**: `Allow`, `Forbid`, `Replace`
4. **Comandos**: `create job`, `get jobs`, `logs job/<name>`
5. **Troubleshooting**: `describe`, `logs`, `events`

### Simulacros de Examen

**Práctica 1**: Crear Job que ejecute 10 veces con 3 workers paralelos
**Práctica 2**: CronJob diario a las 3 AM con `Forbid` concurrencyPolicy
**Práctica 3**: Debugging de Job en CrashLoopBackOff en 3 minutos

---

## 🔗 Navegación Rápida

- **📖 README Principal**: [README.md](./README.md) - Teoría completa (50KB)
- **🧪 Labs**:
  - [Lab 1: Job Simple](./laboratorios/lab-01-job-simple.md)
  - [Lab 2: Parallel Jobs](./laboratorios/lab-02-parallel-jobs.md)
  - [Lab 3: CronJob Backup](./laboratorios/lab-03-cronjob-backup.md)
  - [Lab 4: Troubleshooting](./laboratorios/lab-04-troubleshooting.md)
- **📂 Ejemplos YAML**: [./ejemplos/](./ejemplos/)
- **🏠 Área 2**: [README](../README.md)

---

## 📌 One-Liners Útiles

```bash
# Listar todos los Jobs completados
kubectl get jobs --field-selector status.successful=1

# Listar todos los Jobs fallidos
kubectl get jobs --field-selector status.successful!=1

# Ver logs de todos los Pods de un Job
kubectl logs -l job-name=my-job --all-containers=true

# Eliminar Jobs fallidos
kubectl delete jobs --field-selector status.failed!=0

# Ver cuántos Jobs ha creado un CronJob
kubectl get jobs -l cronjob=<name> --no-headers | wc -l

# Suspender todos los CronJobs en namespace
kubectl get cronjobs -o name | xargs -I {} kubectl patch {} -p '{"spec":{"suspend":true}}'

# Ver último schedule de todos los CronJobs
kubectl get cronjobs -o custom-columns=NAME:.metadata.name,SCHEDULE:.spec.schedule,LAST:.status.lastScheduleTime

# Ejecutar Job y esperar a que complete
kubectl create job test --image=busybox -- echo "test" && kubectl wait --for=condition=complete job/test --timeout=60s
```

---

**📅 Última actualización**: Noviembre 2025  
**✅ Estado**: 100% Completo  
**⏱️ Tiempo de lectura**: 10-15 minutos  

---

**🎯 Próximo paso**: Practica con [Lab 1: Job Simple](./laboratorios/lab-01-job-simple.md)
