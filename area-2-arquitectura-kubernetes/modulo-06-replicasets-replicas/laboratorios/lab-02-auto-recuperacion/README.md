# 🧪 Laboratorio 02: Auto-Recuperación y Escalado Dinámico

**Duración**: 40 minutos  
**Nivel**: Intermedio  
**Objetivo**: Demostrar auto-recuperación y gestión dinámica de réplicas

---

## 📋 Objetivos del Laboratorio

Al completar este laboratorio serás capaz de:

- ✅ Demostrar auto-recuperación (self-healing) de Pods
- ✅ Observar cómo ReplicaSet mantiene estado deseado
- ✅ Simular fallos y ver recuperación automática
- ✅ Escalar dinámicamente bajo carga simulada
- ✅ Analizar comportamiento de Pods durante escalado

---

## 🔧 Prerequisitos

```bash
# Verificar cluster
minikube status

# Limpiar recursos previos
kubectl delete rs --all
kubectl delete pods --all
```

---

## 🔄 Parte 1: Auto-Recuperación Básica

### **1.1 Crear ReplicaSet para Testing**

Crea `auto-heal-test.yaml`:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: autoheal-rs
  labels:
    app: autoheal
    test: self-healing
spec:
  replicas: 3
  selector:
    matchLabels:
      app: autoheal
  template:
    metadata:
      labels:
        app: autoheal
        version: "1.0"
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
```

```bash
# Aplicar
kubectl apply -f auto-heal-test.yaml

# Verificar
kubectl get rs autoheal-rs
kubectl get pods -l app=autoheal
```

### **1.2 Demostrar Auto-Recuperación**

**Terminal 1** - Observar en tiempo real:
```bash
kubectl get pods -l app=autoheal --watch
```

**Terminal 2** - Eliminar un Pod:
```bash
# Obtener nombre del primer Pod
POD_NAME=$(kubectl get pods -l app=autoheal -o jsonpath='{.items[0].metadata.name}')

# Eliminar el Pod
kubectl delete pod $POD_NAME

# Ver estado
kubectl get pods -l app=autoheal
```

**Observa** en Terminal 1:
```
NAME                  READY   STATUS              RESTARTS   AGE
autoheal-rs-abc12     1/1     Terminating         0          2m
autoheal-rs-def34     1/1     Running             0          2m
autoheal-rs-ghi56     1/1     Running             0          2m
autoheal-rs-xyz99     0/1     ContainerCreating   0          1s   ← NUEVO POD
autoheal-rs-xyz99     1/1     Running             0          3s   ← LISTO
```

**❓ Preguntas**:
1. ¿Cuánto tardó en crear el nuevo Pod?
2. ¿El nuevo Pod tiene el mismo nombre que el eliminado?
3. ¿Qué pasó con el estado deseado vs actual?

<details>
<summary>📖 Ver respuestas</summary>

1. **Típicamente 5-15 segundos** (depende del cluster)
2. **No** - Nuevo nombre con hash diferente (autoheal-rs-xyz99)
3. **Estado deseado (3) = Estado actual (3)** - ReplicaSet reconcilió automáticamente
</details>

---

## 💣 Parte 2: Fallos Masivos

### **2.1 Eliminar Múltiples Pods**

```bash
# Eliminar 2 Pods al mismo tiempo
kubectl delete pods -l app=autoheal --field-selector metadata.name!=autoheal-rs-abc12

# O eliminar específicamente 2 Pods
POD1=$(kubectl get pods -l app=autoheal -o jsonpath='{.items[0].metadata.name}')
POD2=$(kubectl get pods -l app=autoheal -o jsonpath='{.items[1].metadata.name}')
kubectl delete pod $POD1 $POD2

# Observar recuperación
kubectl get pods -l app=autoheal --watch
```

### **2.2 Eliminar TODOS los Pods**

```bash
# Eliminar todos los Pods del ReplicaSet
kubectl delete pods -l app=autoheal

# Observar cómo se recrean TODOS
kubectl get pods -l app=autoheal --watch
```

**❓ Pregunta**: ¿Qué pasaría si eliminas el ReplicaSet?

<details>
<summary>💡 Ver experimento</summary>

```bash
# Ver Pods actuales
kubectl get pods -l app=autoheal

# Eliminar ReplicaSet
kubectl delete rs autoheal-rs

# Ver Pods AHORA
kubectl get pods -l app=autoheal
# Output: No resources found ← Todos eliminados

# ¿Por qué?
# Owner Reference: blockOwnerDeletion: true
# Al eliminar el ReplicaSet, se eliminan todos sus Pods
```

Vuelve a crear el ReplicaSet:
```bash
kubectl apply -f auto-heal-test.yaml
```
</details>

---

## 🔥 Parte 3: Simular Fallos de Contenedor

### **3.1 Provocar Crash de Contenedor**

```bash
# Entrar a un Pod
POD_NAME=$(kubectl get pods -l app=autoheal -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -- sh

# Dentro del Pod, matar nginx
killall nginx
exit
```

```bash
# Ver qué pasó
kubectl get pods -l app=autoheal
kubectl describe pod $POD_NAME
```

**Observa** el campo `Restart Count`:
```
NAME                  READY   STATUS    RESTARTS      AGE
autoheal-rs-abc12     1/1     Running   1 (10s ago)   5m  ← RESTART!
```

### **3.2 Provocar CrashLoopBackOff**

Crea `crashloop-test.yaml`:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: crashloop-rs
spec:
  replicas: 2
  selector:
    matchLabels:
      app: crashloop
  template:
    metadata:
      labels:
        app: crashloop
    spec:
      containers:
      - name: failing-container
        image: busybox:latest
        command:
        - sh
        - -c
        - |
          echo "Contenedor iniciado"
          sleep 5
          echo "¡Voy a crashear!"
          exit 1  # ← Provoca crash
```

```bash
# Crear
kubectl apply -f crashloop-test.yaml

# Observar ciclo de reintentos
kubectl get pods -l app=crashloop --watch
```

**Verás**:
```
NAME                 READY   STATUS             RESTARTS     AGE
crashloop-rs-abc12   0/1     CrashLoopBackOff   3 (20s ago)  2m
crashloop-rs-def34   0/1     CrashLoopBackOff   3 (25s ago)  2m
```

```bash
# Limpiar
kubectl delete rs crashloop-rs
```

---

## 📈 Parte 4: Escalado Dinámico

### **4.1 Escalar Durante Operación**

```bash
# Crear ReplicaSet con 5 réplicas
kubectl scale rs autoheal-rs --replicas=5

# Observar creación de nuevos Pods
kubectl get pods -l app=autoheal --watch
```

**Terminal 2** - Mientras se crean:
```bash
# Inmediatamente escalar a 10
kubectl scale rs autoheal-rs --replicas=10
```

**Observa**: ReplicaSet ajusta dinámicamente mientras ya está escalando.

### **4.2 Escalado Incremental**

Script para escalar gradualmente:

```bash
# Escalar de 10 a 20 en incrementos de 2
for i in {10..20..2}; do
  echo "Escalando a $i réplicas..."
  kubectl scale rs autoheal-rs --replicas=$i
  sleep 3
  kubectl get rs autoheal-rs
done
```

### **4.3 Reducir Réplicas Gradualmente**

```bash
# Reducir de 20 a 5 en decrementos de 3
for i in {20..5..-3}; do
  echo "Reduciendo a $i réplicas..."
  kubectl scale rs autoheal-rs --replicas=$i
  sleep 2
  kubectl get pods -l app=autoheal --no-headers | wc -l
done
```

---

## 🧪 Parte 5: Prueba de Carga Simulada

### **5.1 Crear ReplicaSet con Aplicación Web**

Crea `webapp-load.yaml`:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: webapp-load
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp-load
  template:
    metadata:
      labels:
        app: webapp-load
    spec:
      containers:
      - name: webapp
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

```bash
kubectl apply -f webapp-load.yaml
```

### **5.2 Crear Service para Acceso**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-svc
spec:
  selector:
    app: webapp-load
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

```bash
kubectl apply -f webapp-service.yaml
```

### **5.3 Generar Carga**

**Terminal 1** - Monitorear Pods:
```bash
kubectl get pods -l app=webapp-load --watch
```

**Terminal 2** - Generar carga:
```bash
# Crear Pod generador de carga
kubectl run load-generator --image=busybox --rm -it --restart=Never -- /bin/sh

# Dentro del Pod, generar requests
while true; do 
  wget -q -O- http://webapp-svc
  sleep 0.1
done
```

**Terminal 3** - Escalar bajo carga:
```bash
# Escalar a 10 réplicas
kubectl scale rs webapp-load --replicas=10

# Ver distribución
kubectl get pods -l app=webapp-load -o wide
```

---

## 🔍 Parte 6: Análisis de Comportamiento

### **6.1 Tiempo de Recuperación**

Script para medir tiempo de auto-recuperación:

```bash
# !/bin/bash

echo "Midiendo tiempo de auto-recuperación..."

# Obtener Pod a eliminar
POD=$(kubectl get pods -l app=autoheal -o jsonpath='{.items[0].metadata.name}')

# Timestamp inicial
START=$(date +%s)

# Eliminar Pod
kubectl delete pod $POD

# Esperar a que haya 3 Pods Running de nuevo
while [ $(kubectl get pods -l app=autoheal --field-selector=status.phase=Running --no-headers | wc -l) -lt 3 ]; do
  sleep 1
done

# Timestamp final
END=$(date +%s)

# Calcular diferencia
DIFF=$((END - START))

echo "Tiempo de recuperación: ${DIFF} segundos"
```

### **6.2 Ver Historial de Eventos**

```bash
# Ver todos los eventos del ReplicaSet
kubectl get events --field-selector involvedObject.name=autoheal-rs --sort-by='.lastTimestamp'

# Ver eventos de creación de Pods
kubectl get events --field-selector reason=SuccessfulCreate

# Ver eventos de eliminación
kubectl get events --field-selector reason=Killing
```

### **6.3 Analizar Owner References**

```bash
# Ver owner de cada Pod
kubectl get pods -l app=autoheal -o custom-columns=\
NAME:.metadata.name,\
OWNER:.metadata.ownerReferences[0].name,\
UID:.metadata.ownerReferences[0].uid

# Comparar con UID del ReplicaSet
kubectl get rs autoheal-rs -o jsonpath='{.metadata.uid}'
```

---

## 🏆 Parte 7: Desafíos Avanzados

### **Desafío 1: Recuperación Múltiple**

Elimina 5 Pods simultáneamente de un ReplicaSet con 10 réplicas:

1. Crea ReplicaSet con 10 réplicas
2. Elimina 5 Pods al mismo tiempo
3. Mide el tiempo de recuperación total

<details>
<summary>💡 Ver solución</summary>

```bash
# Crear con 10 réplicas
kubectl scale rs autoheal-rs --replicas=10

# Esperar a que todos estén Running
kubectl wait --for=condition=ready pod -l app=autoheal --timeout=60s

# Eliminar 5 Pods
kubectl delete pods -l app=autoheal --field-selector metadata.name!=autoheal-rs-abc12,metadata.name!=autoheal-rs-def34,metadata.name!=autoheal-rs-ghi56,metadata.name!=autoheal-rs-jkl78,metadata.name!=autoheal-rs-mno90

# O más simple:
PODS=$(kubectl get pods -l app=autoheal -o name | head -5)
kubectl delete $PODS

# Observar recuperación
kubectl get pods -l app=autoheal --watch
```
</details>

### **Desafío 2: Escalado Bajo Carga**

Mientras hay carga activa:

1. Escalar de 3 a 20 réplicas
2. Reducir de 20 a 5 réplicas
3. Verificar que NO hubo downtime

<details>
<summary>💡 Ver solución</summary>

```bash
# Terminal 1: Generar carga continua
kubectl run load-test --image=busybox --rm -it -- /bin/sh
while true; do wget -q -O- http://webapp-svc && echo " OK"; sleep 0.5; done

# Terminal 2: Escalar
kubectl scale rs webapp-load --replicas=20
sleep 10
kubectl scale rs webapp-load --replicas=5

# Terminal 3: Monitorear
kubectl get pods -l app=webapp-load --watch

# Verificar: La carga en Terminal 1 nunca debe fallar
```
</details>

### **Desafío 3: Auto-Recuperación Extrema**

¿Qué pasa si eliminas TODOS los Pods cada 5 segundos durante 1 minuto?

<details>
<summary>💡 Ver script</summary>

```bash
# !/bin/bash

END_TIME=$(($(date +%s) + 60))  # 1 minuto desde ahora

while [ $(date +%s) -lt $END_TIME ]; do
  echo "Eliminando todos los Pods..."
  kubectl delete pods -l app=autoheal --force --grace-period=0
  sleep 5
done

echo "Test finalizado. Verificando estado..."
kubectl get rs autoheal-rs
kubectl get pods -l app=autoheal
```

**Resultado esperado**: ReplicaSet siempre mantiene 3 réplicas Running (o intentando)
</details>

---

## 📊 Parte 8: Verificación Final

### **Checklist**

- [ ] Demostrar auto-recuperación eliminando 1 Pod
- [ ] Eliminar múltiples Pods y ver recuperación
- [ ] Provocar crash de contenedor y ver restart
- [ ] Escalar dinámicamente de 3 a 20 réplicas
- [ ] Reducir réplicas de 20 a 5
- [ ] Generar carga y escalar bajo presión
- [ ] Analizar eventos de recuperación
- [ ] Verificar owner references

### **Comandos de Resumen**

```bash
# Ver estado de todos los ReplicaSets
kubectl get rs

# Ver Pods con restarts
kubectl get pods -l app=autoheal -o custom-columns=\
NAME:.metadata.name,\
RESTARTS:.status.containerStatuses[0].restartCount,\
STATUS:.status.phase

# Ver eventos recientes
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

---

## 🧹 Limpieza

```bash
# Eliminar ReplicaSets
kubectl delete rs autoheal-rs webapp-load

# Eliminar Service
kubectl delete svc webapp-svc

# Verificar limpieza
kubectl get rs
kubectl get pods
kubectl get svc
```

---

## 📚 Conceptos Aprendidos

✅ **Self-Healing**: ReplicaSet recrea Pods automáticamente  
✅ **Estado Deseado**: ReplicaSet mantiene `replicas: N` siempre  
✅ **Escalado Dinámico**: Cambiar réplicas sin downtime  
✅ **Resiliencia**: Recuperación ante fallos de Pods/contenedores  
✅ **Owner References**: Control de ciclo de vida de Pods  

---

## ➡️ Próximos Pasos

- [Laboratorio 03: Ownership y Limitaciones](./lab-03-ownership-limitaciones.md)
- [Ejemplos de Auto-Recuperación](../ejemplos/02-auto-recuperacion/)

---

**Última actualización**: Noviembre 2025  
**Versión**: 1.0
