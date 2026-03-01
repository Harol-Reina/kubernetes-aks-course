# Capítulo 30: RBAC y Control de Acceso

En el capítulo anterior pusimos nuestro cluster Kubernetes en la nube con AKS: control plane gestionado, node pools configurados, integración con servicios de Azure. El cluster está corriendo y las aplicaciones están desplegadas. Ahora surge la pregunta que en entornos de producción reales nunca puede ignorarse: ¿quién tiene acceso a qué?

En un cluster compartido entre varios equipos, sin controles de acceso adecuados, cualquier desarrollador con acceso puede ejecutar `kubectl delete namespace production` por error y borrar todo el entorno productivo. Un contratista externo que necesita acceso temporal para depurar un problema puede tener acceso completo de admin al cluster durante meses después de que su contrato terminó. Un pipeline de CI/CD que solo necesita hacer `kubectl apply` en un namespace específico puede tener permisos para leer Secrets en todos los namespaces. Estos son escenarios reales que ocurren en organizaciones que no han invertido tiempo en definir sus políticas de acceso.

La solución en AKS es una doble capa: Azure Active Directory verifica la identidad (¿quién eres?), y Kubernetes RBAC define las capacidades (¿qué puedes hacer y dónde?). Juntos forman un sistema de control de acceso de nivel empresarial que puede modelar desde "este desarrollador puede leer Pods en su namespace" hasta "este equipo de seguridad puede auditar todos los recursos del cluster sin modificar nada".

La analogía perfecta es el aeropuerto: Azure AD es el control de pasaportes en la entrada (verifica tu identidad), y Kubernetes RBAC es la tarjeta de embarque para una puerta específica (defines exactamente a qué vuelo, en qué terminal, puedes acceder).

En este capítulo aprenderás a integrar AKS con Azure Active Directory, a diseñar Roles y ClusterRoles siguiendo el principio de mínimo privilegio, a usar RoleBindings y ClusterRoleBindings para asignar permisos a usuarios, grupos y ServiceAccounts, a implementar aislamiento de namespaces por equipo, y a habilitar audit logging para cumplimiento y forensia de incidentes.

---

## ¿Por qué No Dar Admin a Todos?

En equipos pequeños con un solo administrador, dar acceso `cluster-admin` a todo el mundo puede parecer eficiente. Nadie pierde tiempo pidiendo permisos, nadie bloquea a nadie. El problema aparece cuando el equipo crece, cuando llegan contratistas externos, cuando el auditor de seguridad llega con su checklist, o cuando un desarrollador bienintencionado ejecuta el comando equivocado en el cluster equivocado.

### Incidentes Reales por Acceso Excesivo

Estos escenarios no son hipotéticos. Son patrones que se repiten en organizaciones que no invirtieron en RBAC a tiempo:

**Incidente 1: Borrado accidental de namespace de producción**

Un desarrollador de backend estaba haciendo limpieza en su namespace de desarrollo. Tenía configurado su kubeconfig apuntando a producción por un cambio previo que olvidó revertir. Ejecutó `kubectl delete namespace mi-app` con permisos de `cluster-admin`. El namespace de producción desapareció en 3 segundos, llevándose consigo Deployments, Services, PersistentVolumeClaims, ConfigMaps y Secrets. El proceso de recuperación desde backup tomó 4 horas. Costo estimado en downtime: $80,000.

**Incidente 2: Exposición de Secrets de producción**

Un contratista externo necesitaba acceso temporal para depurar un problema de rendimiento en el cluster. Le dieron acceso `cluster-admin` "solo por unos días". Seis meses después, cuando alguien revisó los RoleBindings, el contratista (que ya no trabajaba con la empresa) seguía teniendo acceso completo. Sus credenciales habían sido comprometidas sin que nadie lo supiera. Los Secrets con credenciales de base de datos y claves de API llevaban meses expuestos.

**Incidente 3: Pipeline de CI/CD con permisos excesivos**

Un pipeline de CI/CD necesitaba hacer `kubectl apply` en el namespace `production`. Por simplicidad, le dieron un token de ServiceAccount con `cluster-admin`. Semanas después, una vulnerabilidad en la imagen del pipeline permitió a un atacante usar ese token para exfiltrar Secrets de todos los namespaces, incluyendo credenciales de proveedores de pago.

### El Principio de Mínimo Privilegio

El **principio de mínimo privilegio** (Principle of Least Privilege, PoLP) establece que cada usuario, proceso o sistema debe tener acceso únicamente a los recursos que necesita para realizar su función, y nada más.

Aplicado a Kubernetes:

- Un desarrollador que trabaja en el namespace `equipo-frontend` solo necesita permisos en ese namespace.
- Un pipeline de CI/CD que despliega en `produccion` solo necesita `create`, `update` y `patch` en Deployments y Services de ese namespace específico. No necesita `delete`, no necesita acceso a Secrets.
- Un sistema de monitoreo que lee métricas solo necesita `get` y `list` en Pods y Nodes. No necesita crear ni modificar nada.
- Un auditor externo que revisa la configuración solo necesita `get` y `list` en todos los recursos. Nunca `create`, `update` o `delete`.

La pregunta correcta al asignar permisos no es "¿qué podría necesitar?", sino "¿qué necesita exactamente ahora mismo?". Los permisos pueden ampliarse cuando la necesidad sea real y documentada.

### Requisitos de Cumplimiento Normativo

En entornos corporativos, el control de acceso no es solo una buena práctica: es un requisito legal y contractual.

**SOC 2 (Service Organization Control 2)**: Requiere controles de acceso basados en roles, logs de auditoría de acceso, revisiones periódicas de permisos, y evidencia de que el acceso se revoca cuando ya no es necesario. Sin RBAC correctamente configurado, una auditoría SOC 2 fallará en los controles CC6.1 y CC6.2.

**GDPR (General Data Protection Regulation)**: El Artículo 25 exige "protección de datos desde el diseño y por defecto". Esto incluye restringir el acceso a datos personales solo al personal que los necesita. Un desarrollador de frontend no debería poder leer Secrets con datos de usuarios almacenados en el namespace de base de datos.

**PCI-DSS (Payment Card Industry Data Security Standard)**: El Requisito 7 exige "restringir el acceso a los componentes del sistema y datos del titular de tarjeta según la necesidad del negocio de conocerlos". Cualquier cluster que procese pagos debe implementar RBAC estricto o fallará una auditoría PCI.

**ISO 27001**: El control A.9.2.3 requiere la gestión de derechos de acceso privilegiado. El control A.9.4.1 exige restricción de acceso a información y funciones del sistema.

### Matriz de Riesgo: Acción × Nivel de Acceso

La siguiente tabla muestra el nivel de daño potencial según la acción y el nivel de acceso del actor:

```
┌─────────────────────────────────┬────────────┬──────────────┬────────────────┐
│ Acción                          │ view       │ edit         │ cluster-admin  │
├─────────────────────────────────┼────────────┼──────────────┼────────────────┤
│ kubectl delete namespace prod   │ Imposible  │ Imposible    │ CATASTROFICO   │
│ kubectl get secrets -A          │ Imposible  │ Imposible*   │ CRITICO        │
│ kubectl delete pod --all        │ Imposible  │ Solo su NS   │ CRITICO        │
│ kubectl apply deploy malicioso  │ Imposible  │ Solo su NS   │ CRITICO        │
│ kubectl exec en pod de BD       │ Imposible  │ Solo su NS   │ ALTO           │
│ kubectl get pods                │ Solo su NS │ Solo su NS   │ Bajo riesgo    │
│ kubectl logs                    │ Solo su NS │ Solo su NS   │ Bajo riesgo    │
└─────────────────────────────────┴────────────┴──────────────┴────────────────┘
* edit no puede leer Secrets por defecto en versiones modernas de K8s
```

La conclusión es directa: `cluster-admin` convierte cualquier error humano o compromiso de credenciales en un incidente de nivel catastrófico. RBAC granular convierte esos mismos errores en incidentes contenidos y recuperables.

---

## Modelo de Permisos: Quién + Qué + Dónde

RBAC en Kubernetes responde exactamente tres preguntas:

1. **¿Quién?** — El Subject (usuario, grupo o ServiceAccount)
2. **¿Qué puede hacer?** — Los verbos sobre recursos (definidos en un Role o ClusterRole)
3. **¿Dónde?** — El scope (namespace específico o todo el cluster)

La vinculación entre el "quién" y el "qué puede hacer en dónde" se realiza mediante un Binding:

```
┌─────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│   QUIEN     │     │      BINDING         │     │        ROL          │
│  (Subject)  │────▶│                      │────▶│    (Permisos)       │
├─────────────┤     ├──────────────────────┤     ├─────────────────────┤
│ • User      │     │ RoleBinding          │     │ Role                │
│ • Group     │     │   (namespace-scoped) │     │   (namespace-scoped)│
│ • SA        │     │                      │     │                     │
│             │     │ ClusterRoleBinding   │     │ ClusterRole         │
│             │     │   (cluster-scoped)   │     │   (cluster-scoped)  │
└─────────────┘     └──────────────────────┘     └─────────────────────┘
```

Existe una combinación especial: un `RoleBinding` puede referenciar un `ClusterRole`. Esto permite definir el rol una sola vez a nivel cluster (reutilizable) y aplicarlo con scope de namespace a través del Binding. Es el patrón más recomendado para roles comunes como "lector de pods" o "desarrollador" que se repiten en múltiples namespaces.

```
ClusterRole "pod-reader"   ←── definido una vez
        │
        ├── RoleBinding en namespace "equipo-a"  → aplica solo en equipo-a
        ├── RoleBinding en namespace "equipo-b"  → aplica solo en equipo-b
        └── RoleBinding en namespace "equipo-c"  → aplica solo en equipo-c
```

### Los Verbos: Qué Operaciones Están Permitidas

Los verbos en RBAC mapean directamente a operaciones HTTP sobre la API de Kubernetes:

```
┌────────────────┬───────────────────┬────────────────────────────────────────┐
│ Verbo RBAC     │ Método HTTP       │ Ejemplo de uso                         │
├────────────────┼───────────────────┼────────────────────────────────────────┤
│ get            │ GET (por nombre)  │ kubectl get pod mi-pod                 │
│ list           │ GET (colección)   │ kubectl get pods                       │
│ watch          │ GET + watch=true  │ kubectl get pods -w                    │
│ create         │ POST              │ kubectl apply -f pod.yaml (nuevo)      │
│ update         │ PUT               │ kubectl apply -f pod.yaml (existente)  │
│ patch          │ PATCH             │ kubectl patch deploy...                │
│ delete         │ DELETE (uno)      │ kubectl delete pod mi-pod              │
│ deletecollect. │ DELETE (colec.)   │ kubectl delete pods --all              │
│ exec           │ POST /exec        │ kubectl exec -it pod -- bash           │
│ portforward    │ POST /portforward │ kubectl port-forward pod 8080:80       │
│ proxy          │ GET/POST /proxy   │ kubectl proxy                          │
└────────────────┴───────────────────┴────────────────────────────────────────┘
```

Para acceso de solo lectura (monitoreo, auditoría), usa: `["get", "list", "watch"]`.
Para acceso de operador (despliegue, sin borrar), usa: `["get", "list", "watch", "create", "update", "patch"]`.
Para acceso completo en un namespace, usa todos los verbos.
Nunca otorgues `deletecollection` a menos que sea absolutamente necesario: permite borrar todos los recursos de un tipo con un solo comando.

### Jerarquía de Recursos en la API

Los recursos en Kubernetes están organizados en grupos de API. Esto importa porque el campo `apiGroups` en las rules de un Role debe coincidir exactamente:

```
API Core ("")          apps                    networking.k8s.io
├── pods               ├── deployments         ├── ingresses
├── services           ├── replicasets         └── networkpolicies
├── configmaps         ├── statefulsets
├── secrets            ├── daemonsets          batch
├── namespaces         └── controllerrevisions ├── jobs
├── nodes                                      └── cronjobs
├── persistentvolumes  rbac.authorization...
└── serviceaccounts    ├── roles               storage.k8s.io
                       ├── clusterroles        ├── storageclasses
                       ├── rolebindings        └── persistentvolumeclaims*
                       └── clusterrolebindings
```

*PersistentVolumeClaims están en el grupo core `""`, no en `storage.k8s.io`.

### Subresources: Permisos Granulares por Operación

Algunos recursos tienen subresources que permiten un control más fino:

```yaml
# Permite ejecutar comandos en pods, pero NO crear ni borrar pods
rules:
- apiGroups: [""]
  resources: ["pods/exec"]      # subresource
  verbs: ["create"]             # POST /exec requiere verbo "create"

# Permite leer logs pero no el pod completo
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]

# Permite port-forward sin más acceso
- apiGroups: [""]
  resources: ["pods/portforward"]
  verbs: ["create"]
```

Subresources importantes:
- `pods/exec` — kubectl exec (verbo: create)
- `pods/log` — kubectl logs (verbo: get)
- `pods/portforward` — kubectl port-forward (verbo: create)
- `pods/status` — leer/actualizar el status del pod
- `deployments/scale` — kubectl scale (verbo: update)
- `deployments/status` — leer el status del deployment

Esta granularidad permite escenarios como: "el equipo de soporte puede ver logs y hacer exec en pods de producción, pero no puede crear ni modificar Deployments".

---

## Conceptos de RBAC

**Role-Based Access Control (RBAC)** permite definir quién puede realizar qué acciones en qué recursos.

### Componentes de RBAC

```
User/Group/ServiceAccount → RoleBinding → Role → Resources
                         ↘ ClusterRoleBinding → ClusterRole → Cluster Resources
```

**Elementos principales:**
- **Subject**: Usuario, grupo o service account
- **Role/ClusterRole**: Conjunto de permisos
- **RoleBinding/ClusterRoleBinding**: Vincula subjects con roles

## Roles y ClusterRoles

### Roles Predefinidos de Kubernetes

Kubernetes incluye un conjunto de ClusterRoles predefinidos que cubren los casos de uso más comunes. Antes de crear roles personalizados, es conveniente saber qué está disponible por defecto:

```
┌──────────────────┬────────────────────────────────────────────────────────┐
│ ClusterRole      │ Permisos incluidos                                     │
├──────────────────┼────────────────────────────────────────────────────────┤
│ cluster-admin    │ Control total sobre todos los recursos del cluster.    │
│                  │ Equivale a root en Linux. Usar solo para admins        │
│                  │ de plataforma. NUNCA para pipelines o apps.            │
├──────────────────┼────────────────────────────────────────────────────────┤
│ admin            │ Acceso completo dentro de un namespace: puede crear    │
│                  │ y gestionar la mayoría de recursos incluyendo Roles y  │
│                  │ RoleBindings. No puede modificar recursos del cluster  │
│                  │ (Nodes, PersistentVolumes, Namespaces).                │
├──────────────────┼────────────────────────────────────────────────────────┤
│ edit             │ Puede crear, modificar y borrar la mayoría de recursos │
│                  │ en un namespace. No puede ver ni modificar Roles ni    │
│                  │ RoleBindings. No puede acceder a Secrets en K8s 1.24+.│
├──────────────────┼────────────────────────────────────────────────────────┤
│ view             │ Solo lectura (get, list, watch) sobre la mayoría de    │
│                  │ recursos en un namespace. No incluye Secrets ni Roles. │
└──────────────────┴────────────────────────────────────────────────────────┘
```

Consultar los roles predefinidos disponibles en el cluster:

```bash
kubectl get clusterroles | grep -v "system:"
```

```
NAME                                                CREATED AT
admin                                               2024-01-15T10:00:00Z
cluster-admin                                       2024-01-15T10:00:00Z
edit                                                2024-01-15T10:00:00Z
view                                                2024-01-15T10:00:00Z
```

Ver el detalle de un ClusterRole predefinido:

```bash
kubectl describe clusterrole edit
```

```
Name:         edit
Labels:       kubernetes.io/bootstrapping=rbac-defaults
              rbac.authorization.k8s.io/aggregate-to-admin=true
PolicyRule:
  Resources                           Non-Resource URLs  Verbs
  ---------                           -----------------  -----
  configmaps                          []                 [create delete deletecollection patch update get list watch]
  endpoints                           []                 [create delete deletecollection patch update get list watch]
  pods                                []                 [create delete deletecollection patch update get list watch]
  pods/attach                         []                 [create delete deletecollection patch update get list watch]
  pods/exec                           []                 [create delete deletecollection patch update get list watch]
  pods/portforward                    []                 [create delete deletecollection patch update get list watch]
  pods/proxy                          []                 [create delete deletecollection patch update get list watch]
  ...
```

### Role Aggregation con Labels

El mecanismo de agregación de roles permite construir ClusterRoles compuestos a partir de otros más pequeños. Esto es especialmente útil para extender los roles predefinidos sin modificarlos directamente:

```yaml
# ClusterRole base que se puede agregar al rol "view"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-view-extension
  labels:
    # Este label hace que los permisos se agreguen automáticamente
    # al ClusterRole "view" predefinido
    rbac.authorization.k8s.io/aggregate-to-view: "true"
rules:
- apiGroups: ["monitoring.coreos.com"]
  resources: ["servicemonitors", "prometheusrules"]
  verbs: ["get", "list", "watch"]
```

Los ClusterRoles predefinidos (`admin`, `edit`, `view`) ya tienen configurado el aggregationRule para recoger automáticamente cualquier role que tenga el label correspondiente. Cuando creas un ClusterRole con `aggregate-to-view: "true"`, todos los RoleBindings que ya usan `view` obtienen esos permisos adicionales automáticamente.

### Role (Namespace-scoped)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: desarrollo
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

### ClusterRole (Cluster-scoped)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["nodes", "pods"]
  verbs: ["get", "list"]
```

## RoleBindings y ClusterRoleBindings

### RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: desarrollo
subjects:
- kind: User
  name: juan@empresa.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### ClusterRoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-nodes
subjects:
- kind: Group
  name: infrastructure-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

## Azure AD Integration con AKS

En un cluster AKS de producción, los usuarios no se gestionan directamente en Kubernetes. Las credenciales de Kubernetes son efímeras y difíciles de auditar. La solución empresarial es delegar la autenticación a Azure Active Directory (Azure AD), que ya gestiona la identidad corporativa: usuarios, grupos, MFA, políticas de contraseñas, y revocación automática cuando un empleado deja la empresa.

### Arquitectura de la Integración

```
┌──────────────────┐    ┌─────────────────┐    ┌──────────────────────┐
│   Azure AD       │    │      AKS         │    │    K8s RBAC          │
│                  │    │                  │    │                      │
│  • Usuarios      │    │  • OIDC Provider  │    │  • ClusterRoles      │
│  • Grupos        │───▶│  • Token Webhook  │───▶│  • Roles             │
│  • MFA           │    │  • kubelogin      │    │  • ClusterRoleBind.  │
│  • Condicional   │    │  • Audit Logs     │    │  • RoleBindings      │
│  • SSO           │    │                  │    │                      │
└──────────────────┘    └─────────────────┘    └──────────────────────┘
         │                       │                        │
         │    1. Solicita token  │                        │
         │◀──────────────────────│                        │
         │    2. Azure AD autentica (MFA si config.)      │
         │──────────────────────▶│                        │
         │    3. Emite token JWT  │                        │
         │                       │    4. K8s valida token │
         │                       │────────────────────────▶
         │                       │    5. RBAC evalua permisos
         │                       │◀───────────────────────
```

El flujo es: el usuario se autentica con sus credenciales corporativas de Azure AD (incluyendo MFA si está configurado), Azure AD emite un token JWT, ese token se presenta a la API de AKS, AKS valida el token contra Azure AD, y luego Kubernetes RBAC evalúa qué puede hacer ese usuario basándose en sus ClusterRoleBindings.

### Habilitar Azure AD Integration en AKS

Si el cluster ya existe y no tiene Azure AD habilitado:

```bash
# Obtener el ID del grupo de administradores en Azure AD
az ad group show \
  --group "kubernetes-admins" \
  --query id \
  --output tsv
```

```
a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

```bash
# Habilitar Azure AD con grupo de administradores del cluster
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --enable-aad \
  --aad-admin-group-object-ids a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

```
AAD role propagation done[############################################]  100.0000%
{
  "aadProfile": {
    "adminGroupObjectIds": [
      "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    ],
    "enableAzureRbac": false,
    "managed": true,
    "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  },
  ...
}
```

Para clusters nuevos, habilitar Azure AD desde la creación:

```bash
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --node-count 3 \
  --enable-aad \
  --aad-admin-group-object-ids a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --generate-ssh-keys
```

### Obtener Credenciales y Autenticarse

```bash
# Obtener kubeconfig para el cluster con Azure AD
az aks get-credentials \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --overwrite-existing
```

La primera vez que ejecutes un comando kubectl, se abrirá un navegador para autenticarte con tus credenciales de Azure AD:

```bash
kubectl get nodes
```

```
To sign in, use a web browser to open the page https://microsoft.com/devicelogin
and enter the code ABCD1234 to authenticate.
```

### Instalación y Uso de kubelogin

`kubelogin` es el plugin de autenticación para AKS con Azure AD. Es necesario para contextos donde no hay navegador disponible (pipelines de CI/CD, servidores):

```bash
# Instalación en Linux
curl -LO https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip
unzip kubelogin-linux-amd64.zip
sudo mv bin/linux_amd64/kubelogin /usr/local/bin/

# Verificar instalación
kubelogin --version
```

```
kubelogin version
git hash: v0.1.0/...
```

```bash
# Convertir kubeconfig para usar kubelogin (modo non-interactive para pipelines)
kubelogin convert-kubeconfig -l azurecli

# O para service principals en CI/CD:
kubelogin convert-kubeconfig -l spn
export AAD_SERVICE_PRINCIPAL_CLIENT_ID=<client-id>
export AAD_SERVICE_PRINCIPAL_CLIENT_SECRET=<client-secret>
```

### Mapear Grupos de Azure AD a ClusterRoleBindings

Una vez que Azure AD está integrado, los grupos de Azure AD se usan como subjects en los RoleBindings de Kubernetes. El identificador del grupo es el Object ID de Azure AD:

```bash
# Obtener el Object ID de un grupo de Azure AD
az ad group show \
  --group "kubernetes-developers" \
  --query id \
  --output tsv
```

```
b2c3d4e5-f6a7-8901-bcde-f12345678901
```

```yaml
# Binding del grupo de desarrolladores al rol "edit" en el namespace "equipo-backend"
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developers-edit-backend
  namespace: equipo-backend
subjects:
- kind: Group
  # Usar el Object ID del grupo de Azure AD, no el nombre del grupo
  name: "b2c3d4e5-f6a7-8901-bcde-f12345678901"
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
```

```yaml
# Binding del equipo de SRE para acceso de solo lectura en todo el cluster
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: sre-team-view-cluster
subjects:
- kind: Group
  # Object ID del grupo "kubernetes-sre" en Azure AD
  name: "c3d4e5f6-a7b8-9012-cdef-123456789012"
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
```

Verificar que el binding funciona correctamente después de autenticarse como miembro del grupo:

```bash
# Verificar como usuario autenticado con Azure AD
kubectl auth whoami
```

```
ATTRIBUTE   VALUE
Username    juan.garcia@empresa.com
Groups      [b2c3d4e5-f6a7-8901-bcde-f12345678901 system:authenticated]
```

```bash
# Verificar permisos del usuario actual
kubectl auth can-i create deployments -n equipo-backend
```

```
yes
```

```bash
kubectl auth can-i create deployments -n equipo-frontend
```

```
no
```

---

## Patrones de Aislamiento con Namespaces

Los namespaces son la unidad fundamental de aislamiento en Kubernetes. Combinados con RBAC, permiten implementar diferentes estrategias de organización según las necesidades del equipo.

### Patron 1: Equipo por Namespace

Cada equipo de desarrollo tiene su propio namespace. Los desarrolladores tienen acceso completo a su namespace y ningún acceso a los demás.

```
cluster
├── namespace: equipo-backend     ← Equipo Backend (5 devs)
├── namespace: equipo-frontend    ← Equipo Frontend (3 devs)
├── namespace: equipo-data        ← Equipo Data (4 devs)
├── namespace: equipo-seguridad   ← Equipo Seguridad (2 devs, read-only en todo)
└── namespace: shared-services   ← Servicios compartidos (solo infra)
```

Este patrón es ideal cuando los equipos trabajan en microservicios independientes. El riesgo principal es la proliferación de namespaces y la necesidad de gestionar comunicación entre ellos con NetworkPolicies.

### Patron 2: Ambiente por Namespace

Los namespaces representan ambientes del ciclo de vida de software. Los mismos equipos tienen diferentes niveles de acceso según el ambiente:

```
cluster
├── namespace: desarrollo    ← Devs: edit, SRE: admin
├── namespace: staging       ← Devs: view, SRE: admin, QA: edit
└── namespace: produccion    ← Devs: view, SRE: admin (aprobacion requerida)
```

Este patrón es el más común. El riesgo es que los pipelines de CI/CD necesitan permisos en múltiples namespaces.

### Patron 3: Proyecto por Namespace

Cada proyecto de negocio o cliente tiene su propio namespace, incluyendo todos los ambientes del proyecto:

```
cluster
├── namespace: proyecto-ecommerce-dev
├── namespace: proyecto-ecommerce-prod
├── namespace: proyecto-crm-dev
└── namespace: proyecto-crm-prod
```

### Implementacion Completa de Aislamiento por Equipo

El siguiente conjunto de manifests implementa el aislamiento completo para un equipo. Incluye el namespace, los permisos RBAC, cuotas de recursos, y restricciones de red:

```yaml
# 1. Namespace del equipo
apiVersion: v1
kind: Namespace
metadata:
  name: equipo-backend
  labels:
    team: backend
    environment: production
```

```yaml
# 2. ResourceQuota para limitar el consumo del equipo
apiVersion: v1
kind: ResourceQuota
metadata:
  name: equipo-backend-quota
  namespace: equipo-backend
spec:
  hard:
    # Limite de Pods concurrentes
    pods: "50"
    # Limites de computo
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    # Limites de almacenamiento
    requests.storage: "100Gi"
    persistentvolumeclaims: "20"
    # Limites de objetos de configuracion
    configmaps: "50"
    secrets: "30"
    services: "20"
    services.loadbalancers: "3"
```

```yaml
# 3. LimitRange para valores por defecto de resources
apiVersion: v1
kind: LimitRange
metadata:
  name: equipo-backend-limitrange
  namespace: equipo-backend
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "2"
      memory: "2Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
```

```yaml
# 4. ClusterRole reutilizable para desarrolladores
# Se aplica en múltiples namespaces via RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer-standard
rules:
# Recursos de aplicacion
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets", "daemonsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
# Recursos core
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "endpoints"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
# Logs y exec (para debugging)
- apiGroups: [""]
  resources: ["pods/log", "pods/exec", "pods/portforward"]
  verbs: ["get", "create"]
# Ingress
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
# Sin permisos para: secrets, nodes, namespaces, RBAC
```

```yaml
# 5. RoleBinding que aplica el ClusterRole en el namespace del equipo
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: equipo-backend-developers
  namespace: equipo-backend
subjects:
- kind: Group
  # Object ID del grupo "kubernetes-backend-devs" en Azure AD
  name: "d4e5f6a7-b8c9-0123-defg-234567890123"
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: developer-standard
  apiGroup: rbac.authorization.k8s.io
```

```yaml
# 6. NetworkPolicy: aislamiento de red por defecto
# Bloquea todo el tráfico entrante y saliente por defecto
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: equipo-backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Permite tráfico dentro del mismo namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: equipo-backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}
  egress:
  - to:
    - podSelector: {}
  # Permite acceso a DNS del cluster
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

### Workflow de Cambio de Contexto entre Equipos

Cuando se trabaja con múltiples namespaces o clusters, es recomendable configurar contextos dedicados:

```bash
# Ver contextos disponibles
kubectl config get-contexts
```

```
CURRENT   NAME                                   CLUSTER          AUTHINFO
*         aks-k8s-course                         aks-k8s-course   clusterUser_...
          aks-k8s-course-equipo-backend          aks-k8s-course   clusterUser_...
          aks-k8s-course-equipo-frontend         aks-k8s-course   clusterUser_...
```

```bash
# Crear un contexto con namespace por defecto para un equipo
kubectl config set-context equipo-backend \
  --cluster=aks-k8s-course \
  --namespace=equipo-backend \
  --user=clusterUser_rg-kubernetes-course_aks-k8s-course

# Cambiar al contexto del equipo backend
kubectl config use-context equipo-backend

# Verificar el contexto actual
kubectl config current-context
```

```
equipo-backend
```

Con este contexto, todos los comandos kubectl operan en el namespace `equipo-backend` sin necesidad de especificar `-n equipo-backend`.

---

## Service Accounts

### Crear Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: desarrollo
```

### Usar Service Account en Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  namespace: desarrollo
spec:
  serviceAccountName: app-service-account
  containers:
  - name: app
    image: nginx:1.21
```

## Verificación de Permisos

Antes de desplegar aplicaciones o depurar problemas de acceso, es fundamental saber exactamente qué permisos tiene un usuario o ServiceAccount. Kubernetes proporciona herramientas integradas para esto.

### kubectl auth can-i

El comando más directo para verificar permisos. Responde "yes" o "no":

```bash
# ¿Puedo crear Deployments en el namespace produccion?
kubectl auth can-i create deployments -n produccion
```

```
no
```

```bash
# ¿Puedo listar Pods en el namespace donde trabajo?
kubectl auth can-i list pods -n equipo-backend
```

```
yes
```

```bash
# ¿Puedo borrar Secrets en cualquier namespace?
kubectl auth can-i delete secrets --all-namespaces
```

```
no
```

```bash
# Listar TODOS los permisos del usuario actual en un namespace
kubectl auth can-i --list -n equipo-backend
```

```
Resources                                       Non-Resource URLs  Resource Names  Verbs
pods                                            []                 []              [create delete deletecollection get list patch update watch]
pods/exec                                       []                 []              [create get]
pods/log                                        []                 []              [get]
deployments.apps                                []                 []              [create delete get list patch update watch]
services                                        []                 []              [create delete get list patch update watch]
configmaps                                      []                 []              [create delete get list patch update watch]
```

### kubectl auth whoami (Kubernetes 1.28+)

Muestra la identidad con la que el servidor API te reconoce:

```bash
kubectl auth whoami
```

```
ATTRIBUTE   VALUE
Username    juan.garcia@empresa.com
Groups      [b2c3d4e5-f6a7-8901-bcde-f12345678901 system:authenticated]
```

Para usuarios que no saben qué grupos de Azure AD están configurados en su token, este comando es invaluable para diagnóstico.

### Impersonacion para Testing

La impersonación permite verificar los permisos de otro usuario o ServiceAccount sin necesidad de tener sus credenciales. Solo los usuarios con permisos de `impersonate` pueden hacerlo (típicamente administradores del cluster):

```bash
# Verificar qué puede hacer el usuario "juan@empresa.com"
kubectl auth can-i --list \
  --as=juan@empresa.com \
  -n equipo-backend
```

```
Resources    Non-Resource URLs  Resource Names  Verbs
pods         []                 []              [get list watch]
configmaps   []                 []              [get list watch]
```

```bash
# Verificar permisos de una ServiceAccount específica
kubectl auth can-i create deployments \
  --as=system:serviceaccount:produccion:deploy-pipeline \
  -n produccion
```

```
yes
```

```bash
# Impersonar un grupo de Azure AD
kubectl auth can-i --list \
  --as=fake-user \
  --as-group=b2c3d4e5-f6a7-8901-bcde-f12345678901 \
  -n equipo-backend
```

La impersonación es la herramienta correcta para auditar permisos antes de hacer cambios a RoleBindings, y para verificar que un binding nuevo funciona como se espera sin necesidad de reloguear.

### Audit Logging: Rastrear Quien Hizo Qué

AKS tiene audit logging configurado a nivel de plataforma. Para acceder a los logs de auditoría:

```bash
# Habilitar envío de logs a Log Analytics (si no está habilitado)
az aks enable-addons \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --addons monitoring

# Los audit logs se encuentran en la categoría "kube-audit"
# Consultarlos en Azure Monitor / Log Analytics:
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query \
  "AzureDiagnostics | where Category == 'kube-audit' | limit 10"
```

Para ver quién borró un recurso específico:

```bash
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query \
  "AzureDiagnostics
  | where Category == 'kube-audit'
  | where requestObject_s contains 'delete'
  | where objectRef_resource_s == 'deployments'
  | project TimeGenerated, user_username_s, verb_s, objectRef_namespace_s, objectRef_name_s
  | order by TimeGenerated desc
  | limit 20"
```

---

## Laboratorio 3.1: Configurar RBAC

### Paso 1: Crear Usuarios de Prueba

```bash
# Crear namespace para pruebas
kubectl create namespace rbac-test

# Crear service accounts
kubectl create serviceaccount developer -n rbac-test
kubectl create serviceaccount viewer -n rbac-test
```

### Paso 2: Crear Roles

```bash
# Role para desarrolladores (permisos completos en namespace)
cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: rbac-test
  name: developer-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF

# Role para viewers (solo lectura)
cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: rbac-test
  name: viewer-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
EOF
```

### Paso 3: Crear RoleBindings

```bash
# RoleBinding para developer
cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: rbac-test
subjects:
- kind: ServiceAccount
  name: developer
  namespace: rbac-test
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
EOF

# RoleBinding para viewer
cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: viewer-binding
  namespace: rbac-test
subjects:
- kind: ServiceAccount
  name: viewer
  namespace: rbac-test
roleRef:
  kind: Role
  name: viewer-role
  apiGroup: rbac.authorization.k8s.io
EOF
```

### Paso 4: Probar Permisos

```bash
# Crear token para developer
DEVELOPER_TOKEN=$(kubectl create token developer -n rbac-test)

# Crear token para viewer
VIEWER_TOKEN=$(kubectl create token viewer -n rbac-test)

# Probar permisos de developer
kubectl auth can-i create pods --namespace=rbac-test --token=$DEVELOPER_TOKEN
kubectl auth can-i delete pods --namespace=rbac-test --token=$DEVELOPER_TOKEN

# Probar permisos de viewer
kubectl auth can-i create pods --namespace=rbac-test --token=$VIEWER_TOKEN
kubectl auth can-i get pods --namespace=rbac-test --token=$VIEWER_TOKEN

# Probar crear pod como developer
kubectl run test-pod --image=nginx --namespace=rbac-test --token=$DEVELOPER_TOKEN

# Intentar crear pod como viewer (debería fallar)
kubectl run test-pod-2 --image=nginx --namespace=rbac-test --token=$VIEWER_TOKEN
```

---

## Troubleshooting RBAC

Los errores de RBAC son frustrantes porque el mensaje de error de Kubernetes dice poco sobre la causa raíz. La respuesta estándar es `Error from server (Forbidden): ...` sin indicar qué permiso falta exactamente. Esta sección cubre los escenarios más frecuentes con diagnóstico paso a paso.

### Escenario 1: "Error from server (Forbidden)" — RoleBinding Faltante

**Sintoma:**

```bash
kubectl get pods -n produccion
```

```
Error from server (Forbidden): pods is forbidden: User "juan@empresa.com"
cannot list resource "pods" in API group "" in the namespace "produccion"
```

**Diagnostico:**

```bash
# Verificar si existe algún RoleBinding para este usuario en el namespace
kubectl get rolebindings -n produccion -o wide | grep juan
```

```
# No output — no hay binding para este usuario
```

```bash
# Verificar ClusterRoleBindings
kubectl get clusterrolebindings -o wide | grep juan
```

```
# No output tampoco
```

**Causa:** El usuario no tiene ningún RoleBinding ni ClusterRoleBinding que le otorgue permisos en ese namespace.

**Solucion:**

```bash
# Opcion 1: Darle el rol predefinido "view" en el namespace
kubectl create rolebinding juan-view-produccion \
  --clusterrole=view \
  --user=juan@empresa.com \
  --namespace=produccion
```

```
rolebinding.rbac.authorization.k8s.io/juan-view-produccion created
```

```bash
# Verificar que funciona
kubectl auth can-i list pods \
  --as=juan@empresa.com \
  -n produccion
```

```
yes
```

---

### Escenario 2: El Usuario Puede Listar pero No Crear

**Sintoma:** El usuario puede ejecutar `kubectl get pods` pero al intentar `kubectl apply` recibe Forbidden.

```bash
kubectl apply -f mi-deployment.yaml -n desarrollo
```

```
Error from server (Forbidden): deployments.apps is forbidden: User "ana@empresa.com"
cannot create resource "deployments" in API group "apps" in the namespace "desarrollo"
```

**Diagnostico:**

```bash
# Ver todos los permisos del usuario en el namespace
kubectl auth can-i --list \
  --as=ana@empresa.com \
  -n desarrollo
```

```
Resources       Non-Resource URLs  Resource Names  Verbs
pods            []                 []              [get list watch]
deployments     []                 []              [get list watch]
```

**Causa:** El usuario tiene el rol `view` (solo lectura) pero necesita el rol `edit` o un rol personalizado que incluya `create`.

**Solucion:**

```bash
# Verificar qué RoleBinding tiene actualmente
kubectl get rolebindings -n desarrollo -o wide | grep ana
```

```
ana-view-desarrollo   ClusterRole/view   17d   User/ana@empresa.com
```

```bash
# Actualizar el binding al rol edit
kubectl delete rolebinding ana-view-desarrollo -n desarrollo
kubectl create rolebinding ana-edit-desarrollo \
  --clusterrole=edit \
  --user=ana@empresa.com \
  --namespace=desarrollo
```

---

### Escenario 3: Funciona en Namespace A pero No en Namespace B

**Sintoma:** El usuario puede hacer `kubectl get pods -n desarrollo` pero no `kubectl get pods -n staging`.

**Diagnostico:**

```bash
# Ver todos los RoleBindings del usuario en todos los namespaces
kubectl get rolebindings --all-namespaces -o wide | grep ana@empresa.com
```

```
NAMESPACE    NAME                  ROLE            AGE   USERS
desarrollo   ana-edit-desarrollo   ClusterRole/edit  5d   ana@empresa.com
```

**Causa:** El RoleBinding existe solo en el namespace `desarrollo`, no en `staging`. Los RoleBindings son namespace-scoped: no se propagan automáticamente a otros namespaces.

**Solucion A** — Agregar binding en el namespace que falta:

```bash
kubectl create rolebinding ana-view-staging \
  --clusterrole=view \
  --user=ana@empresa.com \
  --namespace=staging
```

**Solucion B** — Si el usuario necesita el mismo acceso en muchos namespaces, usar un ClusterRoleBinding (con precaución, ya que aplica a todo el cluster):

```bash
# Solo si el acceso en todos los namespaces es apropiado para este usuario
kubectl create clusterrolebinding ana-view-all \
  --clusterrole=view \
  --user=ana@empresa.com
```

---

### Escenario 4: ServiceAccount No Puede Leer Secrets

**Sintoma:** Una aplicación que usa una ServiceAccount recibe errores al intentar leer Secrets del cluster (por ejemplo, un operador que gestiona configuración).

```
E0301 12:34:56.789012       1 reflector.go:138] pkg/mod/k8s.io/client-go@v0.26.0/
tools/cache/reflector.go:167: Failed to watch *v1.Secret:
failed to list *v1.Secret: secrets is forbidden:
User "system:serviceaccount:operators:config-operator" cannot list resource
"secrets" in API group "" in the namespace "produccion"
```

**Diagnostico:**

```bash
# Verificar los RoleBindings de la ServiceAccount
kubectl get rolebindings -n produccion -o wide | grep config-operator
kubectl get clusterrolebindings -o wide | grep config-operator
```

```
# Probablemente vacío o con un rol que no incluye secrets
```

```bash
# Verificar permisos actuales de la SA
kubectl auth can-i list secrets \
  --as=system:serviceaccount:operators:config-operator \
  -n produccion
```

```
no
```

**Causa:** La ServiceAccount no tiene un Role/RoleBinding que le permita acceder a Secrets. Recuerda que el acceso a Secrets es separado del acceso a otros recursos y debe concederse explícitamente.

**Solucion:**

```yaml
# Role con acceso específico a secrets
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: produccion
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch"]
  # Opcional: restringir a secrets específicos por nombre
  # resourceNames: ["app-credentials", "db-password"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: config-operator-secrets
  namespace: produccion
subjects:
- kind: ServiceAccount
  name: config-operator
  namespace: operators
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f secret-reader-binding.yaml

# Verificar
kubectl auth can-i list secrets \
  --as=system:serviceaccount:operators:config-operator \
  -n produccion
```

```
yes
```

---

### Escenario 5: Usuario Azure AD No Puede Autenticarse

**Sintoma:** Después de ejecutar `kubectl get nodes`, el proceso de autenticación falla o el token es rechazado.

```bash
kubectl get nodes
```

```
Error from server (Unauthorized): nodes is forbidden: User "" cannot list resource
"nodes" in API group "" at the cluster scope
```

O el navegador no se abre y el comando queda esperando.

**Diagnostico:**

```bash
# Verificar que kubelogin está instalado
kubelogin --version
```

```
bash: kubelogin: command not found
```

```bash
# Verificar la configuración del kubeconfig
kubectl config view --minify
```

```yaml
users:
- name: clusterUser_rg-kubernetes-course_aks-k8s-course
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - get-token
      - --login
      - devicecode
      command: kubelogin    # kubelogin no está instalado
```

**Causa:** `kubelogin` no está instalado o el kubeconfig no está correctamente configurado para usar el método de autenticación adecuado.

**Solucion:**

```bash
# 1. Instalar kubelogin
curl -LO https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip
unzip kubelogin-linux-amd64.zip
sudo mv bin/linux_amd64/kubelogin /usr/local/bin/
chmod +x /usr/local/bin/kubelogin

# 2. Regenerar las credenciales
az aks get-credentials \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --overwrite-existing

# 3. Para autenticación sin navegador (CI/CD), convertir a az CLI auth
kubelogin convert-kubeconfig -l azurecli

# 4. Intentar de nuevo
kubectl get nodes
```

---

### Escenario 6: Binding de Grupo Azure AD No Funciona

**Sintoma:** Un usuario es miembro del grupo de Azure AD pero no obtiene los permisos esperados cuando intenta acceder al cluster.

```bash
kubectl get pods -n equipo-backend
```

```
Error from server (Forbidden): pods is forbidden: User "pedro@empresa.com"
cannot list resource "pods" in API group "" in the namespace "equipo-backend"
```

A pesar de que existe este ClusterRoleBinding:

```yaml
subjects:
- kind: Group
  name: "d4e5f6a7-b8c9-0123-defg-234567890123"  # grupo azure-backend-devs
  apiGroup: rbac.authorization.k8s.io
```

**Diagnostico:**

```bash
# Ver el token de Pedro para verificar qué grupos incluye
kubectl auth whoami --as=pedro@empresa.com
# (requiere que el admin tenga permisos de impersonation)

# O pedirle a Pedro que ejecute:
kubectl auth whoami
```

```
ATTRIBUTE   VALUE
Username    pedro@empresa.com
Groups      [e5f6a7b8-c9d0-1234-efgh-345678901234 system:authenticated]
```

**Causa:** El Object ID del grupo en el kubeconfig no coincide con el Object ID real del grupo en Azure AD. El grupo en el token de Pedro es `e5f6a7b8-...` pero el binding usa `d4e5f6a7-...`.

**Solucion:**

```bash
# Verificar el Object ID correcto del grupo en Azure AD
az ad group show \
  --group "azure-backend-devs" \
  --query id \
  --output tsv
```

```
e5f6a7b8-c9d0-1234-efgh-345678901234
```

```bash
# Actualizar el ClusterRoleBinding con el ID correcto
kubectl patch clusterrolebinding developers-edit-backend \
  --type='json' \
  -p='[{"op": "replace", "path": "/subjects/0/name", "value": "e5f6a7b8-c9d0-1234-efgh-345678901234"}]'

# Verificar que ahora funciona
kubectl auth can-i list pods \
  --as=pedro@empresa.com \
  --as-group=e5f6a7b8-c9d0-1234-efgh-345678901234 \
  -n equipo-backend
```

```
yes
```

**Nota importante:** Después de que un usuario se une a un grupo en Azure AD, puede tardar hasta 60 minutos en que el cambio se refleje en los tokens emitidos. Si el binding es correcto pero el acceso sigue fallando, esperar y pedir al usuario que cierre sesión y vuelva a autenticarse para forzar la actualización del token.

---

## Resumen del Capítulo

### Conceptos Fundamentales Cubiertos

RBAC en Kubernetes es el sistema de autorización que responde tres preguntas: quién puede hacer qué y dónde. Los componentes principales son:

- **Subject**: El "quién" — puede ser un User (cuenta de Azure AD), un Group (grupo de Azure AD), o una ServiceAccount (identidad para procesos dentro del cluster).
- **Role / ClusterRole**: El "qué" — define los verbos permitidos sobre recursos de la API de Kubernetes. Role aplica a un namespace, ClusterRole aplica al cluster completo pero también puede usarse namespace-scoped vía RoleBinding.
- **RoleBinding / ClusterRoleBinding**: El "dónde y a quién" — vincula un Subject con un Role en un namespace específico (RoleBinding) o en todo el cluster (ClusterRoleBinding).

### Principios de Diseño

El principio de mínimo privilegio es la guía fundamental: otorgar únicamente los permisos que el actor necesita para su función actual, revisando y revocando accesos cuando ya no son necesarios. Esto reduce el radio de blast de cualquier incidente de seguridad.

La jerarquía correcta de permisos, del menor al mayor:

```
view  <  edit  <  admin  <  cluster-admin
(lectura)  (rw sin RBAC)  (rw + RBAC ns)  (rw todo)
```

Para la mayoría de los desarrolladores, `edit` en su namespace es suficiente. `cluster-admin` debe reservarse exclusivamente para administradores de plataforma con responsabilidad sobre el cluster completo.

### Azure AD + Kubernetes RBAC: La Doble Capa

En AKS de producción, la autenticación y la autorización son dos capas separadas:

1. **Autenticacion** (Azure AD): Verifica la identidad. Gestiona usuarios, grupos, MFA, y políticas de contraseñas corporativas. Integrado con kubelogin.
2. **Autorizacion** (Kubernetes RBAC): Define lo que la identidad verificada puede hacer. Los grupos de Azure AD se referencian en RoleBindings usando su Object ID.

Esta separación es poderosa: cuando un empleado deja la empresa y se desactiva su cuenta en Azure AD, automáticamente pierde acceso al cluster de Kubernetes sin necesidad de modificar ningún RoleBinding.

### Herramientas de Verificacion

```bash
# Mi identidad actual en el cluster
kubectl auth whoami

# ¿Puedo hacer X en el namespace Y?
kubectl auth can-i <verbo> <recurso> -n <namespace>

# Lista completa de mis permisos en un namespace
kubectl auth can-i --list -n <namespace>

# Verificar permisos de otro usuario (requiere permisos de impersonation)
kubectl auth can-i --list --as=<usuario> -n <namespace>

# Verificar permisos de una ServiceAccount
kubectl auth can-i <verbo> <recurso> \
  --as=system:serviceaccount:<namespace>:<nombre-sa>

# Ver todos los RoleBindings en un namespace
kubectl get rolebindings -n <namespace> -o wide

# Ver todos los ClusterRoleBindings
kubectl get clusterrolebindings -o wide
```

### Checklist de Seguridad RBAC

Antes de poner un cluster en producción, verificar:

- [ ] No existen ClusterRoleBindings con `cluster-admin` para usuarios individuales o pipelines
- [ ] Los grupos de Azure AD están correctamente mapeados con sus Object IDs reales
- [ ] Cada namespace tiene ResourceQuota y LimitRange configurados
- [ ] Los pipelines de CI/CD usan ServiceAccounts con permisos mínimos en su namespace específico
- [ ] Los Secrets no están accesibles para roles de desarrollo estándar (usar `view` o roles custom sin secrets)
- [ ] Se realizan revisiones periódicas de RoleBindings para detectar accesos obsoletos
- [ ] El audit logging está habilitado y los logs son accesibles para el equipo de seguridad

### Temas Relacionados

Este capítulo es la base para los siguientes temas de seguridad en Kubernetes:

- **Network Policies** (Capítulo 31): El control de acceso a nivel de red complementa RBAC. RBAC controla quién puede hablar con la API del cluster; NetworkPolicies controla qué Pods pueden comunicarse entre sí.
- **Pod Security Standards** (Capítulo 32): Controlan qué pueden hacer los Pods a nivel de sistema operativo (privileged, hostPID, capabilities).
- **Secrets Management** (Capítulo 33): La integración con Azure Key Vault para gestionar Secrets fuera del cluster reduce el alcance de lo que RBAC necesita proteger.
- **OPA/Gatekeeper** (Capítulo 34): Las políticas de admission control complementan RBAC con validaciones más complejas (por ejemplo, "todos los Deployments deben tener resource limits").

### Referencia Rápida de Comandos

```bash
# Crear Role desde comando
kubectl create role <nombre> \
  --verb=get,list,watch \
  --resource=pods,services \
  -n <namespace>

# Crear ClusterRole desde comando
kubectl create clusterrole <nombre> \
  --verb=get,list,watch \
  --resource=nodes,pods

# Crear RoleBinding desde comando
kubectl create rolebinding <nombre> \
  --clusterrole=<rol> \
  --user=<usuario> \
  -n <namespace>

# Crear RoleBinding para grupo
kubectl create rolebinding <nombre> \
  --clusterrole=<rol> \
  --group=<object-id-grupo-azure-ad> \
  -n <namespace>

# Crear RoleBinding para ServiceAccount
kubectl create rolebinding <nombre> \
  --clusterrole=<rol> \
  --serviceaccount=<namespace>:<nombre-sa> \
  -n <namespace>

# Ver permisos de un Role en detalle
kubectl describe role <nombre> -n <namespace>
kubectl describe clusterrole <nombre>

# Ver qué bindings usan un ClusterRole
kubectl get rolebindings,clusterrolebindings --all-namespaces \
  -o jsonpath='{range .items[?(@.roleRef.name=="<nombre-rol>")]}
  {.metadata.namespace}/{.metadata.name}{"\n"}{end}'
```
