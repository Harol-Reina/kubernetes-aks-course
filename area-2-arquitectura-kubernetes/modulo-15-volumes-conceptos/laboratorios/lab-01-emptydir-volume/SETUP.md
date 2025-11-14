# ⚙️ Setup - Lab 01: EmptyDir Volume

## 📋 Prerequisitos

### Cluster Kubernetes

- ✅ Minikube, Kind, o cluster remoto funcionando
- ✅ kubectl configurado y conectado
- ✅ Permisos para crear Pods

### Verificación Rápida

```bash
# Verificar conexión al cluster
kubectl cluster-info

# Verificar nodos disponibles
kubectl get nodes

# Verificar namespace por defecto
kubectl config view --minify | grep namespace
```

---

## 🛠️ Herramientas Necesarias

| Herramienta | Versión Mínima | Verificación |
|-------------|----------------|--------------|
| kubectl | 1.24+ | `kubectl version --client` |
| Cluster K8s | 1.24+ | `kubectl version --short` |

---

## 📦 Recursos del Cluster

**Espacio requerido**: Mínimo (pods pequeños con busybox)

**Namespace recomendado**: `default` o crear uno nuevo

```bash
# Opcional: crear namespace dedicado
kubectl create namespace volumes-lab
kubectl config set-context --current --namespace=volumes-lab
```

---

## ✅ Validación Pre-Lab

Ejecuta estos comandos antes de comenzar:

```bash
# 1. Cluster accesible
kubectl get nodes
# Esperado: Al menos 1 nodo Ready

# 2. Permisos para crear Pods
kubectl auth can-i create pods
# Esperado: yes

# 3. Crear un Pod de prueba rápido
kubectl run test-pod --image=busybox --restart=Never --command -- sleep 10
kubectl wait --for=condition=Ready pod/test-pod --timeout=30s
kubectl delete pod test-pod
# Esperado: Pod se crea y elimina sin errores
```

---

## 🚀 ¡Listo para Comenzar!

Si todas las validaciones pasaron, puedes proceder con el [README.md](./README.md) del laboratorio.

---

## 🆘 Troubleshooting Setup

### Error: "connection refused"

**Solución**:
```bash
# Si usas Minikube
minikube status
minikube start

# Verificar contexto
kubectl config current-context
```

### Error: "forbidden: User cannot create pods"

**Solución**: Necesitas permisos de cluster. Contacta a tu administrador o usa un cluster local donde tengas permisos admin.

---

**📌 Nota**: Este lab no requiere configuración especial de almacenamiento persistente, solo un cluster básico funcionando.
