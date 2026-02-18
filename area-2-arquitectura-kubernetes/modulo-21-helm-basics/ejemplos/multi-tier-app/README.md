# Multi-Tier Application Chart

Helm chart completo para aplicación de 3 capas con frontend, backend, database y cache.

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────┐
│            INGRESS                      │
│  myapp.example.com                      │
└──────────┬──────────────────────────────┘
           │
     ┌─────┴─────┐
     │           │
┌────▼────┐ ┌───▼──────┐
│ FRONTEND│ │ BACKEND  │
│ (NGINX) │ │ (Node.js)│
│ x2      │ │ x3       │
└─────────┘ └────┬─────┘
                 │
         ┌───────┴───────┐
         │               │
    ┌────▼────┐    ┌────▼────┐
    │DATABASE │    │  REDIS  │
    │(PostGres│    │ (Cache) │
    │StatefulS│    │         │
    └─────────┘    └─────────┘
```

## 🚀 Quick Start

```bash
# Instalar completo
helm install myapp .

# Solo frontend y backend (sin database)
helm install myapp . --set database.enabled=false

# Producción con Ingress
helm install myapp . -f values-prod.yaml
```

## ⚙️ Componentes

### Frontend
- **Image**: nginx:1.21.0
- **Replicas**: 2
- **Port**: 80
- **Resources**: 100m CPU, 128Mi RAM

### Backend  
- **Image**: node:16-alpine
- **Replicas**: 3
- **Port**: 3000
- **Env Variables**: NODE_ENV, API_PORT, DATABASE_HOST, REDIS_HOST
- **Resources**: 250m CPU, 256Mi RAM

### Database (PostgreSQL)
- **Image**: postgres:14-alpine
- **Type**: StatefulSet
- **Port**: 5432
- **Persistence**: 10Gi PVC
- **Resources**: 250m CPU, 256Mi RAM

### Redis Cache
- **Image**: redis:7-alpine
- **Replicas**: 1
- **Port**: 6379
- **Resources**: 100m CPU, 128Mi RAM

## 📝 Configuración

### Habilitar/Deshabilitar Componentes

```yaml
# values.yaml
frontend:
  enabled: true    # Habilitar/deshabilitar

backend:
  enabled: true

database:
  enabled: true

redis:
  enabled: false   # Deshabilitar Redis
```

### Customizar Recursos

```yaml
backend:
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi
```

### Configurar Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          backend: frontend
        - path: /api
          backend: backend
```

## 🎯 Casos de Uso

### Desarrollo Local

```bash
cat > values-dev.yaml <<EOF
frontend:
  replicaCount: 1
backend:
  replicaCount: 1
database:
  persistence:
    enabled: false
redis:
  enabled: false
ingress:
  enabled: false
EOF

helm install myapp-dev . -f values-dev.yaml
kubectl port-forward svc/myapp-dev-frontend 8080:80
```

### Staging

```bash
helm install myapp-staging . \
  --set ingress.hosts[0].host=staging.myapp.com \
  --set frontend.replicaCount=2 \
  --set backend.replicaCount=2
```

### Producción

```bash
helm install myapp-prod . \
  --set ingress.hosts[0].host=myapp.com \
  --set frontend.replicaCount=3 \
  --set backend.replicaCount=5 \
  --set database.persistence.size=50Gi
```

## 🔐 Secrets

Las credenciales de database se crean automáticamente:

```bash
kubectl get secret myapp-database-secret -o yaml
```

Para usar secrets externos:

```yaml
database:
  auth:
    existingSecret: my-external-secret
```

## 📊 Monitoreo

```bash
# Ver todos los componentes
kubectl get all -l app=multi-tier-app

# Ver logs del backend
kubectl logs -l component=backend

# Ver logs de database
kubectl logs -l component=database

# Conectar a PostgreSQL
kubectl exec -it myapp-database-0 -- psql -U appuser -d appdb
```

## 🔄 Upgrade

```bash
# Actualizar imagen del backend
helm upgrade myapp . --set backend.image.tag=16.1-alpine

# Escalar frontend
helm upgrade myapp . --set frontend.replicaCount=5

# Ver historial
helm history myapp
```

## 🧹 Cleanup

```bash
helm uninstall myapp
kubectl delete pvc -l app=multi-tier-app
```

## ✅ Checklist

- [ ] Configurar valores en values.yaml
- [ ] Ajustar recursos según necesidad
- [ ] Configurar Ingress con dominio real
- [ ] Configurar secrets externos
- [ ] Habilitar persistencia para database
- [ ] Configurar backups de database
- [ ] Agregar health checks personalizados
- [ ] Configurar HPA para autoscaling
