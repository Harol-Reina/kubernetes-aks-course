# ⚙️ Setup - Lab 01: PV/PVC Static

## 📋 Prerequisitos

- ✅ Cluster Kubernetes (Minikube recomendado)
- ✅ kubectl configurado
- ✅ Permisos para crear PV/PVC

## ✅ Validación

```bash
kubectl cluster-info
kubectl auth can-i create persistentvolumes
kubectl auth can-i create persistentvolumeclaims
```

🚀 [Comenzar Lab](./README.md)
