# 🧪 Laboratorio 03: Ownership, Limitaciones y Transición a Deployments

**Duración**: 50 minutos  
**Nivel**: Avanzado  
**Objetivo**: Comprender owner references, limitaciones de ReplicaSets y por qué usar Deployments

---

## 📋 Objetivos del Laboratorio

Al completar este laboratorio serás capaz de:

- ✅ Comprender owner references y adopción de Pods
- ✅ Demostrar el problema de adopción de Pods huérfanos
- ✅ Experimentar con limitaciones de actualización
- ✅ Entender por qué ReplicaSets no soportan rolling updates
- ✅ Comparar ReplicaSets vs Deployments

---

## 🔧 Prerequisitos

```bash
# Limpiar recursos previos
kubectl delete rs --all
kubectl delete pods --all
kubectl delete deploy --all
```

---

## 🔗 Parte 1: Owner References

### **1.1 Crear ReplicaSet y Analizar Owner**

Crea `ownership-test.yaml`:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: owner-test-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ownership-demo
  template:
    metadata:
      labels:
        app: ownership-demo
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
```

```bash
# Crear ReplicaSet
kubectl apply -f ownership-test.yaml

# Ver Pods creados
kubectl get pods -l app=ownership-demo
```

### **1.2 Examinar Owner References**

```bash
# Obtener nombre de un Pod
POD=$(kubectl get pods -l app=ownership-demo -o jsonpath='{.items[0].metadata.name}')

# Ver owner reference completo
kubectl get pod $POD -o yaml | grep -A 15 ownerReferences
```

**Salida esperada**:
```yaml
ownerReferences:
- apiVersion: apps/v1
  kind: ReplicaSet
  name: owner-test-rs
  uid: 12345-67890-abcde
  controller: true
  blockOwnerDeletion: true
```

**Análisis de campos**:
- `kind: ReplicaSet`: Tipo de owner
- `name: owner-test-rs`: Nombre del owner
- `uid`: ID único del ReplicaSet
- `controller: true`: Este ReplicaSet controla el Pod
- `blockOwnerDeletion: true`: No se puede eliminar el RS mientras el Pod exista

### **1.3 Verificar Cascada de Eliminación**

```bash
# Eliminar ReplicaSet
kubectl delete rs owner-test-rs

# Ver Pods inmediatamente
kubectl get pods -l app=ownership-demo
# Output: No resources found ← Todos eliminados por owner reference
```

### **1.4 Eliminar SIN Cascada (Orphan)**

```bash
# Recrear ReplicaSet
kubectl apply -f ownership-test.yaml

# Eliminar ReplicaSet pero MANTENER Pods
kubectl delete rs owner-test-rs --cascade=orphan

# Ver Pods
kubectl get pods -l app=ownership-demo
# Output: Pods siguen existiendo ← Ahora son huérfanos
```

```bash
# Ver owner references AHORA
POD=$(kubectl get pods -l app=ownership-demo -o jsonpath='{.items[0].metadata.name}')
kubectl get pod $POD -o yaml | grep -A 5 ownerReferences
# Output: (vacío) ← Sin owner
```

---

## ⚠️ Parte 2: Peligro de Adopción

### **2.1 Crear Pods Huérfanos**

Crea `orphan-pods.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: orphan-pod-1
  labels:
    app: dangerous-demo
    version: "old"
spec:
  containers:
  - name: nginx
    image: nginx:1.20-alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: orphan-pod-2
  labels:
    app: dangerous-demo
    version: "old"
spec:
  containers:
  - name: nginx
    image: nginx:1.21-alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: orphan-pod-3
  labels:
    app: dangerous-demo
    version: "old"
spec:
  containers:
  - name: nginx
    image: nginx:alpine
```

```bash
# Crear Pods manualmente
kubectl apply -f orphan-pods.yaml

# Verificar que NO tienen owner
kubectl get pods -l app=dangerous-demo
kubectl get pod orphan-pod-1 -o jsonpath='{.metadata.ownerReferences}'
# Output: (vacío)
```

### **2.2 Crear ReplicaSet que Adoptará los Pods**

Crea `adopting-replicaset.yaml`:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: adopting-rs
spec:
  replicas: 5  # Pedir 5, ya hay 3 huérfanos
  selector:
    matchLabels:
      app: dangerous-demo  # ← Coincide con los huérfanos
  template:
    metadata:
      labels:
        app: dangerous-demo
        version: "new"
    spec:
      containers:
      - name: nginx
        image: nginx:1.22-alpine  # ← Versión DIFERENTE
```

```bash
# Crear ReplicaSet
kubectl apply -f adopting-replicaset.yaml

# Ver qué pasó
kubectl get pods -l app=dangerous-demo --show-labels
```

**Resultado**:
```
NAME             READY   STATUS    AGE   LABELS                        IMAGE
orphan-pod-1     1/1     Running   2m    app=dangerous-demo,version=old   nginx:1.20-alpine ← ADOPTADO
orphan-pod-2     1/1     Running   2m    app=dangerous-demo,version=old   nginx:1.21-alpine ← ADOPTADO
orphan-pod-3     1/1     Running   2m    app=dangerous-demo,version=old   nginx:alpine      ← ADOPTADO
adopting-rs-abc  1/1     Running   5s    app=dangerous-demo,version=new   nginx:1.22-alpine ← NUEVO
adopting-rs-def  1/1     Running   5s    app=dangerous-demo,version=new   nginx:1.22-alpine ← NUEVO
```

### **2.3 Verificar el Problema**

```bash
# Ver versiones de nginx en cada Pod
kubectl get pods -l app=dangerous-demo -o custom-columns=\
NAME:.metadata.name,\
IMAGE:.spec.containers[0].image,\
OWNER:.metadata.ownerReferences[0].name

# Ver owner references de un huérfano adoptado
kubectl get pod orphan-pod-1 -o yaml | grep -A 5 ownerReferences
```

**Observa**: 
- ⚠️ 5 Pods con **3 versiones diferentes** de nginx
- ⚠️ Configuración **inconsistente**
- ⚠️ ReplicaSet NO actualiza los Pods adoptados

**❓ Pregunta**: ¿Cómo solucionarías esto?

<details>
<summary>💡 Ver solución</summary>

```bash
# Opción 1: Eliminar Pods huérfanos manualmente
kubectl delete pod orphan-pod-1 orphan-pod-2 orphan-pod-3
# ReplicaSet creará nuevos Pods con la versión correcta

# Opción 2: Usar labels únicos siempre
# Evitar crear Pods manuales con labels genéricos
```
</details>

---

## 🚫 Parte 3: Limitación de Updates

### **3.1 Crear ReplicaSet con Versión Específica**

Crea `no-update-demo.yaml`:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: no-update-rs
spec:
  replicas: 4
  selector:
    matchLabels:
      app: update-test
  template:
    metadata:
      labels:
        app: update-test
        version: "v1"
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine  # ← Versión inicial
        ports:
        - containerPort: 80
```

```bash
# Crear
kubectl apply -f no-update-demo.yaml

# Verificar versión de imagen
kubectl get pods -l app=update-test -o jsonpath='{.items[*].spec.containers[0].image}'
# Output: nginx:1.20-alpine nginx:1.20-alpine nginx:1.20-alpine nginx:1.20-alpine
```

### **3.2 Intentar Actualizar la Imagen**

Edita `no-update-demo.yaml` y cambia:

```yaml
containers:
- name: nginx
  image: nginx:1.21-alpine  # ← Cambiar a 1.21
```

```bash
# Aplicar cambios
kubectl apply -f no-update-demo.yaml

# Ver versión de Pods
kubectl get pods -l app=update-test -o jsonpath='{.items[*].spec.containers[0].image}'
# Output: nginx:1.20-alpine nginx:1.20-alpine nginx:1.20-alpine nginx:1.20-alpine
# ❌ NO CAMBIÓ
```

### **3.3 Verificar que el ReplicaSet SÍ se Actualizó**

```bash
# Ver template del ReplicaSet
kubectl get rs no-update-rs -o jsonpath='{.spec.template.spec.containers[0].image}'
# Output: nginx:1.21-alpine ← Template actualizado
```

**Conclusión**: 
- ✅ ReplicaSet actualizado
- ❌ Pods existentes NO actualizados
- ⚠️ **Inconsistencia** entre template y Pods running

### **3.4 Forzar Actualización (Manual)**

```bash
# Eliminar 1 Pod
POD=$(kubectl get pods -l app=update-test -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD

# Ver versiones AHORA
kubectl get pods -l app=update-test -o jsonpath='{.items[*].spec.containers[0].image}'
# Output: nginx:1.20-alpine nginx:1.20-alpine nginx:1.20-alpine nginx:1.21-alpine
#         ↑ viejos          ↑ viejos          ↑ viejos          ↑ NUEVO con v1.21
```

**Problema**: Tienes que eliminar TODOS los Pods manualmente uno por uno:

```bash
# Eliminar todos los Pods viejos
for pod in $(kubectl get pods -l app=update-test -o name); do
  kubectl delete $pod
  sleep 5  # Esperar que se cree el nuevo
done

# Verificar que TODOS tienen nueva versión
kubectl get pods -l app=update-test -o jsonpath='{.items[*].spec.containers[0].image}'
# Output: nginx:1.21-alpine nginx:1.21-alpine nginx:1.21-alpine nginx:1.21-alpine
```

**❌ Problemas de este enfoque**:
1. **Manual** - Tienes que hacerlo tú
2. **Downtime** - Mientras eliminas Pods hay menos réplicas
3. **Sin rollback** - Si falla, no puedes volver atrás
4. **Sin historial** - No sabes qué versiones corriste antes

---

## 🆚 Parte 4: Deployments vs ReplicaSets

### **4.1 Crear Deployment (Comparación)**

Crea `deployment-comparison.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-demo
spec:
  replicas: 4
  selector:
    matchLabels:
      app: deploy-test
  template:
    metadata:
      labels:
        app: deploy-test
        version: "v1"
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
```

```bash
# Crear Deployment
kubectl apply -f deployment-comparison.yaml

# Ver Deployment
kubectl get deploy

# Ver ReplicaSet creado AUTOMÁTICAMENTE por el Deployment
kubectl get rs

# Ver Pods
kubectl get pods -l app=deploy-test
```

**Observa**: 
```
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment-demo                    4/4     4            4           10s

NAME                               DESIRED   CURRENT   READY   AGE
deployment-demo-5d4f7b8c9d         4         4         4       10s  ← ReplicaSet auto-creado

NAME                               READY   STATUS    RESTARTS   AGE
deployment-demo-5d4f7b8c9d-abc12   1/1     Running   0          10s
deployment-demo-5d4f7b8c9d-def34   1/1     Running   0          10s
deployment-demo-5d4f7b8c9d-ghi56   1/1     Running   0          10s
deployment-demo-5d4f7b8c9d-jkl78   1/1     Running   0          10s
```

### **4.2 Actualizar Deployment (Rolling Update Automático)**

Edita `deployment-comparison.yaml`:

```yaml
containers:
- name: nginx
  image: nginx:1.21-alpine  # ← Cambiar versión
```

```bash
# Aplicar cambios
kubectl apply -f deployment-comparison.yaml

# Observar rolling update EN TIEMPO REAL
kubectl get pods -l app=deploy-test --watch
```

**Verás**:
```
NAME                               READY   STATUS              RESTARTS   AGE
deployment-demo-5d4f7b8c9d-abc12   1/1     Running             0          2m
deployment-demo-5d4f7b8c9d-def34   1/1     Running             0          2m
deployment-demo-5d4f7b8c9d-ghi56   1/1     Running             0          2m
deployment-demo-5d4f7b8c9d-jkl78   1/1     Running             0          2m
deployment-demo-7f9c8d6e5a-xyz12   0/1     ContainerCreating   0          1s   ← NUEVO Pod creándose
deployment-demo-7f9c8d6e5a-xyz12   1/1     Running             0          3s   ← NUEVO listo
deployment-demo-5d4f7b8c9d-abc12   1/1     Terminating         0          2m   ← VIEJO terminando
deployment-demo-7f9c8d6e5a-uvw34   0/1     ContainerCreating   0          1s   ← NUEVO creándose
...
```

**✅ Ventajas del Deployment**:
1. **Automático** - Rolling update sin intervención
2. **Zero downtime** - Siempre hay Pods running
3. **Gradual** - Crea nuevos antes de eliminar viejos
4. **Controlado** - Puedes pausar/reanudar

### **4.3 Ver Historial de Versiones**

```bash
# Ver historial de revisiones
kubectl rollout history deployment deployment-demo

# Ver detalles de una revisión
kubectl rollout history deployment deployment-demo --revision=2
```

### **4.4 Rollback a Versión Anterior**

```bash
# Hacer rollback a revisión anterior
kubectl rollout undo deployment deployment-demo

# Ver proceso de rollback
kubectl get pods -l app=deploy-test --watch

# Verificar versión
kubectl get pods -l app=deploy-test -o jsonpath='{.items[0].spec.containers[0].image}'
# Output: nginx:1.20-alpine ← Volvió a la versión anterior
```

### **4.5 Rollback a Revisión Específica**

```bash
# Ver historial
kubectl rollout history deployment deployment-demo

# Rollback a revisión 1
kubectl rollout undo deployment deployment-demo --to-revision=1

# Verificar
kubectl get pods -l app=deploy-test -o jsonpath='{.items[*].spec.containers[0].image}'
```

---

## 📊 Parte 5: Comparación Side-by-Side

### **5.1 Tabla Comparativa**

| Característica | ReplicaSet | Deployment |
|----------------|------------|------------|
| Auto-recuperación | ✅ Sí | ✅ Sí |
| Escalado | ✅ Sí | ✅ Sí |
| Rolling Updates | ❌ No | ✅ Sí |
| Rollback | ❌ No | ✅ Sí |
| Historial | ❌ No | ✅ Sí |
| Estrategias de deploy | ❌ No | ✅ Sí (RollingUpdate, Recreate) |
| Pause/Resume | ❌ No | ✅ Sí |
| **Uso recomendado** | Testing/aprendizaje | **Producción** |

### **5.2 Demo Final: Deployment Completo**

Crea `production-ready.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-app
  labels:
    app: production
    environment: demo
spec:
  replicas: 5
  
  # Estrategia de actualización
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Cuántos Pods extra durante update
      maxUnavailable: 0  # Cuántos Pods pueden estar down
  
  selector:
    matchLabels:
      app: production
  
  template:
    metadata:
      labels:
        app: production
        version: "v1.0"
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
        
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
```

```bash
# Crear Deployment
kubectl apply -f production-ready.yaml

# Ver estado
kubectl get deploy production-app
kubectl get rs
kubectl get pods -l app=production

# Actualizar (cambiar image a nginx:1.21-alpine)
kubectl set image deployment/production-app app=nginx:1.21-alpine

# Observar rolling update
kubectl rollout status deployment production-app

# Ver historial
kubectl rollout history deployment production-app
```

---

## 🏆 Parte 6: Desafíos Finales

### **Desafío 1: Comparar Tiempos**

Mide el tiempo de actualización manual (ReplicaSet) vs automática (Deployment):

1. ReplicaSet: Cambiar imagen eliminando Pods manualmente
2. Deployment: Cambiar imagen con rolling update
3. Comparar tiempos

<details>
<summary>💡 Ver script</summary>

```bash
# ReplicaSet (manual)
START=$(date +%s)
kubectl apply -f no-update-demo.yaml  # Con nueva imagen
for pod in $(kubectl get pods -l app=update-test -o name); do
  kubectl delete $pod
  sleep 5
done
END=$(date +%s)
echo "ReplicaSet: $((END - START)) segundos"

# Deployment (automático)
START=$(date +%s)
kubectl set image deployment/deployment-demo nginx=nginx:1.22-alpine
kubectl rollout status deployment deployment-demo
END=$(date +%s)
echo "Deployment: $((END - START)) segundos"
```
</details>

### **Desafío 2: Simulador de Fallo**

Durante un rolling update de Deployment, elimina Pods manualmente. ¿Qué pasa?

<details>
<summary>💡 Ver experimento</summary>

```bash
# Terminal 1: Rolling update
kubectl set image deployment/production-app app=nginx:1.22-alpine
kubectl rollout status deployment production-app

# Terminal 2: Eliminar Pods durante update
while true; do
  POD=$(kubectl get pods -l app=production -o name | head -1)
  kubectl delete $POD
  sleep 2
done

# Resultado: Deployment mantiene el número de réplicas y completa el update
```
</details>

---

## 📚 Conceptos Aprendidos

✅ **Owner References**: Control de ciclo de vida de Pods  
✅ **Adopción**: ReplicaSets pueden adoptar Pods huérfanos (peligroso)  
✅ **Limitación de Updates**: ReplicaSets NO actualizan Pods existentes  
✅ **Rolling Updates**: Solo Deployments soportan updates automáticos  
✅ **Rollback**: Solo Deployments permiten volver a versiones anteriores  
✅ **Best Practice**: **Siempre usa Deployments en producción**  

---

## 🧹 Limpieza

```bash
kubectl delete rs owner-test-rs adopting-rs no-update-rs
kubectl delete deploy deployment-demo production-app
kubectl delete pods --all
```

---

## ➡️ Próximos Pasos

- [Módulo 07: Deployments y Rolling Updates](../../modulo-07-deployments/README.md)
- [Ejemplos de Limitaciones](../ejemplos/05-limitaciones/)

---

**Última actualización**: Noviembre 2025  
**Versión**: 1.0
