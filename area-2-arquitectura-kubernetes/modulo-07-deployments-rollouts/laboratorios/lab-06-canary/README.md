# 🧪 Laboratorio 06: Best Practices en Production

**Duración estimada**: 50 minutos  
**Dificultad**: Avanzado  
**Objetivo**: Implementar deployment production-ready con todas las best practices

---

## 📋 Prerequisitos

```bash
# Verificar cluster
minikube status

# Crear namespace
kubectl create namespace lab-production
kubectl config set-context --current --namespace=lab-production

# Verificar
kubectl get ns lab-production
```

---

## 🎯 Ejercicio 1: Deployment Production-Ready Completo

### **Paso 1: Template base production-ready**

Crea `production-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-prod
  namespace: lab-production
  labels:
    app: webapp
    tier: frontend
    environment: production
  annotations:
    kubernetes.io/change-cause: "Production release v1.0.0"
    deployment.kubernetes.io/description: "Web application production deployment"
spec:
  # Estrategia de deployment
  replicas: 5
  revisionHistoryLimit: 10
  
  # Estrategia de actualización
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2         # Máximo 2 pods adicionales durante update
      maxUnavailable: 1   # Máximo 1 pod no disponible
  
  # Selector
  selector:
    matchLabels:
      app: webapp
      tier: frontend
  
  # Template del pod
  template:
    metadata:
      labels:
        app: webapp
        tier: frontend
        version: "1.0.0"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      # Anti-affinity para distribuir pods
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
                  - webapp
              topologyKey: kubernetes.io/hostname
      
      # Tolerations para nodos específicos
      tolerations:
      - key: "node-role"
        operator: "Equal"
        value: "production"
        effect: "NoSchedule"
      
      # Security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      
      containers:
      - name: webapp
        image: nginx:1.21-alpine
        imagePullPolicy: IfNotPresent
        
        # Ports
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        - name: metrics
          containerPort: 8080
          protocol: TCP
        
        # Environment variables
        env:
        - name: APP_VERSION
          value: "1.0.0"
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "info"
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        
        # Resource requests y limits
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        # Readiness probe
        readinessProbe:
          httpGet:
            path: /
            port: http
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        
        # Liveness probe
        livenessProbe:
          httpGet:
            path: /
            port: http
            scheme: HTTP
          initialDelaySeconds: 30
          periodSeconds: 15
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        
        # Startup probe para aplicaciones lentas
        startupProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 30  # 30 * 5s = 150s máximo para startup
        
        # Lifecycle hooks
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]  # Graceful shutdown
        
        # Security context del contenedor
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        # Volume mounts
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /var/cache/nginx
        - name: run
          mountPath: /var/run
      
      # Volumes
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
      - name: run
        emptyDir: {}
      
      # Termination grace period
      terminationGracePeriodSeconds: 30
```

```bash
# Aplicar
kubectl apply -f production-deployment.yaml

# Monitorear
kubectl rollout status deployment/webapp-prod

# Verificar
kubectl get deployment webapp-prod -o wide
kubectl get pods -l app=webapp -o wide
```

### **Paso 2: Verificar distribución de pods (anti-affinity)**

```bash
# Ver en qué nodos están los pods
kubectl get pods -l app=webapp -o wide

# Si solo tienes 1 nodo (minikube), todos estarán ahí
# En cluster multi-nodo, estarían distribuidos

# Ver eventos de scheduling
kubectl get events --sort-by='.lastTimestamp' | grep webapp-prod
```

### **Paso 3: Probar health checks**

```bash
# Ver estado de readiness
kubectl get pods -l app=webapp

# Ver detalles de probes en un pod
POD_NAME=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME | grep -A 10 "Liveness\|Readiness\|Startup"

# Ver logs de probes (si hay fallos)
kubectl logs $POD_NAME
```

### **Paso 4: Probar resource limits**

```bash
# Ver recursos asignados
kubectl top pods -l app=webapp

# Ver límites configurados
kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{.spec.containers[*].resources}{"\n\n"}{end}'
```

---

## 🎯 Ejercicio 2: ConfigMap y Secrets Management

### **Paso 1: Crear ConfigMap para configuración**

Crea `webapp-configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: webapp-config
  namespace: lab-production
data:
  # Configuración de aplicación
  app.conf: |
    server {
      listen 80;
      server_name webapp.example.com;
      
      location / {
        root /usr/share/nginx/html;
        index index.html;
      }
      
      location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
      }
    }
  
  # Variables de configuración
  LOG_FORMAT: "json"
  MAX_CONNECTIONS: "1000"
  TIMEOUT: "30s"
```

```bash
# Aplicar
kubectl apply -f webapp-configmap.yaml

# Verificar
kubectl get configmap webapp-config
kubectl describe configmap webapp-config
```

### **Paso 2: Crear Secret para datos sensibles**

```bash
# Crear secret desde literal
kubectl create secret generic webapp-secrets \
  --from-literal=database-password='P@ssw0rd123' \
  --from-literal=api-key='secret-api-key-12345' \
  --from-literal=jwt-secret='jwt-secret-token'

# Verificar (valores codificados en base64)
kubectl get secret webapp-secrets -o yaml

# Ver valores decodificados
kubectl get secret webapp-secrets -o jsonpath='{.data.database-password}' | base64 -d
```

### **Paso 3: Actualizar deployment con ConfigMap y Secrets**

Crea `webapp-with-config.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-with-config
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp-config
  template:
    metadata:
      labels:
        app: webapp-config
    spec:
      containers:
      - name: webapp
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        
        # Environment desde ConfigMap
        env:
        - name: LOG_FORMAT
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: LOG_FORMAT
        - name: MAX_CONNECTIONS
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: MAX_CONNECTIONS
        
        # Environment desde Secret
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: database-password
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: api-key
        
        # Volume mount para config file
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d/
        - name: tmp
          mountPath: /tmp
        
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      
      volumes:
      - name: config
        configMap:
          name: webapp-config
          items:
          - key: app.conf
            path: default.conf
      - name: tmp
        emptyDir: {}
```

```bash
# Aplicar
kubectl apply -f webapp-with-config.yaml

# Verificar
kubectl get pods -l app=webapp-config

# Ver variables de entorno en un pod
POD_NAME=$(kubectl get pods -l app=webapp-config -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- env | grep -E 'LOG_FORMAT|MAX_CONNECTIONS|DATABASE_PASSWORD'

# Ver archivo de configuración montado
kubectl exec $POD_NAME -- cat /etc/nginx/conf.d/default.conf
```

---

## 🎯 Ejercicio 3: Service y Ingress Production-Ready

### **Paso 1: Service con configuraciones avanzadas**

Crea `webapp-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
  namespace: lab-production
  labels:
    app: webapp
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # Para AWS
spec:
  type: ClusterIP
  sessionAffinity: ClientIP  # Sticky sessions
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 horas
  
  selector:
    app: webapp
    tier: frontend
  
  ports:
  - name: http
    port: 80
    targetPort: http
    protocol: TCP
  - name: metrics
    port: 8080
    targetPort: metrics
    protocol: TCP
```

```bash
# Aplicar
kubectl apply -f webapp-service.yaml

# Verificar
kubectl get svc webapp-service
kubectl describe svc webapp-service

# Ver endpoints
kubectl get endpoints webapp-service
```

### **Paso 2: Crear Ingress (si tienes ingress controller)**

Crea `webapp-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  namespace: lab-production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  rules:
  - host: webapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80
  tls:
  - hosts:
    - webapp.example.com
    secretName: webapp-tls-cert
```

```bash
# Si tienes ingress controller instalado
# kubectl apply -f webapp-ingress.yaml
# kubectl get ingress webapp-ingress
```

---

## 🎯 Ejercicio 4: HorizontalPodAutoscaler (HPA)

### **Paso 1: Habilitar metrics-server (si no está)**

```bash
# En minikube
minikube addons enable metrics-server

# Verificar
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml
kubectl top nodes
kubectl top pods -n lab-production
```

### **Paso 2: Crear HPA**

Crea `webapp-hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
  namespace: lab-production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp-prod
  
  minReplicas: 3
  maxReplicas: 10
  
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Escalar cuando CPU > 70%
  
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80  # Escalar cuando memoria > 80%
  
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Esperar 5 min antes de scale down
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60  # Reducir máximo 50% cada minuto
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30  # Duplicar máximo cada 30 segundos
      - type: Pods
        value: 2
        periodSeconds: 30  # O agregar 2 pods cada 30 segundos
      selectPolicy: Max  # Elegir la más agresiva
```

```bash
# Aplicar
kubectl apply -f webapp-hpa.yaml

# Verificar
kubectl get hpa webapp-hpa
kubectl describe hpa webapp-hpa

# Monitorear autoscaling
watch kubectl get hpa webapp-hpa
```

### **Paso 3: Generar carga para probar HPA**

```bash
# Crear pod de carga
kubectl run load-generator --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://webapp-service.lab-production.svc.cluster.local; done"

# Monitorear HPA (en otra terminal)
watch kubectl get hpa webapp-hpa

# Ver pods escalando
watch kubectl get pods -l app=webapp

# Limpiar
kubectl delete pod load-generator
```

---

## 🎯 Ejercicio 5: PodDisruptionBudget (PDB)

### **Paso 1: Crear PDB para alta disponibilidad**

Crea `webapp-pdb.yaml`:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: webapp-pdb
  namespace: lab-production
spec:
  minAvailable: 2  # Mínimo 2 pods siempre disponibles
  selector:
    matchLabels:
      app: webapp
      tier: frontend
---
# PDB alternativo usando maxUnavailable
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: webapp-pdb-percentage
  namespace: lab-production
spec:
  maxUnavailable: 25%  # Máximo 25% no disponible durante disrupciones
  selector:
    matchLabels:
      app: webapp-config
```

```bash
# Aplicar
kubectl apply -f webapp-pdb.yaml

# Verificar
kubectl get pdb -n lab-production
kubectl describe pdb webapp-pdb
```

### **Paso 2: Probar PDB con drain**

```bash
# Ver en qué nodos están los pods
kubectl get pods -l app=webapp -o wide

# Intentar drain de un nodo (si tienes multi-nodo)
# kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# El PDB previene que se eliminen demasiados pods simultáneamente
```

---

## 🎯 Ejercicio 6: Monitoring y Observability

### **Paso 1: Labels y annotations consistentes**

```bash
# Verificar labels en todos los recursos
kubectl get all -n lab-production --show-labels

# Labels recomendados:
# - app: nombre de la aplicación
# - version: versión de la aplicación
# - environment: prod/staging/dev
# - tier: frontend/backend/database
# - managed-by: kubectl/helm/terraform
```

### **Paso 2: Crear ServiceMonitor para Prometheus**

Crea `webapp-servicemonitor.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: webapp-monitor
  namespace: lab-production
  labels:
    app: webapp
spec:
  selector:
    matchLabels:
      app: webapp
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

---

## 🎯 Ejercicio 7: NetworkPolicy para Seguridad

### **Paso 1: Crear NetworkPolicy restrictiva**

Crea `webapp-networkpolicy.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: webapp-network-policy
  namespace: lab-production
spec:
  podSelector:
    matchLabels:
      app: webapp
  
  policyTypes:
  - Ingress
  - Egress
  
  ingress:
  # Permitir tráfico desde ingress controller
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80
  
  # Permitir tráfico desde Prometheus
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 8080
  
  egress:
  # Permitir DNS
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
  
  # Permitir tráfico a backend
  - to:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 8080
```

```bash
# Aplicar
kubectl apply -f webapp-networkpolicy.yaml

# Verificar
kubectl get networkpolicy -n lab-production
kubectl describe networkpolicy webapp-network-policy
```

---

## 🧹 Limpieza

```bash
# Eliminar todos los recursos
kubectl delete namespace lab-production

# Restaurar namespace
kubectl config set-context --current --namespace=default
```

---

## ✅ Checklist Production-Ready

- [ ] **Deployment**
  - [ ] Labels y annotations completas
  - [ ] Resource requests y limits configurados
  - [ ] Readiness, liveness y startup probes
  - [ ] Anti-affinity para distribución
  - [ ] Security context configurado
  - [ ] Graceful shutdown con preStop hook
  - [ ] RevisionHistoryLimit apropiado

- [ ] **ConfigMap y Secrets**
  - [ ] Configuración externalizada
  - [ ] Secrets para datos sensibles
  - [ ] Versionado de configuración

- [ ] **Estrategia de Actualización**
  - [ ] RollingUpdate con maxSurge y maxUnavailable
  - [ ] Change-cause annotations
  - [ ] Rollback plan documentado

- [ ] **Alta Disponibilidad**
  - [ ] Mínimo 3 replicas
  - [ ] PodDisruptionBudget configurado
  - [ ] HPA para escalado automático

- [ ] **Networking**
  - [ ] Service con configuración apropiada
  - [ ] Ingress con TLS
  - [ ] NetworkPolicy para seguridad

- [ ] **Observability**
  - [ ] Logs estructurados
  - [ ] Métricas expuestas
  - [ ] Health endpoints

---

## 🎓 Resumen

En este laboratorio implementaste:

- ✅ Deployment production-ready completo
- ✅ ConfigMap y Secrets management
- ✅ Service e Ingress avanzados
- ✅ HorizontalPodAutoscaler para escalado
- ✅ PodDisruptionBudget para HA
- ✅ NetworkPolicy para seguridad
- ✅ Monitoring y observability

**Próximo**: Lab 07 - Troubleshooting de Deployments 🚀
