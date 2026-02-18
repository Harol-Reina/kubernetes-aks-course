# Lab 03: Secret como Variables de Entorno

## 📋 Información del Laboratorio

- **Módulo**: 14 - Secrets & Sensitive Data
- **Laboratorio**: 03 - Secret as Environment Variables
- **Dificultad**: 🟢 Principiante
- **Tiempo estimado**: 15-20 minutos

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:
- ✅ Inyectar secrets como variables de entorno en pods
- ✅ Usar `envFrom` para cargar todos los valores de un secret
- ✅ Usar `env` con `secretKeyRef` para valores individuales
- ✅ Combinar múltiples secrets en un solo pod
- ✅ Entender cuándo usar volumes vs env vars

## 📚 Prerrequisitos

- ✅ [SETUP.md](./SETUP.md) - Configuración del entorno
- ✅ Lab 01: Secret Básico
- ✅ Lab 02: Secret from File

## 🔧 Escenario del Laboratorio

Vas a crear una aplicación que se conecta a:
1. Una base de datos PostgreSQL
2. Un servicio de email (SMTP)
3. Una API externa

Cada servicio requiere credenciales que almacenarás en secrets separados e inyectarás como variables de entorno.

---

## 📝 Paso 1: Crear Múltiples Secrets

### 1.1. Secret para Base de Datos

```bash
kubectl create secret generic db-config \
  --from-literal=DB_HOST=postgres.example.com \
  --from-literal=DB_PORT=5432 \
  --from-literal=DB_NAME=myapp_production \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASSWORD=SecureP@ssw0rd123
```

### 1.2. Secret para Email (SMTP)

```bash
kubectl create secret generic smtp-config \
  --from-literal=SMTP_HOST=smtp.gmail.com \
  --from-literal=SMTP_PORT=587 \
  --from-literal=SMTP_USER=myapp@example.com \
  --from-literal=SMTP_PASSWORD=EmailP@ss456
```

### 1.3. Secret para API Externa

```bash
kubectl create secret generic api-credentials \
  --from-literal=API_KEY=sk_live_1234567890abcdefghijklmnop \
  --from-literal=API_SECRET=secret_abcdefghijklmnop1234567890
```

### 1.4. Verificar Secrets Creados

```bash
kubectl get secrets

kubectl describe secret db-config
kubectl describe secret smtp-config
kubectl describe secret api-credentials
```

---

## 📝 Paso 2: Inyectar Secret Completo con envFrom

### 2.1. Crear Pod con envFrom

Crea `pod-envfrom.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-envfrom
  labels:
    app: myapp
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "=== Database Configuration ==="
        echo "Host: $DB_HOST"
        echo "Port: $DB_PORT"
        echo "Database: $DB_NAME"
        echo "User: $DB_USER"
        echo "Password: [HIDDEN]"
        echo
        echo "=== SMTP Configuration ==="
        echo "Host: $SMTP_HOST"
        echo "Port: $SMTP_PORT"
        echo "User: $SMTP_USER"
        echo
        echo "=== API Configuration ==="
        echo "API Key: ${API_KEY:0:20}..."
        echo
        echo "Sleeping..."
        sleep 3600
    
    envFrom:
    - secretRef:
        name: db-config
    - secretRef:
        name: smtp-config
    - secretRef:
        name: api-credentials
```

**Explicación**:
- `envFrom`: Inyecta TODAS las claves del secret como env vars
- Se pueden especificar múltiples secrets
- Nombres de claves se convierten en nombres de variables

### 2.2. Aplicar y Verificar

```bash
kubectl apply -f pod-envfrom.yaml

kubectl wait --for=condition=Ready pod/app-envfrom --timeout=30s

kubectl logs app-envfrom
```

**Salida esperada**:
```
=== Database Configuration ===
Host: postgres.example.com
Port: 5432
Database: myapp_production
User: admin
Password: [HIDDEN]

=== SMTP Configuration ===
Host: smtp.gmail.com
Port: 587
User: myapp@example.com

=== API Configuration ===
API Key: sk_live_1234567890ab...
```

---

## 📝 Paso 3: Inyectar Valores Individuales con env

### 3.1. Crear Pod con env y secretKeyRef

Crea `pod-env-selective.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-selective
  labels:
    app: myapp
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "Database connection string:"
        echo "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"
        echo
        echo "Email from: $SMTP_USER"
        echo "API authentication: Bearer $API_KEY"
        sleep 3600
    
    env:
    # Database credentials (valores individuales)
    - name: DB_HOST
      valueFrom:
        secretKeyRef:
          name: db-config
          key: DB_HOST
    
    - name: DB_PORT
      valueFrom:
        secretKeyRef:
          name: db-config
          key: DB_PORT
    
    - name: DB_NAME
      valueFrom:
        secretKeyRef:
          name: db-config
          key: DB_NAME
    
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-config
          key: DB_USER
    
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-config
          key: DB_PASSWORD
    
    # SMTP (solo usuario)
    - name: SMTP_USER
      valueFrom:
        secretKeyRef:
          name: smtp-config
          key: SMTP_USER
    
    # API (solo key)
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: api-credentials
          key: API_KEY
```

**Ventajas**:
- Control granular sobre qué valores se inyectan
- Puedes combinar secrets y configmaps
- Puedes renombrar variables

### 3.2. Aplicar y Verificar

```bash
kubectl apply -f pod-env-selective.yaml

kubectl logs app-selective
```

---

## 📝 Paso 4: Combinar Secrets, ConfigMaps y Valores Literales

### 4.1. Crear ConfigMap para Configuración No Sensible

```bash
kubectl create configmap app-config \
  --from-literal=APP_NAME="MyApp Production" \
  --from-literal=LOG_LEVEL=info \
  --from-literal=ENVIRONMENT=production
```

### 4.2. Crear Pod Mixto

Crea `pod-combined.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-combined
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "Application: $APP_NAME"
        echo "Environment: $ENVIRONMENT"
        echo "Log Level: $LOG_LEVEL"
        echo "Version: $APP_VERSION"
        echo
        echo "Database: $DB_HOST:$DB_PORT/$DB_NAME"
        echo "User: $DB_USER"
        echo
        sleep 3600
    
    env:
    # Valor literal (hardcoded)
    - name: APP_VERSION
      value: "v1.2.3"
    
    # Desde ConfigMap
    - name: APP_NAME
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_NAME
    
    - name: ENVIRONMENT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: ENVIRONMENT
    
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: LOG_LEVEL
    
    # Desde Secret
    - name: DB_HOST
      valueFrom:
        secretKeyRef:
          name: db-config
          key: DB_HOST
    
    - name: DB_PORT
      valueFrom:
        secretKeyRef:
          name: db-config
          key: DB_PORT
    
    - name: DB_NAME
      valueFrom:
        secretKeyRef:
          name: db-config
          key: DB_NAME
    
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-config
          key: DB_USER
```

### 4.3. Aplicar y Verificar

```bash
kubectl apply -f pod-combined.yaml

kubectl logs app-combined
```

---

## 📝 Paso 5: Verificar Variables de Entorno Dentro del Pod

### 5.1. Listar Todas las Variables

```bash
kubectl exec app-envfrom -- env | sort
```

### 5.2. Buscar Variables Específicas

```bash
# Variables de base de datos
kubectl exec app-envfrom -- env | grep ^DB_

# Variables de SMTP
kubectl exec app-envfrom -- env | grep ^SMTP_

# Variables de API
kubectl exec app-envfrom -- env | grep ^API_
```

### 5.3. Verificar Valor de Variable Individual

```bash
# Ver password de BD (cuidado en producción!)
kubectl exec app-envfrom -- printenv DB_PASSWORD

# Ver API key
kubectl exec app-envfrom -- printenv API_KEY
```

---

## ✅ Verificación del Laboratorio

```bash
# 1. Todos los secrets existen
kubectl get secrets db-config smtp-config api-credentials

# 2. Todos los pods running
kubectl get pods -l app=myapp

# 3. Variables inyectadas correctamente
kubectl exec app-envfrom -- printenv DB_HOST
kubectl exec app-selective -- printenv SMTP_USER
kubectl exec app-combined -- printenv ENVIRONMENT

# 4. Logs muestran configuración
kubectl logs app-envfrom | head -15
```

---

## 🧹 Limpieza

```bash
./cleanup.sh
```

---

## 📖 Conceptos Clave

### ✅ envFrom vs env

| Método | Uso | Ventajas | Desventajas |
|--------|-----|----------|-------------|
| **envFrom** | Todo el secret | Rápido, menos código | Sin control granular |
| **env + secretKeyRef** | Valores selectivos | Control total | Más verboso |

### ✅ Cuándo Usar Env Vars vs Volumes

**Variables de Entorno**:
- ✅ Configuración simple (URLs, passwords)
- ✅ 12-factor apps
- ✅ Valores pequeños (<1KB)

**Volúmenes**:
- ✅ Archivos grandes (certificados, configs)
- ✅ Múltiples archivos relacionados
- ✅ Necesidad de recargar sin reiniciar pod

### ✅ Mejores Prácticas

- ✅ No imprimas secrets en logs
- ✅ Usa nombres descriptivos de variables
- ✅ Agrupa secrets relacionados
- ✅ Documenta qué secret provee qué variable
- ✅ Considera external secret managers (Vault)

---

## 🎓 Preguntas de Repaso

1. **¿Qué hace envFrom?**
   - Inyecta TODAS las claves de un secret como env vars

2. **¿Cuándo usar env vs envFrom?**
   - `env`: Cuando necesitas solo algunos valores
   - `envFrom`: Cuando necesitas todo el secret

3. **¿Puedes combinar secrets y configmaps?**
   - Sí, puedes usar múltiples sources

4. **¿Las env vars se actualizan si cambias el secret?**
   - No, necesitas recrear el pod

---

## 🚀 Módulo Completado

¡Felicidades! Has completado el **Módulo 14: Secrets & Sensitive Data**

**Lo que aprendiste**:
- ✅ Crear secrets con kubectl y YAML
- ✅ Crear secrets desde archivos
- ✅ Montar secrets como volúmenes
- ✅ Inyectar secrets como env vars
- ✅ Combinar múltiples sources de configuración

**Siguiente**: [Módulo 15: Volumes - Conceptos](../../modulo-15-volumes-conceptos/README.md)
