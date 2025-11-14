# Ejemplo 05: RBAC Debugging - Troubleshooting de Permisos

> **Objetivo**: Practicar diagnóstico y resolución de problemas RBAC  
> **Dificultad**: ⭐⭐⭐⭐ (Avanzado)  
> **Tiempo estimado**: 35-45 minutos

## 📋 Descripción

8 escenarios con errores RBAC + 3 ejemplos correctos para comparación. Aprende a diagnosticar "forbidden" errors y configurar permisos correctamente.

## 🎯 Escenarios

### ❌ Con Errores (8)
1. **SA Sin Permisos** - ServiceAccount sin Role/RoleBinding
2. **Wrong Verbs** - Solo `get`, necesita `list`
3. **Namespace Mismatch** - RoleBinding en namespace incorrecto
4. **ClusterRole con RoleBinding** - Scope confusion
5. **Missing API Group** - Deployments necesita `apps` group
6. **Secrets Access Denied** - No permissions para Secrets
7. **Node Access con Role** - Nodes requieren ClusterRole
8. **Wrong Resource Names** - Typo en resourceNames

### ✅ Correctos (3)
1. **Full Pod Access** - Role completo para pods
2. **Cluster-wide Read-Only** - ClusterRole para lectura
3. **Deployment Manager** - Permisos completos para deployments

## 📁 Archivos

```
05-rbac-debugging/
├── README.md                    # Este archivo
├── rbac-debugging.yaml          # 11 escenarios RBAC
├── test-permissions.sh          # Script para testear permisos
└── cleanup.sh                   # Limpieza
```

## 🚀 Uso

### Aplicar Escenarios

```bash
kubectl apply -f rbac-debugging.yaml
```

### Diagnosticar RBAC

```bash
# Test permisos de un ServiceAccount
kubectl auth can-i list pods --as=system:serviceaccount:default:sa-no-permissions
# Output: no

# Ver permisos que tiene
kubectl auth can-i --list --as=system:serviceaccount:default:sa-no-permissions

# Describir Role
kubectl describe role <role-name>

# Describir RoleBinding
kubectl describe rolebinding <rolebinding-name>

# Ver todos los bindings de un SA
kubectl get rolebindings,clusterrolebindings --all-namespaces -o json | \
  jq '.items[] | select(.subjects[]?.name=="sa-name")'
```

### Test Automatizado

```bash
chmod +x test-permissions.sh
./test-permissions.sh
```

## 🔍 Comandos Esenciales

```bash
# Verificar permisos
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<sa-name>
kubectl auth can-i create pods --as=system:serviceaccount:default:my-sa

# Listar permisos
kubectl auth can-i --list --as=system:serviceaccount:default:my-sa

# Ver Roles y bindings
kubectl get roles,rolebindings
kubectl get clusterroles,clusterrolebindings

# Describir para ver reglas
kubectl describe role <name>
kubectl describe clusterrole <name>

# Ver qué SAs existen
kubectl get serviceaccounts

# Crear SA, Role, RoleBinding
kubectl create sa my-sa
kubectl create role my-role --verb=get,list --resource=pods
kubectl create rolebinding my-binding --role=my-role --serviceaccount=default:my-sa
```

## 🐛 Errores Comunes

| Error | Causa | Fix |
|-------|-------|-----|
| `forbidden: User "system:serviceaccount:default:sa" cannot list pods` | No RoleBinding | Crear RoleBinding |
| `cannot list resource "deployments" in API group "" ` | Missing apiGroup | Agregar `apiGroups: ["apps"]` |
| `forbidden: User cannot get resource "nodes"` | Needs ClusterRole | Usar ClusterRole + ClusterRoleBinding |
| `Error from server (Forbidden): secrets is forbidden` | No permission | Agregar Secrets al Role |

## 💡 Best Practices

1. **Principio de mínimo privilegio**: Solo dar permisos necesarios
2. **Usar RoleBinding** (namespace-scoped) cuando sea posible
3. **ClusterRoleBinding** solo para recursos cluster-scoped (nodes, pvs)
4. **Especificar apiGroups**: Core resources usan `""`, otros `apps`, `batch`, etc.
5. **Test permisos**: Siempre verificar con `kubectl auth can-i`
6. **Nombrar descriptivamente**: SA, Role, RoleBinding con nombres claros

## 🧹 Limpieza

```bash
./cleanup.sh
```

## 📚 Recursos

- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [kubectl auth can-i](https://kubernetes.io/docs/reference/access-authn-authz/authorization/)

---

**Volver a**: [README de Ejemplos](../README.md)
