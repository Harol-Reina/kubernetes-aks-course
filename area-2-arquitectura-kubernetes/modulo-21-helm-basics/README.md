# 📦 Módulo 21: Helm - Package Manager para Kubernetes

> **Duración estimada**: 3.5 horas (90 min teoría + 120 min práctica)  
> **Nivel**: Intermedio  
> **Prerequisitos**: Módulos 1-20, familiaridad con YAML y templating básico  
> **Cobertura CKAD**: 5-7% del examen (Application Deployment)

---

## 🎯 Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:

### Conceptuales
- ✅ Comprender la arquitectura de Helm y su propósito
- ✅ Entender la estructura de un Helm Chart
- ✅ Conocer el ciclo de vida de releases
- ✅ Diferenciar entre Chart, Release y Repository

### Técnicos
- ✅ Instalar y configurar Helm 3
- ✅ Crear charts desde cero
- ✅ Personalizar deployments con `values.yaml`
- ✅ Usar templates y funciones de Helm
- ✅ Gestionar releases (install, upgrade, rollback)
- ✅ Trabajar con repositorios públicos y privados
- ✅ Implementar hooks de ciclo de vida

### Troubleshooting
- ✅ Depurar templates con `helm template` y `--dry-run`
- ✅ Resolver conflictos de valores
- ✅ Diagnosticar fallos en releases
- ✅ Recuperar releases fallidos

### Profesionales
- ✅ Seguir mejores prácticas de Helm
- ✅ Diseñar charts reutilizables
- ✅ Gestionar múltiples entornos (dev, staging, prod)
- ✅ Prepararse para preguntas CKAD sobre Helm

---

## 📋 Prerequisitos

### Conocimientos Previos
- Módulos 1-20 completados
- Experiencia con Deployments, Services, ConfigMaps
- YAML y sintaxis de templates básica
- Git (para gestión de charts)

### Entorno Requerido
```bash
# Verificar cluster Kubernetes
kubectl cluster-info

# Instalar Helm 3
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verificar instalación
helm version
# version.BuildInfo{Version:"v3.13.0", GitCommit:"...", GoVersion:"go1.20.8"}

# Añadir repositorio de ejemplo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

---

## 📚 Estructura del Módulo

### 🎓 Teoría (90 minutos)

| Sección | Tema | Duración |
|---------|------|----------|
| 1 | ¿Qué es Helm? Historia y motivación | 10 min |
| 2 | Arquitectura Helm 3 vs Helm 2 | 10 min |
| 3 | Anatomía de un Chart | 15 min |
| 4 | Sistema de Templates | 15 min |
| 5 | Values y Personalización | 10 min |
| 6 | Gestión de Releases | 15 min |
| 7 | Repositorios y Artifact Hub | 10 min |
| 8 | Mejores Prácticas | 5 min |

### 🧪 Práctica (120 minutos)

| Lab | Contenido | Duración | Nivel |
|-----|-----------|----------|-------|
| 01 | Helm Basics: Install, Search, Deploy | 30 min | 🟢 Básico |
| 02 | Crear Chart desde Cero | 30 min | 🟡 Intermedio |
| 03 | Multi-Entorno con Values | 30 min | 🟡 Intermedio |
| 04 | Hooks y Upgrade Avanzado | 30 min | 🔴 Avanzado |

### 📖 Rutas de Aprendizaje

#### 🌱 Principiante (3.5h)
1. Leer teoría completa (90 min)
2. Lab 01: Helm Basics (30 min)
3. Lab 02: Crear Chart (30 min)
4. Revisar ejemplos básicos (30 min)

#### 🚀 Intermedio (2.5h)
1. Leer secciones 3-6 (55 min)
2. Lab 02 + Lab 03 (60 min)
3. Estudiar ejemplos avanzados (30 min)

#### ⚡ CKAD Speed Run (1.5h)
1. RESUMEN-MODULO.md (20 min)
2. Lab 01 + desafíos rápidos (40 min)
3. Comandos esenciales y templates (30 min)

---

## 1️⃣ ¿Qué es Helm?

### Definición

**Helm** es el package manager para Kubernetes, similar a:
- `apt/yum` para Linux
- `npm` para Node.js
- `pip` para Python

Permite empaquetar, distribuir y gestionar aplicaciones Kubernetes completas.

### Problemas que Resuelve

#### ❌ Sin Helm
```bash
# Desplegar aplicación con 20 YAMLs manualmente
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f ingress.yaml
# ... 15 más

# Gestionar valores para dev, staging, prod
# Copiar/pegar YAMLs con cambios manuales
# Difícil hacer rollback consistente
```

#### ✅ Con Helm
```bash
# Instalar aplicación completa en un comando
helm install myapp ./mychart

# Personalizar para diferentes entornos
helm install myapp-dev ./mychart -f values-dev.yaml
helm install myapp-prod ./mychart -f values-prod.yaml

# Rollback atómico
helm rollback myapp 3
```

### Conceptos Clave

| Concepto | Definición | Analogía |
|----------|------------|----------|
| **Chart** | Paquete de recursos K8s | `.deb` o `.rpm` |
| **Release** | Instancia de un chart instalado | Aplicación instalada |
| **Repository** | Colección de charts | `apt` repository |
| **Values** | Configuración personalizada | Opciones de instalación |

---

## 2️⃣ Arquitectura de Helm 3

### Evolución: Helm 2 → Helm 3

#### Helm 2 (Deprecated)
```
┌─────────────┐
│ Helm Client │ ────► ┌────────┐
└─────────────┘       │ Tiller │ (Server-side)
                      └────────┘
                          │
                          ▼
                  ┌──────────────┐
                  │  Kubernetes  │
                  └──────────────┘
```
**Problemas**: Tiller requería permisos elevados (security risk)

#### Helm 3 (Actual)
```
┌─────────────┐
│ Helm Client │ ────► Kubernetes API
└─────────────┘              │
                             ▼
                  ┌──────────────────┐
                  │  ConfigMaps/     │
                  │  Secrets         │
                  │  (Release data)  │
                  └──────────────────┘
```
**Mejoras**:
- ✅ No Tiller (sin servidor)
- ✅ Seguridad mejorada (usa contexto kubectl)
- ✅ Releases por namespace
- ✅ Validación mejorada

### Componentes

```
helm
├── Charts (paquetes)
├── Repositories (distribución)
├── Releases (instancias)
├── Templates (generación YAML)
└── Values (configuración)
```

---

## 3️⃣ Anatomía de un Helm Chart

### Estructura de Directorios

```
mychart/
├── Chart.yaml              # Metadata del chart
├── values.yaml             # Valores por defecto
├── charts/                 # Dependencias (subcharts)
├── templates/              # Templates de Kubernetes
│   ├── NOTES.txt          # Notas post-instalación
│   ├── _helpers.tpl       # Template helpers (parciales)
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   └── tests/
│       └── test-connection.yaml
├── .helmignore            # Archivos a ignorar
└── README.md              # Documentación
```

### Chart.yaml

Define metadata del chart:

```yaml
apiVersion: v2                    # Helm 3 usa v2
name: myapp                       # Nombre del chart
version: 1.0.0                    # Versión del chart (semver)
appVersion: "2.5.1"              # Versión de la app empaquetada
description: Mi aplicación web
type: application                 # application | library
keywords:
  - web
  - nodejs
home: https://myapp.example.com
sources:
  - https://github.com/myorg/myapp
maintainers:
  - name: DevOps Team
    email: devops@example.com
dependencies:                     # Charts de los que depende
  - name: postgresql
    version: 12.x.x
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

### values.yaml

Valores configurables con defaults:

```yaml
# Configuración por defecto
replicaCount: 2

image:
  repository: nginx
  tag: "1.21.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  className: nginx
  hosts:
    - host: myapp.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

### templates/deployment.yaml

Template con placeholders:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "mychart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "mychart.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
```

---

## 4️⃣ Sistema de Templates

### Sintaxis Básica

#### Valores Simples
```yaml
# Template
name: {{ .Values.appName }}

# values.yaml
appName: myapp

# Resultado
name: myapp
```

#### Condicionales
```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-ingress
{{- end }}
```

#### Loops
```yaml
env:
{{- range .Values.env }}
  - name: {{ .name }}
    value: {{ .value | quote }}
{{- end }}
```

### Objetos Integrados

```yaml
# .Release - Info sobre la instalación
{{ .Release.Name }}         # Nombre del release
{{ .Release.Namespace }}    # Namespace destino
{{ .Release.Service }}      # Helm
{{ .Release.Revision }}     # Número de revisión

# .Chart - Info del Chart.yaml
{{ .Chart.Name }}           # mychart
{{ .Chart.Version }}        # 1.0.0
{{ .Chart.AppVersion }}     # 2.5.1

# .Values - Valores de values.yaml
{{ .Values.replicaCount }}  # 2
{{ .Values.image.tag }}     # 1.21.0

# .Capabilities - Info del cluster
{{ .Capabilities.KubeVersion }}  # v1.28.0
{{ .Capabilities.APIVersions }}  # APIs disponibles
```

### Funciones Útiles

```yaml
# Strings
{{ .Values.name | upper }}           # MYAPP
{{ .Values.name | lower }}           # myapp
{{ .Values.name | title }}           # Myapp
{{ .Values.name | quote }}           # "myapp"
{{ .Values.name | default "app" }}   # Si name vacío, usa "app"

# Listas
{{ .Values.ports | join "," }}       # "80,443,8080"

# YAML
{{- toYaml .Values.resources | nindent 10 }}  # Convierte a YAML con indent

# Encoding
{{ .Values.secret | b64enc }}        # Base64 encode

# Lógica
{{ if eq .Values.env "prod" }}production{{ end }}
{{ if ne .Values.replicas 0 }}enabled{{ end }}
```

### Templates Helpers (_helpers.tpl)

```yaml
{{/*
Nombre completo del chart
*/}}
{{- define "mychart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels comunes
*/}}
{{- define "mychart.labels" -}}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Uso en templates
*/}}
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
```

---

## 5️⃣ Values y Personalización

### Jerarquía de Values

Helm combina valores de múltiples fuentes (orden de precedencia):

```
1. Valores por línea de comandos (--set)
2. Archivos -f / --values (último gana)
3. values.yaml del chart padre
4. values.yaml del chart
```

### Ejemplo Práctico

#### values.yaml (defaults)
```yaml
environment: development
replicaCount: 1
image:
  repository: myapp
  tag: latest
```

#### values-prod.yaml (override)
```yaml
environment: production
replicaCount: 3
image:
  tag: "v2.1.0"
```

#### Instalación
```bash
# Desarrollo (usa values.yaml)
helm install myapp-dev ./mychart

# Producción (override con values-prod.yaml)
helm install myapp-prod ./mychart -f values-prod.yaml

# Override específico por CLI
helm install myapp-prod ./mychart \
  -f values-prod.yaml \
  --set replicaCount=5 \
  --set image.tag=v2.1.1
```

### Values Anidados

```yaml
# values.yaml
database:
  host: postgres.default.svc
  port: 5432
  credentials:
    username: admin
    password: secret123

# Uso en template
env:
  - name: DB_HOST
    value: {{ .Values.database.host }}
  - name: DB_PORT
    value: {{ .Values.database.port | quote }}
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: username
```

---

## 6️⃣ Gestión de Releases

### Comandos Básicos

#### Instalar Release
```bash
# Instalar desde directorio local
helm install myapp ./mychart

# Instalar desde repositorio
helm install mydb bitnami/postgresql

# Dry-run (simular sin aplicar)
helm install myapp ./mychart --dry-run --debug

# Generar YAML sin instalar
helm template myapp ./mychart > output.yaml

# Instalar en namespace específico
helm install myapp ./mychart -n production --create-namespace

# Esperar a que esté ready
helm install myapp ./mychart --wait --timeout 5m
```

#### Listar Releases
```bash
# Todos los releases del namespace actual
helm list

# Todos los namespaces
helm list -A

# Incluir releases fallidos/desinstalados
helm list --all

# Formato específico
helm list -o json
```

#### Ver Estado
```bash
# Estado del release
helm status myapp

# Historia de revisiones
helm history myapp

# Ver valores aplicados
helm get values myapp

# Ver manifest completo
helm get manifest myapp

# Ver notas post-instalación
helm get notes myapp
```

#### Upgrade Release
```bash
# Actualizar con nuevos valores
helm upgrade myapp ./mychart -f values-v2.yaml

# Actualizar versión de imagen
helm upgrade myapp ./mychart --set image.tag=v2.0.0

# Upgrade o install si no existe
helm upgrade --install myapp ./mychart

# Forzar recreación de pods
helm upgrade myapp ./mychart --force

# Cleanup on fail
helm upgrade myapp ./mychart --atomic --timeout 3m
```

#### Rollback
```bash
# Ver revisiones
helm history myapp
# REVISION  UPDATED    STATUS      CHART         DESCRIPTION
# 1         ...        superseded  mychart-1.0.0 Install complete
# 2         ...        superseded  mychart-1.1.0 Upgrade complete
# 3         ...        deployed    mychart-1.2.0 Upgrade complete

# Rollback a revisión anterior
helm rollback myapp

# Rollback a revisión específica
helm rollback myapp 2

# Dry-run rollback
helm rollback myapp 2 --dry-run
```

#### Desinstalar
```bash
# Desinstalar release
helm uninstall myapp

# Mantener historia (permite rollback)
helm uninstall myapp --keep-history

# Desinstalar con timeout
helm uninstall myapp --timeout 5m
```

### Ciclo de Vida

```
┌─────────────┐
│   Install   │
└─────┬───────┘
      │
      ▼
┌─────────────┐     ┌──────────┐
│  Deployed   │ ◄───┤ Rollback │
└─────┬───────┘     └──────────┘
      │                   ▲
      ▼                   │
┌─────────────┐          │
│   Upgrade   │──────────┘
└─────┬───────┘
      │
      ▼
┌─────────────┐
│  Uninstall  │
└─────────────┘
```

---

## 7️⃣ Repositorios y Artifact Hub

### Gestión de Repositorios

```bash
# Añadir repositorio
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable

# Listar repositorios
helm repo list

# Actualizar índice de charts
helm repo update

# Buscar charts
helm search repo nginx
helm search repo database --versions

# Buscar en Artifact Hub (todos los repos públicos)
helm search hub wordpress

# Remover repositorio
helm repo remove bitnami
```

### Artifact Hub

**URL**: https://artifacthub.io/

Catálogo centralizado de charts de Helm públicos:

- 🔍 Buscar entre miles de charts
- 📊 Ver popularidad y seguridad
- 📖 Documentación integrada
- ⚡ Instalación con un comando

```bash
# Buscar WordPress
helm search hub wordpress

# Ver detalles de un chart
helm show chart bitnami/wordpress
helm show values bitnami/wordpress
helm show readme bitnami/wordpress
```

### Crear Repositorio Propio

#### Opción 1: GitHub Pages
```bash
# 1. Crear charts/
mkdir -p charts
cp -r mychart charts/

# 2. Empaquetar charts
helm package charts/* -d packaged/

# 3. Crear índice
helm repo index packaged/ --url https://myorg.github.io/charts

# 4. Publicar en GitHub Pages
git add packaged/
git commit -m "Add helm charts"
git push origin gh-pages

# 5. Usuarios pueden añadir repo
helm repo add myrepo https://myorg.github.io/charts
```

#### Opción 2: ChartMuseum
```bash
# Desplegar ChartMuseum en K8s
helm install chartmuseum stable/chartmuseum

# Subir chart
curl --data-binary "@mychart-1.0.0.tgz" http://chartmuseum:8080/api/charts
```

---

## 8️⃣ Helm Hooks

### ¿Qué son los Hooks?

Recursos que se ejecutan en momentos específicos del ciclo de vida:

- **pre-install**: Antes de instalar
- **post-install**: Después de instalar
- **pre-upgrade**: Antes de upgrade
- **post-upgrade**: Después de upgrade
- **pre-rollback**: Antes de rollback
- **post-rollback**: Después de rollback
- **pre-delete**: Antes de desinstalar
- **post-delete**: Después de desinstalar
- **test**: Ejecutar tests

### Ejemplo: Database Migration Hook

```yaml
# templates/job-migrate.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-db-migrate
  annotations:
    # Hook annotations
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "-5"           # Orden ejecución (menor = primero)
    "helm.sh/hook-delete-policy": before-hook-creation  # Cleanup automático
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: myapp/migrations:{{ .Values.image.tag }}
        command:
          - /bin/sh
          - -c
          - |
            echo "Running database migrations..."
            ./migrate.sh up
            echo "Migrations completed!"
        env:
        - name: DB_HOST
          value: {{ .Values.database.host }}
```

### Hook Delete Policies

```yaml
annotations:
  "helm.sh/hook-delete-policy": before-hook-creation  # Borrar antes de crear nuevo
  "helm.sh/hook-delete-policy": hook-succeeded       # Borrar si tiene éxito
  "helm.sh/hook-delete-policy": hook-failed          # Borrar si falla
```

---

## 9️⃣ Testing y Debugging

### Validar Templates

```bash
# Linting (verificar sintaxis)
helm lint ./mychart

# Dry-run (simular instalación)
helm install myapp ./mychart --dry-run --debug

# Template (generar YAML sin instalar)
helm template myapp ./mychart

# Template con valores personalizados
helm template myapp ./mychart -f values-prod.yaml

# Template de un solo archivo
helm template myapp ./mychart -s templates/deployment.yaml
```

### Tests de Chart

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ .Release.Name }}-test
  annotations:
    "helm.sh/hook": test
spec:
  restartPolicy: Never
  containers:
  - name: wget
    image: busybox
    command: ['wget']
    args: ['{{ .Release.Name }}-service:{{ .Values.service.port }}']
```

```bash
# Ejecutar tests
helm test myapp

# Ver logs de tests
helm test myapp --logs
```

### Debugging Common Issues

```bash
# 1. Ver valores finales combinados
helm get values myapp --all

# 2. Ver manifest renderizado
helm get manifest myapp

# 3. Ver eventos de Kubernetes
kubectl get events -n default --sort-by='.lastTimestamp'

# 4. Ver logs de hooks
kubectl logs -l "helm.sh/hook=pre-upgrade"

# 5. Reinstalar con debug
helm uninstall myapp
helm install myapp ./mychart --debug --wait
```

---

## 🔟 Mejores Prácticas

### 1. Versionado Semántico

```yaml
# Chart.yaml
version: 1.2.3  # MAJOR.MINOR.PATCH
# MAJOR: Cambios incompatibles
# MINOR: Nueva funcionalidad compatible
# PATCH: Bugfixes
```

### 2. Values Documentados

```yaml
## @section Global parameters
## @param replicaCount Number of replicas
replicaCount: 2

## @param image.repository Image repository
## @param image.tag Image tag (default: Chart appVersion)
image:
  repository: nginx
  tag: ""
```

### 3. Security Defaults

```yaml
# values.yaml - Seguridad por defecto
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  capabilities:
    drop:
    - ALL

podSecurityContext:
  readOnlyRootFilesystem: true
```

### 4. Resource Limits

```yaml
# Siempre definir límites
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### 5. Naming Conventions

```yaml
# templates/_helpers.tpl
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

# Uso consistente
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
```

### 6. Conditional Resources

```yaml
# Habilitar/deshabilitar recursos
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
# ...
{{- end }}
```

### 7. Chart Dependencies

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled  # Habilitar en values.yaml

# values.yaml
postgresql:
  enabled: true
  auth:
    username: myuser
    password: mypass
    database: mydb
```

---

## 🎯 Preparación para CKAD

### Temas del Examen

| Tema CKAD | Cobertura | Peso |
|-----------|-----------|------|
| Instalar aplicaciones con Helm | ✅ 100% | 5% |
| Personalizar charts con values | ✅ 100% | 2% |
| Template básico | ✅ 100% | - |

### Comandos Esenciales

```bash
# CKAD: Instalar desde repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install mydb bitnami/postgresql

# CKAD: Personalizar valores
helm install myapp bitnami/nginx \
  --set replicaCount=3 \
  --set service.type=LoadBalancer

# CKAD: Ver valores disponibles
helm show values bitnami/nginx

# CKAD: Upgrade
helm upgrade myapp bitnami/nginx --set image.tag=1.21.0

# CKAD: Rollback
helm rollback myapp

# CKAD: Desinstalar
helm uninstall myapp
```

### Timing Estimado por Escenario

| Escenario | Tiempo | Estrategia |
|-----------|--------|------------|
| Instalar chart público | 2-3 min | `helm install` directo |
| Personalizar con --set | 3-4 min | Conocer valores key |
| Crear chart básico | 5-7 min | `helm create` + editar |
| Debugging release | 3-5 min | `helm get` + `kubectl logs` |

---

## 📖 Recursos Adicionales

### Documentación Oficial
- **Helm Docs**: https://helm.sh/docs/
- **Chart Best Practices**: https://helm.sh/docs/chart_best_practices/
- **Chart Template Guide**: https://helm.sh/docs/chart_template_guide/

### Repositorios Útiles
- **Artifact Hub**: https://artifacthub.io/
- **Bitnami Charts**: https://github.com/bitnami/charts
- **Helm Stable**: https://github.com/helm/charts

### Herramientas
- **Helmfile**: Gestión declarativa de releases
- **Helm Diff**: Ver diferencias antes de upgrade
- **ChartMuseum**: Repositorio privado de charts

---

## 🧪 Laboratorios

| Lab | Descripción | Duración | Nivel |
|-----|-------------|----------|-------|
| [Lab 01](./laboratorios/lab-01-helm-basics.md) | Helm Basics: Install, Search, Deploy | 30 min | 🟢 |
| [Lab 02](./laboratorios/lab-02-crear-chart.md) | Crear Chart desde Cero | 30 min | 🟡 |
| [Lab 03](./laboratorios/lab-03-multi-entorno.md) | Multi-Entorno con Values | 30 min | 🟡 |
| [Lab 04](./laboratorios/lab-04-hooks-avanzado.md) | Hooks y Upgrade Avanzado | 30 min | 🔴 |

---

## 📝 Resumen

### Puntos Clave

✅ **Helm** es el package manager estándar para Kubernetes  
✅ **Charts** empaquetan aplicaciones completas (Deployment, Service, ConfigMap, etc.)  
✅ **Values** permiten personalizar deployments sin modificar templates  
✅ **Templates** usan Go templating para generar YAML dinámico  
✅ **Releases** son instancias instaladas de charts  
✅ **Repositories** distribuyen charts públicos y privados  
✅ **Hooks** ejecutan tareas en momentos específicos del ciclo de vida  
✅ **CKAD**: Dominar `helm install`, `upgrade`, `rollback`, y personalización con `--set`

### Siguiente Paso

Con Helm completado, has alcanzado **95%+ de cobertura CKAD** 🎉

**Próximos módulos (CKA focus)**:
- Módulo 22: Cluster Setup con kubeadm
- Módulo 23: Maintenance & Upgrades
- Módulo 24: Advanced Scheduling

---

## ❓ Troubleshooting

### Error: "Release already exists"
```bash
# Ver releases existentes
helm list -A

# Forzar reinstalación
helm uninstall myapp
helm install myapp ./mychart
```

### Error: "Validation failed"
```bash
# Validar antes de instalar
helm lint ./mychart
helm template myapp ./mychart --debug
```

### Error: "Upgrade failed"
```bash
# Ver estado
helm status myapp
helm history myapp

# Rollback
helm rollback myapp

# Reinstalar desde cero
helm uninstall myapp
helm install myapp ./mychart
```

### Templates no se renderizan correctamente
```bash
# Debug template rendering
helm template myapp ./mychart --debug

# Ver valores finales
helm install myapp ./mychart --dry-run --debug | grep -A 20 "COMPUTED VALUES"
```

---

**🎓 ¡Felicitaciones!** Has completado el Módulo 21 y alcanzado la preparación completa para CKAD 🚀
