# 🧪 Laboratorio 01: Creación de ReplicaSets

**Duración**: 30 minutos  
**Nivel**: Básico  
**Objetivo**: Crear, gestionar e inspeccionar ReplicaSets en Kubernetes

---

## 📋 Objetivos del Laboratorio

Al completar este laboratorio serás capaz de:

- ✅ Crear ReplicaSets usando manifiestos YAML
- ✅ Inspeccionar ReplicaSets y sus Pods
- ✅ Entender la relación entre ReplicaSet y Pod
- ✅ Modificar el número de réplicas
- ✅ Verificar owner references

---

## 🔧 Prerequisitos

```bash
# Verificar cluster funcionando
minikube status

# Verificar conexión
kubectl cluster-info

# Limpiar recursos previos
kubectl delete rs --all
kubectl delete pods --all
```

---

## 📝 Parte 1: Crear tu Primer ReplicaSet

### **1.1 Crear el Manifiesto**

Crea un archivo `mi-primer-replicaset.yaml`:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: webapp-rs
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
        environment: lab
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "50m"
          limits:
            memory: "64Mi"
            cpu: "100m"
```

### **1.2 Aplicar el Manifiesto**

```bash
# Crear ReplicaSet
kubectl apply -f mi-primer-replicaset.yaml

# Verificar creación
kubectl get rs

# Ver detalles
kubectl describe rs webapp-rs
```

**Salida esperada**:
```
NAME        DESIRED   CURRENT   READY   AGE
webapp-rs   3         3         3       10s
```

### **1.3 Inspeccionar Pods Creados**

```bash
# Listar Pods
kubectl get pods

# Ver Pods con labels
kubectl get pods --show-labels

# Ver Pods de este ReplicaSet específicamente
kubectl get pods -l app=webapp
```

**Salida esperada**:
```
NAME              READY   STATUS    RESTARTS   AGE   LABELS
webapp-rs-abc12   1/1     Running   0          20s   app=webapp,environment=lab
webapp-rs-def34   1/1     Running   0          20s   app=webapp,environment=lab
webapp-rs-ghi56   1/1     Running   0          20s   app=webapp,environment=lab
```

**❓ Preguntas**:
1. ¿Cuántos Pods se crearon?
2. ¿Qué labels tienen los Pods?
3. ¿Cómo se generan los nombres de los Pods?

<details>
<summary>📖 Ver respuestas</summary>

1. **3 Pods** (según `spec.replicas: 3`)
2. **Labels**: `app=webapp` y `environment=lab` (del template)
3. **Nombres**: `<replicaset-name>-<hash-aleatorio>` (webapp-rs-abc12)
</details>

---

## 🔍 Parte 2: Inspeccionar ReplicaSets

### **2.1 Ver Detalles del ReplicaSet**

```bash
# Ver detalles completos
kubectl describe rs webapp-rs

# Ver manifiesto completo en YAML
kubectl get rs webapp-rs -o yaml

# Ver solo spec
kubectl get rs webapp-rs -o jsonpath='{.spec}' | jq
```

### **2.2 Verificar Owner References**

```bash
# Obtener nombre de un Pod
POD_NAME=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')

# Ver owner reference del Pod
kubectl get pod $POD_NAME -o yaml | grep -A 10 ownerReferences
```

**Salida esperada**:
```yaml
ownerReferences:
- apiVersion: apps/v1
  kind: ReplicaSet
  name: webapp-rs
  uid: 12345-67890-abcde
  controller: true
  blockOwnerDeletion: true
```

**❓ Pregunta**: ¿Qué significa `controller: true`?

<details>
<summary>📖 Ver respuesta</summary>

`controller: true` indica que el ReplicaSet **controla** este Pod:
- El ReplicaSet gestiona el ciclo de vida del Pod
- Si el Pod falla, el ReplicaSet lo recrea
- Si eliminas el ReplicaSet, el Pod también se elimina
</details>

### **2.3 Ver Eventos del ReplicaSet**

```bash
# Ver eventos relacionados con el ReplicaSet
kubectl get events --field-selector involvedObject.name=webapp-rs

# Ver eventos en orden cronológico
kubectl get events --field-selector involvedObject.name=webapp-rs --sort-by='.lastTimestamp'
```

---

## 📊 Parte 3: Escalar ReplicaSets

### **3.1 Escalado Imperativo**

```bash
# Escalar a 5 réplicas
kubectl scale rs webapp-rs --replicas=5

# Ver en tiempo real
kubectl get pods -l app=webapp --watch
```

Presiona `Ctrl+C` para detener el watch.

```bash
# Verificar
kubectl get rs webapp-rs
```

**Salida esperada**:
```
NAME        DESIRED   CURRENT   READY   AGE
webapp-rs   5         5         5       2m
```

### **3.2 Escalar a 10 Réplicas**

```bash
# Escalar a 10
kubectl scale rs webapp-rs --replicas=10

# Ver distribución en nodos
kubectl get pods -l app=webapp -o wide
```

### **3.3 Reducir Réplicas**

```bash
# Reducir a 2 réplicas
kubectl scale rs webapp-rs --replicas=2

# Ver qué Pods se eliminan
kubectl get pods -l app=webapp --watch
```

**❓ Pregunta**: ¿Qué Pods elimina el ReplicaSet cuando reduces las réplicas?

<details>
<summary>📖 Ver respuesta</summary>

ReplicaSet generalmente elimina los **Pods más recientes** primero. Esto se hace para:
- Mantener los Pods más estables (los antiguos probablemente estén funcionando bien)
- Respetar el orden de creación
</details>

### **3.4 Escalado Declarativo**

```bash
# Editar manifiesto
kubectl edit rs webapp-rs

# Cambiar replicas: 7
# Guardar y salir (:wq en vim)

# Verificar
kubectl get rs webapp-rs
kubectl get pods -l app=webapp
```

---

## 🧪 Parte 4: Experimentar con Selectores

### **4.1 Crear ReplicaSet con Selector Complejo**

Crea `replicaset-selector.yaml`:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: advanced-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: advanced
    matchExpressions:
    - key: tier
      operator: In
      values:
      - frontend
      - backend
  template:
    metadata:
      labels:
        app: advanced
        tier: frontend
        version: "v1"
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
```

```bash
# Aplicar
kubectl apply -f replicaset-selector.yaml

# Ver Pods
kubectl get pods -l app=advanced --show-labels
```

### **4.2 Verificar Selector**

```bash
# Ver el selector del ReplicaSet
kubectl get rs advanced-rs -o jsonpath='{.spec.selector}' | jq

# Ver qué Pods coinciden
kubectl get pods -l app=advanced -l 'tier in (frontend,backend)'
```

---

## 🔥 Parte 5: Desafíos Prácticos

### **Desafío 1: ReplicaSet con Redis**

Crea un ReplicaSet con:
- Nombre: `redis-rs`
- Réplicas: 4
- Imagen: `redis:alpine`
- Label: `app: cache`
- Puerto: 6379

<details>
<summary>💡 Ver solución</summary>

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: redis-rs
spec:
  replicas: 4
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 6379
```

```bash
kubectl apply -f redis-rs.yaml
kubectl get pods -l app=cache
```
</details>

### **Desafío 2: Inspeccionar Estado**

Para el ReplicaSet `webapp-rs`:

1. ¿Cuál es el UID del ReplicaSet?
2. ¿Cuántos Pods están en estado Running?
3. ¿Qué versión de nginx están usando?

<details>
<summary>💡 Ver comandos</summary>

```bash
# 1. UID del ReplicaSet
kubectl get rs webapp-rs -o jsonpath='{.metadata.uid}'

# 2. Pods Running
kubectl get pods -l app=webapp --field-selector=status.phase=Running --no-headers | wc -l

# 3. Versión de nginx
kubectl get pods -l app=webapp -o jsonpath='{.items[0].spec.containers[0].image}'
```
</details>

### **Desafío 3: Escalar Dinámicamente**

Escala `webapp-rs` siguiendo esta secuencia:
1. 3 → 7 réplicas (imperativo)
2. 7 → 12 réplicas (editando el manifiesto)
3. 12 → 5 réplicas (imperativo)

<details>
<summary>💡 Ver comandos</summary>

```bash
# 1. Escalar a 7
kubectl scale rs webapp-rs --replicas=7
kubectl get rs webapp-rs

# 2. Escalar a 12 (editar)
kubectl edit rs webapp-rs
# Cambiar: replicas: 12
kubectl get rs webapp-rs

# 3. Escalar a 5
kubectl scale rs webapp-rs --replicas=5
kubectl get rs webapp-rs
```
</details>

---

## 📊 Parte 6: Verificación Final

### **Checklist**

Verifica que puedes hacer lo siguiente:

- [ ] Crear un ReplicaSet desde un archivo YAML
- [ ] Listar todos los ReplicaSets
- [ ] Ver Pods creados por un ReplicaSet
- [ ] Escalar un ReplicaSet (imperativo y declarativo)
- [ ] Verificar owner references en un Pod
- [ ] Ver eventos de un ReplicaSet
- [ ] Usar selectores para filtrar Pods

### **Comandos de Resumen**

```bash
# Ver todos los ReplicaSets
kubectl get rs

# Ver todos los Pods con sus labels
kubectl get pods --show-labels

# Ver qué Pods pertenecen a cada ReplicaSet
kubectl get pods -o custom-columns=\
NAME:.metadata.name,\
REPLICASET:.metadata.ownerReferences[0].name,\
LABELS:.metadata.labels
```

---

## 🧹 Limpieza

```bash
# Eliminar todos los ReplicaSets creados
kubectl delete rs webapp-rs advanced-rs redis-rs

# Verificar que los Pods también se eliminaron
kubectl get pods

# Si quedan Pods, eliminarlos
kubectl delete pods --all
```

---

## 📚 Conceptos Aprendidos

✅ **ReplicaSet**: Controlador que garantiza N réplicas de un Pod  
✅ **Selector**: Define qué Pods gestiona el ReplicaSet usando labels  
✅ **Template**: Plantilla para crear nuevos Pods  
✅ **Owner References**: Marca de propiedad en cada Pod  
✅ **Escalado**: Cambiar número de réplicas (imperativo y declarativo)  

---

## ➡️ Próximos Pasos

Continúa con:
- [Laboratorio 02: Auto-Recuperación y Escalado](./lab-02-auto-recuperacion.md)
- [Ejemplos de ReplicaSets](../ejemplos/README.md)

---

**Última actualización**: Noviembre 2025  
**Versión**: 1.0
