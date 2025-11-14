# Laboratorio 03: Services Avanzados - ExternalName, Headless y Producción

**Duración estimada:** 60 minutos  
**Nivel:** Avanzado  
**Objetivo:** Dominar ExternalName, Headless Services, Endpoints manuales y best practices de producción

---

## 📋 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

- ✅ Usar ExternalName para integrar servicios externos
- ✅ Configurar Headless Services con StatefulSets
- ✅ Crear Endpoints manuales para backends no-Kubernetes
- ✅ Implementar Services production-ready
- ✅ Aplicar todas las mejores prácticas de Services

---

## 🔧 Requisitos Previos

- Laboratorios 01 y 02 completados
- Conocimientos de StatefulSets (módulo anterior)
- Cluster con soporte para PersistentVolumes (para StatefulSet)

---

## 📚 Parte 1: ExternalName Service

### Paso 1: Crear ExternalName Service

Vamos a integrar una API externa usando ExternalName.

```bash
# Service apuntando a API externa
cat > external-api-service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: external-api
  labels:
    type: externalname
spec:
  type: ExternalName
  externalName: api.github.com
  # NO tiene selector (no hay Pods)
  # NO tiene ports (opcional, solo documentación)
EOF

kubectl apply -f external-api-service.yaml

# Verificar Service (NO tiene ClusterIP)
kubectl get service external-api

# Describir
kubectl describe service external-api
```

**Salida esperada:**
```
NAME           TYPE           CLUSTER-IP   EXTERNAL-IP      PORT(S)   AGE
external-api   ExternalName   <none>       api.github.com   <none>    10s
```

**🎯 Observa:**
- `CLUSTER-IP`: `<none>` (no se crea ClusterIP)
- `EXTERNAL-IP`: `api.github.com` (CNAME destino)

---

### Paso 2: Probar DNS Resolution

```bash
# Desde un Pod de debug
kubectl run test-external --rm -it --image=busybox --restart=Never -- sh
```

```sh
# DNS lookup del Service
nslookup external-api

# Debería resolver a CNAME: api.github.com
# Server:    10.96.0.10
# Name:      external-api
# Address 1: external-api.default.svc.cluster.local
# ↓ CNAME
# api.github.com

# Test conexión HTTPS
wget --no-check-certificate -O- https://external-api 2>&1 | head -n 5

exit
```

**🎯 Observa:** DNS resuelve a `api.github.com`, no a IP directa.

---

### Paso 3: Caso de Uso - Migración Gradual

Simular migración de servicio externo a interno.

```bash
# FASE 1: Servicio externo (ExternalName)
cat > database-service-phase1.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: database
  labels:
    phase: external
spec:
  type: ExternalName
  externalName: mydb.abc123.us-east-1.rds.amazonaws.com
EOF

kubectl apply -f database-service-phase1.yaml

# Deployment usando el Service
cat > app-using-db.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: app
        image: busybox
        command: ['sh', '-c', 'while true; do nslookup database; sleep 30; done']
EOF

kubectl apply -f app-using-db.yaml

# Ver logs (resuelve a RDS)
kubectl logs -l app=backend --tail=5
```

**Ahora migramos a PostgreSQL interno:**

```bash
# FASE 2: Cambiar a ClusterIP con Pods internos
cat > database-service-phase2.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: database  # ← MISMO nombre
  labels:
    phase: internal
spec:
  type: ClusterIP  # ← Cambió de ExternalName
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
EOF

kubectl apply -f database-service-phase2.yaml

# Ver logs de backend-app (ahora resuelve a ClusterIP)
kubectl logs -l app=backend --tail=5
```

**🎯 Ventaja:** Backend app NO cambia, solo el Service.

---

## 📚 Parte 2: Headless Service con StatefulSet

### Paso 4: Crear MySQL Cluster con Headless Service

```bash
# Headless Service (clusterIP: None)
cat > mysql-headless-service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
  labels:
    app: mysql
spec:
  clusterIP: None  # ← Headless
  selector:
    app: mysql
  ports:
  - name: mysql
    port: 3306
    targetPort: 3306
  publishNotReadyAddresses: true
EOF

kubectl apply -f mysql-headless-service.yaml

# Verificar (ClusterIP = None)
kubectl get service mysql-headless
```

---

### Paso 5: Crear StatefulSet de MySQL

```bash
# Secret para MySQL
kubectl create secret generic mysql-secret \
  --from-literal=root-password='MySecurePass123!'

# StatefulSet
cat > mysql-statefulset.yaml <<'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-headless  # ← Apunta al Headless Service
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - name: mysql
          containerPort: 3306
        
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: root-password
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
        
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        livenessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 30
          periodSeconds: 10
        
        readinessProbe:
          exec:
            command:
            - mysql
            - -h
            - localhost
            - -e
            - SELECT 1
          initialDelaySeconds: 10
          periodSeconds: 5
  
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
EOF

kubectl apply -f mysql-statefulset.yaml

# Ver Pods creándose en orden
kubectl get pods -l app=mysql -w
# Ctrl+C después de ver los 3 Pods
```

**🎯 Observa:** Pods se crean en orden: mysql-0, luego mysql-1, luego mysql-2.

---

### Paso 6: Probar DNS de Headless Service

```bash
# Verificar Endpoints del Headless Service
kubectl get endpoints mysql-headless

# DNS test
kubectl run dns-test --rm -it --image=busybox --restart=Never -- sh
```

```sh
# DNS del Service (retorna TODAS las IPs de Pods)
nslookup mysql-headless

# Output esperado:
# Server:    10.96.0.10
# Name:      mysql-headless
# Address 1: 10.1.2.10 mysql-0.mysql-headless.default.svc.cluster.local
# Address 2: 10.1.2.11 mysql-1.mysql-headless.default.svc.cluster.local
# Address 3: 10.1.2.12 mysql-2.mysql-headless.default.svc.cluster.local

# DNS de Pod INDIVIDUAL (mysql-0)
nslookup mysql-0.mysql-headless

# Output:
# Name:      mysql-0.mysql-headless
# Address 1: 10.1.2.10 mysql-0.mysql-headless.default.svc.cluster.local

# Conectar a Pod específico
telnet mysql-0.mysql-headless 3306

exit
```

**🎯 Clave:**
- Headless Service retorna IPs de Pods directamente (NO ClusterIP)
- Cada Pod tiene DNS único: `<pod-name>.<service-name>`

---

### Paso 7: Caso de Uso - Master-Slave Replication

```bash
# Conectar a mysql-0 (master)
kubectl exec -it mysql-0 -- mysql -u root -p'MySecurePass123!' -e "
CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;
CREATE TABLE IF NOT EXISTS users (id INT, name VARCHAR(50));
INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob');
SELECT * FROM users;
"

# Conectar a mysql-1 (slave, en configuración real)
kubectl exec -it mysql-1 -- mysql -u root -p'MySecurePass123!' -e "
SHOW DATABASES;
"

# Desde app, conectar a master específico:
# mysql://mysql-0.mysql-headless:3306/testdb
# 
# Lecturas balanceadas:
# mysql://mysql-1.mysql-headless:3306/testdb
# mysql://mysql-2.mysql-headless:3306/testdb
```

---

## 📚 Parte 3: Endpoints Manuales

### Paso 8: Service con Endpoints Manuales

Integrar base de datos externa (fuera del cluster).

```bash
# Service SIN selector
cat > external-database-service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: external-database
  labels:
    app: database
    type: external
spec:
  type: ClusterIP
  # SIN selector ← Endpoints NO se crean automáticamente
  ports:
  - name: postgres
    port: 5432
    targetPort: 5432
EOF

kubectl apply -f external-database-service.yaml

# Verificar Endpoints (vacío)
kubectl get endpoints external-database
# NAME                 ENDPOINTS   AGE
# external-database    <none>      5s
```

---

### Paso 9: Crear Endpoints Manuales

```bash
# Endpoints apuntando a IP externa
cat > external-database-endpoints.yaml <<'EOF'
apiVersion: v1
kind: Endpoints
metadata:
  name: external-database  # ← MISMO nombre que Service
subsets:
- addresses:
  # IPs de bases de datos externas (ejemplo)
  - ip: 192.168.100.10
    hostname: db-primary
  - ip: 192.168.100.11
    hostname: db-replica
  
  ports:
  - name: postgres
    port: 5432
    protocol: TCP
EOF

kubectl apply -f external-database-endpoints.yaml

# Ver Endpoints (ahora poblados)
kubectl get endpoints external-database

# Describir
kubectl describe endpoints external-database
```

**Salida esperada:**
```
NAME                 ENDPOINTS                                   AGE
external-database    192.168.100.10:5432,192.168.100.11:5432     10s
```

---

### Paso 10: Usar desde Pods

```bash
# Deployment usando external-database
cat > app-using-external-db.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-external-db
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: postgres:15-alpine
        env:
        - name: PGHOST
          value: "external-database"  # ← Usa nombre del Service
        - name: PGPORT
          value: "5432"
        - name: PGUSER
          value: "postgres"
        command:
        - sh
        - -c
        - |
          while true; do
            echo "Testing connection to external-database..."
            pg_isready -h external-database -p 5432 || echo "DB not reachable"
            sleep 30
          done
EOF

kubectl apply -f app-using-external-db.yaml

# Ver logs (intentos de conexión)
kubectl logs -l app=myapp --tail=10
```

**🎯 Ventaja:** App usa nombre de Service, no IPs hardcoded.

---

## 📚 Parte 4: Production-Ready Service

### Paso 11: Service con Todas las Best Practices

```bash
# Namespace de producción
kubectl create namespace production

# Service production-ready
cat > production-service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: webapp-production
  namespace: production
  
  labels:
    app: webapp
    tier: frontend
    environment: production
    version: v2.0.0
  
  annotations:
    description: "Production webapp with HA"
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
    documentation.url: "https://docs.example.com/webapp"
    team: "platform-engineering"

spec:
  type: LoadBalancer
  selector:
    app: webapp
    tier: frontend
    environment: production
  
  ports:
  - name: http
    port: 80
    targetPort: http-port
  - name: https
    port: 443
    targetPort: https-port
  - name: metrics
    port: 9090
    targetPort: metrics-port
  
  externalTrafficPolicy: Local
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
EOF

kubectl apply -f production-service.yaml
```

---

### Paso 12: Deployment Production-Ready

```bash
cat > production-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-deployment
  namespace: production
  
  labels:
    app: webapp
    environment: production
    version: v2.0.0

spec:
  replicas: 5
  
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  
  minReadySeconds: 30
  revisionHistoryLimit: 10
  
  selector:
    matchLabels:
      app: webapp
      tier: frontend
      environment: production
  
  template:
    metadata:
      labels:
        app: webapp
        tier: frontend
        environment: production
        version: v2.0.0
    
    spec:
      # Pod Anti-Affinity (distribuir en diferentes nodos)
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
      
      # Security Context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      
      containers:
      - name: webapp
        image: nginx:alpine
        imagePullPolicy: IfNotPresent
        
        ports:
        - name: http-port
          containerPort: 80
        - name: https-port
          containerPort: 443
        - name: metrics-port
          containerPort: 9090
        
        env:
        - name: ENVIRONMENT
          value: "production"
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
            cpu: "200m"
        
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
        
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
      
      terminationGracePeriodSeconds: 60
EOF

kubectl apply -f production-deployment.yaml

# Ver distribución en nodos
kubectl get pods -n production -o wide
```

---

### Paso 13: PodDisruptionBudget

```bash
# Garantizar disponibilidad mínima
cat > webapp-pdb.yaml <<'EOF'
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: webapp-pdb
  namespace: production
spec:
  minAvailable: 3  # Siempre mantener 3 Pods
  selector:
    matchLabels:
      app: webapp
      environment: production
EOF

kubectl apply -f webapp-pdb.yaml

# Verificar PDB
kubectl get pdb -n production
kubectl describe pdb webapp-pdb -n production
```

---

### Paso 14: HorizontalPodAutoscaler

```bash
# Autoscaling basado en CPU
cat > webapp-hpa.yaml <<'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp-deployment
  
  minReplicas: 5
  maxReplicas: 20
  
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
EOF

kubectl apply -f webapp-hpa.yaml

# Ver HPA
kubectl get hpa -n production
kubectl describe hpa webapp-hpa -n production
```

---

## 🎓 Desafíos Finales

### Desafío 1: Migración Completa

Migra un servicio de ExternalName a ClusterIP con Pods internos, asegurando zero downtime.

### Desafío 2: Multi-Region Database

Configura Endpoints manuales apuntando a bases de datos en múltiples regiones (simula con diferentes IPs).

### Desafío 3: Production Checklist

Revisa el Service de producción y asegúrate que cumple TODAS las best practices del módulo.

---

## 🧹 Limpieza

```bash
# Eliminar namespace production (borra todo dentro)
kubectl delete namespace production

# Eliminar otros recursos
kubectl delete statefulset mysql
kubectl delete service mysql-headless external-api database external-database
kubectl delete deployment backend-app app-using-db app-using-external-db app-external-db
kubectl delete secret mysql-secret
kubectl delete pvc -l app=mysql

# Eliminar archivos
rm -f *.yaml
```

---

## 📝 Resumen Final del Módulo

### ExternalName

✅ **Uso:**
- Integración con servicios externos
- Migración gradual (externo → interno)
- Abstracción de endpoints

⚠️ **Limitaciones:**
- Solo DNS CNAME (no IPs)
- Sin health checks
- Sin load balancing

---

### Headless Services

✅ **Uso:**
- StatefulSets (MySQL, MongoDB, Cassandra)
- DNS por Pod individual
- Master-slave replication

🔑 **Características:**
- `clusterIP: None`
- DNS retorna IPs de Pods
- Cliente responsable de balanceo

---

### Endpoints Manuales

✅ **Uso:**
- Integrar servicios externos (databases, APIs)
- Legacy systems
- Multi-datacenter

⚠️ **Responsabilidad:**
- Debes mantener IPs actualizadas
- Sin health checks automáticos
- Sin auto-scaling

---

### Production Best Practices

✅ **Checklist completo:**
- [ ] Type apropiado (LoadBalancer en cloud)
- [ ] externalTrafficPolicy: Local (si necesitas IP)
- [ ] sessionAffinity configurado si aplica
- [ ] Labels y annotations completas
- [ ] Monitoring integrado (Prometheus)
- [ ] Múltiples réplicas (HA)
- [ ] PodDisruptionBudget
- [ ] HorizontalPodAutoscaler
- [ ] Resource requests/limits
- [ ] Health checks (liveness + readiness)
- [ ] Security context
- [ ] NetworkPolicy (si aplica)

---

## 🎯 Has Completado el Módulo 08!

### Dominaste:

✅ **Services:**
- ClusterIP (interno)
- NodePort (desarrollo)
- LoadBalancer (producción cloud)
- ExternalName (integración)
- Headless (stateful apps)

✅ **Endpoints:**
- Automáticos (con selector)
- Manuales (sin selector)
- Troubleshooting

✅ **DNS Discovery:**
- Nombres de Services
- Cross-namespace
- FQDN completo

✅ **Conceptos Avanzados:**
- externalTrafficPolicy
- sessionAffinity
- kube-proxy modes
- Best practices de producción

---

## 🔗 Recursos Adicionales

- **[README del Módulo](../README.md)** - Teoría completa
- **[Ejemplos](../ejemplos/README.md)** - 13 ejemplos YAML
- **[Laboratorio 01](lab-01-clusterip-basics.md)** - ClusterIP básico
- **[Laboratorio 02](lab-02-nodeport-loadbalancer.md)** - NodePort y LoadBalancer

**Documentación oficial:**
- https://kubernetes.io/docs/concepts/services-networking/service/
- https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

---

**¡Felicidades por completar el módulo!** 🚀🎉

Ahora estás listo para implementar Services en producción con confianza.
