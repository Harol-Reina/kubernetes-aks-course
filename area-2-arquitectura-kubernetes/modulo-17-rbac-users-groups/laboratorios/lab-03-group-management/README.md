# Laboratorio 03: Gestión de Grupos RBAC

## Información

**Duración**: 60-75 minutos  
**Nivel**: Intermedio-Avanzado  
**Prerequisites**: Labs 01 y 02 completados

## Objetivos

1. Crear grupos de usuarios con OpenSSL (campo Organization)
2. Asignar Roles a grupos completos (no a usuarios individuales)
3. Gestionar permisos masivos eficientemente
4. Escalar RBAC para múltiples usuarios

## Escenario

Tu empresa crece y necesitas gestionar equipos completos:

| Grupo | Usuarios | Namespace | Permisos |
|-------|----------|-----------|----------|
| **developers** | alice, bob | dev | Lectura pods |
| **testers** | charlie, diana | test | Escritura pods |
| **admins** | eve, frank | all | Cluster-wide |

**Objetivo**: Asignar permisos por grupo, no por usuario individual.

---

## Parte 1: Crear Usuarios con Grupos

### Concepto Clave

En RBAC de Kubernetes, los **grupos** se definen en el campo **Organization (O)** del certificado:

```bash
openssl req -new -key alice.key -out alice.csr \
  -subj "/CN=alice/O=developers"
#                 ^^^^^^^^^^^^ Grupo
```

Luego, el RoleBinding vincula al **grupo completo**:

```yaml
subjects:
- kind: Group        # No "User"
  name: developers   # Nombre del grupo
```

---

## Parte 2: Setup Automático

```bash
./create-groups.sh
```

Este script:
- Crea 6 usuarios (alice, bob, charlie, diana, eve, frank)
- Asigna cada usuario a un grupo (developers, testers, admins)
- Crea 3 Roles
- Crea 3 **RoleBindings para grupos** (no para usuarios individuales)

---

## Parte 3: Verificación

### Test 1: Usuarios del mismo grupo tienen mismos permisos

```bash
# Alice (developers) puede ver dev
kubectl config use-context alice@kubernetes
kubectl get pods -n dev
# ✓ Funciona

# Bob (developers) también puede ver dev
kubectl config use-context bob@kubernetes
kubectl get pods -n dev
# ✓ Funciona
```

### Test 2: Usuarios de diferentes grupos NO pueden acceder

```bash
# Alice (developers) NO puede ver test
kubectl config use-context alice@kubernetes
kubectl get pods -n test
# ✗ Error: forbidden
```

### Test 3: Admins tienen acceso cluster-wide

```bash
# Eve (admins) puede ver todos los namespaces
kubectl config use-context eve@kubernetes
kubectl get pods --all-namespaces
# ✓ Funciona
```

---

## Parte 4: Escalabilidad

### Añadir nuevo usuario a grupo existente

```bash
# Sin modificar Roles ni RoleBindings
openssl genrsa -out george.key 2048
openssl req -new -key george.key -out george.csr \
  -subj "/CN=george/O=developers"  # Mismo grupo
  
# Firmar certificado y configurar kubectl
# George automáticamente hereda permisos de "developers"
```

**Ventaja**: No necesitas crear nuevos RoleBindings.

---

## Verificación Automática

```bash
./verify-groups.sh
```

Tests:
- ✓ 6 usuarios configurados
- ✓ Grupos correctos en certificados
- ✓ RoleBindings vinculan a grupos
- ✓ Usuarios del mismo grupo tienen mismos permisos
- ✓ Aislamiento entre grupos

---

## Troubleshooting

### Usuario no hereda permisos del grupo

**Causa**: Campo O incorrecto en certificado

**Verificación**:
```bash
openssl x509 -in alice.crt -noout -subject
# Debe mostrar: CN=alice, O=developers
```

### RoleBinding no funciona con grupos

**Causa**: `kind: User` en lugar de `kind: Group`

**Verificación**:
```bash
kubectl get rolebinding -n dev -o yaml
# Debe tener: kind: Group
```

---

## Cleanup

```bash
./cleanup.sh
```

---

## Conceptos CKA

- **Group-based RBAC**: Escalabilidad para múltiples usuarios
- **Certificate Organization field**: Cómo se definen grupos
- **ClusterRoleBinding**: Para permisos cluster-wide
- **Best practices**: Usar grupos en lugar de usuarios individuales

**Tiempo CKA**: 12-15 minutos para configurar 2 grupos con 3 usuarios cada uno.

---

## Comparación: Usuario vs Grupo

| Aspecto | Individual (Lab 01) | Grupo (Lab 03) |
|---------|---------------------|----------------|
| **Certificados** | 1 por usuario | 1 por usuario (con campo O) |
| **RoleBindings** | 1 por usuario | 1 por grupo |
| **Escalabilidad** | Baja (N bindings) | Alta (1 binding) |
| **Mantenimiento** | Difícil (muchos bindings) | Fácil (1 binding) |
| **Uso CKA** | Casos simples | Casos reales |
