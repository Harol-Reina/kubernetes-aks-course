# 🧪 Laboratorio 3: CronJob - Backup Automático de PostgreSQL

## 📋 Información del Laboratorio

| Atributo | Valor |
|----------|-------|
| **Dificultad** | 🟡 Intermedio |
| **Duración** | 45-60 minutos |
| **Objetivos** | Dominar CronJobs, schedules y backups automatizados |
| **Prerequisitos** | Labs 1-2 completados, conocimientos de cron syntax |

---

## 🎯 Objetivos de Aprendizaje

1. ✅ Crear CronJobs con diferentes schedules
2. ✅ Configurar `concurrencyPolicy` correctamente
3. ✅ Implementar backup automatizado de base de datos
4. ✅ Usar PersistentVolumes con CronJobs
5. ✅ Gestionar histórico de Jobs con `successfulJobsHistoryLimit`
6. ✅ Trigger manual de CronJobs para testing
7. ✅ Troubleshooting de CronJobs que no ejecutan

---

## 📝 Escenario

Eres DBA en una empresa SaaS. Necesitas implementar backups automáticos de PostgreSQL:

- **Backup diario** a las 2:00 AM
- **Retention**: 7 días de histórico
- **Storage**: Guardar en PersistentVolume
- **Seguridad**: Credenciales desde Secrets
- **Validación**: Verificar tamaño de backup
- **Alertas**: Notificar si backup falla

---

## ⏰ Parte 1: CronJob Básico - Syntax y Testing

### Paso 1.1: Crear CronJob simple (cada minuto)

Crea `cronjob-test.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-cronjob
spec:
  schedule: "*/1 * * * *"  # Cada minuto
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox:1.35
            command:
            - /bin/sh
            - -c
            - echo "CronJob ejecutado en $(date)"
          restartPolicy: OnFailure
```

---

### Paso 1.2: Aplicar y observar ejecuciones

```bash
# Aplicar CronJob
kubectl apply -f cronjob-test.yaml

# Ver el CronJob
kubectl get cronjobs

# Ver cuándo fue el último schedule
kubectl get cronjobs hello-cronjob -o jsonpath='{.status.lastScheduleTime}'

# Monitorear Jobs creados (esperar 2-3 minutos)
watch kubectl get jobs -l cronjob=hello-cronjob
```

**Deberías ver:**
```
NAME                     COMPLETIONS   DURATION   AGE
hello-cronjob-28367890   1/1           4s         2m
hello-cronjob-28367891   1/1           3s         1m
hello-cronjob-28367892   0/1           2s         5s  # ← Actual
```

---

### Paso 1.3: Ver logs de cada ejecución

```bash
# Listar todos los Jobs del CronJob
kubectl get jobs -l cronjob=hello-cronjob

# Ver logs de la última ejecución
LAST_JOB=$(kubectl get jobs -l cronjob=hello-cronjob --sort-by=.status.startTime -o name | tail -1)
kubectl logs $LAST_JOB
```

---

### Paso 1.4: Trigger manual (sin esperar schedule)

```bash
# Crear Job manualmente desde el CronJob
kubectl create job --from=cronjob/hello-cronjob manual-test

# Ver el Job
kubectl get job manual-test

# Ver logs
kubectl logs job/manual-test
```

**✅ Checkpoint**: Deberías ver el mensaje "CronJob ejecutado en..."

---

### Paso 1.5: Suspender y reanudar CronJob

```bash
# Suspender (detener nuevas ejecuciones)
kubectl patch cronjob hello-cronjob -p '{"spec":{"suspend":true}}'

# Verificar que está suspendido
kubectl get cronjob hello-cronjob -o jsonpath='{.spec.suspend}'
# Output: true

# Esperar 2 minutos → No se crean nuevos Jobs

# Reanudar
kubectl patch cronjob hello-cronjob -p '{"spec":{"suspend":false}}'
```

---

### Paso 1.6: Limpiar

```bash
kubectl delete cronjob hello-cronjob
kubectl delete jobs -l cronjob=hello-cronjob
```

---

## 🗓️ Parte 2: Schedules Comunes

### Paso 2.1: Experimentar con diferentes schedules

Crea `cronjob-schedules.yaml`:

```yaml
---
# Cada 5 minutos
apiVersion: batch/v1
kind: CronJob
metadata:
  name: every-5-min
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: task
            image: busybox:1.35
            command: ["echo", "Cada 5 minutos"]
          restartPolicy: Never

---
# Cada hora (minuto 0)
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hourly
spec:
  schedule: "0 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: task
            image: busybox:1.35
            command: ["echo", "Cada hora"]
          restartPolicy: Never

---
# Diario a las 2:00 AM
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-2am
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: task
            image: busybox:1.35
            command: ["echo", "Diario 2 AM"]
          restartPolicy: Never

---
# Lunes a las 8:00 AM
apiVersion: batch/v1
kind: CronJob
metadata:
  name: monday-8am
spec:
  schedule: "0 8 * * 1"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: task
            image: busybox:1.35
            command: ["echo", "Lunes 8 AM"]
          restartPolicy: Never
```

---

### Paso 2.2: Aplicar y verificar schedules

```bash
# Aplicar todos
kubectl apply -f cronjob-schedules.yaml

# Listar todos los CronJobs
kubectl get cronjobs

# Ver último schedule de cada uno
kubectl get cronjobs -o custom-columns=NAME:.metadata.name,SCHEDULE:.spec.schedule,LAST:.status.lastScheduleTime
```

---

### Paso 2.3: Herramientas de validación de cron

**Usar crontab.guru:**

```bash
# Abrir en navegador para validar syntax
# https://crontab.guru/

# Ejemplos:
# */5 * * * *    → "At every 5th minute"
# 0 2 * * *      → "At 02:00"
# 0 8 * * 1      → "At 08:00 on Monday"
# 0 0 1 * *      → "At 00:00 on day-of-month 1"
```

---

### Paso 2.4: Limpiar CronJobs de prueba

```bash
kubectl delete cronjobs every-5-min hourly daily-2am monday-8am
```

---

## 💾 Parte 3: Backup Completo de PostgreSQL

### Paso 3.1: Crear namespace y recursos

```bash
# Crear namespace para el lab
kubectl create namespace backup-lab

# Configurar contexto
kubectl config set-context --current --namespace=backup-lab
```

---

### Paso 3.2: Desplegar PostgreSQL (para testing)

Crea `postgres-deployment.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
  namespace: backup-lab
type: Opaque
stringData:
  password: "TestPassword123"

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data-pvc
  namespace: backup-lab
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: backup-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
        - name: POSTGRES_DB
          value: "myapp"
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: postgres-data-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: backup-lab
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
```

```bash
# Aplicar
kubectl apply -f postgres-deployment.yaml

# Esperar que PostgreSQL esté listo
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# Verificar
kubectl get pods -l app=postgres
```

---

### Paso 3.3: Poblar base de datos con datos de prueba

```bash
# Conectar a PostgreSQL
kubectl exec -it deployment/postgres -- psql -U postgres -d myapp

# Dentro de psql, ejecutar:
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50),
  email VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (username, email) VALUES
('alice', 'alice@example.com'),
('bob', 'bob@example.com'),
('charlie', 'charlie@example.com');

SELECT * FROM users;

\q  # Salir
```

---

### Paso 3.4: Crear PVC para backups

Crea `backup-pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: backup-lab
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

```bash
kubectl apply -f backup-pvc.yaml
```

---

### Paso 3.5: Crear CronJob de backup

Crea `postgres-backup-cronjob.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: backup-lab
  labels:
    app: database
    type: backup
spec:
  # Schedule: Cada 2 minutos (para testing)
  # En producción: "0 2 * * *" (2 AM diario)
  schedule: "*/2 * * * *"
  
  # Política de concurrencia
  concurrencyPolicy: Forbid  # No permitir backups simultáneos
  
  # Gestión de histórico
  successfulJobsHistoryLimit: 3   # Últimos 3 backups exitosos
  failedJobsHistoryLimit: 1       # Último fallo
  
  # Deadline para iniciar
  startingDeadlineSeconds: 300
  
  jobTemplate:
    spec:
      backoffLimit: 2
      activeDeadlineSeconds: 600  # 10 min max
      
      template:
        metadata:
          labels:
            app: database
            type: backup
        spec:
          containers:
          - name: backup
            image: postgres:15
            command:
            - /bin/bash
            - -c
            - |
              set -e
              
              TIMESTAMP=$(date +%Y%m%d_%H%M%S)
              BACKUP_FILE="/backups/postgres_backup_${TIMESTAMP}.sql.gz"
              
              echo "=========================================="
              echo "PostgreSQL Backup Started"
              echo "Time: $(date)"
              echo "=========================================="
              
              # Ejecutar pg_dump
              echo "Dumping database..."
              PGPASSWORD=$DB_PASSWORD pg_dump \
                -h $DB_HOST \
                -p $DB_PORT \
                -U postgres \
                -d $DB_NAME \
                --verbose \
                | gzip > "${BACKUP_FILE}"
              
              # Verificar backup
              if [ -f "${BACKUP_FILE}" ]; then
                SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
                echo "✅ Backup completado: ${BACKUP_FILE} (${SIZE})"
              else
                echo "❌ Error: Backup file not created"
                exit 1
              fi
              
              # Limpiar backups antiguos (>7 días)
              echo "Cleaning old backups (>7 days)..."
              find /backups -name "postgres_backup_*.sql.gz" -mtime +7 -delete
              
              echo "=========================================="
              echo "Backup completed successfully!"
              echo "Total backups: $(ls -1 /backups | wc -l)"
              echo "=========================================="
            
            env:
            - name: DB_HOST
              value: "postgres-service"
            - name: DB_PORT
              value: "5432"
            - name: DB_NAME
              value: "myapp"
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-credentials
                  key: password
            
            volumeMounts:
            - name: backup-storage
              mountPath: /backups
            
            resources:
              requests:
                cpu: "250m"
                memory: "256Mi"
              limits:
                cpu: "500m"
                memory: "512Mi"
          
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
          
          restartPolicy: OnFailure
```

---

### Paso 3.6: Aplicar CronJob y trigger manual

```bash
# Aplicar CronJob
kubectl apply -f postgres-backup-cronjob.yaml

# Ver CronJob
kubectl get cronjobs

# Trigger manual para testing
kubectl create job --from=cronjob/postgres-backup manual-backup-1

# Ver progreso
kubectl get jobs -w
```

---

### Paso 3.7: Ver logs del backup

```bash
# Ver logs
kubectl logs job/manual-backup-1

# Debería mostrar:
# ==========================================
# PostgreSQL Backup Started
# ...
# ✅ Backup completado: /backups/postgres_backup_20251113_120000.sql.gz (4.2K)
# ==========================================
```

---

### Paso 3.8: Verificar archivos de backup

```bash
# Listar backups creados
kubectl exec -it deployment/postgres -- ls -lh /backups

# Ver contenido del PVC
kubectl run -it --rm debug --image=busybox:1.35 --restart=Never -- sh -c "ls -lh /backups" --overrides='
{
  "spec": {
    "containers": [{
      "name": "debug",
      "image": "busybox:1.35",
      "command": ["ls", "-lh", "/backups"],
      "volumeMounts": [{
        "name": "backup-vol",
        "mountPath": "/backups"
      }]
    }],
    "volumes": [{
      "name": "backup-vol",
      "persistentVolumeClaim": {
        "claimName": "backup-pvc"
      }
    }]
  }
}'
```

---

### Paso 3.9: Esperar ejecuciones automáticas

```bash
# Monitorear CronJob (ejecuta cada 2 minutos)
watch kubectl get jobs -l cronjob=postgres-backup

# Después de 6 minutos, deberías ver 3 Jobs
```

---

## 🔧 Parte 4: concurrencyPolicy

### Paso 4.1: Entender las políticas

```yaml
concurrencyPolicy: Allow    # ✅ Permitir múltiples ejecuciones simultáneas
concurrencyPolicy: Forbid   # ✅ No crear nuevo si anterior está corriendo
concurrencyPolicy: Replace  # ✅ Cancelar anterior y crear nuevo
```

---

### Paso 4.2: Probar concurrencyPolicy: Forbid

Crea `cronjob-forbid.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: long-task-forbid
spec:
  schedule: "*/1 * * * *"  # Cada minuto
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: long-task
            image: busybox:1.35
            command: ["sleep", "120"]  # 2 minutos (más que el schedule)
          restartPolicy: Never
```

```bash
# Aplicar
kubectl apply -f cronjob-forbid.yaml

# Monitorear
watch kubectl get jobs -l cronjob=long-task-forbid

# Deberías ver que NO se crean Jobs simultáneos
# Si uno está corriendo, el schedule se salta
```

---

## 🐛 Parte 5: Troubleshooting

### Problema 1: CronJob no ejecuta

```bash
# Verificar que NO está suspendido
kubectl get cronjob postgres-backup -o jsonpath='{.spec.suspend}'
# Output debe ser: false (o vacío)

# Si está suspendido, reanudar
kubectl patch cronjob postgres-backup -p '{"spec":{"suspend":false}}'
```

---

### Problema 2: Ver por qué falló

```bash
# Ver último Job creado
LAST_JOB=$(kubectl get jobs -l cronjob=postgres-backup --sort-by=.status.startTime -o name | tail -1)

# Ver detalles del Job
kubectl describe $LAST_JOB

# Ver logs
kubectl logs $LAST_JOB
```

---

### Problema 3: Schedule incorrecto

```bash
# Ver el schedule actual
kubectl get cronjob postgres-backup -o jsonpath='{.spec.schedule}'

# Editar schedule
kubectl edit cronjob postgres-backup

# O con patch
kubectl patch cronjob postgres-backup -p '{"spec":{"schedule":"0 3 * * *"}}'
```

---

## ✅ Verificación de Aprendizaje

### Checklist

- [ ] Crear CronJob con schedule correcto
- [ ] Trigger manual con `kubectl create job --from=cronjob`
- [ ] Configurar `concurrencyPolicy: Forbid`
- [ ] Usar PersistentVolumes en CronJobs
- [ ] Gestionar histórico con `successfulJobsHistoryLimit`
- [ ] Suspender/reanudar CronJobs
- [ ] Troubleshooting de CronJobs que no ejecutan
- [ ] Implementar backup completo con cleanup de antiguos

---

## 🧹 Limpieza

```bash
# Eliminar todos los recursos del lab
kubectl delete namespace backup-lab

# Volver al namespace default
kubectl config set-context --current --namespace=default
```

---

## 🎉 ¡Felicitaciones!

Has completado el Lab 3 y ahora dominas:

✅ Sintaxis de cron schedules  
✅ Políticas de concurrencia (Allow, Forbid, Replace)  
✅ Backups automatizados de bases de datos  
✅ Gestión de PersistentVolumes en CronJobs  
✅ Triggers manuales para testing  
✅ Troubleshooting de CronJobs

**Siguiente:** [Lab 4 - Troubleshooting Challenge](./lab-04-troubleshooting.md)

---

**📅 Última actualización:** Noviembre 2025
