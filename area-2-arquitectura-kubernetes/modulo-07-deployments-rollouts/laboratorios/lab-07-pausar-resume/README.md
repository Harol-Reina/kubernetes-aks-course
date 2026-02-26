# Laboratorio 07: Troubleshooting de Deployments

**Duracion estimada**: 55 minutos
**Dificultad**: Avanzado
**Objetivo**: Diagnosticar y resolver los patrones de fallo mas comunes en Deployments de Kubernetes

---

## Introduccion: Patrones de Fallo en Deployments

Los Deployments en Kubernetes pueden fallar de formas predecibles. Conocer estos patrones
y el enfoque sistematico para diagnosticarlos es una habilidad fundamental para el examen
CKAD y para el trabajo real con clusters en produccion.

### Patrones de fallo comunes

| Estado visible | Causa tipica | Primer comando de diagnostico |
|---------------|--------------|-------------------------------|
| `ImagePullBackOff` / `ErrImagePull` | Imagen o tag inexistente, registry privado sin credenciales | `kubectl describe pod <nombre>` |
| `Running` pero `0/1 Ready` | Readiness probe falla (path incorrecto, puerto incorrecto, aplicacion lenta) | `kubectl describe pod <nombre> \| grep -A 10 Readiness` |
| `CrashLoopBackOff` (exit code 137) | OOMKilled: el contenedor supera el limite de memoria | `kubectl get pod <nombre> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'` |
| `CrashLoopBackOff` (Permission denied) | SecurityContext restrictivo sin volumenes para escritura | `kubectl logs <pod-nombre>` |
| Rollout tarda demasiado | `minReadySeconds` alto, `initialDelaySeconds` alto, `maxUnavailable: 0` | `kubectl rollout status deployment/<nombre>` |
| Error al aplicar manifiesto | Selector no coincide con labels del template | El error aparece directamente en `kubectl apply` |

### Enfoque sistematico de diagnostico

El flujo recomendado para cualquier problema en un Deployment:

```
1. kubectl get deployment <nombre>          → Estado general (READY, UP-TO-DATE, AVAILABLE)
2. kubectl get pods -l app=<label>          → Estado de los Pods individuales
3. kubectl describe pod <pod-nombre>        → Eventos y detalles del fallo
4. kubectl logs <pod-nombre>               → Mensajes de la aplicacion
5. kubectl logs <pod-nombre> --previous    → Logs del intento anterior (CrashLoop)
6. kubectl get events --sort-by='.lastTimestamp' → Historial de eventos del namespace
```

---

## Archivos YAML de este laboratorio

| Archivo | Ejercicio | Problema que demuestra |
|---------|-----------|----------------------|
| `broken-image.yaml` | Ejercicio 1 | ImagePullBackOff por imagen con tag inexistente |
| `broken-readiness.yaml` | Ejercicio 2 | Pods Running pero NOT Ready por readiness probe con path incorrecto |
| `oom-deployment.yaml` | Ejercicio 3 | OOMKilled / CrashLoopBackOff por limite de memoria insuficiente |
| `stuck-rollout.yaml` | Ejercicio 4 | Rollout muy lento por minReadySeconds y initialDelaySeconds altos |
| `selector-mismatch.yaml` | Ejercicio 5 | Fallo de validacion: selector no coincide con template labels |
| `selector-mismatch-fixed.yaml` | Ejercicio 5 | Version corregida del selector mismatch |
| `permission-issue.yaml` | Ejercicio 6 | CrashLoopBackOff por readOnlyRootFilesystem sin volumenes de escritura |
| `permission-issue-fixed.yaml` | Ejercicio 6 | Version corregida con emptyDir para paths de escritura |

---

## Prerequisitos

Ver [SETUP.md](./SETUP.md) para la verificacion completa del entorno.

```bash
# Crear namespace y configurar contexto
kubectl create namespace lab-troubleshooting
kubectl config set-context --current --namespace=lab-troubleshooting

# Verificar
kubectl get ns lab-troubleshooting
```

---

## Ejercicio 1: Deployment Stuck - Pods No Inician (ImagePullBackOff)

### Paso 1: Revisar y aplicar el manifiesto

```bash
# Ver el contenido del manifiesto antes de aplicar
cat broken-image.yaml
```

**Detalle clave del archivo**:
```yaml
containers:
- name: app
  image: nginx:nonexistent-tag-12345   # Tag que no existe en Docker Hub
```

```bash
# Aplicar el manifiesto
kubectl apply -f broken-image.yaml
```

**Output esperado**:
```
deployment.apps/broken-image-app created
```

```bash
# Observar el estado de los Pods
watch kubectl get pods -l app=broken-app
```

**Output esperado tras unos segundos**:
```
NAME                               READY   STATUS             RESTARTS   AGE
broken-image-app-7d4b8c9f6-8xk2p   0/1     ImagePullBackOff   0          30s
broken-image-app-7d4b8c9f6-j9qrs   0/1     ErrImagePull       0          30s
broken-image-app-7d4b8c9f6-m3npt   0/1     ImagePullBackOff   0          30s
```

### Paso 2: Diagnosticar el problema

```bash
# Estado del Deployment
kubectl get deployment broken-image-app
```

**Output esperado**:
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
broken-image-app   0/3     3            0           1m
```

```bash
# Describir un Pod para ver el error exacto
POD_NAME=$(kubectl get pods -l app=broken-app -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME
```

**Seccion relevante del output**:
```
Events:
  Warning  Failed     30s   kubelet  Failed to pull image "nginx:nonexistent-tag-12345":
                                     manifest for nginx:nonexistent-tag-12345 not found
  Warning  Failed     30s   kubelet  Error: ErrImagePull
  Warning  BackOff    15s   kubelet  Back-off pulling image "nginx:nonexistent-tag-12345"
```

```bash
# Ver eventos del namespace filtrando por errores de imagen
kubectl get events --sort-by='.lastTimestamp' | grep -i "error\|failed\|pull"
```

### Paso 3: Solucionar el problema

```bash
# Actualizar a una imagen valida
kubectl set image deployment/broken-image-app app=nginx:1.21-alpine

# Verificar que el rollout progresa
kubectl rollout status deployment/broken-image-app
```

**Output esperado**:
```
Waiting for deployment "broken-image-app" rollout to finish: 0 of 3 updated replicas are available...
deployment "broken-image-app" successfully rolled out
```

```bash
# Confirmar que los Pods estan Ready
kubectl get pods -l app=broken-app
```

**Output esperado**:
```
NAME                               READY   STATUS    RESTARTS   AGE
broken-image-app-5c8d7b4f9-2rwtx   1/1     Running   0          45s
broken-image-app-5c8d7b4f9-4pqkm   1/1     Running   0          40s
broken-image-app-5c8d7b4f9-9xvnj   1/1     Running   0          35s
```

---

## Ejercicio 2: Fallo en Readiness Probe

### Paso 1: Revisar y aplicar el manifiesto

```bash
# Ver el contenido del manifiesto
cat broken-readiness.yaml
```

**Detalle clave del archivo**:
```yaml
readinessProbe:
  httpGet:
    path: /nonexistent-path   # Esta ruta no existe → nginx devuelve 404 → probe falla
    port: 80
```

```bash
# Aplicar el manifiesto
kubectl apply -f broken-readiness.yaml

# Observar el estado de los Pods
watch kubectl get pods -l app=readiness-app
```

**Output esperado tras unos segundos**:
```
NAME                                  READY   STATUS    RESTARTS   AGE
broken-readiness-app-6b9c4d7f8-3kqpz   0/1     Running   0          30s
broken-readiness-app-6b9c4d7f8-7mrxt   0/1     Running   0          30s
broken-readiness-app-6b9c4d7f8-9wvps   0/1     Running   0          30s
```

Los Pods estan `Running` pero `0/1 Ready`. La aplicacion funciona pero no acepta trafico.

### Paso 2: Diagnosticar readiness probe failure

```bash
# Ver que el Deployment no tiene replicas disponibles
kubectl get deployment broken-readiness-app
```

**Output esperado**:
```
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
broken-readiness-app   0/3     3            0           1m
```

```bash
# Describir un Pod y buscar la seccion Readiness
POD_NAME=$(kubectl get pods -l app=readiness-app -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME | grep -A 10 Readiness
```

**Output esperado**:
```
    Readiness:  http-get http://:80/nonexistent-path delay=5s timeout=1s period=5s #success=1 #failure=3
```

```bash
# Ver los eventos del Pod para confirmar el fallo
kubectl get events --field-selector involvedObject.name=$POD_NAME
```

**Output esperado**:
```
Warning  Unhealthy   5s    kubelet  Readiness probe failed:
                                    HTTP probe failed with statuscode: 404
```

```bash
# Probar el endpoint manualmente para confirmar
kubectl exec $POD_NAME -- wget -O- http://localhost/nonexistent-path 2>&1 | head -5
```

**Output esperado**:
```
wget: server returned error: HTTP/1.1 404 Not Found
```

### Paso 3: Solucionar readiness probe

```bash
# Actualizar el path de la readiness probe a uno valido
kubectl patch deployment broken-readiness-app -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","readinessProbe":{"httpGet":{"path":"/"}}}]}}}}'

# Verificar que el rollout se completa
kubectl rollout status deployment/broken-readiness-app

# Confirmar que los Pods estan Ready
kubectl get pods -l app=readiness-app
```

**Output esperado**:
```
NAME                                  READY   STATUS    RESTARTS   AGE
broken-readiness-app-7d4c8e9f2-2xpkq   1/1     Running   0          30s
broken-readiness-app-7d4c8e9f2-5mrqt   1/1     Running   0          25s
broken-readiness-app-7d4c8e9f2-8wvps   1/1     Running   0          20s
```

---

## Ejercicio 3: Recursos Insuficientes (OOMKilled / CrashLoopBackOff)

### Paso 1: Revisar y aplicar el manifiesto

```bash
# Ver el contenido del manifiesto
cat oom-deployment.yaml
```

**Detalle clave del archivo**:
```yaml
command: ["stress"]
args:
- "--vm-bytes"
- "150M"        # Intenta usar 150MB de memoria
resources:
  limits:
    memory: "100Mi"   # Limite insuficiente → OOMKilled cuando supere 100Mi
```

```bash
# Aplicar el manifiesto
kubectl apply -f oom-deployment.yaml

# Observar el estado de los Pods
watch kubectl get pods -l app=oom-app
```

**Output esperado tras unos segundos**:
```
NAME                     READY   STATUS             RESTARTS   AGE
oom-app-5b8c7d9f4-4kqrp   0/1     OOMKilled          0          10s
oom-app-5b8c7d9f4-7mxpt   0/1     CrashLoopBackOff   2          45s
```

### Paso 2: Diagnosticar OOMKilled

```bash
# Describir un Pod y buscar "OOMKilled"
POD_NAME=$(kubectl get pods -l app=oom-app -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME
```

**Seccion relevante del output**:
```
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      ...
      Finished:     ...
```

```bash
# Obtener directamente la razon del ultimo estado
kubectl get pod $POD_NAME -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'
```

**Output esperado**:
```
OOMKilled
```

```bash
# Ver logs del contenedor anterior (puede estar vacio)
kubectl logs $POD_NAME --previous
```

### Paso 3: Solucionar limites de recursos

```bash
# Aumentar el limite de memoria para que el contenedor pueda funcionar
kubectl set resources deployment oom-app --limits=memory=200Mi --requests=memory=100Mi

# Verificar el rollout
kubectl rollout status deployment/oom-app

# Confirmar que los Pods estan estables
kubectl get pods -l app=oom-app
```

**Output esperado**:
```
NAME                   READY   STATUS    RESTARTS   AGE
oom-app-7c9d8b5f2-3qkrx   1/1     Running   0          30s
oom-app-7c9d8b5f2-8wvpm   1/1     Running   0          25s
```

---

## Ejercicio 4: Rollout Stuck - Deployment No Progresa

### Paso 1: Revisar y aplicar el manifiesto

```bash
# Ver el contenido del manifiesto
cat stuck-rollout.yaml
```

**Detalles clave del archivo**:
```yaml
minReadySeconds: 30   # Pod debe estar Ready 30s antes de considerarse "disponible"
strategy:
  rollingUpdate:
    maxUnavailable: 0   # No tolera downtime → rollout muy conservador
readinessProbe:
  initialDelaySeconds: 60   # Espera 60s antes de la primera probe
```

```bash
# Aplicar la version inicial y esperar a que este lista
kubectl apply -f stuck-rollout.yaml
kubectl rollout status deployment/stuck-rollout-app --timeout=5m

# Activar un rolling update para observar el rollout lento
kubectl set image deployment/stuck-rollout-app app=nginx:1.22-alpine

# Observar el progreso (muy lento)
watch kubectl get pods -l app=stuck-app
```

**Output esperado durante el rollout**:
```
NAME                              READY   STATUS    RESTARTS   AGE
stuck-rollout-app-7d4b9c8f2-2qkrx   1/1     Running   0          3m
stuck-rollout-app-7d4b9c8f2-5mrpt   0/1     Running   0          45s   <- nuevo, esperando probe
stuck-rollout-app-7d4b9c8f2-8wvps   1/1     Running   0          3m
...
```

### Paso 2: Diagnosticar rollout stuck

```bash
# Ver el estado del rollout
kubectl rollout status deployment/stuck-rollout-app
```

**Output esperado**:
```
Waiting for deployment "stuck-rollout-app" rollout to finish:
1 out of 5 new replicas have been updated...
```

```bash
# Ver los ReplicaSets activos (deberia haber 2: viejo y nuevo)
kubectl get rs -l app=stuck-app
```

**Output esperado**:
```
NAME                           DESIRED   CURRENT   READY   AGE
stuck-rollout-app-7d4b9c8f2    4         4         4       5m
stuck-rollout-app-9f2c8d4b6    1         1         0       1m
```

```bash
# Ver condiciones del Deployment
kubectl get deployment stuck-rollout-app -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\t"}{.message}{"\n"}{end}'
```

**Output esperado**:
```
Available    True    Minimum availability maintained
Progressing  True    ReplicaSet "stuck-rollout-app-9f2c8d4b6" is progressing.
```

### Paso 3: Soluciones para rollout lento

```bash
# Opcion 1: Reducir tiempos de espera con patch
kubectl patch deployment stuck-rollout-app -p \
  '{"spec":{"minReadySeconds":5,"template":{"spec":{"containers":[{"name":"app","readinessProbe":{"initialDelaySeconds":10}}]}}}}'

# Opcion 2: Pausar el rollout, ajustar y reanudar
kubectl rollout pause deployment/stuck-rollout-app
kubectl edit deployment stuck-rollout-app  # Ajustar minReadySeconds e initialDelaySeconds
kubectl rollout resume deployment/stuck-rollout-app

# Opcion 3: Rollback si no es viable esperar
kubectl rollout undo deployment/stuck-rollout-app

# Verificar estado final
kubectl rollout status deployment/stuck-rollout-app
```

---

## Ejercicio 5: Selector Mismatch

### Paso 1: Revisar el manifiesto con error

```bash
# Ver el contenido del manifiesto roto
cat selector-mismatch.yaml
```

**Detalle del problema en el archivo**:
```yaml
selector:
  matchLabels:
    app: my-app
    version: v1      # El selector exige este label en todos los Pods
template:
  metadata:
    labels:
      app: my-app
      # FALTA: version: v1  → El selector no coincide con los labels del template
```

```bash
# Intentar aplicar el manifiesto roto - este comando FALLARA intencionalmente
kubectl apply -f selector-mismatch.yaml
```

**Error esperado**:
```
The Deployment "selector-mismatch-app" is invalid:
spec.template.metadata.labels: Invalid value: map[string]string{"app":"my-app"}:
`selector` does not match template `labels`
```

Kubernetes valida la coherencia entre el selector y los labels del template antes de
crear cualquier recurso. No se crea ningun Pod.

### Paso 2: Revisar y aplicar la version corregida

```bash
# Ver el contenido del manifiesto corregido
cat selector-mismatch-fixed.yaml
```

**Detalle de la correccion en el archivo**:
```yaml
template:
  metadata:
    labels:
      app: my-app
      version: v1      # Label agregado para que coincida con el selector
```

```bash
# Aplicar la version corregida
kubectl apply -f selector-mismatch-fixed.yaml

# Verificar que el Deployment se crea correctamente
kubectl get deployment selector-mismatch-app
```

**Output esperado**:
```
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
selector-mismatch-app   3/3     3            3           30s
```

```bash
# Verificar que los Pods tienen los labels correctos
kubectl get pods -l app=my-app --show-labels
```

**Output esperado**:
```
NAME                                    READY   STATUS    LABELS
selector-mismatch-app-4c7d8b9f2-3kqrx   1/1     Running   app=my-app,version=v1
selector-mismatch-app-4c7d8b9f2-7mrpt   1/1     Running   app=my-app,version=v1
selector-mismatch-app-4c7d8b9f2-9wvps   1/1     Running   app=my-app,version=v1
```

---

## Ejercicio 6: Problema de Permisos (SecurityContext)

### Paso 1: Revisar y aplicar el manifiesto con error

```bash
# Ver el contenido del manifiesto roto
cat permission-issue.yaml
```

**Detalle del problema en el archivo**:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000    # Usuario sin privilegios
containers:
- name: nginx
  securityContext:
    readOnlyRootFilesystem: true   # nginx necesita escribir → causa Permission denied
  # FALTA: volumeMounts para /var/cache/nginx, /var/run, /tmp
```

```bash
# Aplicar el manifiesto
kubectl apply -f permission-issue.yaml

# Observar el estado de los Pods
watch kubectl get pods -l app=permission-app
```

**Output esperado tras unos segundos**:
```
NAME                          READY   STATUS             RESTARTS   AGE
permission-app-6b9c4d7f8-2qkrx   0/1     CrashLoopBackOff   2          45s
permission-app-6b9c4d7f8-5mrpt   0/1     CrashLoopBackOff   1          45s
```

### Paso 2: Diagnosticar problema de permisos

```bash
# Ver los logs del Pod para identificar el error
POD_NAME=$(kubectl get pods -l app=permission-app -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME
```

**Output esperado**:
```
/docker-entrypoint.sh: 13: cannot create /var/run/nginx.pid: Permission denied
```

```bash
# Ver logs del contenedor anterior si ya reinicio
kubectl logs $POD_NAME --previous

# Verificar el security context aplicado
kubectl get pod $POD_NAME -o jsonpath='{.spec.securityContext}'
kubectl get pod $POD_NAME -o jsonpath='{.spec.containers[0].securityContext}'
```

**Output esperado del segundo comando**:
```
{"readOnlyRootFilesystem":true}
```

### Paso 3: Revisar y aplicar la version corregida

```bash
# Ver el contenido del manifiesto corregido
cat permission-issue-fixed.yaml
```

**Detalle de la correccion en el archivo**:
```yaml
volumeMounts:
- name: cache
  mountPath: /var/cache/nginx   # nginx escribe archivos de cache aqui
- name: run
  mountPath: /var/run           # nginx escribe el PID y sockets aqui
- name: tmp
  mountPath: /tmp               # Archivos temporales generales
volumes:
- name: cache
  emptyDir: {}
- name: run
  emptyDir: {}
- name: tmp
  emptyDir: {}
```

```bash
# Aplicar la version corregida
kubectl apply -f permission-issue-fixed.yaml

# Verificar el rollout
kubectl rollout status deployment/permission-app

# Confirmar que los Pods estan Ready
kubectl get pods -l app=permission-app
```

**Output esperado**:
```
NAME                             READY   STATUS    RESTARTS   AGE
permission-app-9c7d8b4f2-3kqrx   1/1     Running   0          30s
permission-app-9c7d8b4f2-7mrpt   1/1     Running   0          25s
```

---

## Ejercicio 7: Script de Troubleshooting Automatizado

El script `diagnose-deployment.sh` ya existe en este directorio. Hace lo siguiente:
- Muestra el estado del Deployment, ReplicaSets y Pods
- Identifica Pods con problemas
- Muestra los eventos recientes del Deployment
- Describe el Deployment con detalle
- Extrae los logs del Pod problematico
- Muestra las condiciones y el rollout status
- Sugiere comandos utiles para continuar el diagnostico

```bash
# Hacer ejecutable el script
chmod +x diagnose-deployment.sh

# Usar con los Deployments creados en los ejercicios anteriores
./diagnose-deployment.sh broken-image-app lab-troubleshooting
./diagnose-deployment.sh broken-readiness-app lab-troubleshooting
./diagnose-deployment.sh oom-app lab-troubleshooting
```

**Output esperado** (extracto del primer comando):
```
DIAGNOSTICO DE DEPLOYMENT: broken-image-app
Namespace: lab-troubleshooting
================================================

ESTADO DEL DEPLOYMENT:
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
broken-image-app   0/3     3            0           5m

PODS CON PROBLEMAS:
NAME                               READY   STATUS             RESTARTS
broken-image-app-7d4b8c9f6-8xk2p   0/1     ImagePullBackOff   0
...
```

---

## Ejercicio 8: Troubleshooting Checklist

Este checklist sirve como referencia rapida durante el diagnostico de cualquier Deployment:

### 1. Verificacion basica

```bash
kubectl get deployment <nombre>                          # Estado general
kubectl get pods -l app=<label>                          # Estado de los Pods
kubectl get events --sort-by='.lastTimestamp'            # Eventos recientes
```

### 2. Pods No Inician (Pending / ImagePullBackOff)

```bash
# Verificar que la imagen existe
kubectl describe pod <pod-nombre> | grep -A 5 Image

# Verificar pull secrets si la imagen es privada
kubectl get secrets

# Verificar recursos disponibles en los nodos
kubectl top nodes

# Verificar nodeSelector o affinity
kubectl get pod <pod-nombre> -o yaml | grep -A 5 nodeSelector
```

### 3. Pods en CrashLoopBackOff

```bash
# Ver logs del contenedor actual
kubectl logs <pod-nombre>

# Ver logs del intento anterior
kubectl logs <pod-nombre> --previous

# Ver exit code para identificar OOMKilled (137) u otros errores
kubectl get pod <pod-nombre> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'

# Verificar OOMKilled en describe
kubectl describe pod <pod-nombre> | grep OOMKilled

# Ver uso de recursos si el Pod esta corriendo momentaneamente
kubectl top pod <pod-nombre>
```

### 4. Pods Running pero NOT Ready

```bash
# Ver configuracion de la readiness probe
kubectl describe pod <pod-nombre> | grep -A 10 Readiness

# Probar el endpoint de readiness manualmente
kubectl exec <pod-nombre> -- wget -O- http://localhost:<puerto><path>

# Ver eventos de readiness
kubectl get events --field-selector involvedObject.name=<pod-nombre>
```

### 5. Rollout Stuck o Muy Lento

```bash
# Ver progreso del rollout
kubectl rollout status deployment/<nombre>

# Ver los dos ReplicaSets (viejo y nuevo)
kubectl get rs -l app=<label>

# Ver minReadySeconds configurado
kubectl get deployment <nombre> -o jsonpath='{.spec.minReadySeconds}'

# Ver la estrategia de rollout
kubectl get deployment <nombre> -o jsonpath='{.spec.strategy}'

# Pausar el rollout para detener el progreso sin hacer rollback
kubectl rollout pause deployment/<nombre>
```

### 6. Problemas de Configuracion

```bash
# Verificar que selector y template labels coinciden
kubectl get deployment <nombre> -o jsonpath='{.spec.selector}'
kubectl get pods -l app=<label> --show-labels

# Verificar variables de entorno en el contenedor
kubectl exec <pod-nombre> -- env

# Ver volumenes montados
kubectl describe pod <pod-nombre> | grep -A 5 Mounts
```

### 7. Problemas de Permisos (SecurityContext)

```bash
# Ver el security context del Pod
kubectl get pod <pod-nombre> -o jsonpath='{.spec.securityContext}'
kubectl get pod <pod-nombre> -o jsonpath='{.spec.containers[0].securityContext}'

# Los logs de Permission denied aparecen aqui
kubectl logs <pod-nombre>
kubectl logs <pod-nombre> --previous
```

### 8. Comandos de emergencia

```bash
# Rollback a la version anterior
kubectl rollout undo deployment/<nombre>

# Rollback a una revision especifica
kubectl rollout undo deployment/<nombre> --to-revision=2

# Escalar a 0 para detener el trafico de inmediato
kubectl scale deployment <nombre> --replicas=0

# Reiniciar todos los Pods del Deployment
kubectl rollout restart deployment/<nombre>
```

---

## Limpieza

```bash
# Usar el script de limpieza incluido
chmod +x cleanup.sh
./cleanup.sh
```

El script elimina todos los Deployments del laboratorio, el namespace `lab-troubleshooting`
y restaura el contexto a `default`.

---

## Checklist de Completitud

- [ ] Diagnosticar y resolver ImagePullBackOff (Ejercicio 1)
- [ ] Diagnosticar y resolver Readiness probe failures (Ejercicio 2)
- [ ] Diagnosticar y resolver OOMKilled / CrashLoopBackOff (Ejercicio 3)
- [ ] Diagnosticar rollout stuck y aplicar soluciones (Ejercicio 4)
- [ ] Identificar error de selector mismatch al aplicar manifiesto (Ejercicio 5)
- [ ] Aplicar la version corregida del selector mismatch (Ejercicio 5)
- [ ] Diagnosticar CrashLoopBackOff por problemas de permisos (Ejercicio 6)
- [ ] Aplicar la version corregida con emptyDir volumes (Ejercicio 6)
- [ ] Usar el script automatizado de diagnostico (Ejercicio 7)
- [ ] Repasar y practicar el troubleshooting checklist (Ejercicio 8)

---

## Resumen

En este laboratorio practicaste el diagnostico y resolucion de los patrones de fallo
mas frecuentes en Deployments de Kubernetes:

- Identificar ImagePullBackOff y corregir referencias de imagen incorrectas
- Resolver fallos de readiness probe con path o puerto equivocado
- Diagnosticar OOMKilled por limites de memoria insuficientes (exit code 137)
- Analizar rollouts extremadamente lentos por configuracion conservadora
- Reconocer errores de selector mismatch que impiden crear el Deployment
- Solucionar CrashLoopBackOff causado por readOnlyRootFilesystem sin volumenes

Estas habilidades son evaluadas directamente en el examen CKAD y son esenciales
para operar clusters en produccion.

**Siguiente**: Lab 08 - Proyecto Integrador
