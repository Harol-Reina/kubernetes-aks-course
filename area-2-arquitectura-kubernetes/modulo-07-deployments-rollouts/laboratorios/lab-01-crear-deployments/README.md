# Laboratorio 1: Crear y Gestionar Deployments

## 📋 Información del Laboratorio

- **Duración estimada**: 40 minutos
- **Nivel**: Básico
- **Requisitos**: Cluster de Kubernetes funcional
- **Namespace**: `lab-deployments`

## 🎯 Objetivos

Al completar este laboratorio, serás capaz de:

1. Crear Deployments usando manifiestos YAML
2. Entender la relación Deployment → ReplicaSet → Pod
3. Verificar owner references
4. Escalar Deployments manual y declarativamente
5. Actualizar imágenes de contenedores
6. Inspeccionar el estado de Deployments

## 📚 Prerrequisitos

- Cluster de Kubernetes (minikube, kind, o cloud)
- kubectl configurado
- Conocimientos de módulo-06 (ReplicaSets)

## 🔧 Preparación del Entorno

### Paso 1: Crear namespace

```bash
kubectl create namespace lab-deployments
kubectl config set-context --current --namespace=lab-deployments
```

Verificar:
```bash
kubectl config view --minify | grep namespace:
```

**Resultado esperado**:
```
namespace: lab-deployments
```

---

## Ejercicio 1: Crear tu Primer Deployment (10 min)

### Paso 1.1: Crear el manifiesto

Crea `webapp-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
        tier: frontend
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
```

### Paso 1.2: Aplicar el Deployment

```bash
kubectl apply -f webapp-deployment.yaml
```

**Output esperado**:
```
deployment.apps/webapp created
```

### Paso 1.3: Verificar creación

```bash
# Ver el Deployment
kubectl get deployment webapp

# Ver los ReplicaSets creados
kubectl get replicaset

# Ver los Pods
kubectl get pods
```

**Output esperado**:
```
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webapp   3/3     3            3           30s

NAME                DESIRED   CURRENT   READY   AGE
webapp-7d4f8c6b9f   3         3         3       30s

NAME                      READY   STATUS    RESTARTS   AGE
webapp-7d4f8c6b9f-abc12   1/1     Running   0          30s
webapp-7d4f8c6b9f-def34   1/1     Running   0          30s
webapp-7d4f8c6b9f-ghi56   1/1     Running   0          30s
```

### Paso 1.4: Entender la jerarquía

```bash
# Ver descripción del Deployment
kubectl describe deployment webapp
```

Buscar la sección `NewReplicaSet`:
```
NewReplicaSet:   webapp-7d4f8c6b9f (3/3 replicas created)
```

```bash
# Ver el ReplicaSet en detalle
kubectl describe replicaset webapp-7d4f8c6b9f
```

Buscar `Controlled By`:
```
Controlled By:  Deployment/webapp
```

```bash
# Ver un Pod en detalle
kubectl describe pod webapp-7d4f8c6b9f-abc12
```

Buscar `Controlled By`:
```
Controlled By:  ReplicaSet/webapp-7d4f8c6b9f
```

**📊 Diagrama de la jerarquía**:
```
Deployment (webapp)
    ↓ controla
ReplicaSet (webapp-7d4f8c6b9f)
    ↓ controla
Pods (webapp-7d4f8c6b9f-abc12, -def34, -ghi56)
```

### ✅ Verificación

**Pregunta**: ¿Cuántos ReplicaSets ha creado el Deployment?
<details>
<summary>Respuesta</summary>
1 ReplicaSet (el actual)
</details>

**Pregunta**: ¿Quién controla los Pods?
<details>
<summary>Respuesta</summary>
El ReplicaSet (NO el Deployment directamente)
</details>

---

## Ejercicio 2: Explorar Owner References (10 min)

### Paso 2.1: Ver owner reference del ReplicaSet

```bash
kubectl get replicaset webapp-7d4f8c6b9f -o yaml | grep -A 10 ownerReferences
```

**Output esperado**:
```yaml
ownerReferences:
- apiVersion: apps/v1
  blockOwnerDeletion: true
  controller: true
  kind: Deployment
  name: webapp
  uid: <deployment-uid>
```

**Explicación**:
- `kind: Deployment` → El ReplicaSet es controlado por un Deployment
- `name: webapp` → Nombre del Deployment padre
- `controller: true` → Este owner es el controlador activo

### Paso 2.2: Ver owner reference de un Pod

```bash
# Obtener nombre de un Pod
POD_NAME=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')

# Ver owner reference
kubectl get pod $POD_NAME -o yaml | grep -A 10 ownerReferences
```

**Output esperado**:
```yaml
ownerReferences:
- apiVersion: apps/v1
  blockOwnerDeletion: true
  controller: true
  kind: ReplicaSet
  name: webapp-7d4f8c6b9f
  uid: <replicaset-uid>
```

**Explicación**:
- `kind: ReplicaSet` → El Pod es controlado por un ReplicaSet
- Esto confirma la jerarquía: Deployment → ReplicaSet → Pod

### Paso 2.3: Experimento - Eliminar un Pod

```bash
# Eliminar un Pod manualmente
kubectl delete pod $POD_NAME

# Inmediatamente ver los Pods
kubectl get pods -w
```

**Observación**:
- El Pod eliminado cambia a `Terminating`
- ¡El ReplicaSet crea AUTOMÁTICAMENTE un nuevo Pod!
- Siempre mantiene 3 réplicas (como se definió)

**Explicación**: El ReplicaSet detecta que hay menos Pods de los deseados y reconcilia el estado.

### ✅ Verificación

**Pregunta**: ¿Qué pasa si eliminas un ReplicaSet manualmente?
```bash
kubectl delete replicaset webapp-7d4f8c6b9f
kubectl get replicaset
kubectl get pods
```

<details>
<summary>Respuesta</summary>
El Deployment detecta que falta el ReplicaSet y crea uno nuevo con todos los Pods. ¡La reconciliación funciona en todos los niveles!
</details>

---

## Ejercicio 3: Escalar Deployments (10 min)

### Paso 3.1: Escalado imperativo

```bash
# Escalar a 5 réplicas
kubectl scale deployment webapp --replicas=5

# Ver el proceso
kubectl get pods -w
```

Presiona `Ctrl+C` después de ver los nuevos Pods en `Running`.

```bash
# Verificar escalado
kubectl get deployment webapp
```

**Output esperado**:
```
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webapp   5/5     5            5           5m
```

### Paso 3.2: Escalar hacia abajo

```bash
# Reducir a 2 réplicas
kubectl scale deployment webapp --replicas=2

# Ver qué Pods se eliminan
kubectl get pods
```

**Observación**: Kubernetes termina 3 Pods y mantiene 2.

### Paso 3.3: Escalado declarativo

Edita `webapp-deployment.yaml` y cambia:
```yaml
spec:
  replicas: 4  # Cambiar de 3 a 4
```

```bash
# Aplicar cambios
kubectl apply -f webapp-deployment.yaml

# Verificar
kubectl get deployment webapp
```

**Output esperado**:
```
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webapp   4/4     4            4           7m
```

### Paso 3.4: Ver eventos de escalado

```bash
kubectl describe deployment webapp | grep -A 20 Events
```

**Output esperado**:
```
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  5m    deployment-controller  Scaled up to 3
  Normal  ScalingReplicaSet  3m    deployment-controller  Scaled up to 5
  Normal  ScalingReplicaSet  2m    deployment-controller  Scaled down to 2
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled up to 4
```

### ✅ Verificación

**Pregunta**: ¿Cuál es la diferencia entre escalado imperativo y declarativo?

<details>
<summary>Respuesta</summary>

**Imperativo** (`kubectl scale`):
- Cambio temporal
- No modifica el archivo YAML
- Si reaplicamos el YAML, vuelve al valor original

**Declarativo** (editar YAML + `kubectl apply`):
- Cambio permanente
- El archivo refleja el estado deseado
- Recomendado para producción (GitOps)
</summary>
</details>

---

## Ejercicio 4: Actualizar Imagen del Deployment (10 min)

### Paso 4.1: Actualización imperativa

```bash
# Ver imagen actual
kubectl get deployment webapp -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Output**: `nginx:1.21-alpine`

```bash
# Actualizar imagen
kubectl set image deployment/webapp nginx=nginx:1.22-alpine

# Ver el proceso de rolling update
kubectl rollout status deployment webapp
```

**Output esperado**:
```
Waiting for deployment "webapp" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 1 old replicas are pending termination...
deployment "webapp" successfully rolled out
```

### Paso 4.2: Verificar la actualización

```bash
# Ver ReplicaSets ahora
kubectl get replicaset
```

**Output esperado**:
```
NAME                DESIRED   CURRENT   READY   AGE
webapp-7d4f8c6b9f   0         0         0       15m
webapp-8f5c9d7a8g   4         4         4       2m
```

**Observación**:
- ¡Ahora hay 2 ReplicaSets!
- El viejo (7d4f8c6b9f) tiene 0 Pods
- El nuevo (8f5c9d7a8g) tiene 4 Pods
- El viejo se mantiene para rollback

### Paso 4.3: Ver imagen actualizada

```bash
# Verificar imagen en Pods nuevos
kubectl get pods -o jsonpath='{.items[0].spec.containers[0].image}'
```

**Output**: `nginx:1.22-alpine` ✅

### Paso 4.4: Actualización declarativa

Edita `webapp-deployment.yaml`:
```yaml
      containers:
      - name: nginx
        image: nginx:1.23-alpine  # Cambiar de 1.21 a 1.23
```

```bash
# Aplicar
kubectl apply -f webapp-deployment.yaml

# Ver rollout
kubectl rollout status deployment webapp
```

### Paso 4.5: Ver todos los ReplicaSets

```bash
kubectl get replicaset
```

**Output esperado**:
```
NAME                DESIRED   CURRENT   READY   AGE
webapp-7d4f8c6b9f   0         0         0       20m  <- v1.21 (primera versión)
webapp-8f5c9d7a8g   0         0         0       7m   <- v1.22 (segunda versión)
webapp-9g6d0e8b9h   4         4         4       1m   <- v1.23 (versión actual)
```

**Explicación**:
- Cada actualización crea un NUEVO ReplicaSet
- Los viejos quedan en 0 réplicas (para rollback)
- El historial se mantiene según `revisionHistoryLimit`

### ✅ Verificación

Ejecuta:
```bash
kubectl rollout history deployment webapp
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>
```

**Nota**: En el siguiente laboratorio aprenderemos a agregar `change-cause` descriptivo.

---

## 🎓 Desafío Final (Opcional)

Crea un Deployment con las siguientes características:

1. **Nombre**: `api-backend`
2. **Imagen**: `httpd:2.4-alpine`
3. **Réplicas**: 6
4. **Labels**: `app: api`, `tier: backend`
5. **Resources**:
   - Requests: 128Mi memoria, 200m CPU
   - Limits: 256Mi memoria, 500m CPU
6. **Port**: 8080

<details>
<summary>Solución</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-backend
  labels:
    app: api
    tier: backend
spec:
  replicas: 6
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        tier: backend
    spec:
      containers:
      - name: httpd
        image: httpd:2.4-alpine
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "128Mi"
            cpu: "200m"
          limits:
            memory: "256Mi"
            cpu: "500m"
```

```bash
kubectl apply -f api-backend-deployment.yaml
kubectl get deployment api-backend
kubectl get pods -l app=api
```
</details>

---

## 🧹 Limpieza

```bash
# Eliminar Deployments
kubectl delete deployment webapp
kubectl delete deployment api-backend  # Si hiciste el desafío

# Eliminar namespace
kubectl delete namespace lab-deployments

# Volver al namespace default
kubectl config set-context --current --namespace=default
```

Verificar:
```bash
kubectl get deployments -n lab-deployments
```

**Output esperado**: `No resources found in lab-deployments namespace.`

---

## 📝 Resumen

En este laboratorio aprendiste:

✅ **Crear Deployments** usando manifiestos YAML  
✅ **Jerarquía**: Deployment → ReplicaSet → Pod  
✅ **Owner References**: Relaciones de control entre recursos  
✅ **Escalado**: Imperativo (`kubectl scale`) y declarativo (YAML)  
✅ **Actualizaciones**: Cambio de imagen crea nuevo ReplicaSet  
✅ **Rolling Updates**: Actualización gradual automática  
✅ **Historial**: ReplicaSets viejos se mantienen para rollback  

---

## 🔗 Recursos Relacionados

- [README del módulo](../README.md)
- [Ejemplos de Deployments](../ejemplos/)
- [Laboratorio 2: Rolling Updates](lab-02-rolling-updates.md)
- [Documentación oficial](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

---

## ❓ Preguntas de Repaso

1. ¿Qué crea el Deployment automáticamente al aplicarse?
<details><summary>Respuesta</summary>Un ReplicaSet, que a su vez crea los Pods</details>

2. ¿Cuántos ReplicaSets existen después de una actualización?
<details><summary>Respuesta</summary>2 (o más): el actual con Pods, los anteriores en 0 réplicas</details>

3. ¿Qué pasa si elimino un Pod manualmente?
<details><summary>Respuesta</summary>El ReplicaSet crea automáticamente uno nuevo para mantener el número de réplicas deseado</details>

4. ¿Cuál es la diferencia entre `kubectl scale` y editar `replicas` en YAML?
<details><summary>Respuesta</summary>`kubectl scale` es imperativo (temporal), editar YAML es declarativo (permanente, recomendado)</details>

5. ¿Por qué quedan ReplicaSets viejos en 0 réplicas?
<details><summary>Respuesta</summary>Para permitir rollback rápido a versiones anteriores</details>

---

**¡Excelente trabajo! 🎉**  
Continúa con [Laboratorio 2: Rolling Updates](lab-02-rolling-updates.md) para profundizar en el proceso de actualización.
