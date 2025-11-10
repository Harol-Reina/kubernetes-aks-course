# Ejemplos Prácticos - Módulo 14: Secrets

## 📂 Estructura de Ejemplos

```
ejemplos/
├── 01-secrets-basicos/          # Secrets Opaque básicos
├── 02-secrets-literales/        # Creación con kubectl create --from-literal
├── 03-secrets-archivos/         # Creación desde archivos
├── 04-secrets-env/              # Consumo como variables de entorno
├── 05-secrets-volume/           # Montaje como volúmenes
├── 06-secrets-tls/              # Certificados TLS
├── 07-secrets-docker-registry/  # Credenciales Docker
└── 08-combinados/               # Casos de uso avanzados
```

---

## 🎯 Ruta de Aprendizaje Recomendada

### Nivel 1: Fundamentos (01-03)
1. **01-secrets-basicos/** - Entender `data` vs `stringData`
2. **02-secrets-literales/** - Creación rápida con kubectl
3. **03-secrets-archivos/** - Importar desde archivos existentes

### Nivel 2: Consumo (04-05)
4. **04-secrets-env/** - Variables de entorno (individual y envFrom)
5. **05-secrets-volume/** - Montaje como archivos

### Nivel 3: Especializado (06-07)
6. **06-secrets-tls/** - HTTPS con Ingress
7. **07-secrets-docker-registry/** - Imágenes privadas

### Nivel 4: Avanzado (08)
8. **08-combinados/** - Inmutabilidad, versionamiento, envsubst

---

## 📁 Descripción de Directorios

### 01-secrets-basicos/

**Propósito**: Comprender la estructura básica de Secrets y diferencias entre `data` y `stringData`.

**Archivos**:
- `secret-opaque-data.yaml` - Secret con valores Base64 manuales
- `secret-opaque-stringdata.yaml` - Secret con valores en texto plano

**Conceptos clave**:
- Tipo `Opaque` (genérico)
- Codificación Base64
- Ventajas de `stringData`

**Comandos**:
```bash
cd 01-secrets-basicos/

# Aplicar Secrets
kubectl apply -f secret-opaque-data.yaml
kubectl apply -f secret-opaque-stringdata.yaml

# Verificar
kubectl get secrets
kubectl describe secret basic-secret-data
kubectl get secret basic-secret-stringdata -o yaml

# Decodificar valores
kubectl get secret basic-secret-data -o jsonpath='{.data.password}' | base64 --decode
```

---

### 02-secrets-literales/

**Propósito**: Creación rápida de Secrets desde línea de comandos.

**Archivos**:
- `create-from-literal.sh` - Script con múltiples ejemplos

**Conceptos clave**:
- Comando `kubectl create secret generic`
- Flag `--from-literal`
- Caracteres especiales en valores

**Comandos**:
```bash
cd 02-secrets-literales/

# Ejecutar script de ejemplos
chmod +x create-from-literal.sh
./create-from-literal.sh

# Ver Secrets creados
kubectl get secrets
kubectl get secret multi-secret -o yaml

# Limpiar
kubectl delete secret simple-secret multi-secret special-chars-secret
```

---

### 03-secrets-archivos/

**Propósito**: Crear Secrets desde archivos existentes.

**Archivos**:
- `credentials.txt` - Credenciales de base de datos
- `api-token.txt` - Token JWT de ejemplo
- `create-from-files.sh` - Script de creación

**Conceptos clave**:
- Flag `--from-file`
- Nombres de claves personalizados
- Importar directorios completos

**Comandos**:
```bash
cd 03-secrets-archivos/

# Ejecutar script
chmod +x create-from-files.sh
./create-from-files.sh

# Ver contenido decodificado
kubectl get secret custom-key-secret -o jsonpath='{.data.db-credentials}' | base64 --decode

# Limpiar
kubectl delete secret file-secret custom-key-secret multi-file-secret
```

---

### 04-secrets-env/

**Propósito**: Consumir Secrets como variables de entorno en Pods.

**Archivos**:
- `pod-env-individual.yaml` - Mapeo de claves individuales
- `pod-env-all.yaml` - Importar todas las claves con `envFrom`
- `deployment-multi-secrets.yaml` - Combinar ConfigMaps y Secrets

**Conceptos clave**:
- `env.valueFrom.secretKeyRef` (clave individual)
- `envFrom.secretRef` (todas las claves)
- Combinación con ConfigMaps

**Comandos**:
```bash
cd 04-secrets-env/

# Ejemplo 1: Claves individuales
kubectl apply -f pod-env-individual.yaml
kubectl logs app-env-individual
kubectl exec app-env-individual -- env | grep DATABASE

# Ejemplo 2: Todas las claves
kubectl apply -f pod-env-all.yaml
kubectl logs app-env-all

# Ejemplo 3: Múltiples fuentes
kubectl apply -f deployment-multi-secrets.yaml
kubectl logs -l app=myapp --tail=30

# Limpiar
kubectl delete -f pod-env-individual.yaml
kubectl delete -f pod-env-all.yaml
kubectl delete -f deployment-multi-secrets.yaml
```

---

### 05-secrets-volume/

**Propósito**: Montar Secrets como archivos en volúmenes.

**Archivos**:
- `pod-volume-all.yaml` - Montar todas las claves
- `pod-volume-selective.yaml` - Montar claves específicas con renombrado
- `deployment-nginx-secrets.yaml` - Nginx con actualización automática

**Conceptos clave**:
- Montaje de volúmenes
- Campo `items` para selección
- `defaultMode` (permisos)
- Actualización automática vs `subPath`

**Comandos**:
```bash
cd 05-secrets-volume/

# Ejemplo 1: Montar todas las claves
kubectl apply -f pod-volume-all.yaml
kubectl exec app-volume-all -- ls -la /etc/secrets/
kubectl exec app-volume-all -- cat /etc/secrets/password

# Ejemplo 2: Montaje selectivo
kubectl apply -f pod-volume-selective.yaml
kubectl exec app-volume-selective -- ls -la /etc/db-creds/
kubectl exec app-volume-selective -- cat /etc/db-creds/user.txt

# Ejemplo 3: Nginx con actualización
kubectl apply -f deployment-nginx-secrets.yaml
kubectl exec deployment/nginx-with-secrets -- cat /etc/nginx/secrets/.htpasswd

# Probar actualización automática:
kubectl create secret generic nginx-htpasswd \
  --from-literal=.htpasswd='newuser:$apr1$xyz$NewHash' \
  --dry-run=client -o yaml | kubectl apply -f -

# Esperar ~1 minuto y verificar
kubectl exec deployment/nginx-with-secrets -- cat /etc/nginx/secrets/.htpasswd

# Limpiar
kubectl delete -f pod-volume-all.yaml
kubectl delete -f pod-volume-selective.yaml
kubectl delete -f deployment-nginx-secrets.yaml
```

---

### 06-secrets-tls/

**Propósito**: Certificados TLS para HTTPS (Ingress).

**Archivos**:
- `create-tls-secret.sh` - Generar certificados autofirmados
- `ingress-tls.yaml` - Ingress con TLS habilitado

**Conceptos clave**:
- Tipo `kubernetes.io/tls`
- Campos `tls.crt` y `tls.key`
- Uso con Ingress

**Requisitos**:
- OpenSSL instalado
- Ingress Controller (nginx, traefik, etc.)

**Comandos**:
```bash
cd 06-secrets-tls/

# Generar certificados y crear Secret
chmod +x create-tls-secret.sh
./create-tls-secret.sh

# Ver información del certificado
kubectl get secret tls-secret -o jsonpath='{.data.tls\.crt}' | \
  base64 --decode | openssl x509 -text -noout

# Aplicar Ingress
kubectl apply -f ingress-tls.yaml
kubectl get ingress myapp-ingress
kubectl describe ingress myapp-ingress

# Limpiar
kubectl delete -f ingress-tls.yaml
kubectl delete secret tls-secret
rm tls.key tls.crt  # Archivos locales
```

---

### 07-secrets-docker-registry/

**Propósito**: Credenciales para pull de imágenes privadas.

**Archivos**:
- `create-registry-secret.sh` - Crear Secret tipo `dockerconfigjson`
- `pod-imagepullsecrets.yaml` - Pod y Deployment con imagePullSecrets

**Conceptos clave**:
- Tipo `kubernetes.io/dockerconfigjson`
- Campo `imagePullSecrets` en Pods
- Configuración en ServiceAccount

**Comandos**:
```bash
cd 07-secrets-docker-registry/

# Crear Secret de registro
chmod +x create-registry-secret.sh
./create-registry-secret.sh

# Ver Secret decodificado
kubectl get secret my-registry-secret -o jsonpath='{.data.\.dockerconfigjson}' | \
  base64 --decode | jq '.'

# Aplicar Pod con imagePullSecrets
kubectl apply -f pod-imagepullsecrets.yaml
kubectl describe pod private-image-pod | grep -A5 "Events:"
kubectl get sa myapp-serviceaccount -o yaml

# Limpiar
kubectl delete -f pod-imagepullsecrets.yaml
kubectl delete secret my-registry-secret
```

---

### 08-combinados/

**Propósito**: Casos de uso avanzados y buenas prácticas.

**Archivos**:
- `secret-template.yaml` - Template con placeholders para `envsubst`
- `immutable-secrets-versioning.yaml` - Secrets inmutables versionados

**Conceptos clave**:
- Workflow seguro con `envsubst`
- Secrets inmutables (`immutable: true`)
- Estrategia de versionamiento
- Blue-Green deployment

**Comandos**:
```bash
cd 08-combinados/

# Ejemplo 1: Template con envsubst
export DB_HOST="postgres.prod.svc.cluster.local"
export DB_USER="admin"
export DB_PASSWORD="RealPasswordFromVault"
export API_KEY="sk_live_real_key"
export JWT_SECRET="jwt_secret_key"
export ENCRYPTION_KEY="encryption_key_32_chars"
export ENVIRONMENT="production"
export NAMESPACE="default"

envsubst < secret-template.yaml | kubectl apply -f -
kubectl get secret secure-app-secret -o yaml

# Ejemplo 2: Secrets inmutables
kubectl apply -f immutable-secrets-versioning.yaml

# Ver Secrets inmutables
kubectl get secrets -l app=myapp
kubectl describe secret db-credentials-v1

# Intentar modificar (fallará)
kubectl patch secret db-credentials-v1 -p '{"stringData":{"password":"newpass"}}'
# Error: secrets "db-credentials-v1" is forbidden: immutable field

# Ver Deployments con diferentes versiones
kubectl get deployments -l app=myapp
kubectl logs -l secret-version=v1 --tail=5
kubectl logs -l secret-version=v2 --tail=5

# Limpiar
kubectl delete deployment myapp-v1 myapp-v2
kubectl delete secret db-credentials-v1 db-credentials-v2 secure-app-secret
```

---

## 🔧 Herramientas Necesarias

```bash
# Verificar instalación de herramientas
kubectl version --client
base64 --version
envsubst --version  # Instalar: apt-get install gettext-base
jq --version        # Instalar: apt-get install jq
openssl version
```

---

## 📝 Notas Importantes

### ⚠️ Seguridad

1. **NUNCA versionar credenciales reales en Git**
2. Usar `envsubst` con templates para entornos de producción
3. Habilitar encriptación en reposo (etcd)
4. Aplicar RBAC estricto
5. Considerar External Secrets Operator para producción

### 🔄 Actualización de Secrets

- **Variables de entorno**: NO se actualizan automáticamente (requiere reinicio del Pod)
- **Volúmenes sin `subPath`**: Se actualizan automáticamente (~1 minuto)
- **Volúmenes con `subPath`**: NO se actualizan automáticamente

### 🎯 Mejores Prácticas

- Usar `stringData` en desarrollo, automatizar `data` en producción
- Montar Secrets como `readOnly: true`
- Aplicar `defaultMode: 0400` (solo lectura para owner)
- Usar Secrets inmutables con versionamiento en producción
- Separar Secrets por namespace/entorno

---

## 🚀 Siguiente Paso

Después de completar estos ejemplos, continúa con los **laboratorios prácticos**:

- [Lab 01: Creación y Consumo Básico](../laboratorios/lab-01-secrets-basicos.md)
- [Lab 02: Secrets Avanzados](../laboratorios/lab-02-secrets-avanzados.md)
- [Lab 03: Seguridad y Troubleshooting](../laboratorios/lab-03-seguridad-troubleshooting.md)

---

## 📚 Referencias

- [Documentación Principal](../README.md)
- [Kubernetes Secrets Docs](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Security Best Practices](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
