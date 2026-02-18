# Lab 01: Secret Básico - Creación y Uso

## 📋 Información del Laboratorio

- **Módulo**: 14 - Secrets & Sensitive Data
- **Laboratorio**: 01 - Secret Básico
- **Dificultad**: 🟢 Principiante
- **Tiempo estimado**: 15-20 minutos

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:
- ✅ Crear un Secret usando `kubectl create secret`
- ✅ Almacenar datos sensibles (usuario/contraseña) en un Secret
- ✅ Montar un Secret como volumen en un Pod
- ✅ Leer valores del Secret desde archivos dentro del contenedor
- ✅ Verificar que los datos están codificados en base64
- ✅ Eliminar Secrets de forma segura

## 📚 Prerrequisitos

Antes de comenzar, asegúrate de haber completado:
- ✅ [SETUP.md](./SETUP.md) - Configuración del entorno
- ✅ Módulo 04: Pods vs Contenedores
- ✅ Módulo 13: ConfigMaps y Variables de Entorno

## 🔧 Escenario del Laboratorio

Vas a crear una aplicación web simple que necesita credenciales de base de datos. En lugar de hardcodear el usuario y contraseña en el código o en el manifiesto YAML, usarás un **Secret** para almacenar estos datos sensibles de forma segura.

---

## 📝 Paso 1: Crear un Secret con Credenciales de BD

### 1.1. Crear Secret Imperativo (Método Rápido)

```bash
# Crear un secret con usuario y contraseña
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=SuperSecretPass123
```

**Explicación**:
- `generic`: Tipo de secret para datos arbitrarios
- `db-credentials`: Nombre del secret
- `--from-literal`: Define pares clave-valor directamente

### 1.2. Verificar que el Secret fue Creado

```bash
# Listar secrets en el namespace
kubectl get secrets

# Ver detalles del secret (datos están ocultos)
kubectl describe secret db-credentials
```

**Salida esperada**:
```
NAME              TYPE     DATA   AGE
db-credentials    Opaque   2      10s
```

### 1.3. Ver el Secret en Formato YAML

```bash
# Ver el secret completo
kubectl get secret db-credentials -o yaml
```

**Observa**:
- Los valores están codificados en **base64** (no encriptados)
- `type: Opaque` indica datos genéricos

### 1.4. Decodificar Valores (Solo para Verificación)

```bash
# Decodificar el username
kubectl get secret db-credentials -o jsonpath='{.data.username}' | base64 --decode
echo

# Decodificar el password
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 --decode
echo
```

**Salida esperada**:
```
admin
SuperSecretPass123
```

---

## 📝 Paso 2: Usar el Secret en un Pod (Volume Mount)

### 2.1. Crear Manifiesto del Pod

Crea el archivo `pod-with-secret.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-db
  labels:
    app: myapp
spec:
  containers:
  - name: app-container
    image: nginx:alpine
    volumeMounts:
    - name: db-secrets
      mountPath: /etc/db-config
      readOnly: true
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "=== Database Credentials Loaded ==="
        echo "Username: $(cat /etc/db-config/username)"
        echo "Password: $(cat /etc/db-config/password)"
        echo "==================================="
        echo "Starting application..."
        nginx -g 'daemon off;'
  
  volumes:
  - name: db-secrets
    secret:
      secretName: db-credentials
```

**Explicación**:
- `volumeMounts`: Monta el secret como archivos en `/etc/db-config/`
- `readOnly: true`: Seguridad - los secrets son solo lectura
- `volumes.secret`: Referencia al secret `db-credentials`
- Cada clave del secret se convierte en un archivo

### 2.2. Aplicar el Manifiesto

```bash
# Crear el pod
kubectl apply -f pod-with-secret.yaml

# Esperar a que esté running
kubectl wait --for=condition=Ready pod/app-with-db --timeout=60s
```

### 2.3. Verificar los Logs

```bash
# Ver que la app leyó las credenciales
kubectl logs app-with-db
```

**Salida esperada**:
```
=== Database Credentials Loaded ===
Username: admin
Password: SuperSecretPass123
===================================
Starting application...
```

---

## 📝 Paso 3: Explorar el Secret Dentro del Pod

### 3.1. Conectarse al Pod

```bash
# Abrir shell interactivo
kubectl exec -it app-with-db -- sh
```

### 3.2. Verificar Archivos del Secret (Dentro del Pod)

```bash
# Listar archivos del secret
ls -la /etc/db-config/

# Leer el username
cat /etc/db-config/username

# Leer el password
cat /etc/db-config/password

# Salir del pod
exit
```

**Observaciones**:
- Cada clave del secret es un **archivo separado**
- Los nombres de archivo coinciden con las claves
- Los valores están **decodificados** automáticamente
- Son archivos de solo lectura (seguridad)

---

## 📝 Paso 4: Crear Secret desde YAML (Método Declarativo)

### 4.1. Codificar Valores Manualmente

```bash
# Codificar valores en base64
echo -n 'admin' | base64
echo -n 'SuperSecretPass123' | base64
```

**Salida**:
```
YWRtaW4=
U3VwZXJTZWNyZXRQYXNzMTIz
```

### 4.2. Crear Manifiesto del Secret

Crea el archivo `db-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials-yaml
type: Opaque
data:
  username: YWRtaW4=
  password: U3VwZXJTZWNyZXRQYXNzMTIz
```

**Nota**: Los valores deben estar en **base64**

### 4.3. Aplicar el Secret

```bash
# Crear el secret
kubectl apply -f db-secret.yaml

# Verificar
kubectl get secret db-credentials-yaml
```

---

## ✅ Verificación del Laboratorio

### Checklist de Validación

Ejecuta estos comandos para verificar que todo funciona:

```bash
# 1. Secret existe y tiene 2 datos
kubectl get secret db-credentials -o jsonpath='{.data}' | jq

# 2. Pod está running
kubectl get pod app-with-db -o wide

# 3. Pod puede leer el secret
kubectl exec app-with-db -- cat /etc/db-config/username

# 4. Valores son correctos
kubectl exec app-with-db -- cat /etc/db-config/password
```

**Resultados esperados**:
- ✅ Secret tiene 2 claves (username, password)
- ✅ Pod en estado `Running`
- ✅ Username retorna `admin`
- ✅ Password retorna `SuperSecretPass123`

---

## 🧹 Limpieza de Recursos

### Opción 1: Script Automático

```bash
# Ejecutar script de limpieza
./cleanup.sh
```

### Opción 2: Limpieza Manual

```bash
# Eliminar pod
kubectl delete pod app-with-db

# Eliminar secrets
kubectl delete secret db-credentials
kubectl delete secret db-credentials-yaml

# Eliminar archivos YAML
rm -f pod-with-secret.yaml db-secret.yaml

# Verificar limpieza
kubectl get pods,secrets
```

---

## 🔍 Troubleshooting

### Problema 1: Pod en estado `Pending`

**Síntoma**:
```bash
kubectl get pods
# app-with-db   0/1   Pending
```

**Solución**:
```bash
# Ver eventos del pod
kubectl describe pod app-with-db

# Verificar que el secret existe
kubectl get secret db-credentials
```

### Problema 2: Error "secret not found"

**Síntoma**:
```
Error: secret "db-credentials" not found
```

**Solución**:
```bash
# Recrear el secret
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=SuperSecretPass123
```

### Problema 3: Archivos del Secret Vacíos

**Síntoma**:
```bash
kubectl exec app-with-db -- cat /etc/db-config/username
# (sin salida)
```

**Solución**:
```bash
# Verificar que el secret tiene datos
kubectl get secret db-credentials -o yaml

# Eliminar y recrear el pod
kubectl delete pod app-with-db
kubectl apply -f pod-with-secret.yaml
```

---

## 📖 Conceptos Clave Aprendidos

### ✅ Secrets vs ConfigMaps

| Característica | Secrets | ConfigMaps |
|---------------|---------|------------|
| **Propósito** | Datos sensibles | Configuración no sensible |
| **Codificación** | Base64 | Plain text |
| **Seguridad** | Más protección | Sin protección especial |
| **Uso típico** | Passwords, tokens | URLs, flags, configs |

### ✅ Tipos de Secrets

- **Opaque**: Datos genéricos (este lab)
- **kubernetes.io/service-account-token**: Tokens de ServiceAccount
- **kubernetes.io/dockerconfigjson**: Credenciales de registry
- **kubernetes.io/tls**: Certificados TLS

### ✅ Mejores Prácticas

- ✅ Usa `readOnly: true` al montar secrets
- ✅ No hagas commit de secrets en Git
- ✅ Usa RBAC para limitar acceso a secrets
- ✅ Considera encryption at rest para clusters productivos
- ✅ Rota secrets regularmente

---

## 🎓 Preguntas de Repaso

1. **¿Los Secrets están encriptados por defecto?**
   - No, están codificados en base64 (reversible)
   - Necesitas habilitar encryption at rest en etcd

2. **¿Cuál es la diferencia entre `--from-literal` y `--from-file`?**
   - `--from-literal`: Valor directo en CLI
   - `--from-file`: Lee valor de un archivo

3. **¿Por qué usar `readOnly: true` en volumeMounts?**
   - Seguridad: previene modificación accidental
   - Los secrets no deben ser mutables por la app

4. **¿Cómo evitar que secrets aparezcan en logs?**
   - No los imprimas directamente
   - Usa herramientas de secret management (Vault, etc.)

---

## 📚 Recursos Adicionales

- [Kubernetes Secrets Docs](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Best Practices for Secrets](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
- [Encryption at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

---

## 🚀 Siguiente Paso

Continúa con:
- **[Lab 02: Secret from File](../lab-02-secret-from-file/README.md)** - Crear secrets desde archivos
- **[Lab 03: Secret como Variables de Entorno](../lab-03-secret-env-vars/README.md)** - Usar secrets como env vars

---

## 📝 Notas

- Este lab usa secrets básicos (tipo Opaque)
- En producción, considera usar herramientas como HashiCorp Vault
- Base64 NO es encriptación, solo codificación
- Habilita encryption at rest en clusters productivos

**¡Buen trabajo!** 🎉 Has aprendido a crear y usar Secrets básicos en Kubernetes.
