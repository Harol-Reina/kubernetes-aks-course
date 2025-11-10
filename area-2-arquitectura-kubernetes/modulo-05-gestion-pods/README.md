# 🎯 Módulo 05: Gestión de Pods en Kubernetes

**Duración**: 90 minutos  
**Modalidad**: Práctico-Intensivo  
**Dificultad**: Fundamental  
**Versión Kubernetes**: 1.28+ (Noviembre 2025)

## 🎯 Objetivos del Módulo

Al completar este módulo serás capaz de:

- ✅ **Crear Pods** usando `kubectl` (generadores y manifiestos YAML)
- ✅ **Inspeccionar Pods** con `describe`, `logs`, y `exec`
- ✅ **Gestionar ciclo de vida** de Pods (crear, actualizar, eliminar)
- ✅ **Utilizar Labels y Selectors** para organizar Pods
- ✅ **Comprender limitaciones** de los Pods standalone
- ✅ **Trabajar con multi-contenedor** en un mismo Pod
- ✅ **Aplicar mejores prácticas** de gestión de Pods

---

## 📋 Tabla de Contenidos

1. [Prerequisitos](#-1-prerequisitos)
2. [Creación de Pods](#-2-creación-de-pods)
3. [Inspección y Debugging](#-3-inspección-y-debugging)
4. [Gestión del Ciclo de Vida](#-4-gestión-del-ciclo-de-vida)
5. [Pods Multi-Contenedor](#-5-pods-multi-contenedor)
6. [Labels y Selectors](#-6-labels-y-selectors)
7. [Limitaciones de los Pods](#-7-limitaciones-de-los-pods)
8. [Mejores Prácticas](#-8-mejores-prácticas)
9. [Ejemplos y Laboratorios Prácticos](#-ejemplos-y-laboratorios-prácticos)
10. [Recursos Adicionales](#-9-recursos-adicionales)

---

## 🔧 1. Prerequisitos

### **Verificar Cluster**

Antes de comenzar, verifica que tu cluster Kubernetes esté funcionando:

```bash
# Verificar que minikube está corriendo
minikube status

# Si no está corriendo, iniciarlo
minikube start

# Verificar conexión con el cluster
kubectl cluster-info

# Ver nodos disponibles
kubectl get nodes

# Verificar que no hay recursos previos
kubectl get pods
```

**Salida esperada** (cluster limpio):
```
No resources found in default namespace.
```

### **Versión de Kubernetes**

Este módulo está actualizado para Kubernetes 1.28+ (Noviembre 2025):

```bash
# Verificar versión del servidor
kubectl version --short

# Salida esperada:
# Client Version: v1.28.x
# Server Version: v1.28.x
```

---

## 🚀 2. Creación de Pods

### **2.1 Método Imperativo (Generadores)**

En Kubernetes moderno, `kubectl run` utiliza **generadores** para crear Pods:

```bash
# Crear un Pod simple con nginx
kubectl run mi-nginx --image=nginx:alpine

# Verificar creación
kubectl get pods

# Ver más detalles
kubectl get pods -o wide
```

**Salida**:
```
NAME        READY   STATUS    RESTARTS   AGE   IP           NODE
mi-nginx    1/1     Running   0          10s   10.244.0.5   minikube
```

#### **Opciones comunes con `kubectl run`**

```bash
# Pod con puerto expuesto
kubectl run mi-app --image=nginx:alpine --port=80

# Pod con variables de entorno
kubectl run mi-app --image=nginx:alpine --env="ENV=production"

# Pod con límites de recursos
kubectl run mi-app --image=nginx:alpine \
  --requests='cpu=100m,memory=128Mi' \
  --limits='cpu=200m,memory=256Mi'

# Pod en modo dry-run (solo ver YAML sin crear)
kubectl run mi-app --image=nginx:alpine --dry-run=client -o yaml
```

### **2.2 Método Declarativo (Manifiestos YAML)**

**¿Por qué usar YAML en lugar de comandos imperativos?**

| Aspecto | Imperativo (`kubectl run`) | Declarativo (YAML) |
|---------|---------------------------|-------------------|
| **Control de versiones** | ❌ No se guarda histórico | ✅ Se versiona en Git |
| **Reproducibilidad** | ⚠️ Difícil de replicar | ✅ Fácil de replicar |
| **Configuración compleja** | ❌ Muy limitado | ✅ Completo control |
| **Trabajo en equipo** | ❌ Difícil de compartir | ✅ Fácil de compartir |
| **Auditabilidad** | ❌ No hay registro | ✅ Registro completo |

#### **Estructura básica de un Pod**

Crea un directorio para tus manifiestos:

```bash
mkdir -p ~/kubernetes/pods
cd ~/kubernetes/pods
```

📄 **Ver ejemplo completo**: [`ejemplos/basicos/pod-nginx.yaml`](./ejemplos/basicos/pod-nginx.yaml)

**Contenido del archivo `pod-nginx.yaml`**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-simple
  labels:
    app: nginx
    example: "true"
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
```

**Aplicar el manifiesto**:

```bash
# Crear el Pod
kubectl apply -f ejemplos/basicos/pod-nginx.yaml

# Verificar creación
kubectl get pods

# Ver YAML completo generado por Kubernetes
kubectl get pod nginx-simple -o yaml

# Ver solo la especificación
kubectl get pod nginx-simple -o jsonpath='{.spec}' | jq
```

#### **Anatomía del manifiesto Pod**

```yaml
apiVersion: v1              # Versión de la API (v1 para Pods)
kind: Pod                   # Tipo de recurso (Pod con mayúscula)
metadata:                   # Metadatos del Pod
  name: mi-pod              # Nombre único en el namespace
  namespace: default        # Namespace (default si se omite)
  labels:                   # Labels para organización
    app: mi-aplicacion
    tier: frontend
  annotations:              # Anotaciones (metadata no identificativa)
    description: "Pod de ejemplo"
spec:                       # Especificación del Pod
  containers:               # Lista de contenedores (mínimo 1)
  - name: contenedor-1      # Nombre del contenedor
    image: nginx:alpine     # Imagen a usar
    ports:                  # Puertos a exponer
    - containerPort: 80
    env:                    # Variables de entorno
    - name: ENV_VAR
      value: "valor"
```

### **2.3 Ejemplos Prácticos**

#### **Pod con Alpine y comando personalizado**

**`pod-alpine.yaml`**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: alpine-test
  labels:
    app: test
spec:
  containers:
  - name: alpine
    image: alpine:3.18
    command: ['sh', '-c']
    args:
    - |
      echo "Hola desde el Pod!" > /tmp/mensaje.txt
      tail -f /dev/null
```

```bash
# Crear Pod
kubectl apply -f pod-alpine.yaml

# Verificar que está corriendo
kubectl get pod alpine-test

# Ver el mensaje creado
kubectl exec alpine-test -- cat /tmp/mensaje.txt
```

#### **Pod con Python HTTP Server**

**`pod-python-server.yaml`**:
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
      echo "Servidor Python corriendo" > index.html
      python -m http.server 8080
    ports:
    - containerPort: 8080
```

```bash
# Crear Pod
kubectl apply -f pod-python-server.yaml

# Port-forward para acceder localmente
kubectl port-forward pod/python-server 8080:8080

# En otra terminal, probar:
curl http://localhost:8080
```

---

### **💡 Práctica Recomendada**

🧪 **Laboratorio práctico**: [`laboratorios/lab-01-crear-pods.md`](./laboratorios/lab-01-crear-pods.md)

Este laboratorio te guía paso a paso en la creación de Pods usando métodos imperativos y declarativos con ejercicios prácticos.

---

## 🔍 3. Inspección y Debugging

### **3.1 Ver información de Pods**

```bash
# Listar todos los Pods
kubectl get pods

# Más detalles (IP, nodo, etc.)
kubectl get pods -o wide

# Ver con labels
kubectl get pods --show-labels

# Filtrar por label
kubectl get pods -l app=nginx

# Watch mode (actualización en tiempo real)
kubectl get pods --watch

# Ver todos los recursos
kubectl get all
```

### **3.2 Describir un Pod (troubleshooting)**

```bash
# Ver detalles completos del Pod
kubectl describe pod nginx-pod
```

**Salida importante**:
```
Name:         nginx-pod
Namespace:    default
Node:         minikube/192.168.49.2
Status:       Running
IP:           10.244.0.5
Containers:
  nginx:
    Image:        nginx:1.25-alpine
    Port:         80/TCP
    State:        Running
      Started:    Sat, 09 Nov 2025 14:30:00 -0500

Events:         # ← MUY IMPORTANTE para debugging
  Type    Reason     Message
  ----    ------     -------
  Normal  Scheduled  Successfully assigned default/nginx-pod to minikube
  Normal  Pulling    Pulling image "nginx:1.25-alpine"
  Normal  Pulled     Successfully pulled image
  Normal  Created    Created container nginx
  Normal  Started    Started container nginx
```

**Casos de error comunes**:

#### **Error: ImagePullBackOff**

```bash
# Crear Pod con imagen inexistente
kubectl run error-pod --image=nginx:version-que-no-existe

# Ver el error
kubectl describe pod error-pod
```

**Eventos mostrarán**:
```
Events:
  Normal   Scheduled  pod/error-pod
  Normal   Pulling    pulling image "nginx:version-que-no-existe"
  Warning  Failed     Failed to pull image: rpc error: code = NotFound
  Warning  Failed     Error: ErrImagePull
  Normal   BackOff    Back-off pulling image
```

**Solución**:
```bash
# Eliminar Pod con error
kubectl delete pod error-pod

# Crear con imagen correcta
kubectl run nginx-ok --image=nginx:alpine
```

### **3.3 Ver Logs de un Pod**

```bash
# Ver logs del Pod
kubectl logs nginx-pod

# Seguir logs en tiempo real (-f = follow)
kubectl logs nginx-pod -f

# Ver últimas 20 líneas
kubectl logs nginx-pod --tail=20

# Logs desde hace 1 hora
kubectl logs nginx-pod --since=1h

# Logs de un contenedor específico (si hay múltiples)
kubectl logs nginx-pod -c nginx

# Logs del Pod anterior (si se reinició)
kubectl logs nginx-pod --previous
```

**Ejemplo con aplicación que loguea**:

```bash
# Crear Pod que genera logs
kubectl run log-generator --image=busybox -- sh -c \
  'while true; do echo "Log mensaje: $(date)"; sleep 2; done'

# Ver logs en tiempo real
kubectl logs log-generator -f

# Salida:
# Log mensaje: Sat Nov 9 19:30:00 UTC 2025
# Log mensaje: Sat Nov 9 19:30:02 UTC 2025
# ...
```

### **3.4 Ejecutar comandos en un Pod**

```bash
# Ejecutar comando simple
kubectl exec nginx-pod -- ls -la /usr/share/nginx/html

# Modo interactivo (-it)
kubectl exec -it nginx-pod -- sh

# Dentro del Pod:
# / # hostname
# nginx-pod
# / # cat /etc/os-release
# / # exit
```

**Ejemplo: Modificar contenido de nginx**:

```bash
# Entrar al Pod
kubectl exec -it nginx-pod -- sh

# Dentro del Pod:
cd /usr/share/nginx/html
echo "<h1>Hola desde Kubernetes!</h1>" > index.html
exit

# Verificar cambios (usando port-forward)
kubectl port-forward pod/nginx-pod 8080:80

# En otra terminal:
curl http://localhost:8080
# <h1>Hola desde Kubernetes!</h1>
```

### **3.5 Ver recursos utilizados**

```bash
# Instalar metrics-server en minikube
minikube addons enable metrics-server

# Esperar unos segundos y ver métricas
kubectl top pods

# Salida:
# NAME        CPU(cores)   MEMORY(bytes)
# nginx-pod   1m           3Mi
```

---

## ♻️ 4. Gestión del Ciclo de Vida

### **4.1 Crear Pods**

```bash
# Método 1: Imperativo
kubectl run mi-pod --image=nginx:alpine

# Método 2: Declarativo
kubectl apply -f pod.yaml

# Método 3: Crear desde manifiesto generado
kubectl run mi-pod --image=nginx:alpine --dry-run=client -o yaml > pod.yaml
kubectl apply -f pod.yaml
```

### **4.2 Actualizar Pods**

⚠️ **IMPORTANTE**: Los Pods son **inmutables** - no se pueden actualizar directamente.

```bash
# ❌ Esto NO funcionará:
kubectl apply -f pod-modificado.yaml
# Error: forbidden: pod updates may not change fields other than...
```

**Campos que SÍ se pueden actualizar en un Pod existente**:
- `spec.containers[*].image` (solo imagen)
- `spec.activeDeadlineSeconds`
- `spec.tolerations`

**Campos que NO se pueden actualizar**:
- `spec.containers[*].command`
- `spec.containers[*].args`
- `spec.containers[*].env`
- `spec.containers[*].resources`
- Prácticamente todo lo demás en `spec`

**Solución: Recrear el Pod**:

```bash
# 1. Eliminar Pod existente
kubectl delete pod nginx-pod

# 2. Modificar YAML
# 3. Crear nuevo Pod
kubectl apply -f pod-modificado.yaml
```

**O en un solo comando**:

```bash
kubectl replace --force -f pod.yaml
# Esto elimina y recrea el Pod automáticamente
```

### **4.3 Eliminar Pods**

```bash
# Eliminar un Pod específico
kubectl delete pod nginx-pod

# Eliminar usando el archivo YAML
kubectl delete -f pod.yaml

# Eliminar todos los Pods con un label
kubectl delete pods -l app=nginx

# Eliminar todos los Pods en el namespace
kubectl delete pods --all

# Eliminar con grace period personalizado (segundos)
kubectl delete pod nginx-pod --grace-period=10

# Forzar eliminación inmediata (peligroso)
kubectl delete pod nginx-pod --force --grace-period=0
```

**Estados durante la eliminación**:

```bash
# Iniciar eliminación
kubectl delete pod nginx-pod

# En otra terminal, observar:
kubectl get pods --watch

# Verás:
# NAME        READY   STATUS        RESTARTS   AGE
# nginx-pod   1/1     Terminating   0          5m
# nginx-pod   0/1     Terminating   0          5m
# (Pod desaparece)
```

### **4.4 Ciclo de vida completo de un Pod**

```
┌─────────────────────────────────────────────────────────────┐
│                    CICLO DE VIDA DEL POD                    │
└─────────────────────────────────────────────────────────────┘

1. Pending
   ├─ Pod creado en API Server
   ├─ Esperando scheduling
   └─ Descargando imágenes

2. Running
   ├─ Pod asignado a un nodo
   ├─ Contenedores en ejecución
   └─ Al menos 1 contenedor corriendo

3. Succeeded
   ├─ Todos los contenedores terminaron exitosamente
   └─ No se reiniciarán

4. Failed
   ├─ Al menos un contenedor terminó con error
   └─ No se reiniciará (si restartPolicy=Never)

5. Unknown
   ├─ No se puede obtener estado del Pod
   └─ Usualmente problemas de comunicación con nodo

6. CrashLoopBackOff
   ├─ Contenedor falla y se reinicia repetidamente
   └─ Kubernetes espera cada vez más entre reintentos
```

**Ejemplo: Ver transiciones de estado**:

```bash
# Terminal 1: Observar cambios
kubectl get pods --watch

# Terminal 2: Crear Pod
kubectl apply -f pod.yaml

# Verás en Terminal 1:
# NAME      READY   STATUS              RESTARTS   AGE
# mi-pod    0/1     Pending             0          0s
# mi-pod    0/1     ContainerCreating   0          1s
# mi-pod    1/1     Running             0          3s
```

---

## 🔗 5. Pods Multi-Contenedor

### **5.1 ¿Cuándo usar múltiples contenedores en un Pod?**

**Patrones comunes**:

1. **Sidecar**: Contenedor auxiliar que extiende funcionalidad
2. **Ambassador**: Proxy que simplifica comunicación con servicios externos
3. **Adapter**: Normaliza y estandariza salida de logs/metrics

📄 **Ver ejemplos completos**:
- [`ejemplos/multi-contenedor/pod-dos-contenedores.yaml`](./ejemplos/multi-contenedor/pod-dos-contenedores.yaml) - Demo básica
- [`ejemplos/patterns/sidecar-logging.yaml`](./ejemplos/patterns/sidecar-logging.yaml) - Patrón Sidecar
- [`ejemplos/patterns/ambassador-proxy.yaml`](./ejemplos/patterns/ambassador-proxy.yaml) - Patrón Ambassador
- [`ejemplos/patterns/adapter-logging.yaml`](./ejemplos/patterns/adapter-logging.yaml) - Patrón Adapter

**Ejemplo: Pod con dos contenedores**

```yaml
# Archivo: ejemplos/multi-contenedor/pod-dos-contenedores.yaml
apiVersion: v1
kind: Pod
metadata:
  name: dos-contenedores
  labels:
    app: multi-container
spec:
  containers:
  # Contenedor 1: Servidor web
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
  
  # Contenedor 2: Servidor Python
  - name: python-server
    image: python:alpine
    ports:
    - containerPort: 8080
```

```bash
# Crear Pod
kubectl apply -f ejemplos/multi-contenedor/pod-dos-contenedores.yaml

# Ver estado (deben estar READY 2/2)
kubectl get pod dos-contenedores

# Salida:
# NAME               READY   STATUS    RESTARTS   AGE
# dos-contenedores   2/2     Running   0          10s
```

### **5.2 Comunicación entre contenedores**

Los contenedores en un Pod comparten:
- ✅ **Dirección IP** (misma IP para todos)
- ✅ **Namespace de red** (se ven por `localhost`)
- ✅ **Namespace IPC** (pueden compartir memoria)
- ❌ **Filesystem** (cada uno tiene su propio FS)

**Verificar comunicación**:

```bash
# Entrar al contenedor nginx
kubectl exec -it dos-contenedores -c nginx -- sh

# Dentro del contenedor nginx:
# Instalar curl
apk add --no-cache curl

# Acceder al otro contenedor por localhost
curl localhost:8080
# Contenedor 2: Python

# Acceder a sí mismo
curl localhost:80
# Contenedor 1: NGINX

exit
```

**Entrar al contenedor Python**:

```bash
# Entrar al contenedor python-server
kubectl exec -it dos-contenedores -c python-server -- sh

# Dentro del contenedor python:
# Instalar curl
apk add --no-cache curl

# Acceder al contenedor nginx por localhost
curl localhost:80
# Contenedor 1: NGINX

# Acceder a sí mismo
curl localhost:8080
# Contenedor 2: Python

exit
```

### **5.3 Problema: Puertos duplicados**

⚠️ **No se pueden usar los mismos puertos en contenedores del mismo Pod**:

**`pod-error-puertos.yaml`** (INCORRECTO):
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
    - containerPort: 80    # ← Puerto 80
  
  - name: nginx-2
    image: nginx:alpine
    ports:
    - containerPort: 80    # ← ❌ Puerto 80 duplicado!
```

```bash
# Intentar crear
kubectl apply -f pod-error-puertos.yaml

# Ver error
kubectl describe pod error-puertos

# Events:
#   Warning  Failed  Error: failed to start container "nginx-2"
#   Error: listen tcp :80: bind: address already in use
```

**Solución: Usar puertos diferentes**:

```yaml
spec:
  containers:
  - name: nginx-1
    image: nginx:alpine
    ports:
    - containerPort: 80    # ✅ Puerto 80
  
  - name: nginx-2
    image: nginx:alpine
    command: ['sh', '-c', 'nginx -g "daemon off;" || nginx -c /etc/nginx/nginx-custom.conf']
    ports:
    - containerPort: 8080  # ✅ Puerto diferente
```

### **5.4 Ver logs de contenedores específicos**

```bash
# Ver logs del contenedor nginx
kubectl logs dos-contenedores -c nginx

# Ver logs del contenedor python-server
kubectl logs dos-contenedores -c python-server

# Seguir logs de ambos (en terminales separadas)
kubectl logs dos-contenedores -c nginx -f
kubectl logs dos-contenedores -c python-server -f
```

---

### **💡 Práctica Avanzada**

🧪 **Laboratorio práctico**: [`laboratorios/lab-02-multi-contenedor-labels.md`](./laboratorios/lab-02-multi-contenedor-labels.md)

Este laboratorio combina Pods multi-contenedor con gestión avanzada de labels y selectors, incluyendo ejercicios de troubleshooting.

---

## 🏷️ 6. Labels y Selectors

### **6.1 ¿Qué son los Labels?**

Los **labels** son pares clave-valor que se adjuntan a objetos Kubernetes para:
- Organizar recursos
- Filtrar búsquedas
- Permitir que objetos de nivel superior (ReplicaSets, Deployments) identifiquen Pods

**Ejemplo de labels comunes**:

```yaml
metadata:
  labels:
    app: nginx                    # Nombre de la aplicación
    environment: production       # Ambiente
    tier: frontend               # Capa de la aplicación
    version: "1.0"               # Versión
    team: platform               # Equipo responsable
    release: stable              # Canal de release
```

### **6.2 Crear Pods con Labels**

**`pods-con-labels.yaml`**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-prod
  labels:
    app: frontend
    environment: production
    tier: web
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
spec:
  containers:
  - name: python
    image: python:3.11-alpine
    command: ['sh', '-c', 'python -m http.server 8080']
```

```bash
# Crear todos los Pods
kubectl apply -f pods-con-labels.yaml

# Ver Pods con sus labels
kubectl get pods --show-labels
```

**Salida**:
```
NAME            READY   STATUS    AGE   LABELS
frontend-prod   1/1     Running   10s   app=frontend,environment=production,tier=web
frontend-dev    1/1     Running   10s   app=frontend,environment=development,tier=web
backend-prod    1/1     Running   10s   app=backend,environment=production,tier=api
backend-dev     1/1     Running   10s   app=backend,environment=development,tier=api
```

### **6.3 Filtrar Pods con Selectors**

```bash
# Filtrar por app=frontend
kubectl get pods -l app=frontend

# Salida:
# NAME            READY   STATUS    AGE
# frontend-prod   1/1     Running   1m
# frontend-dev    1/1     Running   1m

# Filtrar por environment=production
kubectl get pods -l environment=production

# Salida:
# NAME            READY   STATUS    AGE
# frontend-prod   1/1     Running   1m
# backend-prod    1/1     Running   1m

# Filtrar por tier=api
kubectl get pods -l tier=api

# Salida:
# NAME           READY   STATUS    AGE
# backend-prod   1/1     Running   1m
# backend-dev    1/1     Running   1m
```

**Selectores complejos**:

```bash
# AND: app=frontend Y environment=production
kubectl get pods -l 'app=frontend,environment=production'

# IN: environment IN (development, staging)
kubectl get pods -l 'environment in (development,staging)'

# NOT IN: environment NOT IN (production)
kubectl get pods -l 'environment notin (production)'

# EXISTS: tiene el label "tier"
kubectl get pods -l tier

# NOT EXISTS: no tiene el label "tier"
kubectl get pods -l '!tier'
```

### **6.4 Gestionar Labels**

```bash
# Agregar label a Pod existente
kubectl label pod frontend-prod version=1.0

# Sobrescribir label existente
kubectl label pod frontend-prod version=2.0 --overwrite

# Eliminar label
kubectl label pod frontend-prod version-

# Ver labels de un Pod específico
kubectl get pod frontend-prod --show-labels

# Mostrar solo ciertos labels como columnas
kubectl get pods -L app,environment
```

**Salida de `-L`**:
```
NAME            READY   STATUS    AGE   APP        ENVIRONMENT
frontend-prod   1/1     Running   5m    frontend   production
frontend-dev    1/1     Running   5m    frontend   development
backend-prod    1/1     Running   5m    backend    production
backend-dev     1/1     Running   5m    backend    development
```

### **6.5 Importancia de Labels**

Los labels son **fundamentales** para que objetos de nivel superior gestionen Pods:

```yaml
# Ejemplo: ReplicaSet usa selector de labels
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: frontend-rs
spec:
  replicas: 3
  selector:
    matchLabels:          # ← Busca Pods con estos labels
      app: frontend
      environment: production
  template:
    metadata:
      labels:             # ← Los Pods creados tendrán estos labels
        app: frontend
        environment: production
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
```

---

## ⚠️ 7. Limitaciones de los Pods

### **7.1 Problema #1: No se Auto-Recuperan**

```bash
# Crear Pod
kubectl run test-pod --image=nginx:alpine

# Ver Pod corriendo
kubectl get pods

# Eliminar Pod manualmente
kubectl delete pod test-pod

# Ver Pods (no hay ninguno)
kubectl get pods
# No resources found in default namespace.
```

❌ **El Pod NO se recrea automáticamente**

### **7.2 Problema #2: No se Replican**

```bash
# Crear dos Pods manualmente
kubectl run pod-1 --image=nginx:alpine
kubectl run pod-2 --image=nginx:alpine

# Ver Pods
kubectl get pods

# Salida:
# NAME    READY   STATUS    RESTARTS   AGE
# pod-1   1/1     Running   0          10s
# pod-2   1/1     Running   0          5s
```

❌ **Si quieres 50 réplicas, debes ejecutar `kubectl run` 50 veces**

### **7.3 Problema #3: No se Pueden Actualizar**

```bash
# Crear Pod
kubectl apply -f pod.yaml

# Modificar pod.yaml (cambiar command o env)
# Intentar actualizar
kubectl apply -f pod.yaml
```

❌ **Error**:
```
The Pod "mi-pod" is invalid: spec: Forbidden: pod updates may not 
change fields other than `spec.containers[*].image`
```

### **7.4 Problema #4: Sin Balanceo de Carga Automático**

Aunque crees múltiples Pods manualmente:

```bash
kubectl run pod-1 --image=nginx:alpine --labels="app=web"
kubectl run pod-2 --image=nginx:alpine --labels="app=web"
kubectl run pod-3 --image=nginx:alpine --labels="app=web"
```

❌ **No hay distribución automática de tráfico entre ellos**

### **7.5 Solución: Objetos de Nivel Superior**

```
┌─────────────────────────────────────────────────────────┐
│              JERARQUÍA DE OBJETOS                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Deployment (más alto nivel)                           │
│    ├─ Gestiona rollouts y rollbacks                    │
│    └─ Crea y gestiona ReplicaSets                      │
│                                                         │
│  ReplicaSet                                             │
│    ├─ Garantiza número de réplicas                     │
│    ├─ Auto-recuperación de Pods                        │
│    └─ Crea y gestiona Pods                             │
│                                                         │
│  Pod (nivel más bajo)                                   │
│    ├─ Ejecuta contenedores                             │
│    ├─ NO se auto-recupera                              │
│    └─ NO se replica solo                               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Comparación**:

| Característica | Pod Standalone | ReplicaSet | Deployment |
|----------------|----------------|------------|------------|
| Auto-recuperación | ❌ | ✅ | ✅ |
| Réplicas | ❌ | ✅ | ✅ |
| Rolling updates | ❌ | ❌ | ✅ |
| Rollback | ❌ | ❌ | ✅ |
| Uso recomendado | Testing/Debug | Réplicas simples | **Producción** |

---

## ✅ 8. Mejores Prácticas

### **8.1 Cuándo usar Pods directamente**

✅ **Usar Pods standalone para**:
- Testing y debugging
- Jobs de una sola ejecución
- Experimentación y aprendizaje
- Troubleshooting de problemas

❌ **NO usar Pods standalone para**:
- Aplicaciones en producción
- Servicios que requieren alta disponibilidad
- Cargas de trabajo que necesitan escalar

### **8.2 Organización con Labels**

**Convención recomendada**:

```yaml
metadata:
  labels:
    # Kubernetes recommended labels
    app.kubernetes.io/name: nginx
    app.kubernetes.io/instance: nginx-prod-1
    app.kubernetes.io/version: "1.25"
    app.kubernetes.io/component: frontend
    app.kubernetes.io/part-of: ecommerce
    app.kubernetes.io/managed-by: kubectl
    
    # Custom labels
    environment: production
    team: platform
    cost-center: engineering
```

### **8.3 Naming Conventions**

```yaml
metadata:
  name: <app>-<component>-<environment>-<unique-id>
  # Ejemplos:
  # frontend-web-prod-1
  # backend-api-staging-2
  # database-postgres-dev
```

### **8.4 Resources y Limits**

Siempre define recursos:

```yaml
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    resources:
      requests:        # Mínimo garantizado
        memory: "64Mi"
        cpu: "100m"
      limits:          # Máximo permitido
        memory: "128Mi"
        cpu: "200m"
```

### **8.5 Health Checks**

Implementa probes:

```yaml
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    livenessProbe:    # ¿Está vivo?
      httpGet:
        path: /health
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 5
    
    readinessProbe:   # ¿Está listo para tráfico?
      httpGet:
        path: /ready
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 3
```

### **8.6 Security Best Practices**

```yaml
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

---

## 🧪 Ejemplos y Laboratorios Prácticos

### **📁 Ejemplos YAML Disponibles**

Todos los ejemplos están en [`ejemplos/`](./ejemplos/) organizados por categoría:

#### **Básicos** ([`ejemplos/basicos/`](./ejemplos/basicos/))
| Archivo | Descripción | Uso |
|---------|-------------|-----|
| `pod-nginx.yaml` | Pod simple con NGINX | Testing básico, port-forward |
| `pod-python.yaml` | Pod con Python HTTP server | Demo de aplicaciones custom |
| `pod-con-env.yaml` | Pod con variables de entorno | Configuración de apps |
| `pod-volumenes.yaml` | Pod con volúmenes | Persistencia de datos |

#### **Multi-Contenedor** ([`ejemplos/multi-contenedor/`](./ejemplos/multi-contenedor/))
| Archivo | Descripción | Patrón |
|---------|-------------|--------|
| `pod-dos-contenedores.yaml` | 2 contenedores comunicándose | Demo básica |

#### **Patrones de Diseño** ([`ejemplos/patterns/`](./ejemplos/patterns/))
| Archivo | Descripción | Patrón |
|---------|-------------|--------|
| `sidecar-logging.yaml` | Logging con Fluent Bit | Sidecar |
| `ambassador-proxy.yaml` | Proxy para bases de datos | Ambassador |
| `adapter-logging.yaml` | Normalización de logs | Adapter |

#### **Production-Ready** ([`ejemplos/production-ready/`](./ejemplos/production-ready/))
| Archivo | Descripción | Features |
|---------|-------------|----------|
| `pod-completo.yaml` | Pod con todas las best practices | Resources, probes, security |
| `pod-con-init.yaml` | Pod con init containers | Setup previo |
| `pod-lifecycle.yaml` | Pod con lifecycle hooks | PreStop, PostStart |

#### **Troubleshooting** ([`ejemplos/troubleshooting/`](./ejemplos/troubleshooting/))
| Archivo | Descripción | Problema |
|---------|-------------|----------|
| `pod-crashloop.yaml` | Demo de CrashLoopBackOff | Debugging crashes |
| `pod-imagepull-error.yaml` | Demo de ImagePullBackOff | Errores de imagen |
| `pod-recursos-insuficientes.yaml` | Demo de recursos insuficientes | OOMKilled |

**Ver guía completa**: [`ejemplos/README.md`](./ejemplos/README.md)

---

### **🎓 Laboratorios Hands-On**

| # | Laboratorio | Duración | Nivel | Temas |
|---|-------------|----------|-------|-------|
| 1 | [Creación de Pods](./laboratorios/lab-01-crear-pods.md) | 30 min | Básico | Imperativo, Declarativo, YAML |
| 2 | [Multi-contenedor y Labels](./laboratorios/lab-02-multi-contenedor-labels.md) | 45 min | Intermedio | Sidecar, Labels, Selectors |

**Comandos rápidos**:
```bash
# Aplicar todos los ejemplos básicos
kubectl apply -f ejemplos/basicos/

# Aplicar ejemplos de patterns
kubectl apply -f ejemplos/patterns/

# Ver README de ejemplos
cat ejemplos/README.md
```

---

## 📚 9. Recursos Adicionales

### **9.1 Comandos de referencia rápida**

```bash
# Crear Pod
kubectl run <nombre> --image=<imagen>
kubectl apply -f pod.yaml

# Ver Pods
kubectl get pods
kubectl get pods -o wide
kubectl get pods --show-labels
kubectl get pods -l app=nginx

# Inspeccionar Pod
kubectl describe pod <nombre>
kubectl logs <nombre>
kubectl logs <nombre> -f
kubectl logs <nombre> -c <contenedor>

# Ejecutar comandos
kubectl exec <nombre> -- <comando>
kubectl exec -it <nombre> -- sh

# Eliminar Pod
kubectl delete pod <nombre>
kubectl delete -f pod.yaml
kubectl delete pods --all

# Port forwarding
kubectl port-forward pod/<nombre> <puerto-local>:<puerto-pod>
```

### **9.2 Recursos de aprendizaje**

- 📖 [Documentación oficial de Kubernetes - Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- 📖 [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- 📖 [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- 🎓 [Curso Kubernetes - pabpereza.dev](https://pabpereza.dev/docs/cursos/kubernetes/pods_en_kubernetes_guia_completa_desde_cero)

### **9.3 Próximos pasos**

En el **Módulo 06: ReplicaSets**, aprenderás:
- ✅ Cómo mantener un número deseado de réplicas
- ✅ Auto-recuperación de Pods
- ✅ Escalado horizontal
- ✅ Uso de selectores para gestión de Pods

---

## 🎓 Resumen del Módulo

Has aprendido:

✅ **Crear Pods** usando métodos imperativos y declarativos  
✅ **Inspeccionar y debuggear** Pods con `describe`, `logs`, `exec`  
✅ **Gestionar ciclo de vida** (limitaciones de inmutabilidad)  
✅ **Trabajar con multi-contenedor** (comunicación por localhost)  
✅ **Usar Labels y Selectors** para organización  
✅ **Comprender limitaciones** de Pods standalone  
✅ **Aplicar mejores prácticas** de gestión

**Puntos clave**:
- 🔑 Pods son la unidad mínima, pero **NO se usan solos en producción**
- 🔑 Labels son **esenciales** para organización y gestión
- 🔑 Multi-contenedor solo cuando **comparten ciclo de vida**
- 🔑 Usa **ReplicaSets/Deployments** para cargas reales

---

**📅 Fecha de actualización**: Noviembre 2025  
**🔖 Versión**: 1.0  
**👨‍💻 Autor**: Curso Kubernetes AKS

---

**⬅️ Anterior**: [Módulo 04 - Pods vs Contenedores](../modulo-04-pods-vs-contenedores/README.md)  
**➡️ Siguiente**: [Módulo 06 - ReplicaSets y Réplicas](../modulo-06-replicasets-replicas/README.md)
