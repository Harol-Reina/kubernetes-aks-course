# Values Override Example - Multi-Environment Configuration
# Demostración de personalización para diferentes entornos

Este ejemplo muestra cómo usar Helm para desplegar la misma aplicación
en múltiples entornos (development, staging, production) con configuraciones
diferentes usando archivos de valores.

---
# BASE: Chart estructura (igual para todos los entornos)
---

## Chart.yaml
```yaml
apiVersion: v2
name: multi-env-app
description: Aplicación multi-entorno
version: 1.0.0
appVersion: "2.5.0"
```

## values.yaml (DEFAULTS - Development)
```yaml
# Configuración por defecto para development
environment: development

replicaCount: 1

image:
  repository: myapp/webapp
  tag: "latest"
  pullPolicy: Always

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts: []

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 3

database:
  host: postgres-dev.default.svc
  port: 5432
  name: myapp_dev
  
redis:
  enabled: false
  host: ""

secrets:
  # En dev, usar valores de prueba (NO HACER EN PROD)
  dbPassword: dev-password-123
  apiKey: dev-api-key-xyz

logging:
  level: DEBUG
  format: json

monitoring:
  enabled: false
```

---
# STAGING: values-staging.yaml
---

```yaml
# Override para ambiente staging
environment: staging

# Más réplicas que dev
replicaCount: 2

image:
  # Tag específico (no latest)
  tag: "v2.5.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-staging"
  hosts:
    - host: staging.myapp.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70

database:
  host: postgres-staging.database.svc
  port: 5432
  name: myapp_staging

redis:
  enabled: true
  host: redis-staging.cache.svc

secrets:
  # En staging, usar secrets de K8s (mejor práctica)
  # Estos valores se sobreescriben en runtime
  dbPassword: OVERRIDE_FROM_SECRET
  apiKey: OVERRIDE_FROM_SECRET

logging:
  level: INFO
  format: json

monitoring:
  enabled: true
  prometheus:
    scrape: true
    port: 9090
```

---
# PRODUCTION: values-production.yaml
---

```yaml
# Override para ambiente production
environment: production

# Alta disponibilidad
replicaCount: 5

image:
  # Version específica verificada
  tag: "v2.5.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  # Configuración adicional para prod
  sessionAffinity: ClientIP

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: myapp.com
      paths:
        - path: /
          pathType: Prefix
    - host: www.myapp.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.com
        - www.myapp.com

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 5
  maxReplicas: 20
  targetCPUUtilizationPercentage: 60
  targetMemoryUtilizationPercentage: 70

database:
  host: postgres-prod-cluster.database.svc
  port: 5432
  name: myapp_production
  # Configuración adicional de prod
  maxConnections: 100
  connectionTimeout: 30

redis:
  enabled: true
  host: redis-prod-cluster.cache.svc
  port: 6379
  # Sentinel para HA
  sentinel:
    enabled: true
    master: mymaster

secrets:
  # NUNCA hardcodear secrets en production
  # Usar external-secrets-operator o similar
  dbPassword: EXTERNAL_SECRET_DB_PASSWORD
  apiKey: EXTERNAL_SECRET_API_KEY

logging:
  level: WARN
  format: json
  # Logging estructurado en prod
  structuredLogging: true
  # Enviar logs a sistema externo
  externalLogging:
    enabled: true
    endpoint: https://logs.mycompany.com

monitoring:
  enabled: true
  prometheus:
    scrape: true
    port: 9090
    path: /metrics
  healthcheck:
    liveness:
      initialDelaySeconds: 60
      periodSeconds: 10
      failureThreshold: 3
    readiness:
      initialDelaySeconds: 30
      periodSeconds: 5
      failureThreshold: 3

# PodDisruptionBudget para prod
podDisruptionBudget:
  enabled: true
  minAvailable: 3

# Afinidad de nodos para prod
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
                  - multi-env-app
          topologyKey: kubernetes.io/hostname
```

---
# TEMPLATE: templates/deployment.yaml
---

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deployment
  labels:
    app: {{ .Chart.Name }}
    environment: {{ .Values.environment }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
      release: {{ .Release.Name }}
  
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
        release: {{ .Release.Name }}
        environment: {{ .Values.environment }}
      annotations:
        # Forzar rolling update si cambia config
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
    
    spec:
      {{- if .Values.affinity }}
      affinity:
        {{- toYaml .Values.affinity | nindent 8 }}
      {{- end }}
      
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        
        ports:
        - name: http
          containerPort: 8080
        
        env:
        - name: ENVIRONMENT
          value: {{ .Values.environment }}
        - name: LOG_LEVEL
          value: {{ .Values.logging.level }}
        - name: DB_HOST
          value: {{ .Values.database.host }}
        - name: DB_PORT
          value: {{ .Values.database.port | quote }}
        - name: DB_NAME
          value: {{ .Values.database.name }}
        {{- if .Values.redis.enabled }}
        - name: REDIS_HOST
          value: {{ .Values.redis.host }}
        - name: REDIS_ENABLED
          value: "true"
        {{- end }}
        
        # Secrets desde Secret resource
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ .Release.Name }}-secrets
              key: dbPassword
        
        # Health checks personalizados por ambiente
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          {{- if .Values.monitoring.enabled }}
          initialDelaySeconds: {{ .Values.monitoring.healthcheck.liveness.initialDelaySeconds }}
          periodSeconds: {{ .Values.monitoring.healthcheck.liveness.periodSeconds }}
          {{- else }}
          initialDelaySeconds: 30
          periodSeconds: 10
          {{- end }}
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          {{- if .Values.monitoring.enabled }}
          initialDelaySeconds: {{ .Values.monitoring.healthcheck.readiness.initialDelaySeconds }}
          periodSeconds: {{ .Values.monitoring.healthcheck.readiness.periodSeconds }}
          {{- else }}
          initialDelaySeconds: 5
          periodSeconds: 5
          {{- end }}
        
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
```

---
# 🚀 INSTRUCCIONES DE USO
---

## 1. Crear el chart

```bash
# Crear estructura
mkdir -p multi-env-app/{templates,environments}

# Copiar Chart.yaml, values.yaml (defaults)
# Copiar values-staging.yaml, values-production.yaml a /environments
```

## 2. Desplegar en DEVELOPMENT

```bash
# Usa values.yaml (defaults)
helm install myapp-dev ./multi-env-app -n development --create-namespace

# Verificar
helm list -n development
kubectl get pods -n development -l environment=development
```

## 3. Desplegar en STAGING

```bash
# Override con values-staging.yaml
helm install myapp-staging ./multi-env-app \
  -f ./multi-env-app/environments/values-staging.yaml \
  -n staging \
  --create-namespace

# Verificar
helm list -n staging
kubectl get pods -n staging -l environment=staging
kubectl get ingress -n staging
```

## 4. Desplegar en PRODUCTION

```bash
# Override con values-production.yaml
helm install myapp-prod ./multi-env-app \
  -f ./multi-env-app/environments/values-production.yaml \
  -n production \
  --create-namespace

# Verificar autoscaling
kubectl get hpa -n production

# Verificar múltiples réplicas
kubectl get pods -n production -l environment=production

# Verificar PDB
kubectl get pdb -n production
```

## 5. Ver diferencias entre entornos

```bash
# Comparar valores aplicados
helm get values myapp-dev -n development
helm get values myapp-staging -n staging
helm get values myapp-prod -n production

# Ver manifests generados
helm get manifest myapp-dev -n development > dev-manifest.yaml
helm get manifest myapp-prod -n production > prod-manifest.yaml
diff dev-manifest.yaml prod-manifest.yaml
```

## 6. Override adicionales por CLI

```bash
# Staging con override temporal
helm install myapp-staging ./multi-env-app \
  -f environments/values-staging.yaml \
  --set replicaCount=3 \
  --set image.tag=v2.5.1 \
  -n staging

# Production con secrets externos
helm install myapp-prod ./multi-env-app \
  -f environments/values-production.yaml \
  --set secrets.dbPassword="$(kubectl get secret db-password -o jsonpath='{.data.password}' | base64 -d)" \
  -n production
```

## 7. Upgrade gradual entre entornos

```bash
# 1. Upgrade en dev
helm upgrade myapp-dev ./multi-env-app \
  --set image.tag=v2.6.0 \
  -n development

# 2. Si dev OK, upgrade staging
helm upgrade myapp-staging ./multi-env-app \
  -f environments/values-staging.yaml \
  --set image.tag=v2.6.0 \
  -n staging

# 3. Si staging OK, upgrade production (con rollout controlado)
helm upgrade myapp-prod ./multi-env-app \
  -f environments/values-production.yaml \
  --set image.tag=v2.6.0 \
  -n production \
  --wait \
  --timeout 10m
```

---
# 📊 COMPARACIÓN DE ENTORNOS
---

| Aspecto | Development | Staging | Production |
|---------|-------------|---------|------------|
| **Réplicas** | 1 | 2 | 5 |
| **Image Tag** | latest | v2.5.0 | v2.5.0 |
| **Autoscaling** | ❌ | ✅ (2-5) | ✅ (5-20) |
| **Ingress** | ❌ | ✅ (staging.myapp.com) | ✅ (myapp.com + TLS) |
| **Resources** | 100m/128Mi | 250m/256Mi | 500m/512Mi |
| **Redis** | ❌ | ✅ | ✅ + Sentinel |
| **Monitoring** | ❌ | ✅ | ✅ + Advanced |
| **Log Level** | DEBUG | INFO | WARN |
| **PDB** | ❌ | ❌ | ✅ (minAvailable: 3) |
| **Anti-Affinity** | ❌ | ❌ | ✅ |

---
# 🎯 ESTRATEGIAS DE OVERRIDE
---

## Estrategia 1: Archivos por Ambiente

```bash
environments/
├── values-dev.yaml
├── values-staging.yaml
├── values-prod.yaml
└── values-dr.yaml  # Disaster recovery
```

```bash
# Deploy con archivo específico
helm install myapp ./chart -f environments/values-${ENV}.yaml
```

## Estrategia 2: Múltiples archivos combinados

```bash
# Base + secrets + ambiente
helm install myapp ./chart \
  -f values.yaml \                    # Base
  -f secrets/values-secrets.yaml \    # Secrets (de vault)
  -f environments/values-prod.yaml    # Environment específico
```

## Estrategia 3: CLI overrides dinámicos

```bash
# Build dinámico con variables de CI/CD
helm install myapp ./chart \
  -f values.yaml \
  --set image.tag=${CI_COMMIT_SHA} \
  --set environment=${CI_ENVIRONMENT_NAME} \
  --set ingress.hosts[0].host=${ENVIRONMENT_URL}
```

## Estrategia 4: Helmfile (Gestión Declarativa)

```yaml
# helmfile.yaml
releases:
  - name: myapp-dev
    namespace: development
    chart: ./multi-env-app
    values:
      - values.yaml
    
  - name: myapp-staging
    namespace: staging
    chart: ./multi-env-app
    values:
      - values.yaml
      - environments/values-staging.yaml
    
  - name: myapp-prod
    namespace: production
    chart: ./multi-env-app
    values:
      - values.yaml
      - environments/values-production.yaml
```

```bash
# Deploy todos los ambientes
helmfile sync

# Deploy solo staging
helmfile -e staging sync
```

---
# 🔐 MEJORES PRÁCTICAS: SECRETS
---

## ❌ MAL: Hardcodear secrets
```yaml
# values-prod.yaml
secrets:
  dbPassword: "super-secret-password-123"  # NUNCA HACER ESTO
```

## ✅ BIEN: External Secrets Operator
```yaml
# templates/externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ .Release.Name }}-db-secret
spec:
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: {{ .Release.Name }}-secrets
  data:
  - secretKey: dbPassword
    remoteRef:
      key: {{ .Values.environment }}/database
      property: password
```

## ✅ ALTERNATIVA: Sealed Secrets
```bash
# Crear secret sellado
kubectl create secret generic db-secret \
  --from-literal=password=mypassword \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > sealed-secret.yaml

# Commitear sealed-secret.yaml (está encriptado)
# Helm usa el secret ya desplegado
```

---
# 🧪 TESTING MULTI-AMBIENTE
---

```bash
# Test 1: Validar todos los ambientes
for env in dev staging prod; do
  echo "Testing $env..."
  helm template myapp-$env ./multi-env-app \
    -f environments/values-$env.yaml \
    --validate
done

# Test 2: Verificar diferencias de recursos
helm template myapp-dev ./multi-env-app | \
  yq eval '.spec.replicas' - | grep -A 2 "kind: Deployment"
  
helm template myapp-prod ./multi-env-app \
  -f environments/values-prod.yaml | \
  yq eval '.spec.replicas' - | grep -A 2 "kind: Deployment"

# Test 3: Dry-run install
helm install myapp-test ./multi-env-app \
  -f environments/values-prod.yaml \
  --dry-run --debug > test-output.yaml
```

---
# ✅ CHECKLIST
---

- [ ] values.yaml contiene defaults sensibles
- [ ] Cada ambiente tiene su archivo values-{env}.yaml
- [ ] Secrets NO están hardcodeados
- [ ] Image tags son específicos (no `latest` en prod)
- [ ] Resource limits son apropiados por ambiente
- [ ] Autoscaling configurado para staging/prod
- [ ] Ingress con TLS en production
- [ ] PDB configurado para alta disponibilidad
- [ ] Anti-affinity en production
- [ ] Monitoring habilitado en staging/prod
- [ ] Log levels ajustados por ambiente
- [ ] Tested con `helm template` y `--dry-run`

---

**📖 Siguiente ejemplo**: [multi-tier-app-example.yaml](./multi-tier-app-example.yaml)  
**🎯 Objetivo**: Desplegar aplicación completa (frontend + backend + database)
