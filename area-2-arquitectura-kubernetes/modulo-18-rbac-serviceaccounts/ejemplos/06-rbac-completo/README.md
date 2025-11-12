# ejemplos/06-rbac-completo/README.md
# RBAC Completo: Service Account + Role + RoleBinding

Este directorio contiene un ejemplo completo de implementación RBAC para Service Accounts.

## 📁 Archivos

1. **01-serviceaccount.yaml** - Crea el Service Account
2. **02-role.yaml** - Define los permisos (Role)
3. **03-rolebinding.yaml** - Asigna permisos al Service Account (RoleBinding)

## 🎯 Objetivo

Crear un Service Account llamado `pod-reader` que tenga permisos de **solo lectura** para pods en el namespace `desarrollo`.

## 📊 Arquitectura

```
┌─────────────────────────────────────────────────┐
│         Namespace: desarrollo                   │
│                                                 │
│  ┌──────────────┐                              │
│  │ServiceAccount│                              │
│  │ pod-reader   │                              │
│  └──────┬───────┘                              │
│         │                                       │
│         │ asignado mediante                    │
│         │                                       │
│  ┌──────▼───────┐        ┌──────────────┐     │
│  │ RoleBinding  │───────►│    Role      │     │
│  │ pod-reader-  │        │ pod-reader-  │     │
│  │   binding    │        │    role      │     │
│  └──────────────┘        └──────┬───────┘     │
│                                  │             │
│                          Permisos:             │
│                          - get pods            │
│                          - list pods           │
│                          - get pods/log        │
│                                                 │
└─────────────────────────────────────────────────┘
```

## 🚀 Pasos de Implementación

### Paso 1: Crear el namespace (si no existe)

```bash
kubectl create namespace desarrollo
```

### Paso 2: Aplicar todos los manifiestos

```bash
# Opción 1: Aplicar todo el directorio
kubectl apply -f ejemplos/06-rbac-completo/

# Opción 2: Aplicar en orden específico
kubectl apply -f ejemplos/06-rbac-completo/01-serviceaccount.yaml
kubectl apply -f ejemplos/06-rbac-completo/02-role.yaml
kubectl apply -f ejemplos/06-rbac-completo/03-rolebinding.yaml
```

### Paso 3: Verificar la configuración

```bash
# Verificar Service Account
kubectl get sa pod-reader -n desarrollo
kubectl describe sa pod-reader -n desarrollo

# Verificar Role
kubectl get role pod-reader-role -n desarrollo
kubectl describe role pod-reader-role -n desarrollo

# Verificar RoleBinding
kubectl get rolebinding pod-reader-binding -n desarrollo
kubectl describe rolebinding pod-reader-binding -n desarrollo
```

## ✅ Pruebas

### Verificar permisos del Service Account

```bash
# Ver todos los permisos
kubectl auth can-i --list \
  --as=system:serviceaccount:desarrollo:pod-reader \
  -n desarrollo

# Probar permiso específico (debería ser "yes")
kubectl auth can-i get pods \
  --as=system:serviceaccount:desarrollo:pod-reader \
  -n desarrollo

# Probar permiso que NO tiene (debería ser "no")
kubectl auth can-i delete pods \
  --as=system:serviceaccount:desarrollo:pod-reader \
  -n desarrollo
```

### Crear un pod de prueba

```bash
# Crear archivo test-pod.yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-reader-test
  namespace: desarrollo
spec:
  serviceAccountName: pod-reader
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["sleep", "3600"]
EOF
```

### Probar desde dentro del pod

```bash
# Entrar al pod
kubectl exec -it pod-reader-test -n desarrollo -- bash

# Dentro del pod, probar comandos:
# ✅ Esto debería funcionar
kubectl get pods

# ✅ Esto también debería funcionar
kubectl get pods -o wide

# ✅ Ver logs de un pod
kubectl logs pod-reader-test

# ❌ Esto debería fallar (no tiene permiso de delete)
kubectl delete pod pod-reader-test
```

## 📝 Permisos Otorgados

| Recurso | Verbs Permitidos | Descripción |
|---------|------------------|-------------|
| pods | get, list | Leer información de pods |
| pods/log | get | Leer logs de pods |

## ❌ Permisos NO Otorgados

El Service Account `pod-reader` **NO puede**:
- Crear pods (`create`)
- Actualizar pods (`update`)
- Eliminar pods (`delete`)
- Acceder a otros recursos (services, deployments, secrets, etc.)
- Acceder a pods fuera del namespace `desarrollo`

## 🧹 Limpieza

```bash
# Eliminar el pod de prueba
kubectl delete pod pod-reader-test -n desarrollo

# Eliminar todos los recursos RBAC
kubectl delete -f ejemplos/06-rbac-completo/

# O uno por uno
kubectl delete rolebinding pod-reader-binding -n desarrollo
kubectl delete role pod-reader-role -n desarrollo
kubectl delete sa pod-reader -n desarrollo
```

## 🔍 Troubleshooting

### Problema: "Forbidden" al intentar listar pods

**Solución**: Verificar que el RoleBinding existe y está correctamente configurado

```bash
kubectl get rolebinding pod-reader-binding -n desarrollo -o yaml
```

### Problema: Token no montado en el pod

**Solución**: Verificar que `automountServiceAccountToken` no esté en `false`

```bash
kubectl get sa pod-reader -n desarrollo -o yaml | grep automount
```

### Problema: Permisos funcionan en otros namespaces

**Solución**: Role y RoleBinding son namespace-scoped. Para permisos globales, usar ClusterRole y ClusterRoleBinding.

## 📚 Referencias

- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
