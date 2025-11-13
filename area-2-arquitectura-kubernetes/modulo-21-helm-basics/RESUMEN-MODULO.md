# 📦 RESUMEN: Helm - Package Manager

> ⏱️ **Tiempo de revisión**: 15-20 minutos  
> 🎯 **Objetivo**: Referencia rápida para CKAD y uso diario  
> 📋 **Uso**: Consulta durante examen, troubleshooting, desarrollo

---

## ⚡ Conceptos en 30 Segundos

```
┌─────────────────────────────────────────┐
│         HELM ARCHITECTURE               │
├─────────────────────────────────────────┤
│                                         │
│  CHART (Package)                        │
│    ├── Chart.yaml (metadata)            │
│    ├── values.yaml (config)             │
│    └── templates/ (K8s YAMLs)           │
│         │                               │
│         │ helm install                  │
│         ▼                               │
│  RELEASE (Instance)                     │
│    └── Running in K8s                   │
│                                         │
│  REPOSITORY (Distribution)              │
│    └── Collection of charts             │
└─────────────────────────────────────────┘
```

**Helm = Package Manager para Kubernetes**
- **Chart**: Paquete (like .deb, .rpm)
- **Release**: Instancia instalada
- **Repository**: Catálogo de charts

---

## 🚀 Comandos Esenciales (CKAD)

### Setup Inicial
```bash
# Añadir repositorio (memorizar bitnami)
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Buscar charts
helm search repo nginx
helm search hub wordpress

# Ver info de chart
helm show values bitnami/nginx     # Ver valores configurables
helm show chart bitnami/nginx      # Ver metadata
```

### Instalar Release
```bash
# Instalar desde repo
helm install myapp bitnami/nginx

# Con valores personalizados
helm install myapp bitnami/nginx --set replicaCount=3

# Con archivo de valores
helm install myapp ./mychart -f values-prod.yaml

# Namespace específico
helm install myapp bitnami/nginx -n production --create-namespace

# Dry-run (no aplicar, solo ver)
helm install myapp ./mychart --dry-run --debug

# Esperar a que esté ready
helm install myapp ./mychart --wait --timeout 5m
```

### Gestionar Releases
```bash
# Listar releases
helm list                    # Namespace actual
helm list -A                 # Todos los namespaces
helm list --all              # Incluir fallidos/desinstalados

# Ver estado
helm status myapp
helm get values myapp        # Valores aplicados
helm get manifest myapp      # YAML completo
helm history myapp           # Historial de revisiones

# Upgrade
helm upgrade myapp bitnami/nginx --set image.tag=1.21.0
helm upgrade --install myapp ./mychart  # Install si no existe

# Rollback
helm rollback myapp          # A revisión anterior
helm rollback myapp 3        # A revisión específica

# Desinstalar
helm uninstall myapp
```

### Crear Chart
```bash
# Crear estructura base
helm create mychart

# Validar
helm lint mychart

# Empaquetar
helm package mychart         # Crea mychart-1.0.0.tgz

# Generar YAML sin instalar
helm template myapp ./mychart > output.yaml
```

---

## 📋 Estructura de Chart (Copy-Paste)

### Estructura Mínima
```bash
mychart/
├── Chart.yaml              # REQUERIDO: Metadata
├── values.yaml             # REQUERIDO: Config defaults
└── templates/              # REQUERIDO: K8s YAMLs
    ├── deployment.yaml
    ├── service.yaml
    └── _helpers.tpl        # Opcional: Helpers
```

### Chart.yaml Template
```yaml
apiVersion: v2
name: mychart
version: 1.0.0              # Chart version (semver)
appVersion: "1.0"           # App version
description: My application
type: application
```

### values.yaml Template
```yaml
replicaCount: 2

image:
  repository: nginx
  tag: "1.21.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### templates/deployment.yaml Template
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  labels:
    app: {{ .Chart.Name }}
    release: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
        release: {{ .Release.Name }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 80
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
```

---

## 🔧 Template Syntax Cheatsheet

### Valores
```yaml
# Acceder a valores
{{ .Values.replicaCount }}              # values.yaml
{{ .Release.Name }}                     # Nombre del release
{{ .Chart.Name }}                       # Nombre del chart
{{ .Chart.Version }}                    # Versión del chart

# Valores anidados
{{ .Values.image.repository }}
{{ .Values.database.host }}
```

### Condicionales
```yaml
# If simple
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
{{- end }}

# If-else
{{- if eq .Values.env "prod" }}
replicas: 3
{{- else }}
replicas: 1
{{- end }}
```

### Loops
```yaml
# Range sobre lista
env:
{{- range .Values.env }}
  - name: {{ .name }}
    value: {{ .value }}
{{- end }}

# Range con index
{{- range $index, $value := .Values.hosts }}
  host{{ $index }}: {{ $value }}
{{- end }}
```

### Funciones Útiles
```yaml
# Strings
{{ .Values.name | upper }}              # MAYÚSCULAS
{{ .Values.name | lower }}              # minúsculas
{{ .Values.name | quote }}              # "quoted"
{{ .Values.name | default "app" }}      # Default si vacío

# YAML/JSON
{{- toYaml .Values.resources | nindent 12 }}
{{- toJson .Values.config }}

# Encoding
{{ .Values.password | b64enc }}        # Base64 encode

# Lógica
{{ if eq .Values.env "prod" }}          # Igual
{{ if ne .Values.replicas 0 }}          # No igual
```

### Template Helpers
```yaml
# _helpers.tpl
{{- define "mychart.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end -}}

# Uso
name: {{ include "mychart.fullname" . }}
```

---

## 🎯 Jerarquía de Values (Precedencia)

```
1. --set (CLI)                    ← MAYOR PRIORIDAD
2. -f values-custom.yaml (último)
3. -f values-prod.yaml (primero)
4. values.yaml (chart)            ← MENOR PRIORIDAD
```

### Ejemplo
```bash
# values.yaml: replicas: 2
# values-prod.yaml: replicas: 3

helm install myapp ./mychart \
  -f values-prod.yaml \           # replicas = 3
  --set replicaCount=5            # GANA: replicas = 5
```

---

## 🐛 Troubleshooting Rápido

### Problema: Release no instala
```bash
# 1. Dry-run con debug
helm install myapp ./mychart --dry-run --debug

# 2. Validar sintaxis
helm lint ./mychart

# 3. Ver template generado
helm template myapp ./mychart
```

### Problema: Upgrade falla
```bash
# 1. Ver estado
helm status myapp

# 2. Ver historia
helm history myapp

# 3. Rollback
helm rollback myapp

# 4. Ver eventos K8s
kubectl get events --sort-by='.lastTimestamp'
```

### Problema: Templates incorrectos
```bash
# Ver valores finales
helm get values myapp --all

# Generar YAML específico
helm template myapp ./mychart -s templates/deployment.yaml

# Debug completo
helm install myapp ./mychart --dry-run --debug | less
```

### Problema: Release "stuck"
```bash
# Ver estado de pods
kubectl get pods -l release=myapp

# Ver logs
kubectl logs -l release=myapp

# Forzar desinstalación
helm uninstall myapp --no-hooks
kubectl delete all -l release=myapp
```

### Problema: Values no se aplican
```bash
# Verificar jerarquía
helm get values myapp --all

# Ver qué valores tiene el chart
helm show values bitnami/nginx

# Test con --set
helm upgrade myapp ./mychart --set replicaCount=3 --dry-run
```

---

## 📊 Helm Hooks Comunes

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-migrate
  annotations:
    # Timing del hook
    "helm.sh/hook": pre-upgrade           # Cuándo ejecutar
    
    # Orden de ejecución (-5 = antes, 0 = default, 5 = después)
    "helm.sh/hook-weight": "-5"
    
    # Cleanup automático
    "helm.sh/hook-delete-policy": before-hook-creation
```

### Tipos de Hooks
- `pre-install`: Antes de instalar
- `post-install`: Después de instalar
- `pre-upgrade`: Antes de upgrade
- `post-upgrade`: Después de upgrade
- `pre-delete`: Antes de desinstalar
- `test`: Para tests (`helm test`)

### Delete Policies
- `before-hook-creation`: Borrar antes de crear nuevo
- `hook-succeeded`: Borrar si tiene éxito
- `hook-failed`: Borrar si falla

---

## ⚡ CKAD Cheatsheet (2-3 min por escenario)

### Escenario 1: Instalar PostgreSQL
```bash
# 1. Añadir repo (si no existe)
helm repo add bitnami https://charts.bitnami.com/bitnami

# 2. Instalar con valores custom
helm install mydb bitnami/postgresql \
  --set auth.username=admin \
  --set auth.password=secret123 \
  --set auth.database=myapp

# 3. Verificar
helm status mydb
kubectl get pods -l app.kubernetes.io/name=postgresql
```

### Escenario 2: Upgrade con Rollback
```bash
# 1. Upgrade
helm upgrade myapp bitnami/nginx --set replicaCount=5

# 2. Si falla, ver historia
helm history myapp

# 3. Rollback
helm rollback myapp
```

### Escenario 3: Crear Chart Básico
```bash
# 1. Crear estructura
helm create myapp

# 2. Editar values.yaml
vim myapp/values.yaml
# Cambiar image, replicas, etc.

# 3. Validar y desplegar
helm lint myapp
helm install myapp-dev ./myapp
```

### Escenario 4: Debug Release Fallido
```bash
# 1. Ver estado
helm status myapp

# 2. Ver manifest aplicado
helm get manifest myapp

# 3. Ver logs de pods
kubectl logs -l app.kubernetes.io/instance=myapp

# 4. Desinstalar y reinstalar
helm uninstall myapp
helm install myapp ./mychart --debug --wait
```

---

## 📖 Comandos por Categoría

### Repositorios
```bash
helm repo add <name> <url>       # Añadir repo
helm repo list                   # Listar repos
helm repo update                 # Actualizar índice
helm repo remove <name>          # Remover repo
helm search repo <keyword>       # Buscar en repos
helm search hub <keyword>        # Buscar en Artifact Hub
helm show values <chart>         # Ver valores del chart
```

### Release Management
```bash
helm install <name> <chart>      # Instalar
helm upgrade <name> <chart>      # Actualizar
helm rollback <name> [rev]       # Rollback
helm uninstall <name>            # Desinstalar
helm list                        # Listar releases
helm status <name>               # Ver estado
helm history <name>              # Ver historial
helm get values <name>           # Ver valores aplicados
helm get manifest <name>         # Ver YAML completo
```

### Desarrollo
```bash
helm create <name>               # Crear chart
helm lint <chart>                # Validar sintaxis
helm template <name> <chart>     # Generar YAML
helm package <chart>             # Empaquetar (.tgz)
helm install --dry-run --debug   # Simular instalación
helm test <name>                 # Ejecutar tests
```

---

## 🎯 Mejores Prácticas (Quick Tips)

### ✅ DO
- ✅ Usar versionado semántico (1.2.3)
- ✅ Documentar valores en `values.yaml` con comentarios
- ✅ Definir resource limits por defecto
- ✅ Usar `--dry-run` antes de install/upgrade
- ✅ Hacer `helm lint` antes de commit
- ✅ Usar helpers (`_helpers.tpl`) para nombres consistentes
- ✅ Habilitar/deshabilitar recursos con flags (ingress.enabled)

### ❌ DON'T
- ❌ Hardcodear valores en templates (usar .Values)
- ❌ Omitir resource limits
- ❌ Usar `latest` como image tag
- ❌ Commitear secrets en `values.yaml`
- ❌ Modificar releases directamente con kubectl
- ❌ Olvidar --wait en producción

---

## 📐 Template Patterns Comunes

### Pattern 1: Conditional Resource
```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-ingress
spec:
  rules:
  {{- range .Values.ingress.hosts }}
  - host: {{ .host }}
    http:
      paths:
      {{- range .paths }}
      - path: {{ .path }}
        pathType: {{ .pathType }}
        backend:
          service:
            name: {{ $.Release.Name }}-service
            port:
              number: {{ $.Values.service.port }}
      {{- end }}
  {{- end }}
{{- end }}
```

### Pattern 2: ConfigMap from Values
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
data:
  {{- range $key, $val := .Values.config }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
```

### Pattern 3: Multi-Container with Sidecars
```yaml
spec:
  containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    # ...
  
  {{- if .Values.sidecar.enabled }}
  - name: {{ .Values.sidecar.name }}
    image: "{{ .Values.sidecar.image }}"
    # ...
  {{- end }}
```

---

## 🔍 Debugging Workflow

```
1. helm lint ./mychart
   └─> Syntax OK? ──No──> Fix YAML errors
                └─> Yes
                    │
2. helm template myapp ./mychart
   └─> Renders OK? ──No──> Debug template logic
                  └─> Yes
                      │
3. helm install myapp ./mychart --dry-run --debug
   └─> Validates? ──No──> Fix K8s validation
                 └─> Yes
                     │
4. helm install myapp ./mychart --wait
   └─> Deploys? ──No──> kubectl get events
              └─> Yes ──> SUCCESS!
```

---

## 📊 Objetos Built-in Reference

```yaml
# Release info
{{ .Release.Name }}          # Nombre del release (ej: myapp)
{{ .Release.Namespace }}     # Namespace destino (ej: default)
{{ .Release.Service }}       # Siempre "Helm"
{{ .Release.Revision }}      # Número de revisión (ej: 1, 2, 3...)

# Chart info
{{ .Chart.Name }}            # Nombre del chart (ej: mychart)
{{ .Chart.Version }}         # Versión del chart (ej: 1.0.0)
{{ .Chart.AppVersion }}      # Versión de la app (ej: 2.5.1)

# Values
{{ .Values.* }}              # Cualquier valor de values.yaml

# Capabilities (cluster)
{{ .Capabilities.KubeVersion }}        # v1.28.0
{{ .Capabilities.APIVersions }}        # APIs disponibles
```

---

## 🚀 Quick Exercises (2-5 min cada uno)

### Exercise 1: Instalar NGINX
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install mynginx bitnami/nginx --set replicaCount=2
helm status mynginx
helm uninstall mynginx
```

### Exercise 2: Crear Chart Mínimo
```bash
mkdir quickchart && cd quickchart
cat > Chart.yaml <<EOF
apiVersion: v2
name: quickchart
version: 1.0.0
EOF

mkdir templates
cat > templates/pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: {{ .Release.Name }}-pod
spec:
  containers:
  - name: nginx
    image: nginx:{{ .Values.tag }}
EOF

cat > values.yaml <<EOF
tag: "1.21.0"
EOF

helm install test ./quickchart
helm list
helm uninstall test
```

### Exercise 3: Override Values
```bash
# Crear values-prod.yaml
cat > values-prod.yaml <<EOF
replicaCount: 5
image:
  tag: "1.22.0"
EOF

helm install myapp ./mychart -f values-prod.yaml
helm get values myapp
```

---

## 📚 Referencias Rápidas

### Docs Oficiales
- **Helm Docs**: https://helm.sh/docs/
- **Chart Guide**: https://helm.sh/docs/chart_template_guide/
- **Best Practices**: https://helm.sh/docs/chart_best_practices/

### Artifact Hub
- **Search Charts**: https://artifacthub.io/
- **Bitnami Charts**: https://github.com/bitnami/charts

### CKAD Resources
- Helm representa 5-7% del examen CKAD
- Enfocarse en: install, upgrade, rollback, values override
- Tiempo: 2-4 minutos por pregunta de Helm

---

## ✅ Checklist Pre-CKAD

- [ ] Memorizar: `helm repo add bitnami https://charts.bitnami.com/bitnami`
- [ ] Practicar: `helm install` con `--set` (sin archivo)
- [ ] Conocer: `helm show values` para ver opciones
- [ ] Dominar: `helm upgrade` + `helm rollback`
- [ ] Saber: `helm template` para debug
- [ ] Timing: 2-3 min para instalar/upgrade chart público

---

**⚡ Tiempo total de revisión**: 15-20 minutos  
**🎯 Próximo paso**: Practicar labs 01-04 (120 min)  
**📖 Recurso completo**: [README.md](./README.md)
