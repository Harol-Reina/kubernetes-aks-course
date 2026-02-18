# Laboratorio 1: Crear y Gestionar Service Accounts

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:
- Crear Service Accounts usando comandos kubectl y manifiestos YAML
- Inspeccionar y verificar Service Accounts
- Comprender la diferencia entre el SA `default` y SAs personalizados
- Gestionar el ciclo de vida completo de un Service Account

## ⏱️ Duración Estimada

30-40 minutos

## 📋 Prerrequisitos

- Cluster de Kubernetes funcionando (minikube, AKS, o similar)
- `kubectl` instalado y configurado
- Acceso para crear recursos en al menos un namespace

## 🧪 Ejercicios Prácticos

### Ejercicio 1: Explorar el Service Account Default

Todos los namespaces tienen un Service Account `default` creado automáticamente. Vamos a explorarlo.

**Paso 1:** Listar los Service Accounts en el namespace `default`

```bash
kubectl get serviceaccounts
# o forma corta:
kubectl get sa
```

**Resultado esperado:**
```
NAME      SECRETS   AGE
default   1         30d
```

**Paso 2:** Ver detalles del Service Account `default`

```bash
kubectl describe sa default
```

**Analiza la salida:**
- ¿Qué token tiene asociado?
- ¿Tiene `imagePullSecrets` configurados?
- ¿Qué edad tiene el Service Account?

**Paso 3:** Ver el YAML completo del SA `default`

```bash
kubectl get sa default -o yaml
```

**📝 Tarea:** Identifica en el YAML:
1. El namespace donde existe el SA
2. El nombre del secret asociado al SA
3. Si tiene `automountServiceAccountToken` configurado

---

### Ejercicio 2: Crear tu Primer Service Account (Método Imperativo)

Vamos a crear un Service Account usando comandos `kubectl`.

**Paso 1:** Crear un Service Account llamado `mi-primera-app`

```bash
kubectl create serviceaccount mi-primera-app
```

**Paso 2:** Verificar que se creó correctamente

```bash
kubectl get sa mi-primera-app
kubectl describe sa mi-primera-app
```

**Paso 3:** Ver el secret generado automáticamente

```bash
# Obtener el nombre del secret
SA_SECRET=$(kubectl get sa mi-primera-app -o jsonpath='{.secrets[0].name}')
echo "Secret name: $SA_SECRET"

# Ver el contenido del secret
kubectl get secret $SA_SECRET -o yaml
```

**📝 Pregunta de reflexión:**
¿Qué tres campos principales tiene el secret del Service Account?
<details>
<summary>Ver respuesta</summary>

- `ca.crt`: Certificado de la autoridad certificadora del cluster
- `namespace`: El namespace donde existe el SA
- `token`: El token JWT para autenticación

</details>

**Paso 4:** Generar el YAML de un Service Account sin crearlo

```bash
kubectl create serviceaccount app-staging --dry-run=client -o yaml
```

Esto es útil para ver qué YAML se generaría sin crear el recurso.

**Paso 5:** Limpiar este ejercicio

```bash
kubectl delete sa mi-primera-app
```

---

### Ejercicio 3: Crear Service Account con Manifest YAML

Ahora crearemos un Service Account usando un archivo YAML, el método recomendado para producción.

**Paso 1:** Crear el archivo `mi-app-sa.yaml`

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mi-aplicacion
  namespace: default
  labels:
    app: mi-app
    team: desarrollo
    environment: dev
  annotations:
    description: "Service Account para mi aplicación de prueba"
    created-by: "tu-nombre"
```

**Paso 2:** Aplicar el manifest

```bash
kubectl apply -f mi-app-sa.yaml
```

**Paso 3:** Verificar la creación

```bash
kubectl get sa mi-aplicacion
kubectl describe sa mi-aplicacion
```

**📝 Verifica:**
- ¿Aparecen los labels que definiste?
- ¿Aparecen las annotations?
- ¿Se creó un secret automáticamente?

**Paso 4:** Modificar el Service Account

Edita el archivo `mi-app-sa.yaml` y agrega una nueva annotation:

```yaml
annotations:
  description: "Service Account para mi aplicación de prueba"
  created-by: "tu-nombre"
  updated-at: "2025-11-11"  # Agregar esta línea
```

Aplica el cambio:

```bash
kubectl apply -f mi-app-sa.yaml
```

Verifica que se actualizó:

```bash
kubectl get sa mi-aplicacion -o yaml | grep updated-at
```

---

### Ejercicio 4: Service Accounts en Diferentes Namespaces

Los Service Accounts son recursos con alcance de namespace. Vamos a explorar esto.

**Paso 1:** Crear un nuevo namespace

```bash
kubectl create namespace laboratorio-sa
```

**Paso 2:** Crear el archivo `sa-multi-namespace.yaml`

```yaml
# Service Account en namespace default
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-worker
  namespace: default
  labels:
    role: worker
---
# Service Account en namespace laboratorio-sa
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-worker
  namespace: laboratorio-sa
  labels:
    role: worker
```

**Paso 3:** Aplicar el manifest

```bash
kubectl apply -f sa-multi-namespace.yaml
```

**Paso 4:** Verificar que ambos existen

```bash
# En namespace default
kubectl get sa app-worker -n default

# En namespace laboratorio-sa
kubectl get sa app-worker -n laboratorio-sa

# Listar SAs en todos los namespaces
kubectl get sa --all-namespaces | grep app-worker
```

**📝 Observación importante:**
Puedes tener Service Accounts con el mismo nombre en diferentes namespaces. Son recursos completamente independientes.

---

### Ejercicio 5: Service Account Completo con Configuraciones Avanzadas

Vamos a crear un Service Account con todas las opciones disponibles.

**Paso 1:** Crear el archivo `sa-completo.yaml`

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-api
  namespace: default
  labels:
    app: backend
    tier: api
    environment: development
  annotations:
    description: "Service Account para backend API"
    team: "platform-engineering"
    security-level: "medium"

# Control de montaje automático
automountServiceAccountToken: true
```

**Paso 2:** Aplicar y verificar

```bash
kubectl apply -f sa-completo.yaml
kubectl describe sa backend-api
```

**Paso 3:** Crear una variante sin montaje automático

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: frontend-app
  namespace: default
  labels:
    app: frontend
    tier: web

# Deshabilitar montaje automático (más seguro si no necesita API)
automountServiceAccountToken: false
```

Aplica y compara:

```bash
kubectl apply -f sa-sin-automount.yaml
kubectl describe sa frontend-app
```

**📝 Pregunta:**
¿Cuándo deshabilitarías `automountServiceAccountToken`?
<details>
<summary>Ver respuesta</summary>

Cuando tu aplicación NO necesita acceder a la API de Kubernetes. Esto mejora la seguridad reduciendo la superficie de ataque. Ejemplos:
- Aplicaciones estáticas (nginx sirviendo HTML/CSS/JS)
- Aplicaciones que solo reciben tráfico HTTP
- Aplicaciones legacy que no están diseñadas para Kubernetes

</details>

---

### Ejercicio 6: Inspección Avanzada de Tokens

Vamos a explorar los tokens de Service Account en detalle.

**Paso 1:** Obtener el token de un Service Account

```bash
# Obtener el nombre del secret
SECRET_NAME=$(kubectl get sa mi-aplicacion -o jsonpath='{.secrets[0].name}')

# Extraer y decodificar el token
TOKEN=$(kubectl get secret $SECRET_NAME -o jsonpath='{.data.token}' | base64 -d)

# Mostrar el token (será muy largo)
echo $TOKEN
```

**Paso 2:** Ver el namespace almacenado en el secret

```bash
kubectl get secret $SECRET_NAME -o jsonpath='{.data.namespace}' | base64 -d
echo ""
```

**Paso 3:** Ver el certificado CA

```bash
kubectl get secret $SECRET_NAME -o jsonpath='{.data.ca\.crt}' | base64 -d
```

**⚠️ Nota de Seguridad:**
Los tokens son credenciales sensibles. Nunca los compartas en código, logs, o repositorios públicos.

---

### Ejercicio 7: Gestión del Ciclo de Vida

Practica operaciones comunes de gestión.

**Paso 1:** Listar todos los Service Accounts creados en este lab

```bash
kubectl get sa --show-labels
```

**Paso 2:** Filtrar por label

```bash
kubectl get sa -l environment=dev
kubectl get sa -l app=backend
```

**Paso 3:** Editar un Service Account interactivamente

```bash
kubectl edit sa mi-aplicacion
```

Esto abre un editor. Puedes modificar labels, annotations, etc.

**Paso 4:** Exportar un SA a archivo YAML

```bash
kubectl get sa mi-aplicacion -o yaml > mi-aplicacion-backup.yaml
```

Esto es útil para backups o migración a otros clusters.

**Paso 5:** Eliminar Service Accounts uno por uno

```bash
kubectl delete sa mi-aplicacion
kubectl delete sa app-worker -n default
kubectl delete sa app-worker -n laboratorio-sa
kubectl delete sa backend-api
kubectl delete sa frontend-app
```

**Paso 6:** Limpiar el namespace

```bash
kubectl delete namespace laboratorio-sa
```

---

## ✅ Verificación de Aprendizaje

Responde estas preguntas sin mirar las respuestas:

1. ¿Cuál es el Service Account que se usa por defecto si no especificas uno?
2. ¿Los Service Accounts son recursos con alcance de namespace o cluster?
3. ¿Qué tres archivos principales se montan cuando un pod usa un Service Account?
4. ¿Cuál es la diferencia entre crear un SA con `kubectl create` vs. un manifest YAML?
5. ¿Qué hace el campo `automountServiceAccountToken: false`?

<details>
<summary>Ver respuestas</summary>

1. El Service Account llamado `default` en el namespace correspondiente
2. Namespace-scoped (cada SA pertenece a un namespace específico)
3. `token` (JWT), `ca.crt` (certificado CA), y `namespace` (nombre del namespace)
4. `kubectl create` es imperativo (rápido para pruebas), manifest YAML es declarativo (recomendado para producción, permite versionamiento)
5. Previene que Kubernetes monte automáticamente el token del SA en los pods (mejora seguridad si la app no necesita API)

</details>

---

## 🎓 Conceptos Clave Aprendidos

- ✅ Cada namespace tiene un SA `default` creado automáticamente
- ✅ Los Service Accounts generan secrets con tokens JWT automáticamente
- ✅ Los SAs son recursos con alcance de namespace
- ✅ Puedes controlar el montaje automático de tokens
- ✅ El método declarativo (YAML) es preferido para producción

---

## 🚀 Desafío Extra (Opcional)

Crea una estructura completa de Service Accounts para una aplicación con tres ambientes:

1. **Desarrollo**: `app-dev` (configuración permisiva)
2. **Staging**: `app-staging` (configuración intermedia)
3. **Producción**: `app-prod` (configuración restrictiva, sin automount)

Usa labels apropiados para identificar cada ambiente y annotations para documentar el propósito de cada SA.

---

## 📚 Recursos Adicionales

- [Documentación oficial de Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [Ejemplos del módulo](../ejemplos/)
- Siguiente laboratorio: [Lab 02 - Tokens y Autenticación](./lab-02-tokens-autenticacion.md)

---

**¡Felicitaciones!** Has completado el laboratorio sobre creación y gestión de Service Accounts. Ahora estás listo para explorar cómo los tokens funcionan y cómo asignar permisos en el siguiente laboratorio.
