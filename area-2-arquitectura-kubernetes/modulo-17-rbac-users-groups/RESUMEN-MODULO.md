# 📚 Resumen Módulo 17: RBAC - Usuarios y Grupos

> **Guía de Estudio Rápida** - Control de acceso para **personas** usando **certificados X.509**

---

## 🎯 Conceptos Clave en 5 Minutos

### ¿Qué es RBAC?
**Role-Based Access Control** = Sistema de permisos basado en roles que define **quién** puede hacer **qué** en el cluster.

### Diferencia Fundamental: Usuarios vs Service Accounts
| Aspecto | Usuarios (Módulo 17) | Service Accounts (Módulo 18) |
|---------|---------------------|------------------------------|
| **Para quién** | 👤 Personas (desarrolladores, admins) | 🤖 Aplicaciones (pods, deployments) |
| **Autenticación** | 🔐 Certificados X.509 | 🎫 Tokens JWT |
| **Gestión** | Manual (OpenSSL, scripts) | Automática (API Kubernetes) |
| **Acceso** | Externo (kubectl) | Interno (dentro del cluster) |

### Componentes RBAC
```
Role/ClusterRole      →  Define QUÉ permisos (resources + verbs)
        ↓
RoleBinding/          →  Conecta roles con QUIÉN (Subject)
ClusterRoleBinding    
        ↓
Subject               →  Usuario, Grupo, o ServiceAccount
        ↓
ACCESO PERMITIDO      ✅
```

---

## 📋 Práctica 1: Crear Usuario con Certificado (30 min)

### Paso 1: Generar clave privada y CSR
```bash
# 1. Crear clave privada
openssl genrsa -out developer.key 2048

# 2. Generar Certificate Signing Request (CSR)
openssl req -new -key developer.key -out developer.csr \
  -subj "/CN=developer/O=dev-team"
  
# CN = Common Name (nombre del usuario)
# O = Organization (grupo del usuario)
```

### Paso 2: Crear CertificateSigningRequest en Kubernetes
```yaml
# developer-csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: developer
spec:
  request: <BASE64_ENCODED_CSR>  # cat developer.csr | base64 | tr -d '\n'
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
```

```bash
# Codificar CSR en base64
cat developer.csr | base64 | tr -d '\n'

# Aplicar CSR
kubectl apply -f developer-csr.yaml

# Aprobar certificado
kubectl certificate approve developer

# Obtener certificado firmado
kubectl get csr developer -o jsonpath='{.status.certificate}' | \
  base64 -d > developer.crt
```

### Paso 3: Configurar kubectl
```bash
# 1. Agregar credenciales de usuario
kubectl config set-credentials developer \
  --client-certificate=developer.crt \
  --client-key=developer.key

# 2. Crear contexto
kubectl config set-context developer-context \
  --cluster=<nombre-cluster> \
  --user=developer \
  --namespace=development

# 3. Usar el contexto
kubectl config use-context developer-context

# 4. Verificar usuario actual
kubectl config current-context
```

### ✅ Verificación
```bash
# Debe fallar (sin permisos aún)
kubectl get pods
# Error: User "developer" cannot list resource "pods"

# Esto es correcto - aún no hemos asignado roles
```

---

## 📋 Práctica 2: Crear Role y RoleBinding (20 min)

### Paso 1: Definir Role
```yaml
# role-pod-reader.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: development
rules:
- apiGroups: [""]           # "" = core API group
  resources: ["pods"]       # Qué recursos
  verbs: ["get", "list"]    # Qué acciones
```

```bash
# Aplicar como admin
kubectl apply -f role-pod-reader.yaml
```

### Paso 2: Crear RoleBinding
```yaml
# rolebinding-developer.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-pod-reader
  namespace: development
subjects:
- kind: User              # Tipo: User, Group, ServiceAccount
  name: developer         # Nombre del usuario (CN del certificado)
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader        # Nombre del Role
  apiGroup: rbac.authorization.k8s.io
```

```bash
# Aplicar como admin
kubectl apply -f rolebinding-developer.yaml
```

### ✅ Verificación
```bash
# Cambiar a usuario developer
kubectl config use-context developer-context

# Ahora debe funcionar
kubectl get pods -n development
# ✅ Lista pods exitosamente

# Pero esto debe fallar
kubectl delete pod <pod-name> -n development
# ❌ Error: cannot delete resource "pods"

# Verificar permisos específicos
kubectl auth can-i get pods -n development
# yes

kubectl auth can-i delete pods -n development
# no
```

---

## 📋 Práctica 3: ClusterRole y ClusterRoleBinding (25 min)

### Diferencia: Role vs ClusterRole
| Role | ClusterRole |
|------|-------------|
| Scope: **un namespace** | Scope: **todo el cluster** |
| Permisos en namespace específico | Permisos globales |
| No puede acceder recursos cluster-wide | Puede acceder nodes, PV, namespaces |

### Paso 1: Crear ClusterRole
```yaml
# clusterrole-pod-reader.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: global-pod-reader  # No tiene namespace
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]    # Acceso a logs
  verbs: ["get"]
```

```bash
kubectl apply -f clusterrole-pod-reader.yaml
```

### Paso 2: Crear ClusterRoleBinding
```yaml
# clusterrolebinding-developer.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: developer-global-pods
subjects:
- kind: User
  name: developer
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: global-pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f clusterrolebinding-developer.yaml
```

### ✅ Verificación
```bash
# Como developer, ahora puede ver pods en TODOS los namespaces
kubectl get pods --all-namespaces
# ✅ Funciona

kubectl get pods -n kube-system
# ✅ Funciona

kubectl get pods -n default
# ✅ Funciona
```

---

## 📋 Práctica 4: Roles con Múltiples Recursos (30 min)

### Role Completo para Desarrollador
```yaml
# role-developer-full.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-full
  namespace: development
rules:
# Pods - lectura y logs
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]

# Deployments - gestión completa
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# Services - solo lectura
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]

# ConfigMaps y Secrets - lectura
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]

# Events - lectura (para debugging)
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
```

### Aplicar y Probar
```bash
# Aplicar role
kubectl apply -f role-developer-full.yaml

# Crear rolebinding
kubectl create rolebinding developer-full-binding \
  --role=developer-full \
  --user=developer \
  --namespace=development

# Probar permisos
kubectl auth can-i create deployments -n development --as developer
# yes

kubectl auth can-i delete secrets -n development --as developer
# no

kubectl auth can-i list pods -n development --as developer
# yes
```

---

## 📋 Práctica 5: Grupos en RBAC (25 min)

### Organizar Usuarios por Equipos
```yaml
# rolebinding-group-devs.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developers-binding
  namespace: development
subjects:
- kind: Group
  name: dev-team           # Todos los usuarios con O=dev-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-full
  apiGroup: rbac.authorization.k8s.io
```

### Crear Múltiples Usuarios en el Mismo Grupo
```bash
# Usuario 1: alice
openssl req -new -key alice.key -out alice.csr \
  -subj "/CN=alice/O=dev-team"

# Usuario 2: bob
openssl req -new -key bob.key -out bob.csr \
  -subj "/CN=bob/O=dev-team"

# Usuario 3: charlie
openssl req -new -key charlie.key -out charlie.csr \
  -subj "/CN=charlie/O=dev-team"

# TODOS heredan permisos del grupo "dev-team"
```

### Ventajas de Grupos
```
✅ Gestión centralizada: Un RoleBinding para múltiples usuarios
✅ Escalabilidad: Agregar usuarios sin modificar RoleBindings
✅ Organización: Equipos claramente definidos (dev, ops, qa)
✅ Auditoría: Fácil rastrear permisos por equipo
```

---

## 🔍 Práctica 6: Troubleshooting de Permisos (30 min)

### Problema 1: "User cannot list pods"
```bash
# Error
kubectl get pods
# Error: User "developer" cannot list resource "pods" in namespace "default"

# Diagnóstico
kubectl auth can-i list pods --as developer
# no

# Verificar roles del usuario
kubectl get rolebindings -n default -o wide | grep developer
# (vacío - no hay rolebinding)

# Solución
kubectl create rolebinding developer-pods \
  --role=pod-reader \
  --user=developer \
  --namespace=default
```

### Problema 2: "Forbidden" en namespace diferente
```bash
# Funciona
kubectl get pods -n development
# ✅ OK

# Falla
kubectl get pods -n production
# ❌ Error: Forbidden

# Explicación
# RoleBinding es por namespace - necesitas otro binding en production

# Solución
kubectl create rolebinding developer-pods-prod \
  --role=pod-reader \
  --user=developer \
  --namespace=production
```

### Problema 3: Certificado expirado
```bash
# Error
Unable to connect to the server: x509: certificate has expired

# Verificar fecha del certificado
openssl x509 -in developer.crt -noout -dates
# notAfter=Nov 12 00:00:00 2024 GMT

# Solución: Regenerar certificado
# 1. Crear nuevo CSR
# 2. Aplicar CertificateSigningRequest
# 3. Aprobar y obtener nuevo certificado
# 4. Actualizar kubectl config
```

### Comandos de Diagnóstico
```bash
# 1. Verificar usuario actual
kubectl config current-context

# 2. Ver info del usuario
kubectl config view --minify

# 3. Verificar permisos específicos
kubectl auth can-i <verb> <resource> --as <user> -n <namespace>

# Ejemplos
kubectl auth can-i get pods --as developer -n default
kubectl auth can-i delete deployments --as developer -n production
kubectl auth can-i '*' '*' --as admin --all-namespaces

# 4. Listar todos los RoleBindings de un usuario
kubectl get rolebindings --all-namespaces -o json | \
  jq '.items[] | select(.subjects[]?.name=="developer")'

# 5. Ver detalles de un Role
kubectl describe role pod-reader -n development

# 6. Ver detalles de un RoleBinding
kubectl describe rolebinding developer-pod-reader -n development
```

---

## 🎓 Cheat Sheet de Comandos RBAC

### Gestión de Certificados
```bash
# Generar clave privada
openssl genrsa -out <user>.key 2048

# Generar CSR
openssl req -new -key <user>.key -out <user>.csr \
  -subj "/CN=<username>/O=<group>"

# Codificar CSR para Kubernetes
cat <user>.csr | base64 | tr -d '\n'

# Aprobar CSR
kubectl certificate approve <csr-name>

# Obtener certificado
kubectl get csr <csr-name> -o jsonpath='{.status.certificate}' | \
  base64 -d > <user>.crt

# Verificar certificado
openssl x509 -in <user>.crt -noout -text
```

### kubectl config
```bash
# Agregar credenciales
kubectl config set-credentials <user> \
  --client-certificate=<user>.crt \
  --client-key=<user>.key

# Agregar cluster
kubectl config set-cluster <cluster-name> \
  --server=https://<api-server>:6443 \
  --certificate-authority=ca.crt

# Crear contexto
kubectl config set-context <context-name> \
  --cluster=<cluster> \
  --user=<user> \
  --namespace=<namespace>

# Usar contexto
kubectl config use-context <context-name>

# Ver contextos
kubectl config get-contexts

# Ver contexto actual
kubectl config current-context

# Ver configuración completa
kubectl config view
```

### Crear Roles
```bash
# Role básico
kubectl create role <role-name> \
  --verb=<get,list,watch> \
  --resource=<pods,services> \
  --namespace=<namespace>

# Ejemplos
kubectl create role pod-reader \
  --verb=get,list \
  --resource=pods \
  --namespace=development

kubectl create role deployment-manager \
  --verb=get,list,watch,create,update,patch,delete \
  --resource=deployments \
  --namespace=development

# ClusterRole
kubectl create clusterrole <name> \
  --verb=<verbs> \
  --resource=<resources>

# Ejemplo
kubectl create clusterrole global-pod-reader \
  --verb=get,list,watch \
  --resource=pods
```

### Crear RoleBindings
```bash
# RoleBinding para usuario
kubectl create rolebinding <binding-name> \
  --role=<role-name> \
  --user=<username> \
  --namespace=<namespace>

# RoleBinding para grupo
kubectl create rolebinding <binding-name> \
  --role=<role-name> \
  --group=<groupname> \
  --namespace=<namespace>

# ClusterRoleBinding para usuario
kubectl create clusterrolebinding <binding-name> \
  --clusterrole=<role-name> \
  --user=<username>

# ClusterRoleBinding para grupo
kubectl create clusterrolebinding <binding-name> \
  --clusterrole=<role-name> \
  --group=<groupname>
```

### Verificación de Permisos
```bash
# Verificar permiso propio
kubectl auth can-i <verb> <resource>

# Ejemplos
kubectl auth can-i get pods
kubectl auth can-i delete deployments
kubectl auth can-i create secrets -n production

# Verificar permisos de otro usuario
kubectl auth can-i <verb> <resource> --as <user> -n <namespace>

# Ejemplos
kubectl auth can-i get pods --as developer -n development
kubectl auth can-i delete services --as developer -n production

# Verificar si es admin (todos los permisos)
kubectl auth can-i '*' '*' --all-namespaces
```

### Listar y Describir
```bash
# Listar Roles
kubectl get roles -n <namespace>
kubectl get roles --all-namespaces

# Listar ClusterRoles
kubectl get clusterroles

# Listar RoleBindings
kubectl get rolebindings -n <namespace>
kubectl get rolebindings --all-namespaces

# Listar ClusterRoleBindings
kubectl get clusterrolebindings

# Describir Role
kubectl describe role <role-name> -n <namespace>

# Describir RoleBinding
kubectl describe rolebinding <binding-name> -n <namespace>

# Ver YAML
kubectl get role <role-name> -n <namespace> -o yaml
kubectl get rolebinding <binding-name> -n <namespace> -o yaml
```

### Eliminar
```bash
# Eliminar Role
kubectl delete role <role-name> -n <namespace>

# Eliminar RoleBinding
kubectl delete rolebinding <binding-name> -n <namespace>

# Eliminar ClusterRole
kubectl delete clusterrole <role-name>

# Eliminar ClusterRoleBinding
kubectl delete clusterrolebinding <binding-name>

# Eliminar CSR
kubectl delete csr <csr-name>
```

---

## 📊 Verbs (Acciones) Disponibles

| Verb | Descripción | Ejemplo |
|------|-------------|---------|
| `get` | Leer un recurso específico | `kubectl get pod nginx` |
| `list` | Listar múltiples recursos | `kubectl get pods` |
| `watch` | Observar cambios en tiempo real | `kubectl get pods -w` |
| `create` | Crear nuevos recursos | `kubectl create deployment nginx --image=nginx` |
| `update` | Actualizar recursos existentes | `kubectl replace -f pod.yaml` |
| `patch` | Modificar parcialmente | `kubectl patch pod nginx -p '{...}'` |
| `delete` | Eliminar recursos | `kubectl delete pod nginx` |
| `deletecollection` | Eliminar múltiples recursos | `kubectl delete pods --all` |

### Verbs Especiales
| Verb | Descripción |
|------|-------------|
| `*` | Todos los verbs |
| `get`, `list`, `watch` | Solo lectura (read-only) |
| `create`, `update`, `patch` | Escritura sin borrar |
| `create`, `update`, `patch`, `delete` | Escritura completa |

---

## 🎯 Comparaciones Prácticas

### Role vs ClusterRole

```yaml
# ROLE - Scope: UN namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: development    # ⬅️ Namespace específico
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

---

# CLUSTERROLE - Scope: TODO el cluster
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: global-pod-reader   # ⬅️ SIN namespace
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

### RoleBinding vs ClusterRoleBinding

```yaml
# ROLEBINDING - Asigna permisos en UN namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: development    # ⬅️ Solo en este namespace
subjects:
- kind: User
  name: developer
roleRef:
  kind: Role               # Puede ser Role o ClusterRole
  name: pod-reader

---

# CLUSTERROLEBINDING - Asigna permisos globales
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: global-developer-binding  # ⬅️ SIN namespace
subjects:
- kind: User
  name: developer
roleRef:
  kind: ClusterRole        # DEBE ser ClusterRole
  name: global-pod-reader
```

### Casos de Uso

| Necesidad | Solución |
|-----------|----------|
| Developer lee pods en `dev` namespace | Role + RoleBinding en `dev` |
| Developer lee pods en TODOS los namespaces | ClusterRole + ClusterRoleBinding |
| Developer lee pods en `dev` y `qa` | Role + 2 RoleBindings (uno en cada namespace) |
| Admin gestiona nodes | ClusterRole + ClusterRoleBinding |
| Auditor lee todo sin modificar | ClusterRole (solo get/list) + ClusterRoleBinding |

---

## ✅ Checklist de Implementación RBAC

### Fase 1: Planificación
- [ ] Identificar usuarios/equipos que necesitan acceso
- [ ] Definir roles necesarios (developer, operator, auditor, admin)
- [ ] Mapear permisos por rol (qué recursos, qué acciones)
- [ ] Decidir scope (namespace o cluster-wide)
- [ ] Documentar matriz de permisos

### Fase 2: Configuración Inicial
- [ ] Verificar OpenSSL instalado
- [ ] Confirmar acceso admin al cluster
- [ ] Crear namespaces necesarios
- [ ] Obtener CA del cluster

### Fase 3: Creación de Usuarios
- [ ] Generar claves privadas para cada usuario
- [ ] Crear CSRs con CN (usuario) y O (grupo)
- [ ] Aplicar CertificateSigningRequests en K8s
- [ ] Aprobar CSRs
- [ ] Obtener certificados firmados
- [ ] Distribuir certificados a usuarios

### Fase 4: Definición de Roles
- [ ] Crear Roles para permisos por namespace
- [ ] Crear ClusterRoles para permisos globales
- [ ] Validar resources y verbs correctos
- [ ] Aplicar principio de mínimo privilegio

### Fase 5: Asignación de Permisos
- [ ] Crear RoleBindings por usuario/grupo
- [ ] Crear ClusterRoleBindings si es necesario
- [ ] Verificar subjects correctos (User, Group)
- [ ] Confirmar roleRef apunta al Role correcto

### Fase 6: Configuración kubectl
- [ ] Configurar credenciales en kubectl
- [ ] Crear contextos por usuario
- [ ] Probar cambio de contextos
- [ ] Distribuir kubeconfig a usuarios

### Fase 7: Pruebas y Verificación
- [ ] Probar cada usuario con kubectl auth can-i
- [ ] Verificar permisos positivos (debe funcionar)
- [ ] Verificar permisos negativos (debe fallar)
- [ ] Probar en múltiples namespaces
- [ ] Documentar resultados

### Fase 8: Monitoreo y Mantenimiento
- [ ] Auditar permisos regularmente
- [ ] Renovar certificados antes de expiración
- [ ] Actualizar RoleBindings según cambios de equipo
- [ ] Eliminar usuarios inactivos
- [ ] Revisar logs de acceso

---

## 🎓 Preguntas de Repaso

### Conceptuales
1. ¿Cuál es la diferencia entre Role y ClusterRole?
2. ¿Por qué usamos certificados X.509 para usuarios y no tokens?
3. ¿Qué significa el CN y O en un certificado?
4. ¿Cuándo usar RoleBinding vs ClusterRoleBinding?
5. ¿Qué es el principio de mínimo privilegio en RBAC?

### Prácticas
1. ¿Cómo verificar los permisos de un usuario sin cambiar de contexto?
2. ¿Qué comando usas para aprobar un CSR?
3. ¿Cómo listar todos los RoleBindings de un namespace?
4. ¿Cómo dar permisos de solo lectura a todos los recursos de un namespace?
5. ¿Qué hacer si un certificado expira?

### Troubleshooting
1. Usuario recibe "Forbidden" al ejecutar kubectl get pods - ¿qué verificas primero?
2. Creaste un Role pero el usuario no tiene permisos - ¿qué falta?
3. RoleBinding apunta a un Role que no existe - ¿qué error ves?
4. Usuario tiene permisos en `dev` pero no en `prod` - ¿cómo lo solucionas?
5. ¿Cómo auditar quién tiene permisos de admin en el cluster?

---

## 🔗 Próximos Pasos

### Después de Dominar Este Módulo
✅ Has aprendido a gestionar acceso para **personas**
✅ Dominas certificados X.509 y kubectl config
✅ Sabes crear Roles y RoleBindings

### Siguiente: Módulo 18 - Service Accounts
➡️ **[Módulo 18: RBAC - Service Accounts](../modulo-18-rbac-serviceaccounts/)**

**Aprenderás**:
- Identidades para **aplicaciones** y **pods**
- Tokens JWT automáticos
- Montaje de credenciales en pods
- Permisos para aplicaciones internas

### Recursos Adicionales
- 📖 [Documentación oficial RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- 📖 [Certificate Signing Requests](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/)
- 📖 [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- 🎥 [Tutorial RBAC en Kubernetes](https://www.youtube.com/results?search_query=kubernetes+rbac+tutorial)

### Práctica Adicional
- Implementar RBAC en un proyecto personal
- Crear múltiples usuarios con diferentes roles
- Auditar permisos en cluster existente
- Documentar políticas de acceso de tu organización

---

## 📝 Notas Finales

**Recuerda**:
- RBAC es **aditivo**: No hay permisos "deny", solo "allow"
- Por defecto, **todo está denegado** (whitelist)
- Certificados tienen **expiración** (renovar regularmente)
- Usa **grupos** para gestión escalable
- Principio de **mínimo privilegio** siempre

**Diferencia clave para recordar**:
```
Usuarios (Módulo 17) = Personas con certificados X.509
ServiceAccounts (Módulo 18) = Aplicaciones con tokens JWT
```

¡Éxito en tu aprendizaje de RBAC! 🚀
