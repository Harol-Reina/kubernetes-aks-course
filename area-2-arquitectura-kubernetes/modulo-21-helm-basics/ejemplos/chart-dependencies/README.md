# 📦 Chart con Dependencias (Subcharts)

Chart de ejemplo que demuestra cómo usar **dependencias externas** (subcharts) de Bitnami para PostgreSQL y Redis.

## 🎯 Objetivo

Aprender a:
- Declarar dependencias en `Chart.yaml`
- Gestionar subcharts externos
- Pasar valores a subcharts
- Conectar aplicación con servicios de subcharts
- Habilitar/deshabilitar componentes

## 📁 Estructura

```
chart-dependencies/
├── Chart.yaml              # Incluye dependencies[]
├── values.yaml             # Config para chart padre y subcharts
├── README.md
├── .helmignore
├── charts/                 # Subcharts descargados (generado)
│   ├── postgresql-12.x.x.tgz
│   └── redis-17.x.x.tgz
└── templates/
    ├── deployment.yaml     # App que usa PostgreSQL y Redis
    ├── service.yaml
    ├── configmap.yaml      # Script de inicialización DB
    └── NOTES.txt
```

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────┐
│  chart-dependencies (Chart padre)       │
│                                         │
│  ┌─────────────┐                       │
│  │   App       │ (deployment)          │
│  │   NGINX     │                       │
│  └─────┬───────┘                       │
│        │                               │
│        │ Conecta via ENV VARS          │
│        │                               │
│  ┌─────▼─────────┐  ┌───────────────┐ │
│  │ PostgreSQL    │  │    Redis      │ │
│  │ (subchart)    │  │  (subchart)   │ │
│  │ Bitnami       │  │  Bitnami      │ │
│  └───────────────┘  └───────────────┘ │
└─────────────────────────────────────────┘
```

## 🚀 Uso

### 1. Descargar Dependencias

Antes de instalar, descarga los subcharts:

```bash
cd chart-dependencies

# Ver dependencias declaradas
helm dependency list

# Descargar subcharts de Bitnami
helm dependency update

# Verificar que se descargaron
ls -la charts/
# postgresql-12.x.x.tgz
# redis-17.x.x.tgz
```

### 2. Instalar el Chart Completo

```bash
# Instalar con todos los componentes
helm install myapp .

# Ver todo lo desplegado
kubectl get all -l release=myapp

# Output esperado:
# - Deployment: myapp-myapp (app principal)
# - StatefulSet: myapp-postgresql (database)
# - Deployment: myapp-redis-master (cache)
# - Services para cada componente
# - PVC para PostgreSQL
# - Secrets para credenciales
```

### 3. Verificar Conectividad

```bash
# Ver variables de entorno de la app
kubectl exec -it deployment/myapp-myapp -- env | grep -E "DATABASE|REDIS"

# Output esperado:
# DATABASE_HOST=myapp-postgresql
# DATABASE_PORT=5432
# DATABASE_USER=appuser
# DATABASE_PASSWORD=changeme123
# DATABASE_NAME=appdb
# REDIS_HOST=myapp-redis-master
# REDIS_PORT=6379
```

### 4. Conectar a PostgreSQL

```bash
# Via pod temporal
kubectl run -i --tty --rm debug --image=postgres:14 --restart=Never -- \
  psql -h myapp-postgresql -U appuser -d appdb

# Via port-forward
kubectl port-forward svc/myapp-postgresql 5432:5432 &
psql -h localhost -U appuser -d appdb
# Password: changeme123

# Verificar tablas creadas por init script
\dt
# users
# sessions
```

### 5. Conectar a Redis

```bash
# Via pod temporal
kubectl run -i --tty --rm debug --image=redis:7 --restart=Never -- \
  redis-cli -h myapp-redis-master

# Via port-forward
kubectl port-forward svc/myapp-redis-master 6379:6379 &
redis-cli -h localhost

# Comandos Redis
> PING
PONG
> SET test "hello from helm"
OK
> GET test
"hello from helm"
```

## ⚙️ Configuración

### Habilitar/Deshabilitar Componentes

```bash
# Solo app + PostgreSQL (sin Redis)
helm install myapp . --set redis.enabled=false

# Solo app + Redis (sin PostgreSQL)
helm install myapp . --set postgresql.enabled=false

# Solo app (sin dependencias)
helm install myapp . \
  --set postgresql.enabled=false \
  --set redis.enabled=false
```

### Configurar PostgreSQL

```bash
# Cambiar credenciales
helm install myapp . \
  --set postgresql.auth.username=myuser \
  --set postgresql.auth.password=mypass123 \
  --set postgresql.auth.database=mydb

# Cambiar tamaño de persistencia
helm install myapp . \
  --set postgresql.primary.persistence.size=20Gi

# Deshabilitar persistencia (SOLO PARA DESARROLLO)
helm install myapp . \
  --set postgresql.primary.persistence.enabled=false
```

### Configurar Redis

```bash
# Habilitar autenticación
helm install myapp . \
  --set redis.auth.enabled=true \
  --set redis.auth.password=redis123

# Cambiar arquitectura a replication
helm install myapp . \
  --set redis.architecture=replication \
  --set redis.replica.replicaCount=2
```

### Archivo de Valores Custom

Crea `my-values.yaml`:

```yaml
app:
  replicaCount: 3
  image:
    tag: "1.23.0"

postgresql:
  enabled: true
  auth:
    username: produser
    password: prod_password_123
    database: production_db
  primary:
    persistence:
      size: 50Gi
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"

redis:
  enabled: true
  auth:
    enabled: true
    password: redis_prod_pass
  master:
    persistence:
      enabled: true
      size: 5Gi
```

Instalar con valores custom:

```bash
helm install myapp . -f my-values.yaml
```

## 📊 Gestión de Dependencias

### Ver Información de Dependencias

```bash
# Listar dependencias
helm dependency list

# Output:
# NAME       VERSION  REPOSITORY                              STATUS
# postgresql 12.x.x   https://charts.bitnami.com/bitnami     ok
# redis      17.x.x   https://charts.bitnami.com/bitnami     ok
```

### Actualizar Versiones

Edita `Chart.yaml`:

```yaml
dependencies:
  - name: postgresql
    version: "13.0.0"  # Especificar versión exacta
    repository: "https://charts.bitnami.com/bitnami"
```

Luego actualiza:

```bash
helm dependency update
```

### Usar Subcharts Locales

Puedes copiar un chart local en `charts/`:

```bash
mkdir -p charts
cp -r ../otro-chart charts/
```

### Eliminar Dependencias

```bash
# Eliminar charts descargados
rm -rf charts/*.tgz

# Volver a descargar
helm dependency update
```

## 🔍 Inspeccionar Subcharts

```bash
# Ver valores por defecto de PostgreSQL
helm show values bitnami/postgresql

# Ver valores por defecto de Redis
helm show values bitnami/redis

# Ver todos los recursos que se crearán
helm template myapp . | less

# Contar recursos por tipo
helm template myapp . | grep "^kind:" | sort | uniq -c
```

## 📈 Casos de Uso Reales

### 1. Stack de Desarrollo Local

```bash
# Todo en memoria (sin persistencia)
helm install dev . \
  --set postgresql.primary.persistence.enabled=false \
  --set redis.master.persistence.enabled=false
```

### 2. Stack de Staging

```bash
# Con persistencia pequeña
helm install staging . \
  --set app.replicaCount=2 \
  --set postgresql.primary.persistence.size=10Gi \
  --set redis.master.persistence.enabled=true
```

### 3. Stack de Producción

```bash
# Alta disponibilidad
helm install prod . -f values-prod.yaml

# values-prod.yaml:
# app:
#   replicaCount: 5
# postgresql:
#   architecture: replication
#   readReplicas:
#     replicaCount: 2
#   primary:
#     persistence:
#       size: 100Gi
# redis:
#   architecture: replication
#   replica:
#     replicaCount: 3
```

## 🧪 Testing

```bash
# Validar sintaxis
helm lint .

# Dry-run para ver qué se creará
helm install myapp . --dry-run --debug

# Template sin instalar
helm template myapp .

# Instalar en namespace de prueba
kubectl create namespace test-deps
helm install myapp . --namespace test-deps

# Ver todo lo creado
kubectl get all -n test-deps -l release=myapp

# Limpiar
helm uninstall myapp --namespace test-deps
kubectl delete namespace test-deps
```

## ⚠️ Troubleshooting

### Error: dependency update failed

```bash
# Problema: No se puede descargar subcharts
helm dependency update

# Solución 1: Agregar repo de Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm dependency update

# Solución 2: Verificar conectividad
curl -I https://charts.bitnami.com/bitnami/index.yaml
```

### PostgreSQL no inicia

```bash
# Ver logs
kubectl logs -l app.kubernetes.io/name=postgresql

# Común: Problema con PVC
kubectl get pvc
kubectl describe pvc data-myapp-postgresql-0

# Solución: Usar storageClass correcto
helm upgrade myapp . --set postgresql.global.storageClass=standard
```

### App no conecta a Database

```bash
# Verificar service
kubectl get svc myapp-postgresql

# Verificar DNS
kubectl exec -it deployment/myapp-myapp -- nslookup myapp-postgresql

# Verificar variables de entorno
kubectl exec -it deployment/myapp-myapp -- env | grep DATABASE

# Verificar credenciales
kubectl get secret myapp-postgresql -o jsonpath='{.data.password}' | base64 -d
```

## 📚 Conceptos Clave

### 1. Chart.yaml - dependencies

```yaml
dependencies:
  - name: postgresql              # Nombre del subchart
    version: "12.x.x"             # Versión (permite rangos)
    repository: "https://..."     # Repositorio Helm
    condition: postgresql.enabled # Conditional enable
    tags: ["database"]            # Tag para habilitar grupos
    alias: db                     # Alias personalizado
```

### 2. Values - Pasar a Subcharts

```yaml
# En values.yaml del chart padre:
postgresql:  # El nombre debe coincidir con el subchart
  auth:
    username: myuser
    password: mypass
```

### 3. Templates - Referenciar Subcharts

```yaml
# Nombre del service creado por subchart:
- name: DATABASE_HOST
  value: "{{ .Release.Name }}-postgresql"
# Formato: {{ .Release.Name }}-<nombre-del-subchart>
```

### 4. Import Values

```yaml
# En Chart.yaml:
dependencies:
  - name: postgresql
    import-values:
      - child: auth.username  # Valor del subchart
        parent: dbUser        # Importar como dbUser en chart padre
```

## 🎓 Mejores Prácticas

### ✅ DO

- **Versionado semántico**: Usa rangos (`12.x.x`) para actualizaciones menores
- **Conditions**: Permite deshabilitar subcharts con `condition:`
- **Alias**: Usa alias para múltiples instancias del mismo subchart
- **Testing**: Siempre prueba con `--dry-run` antes de instalar
- **Docs**: Documenta las dependencias y versiones requeridas

### ❌ DON'T

- **No hardcodear nombres**: Usa `{{ .Release.Name }}-service-name`
- **No omitir dependency update**: Siempre ejecuta antes de instalar
- **No versiones latest**: Especifica versiones concretas en producción
- **No contraseñas por defecto**: Cambia passwords en producción
- **No mezclar versions**: Mantén consistencia entre Helm y chart versions

## 🔗 Referencias

- [Bitnami PostgreSQL Chart](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)
- [Bitnami Redis Chart](https://github.com/bitnami/charts/tree/main/bitnami/redis)
- [Helm Dependencies](https://helm.sh/docs/topics/charts/#chart-dependencies)
- [Helm Subcharts](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/)

---

**Nivel**: 🟡 Intermedio  
**Duración estimada**: 25 minutos  
**Prerequisitos**: Helm básico, conocimiento de PostgreSQL/Redis
