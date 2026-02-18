# Laboratorio 3: Troubleshooting de Health Checks

## Objetivos

✅ Diagnosticar problemas comunes con probes  
✅ Usar herramientas de debugging  
✅ Resolver CrashLoopBackOff  
✅ Optimizar configuración problemática

**Duración estimada**: 45 minutos

---

## Problema 1: CrashLoopBackOff

### Escenario

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: crashloop-pod
spec:
  containers:
  - name: app
    image: nginx:1.27-alpine
    
    livenessProbe:
      httpGet:
        path: /nonexistent
        port: 80
      initialDelaySeconds: 1
      periodSeconds: 2
      failureThreshold: 1
```

```bash
kubectl apply -f crashloop-pod.yaml
kubectl get pods crashloop-pod -w
```

### Diagnóstico

```bash
# 1. Ver estado
kubectl get pod crashloop-pod

# Output:
# NAME            READY   STATUS             RESTARTS   AGE
# crashloop-pod   0/1     CrashLoopBackOff   5          5m

# 2. Ver eventos
kubectl describe pod crashloop-pod | tail -30

# 3. Ver logs
kubectl logs crashloop-pod
kubectl logs crashloop-pod --previous  # Logs del contenedor anterior
```

### Solución

```yaml
# ✅ Corregido
livenessProbe:
  httpGet:
    path: /              # Ruta válida
    port: 80
  initialDelaySeconds: 10  # Más tiempo
  periodSeconds: 10
  failureThreshold: 3      # Tolerante
```

---

## Problema 2: Pod Ready pero Sin Tráfico

### Escenario

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-no-traffic
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
      tier: frontend    # ← Nota este label
  template:
    metadata:
      labels:
        app: webapp
        tier: frontend
    spec:
      containers:
      - name: app
        image: nginx:1.27-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  selector:
    app: webapp
    # tier: frontend ← FALTA ESTE SELECTOR
  ports:
  - port: 80
```

### Diagnóstico

```bash
kubectl apply -f webapp-no-traffic.yaml

# 1. Pods están Ready
kubectl get pods -l app=webapp
# NAME                    READY   STATUS
# webapp-no-traffic-xxx   1/1     Running

# 2. PERO no hay endpoints
kubectl get endpoints webapp-service
# NAME              ENDPOINTS   AGE
# webapp-service    <none>      1m

# 3. Comparar labels
kubectl get pods -l app=webapp --show-labels
kubectl get service webapp-service -o yaml | grep selector -A5
```

### Solución

Agregar el label faltante al Service:

```yaml
spec:
  selector:
    app: webapp
    tier: frontend  # ← Agregar
```

---

## Problema 3: Timeouts de Probes

### Escenario

```bash
# Aplicación que responde lento bajo carga
kubectl describe pod slow-app

# Events:
# Warning Unhealthy  1m  kubelet  Readiness probe failed: Get "http://10.244.0.5:8080/ready": context deadline exceeded
```

### Diagnóstico

```bash
# 1. Probar manualmente el endpoint
kubectl exec slow-app -- time wget -O- http://localhost:8080/ready

# Si tarda > timeoutSeconds, fallará

# 2. Ver configuración actual
kubectl get pod slow-app -o yaml | grep -A10 readinessProbe
```

### Solución

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  timeoutSeconds: 5      # Incrementar de 1s a 5s
  periodSeconds: 10      # Menos frecuente
  failureThreshold: 3
```

---

## Problema 4: Liveness Mata Pods bajo Carga

### Escenario

Durante picos de tráfico, los Pods se reinician constantemente.

### Diagnóstico

```bash
# Ver métricas de CPU/Memoria
kubectl top pods

# Ver eventos
kubectl get events --sort-by='.lastTimestamp' | grep Unhealthy

# Ver configuración de probes
kubectl get pod <pod-name> -o yaml | grep -A15 livenessProbe
```

### Análisis

```yaml
# ❌ Problema: Muy agresiva
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 5
  failureThreshold: 1    # Un fallo = muerte
  timeoutSeconds: 1      # 1s no es suficiente bajo carga
```

### Solución

```yaml
# ✅ Tolerante
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 10
  failureThreshold: 5    # Permite fallos transitorios
  timeoutSeconds: 5
  
  # Y/O incrementar recursos
  resources:
    requests:
      cpu: "200m"        # Más CPU
      memory: "256Mi"
```

---

## Comandos Útiles de Debugging

### Ver Estado de Probes

```bash
# Eventos de probes
kubectl get events --field-selector involvedObject.name=<pod-name>,reason=Unhealthy

# Configuración completa
kubectl get pod <pod-name> -o yaml

# Solo sección de probes
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].livenessProbe}'
```

### Ejecutar Probes Manualmente

```bash
# HTTP Probe
kubectl exec <pod-name> -- wget -O- http://localhost:8080/health

# TCP Probe
kubectl exec <pod-name> -- nc -zv localhost 8080

# Exec Probe
kubectl exec <pod-name> -- cat /tmp/healthy
```

### Monitoreo en Tiempo Real

```bash
# Watch Pods
kubectl get pods -w

# Watch Events
kubectl get events --watch | grep probe

# Logs con timestamps
kubectl logs <pod-name> -f --timestamps
```

---

## Ejercicio Final: Debugging Completo

### Desplegar App Problemática

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: buggy-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: buggy
  template:
    metadata:
      labels:
        app: buggy
    spec:
      containers:
      - name: app
        image: nginx:1.27-alpine
        ports:
        - containerPort: 80
        
        startupProbe:
          httpGet:
            path: /
            port: 80
          periodSeconds: 2
          failureThreshold: 5
        
        livenessProbe:
          httpGet:
            path: /healthz    # ← No existe
            port: 80
          periodSeconds: 5
          failureThreshold: 2
          timeoutSeconds: 1
        
        readinessProbe:
          httpGet:
            path: /
            port: 8080        # ← Puerto incorrecto
          periodSeconds: 5
```

### Tarea

1. Aplica el Deployment
2. Identifica todos los problemas
3. Corrige la configuración
4. Verifica que funcione correctamente

<details>
<summary>💡 Solución</summary>

**Problemas encontrados**:
1. Liveness path `/healthz` no existe → Cambiar a `/`
2. Readiness port `8080` incorrecto → Cambiar a `80`
3. Liveness muy agresiva (`failureThreshold: 2`, `timeout: 1s`)

**Configuración corregida**:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  periodSeconds: 10
  failureThreshold: 3
  timeoutSeconds: 3

readinessProbe:
  httpGet:
    path: /
    port: 80
  periodSeconds: 5
  failureThreshold: 3
```

</details>

---

## Checklist de Troubleshooting

Cuando una probe falla, verifica:

```
[ ] ¿El path/puerto es correcto?
[ ] ¿initialDelaySeconds es suficiente?
[ ] ¿timeoutSeconds es realista?
[ ] ¿failureThreshold es tolerante?
[ ] ¿La aplicación realmente responde?
[ ] ¿Hay recursos (CPU/memoria) suficientes?
[ ] ¿Los labels del Service coinciden con los Pods?
[ ] ¿La probe se puede ejecutar manualmente con éxito?
```

---

## Limpieza

```bash
kubectl delete deployment crashloop-pod webapp-no-traffic buggy-app
kubectl delete service webapp-service
```

---

## Resumen

✅ Diagnosticar CrashLoopBackOff  
✅ Resolver problemas de endpoints  
✅ Ajustar timeouts y thresholds  
✅ Evitar cascading failures  
✅ Usar herramientas de debugging efectivamente

## Has Completado el Módulo!

🎉 Felicitaciones! Ahora dominas Health Checks en Kubernetes.

## Recursos Adicionales

- **[README del Módulo](../README.md)**
- **[Ejemplos Completos](../ejemplos/README.md)**
- **[Kubernetes Docs - Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)**
