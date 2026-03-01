# Capítulo 37: Troubleshooting Avanzado

Todo debería funcionar... pero cuando falla, necesitamos un enfoque sistemático. Este capítulo proporciona un framework de diagnóstico y los comandos esenciales para resolver los problemas más comunes en Kubernetes.

---

## Estrategias de Diagnóstico

### Flujo de Troubleshooting

```
1. Identificar el problema
   ↓
2. Recopilar información
   ↓
3. Analizar logs y métricas
   ↓
4. Probar hipótesis
   ↓
5. Implementar solución
   ↓
6. Verificar resolución
```

## Comandos de Diagnóstico

### Información del Clúster

```bash
# Estado general del clúster
kubectl cluster-info
kubectl get nodes
kubectl top nodes

# Eventos del clúster
kubectl get events --sort-by=.metadata.creationTimestamp

# Recursos del sistema
kubectl get pods -n kube-system
kubectl describe node <node-name>
```

### Diagnóstico de Pods

```bash
# Estado de pods
kubectl get pods -o wide
kubectl describe pod <pod-name>

# Logs detallados
kubectl logs <pod-name> -c <container-name> --previous
kubectl logs <pod-name> --since=1h --tail=100

# Ejecutar comandos en pod
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec <pod-name> -- ps aux
kubectl exec <pod-name> -- netstat -tulpn
```

### Diagnóstico de Red

```bash
# Conectividad entre pods
kubectl run test-pod --image=curlimages/curl -i --rm --restart=Never -- curl <service-url>

# DNS resolution
kubectl run test-dns --image=busybox -i --rm --restart=Never -- nslookup kubernetes.default

# Network policies
kubectl describe networkpolicy <policy-name>
```

## Escenarios Comunes de Troubleshooting

### Pod en Estado Pending

```bash
# Verificar recursos del nodo
kubectl describe node

# Verificar PodDisruptionBudgets
kubectl get pdb -A

# Verificar taints y tolerations
kubectl describe node | grep Taints
```

### Pod en CrashLoopBackOff

```bash
# Ver logs del contenedor anterior
kubectl logs <pod-name> --previous

# Verificar health checks
kubectl describe pod <pod-name> | grep -A 10 "Liveness\|Readiness"

# Verificar recursos
kubectl top pod <pod-name>
```

### Problemas de Conectividad

```bash
# Verificar servicios
kubectl get svc
kubectl get endpoints

# Probar conectividad de red
kubectl exec -it <pod-name> -- telnet <service-ip> <port>

# Verificar DNS
kubectl exec -it <pod-name> -- cat /etc/resolv.conf
```

## Laboratorio 4.5: Troubleshooting Práctico

### Paso 1: Crear Aplicación con Problemas

```bash
# Aplicación con problemas intencionados
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: problematic-app
  namespace: desarrollo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: problematic-app
  template:
    metadata:
      labels:
        app: problematic-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        resources:
          requests:
            cpu: 2000m  # Recurso excesivo
            memory: 4Gi
          limits:
            cpu: 2000m
            memory: 4Gi
        readinessProbe:
          httpGet:
            path: /nonexistent  # Path que no existe
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
EOF
```

### Paso 2: Diagnosticar Problemas

```bash
# Ver estado de pods
kubectl get pods -n desarrollo -l app=problematic-app

# Describir pod problemático
POD_NAME=$(kubectl get pods -n desarrollo -l app=problematic-app -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME -n desarrollo

# Ver eventos
kubectl get events -n desarrollo --sort-by=.metadata.creationTimestamp | tail -10

# Verificar recursos disponibles
kubectl top nodes
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Paso 3: Corregir Problemas

```bash
# Corregir configuración
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: problematic-app
  namespace: desarrollo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: problematic-app
  template:
    metadata:
      labels:
        app: problematic-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        resources:
          requests:
            cpu: 100m  # Recurso razonable
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
        readinessProbe:
          httpGet:
            path: /  # Path correcto
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
EOF

# Verificar corrección
kubectl get pods -n desarrollo -l app=problematic-app
kubectl rollout status deployment/problematic-app -n desarrollo
```

---

## Resumen del Capítulo

El troubleshooting sistemático sigue un flujo: identificar, recopilar información, analizar, probar hipótesis e implementar solución. Los comandos clave son `kubectl describe`, `kubectl logs --previous`, `kubectl get events` y `kubectl exec`. Los tres escenarios más comunes — Pending (recursos insuficientes), CrashLoopBackOff (error en la app o health checks) y problemas de conectividad (DNS o Network Policies) — cubren la mayoría de incidentes en producción.
