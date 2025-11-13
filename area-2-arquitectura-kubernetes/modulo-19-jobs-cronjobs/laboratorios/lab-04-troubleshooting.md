# 🧪 Laboratorio 4: Troubleshooting Challenge - Jobs & CronJobs

## 📋 Información del Laboratorio

| Atributo | Valor |
|----------|-------|
| **Dificultad** | 🔴 Avanzado |
| **Duración** | 30-45 minutos |
| **Objetivos** | Diagnosticar y resolver problemas comunes en Jobs y CronJobs |
| **Prerequisitos** | Labs 1-3 completados |

---

## 🎯 Objetivos de Aprendizaje

1. ✅ Diagnosticar Jobs que no completan
2. ✅ Resolver CronJobs que no ejecutan
3. ✅ Troubleshooting de CrashLoopBackOff en Jobs
4. ✅ Identificar problemas de concurrencia
5. ✅ Analizar logs y eventos eficientemente
6. ✅ Aplicar soluciones rápidas bajo presión

---

## 🔥 Formato del Challenge

Este laboratorio simula **escenarios reales de producción** donde algo está mal configurado. Tu tarea es:

1. **Identificar** el problema
2. **Diagnosticar** la causa raíz
3. **Resolver** el issue
4. **Verificar** que la solución funciona

**⏱️ Tiempo sugerido:** 5-8 minutos por escenario (simula presión de examen CKAD)

---

## 🐛 Challenge 1: Job que Nunca Completa

### Escenario

Un developer te reporta que su Job de migración de datos lleva corriendo 30 minutos y no completa.

### Paso 1.1: Desplegar Job problemático

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: stuck-job
spec:
  completions: 5
  parallelism: 2
  template:
    spec:
      containers:
      - name: worker
        image: busybox:1.35
        command: ["sh", "-c", "echo Processing... && sleep 10 && echo Done"]
      restartPolicy: Always  # ⚠️ PROBLEMA AQUÍ
EOF
```

---

### Paso 1.2: Observar el comportamiento

```bash
# Ver el Job
kubectl get jobs stuck-job

# Ver Pods
kubectl get pods -l job-name=stuck-job
```

**🤔 Pregunta:** ¿Qué observas? ¿Por qué no completa?

---

### Paso 1.3: Diagnosticar

```bash
# Ver descripción del Job
kubectl describe job stuck-job

# Ver status de Pods
kubectl get pods -l job-name=stuck-job -o wide
```

<details>
<summary>💡 Ver análisis del problema</summary>

**Problema:** `restartPolicy: Always` es **incorrecto** para Jobs.

**Causa:**
- Jobs requieren `Never` o `OnFailure`
- `Always` causa que el Pod se reinicie indefinidamente
- Nunca alcanza estado `Completed`

**Síntomas:**
- Job muestra `0/5` completions indefinidamente
- Pods se reinician continuamente
- No hay progreso

</details>

---

### Paso 1.4: Resolver

```bash
# Eliminar Job incorrecto
kubectl delete job stuck-job

# Aplicar versión corregida
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: stuck-job-fixed
spec:
  completions: 5
  parallelism: 2
  template:
    spec:
      containers:
      - name: worker
        image: busybox:1.35
        command: ["sh", "-c", "echo Processing... && sleep 10 && echo Done"]
      restartPolicy: Never  # ✅ CORRECTO
EOF

# Verificar
kubectl get jobs stuck-job-fixed -w
```

**✅ Solución:** Cambiar `restartPolicy: Always` → `restartPolicy: Never`

---

## 🔴 Challenge 2: CrashLoopBackOff en Job

### Escenario

Un Job está en CrashLoopBackOff. Los Pods fallan constantemente.

### Paso 2.1: Desplegar Job problemático

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: crashloop-job
spec:
  backoffLimit: 3
  template:
    spec:
      containers:
      - name: processor
        image: busybox:1.35
        command: ["sh", "-c", "echo Starting... && nonexistent_command && echo Done"]
      restartPolicy: Never
EOF
```

---

### Paso 2.2: Observar el problema

```bash
# Ver Job
kubectl get jobs crashloop-job

# Ver Pods (esperarás ver Error/Completed con exit code != 0)
kubectl get pods -l job-name=crashloop-job
```

---

### Paso 2.3: Diagnosticar

```bash
# Ver logs del Pod fallido
kubectl logs -l job-name=crashloop-job --tail=20

# Ver exit code
kubectl get pods -l job-name=crashloop-job -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.exitCode}'

# Ver descripción del Job
kubectl describe job crashloop-job
```

<details>
<summary>💡 Ver análisis del problema</summary>

**Problema:** Comando inválido causa exit code != 0

**Causa:**
- `nonexistent_command` no existe en la imagen
- Shell retorna exit code 127 (command not found)
- Job reintenta hasta alcanzar `backoffLimit`

**Síntomas:**
- Pods con status `Error`
- Logs muestran "sh: nonexistent_command: not found"
- Job eventualmente marca como `Failed`

</details>

---

### Paso 2.4: Resolver

```bash
# Eliminar Job fallido
kubectl delete job crashloop-job

# Aplicar versión corregida
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: crashloop-job-fixed
spec:
  backoffLimit: 3
  template:
    spec:
      containers:
      - name: processor
        image: busybox:1.35
        command: ["sh", "-c", "echo Starting... && echo Processing... && sleep 3 && echo Done"]
      restartPolicy: Never
EOF

# Verificar
kubectl get jobs crashloop-job-fixed -w
```

**✅ Solución:** Corregir el comando inválido

---

## ⏰ Challenge 3: CronJob que No Ejecuta

### Escenario

El CronJob de backup diario no se ha ejecutado en las últimas 24 horas.

### Paso 3.1: Desplegar CronJob problemático

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: broken-cronjob
spec:
  schedule: "0 2 * * *"
  suspend: true  # ⚠️ PROBLEMA AQUÍ
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: busybox:1.35
            command: ["echo", "Backup running"]
          restartPolicy: Never
EOF
```

---

### Paso 3.2: Observar el problema

```bash
# Ver CronJob
kubectl get cronjobs broken-cronjob

# Ver último schedule time
kubectl get cronjob broken-cronjob -o jsonpath='{.status.lastScheduleTime}'

# Ver Jobs creados (debería estar vacío)
kubectl get jobs -l cronjob=broken-cronjob
```

---

### Paso 3.3: Diagnosticar

```bash
# Ver si está suspendido
kubectl get cronjob broken-cronjob -o jsonpath='{.spec.suspend}'
# Output: true ← PROBLEMA

# Ver descripción
kubectl describe cronjob broken-cronjob
```

<details>
<summary>💡 Ver análisis del problema</summary>

**Problema:** `suspend: true` detiene todas las ejecuciones

**Causa:**
- Alguien suspendió el CronJob (mantenimiento, debugging)
- Se olvidó de reanudar

**Síntomas:**
- `lastScheduleTime` es nulo o muy antiguo
- No se crean nuevos Jobs
- CronJob existe pero no hace nada

</details>

---

### Paso 3.4: Resolver

```bash
# Reanudar CronJob
kubectl patch cronjob broken-cronjob -p '{"spec":{"suspend":false}}'

# Verificar
kubectl get cronjob broken-cronjob -o jsonpath='{.spec.suspend}'
# Output: false ← CORRECTO

# Trigger manual para probar
kubectl create job --from=cronjob/broken-cronjob manual-test

# Ver Job
kubectl get jobs manual-test
kubectl logs job/manual-test
```

**✅ Solución:** Cambiar `suspend: true` → `suspend: false`

---

## 🔄 Challenge 4: Problema de Concurrencia

### Escenario

CronJob de reportes crea múltiples Jobs simultáneos, causando conflictos en la base de datos.

### Paso 4.1: Desplegar CronJob problemático

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: report-cronjob
spec:
  schedule: "*/1 * * * *"  # Cada minuto (para testing)
  concurrencyPolicy: Allow  # ⚠️ PROBLEMA AQUÍ
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: report
            image: busybox:1.35
            command: ["sh", "-c", "echo 'Generating report...' && sleep 90 && echo 'Done'"]
          restartPolicy: Never
EOF
```

---

### Paso 4.2: Observar el problema

```bash
# Esperar 3 minutos y ver Jobs
watch kubectl get jobs -l cronjob=report-cronjob

# Deberías ver múltiples Jobs corriendo simultáneamente
```

---

### Paso 4.3: Diagnosticar

```bash
# Ver política de concurrencia
kubectl get cronjob report-cronjob -o jsonpath='{.spec.concurrencyPolicy}'
# Output: Allow ← Permite múltiples simultáneos

# Contar Jobs activos
kubectl get jobs -l cronjob=report-cronjob --field-selector status.successful!=1 | wc -l
```

<details>
<summary>💡 Ver análisis del problema</summary>

**Problema:** `concurrencyPolicy: Allow` permite múltiples ejecuciones

**Causa:**
- Job tarda 90 segundos
- Schedule es cada 60 segundos
- Se solapan ejecuciones

**Síntomas:**
- Múltiples Jobs corriendo al mismo tiempo
- Posibles conflictos en DB
- Uso excesivo de recursos

**Solución:** Usar `Forbid` o `Replace`

</details>

---

### Paso 4.4: Resolver

```bash
# Eliminar CronJob problemático
kubectl delete cronjob report-cronjob

# Aplicar versión corregida
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: report-cronjob-fixed
spec:
  schedule: "*/1 * * * *"
  concurrencyPolicy: Forbid  # ✅ CORRECTO - No permitir solapamiento
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: report
            image: busybox:1.35
            command: ["sh", "-c", "echo 'Generating report...' && sleep 90 && echo 'Done'"]
          restartPolicy: Never
EOF

# Monitorear
watch kubectl get jobs -l cronjob=report-cronjob-fixed
# Ahora solo 1 Job a la vez
```

**✅ Solución:** Cambiar `concurrencyPolicy: Allow` → `concurrencyPolicy: Forbid`

---

## ⏱️ Challenge 5: Job con DeadlineExceeded

### Escenario

Job de procesamiento se mata antes de completar.

### Paso 5.1: Desplegar Job problemático

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: deadline-job
spec:
  activeDeadlineSeconds: 10  # ⚠️ MUY CORTO
  template:
    spec:
      containers:
      - name: processor
        image: busybox:1.35
        command: ["sh", "-c", "echo Starting... && sleep 30 && echo Done"]
      restartPolicy: Never
EOF
```

---

### Paso 5.2: Observar el problema

```bash
# Monitorear Job (esperará 10 segundos y fallará)
kubectl get jobs deadline-job -w
```

---

### Paso 5.3: Diagnosticar

```bash
# Ver mensaje de error
kubectl get job deadline-job -o jsonpath='{.status.conditions[?(@.type=="Failed")].message}'
# Output: "Job was active longer than specified deadline"

# Ver descripción
kubectl describe job deadline-job
```

<details>
<summary>💡 Ver análisis del problema</summary>

**Problema:** `activeDeadlineSeconds: 10` es muy corto

**Causa:**
- Job requiere 30 segundos
- Deadline es solo 10 segundos
- Kubernetes mata el Job

**Síntomas:**
- Job marca como `Failed`
- Mensaje: "Job was active longer than specified deadline"
- Pod puede estar en estado `Completed` o `Error`

</details>

---

### Paso 5.4: Resolver

```bash
# Eliminar Job fallido
kubectl delete job deadline-job

# Aplicar versión corregida
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: deadline-job-fixed
spec:
  activeDeadlineSeconds: 60  # ✅ SUFICIENTE TIEMPO
  template:
    spec:
      containers:
      - name: processor
        image: busybox:1.35
        command: ["sh", "-c", "echo Starting... && sleep 30 && echo Done"]
      restartPolicy: Never
EOF

# Verificar
kubectl get jobs deadline-job-fixed -w
```

**✅ Solución:** Aumentar `activeDeadlineSeconds` a valor realista

---

## 🎯 Challenge Final: Multi-Problem Job

### Escenario

Este Job tiene **3 problemas**. Encuéntralos y corrígelos todos.

### Paso Final.1: Desplegar Job con múltiples problemas

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: multi-problem-job
spec:
  completions: 5
  parallelism: 10  # ⚠️ PROBLEMA 1: parallelism > completions
  backoffLimit: 0  # ⚠️ PROBLEMA 2: No permite reintentos
  activeDeadlineSeconds: 5  # ⚠️ PROBLEMA 3: Deadline muy corto
  template:
    spec:
      containers:
      - name: worker
        image: busybox:1.35
        command: ["sh", "-c", "echo Processing... && sleep 10 && echo Done"]
      restartPolicy: Never
EOF
```

---

### Paso Final.2: Diagnosticar (sin ver solución)

**Tu turno:** Usa todos los comandos aprendidos para identificar los 3 problemas.

```bash
# Pistas:
kubectl get jobs multi-problem-job -w
kubectl describe job multi-problem-job
kubectl get pods -l job-name=multi-problem-job
```

---

### Paso Final.3: Resolver

<details>
<summary>💡 Ver solución completa</summary>

**Problemas identificados:**

1. **`parallelism: 10` > `completions: 5`** 
   - Ineficiente: creará 5 Pods cuando solo 5 completions se requieren
   - Corrección: `parallelism: 3` (razonable)

2. **`backoffLimit: 0`**
   - No permite reintentos
   - Si un Pod falla una vez, Job falla
   - Corrección: `backoffLimit: 3`

3. **`activeDeadlineSeconds: 5`**
   - Job necesita ~10s por Pod
   - Con 5 completions y parallelism 3, necesita ~20s mínimo
   - Corrección: `activeDeadlineSeconds: 60`

**Job corregido:**

```bash
kubectl delete job multi-problem-job

kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: multi-problem-job-fixed
spec:
  completions: 5
  parallelism: 3  # ✅ Correcto
  backoffLimit: 3  # ✅ Permite reintentos
  activeDeadlineSeconds: 60  # ✅ Tiempo suficiente
  template:
    spec:
      containers:
      - name: worker
        image: busybox:1.35
        command: ["sh", "-c", "echo Processing... && sleep 10 && echo Done"]
      restartPolicy: Never
EOF
```

</details>

---

## 📋 Debugging Cheat Sheet

### Comandos Esenciales

```bash
# Ver estado del Job
kubectl get jobs <job-name>

# Ver detalles y eventos
kubectl describe job <job-name>

# Ver Pods del Job
kubectl get pods -l job-name=<job-name>

# Ver logs
kubectl logs -l job-name=<job-name> --tail=50

# Ver exit code
kubectl get pods -l job-name=<job-name> -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.exitCode}'

# Ver mensaje de fallo
kubectl get job <job-name> -o jsonpath='{.status.conditions[?(@.type=="Failed")].message}'

# CronJob: Ver si está suspendido
kubectl get cronjob <name> -o jsonpath='{.spec.suspend}'

# CronJob: Ver último schedule
kubectl get cronjob <name> -o jsonpath='{.status.lastScheduleTime}'
```

---

## ✅ Scorecard del Challenge

| Challenge | Problema | Solución | Completado |
|-----------|----------|----------|------------|
| 1 | restartPolicy: Always | Cambiar a Never | [ ] |
| 2 | Comando inválido | Corregir comando | [ ] |
| 3 | suspend: true | Cambiar a false | [ ] |
| 4 | concurrencyPolicy: Allow | Cambiar a Forbid | [ ] |
| 5 | activeDeadlineSeconds corto | Aumentar valor | [ ] |
| Final | 3 problemas | Corregir todos | [ ] |

**Puntaje:** __/6

---

## 🎉 ¡Felicitaciones!

Has completado el Troubleshooting Challenge. Ahora puedes:

✅ Diagnosticar Jobs que no completan  
✅ Resolver CrashLoopBackOff rápidamente  
✅ Identificar CronJobs suspendidos  
✅ Corregir problemas de concurrencia  
✅ Ajustar deadlines apropiadamente  
✅ Usar herramientas de debugging eficientemente

**Estás listo para:** Certificación CKAD, troubleshooting en producción, entrevistas técnicas.

---

## 🧹 Limpieza

```bash
# Eliminar todos los recursos del lab
kubectl delete jobs --all
kubectl delete cronjobs --all
```

---

**📅 Última actualización:** Noviembre 2025  
**⏱️ Tiempo promedio:** 30-45 minutos  
**🎯 Dificultad:** 🔴 Avanzado
