# 🗄️ Lab 03: StatefulSet Storage - volumeClaimTemplates

## 📋 Objetivo

Aprender a usar **StatefulSets** con `volumeClaimTemplates` para storage persistente por replica.

⏱️ **Duración**: 30-35 min | **Nivel**: 🔴 Avanzado

---

## 📝 Paso a Paso

### 1️⃣ Crear StatefulSet con volumeClaimTemplates

```yaml
# statefulset-storage.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-stateful
spec:
  serviceName: web
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

```bash
kubectl apply -f statefulset-storage.yaml
kubectl get pods
# web-stateful-0, web-stateful-1, web-stateful-2

kubectl get pvc
# data-web-stateful-0, data-web-stateful-1, data-web-stateful-2
```

**📌 Cada Pod obtiene su propio PVC**

---

### 2️⃣ Escribir Datos Únicos en Cada Pod

```bash
for i in 0 1 2; do
  kubectl exec web-stateful-$i -- sh -c "echo 'Pod $i data' > /usr/share/nginx/html/index.html"
done

# Verificar
for i in 0 1 2; do
  echo "Pod $i:"
  kubectl exec web-stateful-$i -- cat /usr/share/nginx/html/index.html
done
```

---

### 3️⃣ Eliminar y Recrear StatefulSet

```bash
# Eliminar StatefulSet (PVCs persisten)
kubectl delete statefulset web-stateful

# PVCs siguen existiendo
kubectl get pvc

# Recrear StatefulSet
kubectl apply -f statefulset-storage.yaml

# Verificar datos persisten
kubectl exec web-stateful-0 -- cat /usr/share/nginx/html/index.html
# Output: Pod 0 data
```

✅ **Datos persisten por replica**

---

### 4️⃣ Headless Service para StatefulSet

```yaml
# service-headless.yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  clusterIP: None
  selector:
    app: web
  ports:
  - port: 80
```

```bash
kubectl apply -f service-headless.yaml

# DNS estable
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup web-stateful-0.web
```

---

## 📊 StatefulSet vs Deployment

| Aspecto | StatefulSet | Deployment |
|---------|-------------|------------|
| **Identidad** | Estable (web-0, web-1) | Efímera |
| **Storage** | PVC por Pod | PVC compartido |
| **DNS** | Predecible | Aleatorio |
| **Orden** | Creación secuencial | Paralelo |

---

## ✅ Checklist
- [ ] Creé StatefulSet con volumeClaimTemplates
- [ ] Verifiqué 1 PVC por Pod
- [ ] Escribí datos únicos en cada replica
- [ ] Confirmé persistencia tras recrear StatefulSet

🔗 [SETUP.md](./SETUP.md) | [cleanup.sh](./cleanup.sh)
