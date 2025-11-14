# Laboratorio 02: Ingress con TLS y Configuraciones Avanzadas

**Duración estimada**: 50-60 minutos  
**Nivel**: Intermedio  
**Prerequisitos**: Lab 01 completado, Ingress controller instalado

## Objetivos

✅ Generar certificados autofirmados con openssl  
✅ Crear Secrets TLS en Kubernetes  
✅ Configurar Ingress con HTTPS  
✅ Implementar múltiples hosts con TLS  
✅ Usar anotaciones avanzadas (rewrite, CORS)  
✅ Verificar TLS con curl y openssl  
✅ Troubleshooting de certificados

---

## Parte 1: Certificados TLS (15 min)

### Paso 1.1: Generar certificado autofirmado

```bash
# Certificado para app.example.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=app.example.com/O=MyOrg"

# Verificar certificado
openssl x509 -in tls.crt -text -noout | grep -E "Subject:|Not"
```

### Paso 1.2: Crear Secret TLS

```bash
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Verificar Secret
kubectl get secret tls-secret
kubectl describe secret tls-secret
```

### Paso 1.3: Crear Ingress con TLS

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: tls-secret
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: servicio-app1
            port:
              number: 8080
EOF
```

### Paso 1.4: Probar HTTPS

```bash
# Configurar /etc/hosts si no existe
echo "$NODE_IP app.example.com" | sudo tee -a /etc/hosts

# Probar con curl (ignorar certificado autofirmado)
curl -k https://app.example.com

# Verificar redirección HTTP → HTTPS
curl -I http://app.example.com
# Debe retornar: 308 Permanent Redirect

# Ver detalles del certificado
openssl s_client -connect app.example.com:443 -servername app.example.com < /dev/null 2>&1 | grep -E "subject=|issuer="
```

---

## Parte 2: Certificado Wildcard Multi-Host (15 min)

### Paso 2.1: Generar certificado wildcard

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout wildcard.key -out wildcard.crt \
  -subj "/CN=*.example.com/O=MyOrg" \
  -addext "subjectAltName=DNS:*.example.com,DNS:example.com"

kubectl create secret tls wildcard-tls \
  --cert=wildcard.crt \
  --key=wildcard.key
```

### Paso 2.2: Ingress multi-host con TLS

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-tls-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app1.example.com
    - app2.example.com
    - api.example.com
    secretName: wildcard-tls
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: servicio-app1
            port:
              number: 8080
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: servicio-app2
            port:
              number: 8080
EOF
```

### Paso 2.3: Configurar y probar

```bash
# Añadir hosts
echo "$NODE_IP app1.example.com app2.example.com" | sudo tee -a /etc/hosts

# Probar
curl -k https://app1.example.com
curl -k https://app2.example.com
```

---

## Parte 3: Anotaciones Avanzadas (20 min)

### Paso 3.1: URL Rewriting

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rewrite-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: servicio-app1
            port:
              number: 8080
EOF

# Probar rewrite
curl http://api.example.com/api/users
# /api/users → /users en el backend
```

### Paso 3.2: CORS

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cors-ingress
  annotations:
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, OPTIONS"
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
            name: servicio-app1
            port:
              number: 8080
EOF

# Verificar headers CORS
curl -H "Origin: https://frontend.com" -I http://api.example.com
# Buscar: Access-Control-Allow-Origin
```

---

## Limpieza

```bash
kubectl delete ingress tls-ingress multi-host-tls-ingress rewrite-ingress cors-ingress
kubectl delete secret tls-secret wildcard-tls
rm -f tls.key tls.crt wildcard.key wildcard.crt
sudo sed -i '/example.com/d' /etc/hosts
```

---

## Checklist

- [ ] Certificados autofirmados generados
- [ ] Secrets TLS creados
- [ ] HTTPS funcionando
- [ ] Certificado wildcard multi-host funciona
- [ ] URL rewriting probado
- [ ] CORS configurado

➡️ [Lab 03: Ingress en Producción](lab-03-ingress-produccion.md)
