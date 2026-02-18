# ⏰ Laboratorios - Jobs y CronJobs

Este módulo contiene laboratorios prácticos para dominar Jobs y CronJobs en Kubernetes.

## 📋 Índice de Laboratorios

### [Lab 01: Job Simple](./lab-01-job-simple/)
**Duración:** 45-60 minutos | **Dificultad:** ⭐⭐☆☆☆

Introducción a Jobs en Kubernetes.

**Objetivos:**
- Crear Jobs básicos
- Configurar completions y parallelism
- Monitorear estado de Jobs
- Logs y troubleshooting básico

---

### [Lab 02: Parallel Jobs](./lab-02-parallel-jobs/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐☆☆

Jobs paralelos y work queues.

**Objetivos:**
- Jobs con paralelismo
- Work queue pattern
- Indexed Jobs
- Job completion indexes

---

### [Lab 03: CronJob Backup](./lab-03-cronjob-backup/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐⭐☆☆

CronJobs para tareas programadas.

**Objetivos:**
- Crear CronJobs
- Configurar schedule (cron syntax)
- Gestión de historial
- Casos de uso reales (backups)

---

### [Lab 04: Troubleshooting](./lab-04-troubleshooting/)
**Duración:** 75-90 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Diagnóstico y solución de problemas.

**Objetivos:**
- Diagnosticar Jobs fallidos
- Manejo de errores y reintentos
- CronJob concurrency policies
- Best practices

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Básico** → Lab 01 (Job simple)
2. **Nivel Intermedio** → Labs 02-03 (Parallel y CronJobs)
3. **Nivel Avanzado** → Lab 04 (Troubleshooting)

**Tiempo total estimado:** 4.5-5 horas

## 📚 Conceptos Clave

### Job
- Ejecuta una tarea hasta completarse
- Garantiza completions exitosos
- Soporta paralelismo

**Configuración básica:**
```yaml
spec:
  completions: 3        # Debe completarse 3 veces
  parallelism: 2        # 2 pods en paralelo
  backoffLimit: 4       # Reintentos ante fallas
```

### CronJob
- Crea Jobs en schedule programado
- Usa sintaxis cron estándar
- Gestiona historial automáticamente

**Sintaxis Cron:**
```
# ┌───────────── minuto (0 - 59)
# │ ┌───────────── hora (0 - 23)
# │ │ ┌───────────── día del mes (1 - 31)
# │ │ │ ┌───────────── mes (1 - 12)
# │ │ │ │ ┌───────────── día de la semana (0 - 6)
# │ │ │ │ │
# * * * * *
```

### Concurrency Policies
- **Allow**: Permite ejecuciones concurrentes
- **Forbid**: Previene concurrencia
- **Replace**: Reemplaza job actual

## ⚠️ Antes de Comenzar

```bash
# Verificar cluster
kubectl cluster-info

# Ver Jobs y CronJobs
kubectl get jobs
kubectl get cronjobs

# Ver pods de Jobs completados
kubectl get pods --show-all
```

## 🧹 Limpieza

```bash
cd lab-XX-nombre
./cleanup.sh
```

## 💡 Best Practices

- Usa `activeDeadlineSeconds` para limitar duración
- Configura `backoffLimit` apropiado
- Limpia Jobs viejos con `ttlSecondsAfterFinished`
- CronJobs: usa `successfulJobsHistoryLimit` y `failedJobsHistoryLimit`
