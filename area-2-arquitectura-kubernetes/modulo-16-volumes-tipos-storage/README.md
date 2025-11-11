# Módulo 16: Volúmenes en Kubernetes - Implementación Práctica en Azure AKS

## 📋 Índice

1. [Introducción](#introducción)
2. [Prerrequisitos](#prerrequisitos)
3. [Implementación de emptyDir](#implementación-de-emptydir)
4. [Implementación de hostPath](#implementación-de-hostpath)
5. [PVC Básico con Azure Disk](#pvc-básico-con-azure-disk)
6. [PV/PVC Manual](#pvpvc-manual)
7. [Access Modes en la Práctica](#access-modes-en-la-práctica)
8. [Reclaim Policies](#reclaim-policies)
9. [StorageClasses Personalizadas](#storageclasses-personalizadas)
10. [Troubleshooting Práctico](#troubleshooting-práctico)
11. [Laboratorios](#laboratorios)
12. [Mejores Prácticas](#mejores-prácticas)
13. [Referencias](#referencias)

---

## Introducción

Este módulo es la **implementación práctica** de los conceptos fundamentales vistos en el [Módulo 15 - Volúmenes: Conceptos](../modulo-15-volumes-conceptos/).

### ¿Qué aprenderás?

En este módulo pondrás en práctica:

- ✅ Crear y usar volúmenes **emptyDir** con ejemplos reales
- ✅ Implementar **hostPath** en DaemonSets
- ✅ Provisionar almacenamiento dinámico con **Azure Disk**
- ✅ Compartir archivos entre Pods con **Azure Files**
- ✅ Configurar **Access Modes** apropiados
- ✅ Gestionar **Reclaim Policies** en producción
- ✅ Crear **StorageClasses personalizadas**
- ✅ **Troubleshoot** problemas reales de volúmenes
- ✅ Realizar laboratorios hands-on completos

### Relación con el Módulo 15

```
┌────────────────────────────────────────────────────┐
│  Módulo 15: Conceptos                             │
│  - ¿Qué son los volúmenes?                         │
│  - Tipos de volúmenes (teoría)                     │
│  - PV/PVC (abstracción)                            │
│  - Access Modes (concepto)                         │
│  - Reclaim Policies (teoría)                       │
└────────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────────┐
│  Módulo 16: Implementación Práctica               │
│  - CÓMO crear volúmenes                            │
│  - YAMLs completos                                 │
│  - Comandos kubectl detallados                     │
│  - Troubleshooting con ejemplos                    │
│  - Laboratorios hands-on                           │
└────────────────────────────────────────────────────┘
```

💡 **Recomendación**: Si no has completado el [Módulo 15](../modulo-15-volumes-conceptos/), revísalo primero para entender los conceptos fundamentales.

---

## Prerrequisitos

### Cluster AKS

Necesitas un cluster de Azure Kubernetes Service funcionando:

```bash
# Verificar cluster
kubectl cluster-info
kubectl get nodes

# Verificar que estás en el contexto correcto
kubectl config current-context
```

### StorageClasses Disponibles

Verifica que tienes las StorageClasses de Azure:

```bash
kubectl get storageclass

# Deberías ver:
# NAME                    PROVISIONER          RECLAIMPOLICY
# azurefile               file.csi.azure.com   Delete
# azurefile-csi           file.csi.azure.com   Delete
# azurefile-csi-premium   file.csi.azure.com   Delete
# default (default)       disk.csi.azure.com   Delete
# managed-csi             disk.csi.azure.com   Delete
# managed-csi-premium     disk.csi.azure.com   Delete
```

### Permisos

Asegúrate de tener permisos para:

```bash
# Crear PVCs
kubectl auth can-i create persistentvolumeclaims

# Crear Pods
kubectl auth can-i create pods

# Ver eventos
kubectl auth can-i get events
```

---

## Implementación de emptyDir

### Concepto Recordatorio

**emptyDir** es un volumen temporal que:
- Se crea vacío cuando el Pod inicia
- Existe solo mientras el Pod viva
- Comparte datos entre contenedores del mismo Pod
- Se elimina cuando el Pod muere

📖 **Ver teoría**: [Módulo 15 - emptyDir](../modulo-15-volumes-conceptos/README.md#emptydir)

### Ejemplo 1: Cache Compartido entre Contenedores

**Archivo**: [`ejemplos/01-emptydir/pod-emptydir-basic.yaml`](./ejemplos/01-emptydir/pod-emptydir-basic.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-emptydir-cache
  labels:
    app: cache-demo
spec:
  containers:
  # Contenedor que escribe datos
  - name: writer
    image: busybox
    command: 
    - sh
    - -c
    - |
      echo "Iniciando escritor..."
      while true; do
        echo "$(date): Datos generados" >> /cache/data.txt
        echo "Total de líneas: $(wc -l < /cache/data.txt)"
        sleep 5
      done
    volumeMounts:
    - name: cache-volume
      mountPath: /cache
  
  # Contenedor que lee datos
  - name: reader
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "Esperando datos..."
      sleep 10
      echo "Leyendo datos compartidos:"
      tail -f /shared/data.txt
    volumeMounts:
    - name: cache-volume
      mountPath: /shared  # Mismo volumen, diferente path
  
  # Definición del volumen emptyDir
  volumes:
  - name: cache-volume
    emptyDir: {}  # Usa disco del nodo
```

**Aplicar y verificar**:

```bash
# 1. Crear el Pod
kubectl apply -f ejemplos/01-emptydir/pod-emptydir-basic.yaml

# 2. Verificar que está corriendo
kubectl get pod pod-emptydir-cache
# NAME                 READY   STATUS    RESTARTS   AGE
# pod-emptydir-cache   2/2     Running   0          10s

# 3. Ver logs del escritor
kubectl logs pod-emptydir-cache -c writer
# Iniciando escritor...
# Total de líneas: 1
# Total de líneas: 2
# Total de líneas: 3

# 4. Ver logs del lector
kubectl logs pod-emptydir-cache -c reader
# Esperando datos...
# Leyendo datos compartidos:
# Sun Nov 10 18:00:01 UTC 2025: Datos generados
# Sun Nov 10 18:00:06 UTC 2025: Datos generados

# 5. Verificar que ambos ven el mismo archivo
kubectl exec pod-emptydir-cache -c writer -- ls -lh /cache
kubectl exec pod-emptydir-cache -c reader -- ls -lh /shared
# Mismo contenido en diferentes rutas

# 6. Ver tamaño del archivo compartido
kubectl exec pod-emptydir-cache -c writer -- wc -l /cache/data.txt
# 50 /cache/data.txt

# 7. Limpiar
kubectl delete pod pod-emptydir-cache
```

**¿Qué sucede?**
1. El Pod se crea con un directorio vacío
2. El contenedor `writer` escribe datos cada 5 segundos
3. El contenedor `reader` lee los mismos datos (montado en diferente ruta)
4. Ambos contenedores comparten el mismo volumen
5. Al eliminar el Pod, **los datos se pierden**

### Ejemplo 2: emptyDir en Memoria RAM

Para cache de alto rendimiento, usa la RAM del nodo:

**Archivo**: [`ejemplos/01-emptydir/pod-emptydir-memory.yaml`](./ejemplos/01-emptydir/pod-emptydir-memory.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-emptydir-memory
spec:
  containers:
  - name: cache-app
    image: nginx:alpine
    volumeMounts:
    - name: ram-cache
      mountPath: /cache
    command:
    - sh
    - -c
    - |
      # Generar datos en cache RAM
      while true; do
        dd if=/dev/zero of=/cache/test-$(date +%s).dat bs=1M count=10
        ls -lh /cache
        sleep 30
      done
  
  volumes:
  - name: ram-cache
    emptyDir:
      medium: Memory      # ← Usar RAM en lugar de disco
      sizeLimit: 128Mi    # Límite de 128 MiB
```

**Aplicar y verificar**:

```bash
# 1. Crear Pod
kubectl apply -f ejemplos/01-emptydir/pod-emptydir-memory.yaml

# 2. Verificar uso de memoria
kubectl exec pod-emptydir-memory -- df -h /cache
# Filesystem      Size  Used Avail Use% Mounted on
# tmpfs           128M   30M   98M  24% /cache

# 3. Ver archivos en RAM
kubectl exec pod-emptydir-memory -- ls -lh /cache
# -rw-r--r-- 1 root root 10M Nov 10 18:05 test-1699641900.dat
# -rw-r--r-- 1 root root 10M Nov 10 18:05 test-1699641930.dat

# 4. Limpiar
kubectl delete pod pod-emptydir-memory
```

⚠️ **Advertencias**:
- Los datos en RAM son **más volátiles** (se pierden con reinicio del contenedor)
- Consume **memoria del nodo** (cuenta contra límites del Pod)
- Útil para **caches temporales** de alto rendimiento

### Ejemplo 3: Deployment con emptyDir

Caso práctico: Nginx con cache compartido

**Archivo**: [`ejemplos/01-emptydir/deployment-nginx-cache.yaml`](./ejemplos/01-emptydir/deployment-nginx-cache.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-with-cache
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-cache
  template:
    metadata:
      labels:
        app: nginx-cache
    spec:
      containers:
      # Nginx principal
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: cache
          mountPath: /var/cache/nginx
        - name: logs
          mountPath: /var/log/nginx
      
      # Sidecar que procesa logs
      - name: log-processor
        image: busybox
        command:
        - sh
        - -c
        - |
          echo "Procesando logs..."
          while true; do
            if [ -f /logs/access.log ]; then
              echo "=== Estadísticas de acceso ==="
              wc -l /logs/access.log
              echo "Últimas 5 peticiones:"
              tail -5 /logs/access.log
            fi
            sleep 30
          done
        volumeMounts:
        - name: logs
          mountPath: /logs
          readOnly: true  # Solo lectura
      
      # Volúmenes compartidos
      volumes:
      - name: cache
        emptyDir: {}
      - name: logs
        emptyDir: {}
```

**Aplicar y verificar**:

```bash
# 1. Desplegar
kubectl apply -f ejemplos/01-emptydir/deployment-nginx-cache.yaml

# 2. Verificar Pods
kubectl get pods -l app=nginx-cache
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-with-cache-7b8f9d5c4d-abc12   2/2     Running   0          30s
# nginx-with-cache-7b8f9d5c4d-xyz34   2/2     Running   0          30s

# 3. Exponer temporalmente
kubectl port-forward deployment/nginx-with-cache 8080:80 &

# 4. Generar tráfico
for i in {1..10}; do curl http://localhost:8080/; done

# 5. Ver logs procesados
POD=$(kubectl get pod -l app=nginx-cache -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD -c log-processor
# === Estadísticas de acceso ===
# 10 /logs/access.log
# Últimas 5 peticiones:
# 127.0.0.1 - - [10/Nov/2025:18:10:01 +0000] "GET / HTTP/1.1" 200 615

# 6. Verificar que cada Pod tiene su propio emptyDir
kubectl exec $POD -c nginx -- ls -la /var/cache/nginx

# 7. Limpiar
kubectl delete deployment nginx-with-cache
```

### Casos de Uso Reales de emptyDir

| Caso de Uso | Descripción | Ejemplo |
|-------------|-------------|---------|
| **Cache compartido** | Contenedor principal y sidecar comparten cache | Nginx + procesador de logs |
| **Datos intermedios** | Procesamiento por lotes en múltiples pasos | ETL pipeline |
| **Comunicación IPC** | Archivos Unix socket entre contenedores | App + proxy local |
| **Git checkout** | Init container clona repo, app lo usa | GitOps pattern |
| **Memoria compartida** | Comunicación de alto rendimiento | Aplicaciones científicas |

### Limitaciones Importantes

❌ **No usar emptyDir para**:
- Datos que deben sobrevivir al Pod
- Bases de datos
- Configuraciones importantes
- Archivos de usuario permanentes

✅ **Usar emptyDir para**:
- Cache temporal
- Logs antes de centralizarlos
- Datos de procesamiento temporal
- Comunicación entre contenedores del mismo Pod

---

## Implementación de hostPath

### Concepto Recordatorio

**hostPath** monta un directorio/archivo del **nodo** directamente en el Pod:
- Atado al nodo específico
- No portable entre nodos
- Riesgo de seguridad
- Solo para casos específicos (DaemonSets, monitoreo)

📖 **Ver teoría**: [Módulo 15 - hostPath](../modulo-15-volumes-conceptos/README.md#hostpath)

⚠️ **ADVERTENCIA**: No usar hostPath para aplicaciones normales en producción.

### Ejemplo 1: Acceso a Logs del Nodo

**Archivo**: [`ejemplos/02-hostpath/pod-hostpath-basic.yaml`](./ejemplos/02-hostpath/pod-hostpath-basic.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-hostpath-logs
spec:
  containers:
  - name: log-viewer
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "=== Logs del nodo montados en /host-logs ==="
      echo ""
      echo "Primeros 10 archivos:"
      ls /host-logs | head -10
      echo ""
      echo "Esperando... (Ctrl+C para salir)"
      tail -f /dev/null
    volumeMounts:
    - name: node-logs
      mountPath: /host-logs
      readOnly: true  # Solo lectura por seguridad
  
  volumes:
  - name: node-logs
    hostPath:
      path: /var/log      # Logs del nodo
      type: Directory     # Debe existir
```

**Aplicar y verificar**:

```bash
# 1. Crear Pod
kubectl apply -f ejemplos/02-hostpath/pod-hostpath-basic.yaml

# 2. Ver logs
kubectl logs pod-hostpath-logs
# === Logs del nodo montados en /host-logs ===
# 
# Primeros 10 archivos:
# alternatives.log
# apt
# bootstrap.log
# dpkg.log
# ...

# 3. Listar archivos específicos
kubectl exec pod-hostpath-logs -- ls -lh /host-logs/syslog
# -rw-r----- 1 syslog adm 1.2M Nov 10 18:15 /host-logs/syslog

# 4. Ver contenido (si tienes permisos)
kubectl exec pod-hostpath-logs -- tail -20 /host-logs/syslog

# 5. Ver en qué nodo está corriendo
kubectl get pod pod-hostpath-logs -o wide
# NAME                READY   STATUS    RESTARTS   AGE   IP           NODE
# pod-hostpath-logs   1/1     Running   0          1m    10.244.1.5   aks-node-1

# 6. Si eliminas y recreas, puede ir a otro nodo
kubectl delete pod pod-hostpath-logs
kubectl apply -f ejemplos/02-hostpath/pod-hostpath-basic.yaml
kubectl get pod pod-hostpath-logs -o wide
# Posiblemente en otro nodo → diferentes logs

# 7. Limpiar
kubectl delete pod pod-hostpath-logs
```

**Observación**: El Pod accede a los logs del **nodo específico** donde se programa.

### Ejemplo 2: DaemonSet para Monitoreo

Uso legítimo de hostPath: DaemonSet que recopila métricas de cada nodo.

**Archivo**: [`ejemplos/02-hostpath/daemonset-log-collector.yaml`](./ejemplos/02-hostpath/daemonset-log-collector.yaml)

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-log-collector
  labels:
    app: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      containers:
      - name: collector
        image: busybox
        command:
        - sh
        - -c
        - |
          echo "Iniciando recopilador de logs en $(hostname)"
          while true; do
            echo "=== $(date) ==="
            echo "Logs disponibles:"
            ls -lh /host-logs | head -5
            echo ""
            echo "Últimas líneas de syslog:"
            tail -3 /host-logs/syslog 2>/dev/null || echo "No disponible"
            echo "---"
            sleep 60
          done
        volumeMounts:
        - name: node-logs
          mountPath: /host-logs
          readOnly: true
        
        # Recursos mínimos para DaemonSet
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
      
      volumes:
      - name: node-logs
        hostPath:
          path: /var/log
          type: Directory
      
      # Tolerations para correr en todos los nodos
      tolerations:
      - effect: NoSchedule
        operator: Exists
```

**Aplicar y verificar**:

```bash
# 1. Desplegar DaemonSet
kubectl apply -f ejemplos/02-hostpath/daemonset-log-collector.yaml

# 2. Verificar que hay un Pod por nodo
kubectl get daemonset node-log-collector
# NAME                 DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE
# node-log-collector   3         3         3       3            3

kubectl get pods -l app=log-collector -o wide
# NAME                       READY   STATUS    NODE
# node-log-collector-abc12   1/1     Running   aks-node-1
# node-log-collector-def34   1/1     Running   aks-node-2
# node-log-collector-ghi56   1/1     Running   aks-node-3

# 3. Ver logs de un Pod específico (nodo 1)
kubectl logs node-log-collector-abc12 --tail=20
# === Sun Nov 10 18:20:01 UTC 2025 ===
# Logs disponibles:
# -rw-r----- 1 syslog adm 1.2M Nov 10 18:20 syslog
# ...

# 4. Ver logs de todos los Pods (todos los nodos)
kubectl logs -l app=log-collector --all-containers=true --tail=5
# [nodo-1] === Sun Nov 10 18:20:01 UTC 2025 ===
# [nodo-2] === Sun Nov 10 18:20:02 UTC 2025 ===
# [nodo-3] === Sun Nov 10 18:20:03 UTC 2025 ===

# 5. Verificar que cada Pod ve SOLO los logs de su nodo
kubectl exec node-log-collector-abc12 -- hostname
# aks-node-1
kubectl exec node-log-collector-abc12 -- ls /host-logs | head -3

# 6. Limpiar
kubectl delete daemonset node-log-collector
```

**¿Por qué funciona?**
- DaemonSet garantiza **un Pod por nodo**
- Cada Pod accede a los logs de **su propio nodo**
- No importa que hostPath esté atado al nodo

### Ejemplo 3: Tipos de hostPath

Kubernetes soporta diferentes tipos de validación:

**Archivo**: [`ejemplos/02-hostpath/pod-hostpath-types.yaml`](./ejemplos/02-hostpath/pod-hostpath-types.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-hostpath-types
spec:
  containers:
  - name: demo
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: dir-or-create
      mountPath: /test-dir
    - name: file-or-create
      mountPath: /test-file
  
  volumes:
  # Crea directorio si no existe
  - name: dir-or-create
    hostPath:
      path: /tmp/k8s-test-dir
      type: DirectoryOrCreate
  
  # Crea archivo si no existe
  - name: file-or-create
    hostPath:
      path: /tmp/k8s-test-file.txt
      type: FileOrCreate
```

**Tipos disponibles**:

| Tipo | Comportamiento | Uso |
|------|----------------|-----|
| `DirectoryOrCreate` | Crea directorio si no existe | **Recomendado** para directorios |
| `Directory` | Debe existir como directorio | Validación estricta |
| `FileOrCreate` | Crea archivo si no existe | Para archivos individuales |
| `File` | Debe existir como archivo | Configuraciones existentes |
| `Socket` | Socket UNIX debe existir | `/var/run/docker.sock` |
| `CharDevice` | Dispositivo de caracteres | Dispositivos especiales |
| `BlockDevice` | Dispositivo de bloques | Discos raw |

**Aplicar y verificar**:

```bash
# 1. Crear Pod
kubectl apply -f ejemplos/02-hostpath/pod-hostpath-types.yaml

# 2. Verificar montajes
kubectl exec pod-hostpath-types -- df -h
# /dev/sda1  ... /test-dir
# /dev/sda1  ... /test-file

# 3. Escribir en directorio
kubectl exec pod-hostpath-types -- sh -c "echo 'test' > /test-dir/data.txt"

# 4. Ver en el nodo (desde otro Pod en el mismo nodo)
NODE=$(kubectl get pod pod-hostpath-types -o jsonpath='{.spec.nodeName}')
echo "Pod en nodo: $NODE"

# Los datos están en /tmp/k8s-test-dir/ del nodo

# 5. Limpiar
kubectl delete pod pod-hostpath-types
```

### Riesgos de Seguridad de hostPath

⚠️ **Ejemplos de configuraciones PELIGROSAS**:

```yaml
# ❌ PELIGRO: Acceso a TODO el sistema de archivos
hostPath:
  path: /

# ❌ PELIGRO: Puede manipular kubelet
hostPath:
  path: /var/lib/kubelet

# ❌ PELIGRO: Puede modificar binarios del sistema
hostPath:
  path: /usr/bin

# ❌ PELIGRO: Acceso al Docker socket (escapar del contenedor)
hostPath:
  path: /var/run/docker.sock
```

**Mitigaciones**:

```yaml
# ✅ BUENO: Solo lectura
volumeMounts:
- name: node-logs
  mountPath: /logs
  readOnly: true  # ← Impide escritura

# ✅ BUENO: Ruta específica
hostPath:
  path: /var/log/app-specific  # No directorios raíz

# ✅ BUENO: Validación de tipo
hostPath:
  path: /var/log
  type: Directory  # Falla si no es directorio
```

### Cuándo Usar hostPath

✅ **Casos legítimos**:
- DaemonSets de monitoreo (Prometheus Node Exporter)
- Recopiladores de logs (Fluentd, Filebeat)
- Agentes de seguridad que necesitan ver el host
- Desarrollo local (Minikube)

❌ **NO usar para**:
- Aplicaciones normales
- Bases de datos multi-nodo
- Datos que deben estar disponibles en cualquier nodo
- Producción (usar PersistentVolumes en su lugar)

---

## PVC Básico con Azure Disk

### Concepto Recordatorio

**PersistentVolumeClaim (PVC)** es una solicitud de almacenamiento que:
- Se vincula automáticamente a un PersistentVolume (PV)
- Provisiona almacenamiento dinámicamente (con StorageClass)
- Sobrevive al Pod
- Es portable entre nodos

� **Ver teoría**: [Módulo 15 - PV/PVC](../modulo-15-volumes-conceptos/README.md#persistentvolume-pv-y-persistentvolumeclaim-pvc)

### Ejemplo 1: PVC con Provisioning Dinámico

El caso más común: crear PVC y que Azure cree automáticamente el disco.

**Archivo**: [`ejemplos/03-pvc-basico/pvc-dynamic-azure.yaml`](./ejemplos/03-pvc-basico/pvc-dynamic-azure.yaml)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-azure-disk-basic
  labels:
    app: demo-pvc
spec:
  accessModes:
    - ReadWriteOnce  # Solo un nodo a la vez
  storageClassName: managed-csi  # StorageClass de Azure Disk
  resources:
    requests:
      storage: 5Gi  # Solicitar 5 GiB
---
# Pod que usa el PVC
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-pvc
spec:
  containers:
  - name: app
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "Iniciando aplicación con PVC..."
      echo "Escribiendo datos en volumen persistente..."
      
      # Escribir datos iniciales
      echo "Pod iniciado: $(date)" > /data/init.txt
      
      # Escribir datos cada 10 segundos
      counter=1
      while true; do
        echo "Escritura #$counter: $(date)" >> /data/log.txt
        echo "Total de escrituras: $counter"
        counter=$((counter + 1))
        sleep 10
      done
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: pvc-azure-disk-basic  # ← Referencia al PVC
```

**Aplicar y verificar el ciclo completo**:

```bash
# 1. Crear el PVC
kubectl apply -f ejemplos/03-pvc-basico/pvc-dynamic-azure.yaml

# 2. Verificar que el PVC está en estado Bound
kubectl get pvc pvc-azure-disk-basic
# NAME                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES
# pvc-azure-disk-basic   Bound    pvc-a1b2c3d4-e5f6-7g8h-9i0j-k1l2m3n4o5p6   5Gi        RWO

# Esto puede tardar ~30 segundos mientras Azure crea el disco

# 3. Ver detalles del PVC
kubectl describe pvc pvc-azure-disk-basic
# Name:          pvc-azure-disk-basic
# Namespace:     default
# StorageClass:  managed-csi
# Status:        Bound
# Volume:        pvc-a1b2c3d4...
# Labels:        app=demo-pvc
# Capacity:      5Gi
# Access Modes:  RWO
# VolumeMode:    Filesystem
# Events:
#   Normal  ProvisioningSucceeded  Successfully provisioned volume

# 4. Ver el PV creado automáticamente
kubectl get pv
# NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
# pvc-a1b2c3d4-e5f6-7g8h-9i0j-k1l2m3n4o5p6   5Gi        RWO            Delete           Bound    default/pvc-azure-disk-basic

# 5. El Pod ya debe estar corriendo
kubectl get pod pod-with-pvc
# NAME           READY   STATUS    RESTARTS   AGE
# pod-with-pvc   1/1     Running   0          1m

# 6. Verificar que está escribiendo datos
kubectl logs pod-with-pvc
# Iniciando aplicación con PVC...
# Escribiendo datos en volumen persistente...
# Total de escrituras: 1
# Total de escrituras: 2
# Total de escrituras: 3

# 7. Verificar archivos en el volumen
kubectl exec pod-with-pvc -- ls -lh /data
# total 8K
# -rw-r--r-- 1 root root  42 Nov 10 19:00 init.txt
# -rw-r--r-- 1 root root 256 Nov 10 19:01 log.txt

kubectl exec pod-with-pvc -- cat /data/init.txt
# Pod iniciado: Sun Nov 10 19:00:15 UTC 2025

kubectl exec pod-with-pvc -- wc -l /data/log.txt
# 15 /data/log.txt

# 8. PRUEBA DE PERSISTENCIA: Eliminar el Pod
kubectl delete pod pod-with-pvc
# pod "pod-with-pvc" deleted

# 9. Verificar que el PVC sigue Bound
kubectl get pvc pvc-azure-disk-basic
# NAME                   STATUS   VOLUME        CAPACITY   ACCESS MODES
# pvc-azure-disk-basic   Bound    pvc-a1b2c3d4  5Gi        RWO
# ✅ El PVC NO se eliminó

# 10. Recrear el Pod con el MISMO PVC
kubectl apply -f ejemplos/03-pvc-basico/pvc-dynamic-azure.yaml

# 11. Esperar a que inicie
kubectl wait --for=condition=ready pod/pod-with-pvc --timeout=60s

# 12. Verificar que los DATOS ANTERIORES siguen ahí
kubectl exec pod-with-pvc -- cat /data/init.txt
# Pod iniciado: Sun Nov 10 19:00:15 UTC 2025
# ✅ Datos del Pod anterior preservados!

kubectl exec pod-with-pvc -- wc -l /data/log.txt
# 15 /data/log.txt
# ✅ Las 15 líneas anteriores siguen ahí

# 13. Ver que ahora hay datos nuevos Y viejos
sleep 30
kubectl exec pod-with-pvc -- tail -5 /data/log.txt
# Escritura #15: Sun Nov 10 19:01:45 UTC 2025  ← Viejo
# Escritura #1: Sun Nov 10 19:05:00 UTC 2025   ← Nuevo Pod
# Escritura #2: Sun Nov 10 19:05:10 UTC 2025
# Escritura #3: Sun Nov 10 19:05:20 UTC 2025
# Escritura #4: Sun Nov 10 19:05:30 UTC 2025

# 14. Limpiar
kubectl delete pod pod-with-pvc
kubectl delete pvc pvc-azure-disk-basic
# El PV y el disco de Azure se eliminan automáticamente (Reclaim Policy: Delete)
```

**¿Qué aprendimos?**
- ✅ PVC provisiona disco Azure automáticamente
- ✅ Datos persisten cuando Pod muere
- ✅ Nuevo Pod puede montar el mismo PVC
- ✅ Eliminar PVC elimina el disco (política Delete)

### Ejemplo 2: PostgreSQL con PVC

Caso real: Base de datos con almacenamiento persistente.

**Archivo**: [`ejemplos/03-pvc-basico/deployment-postgres-pvc.yaml`](./ejemplos/03-pvc-basico/deployment-postgres-pvc.yaml)

```yaml
# PVC para PostgreSQL
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  labels:
    app: postgres
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi
  resources:
    requests:
      storage: 10Gi
---
# Deployment de PostgreSQL
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  labels:
    app: postgres
spec:
  replicas: 1  # Solo 1 réplica (RWO permite solo un Pod)
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "supersecret123"  # ⚠️ Usar Secret en producción
        - name: POSTGRES_DB
          value: "testdb"
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
          name: postgres
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
          # subPath evita problemas con lost+found
      
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
# Service para acceder a PostgreSQL
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
```

**Aplicar y probar persistencia de datos**:

```bash
# 1. Desplegar PostgreSQL
kubectl apply -f ejemplos/03-pvc-basico/deployment-postgres-pvc.yaml

# 2. Esperar a que esté listo
kubectl wait --for=condition=available deployment/postgres --timeout=120s

# 3. Verificar PVC
kubectl get pvc postgres-pvc
# NAME           STATUS   VOLUME        CAPACITY   ACCESS MODES
# postgres-pvc   Bound    pvc-xyz123    10Gi       RWO

# 4. Obtener nombre del Pod
POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
echo "Pod de PostgreSQL: $POD"

# 5. Crear una base de datos y tabla
kubectl exec -it $POD -- psql -U postgres -d testdb -c "
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW()
);
"
# CREATE TABLE

# 6. Insertar datos
kubectl exec -it $POD -- psql -U postgres -d testdb -c "
INSERT INTO users (name) VALUES 
  ('Alice'),
  ('Bob'),
  ('Charlie');
"
# INSERT 0 3

# 7. Verificar datos
kubectl exec -it $POD -- psql -U postgres -d testdb -c "SELECT * FROM users;"
#  id |  name   |         created_at         
# ----+---------+----------------------------
#   1 | Alice   | 2025-11-10 19:10:00.123456
#   2 | Bob     | 2025-11-10 19:10:00.123457
#   3 | Charlie | 2025-11-10 19:10:00.123458

# 8. PRUEBA DE PERSISTENCIA: Eliminar el Pod
kubectl delete pod $POD
# pod "postgres-xyz-abc" deleted

# 9. Esperar a que Deployment recree el Pod
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# 10. Obtener nuevo nombre de Pod
NEW_POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
echo "Nuevo Pod: $NEW_POD"

# 11. Verificar que los DATOS siguen ahí
kubectl exec -it $NEW_POD -- psql -U postgres -d testdb -c "SELECT * FROM users;"
#  id |  name   |         created_at         
# ----+---------+----------------------------
#   1 | Alice   | 2025-11-10 19:10:00.123456
#   2 | Bob     | 2025-11-10 19:10:00.123457
#   3 | Charlie | 2025-11-10 19:10:00.123458
# ✅ DATOS PRESERVADOS!

# 12. Insertar más datos
kubectl exec -it $NEW_POD -- psql -U postgres -d testdb -c "
INSERT INTO users (name) VALUES ('David');
"

kubectl exec -it $NEW_POD -- psql -U postgres -d testdb -c "SELECT COUNT(*) FROM users;"
#  count 
# -------
#      4

# 13. Ver uso de disco
kubectl exec $NEW_POD -- df -h /var/lib/postgresql/data
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sdc        9.8G  150M  9.2G   2% /var/lib/postgresql/data

# 14. Limpiar
kubectl delete deployment postgres
kubectl delete service postgres
kubectl delete pvc postgres-pvc
```

**Observaciones importantes**:
- ✅ Base de datos sobrevive reinicio del Pod
- ✅ Deployment recrea Pod automáticamente
- ✅ Datos persisten en Azure Disk
- ⚠️ Solo 1 réplica porque Azure Disk es RWO

### Ejemplo 3: PVC con Premium SSD

Para aplicaciones con alto I/O, usa Premium SSD.

**Archivo**: [`ejemplos/03-pvc-basico/pvc-premium-ssd.yaml`](./ejemplos/03-pvc-basico/pvc-premium-ssd.yaml)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-premium
  labels:
    performance: high
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi-premium  # ← Premium SSD
  resources:
    requests:
      storage: 128Gi  # Mínimo 128Gi para Premium
```

**Aplicar y comparar rendimiento**:

```bash
# 1. Crear PVC Premium
kubectl apply -f ejemplos/03-pvc-basico/pvc-premium-ssd.yaml

# 2. Verificar
kubectl get pvc pvc-premium
# NAME          STATUS   VOLUME        CAPACITY   STORAGECLASS
# pvc-premium   Bound    pvc-abc123    128Gi      managed-csi-premium

# 3. Ver detalles del PV
kubectl get pv -o custom-columns=\
NAME:.metadata.name,\
CAPACITY:.spec.capacity.storage,\
STORAGECLASS:.spec.storageClassName,\
RECLAIM:.spec.persistentVolumeReclaimPolicy

# 4. Comparar con Standard
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-standard
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi
  resources:
    requests:
      storage: 10Gi
EOF

# 5. Ver ambos
kubectl get pvc
# NAME           STATUS   VOLUME      CAPACITY   STORAGECLASS
# pvc-premium    Bound    pvc-abc123  128Gi      managed-csi-premium
# pvc-standard   Bound    pvc-xyz456  10Gi       managed-csi

# 6. Limpiar
kubectl delete pvc pvc-premium pvc-standard
```

**Diferencias clave**:

| Aspecto | Standard SSD | Premium SSD |
|---------|--------------|-------------|
| **StorageClass** | `managed-csi` | `managed-csi-premium` |
| **Tamaño mínimo** | 1Gi | 128Gi |
| **IOPS** | Hasta 500 | Hasta 20,000 |
| **Throughput** | Hasta 60 MB/s | Hasta 900 MB/s |
| **Latencia** | ~10ms | <1ms |
| **Costo** | � | 💰💰💰 |
| **Uso** | Apps generales | Bases de datos, alto I/O |

### Ejemplo 4: PVC con Azure Files (ReadWriteMany)

Para compartir archivos entre múltiples Pods.

**Archivo**: [`ejemplos/03-pvc-basico/pvc-azure-files.yaml`](./ejemplos/03-pvc-basico/pvc-azure-files.yaml)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-shared-files
  labels:
    type: shared
spec:
  accessModes:
    - ReadWriteMany  # ← Múltiples Pods pueden acceder
  storageClassName: azurefile-csi  # Azure Files
  resources:
    requests:
      storage: 50Gi
---
# Deployment con múltiples réplicas compartiendo archivos
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-with-shared-files
spec:
  replicas: 3  # 3 Pods compartiendo el mismo volumen
  selector:
    matchLabels:
      app: web-shared
  template:
    metadata:
      labels:
        app: web-shared
    spec:
      containers:
      - name: web
        image: nginx:alpine
        command:
        - sh
        - -c
        - |
          # Escribir hostname en archivo compartido
          echo "Pod $(hostname) iniciado en $(date)" >> /shared/access.log
          
          # Servir archivos compartidos
          echo "<h1>Pod: $(hostname)</h1>" > /usr/share/nginx/html/index.html
          echo "<p>Archivos compartidos en /shared</p>" >> /usr/share/nginx/html/index.html
          echo "<pre>$(ls -lh /shared)</pre>" >> /usr/share/nginx/html/index.html
          
          # Iniciar nginx
          nginx -g 'daemon off;'
        volumeMounts:
        - name: shared-storage
          mountPath: /shared
        ports:
        - containerPort: 80
      
      volumes:
      - name: shared-storage
        persistentVolumeClaim:
          claimName: pvc-shared-files
```

**Aplicar y verificar compartición**:

```bash
# 1. Desplegar
kubectl apply -f ejemplos/03-pvc-basico/pvc-azure-files.yaml

# 2. Esperar
kubectl wait --for=condition=available deployment/web-with-shared-files --timeout=120s

# 3. Verificar PVC
kubectl get pvc pvc-shared-files
# NAME               STATUS   VOLUME        CAPACITY   ACCESS MODES
# pvc-shared-files   Bound    pvc-files123  50Gi       RWX

# 4. Ver los 3 Pods
kubectl get pods -l app=web-shared
# NAME                                    READY   STATUS    RESTARTS   AGE
# web-with-shared-files-abc-123          1/1     Running   0          1m
# web-with-shared-files-abc-456          1/1     Running   0          1m
# web-with-shared-files-abc-789          1/1     Running   0          1m

# 5. Verificar que TODOS escribieron en el archivo compartido
POD1=$(kubectl get pod -l app=web-shared -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD1 -- cat /shared/access.log
# Pod web-with-shared-files-abc-123 iniciado en Sun Nov 10 19:20:00 UTC 2025
# Pod web-with-shared-files-abc-456 iniciado en Sun Nov 10 19:20:01 UTC 2025
# Pod web-with-shared-files-abc-789 iniciado en Sun Nov 10 19:20:02 UTC 2025
# ✅ Los 3 Pods escribieron en el MISMO archivo!

# 6. Escribir desde un Pod
kubectl exec $POD1 -- sh -c "echo 'Mensaje desde Pod 1' >> /shared/messages.txt"

# 7. Leer desde OTRO Pod
POD2=$(kubectl get pod -l app=web-shared -o jsonpath='{.items[1].metadata.name}')
kubectl exec $POD2 -- cat /shared/messages.txt
# Mensaje desde Pod 1
# ✅ Pod 2 ve lo que Pod 1 escribió!

# 8. Ver que TODOS los Pods ven el mismo directorio
for pod in $(kubectl get pod -l app=web-shared -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== $pod ==="
  kubectl exec $pod -- ls -lh /shared
done

# 9. Limpiar
kubectl delete deployment web-with-shared-files
kubectl delete pvc pvc-shared-files
```

**Casos de uso de ReadWriteMany**:
- 📤 Uploads compartidos entre Pods web
- 📝 Logs centralizados
- 🎨 CMS con múltiples workers
- 📊 Datos de configuración compartidos
- 🖼️ Assets estáticos (imágenes, CSS, JS)

### Ejemplo 5: StorageClass Personalizada

Crear tu propia StorageClass con configuración específica.

**Archivo**: [`ejemplos/03-pvc-basico/storageclass-custom.yaml`](./ejemplos/03-pvc-basico/storageclass-custom.yaml)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd-retain
  labels:
    tier: premium
provisioner: disk.csi.azure.com
parameters:
  skuname: Premium_LRS        # Premium SSD
  cachingmode: ReadOnly       # Cache de lectura
  kind: Managed
  storageaccounttype: Premium_LRS
reclaimPolicy: Retain         # ← Proteger datos (no eliminar disco)
volumeBindingMode: WaitForFirstConsumer  # Crear en la misma zona que el Pod
allowVolumeExpansion: true    # Permitir expansión
mountOptions:
  - dir_mode=0755
  - file_mode=0644
  - uid=1000
  - gid=1000
---
# PVC usando la StorageClass personalizada
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-custom-class
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd-retain  # ← Usar clase personalizada
  resources:
    requests:
      storage: 256Gi
```

**Aplicar y verificar**:

```bash
# 1. Crear StorageClass personalizada
kubectl apply -f ejemplos/03-pvc-basico/storageclass-custom.yaml

# 2. Listar StorageClasses
kubectl get storageclass
# NAME                PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE
# fast-ssd-retain     disk.csi.azure.com   Retain          WaitForFirstConsumer
# managed-csi         disk.csi.azure.com   Delete          WaitForFirstConsumer
# ...

# 3. Ver detalles
kubectl describe storageclass fast-ssd-retain
# Name:            fast-ssd-retain
# Provisioner:     disk.csi.azure.com
# Parameters:      cachingmode=ReadOnly,kind=Managed,skuname=Premium_LRS
# ReclaimPolicy:   Retain
# VolumeBindingMode: WaitForFirstConsumer
# AllowVolumeExpansion: True

# 4. PVC está Pending (WaitForFirstConsumer)
kubectl get pvc pvc-custom-class
# NAME              STATUS    VOLUME   CAPACITY   ACCESS MODES
# pvc-custom-class  Pending                       RWO

# 5. Crear Pod que use el PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pod-custom-storage
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-custom-class
EOF

# 6. Ahora el PVC se provisiona
kubectl get pvc pvc-custom-class
# NAME              STATUS   VOLUME        CAPACITY   ACCESS MODES
# pvc-custom-class  Bound    pvc-abc123    256Gi      RWO

# 7. Ver que tiene política Retain
kubectl get pv -o custom-columns=\
NAME:.metadata.name,\
CAPACITY:.spec.capacity.storage,\
RECLAIM:.spec.persistentVolumeReclaimPolicy
# NAME          CAPACITY   RECLAIM
# pvc-abc123    256Gi      Retain

# 8. Eliminar Pod y PVC
kubectl delete pod pod-custom-storage
kubectl delete pvc pvc-custom-class

# 9. El PV queda en Released (no se elimina)
kubectl get pv
# NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS
# pvc-abc123    256Gi      RWO            Retain           Released

# ✅ El disco Azure NO se eliminó (política Retain)

# 10. Limpiar manualmente
kubectl delete pv pvc-abc123
kubectl delete storageclass fast-ssd-retain
```

**Parámetros importantes de StorageClass**:

| Parámetro | Valores | Descripción |
|-----------|---------|-------------|
| `skuname` | Standard_LRS, Premium_LRS, StandardSSD_LRS | Tipo de disco |
| `cachingmode` | None, ReadOnly, ReadWrite | Cache del disco |
| `reclaimPolicy` | Delete, Retain | Qué hacer al eliminar PVC |
| `volumeBindingMode` | Immediate, WaitForFirstConsumer | Cuándo crear |
| `allowVolumeExpansion` | true, false | Permitir expansión |

---

📁 **Próxima sección**: Continuará con Access Modes en la práctica (ETAPA 4C).

💡 **Has aprendido**:
- ✅ PVC con provisioning dinámico
- ✅ PostgreSQL persistente
- ✅ Diferencias Premium vs Standard
- ✅ ReadWriteMany con Azure Files
- ✅ StorageClasses personalizadas

---

## Access Modes en la Práctica

### Concepto Recordatorio

Los **Access Modes** definen cómo se puede montar un volumen:

- **ReadWriteOnce (RWO)**: Solo un nodo puede montar en modo lectura-escritura
- **ReadOnlyMany (ROX)**: Múltiples nodos pueden montar en solo lectura
- **ReadWriteMany (RWX)**: Múltiples nodos pueden montar en lectura-escritura

📖 **Ver teoría**: [Módulo 15 - Access Modes](../modulo-15-volumes-conceptos/README.md#access-modes)

### Compatibilidad de Access Modes en Azure

| Storage Type | RWO | ROX | RWX | Notas |
|--------------|-----|-----|-----|-------|
| **Azure Disk** | ✅ | ❌ | ❌ | Solo un Pod a la vez |
| **Azure Files** | ✅ | ✅ | ✅ | Todos los modos soportados |
| **emptyDir** | ✅ | ✅ | ✅ | Solo dentro del mismo Pod |
| **hostPath** | ✅ | ✅ | ✅ | Solo en el mismo nodo |

### Ejemplo 1: ReadWriteOnce (RWO) - Caso Típico

El access mode más común: un disco que solo puede ser usado por un Pod a la vez.

**Archivo**: [`ejemplos/05-access-modes/pvc-rwo-exclusive.yaml`](./ejemplos/05-access-modes/pvc-rwo-exclusive.yaml)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwo-database
  labels:
    access: exclusive
spec:
  accessModes:
    - ReadWriteOnce  # ← Solo un nodo/Pod
  storageClassName: managed-csi
  resources:
    requests:
      storage: 10Gi
---
# Deployment con 1 réplica (funciona)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-single
spec:
  replicas: 1  # ← Solo 1 Pod puede usar RWO
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpass123"
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
      
      volumes:
      - name: mysql-data
        persistentVolumeClaim:
          claimName: pvc-rwo-database
```

**Aplicar y probar límite de RWO**:

```bash
# 1. Crear PVC y Deployment
kubectl apply -f ejemplos/05-access-modes/pvc-rwo-exclusive.yaml

# 2. Verificar
kubectl get pvc pvc-rwo-database
# NAME              STATUS   VOLUME        CAPACITY   ACCESS MODES
# pvc-rwo-database  Bound    pvc-abc123    10Gi       RWO

kubectl get pods -l app=mysql
# NAME                           READY   STATUS    RESTARTS   AGE
# mysql-single-xyz-123          1/1     Running   0          1m

# 3. INTENTAR escalar a 2 réplicas
kubectl scale deployment mysql-single --replicas=2

# 4. Ver qué pasa
kubectl get pods -l app=mysql
# NAME                           READY   STATUS              RESTARTS   AGE
# mysql-single-xyz-123          1/1     Running             0          2m
# mysql-single-xyz-456          0/1     ContainerCreating   0          30s

# ⚠️ El segundo Pod se queda en ContainerCreating

# 5. Ver el problema
kubectl describe pod mysql-single-xyz-456 | grep -A 5 Events
# Events:
#   Type     Reason              Message
#   ----     ------              -------
#   Warning  FailedAttachVolume  Multi-Attach error for volume "pvc-abc123"
#   Warning  FailedMount         Unable to attach or mount volumes: unmounted volumes=[mysql-data]

# ❌ Azure Disk no permite múltiples Pods simultáneos con RWO

# 6. Volver a 1 réplica
kubectl scale deployment mysql-single --replicas=1

# 7. Limpiar
kubectl delete deployment mysql-single
kubectl delete pvc pvc-rwo-database
```

**Lección importante**: RWO = **1 Pod a la vez**, aunque estén en el mismo nodo.

### Ejemplo 2: ReadWriteMany (RWX) - Compartición Múltiple

Para compartir archivos entre múltiples Pods, necesitas Azure Files.

**Archivo**: [`ejemplos/05-access-modes/pvc-rwx-shared.yaml`](./ejemplos/05-access-modes/pvc-rwx-shared.yaml)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwx-uploads
  labels:
    access: shared
spec:
  accessModes:
    - ReadWriteMany  # ← Múltiples Pods pueden leer/escribir
  storageClassName: azurefile-csi  # Requiere Azure Files
  resources:
    requests:
      storage: 20Gi
---
# Deployment con múltiples réplicas (funciona)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-upload
spec:
  replicas: 3  # ← 3 Pods compartiendo el volumen
  selector:
    matchLabels:
      app: web-upload
  template:
    metadata:
      labels:
        app: web-upload
    spec:
      containers:
      - name: web
        image: nginx:alpine
        command:
        - sh
        - -c
        - |
          # Script de inicio que registra el Pod
          echo "Pod $(hostname) iniciado en $(date)" >> /uploads/activity.log
          
          # Crear index.html que muestra archivos
          cat > /usr/share/nginx/html/index.html <<'EOF'
          <!DOCTYPE html>
          <html>
          <head>
            <title>Shared Uploads</title>
            <meta http-equiv="refresh" content="5">
          </head>
          <body>
            <h1>Pod: HOSTNAME</h1>
            <h2>Archivos Compartidos:</h2>
            <iframe src="/uploads/" width="100%" height="400"></iframe>
            <h2>Registro de Actividad:</h2>
            <pre id="log"></pre>
            <script>
              fetch('/uploads/activity.log')
                .then(r => r.text())
                .then(t => document.getElementById('log').textContent = t);
            </script>
          </body>
          </html>
EOF
          
          # Reemplazar HOSTNAME con el nombre real del Pod
          sed -i "s/HOSTNAME/$(hostname)/g" /usr/share/nginx/html/index.html
          
          # Configurar Nginx para servir /uploads
          cat > /etc/nginx/conf.d/uploads.conf <<'EOF'
          server {
            listen 80;
            location /uploads/ {
              alias /uploads/;
              autoindex on;
            }
          }
EOF
          
          # Iniciar Nginx
          nginx -g 'daemon off;'
        
        volumeMounts:
        - name: shared-uploads
          mountPath: /uploads
        
        ports:
        - containerPort: 80
      
      volumes:
      - name: shared-uploads
        persistentVolumeClaim:
          claimName: pvc-rwx-uploads
---
# Service para acceder
apiVersion: v1
kind: Service
metadata:
  name: web-upload
spec:
  selector:
    app: web-upload
  ports:
  - port: 80
  type: LoadBalancer
```

**Aplicar y probar compartición real**:

```bash
# 1. Desplegar
kubectl apply -f ejemplos/05-access-modes/pvc-rwx-shared.yaml

# 2. Esperar a que esté listo
kubectl wait --for=condition=available deployment/web-upload --timeout=120s

# 3. Verificar PVC
kubectl get pvc pvc-rwx-uploads
# NAME             STATUS   VOLUME        CAPACITY   ACCESS MODES
# pvc-rwx-uploads  Bound    pvc-files123  20Gi       RWX

# 4. Ver los 3 Pods
kubectl get pods -l app=web-upload
# NAME                         READY   STATUS    RESTARTS   AGE
# web-upload-abc-123          1/1     Running   0          1m
# web-upload-abc-456          1/1     Running   0          1m
# web-upload-abc-789          1/1     Running   0          1m

# ✅ Los 3 Pods se iniciaron correctamente (no como con RWO)

# 5. Todos escribieron en el log compartido
kubectl exec deployment/web-upload -- cat /uploads/activity.log
# Pod web-upload-abc-123 iniciado en Sun Nov 10 20:00:00 UTC 2025
# Pod web-upload-abc-456 iniciado en Sun Nov 10 20:00:01 UTC 2025
# Pod web-upload-abc-789 iniciado en Sun Nov 10 20:00:02 UTC 2025

# 6. Subir archivo desde Pod 1
POD1=$(kubectl get pod -l app=web-upload -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD1 -- sh -c "echo 'Contenido desde Pod 1' > /uploads/file-from-pod1.txt"

# 7. Leer desde Pod 2
POD2=$(kubectl get pod -l app=web-upload -o jsonpath='{.items[1].metadata.name}')
kubectl exec $POD2 -- cat /uploads/file-from-pod1.txt
# Contenido desde Pod 1
# ✅ Pod 2 ve lo que Pod 1 escribió

# 8. Todos los Pods ven los mismos archivos
for pod in $(kubectl get pod -l app=web-upload -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== $pod ==="
  kubectl exec $pod -- ls -lh /uploads/
done
# ==> Todos muestran los mismos archivos

# 9. Obtener IP del Service
kubectl get service web-upload
# NAME         TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)
# web-upload   LoadBalancer   10.0.100.50    52.123.45.67    80:30123/TCP

# 10. Probar desde navegador o curl
# Cada refresh puede ser atendido por un Pod diferente
# curl http://52.123.45.67/

# 11. Limpiar
kubectl delete deployment web-upload
kubectl delete service web-upload
kubectl delete pvc pvc-rwx-uploads
```

**Diferencia clave RWO vs RWX**:

| Aspecto | RWO (Azure Disk) | RWX (Azure Files) |
|---------|------------------|-------------------|
| **Pods simultáneos** | ❌ Solo 1 | ✅ Múltiples |
| **Escalamiento** | ❌ Bloqueado | ✅ Libre |
| **Compartir archivos** | ❌ No | ✅ Sí |
| **Rendimiento** | 🚀 Alto (SSD) | 📊 Medio (NFS-like) |
| **Costo** | 💰 | 💰💰 |
| **Caso de uso** | Bases de datos | CMS, uploads, logs |

### Ejemplo 3: ReadOnlyMany (ROX) - Configuración Compartida

Distribuir configuración inmutable a múltiples Pods.

**Archivo**: [`ejemplos/05-access-modes/pvc-rox-config.yaml`](./ejemplos/05-access-modes/pvc-rox-config.yaml)

```yaml
# 1. PVC inicial con RWX para cargar datos
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-shared-config
spec:
  accessModes:
    - ReadWriteMany  # Inicialmente RWX para escribir
  storageClassName: azurefile-csi
  resources:
    requests:
      storage: 1Gi
---
# 2. Job para cargar configuración
apiVersion: batch/v1
kind: Job
metadata:
  name: load-config
spec:
  template:
    spec:
      containers:
      - name: loader
        image: busybox
        command:
        - sh
        - -c
        - |
          echo "Cargando configuración inicial..."
          
          # Crear archivos de configuración
          cat > /config/app.conf <<'EOF'
          # Configuración de la aplicación
          DB_HOST=postgres.default.svc.cluster.local
          DB_PORT=5432
          CACHE_ENABLED=true
          LOG_LEVEL=info
EOF
          
          cat > /config/features.json <<'EOF'
          {
            "feature_flags": {
              "new_ui": true,
              "beta_api": false,
              "analytics": true
            }
          }
EOF
          
          echo "Configuración cargada exitosamente"
          ls -lh /config/
        
        volumeMounts:
        - name: config-volume
          mountPath: /config
      
      volumes:
      - name: config-volume
        persistentVolumeClaim:
          claimName: pvc-shared-config
      
      restartPolicy: Never
---
# 3. Deployment que lee configuración (read-only)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-config
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: nginx:alpine
        command:
        - sh
        - -c
        - |
          echo "Pod $(hostname) iniciado"
          
          # Verificar que archivos están presentes
          echo "=== Archivos de configuración ==="
          ls -lh /config/
          
          echo ""
          echo "=== app.conf ==="
          cat /config/app.conf
          
          echo ""
          echo "=== features.json ==="
          cat /config/features.json
          
          # Intentar escribir (debería fallar por read-only)
          echo ""
          echo "=== Intentando escribir (debería fallar) ==="
          echo "test" > /config/test.txt 2>&1 || echo "✅ Escritura bloqueada correctamente"
          
          # Mantener Pod vivo
          sleep 3600
        
        volumeMounts:
        - name: config-volume
          mountPath: /config
          readOnly: true  # ← Montar en modo solo lectura
      
      volumes:
      - name: config-volume
        persistentVolumeClaim:
          claimName: pvc-shared-config
```

**Aplicar y verificar read-only**:

```bash
# 1. Crear PVC y Job de carga
kubectl apply -f ejemplos/05-access-modes/pvc-rox-config.yaml

# 2. Esperar a que Job complete
kubectl wait --for=condition=complete job/load-config --timeout=60s

# 3. Ver logs del Job
kubectl logs job/load-config
# Cargando configuración inicial...
# Configuración cargada exitosamente
# total 8K
# -rw-r--r-- 1 root root 120 Nov 10 20:10 app.conf
# -rw-r--r-- 1 root root 150 Nov 10 20:10 features.json

# 4. Deployment ya está corriendo
kubectl get pods -l app=myapp
# NAME                              READY   STATUS    RESTARTS   AGE
# app-with-config-abc-123          1/1     Running   0          1m
# app-with-config-abc-456          1/1     Running   0          1m
# app-with-config-abc-789          1/1     Running   0          1m

# 5. Ver logs de cualquier Pod
POD=$(kubectl get pod -l app=myapp -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD
# Pod app-with-config-abc-123 iniciado
# === Archivos de configuración ===
# total 8K
# -rw-r--r-- 1 root root 120 Nov 10 20:10 app.conf
# -rw-r--r-- 1 root root 150 Nov 10 20:10 features.json
#
# === app.conf ===
# # Configuración de la aplicación
# DB_HOST=postgres.default.svc.cluster.local
# DB_PORT=5432
# CACHE_ENABLED=true
# LOG_LEVEL=info
#
# === features.json ===
# {
#   "feature_flags": {
#     "new_ui": true,
#     "beta_api": false,
#     "analytics": true
#   }
# }
#
# === Intentando escribir (debería fallar) ===
# ✅ Escritura bloqueada correctamente

# 6. Intentar escribir manualmente desde un Pod
kubectl exec $POD -- sh -c "echo 'hack' > /config/hack.txt"
# sh: can't create /config/hack.txt: Read-only file system
# ✅ Protección funcionando

# 7. Pero el PVC original permite escritura (para actualizaciones)
kubectl run config-updater --image=busybox --rm -it --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "config-updater",
      "image": "busybox",
      "command": ["sh", "-c", "echo \"UPDATED=true\" >> /config/app.conf && cat /config/app.conf"],
      "volumeMounts": [{
        "name": "config",
        "mountPath": "/config"
      }]
    }],
    "volumes": [{
      "name": "config",
      "persistentVolumeClaim": {
        "claimName": "pvc-shared-config"
      }
    }]
  }
}'
# (muestra el archivo actualizado con UPDATED=true)

# 8. Los Pods existentes NO ven el cambio (necesitan reinicio)
kubectl exec $POD -- grep UPDATED /config/app.conf
# (no sale nada, porque el Pod ya tenía el volumen montado)

# 9. Reiniciar Pods para ver cambios
kubectl rollout restart deployment/app-with-config
kubectl wait --for=condition=ready pod -l app=myapp --timeout=60s

# 10. Ahora sí ven el cambio
NEW_POD=$(kubectl get pod -l app=myapp -o jsonpath='{.items[0].metadata.name}')
kubectl exec $NEW_POD -- grep UPDATED /config/app.conf
# UPDATED=true

# 11. Limpiar
kubectl delete deployment app-with-config
kubectl delete job load-config
kubectl delete pvc pvc-shared-config
```

**Patrón ROX útil**:
1. ✅ Job/Pod inicial escribe configuración (RWX)
2. ✅ Deployment monta como `readOnly: true`
3. ✅ Protege contra modificaciones accidentales
4. ✅ Permite actualizaciones controladas
5. ✅ Rollout para aplicar cambios

---

## Reclaim Policies en la Práctica

### Concepto Recordatorio

**Reclaim Policy** define qué pasa con el PV cuando se elimina el PVC:

- **Delete**: Eliminar PV y disco Azure automáticamente
- **Retain**: Conservar PV y disco para recuperación manual

📖 **Ver teoría**: [Módulo 15 - Reclaim Policies](../modulo-15-volumes-conceptos/README.md#reclaim-policy)

### Ejemplo 1: Política Delete (Por Defecto)

Comportamiento estándar: eliminar todo cuando se borra el PVC.

**Archivo**: [`ejemplos/06-reclaim-policies/pvc-delete-policy.yaml`](./ejemplos/06-reclaim-policies/pvc-delete-policy.yaml)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-ephemeral-data
  labels:
    retention: temporary
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi  # Delete policy por defecto
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-temp-data
spec:
  containers:
  - name: app
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "Generando datos temporales..."
      
      # Escribir bastantes datos
      for i in $(seq 1 100); do
        echo "Línea de datos #$i: $(date)" >> /data/temp-data.txt
      done
      
      echo "Total de líneas: $(wc -l /data/temp-data.txt)"
      
      # Mantener vivo
      sleep 3600
    
    volumeMounts:
    - name: temp-storage
      mountPath: /data
  
  volumes:
  - name: temp-storage
    persistentVolumeClaim:
      claimName: pvc-ephemeral-data
```

**Probar ciclo completo de Delete**:

```bash
# 1. Crear PVC y Pod
kubectl apply -f ejemplos/06-reclaim-policies/pvc-delete-policy.yaml

# 2. Esperar
kubectl wait --for=condition=ready pod/pod-temp-data --timeout=60s

# 3. Ver PVC y PV
kubectl get pvc pvc-ephemeral-data
# NAME                  STATUS   VOLUME        CAPACITY   ACCESS MODES
# pvc-ephemeral-data    Bound    pvc-abc123    5Gi        RWO

PV_NAME=$(kubectl get pvc pvc-ephemeral-data -o jsonpath='{.spec.volumeName}')
echo "PV: $PV_NAME"

kubectl get pv $PV_NAME
# NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
# pvc-abc123   5Gi        RWO            Delete           Bound    default/pvc-ephemeral-data

# ⚠️ RECLAIM POLICY = Delete

# 4. Verificar datos
kubectl exec pod-temp-data -- wc -l /data/temp-data.txt
# 100 /data/temp-data.txt

# 5. Obtener ID del disco Azure (para verificar eliminación)
kubectl describe pv $PV_NAME | grep VolumeHandle
# VolumeHandle: /subscriptions/.../Microsoft.Compute/disks/pvc-abc123-disk

# 6. ELIMINAR el PVC
kubectl delete pvc pvc-ephemeral-data
# persistentvolumeclaim "pvc-ephemeral-data" deleted

# 7. El PV también se eliminó automáticamente
kubectl get pv $PV_NAME
# Error from server (NotFound): persistentvolumes "pvc-abc123" not found

# ✅ PV eliminado por política Delete

# 8. El disco Azure también se eliminó
# (puedes verificar en Azure Portal o con az cli)
# az disk show --ids <VolumeHandle>
# ERROR: Disk not found

# 9. El Pod queda con volumen roto
kubectl get pod pod-temp-data
# NAME            READY   STATUS    RESTARTS   AGE
# pod-temp-data   1/1     Running   0          5m

kubectl exec pod-temp-data -- ls /data/
# (todavía funciona porque el Pod ya tenía el volumen montado)

# 10. Pero si reinicias el Pod, falla
kubectl delete pod pod-temp-data
kubectl apply -f ejemplos/06-reclaim-policies/pvc-delete-policy.yaml
kubectl get pod pod-temp-data
# NAME            READY   STATUS    RESTARTS   AGE
# pod-temp-data   0/1     Pending   0          10s

kubectl describe pod pod-temp-data | grep -A 3 Events
# Events:
#   Warning  FailedScheduling  persistentvolumeclaim "pvc-ephemeral-data" not found

# ❌ PVC ya no existe

# 11. Limpiar
kubectl delete pod pod-temp-data
```

**Cuándo usar Delete**:
- ✅ Desarrollo y testing
- ✅ Datos temporales (caches, builds)
- ✅ Ambientes efímeros
- ⚠️ **NO para producción** (pérdida de datos)

### Ejemplo 2: Política Retain (Protección de Datos)

Conservar disco Azure para recuperación manual.

**Archivo**: [`ejemplos/06-reclaim-policies/storageclass-retain.yaml`](./ejemplos/06-reclaim-policies/storageclass-retain.yaml)

```yaml
# StorageClass con política Retain
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi-retain
  labels:
    retention: permanent
provisioner: disk.csi.azure.com
parameters:
  skuname: Premium_LRS
  kind: Managed
reclaimPolicy: Retain  # ← Conservar disco al eliminar PVC
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
# PVC usando StorageClass con Retain
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-important-data
  labels:
    retention: critical
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi-retain  # ← Usar clase con Retain
  resources:
    requests:
      storage: 50Gi
---
# StatefulSet con datos críticos
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-critical
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres-critical
  template:
    metadata:
      labels:
        app: postgres-critical
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "criticalpass123"
        - name: POSTGRES_DB
          value: "production"
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: pvc-important-data
```

**Probar protección con Retain**:

```bash
# 1. Crear StorageClass con Retain
kubectl apply -f ejemplos/06-reclaim-policies/storageclass-retain.yaml

# 2. Esperar a que StatefulSet esté listo
kubectl wait --for=condition=ready pod/postgres-critical-0 --timeout=120s

# 3. Verificar PVC
kubectl get pvc pvc-important-data
# NAME                  STATUS   VOLUME        CAPACITY   STORAGECLASS
# pvc-important-data    Bound    pvc-xyz789    50Gi       managed-csi-retain

# 4. Verificar PV con política Retain
PV_NAME=$(kubectl get pvc pvc-important-data -o jsonpath='{.spec.volumeName}')
kubectl get pv $PV_NAME -o custom-columns=\
NAME:.metadata.name,\
CAPACITY:.spec.capacity.storage,\
RECLAIM:.spec.persistentVolumeReclaimPolicy,\
STATUS:.status.phase

# NAME         CAPACITY   RECLAIM   STATUS
# pvc-xyz789   50Gi       Retain    Bound

# ✅ Política Retain configurada

# 5. Crear datos importantes
kubectl exec postgres-critical-0 -- psql -U postgres -d production -c "
CREATE TABLE critical_data (
  id SERIAL PRIMARY KEY,
  value TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO critical_data (value) VALUES 
  ('Dato crítico 1'),
  ('Dato crítico 2'),
  ('Dato crítico 3');
"

kubectl exec postgres-critical-0 -- psql -U postgres -d production -c \
  "SELECT * FROM critical_data;"
#  id |      value      |         created_at
# ----+-----------------+----------------------------
#   1 | Dato crítico 1  | 2025-11-10 20:30:00.123456
#   2 | Dato crítico 2  | 2025-11-10 20:30:00.123457
#   3 | Dato crítico 3  | 2025-11-10 20:30:00.123458

# 6. Guardar el nombre del PV para recuperación
echo "PV para recuperación: $PV_NAME" > pv-recovery-info.txt
cat pv-recovery-info.txt

# 7. SIMULAR ELIMINACIÓN ACCIDENTAL del PVC
kubectl delete pvc pvc-important-data
# persistentvolumeclaim "pvc-important-data" deleted

# 8. El PV NO se eliminó (política Retain)
kubectl get pv $PV_NAME
# NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS
# pvc-xyz789   50Gi       RWO            Retain           Released

# ✅ Estado = Released (no eliminado!)

# 9. El disco Azure también se conservó
kubectl describe pv $PV_NAME | grep VolumeHandle
# VolumeHandle: /subscriptions/.../disks/pvc-xyz789-disk
# (el disco sigue existiendo en Azure)

# 10. RECUPERACIÓN: Crear nuevo PVC apuntando al mismo PV
cat > pvc-recovered.yaml <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-recovered
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi-retain
  resources:
    requests:
      storage: 50Gi
  volumeName: $PV_NAME  # ← Vincular al PV existente
EOF

# 11. Antes, cambiar PV a Available (quitar claimRef)
kubectl patch pv $PV_NAME -p '{"spec":{"claimRef": null}}'

kubectl get pv $PV_NAME
# NAME         CAPACITY   RECLAIM POLICY   STATUS
# pvc-xyz789   50Gi       Retain           Available

# 12. Ahora crear PVC recuperado
kubectl apply -f pvc-recovered.yaml

kubectl get pvc pvc-recovered
# NAME            STATUS   VOLUME       CAPACITY   ACCESS MODES
# pvc-recovered   Bound    pvc-xyz789   50Gi       RWO

# ✅ PVC vinculado al PV original!

# 13. Recrear StatefulSet con PVC recuperado
kubectl delete statefulset postgres-critical

cat > postgres-recovered.yaml <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-recovered
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres-recovered
  template:
    metadata:
      labels:
        app: postgres-recovered
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "criticalpass123"
        - name: POSTGRES_DB
          value: "production"
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: pvc-recovered
EOF

kubectl apply -f postgres-recovered.yaml
kubectl wait --for=condition=ready pod/postgres-recovered-0 --timeout=120s

# 14. VERIFICAR que los datos originales están intactos
kubectl exec postgres-recovered-0 -- psql -U postgres -d production -c \
  "SELECT * FROM critical_data;"
#  id |      value      |         created_at
# ----+-----------------+----------------------------
#   1 | Dato crítico 1  | 2025-11-10 20:30:00.123456
#   2 | Dato crítico 2  | 2025-11-10 20:30:00.123457
#   3 | Dato crítico 3  | 2025-11-10 20:30:00.123458

# ✅✅✅ DATOS RECUPERADOS EXITOSAMENTE!

# 15. Limpiar
kubectl delete statefulset postgres-recovered
kubectl delete pvc pvc-recovered
kubectl delete pv $PV_NAME
kubectl delete storageclass managed-csi-retain
rm pvc-recovered.yaml postgres-recovered.yaml pv-recovery-info.txt
```

**Comparación Delete vs Retain**:

| Aspecto | Delete | Retain |
|---------|--------|--------|
| **Al eliminar PVC** | PV y disco eliminados | PV pasa a Released |
| **Disco Azure** | ❌ Eliminado | ✅ Conservado |
| **Recuperación** | ❌ Imposible | ✅ Posible |
| **Costo** | 💰 (solo mientras existe) | 💰💰 (hasta eliminar manualmente) |
| **Riesgo de pérdida** | ⚠️ Alto | ✅ Bajo |
| **Uso recomendado** | Dev/Test | Producción |
| **Cleanup** | Automático | Manual |

### Ejemplo 3: Cambiar Reclaim Policy de un PV Existente

Puedes cambiar la política de un PV activo.

```bash
# 1. Crear PVC con Delete (por defecto)
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-to-protect
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-csi
  resources:
    requests:
      storage: 10Gi
EOF

# 2. Esperar a que se vincule
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/pvc-to-protect --timeout=60s

# 3. Ver política actual
PV_NAME=$(kubectl get pvc pvc-to-protect -o jsonpath='{.spec.volumeName}')
kubectl get pv $PV_NAME -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'
# Delete

# 4. CAMBIAR a Retain para proteger datos
kubectl patch pv $PV_NAME -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

# 5. Verificar cambio
kubectl get pv $PV_NAME -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'
# Retain

# ✅ Ahora el PV está protegido

# 6. Probar: eliminar PVC
kubectl delete pvc pvc-to-protect

# 7. PV sigue existiendo
kubectl get pv $PV_NAME
# NAME         CAPACITY   RECLAIM POLICY   STATUS
# pvc-...      10Gi       Retain           Released

# 8. Limpiar manualmente
kubectl delete pv $PV_NAME
```

**Mejores prácticas**:
- ✅ Producción: siempre usar `Retain`
- ✅ Backups: programar snapshots regulares
- ✅ Documentar: guardar nombres de PV importantes
- ✅ Monitorear: alertas cuando PV pasa a Released
- ⚠️ Costos: eliminar PV Released que ya no necesitas

---

💡 **Has aprendido**:
- ✅ Access Modes: RWO, ROX, RWX en la práctica
- ✅ Diferencias Azure Disk (RWO) vs Azure Files (RWX)
- ✅ Reclaim Policies: Delete vs Retain
- ✅ Recuperación de datos con Retain
- ✅ Cambiar políticas de PV existentes

📁 **Próxima sección**: Continuará con Troubleshooting y Labs (ETAPA 4D).

---

## Troubleshooting Práctico

### Errores Comunes y Soluciones

Esta sección cubre los problemas más frecuentes con volúmenes en AKS y cómo resolverlos.

### Error 1: Pod en ContainerCreating - Volume Attach Timeout

**Síntoma**:
```bash
kubectl get pods
# NAME                 READY   STATUS              RESTARTS   AGE
# myapp-abc-123       0/1     ContainerCreating   0          5m
```

**Diagnosis**:
```bash
kubectl describe pod myapp-abc-123 | tail -20
# Events:
#   Type     Reason              Age   From                     Message
#   ----     ------              ----  ----                     -------
#   Warning  FailedAttachVolume  3m    attachdetach-controller  AttachVolume.Attach failed for volume "pvc-xyz" : rpc error: code = Internal desc = Could not attach disk
#   Warning  FailedMount         1m    kubelet                  Unable to attach or mount volumes: timeout expired waiting for volumes to attach or mount
```

**Causas comunes**:

1. **Disco ya montado en otro nodo** (RWO):
```bash
# Verificar si el disco está en uso
PVC_NAME="my-pvc"
PV_NAME=$(kubectl get pvc $PVC_NAME -o jsonpath='{.spec.volumeName}')

# Ver en qué nodo está montado
kubectl get volumeattachment | grep $PV_NAME
# csi-xyz123   pvc-abc456   node-1   true   5m

# Ver Pods usando el PVC
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName=="'$PVC_NAME'") | .metadata.name'
```

**Solución**:
```bash
# Si hay un Pod "zombie" usando el disco
OLD_POD="myapp-old-xyz-456"
kubectl delete pod $OLD_POD --force --grace-period=0

# Esperar a que el disco se desmonte (hasta 2 minutos)
kubectl wait --for=delete pod/$OLD_POD --timeout=120s

# El nuevo Pod ahora debería poder montar
kubectl get pod myapp-abc-123
# NAME              READY   STATUS    RESTARTS   AGE
# myapp-abc-123    1/1     Running   0          7m
```

2. **Cuota de discos excedida en Azure**:
```bash
# Verificar cuota de discos en la suscripción
az vm list-usage --location eastus -o table | grep -i disk

# Ver PVs actuales
kubectl get pv | wc -l

# Si alcanzaste el límite, elimina PVs no usados
kubectl get pv | grep Released
kubectl delete pv <pv-name>
```

3. **Zona de disponibilidad incorrecta**:
```bash
# Ver en qué zona está el disco
kubectl describe pv $PV_NAME | grep topology.kubernetes.io/zone
# topology.kubernetes.io/zone=eastus-1

# Ver en qué zona está el nodo
kubectl get node <node-name> -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
# eastus-2

# ❌ Zona diferente! El disco no puede montarse

# Solución: Usar WaitForFirstConsumer
kubectl get storageclass managed-csi -o yaml | grep volumeBindingMode
# volumeBindingMode: WaitForFirstConsumer
# ✅ Esto crea el disco en la misma zona que el Pod
```

---

### Error 2: PVC en Pending - No StorageClass

**Síntoma**:
```bash
kubectl get pvc
# NAME       STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# my-pvc     Pending                                                     10m
```

**Diagnosis**:
```bash
kubectl describe pvc my-pvc
# Events:
#   Type     Reason              Age   Message
#   ----     ------              ----  -------
#   Warning  ProvisioningFailed  2m    storageclass.storage.k8s.io "standard" not found
```

**Solución**:
```bash
# 1. Listar StorageClasses disponibles
kubectl get storageclass
# NAME                PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE
# managed-csi         disk.csi.azure.com   Delete          WaitForFirstConsumer
# azurefile-csi       file.csi.azure.com   Delete          Immediate

# 2. Actualizar PVC con StorageClass correcto
kubectl patch pvc my-pvc -p '{"spec":{"storageClassName":"managed-csi"}}'

# 3. Si el PVC ya tiene un StorageClass incorrecto, recrearlo
kubectl get pvc my-pvc -o yaml > my-pvc-backup.yaml
kubectl delete pvc my-pvc

# Editar y aplicar
sed -i 's/storageClassName: standard/storageClassName: managed-csi/' my-pvc-backup.yaml
kubectl apply -f my-pvc-backup.yaml
```

---

### Error 3: Multi-Attach Error (ReadWriteOnce)

**Síntoma**:
```bash
kubectl get pods
# NAME                 READY   STATUS              RESTARTS   AGE
# app-abc-123         1/1     Running             0          5m
# app-abc-456         0/1     ContainerCreating   0          2m

kubectl describe pod app-abc-456 | grep -A 3 "Multi-Attach"
# Warning  FailedAttachVolume  Multi-Attach error for volume "pvc-xyz" Volume is already used by pod(s) app-abc-123
```

**Causa**: Deployment con `replicas > 1` usando PVC con access mode `ReadWriteOnce`.

**Solución 1**: Reducir a 1 réplica
```bash
kubectl scale deployment app --replicas=1
```

**Solución 2**: Usar StatefulSet con volumeClaimTemplates
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: app
spec:
  serviceName: app
  replicas: 3  # ✅ Cada Pod tiene su propio PVC
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:latest
        volumeMounts:
        - name: data
          mountPath: /data
  
  volumeClaimTemplates:  # ← Cada réplica obtiene su PVC
  - metadata:
      name: data
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: managed-csi
      resources:
        requests:
          storage: 10Gi
```

**Solución 3**: Usar ReadWriteMany (Azure Files)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-pvc
spec:
  accessModes:
    - ReadWriteMany  # ✅ Múltiples Pods OK
  storageClassName: azurefile-csi  # ← Requiere Azure Files
  resources:
    requests:
      storage: 10Gi
```

---

### Error 4: Pod Evicted - Disk Pressure

**Síntoma**:
```bash
kubectl get pods
# NAME             READY   STATUS    RESTARTS   AGE
# myapp-abc-123   0/1     Evicted   0          10m

kubectl describe pod myapp-abc-123
# Status:  Failed
# Reason:  Evicted
# Message: The node was low on resource: ephemeral-storage. Container myapp was using 15Gi, which exceeds its request of 0.
```

**Diagnosis**:
```bash
# Ver uso de disco en nodos
kubectl describe nodes | grep -A 5 "Allocated resources"

# Ver uso de emptyDir en el Pod
kubectl exec <pod-running> -- df -h
# Filesystem      Size  Used Avail Use% Mounted on
# overlay          30G   20G   10G  67% /
# tmpfs            16G  1.5G   15G  10% /cache  ← emptyDir consumiendo mucho
```

**Solución**:
```bash
# 1. Establecer límite en emptyDir
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: cache
      mountPath: /cache
  
  volumes:
  - name: cache
    emptyDir:
      sizeLimit: 2Gi  # ← Límite de 2GB
EOF

# 2. Limpiar archivos temporales regularmente
# Agregar sidecar que limpia cache antiguo
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: myapp-with-cleaner
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: cache
      mountPath: /cache
  
  - name: cache-cleaner
    image: busybox
    command:
    - sh
    - -c
    - |
      while true; do
        echo "Limpiando archivos antiguos..."
        find /cache -type f -mtime +1 -delete
        echo "Espacio libre: \$(df -h /cache | tail -1 | awk '{print \$4}')"
        sleep 3600  # Limpiar cada hora
      done
    volumeMounts:
    - name: cache
      mountPath: /cache
  
  volumes:
  - name: cache
    emptyDir:
      sizeLimit: 5Gi
EOF
```

---

### Error 5: PVC Stuck in Terminating

**Síntoma**:
```bash
kubectl delete pvc my-pvc
# persistentvolumeclaim "my-pvc" deleted

# Pero después de varios minutos...
kubectl get pvc
# NAME     STATUS        VOLUME   CAPACITY   ACCESS MODES
# my-pvc   Terminating   pvc-xyz  10Gi       RWO
```

**Diagnosis**:
```bash
# Ver si hay Pods aún usando el PVC
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName=="my-pvc") | "\(.metadata.namespace)/\(.metadata.name)"'
# default/myapp-abc-123

# Ver finalizers del PVC
kubectl get pvc my-pvc -o jsonpath='{.metadata.finalizers}'
# ["kubernetes.io/pvc-protection"]
```

**Solución**:
```bash
# 1. Eliminar Pods que usan el PVC
kubectl delete pod myapp-abc-123

# 2. Si aún está Terminating, verificar finalizers
kubectl get pvc my-pvc -o yaml | grep -A 5 finalizers

# 3. Remover finalizer manualmente (último recurso)
kubectl patch pvc my-pvc -p '{"metadata":{"finalizers":null}}' --type=merge

# 4. Ahora debería eliminarse
kubectl get pvc
# No resources found
```

---

### Error 6: Access Denied - Permission Issues

**Síntoma**:
```bash
kubectl logs myapp-abc-123
# ERROR: Failed to write to /data/file.txt: Permission denied
```

**Diagnosis**:
```bash
# Verificar permisos del volumen
kubectl exec myapp-abc-123 -- ls -ld /data
# drwxr-xr-x 2 root root 4096 Nov 10 21:00 /data

# Verificar con qué usuario corre el Pod
kubectl exec myapp-abc-123 -- id
# uid=1000(appuser) gid=1000(appuser) groups=1000(appuser)
# ❌ El usuario 1000 no puede escribir (owner es root)
```

**Solución 1**: Usar securityContext para cambiar ownership
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  securityContext:
    fsGroup: 1000  # ← Establece grupo del volumen
    runAsUser: 1000
  
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: data
      mountPath: /data
  
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-pvc
```

**Verificar**:
```bash
kubectl exec myapp -- ls -ld /data
# drwxrwsr-x 2 root 1000 4096 Nov 10 21:05 /data
# ✅ Ahora el grupo 1000 puede escribir

kubectl exec myapp -- touch /data/test.txt
# (sin errores)

kubectl exec myapp -- ls -l /data/test.txt
# -rw-r--r-- 1 1000 1000 0 Nov 10 21:05 /data/test.txt
```

**Solución 2**: Usar initContainer para cambiar permisos
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  initContainers:
  - name: fix-permissions
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "Cambiando permisos de /data..."
      chown -R 1000:1000 /data
      chmod -R 775 /data
      echo "Permisos actualizados"
    volumeMounts:
    - name: data
      mountPath: /data
  
  containers:
  - name: app
    image: myapp:latest
    securityContext:
      runAsUser: 1000
    volumeMounts:
    - name: data
      mountPath: /data
  
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-pvc
```

---

### Debugging Avanzado

#### Comandos útiles para troubleshooting

```bash
# 1. Ver todos los volúmenes y su estado
kubectl get pv,pvc --all-namespaces -o wide

# 2. Ver eventos recientes del cluster
kubectl get events --sort-by='.lastTimestamp' | grep -i volume

# 3. Ver volumeattachments (discos montados en nodos)
kubectl get volumeattachment

# 4. Describir nodo para ver discos montados
kubectl describe node <node-name> | grep -A 20 "Attached Volumes"

# 5. Ver StorageClasses y sus parámetros
kubectl get storageclass -o yaml

# 6. Ver uso de almacenamiento en Pods
kubectl top pods --containers | grep -v "0/"

# 7. Verificar CSI driver
kubectl get pods -n kube-system | grep csi
# csi-azuredisk-controller-xyz   5/5     Running
# csi-azuredisk-node-abc         3/3     Running
# csi-azurefile-controller-def   4/4     Running
# csi-azurefile-node-ghi         3/3     Running

# 8. Logs del CSI driver (si hay problemas de provisioning)
kubectl logs -n kube-system <csi-azuredisk-controller-xyz> -c csi-provisioner

# 9. Ver detalles del disco en Azure
PV_NAME="pvc-abc123"
VOLUME_HANDLE=$(kubectl get pv $PV_NAME -o jsonpath='{.spec.csi.volumeHandle}')
az disk show --ids $VOLUME_HANDLE --query '{name:name, diskState:diskState, diskSizeGb:diskSizeGb, location:location}'
```

---

## Laboratorios

Este módulo incluye dos laboratorios completos para practicar todo lo aprendido:

### 📚 Lab 01: Volúmenes Básicos

**Ubicación**: [`laboratorios/lab-01-volumenes-basicos/`](./laboratorios/lab-01-volumenes-basicos/)

**Duración estimada**: 60-90 minutos

**Objetivos**:
1. Trabajar con volúmenes emptyDir
2. Explorar volúmenes hostPath
3. Crear y usar PersistentVolumeClaims
4. Comparar diferentes tipos de volúmenes

**Ejercicios**:
- ✏️ Ejercicio 1: Pod con emptyDir compartido entre contenedores
- ✏️ Ejercicio 2: DaemonSet con hostPath para logs del nodo
- ✏️ Ejercicio 3: PVC con Azure Disk y aplicación web
- ✏️ Ejercicio 4: Comparación de rendimiento entre tipos de volúmenes

**Qué aprenderás**:
- Cuándo usar cada tipo de volumen
- Cómo compartir datos entre contenedores
- Provisioning dinámico vs manual
- Persistencia de datos en Kubernetes

👉 [Iniciar Lab 01](./laboratorios/lab-01-volumenes-basicos/README.md)

---

### 📚 Lab 02: PV/PVC Avanzado

**Ubicación**: [`laboratorios/lab-02-pv-pvc-avanzado/`](./laboratorios/lab-02-pv-pvc-avanzado/)

**Duración estimada**: 90-120 minutos

**Objetivos**:
1. Dominar Access Modes (RWO, ROX, RWX)
2. Trabajar con Reclaim Policies
3. Crear StorageClasses personalizadas
4. Troubleshooting de problemas comunes

**Ejercicios**:
- ✏️ Ejercicio 1: StatefulSet con volumeClaimTemplates
- ✏️ Ejercicio 2: Aplicación multi-Pod con ReadWriteMany
- ✏️ Ejercicio 3: Recuperación de datos con Reclaim Policy Retain
- ✏️ Ejercicio 4: Diagnóstico y resolución de errores de volúmenes

**Qué aprenderás**:
- Escalamiento de aplicaciones con estado
- Compartición de archivos entre Pods
- Recuperación de datos ante fallos
- Técnicas avanzadas de troubleshooting

👉 [Iniciar Lab 02](./laboratorios/lab-02-pv-pvc-avanzado/README.md)

---

## Mejores Prácticas

### 🎯 Desarrollo y Testing

```yaml
# ✅ Usar emptyDir para caches temporales
volumes:
- name: cache
  emptyDir:
    sizeLimit: 1Gi  # Siempre establecer límite

# ✅ Delete policy para dev/test
spec:
  storageClassName: managed-csi  # Delete por defecto

# ✅ Tamaños pequeños para ahorrar costos
resources:
  requests:
    storage: 5Gi  # Solo lo necesario
```

### 🏭 Producción

```yaml
# ✅ Retain policy para datos críticos
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: production-storage
provisioner: disk.csi.azure.com
parameters:
  skuname: Premium_LRS
reclaimPolicy: Retain  # Proteger datos
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true

# ✅ Usar Premium SSD para bases de datos
spec:
  storageClassName: managed-csi-premium
  resources:
    requests:
      storage: 256Gi

# ✅ Labels para organización
metadata:
  labels:
    app: postgres
    tier: database
    environment: production
    backup: daily
```

### 🔒 Seguridad

```yaml
# ✅ Nunca usar hostPath en producción (solo DaemonSets justificados)

# ✅ Usar securityContext
spec:
  securityContext:
    fsGroup: 1000
    runAsUser: 1000
    runAsNonRoot: true

# ✅ readOnly cuando sea posible
volumeMounts:
- name: config
  mountPath: /etc/config
  readOnly: true  # Protección extra
```

### 💰 Optimización de Costos

```bash
# ✅ Eliminar PVs Released regularmente
kubectl get pv | grep Released | awk '{print $1}' | xargs kubectl delete pv

# ✅ Usar Standard SSD cuando Premium no sea necesario
# Premium: ~$24/mes por 256GB
# Standard: ~$15/mes por 256GB

# ✅ Limpiar recursos no usados
kubectl get pvc --all-namespaces | grep -v Bound

# ✅ Usar emptyDir en lugar de PVC para datos temporales
```

### 📊 Monitoreo

```yaml
# ✅ Establecer límites de recursos
spec:
  containers:
  - name: app
    resources:
      limits:
        ephemeral-storage: 5Gi  # Limitar emptyDir
      requests:
        ephemeral-storage: 1Gi

# ✅ Alertas recomendadas:
# - PVC cerca del 80% de capacidad
# - PVs en estado Released
# - Pods en ContainerCreating >5min
# - Disk pressure en nodos
```

### 📋 Backup y Recuperación

```bash
# ✅ Hacer snapshots regulares de PVs críticos
az snapshot create \
  --resource-group MC_myResourceGroup_myAKSCluster_eastus \
  --source <disk-id> \
  --name backup-$(date +%Y%m%d)

# ✅ Documentar nombres de PV importantes
kubectl get pvc production-db -o jsonpath='{.spec.volumeName}' > pv-critical.txt

# ✅ Usar Velero para backups de cluster completo
# https://velero.io/
```

### 🔄 StatefulSets

```yaml
# ✅ Siempre usar volumeClaimTemplates con StatefulSets
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 3
  
  volumeClaimTemplates:  # ← Cada Pod tiene su PVC
  - metadata:
      name: data
      labels:
        app: postgres
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: managed-csi-premium
      resources:
        requests:
          storage: 100Gi

# ❌ NO compartir un solo PVC entre réplicas de StatefulSet
```

---

## Resumen del Módulo

### 🎓 Conceptos Dominados

Has completado el módulo de **Volúmenes: Tipos y Storage** en Azure Kubernetes Service. Ahora dominas:

#### Volúmenes Básicos
- ✅ **emptyDir**: Almacenamiento temporal compartido entre contenedores
- ✅ **hostPath**: Acceso a archivos del nodo (DaemonSets)
- ✅ Casos de uso y limitaciones de cada tipo

#### Almacenamiento Persistente
- ✅ **PersistentVolume (PV)**: Recurso de almacenamiento en el cluster
- ✅ **PersistentVolumeClaim (PVC)**: Solicitud de almacenamiento
- ✅ Provisioning dinámico vs manual
- ✅ Azure Disk (RWO) vs Azure Files (RWX)

#### Access Modes
- ✅ **ReadWriteOnce (RWO)**: Un nodo, lectura-escritura
- ✅ **ReadOnlyMany (ROX)**: Múltiples nodos, solo lectura
- ✅ **ReadWriteMany (RWX)**: Múltiples nodos, lectura-escritura
- ✅ Compatibilidad con tipos de storage en Azure

#### Reclaim Policies
- ✅ **Delete**: Eliminación automática (dev/test)
- ✅ **Retain**: Protección de datos (producción)
- ✅ Recuperación de datos después de eliminar PVC

#### StorageClasses
- ✅ `managed-csi`: Azure Disk Standard SSD
- ✅ `managed-csi-premium`: Azure Disk Premium SSD
- ✅ `azurefile-csi`: Azure Files (SMB)
- ✅ Creación de StorageClasses personalizadas

#### Troubleshooting
- ✅ Diagnóstico de errores comunes
- ✅ Multi-Attach errors
- ✅ Permission denied
- ✅ PVC stuck in Terminating
- ✅ Disk pressure y eviction

### 📈 Progreso del Curso

```
Área 2: Arquitectura de Kubernetes
├── ✅ Módulo 15: Volúmenes - Conceptos
└── ✅ Módulo 16: Volúmenes - Tipos y Storage ← Estás aquí
```

### 🎯 Próximos Pasos

1. **Completar los laboratorios**:
   - [Lab 01: Volúmenes Básicos](./laboratorios/lab-01-volumenes-basicos/)
   - [Lab 02: PV/PVC Avanzado](./laboratorios/lab-02-pv-pvc-avanzado/)

2. **Practicar en tu cluster**:
   - Crear PVCs con diferentes StorageClasses
   - Probar access modes (RWO, RWX)
   - Simular fallos y recuperación

3. **Explorar temas avanzados**:
   - Volume snapshots
   - Velero para backups
   - CSI drivers personalizados
   - Azure NetApp Files para alto rendimiento

### 📚 Referencias Adicionales

**Documentación oficial**:
- [Kubernetes Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Azure Disk CSI Driver](https://github.com/kubernetes-sigs/azuredisk-csi-driver)
- [Azure File CSI Driver](https://github.com/kubernetes-sigs/azurefile-csi-driver)

**Mejores prácticas**:
- [AKS Storage Best Practices](https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-storage)
- [Kubernetes Storage Performance](https://kubernetes.io/blog/2018/07/12/resizing-persistent-volumes-using-kubernetes/)

**Herramientas útiles**:
- [Velero](https://velero.io/) - Backup y migración de clusters
- [K9s](https://k9scli.io/) - TUI para gestión de Kubernetes
- [kubectl-view-allocations](https://github.com/davidB/kubectl-view-allocations) - Ver uso de recursos

---

## 🎉 ¡Felicitaciones!

Has completado el **Módulo 16: Volúmenes - Tipos y Storage** del curso de Kubernetes en Azure.

Ahora tienes las habilidades para:
- ✅ Diseñar estrategias de almacenamiento para aplicaciones
- ✅ Implementar persistencia de datos en producción
- ✅ Troubleshoot problemas de volúmenes
- ✅ Optimizar costos de almacenamiento en Azure
- ✅ Recuperar datos ante fallos

**Sigue practicando** y no olvides completar los laboratorios para consolidar el conocimiento.

---

**¿Preguntas o problemas?** Revisa la sección de [Troubleshooting](#troubleshooting-práctico) o consulta los laboratorios para ejemplos adicionales.

**Siguiente módulo**: Continúa tu aprendizaje con módulos sobre ConfigMaps, Secrets, y gestión de configuración.

---

📖 **Ver teoría**: [Volver a Módulo 15 - Conceptos](../modulo-15-volumes-conceptos/README.md)

🏠 **Inicio del curso**: [README principal](../../README.md)
