# Laboratorio 03: Ingress en Producción

**Duración estimada**: 60-70 minutos  
**Nivel**: Avanzado  
**Prerequisitos**: Labs 01 y 02 completados

## Objetivos

✅ Arquitectura multi-app con ingress  
✅ Implementar canary deployments  
✅ Configurar rate limiting  
✅ Whitelist de IPs  
✅ Sticky sessions  
✅ Alta disponibilidad del ingress controller  
✅ Best practices de producción

---

## Parte 1: Canary Deployments (20 min)

### Paso 1.1: Desplegar v1 y v2

```bash
# Versión 1 (estable)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: v1
  template:
    metadata:
      labels:
        app: myapp
        version: v1
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        command: ["/bin/sh", "-c"]
        args:
          - echo '<h1>VERSION 1</h1>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'
---
apiVersion: v1
kind: Service
metadata:
  name: app-v1
spec:
  selector:
    app: myapp
    version: v1
  ports:
    - port: 80
---
# Versión 2 (canary)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: v2
  template:
    metadata:
      labels:
        app: myapp
        version: v2
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        command: ["/bin/sh", "-c"]
        args:
          - echo '<h1>VERSION 2 - NEW</h1>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'
---
apiVersion: v1
kind: Service
metadata:
  name: app-v2
spec:
  selector:
    app: myapp
    version: v2
  ports:
    - port: 80
EOF
```

### Paso 1.2: Configurar canary (20% tráfico a v2)

```bash
kubectl apply -f - <<EOF
# Ingress principal (v1)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: production
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v1
            port:
              number: 80
---
# Ingress canary (v2)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "20"
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v2
            port:
              number: 80
EOF
```

### Paso 1.3: Verificar distribución

```bash
# Generar 100 requests
for i in {1..100}; do 
  curl -s http://app.example.com | grep -o "VERSION [12]"
done | sort | uniq -c

# Debería mostrar ~20 v2 y ~80 v1

# Aumentar canary a 50%
kubectl patch ingress canary -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/canary-weight":"50"}}}'

# Probar nuevamente
for i in {1..100}; do 
  curl -s http://app.example.com | grep -o "VERSION [12]"
done | sort | uniq -c
```

---

## Parte 2: Rate Limiting y Seguridad (15 min)

### Paso 2.1: Rate limiting

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rate-limited-api
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "5"
    nginx.ingress.kubernetes.io/limit-connections: "10"
spec:
  ingressClassName: nginx
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v1
            port:
              number: 80
EOF

# Probar rate limit
for i in {1..20}; do 
  curl -s -o /dev/null -w "%{http_code}\n" http://api.example.com
done
# Verás varios 503 Service Temporarily Unavailable
```

### Paso 2.2: IP Whitelist

```bash
# Obtener tu IP
MY_IP=$(curl -s https://ifconfig.me)

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: admin-whitelist
  annotations:
    nginx.ingress.kubernetes.io/whitelist-source-range: "$MY_IP/32,10.0.0.0/8"
spec:
  ingressClassName: nginx
  rules:
  - host: admin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v1
            port:
              number: 80
EOF

# Probar (debería funcionar desde tu IP)
curl http://admin.example.com
```

---

## Parte 3: Alta Disponibilidad (15 min)

### Paso 3.1: Escalar ingress controller

```bash
# Escalar a 3 réplicas
helm upgrade nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --reuse-values \
  --set controller.replicaCount=3

# Verificar
kubectl get pods -n ingress-nginx
```

### Paso 3.2: PodDisruptionBudget

```bash
kubectl apply -f - <<EOF
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ingress-nginx-pdb
  namespace: ingress-nginx
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
EOF
```

---

## Parte 4: Monitoreo (10 min)

### Paso 4.1: Ver métricas

```bash
# Port-forward al puerto de métricas
kubectl port-forward -n ingress-nginx svc/nginx-ingress-controller-metrics 10254:10254 &

# Ver métricas de Prometheus
curl http://localhost:10254/metrics | grep nginx_ingress_controller_requests
```

### Paso 4.2: Logs

```bash
# Logs en tiempo real
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller -f

# Filtrar por Ingress específico
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller | grep "canary"
```

---

## Best Practices Checklist

### Seguridad
- [ ] TLS habilitado con certificados válidos
- [ ] Force SSL redirect configurado
- [ ] HSTS enabled
- [ ] Rate limiting en APIs públicas
- [ ] IP whitelist para endpoints sensibles
- [ ] Basic auth o OAuth para admin

### Alta Disponibilidad
- [ ] Mínimo 3 réplicas del ingress controller
- [ ] PodDisruptionBudget configurado
- [ ] Resource requests/limits definidos
- [ ] Health checks (readiness/liveness)
- [ ] Anti-affinity rules

### Rendimiento
- [ ] Gzip compression habilitada
- [ ] Proxy buffers optimizados
- [ ] Timeouts apropiados
- [ ] Connection pooling

### Monitoreo
- [ ] Métricas de Prometheus habilitadas
- [ ] Logs centralizados
- [ ] Alertas configuradas (cert expiration, 5xx)
- [ ] Dashboards de Grafana

---

## Limpieza

```bash
kubectl delete ingress production canary rate-limited-api admin-whitelist
kubectl delete deployment app-v1 app-v2
kubectl delete service app-v1 app-v2
kubectl delete pdb -n ingress-nginx ingress-nginx-pdb
```

---

## Checklist Final

- [ ] Canary deployments implementado y probado
- [ ] Rate limiting funciona
- [ ] IP whitelist configurado
- [ ] Ingress controller escalado a 3 réplicas
- [ ] PDB creado
- [ ] Métricas verificadas
- [ ] Best practices implementadas

---

**¡Felicitaciones! Has completado el módulo de Ingress.**

⬅️ [Lab 02: TLS Avanzado](lab-02-ingress-tls-avanzado.md)  
🏠 [Volver al README del módulo](../README.md)
