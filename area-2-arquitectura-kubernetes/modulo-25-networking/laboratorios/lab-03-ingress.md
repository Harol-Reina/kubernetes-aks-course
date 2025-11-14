# Laboratorio 03: Ingress Controllers y Routing

## 📋 Metadata

- **Módulo**: 25 - Networking
- **Laboratorio**: 03
- **Título**: Ingress Controllers, Routing y TLS
- **Duración estimada**: 60-75 minutos
- **Dificultad**: ⭐⭐⭐ (Avanzado)
- **Objetivos CKA**: Ingress (5-10%)

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio serás capaz de:

1. Instalar y configurar ingress-nginx controller
2. Crear recursos Ingress con path-based routing
3. Configurar host-based routing (virtual hosts)
4. Implementar TLS/HTTPS termination
5. Usar annotations avanzadas (rewrites, CORS, rate limiting)
6. Troubleshoot problemas comunes de Ingress
7. Configurar ingress para aplicaciones multi-tier

## 📚 Prerequisitos

- Cluster de Kubernetes funcional
- kubectl configurado
- Laboratorios 01 y 02 completados
- Conocimientos de HTTP/HTTPS y DNS

## 🔧 Preparación del Entorno

### Verificar cluster

```bash
kubectl cluster-info
kubectl get nodes
```

### Crear namespace

```bash
kubectl create namespace lab-ingress
kubectl config set-context --current --namespace=lab-ingress
```

---

## 📝 Ejercicio 1: Instalar Ingress-nginx Controller

### 1.1 Instalación del Controller

**Para minikube:**

```bash
minikube addons enable ingress

# Verificar
kubectl get pods -n ingress-nginx
```

**Para clusters reales (bare-metal/cloud):**

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Esperar a que esté ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 1.2 Verificar Instalación

```bash
# Ver pods del controller
kubectl get pods -n ingress-nginx

# Ver service del controller
kubectl get svc -n ingress-nginx

# Ver logs del controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50
```

### 1.3 Obtener IP/Hostname del Ingress Controller

```bash
# Para LoadBalancer
kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Para minikube
minikube ip

# Guardar en variable
export INGRESS_IP=$(minikube ip)  # o la IP de tu LoadBalancer
echo $INGRESS_IP
```

---

## 📝 Ejercicio 2: Ingress Básico (Path-based Routing)

### 2.1 Desplegar Aplicaciones

```bash
cat <<EOF | kubectl apply -f -
# App1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  namespace: lab-ingress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh"]
        args:
          - -c
          - |
            echo "<h1>App1 - Pod: \$(hostname)</h1>" > /usr/share/nginx/html/index.html
            nginx -g 'daemon off;'
---
apiVersion: v1
kind: Service
metadata:
  name: app1-service
  namespace: lab-ingress
spec:
  selector:
    app: app1
  ports:
  - port: 80
    targetPort: 80
---
# App2
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
  namespace: lab-ingress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh"]
        args:
          - -c
          - |
            echo "<h1>App2 - Pod: \$(hostname)</h1>" > /usr/share/nginx/html/index.html
            nginx -g 'daemon off;'
---
apiVersion: v1
kind: Service
metadata:
  name: app2-service
  namespace: lab-ingress
spec:
  selector:
    app: app2
  ports:
  - port: 80
    targetPort: 80
EOF
```

**Verificar:**

```bash
kubectl get deployments,svc -n lab-ingress
kubectl get pods -l app=app1
kubectl get pods -l app=app2
```

### 2.2 Crear Ingress con Path-based Routing

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
  namespace: lab-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
EOF
```

### 2.3 Verificar Ingress

```bash
# Ver ingress
kubectl get ingress -n lab-ingress

# Describir
kubectl describe ingress path-based-ingress -n lab-ingress

# Ver ADDRESS asignada (puede tardar unos segundos)
kubectl get ingress path-based-ingress -n lab-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### 2.4 Test Path-based Routing

```bash
# Agregar entrada en /etc/hosts (en tu máquina local)
# sudo sh -c "echo '$INGRESS_IP myapp.example.com' >> /etc/hosts"

# Test usando curl con header Host
curl -H "Host: myapp.example.com" http://$INGRESS_IP/app1
curl -H "Host: myapp.example.com" http://$INGRESS_IP/app2

# Multiple requests para ver balanceo
for i in {1..5}; do
  echo "Request $i:"
  curl -s -H "Host: myapp.example.com" http://$INGRESS_IP/app1 | grep -o "Pod: .*"
done
```

**❓ Pregunta:** ¿Cómo enruta el Ingress las requests a /app1 vs /app2?

---

## 📝 Ejercicio 3: Host-based Routing (Virtual Hosts)

### 3.1 Crear Ingress con Múltiples Hosts

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-based-ingress
  namespace: lab-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
EOF
```

### 3.2 Test Host-based Routing

```bash
# Test App1
curl -H "Host: app1.example.com" http://$INGRESS_IP/

# Test App2
curl -H "Host: app2.example.com" http://$INGRESS_IP/

# Test host no configurado (debería dar 404)
curl -H "Host: notfound.example.com" http://$INGRESS_IP/
```

**❓ Pregunta:** ¿Qué pasa si no se envía el header Host?

---

## 📝 Ejercicio 4: TLS/HTTPS Termination

### 4.1 Crear Certificado TLS (Self-signed para testing)

```bash
# Generar certificado autofirmado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=secure.example.com/O=MyOrg"

# Crear secret TLS
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key \
  -n lab-ingress

# Verificar secret
kubectl get secret tls-secret -n lab-ingress
kubectl describe secret tls-secret -n lab-ingress
```

### 4.2 Crear Ingress con TLS

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
  namespace: lab-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - secure.example.com
    secretName: tls-secret
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
EOF
```

### 4.3 Test HTTPS

```bash
# Test HTTPS (con certificado self-signed, usar -k)
curl -k -H "Host: secure.example.com" https://$INGRESS_IP/

# Test redirección HTTP -> HTTPS
curl -v -H "Host: secure.example.com" http://$INGRESS_IP/ 2>&1 | grep -i location

# Ver detalles del certificado
openssl s_client -connect $INGRESS_IP:443 -servername secure.example.com < /dev/null 2>/dev/null | openssl x509 -noout -text | grep -A 2 "Subject:"
```

**❓ Pregunta:** ¿Qué hace la annotation `ssl-redirect`?

---

## 📝 Ejercicio 5: URL Rewriting

### 5.1 Crear Ingress con Rewrite

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rewrite-ingress
  namespace: lab-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: rewrite.example.com
    http:
      paths:
      # /api/v1/users -> /users
      - path: /api/v1(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
      # /api/v2/users -> /users
      - path: /api/v2(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
EOF
```

### 5.2 Test Rewriting

```bash
# Request a /api/v1/... se reescribe a /
curl -H "Host: rewrite.example.com" http://$INGRESS_IP/api/v1/

# Request a /api/v2/... se reescribe a / (va a app2)
curl -H "Host: rewrite.example.com" http://$INGRESS_IP/api/v2/
```

**❓ Pregunta:** ¿Para qué sirve la captura `(.*)` en el path?

---

## 📝 Ejercicio 6: CORS Configuration

### 6.1 Crear Ingress con CORS

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cors-ingress
  namespace: lab-ingress
  annotations:
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://frontend.example.com"
    nginx.ingress.kubernetes.io/cors-allow-credentials: "true"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Authorization,Content-Type"
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
            name: app1-service
            port:
              number: 80
EOF
```

### 6.2 Test CORS Headers

```bash
# Hacer request con Origin header
curl -v -H "Host: api.example.com" \
     -H "Origin: https://frontend.example.com" \
     http://$INGRESS_IP/ 2>&1 | grep -i "access-control"

# Debería mostrar:
# Access-Control-Allow-Origin: https://frontend.example.com
# Access-Control-Allow-Credentials: true
```

---

## 📝 Ejercicio 7: Rate Limiting

### 7.1 Crear Ingress con Rate Limiting

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rate-limit-ingress
  namespace: lab-ingress
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "2"  # 2 requests por segundo
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "2"  # Burst = 4
spec:
  ingressClassName: nginx
  rules:
  - host: ratelimit.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
EOF
```

### 7.2 Test Rate Limiting

```bash
# Hacer múltiples requests rápidas (deberían ser limitadas)
for i in {1..10}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: ratelimit.example.com" http://$INGRESS_IP/)
  echo "Request $i: HTTP $STATUS"
  sleep 0.1
done

# Deberías ver algunos 503 (Service Temporarily Unavailable)
```

**❓ Pregunta:** ¿Qué código HTTP se devuelve cuando se excede el rate limit?

---

## 📝 Ejercicio 8: Custom Headers y Security

### 8.1 Ingress con Security Headers

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: security-ingress
  namespace: lab-ingress
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
      more_set_headers "Strict-Transport-Security: max-age=31536000";
      more_set_headers "Content-Security-Policy: default-src 'self'";
spec:
  ingressClassName: nginx
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
EOF
```

### 8.2 Test Security Headers

```bash
# Ver todos los headers de respuesta
curl -v -H "Host: secure.example.com" http://$INGRESS_IP/ 2>&1 | grep -E "^< (X-|Strict|Content-Security)"

# Deberías ver:
# X-Frame-Options: DENY
# X-Content-Type-Options: nosniff
# X-XSS-Protection: 1; mode=block
# Strict-Transport-Security: max-age=31536000
# Content-Security-Policy: default-src 'self'
```

---

## 📝 Ejercicio 9: Aplicación Completa (Frontend + Backend + API)

### 9.1 Desplegar Three-Tier App

```bash
cat <<EOF | kubectl apply -f -
# API Backend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: lab-ingress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh"]
        args:
          - -c
          - |
            mkdir -p /usr/share/nginx/html/api/v1
            echo '{"status":"ok","version":"1.0","pod":"'$(hostname)'"}' > /usr/share/nginx/html/api/v1/status
            nginx -g 'daemon off;'
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: lab-ingress
spec:
  selector:
    app: api
  ports:
  - port: 80
---
# Web Frontend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: lab-ingress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh"]
        args:
          - -c
          - |
            cat > /usr/share/nginx/html/index.html <<HTML
            <!DOCTYPE html>
            <html>
            <head><title>Web App</title></head>
            <body>
              <h1>Web Frontend</h1>
              <p>Pod: $(hostname)</p>
              <a href="/api/v1/status">API Status</a>
            </body>
            </html>
            HTML
            nginx -g 'daemon off;'
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: lab-ingress
spec:
  selector:
    app: web
  ports:
  - port: 80
EOF
```

### 9.2 Crear Ingress Completo

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: complete-ingress
  namespace: lab-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-App-Version: 1.0.0";
spec:
  ingressClassName: nginx
  rules:
  - host: mycompany.example.com
    http:
      paths:
      # Frontend
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
      # API
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
EOF
```

### 9.3 Test Aplicación Completa

```bash
# Test Frontend
curl -H "Host: mycompany.example.com" http://$INGRESS_IP/

# Test API
curl -H "Host: mycompany.example.com" http://$INGRESS_IP/api/v1/status

# Ver custom header
curl -v -H "Host: mycompany.example.com" http://$INGRESS_IP/ 2>&1 | grep "X-App-Version"
```

---

## 📝 Ejercicio 10: Troubleshooting Ingress

### 10.1 Escenario: Ingress sin Backend

```bash
# Crear ingress para service que NO existe
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: broken-ingress
  namespace: lab-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: broken.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nonexistent-service  # Service que NO existe
            port:
              number: 80
EOF
```

### 10.2 Diagnosticar

```bash
# Ver ingress
kubectl get ingress broken-ingress -n lab-ingress

# Describir (ver eventos/warnings)
kubectl describe ingress broken-ingress -n lab-ingress

# Test (dará 503 Service Temporarily Unavailable)
curl -v -H "Host: broken.example.com" http://$INGRESS_IP/ 2>&1 | grep "< HTTP"

# Ver logs del controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50 | grep broken.example.com
```

**❓ Pregunta:** ¿Qué código HTTP devuelve cuando el backend no existe?

### 10.3 Diagnosticar Configuración Nginx

```bash
# Ver configuración nginx generada
CONTROLLER_POD=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n ingress-nginx $CONTROLLER_POD -- cat /etc/nginx/nginx.conf | grep -A 20 "server_name broken.example.com"
```

### 10.4 Common Issues Checklist

```bash
# 1. Verificar ingress class
kubectl get ingressclass

# 2. Verificar que el service existe
kubectl get svc -n lab-ingress

# 3. Verificar que el service tiene endpoints
kubectl get endpoints -n lab-ingress

# 4. Verificar logs del controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=100

# 5. Verificar eventos
kubectl get events -n lab-ingress --sort-by='.lastTimestamp'

# 6. Test interno (desde dentro del cluster)
kubectl run test --image=curlimages/curl --rm -it --restart=Never -- curl http://app1-service.lab-ingress/
```

---

## 🎓 Verificación Final

### Checklist de Aprendizaje

- [ ] Instalar ingress-nginx controller
- [ ] Crear ingress con path-based routing
- [ ] Crear ingress con host-based routing
- [ ] Configurar TLS termination
- [ ] Implementar URL rewriting
- [ ] Configurar CORS headers
- [ ] Aplicar rate limiting
- [ ] Añadir custom security headers
- [ ] Diagnosticar problemas de ingress

### Comandos de Validación

```bash
# Listar todos los ingress
kubectl get ingress -n lab-ingress

# Contar ingress creados
kubectl get ingress -n lab-ingress --no-headers | wc -l

# Test completo
echo "=== Testing Ingress ==="
echo "1. Path-based routing:"
curl -s -H "Host: myapp.example.com" http://$INGRESS_IP/app1 | grep -o "App[0-9]"

echo "2. Host-based routing:"
curl -s -H "Host: app1.example.com" http://$INGRESS_IP/ | grep -o "App[0-9]"

echo "3. TLS:"
curl -sk https://$INGRESS_IP/ -H "Host: secure.example.com" | head -1

echo "4. Complete app:"
curl -s -H "Host: mycompany.example.com" http://$INGRESS_IP/api/v1/status
```

---

## 🧹 Limpieza

```bash
# Eliminar namespace
kubectl delete namespace lab-ingress

# Eliminar certificados locales
rm -f tls.key tls.crt

# Volver a default
kubectl config set-context --current --namespace=default

# (Opcional) Desinstalar ingress controller
# kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
# minikube addons disable ingress
```

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

### Annotations Reference

- [NGINX Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/)

### Comandos de Referencia

```bash
# Ingress
kubectl get ingress -A
kubectl describe ingress <name>
kubectl get ingress <name> -o yaml

# Controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx <controller-pod>
kubectl exec -n ingress-nginx <controller-pod> -- cat /etc/nginx/nginx.conf

# Testing
curl -H "Host: example.com" http://<INGRESS-IP>/
curl -k https://<INGRESS-IP>/ -H "Host: example.com"
```

---

## ✅ Criterios de Éxito

Has completado exitosamente este laboratorio si:

1. ✅ Instalaste y verificaste ingress-nginx controller
2. ✅ Configuraste path-based y host-based routing
3. ✅ Implementaste TLS termination con certificados
4. ✅ Aplicaste URL rewriting correctamente
5. ✅ Configuraste CORS y rate limiting
6. ✅ Añadiste security headers personalizados
7. ✅ Diagnosticaste y resolviste problemas de ingress

**¡Felicitaciones! 🎉 Has completado el Laboratorio 03 de Ingress.**
