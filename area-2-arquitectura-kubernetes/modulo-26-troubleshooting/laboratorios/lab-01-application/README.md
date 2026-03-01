# Laboratorio 01: Application Troubleshooting

> **Duracion estimada**: 60-75 minutos
> **Dificultad**: Avanzado
> **Objetivos CKA**: Application Lifecycle Management (15%), Troubleshooting (25-30%)

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Diagnostico CrashLoopBackOff** | Uso de `kubectl logs --previous` para ver logs del contenedor antes del ultimo crash. Identificacion de errores en command/args del spec |
| **Diagnostico ImagePullBackOff** | Uso de `kubectl describe pod` para inspeccionar la seccion Events y obtener el mensaje exacto del registry sobre el tag invalido |
| **OOMKilled y resource limits** | Identificacion de exit code 137 (SIGKILL por OOM). Ajuste de memory limits y requests para que el limit supere el uso real del proceso |
| **Init Containers** | Diagnostico con `kubectl logs <pod> -c <init-container>`. Estado Init:0/1 indica init container bloqueado. Dos opciones de fix: crear la dependencia o eliminar el init container |
| **Liveness y Readiness Probes** | Diferencia entre liveness (reinicia el pod) y readiness (excluye del Service). Configuracion correcta de path, port, initialDelaySeconds y failureThreshold |
| **Referencias a ConfigMap y Secret** | Estado CreateContainerConfigError cuando envFrom referencia un ConfigMap inexistente. Crear el recurso faltante resuelve el problema sin recrear el Deployment |
| **Diagnostico Port Mismatch** | Comparacion de containerPort del pod vs targetPort del Service. Los Endpoints pueden existir pero el trafico falla si los puertos no coinciden |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque declarativo. Todas las operaciones de setup y fix se realizan mediante archivos YAML:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `scenario-01-crashloop-setup.yaml` | 1 | Deployment webapp-crash con ruta de configuracion nginx inexistente |
| `scenario-01-crashloop-fix.yaml` | 1 | Deployment webapp-crash corregido sin argumentos invalidos |
| `scenario-02-imagepull-setup.yaml` | 2 | Deployment api-server con tag de imagen nonexistent-tag-12345 |
| `scenario-03-oomkilled-setup.yaml` | 3 | Pod memory-hog con memory limit de 100Mi insuficiente para 250M de uso |
| `scenario-03-oomkilled-fix.yaml` | 3 | Pod memory-hog corregido con memory limit de 512Mi |
| `scenario-04-initcontainer-setup.yaml` | 4 | Pod backend-app con init container esperando postgres-service inexistente |
| `scenario-04-initcontainer-fix.yaml` | 4 | Pod backend-app sin init container bloqueante (Opcion 2 del fix) |
| `scenario-05-liveness-setup.yaml` | 5 | Pod web-server con liveness probe apuntando a /healthz (path invalido en nginx) |
| `scenario-05-liveness-fix.yaml` | 5 | Pod web-server con liveness probe corregido a path: / (Opcion 1) |
| `scenario-06-configmap-setup.yaml` | 6 | Deployment config-app referenciando ConfigMap app-settings inexistente |
| `scenario-06-configmap-fix.yaml` | 6 | ConfigMap app-settings creado para satisfacer la referencia del Deployment |
| `scenario-07-readiness-setup.yaml` | 7 | Pod api-pod + Service api-service con readiness probe en puerto 8080 y path /ready incorrectos |
| `scenario-07-readiness-fix.yaml` | 7 | Pod api-pod corregido con readiness probe en puerto 80 y path / |
| `scenario-08-portmismatch-setup.yaml` | 8 | Pod python-app + Service python-service con targetPort: 80 incorrecto (app usa 8000) |
| `scenario-08-portmismatch-fix.yaml` | 8 | Service python-service corregido con targetPort: 8000 |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Objetivos de Aprendizaje

Al completar este laboratorio, seras capaz de:
- Diagnosticar pods en estados de error (CrashLoopBackOff, ImagePullBackOff, OOMKilled)
- Resolver problemas con init containers
- Troubleshoot liveness y readiness probes
- Identificar y corregir problemas con ConfigMaps y Secrets
- Usar kubectl logs, describe y exec efectivamente
- Aplicar metodologia sistematica de troubleshooting

---

## Escenarios

### Escenario 1: Pod en CrashLoopBackOff

**Situacion**: Un deployment de una aplicacion esta fallando constantemente.

**Tareas**:
1. Investigar por que el pod `webapp-crash` esta en CrashLoopBackOff
2. Identificar la causa raiz usando logs
3. Corregir el problema

**Setup**:
```bash
kubectl apply -f scenario-01-crashloop-setup.yaml
```

<details>
<summary>Pistas</summary>

1. Usa `kubectl get pods` para ver el estado
2. Usa `kubectl logs <pod-name>` para ver los logs actuales
3. Usa `kubectl logs <pod-name> --previous` para ver logs del crash anterior
4. El error estara en los argumentos del comando

</details>

<details>
<summary>Solucion</summary>

**Diagnostico**:
```bash
# Ver estado del pod
kubectl get pods -l app=webapp

# Ver logs (puede estar vacio si crashea inmediatamente)
kubectl logs -l app=webapp

# Ver logs del container anterior
kubectl logs -l app=webapp --previous

# Output esperado:
# nginx: [emerg] open() "/etc/nginx/nonexistent.conf" failed (2: No such file or directory)
```

**Causa raiz**: El archivo de configuracion `/etc/nginx/nonexistent.conf` no existe.

**Fix**:
```bash
# Opcion 1: Usar config por defecto mediante patch
kubectl patch deployment webapp-crash -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","command":["nginx"],"args":["-g","daemon off;"]}]}}}}'

# Opcion 2: Recrear sin args incorrectos
kubectl delete deployment webapp-crash
kubectl apply -f scenario-01-crashloop-fix.yaml
```

**Verificacion**:
```bash
kubectl get pods -l app=webapp
# Estado: Running

kubectl logs -l app=webapp
# Logs normales de nginx
```

</details>

---

### Escenario 2: ImagePullBackOff

**Situacion**: Un nuevo deployment no puede iniciar sus pods.

**Tareas**:
1. Diagnosticar por que `api-server` esta en ImagePullBackOff
2. Identificar que esta mal con la imagen
3. Corregir el problema

**Setup**:
```bash
kubectl apply -f scenario-02-imagepull-setup.yaml
```

<details>
<summary>Pistas</summary>

1. Usa `kubectl describe pod` para ver eventos
2. El error estara en la seccion "Events"
3. Verifica el tag de la imagen

</details>

<details>
<summary>Solucion</summary>

**Diagnostico**:
```bash
# Ver estado
kubectl get pods -l app=api

# Describir el pod para ver eventos
kubectl describe pod -l app=api

# Output esperado en Events:
# Failed to pull image "nginx:nonexistent-tag-12345": rpc error: code = Unknown desc = Error response from daemon: manifest for nginx:nonexistent-tag-12345 not found
```

**Causa raiz**: El tag `nonexistent-tag-12345` no existe en Docker Hub.

**Fix**:
```bash
# Actualizar a un tag valido
kubectl set image deployment/api-server api=nginx:1.21

# O editar directamente
kubectl edit deployment api-server
# Cambiar image: nginx:nonexistent-tag-12345 a nginx:1.21
```

**Verificacion**:
```bash
kubectl get pods -l app=api
# Estado: Running

kubectl describe pod -l app=api | grep "Successfully pulled"
```

</details>

---

### Escenario 3: OOMKilled - Out of Memory

**Situacion**: Una aplicacion se reinicia constantemente con exit code 137.

**Tareas**:
1. Identificar que el pod esta siendo killed por falta de memoria
2. Ver los resource limits actuales
3. Ajustar los limits apropiadamente

**Setup**:
```bash
kubectl apply -f scenario-03-oomkilled-setup.yaml
```

<details>
<summary>Pistas</summary>

1. Usa `kubectl describe pod` y busca "Last State"
2. Exit code 137 = SIGKILL por OOM
3. La app necesita 250M pero el limit es 100Mi

</details>

<details>
<summary>Solucion</summary>

**Diagnostico**:
```bash
# Ver estado
kubectl get pod memory-hog

# Describir para ver Last State
kubectl describe pod memory-hog | grep -A 10 "Last State"

# Output esperado:
#   Last State:     Terminated
#     Reason:       OOMKilled
#     Exit Code:    137

# Ver limites actuales
kubectl get pod memory-hog -o jsonpath='{.spec.containers[0].resources.limits.memory}'
# Output: 100Mi
```

**Causa raiz**: El container necesita 250M de memoria pero el limit es solo 100Mi.

**Fix**:
```bash
# Recrear con limites apropiados
kubectl delete pod memory-hog
kubectl apply -f scenario-03-oomkilled-fix.yaml
```

**Verificacion**:
```bash
kubectl get pod memory-hog
# Estado: Running

# Verificar que no se reinicia
watch kubectl get pod memory-hog
```

</details>

---

### Escenario 4: Init Container Failure

**Situacion**: Un pod esta stuck en Init:0/1 y no puede iniciar.

**Tareas**:
1. Identificar que init container esta fallando
2. Diagnosticar por que esta fallando
3. Resolver el problema

**Setup**:
```bash
kubectl apply -f scenario-04-initcontainer-setup.yaml
```

<details>
<summary>Pistas</summary>

1. El pod esta esperando por un servicio que no existe
2. Usa `kubectl describe pod` para ver init containers
3. Usa `kubectl logs <pod> -c <init-container-name>` para ver logs del init container

</details>

<details>
<summary>Solucion</summary>

**Diagnostico**:
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

**Causa raiz**: El servicio `postgres-service` no existe.

**Fix - Opcion 1: Crear el servicio**:
```bash
# Crear un pod de postgres
kubectl run postgres --image=postgres:13 --env="POSTGRES_PASSWORD=password"

# Crear el servicio
kubectl expose pod postgres --port=5432 --name=postgres-service

# Ahora el init container deberia completarse
kubectl get pod backend-app -w
```

**Fix - Opcion 2: Remover el init container**:
```bash
kubectl delete pod backend-app
kubectl apply -f scenario-04-initcontainer-fix.yaml
```

**Verificacion**:
```bash
kubectl get pod backend-app
# Estado: Running
```

</details>

---

### Escenario 5: Liveness Probe Failure

**Situacion**: Un pod se reinicia cada ~30 segundos sin razon aparente.

**Tareas**:
1. Identificar que el liveness probe esta fallando
2. Entender por que esta fallando
3. Ajustar el probe apropiadamente

**Setup**:
```bash
kubectl apply -f scenario-05-liveness-setup.yaml
```

<details>
<summary>Pistas</summary>

1. El pod se reinicia por liveness probe failure
2. nginx no tiene endpoint `/healthz` por defecto
3. Usa `/` en lugar de `/healthz` o aumenta failureThreshold

</details>

<details>
<summary>Solucion</summary>

**Diagnostico**:
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

**Causa raiz**: El liveness probe busca `/healthz` que no existe en nginx default. nginx retorna 404.

**Fix - Opcion 1: Usar path valido**:
```bash
kubectl delete pod web-server
kubectl apply -f scenario-05-liveness-fix.yaml
```

**Fix - Opcion 2: Ajustar tolerancia** (alternativa, mantener inline):
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
      initialDelaySeconds: 30
      periodSeconds: 15
      failureThreshold: 3
      timeoutSeconds: 5
EOF
```

**Verificacion**:
```bash
# Ver que no se reinicia
watch kubectl get pod web-server
# RESTARTS debe permanecer en 0
```

</details>

---

### Escenario 6: Missing ConfigMap

**Situacion**: Un deployment no puede crear pods debido a un ConfigMap faltante.

**Tareas**:
1. Identificar que el ConfigMap no existe
2. Crear el ConfigMap necesario
3. Verificar que el pod inicia correctamente

**Setup**:
```bash
kubectl apply -f scenario-06-configmap-setup.yaml
```

<details>
<summary>Pistas</summary>

1. El pod estara en CreateContainerConfigError
2. Usa `kubectl describe pod` para ver el error
3. Necesitas crear el ConfigMap `app-settings`

</details>

<details>
<summary>Solucion</summary>

**Diagnostico**:
```bash
# Ver estado
kubectl get pods -l app=config-app
# STATUS: CreateContainerConfigError

# Describir para ver error
kubectl describe pod -l app=config-app
# Output en Events:
# Error: configmap "app-settings" not found
```

**Causa raiz**: El ConfigMap `app-settings` no existe.

**Fix**:
```bash
# Opcion 1: Crear el ConfigMap con kubectl
kubectl create configmap app-settings \
  --from-literal=APP_ENV=production \
  --from-literal=LOG_LEVEL=info \
  --from-literal=MAX_CONNECTIONS=100

# Opcion 2: Crear con YAML declarativo
kubectl apply -f scenario-06-configmap-fix.yaml
```

**Verificacion**:
```bash
# Ver que el pod ahora esta Running
kubectl get pods -l app=config-app

# Verificar variables de entorno
kubectl exec -l app=config-app -- env | grep -E 'APP_ENV|LOG_LEVEL|MAX_CONNECTIONS'
```

</details>

---

### Escenario 7: Readiness Probe Never Ready

**Situacion**: Un pod esta Running pero no recibe trafico del Service.

**Tareas**:
1. Identificar que el pod no esta Ready (0/1)
2. Diagnosticar el readiness probe
3. Corregir el problema

**Setup**:
```bash
kubectl apply -f scenario-07-readiness-setup.yaml
```

<details>
<summary>Pistas</summary>

1. El pod esta Running pero READY es 0/1
2. El readiness probe tiene dos problemas: path y port
3. nginx no tiene `/ready` y usa puerto 80, no 8080

</details>

<details>
<summary>Solucion</summary>

**Diagnostico**:
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
# ENDPOINTS: <none>  <- Sin endpoints porque pod no esta ready
```

**Causa raiz**:
- El readiness probe busca puerto 8080 pero nginx usa 80
- El path `/ready` no existe

**Fix**:
```bash
kubectl delete pod api-pod
kubectl apply -f scenario-07-readiness-fix.yaml
```

**Verificacion**:
```bash
# Ver que ahora esta Ready
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

**Situacion**: El Service esta configurado pero no puede conectarse a los pods.

**Tareas**:
1. Identificar el port mismatch
2. Corregir la configuracion
3. Verificar conectividad

**Setup**:
```bash
kubectl apply -f scenario-08-portmismatch-setup.yaml
```

<details>
<summary>Pistas</summary>

1. El servicio apunta al puerto 80
2. La aplicacion escucha en el puerto 8000
3. targetPort debe ser 8000

</details>

<details>
<summary>Solucion</summary>

**Diagnostico**:
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
# Output: 80  <- MISMATCH!
```

**Causa raiz**: Service targetPort es 80 pero el container escucha en 8000.

**Fix**:
```bash
# Patch el servicio directamente
kubectl patch svc python-service -p '{"spec":{"ports":[{"port":80,"targetPort":8000}]}}'

# O recrear el servicio
kubectl delete svc python-service
kubectl apply -f scenario-08-portmismatch-fix.yaml
```

**Verificacion**:
```bash
kubectl run test --image=busybox:1.28 -it --rm -- wget -O- http://python-service
# Ahora debe funcionar y mostrar el HTML
```

</details>

---

## Limpieza

```bash
# Ejecutar el script de limpieza
bash cleanup.sh

# O limpiar manualmente
kubectl delete deployment webapp-crash api-server config-app
kubectl delete pod memory-hog backend-app web-server api-pod python-app
kubectl delete svc api-service python-service postgres-service
kubectl delete pod postgres
kubectl delete configmap app-settings
```

---

## Evaluacion

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

## Puntos Clave para el Examen CKA

1. **Siempre usa `kubectl describe pod`** - Los Events son criticos
2. **Logs anteriores con `--previous`** - Para ver crashes
3. **Exit Code 137 = OOMKilled** - Aumentar memory limits
4. **Init containers** - Diagnosticar con logs especificos del container
5. **Probes** - Verificar path, port, y timing
6. **ConfigMaps/Secrets** - CreateContainerConfigError indica faltantes
7. **Port mismatch** - Verificar containerPort vs targetPort
8. **Ready vs Running** - Pod puede estar Running pero no Ready

---

**Tiempo objetivo**: Resolver cada escenario en 5-8 minutos
**Siguiente**: Lab 02 - Control Plane & Nodes
