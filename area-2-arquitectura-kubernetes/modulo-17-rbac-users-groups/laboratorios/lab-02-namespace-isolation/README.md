# Laboratorio 02: Aislamiento de Namespaces con RBAC

## Información

**Duración**: 60-75 minutos  
**Nivel**: Intermedio  
**Prerequisites**: Lab 01 completado

## Objetivos

1. Crear múltiples usuarios con acceso a namespaces específicos
2. Implementar aislamiento total entre namespaces
3. Configurar Roles con permisos diferenciados por namespace
4. Verificar que usuarios NO puedan acceder a namespaces ajenos

## Escenario

Tu empresa tiene 3 equipos con requisitos diferentes:

| Equipo | Namespace | Usuario | Permisos |
|--------|-----------|---------|----------|
| **Development** | `dev` | `dev-user` | Lectura pods, logs |
| **Testing** | `test` | `test-user` | Lectura + escritura pods |
| **Production** | `prod` | `prod-admin` | Todos los recursos |

**Objetivo**: Configurar RBAC para que cada usuario solo acceda a su namespace.

---

## Parte 1: Setup Automático

### Script de Configuración

Usa el script `create-multi-users.sh` para automatizar:

```bash
./create-multi-users.sh
```

Este script crea:
- 3 namespaces (`dev`, `test`, `prod`)
- 3 usuarios con certificados
- 3 Roles con permisos diferenciados
- 3 RoleBindings
- Configuración kubectl para cada usuario

---

## Parte 2: Verificación de Aislamiento

### Test 1: Verificar acceso permitido

```bash
# Usuario dev-user puede ver dev
kubectl config use-context dev-user@kubernetes
kubectl get pods -n dev
# ✓ Debe funcionar

# Usuario test-user puede ver test
kubectl config use-context test-user@kubernetes
kubectl get pods -n test
# ✓ Debe funcionar
```

### Test 2: Verificar aislamiento entre namespaces

```bash
# Usuario dev-user NO puede ver test
kubectl config use-context dev-user@kubernetes
kubectl get pods -n test
# ✗ Error: forbidden

# Usuario test-user NO puede ver prod
kubectl config use-context test-user@kubernetes
kubectl get pods -n prod
# ✗ Error: forbidden
```

### Test 3: Verificar diferencia de permisos

```bash
# dev-user solo lectura
kubectl config use-context dev-user@kubernetes
kubectl run test --image=nginx -n dev
# ✗ Error: forbidden

# test-user puede crear pods
kubectl config use-context test-user@kubernetes
kubectl run test --image=nginx -n test
# ✓ Debe funcionar

# prod-admin tiene permisos completos
kubectl config use-context prod-admin@kubernetes
kubectl create deployment nginx --image=nginx -n prod
kubectl expose deployment nginx --port=80 -n prod
# ✓ Debe funcionar
```

---

## Parte 3: Verificación Automática

```bash
./verify-isolation.sh
```

Este script ejecuta 15 tests para verificar:
- ✓ Namespaces creados
- ✓ Usuarios configurados
- ✓ Roles y RoleBindings correctos
- ✓ Aislamiento entre namespaces
- ✓ Permisos diferenciados

---

## Troubleshooting

### Usuario puede acceder a namespace incorrecto

**Causa**: RoleBinding mal configurado

**Solución**:
```bash
kubectl get rolebinding -n dev
# Verificar que solo dev-user tiene binding en dev
```

### Usuario no puede acceder a su propio namespace

**Causa**: Role sin permisos o RoleBinding incorrecto

**Solución**:
```bash
kubectl describe role -n dev
kubectl describe rolebinding -n dev
```

---

## Cleanup

```bash
./cleanup.sh
```

Elimina todos los recursos creados.

---

## Conceptos CKA

- **Namespace isolation**: Seguridad multi-tenant
- **Role granularity**: Permisos específicos por namespace
- **RoleBinding scope**: Limitado a un namespace
- **ClusterRole vs Role**: Cuándo usar cada uno

**Tiempo estimado CKA**: 8-10 minutos para configurar 2 usuarios aislados.
