# Laboratorio 2: Rolling Updates y Estrategias de Despliegue

## 📋 Información del Laboratorio

- **Duración estimada**: 50 minutos
- **Nivel**: Intermedio
- **Requisitos**: Laboratorio 1 completado
- **Namespace**: `lab-rolling-updates`

## 🎯 Objetivos

Al completar este laboratorio, serás capaz de:

1. Entender el proceso de rolling update en detalle
2. Controlar el comportamiento con `maxSurge` y `maxUnavailable`
3. Comparar estrategias RollingUpdate vs Recreate
4. Monitorear el progreso de un rollout
5. Usar anotaciones `change-cause` para historial descriptivo
6. Pausar y reanudar rollouts

## 📚 Prerrequisitos

- Laboratorio 1 completado
- Conocimiento de Deployments básicos
- Cluster de Kubernetes funcional

## 🔧 Preparación del Entorno

```bash
# Crear namespace
kubectl create namespace lab-rolling-updates
kubectl config set-context --current --namespace=lab-rolling-updates

# Verificar
kubectl config view --minify | grep namespace:
```

---

## Ejercicio 1: Rolling Update Básico (10 min)

### Paso 1.1: Crear Deployment inicial

Crea `rolling-demo.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-demo
  annotations:
    kubernetes.io/change-cause: "v1.0 - Deploy inicial con nginx 1.20"
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: rolling-demo
  template:
    metadata:
      labels:
        app: rolling-demo
        version: "v1.0"
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
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
          initialDelaySeconds: 5
          periodSeconds: 2
```

```bash
kubectl apply -f rolling-demo.yaml
```

### Paso 1.2: Verificar estado inicial

```bash
# Ver Deployment
kubectl get deployment rolling-demo

# Ver ReplicaSet
kubectl get replicaset

# Ver Pods con versión
kubectl get pods -L version
```

**Output esperado**:
```
NAME                           READY   STATUS    RESTARTS   AGE   VERSION
rolling-demo-7d4f8c6b9f-abc    1/1     Running   0          30s   v1.0
rolling-demo-7d4f8c6b9f-def    1/1     Running   0          30s   v1.0
rolling-demo-7d4f8c6b9f-ghi    1/1     Running   0          30s   v1.0
rolling-demo-7d4f8c6b9f-jkl    1/1     Running   0          30s   v1.0
rolling-demo-7d4f8c6b9f-mno    1/1     Running   0          30s   v1.0
```

### Paso 1.3: Realizar rolling update

**Terminal 1** (monitoreo):
```bash
kubectl get pods -w
```

**Terminal 2** (actualización):
```bash
# Actualizar imagen a 1.21
kubectl set image deployment/rolling-demo nginx=nginx:1.21-alpine

# Agregar change-cause
kubectl annotate deployment rolling-demo \
  kubernetes.io/change-cause="v1.1 - Actualizar nginx a 1.21"
```

**Observación en Terminal 1**:
```
rolling-demo-7d4f8c6b9f-abc    1/1     Running       0     2m
rolling-demo-8f5c9d7a8g-pqr    0/1     Pending       0     0s   <- Nuevo Pod creado
rolling-demo-8f5c9d7a8g-pqr    0/1     ContainerCreating   0     0s
rolling-demo-8f5c9d7a8g-pqr    0/1     Running       0     2s
rolling-demo-8f5c9d7a8g-pqr    1/1     Running       0     5s   <- Nuevo Pod Ready
rolling-demo-7d4f8c6b9f-abc    1/1     Terminating   0     2m   <- Viejo Pod terminando
rolling-demo-8f5c9d7a8g-stu    0/1     Pending       0     0s   <- Siguiente nuevo Pod
...
```

### Paso 1.4: Ver historial

```bash
kubectl rollout history deployment rolling-demo
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
1         v1.0 - Deploy inicial con nginx 1.20
2         v1.1 - Actualizar nginx a 1.21
```

### ✅ Verificación

**Pregunta**: ¿Cuántos Pods estuvieron corriendo simultáneamente durante el update?

<details>
<summary>Respuesta</summary>
Máximo 6 Pods (5 deseados + 1 de maxSurge)
</details>

**Pregunta**: ¿Cuál fue el mínimo de Pods disponibles?

<details>
<summary>Respuesta</summary>
Mínimo 4 Pods (5 deseados - 1 de maxUnavailable)
</details>

---

## Ejercicio 2: Controlar maxSurge y maxUnavailable (15 min)

### Paso 2.1: Caso A - Alta disponibilidad (maxUnavailable: 0)

Crea `rolling-ha.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-ha
  annotations:
    kubernetes.io/change-cause: "v1.0 - Configuración alta disponibilidad"
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # ¡NUNCA baja de 4 Pods!
  selector:
    matchLabels:
      app: rolling-ha
  template:
    metadata:
      labels:
        app: rolling-ha
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
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
kubectl apply -f rolling-ha.yaml

# Esperar a que esté ready
kubectl rollout status deployment rolling-ha
```

### Paso 2.2: Actualizar con maxUnavailable: 0

**Terminal 1**:
```bash
kubectl get pods -l app=rolling-ha -w
```

**Terminal 2**:
```bash
kubectl set image deployment/rolling-ha nginx=nginx:1.21-alpine

kubectl annotate deployment rolling-ha \
  kubernetes.io/change-cause="v1.1 - Update con maxUnavailable=0"
```

**Observación**:
- Primero crea 1 Pod nuevo (maxSurge: 1)
- Espera a que esté Ready
- LUEGO termina 1 Pod viejo
- Repite hasta terminar
- ✅ Siempre hay 4 Pods disponibles

**Cálculo**:
```
maxSurge: 1       → Permite hasta 5 Pods (4 + 1)
maxUnavailable: 0 → Mínimo 4 Pods siempre
```

### Paso 2.3: Caso B - Actualización rápida (maxUnavailable: 2)

Crea `rolling-fast.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-fast
  annotations:
    kubernetes.io/change-cause: "v1.0 - Configuración rápida"
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 2  # Puede tener hasta 2 Pods down
  selector:
    matchLabels:
      app: rolling-fast
  template:
    metadata:
      labels:
        app: rolling-fast
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
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
kubectl apply -f rolling-fast.yaml
kubectl rollout status deployment rolling-fast
```

### Paso 2.4: Actualizar con parámetros agresivos

**Terminal 1**:
```bash
kubectl get pods -l app=rolling-fast -w
```

**Terminal 2**:
```bash
kubectl set image deployment/rolling-fast nginx=nginx:1.22-alpine

kubectl annotate deployment rolling-fast \
  kubernetes.io/change-cause="v1.1 - Update rápido con maxUnavailable=2"
```

**Observación**:
- Crea hasta 2 Pods nuevos simultáneamente
- Puede tener hasta 2 Pods down
- Actualización MUCHO más rápida
- Trade-off: Menos disponibilidad durante update

**Cálculo**:
```
maxSurge: 2       → Permite hasta 8 Pods (6 + 2)
maxUnavailable: 2 → Mínimo 4 Pods (6 - 2)
```

### Paso 2.5: Comparar tiempos

```bash
# Ver duración del rollout
kubectl describe deployment rolling-ha | grep -A 5 Events
kubectl describe deployment rolling-fast | grep -A 5 Events
```

**Comparación**:
| Deployment | maxSurge | maxUnavailable | Disponibilidad | Velocidad |
|------------|----------|----------------|----------------|-----------|
| rolling-ha | 1 | 0 | 100% (4/4) | Lento |
| rolling-fast | 2 | 2 | 67% (4/6) | Rápido |

### ✅ Verificación

**Pregunta**: ¿Cuándo usarías `maxUnavailable: 0`?

<details>
<summary>Respuesta</summary>
Producción con alta disponibilidad crítica, donde NO puedes tolerar reducción de capacidad.
</details>

**Pregunta**: ¿Cuándo usarías `maxUnavailable: 2`?

<details>
<summary>Respuesta</summary>
Desarrollo/staging, o producción con tolerancia a downtime parcial, priorizando velocidad.
</details>

---

## Ejercicio 3: Estrategia Recreate (10 min)

### Paso 3.1: Crear Deployment con estrategia Recreate

Crea `recreate-demo.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: recreate-demo
  annotations:
    kubernetes.io/change-cause: "v1.0 - Deploy con estrategia Recreate"
spec:
  replicas: 4
  strategy:
    type: Recreate  # ¡Sin rolling update!
  selector:
    matchLabels:
      app: recreate-demo
  template:
    metadata:
      labels:
        app: recreate-demo
        version: "v1.0"
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

```bash
kubectl apply -f recreate-demo.yaml
kubectl rollout status deployment recreate-demo
```

### Paso 3.2: Actualizar con Recreate

**Terminal 1**:
```bash
kubectl get pods -l app=recreate-demo -w
```

**Terminal 2**:
```bash
kubectl set image deployment/recreate-demo nginx=nginx:1.21-alpine

kubectl annotate deployment recreate-demo \
  kubernetes.io/change-cause="v1.1 - Update con Recreate (downtime completo)"
```

**Observación en Terminal 1**:
```
recreate-demo-abc   1/1     Running       0     1m
recreate-demo-def   1/1     Running       0     1m
recreate-demo-ghi   1/1     Running       0     1m
recreate-demo-jkl   1/1     Running       0     1m
recreate-demo-abc   1/1     Terminating   0     1m  <- TODOS terminan
recreate-demo-def   1/1     Terminating   0     1m
recreate-demo-ghi   1/1     Terminating   0     1m
recreate-demo-jkl   1/1     Terminating   0     1m
recreate-demo-abc   0/1     Terminating   0     1m
...
recreate-demo-pqr   0/1     Pending       0     0s  <- Nuevos Pods crean DESPUÉS
recreate-demo-stu   0/1     Pending       0     0s
recreate-demo-vwx   0/1     Pending       0     0s
recreate-demo-yza   0/1     Pending       0     0s
recreate-demo-pqr   0/1     ContainerCreating   0     0s
...
```

**Explicación**:
1. TODOS los Pods viejos se eliminan primero
2. Hay un período de **DOWNTIME COMPLETO** (0 Pods)
3. Luego se crean TODOS los Pods nuevos
4. No hay Pods de versiones diferentes corriendo juntas

### Paso 3.3: Verificar downtime

```bash
kubectl describe deployment recreate-demo | grep -A 10 Events
```

**Output esperado**:
```
Events:
  Type    Reason             Message
  ----    ------             -------
  Normal  ScalingReplicaSet  Scaled down replica set recreate-demo-old to 0
  Normal  ScalingReplicaSet  Scaled up replica set recreate-demo-new to 4
```

**Nota**: Hay un gap temporal entre el scale down y scale up.

### Paso 3.4: Cuándo usar Recreate

**✅ Casos de uso válidos**:
- Aplicación NO soporta múltiples versiones simultáneas
- Migración de base de datos incompatible
- Cambios de schema que requieren downtime
- Desarrollo/testing (no producción)

**❌ NO usar Recreate si**:
- Necesitas alta disponibilidad
- Puedes hacer rolling updates
- Estás en producción

### ✅ Verificación

Ejecuta:
```bash
# Contar ReplicaSets
kubectl get replicaset -l app=recreate-demo
```

**Pregunta**: ¿Cuántos ReplicaSets hay?

<details>
<summary>Respuesta</summary>
2: El viejo (0 réplicas) y el nuevo (4 réplicas), igual que con RollingUpdate. La diferencia es el PROCESO de actualización, no el resultado final.
</details>

---

## Ejercicio 4: Pausar y Reanudar Rollouts (15 min)

### Paso 4.1: Crear Deployment para demo

Crea `pause-demo.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pause-demo
  annotations:
    kubernetes.io/change-cause: "v1.0 - Demo pause/resume"
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: pause-demo
  template:
    metadata:
      labels:
        app: pause-demo
        version: "v1.0"
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
        env:
        - name: APP_VERSION
          value: "v1.0"
        - name: ENVIRONMENT
          value: "development"
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
kubectl apply -f pause-demo.yaml
kubectl rollout status deployment pause-demo
```

### Paso 4.2: Pausar el Deployment

```bash
kubectl rollout pause deployment pause-demo
```

**Output**: `deployment.apps/pause-demo paused`

### Paso 4.3: Hacer múltiples cambios (mientras está pausado)

```bash
# Cambio 1: Actualizar imagen
kubectl set image deployment/pause-demo nginx=nginx:1.23-alpine

# Cambio 2: Actualizar variable de entorno
kubectl set env deployment/pause-demo APP_VERSION=v2.0

# Cambio 3: Aumentar recursos
kubectl set resources deployment/pause-demo \
  -c nginx \
  --requests=cpu=200m,memory=128Mi \
  --limits=cpu=500m,memory=256Mi

# Cambio 4: Escalar
kubectl scale deployment pause-demo --replicas=8
```

### Paso 4.4: Verificar que NO se aplican cambios

```bash
# Ver Pods (siguen igual)
kubectl get pods -l app=pause-demo

# Ver imagen en Deployment spec
kubectl get deployment pause-demo -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Output**: `nginx:1.23-alpine` (cambió en spec)

```bash
# Ver imagen en Pods reales
kubectl get pods -l app=pause-demo -o jsonpath='{.items[0].spec.containers[0].image}'
```

**Output**: `nginx:1.20-alpine` (NO cambió en Pods)

**Explicación**: Los cambios están en el Deployment spec, pero NO se han aplicado a los Pods.

### Paso 4.5: Reanudar el Deployment

**Terminal 1**:
```bash
kubectl get pods -l app=pause-demo -w
```

**Terminal 2**:
```bash
kubectl rollout resume deployment pause-demo

kubectl annotate deployment pause-demo \
  kubernetes.io/change-cause="v2.0 - Múltiples cambios aplicados juntos"
```

**Observación**:
- AHORA sí se inicia el rolling update
- TODOS los cambios se aplican en UN solo rollout
- Más eficiente que 4 rollouts separados

### Paso 4.6: Verificar resultado

```bash
# Ver Pods finales
kubectl get pods -l app=pause-demo
```

**Output esperado**: 8 Pods (escalado a 8)

```bash
# Verificar imagen
kubectl get pods -l app=pause-demo -o jsonpath='{.items[0].spec.containers[0].image}'
```

**Output**: `nginx:1.23-alpine` ✅

```bash
# Verificar variable de entorno
kubectl exec deployment/pause-demo -- env | grep APP_VERSION
```

**Output**: `APP_VERSION=v2.0` ✅

```bash
# Verificar recursos
kubectl get pods -l app=pause-demo -o jsonpath='{.items[0].spec.containers[0].resources}'
```

**Output**: `{"limits":{"cpu":"500m","memory":"256Mi"},"requests":{"cpu":"200m","memory":"128Mi"}}` ✅

### ✅ Verificación

**Pregunta**: ¿Cuántos rollouts se ejecutaron?

<details>
<summary>Respuesta</summary>
1 solo rollout (en lugar de 4 separados). Pause/Resume permite batch changes.
</details>

---

## 🎓 Desafío Final

Crea un Deployment que cumpla:

1. **Nombre**: `challenge-app`
2. **Réplicas**: 10
3. **Estrategia**: RollingUpdate
   - Garantía de alta disponibilidad (maxUnavailable: 0)
   - Permite hasta 3 Pods extra durante update
4. **Imagen inicial**: `nginx:1.21-alpine`
5. **Change-cause**: "v1.0 - Challenge deployment"
6. **Tarea**: Actualizar a `nginx:1.23-alpine` y verificar que NUNCA baja de 10 Pods disponibles

<details>
<summary>Solución</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: challenge-app
  annotations:
    kubernetes.io/change-cause: "v1.0 - Challenge deployment"
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 3
      maxUnavailable: 0
  selector:
    matchLabels:
      app: challenge-app
  template:
    metadata:
      labels:
        app: challenge-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
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
          initialDelaySeconds: 2
          periodSeconds: 2
```

```bash
kubectl apply -f challenge.yaml
kubectl rollout status deployment challenge-app

# Actualizar (Terminal 1: watch, Terminal 2: update)
# Terminal 1:
kubectl get pods -l app=challenge-app -w

# Terminal 2:
kubectl set image deployment/challenge-app nginx=nginx:1.23-alpine
kubectl annotate deployment challenge-app \
  kubernetes.io/change-cause="v1.1 - Actualizado a nginx 1.23"

# Verificar que durante el update había máximo 13 Pods (10 + 3)
# y mínimo 10 Pods (10 - 0)
```
</details>

---

## 🧹 Limpieza

```bash
kubectl delete deployment --all -n lab-rolling-updates
kubectl delete namespace lab-rolling-updates
kubectl config set-context --current --namespace=default
```

---

## 📝 Resumen

En este laboratorio aprendiste:

✅ **Rolling Updates**: Proceso gradual de actualización  
✅ **maxSurge**: Pods extra permitidos durante update  
✅ **maxUnavailable**: Pods que pueden estar down  
✅ **Estrategia Recreate**: Downtime completo, todos los Pods reemplazados  
✅ **Change-cause**: Annotations para historial descriptivo  
✅ **Pause/Resume**: Aplicar múltiples cambios en un rollout  
✅ **Trade-offs**: Disponibilidad vs Velocidad de actualización  

---

## 🔗 Recursos Relacionados

- [Laboratorio 1: Crear Deployments](lab-01-crear-deployments.md)
- [Laboratorio 3: Rollback y Versiones](lab-03-rollback-versiones.md)
- [Ejemplos de Rolling Updates](../ejemplos/02-rolling-updates/)
- [README del módulo](../README.md)

---

**¡Excelente trabajo! 🚀**  
Continúa con [Laboratorio 3: Rollback y Versiones](lab-03-rollback-versiones.md).
