# 🧪 Lab 2: Sidecar Logging Pattern

> **Duración estimada**: 35 minutos  
> **Nivel**: 🟡 Intermedio  
> **Objetivos**: Implementar sidecar para logging con shared volumes

---

## 🎯 Objetivos

1. ✅ Crear Pod multi-container con sidecar
2. ✅ Configurar shared volumes (emptyDir)
3. ✅ Implementar log processing en sidecar
4. ✅ Entender localhost networking
5. ✅ Aplicar read-only mounts

---

## 📋 Prerrequisitos

```bash
kubectl cluster-info
kubectl delete pod --all --force 2>/dev/null || true
```

---

## 🔨 Parte 1: Sidecar Básico (10 min)

### Paso 1.1: Crear Pod con Sidecar

Archivo `sidecar-basic.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: log-app
spec:
  containers:
  
  # Main App: Escribe logs
  - name: app
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      while true; do
        echo "$(date) - Log entry" >> /logs/app.log
        echo "$(date) - App running"
        sleep 5
      done
    volumeMounts:
    - name: logs
      mountPath: /logs
  
  # Sidecar: Lee logs
  - name: log-sidecar
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      echo "Sidecar iniciado"
      while [ ! -f /logs/app.log ]; do
        sleep 2
      done
      echo "✅ Logs detectados, procesando..."
      tail -f /logs/app.log
    volumeMounts:
    - name: logs
      mountPath: /logs
      readOnly: true  # Solo lectura
  
  volumes:
  - name: logs
    emptyDir: {}
```

---

### Paso 1.2: Aplicar y Verificar

```bash
# Aplicar
kubectl apply -f sidecar-basic.yaml

# Ver ambos containers running
kubectl get pod log-app

# Expected:
# NAME      READY   STATUS    RESTARTS   AGE
# log-app   2/2     Running   0          10s

# Ver logs de app (escribiendo)
kubectl logs log-app -c app

# Ver logs de sidecar (leyendo)
kubectl logs log-app -c log-sidecar

# Ver ambos en tiempo real (con stern si disponible)
stern log-app
```

---

### Paso 1.3: Verificar Shared Volume

```bash
# Ver archivos desde app
kubectl exec log-app -c app -- ls -la /logs

# Ver mismos archivos desde sidecar
kubectl exec log-app -c log-sidecar -- ls -la /logs

# Intentar escribir desde sidecar (debe fallar por read-only)
kubectl exec log-app -c log-sidecar -- touch /logs/test.txt
# Error: Read-only file system ✅

# Escribir desde app (debe funcionar)
kubectl exec log-app -c app -- touch /logs/test.txt
# Success ✅
```

---

### ✅ Checkpoint 1

- [ ] Ambos containers comparten el mismo volume
- [ ] App escribe logs, sidecar lee
- [ ] Sidecar tiene mount read-only (seguridad)
- [ ] READY 2/2 indica ambos containers corriendo

---

## 📊 Parte 2: Log Processing Avanzado (12 min)

### Paso 2.1: Sidecar con Formato JSON

Archivo `sidecar-json.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: log-json
spec:
  containers:
  
  - name: app
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      while true; do
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        LEVEL=$(shuf -e INFO WARN ERROR -n 1)
        MESSAGE="Sample log message"
        
        # Formato custom
        echo "[${TIMESTAMP}] ${LEVEL} | ${MESSAGE}" >> /logs/app.log
        sleep 3
      done
    volumeMounts:
    - name: logs
      mountPath: /logs
  
  - name: json-converter
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      while [ ! -f /logs/app.log ]; do sleep 1; done
      
      tail -f /logs/app.log | while read line; do
        TIMESTAMP=$(echo "$line" | cut -d']' -f1 | tr -d '[')
        LEVEL=$(echo "$line" | cut -d'|' -f1 | awk '{print $NF}')
        MESSAGE=$(echo "$line" | cut -d'|' -f2-)
        
        JSON="{\"timestamp\":\"${TIMESTAMP}\",\"level\":\"${LEVEL}\",\"message\":\"${MESSAGE}\"}"
        echo "$JSON" >> /logs/app.json
        echo "[CONVERTER] Converted: $LEVEL"
      done
    volumeMounts:
    - name: logs
      mountPath: /logs
  
  volumes:
  - name: logs
    emptyDir: {}
```

```bash
# Aplicar
kubectl apply -f sidecar-json.yaml

# Ver logs custom (app)
kubectl logs log-json -c app

# Ver conversión (sidecar)
kubectl logs log-json -c json-converter

# Ver JSON generado
kubectl exec log-json -c json-converter -- cat /logs/app.json
```

---

### Paso 2.2: Múltiples Sidecars

Archivo `multi-sidecar.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-sidecar
spec:
  containers:
  
  - name: web
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
  
  # Sidecar 1: Access logs
  - name: access-logger
    image: busybox:1.35
    command: ['sh', '-c', 'tail -f /logs/access.log || sleep infinity']
    volumeMounts:
    - name: logs
      mountPath: /logs
      readOnly: true
  
  # Sidecar 2: Error logs
  - name: error-logger
    image: busybox:1.35
    command: ['sh', '-c', 'tail -f /logs/error.log || sleep infinity']
    volumeMounts:
    - name: logs
      mountPath: /logs
      readOnly: true
  
  volumes:
  - name: logs
    emptyDir: {}
```

```bash
kubectl apply -f multi-sidecar.yaml

# Ver 3 containers
kubectl get pod multi-sidecar
# READY: 3/3

# Generar tráfico
kubectl port-forward multi-sidecar 8080:80 &
curl localhost:8080

# Ver logs de cada sidecar
kubectl logs multi-sidecar -c access-logger
kubectl logs multi-sidecar -c error-logger
```

---

### ✅ Checkpoint 2

- [ ] Sidecar puede transformar formato de logs
- [ ] Múltiples sidecars pueden procesar diferentes logs
- [ ] Cada sidecar tiene su propia función específica

---

## 🌐 Parte 3: Localhost Communication (8 min)

### Paso 3.1: Sidecar que Consulta Main App

Archivo `sidecar-monitor.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-monitor
spec:
  containers:
  
  - name: web
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
  
  - name: health-monitor
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      while true; do
        if wget -q -O- http://localhost:80 > /dev/null 2>&1; then
          echo "$(date) ✅ Health check OK"
        else
          echo "$(date) ❌ Health check FAILED"
        fi
        sleep 10
      done
```

```bash
kubectl apply -f sidecar-monitor.yaml

# Ver monitor verificando salud
kubectl logs app-with-monitor -c health-monitor -f

# Desde sidecar, acceder a main app via localhost
kubectl exec app-with-monitor -c health-monitor -- wget -qO- http://localhost

# Desde main app, ver que está listening
kubectl exec app-with-monitor -c web -- netstat -tuln | grep :80
```

---

### Paso 3.2: Verificar Networking Compartido

```bash
# Ver IP del Pod (ambos containers la comparten)
kubectl get pod app-with-monitor -o jsonpath='{.status.podIP}'

# Desde cualquier container, ver misma IP
kubectl exec app-with-monitor -c web -- hostname -i
kubectl exec app-with-monitor -c health-monitor -- hostname -i
# Misma IP ✅

# Ver procesos de ambos containers
kubectl exec app-with-monitor -c web -- ps aux
kubectl exec app-with-monitor -c health-monitor -- ps aux
```

---

### ✅ Checkpoint 3

- [ ] Containers en mismo Pod comparten IP
- [ ] Comunicación via localhost:port
- [ ] Ambos containers pueden ver puertos abiertos

---

## 🐛 Parte 4: Troubleshooting (5 min)

### Problema 1: Sidecar No Ve Logs

```bash
# Diagnosticar
kubectl get pod log-app -o jsonpath='{range .spec.containers[*]}{.name}{": "}{.volumeMounts[*].mountPath}{"\n"}{end}'

# Verificar mountPath es el mismo
# App:     /logs
# Sidecar: /logs ✅

# Ver archivos en cada container
kubectl exec log-app -c app -- ls /logs
kubectl exec log-app -c sidecar -- ls /logs
```

### Problema 2: OOMKilled en Sidecar

```bash
# Ver cuál container fue killed
kubectl describe pod log-app | grep -A 5 "Last State"

# Aumentar memory limit
resources:
  limits:
    memory: "256Mi"  # Era 64Mi
```

### Problema 3: Sidecar Arranca Antes que App

```bash
# Agregar wait en sidecar
command:
- sh
- -c
- |
  echo "Esperando logs de app..."
  while [ ! -f /logs/app.log ]; do
    sleep 2
  done
  tail -f /logs/app.log
```

---

## 🎯 Desafíos

### Desafío 1: Fluentd Real

Implementa sidecar con Fluentd real:

```yaml
- name: fluentd
  image: fluent/fluentd:v1.16
  env:
  - name: FLUENT_ELASTICSEARCH_HOST
    value: "elasticsearch"
```

### Desafío 2: Log Rotation

Sidecar que rota logs cada 100 líneas:

```bash
tail -f /logs/app.log | while read line; do
  echo "$line" >> /logs/current.log
  LINES=$(wc -l < /logs/current.log)
  if [ $LINES -ge 100 ]; then
    mv /logs/current.log /logs/rotated-$(date +%s).log
  fi
done
```

---

## 📝 Limpieza

```bash
kubectl delete pod log-app log-json multi-sidecar app-with-monitor --force
```

---

## ✅ Auto-Evaluación

- [ ] Creé Pod con app + sidecar
- [ ] Configuré shared volume correctamente
- [ ] Implementé read-only mount en sidecar
- [ ] Transformé formato de logs (custom → JSON)
- [ ] Usé múltiples sidecars (access + error)
- [ ] Verifiqué localhost communication
- [ ] Troubleshoot problemas comunes

---

## 🎓 Conceptos Clave

```
SIDECAR PATTERN
├─ Containers ejecutan EN PARALELO
├─ Shared resources: volumes, network
├─ Separación de concerns
└─ Read-only mounts para seguridad

LOCALHOST NETWORKING
├─ Misma IP para todos los containers
├─ Comunicación: localhost:port
└─ Puertos no pueden duplicarse

SHARED VOLUMES
├─ emptyDir: temporal (vida del Pod)
├─ PVC: persistente
└─ mountPath debe ser igual
```

---

**¡Lab 2 completado!** 🎉

*Tiempo*: _____ min  
*Próximo*: Lab 3 - Multi-Container Communication