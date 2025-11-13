# Módulo 14: Secrets - Gestión de Datos Sensibles en Kubernetes

## 📋 Índice

1. [Introducción a los Secrets](#introducción-a-los-secrets)
2. [Secrets vs ConfigMaps](#secrets-vs-configmaps)
3. [Tipos de Secrets](#tipos-de-secrets)
4. [Creación de Secrets](#creación-de-secrets)
5. [Consumo de Secrets](#consumo-de-secrets)
6. [Base64 y Seguridad](#base64-y-seguridad)
7. [Secrets Inmutables](#secrets-inmutables)
8. [Buenas Prácticas de Seguridad](#buenas-prácticas-de-seguridad)
9. [Troubleshooting](#troubleshooting)
10. [Laboratorios Prácticos](#laboratorios-prácticos)
11. [Referencias](#referencias)

---

## Introducción a los Secrets

### ¿Qué es un Secret?

Un **Secret** es un objeto de Kubernetes diseñado específicamente para almacenar y gestionar información sensible como:

- 🔑 **Contraseñas** de bases de datos
- 🎫 **Tokens** de autenticación (API keys, JWT)
- 🔐 **Certificados TLS** y claves privadas
- 📧 **Credenciales** de registros de imágenes Docker
- 🔒 **Claves SSH** para autenticación
- 🗝️ **Cualquier dato confidencial** que no deba exponerse

### Características Principales

```yaml
✓ Almacenamiento separado de la configuración de aplicaciones
✓ Codificación Base64 (obscuridad, no encriptación)
✓ Transmisión solo a nodos que ejecutan Pods que los requieren
✓ Almacenamiento en tmpfs (no en disco persistente)
✓ Soporte para encriptación en reposo (etcd)
✓ Control de acceso mediante RBAC
✓ Límite de tamaño: 1 MiB por Secret
```

### Ventajas de Usar Secrets

#### 🎯 **Separación de Responsabilidades**
```
Código de Aplicación ────────┐
                             │
ConfigMap (Config Pública) ──┼──> Pod/Deployment
                             │
Secret (Datos Sensibles) ────┘
```

- **Desarrollo**: El código no contiene credenciales hardcodeadas
- **Operaciones**: Los secretos se gestionan independientemente
- **Seguridad**: Se aplican políticas de acceso específicas

#### 🔄 **Actualización Dinámica**
- Modificar secretos sin reconstruir imágenes
- Actualización automática en Pods (cuando se montan como volúmenes)
- Versionamiento y rollback de configuraciones sensibles

#### 🛡️ **Seguridad Mejorada**
- Acceso restringido mediante RBAC
- Encriptación en tránsito y en reposo (configuración adicional)
- Auditoría de accesos a secretos

---

## Secrets vs ConfigMaps

### Comparación Lado a Lado

| Característica | **ConfigMap** | **Secret** |
|----------------|---------------|------------|
| **Propósito** | Configuración no sensible | Datos sensibles/confidenciales |
| **Almacenamiento** | Texto plano en etcd | Base64 + encriptación opcional |
| **Visibilidad** | `kubectl describe` muestra datos | Datos ocultos en `describe` |
| **Tamaño máximo** | 1 MiB | 1 MiB |
| **Tipos** | Solo `ConfigMap` | Múltiples tipos especializados |
| **RBAC** | Permisos generales | Permisos más estrictos |
| **Auditoría** | Estándar | Registro detallado |

### ¿Cuándo Usar Cada Uno?

#### ✅ Usa **ConfigMap** para:
```yaml
# Ejemplos de datos NO sensibles
- Archivos de configuración (nginx.conf, application.properties)
- Variables de entorno públicas (LOG_LEVEL, API_URL)
- Scripts de inicialización
- Datos de configuración que pueden ser públicos
```

#### 🔐 Usa **Secret** para:
```yaml
# Ejemplos de datos SENSIBLES
- Contraseñas de bases de datos: POSTGRES_PASSWORD
- API Keys y tokens: STRIPE_API_KEY, GITHUB_TOKEN
- Certificados TLS: tls.crt, tls.key
- Credenciales Docker: .dockerconfigjson
- Claves SSH: id_rsa, id_rsa.pub
```

### Ejemplo Comparativo

**ConfigMap** - Configuración de aplicación:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database.host: "postgres.default.svc.cluster.local"
  database.port: "5432"
  database.name: "myapp"
  log.level: "info"
```

**Secret** - Credenciales de la misma aplicación:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  database.username: "admin"
  database.password: "SecureP@ssw0rd!"
```

---

## Tipos de Secrets

Kubernetes proporciona varios tipos de Secrets especializados para diferentes casos de uso:

### 1. **Opaque** (Genérico)

Tipo por defecto para datos arbitrarios definidos por el usuario.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: generic-secret
type: Opaque  # Tipo por defecto
stringData:
  username: "admin"
  password: "mypassword"
  api-key: "abc123xyz789"
```

**Uso típico**: Credenciales de aplicaciones, tokens personalizados, cualquier dato sensible.

### 2. **kubernetes.io/service-account-token**

Token de autenticación para ServiceAccounts (mecanismo legacy).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sa-token-secret
  annotations:
    kubernetes.io/service-account.name: "my-service-account"
type: kubernetes.io/service-account-token
```

⚠️ **Recomendación**: Usar `TokenRequest` API (tokens de corta duración) en lugar de este tipo.

### 3. **kubernetes.io/dockerconfigjson**

Credenciales para pull de imágenes de registros privados.

**Creación por línea de comandos**:
```bash
kubectl create secret docker-registry my-registry-secret \
  --docker-server=myregistry.example.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=user@example.com
```

**Manifiesto YAML**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: docker-registry-secret
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6eyJteXJlZ2lzdHJ5LmV4YW1wbGUuY29tIjp7InVzZXJuYW1lIjoibXl1c2VyIiwicGFzc3dvcmQiOiJteXBhc3N3b3JkIiwiZW1haWwiOiJ1c2VyQGV4YW1wbGUuY29tIiwiYXV0aCI6ImJYbDFjMlZ5T20xNWNHRnpjM2R2Y21RPSJ9fX0=
```

**Uso en Pod**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-image-pod
spec:
  imagePullSecrets:
  - name: docker-registry-secret
  containers:
  - name: app
    image: myregistry.example.com/myapp:latest
```

📁 **Ejemplos completos**: [`ejemplos/07-secrets-docker-registry/`](./ejemplos/07-secrets-docker-registry/)
- `secret-docker-registry.yaml` - Secret de Docker Registry
- `deployment-private-image.yaml` - Deployment usando imagePullSecrets
- `create-docker-secret.sh` - Script de creación imperativa

### 4. **kubernetes.io/tls**

Certificados TLS y claves privadas para HTTPS.

**Creación por línea de comandos**:
```bash
kubectl create secret tls tls-secret \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key
```

**Manifiesto YAML**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...
  tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQ==...
```

**Uso en Ingress**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: tls-secret
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

📁 **Ejemplos completos**: [`ejemplos/06-secrets-tls/`](./ejemplos/06-secrets-tls/)
- `generate-tls-cert.sh` - Generar certificado TLS autofirmado
- `secret-tls.yaml` - Secret TLS con certificado
- `ingress-tls.yaml` - Ingress usando TLS

### 5. **kubernetes.io/basic-auth**

Credenciales de autenticación básica HTTP.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: basic-auth-secret
type: kubernetes.io/basic-auth
stringData:
  username: admin        # Campo requerido
  password: SecurePass!  # Campo requerido
```

### 6. **kubernetes.io/ssh-auth**

Claves SSH para autenticación.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ssh-auth-secret
type: kubernetes.io/ssh-auth
stringData:
  ssh-privatekey: |
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEA...
    -----END RSA PRIVATE KEY-----
```

### 7. **bootstrap.kubernetes.io/token**

Tokens para el proceso de bootstrap de nodos (uso interno de Kubernetes).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bootstrap-token-abc123
  namespace: kube-system
type: bootstrap.kubernetes.io/token
stringData:
  token-id: "abc123"
  token-secret: "xyz789secrettoken"
  usage-bootstrap-authentication: "true"
  usage-bootstrap-signing: "true"
```

### Resumen de Tipos

```
┌─────────────────────────────────────────────────────────────┐
│                    Tipos de Secrets                         │
├─────────────────────────────────────────────────────────────┤
│ Opaque                      → Datos genéricos arbitrarios   │
│ dockerconfigjson            → Credenciales de registros     │
│ tls                         → Certificados TLS              │
│ basic-auth                  → Autenticación básica HTTP     │
│ ssh-auth                    → Claves SSH                    │
│ service-account-token       → Tokens de ServiceAccount      │
│ bootstrap.kubernetes.io/... → Bootstrap de nodos            │
└─────────────────────────────────────────────────────────────┘
```

---

## Creación de Secrets

### Método 1: Usando `kubectl create secret`

#### Desde Literales (--from-literal)

Crear secretos con valores directos en la línea de comandos:

```bash
# Crear un secreto genérico con múltiples claves
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password='SuperSecret123!' \
  --from-literal=database=production

# Verificar
kubectl get secret db-credentials
kubectl describe secret db-credentials
```

**Ventajas**: Rápido para pruebas
**Desventajas**: Las credenciales quedan en el historial de bash

📁 **Ejemplo completo con script**: [`ejemplos/02-secrets-literales/create-from-literal.sh`](./ejemplos/02-secrets-literales/create-from-literal.sh)

#### Desde Archivos (--from-file)

Crear secretos desde archivos existentes:

```bash
# Crear archivos con datos sensibles
echo -n 'admin' > ./username.txt
echo -n 'SecurePassword' > ./password.txt

# Crear Secret desde archivos
kubectl create secret generic file-secrets \
  --from-file=username=./username.txt \
  --from-file=password=./password.txt

# Crear Secret desde archivo completo (la clave será el nombre del archivo)
kubectl create secret generic ssh-key \
  --from-file=id_rsa=~/.ssh/id_rsa
```

📁 **Ejemplos completos**: [`ejemplos/03-secrets-archivos/`](./ejemplos/03-secrets-archivos/)
- `credentials.txt` - Archivo de credenciales de ejemplo
- `api-token.txt` - Token JWT de ejemplo
- `create-from-files.sh` - Script completo de creación

#### Desde Directorio

```bash
# Crear Secret con todos los archivos de un directorio
mkdir secret-files/
echo -n 'value1' > secret-files/key1.txt
echo -n 'value2' > secret-files/key2.txt

kubectl create secret generic dir-secrets \
  --from-file=secret-files/
```

#### Desde Variables de Entorno (--from-env-file)

```bash
# Crear archivo .env
cat <<EOF > app.env
DB_USERNAME=admin
DB_PASSWORD=SecretPass
API_KEY=abc123xyz
EOF

# Crear Secret desde archivo .env
kubectl create secret generic env-secrets \
  --from-env-file=app.env
```

### Método 2: Usando Manifiestos YAML

#### Con `data` (Base64 manual)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: manual-base64-secret
  namespace: default
type: Opaque
data:
  # Valores codificados en Base64
  username: YWRtaW4=              # "admin"
  password: U2VjdXJlUGFzc3dvcmQ=  # "SecurePassword"
```

**Codificar manualmente**:
```bash
# Codificar valores
echo -n 'admin' | base64            # YWRtaW4=
echo -n 'SecurePassword' | base64   # U2VjdXJlUGFzc3dvcmQ=

# Decodificar para verificar
echo 'YWRtaW4=' | base64 --decode   # admin
```

📁 **Ejemplo completo**: [`ejemplos/01-secrets-basicos/secret-opaque-data.yaml`](./ejemplos/01-secrets-basicos/secret-opaque-data.yaml)

#### Con `stringData` (Recomendado para desarrollo)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: string-data-secret
  namespace: default
type: Opaque
stringData:
  # Valores en texto plano (Kubernetes los codifica automáticamente)
  username: "admin"
  password: "SecurePassword"
  database-url: "postgresql://admin:pass@db.example.com:5432/mydb"
```

⚠️ **Importante**: `stringData` es **write-only**. Kubernetes lo convierte a `data` automáticamente.

**Verificación**:
```bash
kubectl apply -f secret.yaml
kubectl get secret string-data-secret -o yaml
# Verás que stringData se convirtió a data con valores Base64
```

📁 **Ejemplo completo**: [`ejemplos/01-secrets-basicos/secret-opaque-stringdata.yaml`](./ejemplos/01-secrets-basicos/secret-opaque-stringdata.yaml)

#### Combinando `data` y `stringData`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: combined-secret
type: Opaque
data:
  # Valor ya codificado (por ejemplo, desde un archivo existente)
  tls.crt: LS0tLS1CRUdJTi...
stringData:
  # Valores en texto plano
  username: "admin"
  password: "mypassword"
```

⚠️ Si una clave existe en ambos campos, **`stringData` tiene prioridad**.

### Método 3: Usando Kustomize

**kustomization.yaml**:
```yaml
secretGenerator:
- name: app-secrets
  literals:
  - username=admin
  - password=SecretPass
  files:
  - ssh-key=~/.ssh/id_rsa
  envs:
  - app.env
```

**Generar Secret**:
```bash
kubectl kustomize . | kubectl apply -f -
```

### Método 4: Workflow Seguro con `envsubst`

Para **evitar guardar credenciales en Git**, usa placeholders y variables de entorno:

**secret-template.yaml**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secure-secret
type: Opaque
stringData:
  username: ${DB_USERNAME}      # Placeholder
  password: ${DB_PASSWORD}      # Placeholder
  api-key: ${API_KEY}           # Placeholder
```

**Aplicación segura**:
```bash
# 1. Exportar variables de entorno (desde un vault, CI/CD, etc.)
export DB_USERNAME="admin"
export DB_PASSWORD="RealSecurePassword"
export API_KEY="real-api-key-abc123"

# 2. Sustituir placeholders y aplicar
envsubst < secret-template.yaml | kubectl apply -f -

# 3. Las credenciales NUNCA se guardan en Git
# El template con placeholders es seguro para versionar
```

📁 **Ejemplo completo**: [`ejemplos/08-combinados/secret-template.yaml`](./ejemplos/08-combinados/secret-template.yaml)

**Aplicación segura**:
```bash
# 1. Exportar variables de entorno (desde un vault, CI/CD, etc.)
export DB_USERNAME="admin"
export DB_PASSWORD="RealSecurePassword"
export API_KEY="real-api-key-abc123"

# 2. Sustituir placeholders y aplicar
envsubst < secret-template.yaml | kubectl apply -f -

# 3. Las credenciales NUNCA se guardan en Git
# El template con placeholders es seguro para versionar
```

**Verificación de variables antes de aplicar**:
```bash
# Ver resultado de la sustitución sin aplicar
envsubst < secret-template.yaml

# Guardar en archivo temporal si es necesario
envsubst < secret-template.yaml > /tmp/secret-real.yaml
kubectl apply -f /tmp/secret-real.yaml
rm /tmp/secret-real.yaml  # Eliminar archivo temporal
```

### Comparación de Métodos

| Método | Uso Recomendado | Pros | Contras |
|--------|-----------------|------|---------|
| `kubectl create` | Desarrollo/testing rápido | Muy rápido | Credenciales en historial bash |
| `data` (Base64) | Automatización | Control total | Tedioso manualmente |
| `stringData` | Desarrollo local | Fácil de escribir | ⚠️ No versionar con credenciales reales |
| `envsubst` | **Producción** | ✅ Seguro para Git | Requiere gestión de variables |
| Kustomize | CI/CD, multi-entorno | Generación dinámica | Curva de aprendizaje |

---

## Consumo de Secrets

Los Secrets pueden ser consumidos por los Pods de dos formas principales:

### 1. Como Variables de Entorno

#### Consumir Claves Individuales

**Secret de ejemplo**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:
  DB_HOST: "postgres.default.svc.cluster.local"
  DB_PORT: "5432"
  DB_NAME: "myapp"
  DB_USER: "admin"
  DB_PASSWORD: "SecurePass123"
```

**Pod consumiendo claves específicas**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-env-vars
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    # Mapear claves individuales a variables de entorno
    - name: DATABASE_HOST
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: DB_HOST
    
    - name: DATABASE_USER
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: DB_USER
    
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: DB_PASSWORD
```

**Verificación**:
```bash
kubectl exec app-with-env-vars -- env | grep DATABASE
# DATABASE_HOST=postgres.default.svc.cluster.local
# DATABASE_USER=admin
# DATABASE_PASSWORD=SecurePass123
```

#### Consumir Todas las Claves (`envFrom`)

**Pod consumiendo todo el Secret**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-all-env
spec:
  containers:
  - name: app
    image: myapp:latest
    # Importar TODAS las claves del Secret como variables de entorno
    envFrom:
    - secretRef:
        name: db-secret
```

**Resultado**: Cada clave del Secret se convierte en una variable de entorno.

```bash
kubectl exec app-with-all-env -- env | sort
# DB_HOST=postgres.default.svc.cluster.local
# DB_NAME=myapp
# DB_PASSWORD=SecurePass123
# DB_PORT=5432
# DB_USER=admin
```

📁 **Ejemplo completo**: [`ejemplos/04-secrets-env/pod-env-all.yaml`](./ejemplos/04-secrets-env/pod-env-all.yaml)

#### Combinando ConfigMaps y Secrets

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-combined
spec:
  containers:
  - name: app
    image: myapp:latest
    # Variables individuales
    env:
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: log.level
    
    # Importar todo el ConfigMap
    envFrom:
    - configMapRef:
        name: app-config
    
    # Importar todo el Secret
    - secretRef:
        name: db-secret
```

📁 **Ejemplo completo con múltiples Secrets**: [`ejemplos/04-secrets-env/deployment-multi-secrets.yaml`](./ejemplos/04-secrets-env/deployment-multi-secrets.yaml)

### 2. Como Volúmenes (Montaje de Archivos)

#### Montar Todas las Claves

**Pod montando Secret como volumen**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-volume
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "ls -la /etc/secrets && sleep 3600"]
    
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true  # Siempre montar como solo lectura
  
  volumes:
  - name: secret-volume
    secret:
      secretName: db-secret
```

**Resultado en el contenedor**:
```bash
kubectl exec app-with-volume -- ls -la /etc/secrets
# Cada clave del Secret se convierte en un archivo
kubectl exec app-with-volume -- cat /etc/secrets/DB_PASSWORD
# SecurePass123
```

📁 **Ejemplo completo**: [`ejemplos/05-secrets-volume/pod-volume-all.yaml`](./ejemplos/05-secrets-volume/pod-volume-all.yaml)

#### Montar Claves Específicas con `items`

**Montar solo algunas claves**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-selective-mount
spec:
  containers:
  - name: app
    image: nginx:alpine
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  
  volumes:
  - name: secret-volume
    secret:
      secretName: db-secret
      items:  # Solo montar claves específicas
      - key: DB_USER
        path: username.txt       # Renombrar archivo
      - key: DB_PASSWORD
        path: credentials/password.txt  # Con subdirectorio
```

**Resultado**:
```bash
kubectl exec app-selective-mount -- cat /etc/secrets/username.txt
# admin
```

📁 **Ejemplo completo**: [`ejemplos/05-secrets-volume/pod-volume-selective.yaml`](./ejemplos/05-secrets-volume/pod-volume-selective.yaml)

#### Montar en Ruta Específica con `subPath`

**Montar un solo archivo sin sobrescribir directorio**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-tls
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    volumeMounts:
    # Montar solo el certificado en ruta específica
    - name: tls-certs
      mountPath: /etc/nginx/ssl/tls.crt
      subPath: tls.crt
      readOnly: true
    
    # Montar solo la clave en otra ruta
    - name: tls-certs
      mountPath: /etc/nginx/ssl/tls.key
      subPath: tls.key
      readOnly: true
  
  volumes:
  - name: tls-certs
    secret:
      secretName: tls-secret
```

⚠️ **Importante**: Con `subPath`, **no se reciben actualizaciones automáticas** del Secret.

📁 **Ejemplo completo con subPath**: [`ejemplos/05-secrets-volume/pod-volume-subpath.yaml`](./ejemplos/05-secrets-volume/pod-volume-subpath.yaml)

### 3. Secrets Opcionales

Si un Secret no existe, el Pod falla al iniciar. Para permitir Secrets opcionales:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-optional-secret
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
    
    # Variable de entorno desde Secret opcional
    env:
    - name: OPTIONAL_KEY
      valueFrom:
        secretKeyRef:
          name: optional-secret
          key: data
          optional: true  # No fallar si no existe
    
    volumeMounts:
    - name: optional-volume
      mountPath: /etc/optional
      readOnly: true
  
  volumes:
  - name: optional-volume
    secret:
      secretName: another-optional-secret
      optional: true  # No fallar si no existe
```

### 4. Actualización Automática de Secrets

**Secrets montados como volúmenes**:
- ✅ Se actualizan automáticamente (eventual consistency)
- ⏱️ Delay típico: Período de sincronización del kubelet (~1 minuto)
- ❌ No funciona con `subPath`

**Secrets como variables de entorno**:
- ❌ **NO** se actualizan automáticamente
- 🔄 Requiere recrear el Pod para ver cambios

**Ejemplo de actualización**:
```bash
# Actualizar Secret
kubectl create secret generic db-secret \
  --from-literal=password='NewPassword' \
  --dry-run=client -o yaml | kubectl apply -f -

# Pod con volumen: Verá el cambio después de ~1 minuto
kubectl exec app-with-volume -- cat /etc/secrets/password

# Pod con env vars: NO verá el cambio hasta reiniciar
kubectl delete pod app-with-env-vars
kubectl apply -f pod-with-env-vars.yaml
```

### Resumen de Métodos de Consumo

| Método | Actualización Automática | Uso Recomendado |
|--------|--------------------------|-----------------|
| **env → secretKeyRef** | ❌ No | Valores simples que no cambian |
| **envFrom → secretRef** | ❌ No | Importar múltiples variables |
| **Volume (todas las claves)** | ✅ Sí (~1 min) | Archivos de configuración |
| **Volume + items** | ✅ Sí (~1 min) | Montar claves específicas |
| **Volume + subPath** | ❌ No | Archivos individuales estáticos |

---

## Base64 y Seguridad

### ¿Por Qué Base64?

Kubernetes usa **Base64** para codificar Secrets por las siguientes razones:

1. **Compatibilidad**: Permite almacenar datos binarios (certificados, claves) en YAML/JSON
2. **Transparencia**: Facilita inspección manual (decodificar con `base64 -d`)
3. **No es encriptación**: Es solo **ofuscación** (obscurity, not security)

⚠️ **IMPORTANTE**: **Base64 NO es seguro**. Cualquier persona con acceso puede decodificar:

```bash
echo "U2VjdXJlUGFzc3dvcmQ=" | base64 --decode
# SecurePassword
```

### Codificación y Decodificación Manual

#### Codificar a Base64

```bash
# Texto simple
echo -n 'mypassword' | base64
# bXlwYXNzd29yZA==

# Archivo completo
base64 < /path/to/file.txt
# o
cat /path/to/file.txt | base64

# Certificado TLS
base64 < tls.crt
```

⚠️ **Importante**: Usar `-n` con `echo` para evitar salto de línea.

#### Decodificar desde Base64

```bash
# Decodificar texto
echo 'bXlwYXNzd29yZA==' | base64 --decode
# mypassword

# Decodificar Secret de Kubernetes
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 --decode
# SecurePassword

# Decodificar todo el Secret
kubectl get secret db-secret -o json | \
  jq -r '.data | to_entries[] | "\(.key): \(.value | @base64d)"'
# DB_HOST: postgres.default.svc.cluster.local
# DB_PASSWORD: SecurePassword
# DB_USER: admin
```

### Visualización de Secrets

#### Comando `describe` (Oculta valores)

```bash
kubectl describe secret db-secret
# Name:         db-secret
# Namespace:    default
# Labels:       <none>
# Annotations:  <none>
#
# Type:  Opaque
#
# Data
# ====
# DB_HOST:      34 bytes
# DB_PASSWORD:  13 bytes
# DB_USER:      5 bytes
```

Solo muestra **tamaño** de cada clave, no el valor.

#### Comando `get -o yaml` (Muestra valores codificados)

```bash
kubectl get secret db-secret -o yaml
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  DB_HOST: cG9zdGdyZXMuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbA==
  DB_PASSWORD: U2VjdXJlUGFzczEyMw==
  DB_USER: YWRtaW4=
```

Valores visibles pero codificados en Base64.

### Seguridad Real de Secrets

#### ⚠️ Secretos NO Son Seguros por Defecto

```
┌────────────────────────────────────────────────────────────┐
│        Estado de Seguridad de Secrets (Por Defecto)       │
├────────────────────────────────────────────────────────────┤
│ ❌ Almacenados en TEXTO PLANO en etcd                      │
│ ❌ Base64 es reversible (no es encriptación)               │
│ ❌ Cualquiera con acceso a etcd puede leerlos              │
│ ❌ Cualquiera que pueda crear Pods puede leer Secrets      │
│ ❌ Aparecen en `kubectl get secret -o yaml`                │
└────────────────────────────────────────────────────────────┘
```

#### ✅ Medidas de Seguridad Necesarias

Para usar Secrets de forma segura en producción:

1. **Encriptación en Reposo (Encryption at Rest)**
   ```yaml
   # En el API Server: /etc/kubernetes/encryption-config.yaml
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
       - identity: {}  # Fallback para leer Secrets no encriptados
   ```

2. **RBAC Estricto**
   ```yaml
   # Denegar acceso a Secrets por defecto
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: pod-reader
   rules:
   - apiGroups: [""]
     resources: ["pods"]
     verbs: ["get", "list"]
   # NO incluir "secrets" aquí
   ```

3. **Namespaces Separados**
   ```bash
   # Aislamiento de Secrets por entorno
   kubectl create namespace production
   kubectl create secret generic db-secret -n production ...
   ```

4. **Network Policies**
   - Limitar comunicación entre Pods
   - Solo Pods autorizados pueden comunicarse con servicios que usan Secrets

5. **Auditoría**
   ```yaml
   # Habilitar audit logging para Secrets
   apiVersion: audit.k8s.io/v1
   kind: Policy
   rules:
   - level: RequestResponse
     resources:
     - group: ""
       resources: ["secrets"]
   ```

6. **Secret Store Externos** (Recomendado para producción)
   - **HashiCorp Vault**
   - **AWS Secrets Manager**
   - **Azure Key Vault**
   - **Google Secret Manager**
   - **External Secrets Operator**

### Ejemplo de Flujo Seguro

```
┌─────────────┐
│ Desarrollador│
└──────┬──────┘
       │ 1. Crea template con placeholders
       │    (secret-template.yaml)
       ├─────────────────────────────────────────┐
       │                                         │
       │ apiVersion: v1                          │
       │ kind: Secret                            │
       │ stringData:                             │
       │   password: ${DB_PASSWORD}              │
       └─────────────────────────────────────────┘
       │
       │ 2. Versiona template en Git (seguro)
       ▼
┌─────────────┐
│ Git Repo    │ ← Template sin credenciales reales
└──────┬──────┘
       │
       │ 3. CI/CD obtiene credenciales de Vault
       ▼
┌─────────────┐     4. export DB_PASSWORD="..."
│ CI/CD       ├────────────────────────────────────┐
└──────┬──────┘                                    │
       │                                           │
       │ 5. envsubst < template | kubectl apply   │
       ▼                                           │
┌─────────────┐                                    │
│ Kubernetes  │ ← Secret con valor real            │
│ (etcd       │   (nunca guardado en Git)          │
│  encrypted) │                                    │
└─────────────┘
```

---

## Secrets Inmutables

### ¿Qué Son los Secrets Inmutables?

Desde Kubernetes **v1.21** (stable), puedes marcar Secrets (y ConfigMaps) como **inmutables**:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: immutable-secret
type: Opaque
data:
  key1: dmFsdWUx
immutable: true  # No se puede modificar
```

### Beneficios

1. **Protección contra cambios accidentales**
   - Evita modificaciones que podrían causar interrupciones
   - Los datos no pueden ser alterados sin eliminar el Secret

2. **Rendimiento mejorado**
   - Kubelet no necesita watch de Secrets inmutables
   - Reduce carga en kube-apiserver (importante con miles de Secrets)

3. **Versionamiento explícito**
   - Fuerza a crear nuevos Secrets para cambios
   - Facilita rollback a versiones anteriores

### Uso con Versionamiento

**Estrategia recomendada**:

```yaml
# Versión 1 del Secret
apiVersion: v1
kind: Secret
metadata:
  name: db-secret-v1  # Nombre versionado
type: Opaque
immutable: true
stringData:
  password: "OldPassword"
---
# Deployment usando v1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret-v1  # Referencia versionada
              key: password
```

📁 **Ejemplo completo con versionamiento**: [`ejemplos/08-combinados/immutable-secrets-versioning.yaml`](./ejemplos/08-combinados/immutable-secrets-versioning.yaml)

**Para actualizar**:

```yaml
# Versión 2 del Secret (nuevo recurso)
apiVersion: v1
kind: Secret
metadata:
  name: db-secret-v2  # Nuevo nombre
type: Opaque
immutable: true
stringData:
  password: "NewPassword"
---
# Actualizar Deployment para usar v2
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret-v2  # Nueva referencia
              key: password
```

### Limitaciones

⚠️ **Irreversible**: Una vez marcado como `immutable: true`, **NO** puedes:
- Cambiar datos del Secret
- Cambiar la inmutabilidad a `false`

Solo puedes **eliminar** el Secret y crear uno nuevo.

```bash
# Intentar modificar un Secret inmutable
kubectl edit secret immutable-secret
# Error: el Secret es inmutable

# Solución: Eliminar y recrear
kubectl delete secret immutable-secret
kubectl create secret generic immutable-secret --from-literal=key=newvalue
```

### Cuándo Usar Secrets Inmutables

| Escenario | Inmutable | Mutable |
|-----------|-----------|---------|
| Certificados TLS (larga duración) | ✅ Sí | ❌ No |
| Tokens de producción | ✅ Sí | ❌ No |
| Credenciales de desarrollo/testing | ❌ No | ✅ Sí |
| Secrets con rotación frecuente | ❌ No | ✅ Sí |
| Configuración versionada explícita | ✅ Sí | ❌ No |

---

## Buenas Prácticas de Seguridad

### 🛡️ Principios Fundamentales

#### 1. **Nunca Guardar Secrets en Git**

❌ **MAL**:
```yaml
# secret.yaml (en Git)
apiVersion: v1
kind: Secret
stringData:
  password: "MyRealPassword123"  # ❌ Credencial real en Git
```

✅ **BIEN**:
```yaml
# secret-template.yaml (en Git)
apiVersion: v1
kind: Secret
stringData:
  password: ${DB_PASSWORD}  # ✅ Placeholder, valor real en CI/CD
```

#### 2. **Principio de Menor Privilegio (RBAC)**

```yaml
# Crear ServiceAccount con acceso limitado
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: production
---
# Role con permisos mínimos (SIN acceso a Secrets)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "configmaps"]  # Solo Pods y ConfigMaps
  verbs: ["get", "list"]
# NO incluir "secrets" aquí
---
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-rolebinding
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-sa
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

#### 3. **Aislamiento por Namespace**

```bash
# Separar Secrets por entorno
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production

# Crear Secrets en namespaces específicos
kubectl create secret generic db-secret \
  --from-literal=password=DevPass \
  -n dev

kubectl create secret generic db-secret \
  --from-literal=password=ProductionPass \
  -n production
```

#### 4. **Encriptación en Reposo**

**Configuración del API Server**:
```yaml
# /etc/kubernetes/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: <32-byte-base64-encoded-key>
    - identity: {}
```

**Generar clave de encriptación**:
```bash
head -c 32 /dev/urandom | base64
```

**Configurar API Server**:
```bash
kube-apiserver \
  --encryption-provider-config=/etc/kubernetes/encryption-config.yaml \
  ...
```

#### 5. **No Usar Secrets en Logs**

❌ **MAL**:
```bash
# Logs pueden exponer Secrets
kubectl logs mypod | grep PASSWORD
```

✅ **BIEN**:
```python
# En la aplicación, NO logear valores sensibles
import os
import logging

db_password = os.getenv('DB_PASSWORD')
# logging.info(f"Password: {db_password}")  # ❌ NUNCA hacer esto
logging.info("Database connection configured")  # ✅ Log genérico
```

#### 6. **Rotación de Secrets**

**Estrategia de rotación**:
```bash
# 1. Crear nuevo Secret versionado
kubectl create secret generic db-secret-v2 \
  --from-literal=password=NewPassword

# 2. Actualizar Deployment para usar nuevo Secret
kubectl set env deployment/myapp \
  DB_PASSWORD_SECRET=db-secret-v2

# 3. Rollout del Deployment
kubectl rollout status deployment/myapp

# 4. Verificar que funciona correctamente
# 5. Eliminar Secret antiguo
kubectl delete secret db-secret-v1
```

#### 7. **Montar Secrets como ReadOnly**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true  # ✅ Siempre usar readOnly
  volumes:
  - name: secret-volume
    secret:
      secretName: my-secret
      defaultMode: 0400  # Permisos r-------- (solo lectura para owner)
```

#### 8. **Restringir Acceso a Contenedores Específicos**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  # Contenedor frontend SIN acceso a Secrets
  - name: frontend
    image: nginx:alpine
  
  # Solo el contenedor backend tiene acceso
  - name: backend
    image: myapp:latest
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
```

### 🔐 Soluciones de Gestión Externa de Secrets

#### External Secrets Operator

```yaml
# ExternalSecret que sincroniza desde AWS Secrets Manager
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: aws-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: db-secret  # Secret de Kubernetes que se creará
  data:
  - secretKey: password
    remoteRef:
      key: prod/db/password
```

#### HashiCorp Vault

```yaml
# Vault Agent Injector Annotation
apiVersion: v1
kind: Pod
metadata:
  name: vault-pod
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/agent-inject-secret-db: "secret/data/database"
    vault.hashicorp.com/role: "myapp"
spec:
  serviceAccountName: vault-auth
  containers:
  - name: app
    image: myapp:latest
```

### 📋 Checklist de Seguridad

```
┌─────────────────────────────────────────────────────────────┐
│             Checklist de Seguridad de Secrets               │
├─────────────────────────────────────────────────────────────┤
│ ✅ Encriptación en reposo habilitada (etcd)                 │
│ ✅ RBAC configurado con mínimos privilegios                 │
│ ✅ Secrets NO versionados en Git (usar placeholders)        │
│ ✅ Namespaces separados por entorno                         │
│ ✅ Secrets montados como readOnly                           │
│ ✅ defaultMode restrictivo (0400)                           │
│ ✅ Auditoría habilitada para accesos a Secrets              │
│ ✅ Rotación periódica de credenciales                       │
│ ✅ Usar Secret Store externo (Vault, AWS SM, etc.)         │
│ ✅ No logear valores de Secrets                             │
│ ✅ Network Policies para limitar acceso                     │
│ ✅ ServiceAccounts específicos por aplicación               │
└─────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### Problema 1: Secret No Encontrado

**Síntoma**:
```bash
kubectl get pods
# NAME     READY   STATUS                  RESTARTS   AGE
# mypod    0/1     CreateContainerConfigError   0          5s
```

**Descripción del Pod**:
```bash
kubectl describe pod mypod
# Events:
#   Warning  Failed  secret "db-secret" not found
```

**Causas**:
- Secret no existe en el namespace
- Nombre del Secret incorrecto
- Secret en namespace diferente

**Solución**:
```bash
# Verificar si el Secret existe
kubectl get secret db-secret
# Error from server (NotFound): secrets "db-secret" not found

# Crear el Secret
kubectl create secret generic db-secret \
  --from-literal=password=MyPassword

# Verificar namespace
kubectl get secret -n production  # Si el Pod está en otro namespace
```

### Problema 2: Clave Inexistente en Secret

**Síntoma**:
```yaml
# Pod definition
env:
- name: DB_PASS
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: password  # Esta clave no existe
```

**Error**:
```bash
kubectl describe pod mypod
# Warning  Failed  key "password" not found in secret "db-secret"
```

**Solución**:
```bash
# Ver claves disponibles en el Secret
kubectl get secret db-secret -o jsonpath='{.data}' | jq 'keys'
# ["DB_PASSWORD", "DB_USER"]  # La clave real es "DB_PASSWORD"

# Corregir Pod definition
env:
- name: DB_PASS
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: DB_PASSWORD  # Nombre correcto
```

### Problema 3: Caracteres Inválidos en Claves

**Error**:
```yaml
apiVersion: v1
kind: Secret
stringData:
  database.password: "MyPass"  # ❌ Punto no válido para env vars
```

**Síntoma**:
```bash
kubectl apply -f secret.yaml
# Secret created

kubectl logs mypod
# env: can't execute 'database.password': No such file or directory
```

**Explicación**: Variables de entorno en Linux **no permiten puntos**.

**Solución**:
```yaml
# Opción 1: Usar guiones bajos
apiVersion: v1
kind: Secret
stringData:
  database_password: "MyPass"  # ✅ Válido

# Opción 2: Montar como volumen (permite cualquier nombre de clave)
volumeMounts:
- name: secret-vol
  mountPath: /etc/secrets
volumes:
- name: secret-vol
  secret:
    secretName: db-secret
# Archivo /etc/secrets/database.password será válido
```

### Problema 4: Secret No Se Actualiza en Pod

**Síntoma**:
```bash
# Actualizar Secret
kubectl create secret generic db-secret \
  --from-literal=password=NewPassword \
  --dry-run=client -o yaml | kubectl apply -f -

# Ver variable en Pod
kubectl exec mypod -- echo $DB_PASSWORD
# OldPassword  # ❌ No cambió
```

**Causa**: Variables de entorno **NO se actualizan automáticamente**.

**Solución**:
```bash
# Opción 1: Reiniciar Pod
kubectl delete pod mypod
# El nuevo Pod tendrá el valor actualizado

# Opción 2: Usar volúmenes (actualización automática)
volumeMounts:
- name: secret-volume
  mountPath: /etc/secrets

# Verificar después de ~1 minuto
kubectl exec mypod -- cat /etc/secrets/password
# NewPassword  # ✅ Actualizado automáticamente
```

### Problema 5: Error de Decodificación Base64

**Síntoma**:
```yaml
apiVersion: v1
kind: Secret
data:
  password: MyPassword  # ❌ No está en Base64
```

**Error**:
```bash
kubectl apply -f secret.yaml
# error: illegal base64 data at input byte 0
```

**Solución**:
```yaml
# Opción 1: Codificar manualmente
data:
  password: TXlQYXNzd29yZA==  # echo -n 'MyPassword' | base64

# Opción 2: Usar stringData (recomendado)
stringData:
  password: MyPassword  # ✅ Kubernetes lo codifica automáticamente
```

### Problema 6: Permisos Insuficientes (RBAC)

**Síntoma**:
```bash
kubectl get secrets
# Error from server (Forbidden): secrets is forbidden: 
# User "developer" cannot list resource "secrets" in API group "" in the namespace "production"
```

**Causa**: Usuario/ServiceAccount sin permisos para acceder a Secrets.

**Solución**:
```yaml
# Crear Role con permisos
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]  # Solo lectura
---
# Crear RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-secrets
  namespace: production
subjects:
- kind: User
  name: developer
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

### Problema 7: Secret Inmutable No Se Puede Modificar

**Síntoma**:
```bash
kubectl edit secret immutable-secret
# error: secrets "immutable-secret" is immutable
```

**Solución**:
```bash
# Solo se puede eliminar y recrear
kubectl delete secret immutable-secret

kubectl create secret generic immutable-secret \
  --from-literal=key=newvalue
```

### Problema 8: Secret Muy Grande

**Error**:
```bash
kubectl create secret generic large-secret \
  --from-file=large-file.txt
# Error: Secret "large-secret" is invalid: data: Too long: 
# must have at most 1048576 bytes
```

**Causa**: Límite de 1 MiB por Secret.

**Solución**:
```bash
# Opción 1: Dividir en múltiples Secrets
split -b 1000000 large-file.txt part-
kubectl create secret generic secret-part1 --from-file=part-aa
kubectl create secret generic secret-part2 --from-file=part-ab

# Opción 2: Usar almacenamiento persistente
kubectl create configmap large-data --from-file=large-file.txt
# Y montar como volumen
```

### Comandos Útiles de Diagnóstico

```bash
# Ver todos los Secrets del namespace
kubectl get secrets

# Ver detalles sin valores
kubectl describe secret my-secret

# Ver Secret completo (con valores en Base64)
kubectl get secret my-secret -o yaml

# Decodificar todas las claves
kubectl get secret my-secret -o json | \
  jq -r '.data | to_entries[] | "\(.key): \(.value | @base64d)"'

# Ver qué Pods usan un Secret
kubectl get pods -o json | \
  jq -r '.items[] | select(.spec.volumes[]?.secret.secretName == "my-secret") | .metadata.name'

# Verificar eventos relacionados con Secrets
kubectl get events --field-selector involvedObject.kind=Secret

# Ver logs del Pod con problemas
kubectl logs mypod
kubectl describe pod mypod
```

---

## Laboratorios Prácticos

### 🧪 Laboratorios Prácticos Disponibles

| Lab | Título | Duración | Nivel |
|-----|--------|----------|-------|
| **Lab 01** | [Creación y Consumo Básico de Secrets](./laboratorios/lab-01-secrets-basicos.md) | 30-40 min | Básico |
| **Lab 02** | [Secrets Avanzados y Tipos Especializados](./laboratorios/lab-02-secrets-avanzados.md) | 60 min | Intermedio |
| **Lab 03** | [Seguridad y Troubleshooting](./laboratorios/lab-03-seguridad-troubleshooting.md) | 45-50 min | Avanzado |

#### Lab 01: Creación y Consumo Básico de Secrets
- Crear Secrets con `kubectl create` (literales, archivos)
- Crear Secrets con manifiestos YAML (`data` vs `stringData`)
- Consumir Secrets como variables de entorno
- Montar Secrets como volúmenes
- Base64 encoding/decoding
- Troubleshooting básico

#### Lab 02: Secrets Avanzados y Tipos Especializados
- Secrets TLS para Ingress
- Docker registry secrets (imagePullSecrets)
- Combinación de ConfigMaps y Secrets
- Secrets inmutables y versionamiento
- Workflow seguro con `envsubst`
- Actualización de Secrets sin downtime

#### Lab 03: Seguridad y Troubleshooting
- RBAC para Secrets
- Encriptación en reposo (simulación)
- Errores comunes y soluciones
- Anti-patrones de seguridad
- Rotación de Secrets
- Introducción a External Secrets Operator

---

## Referencias

### 📚 Documentación Oficial

- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Good Practices for Kubernetes Secrets](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
- [Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)
- [Managing Secrets using kubectl](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/)
- [Managing Secrets using Configuration File](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-config-file/)

### 🔗 Recursos Adicionales

- [External Secrets Operator](https://external-secrets.io/)
- [HashiCorp Vault](https://www.vaultproject.io/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [SOPS (Secrets OPerationS)](https://github.com/mozilla/sops)

### 📖 Módulos Relacionados

- [Módulo 13: ConfigMaps y Variables de Entorno](../modulo-13-configmaps-variables/)
- [Módulo 15: Persistent Volumes](../modulo-15-persistent-volumes/) (siguiente)
- [Módulo 11: Deployments](../modulo-11-deployments/)

### 🛠️ Herramientas

- `kubectl` - Cliente de línea de comandos de Kubernetes
- `base64` - Codificación/decodificación Base64
- `envsubst` - Sustitución de variables de entorno
- `jq` - Procesador JSON para consultas
- `kubeseal` - Herramienta para Sealed Secrets

---

## 🎓 Próximos Pasos

Después de completar este módulo, deberías poder:

- ✅ Comprender la diferencia entre Secrets y ConfigMaps
- ✅ Crear Secrets usando múltiples métodos
- ✅ Consumir Secrets de forma segura en Pods
- ✅ Implementar buenas prácticas de seguridad
- ✅ Troubleshoot problemas comunes con Secrets
- ✅ Preparar Secrets para entornos de producción

**Continúa con**: [Módulo 15: Persistent Volumes](../modulo-15-persistent-volumes/)

---

## 📝 Notas Finales

### ⚠️ Advertencias Importantes

1. **Base64 NO es encriptación**: Cualquiera puede decodificar Secrets
2. **Nunca versionar credenciales reales en Git**: Usar placeholders + `envsubst`
3. **Habilitar encriptación en reposo**: Obligatorio para producción
4. **RBAC estricto**: Aplicar principio de menor privilegio
5. **Considerar soluciones externas**: Vault, External Secrets Operator, etc.

### 🎯 Best Practices Summary

```yaml
✓ Usar stringData en desarrollo, data en producción automatizada
✓ Montar Secrets como volúmenes (actualización automática)
✓ Aplicar defaultMode restrictivo (0400)
✓ Usar Secrets inmutables con versionamiento
✓ Separar Secrets por namespace/entorno
✓ Rotar credenciales periódicamente
✓ Auditar accesos a Secrets
✓ Usar Secret Stores externos en producción
```

---

**¡Éxito en tu aprendizaje de Kubernetes Secrets!** 🚀
