# Laboratorio 02: PersistentVolume y PersistentVolumeClaim Avanzado

## 📋 Información del Laboratorio

**Duración estimada**: 45-55 minutos  
**Nivel**: Intermedio  
**Prerequisitos**:
- Haber completado [Laboratorio 01](../lab-01-volumenes-basicos/)
- Cluster AKS activo con múltiples nodos (recomendado)
- kubectl y Azure CLI configurados
- Comprensión básica de PVC

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

1. ✅ Crear PersistentVolumes (PV) manualmente y vincularlos con PVC
2. ✅ Usar Access Modes correctamente (RWO, ROX, RWX)
3. ✅ Implementar y probar Reclaim Policies (Retain, Delete)
4. ✅ Trabajar con Azure Files para almacenamiento compartido
5. ✅ Diagnosticar y resolver problemas comunes de volúmenes
6. ✅ Recuperar datos después de eliminar un PVC (con Retain)

## 📚 Conceptos Clave

Este laboratorio profundiza en conceptos avanzados de almacenamiento persistente:

| Concepto | Descripción | Impacto |
|----------|-------------|---------|
| **Access Mode RWO** | ReadWriteOnce - Un nodo | Azure Disk |
| **Access Mode RWX** | ReadWriteMany - Múltiples nodos | Azure Files |
| **Reclaim Policy Retain** | PV NO se elimina | Protección de datos |
| **Reclaim Policy Delete** | PV se elimina automáticamente | Limpieza automática |
| **StorageClass** | Template para provisioning | Automatización |

---

## 🧪 Ejercicio 1: Access Modes - ReadWriteOnce vs ReadWriteMany (15 min)

### Objetivo
Entender las diferencias entre RWO (Azure Disk) y RWX (Azure Files) con ejemplos prácticos.

### Parte A: ReadWriteOnce con Azure Disk

#### Paso 1.1: Crear PVC con RWO

Crea el archivo `pvc-rwo.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwo-disk
  labels:
    lab: pv-pvc-avanzado
    access-mode: rwo
spec:
  accessModes:
    - ReadWriteOnce  # Solo un nodo puede montar
  storageClassName: managed-csi  # Azure Disk
  resources:
    requests:
      storage: 5Gi
```

```bash
# Aplicar
kubectl apply -f pvc-rwo.yaml

# Verificar
kubectl get pvc pvc-rwo-disk
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/pvc-rwo-disk --timeout=60s
```

#### Paso 1.2: Crear Deployment con 3 réplicas usando RWO

Crea el archivo `deployment-rwo.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-rwo
  labels:
    lab: pv-pvc-avanzado
spec:
  replicas: 3  # Intentar 3 réplicas
  selector:
    matchLabels:
      app: app-rwo
  template:
    metadata:
      labels:
        app: app-rwo
    spec:
      containers:
      - name: app
        image: busybox
        command:
        - sh
        - -c
        - |
          echo "Pod: $(hostname)"
          echo "Nodo: $NODE_NAME"
          echo "Escribiendo en volumen RWO..."
          echo "$(date): Pod $(hostname) en nodo $NODE_NAME" >> /data/log.txt
          tail -f /data/log.txt
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        volumeMounts:
        - name: storage
          mountPath: /data
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: pvc-rwo-disk
```

```bash
# Aplicar
kubectl apply -f deployment-rwo.yaml

# Esperar un poco
sleep 10

# Ver estado de los Pods
kubectl get pods -l app=app-rwo -o wide
```

**Observación esperada**:
- Si todos los Pods están en el **mismo nodo**: ✅ Los 3 estarán Running
- Si los Pods están en **diferentes nodos**: ⚠️ Solo 1-2 estarán Running, otros Pending

```bash
# Ver eventos de Pods pending
kubectl get events --sort-by='.lastTimestamp' | grep -i "multi-attach\|failedattach"

# Si ves "Multi-Attach error":
# ✅ Es el comportamiento esperado con ReadWriteOnce
```

#### Paso 1.3: Verificar en qué nodos están los Pods

```bash
# Ver distribución de Pods por nodo
kubectl get pods -l app=app-rwo -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName

# ⚠️ ReadWriteOnce = Solo un nodo puede montar el volumen
```

### Parte B: ReadWriteMany con Azure Files

#### Paso 1.4: Crear PVC con RWX

Crea el archivo `pvc-rwx.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwx-files
  labels:
    lab: pv-pvc-avanzado
    access-mode: rwx
spec:
  accessModes:
    - ReadWriteMany  # Múltiples nodos pueden montar
  storageClassName: azurefile-csi  # Azure Files (no Disk!)
  resources:
    requests:
      storage: 10Gi
```

```bash
# Aplicar
kubectl apply -f pvc-rwx.yaml

# Verificar (puede tardar más que Disk)
kubectl get pvc pvc-rwx-files
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/pvc-rwx-files --timeout=120s
```

#### Paso 1.5: Crear Deployment con 5 réplicas usando RWX

Crea el archivo `deployment-rwx.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-rwx
  labels:
    lab: pv-pvc-avanzado
spec:
  replicas: 5  # Múltiples réplicas, sin problemas
  selector:
    matchLabels:
      app: app-rwx
  template:
    metadata:
      labels:
        app: app-rwx
    spec:
      containers:
      - name: app
        image: busybox
        command:
        - sh
        - -c
        - |
          echo "Pod: $(hostname)"
          echo "Nodo: $NODE_NAME"
          
          # Crear directorio por Pod
          mkdir -p /shared/pods/$(hostname)
          
          # Escribir datos
          while true; do
            echo "$(date): Pod $(hostname) en nodo $NODE_NAME" >> /shared/pods/$(hostname)/log.txt
            echo "$(date): Global desde $(hostname)" >> /shared/global.log
            echo "Escribí en /shared/pods/$(hostname)/log.txt"
            echo "Total de Pods activos: $(ls -1 /shared/pods/ | wc -l)"
            sleep 10
          done
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        volumeMounts:
        - name: shared-storage
          mountPath: /shared
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
      volumes:
      - name: shared-storage
        persistentVolumeClaim:
          claimName: pvc-rwx-files
```

```bash
# Aplicar
kubectl apply -f deployment-rwx.yaml

# Esperar
sleep 15

# Ver estado de los Pods
kubectl get pods -l app=app-rwx -o wide

# ✅ TODOS los Pods deben estar Running
# ✅ Pueden estar en diferentes nodos
```

#### Paso 1.6: Verificar compartición de datos

```bash
# Ver logs de varios Pods
kubectl logs -l app=app-rwx --tail=5 --prefix | head -30

# Acceder a un Pod y ver datos de TODOS los Pods
POD=$(kubectl get pod -l app=app-rwx -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- ls -l /shared/pods/
# Deberías ver directorios de los 5 Pods ✅

# Ver log global (escrito por todos)
kubectl exec $POD -- tail -20 /shared/global.log
# Verás entradas de múltiples Pods ✅
```

### 🔍 Análisis del Ejercicio 1

**Comparación**:

| Aspecto | ReadWriteOnce (Disk) | ReadWriteMany (Files) |
|---------|----------------------|----------------------|
| **StorageClass** | managed-csi | azurefile-csi |
| **Tecnología** | Azure Managed Disk | Azure Files (SMB) |
| **Nodos simultáneos** | 1 | Múltiples ✅ |
| **Rendimiento** | Alto (SSD) | Moderado |
| **Costo** | Bajo-Medio | Medio-Alto |
| **Caso de uso** | DB single-instance | Apps distribuidas |

**Cuándo usar cada uno**:
- **RWO**: PostgreSQL, MySQL, MongoDB (1 réplica)
- **RWX**: WordPress, CMS, procesamiento distribuido

---

## 🧪 Ejercicio 2: Reclaim Policies - Retain vs Delete (20 min)

### Objetivo
Entender y practicar las políticas de recuperación de volúmenes.

### Parte A: Política Delete (por defecto)

#### Paso 2.1: Crear PVC con StorageClass Delete

```bash
# Usar PVC existente (pvc-rwo-disk tiene Delete por defecto)
kubectl get pvc pvc-rwo-disk

# Ver el PV asociado
PV_DELETE=$(kubectl get pvc pvc-rwo-disk -o jsonpath='{.spec.volumeName}')
echo "PV: $PV_DELETE"

# Verificar Reclaim Policy
kubectl get pv $PV_DELETE -o custom-columns=NAME:.metadata.name,RECLAIM:.spec.persistentVolumeReclaimPolicy
# Debe mostrar: Delete
```

#### Paso 2.2: Escribir datos y luego eliminar PVC

```bash
# Escribir datos
kubectl exec -it $(kubectl get pod -l app=app-rwo -o jsonpath='{.items[0].metadata.name}') -- \
  sh -c 'echo "Datos importantes con Delete policy" > /data/important.txt'

# Verificar datos
kubectl exec $(kubectl get pod -l app=app-rwo -o jsonpath='{.items[0].metadata.name}') -- \
  cat /data/important.txt

# Obtener URI del disco Azure
DISK_URI=$(kubectl get pv $PV_DELETE -o jsonpath='{.spec.csi.volumeHandle}')
echo "Disco Azure: $DISK_URI"

# Eliminar Deployment y PVC
kubectl delete deployment app-rwo
kubectl delete pvc pvc-rwo-disk

# Esperar un momento
sleep 5

# Verificar que PV se eliminó
kubectl get pv $PV_DELETE
# Error: not found ✅

# ⚠️ El disco Azure también se eliminó
# Los datos se perdieron permanentemente
```

### Parte B: Política Retain

#### Paso 2.3: Crear StorageClass con Retain

Crea el archivo `storageclass-retain.yaml`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: disk-retain
  labels:
    lab: pv-pvc-avanzado
provisioner: disk.csi.azure.com
parameters:
  skuname: StandardSSD_LRS
  kind: Managed
reclaimPolicy: Retain  # ← Proteger datos
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

```bash
# Aplicar
kubectl apply -f storageclass-retain.yaml

# Verificar
kubectl get storageclass disk-retain
```

#### Paso 2.4: Crear PVC con Retain policy

Crea el archivo `pvc-retain.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-retain-test
  labels:
    lab: pv-pvc-avanzado
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: disk-retain  # ← Usa StorageClass con Retain
  resources:
    requests:
      storage: 3Gi
```

```bash
# Aplicar
kubectl apply -f pvc-retain.yaml
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/pvc-retain-test --timeout=60s
```

#### Paso 2.5: Escribir datos "críticos"

Crea el archivo `pod-retain-test.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: data-saver
  labels:
    lab: pv-pvc-avanzado
spec:
  containers:
  - name: app
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "=== Guardando datos críticos ==="
      echo "Estos datos deben protegerse con Retain policy"
      
      # Crear datos "importantes"
      cat > /data/critical-data.json <<EOF
      {
        "database": "production",
        "backup_date": "$(date)",
        "records": 1000000,
        "status": "critical"
      }
      EOF
      
      echo "Datos guardados:"
      cat /data/critical-data.json
      
      sleep 3600
    volumeMounts:
    - name: critical-storage
      mountPath: /data
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
  volumes:
  - name: critical-storage
    persistentVolumeClaim:
      claimName: pvc-retain-test
```

```bash
# Aplicar
kubectl apply -f pod-retain-test.yaml
kubectl wait --for=condition=ready pod/data-saver --timeout=60s

# Ver logs
kubectl logs data-saver

# Verificar datos
kubectl exec data-saver -- cat /data/critical-data.json
```

#### Paso 2.6: Simular "eliminación accidental" del PVC

```bash
# Obtener nombre del PV
PV_RETAIN=$(kubectl get pvc pvc-retain-test -o jsonpath='{.spec.volumeName}')
echo "PV con Retain: $PV_RETAIN"

# Obtener URI del disco
DISK_URI_RETAIN=$(kubectl get pv $PV_RETAIN -o jsonpath='{.spec.csi.volumeHandle}')
echo "Disco protegido: $DISK_URI_RETAIN"

# ⚠️ Simular eliminación accidental
kubectl delete pod data-saver
kubectl delete pvc pvc-retain-test

# Verificar estado del PV
kubectl get pv $PV_RETAIN
# STATUS: Released ✅ (NO eliminado)
```

#### Paso 2.7: Recuperar datos del PV

```bash
# Ver detalles del PV
kubectl describe pv $PV_RETAIN
# Observar: ClaimRef apunta al PVC eliminado

# Limpiar claimRef para poder reutilizar el PV
kubectl patch pv $PV_RETAIN -p '{"spec":{"claimRef":null}}'

# Verificar nuevo estado
kubectl get pv $PV_RETAIN
# STATUS: Available ✅
```

#### Paso 2.8: Crear nuevo PVC para recuperar datos

Crea el archivo `pvc-recover.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-recovered-data
  labels:
    lab: pv-pvc-avanzado
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: disk-retain
  resources:
    requests:
      storage: 3Gi
```

```bash
# Aplicar
kubectl apply -f pvc-recover.yaml

# Verificar que se vinculó al PV existente
kubectl get pvc pvc-recovered-data
# Debe estar Bound al mismo PV

# Verificar datos recuperados
kubectl run data-recovery --image=busybox --rm -it --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "recovery",
      "image": "busybox",
      "command": ["cat", "/data/critical-data.json"],
      "volumeMounts": [{
        "name": "recovered",
        "mountPath": "/data"
      }]
    }],
    "volumes": [{
      "name": "recovered",
      "persistentVolumeClaim": {
        "claimName": "pvc-recovered-data"
      }
    }]
  }
}'

# ✅ Debe mostrar los datos originales
```

### 🔍 Análisis del Ejercicio 2

**Flujo con Delete**:
1. PVC eliminado → PV eliminado → Disco eliminado
2. ❌ Datos perdidos permanentemente
3. ✅ Limpieza automática

**Flujo con Retain**:
1. PVC eliminado → PV pasa a "Released"
2. ✅ Disco intacto, datos protegidos
3. Manual: Limpiar claimRef → Crear nuevo PVC
4. ✅ Datos recuperados

**Decisión**:
- **Producción/Datos críticos**: Retain
- **Desarrollo/Datos temporales**: Delete

---

## 🧪 Ejercicio 3: Troubleshooting de Volúmenes (10 min)

### Objetivo
Diagnosticar y resolver problemas comunes de almacenamiento.

### Escenario 1: PVC Stuck en Pending

#### Paso 3.1: Crear PVC que fallará

Crea el archivo `pvc-problema.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-problema
  labels:
    lab: pv-pvc-avanzado
spec:
  accessModes:
    - ReadWriteMany  # ← Problema: managed-csi NO soporta RWX
  storageClassName: managed-csi  # ← Azure Disk
  resources:
    requests:
      storage: 5Gi
```

```bash
# Aplicar
kubectl apply -f pvc-problema.yaml

# Ver estado
kubectl get pvc pvc-problema
# STATUS: Pending ⚠️

# Diagnosticar
kubectl describe pvc pvc-problema
```

**Buscar en Events**:
```
Warning  ProvisioningFailed  ... storageclass "managed-csi" not found or does not support ReadWriteMany
```

**Solución**:
```bash
# Eliminar PVC problemático
kubectl delete pvc pvc-problema

# Usar StorageClass correcto (azurefile-csi para RWX)
```

### Escenario 2: Multi-Attach Error

#### Paso 3.2: Recrear escenario de multi-attach

```bash
# Usar deployment-rwo.yaml del Ejercicio 1
# Si no existe, recrearlo
kubectl apply -f pvc-rwo.yaml
kubectl apply -f deployment-rwo.yaml

# Escalar para forzar distribución multi-nodo
kubectl scale deployment app-rwo --replicas=10

# Ver Pods pending
kubectl get pods -l app=app-rwo | grep Pending

# Diagnosticar
kubectl describe pod <pod-pending-name>
```

**Buscar en Events**:
```
Warning  FailedAttachVolume  ... Multi-Attach error for volume "pvc-..." 
         Volume is already used by pod(s) ...
```

**Solución**:
```bash
# Opción 1: Reducir réplicas a 1
kubectl scale deployment app-rwo --replicas=1

# Opción 2: Usar StatefulSet con volumeClaimTemplates
# (cada Pod obtiene su propio PVC)

# Opción 3: Cambiar a Azure Files (RWX)
```

### Escenario 3: PV Released y no disponible

**Ya lo practicamos en Ejercicio 2** ✅

**Solución recordatorio**:
```bash
kubectl patch pv <pv-name> -p '{"spec":{"claimRef":null}}'
```

### 🔍 Análisis del Ejercicio 3

**Checklist de troubleshooting**:

1. **PVC Pending**:
   - ✅ Ver `kubectl describe pvc <nombre>`
   - ✅ Verificar Events
   - ✅ Verificar que StorageClass existe
   - ✅ Verificar compatibilidad Access Mode

2. **Multi-Attach Error**:
   - ✅ Verificar Access Mode (RWO = solo 1 nodo)
   - ✅ Ver `kubectl get pods -o wide` (distribución de nodos)
   - ✅ Considerar RWX o StatefulSet

3. **PV Released**:
   - ✅ Ver `kubectl get pv`
   - ✅ Limpiar claimRef con patch
   - ✅ Crear nuevo PVC

4. **Performance bajo**:
   - ✅ Considerar Premium SSD
   - ✅ Aumentar tamaño del disco (más IOPS)
   - ✅ Verificar que no hay throttling

---

## 🧹 Limpieza del Laboratorio

### Paso 1: Eliminar Deployments y Pods

```bash
# Deployments
kubectl delete deployment app-rwo app-rwx 2>/dev/null || true

# Pods individuales
kubectl delete pod data-saver 2>/dev/null || true
```

### Paso 2: Eliminar PVCs

```bash
# PVCs del lab
kubectl delete pvc pvc-rwx-files pvc-recovered-data 2>/dev/null || true

# Esperar a que se eliminen
kubectl wait --for=delete pvc/pvc-rwx-files --timeout=60s 2>/dev/null || true
```

### Paso 3: Limpiar PVs con Retain

```bash
# Ver PVs en estado Released
kubectl get pv | grep Released

# Eliminar manualmente los PVs Released
kubectl delete pv $PV_RETAIN 2>/dev/null || true
```

### Paso 4: Eliminar StorageClass custom

```bash
kubectl delete storageclass disk-retain
```

### Paso 5: Verificar limpieza

```bash
# No debe haber recursos del lab
kubectl get all,pvc,pv,storageclass -l lab=pv-pvc-avanzado

# Verificar PVs huérfanos
kubectl get pv
# Si hay PVs en Released, eliminarlos
```

---

## ✅ Verificación de Conocimientos

### Pregunta 1
**¿Cuál es la diferencia principal entre Azure Disk y Azure Files en términos de Access Mode?**

<details>
<summary>Ver respuesta</summary>

- **Azure Disk (managed-csi)**: Solo soporta **ReadWriteOnce (RWO)** - un solo nodo puede montar
- **Azure Files (azurefile-csi)**: Soporta **ReadWriteMany (RWX)** - múltiples nodos pueden montar simultáneamente

Azure Disk es block storage (como un USB), mientras que Azure Files es file storage (como una carpeta compartida en red).

</details>

### Pregunta 2
**¿Qué pasa con un PersistentVolume cuando eliminas su PVC si la Reclaim Policy es "Retain"?**

<details>
<summary>Ver respuesta</summary>

El PV pasa a estado **"Released"** pero NO se elimina:
1. El disco Azure permanece intacto con todos los datos
2. El PV sigue existiendo pero no está disponible para nuevos PVCs
3. Para reutilizarlo: `kubectl patch pv <name> -p '{"spec":{"claimRef":null}}'`
4. Luego crear nuevo PVC que se vincule al PV

Esto permite **recuperación de datos** en caso de eliminación accidental.

</details>

### Pregunta 3
**¿Por qué un Deployment con 3 réplicas usando un PVC con ReadWriteOnce podría tener solo 1 Pod Running?**

<details>
<summary>Ver respuesta</summary>

Porque **ReadWriteOnce** permite que solo un **nodo** monte el volumen:

- Si los 3 Pods van al mismo nodo: ✅ Los 3 funcionan
- Si los Pods se distribuyen entre nodos: ❌ Solo el primero funciona
- Los otros quedan Pending con "Multi-Attach error"

**Solución**:
- Usar ReadWriteMany (Azure Files) si necesitas múltiples réplicas
- O usar StatefulSet con volumeClaimTemplates (cada Pod su propio PVC)

</details>

### Pregunta 4
**¿Cuándo usarías Reclaim Policy "Retain" en lugar de "Delete"?**

<details>
<summary>Ver respuesta</summary>

**Usar Retain cuando**:
- Datos de producción críticos
- Bases de datos importantes
- Entornos regulados (compliance, auditoría)
- Migración entre clusters
- Necesitas backup manual antes de eliminar

**Usar Delete cuando**:
- Entornos de desarrollo/testing
- Datos temporales o fácilmente reconstruibles
- CI/CD pipelines
- Quieres limpieza automática
- Datos respaldados externamente

**Regla**: En caso de duda para producción → **Retain** (más seguro)

</details>

---

## 🎓 Resumen del Laboratorio

**Lo que aprendiste**:

### 1. Access Modes en Azure

| Access Mode | StorageClass | Pods simultáneos | Caso de Uso |
|-------------|--------------|------------------|-------------|
| **ReadWriteOnce** | managed-csi | 1 nodo | PostgreSQL, MySQL |
| **ReadWriteMany** | azurefile-csi | Múltiples nodos | WordPress, CMS |

### 2. Reclaim Policies

| Policy | Al eliminar PVC | Caso de Uso |
|--------|-----------------|-------------|
| **Delete** | PV + disco eliminados | Dev/test, datos temporales |
| **Retain** | PV Released, disco intacto | Producción, datos críticos |

### 3. Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| PVC Pending | StorageClass incompatible | Verificar Access Mode compatible |
| Multi-Attach error | RWO con múltiples nodos | Usar RWX o StatefulSet |
| PV Released | Retain policy, PVC eliminado | Patch claimRef, crear nuevo PVC |

### 4. Mejores Prácticas

✅ **Hacer**:
- Usar Retain para datos de producción
- Verificar Access Mode según necesidad
- Monitorear PVs Released
- Etiquetar recursos claramente
- Hacer backups externos

❌ **Evitar**:
- RWO con Deployments multi-réplica (usar StatefulSet)
- Delete para datos críticos sin backup
- Ignorar PVs Released (generan costos)
- Cambiar Reclaim Policy después de crear PV

---

## 📊 Matriz de Decisión de Almacenamiento

```
¿Necesitas almacenamiento persistente?
│
├─NO─→ emptyDir (Lab 01)
│
└─SÍ─→ ¿Múltiples Pods necesitan acceso simultáneo?
       │
       ├─NO─→ ¿Es producción?
       │      │
       │      ├─SÍ─→ managed-csi (RWO) + Retain
       │      │      + Backups externos
       │      │
       │      └─NO─→ managed-csi (RWO) + Delete
       │
       └─SÍ─→ azurefile-csi (RWX)
              │
              ├─Producción─→ Retain
              └─Dev/Test───→ Delete
```

---

## 📚 Recursos Adicionales

- [Documentación Principal](../../README.md)
- [Ejemplos Completos](../../ejemplos/)
- [Laboratorio 01 - Volúmenes Básicos](../lab-01-volumenes-basicos/)
- [Azure Disk Documentation](https://docs.microsoft.com/azure/aks/azure-disk-csi)
- [Azure Files Documentation](https://docs.microsoft.com/azure/aks/azure-files-csi)

---

## 🔜 Próximos Pasos

### Temas Avanzados (Módulo 16)

- **StatefulSets** con volumeClaimTemplates
- **Volume Snapshots** y backups
- **Expansión de volúmenes** (resize online)
- **CSI Drivers** avanzados
- **Performance tuning** de almacenamiento

### Práctica Adicional

1. Implementar PostgreSQL con StatefulSet
2. Configurar backup automatizado de PVs
3. Migrar aplicación de VM a AKS con datos
4. Implementar WordPress multi-réplica con Azure Files

---

**¡Excelente trabajo completando el Laboratorio 02!** 🎉

Has dominado conceptos avanzados de almacenamiento persistente en Kubernetes. Ahora estás preparado para diseñar soluciones de almacenamiento robustas y resilientes en Azure AKS.
