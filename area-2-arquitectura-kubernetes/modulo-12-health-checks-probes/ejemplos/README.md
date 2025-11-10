# Ejemplos de Health Checks y Probes

Esta carpeta contiene ejemplos organizados por tipo de probe y casos de uso.

## Estructura

```
ejemplos/
├── 01-liveness/              # Liveness Probes
│   ├── liveness-http-deadlock.yaml
│   ├── liveness-exec-file.yaml
│   └── liveness-tcp-socket.yaml
│
├── 02-readiness/             # Readiness Probes
│   ├── readiness-database-check.yaml
│   ├── readiness-tcp-socket.yaml
│   └── readiness-exec-script.yaml
│
├── 03-startup/               # Startup Probes
│   ├── startup-slow-app.yaml
│   └── startup-database.yaml
│
├── 04-combinados/            # Probes Combinadas
│   ├── probes-completas.yaml
│   ├── nodejs-express-probes.yaml
│   └── python-flask-probes.yaml
│
├── 05-http/                  # HTTP Probes Avanzadas
│   ├── http-get-custom-headers.yaml
│   ├── named-ports.yaml
│   └── grpc-etcd-probe.yaml
│
├── 06-tcp/                   # TCP Socket Probes
│   ├── tcp-socket-redis.yaml
│   └── tcp-socket-mysql.yaml
│
└── 07-exec/                  # Exec Command Probes
    ├── exec-custom-script.yaml
    └── exec-postgres-complete.yaml
```

## Cómo Usar los Ejemplos

### 1. Liveness Probes (01-liveness/)

**Propósito**: Detectar y reiniciar contenedores fallidos

```bash
# HTTP Liveness
kubectl apply -f 01-liveness/liveness-http-deadlock.yaml
kubectl get pods liveness-http -w
kubectl describe pod liveness-http

# Exec Liveness
kubectl apply -f 01-liveness/liveness-exec-file.yaml
kubectl describe pod liveness-exec | grep -A10 "Liveness"

# TCP Liveness
kubectl apply -f 01-liveness/liveness-tcp-socket.yaml
```

### 2. Readiness Probes (02-readiness/)

**Propósito**: Controlar cuándo un Pod recibe tráfico

```bash
# HTTP Readiness con Service
kubectl apply -f 02-readiness/readiness-database-check.yaml
kubectl expose pod readiness-http --port=80
kubectl get endpoints readiness-http

# TCP Readiness
kubectl apply -f 02-readiness/readiness-tcp-socket.yaml

# Exec Readiness
kubectl apply -f 02-readiness/readiness-exec-script.yaml
kubectl get pods readiness-exec -w
```

### 3. Startup Probes (03-startup/)

**Propósito**: Permitir arranque lento sin reiniciar prematuramente

```bash
# App con arranque lento
kubectl apply -f 03-startup/startup-slow-app.yaml
kubectl describe pod startup-slow-app

# PostgreSQL con startup
kubectl apply -f 03-startup/startup-database.yaml
kubectl logs postgres-startup -f
```

### 4. Probes Combinadas (04-combinados/)

**Propósito**: Patrón completo para producción

```bash
# Deployment con las 3 probes
kubectl apply -f 04-combinados/probes-completas.yaml
kubectl get pods -l app=webapp -w
kubectl get endpoints webapp-service

# Node.js con Express
kubectl apply -f 04-combinados/nodejs-express-probes.yaml
kubectl port-forward deployment/nodejs-api 3000:3000
curl http://localhost:3000/startup
curl http://localhost:3000/health
curl http://localhost:3000/ready

# Python con Flask
kubectl apply -f 04-combinados/python-flask-probes.yaml
kubectl logs -f deployment/python-flask-api
```

### 5. HTTP Probes Avanzadas (05-http/)

```bash
# Custom Headers
kubectl apply -f 05-http/http-get-custom-headers.yaml

# Named Ports
kubectl apply -f 05-http/named-ports.yaml
kubectl get pod nginx-named-ports -o yaml | grep -A10 ports

# gRPC (requiere K8s 1.27+)
kubectl apply -f 05-http/grpc-etcd-probe.yaml
kubectl logs etcd-grpc
```

### 6. TCP Socket Probes (06-tcp/)

```bash
# Redis
kubectl apply -f 06-tcp/tcp-socket-redis.yaml
kubectl exec redis-tcp -- redis-cli ping
kubectl exec redis-tcp -- redis-cli set key value
kubectl exec redis-tcp -- redis-cli get key

# MySQL
kubectl apply -f 06-tcp/tcp-socket-mysql.yaml
kubectl logs mysql-tcp -f
kubectl exec mysql-tcp -- mysql -uroot -prootpassword -e "SHOW DATABASES;"
```

### 7. Exec Command Probes (07-exec/)

```bash
# Script personalizado
kubectl apply -f 07-exec/exec-custom-script.yaml
kubectl exec exec-custom-script -- /app/health_check.sh

# PostgreSQL completo
kubectl apply -f 07-exec/exec-postgres-complete.yaml
kubectl exec postgres-exec -- psql -U postgres -d production_db -c '\l'
```

## Comandos Útiles

### Monitoreo de Probes

```bash
# Ver estado en tiempo real
kubectl get pods -w

# Ver eventos de probes
kubectl get events --watch | grep probe

# Ver configuración de probes
kubectl get pod <pod-name> -o yaml | grep -A15 Probe

# Ver solo eventos de probes fallidas
kubectl get events --field-selector reason=Unhealthy
```

### Debugging

```bash
# Logs del Pod
kubectl logs <pod-name> -f

# Describe para ver eventos
kubectl describe pod <pod-name>

# Ejecutar probe manualmente (HTTP)
kubectl exec <pod-name> -- wget -O- http://localhost:8080/health

# Ejecutar probe manualmente (TCP)
kubectl exec <pod-name> -- nc -zv localhost 8080

# Ejecutar probe manualmente (exec)
kubectl exec <pod-name> -- cat /tmp/healthy
```

### Limpieza

```bash
# Eliminar un ejemplo específico
kubectl delete -f 01-liveness/liveness-http-deadlock.yaml

# Eliminar todos los ejemplos de liveness
kubectl delete -f 01-liveness/

# Eliminar todos los Pods de ejemplos
kubectl delete pods -l test=liveness
kubectl delete pods -l app=demo
```

## Comparación Rápida

| Probe | Falla → Acción | Cuándo Usar |
|-------|----------------|-------------|
| **Startup** | Reinicia Pod | Apps con arranque lento (> 30s) |
| **Liveness** | Reinicia contenedor | Detectar deadlocks, bugs críticos |
| **Readiness** | Quita del Service | Controlar tráfico, deps externas |

## Mejores Prácticas

### ✅ DO

```yaml
# Startup para apps lentas
startupProbe:
  periodSeconds: 10
  failureThreshold: 30  # 5 min total

# Liveness tolerante
livenessProbe:
  periodSeconds: 10
  failureThreshold: 3   # Permite transitorios

# Readiness sensible
readinessProbe:
  periodSeconds: 5
  failureThreshold: 2   # Rápido para quitar tráfico
```

### ❌ DON'T

```yaml
# ❌ Liveness muy agresiva
livenessProbe:
  periodSeconds: 2
  failureThreshold: 1   # PELIGRO: cascading failures

# ❌ Readiness muy lenta
readinessProbe:
  periodSeconds: 60
  failureThreshold: 10  # Tarda 10 min en quitar del Service
```

## Siguiente Paso

Después de probar los ejemplos, continúa con:

1. **[Laboratorio 1](../laboratorios/lab-01-probes-basico.md)**: Configuración básica
2. **[Laboratorio 2](../laboratorios/lab-02-startup-avanzado.md)**: Casos avanzados
3. **[Laboratorio 3](../laboratorios/lab-03-troubleshooting.md)**: Debugging

## Recursos

- **[README principal](../README.md)**: Teoría completa de probes
- **[Kubernetes Docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)**: Documentación oficial
