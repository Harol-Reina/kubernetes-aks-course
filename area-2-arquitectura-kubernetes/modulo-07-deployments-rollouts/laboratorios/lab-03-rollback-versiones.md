# Laboratorio 3: Rollback y Gestión de Versiones

## 📋 Información del Laboratorio

- **Duración estimada**: 60 minutos
- **Nivel**: Avanzado
- **Requisitos**: Laboratorios 1 y 2 completados
- **Namespace**: `lab-rollback`

## 🎯 Objetivos

Al completar este laboratorio, serás capaz de:

1. Gestionar historial de revisiones con `revisionHistoryLimit`
2. Visualizar y explorar versiones anteriores
3. Realizar rollback a versiones específicas
4. Detectar y recuperarse de despliegues fallidos
5. Usar `change-cause` annotations efectivamente
6. Implementar estrategias de rollback en producción
7. Combinar pause/resume con rollback

## 📚 Prerrequisitos

- Laboratorios 1 y 2 completados
- Conocimiento de rolling updates
- Cluster de Kubernetes funcional

## 🔧 Preparación del Entorno

```bash
# Crear namespace
kubectl create namespace lab-rollback
kubectl config set-context --current --namespace=lab-rollback

# Verificar
kubectl get namespaces | grep lab-rollback
```

---

## Ejercicio 1: Historial de Revisiones (15 min)

### Paso 1.1: Crear Deployment con historial

Crea `version-history.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: version-history
  annotations:
    kubernetes.io/change-cause: "v1.0.0 - Release inicial con nginx 1.19"
spec:
  replicas: 4
  revisionHistoryLimit: 5  # Mantener 5 versiones anteriores
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: version-history
  template:
    metadata:
      labels:
        app: version-history
        version: "v1.0.0"
    spec:
      containers:
      - name: nginx
        image: nginx:1.19-alpine
        ports:
        - containerPort: 80
        env:
        - name: APP_VERSION
          value: "v1.0.0"
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 2
```

```bash
kubectl apply -f version-history.yaml
kubectl rollout status deployment version-history
```

### Paso 1.2: Crear múltiples versiones

```bash
# Versión 1.1.0
kubectl set image deployment/version-history nginx=nginx:1.20-alpine
kubectl set env deployment/version-history APP_VERSION=v1.1.0
kubectl annotate deployment version-history \
  kubernetes.io/change-cause="v1.1.0 - Actualización menor nginx 1.20" --overwrite
kubectl rollout status deployment version-history

# Versión 1.2.0
kubectl set image deployment/version-history nginx=nginx:1.21-alpine
kubectl set env deployment/version-history APP_VERSION=v1.2.0
kubectl annotate deployment version-history \
  kubernetes.io/change-cause="v1.2.0 - Actualización menor nginx 1.21" --overwrite
kubectl rollout status deployment version-history

# Versión 1.3.0
kubectl set image deployment/version-history nginx=nginx:1.22-alpine
kubectl set env deployment/version-history APP_VERSION=v1.3.0
kubectl annotate deployment version-history \
  kubernetes.io/change-cause="v1.3.0 - Actualización menor nginx 1.22" --overwrite
kubectl rollout status deployment version-history

# Versión 2.0.0 (major)
kubectl set image deployment/version-history nginx=nginx:1.23-alpine
kubectl set env deployment/version-history APP_VERSION=v2.0.0
kubectl annotate deployment version-history \
  kubernetes.io/change-cause="v2.0.0 - Major release nginx 1.23" --overwrite
kubectl rollout status deployment version-history
```

### Paso 1.3: Ver historial completo

```bash
kubectl rollout history deployment version-history
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
1         v1.0.0 - Release inicial con nginx 1.19
2         v1.1.0 - Actualización menor nginx 1.20
3         v1.2.0 - Actualización menor nginx 1.21
4         v1.3.0 - Actualización menor nginx 1.22
5         v2.0.0 - Major release nginx 1.23
```

### Paso 1.4: Ver detalles de revisión específica

```bash
# Ver detalles de revisión 3
kubectl rollout history deployment version-history --revision=3
```

**Output esperado**:
```
deployment.apps/version-history with revision #3
Pod Template:
  Labels:	app=version-history
	pod-template-hash=abc123
	version=v1.0.0
  Annotations:	kubernetes.io/change-cause: v1.2.0 - Actualización menor nginx 1.21
  Containers:
   nginx:
    Image:	nginx:1.21-alpine
    Port:	80/TCP
    Environment:
      APP_VERSION:	v1.2.0
    ...
```

### Paso 1.5: Ver ReplicaSets históricos

```bash
kubectl get replicaset
```

**Output esperado**:
```
NAME                      DESIRED   CURRENT   READY   AGE
version-history-rev1      0         0         0       10m
version-history-rev2      0         0         0       8m
version-history-rev3      0         0         0       6m
version-history-rev4      0         0         0       4m
version-history-rev5      4         4         4       2m  <- Actual
```

**Explicación**:
- Cada revisión tiene su propio ReplicaSet
- Los viejos quedan en 0 réplicas (para rollback)
- Se mantienen según `revisionHistoryLimit: 5`

### ✅ Verificación

**Pregunta**: ¿Qué pasa si haces una 6ª actualización con `revisionHistoryLimit: 5`?

```bash
# Hacer versión 6
kubectl set image deployment/version-history nginx=nginx:alpine
kubectl annotate deployment version-history \
  kubernetes.io/change-cause="v2.1.0 - Latest nginx" --overwrite

# Ver ReplicaSets
kubectl get replicaset
```

<details>
<summary>Respuesta</summary>
El ReplicaSet MÁS VIEJO (rev1) se elimina. Solo se mantienen los últimos 5. Ahora tienes rev2, rev3, rev4, rev5, rev6.
</details>

---

## Ejercicio 2: Rollback Básico (10 min)

### Paso 2.1: Ver versión actual

```bash
# Ver imagen actual
kubectl get deployment version-history -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Output**: `nginx:alpine` (v2.1.0)

```bash
# Ver versión en variable de entorno
kubectl exec deployment/version-history -- env | grep APP_VERSION
```

**Output**: `APP_VERSION=v2.1.0`

### Paso 2.2: Rollback a versión anterior (undo)

```bash
# Rollback a la versión inmediatamente anterior
kubectl rollout undo deployment version-history
```

**Output**: `deployment.apps/version-history rolled back`

```bash
# Ver estado del rollback
kubectl rollout status deployment version-history
```

### Paso 2.3: Verificar rollback

```bash
# Ver imagen ahora
kubectl get deployment version-history -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Output**: `nginx:1.23-alpine` (v2.0.0) ✅

```bash
# Ver historial actualizado
kubectl rollout history deployment version-history
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
2         v1.1.0 - Actualización menor nginx 1.20
3         v1.2.0 - Actualización menor nginx 1.21
4         v1.3.0 - Actualización menor nginx 1.22
5         v2.1.0 - Latest nginx
6         v2.0.0 - Major release nginx 1.23  <- ¡Ahora es revision 6!
```

**Explicación**:
- Rollback NO elimina la revisión problemática
- Crea una NUEVA revisión (6) con el contenido de la anterior (5)
- La revisión 1 (v1.0.0) se eliminó porque `revisionHistoryLimit: 5`

### Paso 2.4: Rollback a revisión específica

```bash
# Ver historial
kubectl rollout history deployment version-history

# Rollback a revisión 3 (nginx 1.21)
kubectl rollout undo deployment version-history --to-revision=3
```

**Output**: `deployment.apps/version-history rolled back`

```bash
# Verificar
kubectl get deployment version-history -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Output**: `nginx:1.21-alpine` ✅

```bash
# Ver variable de entorno
kubectl exec deployment/version-history -- env | grep APP_VERSION
```

**Output**: `APP_VERSION=v1.2.0` ✅

### ✅ Verificación

**Pregunta**: ¿Cómo se numeran las revisiones después de rollback a --to-revision=3?

```bash
kubectl rollout history deployment version-history
```

<details>
<summary>Respuesta</summary>
La revisión 3 desaparece y se crea una nueva revisión (7) con su contenido:
```
REVISION  CHANGE-CAUSE
2         v1.1.0 - ...
4         v1.3.0 - ...
5         v2.1.0 - ...
6         v2.0.0 - ...
7         v1.2.0 - ...  <- contenido de ex-revision 3
```
</details>

---

## Ejercicio 3: Rollback de Deployment Fallido (15 min)

### Paso 3.1: Crear Deployment productivo

Crea `production-app.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-app
  annotations:
    kubernetes.io/change-cause: "v1.0.0 - Production stable release"
spec:
  replicas: 5
  revisionHistoryLimit: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: production-app
  template:
    metadata:
      labels:
        app: production-app
        version: "v1.0.0"
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine  # Imagen VÁLIDA
        ports:
        - containerPort: 80
        env:
        - name: APP_VERSION
          value: "v1.0.0"
        - name: RELEASE_DATE
          value: "2025-01-01"
        resources:
          requests:
            memory: "128Mi"
            cpu: "200m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 3
```

```bash
kubectl apply -f production-app.yaml
kubectl rollout status deployment production-app
```

### Paso 3.2: Desplegar versión con imagen ROTA

**Terminal 1** (monitoring):
```bash
kubectl get pods -l app=production-app -w
```

**Terminal 2** (deploy malo):
```bash
# Intentar actualizar a imagen que NO EXISTE
kubectl set image deployment/production-app app=nginx:broken-tag-12345
kubectl annotate deployment production-app \
  kubernetes.io/change-cause="v2.0.0 - BROKEN deployment" --overwrite
```

**Observación en Terminal 1**:
```
production-app-old-abc   1/1     Running       0     2m
production-app-new-xyz   0/1     Pending       0     0s
production-app-new-xyz   0/1     ContainerCreating   0     0s
production-app-new-xyz   0/1     ErrImagePull        0     5s
production-app-new-xyz   0/1     ImagePullBackOff    0     20s
production-app-new-xyz   0/1     ErrImagePull        0     35s
production-app-new-xyz   0/1     ImagePullBackOff    0     50s
```

**Explicación**:
- El nuevo Pod NO puede arrancar (imagen no existe)
- Queda en estado `ImagePullBackOff`
- Los Pods viejos SIGUEN corriendo (maxUnavailable: 0)
- ✅ La aplicación sigue funcional

### Paso 3.3: Ver estado del Deployment

```bash
kubectl get deployment production-app
```

**Output**:
```
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
production-app   5/5     1            5           5m
```

**Explicación**:
- `READY: 5/5` → Los 5 Pods viejos siguen ready
- `UP-TO-DATE: 1` → 1 Pod nuevo creado (pero no ready)
- `AVAILABLE: 5` → Aplicación funcionando normalmente

```bash
kubectl rollout status deployment production-app
```

**Output**:
```
Waiting for deployment "production-app" rollout to finish: 1 out of 5 new replicas have been updated...
```

**Estado**: Rollout ATASCADO

### Paso 3.4: Ver detalles del error

```bash
# Ver eventos del Deployment
kubectl describe deployment production-app | tail -20

# Ver Pod con error
kubectl get pods -l app=production-app | grep ImagePullBackOff
POD_NAME=$(kubectl get pods -l app=production-app -o jsonpath='{.items[?(@.status.phase=="Pending")].metadata.name}')
kubectl describe pod $POD_NAME | grep -A 5 Events
```

**Output**:
```
Events:
  Type     Reason     Message
  ----     ------     -------
  Normal   Scheduled  Successfully assigned default/production-app-new-xyz to node1
  Normal   Pulling    Pulling image "nginx:broken-tag-12345"
  Warning  Failed     Failed to pull image "nginx:broken-tag-12345": rpc error: code = Unknown desc = Error response from daemon: manifest for nginx:broken-tag-12345 not found
  Warning  Failed     Error: ErrImagePull
  Normal   BackOff    Back-off pulling image "nginx:broken-tag-12345"
  Warning  Failed     Error: ImagePullBackOff
```

### Paso 3.5: Rollback inmediato

```bash
# Rollback a versión anterior (la que funcionaba)
kubectl rollout undo deployment production-app
```

**Output**: `deployment.apps/production-app rolled back`

```bash
# Monitorear el rollback
kubectl rollout status deployment production-app
```

**Output**: `deployment "production-app" successfully rolled out` ✅

```bash
# Verificar que todo está OK
kubectl get pods -l app=production-app
```

**Output esperado**:
```
NAME                          READY   STATUS    RESTARTS   AGE
production-app-old-abc        1/1     Running   0          8m
production-app-old-def        1/1     Running   0          8m
production-app-old-ghi        1/1     Running   0          8m
production-app-old-jkl        1/1     Running   0          8m
production-app-old-mno        1/1     Running   0          8m
```

✅ Todos los Pods corriendo con imagen válida

### ✅ Verificación

**Pregunta**: ¿Por qué la aplicación NO tuvo downtime durante el deploy fallido?

<details>
<summary>Respuesta</summary>
Por `maxUnavailable: 0`. Kubernetes NO elimina Pods viejos hasta que los nuevos estén Ready. Como los nuevos nunca llegaron a Ready, los viejos se mantuvieron.
</details>

---

## Ejercicio 4: Rollback Automático con Probes (10 min)

### Paso 4.1: Crear Deployment con liveness probe estricto

Crea `auto-rollback.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auto-rollback
  annotations:
    kubernetes.io/change-cause: "v1.0 - Healthy version"
spec:
  replicas: 3
  progressDeadlineSeconds: 120  # Timeout de 2 minutos
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: auto-rollback
  template:
    metadata:
      labels:
        app: auto-rollback
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /healthz  # Endpoint que EXISTE
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 2  # Falla después de 2 intentos (10s)
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
          failureThreshold: 2
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

```bash
kubectl apply -f auto-rollback.yaml
kubectl rollout status deployment auto-rollback
```

**Nota**: Los Pods fallarán readinessProbe porque `/ready` no existe, pero arrancarán eventualmente.

### Paso 4.2: Simular deploy con probe fallido

Actualiza `auto-rollback.yaml` cambiando la imagen a una inválida:

```yaml
        image: nginx:invalid-image-404
```

```bash
kubectl apply -f auto-rollback.yaml
kubectl annotate deployment auto-rollback \
  kubernetes.io/change-cause="v2.0 - BROKEN with invalid image" --overwrite
```

**Terminal 1**:
```bash
kubectl get pods -l app=auto-rollback -w
```

**Observación**: Pods nuevos quedan en `ImagePullBackOff`

### Paso 4.3: Esperar timeout

```bash
# Esperar ~2 minutos (progressDeadlineSeconds: 120)
kubectl rollout status deployment auto-rollback --timeout=3m
```

**Output después de timeout**:
```
error: deployment "auto-rollback" exceeded its progress deadline
```

```bash
# Ver condiciones del Deployment
kubectl get deployment auto-rollback -o jsonpath='{.status.conditions}' | jq
```

**Output esperado**:
```json
[
  {
    "type": "Progressing",
    "status": "False",
    "reason": "ProgressDeadlineExceeded",
    "message": "ReplicaSet auto-rollback-xyz has timed out progressing."
  }
]
```

**Explicación**:
- Kubernetes detecta que el rollout NO progresa
- Marca el Deployment como fallido
- NO hace rollback automático (debes hacerlo manual)

### Paso 4.4: Rollback manual

```bash
kubectl rollout undo deployment auto-rollback
kubectl rollout status deployment auto-rollback
```

### ✅ Verificación

**Pregunta**: ¿Kubernetes hace rollback automático cuando falla un deployment?

<details>
<summary>Respuesta</summary>
NO. Kubernetes solo DETIENE el rollout y marca el estado como fallido. El rollback debe hacerse MANUALMENTE con `kubectl rollout undo`.
</details>

---

## Ejercicio 5: Workflow Completo de Versiones (10 min)

### Paso 5.1: Crear app con versionado completo

Crea `versioned-app.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: versioned-app
  labels:
    app: versioned-app
    environment: production
  annotations:
    kubernetes.io/change-cause: "v1.0.0 - Initial release (2025-01-15)"
    app.kubernetes.io/version: "1.0.0"
    release.date: "2025-01-15"
    jira.ticket: "PROD-1001"
spec:
  replicas: 5
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 300
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: versioned-app
  template:
    metadata:
      labels:
        app: versioned-app
        version: "v1.0.0"
        tier: backend
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
    spec:
      containers:
      - name: app
        image: nginx:1.20-alpine
        ports:
        - name: http
          containerPort: 80
        env:
        - name: APP_VERSION
          value: "v1.0.0"
        - name: RELEASE_DATE
          value: "2025-01-15"
        - name: BUILD_NUMBER
          value: "100"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

```bash
kubectl apply -f versioned-app.yaml
kubectl rollout status deployment versioned-app
```

### Paso 5.2: Simular ciclo de releases

```bash
# Release v1.1.0 (minor update)
kubectl set image deployment/versioned-app app=nginx:1.21-alpine
kubectl set env deployment/versioned-app APP_VERSION=v1.1.0 BUILD_NUMBER=110
kubectl label deployment versioned-app app.kubernetes.io/version=1.1.0 --overwrite
kubectl annotate deployment versioned-app \
  kubernetes.io/change-cause="v1.1.0 - Feature: improved logging (PROD-1002)" \
  release.date="2025-02-01" \
  jira.ticket="PROD-1002" --overwrite
kubectl rollout status deployment versioned-app

# Release v1.1.1 (patch)
kubectl set image deployment/versioned-app app=nginx:1.21-alpine  # Sin cambio
kubectl set env deployment/versioned-app APP_VERSION=v1.1.1 BUILD_NUMBER=111
kubectl annotate deployment versioned-app \
  kubernetes.io/change-cause="v1.1.1 - Hotfix: memory leak (PROD-1003)" \
  release.date="2025-02-05" \
  jira.ticket="PROD-1003" --overwrite
kubectl rollout status deployment versioned-app

# Release v2.0.0 (major - BROKEN)
kubectl set image deployment/versioned-app app=nginx:fake-version-999
kubectl set env deployment/versioned-app APP_VERSION=v2.0.0 BUILD_NUMBER=200
kubectl annotate deployment versioned-app \
  kubernetes.io/change-cause="v2.0.0 - MAJOR: API redesign (PROD-1004 - BROKEN)" \
  release.date="2025-03-01" \
  jira.ticket="PROD-1004" --overwrite
```

### Paso 5.3: Ver historial completo

```bash
kubectl rollout history deployment versioned-app
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
1         v1.0.0 - Initial release (2025-01-15)
2         v1.1.0 - Feature: improved logging (PROD-1002)
3         v1.1.1 - Hotfix: memory leak (PROD-1003)
4         v2.0.0 - MAJOR: API redesign (PROD-1004 - BROKEN)
```

### Paso 5.4: Detectar y rollback

```bash
# Ver estado actual
kubectl get deployment versioned-app

# Ver Pods
kubectl get pods -l app=versioned-app

# Identificar problemas
kubectl describe deployment versioned-app | grep -A 5 Conditions
```

**Output**:
```
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    ReplicaSetUpdated  # O False si timeout
```

```bash
# Rollback a última versión buena conocida (v1.1.1)
kubectl rollout undo deployment versioned-app --to-revision=3

# Actualizar change-cause para reflejar rollback
kubectl annotate deployment versioned-app \
  kubernetes.io/change-cause="v1.1.1 - ROLLBACK from broken v2.0.0" --overwrite
```

### Paso 5.5: Verificar recuperación

```bash
# Ver todos los Pods
kubectl get pods -l app=versioned-app

# Verificar versión
kubectl exec deployment/versioned-app -- env | grep APP_VERSION
```

**Output**: `APP_VERSION=v1.1.1` ✅

```bash
# Ver historial actualizado
kubectl rollout history deployment versioned-app
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
1         v1.0.0 - Initial release (2025-01-15)
2         v1.1.0 - Feature: improved logging (PROD-1002)
4         v2.0.0 - MAJOR: API redesign (PROD-1004 - BROKEN)
5         v1.1.1 - ROLLBACK from broken v2.0.0  <- Nueva revisión
```

### ✅ Verificación

**Ejercicio**: Crea un script de "rollback seguro" que:
1. Verifique estado del Deployment
2. Haga rollback si hay problemas
3. Actualice change-cause

<details>
<summary>Solución</summary>

```bash
#!/bin/bash
# safe-rollback.sh

DEPLOYMENT=$1
NAMESPACE=${2:-default}

if [ -z "$DEPLOYMENT" ]; then
  echo "Uso: ./safe-rollback.sh <deployment> [namespace]"
  exit 1
fi

echo "Verificando estado de $DEPLOYMENT en namespace $NAMESPACE..."

# Verificar si hay Pods con errores
ERROR_PODS=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT \
  -o jsonpath='{.items[?(@.status.phase!="Running")].metadata.name}')

if [ -n "$ERROR_PODS" ]; then
  echo "⚠️  Pods con errores detectados:"
  echo "$ERROR_PODS"
  echo ""
  echo "Ejecutando rollback..."
  kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE
  kubectl annotate deployment/$DEPLOYMENT -n $NAMESPACE \
    kubernetes.io/change-cause="EMERGENCY ROLLBACK - $(date +%Y-%m-%d_%H:%M:%S)" --overwrite
  echo "✅ Rollback completado"
else
  echo "✅ No hay errores, Deployment saludable"
fi
```

Uso:
```bash
chmod +x safe-rollback.sh
./safe-rollback.sh versioned-app lab-rollback
```
</details>

---

## 🎓 Desafío Final: Simulación de Incidente en Producción

### Escenario

Eres el SRE de turno. A las 3 AM recibes una alerta: el deployment `critical-service` tiene Pods fallando después de un release.

**Datos**:
- Deployment: `critical-service`
- Réplicas: 10
- Última versión buena: v3.2.1 (revision 12)
- Versión actual (broken): v3.3.0 (revision 13)
- SLA: 99.9% uptime

**Tareas**:
1. Crear el deployment en estado "broken"
2. Diagnosticar el problema
3. Realizar rollback
4. Documentar el incidente
5. Verificar recuperación completa

<details>
<summary>Solución Completa</summary>

**Paso 1: Setup del escenario**

```yaml
# critical-service-broken.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-service
  annotations:
    kubernetes.io/change-cause: "v3.3.0 - BROKEN: new feature with bug (INC-9999)"
spec:
  replicas: 10
  revisionHistoryLimit: 15
  progressDeadlineSeconds: 180
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0
  selector:
    matchLabels:
      app: critical-service
  template:
    metadata:
      labels:
        app: critical-service
        version: "v3.3.0"
    spec:
      containers:
      - name: app
        image: nginx:nonexistent-tag  # Imagen ROTA
        ports:
        - containerPort: 80
        env:
        - name: APP_VERSION
          value: "v3.3.0"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 2
```

```bash
# Primero crear versión "buena" (v3.2.1)
cat > critical-service-good.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-service
  annotations:
    kubernetes.io/change-cause: "v3.2.1 - Stable production version"
spec:
  replicas: 10
  revisionHistoryLimit: 15
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0
  selector:
    matchLabels:
      app: critical-service
  template:
    metadata:
      labels:
        app: critical-service
        version: "v3.2.1"
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine  # Imagen VÁLIDA
        ports:
        - containerPort: 80
        env:
        - name: APP_VERSION
          value: "v3.2.1"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
EOF

kubectl apply -f critical-service-good.yaml
kubectl rollout status deployment critical-service

# Ahora aplicar versión rota
kubectl apply -f critical-service-broken.yaml
```

**Paso 2: Diagnóstico (como SRE)**

```bash
# Ver estado general
kubectl get deployment critical-service
kubectl get pods -l app=critical-service

# Identificar Pods con problemas
kubectl get pods -l app=critical-service | grep -E "ImagePullBackOff|ErrImagePull|CrashLoopBackOff"

# Ver eventos
kubectl describe deployment critical-service | tail -30

# Ver logs si hay
kubectl logs -l app=critical-service --tail=50

# Verificar historial
kubectl rollout history deployment critical-service
```

**Paso 3: Rollback de emergencia**

```bash
# Rollback inmediato
kubectl rollout undo deployment critical-service

# Monitorear recuperación
kubectl rollout status deployment critical-service

# Verificar Pods
kubectl get pods -l app=critical-service
```

**Paso 4: Documentación del incidente**

```bash
# Crear incidente report
cat > incident-report-INC-9999.md <<EOF
# Incident Report: INC-9999

## Resumen
- **Fecha**: $(date)
- **Severidad**: P1 (Critical)
- **Servicio**: critical-service
- **Impacto**: Rollout fallido, 0% downtime (gracias a maxUnavailable: 0)

## Timeline
- 03:00 - Deploy de v3.3.0 iniciado
- 03:02 - Alerta: Pods en ImagePullBackOff
- 03:03 - SRE notificado
- 03:05 - Rollback a v3.2.1 ejecutado
- 03:07 - Servicio completamente recuperado

## Root Cause
Imagen Docker incorrecta: \`nginx:nonexistent-tag\` no existe en registry.

## Resolución
Rollback a última versión buena conocida (v3.2.1, revision 12).

## Lecciones Aprendidas
1. ✅ maxUnavailable: 0 previno downtime
2. ⚠️  Faltó validación de imagen antes de deploy
3. 📝 Agregar step de smoke test en CI/CD

## Action Items
- [ ] Implementar image validation en pipeline (JIRA: OPS-1234)
- [ ] Agregar smoke tests pre-production (JIRA: OPS-1235)
- [ ] Revisar proceso de release (JIRA: OPS-1236)
EOF

cat incident-report-INC-9999.md
```

**Paso 5: Verificación final**

```bash
# Verificar TODOS los Pods healthy
kubectl get pods -l app=critical-service

# Verificar versión
kubectl get deployment critical-service -o jsonpath='{.spec.template.spec.containers[0].image}'

# Verificar métricas (si Prometheus disponible)
# curl -s http://prometheus/api/v1/query?query=up{job="critical-service"}

# Confirmar en historial
kubectl rollout history deployment critical-service
```

**Output esperado**:
```
All Pods Running ✅
Image: nginx:1.21-alpine ✅
Version: v3.2.1 ✅
Availability: 10/10 ✅
```

</details>

---

## 🧹 Limpieza

```bash
kubectl delete deployment --all -n lab-rollback
kubectl delete namespace lab-rollback
kubectl config set-context --current --namespace=default
```

---

## 📝 Resumen

En este laboratorio aprendiste:

✅ **Historial de revisiones**: `revisionHistoryLimit` controla cuántas versiones guardar  
✅ **Visualizar versiones**: `kubectl rollout history` muestra todas las revisiones  
✅ **Rollback básico**: `kubectl rollout undo` vuelve a versión anterior  
✅ **Rollback específico**: `--to-revision=N` va a versión exacta  
✅ **Change-cause**: Annotations descriptivas para tracking  
✅ **Detección de fallos**: `progressDeadlineSeconds` marca deployments atascados  
✅ **Alta disponibilidad**: `maxUnavailable: 0` previene downtime  
✅ **Gestión de incidentes**: Workflow completo de diagnóstico y recuperación  

---

## 🔗 Recursos Relacionados

- [Laboratorio 1: Crear Deployments](lab-01-crear-deployments.md)
- [Laboratorio 2: Rolling Updates](lab-02-rolling-updates.md)
- [Ejemplos de Rollback](../ejemplos/04-rollback/)
- [README del módulo](../README.md)

---

**¡Felicitaciones! 🎉**  
Has completado todos los laboratorios del módulo de Deployments. Ahora dominas:
- Creación y gestión de Deployments
- Rolling updates y estrategias
- Rollback y recuperación de incidentes

**Siguiente paso**: Aplicar estos conocimientos en proyectos reales y explorar [HorizontalPodAutoscaler](../../modulo-08-autoscaling/) para escalado automático.
