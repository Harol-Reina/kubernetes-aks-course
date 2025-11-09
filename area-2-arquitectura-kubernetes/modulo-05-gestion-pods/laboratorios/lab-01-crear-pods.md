# 🧪 Laboratorio 01: Creación de Pods

**Duración estimada**: 30 minutos  
**Dificultad**: Básico  
**Objetivo**: Dominar la creación de Pods usando métodos imperativos y declarativos

---

## 📋 Prerequisitos

```bash
# Verificar cluster
minikube status

# Limpiar recursos previos
kubectl delete pods --all
```

---

## 🎯 Ejercicio 1: Creación Imperativa

### **Paso 1: Pod simple con nginx**

```bash
# Crear Pod
kubectl run nginx-test --image=nginx:alpine

# Verificar creación
kubectl get pods

# Ver detalles
kubectl get pods -o wide

# Esperado:
# NAME         READY   STATUS    RESTARTS   AGE   IP           NODE
# nginx-test   1/1     Running   0          10s   10.244.0.5   minikube
```

### **Paso 2: Pod con puerto específico**

```bash
# Crear Pod con puerto
kubectl run nginx-web --image=nginx:alpine --port=80

# Verificar
kubectl get pod nginx-web

# Ver configuración del puerto
kubectl get pod nginx-web -o jsonpath='{.spec.containers[0].ports}' | jq
```

### **Paso 3: Pod con variables de entorno**

```bash
# Crear Pod con env vars
kubectl run app-env --image=busybox \
  --env="ENV=production" \
  --env="VERSION=1.0" \
  -- sh -c 'echo "ENV=$ENV VERSION=$VERSION" && sleep 3600'

# Verificar variables
kubectl exec app-env -- env | grep -E 'ENV|VERSION'

# Esperado:
# ENV=production
# VERSION=1.0
```

### **Paso 4: Ver YAML generado**

```bash
# Generar YAML sin crear Pod
kubectl run my-pod --image=nginx:alpine --dry-run=client -o yaml

# Guardar en archivo
kubectl run my-pod --image=nginx:alpine --dry-run=client -o yaml > pod-generated.yaml

# Ver archivo
cat pod-generated.yaml
```

---

## 🎯 Ejercicio 2: Creación Declarativa

### **Paso 1: Pod básico**

Crea `pod-declarativo.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-declarativo
  labels:
    app: nginx
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
```

```bash
# Aplicar manifiesto
kubectl apply -f pod-declarativo.yaml

# Verificar
kubectl get pod nginx-declarativo

# Ver labels
kubectl get pod nginx-declarativo --show-labels
```

### **Paso 2: Pod con comando personalizado**

Crea `pod-con-comando.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: alpine-cmd
spec:
  containers:
  - name: alpine
    image: alpine:3.18
    command: ['sh', '-c']
    args:
    - |
      echo "Iniciando contenedor..."
      echo "Hostname: $(hostname)"
      echo "Fecha: $(date)"
      sleep 3600
```

```bash
# Crear Pod
kubectl apply -f pod-con-comando.yaml

# Ver logs
kubectl logs alpine-cmd

# Esperado:
# Iniciando contenedor...
# Hostname: alpine-cmd
# Fecha: Sat Nov 9 19:30:00 UTC 2025
```

### **Paso 3: Pod con Python server**

Crea `pod-python.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: python-server
  labels:
    app: web
    language: python
spec:
  containers:
  - name: server
    image: python:3.11-alpine
    command: ['sh', '-c']
    args:
    - |
      echo "<h1>Servidor Python en Kubernetes</h1>" > index.html
      echo "<p>Pod: $(hostname)</p>" >> index.html
      python -m http.server 8080
    ports:
    - containerPort: 8080
```

```bash
# Crear Pod
kubectl apply -f pod-python.yaml

# Verificar que está corriendo
kubectl get pod python-server

# Port-forward para acceder
kubectl port-forward pod/python-server 8080:8080 &

# Probar en otra terminal
curl http://localhost:8080

# Matar port-forward
pkill -f "port-forward.*python-server"
```

---

## 🎯 Ejercicio 3: Gestión de múltiples Pods

### **Paso 1: Crear múltiples Pods en un archivo**

Crea `pods-multiples.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-1
  labels:
    app: frontend
    instance: "1"
spec:
  containers:
  - name: nginx
    image: nginx:alpine

---
apiVersion: v1
kind: Pod
metadata:
  name: frontend-2
  labels:
    app: frontend
    instance: "2"
spec:
  containers:
  - name: nginx
    image: nginx:alpine

---
apiVersion: v1
kind: Pod
metadata:
  name: backend-1
  labels:
    app: backend
    instance: "1"
spec:
  containers:
  - name: python
    image: python:3.11-alpine
    command: ['sh', '-c', 'python -m http.server 8080']
```

```bash
# Crear todos los Pods
kubectl apply -f pods-multiples.yaml

# Ver todos los Pods
kubectl get pods

# Filtrar por label
kubectl get pods -l app=frontend
kubectl get pods -l app=backend
```

### **Paso 2: Operaciones en batch**

```bash
# Ver logs de todos los Pods frontend
for pod in $(kubectl get pods -l app=frontend -o name); do
  echo "=== Logs de $pod ==="
  kubectl logs $pod
done

# Eliminar todos los Pods frontend
kubectl delete pods -l app=frontend

# Verificar
kubectl get pods
```

---

## 🎯 Ejercicio 4: Debugging y Troubleshooting

### **Paso 1: Pod con imagen incorrecta**

```bash
# Crear Pod con imagen que no existe
kubectl run error-image --image=nginx:version-inexistente

# Ver estado
kubectl get pod error-image

# Esperado:
# NAME          READY   STATUS             RESTARTS   AGE
# error-image   0/1     ImagePullBackOff   0          30s

# Ver eventos
kubectl describe pod error-image | tail -20

# Ver error específico
kubectl get events --field-selector involvedObject.name=error-image
```

### **Paso 2: Pod con comando que falla**

Crea `pod-error-comando.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: error-comando
spec:
  containers:
  - name: failing
    image: alpine:3.18
    command: ['sh', '-c']
    args:
    - |
      echo "Iniciando..."
      exit 1
```

```bash
# Crear Pod
kubectl apply -f pod-error-comando.yaml

# Ver estado
kubectl get pod error-comando --watch

# Verás:
# NAME            READY   STATUS             RESTARTS   AGE
# error-comando   0/1     CrashLoopBackOff   3          1m

# Ver logs
kubectl logs error-comando

# Ver logs del intento anterior
kubectl logs error-comando --previous
```

### **Paso 3: Limpiar Pods con error**

```bash
# Eliminar Pod con error
kubectl delete pod error-image error-comando

# Verificar
kubectl get pods
```

---

## 🎯 Ejercicio 5: Interacción con Pods

### **Paso 1: Ejecutar comandos**

```bash
# Crear Pod de trabajo
kubectl run workspace --image=alpine:3.18 -- sleep 3600

# Ejecutar comando simple
kubectl exec workspace -- ls -la /

# Ver variables de entorno
kubectl exec workspace -- env

# Ver procesos
kubectl exec workspace -- ps aux
```

### **Paso 2: Modo interactivo**

```bash
# Entrar al Pod
kubectl exec -it workspace -- sh

# Dentro del Pod:
hostname
ip addr
cat /etc/os-release
apk add --no-cache curl
exit
```

### **Paso 3: Copiar archivos**

```bash
# Crear archivo local
echo "Hola desde local" > mensaje.txt

# Copiar al Pod
kubectl cp mensaje.txt workspace:/tmp/mensaje.txt

# Verificar
kubectl exec workspace -- cat /tmp/mensaje.txt

# Copiar desde el Pod
kubectl exec workspace -- sh -c 'echo "Desde Pod" > /tmp/respuesta.txt'
kubectl cp workspace:/tmp/respuesta.txt respuesta-local.txt
cat respuesta-local.txt
```

---

## ✅ Verificación Final

### **Checklist de Pods creados**

```bash
# Listar todos los Pods
kubectl get pods

# Deberías tener:
# - nginx-test
# - nginx-web
# - app-env
# - nginx-declarativo
# - alpine-cmd
# - python-server
# - backend-1
# - workspace
```

### **Limpiar todo**

```bash
# Eliminar todos los Pods
kubectl delete pods --all

# Eliminar archivos YAML de prueba
rm -f pod-*.yaml pods-multiples.yaml mensaje.txt respuesta-local.txt

# Verificar limpieza
kubectl get pods
```

---

## 📝 Resumen

En este laboratorio has:

✅ Creado Pods con `kubectl run` (imperativo)  
✅ Creado Pods con manifiestos YAML (declarativo)  
✅ Trabajado con múltiples Pods en un archivo  
✅ Debuggeado Pods con errores  
✅ Ejecutado comandos dentro de Pods  
✅ Copiado archivos entre local y Pods

**Próximo laboratorio**: Lab 02 - Inspección y Logs de Pods
