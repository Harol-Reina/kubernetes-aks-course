# Laboratorios - Módulo 18: RBAC ServiceAccounts

> **Objetivo**: Dominar ServiceAccounts y su integración con RBAC  
> **Tiempo total estimado**: 60-75 minutos  
> **Nivel**: Intermedio

## 📁 Estructura

```
laboratorios/
├── README.md                          # Este archivo
└── lab-01-crear-serviceaccounts/      # Creación y uso de ServiceAccounts
    ├── README.md                      # Instrucciones completas
    ├── SETUP.md                       # Guía de setup
    └── cleanup.sh                     # Script de limpieza
```

## 📋 Laboratorio Disponible

### [Lab 01: Crear ServiceAccounts](./lab-01-crear-serviceaccounts/) ⭐⭐⭐
**Duración**: 60-75 minutos | **Dificultad**: Intermedio

**Objetivos**:
- Crear ServiceAccounts imperativamente y declarativamente
- Vincular ServiceAccounts con Roles y RoleBindings
- Usar ServiceAccounts en pods y deployments
- Verificar permisos de ServiceAccounts
- Acceder a la API de Kubernetes desde pods

**Archivos**:
- `README.md` - Instrucciones paso a paso
- `SETUP.md` - Prerequisitos y verificación
- `cleanup.sh` - Limpieza de recursos

**Conceptos cubiertos**:
- Creación de ServiceAccounts
- Token mounting y acceso
- RBAC con ServiceAccounts
- Role y RoleBinding
- ClusterRole y ClusterRoleBinding
- API access desde pods
- Best practices de seguridad

---

## 🚀 Guía de Uso

```bash
# Navegar al lab
cd lab-01-crear-serviceaccounts/

# Leer prerequisitos
cat SETUP.md

# Verificar entorno
kubectl auth can-i create serviceaccounts

# Seguir instrucciones
cat README.md

# Limpiar al finalizar
chmod +x cleanup.sh
./cleanup.sh
```

## 🎯 Resultados de Aprendizaje

Después de completar este laboratorio, serás capaz de:

- [ ] Crear ServiceAccounts con `kubectl create sa`
- [ ] Escribir manifiestos YAML de ServiceAccounts
- [ ] Vincular SAs con Roles usando RoleBindings
- [ ] Asignar ServiceAccounts a pods
- [ ] Verificar permisos con `kubectl auth can-i --as`
- [ ] Acceder al token del SA desde un pod
- [ ] Configurar permisos mínimos (principle of least privilege)
- [ ] Troubleshoot problemas de permisos

## 💡 Tips

### Comandos Rápidos

```bash
# Crear SA
kubectl create sa mi-sa

# Ver SAs
kubectl get sa

# Ver detalles
kubectl describe sa mi-sa

# Probar permisos
kubectl auth can-i list pods --as=system:serviceaccount:default:mi-sa
```

### Debugging

```bash
# Ver qué SA usa un pod
kubectl get pod <pod> -o jsonpath='{.spec.serviceAccountName}'

# Ver token en pod
kubectl exec <pod> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Ver eventos de RBAC
kubectl get events | grep -i forbidden
```

## 📚 Recursos

- **Docs**: [Configure Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- **RBAC**: [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- **Ejemplos**: Ver [../ejemplos/](../ejemplos/)

---

[Volver al módulo](../README.md) | [Ver ejemplos](../ejemplos/)
