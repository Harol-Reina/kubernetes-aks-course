# Laboratorio 01: Fundamentos de Ingress

**Duración estimada**: 40-45 minutos  
**Nivel**: Básico  
**Prerequisitos**: Cluster Kubernetes funcional (minikube, kind, k3s o cloud)

## Objetivos

Al completar este laboratorio, serás capaz de:

✅ Instalar nginx ingress controller con Helm  
✅ Crear deployments y services de prueba  
✅ Configurar Ingress con path-based routing  
✅ Configurar Ingress con host-based routing  
✅ Verificar el funcionamiento con curl  
✅ Configurar DNS local con /etc/hosts  
✅ Troubleshootar problemas comunes de Ingress

---

## Parte 1: Instalación del Ingress Controller (10 min)

### Paso 1.1: Instalar Helm (si no está instalado)

```bash
# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verificar instalación
helm version
```

### Paso 1.2: Añadir repositorio de ingress-nginx

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

### Paso 1.3: Instalar nginx ingress controller

```bash
# Para desarrollo (NodePort)
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClass=nginx
```

### Paso 1.4: Verificar instalación

```bash
# Ver pods del ingress controller
kubectl get pods -n ingress-nginx

# Ver servicio (NodePort)
kubectl get svc -n ingress-nginx

# Ver IngressClass creada
kubectl get ingressclass

# Obtener NodePort
export NODE_PORT=$(kubectl get svc -n ingress-nginx nginx-ingress-controller -o jsonpath='{.spec.ports[0].nodePort}')
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
echo "Ingress URL: http://$NODE_IP:$NODE_PORT"
```

**Verificación**: Deberías ver el pod `nginx-ingress-controller-*` en estado `Running`.

---

## Parte 2: Crear Aplicaciones de Prueba (5 min)

### Paso 2.1: Aplicar deployments de ejemplo

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
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
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh", "-c"]
        args:
          - echo '<h1>APP 1</h1><p>Pod: '$(hostname)'</p>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'
---
apiVersion: v1
kind: Service
metadata:
  name: servicio-app1
spec:
  selector:
    app: app1
  ports:
    - port: 8080
      targetPort: 80
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
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
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh", "-c"]
        args:
          - echo '<h1>APP 2</h1><p>Pod: '$(hostname)'</p>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'
---
apiVersion: v1
kind: Service
metadata:
  name: servicio-app2
spec:
  selector:
    app: app2
  ports:
    - port: 8080
      targetPort: 80
  type: ClusterIP
EOF
```

### Paso 2.2: Verificar recursos creados

```bash
kubectl get deployments,services,pods
kubectl get endpoints servicio-app1 servicio-app2
```

---

## Parte 3: Ingress Path-Based Routing (10 min)

### Paso 3.1: Crear Ingress por path

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: servicio-app1
            port:
              number: 8080
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: servicio-app2
            port:
              number: 8080
EOF
```

### Paso 3.2: Verificar Ingress

```bash
kubectl get ingress path-based-ingress
kubectl describe ingress path-based-ingress
```

### Paso 3.3: Probar con curl

```bash
# Probar app1
curl http://$NODE_IP:$NODE_PORT/app1
# Debería mostrar: APP 1

# Probar app2
curl http://$NODE_IP:$NODE_PORT/app2
# Debería mostrar: APP 2

# Probar path inexistente (404)
curl http://$NODE_IP:$NODE_PORT/app3
```

---

## Parte 4: Ingress Host-Based Routing (10 min)

### Paso 4.1: Crear Ingress por host

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-based-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
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

### Paso 4.2: Configurar DNS local

```bash
# Linux/Mac: Editar /etc/hosts
echo "$NODE_IP app1.example.com app2.example.com" | sudo tee -a /etc/hosts

# Verificar
cat /etc/hosts | grep example.com
```

### Paso 4.3: Probar con curl

```bash
# Probar con header Host (sin DNS)
curl -H "Host: app1.example.com" http://$NODE_IP:$NODE_PORT

# Probar con DNS configurado
curl http://app1.example.com
curl http://app2.example.com

# Probar en navegador
firefox http://app1.example.com
```

---

## Parte 5: Troubleshooting (5-10 min)

### Escenario 1: Ingress retorna 404

```bash
# Diagnosticar
kubectl describe ingress <nombre>
kubectl get svc <service-name>
kubectl get endpoints <service-name>

# Verificar logs del controller
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller --tail=50
```

### Escenario 2: Service sin endpoints

```bash
# Verificar
kubectl get endpoints servicio-app1

# Si está vacío, verificar:
kubectl get pods -l app=app1
kubectl describe service servicio-app1
```

---

## Limpieza

```bash
# Eliminar Ingress
kubectl delete ingress path-based-ingress host-based-ingress

# Eliminar apps
kubectl delete deployment app1 app2
kubectl delete service servicio-app1 servicio-app2

# Limpiar /etc/hosts
sudo sed -i '/app1.example.com/d' /etc/hosts
sudo sed -i '/app2.example.com/d' /etc/hosts

# Opcional: Desinstalar ingress controller
# helm uninstall nginx-ingress -n ingress-nginx
```

---

## Checklist de Completado

- [ ] Ingress controller instalado y funcionando
- [ ] Apps de prueba desplegadas
- [ ] Path-based routing funciona (/app1, /app2)
- [ ] Host-based routing funciona (app1.example.com)
- [ ] DNS local configurado correctamente
- [ ] Troubleshooting practicado

---

## Próximos Pasos

➡️ [Lab 02: Ingress con TLS y Configuraciones Avanzadas](lab-02-ingress-tls-avanzado.md)
