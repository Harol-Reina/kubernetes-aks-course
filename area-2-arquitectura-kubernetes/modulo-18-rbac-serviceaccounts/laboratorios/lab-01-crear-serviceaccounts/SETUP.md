# Setup - Lab 01: Crear ServiceAccounts

## 📋 Prerequisitos

### Conocimientos Requeridos
- ✅ Conceptos de RBAC (Módulo 17)
- ✅ Comprensión de Roles y RoleBindings
- ✅ Conocimiento de pods y deployments
- ✅ Familiaridad con la API de Kubernetes

### Herramientas Necesarias
- ✅ `kubectl` instalado y configurado
- ✅ Cluster de Kubernetes funcional
- ✅ Permisos para crear ServiceAccounts, Roles, RoleBindings

### Verificación del Entorno

```bash
# Verificar conexión
kubectl cluster-info

# Verificar permisos
kubectl auth can-i create serviceaccounts
kubectl auth can-i create roles
kubectl auth can-i create rolebindings

# Verificar versión (ServiceAccount features)
kubectl version --short
```

## 🎯 Estado Inicial

- Cluster funcional
- Permisos de administrador o suficientes para RBAC
- Namespace `default` disponible

## 🧹 Limpieza Previa

```bash
# Limpiar ServiceAccounts anteriores
kubectl delete sa --all -n default

# Verificar
kubectl get sa
```

## ✅ Validación

```bash
# Test rápido
kubectl create sa test-sa --dry-run=client -o yaml
echo "✅ Listo para el lab"
```

---

[Iniciar Lab](./README.md)
