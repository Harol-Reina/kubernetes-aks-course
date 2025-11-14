# 🧪 Laboratorio 2: Jobs Paralelos - Procesamiento Batch

## 📋 Información del Laboratorio

| Atributo | Valor |
|----------|-------|
| **Dificultad** | 🟡 Intermedio |
| **Duración** | 30-40 minutos |
| **Objetivos** | Dominar ejecución paralela y patrones de procesamiento batch |
| **Prerequisitos** | Lab 1 completado, conceptos de paralelismo |

---

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio serás capaz de:

1. ✅ Configurar Jobs con `completions` y `parallelism`
2. ✅ Implementar patrón de procesamiento paralelo con completions fijos
3. ✅ Crear work queue pattern con worker pool
4. ✅ Usar Indexed Jobs para procesamiento particionado (K8s 1.21+)
5. ✅ Optimizar rendimiento ajustando paralelismo
6. ✅ Monitorear Jobs paralelos en tiempo real

---

## 📝 Escenario

Eres el ingeniero de datos en una fintech que procesa transacciones. Cada noche deben procesarse:

- **10,000 transacciones** de validación
- **Requisito**: Completar en menos de 10 minutos
- **Restricción**: Solo 5 workers simultáneos (límite de DB connections)
- **Solución**: Job paralelo que distribuye carga entre workers

---

## 🔢 Parte 1: Parallel Job con Fixed Completions

### Paso 1.1: Entender el patrón

**Patrón Fixed Completions:**
```
completions: 10    # Total de ejecuciones exitosas requeridas
parallelism: 3     # Máximo 3 Pods corriendo simultáneamente
```

**Comportamiento:**
- Kubernetes crea hasta 3 Pods simultáneos
- Cuando uno completa, crea otro (si faltan completions)
- Continúa hasta alcanzar 10 completions exitosos

---

### Paso 1.2: Crear Job paralelo básico

Crea `parallel-fixed.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-processor
  labels:
    app: batch-processing
    type: parallel
spec:
  # Configuración paralela
  completions: 10         # Ejecutar 10 veces
  parallelism: 3          # Máximo 3 simultáneos
  backoffLimit: 5
  activeDeadlineSeconds: 600  # 10 minutos max
  
  template:
    metadata:
      labels:
        job-name: parallel-processor
    spec:
      containers:
      - name: worker
        image: busybox:1.35
        command:
        - /bin/sh
        - -c
        - |
          # Generar ID único para esta tarea
          TASK_ID=$(shuf -i 1-10000 -n 1)
          WORKER_NAME=$(hostname)
          
          echo "=========================================="
          echo "Worker: ${WORKER_NAME}"
          echo "Task ID: ${TASK_ID}"
          echo "Started: $(date)"
          echo "=========================================="
          
          # Simular procesamiento (5-15 segundos)
          DURATION=$(shuf -i 5-15 -n 1)
          echo "Processing for ${DURATION} seconds..."
          
          for i in $(seq 1 ${DURATION}); do
            echo "Progress: ${i}/${DURATION}"
            sleep 1
          done
          
          echo "✅ Task ${TASK_ID} completed by ${WORKER_NAME}"
          echo "Finished: $(date)"
          exit 0
        
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "250m"
            memory: "256Mi"
      
      restartPolicy: OnFailure
```

---

### Paso 1.3: Aplicar y monitorear

```bash
# Aplicar el Job
kubectl apply -f parallel-fixed.yaml

# Monitorear en tiempo real
kubectl get jobs parallel-processor -w
```

**Deberías ver:**
```
NAME                 COMPLETIONS   DURATION   AGE
parallel-processor   0/10          0s         2s
parallel-processor   1/10          8s         10s
parallel-processor   2/10          12s        14s
parallel-processor   3/10          15s        17s
...
parallel-processor   10/10         45s        47s  # ← Completado!
```

---

### Paso 1.4: Observar Pods en paralelo

**En otra terminal (o en tmux):**

```bash
# Watch de Pods en tiempo real
watch kubectl get pods -l job-name=parallel-processor
```

**Deberías ver:**
- Máximo 3 Pods corriendo simultáneamente
- Cuando uno completa (`Completed`), otro se crea
- Hasta alcanzar 10 Pods totales completados

---

### Paso 1.5: Analizar logs de todos los workers

```bash
# Ver logs de todos los Pods (uno por uno)
kubectl logs -l job-name=parallel-processor --tail=20

# Ver logs de un Pod específico
kubectl get pods -l job-name=parallel-processor
kubectl logs parallel-processor-xxxxx  # Reemplazar con nombre real
```

---

### Paso 1.6: Calcular tiempo total vs paralelo

```bash
# Ver duración total del Job
kubectl get job parallel-processor -o jsonpath='{.status.completionTime}'
kubectl get job parallel-processor -o jsonpath='{.status.startTime}'

# Calcular diferencia (en segundos)
START=$(kubectl get job parallel-processor -o jsonpath='{.status.startTime}' | date -u -f - +%s 2>/dev/null || echo 0)
END=$(kubectl get job parallel-processor -o jsonpath='{.status.completionTime}' | date -u -f - +%s 2>/dev/null || echo 0)
echo "Duración total: $((END - START)) segundos"
```

**🧮 Análisis:**
- **Sin paralelismo** (1 Pod): ~100-150 segundos (10 tareas × ~10-15s cada una)
- **Con paralelismo 3**: ~45-60 segundos (reducción de ~50-60%)

---

### Paso 1.7: Experimentar con diferentes niveles de paralelismo

```bash
# Limpiar Job anterior
kubectl delete job parallel-processor

# Editar YAML y cambiar parallelism a 5
# parallelism: 5

kubectl apply -f parallel-fixed.yaml
kubectl get jobs parallel-processor -w
```

**📊 Compara duraciones:**
- parallelism: 1 → ~100-150s
- parallelism: 3 → ~45-60s
- parallelism: 5 → ~30-40s
- parallelism: 10 → ~15-20s (todos en paralelo)

---

## 🎯 Parte 2: Work Queue Pattern (Worker Pool)

### Paso 2.1: Entender el patrón

**Patrón Work Queue:**
```
parallelism: 5       # 5 workers corriendo
# NO se define completions
```

**Comportamiento:**
- Workers consumen tareas de una cola externa (Redis, RabbitMQ, S3)
- Cada worker termina cuando la cola está vacía
- No hay número fijo de completions

---

### Paso 2.2: Simular Work Queue con contador compartido

Crea `work-queue-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: work-queue-processor
  labels:
    app: queue-worker
    pattern: work-queue
spec:
  # Solo parallelism, SIN completions
  parallelism: 5
  backoffLimit: 3
  activeDeadlineSeconds: 300
  
  template:
    spec:
      containers:
      - name: worker
        image: busybox:1.35
        command:
        - /bin/sh
        - -c
        - |
          WORKER=$(hostname)
          echo "[${WORKER}] Worker iniciado"
          
          # Simular consumo de cola
          # En producción: while task=$(redis-cli LPOP queue); do
          
          TASKS_PROCESSED=0
          for i in 1 2 3 4 5; do
            TASK_ID=$(shuf -i 1000-9999 -n 1)
            echo "[${WORKER}] Procesando tarea #${TASK_ID}"
            sleep $(shuf -i 2-5 -n 1)
            echo "[${WORKER}] ✅ Tarea #${TASK_ID} completada"
            TASKS_PROCESSED=$((TASKS_PROCESSED + 1))
          done
          
          echo "[${WORKER}] Cola vacía. Total procesado: ${TASKS_PROCESSED}"
          echo "[${WORKER}] Finalizando..."
          exit 0
        
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
      
      restartPolicy: OnFailure
```

---

### Paso 2.3: Aplicar y observar

```bash
# Aplicar Job
kubectl apply -f work-queue-job.yaml

# Monitorear
kubectl get jobs work-queue-processor -w

# Ver Pods (deberías ver 5 corriendo simultáneamente)
kubectl get pods -l job-name=work-queue-processor
```

**Observa:**
- 5 Pods se crean inmediatamente
- Todos corren en paralelo
- Cuando los 5 terminan, el Job se marca como completado
- `COMPLETIONS` muestra `5/1 of 5` (confuso, pero correcto)

---

### Paso 2.4: Ver logs de todos los workers

```bash
# Logs de todos los workers
for pod in $(kubectl get pods -l job-name=work-queue-processor -o name); do
  echo "=== $pod ==="
  kubectl logs $pod | head -10
  echo ""
done
```

---

## 📊 Parte 3: Indexed Jobs (K8s 1.21+)

### Paso 3.1: Entender Indexed Mode

**Indexed Jobs:**
```
completionMode: Indexed
completions: 5
parallelism: 2
```

**Comportamiento:**
- Cada Pod recibe un índice único: 0, 1, 2, 3, 4
- Variable `JOB_COMPLETION_INDEX` disponible dentro del Pod
- Útil para procesar datos particionados (shards)

---

### Paso 3.2: Crear Indexed Job

Crea `indexed-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: indexed-data-processor
  labels:
    app: data-pipeline
    type: indexed
spec:
  # Modo Indexed
  completionMode: Indexed
  completions: 5            # Índices: 0, 1, 2, 3, 4
  parallelism: 2            # 2 workers simultáneos
  backoffLimit: 2
  
  template:
    spec:
      containers:
      - name: processor
        image: busybox:1.35
        command:
        - /bin/sh
        - -c
        - |
          # JOB_COMPLETION_INDEX es inyectado automáticamente
          INDEX=${JOB_COMPLETION_INDEX}
          WORKER=$(hostname)
          
          echo "=========================================="
          echo "Worker: ${WORKER}"
          echo "Processing Partition: ${INDEX}"
          echo "=========================================="
          
          # Simular procesamiento de partición específica
          echo "Descargando data_${INDEX}.csv..."
          sleep 2
          
          echo "Procesando registros de partición ${INDEX}..."
          for i in 1 2 3 4 5; do
            echo "  Registro ${i} de partición ${INDEX} procesado"
            sleep 1
          done
          
          echo "Guardando resultados de partición ${INDEX}..."
          sleep 1
          
          echo "✅ Partición ${INDEX} completada!"
          exit 0
        
        env:
        # JOB_COMPLETION_INDEX es inyectado por Kubernetes
        - name: TOTAL_PARTITIONS
          value: "5"
        
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
      
      restartPolicy: OnFailure
```

---

### Paso 3.3: Aplicar y monitorear índices

```bash
# Aplicar Job
kubectl apply -f indexed-job.yaml

# Ver Pods con sus índices
kubectl get pods -l job-name=indexed-data-processor --sort-by=.metadata.name
```

**Deberías ver:**
```
NAME                            READY   STATUS    AGE
indexed-data-processor-0-xxxxx  1/1     Running   5s
indexed-data-processor-1-xxxxx  1/1     Running   5s
indexed-data-processor-2-xxxxx  0/1     Pending   5s
indexed-data-processor-3-xxxxx  0/1     Pending   5s
indexed-data-processor-4-xxxxx  0/1     Pending   5s
```

**📝 Nota**: Los nombres tienen el índice (0, 1, 2, 3, 4)

---

### Paso 3.4: Ver logs por índice

```bash
# Logs de partición 0
kubectl logs indexed-data-processor-0-xxxxx  # Reemplazar xxxxx

# Logs de todas las particiones
for i in 0 1 2 3 4; do
  POD=$(kubectl get pod -l job-name=indexed-data-processor -l batch.kubernetes.io/job-completion-index=$i -o name)
  echo "=== Partition $i ==="
  kubectl logs $POD 2>/dev/null || echo "Aún no completado"
  echo ""
done
```

---

### Paso 3.5: Verificar variable JOB_COMPLETION_INDEX

```bash
# Ejecutar comando dentro de un Pod para ver la variable
kubectl exec -it indexed-data-processor-0-xxxxx -- sh -c 'echo "Mi índice es: $JOB_COMPLETION_INDEX"'
```

**Salida esperada:** `Mi índice es: 0`

---

## 📈 Parte 4: Caso Real - Procesamiento de Logs

### Paso 4.1: Escenario realista

**Requisito:** Procesar logs de 12 meses (enero-diciembre)  
**Solución:** Indexed Job con 12 índices (uno por mes)

Crea `log-processor-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: log-processor-monthly
  labels:
    app: analytics
    year: "2024"
spec:
  completionMode: Indexed
  completions: 12           # 12 meses
  parallelism: 4            # 4 meses simultáneos
  backoffLimit: 2
  activeDeadlineSeconds: 3600  # 1 hora max
  
  template:
    metadata:
      labels:
        job-name: log-processor-monthly
    spec:
      containers:
      - name: processor
        image: python:3.11-slim
        command:
        - python3
        - -c
        - |
          import os
          import time
          
          months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
          month_index = int(os.getenv('JOB_COMPLETION_INDEX', 0))
          month_name = months[month_index]
          
          print(f"{'='*50}")
          print(f"Processing Logs for: {month_name} 2024")
          print(f"{'='*50}")
          
          print(f"[1/4] Downloading logs for {month_name}...")
          time.sleep(3)
          
          print(f"[2/4] Parsing {month_name} logs...")
          time.sleep(4)
          
          print(f"[3/4] Aggregating metrics for {month_name}...")
          time.sleep(3)
          
          print(f"[4/4] Uploading results for {month_name}...")
          time.sleep(2)
          
          print(f"✅ {month_name} 2024 processing completed!")
        
        env:
        - name: YEAR
          value: "2024"
        - name: OUTPUT_BUCKET
          value: "s3://analytics/2024/"
        
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
      
      restartPolicy: OnFailure
```

---

### Paso 4.2: Ejecutar y monitorear progreso

```bash
# Aplicar Job
kubectl apply -f log-processor-job.yaml

# Monitorear completions
kubectl get job log-processor-monthly -w
```

**Deberías ver progreso:**
```
NAME                     COMPLETIONS   DURATION   AGE
log-processor-monthly    0/12          0s         2s
log-processor-monthly    1/12          15s        17s
log-processor-monthly    2/12          18s        20s
log-processor-monthly    4/12          25s        27s  # 4 en paralelo
...
log-processor-monthly    12/12         90s        92s  # Completado
```

---

### Paso 4.3: Ver logs por mes

```bash
# Ver logs de enero (índice 0)
kubectl logs -l batch.kubernetes.io/job-completion-index=0

# Ver logs de todos los meses procesados
for i in $(seq 0 11); do
  echo "=== Month Index: $i ==="
  kubectl logs -l batch.kubernetes.io/job-completion-index=$i --tail=5 2>/dev/null
  echo ""
done
```

---

## 🧪 Parte 5: Comparación de Rendimiento

### Paso 5.1: Benchmark de diferentes configuraciones

Crea script `benchmark-jobs.sh`:

```bash
#!/bin/bash

echo "Benchmark de Jobs Paralelos"
echo "=============================="

# Test 1: Sin paralelismo
echo "Test 1: Parallelism = 1"
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: bench-p1
spec:
  completions: 10
  parallelism: 1
  template:
    spec:
      containers:
      - name: worker
        image: busybox:1.35
        command: ["sh", "-c", "sleep 5 && echo Done"]
      restartPolicy: Never
EOF

kubectl wait --for=condition=complete job/bench-p1 --timeout=300s
DURATION_P1=$(kubectl get job bench-p1 -o jsonpath='{.status.completionTime}' | date -u -f - +%s)
START_P1=$(kubectl get job bench-p1 -o jsonpath='{.status.startTime}' | date -u -f - +%s)
echo "Duración: $((DURATION_P1 - START_P1))s"
kubectl delete job bench-p1

# Test 2: Parallelism = 5
echo ""
echo "Test 2: Parallelism = 5"
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: bench-p5
spec:
  completions: 10
  parallelism: 5
  template:
    spec:
      containers:
      - name: worker
        image: busybox:1.35
        command: ["sh", "-c", "sleep 5 && echo Done"]
      restartPolicy: Never
EOF

kubectl wait --for=condition=complete job/bench-p5 --timeout=300s
DURATION_P5=$(kubectl get job bench-p5 -o jsonpath='{.status.completionTime}' | date -u -f - +%s)
START_P5=$(kubectl get job bench-p5 -o jsonpath='{.status.startTime}' | date -u -f - +%s)
echo "Duración: $((DURATION_P5 - START_P5))s"
kubectl delete job bench-p5

echo ""
echo "=============================="
echo "Resumen:"
echo "Parallelism 1: ~50s (10 × 5s)"
echo "Parallelism 5: ~10s (2 grupos × 5s)"
echo "Speedup: ~5x"
```

---

### Paso 5.2: Ejecutar benchmark

```bash
# Dar permisos de ejecución
chmod +x benchmark-jobs.sh

# Ejecutar
./benchmark-jobs.sh
```

---

## ✅ Verificación de Aprendizaje

### Quiz Rápido

1. **Si `completions: 10` y `parallelism: 3`, ¿cuántos Pods corren simultáneamente?**
   - [ ] 10
   - [x] Máximo 3
   - [ ] 1
   - [ ] 13

2. **¿Cuál patrón NO define `completions`?**
   - [ ] Fixed Completions
   - [ ] Indexed Jobs
   - [x] Work Queue
   - [ ] Parallel Processing

3. **En Indexed Jobs, ¿qué variable tiene el índice del Pod?**
   - [ ] POD_INDEX
   - [x] JOB_COMPLETION_INDEX
   - [ ] COMPLETION_INDEX
   - [ ] INDEX

4. **Si quieres procesar 100 archivos con 10 workers, ¿qué configuración usas?**
   - [x] completions: 100, parallelism: 10
   - [ ] completions: 10, parallelism: 100
   - [ ] parallelism: 100
   - [ ] completions: 10

---

## 🎯 Desafío Extra

### Desafío: ETL Paralelo

Crea un Indexed Job que:
- Procesa 8 particiones de datos
- 4 workers en paralelo
- Cada worker simula: Download (3s) → Transform (5s) → Upload (2s)
- Timeout de 5 minutos
- TTL de 10 minutos después de completar

<details>
<summary>💡 Ver solución</summary>

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: etl-challenge
spec:
  completionMode: Indexed
  completions: 8
  parallelism: 4
  backoffLimit: 2
  activeDeadlineSeconds: 300
  ttlSecondsAfterFinished: 600
  template:
    spec:
      containers:
      - name: etl-worker
        image: busybox:1.35
        command:
        - sh
        - -c
        - |
          echo "[Partition ${JOB_COMPLETION_INDEX}] Download (3s)..."
          sleep 3
          echo "[Partition ${JOB_COMPLETION_INDEX}] Transform (5s)..."
          sleep 5
          echo "[Partition ${JOB_COMPLETION_INDEX}] Upload (2s)..."
          sleep 2
          echo "[Partition ${JOB_COMPLETION_INDEX}] ✅ Done!"
      restartPolicy: Never
```

</details>

---

## 🎉 ¡Felicitaciones!

Has dominado Jobs paralelos y ahora sabes:

✅ Configurar `completions` y `parallelism`  
✅ Implementar Fixed Completions pattern  
✅ Crear Work Queue pattern  
✅ Usar Indexed Jobs (K8s 1.21+)  
✅ Optimizar rendimiento con paralelismo  
✅ Procesar datos particionados eficientemente

**Siguiente:** [Lab 3 - CronJobs](./lab-03-cronjob-backup.md)

---

**📅 Última actualización:** Noviembre 2025
