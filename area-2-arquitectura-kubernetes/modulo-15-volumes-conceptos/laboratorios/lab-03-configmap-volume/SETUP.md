# ⚙️ Setup - Lab 03: ConfigMap Volume

## 📋 Prerequisitos

### Cluster Kubernetes

- ✅ Minikube, Kind, o cluster remoto funcionando
- ✅ kubectl configurado
- ✅ Permisos para crear Pods y ConfigMaps

### Verificación Rápida

```bash
# Verificar conexión
kubectl cluster-info

# Verificar permisos
kubectl auth can-i create configmaps
kubectl auth can-i create pods
# Ambos deben retornar: yes
```

---

## 🛠️ Herramientas Necesarias

| Herramienta | Versión Mínima | Verificación |
|-------------|----------------|--------------|
| kubectl | 1.24+ | `kubectl version --client` |
| Cluster K8s | 1.24+ | `kubectl version --short` |

---

## 📦 Recursos del Cluster

**Requerimientos**: Mínimos (ConfigMaps pequeños + Pods ligeros)

**Namespace**: `default` o crear uno nuevo

```bash
# Opcional: namespace dedicado
kubectl create namespace config-lab
kubectl config set-context --current --namespace=config-lab
```

---

## ✅ Validación Pre-Lab

```bash
# 1. Crear ConfigMap de prueba
kubectl create configmap test-config --from-literal=test=value

# 2. Verificar creación
kubectl get configmap test-config

# 3. Limpiar
kubectl delete configmap test-config

# Esperado: Sin errores
```

---

## 🚀 ¡Listo para Comenzar!

Si todas las validaciones pasaron, procede con el [README.md](./README.md) del laboratorio.

---

## 🆘 Troubleshooting Setup

### Error: "forbidden: User cannot create configmaps"

**Solución**: Necesitas permisos en el namespace. Contacta al admin o usa un cluster local.

### Error: ConfigMaps not supported

**Solución**: Actualiza tu versión de Kubernetes a 1.24+.

---

**📌 Nota**: Este lab no requiere configuración especial de storage, solo permisos básicos de cluster.
