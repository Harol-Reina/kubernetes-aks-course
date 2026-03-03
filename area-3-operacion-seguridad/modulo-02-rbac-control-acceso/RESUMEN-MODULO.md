# 📚 RESUMEN - Módulo 02 (Área 3): RBAC y Control de Acceso

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre **RBAC (Role-Based Access Control)** en Kubernetes — el sistema que controla quién puede hacer qué en tu cluster. Aprenderás a crear Roles, ClusterRoles, RoleBindings, ServiceAccounts, y a integrar AKS con Azure Active Directory para autenticación empresarial.

**Duración**: 6 horas (teoría + labs)
**Nivel**: Intermedio-Avanzado
**Prerequisitos**: Namespaces, Pods, Deployments, conceptos básicos de seguridad

---

## 📋 Objetivos de Aprendizaje

### Fundamentos
- ✅ Explicar qué es RBAC y por qué es necesario
- ✅ Diferenciar entre autenticación (quién eres) y autorización (qué puedes hacer)
- ✅ Aplicar el principio de mínimo privilegio
- ✅ Entender la diferencia entre Role y ClusterRole

### Técnico
- ✅ Crear Roles con permisos específicos
- ✅ Crear RoleBindings para asignar permisos
- ✅ Configurar ServiceAccounts para Pods y pipelines
- ✅ Usar `kubectl auth can-i` para auditar permisos
- ✅ Integrar AKS con Azure AD

### Troubleshooting
- ✅ Diagnosticar errores "Forbidden"
- ✅ Auditar permisos existentes en el cluster
- ✅ Identificar permisos excesivos

---

## 🗺️ Estructura de Aprendizaje

### Las 4 Piezas de RBAC

```
┌─────────────────────────────────────────────────┐
│  1. QUIÉN         →  ServiceAccount / User       │
│  2. QUÉ PERMISOS  →  Role / ClusterRole          │
│  3. CONEXIÓN      →  RoleBinding / ClusterRoleB.  │
│  4. DÓNDE         →  Namespace / Cluster          │
└─────────────────────────────────────────────────┘
```

### Diagrama Mental

```
ServiceAccount ──► RoleBinding ──► Role ──► [verbs] sobre [resources]
                         │
                   (en un namespace)

ServiceAccount ──► ClusterRoleBinding ──► ClusterRole ──► [verbs] sobre [resources]
                         │
                   (en todo el cluster)
```

### Tabla Comparativa

| Componente | Alcance | Uso típico |
|-----------|---------|------------|
| Role | Un namespace | Permisos para un equipo en su espacio |
| ClusterRole | Todo el cluster | Permisos para auditor, admin, nodos |
| RoleBinding | Un namespace | Asignar Role a usuario en un namespace |
| ClusterRoleBinding | Todo el cluster | Asignar ClusterRole globalmente |
| ServiceAccount | Un namespace | Identidad para Pods y CI/CD |

---

## 🔧 Comandos Esenciales

### Básicos

```bash
# Ver ServiceAccounts
kubectl get sa -n <namespace>

# Ver Roles
kubectl get roles -n <namespace>
kubectl describe role <name> -n <namespace>

# Ver RoleBindings
kubectl get rolebindings -n <namespace> -o wide

# Ver ClusterRoles
kubectl get clusterroles | grep -v system:

# Ver ClusterRoleBindings
kubectl get clusterrolebindings | grep -v system:
```

### Verificar Permisos

```bash
# ¿Puedo hacer X?
kubectl auth can-i <verb> <resource> -n <namespace>

# ¿Puede un ServiceAccount hacer X?
kubectl auth can-i <verb> <resource> \
  --as=system:serviceaccount:<ns>:<sa-name> -n <namespace>

# Listar TODOS los permisos de un SA
kubectl auth can-i --list \
  --as=system:serviceaccount:<ns>:<sa-name> -n <namespace>

# ¿Quién puede hacer X? (requiere RBAC review)
kubectl auth can-i <verb> <resource> --list
```

### Crear RBAC

```bash
# Crear Role (imperativo)
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n <namespace>

# Crear RoleBinding
kubectl create rolebinding dev-pod-reader \
  --role=pod-reader \
  --serviceaccount=<ns>:<sa-name> \
  -n <namespace>

# Crear ClusterRole
kubectl create clusterrole node-reader \
  --verb=get,list,watch \
  --resource=nodes

# Crear ClusterRoleBinding
kubectl create clusterrolebinding global-reader \
  --clusterrole=node-reader \
  --serviceaccount=<ns>:<sa-name>
```

---

## 📝 Cheat Sheet: YAML Snippets

### Role con Permisos de Lectura

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: mi-namespace
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "services"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
```

### RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-pod-reader
  namespace: mi-namespace
subjects:
- kind: ServiceAccount
  name: mi-sa
  namespace: mi-namespace
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### ServiceAccount para CI/CD

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cicd-deployer
  namespace: produccion
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deploy-role
  namespace: produccion
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cicd-deploy-binding
  namespace: produccion
subjects:
- kind: ServiceAccount
  name: cicd-deployer
  namespace: produccion
roleRef:
  kind: Role
  name: deploy-role
  apiGroup: rbac.authorization.k8s.io
```

---

## ❗ Problemas Comunes y Soluciones

### 1. Error "Forbidden" al ejecutar kubectl

**Causa**: El usuario/SA no tiene permisos.
**Diagnóstico**: `kubectl auth can-i <verb> <resource> --as=<user> -n <ns>`
**Solución**: Crear Role + RoleBinding con los verbos necesarios.

### 2. RoleBinding creado pero permisos no funcionan

**Causa**: El RoleBinding está en un namespace diferente al Role.
**Solución**: Verificar que Role, RoleBinding y recursos están en el mismo namespace.

### 3. ServiceAccount no puede acceder a otro namespace

**Causa**: Los Roles son namespace-scoped.
**Solución**: Usar ClusterRole + ClusterRoleBinding para acceso cross-namespace.

### 4. Permisos de ServiceAccount "default" demasiado amplios

**Causa**: Alguien dio permisos al SA default.
**Solución**: Crear SAs específicos para cada aplicación. Nunca dar permisos al SA default.

### 5. No puedo ver qué permisos tienen los demás

**Solución**:
```bash
kubectl get rolebindings,clusterrolebindings -A -o wide
```

### 6. Error al impersonar con --as

**Causa**: Tu usuario necesita el permiso `impersonate`.
**Solución**: Solo cluster-admin puede usar `--as`. Verifica tu contexto.

---

## ✅ Checklist de Conceptos

- [ ] Sé la diferencia entre autenticación y autorización
- [ ] Puedo crear Roles con permisos específicos (verbos + recursos)
- [ ] Puedo crear RoleBindings que conectan SA con Roles
- [ ] Entiendo cuándo usar Role vs ClusterRole
- [ ] Sé usar `kubectl auth can-i` para verificar permisos
- [ ] Puedo crear ServiceAccounts específicos para aplicaciones
- [ ] Entiendo el principio de mínimo privilegio
- [ ] Sé auditar permisos existentes en el cluster
- [ ] Puedo impersonar usuarios con `--as` para probar permisos

---

## 📝 Preguntas de Repaso

### 1. ¿Cuál es la diferencia entre un Role y un ClusterRole?

<details>
<summary>Ver respuesta</summary>

Un **Role** aplica solo dentro de un namespace específico. Un **ClusterRole** aplica en todo el cluster. Usa Role cuando los permisos son para un equipo en su namespace. Usa ClusterRole para permisos globales (auditor, admin, acceso a nodos).
</details>

### 2. ¿Qué verbos necesita un ServiceAccount para un pipeline CI/CD?

<details>
<summary>Ver respuesta</summary>

Típicamente: `get`, `list`, `watch`, `create`, `update`, `patch` en Deployments y Services. NO necesita `delete` (para evitar eliminaciones accidentales) ni acceso a Secrets (a menos que sea estrictamente necesario).
</details>

### 3. ¿Cómo verificas si un ServiceAccount puede crear Pods?

<details>
<summary>Ver respuesta</summary>

```bash
kubectl auth can-i create pods \
  --as=system:serviceaccount:<namespace>:<sa-name> \
  -n <namespace>
```
</details>

### 4. ¿Qué pasa si un Pod no especifica un ServiceAccount?

<details>
<summary>Ver respuesta</summary>

Usa el ServiceAccount `default` del namespace. Este SA normalmente tiene permisos muy limitados (casi ninguno). Es una buena práctica crear SAs específicos con solo los permisos necesarios.
</details>

### 5. ¿Por qué los ClusterRoles necesitan ClusterRoleBindings separados?

<details>
<summary>Ver respuesta</summary>

Los ClusterRoles son cluster-scoped, no pertenecen a ningún namespace. Por eso necesitan ClusterRoleBindings (también cluster-scoped) para asignarlos. Sin embargo, puedes usar un RoleBinding para asignar un ClusterRole a un namespace específico, lo que limita su alcance.
</details>

### 6. ¿Cómo listar TODOS los permisos de un usuario?

<details>
<summary>Ver respuesta</summary>

```bash
kubectl auth can-i --list --as=system:serviceaccount:<ns>:<sa> -n <namespace>
```
</details>

### 7. ¿Qué es el principio de mínimo privilegio?

<details>
<summary>Ver respuesta</summary>

Cada usuario o proceso debe tener SOLO los permisos que necesita para su función, y nada más. No dar permisos "por si acaso". Los permisos se amplían cuando la necesidad es real y documentada.
</details>

### 8. ¿Cómo se integra RBAC con Azure AD en AKS?

<details>
<summary>Ver respuesta</summary>

Azure AD se encarga de la **autenticación** (verificar identidad). Kubernetes RBAC se encarga de la **autorización** (qué puede hacer). Al habilitar Azure AD en AKS, los usuarios se autentican con sus credenciales corporativas, y luego RBAC determina sus permisos en el cluster.
</details>

---

## 🎓 Relevancia para Certificaciones

### CKA
- RBAC es ~8% del examen CKA
- Crear Roles, ClusterRoles, RoleBindings, ClusterRoleBindings
- Verificar permisos con `auth can-i`

### CKAD
- ServiceAccounts y permisos para aplicaciones
- Configurar pods con ServiceAccounts específicos

### AKS Specialty
- Integración con Azure AD / Entra ID
- Managed Identity para pods (Azure Workload Identity)
- Kubernetes RBAC + Azure RBAC combinados

---

## 🔗 Siguiente Paso

Continúa con el **Módulo 03: Network Policies** para aprender a controlar la comunicación entre Pods a nivel de red. RBAC controla quién puede GESTIONAR recursos; Network Policies controlan quién puede COMUNICARSE con quién.
