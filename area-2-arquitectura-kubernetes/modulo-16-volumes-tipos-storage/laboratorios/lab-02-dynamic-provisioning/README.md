# ⚡ Lab 02: Dynamic Provisioning - StorageClass

## 📋 Objetivo

Aprender **aprovisionamiento dinámico** con StorageClass para crear PVs automáticamente.

⏱️ **Duración**: 25-30 min | **Nivel**: 🟡 Intermedio

---

## 📝 Paso a Paso

### 1️⃣ Verificar StorageClass Existente

```bash
kubectl get storageclass
# Minikube: standard (default)
```

---

### 2️⃣ Crear PVC Dinámico

```yaml
# pvc-dynamic.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-dynamic
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: standard
```

```bash
kubectl apply -f pvc-dynamic.yaml
kubectl get pvc
# PV creado automáticamente
kubectl get pv
```

---

### 3️⃣ Usar PVC en Deployment

```yaml
# deployment-dynamic-storage.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-dynamic-storage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: storage-app
  template:
    metadata:
      labels:
        app: storage-app
    spec:
      containers:
      - name: app
        image: nginx:alpine
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: pvc-dynamic
```

```bash
kubectl apply -f deployment-dynamic-storage.yaml
kubectl exec -it deploy/app-dynamic-storage -- sh -c "echo 'Dynamic PV' > /usr/share/nginx/html/index.html"
```

---

### 4️⃣ Crear StorageClass Personalizada

```yaml
# storageclass-custom.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: k8s.io/minikube-hostpath
parameters:
  type: pd-ssd
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

```bash
kubectl apply -f storageclass-custom.yaml
kubectl get sc
```

---

## 📊 Reclaim Policies

| Policy | Comportamiento |
|--------|----------------|
| **Retain** | PV se mantiene tras eliminar PVC |
| **Delete** | PV se elimina automáticamente |
| **Recycle** | Deprecated, usar Delete |

---

## ✅ Checklist
- [ ] Verifiqué StorageClass predeterminada
- [ ] Creé PVC dinámico (PV creado automáticamente)
- [ ] Usé PVC en Deployment
- [ ] Creé StorageClass personalizada

🔗 [SETUP.md](./SETUP.md) | [cleanup.sh](./cleanup.sh)
