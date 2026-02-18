# 📚 RESUMEN - Módulo 16: Volúmenes - Implementación Práctica en Azure AKS

**Guía de Implementación Hands-On | YAMLs + kubectl + Troubleshooting**

---

## 🎯 Visión General del Módulo

Este módulo es **100% práctica**. Aprenderás a **implementar volúmenes** en Azure AKS con YAMLs completos, comandos kubectl detallados y troubleshooting real. Todo lo que estudiaste conceptualmente en el Módulo 15, ahora lo pondrás en acción.

**Duración**: 7 horas (implementación + troubleshooting + 2 labs)  
**Nivel**: Implementación Práctica  
**Prerequisito**: Módulo 15 completado (**CRÍTICO**)

---

## 📋 Objetivos de Aprendizaje

### Implementación Práctica
- ✅ Crear volúmenes emptyDir y hostPath con YAMLs
- ✅ Provisionar PVC con Azure Disk dinámicamente
- ✅ Crear PV y PVC manualmente
- ✅ Configurar access modes (RWO, RWX)
- ✅ Aplicar reclaim policies (Retain, Delete)

### Técnico
- ✅ Comandos kubectl para volúmenes
- ✅ Verificar binding de PV/PVC
- ✅ Montar volúmenes en Pods
- ✅ Crear StorageClasses personalizadas
- ✅ Expandir volúmenes dinámicamente

### Troubleshooting
- ✅ Diagnosticar PVC Pending
- ✅ Resolver problemas de montaje
- ✅ Solucionar errores de permisos
- ✅ Depurar provisioning fallido

---

## 🔗 Relación con Módulo 15 - SEPARACIÓN CLARA

```
┌────────────────────────────────────────┐
│  MÓDULO 15: Conceptos (YA completado)  │
│                                        │
│  📖 Qué son volúmenes                  │
│  📊 Tipos (emptyDir, PV/PVC)           │
│  🎨 Access Modes (teoría)              │
│  📚 Reclaim Policies (concepto)        │
│                                        │
│  ❌ SIN YAMLs de producción            │
│  ❌ SIN kubectl detallado              │
└────────────────────────────────────────┘
              ↓
       ¡AHORA LA PRÁCTICA!
              ↓
┌────────────────────────────────────────┐
│  MÓDULO 16: Implementación Práctica    │
│  (Este resumen)                        │
│                                        │
│  ✅ YAMLs completos listos             │
│  ✅ kubectl paso a paso                │
│  ✅ Provisioning en AKS                │
│  ✅ Troubleshooting real               │
│  ✅ 2 Labs hands-on                    │
└────────────────────────────────────────┘
```

---

## 🗺️ Guía de Implementación Práctica

### Práctica 1: emptyDir - Compartir Datos entre Contenedores (30 min)

#### YAML Completo

**Archivo**: `ejemplos/01-emptydir/pod-emptydir.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-emptydir
  labels:
    app: emptydir-demo
spec:
  containers:
  # Contenedor 1: Escribe datos
  - name: writer
    image: busybox
    command: ["/bin/sh"]
    args:
      - -c
      - |
        while true; do
          echo "$(date): Hello from writer" >> /data/log.txt
          sleep 5
        done
    volumeMounts:
    - name: shared-data
      mountPath: /data      # ← Writer escribe aquí
  
  # Contenedor 2: Lee datos
  - name: reader
    image: busybox
    command: ["/bin/sh"]
    args:
      - -c
      - |
        tail -f /logs/log.txt
    volumeMounts:
    - name: shared-data
      mountPath: /logs      # ← Reader lee aquí (mismo volumen, diferente path)
  
  volumes:
  - name: shared-data
    emptyDir: {}            # ← Volumen efímero compartido
```

#### Comandos kubectl

```bash
# 1. Aplicar YAML
kubectl apply -f pod-emptydir.yaml

# 2. Verificar Pod
kubectl get pods pod-emptydir
# NAME           READY   STATUS    RESTARTS   AGE
# pod-emptydir   2/2     Running   0          10s

# 3. Ver logs del reader (lee datos del writer)
kubectl logs pod-emptydir -c reader
# 2025-11-12 18:30:45: Hello from writer
# 2025-11-12 18:30:50: Hello from writer
# ...

# 4. Verificar volumen dentro del Pod
kubectl exec pod-emptydir -c writer -- ls -la /data
# total 4
# drwxrwxrwx    2 root     root          4096 Nov 12 18:30 .
# -rw-r--r--    1 root     root          1234 Nov 12 18:31 log.txt

# 5. Ver contenido del archivo compartido
kubectl exec pod-emptydir -c reader -- cat /logs/log.txt

# 6. ELIMINAR Pod → Volumen se borra
kubectl delete pod pod-emptydir

# 7. Recrear Pod → Volumen vacío (datos perdidos)
kubectl apply -f pod-emptydir.yaml
kubectl exec pod-emptydir -c reader -- ls /logs
# log.txt no existe (nuevo emptyDir)
```

#### Verificación de Concepto

**✅ Volumen compartido**: Writer escribe en `/data`, Reader lee desde `/logs` (mismo volumen)  
**✅ Efímero**: Al eliminar Pod, datos se pierden  
**✅ Uso típico**: Logs temporales, caché, scratch space

---

### Práctica 2: PVC Básico con Azure Disk (45 min)

#### YAML Completo

**Archivo**: `ejemplos/03-pvc-basico/pvc-azure-disk.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-azure-disk
spec:
  accessModes:
    - ReadWriteOnce        # ← RWO: Solo un Pod a la vez
  storageClassName: managed-csi  # ← StorageClass de Azure Disk
  resources:
    requests:
      storage: 10Gi        # ← Tamaño solicitado
```

**Archivo**: `ejemplos/03-pvc-basico/pod-using-pvc.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-database
spec:
  containers:
  - name: postgres
    image: postgres:14
    env:
    - name: POSTGRES_PASSWORD
      value: mysecretpassword
    volumeMounts:
    - name: data-volume
      mountPath: /var/lib/postgresql/data
      subPath: postgres     # ← Evitar conflictos con lost+found
  
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: pvc-azure-disk    # ← Usa el PVC
```

#### Comandos kubectl - Paso a Paso

```bash
# 1. Ver StorageClasses disponibles
kubectl get storageclass
# NAME                    PROVISIONER            RECLAIMPOLICY
# managed-csi (default)   disk.csi.azure.com     Delete
# managed-csi-premium     disk.csi.azure.com     Delete
# azurefile-csi           file.csi.azure.com     Delete

# 2. Crear PVC (provisioning dinámico)
kubectl apply -f pvc-azure-disk.yaml

# 3. Verificar PVC (puede tardar ~30s en Bound)
kubectl get pvc pvc-azure-disk
# NAME              STATUS    VOLUME                                     CAPACITY   ACCESS MODES
# pvc-azure-disk    Bound     pvc-abc123-xyz...                          10Gi       RWO

# ⚠️ Si queda en Pending, ver troubleshooting más abajo

# 4. Ver PV creado automáticamente
kubectl get pv
# NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
# pvc-abc123-xyz...                          10Gi       RWO            Delete           Bound    default/pvc-azure-disk

# 5. Ver detalles del PVC
kubectl describe pvc pvc-azure-disk
# Events:
#   Normal  ProvisioningSucceeded  disk.csi.azure.com successfully provisioned volume pvc-abc123-xyz

# 6. Crear Pod que usa el PVC
kubectl apply -f pod-using-pvc.yaml

# 7. Verificar Pod montó el volumen
kubectl get pods pod-database
# NAME           READY   STATUS    RESTARTS   AGE
# pod-database   1/1     Running   0          30s

# 8. Escribir datos en el volumen
kubectl exec pod-database -- su - postgres -c \
  "psql -c \"CREATE TABLE users (id serial, name varchar(50));\""

kubectl exec pod-database -- su - postgres -c \
  "psql -c \"INSERT INTO users (name) VALUES ('Alice'), ('Bob');\""

# 9. Verificar datos
kubectl exec pod-database -- su - postgres -c \
  "psql -c \"SELECT * FROM users;\""
#  id | name
# ----+-------
#   1 | Alice
#   2 | Bob

# 10. ELIMINAR Pod (simular crash)
kubectl delete pod pod-database

# 11. RECREAR Pod (mismo PVC)
kubectl apply -f pod-using-pvc.yaml

# 12. ✅ Verificar datos persisten
kubectl exec pod-database -- su - postgres -c \
  "psql -c \"SELECT * FROM users;\""
#  id | name
# ----+-------
#   1 | Alice
#   2 | Bob
# ✅ Datos intactos!

# 13. Limpiar
kubectl delete pod pod-database
kubectl delete pvc pvc-azure-disk
# PV se elimina automáticamente (Reclaim Policy: Delete)
```

#### Verificación de Concepto

**✅ Persistencia**: Datos sobreviven al Pod  
**✅ Provisioning dinámico**: PV creado automáticamente por Azure  
**✅ Azure Disk**: Disco en Azure Storage, accesible por el Pod

---

### Práctica 3: PV y PVC Manual (40 min)

#### YAML Completo

**Archivo**: `ejemplos/04-pv-pvc-manual/pv-manual.yaml`

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-manual
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain    # ← Retain en producción
  storageClassName: manual                 # ← Clase personalizada
  azureDisk:
    diskName: my-disk-name                 # ← Disco pre-creado en Azure
    diskURI: /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Compute/disks/my-disk-name
    kind: Managed
```

**Archivo**: `ejemplos/04-pv-pvc-manual/pvc-manual.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-manual
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual      # ← Debe coincidir con PV
  resources:
    requests:
      storage: 20Gi             # ← Debe ser ≤ capacidad del PV
```

#### Comandos kubectl

```bash
# 1. Crear PV manualmente (admin)
kubectl apply -f pv-manual.yaml

# 2. Verificar PV disponible
kubectl get pv pv-manual
# NAME        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM
# pv-manual   20Gi       RWO            Retain           Available

# 3. Crear PVC (desarrollador)
kubectl apply -f pvc-manual.yaml

# 4. Verificar binding automático
kubectl get pvc pvc-manual
# NAME         STATUS   VOLUME      CAPACITY   ACCESS MODES
# pvc-manual   Bound    pv-manual   20Gi       RWO

kubectl get pv pv-manual
# NAME        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
# pv-manual   20Gi       RWO            Retain           Bound    default/pvc-manual

# 5. Usar PVC en Pod (igual que antes)
# ... volumeMounts con claimName: pvc-manual
```

#### Verificación de Concepto

**✅ Admin crea PV** (conoce detalles de Azure)  
**✅ Desarrollador crea PVC** (solo especifica requisitos)  
**✅ Binding automático** (K8s vincula PVC → PV)

---

### Práctica 4: Access Modes - RWO vs RWX (40 min)

#### Escenario 1: ReadWriteOnce (Azure Disk)

**Solo un Pod puede montar el volumen**

```yaml
# pvc-rwo.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwo
spec:
  accessModes:
    - ReadWriteOnce      # ← RWO
  storageClassName: managed-csi
  resources:
    requests:
      storage: 10Gi
```

**Testing**:
```bash
# 1. Crear PVC
kubectl apply -f pvc-rwo.yaml

# 2. Crear Pod 1
kubectl run pod1 --image=nginx --overrides='
{
  "spec": {
    "volumes": [{"name":"vol","persistentVolumeClaim":{"claimName":"pvc-rwo"}}],
    "containers": [{
      "name":"nginx",
      "image":"nginx",
      "volumeMounts":[{"name":"vol","mountPath":"/data"}]
    }]
  }
}'

# 3. Verificar Pod 1 running
kubectl get pods pod1
# pod1   1/1   Running

# 4. Intentar crear Pod 2 en DIFERENTE nodo
kubectl run pod2 --image=nginx --overrides='...(mismo volumen)...'

# 5. Pod 2 puede quedar Pending si está en nodo diferente
kubectl get pods pod2
# pod2   0/1   Pending    # ← No puede montar (RWO)

# 6. Describir Pod 2
kubectl describe pod pod2
# Events:
#   Warning  FailedAttachVolume  Multi-Attach error for volume "pvc-..." 
#   Volume is already exclusively attached to node1 and can't be attached to node2

# 7. Limpiar
kubectl delete pod pod1 pod2
kubectl delete pvc pvc-rwo
```

---

#### Escenario 2: ReadWriteMany (Azure Files)

**Múltiples Pods pueden compartir**

```yaml
# pvc-rwx.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwx
spec:
  accessModes:
    - ReadWriteMany      # ← RWX
  storageClassName: azurefile-csi    # ← Azure Files (soporta RWX)
  resources:
    requests:
      storage: 10Gi
```

**Testing**:
```bash
# 1. Crear PVC con RWX
kubectl apply -f pvc-rwx.yaml

# 2. Crear múltiples Pods
kubectl run pod1 --image=nginx --overrides='
{
  "spec": {
    "volumes": [{"name":"vol","persistentVolumeClaim":{"claimName":"pvc-rwx"}}],
    "containers": [{
      "name":"nginx",
      "image":"nginx",
      "volumeMounts":[{"name":"vol","mountPath":"/data"}]
    }]
  }
}'

kubectl run pod2 --image=nginx --overrides='...(mismo)...'
kubectl run pod3 --image=nginx --overrides='...(mismo)...'

# 3. Todos los Pods en Running
kubectl get pods
# pod1   1/1   Running    ✅
# pod2   1/1   Running    ✅
# pod3   1/1   Running    ✅

# 4. Escribir desde Pod 1
kubectl exec pod1 -- sh -c 'echo "Hello from pod1" > /data/shared.txt'

# 5. Leer desde Pod 2
kubectl exec pod2 -- cat /data/shared.txt
# Hello from pod1    ✅ Compartido!

# 6. Escribir desde Pod 3
kubectl exec pod3 -- sh -c 'echo "Hello from pod3" >> /data/shared.txt'

# 7. Leer desde Pod 1
kubectl exec pod1 -- cat /data/shared.txt
# Hello from pod1
# Hello from pod3    ✅ Todos ven los mismos datos
```

#### Comparación Práctica

| Aspecto | RWO (Azure Disk) | RWX (Azure Files) |
|---------|------------------|-------------------|
| **Múltiples Pods** | ❌ No (mismo nodo sí) | ✅ Sí |
| **Performance** | Alta (SSD) | Media (SMB) |
| **Uso** | Bases de datos | Archivos compartidos |
| **Costo** | Medio | Bajo |

---

### Práctica 5: Reclaim Policies - Retain vs Delete (30 min)

#### Escenario 1: Delete (Default)

**PV se elimina con el PVC**

```bash
# 1. Crear PVC (usa storageClass con Delete)
kubectl apply -f pvc-delete.yaml
# storageClassName: managed-csi  ← Reclaim Policy: Delete

# 2. Verificar PV creado
kubectl get pv
# pvc-abc123...   10Gi   RWO   Delete   Bound   default/pvc-delete

# 3. Escribir datos
kubectl run test-pod --image=busybox --overrides='...'
kubectl exec test-pod -- sh -c 'echo "important data" > /data/file.txt'

# 4. ELIMINAR PVC
kubectl delete pvc pvc-delete

# 5. PV también se elimina automáticamente
kubectl get pv
# No resources found    ← PV eliminado

# ⚠️ Disco de Azure también eliminado
# ❌ Datos perdidos permanentemente
```

---

#### Escenario 2: Retain (Producción)

**PV se mantiene, datos intactos**

```yaml
# pv-retain.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-retain
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain    # ← Retain
  storageClassName: manual
  azureDisk:
    diskName: important-data-disk
    diskURI: /subscriptions/.../disks/important-data-disk
```

```bash
# 1. Crear PV con Retain
kubectl apply -f pv-retain.yaml

# 2. Crear PVC
kubectl apply -f pvc-retain.yaml

# 3. Escribir datos críticos
kubectl exec test-pod -- sh -c 'echo "CRITICAL DATA" > /data/backup.txt'

# 4. ELIMINAR PVC (simular accidente)
kubectl delete pvc pvc-retain

# 5. PV queda en estado Released (no eliminado)
kubectl get pv pv-retain
# NAME        CAPACITY   RECLAIM POLICY   STATUS     CLAIM
# pv-retain   10Gi       Retain           Released   default/pvc-retain

# 6. Disco de Azure INTACTO
# az disk show --name important-data-disk
# ✅ Disco existe

# 7. Recuperar datos: Crear nuevo PVC apuntando al mismo PV
# (requiere limpiar claimRef del PV primero)
kubectl patch pv pv-retain -p '{"spec":{"claimRef": null}}'

kubectl apply -f pvc-retain-new.yaml    # Nuevo PVC
# ✅ Datos recuperados
```

#### Decisión de Diseño

**Cuándo usar**:
- **Delete**: Dev/test, datos no críticos, limpieza automática
- **Retain**: **Producción**, datos críticos, backups manuales

---

### Práctica 6: Troubleshooting Hands-On (40 min)

#### Problema 1: PVC en Pending

**Síntoma**:
```bash
kubectl get pvc
# NAME       STATUS    VOLUME   CAPACITY
# my-pvc     Pending   -        -
```

**Diagnóstico**:
```bash
# 1. Describir PVC
kubectl describe pvc my-pvc

# Eventos típicos:
# ❌ Error: no persistent volumes available
#    Causa: No hay PV que cumpla requisitos

# ❌ Error: StorageClass "my-class" not found
#    Causa: StorageClass no existe

# ❌ Error: failed to provision volume
#    Causa: Problema con provisioner de Azure
```

**Solución 1** (No hay PV):
```bash
# Verificar PVs disponibles
kubectl get pv

# Si no hay ninguno, crear PV o usar StorageClass
kubectl apply -f pv.yaml
```

**Solución 2** (StorageClass no existe):
```bash
# Ver StorageClasses
kubectl get storageclass

# Corregir nombre en PVC
kubectl edit pvc my-pvc
# storageClassName: managed-csi  ← Usar uno existente
```

**Solución 3** (Problema provisioning):
```bash
# Ver logs del provisioner
kubectl logs -n kube-system -l app=csi-azuredisk-controller

# Verificar permisos en Azure
# az role assignment list --assignee <identity>
```

---

#### Problema 2: Pod no Monta Volumen

**Síntoma**:
```bash
kubectl get pods
# NAME     READY   STATUS              RESTARTS   AGE
# my-pod   0/1     ContainerCreating   0          5m
```

**Diagnóstico**:
```bash
kubectl describe pod my-pod

# Eventos típicos:
# ❌ MountVolume.SetUp failed: volume is already attached by pod "other-pod"
#    Causa: RWO, otro Pod ya lo tiene montado

# ❌ MountVolume.SetUp failed: permission denied
#    Causa: Permisos incorrectos en el volumen

# ❌ persistentvolumeclaim "my-pvc" not found
#    Causa: PVC no existe o namespace incorrecto
```

**Solución 1** (RWO conflict):
```bash
# Eliminar el otro Pod
kubectl get pods -o wide | grep my-pvc
kubectl delete pod other-pod

# Esperar que el volumen se desmonte (~60s)
# Nuevo Pod podrá montarlo
```

**Solución 2** (Permisos):
```bash
# Verificar propietario del volumen
kubectl exec my-pod -- ls -la /data
# drwxr-xr-x root root    ← Problema si app no es root

# Solución: securityContext
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  securityContext:
    fsGroup: 1000      # ← Grupo del volumen
  containers:
  - name: app
    image: myapp
    volumeMounts:
    - name: data
      mountPath: /data
EOF
```

---

#### Problema 3: Datos No Persisten

**Síntoma**: Eliminar Pod → Datos desaparecen

**Diagnóstico**:
```bash
# 1. Verificar tipo de volumen
kubectl get pod my-pod -o yaml | grep -A 5 volumes:

# ❌ Si es emptyDir, datos son efímeros
# volumes:
# - name: data
#   emptyDir: {}

# ❌ Si PVC no está bound
kubectl get pvc
# my-pvc   Pending   -   -
```

**Solución**:
```bash
# Cambiar a PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    image: myapp
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-pvc    # ← Usar PVC en vez de emptyDir
EOF
```

---

## 📝 Comandos Esenciales - Cheat Sheet

### PersistentVolumeClaim

```bash
# Crear PVC
kubectl apply -f pvc.yaml

# Ver PVCs
kubectl get pvc
kubectl get pvc -o wide

# Describir PVC (ver eventos)
kubectl describe pvc <pvc-name>

# Ver YAML completo
kubectl get pvc <pvc-name> -o yaml

# Eliminar PVC
kubectl delete pvc <pvc-name>

# Ver qué Pod usa un PVC
kubectl get pods --all-namespaces -o json | \
  jq '.items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName=="<pvc-name>") | .metadata.name'
```

### PersistentVolume

```bash
# Crear PV
kubectl apply -f pv.yaml

# Ver PVs
kubectl get pv
kubectl get pv -o wide

# Describir PV
kubectl describe pv <pv-name>

# Ver binding (qué PVC usa el PV)
kubectl get pv <pv-name> -o jsonpath='{.spec.claimRef.name}'

# Patch PV (cambiar reclaim policy)
kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

# Limpiar claimRef (liberar PV Released)
kubectl patch pv <pv-name> -p '{"spec":{"claimRef": null}}'
```

### StorageClass

```bash
# Ver StorageClasses
kubectl get storageclass
kubectl get sc    # Alias

# Ver default StorageClass
kubectl get sc -o json | jq '.items[] | select(.metadata.annotations."storageclass.kubernetes.io/is-default-class"=="true") | .metadata.name'

# Describir StorageClass
kubectl describe sc managed-csi

# Crear StorageClass personalizada
kubectl apply -f storageclass-custom.yaml
```

### Troubleshooting

```bash
# Ver eventos de PVC
kubectl describe pvc <pvc-name> | grep -A 10 Events

# Ver por qué Pod no puede montar volumen
kubectl describe pod <pod-name> | grep -A 20 Events

# Ver logs del provisioner (Azure Disk)
kubectl logs -n kube-system -l app=csi-azuredisk-controller

# Ver logs del provisioner (Azure Files)
kubectl logs -n kube-system -l app=csi-azurefile-controller

# Verificar volumen montado en Pod
kubectl exec <pod-name> -- df -h
kubectl exec <pod-name> -- ls -la /data

# Ver qué PVs están disponibles
kubectl get pv --field-selector status.phase=Available
```

---

## 🎯 Comparaciones Prácticas

### emptyDir vs PVC

```
emptyDir:
  ✅ Rápido de crear
  ✅ Sin configuración
  ❌ Efímero (muere con Pod)
  Uso: Caché, logs temporales

PVC:
  ✅ Persistente
  ✅ Sobrevive al Pod
  ⚠️ Requiere configuración
  Uso: Bases de datos, datos críticos
```

### Azure Disk vs Azure Files

```
Azure Disk (RWO):
  ✅ Alta performance (SSD)
  ✅ Bases de datos
  ❌ Solo un Pod a la vez
  StorageClass: managed-csi

Azure Files (RWX):
  ✅ Compartido entre Pods
  ✅ Archivos estáticos
  ⚠️ Performance media
  StorageClass: azurefile-csi
```

### Retain vs Delete

```
Retain:
  ✅ Datos seguros
  ✅ Recuperación posible
  ⚠️ Limpieza manual
  Uso: Producción

Delete:
  ✅ Limpieza automática
  ❌ Datos perdidos
  ✅ Conveniente
  Uso: Dev/Test
```

---

## ✅ Checklist de Implementación

### emptyDir
- [ ] Creé Pod con emptyDir
- [ ] Compartí datos entre contenedores
- [ ] Verifiqué que datos se pierden al eliminar Pod

### PVC Básico
- [ ] Creé PVC con provisioning dinámico
- [ ] Monté PVC en un Pod
- [ ] Escribí datos y verifiqué persistencia
- [ ] Eliminé y recreé Pod - datos intactos

### PV/PVC Manual
- [ ] Creé PV manualmente (admin)
- [ ] Creé PVC que se vincula al PV
- [ ] Verifiqué binding automático
- [ ] Usé PVC en un Pod

### Access Modes
- [ ] Probé RWO con Azure Disk
- [ ] Probé RWX con Azure Files
- [ ] Verifiqué que RWO no permite múltiples nodos
- [ ] Verifiqué que RWX permite compartir

### Reclaim Policies
- [ ] Probé Delete (PV se elimina con PVC)
- [ ] Probé Retain (PV persiste)
- [ ] Recuperé datos de PV Released

### Troubleshooting
- [ ] Diagnostiqué PVC Pending
- [ ] Resolví problema de montaje
- [ ] Solucioné errores de permisos
- [ ] Verifiqué provisioning fallido

### Laboratorios
- [ ] Completé Lab 1: Volúmenes Básicos (60 min)
- [ ] Completé Lab 2: PV/PVC Avanzado (90 min)

---

## 🎓 Recursos del Módulo

### Ejemplos Prácticos
- [`ejemplos/01-emptydir/`](ejemplos/01-emptydir/) - emptyDir con múltiples contenedores
- [`ejemplos/02-hostpath/`](ejemplos/02-hostpath/) - hostPath en DaemonSet
- [`ejemplos/03-pvc-basico/`](ejemplos/03-pvc-basico/) - PVC con Azure Disk dinámico
- [`ejemplos/04-pv-pvc-manual/`](ejemplos/04-pv-pvc-manual/) - PV y PVC manual
- [`ejemplos/05-access-modes/`](ejemplos/05-access-modes/) - RWO vs RWX
- [`ejemplos/06-reclaim-policies/`](ejemplos/06-reclaim-policies/) - Retain vs Delete

### Laboratorios
- [`lab-01-volumenes-basicos/`](laboratorios/lab-01-volumenes-basicos/) - 60 min
- [`lab-02-pv-pvc-avanzado/`](laboratorios/lab-02-pv-pvc-avanzado/) - 90 min

---

## 🎉 ¡Felicitaciones!

Has completado el Módulo 16 de Implementación Práctica de Volúmenes. Ahora puedes:

- ✅ Crear volúmenes emptyDir y hostPath
- ✅ Provisionar PVC con Azure Disk/Files
- ✅ Crear PV y PVC manualmente
- ✅ Configurar access modes apropiados
- ✅ Aplicar reclaim policies
- ✅ Troubleshoot problemas reales
- ✅ Implementar soluciones de almacenamiento en producción

**Próximos pasos**:
1. Revisar este resumen antes de labs
2. Completar Lab 1 y Lab 2
3. Aplicar en proyectos reales
4. Continuar con Módulo 17: RBAC

¡Sigue adelante! 🚀
