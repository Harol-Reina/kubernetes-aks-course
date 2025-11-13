{{/*
============================================================================
HELPERS - Named Templates Reutilizables
============================================================================
Los helpers se definen con {{- define "nombre" -}} y se usan con {{- include "nombre" . -}}
*/}}

{{/*
Expand the name of the chart.
Genera el nombre base para todos los recursos.
*/}}
{{- define "advanced-templates.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
Combina release name con chart name para nombres únicos.
Trunca a 63 caracteres (límite de Kubernetes).
*/}}
{{- define "advanced-templates.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
Usado para el label "chart" en todos los recursos.
*/}}
{{- define "advanced-templates.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels - Aplicado a TODOS los recursos
Incluye labels estándar de Kubernetes y custom labels.
Uso: {{ include "advanced-templates.labels" . | nindent 4 }}
*/}}
{{- define "advanced-templates.labels" -}}
helm.sh/chart: {{ include "advanced-templates.chart" . }}
{{ include "advanced-templates.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels - Usado por Deployments, Services, etc.
IMPORTANTE: Estos labels deben ser inmutables (no cambiar entre upgrades).
*/}}
{{- define "advanced-templates.selectorLabels" -}}
app.kubernetes.io/name: {{ include "advanced-templates.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use.
Si no se especifica nombre, usa el fullname del chart.
*/}}
{{- define "advanced-templates.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "advanced-templates.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate the image name with tag.
Combina repository:tag de forma consistente.
*/}}
{{- define "advanced-templates.image" -}}
{{- $tag := .Values.app.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.app.image.repository $tag }}
{{- end }}

{{/*
Generate container port name based on protocol.
Estandariza nombres de puertos.
*/}}
{{- define "advanced-templates.portName" -}}
{{- $port := .port }}
{{- $protocol := .protocol | default "TCP" | lower }}
{{- if eq $protocol "tcp" }}
{{- if eq ($port | int) 80 }}http{{- else if eq ($port | int) 443 }}https{{- else }}tcp-{{ $port }}{{- end }}
{{- else }}
{{- printf "%s-%d" $protocol ($port | int) }}
{{- end }}
{{- end }}

{{/*
Common annotations
Combina annotations comunes con annotations custom.
*/}}
{{- define "advanced-templates.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Generate environment variables from list.
Convierte lista de env vars a formato YAML válido.
*/}}
{{- define "advanced-templates.env" -}}
{{- range .Values.app.env }}
- name: {{ .name }}
  {{- if .value }}
  value: {{ .value | quote }}
  {{- else if .valueFrom }}
  valueFrom:
    {{- toYaml .valueFrom | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Generate resource limits and requests.
Aplica resources si están definidos.
*/}}
{{- define "advanced-templates.resources" -}}
{{- if .Values.app.resources }}
resources:
  {{- toYaml .Values.app.resources | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Generate liveness probe.
Template reutilizable para liveness probe.
*/}}
{{- define "advanced-templates.livenessProbe" -}}
{{- if .Values.app.livenessProbe }}
livenessProbe:
  {{- toYaml .Values.app.livenessProbe | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Generate readiness probe.
Template reutilizable para readiness probe.
*/}}
{{- define "advanced-templates.readinessProbe" -}}
{{- if .Values.app.readinessProbe }}
readinessProbe:
  {{- toYaml .Values.app.readinessProbe | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Generate security context.
Aplica security context del pod y container.
*/}}
{{- define "advanced-templates.securityContext" -}}
{{- if .Values.app.securityContext }}
securityContext:
  {{- toYaml .Values.app.securityContext | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Generate node selector.
Permite scheduling en nodos específicos.
*/}}
{{- define "advanced-templates.nodeSelector" -}}
{{- if .Values.nodeSelector }}
nodeSelector:
  {{- toYaml .Values.nodeSelector | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Generate tolerations.
Permite pods en nodos con taints.
*/}}
{{- define "advanced-templates.tolerations" -}}
{{- if .Values.tolerations }}
tolerations:
  {{- toYaml .Values.tolerations | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Generate affinity rules.
Controla scheduling basado en afinidad.
*/}}
{{- define "advanced-templates.affinity" -}}
{{- if .Values.affinity }}
affinity:
  {{- toYaml .Values.affinity | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Validate required values.
Helper que valida valores obligatorios y falla si faltan.
Uso: {{ include "advanced-templates.validateValues" . }}
*/}}
{{- define "advanced-templates.validateValues" -}}
{{- if not .Values.app.name }}
{{- fail "app.name is required!" }}
{{- end }}
{{- if not .Values.app.image.repository }}
{{- fail "app.image.repository is required!" }}
{{- end }}
{{- if .Values.app.ingress.enabled }}
  {{- if not .Values.app.ingress.hosts }}
  {{- fail "app.ingress.hosts is required when ingress is enabled!" }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Generate ingress host configuration.
Helper complejo para generar configuración de hosts en Ingress.
*/}}
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

{{/*
Calculate replica count.
Usa autoscaling si está habilitado, sino usa replicaCount.
*/}}
{{- define "advanced-templates.replicaCount" -}}
{{- if .Values.app.autoscaling.enabled }}
{{- .Values.app.autoscaling.minReplicas }}
{{- else }}
{{- .Values.app.replicaCount }}
{{- end }}
{{- end }}

{{/*
Check if autoscaling is enabled and return boolean.
Helper que devuelve true/false.
*/}}
{{- define "advanced-templates.isAutoscalingEnabled" -}}
{{- if .Values.app.autoscaling.enabled }}
true
{{- else }}
false
{{- end }}
{{- end }}

{{/*
Format memory size.
Convierte valores de memoria a formato Kubernetes.
*/}}
{{- define "advanced-templates.formatMemory" -}}
{{- $size := . }}
{{- if hasSuffix "Mi" $size }}
{{- $size }}
{{- else if hasSuffix "Gi" $size }}
{{- $size }}
{{- else }}
{{- printf "%sMi" $size }}
{{- end }}
{{- end }}

{{/*
Generate PVC name.
Nombre único para PersistentVolumeClaim.
*/}}
{{- define "advanced-templates.pvcName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- include "advanced-templates.fullname" . }}-data
{{- end }}
{{- end }}

{{/*
Check if running in production.
Helper que detecta si estamos en producción basado en labels.
*/}}
{{- define "advanced-templates.isProduction" -}}
{{- if eq (index .Values.commonLabels "environment") "production" }}
true
{{- else }}
false
{{- end }}
{{- end }}
