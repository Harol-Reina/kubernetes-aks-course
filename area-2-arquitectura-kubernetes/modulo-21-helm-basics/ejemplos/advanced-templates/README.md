# 🚀 Advanced Templates - Templates Avanzados de Helm

Chart de ejemplo que demuestra **técnicas avanzadas** de templating en Helm, incluyendo helpers reutilizables, funciones complejas, y mejores prácticas de producción.

## 🎯 Objetivo

Aprender técnicas avanzadas:
- **Named Templates** (_helpers.tpl)
- **Template Functions** (sprig functions)
- **Flow Control** (if/else, range, with)
- **Template Composition** (include, template)
- **Validation** (fail, required)
- **Checksums** para reiniciar pods
- **DRY Principle** (Don't Repeat Yourself)

## 📁 Estructura

```
advanced-templates/
├── Chart.yaml
├── values.yaml             # 200+ líneas de configuración
├── README.md
└── templates/
    ├── _helpers.tpl        # 20+ named templates ⭐
    ├── deployment.yaml     # Usa todos los helpers
    ├── service.yaml
    ├── ingress.yaml        # Ingress multi-host
    ├── configmap.yaml
    ├── secret.yaml
    ├── serviceaccount.yaml
    ├── hpa.yaml           # HorizontalPodAutoscaler
    ├── pdb.yaml           # PodDisruptionBudget
    ├── networkpolicy.yaml # NetworkPolicy
    └── pvc.yaml           # PersistentVolumeClaim
```

## 🧩 Helpers Principales (_helpers.tpl)

### 1. Naming Helpers

```yaml
{{- define "advanced-templates.name" -}}
# Genera nombre base del chart
{{- end }}

{{- define "advanced-templates.fullname" -}}
# Genera nombre completo (release + chart)
# Usado para nombres de recursos
{{- end }}

{{- define "advanced-templates.chart" -}}
# Genera "nombre-version" para el label chart
{{- end }}
```

**Uso**:
```yaml
metadata:
  name: {{ include "advanced-templates.fullname" . }}
  labels:
    helm.sh/chart: {{ include "advanced-templates.chart" . }}
```

### 2. Label Helpers

```yaml
{{- define "advanced-templates.labels" -}}
# Labels COMPLETOS para metadata
# Incluye: chart, name, instance, version, managed-by
{{- end }}

{{- define "advanced-templates.selectorLabels" -}}
# Labels INMUTABLES para selectors
# Solo: name, instance
{{- end }}
```

**Uso**:
```yaml
metadata:
  labels:
    {{- include "advanced-templates.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "advanced-templates.selectorLabels" . | nindent 6 }}
```

### 3. Configuration Helpers

```yaml
{{- define "advanced-templates.image" -}}
# Genera: repository:tag
{{- end }}

{{- define "advanced-templates.serviceAccountName" -}}
# Determina nombre del ServiceAccount
{{- end }}

{{- define "advanced-templates.portName" -}}
# Genera nombre de puerto (http, https, tcp-XXX)
{{- end }}
```

### 4. Resource Helpers

```yaml
{{- define "advanced-templates.resources" -}}
# Genera bloque resources (requests/limits)
{{- end }}

{{- define "advanced-templates.livenessProbe" -}}
# Genera liveness probe completo
{{- end }}

{{- define "advanced-templates.readinessProbe" -}}
# Genera readiness probe completo
{{- end }}

{{- define "advanced-templates.securityContext" -}}
# Genera security context del pod
{{- end }}
```

### 5. Scheduling Helpers

```yaml
{{- define "advanced-templates.nodeSelector" -}}
# Genera node selector
{{- end }}

{{- define "advanced-templates.tolerations" -}}
# Genera tolerations
{{- end }}

{{- define "advanced-templates.affinity" -}}
# Genera affinity rules
{{- end }}
```

### 6. Validation Helpers

```yaml
{{- define "advanced-templates.validateValues" -}}
# Valida valores requeridos
# Falla si faltan valores críticos
{{- end }}
```

**Uso**:
```yaml
# Al inicio del deployment.yaml
{{- include "advanced-templates.validateValues" . }}
```

### 7. Complex Helpers

```yaml
{{- define "advanced-templates.ingressHosts" -}}
# Genera configuración compleja de hosts en Ingress
# Itera sobre múltiples hosts y paths
{{- end }}

{{- define "advanced-templates.replicaCount" -}}
# Calcula replicas (autoscaling vs manual)
{{- end }}

{{- define "advanced-templates.isProduction" -}}
# Detecta si estamos en producción
{{- end }}
```

## 🚀 Uso

### 1. Template Simple

```bash
cd advanced-templates

# Ver YAML generado
helm template myapp .

# Guardar en archivo
helm template myapp . > generated.yaml
```

### 2. Validar Sintaxis

```bash
# Lint del chart
helm lint .

# Verificar valores requeridos
helm install myapp . --dry-run --debug

# Si falta un valor requerido:
# Error: app.name is required!
```

### 3. Instalar

```bash
# Instalación estándar
helm install myapp .

# Con valores custom
helm install myapp . \
  --set app.replicaCount=5 \
  --set app.autoscaling.enabled=true
```

### 4. Ver Recursos Generados

```bash
# Ver qué se creó
kubectl get all -l app.kubernetes.io/instance=myapp

# Output esperado:
# - Deployment
# - Service
# - Ingress
# - HPA (si autoscaling.enabled=true)
# - PDB (si podDisruptionBudget.enabled=true)
# - NetworkPolicy (si networkPolicy.enabled=true)
# - ServiceAccount
# - ConfigMap
# - Secret
# - PVC (si persistence.enabled=true)
```

## 📝 Ejemplos de Uso de Helpers

### Ejemplo 1: Labels Estándar

**En deployment.yaml**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "advanced-templates.fullname" . }}
  labels:
    {{- include "advanced-templates.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "advanced-templates.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "advanced-templates.selectorLabels" . | nindent 8 }}
```

**Resultado**:
```yaml
metadata:
  name: myapp-advanced-app
  labels:
    helm.sh/chart: advanced-templates-1.0.0
    app.kubernetes.io/name: advanced-templates
    app.kubernetes.io/instance: myapp
    app.kubernetes.io/version: "2.0"
    app.kubernetes.io/managed-by: Helm
    environment: production
    team: platform
```

### Ejemplo 2: Configuración Condicional

**En deployment.yaml**:
```yaml
spec:
  {{- if not .Values.app.autoscaling.enabled }}
  replicas: {{ .Values.app.replicaCount }}
  {{- end }}
```

**Lógica**:
- Si autoscaling está habilitado: HPA controla réplicas
- Si autoscaling está deshabilitado: Usa replicaCount manual

### Ejemplo 3: Checksums para Auto-Restart

**En deployment.yaml**:
```yaml
template:
  metadata:
    annotations:
      checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
      checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
```

**Efecto**:
- Si ConfigMap o Secret cambia → checksum cambia → pods se reinician
- Automático, sin necesidad de `kubectl rollout restart`

### Ejemplo 4: Validación de Valores

**En _helpers.tpl**:
```yaml
{{- define "advanced-templates.validateValues" -}}
{{- if not .Values.app.name }}
{{- fail "app.name is required!" }}
{{- end }}
{{- if .Values.app.ingress.enabled }}
  {{- if not .Values.app.ingress.hosts }}
  {{- fail "app.ingress.hosts is required when ingress is enabled!" }}
  {{- end }}
{{- end }}
{{- end }}
```

**Resultado**:
```bash
helm install myapp . --set app.name=""
# Error: execution error at (advanced-templates/templates/deployment.yaml:2:4):
# app.name is required!
```

### Ejemplo 5: Ingress Multi-Host

**En _helpers.tpl**:
```yaml
{{- define "advanced-templates.ingressHosts" -}}
{{- range .Values.app.ingress.hosts }}
- host: {{ .host }}
  http:
    paths:
    {{- range .paths }}
    - path: {{ .path }}
      pathType: {{ .pathType }}
      backend:
        service:
          name: {{ include "advanced-templates.fullname" $ }}
          port:
            number: {{ $.Values.app.service.port }}
    {{- end }}
{{- end }}
{{- end }}
```

**En ingress.yaml**:
```yaml
spec:
  rules:
  {{- include "advanced-templates.ingressHosts" . | nindent 2 }}
```

**Resultado**:
```yaml
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-advanced-app
            port:
              number: 80
  - host: api.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: myapp-advanced-app
            port:
              number: 80
```

## ⚙️ Configuración Avanzada

### 1. Autoscaling Inteligente

```yaml
# values.yaml
app:
  replicaCount: 3          # Usado si autoscaling.enabled=false
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

```bash
# Instalar con autoscaling
helm install myapp . --set app.autoscaling.enabled=true

# Verificar HPA
kubectl get hpa myapp-advanced-app

# Ver scaling events
kubectl describe hpa myapp-advanced-app
```

### 2. PodDisruptionBudget para Alta Disponibilidad

```yaml
# values.yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 1
  # maxUnavailable: 1  # Alternativa
```

**Efecto**: Durante drains, evictions, o upgrades, siempre habrá al menos 1 pod disponible.

### 3. NetworkPolicy para Seguridad

```yaml
# values.yaml
networkPolicy:
  enabled: true
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            role: frontend
      ports:
      - protocol: TCP
        port: 80
  egress:
    - to:
      - podSelector:
          matchLabels:
            role: database
      ports:
      - protocol: TCP
        port: 5432
```

**Efecto**: Solo pods con label `role: frontend` pueden conectarse. La app solo puede conectarse a pods con label `role: database`.

### 4. Security Context Robusto

```yaml
# values.yaml
app:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    capabilities:
      drop:
        - ALL
      add:
        - NET_BIND_SERVICE
    readOnlyRootFilesystem: true
```

**Mejores prácticas de seguridad**:
- ✅ No root
- ✅ User/Group específicos
- ✅ Filesystem read-only
- ✅ Capabilities mínimos

### 5. Affinity para Distribución

```yaml
# values.yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - advanced-app
          topologyKey: kubernetes.io/hostname
```

**Efecto**: Distribuye pods en diferentes nodos (alta disponibilidad).

## 🧪 Testing

### 1. Test de Helpers

```bash
# Test individual de helper
helm template myapp . --show-only templates/deployment.yaml | grep "app.kubernetes.io/name"

# Ver todos los labels generados
helm template myapp . | grep -A5 "labels:"
```

### 2. Test de Validación

```bash
# Probar validación de valores
helm install test . --set app.name="" --dry-run

# Probar con valores incorrectos
helm install test . --set app.ingress.enabled=true --dry-run
# Error: app.ingress.hosts is required when ingress is enabled!
```

### 3. Test de Condicionales

```bash
# Sin autoscaling
helm template test . --set app.autoscaling.enabled=false | grep "replicas:"
# Output: replicas: 3

# Con autoscaling
helm template test . --set app.autoscaling.enabled=true | grep "replicas:"
# Output: (no replicas en Deployment, controlado por HPA)

# Ver HPA creado
helm template test . --set app.autoscaling.enabled=true | grep "kind: HorizontalPodAutoscaler"
```

### 4. Test de Checksums

```bash
# Ver checksum inicial
helm template myapp . | grep "checksum/config:"
# checksum/config: 5d41402abc4b2a76b9719d911017c592

# Cambiar ConfigMap y ver checksum nuevo
helm template myapp . --set configMap.data.new="value" | grep "checksum/config:"
# checksum/config: 7d793037a0760186574b0282f2f435e7
# ☝️ Diferente → pods se reiniciarían
```

## 📊 Funciones Sprig Usadas

### String Functions

```yaml
# trunc - Truncar a N caracteres
{{ .Release.Name | trunc 63 }}

# trimSuffix - Quitar sufijo
{{ .Release.Name | trunc 63 | trimSuffix "-" }}

# quote - Agregar comillas
{{ .Values.db.name | quote }}

# upper/lower
{{ .Values.env | upper }}

# replace
{{ .Chart.Version | replace "+" "_" }}
```

### Default & Conditional

```yaml
# default - Valor por defecto si vacío
{{ .Values.nameOverride | default .Chart.Name }}

# ternary - Operador ternario
{{ .Values.enabled | ternary "yes" "no" }}

# required - Falla si vacío
{{ required "app.name is required" .Values.app.name }}
```

### Type Conversion

```yaml
# toString
{{ .Values.port | toString }}

# toYaml - Convertir objeto a YAML
{{- toYaml .Values.resources | nindent 2 }}

# toJson
{{ .Values.config | toJson }}
```

### Encoding

```yaml
# b64enc/b64dec - Base64
{{ .Values.password | b64enc }}

# sha256sum - Hash
{{ include "template" . | sha256sum }}
```

### List & Dict

```yaml
# range - Iterar
{{- range .Values.hosts }}
- {{ . }}
{{- end }}

# with - Scope
{{- with .Values.config }}
  {{- toYaml . | nindent 2 }}
{{- end }}

# dict - Crear diccionario
{{ include "helper" (dict "port" 80 "protocol" "TCP") }}
```

## 🎓 Mejores Prácticas Demostradas

### ✅ DO

1. **Named Templates Reutilizables**
   ```yaml
   # En _helpers.tpl
   {{- define "myapp.labels" -}}
   app: {{ .Values.app.name }}
   {{- end }}
   
   # Usar en múltiples lugares
   labels:
     {{- include "myapp.labels" . | nindent 4 }}
   ```

2. **Validación Temprana**
   ```yaml
   {{- if not .Values.required }}
   {{- fail "required value is missing!" }}
   {{- end }}
   ```

3. **Checksums para Auto-Restart**
   ```yaml
   annotations:
     checksum/config: {{ include "path/config.yaml" . | sha256sum }}
   ```

4. **Conditional Resources**
   ```yaml
   {{- if .Values.feature.enabled }}
   # Crear recurso solo si está habilitado
   {{- end }}
   ```

5. **DRY con Helpers**
   - No repetir labels, nombres, configuraciones
   - Centralizar en _helpers.tpl

### ❌ DON'T

1. **No Hardcodear Valores**
   ```yaml
   # ❌ Malo
   name: my-app-prod
   
   # ✅ Bueno
   name: {{ include "myapp.fullname" . }}
   ```

2. **No Usar Labels Mutables en Selectors**
   ```yaml
   # ❌ Malo - version cambia
   selector:
     matchLabels:
       version: {{ .Chart.Version }}
   
   # ✅ Bueno - inmutable
   selector:
     matchLabels:
       {{- include "myapp.selectorLabels" . }}
   ```

3. **No Ignorar Indentación**
   ```yaml
   # ❌ Malo
   {{ include "helper" . }}
   
   # ✅ Bueno
   {{- include "helper" . | nindent 4 }}
   ```

4. **No Olvidar Scope ($)**
   ```yaml
   # ❌ Malo - pierde scope en range
   {{- range .Values.items }}
   image: {{ .Values.image }}  # ERROR
   {{- end }}
   
   # ✅ Bueno - usa $
   {{- range .Values.items }}
   image: {{ $.Values.image }}  # OK
   {{- end }}
   ```

## 📚 Conceptos Clave

### 1. Named Templates

Definidos en `_helpers.tpl` (el `_` hace que no genere YAML):

```yaml
{{- define "nombre" -}}
contenido
{{- end }}
```

Usados con `include`:

```yaml
{{ include "nombre" . | nindent 4 }}
```

### 2. Scope (.)

- `.` = Scope actual (root por defecto)
- `$` = Scope root (útil en loops)
- `.Values`, `.Chart`, `.Release` = Objetos disponibles

### 3. Whitespace Control

```yaml
{{- quita espacios a la izquierda
-}} quita espacios a la derecha
{{ }} mantiene espacios
```

### 4. Nindent

```yaml
{{- include "helper" . | nindent 4 }}
# Agrega 4 espacios de indentación
```

## 🔗 Referencias

- [Helm Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Sprig Functions](http://masterminds.github.io/sprig/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Go Template Language](https://pkg.go.dev/text/template)

---

**Nivel**: 🔴 Avanzado  
**Duración estimada**: 40 minutos  
**Prerequisitos**: Helm intermedio, Go templates, Kubernetes avanzado
