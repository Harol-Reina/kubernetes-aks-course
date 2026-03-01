# Capítulo 33: Azure Key Vault

Los datos persisten en volúmenes. Ahora protegemos los secretos de las aplicaciones — contraseñas, claves API, certificados — con Azure Key Vault, una solución cloud-native que supera las limitaciones de los Kubernetes Secrets estándar.

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

## Resumen del Capítulo

Azure Key Vault proporciona gestión centralizada de secretos fuera del cluster, con rotación automática, auditoría y control de acceso granular. Mediante el CSI Secrets Store Driver, los secretos se montan como volúmenes o se sincronizan como Kubernetes Secrets. La autenticación usa Managed Identity, eliminando la necesidad de almacenar credenciales en el cluster.
