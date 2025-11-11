# Laboratorio 01: Volúmenes Básicos en Kubernetes

## 📋 Información del Laboratorio

**Duración estimada**: 30-40 minutos  
**Nivel**: Principiante  
**Prerequisitos**:
- Cluster AKS activo
- kubectl configurado
- Conocimientos básicos de Pods y Deployments

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

1. ✅ Crear y usar volúmenes `emptyDir` para compartir datos entre contenedores
2. ✅ Entender cuándo usar (y NO usar) `hostPath`
3. ✅ Solicitar almacenamiento persistente con PersistentVolumeClaim (PVC)
4. ✅ Verificar persistencia de datos ante reinicios de Pods
5. ✅ Limpiar recursos correctamente

## 📚 Conceptos Clave

Este laboratorio cubre los tres tipos fundamentales de volúmenes:

| Tipo de Volumen | Persistencia | Compartible | Caso de Uso |
|-----------------|--------------|-------------|-------------|
| **emptyDir** | Solo mientras el Pod existe | Entre contenedores del Pod | Datos temporales, caché |
| **hostPath** | En el nodo | NO (solo ese nodo) | Dev/testing, casos específicos |
| **PVC** | Persistente (cluster-level) | Depende del Access Mode | Producción, bases de datos |

---

## 🧪 Ejercicio 1: Volúmenes Temporales con emptyDir (10 min)

### Objetivo
Compartir datos entre dos contenedores usando un volumen temporal `emptyDir`.

### Paso 1.1: Crear Pod con emptyDir

Crea el archivo `pod-writer-reader.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: writer-reader
  labels:
    lab: volumenes-basicos
spec:
  containers:
  # Contenedor 1: Escribe datos
  - name: writer
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "Contenedor writer iniciado"
      counter=1
      while true; do
        echo "Mensaje $counter - $(date)" >> /shared/messages.txt
        echo "Escribí mensaje $counter"
        counter=$((counter + 1))
        sleep 5
      done
    volumeMounts:
    - name: shared-data
      mountPath: /shared
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
  
  # Contenedor 2: Lee datos
  - name: reader
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "Contenedor reader iniciado"
      echo "Esperando datos..."
      sleep 3
      while true; do
        if [ -f /shared/messages.txt ]; then
          echo "=== Últimos 5 mensajes ==="
          tail -5 /shared/messages.txt
        else
          echo "Esperando que writer cree el archivo..."
        fi
        sleep 10
      done
    volumeMounts:
    - name: shared-data
      mountPath: /shared
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
  
  # Volumen compartido
  volumes:
  - name: shared-data
    emptyDir: {}
```

### Paso 1.2: Aplicar y verificar

```bash
# Aplicar el Pod
kubectl apply -f pod-writer-reader.yaml

# Verificar que el Pod está corriendo
kubectl get pod writer-reader

# Ver logs del writer
kubectl logs writer-reader -c writer --tail=10

# Ver logs del reader
kubectl logs writer-reader -c reader --tail=20
```

**Salida esperada del reader**:
```
=== Últimos 5 mensajes ===
Mensaje 1 - Mon Nov 10 10:15:23 UTC 2025
Mensaje 2 - Mon Nov 10 10:15:28 UTC 2025
Mensaje 3 - Mon Nov 10 10:15:33 UTC 2025
...
```

### Paso 1.3: Verificar que los contenedores comparten datos

```bash
# Acceder al writer y ver el archivo
kubectl exec writer-reader -c writer -- cat /shared/messages.txt

# Acceder al reader y ver EL MISMO archivo
kubectl exec writer-reader -c reader -- cat /shared/messages.txt

# ✅ Ambos contenedores ven los mismos datos
```

### Paso 1.4: Probar que emptyDir NO es persistente

```bash
# Eliminar el Pod
kubectl delete pod writer-reader

# Recrear el Pod
kubectl apply -f pod-writer-reader.yaml

# Esperar a que esté listo
kubectl wait --for=condition=ready pod/writer-reader --timeout=60s

# Verificar logs del reader
kubectl logs writer-reader -c reader --tail=10

# ❌ Los mensajes empiezan desde cero (contador = 1)
# El volumen emptyDir se creó vacío de nuevo
```

### 🔍 Análisis del Ejercicio 1

**Pregunta**: ¿Por qué los datos no persistieron?

**Respuesta**: `emptyDir` es temporal. Se crea cuando el Pod se crea y se elimina cuando el Pod se elimina. Los datos solo persisten mientras el Pod existe.

**Casos de uso válidos para emptyDir**:
- ✅ Compartir datos entre contenedores del mismo Pod
- ✅ Caché temporal (ejemplo: scratch space para procesamiento)
- ✅ Datos que se pueden reconstruir fácilmente

---

## 🧪 Ejercicio 2: Explorar hostPath (Solo para Entender) (5 min)

### Objetivo
Entender qué es `hostPath` y por qué NO debe usarse en producción.

### Paso 2.1: Crear Pod con hostPath

Crea el archivo `pod-hostpath-demo.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo
  labels:
    lab: volumenes-basicos
spec:
  containers:
  - name: demo
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "=== Pod con hostPath ==="
      echo "Nodo: $NODE_NAME"
      echo ""
      
      # Crear archivo en el nodo
      echo "Datos desde Pod: $(hostname)" > /host-data/pod-info.txt
      
      echo "Archivo creado en /tmp/k8s-demo/ del nodo"
      ls -lh /host-data/
      
      sleep 3600
    env:
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    volumeMounts:
    - name: host-volume
      mountPath: /host-data
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
  
  volumes:
  - name: host-volume
    hostPath:
      path: /tmp/k8s-demo
      type: DirectoryOrCreate
```

### Paso 2.2: Aplicar y verificar

```bash
# Aplicar
kubectl apply -f pod-hostpath-demo.yaml

# Ver en qué nodo está el Pod
kubectl get pod hostpath-demo -o wide

# Ver logs
kubectl logs hostpath-demo

# Ver archivo creado
kubectl exec hostpath-demo -- cat /host-data/pod-info.txt
```

### Paso 2.3: Entender el problema de hostPath

```bash
# Eliminar el Pod
kubectl delete pod hostpath-demo

# Recrear el Pod
kubectl apply -f pod-hostpath-demo.yaml

# Esperar
kubectl wait --for=condition=ready pod/hostpath-demo --timeout=60s

# Ver en qué nodo está AHORA
kubectl get pod hostpath-demo -o wide

# ⚠️ Si está en un nodo DIFERENTE:
# - No verá el archivo anterior
# - El archivo original sigue en el nodo anterior
# - Los datos NO son portátiles
```

### 🔍 Análisis del Ejercicio 2

**Problemas de hostPath**:
1. ❌ **No portátil**: Datos quedan en un nodo específico
2. ❌ **Seguridad**: Acceso directo al filesystem del nodo
3. ❌ **No aislado**: Múltiples Pods podrían sobrescribir datos
4. ❌ **No funciona con auto-scaling**: Pods nuevos van a otros nodos

**¿Cuándo SÍ usar hostPath?**:
- DaemonSets que acceden a logs del sistema (`/var/log`)
- Herramientas de monitoreo que necesitan Docker socket
- Solo en casos MUY específicos

**Para producción**: Usar PersistentVolumeClaim (PVC)

### Limpieza del Ejercicio 2

```bash
kubectl delete pod hostpath-demo
```

---

## 🧪 Ejercicio 3: Almacenamiento Persistente con PVC (15 min)

### Objetivo
Usar PersistentVolumeClaim para almacenamiento que persiste ante reinicios de Pods.

### Paso 3.1: Crear PVC

Crea el archivo `pvc-lab.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-lab-data
  labels:
    lab: volumenes-basicos
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi
  resources:
    requests:
      storage: 5Gi
```

```bash
# Aplicar el PVC
kubectl apply -f pvc-lab.yaml

# Verificar estado (puede tardar unos segundos)
kubectl get pvc pvc-lab-data

# Debe mostrar STATUS: Bound o Pending
# Si está Pending, espera un momento
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/pvc-lab-data --timeout=60s
```

### Paso 3.2: Ver el PersistentVolume creado automáticamente

```bash
# Ver PVs
kubectl get pv

# Obtener nombre del PV
PV_NAME=$(kubectl get pvc pvc-lab-data -o jsonpath='{.spec.volumeName}')
echo "PV creado: $PV_NAME"

# Ver detalles del PV
kubectl describe pv $PV_NAME
```

**Observar**:
- `StorageClass`: managed-csi (Azure Disk)
- `Reclaim Policy`: Delete (se eliminará con el PVC)
- `VolumeHandle`: URI del disco en Azure

### Paso 3.3: Crear Pod que usa el PVC

Crea el archivo `pod-with-pvc.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: data-writer
  labels:
    lab: volumenes-basicos
spec:
  containers:
  - name: writer
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "=== Pod con almacenamiento persistente ==="
      echo ""
      
      # Verificar si hay datos previos
      if [ -f /data/counter.txt ]; then
        COUNTER=$(cat /data/counter.txt)
        echo "✅ Datos previos encontrados: contador = $COUNTER"
      else
        COUNTER=0
        echo "📝 Primera ejecución, iniciando contador en 0"
      fi
      
      # Incrementar contador
      COUNTER=$((COUNTER + 1))
      echo $COUNTER > /data/counter.txt
      
      # Guardar información de la ejecución
      echo "Ejecución #$COUNTER - Pod: $(hostname) - Timestamp: $(date)" >> /data/history.log
      
      echo ""
      echo "=== Estado actual ==="
      echo "Contador: $COUNTER"
      echo ""
      echo "=== Historial completo ==="
      cat /data/history.log
      
      echo ""
      echo "Datos guardados en volumen persistente"
      echo "Manteniendo Pod activo..."
      sleep 3600
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
  
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: pvc-lab-data
```

```bash
# Aplicar
kubectl apply -f pod-with-pvc.yaml

# Esperar a que esté listo
kubectl wait --for=condition=ready pod/data-writer --timeout=60s

# Ver logs
kubectl logs data-writer
```

**Salida esperada (primera ejecución)**:
```
📝 Primera ejecución, iniciando contador en 0

=== Estado actual ===
Contador: 1

=== Historial completo ===
Ejecución #1 - Pod: data-writer - Timestamp: Mon Nov 10 ...
```

### Paso 3.4: Probar persistencia de datos

```bash
# Eliminar el Pod
kubectl delete pod data-writer

# Recrear el Pod (mismo PVC)
kubectl apply -f pod-with-pvc.yaml

# Esperar
kubectl wait --for=condition=ready pod/data-writer --timeout=60s

# Ver logs de NUEVO
kubectl logs data-writer
```

**Salida esperada (segunda ejecución)**:
```
✅ Datos previos encontrados: contador = 1

=== Estado actual ===
Contador: 2

=== Historial completo ===
Ejecución #1 - Pod: data-writer - Timestamp: Mon Nov 10 10:30:15 ...
Ejecución #2 - Pod: data-writer - Timestamp: Mon Nov 10 10:32:45 ...
```

**✅ Los datos persistieron!** El contador incrementó y el historial se mantuvo.

### Paso 3.5: Verificar múltiples reinicios

```bash
# Repetir el ciclo varias veces
for i in {1..3}; do
  echo "=== Iteración $i ==="
  kubectl delete pod data-writer --wait=true
  kubectl apply -f pod-with-pvc.yaml
  kubectl wait --for=condition=ready pod/data-writer --timeout=60s
  kubectl logs data-writer | grep "Contador:"
  echo ""
done
```

**Salida esperada**:
```
=== Iteración 1 ===
Contador: 3

=== Iteración 2 ===
Contador: 4

=== Iteración 3 ===
Contador: 5
```

**✅ Perfecto!** Los datos sobreviven a los reinicios del Pod.

### 🔍 Análisis del Ejercicio 3

**¿Qué pasó?**

1. **PVC solicita almacenamiento** → Kubernetes crea PV + disco Azure
2. **Pod monta el PVC** → Datos se escriben en disco Azure
3. **Pod se elimina** → Disco Azure NO se elimina (PVC sigue)
4. **Nuevo Pod monta mismo PVC** → Lee datos del mismo disco Azure

**Ventajas de PVC**:
- ✅ Persistencia real (cluster-level)
- ✅ Portátil entre nodos
- ✅ Gestión automatizada por Kubernetes
- ✅ Perfecto para producción

---

## 🧪 Ejercicio 4: Comparación Final (5 min)

### Objetivo
Comparar los tres tipos de volúmenes lado a lado.

### Paso 4.1: Tabla comparativa

| Aspecto | emptyDir | hostPath | PVC |
|---------|----------|----------|-----|
| **Persistencia** | Solo mientras Pod existe | Mientras nodo exista | Permanente (cluster-level) |
| **Portabilidad** | N/A (temporal) | ❌ No (ligado al nodo) | ✅ Sí (entre nodos) |
| **Seguridad** | ✅ Aislado | ❌ Acceso al nodo | ✅ Aislado |
| **Uso en Producción** | ✅ Sí (datos temporales) | ❌ No (solo casos específicos) | ✅ Sí (recomendado) |
| **Caso de Uso** | Caché, scratch space | Logs del sistema, Docker socket | Bases de datos, aplicaciones stateful |

### Paso 4.2: Verificar recursos actuales

```bash
# Ver todos los Pods del lab
kubectl get pods -l lab=volumenes-basicos

# Ver PVCs
kubectl get pvc -l lab=volumenes-basicos

# Ver PVs
kubectl get pv

# Ver uso de almacenamiento
kubectl exec data-writer -- df -h /data
```

---

## 🧹 Limpieza del Laboratorio

### Paso 1: Eliminar Pods

```bash
# Eliminar todos los Pods del lab
kubectl delete pods -l lab=volumenes-basicos
```

### Paso 2: Eliminar PVC

```bash
# Eliminar PVC
kubectl delete pvc pvc-lab-data

# Verificar que el PV también se eliminó (reclaimPolicy: Delete)
kubectl get pv

# ✅ El PV debe haberse eliminado automáticamente
```

### Paso 3: Verificar limpieza completa

```bash
# No debe haber recursos del lab
kubectl get all,pvc -l lab=volumenes-basicos

# Debe mostrar: No resources found
```

---

## ✅ Verificación de Conocimientos

Responde estas preguntas para verificar tu aprendizaje:

### Pregunta 1
**¿Qué pasa con los datos en un volumen `emptyDir` cuando se elimina el Pod?**

<details>
<summary>Ver respuesta</summary>

Los datos se **eliminan permanentemente**. `emptyDir` es temporal y solo existe mientras el Pod exista.

</details>

### Pregunta 2
**¿Por qué `hostPath` NO es recomendado para aplicaciones en producción?**

<details>
<summary>Ver respuesta</summary>

Porque:
1. Los datos quedan en un nodo específico (no portátil)
2. Si el Pod se programa en otro nodo, no verá los datos
3. Riesgos de seguridad (acceso directo al filesystem del nodo)
4. No funciona bien con auto-scaling

</details>

### Pregunta 3
**¿Qué componente crea automáticamente el PersistentVolume cuando usas un PVC?**

<details>
<summary>Ver respuesta</summary>

El **StorageClass** y su **provisioner** (en nuestro caso, `disk.csi.azure.com` del StorageClass `managed-csi`).

</details>

### Pregunta 4
**¿Cuándo usarías `emptyDir` en lugar de PVC?**

<details>
<summary>Ver respuesta</summary>

Cuando:
- Los datos son temporales (no necesitan persistir)
- Necesitas compartir datos entre contenedores del mismo Pod
- Caché, scratch space, o datos que se pueden reconstruir fácilmente
- No quieres el overhead de almacenamiento persistente

</details>

---

## 🎓 Resumen del Laboratorio

**Lo que aprendiste**:

1. ✅ **emptyDir**: Volumen temporal para compartir datos entre contenedores del Pod
   - Fácil de usar
   - Se elimina con el Pod
   - Perfecto para datos temporales

2. ✅ **hostPath**: Monta directorio del nodo
   - Solo para casos MUY específicos
   - NO usar en producción
   - Problemas de portabilidad y seguridad

3. ✅ **PVC**: Almacenamiento persistente real
   - Datos persisten ante reinicios
   - Portátil entre nodos
   - Recomendado para producción
   - Gestión automatizada

**Regla de oro**:
- **Datos temporales** → `emptyDir`
- **Datos persistentes** → `PVC`
- **Casos específicos del nodo** → `hostPath` (con precaución)

---

## 📚 Recursos Adicionales

- [Documentación Principal del Módulo](../../README.md)
- [Ejemplos Completos](../../ejemplos/)
- [Laboratorio 02 - PV/PVC Avanzado](../lab-02-pv-pvc-avanzado/)

---

## 🔜 Próximos Pasos

Continúa con el [Laboratorio 02](../lab-02-pv-pvc-avanzado/) para aprender sobre:
- Provisioning manual de PV
- Access Modes (RWO, ROX, RWX)
- Reclaim Policies (Retain, Delete)
- Troubleshooting avanzado

**¡Excelente trabajo completando el Laboratorio 01!** 🎉
