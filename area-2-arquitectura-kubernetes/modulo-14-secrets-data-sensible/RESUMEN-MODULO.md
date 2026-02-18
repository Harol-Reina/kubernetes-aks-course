# 📚 RESUMEN - Módulo 14: Secrets - Gestión de Datos Sensibles

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre la **gestión segura de datos sensibles** en Kubernetes usando Secrets. Aprenderás a almacenar contraseñas, tokens, certificados TLS y credenciales de forma segura, entendiendo las diferencias con ConfigMaps y las limitaciones de seguridad de base64.

**Duración**: 4.5 horas (teoría + práctica)  
**Nivel**: Intermedio-Avanzado  
**Prerequisitos**: Pods, ConfigMaps, Namespaces, conceptos de seguridad

---

## 📋 Objetivos de Aprendizaje

### Fundamentos
- ✅ Entender qué son los Secrets y cuándo usarlos vs ConfigMaps
- ✅ Conocer tipos de Secrets (Opaque, TLS, docker-registry, SA-token)
- ✅ Comprender limitaciones de base64 (encoding ≠ encryption)
- ✅ Saber cómo se actualizan Secrets en Pods

### Técnico
- ✅ Crear Secrets (literales, archivos, YAML, TLS)
- ✅ Consumir Secrets como env vars y volumes
- ✅ Configurar imagePullSecrets para registros privados
- ✅ Gestionar certificados TLS para Ingress
- ✅ Aplicar Secrets inmutables

### Avanzado
- ✅ Implementar RBAC para proteger Secrets
- ✅ Habilitar encryption at rest
- ✅ Integrar Sealed Secrets o Vault
- ✅ Diseñar estrategias de rotación de credenciales
- ✅ Auditar acceso a Secrets

---

## 🗺️ Estructura de Aprendizaje

### Fase 1: Introducción a Secrets (20 min)
**Teoría**: Sección 1 del README

#### ¿Qué es un Secret?

**Secret** = Objeto de Kubernetes para almacenar **datos sensibles** (passwords, tokens, certs).

**Usos típicos**:
- 🔑 Contraseñas de bases de datos
- 🎫 API keys, JWT tokens
- 🔐 Certificados TLS y claves privadas
- 📧 Credenciales de registros Docker
- 🗝️ Claves SSH

#### Características Clave

**Namespace-scoped**: Secrets existen dentro de un namespace.

```bash
# Secret en namespace 'production'
kubectl create secret generic db-secret \
  --from-literal=password=secret123 \
  -n production

# NO es accesible desde namespace 'development'
```

**Base64 encoded**: Datos se codifican en base64 (NO es cifrado).

```bash
echo -n "password123" | base64
# cGFzc3dvcmQxMjM=

echo "cGFzc3dvcmQxMjM=" | base64 -d
# password123  ← Fácil de decodificar
```

**⚠️ Base64 ≠ Encryption**: Cualquiera con acceso al Secret puede decodificarlo.

---

### Fase 2: Secrets vs ConfigMaps (15 min)
**Teoría**: Sección 2 del README

#### Comparación Directa

| Aspecto | Secret | ConfigMap |
|---------|--------|-----------|
| **Propósito** | Datos sensibles | Configuración pública |
| **Codificación** | Base64 | Texto plano |
| **Ejemplos** | Passwords, tokens, certs | DB host, URLs, flags |
| **Seguridad** | RBAC + encryption at rest | RBAC básico |
| **Visibilidad** | Oculto en `kubectl get` | Visible |
| **Límite tamaño** | 1 MiB | 1 MiB |

#### Cuándo Usar Cada Uno

**✅ Usar Secret para**:
- Contraseñas de bases de datos
- API keys, OAuth tokens
- Certificados TLS/SSL
- Claves privadas SSH/GPG
- Credenciales de servicios externos

**✅ Usar ConfigMap para**:
- URLs de servicios
- Niveles de log (debug, info)
- Feature flags
- Archivos de configuración (nginx.conf, app.properties)
- Cualquier dato que puede ser público

**⚠️ Regla de oro**: Si lo verías en un `.env.example` (ejemplo público) → ConfigMap. Si está en `.env` (privado) → Secret.

---

### Fase 3: Tipos de Secrets (30 min)
**Teoría**: Sección 3 del README

#### 1. Opaque (Generic)

**Tipo por defecto** para datos arbitrarios.

```bash
kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123
```

**YAML**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque    # ← Tipo genérico
data:
  username: YWRtaW4=           # base64("admin")
  password: c2VjcmV0MTIz       # base64("secret123")
```

**Verificar**:
```bash
kubectl get secret my-secret -o yaml

# Decodificar
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d
# secret123
```

---

#### 2. kubernetes.io/tls

**Para certificados TLS** (HTTPS, Ingress).

**Requiere 2 archivos**:
- `tls.crt` - Certificado público
- `tls.key` - Clave privada

**Crear**:
```bash
# Generar certificado autofirmado (testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=example.com/O=MyOrg"

# Crear Secret TLS
kubectl create secret tls my-tls-secret \
  --cert=tls.crt \
  --key=tls.key
```

**YAML**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-tls-secret
type: kubernetes.io/tls
data:
  tls.crt: <base64-cert>
  tls.key: <base64-key>
```

**Usar en Ingress**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
spec:
  tls:
  - hosts:
    - example.com
    secretName: my-tls-secret    # ← Secret TLS
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
```

---

#### 3. kubernetes.io/dockerconfigjson

**Para autenticación en registros privados** (Docker Hub, ACR, ECR, GCR).

**Crear**:
```bash
kubectl create secret docker-registry my-registry-secret \
  --docker-server=docker.io \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=user@example.com
```

**Usar en Pod** (imagePullSecrets):
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myuser/private-image:1.0    # Imagen privada
  imagePullSecrets:
  - name: my-registry-secret           # ← Credenciales
```

**Sin imagePullSecrets**:
```bash
kubectl get pods
# myapp   0/1   ImagePullBackOff   ← Error: no credentials
```

**Con imagePullSecrets**:
```bash
kubectl get pods
# myapp   1/1   Running   ← Funciona
```

---

#### 4. kubernetes.io/service-account-token

**Tokens de Service Account** (creados automáticamente por K8s).

**Ver token de SA**:
```bash
# Ver Service Account
kubectl get serviceaccount default -o yaml

# Ver Secret asociado (K8s <1.24)
kubectl get secret

# K8s 1.24+: tokens no se crean automáticamente
# Crear manualmente:
kubectl create token default
```

---

### Fase 4: Creación de Secrets (40 min)
**Teoría**: Sección 4 del README

#### Método 1: Desde Literales (inline)

```bash
kubectl create secret generic app-secret \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASSWORD=secret123 \
  --from-literal=API_KEY=abc123xyz
```

**Verificar**:
```bash
kubectl get secret app-secret -o yaml

# data:
#   DB_USER: YWRtaW4=
#   DB_PASSWORD: c2VjcmV0MTIz
#   API_KEY: YWJjMTIzeHl6
```

---

#### Método 2: Desde Archivos

**Crear archivos**:
```bash
echo -n "admin" > username.txt
echo -n "secret123" > password.txt
```

**Opción A**: Clave = nombre de archivo
```bash
kubectl create secret generic app-secret \
  --from-file=username.txt \
  --from-file=password.txt
```

**Resultado**:
```yaml
data:
  username.txt: YWRtaW4=
  password.txt: c2VjcmV0MTIz
```

**Opción B**: Clave personalizada
```bash
kubectl create secret generic app-secret \
  --from-file=DB_USER=username.txt \
  --from-file=DB_PASSWORD=password.txt
```

**Resultado**:
```yaml
data:
  DB_USER: YWRtaW4=
  DB_PASSWORD: c2VjcmV0MTIz
```

---

#### Método 3: YAML Declarativo (con data)

**Codificar valores**:
```bash
echo -n "admin" | base64
# YWRtaW4=

echo -n "secret123" | base64
# c2VjcmV0MTIz
```

**YAML**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  DB_USER: YWRtaW4=           # ← base64
  DB_PASSWORD: c2VjcmV0MTIz  # ← base64
```

```bash
kubectl apply -f secret.yaml
```

---

#### Método 4: YAML con stringData (más fácil)

**stringData** = valores en texto plano (K8s convierte a base64 automáticamente).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
stringData:              # ← Texto plano
  DB_USER: admin
  DB_PASSWORD: secret123
```

```bash
kubectl apply -f secret.yaml

# Verificar (K8s lo convirtió a base64)
kubectl get secret app-secret -o yaml
# data:
#   DB_USER: YWRtaW4=
#   DB_PASSWORD: c2VjcmV0MTIz
```

**✅ Ventaja**: No necesitas codificar manualmente a base64.  
**⚠️ Advertencia**: Texto plano en archivo YAML (no commitear a Git).

---

### Fase 5: Consumo de Secrets (40 min)
**Teoría**: Sección 5 del README

#### Opción 1: Como Variables de Entorno Individuales

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: DB_USER
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: DB_PASSWORD
```

**Verificar**:
```bash
kubectl exec myapp -- printenv DB_USER
# admin

kubectl exec myapp -- printenv DB_PASSWORD
# secret123
```

---

#### Opción 2: Todas las Claves como Env Vars (envFrom)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    envFrom:
    - secretRef:
        name: app-secret    # ← Todas las claves del Secret
```

**Resultado**: Todas las claves del Secret se convierten en variables de entorno.

```bash
kubectl exec myapp -- env | grep DB_
# DB_USER=admin
# DB_PASSWORD=secret123
```

---

#### Opción 3: Como Volumen (Archivos)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets    # ← Directorio de montaje
      readOnly: true             # ← Buena práctica
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secret
```

**Resultado en el contenedor**:
```bash
kubectl exec myapp -- ls /etc/secrets
# DB_PASSWORD
# DB_USER

kubectl exec myapp -- cat /etc/secrets/DB_USER
# admin

kubectl exec myapp -- cat /etc/secrets/DB_PASSWORD
# secret123
```

**Cada clave del Secret = 1 archivo**.

---

#### Opción 4: Archivos Específicos con subPath

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/db-password
      subPath: DB_PASSWORD       # ← Solo este archivo
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secret
      items:
      - key: DB_PASSWORD
        path: DB_PASSWORD
```

**Resultado**: Solo `/etc/db-password` (un archivo).

---

#### Comparación: Env Vars vs Volumes

| Aspecto | Env Vars | Volumes |
|---------|----------|---------|
| **Uso** | Valores simples | Archivos (certs, keys) |
| **Actualización** | ❌ No (requiere restart) | ✅ Sí (automático ~60s) |
| **Visibilidad** | Visibles en procesos | Archivos protegidos |
| **Formato** | KEY=value | Archivos individuales |
| **Seguridad** | Logs pueden exponerlos | Más seguro (readOnly) |

**Recomendación**:
- **Env vars**: Passwords simples, API keys
- **Volumes**: Certificados TLS, claves SSH, configs complejas

---

### Fase 6: Base64 y Seguridad (25 min)
**Teoría**: Sección 6 del README

#### ⚠️ Limitaciones de Seguridad

**Base64 NO es cifrado**:
```bash
# Cualquiera con acceso puede decodificar
kubectl get secret app-secret -o yaml
# data:
#   DB_PASSWORD: c2VjcmV0MTIz

echo "c2VjcmV0MTIz" | base64 -d
# secret123  ← ¡Expuesto!
```

#### Vectores de Ataque

1. **kubectl get secret** con permisos RBAC
2. **etcd sin cifrado** (almacenamiento en texto plano)
3. **Logs de aplicación** exponen env vars
4. **Git commits** con Secrets en YAML

#### Mitigaciones

**1. RBAC estricto**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]    # ← Solo lectura, NO create/update/delete
```

**2. Encryption at Rest**:
```bash
# Habilitar cifrado en etcd (requiere configuración del clúster)
# Ver documentación: https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
```

**3. Herramientas Externas**:
- **Sealed Secrets**: Cifra Secrets para Git
- **HashiCorp Vault**: Gestión centralizada de secretos
- **External Secrets Operator**: Sincroniza con AWS Secrets Manager, Azure Key Vault, etc.

**4. Auditoría**:
```bash
# Auditar acceso a Secrets
kubectl get events --all-namespaces | grep secret
```

---

### Fase 7: Secrets Inmutables (20 min)
**Teoría**: Sección 7 del README

#### ¿Qué son Secrets Inmutables?

**Inmutable** = No se puede modificar después de crear (K8s 1.21+).

**Beneficios**:
- ✅ **Performance**: kubelet no necesita watch cambios
- ✅ **Seguridad**: Previene modificaciones accidentales/maliciosas
- ✅ **Estabilidad**: Credenciales no cambian bajo los Pods

**Crear inmutable**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
immutable: true      # ← Inmutable
stringData:
  DB_PASSWORD: secret123
```

**Intentar modificar**:
```bash
kubectl edit secret app-secret
# Error: field is immutable
```

**Para cambiar**: Eliminar y recrear (o crear nueva versión).

```bash
kubectl delete secret app-secret
kubectl apply -f app-secret-v2.yaml
```

#### Estrategia: Secrets Versionados

```yaml
# Versión 1
apiVersion: v1
kind: Secret
metadata:
  name: app-secret-v1
  labels:
    version: "1"
immutable: true
stringData:
  API_KEY: old-key-abc123
---
# Deployment usa v1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: app
        envFrom:
        - secretRef:
            name: app-secret-v1
```

**Rotación de credenciales**:
```bash
# Crear nueva versión
kubectl apply -f app-secret-v2.yaml

# Actualizar Deployment
kubectl set env deployment/myapp --from=secret/app-secret-v2 --overwrite

# Rollout
kubectl rollout restart deployment/myapp

# Eliminar versión antigua (después de verificar)
kubectl delete secret app-secret-v1
```

---

### Fase 8: Buenas Prácticas (45 min)
**Teoría**: Sección 8 del README

#### 1. Nunca Commitear Secrets a Git

**❌ MAL**:
```bash
git add secret.yaml
git commit -m "Add database credentials"
git push origin main
# ¡Secrets expuestos en GitHub!
```

**✅ BIEN**:
```bash
# .gitignore
*secret*.yaml
.env
credentials/
```

**Alternativa**: Sealed Secrets
```bash
# Cifrar Secret para Git
kubeseal -f secret.yaml -w sealed-secret.yaml

# Commitear versión cifrada
git add sealed-secret.yaml
```

---

#### 2. Usar RBAC para Proteger Secrets

**Role mínimo** (solo lectura de Secrets específicos):
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-secret-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["app-secret"]    # ← Solo este Secret
  verbs: ["get"]                   # ← Solo lectura
```

**Binding**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-secret-reader-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: myapp-sa
roleRef:
  kind: Role
  name: app-secret-reader
  apiGroup: rbac.authorization.k8s.io
```

---

#### 3. Separar Secrets por Entorno

**Estructura**:
```
secrets/
├── dev/
│   ├── db-secret.yaml
│   └── api-secret.yaml
├── staging/
│   ├── db-secret.yaml
│   └── api-secret.yaml
└── prod/
    ├── db-secret.yaml
    └── api-secret.yaml
```

**Aplicar según entorno**:
```bash
kubectl apply -f secrets/dev/ -n development
kubectl apply -f secrets/prod/ -n production
```

---

#### 4. Montar Secrets como Volumes (más seguro)

**❌ MENOS seguro** (env vars):
```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: app-secret
      key: DB_PASSWORD
```

**Problema**: Variables de entorno pueden aparecer en logs, `/proc/*/environ`, etc.

**✅ MÁS seguro** (volumes):
```yaml
volumeMounts:
- name: secrets
  mountPath: /etc/secrets
  readOnly: true    # ← ReadOnly
volumes:
- name: secrets
  secret:
    secretName: app-secret
    defaultMode: 0400    # ← Permisos restrictivos
```

**Ventaja**: Archivos protegidos, no visibles en procesos.

---

#### 5. Usar Secrets Inmutables en Producción

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: prod-db-secret
  namespace: production
type: Opaque
immutable: true    # ← Producción
stringData:
  password: secure-prod-password
```

---

#### 6. Rotar Credenciales Periódicamente

**Estrategia**:
1. Crear Secret versionado (`db-secret-v2`)
2. Actualizar Deployment para usar `v2`
3. Rollout del Deployment
4. Verificar funcionamiento
5. Eliminar Secret `v1`

**Automatización**: Usar herramientas como Vault para rotación automática.

---

#### 7. Auditar Acceso a Secrets

**Habilitar audit logging** (nivel clúster):
```yaml
# kube-apiserver audit policy
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets"]
  verbs: ["get", "list", "watch"]
```

**Revisar logs**:
```bash
kubectl logs -n kube-system kube-apiserver-* | grep secret
```

---

#### 8. Usar External Secrets Operator (Producción)

**Integrar con servicios externos**:
- AWS Secrets Manager
- Azure Key Vault
- Google Secret Manager
- HashiCorp Vault

**Ejemplo** (External Secrets Operator):
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
  target:
    name: app-secret    # K8s Secret a crear
  data:
  - secretKey: DB_PASSWORD
    remoteRef:
      key: prod/db-password
```

**Ventaja**: Secrets nunca se almacenan en Git o etcd sin cifrar.

---

### Fase 9: Troubleshooting (30 min)
**Teoría**: Sección 9 del README

#### Problema 1: Secret no existe

**Síntoma**:
```bash
kubectl get pods
# myapp   0/1   CreateContainerConfigError   0   10s
```

**Diagnóstico**:
```bash
kubectl describe pod myapp

# Warning  Failed  secret "app-secret" not found
```

**Solución**:
```bash
# Verificar namespace correcto
kubectl get secret app-secret -n production

# Crear si falta
kubectl create secret generic app-secret \
  --from-literal=password=secret123 \
  -n production
```

---

#### Problema 2: Clave no existe en Secret

**Síntoma**: Pod en `CreateContainerConfigError`

**Diagnóstico**:
```bash
kubectl describe pod myapp

# Error: key "DB_PASSWORD" not found in Secret "app-secret"
```

**Solución**:
```bash
# Ver claves del Secret
kubectl get secret app-secret -o yaml

# Agregar clave faltante
kubectl create secret generic app-secret \
  --from-literal=DB_PASSWORD=secret123 \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

#### Problema 3: ImagePullBackOff (falta imagePullSecret)

**Síntoma**:
```bash
kubectl get pods
# myapp   0/1   ImagePullBackOff   0   2m
```

**Diagnóstico**:
```bash
kubectl describe pod myapp

# Failed to pull image "private.registry.io/myapp:1.0": 
# unauthorized: authentication required
```

**Solución**:
```bash
# Crear imagePullSecret
kubectl create secret docker-registry my-registry \
  --docker-server=private.registry.io \
  --docker-username=myuser \
  --docker-password=mypassword

# Agregar a Deployment
kubectl patch deployment myapp -p \
  '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"my-registry"}]}}}}'
```

---

#### Problema 4: Secret actualizado pero Pod no cambia

**Síntoma**: Cambios en Secret no se reflejan en el Pod.

**Causa**: Env vars no se actualizan automáticamente.

**Solución A** (restart):
```bash
kubectl rollout restart deployment myapp
```

**Solución B** (volumes - actualización automática):
```yaml
# Cambiar de env vars a volume
volumeMounts:
- name: secrets
  mountPath: /etc/secrets
volumes:
- name: secrets
  secret:
    secretName: app-secret
```

---

#### Problema 5: Permisos RBAC insuficientes

**Síntoma**:
```bash
kubectl get secret
# Error from server (Forbidden): secrets is forbidden: 
# User "system:serviceaccount:default:myapp-sa" cannot list resource "secrets"
```

**Solución**:
```bash
# Crear Role con permisos
kubectl create role secret-reader \
  --verb=get,list \
  --resource=secrets

# Binding a ServiceAccount
kubectl create rolebinding secret-reader-binding \
  --role=secret-reader \
  --serviceaccount=default:myapp-sa
```

---

#### Problema 6: Secret inmutable no se puede editar

**Síntoma**:
```bash
kubectl edit secret app-secret
# Error: field is immutable
```

**Solución**:
```bash
# Opción 1: Eliminar y recrear
kubectl delete secret app-secret
kubectl create secret generic app-secret \
  --from-literal=password=new-password

# Opción 2: Crear nueva versión
kubectl create secret generic app-secret-v2 \
  --from-literal=password=new-password

# Actualizar Deployment
kubectl set env deployment/myapp --from=secret/app-secret-v2
```

---

## 📝 Comandos Esenciales - Cheat Sheet

### Crear Secrets

```bash
# Desde literales
kubectl create secret generic <name> \
  --from-literal=KEY1=value1 \
  --from-literal=KEY2=value2

# Desde archivos
kubectl create secret generic <name> \
  --from-file=KEY=path/to/file \
  --from-file=path/to/file2

# Secret TLS
kubectl create secret tls <name> \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key

# Docker registry
kubectl create secret docker-registry <name> \
  --docker-server=<server> \
  --docker-username=<user> \
  --docker-password=<password> \
  --docker-email=<email>

# Desde YAML
kubectl apply -f secret.yaml
```

### Ver Secrets

```bash
# Listar Secrets
kubectl get secrets

# Ver contenido (base64)
kubectl get secret <name> -o yaml

# Decodificar clave específica
kubectl get secret <name> -o jsonpath='{.data.KEY}' | base64 -d

# Describir (sin mostrar valores)
kubectl describe secret <name>
```

### Usar en Pods

```bash
# Verificar env vars
kubectl exec <pod> -- env

# Ver archivo montado
kubectl exec <pod> -- cat /etc/secrets/KEY

# Listar archivos
kubectl exec <pod> -- ls -la /etc/secrets/
```

### Actualizar Secrets

```bash
# Editar (si no es inmutable)
kubectl edit secret <name>

# Patch
kubectl patch secret <name> -p \
  '{"stringData":{"KEY":"new-value"}}'

# Recrear
kubectl delete secret <name>
kubectl create secret generic <name> --from-literal=KEY=value
```

### Troubleshooting

```bash
# Ver eventos del Pod
kubectl describe pod <name>

# Ver logs
kubectl logs <name>

# Verificar permisos RBAC
kubectl auth can-i get secrets

# Verificar Secret existe
kubectl get secret <name>

# Ver qué ServiceAccount usa el Pod
kubectl get pod <name> -o jsonpath='{.spec.serviceAccountName}'
```

---

## 🎯 Conceptos Clave para Recordar

### Secrets vs ConfigMaps

```
SECRET:
  - Datos sensibles (passwords, tokens, certs)
  - Base64 encoded
  - RBAC + encryption at rest

CONFIGMAP:
  - Configuración pública (URLs, flags)
  - Texto plano
  - RBAC básico
```

### Base64 ≠ Encryption

```
Base64:  Encoding (reversible fácilmente)
Encryption:  Cifrado (requiere clave para descifrar)

⚠️ Cualquiera con acceso a Secret puede decodificar base64
```

### Tipos de Secrets

```
Opaque:                    Datos genéricos
kubernetes.io/tls:         Certificados TLS
kubernetes.io/dockerconfigjson:  Credenciales Docker registry
kubernetes.io/service-account-token:  Tokens SA
```

### Consumo: Env Vars vs Volumes

```
ENV VARS:
  - Valores simples
  - ❌ No se actualizan automáticamente
  - ⚠️ Visibles en logs/procesos

VOLUMES:
  - Archivos (certs, keys)
  - ✅ Se actualizan automáticamente
  - ✅ Más seguros (readOnly)
```

### Secrets Inmutables

```
immutable: true
  ✅ Mejor performance
  ✅ Previene cambios maliciosos
  ❌ No se puede editar (eliminar y recrear)
```

---

## ✅ Checklist de Dominio

### Fundamentos
- [ ] Entiendo qué son Secrets y cuándo usarlos vs ConfigMaps
- [ ] Conozco los 4 tipos principales de Secrets
- [ ] Sé que base64 NO es cifrado
- [ ] Comprendo namespace-scoped de Secrets

### Creación
- [ ] Puedo crear Secret Opaque desde literales
- [ ] Sé crear Secret desde archivos
- [ ] Puedo crear Secret TLS con certificados
- [ ] Sé crear imagePullSecret para registros privados
- [ ] Conozco diferencia entre data y stringData

### Consumo
- [ ] Puedo consumir Secret como env vars individuales
- [ ] Sé usar envFrom para todas las claves
- [ ] Puedo montar Secret como volumen
- [ ] Sé usar subPath para archivos específicos
- [ ] Entiendo diferencia seguridad env vars vs volumes

### Seguridad
- [ ] Sé configurar RBAC para proteger Secrets
- [ ] Entiendo encryption at rest
- [ ] Conozco Sealed Secrets o Vault
- [ ] Sé separar Secrets por entorno
- [ ] Aplico principio de least privilege

### Actualizaciones
- [ ] Entiendo cuándo se actualizan env vars (nunca)
- [ ] Sé que volumes se actualizan automáticamente (~60s)
- [ ] Puedo versionar Secrets
- [ ] Sé hacer rollout restart de Deployments

### Inmutabilidad
- [ ] Sé crear Secrets inmutables
- [ ] Entiendo ventajas (performance, seguridad)
- [ ] Puedo gestionar Secrets versionados
- [ ] Sé cuándo aplicar inmutabilidad (producción)

### Troubleshooting
- [ ] Diagnostico "Secret not found"
- [ ] Resuelvo "key not found in Secret"
- [ ] Soluciono ImagePullBackOff
- [ ] Sé forzar actualización de Pods
- [ ] Verifico permisos RBAC

### Práctica
- [ ] Apliqué Secrets en apps propias
- [ ] Configuré imagePullSecrets
- [ ] Gestioné certificados TLS para Ingress
- [ ] Implementé RBAC para Secrets
- [ ] Exploré Sealed Secrets o Vault

---

## 🎓 Evaluación Final

### Preguntas Clave
1. ¿Cuál es la diferencia entre Secret y ConfigMap?
2. ¿Por qué base64 NO es seguro?
3. ¿Qué tipos de Secrets existen y para qué sirven?
4. ¿Cómo usar imagePullSecrets?
5. ¿Cuándo usar Secrets inmutables?
6. ¿Cómo proteger Secrets con RBAC?

<details>
<summary>Ver Respuestas</summary>

1. **Secret vs ConfigMap**:
   - **Secret**: Datos sensibles (passwords, tokens), base64, RBAC + encryption
   - **ConfigMap**: Configuración pública (URLs, flags), texto plano
   - Regla: Si está en `.env` → Secret, si está en `.env.example` → ConfigMap

2. **Base64 NO es seguro**:
   - Base64 es **encoding**, no cifrado
   - Cualquiera puede decodificar: `echo "base64string" | base64 -d`
   - Necesitas: RBAC, encryption at rest, herramientas externas (Vault)

3. **Tipos de Secrets**:
   - **Opaque**: Genérico (passwords, API keys)
   - **kubernetes.io/tls**: Certificados TLS para Ingress/HTTPS
   - **kubernetes.io/dockerconfigjson**: Credenciales registros privados
   - **kubernetes.io/service-account-token**: Tokens de Service Account

4. **imagePullSecrets**:
   ```bash
   # Crear
   kubectl create secret docker-registry my-registry \
     --docker-server=registry.io \
     --docker-username=user \
     --docker-password=pass
   
   # Usar en Pod
   spec:
     imagePullSecrets:
     - name: my-registry
   ```

5. **Secrets inmutables**:
   - **Cuándo**: Producción, configuración estable
   - **Por qué**: Performance (no watch), seguridad (no modificación)
   - **Cómo**: `immutable: true` en YAML
   - **Cambiar**: Eliminar y recrear, o crear nueva versión

6. **RBAC para Secrets**:
   ```yaml
   # Role mínimo
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: secret-reader
   rules:
   - apiGroups: [""]
     resources: ["secrets"]
     resourceNames: ["app-secret"]  # Específico
     verbs: ["get"]                 # Solo lectura
   ```

</details>

---

## 🔗 Recursos Adicionales

### Documentación Oficial
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Distribute Credentials Securely](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/)
- [Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

### Ejemplos del Módulo
- [`ejemplos/01-secrets-basicos/`](ejemplos/01-secrets-basicos/) - Secret Opaque
- [`ejemplos/02-secrets-literales/`](ejemplos/02-secrets-literales/) - Creación con literales
- [`ejemplos/03-secrets-archivos/`](ejemplos/03-secrets-archivos/) - Desde archivos
- [`ejemplos/04-secrets-env/`](ejemplos/04-secrets-env/) - Como env vars
- [`ejemplos/05-secrets-volume/`](ejemplos/05-secrets-volume/) - Como volúmenes
- [`ejemplos/06-secrets-tls/`](ejemplos/06-secrets-tls/) - Certificados TLS
- [`ejemplos/07-secrets-docker-registry/`](ejemplos/07-secrets-docker-registry/) - imagePullSecrets
- [`ejemplos/08-combinados/`](ejemplos/08-combinados/) - Múltiples tipos

### Herramientas Externas
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) - Cifrado para Git
- [HashiCorp Vault](https://www.vaultproject.io/) - Gestión centralizada
- [External Secrets Operator](https://external-secrets.io/) - Sincronización con cloud providers

### Siguiente Módulo
➡️ Módulo 15: Volumes - Conceptos y Almacenamiento Persistente

---

## 🎉 ¡Felicitaciones!

Has completado el Módulo 14 de Secrets. Ahora puedes:

- ✅ Gestionar datos sensibles en Kubernetes
- ✅ Crear Secrets (Opaque, TLS, docker-registry)
- ✅ Consumir Secrets (env vars, volumes)
- ✅ Configurar imagePullSecrets para registros privados
- ✅ Aplicar Secrets inmutables
- ✅ Implementar RBAC y buenas prácticas de seguridad
- ✅ Troubleshoot problemas comunes

**⚠️ Recuerda**: Base64 ≠ Encryption. Usa RBAC, encryption at rest y herramientas externas para seguridad real.

**Próximos pasos**:
1. Revisar este resumen periódicamente
2. Practicar con los 8 ejemplos del módulo
3. Migrar credenciales hardcoded a Secrets
4. Explorar Sealed Secrets o Vault
5. Continuar con Módulo 15: Volumes

¡Sigue adelante! 🚀
