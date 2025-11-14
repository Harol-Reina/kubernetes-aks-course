# Laboratorio 2: Startup Probes y Casos Avanzados

## Objetivos

✅ Configurar Startup Probes para aplicaciones de arranque lento  
✅ Combinar Startup, Liveness y Readiness correctamente  
✅ Implementar probes en aplicaciones reales  
✅ Optimizar configuración para producción

**Duración estimada**: 60 minutos

---

## Parte 1: Startup Probe para Aplicaciones Lentas

### Escenario

Tienes una aplicación que tarda 2-3 minutos en arrancar. Sin Startup Probe, la Liveness Probe la reiniciaría prematuramente.

### Paso 1.1: Sin Startup Probe (Problemático)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: slow-app-without-startup
spec:
  containers:
  - name: app
    image: alpine:3.19
    command:
    - sh
    - -c
    - 'echo "Iniciando..."; sleep 120; echo "Listo!"; sleep 3600'
    
    livenessProbe:
      exec:
        command: ['sh', '-c', 'pgrep -f sleep']
      initialDelaySeconds: 30  # No es suficiente
      periodSeconds: 10
      failureThreshold: 3      # 3 × 10 = 30s de tolerancia
```

```bash
kubectl apply -f slow-app-without-startup.yaml
kubectl get pods slow-app-without-startup -w
```

**Problema**: El Pod se reinicia porque tarda más de 60s (initialDelay 30s + 30s de tolerancia)

### Paso 1.2: Con Startup Probe (Solución)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: slow-app-with-startup
spec:
  containers:
  - name: app
    image: alpine:3.19
    command:
    - sh
    - -c
    - |
      echo "Iniciando aplicación..."
      sleep 120
      touch /tmp/started
      echo "Aplicación iniciada!"
      sleep 3600
    
    # Startup: Permite hasta 5 minutos para arrancar
    startupProbe:
      exec:
        command: ['test', '-f', '/tmp/started']
      periodSeconds: 10
      failureThreshold: 30    # 30 × 10s = 300s = 5 min
    
    # Liveness: Se activa DESPUÉS de Startup
    livenessProbe:
      exec:
        command: ['pgrep', '-f', 'sleep']
      periodSeconds: 10
      failureThreshold: 3
```

```bash
kubectl apply -f slow-app-with-startup.yaml
kubectl get pods slow-app-with-startup -w
kubectl describe pod slow-app-with-startup
```

**✅ Resultado**: El Pod arranca correctamente sin reinicios.

---

## Parte 2: PostgreSQL con Probes Completas

### Paso 2.1: Desplegar PostgreSQL

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgres-production
spec:
  containers:
  - name: postgres
    image: postgres:16-alpine
    env:
    - name: POSTGRES_PASSWORD
      value: "securepassword"
    - name: POSTGRES_DB
      value: "appdb"
    ports:
    - containerPort: 5432
    
    # 1. Startup: Espera inicialización de DB
    startupProbe:
      exec:
        command:
        - sh
        - -c
        - pg_isready -U postgres
      initialDelaySeconds: 10
      periodSeconds: 5
      failureThreshold: 60    # 5 minutos max
    
    # 2. Liveness: Verifica proceso vivo
    livenessProbe:
      exec:
        command: ['pg_isready', '-U', 'postgres']
      periodSeconds: 10
      failureThreshold: 3
    
    # 3. Readiness: Verifica queries
    readinessProbe:
      exec:
        command:
        - sh
        - -c
        - pg_isready -U postgres && psql -U postgres -d appdb -c 'SELECT 1'
      periodSeconds: 5
      failureThreshold: 3
```

```bash
kubectl apply -f postgres-production.yaml
kubectl logs postgres-production -f
```

### Paso 2.2: Verificar Secuencia de Probes

```bash
# Ver orden de ejecución de probes
kubectl describe pod postgres-production | grep -A5 "Startup\|Liveness\|Readiness"
```

Observa que:
1. **Startup** se ejecuta primero
2. **Liveness** y **Readiness** se activan después de Startup exitosa

---

## Parte 3: Aplicación Node.js con Endpoints Dedicados

### Paso 3.1: Deployment Completo

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nodejs
  template:
    metadata:
      labels:
        app: nodejs
    spec:
      containers:
      - name: api
        image: node:20-alpine
        workingDir: /app
        command:
        - sh
        - -c
        - |
          # Crear servidor Express
          cat > server.js <<'EOF'
          const express = require('express');
          const app = express();
          
          let started = false;
          let ready = false;
          
          // Simula carga inicial
          setTimeout(() => { started = true; ready = true; }, 15000);
          
          app.get('/startup', (req, res) => {
            res.status(started ? 200 : 503).send(started ? 'Started' : 'Starting');
          });
          
          app.get('/health', (req, res) => {
            res.status(200).send('OK');
          });
          
          app.get('/ready', (req, res) => {
            res.status(ready ? 200 : 503).send(ready ? 'Ready' : 'Not Ready');
          });
          
          app.listen(3000, () => console.log('Server running'));
          EOF
          
          npm init -y && npm install express && node server.js
        
        ports:
        - name: http
          containerPort: 3000
        
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        
        startupProbe:
          httpGet:
            path: /startup
            port: http
          periodSeconds: 5
          failureThreshold: 12    # 1 minuto
        
        livenessProbe:
          httpGet:
            path: /health
            port: http
          periodSeconds: 10
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          periodSeconds: 5
          failureThreshold: 2
```

```bash
kubectl apply -f nodejs-production.yaml
kubectl get pods -l app=nodejs -w
```

### Paso 3.2: Probar Endpoints

```bash
# Port forward
kubectl port-forward deployment/nodejs-production 3000:3000

# En otra terminal
curl http://localhost:3000/startup
curl http://localhost:3000/health
curl http://localhost:3000/ready
```

---

## Parte 4: Optimización de Probes para Producción

### Escenario: Alta Disponibilidad

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: critical
  template:
    metadata:
      labels:
        app: critical
    spec:
      containers:
      - name: app
        image: nginx:1.27-alpine
        ports:
        - name: http
          containerPort: 80
        
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "1000m"
            memory: "512Mi"
        
        # Startup: Rápido (app ligera)
        startupProbe:
          httpGet:
            path: /
            port: http
          periodSeconds: 2
          failureThreshold: 10    # 20s max
        
        # Liveness: MUY TOLERANTE (evita cascading failures)
        livenessProbe:
          httpGet:
            path: /
            port: http
          periodSeconds: 30       # Menos frecuente
          failureThreshold: 5     # 150s de tolerancia
          timeoutSeconds: 5
        
        # Readiness: Sensible (control de tráfico rápido)
        readinessProbe:
          httpGet:
            path: /
            port: http
          periodSeconds: 5        # Frecuente
          successThreshold: 1     # Rápido para marcar Ready
          failureThreshold: 2     # Rápido para quitar
          timeoutSeconds: 3
```

### Análisis de Configuración

| Probe | periodSeconds | failureThreshold | Tiempo Total | Estrategia |
|-------|---------------|------------------|--------------|------------|
| Startup | 2s | 10 | 20s | Rápido (app ligera) |
| Liveness | 30s | 5 | 150s | Muy tolerante |
| Readiness | 5s | 2 | 10s | Sensible |

---

## Parte 5: Casos Reales de Troubleshooting

### Caso 1: Cascading Failures bajo Carga

**Síntoma**: Pods se reinician en cadena bajo alta carga

**Causa**: Liveness Probe muy agresiva

```yaml
# ❌ MAL
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 2
  failureThreshold: 1    # Un fallo = reinicio
  timeoutSeconds: 1      # 1s de timeout
```

**Solución**:

```yaml
# ✅ BIEN
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 10
  failureThreshold: 5    # Tolerante
  timeoutSeconds: 5      # Timeout generoso
```

---

## Limpieza

```bash
kubectl delete pod slow-app-without-startup slow-app-with-startup postgres-production
kubectl delete deployment nodejs-production critical-app
```

---

## Resumen

✅ Startup Probes evitan reinicios prematuros  
✅ Combina las 3 probes para producción  
✅ Liveness tolerante evita cascading failures  
✅ Readiness sensible controla tráfico efectivamente

## Siguiente Paso

**[Laboratorio 3 - Troubleshooting de Probes](lab-03-troubleshooting.md)**
