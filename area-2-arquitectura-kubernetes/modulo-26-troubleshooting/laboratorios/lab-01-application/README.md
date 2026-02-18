# Laboratorio 01: Application Troubleshooting

> **Duración estimada**: 60-75 minutos  
> **Dificultad**: ⭐⭐⭐ (Avanzado)  
> **Objetivos CKA**: Application Lifecycle Management (15%), Troubleshooting (25-30%)

## 📋 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:
- ✅ Diagnosticar pods en estados de error (CrashLoopBackOff, ImagePullBackOff, OOMKilled)
- ✅ Resolver problemas con init containers
- ✅ Troubleshoot liveness y readiness probes
- ✅ Identificar y corregir problemas con ConfigMaps y Secrets
- ✅ Usar kubectl logs, describe y exec efectivamente
- ✅ Aplicar metodología sistemática de troubleshooting

## 🎯 Escenarios

### Escenario 1: Pod en CrashLoopBackOff
**Situación**: Un deployment de una aplicación está fallando constantemente.

**Tareas**:
1. Investigar por qué el pod `webapp-crash` está en CrashLoopBackOff
2. Identificar la causa raíz usando logs
3. Corregir el problema

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-crash
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: app
        image: nginx:1.21
        command: ["nginx"]
        args: ["-g", "daemon off;", "-c", "/etc/nginx/nonexistent.conf"]
        ports:
        - containerPort: 80
EOF
```

<details>
<summary>💡 Pistas</summary>

1. Usa `kubectl get pods` para ver el estado
2. Usa `kubectl logs <pod-name>` para ver los logs actuales
3. Usa `kubectl logs <pod-name> --previous` para ver logs del crash anterior
4. El error estará en los argumentos del comando

</details>

<details>
<summary>✅ Solución</summary>

**Diagnóstico**:
```bash
# Ver estado del pod
kubectl get pods -l app=webapp

# Ver logs (puede estar vacío si crashea inmediatamente)
kubectl logs -l app=webapp

# Ver logs del container anterior
kubectl logs -l app=webapp --previous

# Output esperado:
# nginx: [emerg] open() "/etc/nginx/nonexistent.conf" failed (2: No such file or directory)
```

**Causa raíz**: El archivo de configuración `/etc/nginx/nonexistent.conf` no existe.

**Fix**:
```bash
# Opción 1: Usar config por defecto
kubectl patch deployment webapp-crash -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","command":["nginx"],"args":["-g","daemon off;"]}]}}}}'

# Opción 2: Recrear sin args incorrectos
kubectl delete deployment webapp-crash

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-crash
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: app
        image: nginx:1.21
        ports:
        - containerPort: 80
EOF
```

**Verificación**:
```bash
kubectl get pods -l app=webapp
# Estado: Running

kubectl logs -l app=webapp
# Logs normales de nginx
```

</details>

---

### Escenario 2: ImagePullBackOff
**Situación**: Un nuevo deployment no puede iniciar sus pods.

**Tareas**:
1. Diagnosticar por qué `api-server` está en ImagePullBackOff
2. Identificar qué está mal con la imagen
3. Corregir el problema

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
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
      - name: api
        image: nginx:nonexistent-tag-12345
        ports:
        - containerPort: 8080
EOF
```

<details>
<summary>💡 Pistas</summary>

1. Usa `kubectl describe pod` para ver eventos
2. El error estará en la sección "Events"
3. Verifica el tag de la imagen

</details>

<details>
<summary>✅ Solución</summary>

**Diagnóstico**:
```bash
# Ver estado
kubectl get pods -l app=api

# Describir el pod para ver eventos
kubectl describe pod -l app=api

# Output esperado en Events:
# Failed to pull image "nginx:nonexistent-tag-12345": rpc error: code = Unknown desc = Error response from daemon: manifest for nginx:nonexistent-tag-12345 not found
```

**Causa raíz**: El tag `nonexistent-tag-12345` no existe en Docker Hub.

**Fix**:
```bash
# Actualizar a un tag válido
kubectl set image deployment/api-server api=nginx:1.21

# O editar directamente
kubectl edit deployment api-server
# Cambiar image: nginx:nonexistent-tag-12345 → nginx:1.21
```

**Verificación**:
```bash
kubectl get pods -l app=api
# Estado: Running

kubectl describe pod -l app=api | grep "Successfully pulled"
```

</details>

---

### Escenario 3: OOMKilled - Out of Memory
**Situación**: Una aplicación se reinicia constantemente con exit code 137.

**Tareas**:
1. Identificar que el pod está siendo killed por falta de memoria
2. Ver los resource limits actuales
3. Ajustar los limits apropiadamente

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: memory-hog
spec:
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "250M", "--vm-hang", "0"]
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "100Mi"
        cpu: "200m"
EOF
```

<details>
<summary>💡 Pistas</summary>

1. Usa `kubectl describe pod` y busca "Last State"
2. Exit code 137 = SIGKILL por OOM
3. La app necesita 250M pero el limit es 100Mi

</details>

<details>
<summary>✅ Solución</summary>

**Diagnóstico**:
```bash
# Ver estado
kubectl get pod memory-hog

# Describir para ver Last State
kubectl describe pod memory-hog | grep -A 10 "Last State"

# Output esperado:
#   Last State:     Terminated
#     Reason:       OOMKilled
#     Exit Code:    137

# Ver límites actuales
kubectl get pod memory-hog -o jsonpath='{.spec.containers[0].resources.limits.memory}'
# Output: 100Mi
```

**Causa raíz**: El container necesita 250M de memoria pero el limit es solo 100Mi.

**Fix**:
```bash
# Recrear con límites apropiados
kubectl delete pod memory-hog

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: memory-hog
spec:
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "250M", "--vm-hang", "0"]
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"  # Suficiente headroom
        cpu: "200m"
EOF
```

**Verificación**:
```bash
kubectl get pod memory-hog
# Estado: Running

# Verificar que no se reinicia
watch kubectl get pod memory-hog
```

</details>

---

### Escenario 4: Init Container Failure
**Situación**: Un pod está stuck en Init:0/1 y no puede iniciar.

**Tareas**:
1. Identificar qué init container está fallando
2. Diagnosticar por qué está fallando
3. Resolver el problema

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: backend-app
spec:
  initContainers:
  - name: wait-for-database
    image: busybox:1.28
    command: ['sh', '-c']
    args:
    - |
      until nslookup postgres-service.default.svc.cluster.local; do
        echo "Waiting for database service..."
        sleep 2
      done
  containers:
  - name: app
    image: nginx:1.21
    ports:
    - containerPort: 80
EOF
```

<details>
<summary>💡 Pistas</summary>

1. El pod está esperando por un servicio que no existe
2. Usa `kubectl describe pod` para ver init containers
3. Usa `kubectl logs <pod> -c <init-container-name>` para ver logs del init container

</details>

<details>
<summary>✅ Solución</summary>

**Diagnóstico**:
```bash
# Ver estado
kubectl get pod backend-app
# STATUS: Init:0/1

# Describir para ver init containers
kubectl describe pod backend-app | grep -A 20 "Init Containers"

# Ver logs del init container
kubectl logs backend-app -c wait-for-database
# Output: 
# Waiting for database service...
# nslookup: can't resolve 'postgres-service.default.svc.cluster.local'
```

**Causa raíz**: El servicio `postgres-service` no existe.

**Fix - Opción 1: Crear el servicio**:
```bash
# Crear un pod de postgres
kubectl run postgres --image=postgres:13 --env="POSTGRES_PASSWORD=password"

# Crear el servicio
kubectl expose pod postgres --port=5432 --name=postgres-service

# Ahora el init container debería completarse
kubectl get pod backend-app -w
```

**Fix - Opción 2: Remover el init container**:
```bash
kubectl delete pod backend-app

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: backend-app
spec:
  containers:
  - name: app
    image: nginx:1.21
    ports:
    - containerPort: 80
EOF
```

**Verificación**:
```bash
kubectl get pod backend-app
# Estado: Running
```

</details>

---

### Escenario 5: Liveness Probe Failure
**Situación**: Un pod se reinicia cada ~30 segundos sin razón aparente.

**Tareas**:
1. Identificar que el liveness probe está fallando
2. Entender por qué está fallando
3. Ajustar el probe apropiadamente

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /healthz
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
      failureThreshold: 2
EOF
```

<details>
<summary>💡 Pistas</summary>

1. El pod se reinicia por liveness probe failure
2. nginx no tiene endpoint `/healthz` por defecto
3. Usa `/` en lugar de `/healthz` o aumenta failureThreshold

</details>

<details>
<summary>✅ Solución</summary>

**Diagnóstico**:
```bash
# Ver estado y restarts
kubectl get pod web-server
# RESTARTS: incrementando constantemente

# Describir para ver eventos
kubectl describe pod web-server | grep -A 10 "Liveness"
# Output:
# Liveness probe failed: HTTP probe failed with statuscode: 404

# Ver eventos de restart
kubectl get events --field-selector involvedObject.name=web-server
```

**Causa raíz**: El liveness probe busca `/healthz` que no existe en nginx default. nginx retorna 404.

**Fix - Opción 1: Usar path válido**:
```bash
kubectl delete pod web-server

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /  # Path válido
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
      failureThreshold: 3
EOF
```

**Fix - Opción 2: Ajustar tolerancia**:
```bash
kubectl delete pod web-server

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 30  # Más tiempo para iniciar
      periodSeconds: 15
      failureThreshold: 3
      timeoutSeconds: 5
EOF
```

**Verificación**:
```bash
# Ver que no se reinicia
watch kubectl get pod web-server
# RESTARTS debe permanecer en 0
```

</details>

---

### Escenario 6: Missing ConfigMap
**Situación**: Un deployment no puede crear pods debido a un ConfigMap faltante.

**Tareas**:
1. Identificar que el ConfigMap no existe
2. Crear el ConfigMap necesario
3. Verificar que el pod inicia correctamente

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: config-app
  template:
    metadata:
      labels:
        app: config-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        envFrom:
        - configMapRef:
            name: app-settings
        ports:
        - containerPort: 80
EOF
```

<details>
<summary>💡 Pistas</summary>

1. El pod estará en CreateContainerConfigError
2. Usa `kubectl describe pod` para ver el error
3. Necesitas crear el ConfigMap `app-settings`

</details>

<details>
<summary>✅ Solución</summary>

**Diagnóstico**:
```bash
# Ver estado
kubectl get pods -l app=config-app
# STATUS: CreateContainerConfigError

# Describir para ver error
kubectl describe pod -l app=config-app
# Output en Events:
# Error: configmap "app-settings" not found
```

**Causa raíz**: El ConfigMap `app-settings` no existe.

**Fix**:
```bash
# Crear el ConfigMap
kubectl create configmap app-settings \
  --from-literal=APP_ENV=production \
  --from-literal=LOG_LEVEL=info \
  --from-literal=MAX_CONNECTIONS=100

# O con YAML
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-settings
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
EOF
```

**Verificación**:
```bash
# Ver que el pod ahora está Running
kubectl get pods -l app=config-app

# Verificar variables de entorno
kubectl exec -l app=config-app -- env | grep -E 'APP_ENV|LOG_LEVEL|MAX_CONNECTIONS'
```

</details>

---

### Escenario 7: Readiness Probe Never Ready
**Situación**: Un pod está Running pero no recibe tráfico del Service.

**Tareas**:
1. Identificar que el pod no está Ready (0/1)
2. Diagnosticar el readiness probe
3. Corregir el problema

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: api-pod
  labels:
    app: api
spec:
  containers:
  - name: api
    image: nginx:1.21
    ports:
    - containerPort: 80
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 80
EOF
```

<details>
<summary>💡 Pistas</summary>

1. El pod está Running pero READY es 0/1
2. El readiness probe tiene dos problemas: path y port
3. nginx no tiene `/ready` y usa puerto 80, no 8080

</details>

<details>
<summary>✅ Solución</summary>

**Diagnóstico**:
```bash
# Ver estado
kubectl get pod api-pod
# STATUS: Running, READY: 0/1

# Describir para ver readiness probe
kubectl describe pod api-pod | grep -A 10 "Readiness"
# Output:
# Readiness probe failed: Get http://...:8080/ready: dial tcp ...:8080: connect: connection refused

# Ver endpoints del servicio
kubectl get endpoints api-service
# ENDPOINTS: <none>  ← Sin endpoints porque pod no está ready
```

**Causa raíz**: 
- El readiness probe busca puerto 8080 pero nginx usa 80
- El path `/ready` no existe

**Fix**:
```bash
kubectl delete pod api-pod

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: api-pod
  labels:
    app: api
spec:
  containers:
  - name: api
    image: nginx:1.21
    ports:
    - containerPort: 80
    readinessProbe:
      httpGet:
        path: /  # Path válido
        port: 80  # Puerto correcto
      initialDelaySeconds: 5
      periodSeconds: 5
EOF
```

**Verificación**:
```bash
# Ver que ahora está Ready
kubectl get pod api-pod
# READY: 1/1

# Ver que el service tiene endpoints
kubectl get endpoints api-service
# Ahora debe tener la IP del pod

# Test el servicio
kubectl run test --image=busybox:1.28 -it --rm -- wget -O- http://api-service
```

</details>

---

### Escenario 8: Application Port Mismatch
**Situación**: El Service está configurado pero no puede conectarse a los pods.

**Tareas**:
1. Identificar el port mismatch
2. Corregir la configuración
3. Verificar conectividad

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: python-app
  labels:
    app: python
spec:
  containers:
  - name: app
    image: python:3.9-slim
    command: ["python", "-m", "http.server", "8000"]
    ports:
    - containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: python-service
spec:
  selector:
    app: python
  ports:
  - port: 80
    targetPort: 80
EOF
```

<details>
<summary>💡 Pistas</summary>

1. El servicio apunta al puerto 80
2. La aplicación escucha en el puerto 8000
3. targetPort debe ser 8000

</details>

<details>
<summary>✅ Solución</summary>

**Diagnóstico**:
```bash
# Ver estado
kubectl get pod python-app
kubectl get svc python-service
kubectl get endpoints python-service
# Endpoints existe (IP del pod)

# Intentar acceder
kubectl run test --image=busybox:1.28 -it --rm -- wget -O- http://python-service
# Output: connection refused

# Ver puertos
kubectl get pod python-app -o jsonpath='{.spec.containers[0].ports[0].containerPort}'
# Output: 8000

kubectl get svc python-service -o jsonpath='{.spec.ports[0].targetPort}'
# Output: 80  ← MISMATCH!
```

**Causa raíz**: Service targetPort es 80 pero el container escucha en 8000.

**Fix**:
```bash
# Patch el servicio
kubectl patch svc python-service -p '{"spec":{"ports":[{"port":80,"targetPort":8000}]}}'

# O recrear
kubectl delete svc python-service

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: python-service
spec:
  selector:
    app: python
  ports:
  - port: 80
    targetPort: 8000  # Correcto
EOF
```

**Verificación**:
```bash
kubectl run test --image=busybox:1.28 -it --rm -- wget -O- http://python-service
# Ahora debe funcionar y mostrar el HTML
```

</details>

---

## 🧹 Limpieza

```bash
# Eliminar todos los recursos del lab
kubectl delete deployment webapp-crash api-server config-app
kubectl delete pod memory-hog backend-app web-server api-pod python-app
kubectl delete svc api-service python-service postgres-service
kubectl delete pod postgres
kubectl delete configmap app-settings
```

---

## 📊 Evaluación

Marca las tareas completadas:

- [ ] Escenario 1: CrashLoopBackOff resuelto
- [ ] Escenario 2: ImagePullBackOff resuelto
- [ ] Escenario 3: OOMKilled resuelto
- [ ] Escenario 4: Init Container resuelto
- [ ] Escenario 5: Liveness Probe resuelto
- [ ] Escenario 6: Missing ConfigMap resuelto
- [ ] Escenario 7: Readiness Probe resuelto
- [ ] Escenario 8: Port Mismatch resuelto

---

## 🎯 Puntos Clave para el Examen CKA

1. **Siempre usa `kubectl describe pod`** - Los Events son críticos
2. **Logs anteriores con `--previous`** - Para ver crashes
3. **Exit Code 137 = OOMKilled** - Aumentar memory limits
4. **Init containers** - Diagnosticar con logs específicos del container
5. **Probes** - Verificar path, port, y timing
6. **ConfigMaps/Secrets** - CreateContainerConfigError indica faltantes
7. **Port mismatch** - Verificar containerPort vs targetPort
8. **Ready vs Running** - Pod puede estar Running pero no Ready

---

**Tiempo objetivo**: Resolver cada escenario en 5-8 minutos  
**Siguiente**: [Lab 02 - Control Plane & Nodes](./lab-02-control-plane-nodes.md)
