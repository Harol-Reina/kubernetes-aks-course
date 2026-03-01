# Capítulo 33: Azure Key Vault

Los datos de aplicación ahora persisten de forma segura en Azure Disk y Azure Files. Hemos resuelto el problema del almacenamiento — pero queda una brecha de seguridad importante: las credenciales que usan esas aplicaciones para acceder a la base de datos, al servicio de pagos, a las APIs externas.

Kubernetes Secrets parecen seguros, pero tienen una debilidad fundamental: están codificados en base64, no cifrados. Cualquier persona con acceso de lectura al namespace puede ejecutar `kubectl get secret mi-secreto -o yaml` y ver el valor. Lo único que separa el texto plano del secreto es un simple `echo "cGFzc3dvcmQ=" | base64 -d`. Además, los Secrets de Kubernetes no tienen audit trail — no sabes quién accedió a qué secreto ni cuándo — ni rotación automática de contraseñas ni control de versiones. En un entorno regulado (PCI-DSS, SOC2, HIPAA), esto no es aceptable.

Azure Key Vault resuelve todos estos problemas de una vez: almacena secretos, claves y certificados con cifrado AES-256, registra cada acceso en logs de auditoría, permite rotación automática de secretos, y controla el acceso mediante políticas de identidad gestionada. La integración con Kubernetes se hace a través del CSI Secrets Store Driver y SecretProviderClass, que montan los secretos de Key Vault directamente como volúmenes en los Pods.

Imagina que los Kubernetes Secrets son un cajón con llave: cualquiera que tenga la llave del cajón (acceso al namespace) puede ver todo lo que hay dentro. Azure Key Vault es como una cámara acorazada bancaria: acceso registrado, llaves rotadas periódicamente, auditoría de cada entrada, y seguro contra robos con cifrado de nivel empresarial.

En este capítulo aprenderás a crear y configurar un Azure Key Vault desde la CLI, a instalar el CSI Secret Store Driver con Helm, a definir SecretProviderClass para mapear secretos de Key Vault a Pods, a configurar Managed Identities para autenticación sin contraseñas, y a implementar rotación automática de secretos en aplicaciones en ejecución.

---

## Los Kubernetes Secrets Son base64, No Encriptados

Antes de entender por qué necesitamos Azure Key Vault, hay que entender exactamente cuál es el problema con los Kubernetes Secrets. Muchos equipos asumen que si crean un Secret, ese valor está protegido. La realidad es diferente.

### Demostración del Problema

```bash
# Crear un Secret con una contraseña "secreta"
kubectl create secret generic db-creds \
  --from-literal=password=SuperSecret123

# El Secret existe en el cluster
kubectl get secret db-creds
# NAME        TYPE     DATA   AGE
# db-creds    Opaque   1      5s

# Obtener el valor "codificado"
kubectl get secret db-creds -o jsonpath='{.data.password}'
# U3VwZXJTZWNyZXQxMjM=

# Decodificar — cualquier persona con kubectl puede hacer esto
kubectl get secret db-creds -o jsonpath='{.data.password}' | base64 -d
# SuperSecret123    <- cualquiera con acceso al namespace puede leer esto

# Ver el YAML completo del Secret
kubectl get secret db-creds -o yaml
# apiVersion: v1
# data:
#   password: U3VwZXJTZWNyZXQxMjM=   <- solo base64
# kind: Secret
# metadata:
#   name: db-creds
#   namespace: default
# type: Opaque
```

Esto demuestra el problema central: **base64 es una codificación, no un cifrado**. Cualquier persona con permisos de `get` sobre Secrets en el namespace puede recuperar el valor en texto plano con un solo comando.

### Qué Es base64 (y Qué No Es)

base64 es un esquema de codificación binario-a-texto que convierte datos binarios arbitrarios en caracteres ASCII imprimibles. Se usa para transportar datos en formatos que solo aceptan texto, como JSON o YAML. Es completamente reversible sin ninguna clave secreta.

```bash
# base64 es solo una transformación reversible
echo "MiContrasenaSecreta" | base64
# TWlDb250cmFzZW5hU2VjcmV0YQ==

echo "TWlDb250cmFzZW5hU2VjcmV0YQ==" | base64 -d
# MiContrasenaSecreta

# No se necesita ninguna clave, ningún algoritmo secreto
# Cualquier herramienta puede hacer esto: openssl, python, node.js, etc.
python3 -c "import base64; print(base64.b64decode('TWlDb250cmFzZW5hU2VjcmV0YQ==').decode())"
# MiContrasenaSecreta
```

### Encryption at Rest en etcd

Kubernetes ofrece cifrado en reposo mediante `EncryptionConfiguration`. Cuando está habilitado, los Secrets se almacenan cifrados en etcd (la base de datos interna del cluster). Esto protege contra acceso físico al disco de etcd, pero **no resuelve el problema de acceso a través de kubectl**.

```yaml
# Ejemplo de EncryptionConfiguration (se aplica en el API server)
# /etc/kubernetes/enc/enc.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <base64-encoded-32-byte-key>
      - identity: {}
```

```bash
# Verificar si encryption at rest está habilitado
kubectl get pod kube-apiserver-<node> -n kube-system -o yaml | grep encryption
# --encryption-provider-config=/etc/kubernetes/enc/enc.yaml

# En AKS, etcd encryption está habilitado por defecto
# Pero esto no impide que kubectl get secret muestre el valor
```

El cifrado en reposo protege el medio de almacenamiento, pero una vez que el API server descifra el valor para responder a una petición kubectl, el resultado es texto plano. El problema de control de acceso persiste.

### Limitaciones de Kubernetes Secrets: Tabla Comparativa

Incluso con encryption at rest habilitado, los Kubernetes Secrets tienen limitaciones fundamentales que los hacen inadecuados para entornos regulados:

| Característica | Kubernetes Secrets | Azure Key Vault |
|---------------|-------------------|-----------------|
| Cifrado en reposo | base64 + etcd AES (opcional) | AES-256 / RSA siempre activo |
| Control de acceso | Kubernetes RBAC (namespace) | Azure RBAC + Access Policies |
| Audit trail | Kubernetes audit logs (si está configurado) | Key Vault audit logs (siempre activo) |
| Rotación automática | Manual (requiere redeploy) | Automática con notificaciones |
| Versionado | No — solo el valor actual | Sí — historial completo de versiones |
| Gestión centralizada | Por cluster | Por subscription / tenant |
| Soporte HSM | No | Sí (tier Premium) |
| Integración CI/CD | Limitada | GitHub Actions, Azure DevOps nativo |
| Notificaciones de expiración | No | Event Grid / email alerts |
| Conformidad regulatoria | Limitada | FIPS 140-2, PCI-DSS, SOC2, HIPAA |

### Por Qué Esto Importa en Entornos Reales

En un entorno de producción regulado, un auditor preguntará:

- "¿Quién accedió al secreto de la base de datos el 15 de enero a las 3:42 AM?" — **Kubernetes no puede responder esto sin audit logs configurados manualmente.**
- "¿Cuándo fue la última vez que se rotó la contraseña del servicio de pagos?" — **Kubernetes no rastrea esto.**
- "¿Puede demostrar que ningún desarrollador tiene acceso a los secretos de producción?" — **En Kubernetes, el acceso al namespace implica acceso a los Secrets.**

Azure Key Vault responde estas preguntas de forma nativa, con logs de auditoría inmutables, políticas de acceso granulares por identidad, y rotación automática programada.

---

## Crear y Configurar Azure Key Vault

### Conceptos Fundamentales

Azure Key Vault puede almacenar tres tipos de objetos:

- **Secrets**: Cadenas de texto — contraseñas, connection strings, API keys, tokens
- **Keys**: Claves criptográficas para cifrado/descifrado y firma digital. Pueden ser RSA o EC, y pueden residir en un HSM (Hardware Security Module) en el tier Premium.
- **Certificates**: Certificados TLS/SSL completos (clave privada + certificado) con renovación automática mediante Let's Encrypt u otras CAs.

### Crear el Key Vault con Azure CLI

```bash
# Variables de entorno para reutilización
RESOURCE_GROUP="rg-kubernetes-course"
LOCATION="eastus"
KEYVAULT_NAME="kv-k8s-course"         # Debe ser globalmente único (3-24 chars)
AKS_NAME="aks-k8s-course"

# Verificar que el nombre está disponible (los nombres son globalmente únicos)
az keyvault check-name --name $KEYVAULT_NAME
# {
#   "message": null,
#   "nameAvailable": true,
#   "reason": null
# }

# Crear Key Vault con autorización RBAC (recomendado sobre Access Policies)
az keyvault create \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --enable-rbac-authorization true \
  --sku standard
# {
#   "id": "/subscriptions/.../resourceGroups/rg-kubernetes-course/providers/Microsoft.KeyVault/vaults/kv-k8s-course",
#   "location": "eastus",
#   "name": "kv-k8s-course",
#   "properties": {
#     "enableRbacAuthorization": true,
#     "sku": { "family": "A", "name": "standard" },
#     ...
#   }
# }

# Verificar creación
az keyvault show --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP \
  --query "{name:name, location:location, rbac:properties.enableRbacAuthorization}" \
  -o table
# Name             Location    Rbac
# ---------------  ----------  ------
# kv-k8s-course    eastus      True
```

### Access Policies vs Azure RBAC

Key Vault ofrece dos modelos de autorización. Se recomienda RBAC para nuevos deployments:

**Access Policies (modelo antiguo)**:
```bash
# Access Policies se configuran por vault, no son Azure RBAC estándar
# Solo los "Key Vault Administrators" pueden modificarlas
# Limitación: no se integran con Azure Policy ni PIM

az keyvault set-policy \
  --name $KEYVAULT_NAME \
  --object-id <principal-id> \
  --secret-permissions get list
```

**Azure RBAC (modelo recomendado)**:
```bash
# Roles de Key Vault disponibles:
# - Key Vault Administrator        : gestión completa del vault
# - Key Vault Secrets Officer      : gestionar secretos (crear, eliminar, recuperar)
# - Key Vault Secrets User         : leer secretos (get, list) — para aplicaciones
# - Key Vault Reader               : ver metadatos pero no valores
# - Key Vault Crypto Officer       : gestionar claves
# - Key Vault Crypto User          : usar claves para operaciones criptográficas

# Obtener el scope (ID del Key Vault)
KEYVAULT_ID=$(az keyvault show --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP --query id -o tsv)

# Asignar rol "Key Vault Secrets User" a una identidad gestionada
IDENTITY_PRINCIPAL_ID="<principal-id-de-la-managed-identity>"

az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee-object-id $IDENTITY_PRINCIPAL_ID \
  --assignee-principal-type ServicePrincipal \
  --scope $KEYVAULT_ID
# {
#   "principalId": "...",
#   "roleDefinitionName": "Key Vault Secrets User",
#   "scope": "/subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/kv-k8s-course"
# }
```

### Agregar Secretos al Key Vault

```bash
# Agregar secrets individuales
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name "database-password" \
  --value "SuperSecret123!"
# {
#   "id": "https://kv-k8s-course.vault.azure.net/secrets/database-password/abc123...",
#   "name": "database-password",
#   "value": "SuperSecret123!"
# }

az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name "api-key" \
  --value "abcd1234-ef56-7890-abcd-1234567890ab"

az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name "redis-connection-string" \
  --value "redis://user:password@redis.example.com:6379"

# Agregar secret con expiración (buena práctica para tokens temporales)
EXPIRY_DATE=$(date -u -d "+90 days" '+%Y-%m-%dT%H:%M:%SZ')
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name "temp-admin-token" \
  --value "token-temporal-xyz" \
  --expires $EXPIRY_DATE

# Listar secretos (solo metadatos, no valores)
az keyvault secret list --vault-name $KEYVAULT_NAME -o table
# Name                    Enabled    Expires
# ----------------------  ---------  --------------------
# api-key                 True
# database-password       True
# redis-connection-string True
# temp-admin-token        True       2026-06-01T00:00:00Z

# Ver versiones de un secreto (Key Vault mantiene historial)
az keyvault secret list-versions \
  --vault-name $KEYVAULT_NAME \
  --name "database-password" \
  -o table
# Name               Created               Updated               Enabled
# -----------------  --------------------  --------------------  ---------
# database-password  2026-03-01T10:00:00Z  2026-03-01T10:00:00Z  True
```

### Configuración de Red: Acceso Público vs Private Endpoint

```bash
# Por defecto, Key Vault es accesible públicamente desde Internet
# Para producción, usar Private Endpoint (más seguro)

# Opción 1: Restringir acceso a IPs/VNets específicas
az keyvault update \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --default-action Deny \
  --bypass AzureServices

# Permitir la VNet del AKS cluster
AKS_VNET_ID=$(az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP \
  --query "agentPoolProfiles[0].vnetSubnetId" -o tsv | sed 's|/subnets/.*||')

az keyvault network-rule add \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $AKS_VNET_ID \
  --subnet "aks-subnet"

# Opción 2: Private Endpoint (recomendado para producción)
# El acceso al Key Vault solo es posible desde dentro de la VNet
# Requiere Azure Private DNS Zone para resolución de nombres
```

### Convenciones de Nomenclatura

```
kv-<proyecto>-<entorno>-<region>
kv-ecommerce-prod-eastus
kv-ecommerce-dev-eastus
kv-payments-prod-westeurope

Secretos dentro del vault:
<servicio>-<tipo>-<descriptor>
db-password-mysql-primary
db-password-redis-cache
api-key-stripe-production
cert-tls-frontend-wildcard
```

---

## CSI Secret Store Driver: Arquitectura

El CSI (Container Storage Interface) Secret Store Driver es el puente entre Azure Key Vault y los Pods de Kubernetes. Entender su arquitectura es fundamental para configurarlo correctamente y diagnosticar problemas.

### Diagrama de Arquitectura

```
┌──────────────────────────────────────────────────────────────────┐
│                          AKS Cluster                             │
│                                                                  │
│  ┌──────────────────────────────────┐                           │
│  │          Nodo Worker             │                           │
│  │                                  │                           │
│  │  ┌──────────────────────────┐   │                           │
│  │  │          Pod              │   │                           │
│  │  │  ┌────────────────────┐  │   │                           │
│  │  │  │   Contenedor App   │  │   │                           │
│  │  │  │                    │  │   │                           │
│  │  │  │  /mnt/secrets/     │  │   │                           │
│  │  │  │    database-pass   │  │   │                           │
│  │  │  │    api-key         │  │   │                           │
│  │  │  └────────────────────┘  │   │                           │
│  │  │  (CSI Volume montado)    │   │                           │
│  │  └──────────────┬───────────┘   │                           │
│  │                 │               │                           │
│  │  ┌──────────────▼───────────┐   │                           │
│  │  │  secrets-store-csi-driver │   │                           │
│  │  │  (DaemonSet - un pod      │   │                           │
│  │  │   por nodo)               │   │                           │
│  │  │                           │   │                           │
│  │  │  Lee SecretProviderClass  │   │                           │
│  │  │  ──────────────────────── │   │                           │
│  │  │  apiVersion: secrets-     │   │                           │
│  │  │    store.csi.x-k8s.io/v1 │   │                           │
│  │  │  kind: SecretProviderClass│   │                           │
│  │  └──────────────┬────────────┘   │                           │
│  └─────────────────│────────────────┘                           │
│                    │                                            │
│  ┌─────────────────▼─────────────────┐                         │
│  │    azure-keyvault-secrets-provider │                         │
│  │    (DaemonSet - plugin del driver) │                         │
│  └─────────────────┬─────────────────┘                         │
└────────────────────│──────────────────────────────────────────┘
                     │  HTTPS (Workload Identity / MSI)
                     │
          ┌──────────▼──────────┐
          │   Azure Key Vault   │
          │                     │
          │  Secrets:           │
          │    database-pass    │
          │    api-key          │
          │    redis-conn-str   │
          │                     │
          │  Keys:              │
          │    encryption-key   │
          │                     │
          │  Certificates:      │
          │    tls-frontend     │
          └─────────────────────┘
```

### Flujo de Funcionamiento

Cuando un Pod se crea con un volumen CSI de tipo `secrets-store.csi.k8s.io`, el siguiente flujo ocurre:

**1. Solicitud de montaje**
```
kubelet detecta el Pod → solicita montaje del volumen CSI
  → llama al secrets-store-csi-driver (DaemonSet en el mismo nodo)
```

**2. Lectura de SecretProviderClass**
```
CSI driver lee el objeto SecretProviderClass referenciado
  → obtiene: nombre del Key Vault, lista de secretos, tenant ID, configuración de identidad
```

**3. Autenticación con Azure Key Vault**
```
azure-keyvault-secrets-provider se autentica con Key Vault
  → usando Workload Identity (token OIDC del Service Account)
  → o usando Managed Identity del nodo
```

**4. Obtención de secretos**
```
Provider llama a la API de Key Vault: GET /secrets/{nombre}
  → Key Vault verifica permisos (RBAC / Access Policy)
  → retorna el valor del secreto
  → Key Vault registra el acceso en audit log
```

**5. Montaje del volumen**
```
Driver escribe los secretos como archivos en el sistema de archivos tmpfs del Pod
  → /mnt/secrets/database-password  (archivo con el valor)
  → /mnt/secrets/api-key            (archivo con el valor)
Volumen montado como read-only
```

**6. Sincronización a Kubernetes Secrets (opcional)**
```
Si secretObjects está configurado en SecretProviderClass:
  → Driver crea o actualiza un Kubernetes Secret con los valores
  → Las aplicaciones pueden usarlos como env vars mediante secretKeyRef
```

### Instalación con Helm

```bash
# Agregar repositorios Helm necesarios
helm repo add csi-secrets-store-provider-azure \
  https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm repo update

# Instalar el CSI Secrets Store Driver + Azure Provider
# (instala ambos componentes en un solo chart)
helm install csi-secrets-store-provider-azure \
  csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true \
  --set rotationPollInterval=2m

# Verificar que los DaemonSets están corriendo
kubectl get daemonset -n kube-system | grep -E "(secrets-store|csi)"
# NAME                                        DESIRED   CURRENT   READY   ...
# secrets-store-csi-driver                    3         3         3       ...
# csi-secrets-store-provider-azure            3         3         3       ...

kubectl get pods -n kube-system -l app=secrets-store-csi-driver
# NAME                               READY   STATUS    RESTARTS   AGE
# secrets-store-csi-driver-4xk9p    3/3     Running   0          2m
# secrets-store-csi-driver-7blrq    3/3     Running   0          2m
# secrets-store-csi-driver-n2s8t    3/3     Running   0          2m
```

### Instalación como AKS Addon (alternativa recomendada)

```bash
# Azure gestiona el ciclo de vida del addon (actualizaciones automáticas con AKS)
az aks enable-addons \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --addons azure-keyvault-secrets-provider

# Verificar addon habilitado
az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --query "addonProfiles.azureKeyvaultSecretsProvider.enabled"
# true

# El addon crea automáticamente una Managed Identity para el acceso a Key Vault
az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" -o tsv
# xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## SecretProviderClass en Detalle

`SecretProviderClass` es un Custom Resource (CRD) que define qué secretos obtener de Azure Key Vault, cómo autenticarse, y si sincronizarlos como Kubernetes Secrets. Es el objeto de configuración central de la integración.

### YAML Completo Anotado

```yaml
# Uso: kubectl apply -f secret-provider-class.yaml
#
# SecretProviderClass define la fuente de secretos (Azure Key Vault)
# y cómo mapearlos a archivos de volumen y/o Kubernetes Secrets.
#
# Namespace: desarrollo
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secrets
  namespace: desarrollo                # Debe estar en el mismo namespace que los Pods que lo usen
spec:
  provider: azure                      # Proveedor: azure | aws | gcp | vault (HashiCorp)

  parameters:
    # --- Identidad y Autenticación ---
    clientID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    # Client ID de la Managed Identity (User-Assigned) que tiene acceso al Key Vault.
    # Con Workload Identity, este es el clientId de la managed identity federada.
    # Con el addon de AKS, usar el clientId del addon (az aks show ... addonProfiles...)

    # --- Key Vault Configuration ---
    keyvaultName: "kv-k8s-course"     # Nombre del Azure Key Vault (sin .vault.azure.net)
    cloudName: ""                      # Vacío = AzurePublicCloud. Otros: AzureChinaCloud, AzureUSGovernmentCloud

    tenantId: "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    # Azure Active Directory Tenant ID donde reside el Key Vault.
    # Obtener con: az account show --query tenantId -o tsv

    # --- Lista de Secretos a Obtener ---
    objects: |
      array:
        - |
          objectName: database-password    # Nombre del secreto en Key Vault
          objectType: secret               # secret | key | cert
          objectVersion: ""               # "" = versión más reciente; o especificar ID de versión
          objectAlias: db-pass             # (Opcional) Nombre del archivo en el volumen montado
                                           # Si no se especifica, el archivo tiene el objectName
        - |
          objectName: api-key
          objectType: secret
          objectVersion: ""
        - |
          objectName: redis-connection-string
          objectType: secret
          objectVersion: ""               # Fijar versión específica para staging:
                                          # objectVersion: "abc123def456..."
        - |
          objectName: tls-frontend        # Certificado TLS completo
          objectType: cert                # Tipo cert monta: tls.key, tls.crt, fullchain.pem
          objectVersion: ""

  # --- Sincronización a Kubernetes Secrets (OPCIONAL) ---
  # Cuando está configurado, el CSI driver crea/actualiza Kubernetes Secrets
  # con los valores obtenidos de Key Vault. Esto permite usar secretKeyRef en env vars.
  # IMPORTANTE: El Pod DEBE montar el volumen CSI para que la sincronización ocurra.
  secretObjects:
  - secretName: app-db-secret            # Nombre del Kubernetes Secret que se creará
    type: Opaque                         # Tipo: Opaque | kubernetes.io/tls | kubernetes.io/dockerconfigjson
    data:
    - objectName: database-password      # Debe coincidir con objectName de la lista anterior
      key: db-password                   # Clave dentro del Kubernetes Secret
    - objectName: api-key
      key: api-key

  - secretName: tls-secret              # Secret separado para certificado TLS
    type: kubernetes.io/tls             # Tipo TLS requiere tls.crt y tls.key
    data:
    - objectName: tls-frontend
      key: tls.crt
    - objectName: tls-frontend
      key: tls.key
```

### Usar Secretos como Variables de Entorno

Para usar secretos como variables de entorno, la aplicación necesita:
1. El volumen CSI montado (trigger de sincronización)
2. `secretObjects` definido en el SecretProviderClass
3. `env.valueFrom.secretKeyRef` en el contenedor

```yaml
# Uso: kubectl apply -f pod-with-env-vars.yaml
#
# Pod que accede a secretos de Key Vault como variables de entorno.
# Requiere SecretProviderClass con secretObjects configurado.
apiVersion: v1
kind: Pod
metadata:
  name: app-with-keyvault-env
  namespace: desarrollo
  labels:
    app: mi-aplicacion
    azure.workload.identity/use: "true"   # Habilita Workload Identity para este Pod
spec:
  serviceAccountName: keyvault-sa         # Service Account anotado con Workload Identity
  containers:
  - name: app
    image: nginx:1.25
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
    env:
    # Variables de entorno desde Kubernetes Secret sincronizado por SecretProviderClass
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-db-secret             # Kubernetes Secret creado por secretObjects
          key: db-password
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: app-db-secret
          key: api-key
    volumeMounts:
    # El volumen CSI DEBE montarse aunque no se usen los archivos directamente
    # Su presencia activa la sincronización a Kubernetes Secrets
    - name: secrets-store-vol
      mountPath: "/mnt/secrets"
      readOnly: true
  volumes:
  - name: secrets-store-vol
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: azure-keyvault-secrets
```

### Usar Secretos como Archivos de Volumen

Cuando la aplicación lee directamente del sistema de archivos (más seguro, sin env vars):

```yaml
# Uso: kubectl apply -f pod-with-file-secrets.yaml
#
# Pod que lee secretos como archivos. Más seguro que env vars:
# los archivos no aparecen en 'kubectl describe pod' ni en logs.
apiVersion: v1
kind: Pod
metadata:
  name: app-with-file-secrets
  namespace: desarrollo
  labels:
    app: mi-aplicacion-segura
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: keyvault-sa
  containers:
  - name: app
    image: nginx:1.25
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
    command: ["/bin/sh", "-c"]
    args:
    - |
      # La aplicación lee el secreto desde el archivo
      DB_PASS=$(cat /mnt/secrets/db-pass)
      echo "Conectando a BD con la contraseña obtenida de Key Vault..."
      exec nginx -g 'daemon off;'
    volumeMounts:
    - name: secrets-store-vol
      mountPath: "/mnt/secrets"
      readOnly: true
  volumes:
  - name: secrets-store-vol
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: azure-keyvault-secrets
# Verificar archivos montados:
# kubectl exec app-with-file-secrets -n desarrollo -- ls -la /mnt/secrets/
# -r--r--r-- 1 root root 12 Mar 01 10:00 api-key
# -r--r--r-- 1 root root 14 Mar 01 10:00 db-pass
# -r--r--r-- 1 root root 45 Mar 01 10:00 redis-connection-string
```

### Múltiples Secretos en una SecretProviderClass

En aplicaciones reales, un Pod necesita acceder a múltiples secretos de distintas categorías:

```yaml
# Uso: kubectl apply -f secret-provider-complete.yaml
#
# SecretProviderClass completo para una aplicación e-commerce
# que necesita: BD, cache, APIs externas, y certificado TLS.
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: ecommerce-secrets
  namespace: produccion
spec:
  provider: azure
  parameters:
    clientID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    keyvaultName: "kv-ecommerce-prod-eastus"
    cloudName: ""
    tenantId: "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    objects: |
      array:
        - |
          objectName: db-mysql-primary-password
          objectType: secret
          objectAlias: db-primary-pass
        - |
          objectName: db-mysql-replica-password
          objectType: secret
          objectAlias: db-replica-pass
        - |
          objectName: redis-cache-password
          objectType: secret
          objectAlias: redis-pass
        - |
          objectName: stripe-api-key-production
          objectType: secret
          objectAlias: stripe-key
        - |
          objectName: sendgrid-api-key
          objectType: secret
          objectAlias: sendgrid-key
        - |
          objectName: jwt-signing-secret
          objectType: secret
          objectAlias: jwt-secret
        - |
          objectName: tls-ecommerce-wildcard
          objectType: cert
          objectAlias: tls-cert
  secretObjects:
  - secretName: ecommerce-db-secrets
    type: Opaque
    data:
    - objectName: db-primary-pass
      key: primary-password
    - objectName: db-replica-pass
      key: replica-password
  - secretName: ecommerce-api-secrets
    type: Opaque
    data:
    - objectName: stripe-key
      key: stripe-api-key
    - objectName: sendgrid-key
      key: sendgrid-api-key
    - objectName: jwt-secret
      key: jwt-signing-secret
  - secretName: ecommerce-tls
    type: kubernetes.io/tls
    data:
    - objectName: tls-cert
      key: tls.crt
    - objectName: tls-cert
      key: tls.key
```

---

## Autenticación: Managed Identity vs Workload Identity

La autenticación es el aspecto más crítico de la integración con Key Vault. El CSI driver necesita credenciales para llamar a la API de Key Vault, pero no podemos almacenar esas credenciales en el cluster — eso reproduciría el problema original.

### La Evolución del Modelo de Autenticación

```
Historial:
──────────────────────────────────────────────────────────────────
2019-2021  Service Principal + Secret  ← credencial en el cluster
2020-2022  Pod Identity (AAD Pod Identity) ← deprecado en 2022
2022+      Managed Identity del nodo      ← aún válido pero limitado
2022+      Workload Identity              ← RECOMENDADO ACTUAL
──────────────────────────────────────────────────────────────────
```

**Pod Identity (DEPRECADO — no usar en nuevos proyectos)**:
- Usaba un controlador personalizado que interceptaba las peticiones de metadatos del nodo
- Requería `aadpodidbinding` label en los Pods
- Problemático en AKS 1.24+, retirado oficialmente

**Managed Identity del Nodo (System-Assigned)**:
- Todos los Pods en el nodo comparten la misma identidad
- Más simple pero sin aislamiento: un Pod comprometido puede acceder a todos los Key Vaults a los que tiene acceso el nodo
- Útil para escenarios de dev/test simples

**Workload Identity (RECOMENDADO)**:
- Cada Service Account tiene su propia identidad Azure
- Aislamiento completo: cada microservicio tiene solo los permisos que necesita
- Basado en OIDC (estándar industrial), no en interceptación de tráfico
- Compatible con todas las versiones recientes de AKS

### Configurar Workload Identity Paso a Paso

```bash
# =============================================
# Paso 1: Habilitar Workload Identity en AKS
# =============================================
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --enable-oidc-issuer \
  --enable-workload-identity

# Obtener el OIDC Issuer URL del cluster
OIDC_ISSUER=$(az aks show \
  --name $AKS_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "oidcIssuerProfile.issuerUrl" -o tsv)

echo "OIDC Issuer: $OIDC_ISSUER"
# OIDC Issuer: https://eastus.oic.prod-aks.azure.com/yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/

# =============================================
# Paso 2: Crear User-Assigned Managed Identity
# =============================================
IDENTITY_NAME="keyvault-identity"

az identity create \
  --name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

IDENTITY_CLIENT_ID=$(az identity show \
  --name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query clientId -o tsv)

IDENTITY_PRINCIPAL_ID=$(az identity show \
  --name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query principalId -o tsv)

echo "Identity Client ID: $IDENTITY_CLIENT_ID"
echo "Identity Principal ID: $IDENTITY_PRINCIPAL_ID"

# =============================================
# Paso 3: Asignar permisos en Key Vault
# =============================================
KEYVAULT_ID=$(az keyvault show \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

# Rol "Key Vault Secrets User" = permisos de solo lectura (get + list)
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee-object-id $IDENTITY_PRINCIPAL_ID \
  --assignee-principal-type ServicePrincipal \
  --scope $KEYVAULT_ID

# Verificar asignación
az role assignment list --scope $KEYVAULT_ID -o table
# Principal              Role                    Scope
# ---------------------  ----------------------  -------
# keyvault-identity      Key Vault Secrets User  .../kv-k8s-course

# =============================================
# Paso 4: Crear Federated Credential (vínculo OIDC)
# =============================================
# Este es el paso clave: vincula el Service Account de Kubernetes
# con la Managed Identity de Azure mediante el protocolo OIDC.

NAMESPACE="desarrollo"
SERVICE_ACCOUNT_NAME="keyvault-sa"

az identity federated-credential create \
  --name "keyvault-fed-cred" \
  --identity-name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --issuer $OIDC_ISSUER \
  --subject "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT_NAME}"
# El subject sigue el formato: system:serviceaccount:<namespace>:<sa-name>
# Esto significa: "el SA 'keyvault-sa' del namespace 'desarrollo' en ESTE cluster"

# Verificar credencial federada
az identity federated-credential list \
  --identity-name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP -o table
# Name               Issuer                           Subject
# -----------------  --------------------------------  ----------------------------------------
# keyvault-fed-cred  https://eastus.oic.prod-aks...   system:serviceaccount:desarrollo:keyvault-sa

# =============================================
# Paso 5: Crear Service Account en Kubernetes
# =============================================
kubectl create namespace $NAMESPACE 2>/dev/null || true

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: keyvault-sa
  namespace: desarrollo
  annotations:
    # Esta anotación vincula el SA con la Managed Identity de Azure
    azure.workload.identity/client-id: "${IDENTITY_CLIENT_ID}"
  labels:
    azure.workload.identity/use: "true"
EOF

# Verificar Service Account
kubectl describe serviceaccount keyvault-sa -n desarrollo
# Name:                keyvault-sa
# Namespace:           desarrollo
# Annotations:         azure.workload.identity/client-id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# Labels:              azure.workload.identity/use=true

# =============================================
# Paso 6: Verificar la cadena de autenticación
# =============================================
# Crear un Pod de prueba con Workload Identity
kubectl run wi-test \
  --image=mcr.microsoft.com/azure-cli \
  --namespace=desarrollo \
  --overrides='{
    "spec": {
      "serviceAccountName": "keyvault-sa",
      "containers": [{
        "name": "wi-test",
        "image": "mcr.microsoft.com/azure-cli",
        "command": ["sleep", "3600"],
        "labels": {"azure.workload.identity/use": "true"}
      }]
    }
  }'

# En el Pod, las siguientes variables de entorno son inyectadas automáticamente:
# AZURE_CLIENT_ID        = clientId de la managed identity
# AZURE_TENANT_ID        = tenantId del AD
# AZURE_FEDERATED_TOKEN_FILE = ruta al token OIDC
# El SDK de Azure y az CLI las usan automáticamente para autenticarse

kubectl exec wi-test -n desarrollo -- az login --federated-token $(cat $AZURE_FEDERATED_TOKEN_FILE) \
  --service-principal --username $AZURE_CLIENT_ID --tenant $AZURE_TENANT_ID
kubectl exec wi-test -n desarrollo -- az keyvault secret show \
  --vault-name $KEYVAULT_NAME --name database-password
# Si funciona: la cadena Workload Identity está correctamente configurada

kubectl delete pod wi-test -n desarrollo
```

### Diagrama del Flujo de Autenticación Workload Identity

```
┌─────────────────────────────────────────────────────────────────────┐
│ Kubernetes Pod (serviceAccountName: keyvault-sa)                    │
│                                                                     │
│  Token OIDC proyectado en:                                          │
│  /var/run/secrets/azure/tokens/azure-identity-token                │
│  (emitido por el OIDC Issuer del AKS cluster)                      │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ 1. Token OIDC del Service Account
                           ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Azure AD (Microsoft Entra ID)                                        │
│                                                                      │
│  2. Validar token contra OIDC Issuer URL del cluster                │
│  3. Verificar: issuer + subject (system:serviceaccount:ns:sa-name)  │
│  4. Federated Credential hace match → emitir Access Token Azure     │
└──────────────────────────┬───────────────────────────────────────────┘
                           │ 5. Access Token de la Managed Identity
                           ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Azure Key Vault                                                      │
│                                                                      │
│  6. Validar Access Token                                             │
│  7. Verificar RBAC: ¿tiene rol "Key Vault Secrets User"?            │
│  8. Retornar valor del secreto                                       │
│  9. Registrar acceso en audit log                                    │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Rotación Automática de Secrets

Una de las ventajas clave de Azure Key Vault sobre Kubernetes Secrets es la rotación automática. El CSI driver puede detectar cuando un secreto en Key Vault ha sido actualizado y reflejar el cambio en los Pods en ejecución sin necesidad de reiniciarlos.

### Habilitar Rotación en el CSI Driver

```bash
# Al instalar con Helm, habilitar rotación
helm install csi-secrets-store-provider-azure \
  csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true \
  --set rotationPollInterval=2m        # Intervalo de polling: cada 2 minutos

# Si ya está instalado, actualizar con helm upgrade
helm upgrade csi-secrets-store-provider-azure \
  csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true \
  --set rotationPollInterval=2m

# Verificar que la rotación está habilitada
kubectl get pods -n kube-system -l app=secrets-store-csi-driver -o yaml | \
  grep -A2 "enableSecretRotation"
```

### Cómo Funciona la Rotación

```
Ciclo de rotación (cada rotationPollInterval):

1. CSI driver verifica la última versión del secreto en Key Vault
   GET https://kv-k8s-course.vault.azure.net/secrets/database-password
   Response: version=abc123 (nueva versión detectada)

2. Si la versión cambió:
   - Actualiza el archivo en el volumen montado del Pod
   - Actualiza el Kubernetes Secret (si secretObjects está configurado)

3. La aplicación detecta el cambio:
   - Archivos de volumen: la aplicación que lea el archivo verá el nuevo valor
     en la próxima lectura (sin reinicio del Pod)
   - Variables de entorno: NO se actualizan automáticamente
     (las env vars se cargan en el inicio del proceso)
```

### Actualizar un Secreto en Key Vault

```bash
# Rotar el secreto en Azure Key Vault
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name "database-password" \
  --value "NuevaSuperContrasena456!"
# Esto crea una nueva versión del secreto

# La versión anterior sigue existiendo (historial completo)
az keyvault secret list-versions \
  --vault-name $KEYVAULT_NAME \
  --name "database-password" -o table
# Name               Created               Enabled   Expires
# -----------------  --------------------  --------  -------
# database-password  2026-03-01T10:00:00Z  False     (versión anterior, deshabilitada)
# database-password  2026-03-01T15:30:00Z  True      (nueva versión activa)

# Después del rotationPollInterval (2 minutos), verificar que el Pod tiene el nuevo valor
kubectl exec <pod-name> -n desarrollo -- cat /mnt/secrets/database-password
# NuevaSuperContrasena456!
```

### Estrategias de Consumo para Rotación

**Aplicaciones que leen archivos (mejor estrategia)**:
```python
# La aplicación lee el archivo en cada operación, no en el inicio
# Esto permite detectar rotaciones sin reiniciar el proceso
import os

def get_db_password():
    with open('/mnt/secrets/database-password', 'r') as f:
        return f.read().strip()

# En cada conexión a la BD:
password = get_db_password()  # Siempre obtiene el valor actual del archivo
```

**Aplicaciones que usan env vars (requieren reinicio)**:
```bash
# Las variables de entorno se cargan en el inicio del proceso
# Para consumir el valor rotado, el Pod debe reiniciarse
kubectl rollout restart deployment/mi-aplicacion -n desarrollo

# Alternativa: usar un sidecar que restarted el proceso principal
# cuando detecta cambio en el archivo del secreto
```

**Configurar alertas de expiración en Key Vault**:
```bash
# Configurar notificación por email cuando un secreto está próximo a expirar
# (requiere Azure Monitor / Event Grid)
az monitor action-group create \
  --name "keyvault-alerts" \
  --resource-group $RESOURCE_GROUP \
  --short-name "kv-alerts" \
  --email-receivers name=admin email=admin@empresa.com

# Crear alerta para secretos próximos a vencer
az monitor metrics alert create \
  --name "secret-near-expiry" \
  --resource-group $RESOURCE_GROUP \
  --scopes $KEYVAULT_ID \
  --condition "count 'Availability' < 1" \
  --action-groups "keyvault-alerts"
```

### Mejores Prácticas de Rotación

```
Frecuencia recomendada:
┌─────────────────────────────────────────────────────────────┐
│ Tipo de Secreto          │ Rotación         │ Poll Interval │
├─────────────────────────────────────────────────────────────┤
│ Contraseñas de BD        │ Cada 90 días     │ 5m            │
│ API Keys de terceros     │ Cada 30-60 días  │ 5m            │
│ Certificados TLS         │ Antes de expirar │ 1h            │
│ Tokens de servicio       │ Cada 24h o menos │ 2m            │
│ JWT signing secrets      │ Cada 30 días     │ 5m            │
└─────────────────────────────────────────────────────────────┘

Reglas generales:
- rotationPollInterval bajo = más rápido pero más llamadas a Key Vault (costo)
- Para secretos críticos: poll cada 2-5 minutos
- Para secretos estables (certificados): poll cada hora
- Nunca usar objectVersion fijo si se quiere rotación automática
- Monitorear el audit log de Key Vault para detectar accesos inesperados
```

---

## Azure Key Vault Provider for Secrets Store CSI Driver

Esta integración permite montar secretos, claves y certificados de Azure Key Vault como volúmenes en Pods.

### Instalación del Provider

```bash
# Agregar repositorio Helm
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts

# Instalar CSI Secrets Store Driver
helm install csi-secrets-store-provider-azure csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system

# Verificar instalación
kubectl get pods -n kube-system -l app=secrets-store-csi-driver
```

### Configurar Azure Key Vault

```bash
# Crear Key Vault
az keyvault create \
  --name kv-k8s-course \
  --resource-group rg-kubernetes-course \
  --location eastus

# Agregar secretos
az keyvault secret set \
  --vault-name kv-k8s-course \
  --name database-password \
  --value "SuperSecret123!"

az keyvault secret set \
  --vault-name kv-k8s-course \
  --name api-key \
  --value "abcd1234-ef56-7890-abcd-1234567890ab"
```

### Configurar Identidad Gestionada

```bash
# Crear managed identity
az identity create \
  --resource-group rg-kubernetes-course \
  --name aks-keyvault-identity

# Obtener client ID e identity ID
IDENTITY_CLIENT_ID=$(az identity show --resource-group rg-kubernetes-course --name aks-keyvault-identity --query clientId -o tsv)
IDENTITY_RESOURCE_ID=$(az identity show --resource-group rg-kubernetes-course --name aks-keyvault-identity --query id -o tsv)

# Asignar permisos al Key Vault
az keyvault set-policy \
  --name kv-k8s-course \
  --object-id $(az identity show --resource-group rg-kubernetes-course --name aks-keyvault-identity --query principalId -o tsv) \
  --secret-permissions get list

# Asignar identity al AKS
az aks pod-identity add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --namespace desarrollo \
  --name keyvault-identity \
  --identity-resource-id $IDENTITY_RESOURCE_ID
```

## Laboratorio 3.4: Usar Azure Key Vault

### Paso 1: Crear SecretProviderClass

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secret
  namespace: desarrollo
spec:
  provider: azure
  parameters:
    usePodIdentity: "true"
    keyvaultName: kv-k8s-course
    cloudName: ""
    objects: |
      array:
        - |
          objectName: database-password
          objectType: secret
          objectVersion: ""
        - |
          objectName: api-key
          objectType: secret
          objectVersion: ""
    tenantId: $(az account show --query tenantId -o tsv)
  secretObjects:
  - secretName: app-secrets
    type: Opaque
    data:
    - objectName: database-password
      key: db-password
    - objectName: api-key
      key: api-key
EOF
```

### Paso 2: Crear Pod que use Key Vault

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: keyvault-app
  namespace: desarrollo
  labels:
    aadpodidbinding: keyvault-identity
spec:
  containers:
  - name: app
    image: nginx:1.21
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: db-password
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: api-key
    volumeMounts:
    - name: secrets-store
      mountPath: "/mnt/secrets"
      readOnly: true
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: azure-keyvault-secret
EOF

# Verificar que el pod puede acceder a los secretos
kubectl exec keyvault-app -n desarrollo -- env | grep -E "(DB_PASSWORD|API_KEY)"
kubectl exec keyvault-app -n desarrollo -- ls -la /mnt/secrets
kubectl exec keyvault-app -n desarrollo -- cat /mnt/secrets/database-password
```

---

## Troubleshooting: Azure Key Vault y CSI Driver

Los problemas de integración con Azure Key Vault suelen manifestarse en el momento en que un Pod intenta montar el volumen CSI. El diagnóstico siempre empieza por los eventos del Pod y los logs del CSI driver.

### Herramientas de Diagnóstico Inicial

```bash
# Siempre empezar aquí: eventos del Pod fallido
kubectl describe pod <pod-name> -n <namespace>
# Buscar sección "Events:" al final — ahí están los errores del CSI driver

# Logs del CSI driver en el nodo donde está el Pod
NODENAME=$(kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.nodeName}')
kubectl logs -l app=secrets-store-csi-driver \
  -n kube-system \
  --field-selector spec.nodeName=$NODENAME \
  -c secrets-store

# Logs del Azure provider
kubectl logs -l app=csi-secrets-store-provider-azure \
  -n kube-system \
  --field-selector spec.nodeName=$NODENAME

# Estado de los SecretProviderClass
kubectl get secretproviderclass -A
kubectl describe secretproviderclass azure-keyvault-secrets -n desarrollo
```

### Escenario 1: Pod en Pending — No Puede Montar el Volumen

**Síntoma**:
```
kubectl describe pod keyvault-app -n desarrollo
# Events:
#   Warning  FailedMount  30s  kubelet
#     MountVolume.SetUp failed for volume "secrets-store-vol":
#     rpc error: code = Unknown desc = failed to mount secrets store objects for pod
#     desarrollo/keyvault-app, err: rpc error: code = Unknown
#     desc = failed to get secretproviderclass desarrollo/azure-keyvault-secrets
```

**Causa**: El SecretProviderClass no existe o está en un namespace diferente.

**Diagnóstico y solución**:
```bash
# Verificar que el SecretProviderClass existe en el namespace correcto
kubectl get secretproviderclass -n desarrollo
# No resources found in desarrollo namespace.  <- PROBLEMA

# Verificar en todos los namespaces
kubectl get secretproviderclass -A
# NAMESPACE    NAME                    AGE
# default      azure-keyvault-secrets  5m   <- está en el namespace equivocado

# Solución: recrear en el namespace correcto
kubectl get secretproviderclass azure-keyvault-secrets -n default -o yaml | \
  sed 's/namespace: default/namespace: desarrollo/' | \
  kubectl apply -f -
```

### Escenario 2: SecretProviderClass No Encontrado — CSI Driver No Instalado

**Síntoma**:
```bash
kubectl describe pod keyvault-app -n desarrollo
# Events:
#   Warning  FailedMount  10s  kubelet
#     MountVolume.SetUp failed for volume "secrets-store-vol":
#     rpc error: code = Unimplemented desc = unknown service volume.v1alpha1.VolumeService
```

**Causa**: El CSI driver no está instalado en el cluster.

**Diagnóstico y solución**:
```bash
# Verificar si el CSI driver está instalado
kubectl get daemonset -n kube-system | grep secrets-store
# (vacío) <- CSI driver no está instalado

# Verificar si el CRD existe
kubectl get crd | grep secrets-store
# (vacío) <- CRDs no están instalados

# Solución opción 1: instalar con Helm
helm repo add csi-secrets-store-provider-azure \
  https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm install csi-secrets-store-provider-azure \
  csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true

# Solución opción 2: habilitar como addon de AKS
az aks enable-addons \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --addons azure-keyvault-secrets-provider

# Verificar tras instalación
kubectl get daemonset -n kube-system | grep secrets-store
# NAME                                DESIRED   CURRENT   READY
# secrets-store-csi-driver            3         3         3
# csi-secrets-store-provider-azure    3         3         3
```

### Escenario 3: "Forbidden" al Acceder al Key Vault

**Síntoma**:
```bash
# Logs del provider en el nodo
kubectl logs -l app=csi-secrets-store-provider-azure -n kube-system
# E0301 10:15:00.123456] failed to get secret database-password from keyvault kv-k8s-course,
#   error: autorest/azure: Service returned an error. Status=403 Code="Forbidden"
#   Message="The user, group or application 'appid=xxxxxxxx...' does not have secrets get
#   permission on key vault 'kv-k8s-course;location=eastus'.
#   For help resolving this issue, please see https://go.microsoft.com/fwlink/?linkid=2125287"
```

**Causa**: La Managed Identity no tiene permisos sobre el Key Vault.

**Diagnóstico y solución**:
```bash
# Verificar qué identity está usando el Pod
kubectl describe pod keyvault-app -n desarrollo | grep -A5 "azure.workload"

# Obtener el clientId de la identity
IDENTITY_CLIENT_ID=$(kubectl get serviceaccount keyvault-sa -n desarrollo \
  -o jsonpath='{.metadata.annotations.azure\.workload\.identity/client-id}')
echo "Identity Client ID: $IDENTITY_CLIENT_ID"

# Obtener el principalId de la managed identity
IDENTITY_PRINCIPAL_ID=$(az identity show \
  --name keyvault-identity \
  --resource-group $RESOURCE_GROUP \
  --query principalId -o tsv)

# Verificar role assignments actuales
KEYVAULT_ID=$(az keyvault show --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP --query id -o tsv)
az role assignment list --scope $KEYVAULT_ID --assignee $IDENTITY_PRINCIPAL_ID -o table
# (vacío si no hay asignaciones)

# Solución: asignar el rol correcto
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee-object-id $IDENTITY_PRINCIPAL_ID \
  --assignee-principal-type ServicePrincipal \
  --scope $KEYVAULT_ID

# Si el Key Vault usa Access Policies (no RBAC):
az keyvault set-policy \
  --name $KEYVAULT_NAME \
  --object-id $IDENTITY_PRINCIPAL_ID \
  --secret-permissions get list
```

### Escenario 4: Sincronización a Kubernetes Secret Falla

**Síntoma**:
```bash
# El Pod está corriendo pero el Kubernetes Secret no se crea
kubectl get secret app-db-secret -n desarrollo
# Error from server (NotFound): secrets "app-db-secret" not found

# Aun cuando el volumen CSI está montado
kubectl exec keyvault-app -n desarrollo -- ls /mnt/secrets
# database-password
# api-key
```

**Causa**: `syncSecret.enabled=true` no está activado en el CSI driver, o el Pod no tiene el volumen montado.

**Diagnóstico y solución**:
```bash
# Verificar que syncSecret está habilitado
helm get values csi-secrets-store-provider-azure -n kube-system | grep syncSecret
# syncSecret:
#   enabled: false   <- PROBLEMA

# Solución: actualizar la instalación de Helm
helm upgrade csi-secrets-store-provider-azure \
  csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true

# Verificar que el RBAC del driver tiene permisos para crear Secrets
kubectl get clusterrole secrets-store-csi-driver -o yaml | grep secrets
# resources: ["secrets"]  <- debe aparecer

# Nota importante: el Kubernetes Secret solo se crea cuando el Pod
# monta el volumen CSI. Si el Pod no está corriendo, el Secret no existe.
kubectl describe secretproviderclasspodstatus -A
# Muestra el estado de sincronización para cada Par (Pod, SecretProviderClass)
```

### Escenario 5: La Rotación No Funciona

**Síntoma**:
```bash
# Se actualizó el secreto en Key Vault hace 10 minutos
# pero el Pod sigue viendo el valor antiguo

kubectl exec keyvault-app -n desarrollo -- cat /mnt/secrets/database-password
# SuperSecret123!   <- valor antiguo

az keyvault secret show --vault-name $KEYVAULT_NAME --name database-password --query value -o tsv
# NuevaSuperContrasena456!   <- valor nuevo en Key Vault
```

**Causa**: La rotación no está habilitada o el intervalo de polling no ha expirado.

**Diagnóstico y solución**:
```bash
# Verificar configuración de rotación en el driver
kubectl get daemonset secrets-store-csi-driver -n kube-system -o yaml | \
  grep -E "(enableSecretRotation|rotationPollInterval)"
# (vacío si no está configurado)

# Verificar los flags del contenedor del driver
kubectl describe daemonset secrets-store-csi-driver -n kube-system | grep -A20 "Args:"
# Si enableSecretRotation no aparece: la rotación no está habilitada

# Solución: actualizar con Helm
helm upgrade csi-secrets-store-provider-azure \
  csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system \
  --set enableSecretRotation=true \
  --set rotationPollInterval=2m

# Verificar que el objectVersion en SecretProviderClass es ""
# Si está fijado a una versión específica, la rotación no funciona
kubectl get secretproviderclass azure-keyvault-secrets -n desarrollo -o yaml | grep objectVersion
# objectVersion: "abc123..."  <- PROBLEMA: versión fija

# Solución: cambiar objectVersion a ""
kubectl edit secretproviderclass azure-keyvault-secrets -n desarrollo
# Cambiar: objectVersion: "abc123..." -> objectVersion: ""

# Forzar una rotación manual (reiniciar el Pod para obtener valor nuevo)
kubectl delete pod keyvault-app -n desarrollo
# El nuevo Pod obtendrá el valor actual de Key Vault al montarse
```

### Escenario 6: Workload Identity Auth Falla

**Síntoma**:
```bash
kubectl logs -l app=csi-secrets-store-provider-azure -n kube-system
# E0301 09:45:00.000000] failed to get token: AADSTS70011: The provided request must
#   include a 'scope' input parameter. The provided value for the input parameter 'scope'
#   is not valid.
# -- o bien --
# E0301 09:45:00.000000] failed to acquire token: AADSTS7000215: Invalid client secret
#   provided. Ensure the secret being sent in the request is the client secret value,
#   not the client secret ID
# -- o bien --
# E0301 09:45:00.000000] failed: the federated token file does not exist
```

**Causa**: La Federated Credential no coincide con el Service Account, o Workload Identity no está habilitado en el cluster.

**Diagnóstico y solución**:
```bash
# Verificar que Workload Identity está habilitado en AKS
az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP \
  --query "securityProfile.workloadIdentity.enabled"
# false  <- PROBLEMA

# Habilitar Workload Identity
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --enable-oidc-issuer \
  --enable-workload-identity

# Verificar la Federated Credential — el subject debe coincidir exactamente
az identity federated-credential list \
  --identity-name keyvault-identity \
  --resource-group $RESOURCE_GROUP
# {
#   "subject": "system:serviceaccount:produccion:keyvault-sa"  <- si el NS está mal
# }

# El Pod está en namespace "desarrollo" pero la credential dice "produccion"
# Solución: recrear la federated credential con el namespace correcto
az identity federated-credential delete \
  --name keyvault-fed-cred \
  --identity-name keyvault-identity \
  --resource-group $RESOURCE_GROUP

az identity federated-credential create \
  --name keyvault-fed-cred \
  --identity-name keyvault-identity \
  --resource-group $RESOURCE_GROUP \
  --issuer $OIDC_ISSUER \
  --subject "system:serviceaccount:desarrollo:keyvault-sa"

# Verificar que el Service Account tiene la anotación correcta
kubectl get serviceaccount keyvault-sa -n desarrollo -o yaml | grep annotations -A3
# annotations:
#   azure.workload.identity/client-id: "xxxxxxxx-..."  <- debe existir

# Verificar que el Pod tiene el label de Workload Identity
kubectl get pod keyvault-app -n desarrollo -o yaml | grep "azure.workload.identity"
# labels:
#   azure.workload.identity/use: "true"  <- debe existir en el Pod o en el SA

# Verificar que el token OIDC se proyecta en el Pod
kubectl exec keyvault-app -n desarrollo -- \
  ls /var/run/secrets/azure/tokens/
# azure-identity-token   <- debe existir si WI está correctamente configurado
```

---

## Resumen del Capítulo

Azure Key Vault es la solución empresarial para la gestión de secretos en Kubernetes con AKS. En este capítulo cubrimos todo el espectro, desde el problema fundamental hasta la implementación completa en producción.

**El problema de Kubernetes Secrets**: Los Secrets de Kubernetes son base64, no cifrado real. Cualquier usuario con acceso al namespace puede decodificar los valores. No hay audit trail nativo, no hay rotación automática, y no hay historial de versiones — limitaciones inaceptables en entornos PCI-DSS, SOC2 o HIPAA.

**La solución con Azure Key Vault**: Almacenamiento centralizado de secretos con cifrado AES-256 siempre activo, audit logs inmutables para cada acceso, rotación automática con historial de versiones, y control de acceso granular mediante Azure RBAC. Un vault puede servir a múltiples clusters en la misma subscription.

**El puente: CSI Secret Store Driver**: El DaemonSet que corre en cada nodo del cluster actúa como intermediario entre los Pods y Key Vault. Cuando un Pod inicia, el driver obtiene los secretos de Key Vault usando la identidad del Service Account, y los monta como archivos en un volumen tmpfs o los sincroniza a Kubernetes Secrets para su uso como env vars.

**Autenticación sin credenciales: Workload Identity**: Elimina completamente la necesidad de almacenar credenciales en el cluster. Cada Service Account obtiene un token OIDC que Azure AD valida contra la Federated Credential configurada, emitiendo un Access Token temporal para acceder al Key Vault. Sin passwords, sin secrets con credenciales, sin rotación manual de service principals.

**Rotación automática**: Con `enableSecretRotation=true` y un `rotationPollInterval` adecuado, el CSI driver verifica periódicamente si los secretos han cambiado en Key Vault y actualiza los archivos montados. Las aplicaciones que leen del sistema de archivos obtienen el nuevo valor sin reiniciarse. Variables de entorno requieren un rollout restart.

**Troubleshooting**: Los problemas más comunes son: namespace incorrecto en SecretProviderClass, permisos faltantes en Key Vault (RBAC o Access Policy), CSI driver no instalado, syncSecret deshabilitado para sincronización a K8s Secrets, y Federated Credential mal configurada (subject no coincide con el Service Account).

La ruta de madurez recomendada para equipos nuevos:
```
Dev/Test:  Managed Identity del nodo + Access Policies  (simple, funciona)
     ↓
Staging:   Workload Identity + Azure RBAC               (aislamiento por SA)
     ↓
Prod:      Workload Identity + Azure RBAC + Private Endpoint + rotación automática + alertas
```
