# 💾 Lab 01: PersistentVolume y PersistentVolumeClaim - Storage Estático

## 📋 Objetivo

Aprender a usar **PersistentVolume (PV)** y **PersistentVolumeClaim (PVC)** para almacenamiento persistente con aprovisionamiento estático.

**Conceptos clave**:
- Separación entre administrador (PV) y usuario (PVC)
- Lifecycle independiente del Pod
- Access modes y reclaim policies

⏱️ **Duración**: 30-35 min | **Nivel**: 🟡 Intermedio

---

## 📝 Paso a Paso

### 1️⃣ Crear PersistentVolume (Admin)

```yaml
# pv-manual.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-manual
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data-pv
    type: DirectoryOrCreate
```

```bash
kubectl apply -f pv-manual.yaml
kubectl get pv
```

---

### 2️⃣ Crear PersistentVolumeClaim (Usuario)

```yaml
# pvc-manual.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-manual
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

```bash
kubectl apply -f pvc-manual.yaml
kubectl get pvc
# STATUS: Bound
```

---

### 3️⃣ Usar PVC en Pod

```yaml
# pod-with-pvc.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-pvc
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo 'Persistent data' > /data/file.txt; sleep 3600"]
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: pvc-manual
```

```bash
kubectl apply -f pod-with-pvc.yaml
kubectl exec pod-with-pvc -- cat /data/file.txt
```

---

### 4️⃣ Verificar Persistencia

```bash
# Eliminar Pod
kubectl delete pod pod-with-pvc

# Crear nuevo Pod
kubectl apply -f pod-with-pvc.yaml

# Verificar datos persisten
kubectl exec pod-with-pvc -- cat /data/file.txt
# Output: Persistent data
```

✅ **Datos persisten entre Pods**

---

## 📊 Access Modes

| Mode | Abreviación | Descripción |
|------|-------------|-------------|
| ReadWriteOnce | RWO | 1 nodo, lectura/escritura |
| ReadOnlyMany | ROX | N nodos, solo lectura |
| ReadWriteMany | RWX | N nodos, lectura/escritura |

---

## 🔍 Troubleshooting

**PVC en Pending**:
```bash
kubectl describe pvc pvc-manual
# Buscar: no persistent volumes available
```

**Solución**: Crear PV con capacidad suficiente y access mode compatible.

---

## ✅ Checklist
- [ ] Creé PV con hostPath
- [ ] Creé PVC que se vinculó al PV
- [ ] Usé PVC en un Pod
- [ ] Verifiqué persistencia de datos

🔗 [SETUP.md](./SETUP.md) | [cleanup.sh](./cleanup.sh)
