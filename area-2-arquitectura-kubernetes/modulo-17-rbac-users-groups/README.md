# Capítulo 19: RBAC — Users y Groups

En los capítulos anteriores construimos una plataforma completa: aplicaciones con storage
persistente, configuración externalizada, secretos protegidos, health checks activos y
recursos controlados. El cluster está funcionando. Ahora, inevitablemente, más personas
necesitan acceder a él.

El problema surge en cuanto el segundo desarrollador se une al equipo. La solución fácil —
darle la misma kubeconfig que tienes tú, con permisos de cluster-admin — es también la más
peligrosa. Con cluster-admin, cualquier acción es posible: un `kubectl delete namespace
production` ejecutado por error en la terminal equivocada destruye todo el entorno de
producción en segundos. No hay confirmación, no hay papelera de reciclaje, no hay deshacer.
Y no es solo un escenario hipotético: incidentes de este tipo ocurren regularmente en equipos
que no han implementado control de acceso. También hay consecuencias de compliance: si tu
empresa maneja datos de clientes, regulaciones como GDPR o SOC2 exigen que puedas demostrar
que solo las personas autorizadas tuvieron acceso a datos sensibles. Con todos usando
cluster-admin, esa demostración es imposible.

RBAC (Role-Based Access Control) es el sistema de permisos de Kubernetes. Permite definir
exactamente qué operaciones (get, list, create, delete, patch) puede realizar cada usuario
sobre qué tipos de recursos (Pods, Secrets, Deployments) en qué Namespaces. El principio de
mínimo privilegio: cada persona tiene exactamente los permisos que necesita para su trabajo,
ni uno más.

Piensa en las tarjetas de acceso de una oficina moderna. No todo el mundo tiene llave del
servidor room, de la sala de dirección o del archivo de recursos humanos. El desarrollador
entra a su planta y a las salas comunes. El administrador de sistemas tiene acceso a la sala
de servidores. El director tiene acceso a todo. Las tarjetas son los RoleBindings, las
cerraduras son los Roles, y cada empleado es un usuario.

En este capítulo dominarás los cuatro objetos de RBAC: Role, ClusterRole, RoleBinding y
ClusterRoleBinding; aprenderás la diferencia entre permisos con scope de Namespace y permisos
a nivel de cluster, crearás usuarios con certificados X.509 y los asociarás a grupos, y
diseñarás una jerarquía de permisos para un equipo de ingeniería real.

---

## 1. ¿Qué es RBAC y por qué lo necesitamos?

### El problema que RBAC resuelve

Imagina esta situación: Eres el administrador de un cluster de Kubernetes en tu empresa. Hasta ahora, has sido el único con acceso al cluster, ejecutando todos los comandos con permisos de administrador:

```
┌─────────────────────────────────────────┐
│         Cluster Kubernetes              │
│  ┌────────────────────────────────┐    │
│  │  Pods, Deployments, Services   │    │
│  │  ConfigMaps, Secrets, etc.     │    │
│  └────────────────────────────────┘    │
│                 ▲                       │
│                 │                       │
│         ┌───────┴────────┐             │
│         │  Administrador  │ (Full)     │
│         │    (tú) 👑      │             │
│         └────────────────┘             │
└─────────────────────────────────────────┘
```

Pero ahora, el equipo está creciendo:
- **Desarrolladores** necesitan desplegar aplicaciones, ver logs, revisar el estado de sus pods
- **Equipo de DevOps** necesita gestionar configuraciones, secretos y monitoreo
- **Auditores** solo necesitan ver recursos, pero no modificarlos

¿Qué harías? ¿Les das a todos acceso de administrador? **¡Absolutamente NO!**

**¿Por qué es peligroso dar acceso total a todos?**
- Un desarrollador podría accidentalmente borrar recursos de producción
- No hay control sobre quién hace qué
- No cumple con principios de seguridad (mínimo privilegio)
- Dificulta la auditoría y compliance

### La solución: RBAC

**RBAC (Role-Based Access Control)** nos permite definir exactamente qué puede hacer cada usuario. Es como dar llaves diferentes a cada persona: el desarrollador tiene llave solo para su oficina, mientras que el gerente tiene llave maestra.

### ¿Qué significa "Role-Based"?

El concepto es simple:

1. **Defines un Rol** = Un conjunto de permisos
2. **Asignas el Rol a un Usuario** = El usuario obtiene esos permisos
3. **El Usuario ejecuta acciones** = Solo puede hacer lo que el rol permite

**Analogía del mundo real - Hospital:**

Piensa en un hospital:
- **Rol "Médico"**: Puede prescribir medicamentos, acceder a historiales médicos, realizar diagnósticos
- **Rol "Enfermero"**: Puede administrar medicamentos, tomar signos vitales, actualizar historiales
- **Rol "Recepcionista"**: Puede ver citas, registrar pacientes, pero NO acceder a historiales médicos

```
Hospital     = Cluster de Kubernetes
Roles        = Conjunto de permisos definidos
Personas     = Usuarios de Kubernetes
Acciones     = Comandos kubectl
```

### Componentes fundamentales de RBAC

RBAC en Kubernetes se compone de 4 elementos principales:

```
┌──────────────────────────────────────────────────────────┐
│                   Componentes RBAC                        │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1. ROLE / CLUSTERROLE                                   │
│     ┌─────────────────────────────────────┐             │
│     │ Define QUÉ se puede hacer:          │             │
│     │ • Resources: pods, services, etc.   │             │
│     │ • Verbs: get, list, create, delete  │             │
│     └─────────────────────────────────────┘             │
│                        ⬇                                  │
│  2. ROLEBINDING / CLUSTERROLEBINDING                     │
│     ┌─────────────────────────────────────┐             │
│     │ Conecta el Role con QUIÉN:          │             │
│     │ • Role: ¿Qué rol usar?              │             │
│     │ • Subject: ¿A quién aplicar?        │             │
│     └─────────────────────────────────────┘             │
│                        ⬇                                  │
│  3. SUBJECT (Usuario o Grupo)                            │
│     ┌─────────────────────────────────────┐             │
│     │ Define QUIÉN:                       │             │
│     │ • User: nombre del usuario          │             │
│     │ • Group: grupo de usuarios          │             │
│     └─────────────────────────────────────┘             │
│                        ⬇                                  │
│  4. RECURSOS Y ACCIONES                                  │
│     ┌─────────────────────────────────────┐             │
│     │ El usuario puede ahora:             │             │
│     │ kubectl get pods ✅                  │             │
│     │ kubectl delete deployment ❌         │             │
│     └─────────────────────────────────────┘             │
└──────────────────────────────────────────────────────────┘
```

### Beneficios de implementar RBAC

1. **Seguridad**: Principio de mínimo privilegio - cada usuario solo tiene lo necesario
2. **Auditoría**: Sabes exactamente quién puede hacer qué
3. **Organización**: Grupos facilitan la gestión de permisos en equipos grandes
4. **Compliance**: Cumplimiento con regulaciones y políticas de seguridad
5. **Prevención de errores**: Limita el daño que un error humano puede causar

### Ejemplo práctico inicial

Veamos un caso de uso real:

**Sin RBAC**:
```bash
# Todos usan las mismas credenciales de admin
kubectl delete namespace production  # 😱 ¡Cualquiera puede hacerlo!
```

**Con RBAC**:
```bash
# Usuario 'maria' del equipo de desarrollo
kubectl get pods -n development       # ✅ Permitido
kubectl delete pod -n development     # ✅ Permitido en su namespace
kubectl delete namespace production   # ❌ Forbidden: no tiene permisos
kubectl get secrets -n production     # ❌ Forbidden: no tiene permisos
```

> 📝 **Nota**: En el [Laboratorio 01](./laboratorios/lab-01-rbac-basico/) crearemos este escenario completo paso a paso.

---

## 2. Arquitectura de RBAC en Kubernetes

### Flujo de autorización

Cuando ejecutas un comando con `kubectl`, ocurre el siguiente proceso:

```
1. AUTENTICACIÓN
   kubectl get pods + certificado
   ⬇
   API Server verifica certificado
   
2. IDENTIFICACIÓN  
   Extrae del certificado:
   • CN = Usuario
   • O = Grupo
   
3. AUTORIZACIÓN (RBAC)
   ¿Qué Roles tiene el usuario?
   ¿Coincide con los permisos solicitados?
   
4. EJECUCIÓN
   ✅ Permiso concedido
   Ejecuta el comando
```

### Componentes en detalle

#### Roles y ClusterRoles

Define **QUÉ** se puede hacer:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: development    # ⚠️ Scope: solo este namespace
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]    # Acciones permitidas
```

| Aspecto | Role | ClusterRole |
|---------|------|-------------|
| **Scope** | Un namespace | Todo el cluster |
| **Namespace** | Obligatorio | No tiene |
| **Uso** | Equipos/proyectos | Admin global |

#### RoleBindings y ClusterRoleBindings

Define **QUIÉN** puede usar el Role:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: development
subjects:                   # QUIÉN
- kind: User
  name: maria
  apiGroup: rbac.authorization.k8s.io
roleRef:                    # QUÉ role
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

#### Subjects (Usuarios y Grupos)

```yaml
# Usuario
subjects:
- kind: User
  name: "maria@empresa.com"

# Grupo
subjects:
- kind: Group
  name: "developers"
```

> ⚠️ **Importante**: Kubernetes NO gestiona usuarios internamente. Los usuarios se autentican externamente (certificados, OIDC, etc.).

### Verificación de permisos

```bash
# Verificar permisos del usuario actual
kubectl auth can-i create pods

# Verificar permisos de otro usuario
kubectl auth can-i get pods --as maria
kubectl auth can-i delete pods --as maria -n development
```

---

## 3. Roles: Permisos a nivel de Namespace

Los **Roles** definen permisos que se aplican **únicamente dentro de un namespace específico**.

### ¿Cuándo usar un Role?

Usa un Role cuando:
- ✅ Permisos limitados a un namespace
- ✅ Equipos trabajando en proyectos aislados
- ✅ Aislar permisos entre entornos (dev, qa, prod)

### Anatomía de un Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
  namespace: development        # Crítico: namespace donde aplica
rules:
- apiGroups: [""]              # API Group
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch"]
```

### API Groups explicados

```bash
# Ver todos los recursos y sus API Groups
kubectl api-resources

# Ejemplos:
# pods, services     → apiGroups: [""]
# deployments        → apiGroups: ["apps"]
# jobs               → apiGroups: ["batch"]
# ingresses          → apiGroups: ["networking.k8s.io"]
```

### Verbs (Acciones)

| Verb | Comando kubectl | Descripción |
|------|----------------|-------------|
| `get` | `kubectl get pod mi-pod` | Obtener recurso específico |
| `list` | `kubectl get pods` | Listar recursos |
| `watch` | `kubectl get pods --watch` | Observar cambios |
| `create` | `kubectl create -f pod.yaml` | Crear recursos |
| `update` | `kubectl replace -f pod.yaml` | Reemplazar completo |
| `patch` | `kubectl patch pod mi-pod` | Actualizar parcial |
| `delete` | `kubectl delete pod mi-pod` | Eliminar recurso |

### Ejemplos prácticos

#### Ejemplo 1: Solo lectura

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: development
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
```

**Permite**:
```bash
kubectl get pods -n development          # ✅
kubectl logs mi-pod -n development       # ✅
```

**NO permite**:
```bash
kubectl delete pod mi-pod -n development # ❌
```

> 💾 Ver: [`ejemplos/01-role-pod-reader.yaml`](./ejemplos/01-role-pod-reader.yaml)

#### Ejemplo 2: Developer completo

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: development
rules:
# Pods: control total
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch", "create", "delete"]
# Deployments: control total
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
# Services: solo lectura
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]
```

#### Ejemplo 3: Config Manager

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: config-manager
  namespace: production
rules:
# ConfigMaps y Secrets: gestión completa
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
# Pods: solo lectura (para verificar configs)
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
```

> 💾 Ver: [`ejemplos/05-role-configmaps.yaml`](./ejemplos/05-role-configmaps.yaml)

### Permisos granulares con resourceNames

Restringir a recursos específicos:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: specific-configmap-editor
  namespace: production
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["app-config", "database-config"]  # Solo estos
  verbs: ["get", "update", "patch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["list"]  # Pero puede listar todos
```

> ⚠️ `resourceNames` solo funciona con get, update, patch, delete. NO con list, watch, create.

---

## 4. ClusterRoles: Permisos a nivel de Cluster

Los **ClusterRoles** aplican a **todo el cluster**, no solo a un namespace.

### ¿Cuándo usar ClusterRole?

- ✅ Permisos en múltiples/todos los namespaces
- ✅ Recursos no-namespaced (nodes, persistentvolumes)
- ✅ Roles reutilizables
- ✅ Administradores globales

### Diferencias: Role vs ClusterRole

```
ROLE
├─ Scope: Un namespace
├─ Requiere: metadata.namespace
└─ Recursos: Solo namespaced

CLUSTERROLE
├─ Scope: Todo el cluster
├─ NO tiene: namespace
└─ Recursos: Namespaced Y no-namespaced
```

### Anatomía de un ClusterRole

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-pod-reader
  # ⚠️ NO hay campo namespace
rules:
# Para recursos namespaced (aplica a TODOS los namespaces)
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
# Para recursos cluster-wide
- apiGroups: [""]
  resources: ["nodes", "namespaces"]
  verbs: ["get", "list"]
```

### Recursos no-namespaced

```bash
# Ver recursos no-namespaced
kubectl api-resources --namespaced=false

# Ejemplos:
# - nodes
# - namespaces
# - persistentvolumes
# - clusterroles
# - storageclasses
```

### Ejemplos prácticos

#### Ejemplo 1: Viewer global

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: global-viewer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["nodes", "namespaces"]
  verbs: ["get", "list"]
```

**Permite**:
```bash
kubectl get pods --all-namespaces  # ✅
kubectl get nodes                  # ✅
```

> 💾 Ver: [`ejemplos/02-clusterrole-pod-reader.yaml`](./ejemplos/02-clusterrole-pod-reader.yaml)

#### Ejemplo 2: Services Admin global

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: services-admin
rules:
- apiGroups: [""]
  resources: ["services", "endpoints"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

> 💾 Ver: [`ejemplos/07-clusterrole-services.yaml`](./ejemplos/07-clusterrole-services.yaml)

### ClusterRoles predefinidos

Kubernetes incluye ClusterRoles predefinidos:

```bash
kubectl get clusterroles

# Importantes:
# - cluster-admin  : Super administrador (TODO)
# - admin          : Admin de namespace
# - edit           : Editor
# - view           : Solo lectura
```

### Patrón: ClusterRole + RoleBinding

**Poderoso**: Usar un ClusterRole con RoleBinding para aplicar permisos solo en un namespace:

```yaml
# 1. ClusterRole reutilizable
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-manager
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "create", "delete"]
---
# 2. RoleBinding en namespace "dev"
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-pod-manager
  namespace: development
subjects:
- kind: User
  name: maria
roleRef:
  kind: ClusterRole      # ← ClusterRole
  name: pod-manager
---
# 3. RoleBinding en namespace "qa"
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: qa-pod-manager
  namespace: qa
subjects:
- kind: User
  name: juan
roleRef:
  kind: ClusterRole
  name: pod-manager
```

**Resultado**:
- `maria` puede gestionar pods SOLO en `development`
- `juan` puede gestionar pods SOLO en `qa`
- Mismo ClusterRole, diferentes namespaces

### Guía de decisión

```
¿Permisos para UN namespace?
  ├─ ¿Reutilizar el role?
  │   ├─ SÍ → ClusterRole + RoleBinding
  │   └─ NO → Role + RoleBinding
  └─ ¿Acceso en TODOS los namespaces?
      ├─ SÍ → ClusterRole + ClusterRoleBinding
      └─ ¿Recursos no-namespaced?
          └─ SÍ → ClusterRole + ClusterRoleBinding
```

---

## 5. RoleBindings: Conectando Roles con Usuarios

Los **RoleBindings** conectan Roles/ClusterRoles con Subjects (usuarios o grupos).

### Anatomía de un RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: development    # Namespace donde aplica
subjects:                   # QUIÉN obtiene permisos
- kind: User               # Tipo: User, Group, ServiceAccount
  name: maria
  apiGroup: rbac.authorization.k8s.io
roleRef:                    # QUÉ permisos
  kind: Role               # O ClusterRole
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Tipos de Subjects

#### Usuario

```yaml
subjects:
- kind: User
  name: maria@empresa.com
  apiGroup: rbac.authorization.k8s.io
```

#### Grupo

```yaml
subjects:
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io
```

#### Múltiples subjects

```yaml
subjects:
- kind: User
  name: maria
- kind: User
  name: juan
- kind: Group
  name: developers
```

### Ejemplos prácticos

#### Ejemplo 1: RoleBinding básico

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: maria-pod-reader
  namespace: development
subjects:
- kind: User
  name: maria
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

> �� Ver: [`ejemplos/03-rolebinding-basic.yaml`](./ejemplos/03-rolebinding-basic.yaml)

#### Ejemplo 2: RoleBinding para grupo

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developers-binding
  namespace: development
subjects:
- kind: Group
  name: developers          # Todos en el grupo
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

> �� Ver: [`ejemplos/06-rolebinding-group.yaml`](./ejemplos/06-rolebinding-group.yaml)

### ClusterRoleBinding

Para permisos globales:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: global-viewer-binding
  # NO tiene namespace
subjects:
- kind: User
  name: juan
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: global-viewer
  apiGroup: rbac.authorization.k8s.io
```

> 💾 Ver: [`ejemplos/04-clusterrolebinding-basic.yaml`](./ejemplos/04-clusterrolebinding-basic.yaml)

### ClusterRoleBinding a cluster-admin

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user-binding
subjects:
- kind: User
  name: admin-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin    # ⚠️ Acceso total
  apiGroup: rbac.authorization.k8s.io
```

> 💾 Ver: [`ejemplos/08-clusterrolebinding-admin.yaml`](./ejemplos/08-clusterrolebinding-admin.yaml)

### Verificar bindings

```bash
# Ver RoleBindings en un namespace
kubectl get rolebindings -n development

# Ver ClusterRoleBindings
kubectl get clusterrolebindings

# Describir un binding
kubectl describe rolebinding maria-pod-reader -n development

# Ver quién tiene cluster-admin
kubectl get clusterrolebindings -o json |   jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name'
```

---

## 6. Creación de Usuarios con Certificados

Kubernetes NO gestiona usuarios internamente. Debemos crearlos externamente usando certificados.

### Proceso completo

```
1. Generar clave privada (usuario)
   ↓
2. Crear Certificate Signing Request (CSR)
   ↓
3. Firmar CSR con CA del cluster
   ↓
4. Obtener certificado firmado
   ↓
5. Configurar kubectl con el certificado
```

### ¿Por qué certificados?

El API Server de Kubernetes tiene un **Certificate Authority (CA)** que firma certificados. Cuando presentas un certificado firmado por esta CA, Kubernetes:
1. ✅ Verifica que es válido
2. ✅ Extrae el usuario del campo CN (Common Name)
3. ✅ Extrae el grupo del campo O (Organization)
4. ✅ Te permite autenticarte

### Paso 1: Generar clave privada

```bash
# Generar clave privada para el usuario
openssl genrsa -out maria.key 2048
```

### Paso 2: Crear Certificate Signing Request (CSR)

```bash
# Crear CSR
openssl req -new   -key maria.key   -out maria.csr   -subj "/CN=maria/O=developers"
```

**Campos importantes**:
- `CN=maria` → Kubernetes lo usa como **nombre de usuario**
- `O=developers` → Kubernetes lo usa como **grupo**

> ⚠️ **Crítico**: El valor de CN será el nombre del usuario. El valor de O será el grupo.

### Paso 3: Obtener CA del cluster

```bash
# En minikube/AKS, obtener ubicación del CA
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt

# Ubicación común en minikube
# CA cert: ~/.minikube/ca.crt
# CA key:  ~/.minikube/ca.key
```

### Paso 4: Firmar el CSR con el CA

```bash
# Firmar CSR con el CA del cluster
openssl x509 -req   -in maria.csr   -CA ca.crt   -CAkey ca.key   -CAcreateserial   -out maria.crt   -days 365
```

**Resultado**: `maria.crt` es el certificado firmado válido para Kubernetes.

### Paso 5: Verificar el certificado

```bash
# Ver detalles del certificado
openssl x509 -in maria.crt -text -noout

# Verificar CN y O
openssl x509 -in maria.crt -noout -subject
# Output: subject=CN = maria, O = developers
```

### Script completo

> 💾 Ver script automatizado: [`ejemplos/09-generar-usuario-certificado.sh`](./ejemplos/09-generar-usuario-certificado.sh)

```bash
#!/bin/bash
# Generar certificado para usuario de Kubernetes

USERNAME="maria"
GROUP="developers"

# 1. Generar clave privada
openssl genrsa -out ${USERNAME}.key 2048

# 2. Crear CSR
openssl req -new   -key ${USERNAME}.key   -out ${USERNAME}.csr   -subj "/CN=${USERNAME}/O=${GROUP}"

# 3. Firmar con CA del cluster
openssl x509 -req   -in ${USERNAME}.csr   -CA ~/.minikube/ca.crt   -CAkey ~/.minikube/ca.key   -CAcreateserial   -out ${USERNAME}.crt   -days 365

echo "✅ Certificado creado: ${USERNAME}.crt"
echo "   Usuario: ${USERNAME}"
echo "   Grupo: ${GROUP}"
```

---

## 7. Configuración de kubectl para Usuarios

Una vez tenemos el certificado, debemos configurar kubectl para usarlo.

### Configuración de kubectl

kubectl usa el archivo `~/.kube/config` para gestionar múltiples usuarios y clusters.

### Paso 1: Agregar el cluster

```bash
kubectl config set-cluster minikube   --server=https://192.168.49.2:8443   --certificate-authority=~/.minikube/ca.crt
```

### Paso 2: Agregar credenciales del usuario

```bash
kubectl config set-credentials maria   --client-certificate=maria.crt   --client-key=maria.key
```

### Paso 3: Crear contexto

```bash
kubectl config set-context maria-context   --cluster=minikube   --user=maria   --namespace=development
```

### Paso 4: Usar el contexto

```bash
# Cambiar al nuevo contexto
kubectl config use-context maria-context

# Verificar contexto actual
kubectl config current-context

# Intentar comandos
kubectl get pods  # Si maria no tiene permisos → Forbidden
```

### Ver configuración

```bash
# Ver configuración completa
kubectl config view

# Ver solo contextos
kubectl config get-contexts

# Ver usuario actual
kubectl config current-context
```

### Estructura del kubeconfig

```yaml
apiVersion: v1
kind: Config
clusters:
- name: minikube
  cluster:
    server: https://192.168.49.2:8443
    certificate-authority: /home/user/.minikube/ca.crt
users:
- name: maria
  user:
    client-certificate: /path/to/maria.crt
    client-key: /path/to/maria.key
contexts:
- name: maria-context
  context:
    cluster: minikube
    user: maria
    namespace: development
current-context: maria-context
```

### Script completo

> 💾 Ver script: [`ejemplos/11-configurar-kubectl.sh`](./ejemplos/11-configurar-kubectl.sh)

```bash
#!/bin/bash
# Configurar kubectl para nuevo usuario

USERNAME="maria"
CLUSTER="minikube"
CONTEXT="${USERNAME}-context"

# Obtener API Server URL
API_SERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')

# 1. Set cluster
kubectl config set-cluster ${CLUSTER}   --server=${API_SERVER}   --certificate-authority=~/.minikube/ca.crt

# 2. Set credentials
kubectl config set-credentials ${USERNAME}   --client-certificate=${USERNAME}.crt   --client-key=${USERNAME}.key

# 3. Create context
kubectl config set-context ${CONTEXT}   --cluster=${CLUSTER}   --user=${USERNAME}   --namespace=development

# 4. Use context
kubectl config use-context ${CONTEXT}

echo "✅ Contexto configurado: ${CONTEXT}"
kubectl config current-context
```

---

## 8. Grupos: Organización de Permisos

Los **grupos** permiten asignar permisos a múltiples usuarios de una vez.

### ¿Qué es un grupo en Kubernetes?

Un grupo es simplemente un string en el campo **Organization (O)** del certificado. Kubernetes agrupa usuarios que comparten el mismo valor de O.

### Crear usuarios en un grupo

```bash
# Usuario 1 en grupo "developers"
openssl req -new   -key maria.key   -out maria.csr   -subj "/CN=maria/O=developers"

# Usuario 2 en el mismo grupo
openssl req -new   -key juan.key   -out juan.csr   -subj "/CN=juan/O=developers"

# Usuario 3 en grupo "devops"
openssl req -new   -key carlos.key   -out carlos.csr   -subj "/CN=carlos/O=devops"
```

### Asignar permisos a un grupo

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developers-binding
  namespace: development
subjects:
- kind: Group              # ← Tipo: Group
  name: developers         # ← Todos en grupo "developers"
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

**Resultado**:
- ✅ `maria` (grupo: developers) tiene permisos
- ✅ `juan` (grupo: developers) tiene permisos
- ❌ `carlos` (grupo: devops) NO tiene permisos

### Ejemplo práctico completo

**Escenario**: Equipo de desarrollo y equipo de DevOps

```yaml
# ClusterRole para developers
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer-role
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments", "services"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
# ClusterRole para DevOps
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: devops-role
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
---
# RoleBinding para grupo "developers"
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developers-binding
  namespace: development
subjects:
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
---
# ClusterRoleBinding para grupo "devops"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: devops-binding
subjects:
- kind: Group
  name: devops
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: devops-role
  apiGroup: rbac.authorization.k8s.io
```

### Múltiples grupos por usuario

Un usuario puede pertenecer a múltiples grupos:

```bash
# Usuario con múltiples grupos
openssl req -new   -key admin.key   -out admin.csr   -subj "/CN=admin/O=developers/O=admins"
```

### Ventajas de usar grupos

1. **Escalabilidad**: Agrega usuarios al grupo, automáticamente tienen permisos
2. **Mantenimiento**: Modifica permisos del grupo, afecta a todos
3. **Organización**: Refleja estructura de equipos
4. **Auditoría**: Fácil ver quién tiene qué permisos por equipo

---

## 9. Troubleshooting y Mejores Prácticas

### Errores comunes

#### Error: Forbidden

```bash
$ kubectl get pods
Error from server (Forbidden): pods is forbidden: 
User "maria" cannot list resource "pods" in API group "" in the namespace "default"
```

**Causas**:
1. Usuario no tiene RoleBinding
2. RoleBinding en namespace incorrecto
3. Role no incluye el verbo necesario
4. Role no incluye el recurso

**Solución**:
```bash
# Verificar permisos
kubectl auth can-i list pods --as maria

# Verificar RoleBindings
kubectl get rolebindings -A | grep maria

# Describir Role
kubectl describe role pod-reader -n development
```

#### Error: No resources found

```bash
$ kubectl get pods
No resources found in default namespace.
```

**NO es un error de permisos**, simplemente no hay pods.

#### Error: Certificado no válido

```bash
$ kubectl get pods
Unable to connect to the server: x509: certificate signed by unknown authority
```

**Causa**: Certificado no firmado por el CA del cluster

**Solución**:
```bash
# Verificar que usaste el CA correcto
kubectl config view --raw

# Re-firmar certificado
openssl x509 -req -in maria.csr   -CA ~/.minikube/ca.crt   -CAkey ~/.minikube/ca.key   -out maria.crt -days 365
```

### Mejores prácticas

#### 1. Principio de mínimo privilegio

```yaml
# ❌ MAL: Dar todos los permisos
verbs: ["*"]

# ✅ BIEN: Solo lo necesario
verbs: ["get", "list", "watch"]
```

#### 2. Usar grupos en lugar de usuarios individuales

```yaml
# ❌ MAL: Binding por cada usuario
subjects:
- kind: User
  name: maria
- kind: User
  name: juan
- kind: User
  name: pedro

# ✅ BIEN: Usar grupos
subjects:
- kind: Group
  name: developers
```

#### 3. Namespaces para aislar

```yaml
# ✅ BIEN: Roles por namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: development  # Solo en dev
```

#### 4. Evitar cluster-admin excepto admins

```yaml
# ⚠️ PELIGROSO: cluster-admin da acceso total
roleRef:
  kind: ClusterRole
  name: cluster-admin

# ✅ MEJOR: Roles específicos
roleRef:
  kind: ClusterRole
  name: view  # Solo lectura
```

#### 5. Auditar regularmente

```bash
# Ver todos los ClusterRoleBindings
kubectl get clusterrolebindings

# Ver quién tiene cluster-admin
kubectl get clusterrolebindings -o json |   jq -r '.items[] | select(.roleRef.name=="cluster-admin")'

# Listar todos los RoleBindings
kubectl get rolebindings -A
```

#### 6. Documentar permisos

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: development
  annotations:
    description: "Permisos para equipo de desarrollo"
    team: "Backend Team"
    owner: "devops@empresa.com"
```

#### 7. Usar ClusterRoles reutilizables

```yaml
# Define una vez
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-manager
rules:
  # ...

# Usa en múltiples namespaces
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-pod-manager
  namespace: dev
roleRef:
  kind: ClusterRole  # Reutiliza ClusterRole
  name: pod-manager
```

### Comandos útiles para troubleshooting

```bash
# Verificar permisos de usuario actual
kubectl auth can-i create pods
kubectl auth can-i delete deployments -n production

# Verificar permisos de otro usuario
kubectl auth can-i get pods --as maria
kubectl auth can-i delete pods --as maria -n dev

# Ver configuración actual
kubectl config view
kubectl config current-context

# Listar todos los contextos
kubectl config get-contexts

# Ver Roles y RoleBindings
kubectl get roles -A
kubectl get rolebindings -A
kubectl get clusterroles
kubectl get clusterrolebindings

# Describir permisos
kubectl describe role developer -n development
kubectl describe rolebinding maria-binding -n development
```

---

## 10. Resumen y Próximos Pasos

### Resumen del Módulo

En este módulo has aprendido:

1. ✅ **RBAC**: Control de acceso basado en roles
2. ✅ **Roles vs ClusterRoles**: Scope de namespace vs cluster
3. ✅ **RoleBindings**: Conectar roles con usuarios/grupos
4. ✅ **Usuarios con certificados**: Autenticación con OpenSSL
5. ✅ **Configuración kubectl**: Contexts y credenciales
6. ✅ **Grupos**: Organización de permisos a escala
7. ✅ **Troubleshooting**: Resolver errores comunes

### Fórmula RBAC

```
Role/ClusterRole (QUÉ)
        +
RoleBinding/ClusterRoleBinding (QUIÉN)
        =
Usuario/Grupo con permisos específicos
```

### Diferencia clave: Usuarios vs Service Accounts

| Aspecto | Usuarios (Módulo 17) | Service Accounts (Módulo 18) |
|---------|---------------------|------------------------------|
| **Para** | Personas | Aplicaciones/Pods |
| **Autenticación** | Certificados externos | Tokens internos |
| **Gestión** | Externa (OpenSSL, OIDC) | Interna (Kubernetes) |
| **Uso** | kubectl desde fuera | Pods dentro del cluster |
| **Ejemplo** | Desarrollador María | Pod de monitoring |

### Laboratorios

Practica lo aprendido en los laboratorios:

1. 🔬 **[Laboratorio 01: RBAC Básico](./laboratorios/lab-01-rbac-basico/)**
   - Crear usuario con certificados
   - Crear Role y RoleBinding
   - Probar permisos
   - Troubleshooting

2. 🔬 **[Laboratorio 02: RBAC Avanzado](./laboratorios/lab-02-rbac-avanzado/)**
   - ClusterRoles y ClusterRoleBindings
   - Grupos de usuarios
   - Múltiples namespaces
   - Escenarios reales

### Recursos adicionales

- 📚 [Documentación oficial de Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- 💾 [Ejemplos de este módulo](./ejemplos/)
- 🔗 [Guía de pabpereza.dev](https://pabpereza.dev/docs/cursos/kubernetes/usuarios_y_service_accounts_en_kubernetes_gestion_de_identidades)

### Próximo módulo

➡️ **Módulo 18: RBAC - Service Accounts**
- Identidades para pods y aplicaciones
- Tokens automáticos
- Permisos para aplicaciones dentro del cluster

---

## Apéndice: Referencia Rápida

### Comandos esenciales

```bash
# Usuarios y certificados
openssl genrsa -out user.key 2048
openssl req -new -key user.key -out user.csr -subj "/CN=user/O=group"
openssl x509 -req -in user.csr -CA ca.crt -CAkey ca.key -out user.crt

# kubectl config
kubectl config set-credentials user --client-certificate=user.crt --client-key=user.key
kubectl config set-context user-ctx --cluster=minikube --user=user
kubectl config use-context user-ctx

# Verificar permisos
kubectl auth can-i <verb> <resource>
kubectl auth can-i get pods --as user

# RBAC resources
kubectl get roles -A
kubectl get rolebindings -A
kubectl get clusterroles
kubectl get clusterrolebindings
kubectl describe role <name> -n <namespace>
```

### Plantillas YAML

**Role básico**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: <name>
  namespace: <namespace>
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

**RoleBinding básico**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: <name>
  namespace: <namespace>
subjects:
- kind: User
  name: <username>
roleRef:
  kind: Role
  name: <role-name>
  apiGroup: rbac.authorization.k8s.io
```

---

**¡Felicitaciones> "/media/Data/Source/Courses/K8S/area-2-arquitectura-kubernetes/modulo-17-rbac-users-groups/README_part1.md" << 'EOFPART1'
# Módulo 17: RBAC - Usuarios y Grupos en Kubernetes

## Tabla de Contenidos
1. [Introducción](#introducción-al-módulo)
2. [¿Qué es RBAC?](#1-qué-es-rbac-y-por-qué-lo-necesitamos)
3. [Arquitectura RBAC](#2-arquitectura-de-rbac-en-kubernetes)
4. [Roles](#3-roles-permisos-a-nivel-de-namespace)
5. [ClusterRoles](#4-clusterroles-permisos-a-nivel-de-cluster)
6. [RoleBindings](#5-rolebindings-conectando-roles-con-usuarios)
7. [Usuarios con Certificados](#6-creación-de-usuarios-con-certificados)
8. [Configuración kubectl](#7-configuración-de-kubectl-para-usuarios)
9. [Grupos en RBAC](#8-grupos-organización-de-permisos)
10. [Troubleshooting](#9-troubleshooting-y-mejores-prácticas)

---

## Introducción al Módulo

Bienvenidos al módulo 17, donde aprenderemos sobre **RBAC (Role-Based Access Control)** enfocado específicamente en **usuarios y grupos**.

### ¿Qué cubriremos?
- ✅ Usuarios y autenticación basada en certificados
- ✅ Grupos para organizar permisos
- ✅ Roles y ClusterRoles
- ✅ RoleBindings y ClusterRoleBindings

### ¿Qué NO cubriremos?
- ❌ Service Accounts (módulo 18)
- ❌ Autenticación de aplicaciones
- ❌ Tokens de pods

> **💡 Diferencia clave**: Usuarios = personas (kubectl). Service Accounts = aplicaciones (pods).

EOFPART1* Has completado el Módulo 17: RBAC - Usuarios y Grupos.

Ahora estás listo para gestionar el acceso de usuarios humanos a tu cluster de Kubernetes de forma segura y escalable.

## Resumen del Capítulo

Este capítulo cubrió los conceptos fundamentales de rbac — users y groups, desde la teoría hasta la práctica con ejemplos y manifiestos YAML aplicables en entornos reales. Los laboratorios en el directorio `laboratorios/` permiten practicar cada concepto, y el `RESUMEN-MODULO.md` sirve como guía de repaso rápido.
