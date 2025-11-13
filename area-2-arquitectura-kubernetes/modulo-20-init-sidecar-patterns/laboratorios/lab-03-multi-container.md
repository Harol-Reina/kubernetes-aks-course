# 🧪 Lab 3: Multi-Container Communication

> **Duración**: 30 minutos | **Nivel**: 🟡 Intermedio

---

## 🎯 Objetivos

1. ✅ Comunicación localhost entre containers
2. ✅ Ambassador pattern (proxy a externos)
3. ✅ Adapter pattern (formato conversion)
4. ✅ Resource management multi-container

---

## 📋 Setup

```bash
kubectl delete pod --all --force 2>/dev/null || true
```

---

## 🔨 Parte 1: Ambassador Pattern (12 min)

### Paso 1.1: Crear Redis Backend

```bash
kubectl run redis --image=redis:7-alpine --port=6379
kubectl expose pod redis --port=6379
kubectl wait --for=condition=Ready pod/redis --timeout=60s
```

### Paso 1.2: App con Ambassador Proxy

`ambassador.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-redis
spec:
  containers:
  
  # Main App (conecta a localhost:6379)
  - name: app
    image: redis:7-alpine
    command:
    - sh
    - -c
    - |
      sleep 5
      echo "Testing Redis via Ambassador..."
      redis-cli -h localhost SET key1 "value1"
      redis-cli -h localhost GET key1
      echo "✅ Ambassador funcionando"
      tail -f /dev/null
    resources:
      requests:
        cpu: "100m"
        memory: "64Mi"
  
  # Ambassador (proxy a Redis externo)
  - name: redis-proxy
    image: haproxy:2.8-alpine
    ports:
    - containerPort: 6379
    command:
    - sh
    - -c
    - |
      cat > /tmp/haproxy.cfg <<'EOF'
      defaults
        mode tcp
        timeout connect 5s
        timeout client 30s
        timeout server 30s
      
      frontend redis-in
        bind *:6379
        default_backend redis-out
      
      backend redis-out
        server redis1 redis.default.svc.cluster.local:6379
      EOF
      
      haproxy -f /tmp/haproxy.cfg
    resources:
      requests:
        cpu: "50m"
        memory: "32Mi"
```

```bash
kubectl apply -f ambassador.yaml

# Ver ambos containers
kubectl get pod app-redis
# READY: 2/2

# Ver logs de app
kubectl logs app-redis -c app

# Probar manualmente
kubectl exec app-redis -c app -- redis-cli -h localhost PING
# PONG ✅
```

### ✅ Checkpoint 1: Ambassador

- [ ] App conecta a localhost, no sabe de Redis externo
- [ ] Ambassador proxy maneja routing
- [ ] Cambiar backend no requiere modificar app

---

## 🔄 Parte 2: Adapter Pattern (10 min)

### Paso 2.1: Logs Custom → JSON

`adapter.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: log-adapter
spec:
  containers:
  
  # Legacy app (logs custom format)
  - name: legacy
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      while true; do
        echo "[$(date +%H:%M:%S)] ERROR | Connection failed | code=500" >> /logs/app.log
        sleep 5
      done
    volumeMounts:
    - name: logs
      mountPath: /logs
  
  # Adapter (custom → JSON)
  - name: adapter
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      while [ ! -f /logs/app.log ]; do sleep 1; done
      
      tail -f /logs/app.log | while read line; do
        TIME=$(echo "$line" | cut -d']' -f1 | tr -d '[')
        LEVEL=$(echo "$line" | cut -d'|' -f1 | awk '{print $NF}')
        MSG=$(echo "$line" | cut -d'|' -f2 | xargs)
        CODE=$(echo "$line" | cut -d'=' -f2)
        
        JSON="{\"time\":\"$TIME\",\"level\":\"$LEVEL\",\"msg\":\"$MSG\",\"code\":$CODE}"
        echo "$JSON" | tee -a /logs/app.json
      done
    volumeMounts:
    - name: logs
      mountPath: /logs
  
  volumes:
  - name: logs
    emptyDir: {}
```

```bash
kubectl apply -f adapter.yaml

# Ver formato original (legacy)
kubectl logs log-adapter -c legacy

# Ver formato JSON (adapter)
kubectl logs log-adapter -c adapter

# Ver archivo JSON
kubectl exec log-adapter -c adapter -- cat /logs/app.json
```

### ✅ Checkpoint 2: Adapter

- [ ] Legacy app sin modificar
- [ ] Adapter transforma output
- [ ] JSON listo para Elasticsearch/Splunk

---

## 📊 Parte 3: Resource Management (8 min)

### Paso 3.1: Pod con Resource Limits

`resources.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-resources
spec:
  containers:
  
  - name: main
    image: nginx:1.25-alpine
    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
  
  - name: sidecar-1
    image: busybox:1.35
    command: ['sh', '-c', 'sleep infinity']
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
  
  - name: sidecar-2
    image: busybox:1.35
    command: ['sh', '-c', 'sleep infinity']
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
```

```bash
kubectl apply -f resources.yaml

# Ver resources totales del Pod
# CPU requests:  250m + 50m + 50m = 350m
# Memory requests: 256Mi + 64Mi + 64Mi = 384Mi

# Ver usage real
kubectl top pod multi-resources --containers

# Ver resources por container
kubectl describe pod multi-resources | grep -A 5 "Limits:"
```

### ✅ Checkpoint 3: Resources

- [ ] Cada container tiene sus propios limits
- [ ] Total del Pod = suma de todos
- [ ] Importante para scheduling

---

## 🎯 Desafíos

### Desafío 1: Service Mesh Básico

Crea ambassador + adapter + monitoring:

```yaml
containers:
- name: app
- name: envoy-proxy  # Ambassador
- name: log-adapter  # Adapter
- name: metrics      # Monitoring
```

### Desafío 2: Circuit Breaker

Implementa retry logic en ambassador:

```haproxy
backend redis-out
  option redispatch
  retries 3
  timeout server 2s
  server redis1 redis:6379 check
```

---

## 📝 Limpieza

```bash
kubectl delete pod app-redis log-adapter multi-resources redis --force
kubectl delete service redis
```

---

## ✅ Auto-Evaluación

- [ ] Implementé Ambassador pattern
- [ ] Implementé Adapter pattern
- [ ] Configuré resources por container
- [ ] Entendí diferencia Ambassador vs Adapter
- [ ] Comuniqué containers via localhost

---

## 🎓 Resumen

```
AMBASSADOR
├─ Proxy a servicios externos
├─ App conecta a localhost
└─ Simplifica networking

ADAPTER
├─ Transforma DATA/output
├─ Custom → Standard format
└─ No modificar legacy app

RESOURCES
├─ Limits por container
├─ Total = suma
└─ Importante para QoS
```

**Lab 3 completado!** 🎉

*Próximo*: Lab 4 - Service Mesh Sidecar