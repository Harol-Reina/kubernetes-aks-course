# 📦 Módulo 20: Init Containers & Sidecar Patterns - RESUMEN

> **Quick Reference Guide para Multi-Container Pods**

---

## 🎯 Conceptos Clave (30 segundos)

```
INIT CONTAINERS
├─ Ejecutan ANTES de main containers
├─ Secuenciales (uno por uno)
├─ Deben completar exitosamente (exit 0)
└─ Uso: setup, wait-for, migrations

SIDECAR PATTERN
├─ Ejecutan JUNTO con main container
├─ Paralelos (todos juntos)
├─ Comparten: networking (localhost) + volumes
└─ Uso: logging, monitoring, proxy

SHARED RESOURCES
├─ Network: localhost communication
├─ Volumes: emptyDir, PVC
└─ Process namespace (opcional)
```

---

## ⚡ Comandos Esenciales (2 minutos)

### Ver Containers en un Pod

```bash
# Listar todos los containers (init + main)
kubectl get pod <pod> -o jsonpath='{.spec.initContainers[*].name}{"\n"}{.spec.containers[*].name}'

# Ver status de init containers
kubectl get pod <pod> -o jsonpath='{.status.initContainerStatuses[*].state}'

# Ver status de main containers
kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[*].ready}'

# Resumen completo
kubectl describe pod <pod>
```

---

### Logs de Container Específico

```bash
# Logs de main container
kubectl logs <pod> -c <container-name>

# Logs de init container
kubectl logs <pod> -c <init-container-name>

# Logs previos (container reiniciado)
kubectl logs <pod> -c <container> --previous

# Logs en vivo (follow)
kubectl logs -f <pod> -c <container>

# Todos los containers (con stern)
stern <pod>
```

---

### Exec en Container Específico

```bash
# Shell interactivo
kubectl exec -it <pod> -c <container> -- /bin/sh

# Comando único
kubectl exec <pod> -c <container> -- <comando>

# Ver procesos
kubectl exec <pod> -c <container> -- ps aux

# Ver shared volume
kubectl exec <pod> -c <container> -- ls -la /shared
```

---

## 📝 YAML Templates (5 minutos)

### Template 1: Init Container Básico

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  # INIT CONTAINERS (ejecutan primero)
  initContainers:
  - name: init-myservice
    image: busybox:1.35
    command: ['sh', '-c', 'echo "Init ejecutando..." && sleep 5']
    resources:
      requests:
        cpu: "100m"
        memory: "64Mi"
      limits:
        cpu: "200m"
        memory: "128Mi"
  
  # MAIN CONTAINERS (ejecutan después)
  containers:
  - name: myapp
    image: nginx:1.25
    ports:
    - containerPort: 80
```

**Aplicar:**
```bash
kubectl apply -f pod-init.yaml
kubectl get pod myapp-pod -w  # Ver progreso
```

---

### Template 2: Wait-for Service Pattern

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-wait-db
spec:
  initContainers:
  - name: wait-for-database
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      echo "Esperando a que database esté listo..."
      TIMEOUT=300
      ELAPSED=0
      until nslookup postgres.default.svc.cluster.local || [ $ELAPSED -ge $TIMEOUT ]; do
        echo "Database no disponible, reintentando..."
        sleep 2
        ELAPSED=$((ELAPSED + 2))
      done
      if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "TIMEOUT: Database no disponible"
        exit 1
      fi
      echo "✅ Database listo!"
    resources:
      requests:
        cpu: "100m"
        memory: "64Mi"
  
  containers:
  - name: app
    image: myapp:v1
    env:
    - name: DATABASE_HOST
      value: "postgres.default.svc.cluster.local"
```

**Verificar:**
```bash
# Ver logs del init container
kubectl logs app-wait-db -c wait-for-database

# Ver si completó
kubectl get pod app-wait-db -o jsonpath='{.status.initContainerStatuses[0].state}'
```

---

### Template 3: Sidecar Logging

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-logging
spec:
  containers:
  
  # MAIN APP (escribe logs)
  - name: app
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      while true; do
        echo "$(date) - App log entry" >> /var/log/app/app.log
        sleep 5
      done
    volumeMounts:
    - name: logs
      mountPath: /var/log/app
    resources:
      requests:
        cpu: "100m"
        memory: "64Mi"
  
  # SIDECAR (lee y procesa logs)
  - name: log-shipper
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      echo "Log shipper iniciado..."
      while true; do
        if [ -f /var/log/app/app.log ]; then
          echo "[SHIPPER] Procesando logs..."
          tail -n 5 /var/log/app/app.log
        fi
        sleep 10
      done
    volumeMounts:
    - name: logs
      mountPath: /var/log/app
      readOnly: true
    resources:
      requests:
        cpu: "50m"
        memory: "32Mi"
  
  # SHARED VOLUME
  volumes:
  - name: logs
    emptyDir: {}
```

**Verificar:**
```bash
# Ver logs del app
kubectl logs app-with-logging -c app

# Ver logs del sidecar
kubectl logs app-with-logging -c log-shipper

# Ver ambos (stern)
stern app-with-logging
```

---

### Template 4: Ambassador Proxy Pattern

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-proxy
spec:
  containers:
  
  # MAIN APP (conecta a localhost:6379)
  - name: app
    image: redis:7-alpine
    command: ['sh', '-c', 'redis-cli -h localhost ping']
    env:
    - name: REDIS_HOST
      value: "localhost"
    - name: REDIS_PORT
      value: "6379"
  
  # AMBASSADOR (proxy a Redis externo)
  - name: redis-proxy
    image: haproxy:2.8-alpine
    ports:
    - containerPort: 6379
      name: redis
    volumeMounts:
    - name: haproxy-config
      mountPath: /usr/local/etc/haproxy
    resources:
      requests:
        cpu: "50m"
        memory: "32Mi"
  
  volumes:
  - name: haproxy-config
    configMap:
      name: haproxy-redis-config
```

---

### Template 5: Multi-Container Full

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: full-stack-pod
  labels:
    app: fullstack
spec:
  
  # INIT: Setup
  initContainers:
  - name: setup-config
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      echo "Generando config..."
      cat > /config/app.conf <<EOF
      server=production
      timestamp=$(date)
      EOF
    volumeMounts:
    - name: config
      mountPath: /config
  
  # MAIN: Web App
  containers:
  - name: web
    image: nginx:1.25
    ports:
    - containerPort: 80
      name: http
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
    - name: config
      mountPath: /etc/app
      readOnly: true
    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
  
  # SIDECAR 1: Logging
  - name: log-agent
    image: busybox:1.35
    command: ['sh', '-c', 'tail -f /var/log/nginx/access.log']
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
      readOnly: true
    resources:
      requests:
        cpu: "50m"
        memory: "32Mi"
  
  # SIDECAR 2: Metrics
  - name: metrics-exporter
    image: nginx/nginx-prometheus-exporter:0.11
    args:
    - -nginx.scrape-uri=http://localhost:80/stub_status
    ports:
    - containerPort: 9113
      name: metrics
    resources:
      requests:
        cpu: "50m"
        memory: "32Mi"
  
  # VOLUMES
  volumes:
  - name: logs
    emptyDir: {}
  - name: config
    emptyDir: {}
```

---

## 🔧 Troubleshooting (3 minutos)

### Problema 1: Init Container Nunca Completa

**Síntoma:**
```bash
kubectl get pod myapp
# NAME    READY   STATUS     RESTARTS   AGE
# myapp   0/1     Init:0/1   0          5m
```

**Diagnóstico:**
```bash
# Ver logs del init container
kubectl logs myapp -c <init-name>

# Ver describe
kubectl describe pod myapp | grep -A 10 "Init Containers"
```

**Causa común**: Wait-for loop sin timeout.

**Solución**: Agregar timeout explícito:
```yaml
command:
- sh
- -c
- |
  TIMEOUT=300
  ELAPSED=0
  until check_condition || [ $ELAPSED -ge $TIMEOUT ]; do
    sleep 2
    ELAPSED=$((ELAPSED + 2))
  done
  [ $ELAPSED -lt $TIMEOUT ] || exit 1
```

---

### Problema 2: Init Container CrashLoopBackOff

**Síntoma:**
```bash
kubectl get pod myapp
# NAME    READY   STATUS                  RESTARTS   AGE
# myapp   0/1     Init:CrashLoopBackOff   3          2m
```

**Diagnóstico:**
```bash
# Ver logs del init fallido
kubectl logs myapp -c <init-name> --previous

# Ver exit code
kubectl get pod myapp -o jsonpath='{.status.initContainerStatuses[0].lastState.terminated.exitCode}'
```

**Causa común**: Comando falla, imagen incorrecta, permisos.

**Solución**: Verificar comando y recursos:
```yaml
initContainers:
- name: failing-init
  image: busybox:1.35  # ✅ Verificar imagen existe
  command: ['sh', '-c', 'exit 0']  # ✅ Comando válido
  resources:  # ✅ Agregar limits
    requests:
      cpu: "100m"
      memory: "64Mi"
```

---

### Problema 3: Sidecar No Ve Logs

**Síntoma:**
```bash
kubectl logs mypod -c log-sidecar
# No logs found...
```

**Diagnóstico:**
```bash
# Verificar volumeMounts
kubectl get pod mypod -o jsonpath='{range .spec.containers[*]}{.name}{": "}{.volumeMounts[*].mountPath}{"\n"}{end}'

# Verificar archivos existen
kubectl exec mypod -c app -- ls -la /var/log/app
kubectl exec mypod -c log-sidecar -- ls -la /var/log/app
```

**Causa común**: mountPath diferente o volume no compartido.

**Solución**: Mismo volume, mismo mountPath:
```yaml
containers:
- name: app
  volumeMounts:
  - name: logs
    mountPath: /var/log/app  # ← MISMO

- name: sidecar
  volumeMounts:
  - name: logs
    mountPath: /var/log/app  # ← MISMO
    readOnly: true

volumes:
- name: logs
  emptyDir: {}
```

---

### Problema 4: OOMKilled en Sidecar

**Síntoma:**
```bash
kubectl get pod myapp
# NAME    READY   STATUS      RESTARTS   AGE
# myapp   1/2     OOMKilled   5          10m
```

**Diagnóstico:**
```bash
# Ver qué container fue killed
kubectl describe pod myapp | grep -A 5 "Last State"

# Ver memory usage actual
kubectl top pod myapp --containers
```

**Causa común**: Memory limit muy bajo.

**Solución**: Aumentar memory:
```yaml
containers:
- name: sidecar
  resources:
    requests:
      memory: "128Mi"  # ← Aumentado de 64Mi
    limits:
      memory: "512Mi"  # ← Aumentado de 128Mi
```

---

### Problema 5: Connection Refused a localhost

**Síntoma:**
```bash
kubectl exec mypod -c app -- curl localhost:6379
# curl: (7) Failed to connect to localhost port 6379
```

**Diagnóstico:**
```bash
# Ver qué puertos están abiertos
kubectl exec mypod -c app -- netstat -tuln

# Ver si sidecar está ready
kubectl get pod mypod -o jsonpath='{.status.containerStatuses[?(@.name=="proxy")].ready}'

# Ver logs del proxy
kubectl logs mypod -c proxy
```

**Causa común**: Container no está listening o puerto incorrecto.

**Solución**: Verificar port configuration:
```yaml
containers:
- name: proxy
  ports:
  - containerPort: 6379  # ← Puerto correcto
    name: redis
  
  # Agregar readiness probe
  readinessProbe:
    tcpSocket:
      port: 6379
    initialDelaySeconds: 5
```

---

## 📊 Patrones de Diseño (2 minutos)

### Comparación de Patrones

| Patrón | Propósito | Comunicación | Ejemplo |
|--------|-----------|--------------|---------|
| **Init Container** | Setup antes de app | - | Wait-for DB, migrations |
| **Sidecar** | Extender funcionalidad | Volumes, localhost | Logging, monitoring |
| **Ambassador** | Proxy a externos | Localhost proxy | Redis proxy, API GW |
| **Adapter** | Transformar output | Shared volumes | Log format converter |

---

### Cuándo Usar Cada Patrón

```
INIT CONTAINER
  ✅ Setup tasks (una vez)
  ✅ Wait-for dependencies
  ✅ Database migrations
  ✅ Config generation
  ❌ Long-running processes

SIDECAR
  ✅ Logging agents
  ✅ Monitoring exporters
  ✅ Security proxies
  ✅ Data sync
  ❌ Heavy processing

AMBASSADOR
  ✅ Simplificar networking
  ✅ Service discovery
  ✅ Retry/timeout logic
  ✅ Protocol translation
  ❌ Simple connections

ADAPTER
  ✅ Format conversion
  ✅ Data transformation
  ✅ Legacy app integration
  ✅ Standardization
  ❌ Cuando app puede cambiar
```

---

## 🎯 CKAD Cheatsheet (3 minutos)

### Topics Cubiertos (10% del Examen)

- ✅ Multi-Container Pods
- ✅ Init Containers
- ✅ Sidecar Pattern
- ✅ Shared Volumes (emptyDir)
- ✅ Container Communication (localhost)

---

### Comandos Rápidos para Examen

```bash
# 1. Crear Pod base
kubectl run mypod --image=nginx --dry-run=client -o yaml > pod.yaml

# 2. Ver logs de container específico
kubectl logs <pod> -c <container>

# 3. Exec en container específico
kubectl exec -it <pod> -c <container> -- sh

# 4. Ver init container status
kubectl get pod <pod> -o jsonpath='{.status.initContainerStatuses[*].state}'

# 5. Describe para eventos
kubectl describe pod <pod>
```

---

### Snippet 1: Init Container (2 min)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  initContainers:
  - name: wait-service
    image: busybox
    command: ['sh', '-c', 'until nslookup myservice; do sleep 2; done']
  
  containers:
  - name: app
    image: nginx
```

**Aplicar y verificar:**
```bash
kubectl apply -f pod.yaml
kubectl get pod myapp -w
kubectl logs myapp -c wait-service
```

---

### Snippet 2: Sidecar Logging (3 min)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-logs
spec:
  containers:
  - name: app
    image: busybox
    command: ['/bin/sh', '-c', 'while true; do echo "log" >> /logs/app.log; sleep 5; done']
    volumeMounts:
    - name: logs
      mountPath: /logs
  
  - name: sidecar
    image: busybox
    command: ['/bin/sh', '-c', 'tail -f /logs/app.log']
    volumeMounts:
    - name: logs
      mountPath: /logs
  
  volumes:
  - name: logs
    emptyDir: {}
```

**Verificar:**
```bash
kubectl apply -f pod.yaml
kubectl logs app-logs -c app      # Ver app logs
kubectl logs app-logs -c sidecar  # Ver sidecar procesando
```

---

### Time Management Tips

| Escenario | Tiempo Target | Estrategia |
|-----------|---------------|------------|
| Init Container básico | 2-3 min | Usar `--dry-run`, copiar snippet |
| Sidecar logging | 3-4 min | Template + modificar mountPath |
| Multi-container complejo | 5-7 min | Dividir: init → main → sidecar |
| Troubleshooting | 2-3 min | `logs` + `describe` + fix |

---

## 💡 Best Practices (2 minutos)

### ✅ DO

```yaml
# ✅ Usar resources limits siempre
containers:
- name: sidecar
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "200m"
      memory: "256Mi"

# ✅ Read-only volumes para sidecars
volumeMounts:
- name: logs
  mountPath: /var/log/app
  readOnly: true  # Sidecar solo lee

# ✅ Timeouts en init containers
command:
- sh
- -c
- |
  TIMEOUT=300
  # ... timeout logic ...

# ✅ Security context
securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
```

---

### ❌ DON'T

```yaml
# ❌ No usar init para long-running
initContainers:
- name: bad
  command: ['sleep', '3600']  # Bloquea Pod

# ❌ No omitir resources
containers:
- name: sidecar
  # Sin resources → puede consumir todo el node

# ❌ No usar bucles infinitos sin timeout
command: ['sh', '-c', 'while true; do check; sleep 1; done']

# ❌ No compartir volumes sin necesidad
# Cada container debería tener mínimo acceso necesario
```

---

## 📈 Resource Guidelines (1 minuto)

### Sizing Típico por Tipo de Sidecar

```yaml
# Logging Agent (ligero)
resources:
  requests:
    cpu: "50m"
    memory: "64Mi"
  limits:
    cpu: "100m"
    memory: "128Mi"

# Metrics Exporter (ligero)
resources:
  requests:
    cpu: "50m"
    memory: "64Mi"
  limits:
    cpu: "100m"
    memory: "128Mi"

# Proxy (medio)
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"

# Data Processor (pesado)
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1000m"
    memory: "2Gi"
```

**Total Pod = Suma de todos los containers**

---

## 🔍 Comandos de Inspección (1 minuto)

### Ver Configuración Completa

```bash
# Spec completo del Pod
kubectl get pod <pod> -o yaml

# Solo init containers
kubectl get pod <pod> -o jsonpath='{.spec.initContainers[*].name}'

# Solo main containers
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].name}'

# Resources de cada container
kubectl get pod <pod> -o jsonpath='{range .spec.containers[*]}{.name}{": CPU="}{.resources.requests.cpu}{" MEM="}{.resources.requests.memory}{"\n"}{end}'

# Volumes compartidos
kubectl get pod <pod> -o jsonpath='{.spec.volumes[*].name}'

# VolumeMount por container
kubectl get pod <pod> -o jsonpath='{range .spec.containers[*]}{.name}{": "}{.volumeMounts[*].name}{"\n"}{end}'
```

---

### Ver Status en Tiempo Real

```bash
# Watch del Pod
kubectl get pod <pod> -w

# Status detallado
kubectl get pod <pod> -o custom-columns=\
NAME:.metadata.name,\
READY:.status.containerStatuses[*].ready,\
RESTARTS:.status.containerStatuses[*].restartCount,\
STATUS:.status.phase

# Eventos recientes
kubectl get events --sort-by=.lastTimestamp | grep <pod>
```

---

## 🧪 Ejercicios Rápidos (5 minutos)

### Ejercicio 1: Init Wait-for (2 min)

**Task**: Crear Pod con init que espera a servicio "database".

```bash
# Tu turno: Escribe el YAML
# Hint: usa busybox + nslookup

# Solución:
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  initContainers:
  - name: wait-db
    image: busybox
    command: ['sh', '-c', 'until nslookup database; do sleep 2; done']
  containers:
  - name: app
    image: nginx
EOF
```

---

### Ejercicio 2: Sidecar Logging (3 min)

**Task**: Pod con app que escribe a `/var/log/app.log` y sidecar que lee.

```bash
# Tu turno: Escribe el YAML
# Hint: emptyDir volume compartido

# Solución:
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-logs
spec:
  containers:
  - name: app
    image: busybox
    command: ['sh', '-c', 'while true; do date >> /var/log/app.log; sleep 5; done']
    volumeMounts:
    - name: logs
      mountPath: /var/log
  
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'tail -f /var/log/app.log']
    volumeMounts:
    - name: logs
      mountPath: /var/log
  
  volumes:
  - name: logs
    emptyDir: {}
EOF
```

**Verificar:**
```bash
kubectl logs app-logs -c sidecar
```

---

## 📚 Referencias Rápidas

### Documentación Oficial

- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Multi-Container Pods](https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod/)
- [CKAD Curriculum](https://github.com/cncf/curriculum)

### Ejemplos en este Módulo

```bash
# Ver todos los ejemplos
ls ejemplos/

# Aplicar ejemplo
kubectl apply -f ejemplos/init-container-basic.yaml
kubectl apply -f ejemplos/sidecar-logging.yaml
```

### Labs Disponibles

```bash
# Lab 1: Init Container (30 min)
cd laboratorios/
cat lab-01-init-container.md

# Lab 2: Sidecar Logging (35 min)
cat lab-02-sidecar-logging.md

# Lab 3: Multi-Container (30 min)
cat lab-03-multi-container.md

# Lab 4: Service Mesh (45 min)
cat lab-04-service-mesh.md
```

---

## ✅ Checklist de Dominio

Marca cuando domines cada concepto:

- [ ] Puedo crear init containers
- [ ] Entiendo orden de ejecución (init → main)
- [ ] Sé configurar shared volumes (emptyDir)
- [ ] Entiendo localhost networking
- [ ] Puedo implementar sidecar logging
- [ ] Sé troubleshootear init que falla
- [ ] Puedo ver logs de container específico
- [ ] Entiendo diferencia Sidecar vs Ambassador vs Adapter
- [ ] Sé configurar resources por container
- [ ] Listo para CKAD (multi-container = 10%)

---

## 🎯 Próximos Pasos

1. ✅ **Practicar** ejercicios de este resumen
2. ✅ **Hacer** los 4 labs completos
3. ✅ **Revisar** ejemplos YAML en `/ejemplos/`
4. ✅ **Repetir** labs bajo tiempo (CKAD prep)
5. ✅ **Continuar** a **Módulo 21**: Helm Basics

---

## 🏆 Resumen del Resumen (10 segundos)

```bash
# Init Containers: Setup antes de app
initContainers:
- name: wait-db
  command: ['sh', '-c', 'until nslookup db; do sleep 2; done']

# Sidecar: Funcionalidad auxiliar
containers:
- name: app
  volumeMounts: [{name: logs, mountPath: /logs}]
- name: sidecar
  volumeMounts: [{name: logs, mountPath: /logs, readOnly: true}]

volumes:
- name: logs
  emptyDir: {}

# Comandos clave
kubectl logs <pod> -c <container>
kubectl exec -it <pod> -c <container> -- sh
kubectl describe pod <pod>
```

---

*¡Listo para CKAD! 🎉*

*Última actualización*: 2025-11-13  
*Versión*: 2.0  
*Tiempo de revisión*: 15-20 minutos