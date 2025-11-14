# 🧪 Laboratorio 08: Proyecto Integrador - Deployment Completo

**Duración estimada**: 90 minutos  
**Dificultad**: Avanzado  
**Objetivo**: Diseñar e implementar un deployment production-ready completo integrando todos los conceptos del módulo

---

## 📋 Escenario del Proyecto

Eres el líder técnico de una aplicación web de e-commerce que necesita:

- **Alta disponibilidad** (99.9% uptime)
- **Escalado automático** según tráfico
- **Deployments sin downtime**
- **Rollback rápido** en caso de problemas
- **Monitoreo y observabilidad**
- **Seguridad** hardened

---

## 🎯 Parte 1: Arquitectura y Diseño (15 min)

### **Paso 1: Definir arquitectura**

```bash
# Crear namespace del proyecto
kubectl create namespace ecommerce-prod
kubectl config set-context --current --namespace=ecommerce-prod
```

**Componentes a desplegar**:
1. **Frontend**: 3 componentes (web, api-gateway, cdn)
2. **Backend**: 2 servicios (product-service, order-service)
3. **Base de datos**: Redis (cache)

### **Paso 2: Crear estructura de archivos**

```bash
# Crear directorios
mkdir -p proyecto-ecommerce/{frontend,backend,database,monitoring,manifests}

cd proyecto-ecommerce
```

---

## 🎯 Parte 2: Frontend Deployment (20 min)

### **Paso 1: Crear ConfigMap para frontend**

Crea `frontend/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: ecommerce-prod
data:
  nginx.conf: |
    server {
      listen 80;
      server_name ecommerce.example.com;
      
      location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
      }
      
      location /api {
        proxy_pass http://api-gateway-service:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
      }
      
      location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
      }
    }
  
  app-config.json: |
    {
      "apiUrl": "http://api-gateway-service:8080",
      "environment": "production",
      "version": "1.0.0",
      "features": {
        "analytics": true,
        "darkMode": true
      }
    }
```

### **Paso 2: Crear Secrets para frontend**

```bash
# Crear secrets
kubectl create secret generic frontend-secrets \
  --from-literal=api-key='prod-api-key-abc123' \
  --from-literal=analytics-token='GA-XXXXX-YY' \
  -n ecommerce-prod
```

### **Paso 3: Deployment del frontend**

Crea `frontend/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-web
  namespace: ecommerce-prod
  labels:
    app: frontend
    component: web
    tier: frontend
  annotations:
    kubernetes.io/change-cause: "Initial production release v1.0.0"
spec:
  replicas: 5
  revisionHistoryLimit: 10
  
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  
  selector:
    matchLabels:
      app: frontend
      component: web
  
  template:
    metadata:
      labels:
        app: frontend
        component: web
        version: "1.0.0"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9113"
    spec:
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
                  - frontend
              topologyKey: kubernetes.io/hostname
      
      securityContext:
        runAsNonRoot: true
        runAsUser: 101
        fsGroup: 101
      
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        imagePullPolicy: IfNotPresent
        
        ports:
        - name: http
          containerPort: 80
        - name: metrics
          containerPort: 9113
        
        env:
        - name: APP_VERSION
          value: "1.0.0"
        - name: ENVIRONMENT
          value: "production"
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: frontend-secrets
              key: api-key
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        
        readinessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 15
          timeoutSeconds: 5
          failureThreshold: 3
        
        startupProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 0
          periodSeconds: 5
          failureThreshold: 30
        
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]
        
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /var/cache/nginx
        - name: run
          mountPath: /var/run
      
      volumes:
      - name: config
        configMap:
          name: frontend-config
          items:
          - key: nginx.conf
            path: default.conf
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
      - name: run
        emptyDir: {}
      
      terminationGracePeriodSeconds: 30
```

```bash
# Aplicar
kubectl apply -f frontend/configmap.yaml
kubectl apply -f frontend/deployment.yaml

# Verificar
kubectl rollout status deployment/frontend-web -n ecommerce-prod
kubectl get pods -l app=frontend -o wide
```

### **Paso 4: Service para frontend**

Crea `frontend/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: ecommerce-prod
  labels:
    app: frontend
spec:
  type: ClusterIP
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
  
  selector:
    app: frontend
    component: web
  
  ports:
  - name: http
    port: 80
    targetPort: http
  - name: metrics
    port: 9113
    targetPort: metrics
```

```bash
kubectl apply -f frontend/service.yaml
kubectl get svc frontend-service
```

---

## 🎯 Parte 3: Backend Services (20 min)

### **Paso 1: Product Service**

Crea `backend/product-service.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: ecommerce-prod
  annotations:
    kubernetes.io/change-cause: "Product service v1.0.0"
spec:
  replicas: 3
  revisionHistoryLimit: 10
  
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  
  selector:
    matchLabels:
      app: product-service
  
  template:
    metadata:
      labels:
        app: product-service
        tier: backend
        version: "1.0.0"
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine  # Simula backend
        ports:
        - name: http
          containerPort: 80
        
        env:
        - name: SERVICE_NAME
          value: "product-service"
        - name: VERSION
          value: "1.0.0"
        
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
        
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 15
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: ecommerce-prod
spec:
  selector:
    app: product-service
  ports:
  - port: 8080
    targetPort: http
```

### **Paso 2: Order Service**

Crea `backend/order-service.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: ecommerce-prod
  annotations:
    kubernetes.io/change-cause: "Order service v1.0.0"
spec:
  replicas: 4
  revisionHistoryLimit: 10
  
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  
  selector:
    matchLabels:
      app: order-service
  
  template:
    metadata:
      labels:
        app: order-service
        tier: backend
        version: "1.0.0"
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine
        ports:
        - name: http
          containerPort: 80
        
        env:
        - name: SERVICE_NAME
          value: "order-service"
        - name: VERSION
          value: "1.0.0"
        
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
        
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 15
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: ecommerce-prod
spec:
  selector:
    app: order-service
  ports:
  - port: 8081
    targetPort: http
```

```bash
# Aplicar backends
kubectl apply -f backend/product-service.yaml
kubectl apply -f backend/order-service.yaml

# Verificar
kubectl get deployments -n ecommerce-prod
kubectl get pods -l tier=backend
```

---

## 🎯 Parte 4: Escalado Automático (10 min)

### **Paso 1: Habilitar metrics-server**

```bash
# En minikube
minikube addons enable metrics-server

# Verificar
kubectl top nodes
```

### **Paso 2: Crear HPA para frontend**

Crea `frontend/hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-hpa
  namespace: ecommerce-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend-web
  
  minReplicas: 3
  maxReplicas: 15
  
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 3
        periodSeconds: 30
      selectPolicy: Max
```

```bash
kubectl apply -f frontend/hpa.yaml
kubectl get hpa -n ecommerce-prod
```

---

## 🎯 Parte 5: Alta Disponibilidad (10 min)

### **Paso 1: PodDisruptionBudget**

Crea `manifests/pdb.yaml`:

```yaml
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: frontend-pdb
  namespace: ecommerce-prod
spec:
  minAvailable: 3
  selector:
    matchLabels:
      app: frontend
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: product-service-pdb
  namespace: ecommerce-prod
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: product-service
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: order-service-pdb
  namespace: ecommerce-prod
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: order-service
```

```bash
kubectl apply -f manifests/pdb.yaml
kubectl get pdb -n ecommerce-prod
```

---

## 🎯 Parte 6: Blue-Green Deployment (15 min)

### **Paso 1: Preparar deployment Blue (actual)**

Ya tienes `frontend-web` como versión Blue.

### **Paso 2: Crear versión Green**

Crea `frontend/deployment-green.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-web-green
  namespace: ecommerce-prod
  labels:
    version: green
  annotations:
    kubernetes.io/change-cause: "Green deployment v2.0.0"
spec:
  replicas: 5
  selector:
    matchLabels:
      app: frontend
      component: web
      version: green
  template:
    metadata:
      labels:
        app: frontend
        component: web
        version: green
    spec:
      containers:
      - name: nginx
        image: nginx:1.22-alpine  # Nueva versión
        ports:
        - name: http
          containerPort: 80
        env:
        - name: APP_VERSION
          value: "2.0.0"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
        volumeMounts:
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: tmp
        emptyDir: {}
```

```bash
# Deploy Green
kubectl apply -f frontend/deployment-green.yaml

# Verificar ambas versiones
kubectl get pods -l app=frontend -L version
```

### **Paso 3: Servicio de testing Green**

```bash
# Crear service temporal para testing
kubectl expose deployment frontend-web-green --name=frontend-green-test --port=80 --target-port=http -n ecommerce-prod

# Probar Green
kubectl port-forward svc/frontend-green-test 8081:80 -n ecommerce-prod &
curl localhost:8081/health
```

### **Paso 4: Switch a Green**

```bash
# Ver selector actual
kubectl get svc frontend-service -o yaml | grep -A 3 selector

# Cambiar a Green
kubectl patch service frontend-service -n ecommerce-prod -p '{"spec":{"selector":{"version":"green"}}}'

# Verificar
kubectl get endpoints frontend-service -n ecommerce-prod

# Rollback instantáneo si hay problemas
# kubectl patch service frontend-service -n ecommerce-prod -p '{"spec":{"selector":{"version":null}}}'
```

---

## 🎯 Parte 7: Implementar Rollback (10 min)

### **Paso 1: Simular deployment problemático**

```bash
# Actualizar frontend-web con imagen inválida
kubectl set image deployment/frontend-web nginx=nginx:invalid-tag -n ecommerce-prod
kubectl annotate deployment/frontend-web kubernetes.io/change-cause="v2.1.0 - PROBLEMA DETECTADO" --overwrite
```

### **Paso 2: Detectar y rollback**

```bash
# Monitorear (en otra terminal)
watch kubectl get pods -l app=frontend,component=web

# Ver historial
kubectl rollout history deployment/frontend-web -n ecommerce-prod

# Rollback
kubectl rollout undo deployment/frontend-web -n ecommerce-prod

# Verificar recuperación
kubectl rollout status deployment/frontend-web -n ecommerce-prod
```

---

## 🎯 Parte 8: Validación Final (10 min)

### **Paso 1: Verificar todos los componentes**

```bash
# Ver todos los deployments
kubectl get deployments -n ecommerce-prod

# Ver todos los pods
kubectl get pods -n ecommerce-prod -o wide

# Ver servicios
kubectl get svc -n ecommerce-prod

# Ver HPA
kubectl get hpa -n ecommerce-prod

# Ver PDB
kubectl get pdb -n ecommerce-prod

# Ver historial de rollouts
kubectl rollout history deployment/frontend-web -n ecommerce-prod
kubectl rollout history deployment/product-service -n ecommerce-prod
kubectl rollout history deployment/order-service -n ecommerce-prod
```

### **Paso 2: Generar reporte del proyecto**

```bash
cat > proyecto-ecommerce-report.md << 'EOF'
# 📊 Reporte del Proyecto E-commerce

## ✅ Componentes Desplegados

### Frontend
- **Deployment**: frontend-web (5 replicas)
- **Version actual**: 1.0.0
- **Service**: frontend-service (ClusterIP)
- **HPA**: 3-15 replicas (CPU 70%, Memory 80%)
- **PDB**: minAvailable=3

### Backend
- **Product Service**: 3 replicas
- **Order Service**: 4 replicas
- **PDB**: maxUnavailable=1 y minAvailable=2

## 🎯 Características Implementadas

- [x] Rolling Updates sin downtime
- [x] Health checks (readiness, liveness, startup)
- [x] Resource limits configurados
- [x] Escalado automático (HPA)
- [x] Alta disponibilidad (PDB)
- [x] Blue-Green deployment implementado
- [x] Rollback strategy probada
- [x] ConfigMaps y Secrets
- [x] Security context hardened
- [x] Anti-affinity para distribución

## 📈 Métricas

- **Pods totales**: ~12-15
- **Uptime esperado**: 99.9%
- **Tiempo de rollback**: < 30 segundos
- **Tiempo de scaling**: < 60 segundos

## 🔐 Seguridad

- runAsNonRoot: true
- readOnlyRootFilesystem: true
- Capabilities dropped: ALL
- Secrets para datos sensibles

## ✅ Tests Realizados

1. Rolling update exitoso
2. Rollback a versión anterior
3. Blue-Green switch
4. Health checks funcionando
5. HPA scaling (manual trigger)

## 🚀 Próximos Pasos

- Implementar Canary deployments
- Agregar Ingress con TLS
- Implementar NetworkPolicies
- Agregar monitoreo con Prometheus
EOF

cat proyecto-ecommerce-report.md
```

---

## 🧹 Limpieza

```bash
# Eliminar namespace completo
kubectl delete namespace ecommerce-prod

# Restaurar context
kubectl config set-context --current --namespace=default
```

---

## ✅ Checklist de Evaluación

### Requisitos Funcionales
- [ ] Frontend deployment con 5 replicas
- [ ] Backend services (product + order)
- [ ] ConfigMaps para configuración
- [ ] Secrets para datos sensibles
- [ ] Services expuestos correctamente

### Alta Disponibilidad
- [ ] PodDisruptionBudgets configurados
- [ ] HPA funcionando
- [ ] Anti-affinity configurada
- [ ] Múltiples replicas por servicio

### Deployments
- [ ] Rolling updates sin downtime
- [ ] Rollback funcional
- [ ] Blue-Green implementado
- [ ] Change-cause annotations

### Health & Monitoring
- [ ] Readiness probes configuradas
- [ ] Liveness probes configuradas
- [ ] Startup probes configuradas
- [ ] Resource limits apropiados

### Seguridad
- [ ] Security contexts configurados
- [ ] runAsNonRoot habilitado
- [ ] readOnlyRootFilesystem donde posible
- [ ] Secrets usados para datos sensibles

---

## 🎓 Criterios de Evaluación

| Criterio | Peso | Puntos |
|----------|------|--------|
| **Deployments funcionando** | 20% | /20 |
| **Alta disponibilidad (HPA, PDB)** | 20% | /20 |
| **Rolling updates y rollback** | 20% | /20 |
| **Blue-Green implementation** | 15% | /15 |
| **Health checks configurados** | 10% | /10 |
| **Security best practices** | 10% | /10 |
| **Documentación y reporte** | 5% | /5 |
| **TOTAL** | 100% | /100 |

---

## 🎉 ¡Felicitaciones!

Has completado el proyecto integrador del módulo de Deployments y Rollouts. Este proyecto demuestra:

- ✅ Dominio completo de Deployments
- ✅ Estrategias avanzadas (Rolling, Blue-Green)
- ✅ Alta disponibilidad en producción
- ✅ Escalado automático
- ✅ Rollback y recuperación
- ✅ Best practices de seguridad
- ✅ Configuración production-ready

**🎓 Estás listo para gestionar deployments en producción!**
