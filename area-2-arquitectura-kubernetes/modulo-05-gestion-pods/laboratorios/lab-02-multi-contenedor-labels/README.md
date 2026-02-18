# 🧪 Laboratorio 02: Pods Multi-Contenedor y Labels

**Duración estimada**: 45 minutos  
**Dificultad**: Intermedio  
**Objetivo**: Dominar Pods con múltiples contenedores y gestión de labels

---

## 📋 Prerequisitos

```bash
# Verificar cluster
kubectl get nodes

# Limpiar workspace
kubectl delete pods --all
```

---

## 🎯 Ejercicio 1: Pod con Dos Contenedores

### **Paso 1: Crear Pod multi-contenedor**

Crea `pod-dos-contenedores.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dos-contenedores
  labels:
    app: multi-container
    tier: web
spec:
  containers:
  # Contenedor 1: NGINX
  - name: nginx
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
    command: ['sh', '-c']
    args:
    - |
      echo "Contenedor 1: NGINX en puerto 80" > /usr/share/nginx/html/index.html
      nginx -g 'daemon off;'
  
  # Contenedor 2: Python Server
  - name: python-server
    image: python:3.11-alpine
    ports:
    - containerPort: 8080
    command: ['sh', '-c']
    args:
    - |
      echo "Contenedor 2: Python en puerto 8080" > index.html
      python -m http.server 8080
```

```bash
# Crear Pod
kubectl apply -f pod-dos-contenedores.yaml

# Verificar que ambos contenedores están corriendo
kubectl get pod dos-contenedores

# Esperado:
# NAME               READY   STATUS    RESTARTS   AGE
# dos-contenedores   2/2     Running   0          10s
#                    ↑↑↑
#                    2 de 2 contenedores listos
```

### **Paso 2: Inspeccionar contenedores**

```bash
# Ver detalles del Pod
kubectl describe pod dos-contenedores

# Buscar sección "Containers:"
# Deberías ver:
#   nginx:
#     Container ID: ...
#     Image: nginx:1.25-alpine
#     Port: 80/TCP
#   
#   python-server:
#     Container ID: ...
#     Image: python:3.11-alpine
#     Port: 8080/TCP

# Ver IP del Pod (compartida por ambos contenedores)
kubectl get pod dos-contenedores -o jsonpath='{.status.podIP}'
```

### **Paso 3: Verificar comunicación localhost**

```bash
# Entrar al contenedor nginx
kubectl exec -it dos-contenedores -c nginx -- sh

# Dentro del contenedor nginx:
apk add --no-cache curl

# Acceder al contenedor Python por localhost
curl localhost:8080
# Contenedor 2: Python en puerto 8080

# Acceder a sí mismo
curl localhost:80
# Contenedor 1: NGINX en puerto 80

exit
```

```bash
# Entrar al contenedor Python
kubectl exec -it dos-contenedores -c python-server -- sh

# Dentro del contenedor Python:
apk add --no-cache curl

# Acceder al contenedor NGINX por localhost
curl localhost:80
# Contenedor 1: NGINX en puerto 80

# Acceder a sí mismo
curl localhost:8080
# Contenedor 2: Python en puerto 8080

exit
```

### **Paso 4: Ver logs de cada contenedor**

```bash
# Logs del contenedor nginx
kubectl logs dos-contenedores -c nginx

# Logs del contenedor python-server
kubectl logs dos-contenedores -c python-server

# Seguir logs en tiempo real (en terminales separadas)
# Terminal 1:
kubectl logs dos-contenedores -c nginx -f

# Terminal 2:
kubectl logs dos-contenedores -c python-server -f

# Terminal 3: Generar tráfico
kubectl exec dos-contenedores -c nginx -- curl localhost:8080
kubectl exec dos-contenedores -c python-server -- curl localhost:80
```

---

## 🎯 Ejercicio 2: Problema de Puertos Duplicados

### **Paso 1: Intentar crear Pod con puertos duplicados**

Crea `pod-error-puertos.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: error-puertos
spec:
  containers:
  - name: nginx-1
    image: nginx:alpine
    ports:
    - containerPort: 80    # Puerto 80
  
  - name: nginx-2
    image: nginx:alpine
    ports:
    - containerPort: 80    # ❌ Puerto 80 duplicado
```

```bash
# Intentar crear
kubectl apply -f pod-error-puertos.yaml

# Ver estado
kubectl get pod error-puertos

# Esperado:
# NAME            READY   STATUS    RESTARTS   AGE
# error-puertos   1/2     Error     0          5s

# Ver error
kubectl describe pod error-puertos | grep -A 10 "Events:"

# Verás error: "address already in use"
```

### **Paso 2: Corregir usando puertos diferentes**

Crea `pod-puertos-correctos.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: puertos-correctos
spec:
  containers:
  - name: nginx-80
    image: nginx:alpine
    ports:
    - containerPort: 80
    command: ['sh', '-c']
    args:
    - |
      echo "NGINX en puerto 80" > /usr/share/nginx/html/index.html
      nginx -g 'daemon off;'
  
  - name: nginx-8080
    image: nginx:alpine
    ports:
    - containerPort: 8080
    command: ['sh', '-c']
    args:
    - |
      cat > /etc/nginx/conf.d/custom.conf <<EOF
      server {
        listen 8080;
        location / {
          root /usr/share/nginx/html;
          index index.html;
        }
      }
      EOF
      echo "NGINX en puerto 8080" > /usr/share/nginx/html/index.html
      nginx -g 'daemon off;'
```

```bash
# Eliminar Pod con error
kubectl delete pod error-puertos

# Crear Pod correcto
kubectl apply -f pod-puertos-correctos.yaml

# Verificar
kubectl get pod puertos-correctos

# Esperado:
# NAME                READY   STATUS    RESTARTS   AGE
# puertos-correctos   2/2     Running   0          10s
```

---

## 🎯 Ejercicio 3: Sidecar Pattern

### **Paso 1: Pod con contenedor principal y sidecar**

Crea `pod-sidecar.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-con-sidecar
  labels:
    app: web-app
spec:
  volumes:
  - name: shared-logs
    emptyDir: {}
  
  containers:
  # Contenedor principal: Aplicación web
  - name: app
    image: busybox:1.36
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log
    command: ['sh', '-c']
    args:
    - |
      while true; do
        echo "$(date) - Request procesado" >> /var/log/app.log
        sleep 2
      done
  
  # Sidecar: Procesa logs
  - name: log-processor
    image: busybox:1.36
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log
    command: ['sh', '-c']
    args:
    - |
      while true; do
        if [ -f /var/log/app.log ]; then
          lines=$(wc -l < /var/log/app.log)
          echo "Sidecar: Procesadas $lines líneas de log"
        fi
        sleep 5
      done
```

```bash
# Crear Pod
kubectl apply -f pod-sidecar.yaml

# Ver logs del contenedor principal
kubectl logs app-con-sidecar -c app -f

# En otra terminal, ver logs del sidecar
kubectl logs app-con-sidecar -c log-processor -f

# Verificar compartición de volumen
kubectl exec app-con-sidecar -c app -- cat /var/log/app.log
kubectl exec app-con-sidecar -c log-processor -- cat /var/log/app.log
# Deberían mostrar el mismo contenido
```

---

## 🎯 Ejercicio 4: Labels y Selectors

### **Paso 1: Crear Pods con diferentes labels**

Crea `pods-con-labels.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-prod
  labels:
    app: frontend
    environment: production
    tier: web
    version: "1.0"
spec:
  containers:
  - name: nginx
    image: nginx:alpine

---
apiVersion: v1
kind: Pod
metadata:
  name: frontend-dev
  labels:
    app: frontend
    environment: development
    tier: web
    version: "1.0"
spec:
  containers:
  - name: nginx
    image: nginx:alpine

---
apiVersion: v1
kind: Pod
metadata:
  name: backend-prod
  labels:
    app: backend
    environment: production
    tier: api
    version: "2.0"
spec:
  containers:
  - name: python
    image: python:3.11-alpine
    command: ['sh', '-c', 'python -m http.server 8080']

---
apiVersion: v1
kind: Pod
metadata:
  name: backend-dev
  labels:
    app: backend
    environment: development
    tier: api
    version: "2.0"
spec:
  containers:
  - name: python
    image: python:3.11-alpine
    command: ['sh', '-c', 'python -m http.server 8080']

---
apiVersion: v1
kind: Pod
metadata:
  name: database-prod
  labels:
    app: database
    environment: production
    tier: data
    version: "14"
spec:
  containers:
  - name: postgres
    image: postgres:16-alpine
    env:
    - name: POSTGRES_PASSWORD
      value: "example123"
```

```bash
# Crear todos los Pods
kubectl apply -f pods-con-labels.yaml

# Ver Pods con labels
kubectl get pods --show-labels
```

### **Paso 2: Filtrar con selectores simples**

```bash
# Filtrar por app=frontend
kubectl get pods -l app=frontend

# Esperado:
# NAME            READY   STATUS    RESTARTS   AGE
# frontend-prod   1/1     Running   0          1m
# frontend-dev    1/1     Running   0          1m

# Filtrar por environment=production
kubectl get pods -l environment=production

# Esperado:
# NAME            READY   STATUS    RESTARTS   AGE
# frontend-prod   1/1     Running   0          1m
# backend-prod    1/1     Running   0          1m
# database-prod   1/1     Running   0          1m

# Filtrar por tier=api
kubectl get pods -l tier=api

# Esperado:
# NAME           READY   STATUS    RESTARTS   AGE
# backend-prod   1/1     Running   0          1m
# backend-dev    1/1     Running   0          1m
```

### **Paso 3: Selectores complejos**

```bash
# AND: app=frontend Y environment=production
kubectl get pods -l 'app=frontend,environment=production'

# IN: environment IN (development, staging)
kubectl get pods -l 'environment in (development)'

# NOT IN: environment NOT IN (production)
kubectl get pods -l 'environment notin (production)'

# EXISTS: tiene label "tier"
kubectl get pods -l tier

# NOT EXISTS: no tiene label "tier"
kubectl get pods -l '!tier'

# Múltiples condiciones
kubectl get pods -l 'app in (frontend,backend),environment=production'
```

### **Paso 4: Mostrar labels como columnas**

```bash
# Mostrar labels específicos como columnas
kubectl get pods -L app,environment,tier

# Esperado:
# NAME            READY   STATUS    AGE   APP        ENVIRONMENT    TIER
# frontend-prod   1/1     Running   2m    frontend   production     web
# frontend-dev    1/1     Running   2m    frontend   development    web
# backend-prod    1/1     Running   2m    backend    production     api
# backend-dev     1/1     Running   2m    backend    development    api
# database-prod   1/1     Running   2m    database   production     data
```

### **Paso 5: Modificar labels**

```bash
# Agregar nuevo label
kubectl label pod frontend-prod team=platform

# Verificar
kubectl get pod frontend-prod --show-labels

# Modificar label existente
kubectl label pod frontend-prod version=1.1 --overwrite

# Eliminar label
kubectl label pod frontend-prod team-

# Agregar label a múltiples Pods
kubectl label pods -l app=backend owner=backend-team

# Verificar
kubectl get pods -l app=backend --show-labels
```

---

## 🎯 Ejercicio 5: Operaciones con Labels

### **Paso 1: Eliminar Pods por selector**

```bash
# Ver Pods de development
kubectl get pods -l environment=development

# Eliminar todos los Pods de development
kubectl delete pods -l environment=development

# Verificar (solo quedan production)
kubectl get pods
```

### **Paso 2: Contar Pods por label**

```bash
# Contar Pods por app
kubectl get pods -l app=frontend -o json | jq '.items | length'
kubectl get pods -l app=backend -o json | jq '.items | length'

# Contar total de Pods
kubectl get pods -o json | jq '.items | length'
```

### **Paso 3: Exportar configuración de Pods**

```bash
# Exportar Pod específico
kubectl get pod frontend-prod -o yaml > frontend-prod-backup.yaml

# Exportar todos los Pods con label production
kubectl get pods -l environment=production -o yaml > production-pods-backup.yaml
```

---

## ✅ Verificación Final

### **Checklist**

```bash
# Ver todos los Pods
kubectl get pods --show-labels

# Deberías tener:
# - dos-contenedores (2/2 Running)
# - puertos-correctos (2/2 Running)
# - app-con-sidecar (2/2 Running)
# - frontend-prod (1/1 Running)
# - backend-prod (1/1 Running)
# - database-prod (1/1 Running)
```

### **Pruebas finales**

```bash
# Test 1: Comunicación entre contenedores
kubectl exec dos-contenedores -c nginx -- curl -s localhost:8080 | head -1

# Test 2: Sidecar funcionando
kubectl logs app-con-sidecar -c log-processor | tail -3

# Test 3: Labels filtrados
kubectl get pods -l 'app in (frontend,backend),environment=production'
```

### **Limpiar**

```bash
# Eliminar todos los Pods
kubectl delete pods --all

# Eliminar archivos YAML
rm -f pod-*.yaml pods-con-labels.yaml *-backup.yaml

# Verificar
kubectl get pods
```

---

## 📝 Resumen

En este laboratorio has:

✅ Creado Pods multi-contenedor (2+ contenedores)  
✅ Verificado comunicación por `localhost` entre contenedores  
✅ Resuelto problemas de puertos duplicados  
✅ Implementado patrón Sidecar con volúmenes compartidos  
✅ Usado Labels para organizar Pods  
✅ Aplicado Selectors complejos para filtrar  
✅ Gestionado Labels dinámicamente  

**Próximo laboratorio**: Lab 03 - Limitaciones y Troubleshooting de Pods
