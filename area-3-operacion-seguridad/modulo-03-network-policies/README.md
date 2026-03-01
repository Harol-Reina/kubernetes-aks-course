# Capítulo 31: Network Policies y Seguridad de Red

RBAC controla quién accede a la API. Las Network Policies controlan qué Pods pueden comunicarse entre sí a nivel de red. Son el firewall de Kubernetes: sin ellas, todo Pod puede hablar con todo Pod.

---

## Conceptos de Network Policies

Las **Network Policies** son un mecanismo para controlar el tráfico de red entre Pods usando reglas similares a firewalls.

### Tipos de Políticas

1. **Ingress**: Tráfico entrante al Pod
2. **Egress**: Tráfico saliente del Pod

### Requisitos

- **CNI Plugin** compatible (ej: Calico, Cilium)
- **Azure CNI** con Network Policies habilitadas

## Anatomía de una Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: example-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: allowed
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

## Ejemplos de Network Policies

### Denegar Todo el Tráfico

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: secure-namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Permitir Tráfico entre Tiers

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-to-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: web
    ports:
    - protocol: TCP
      port: 8080
```

### Permitir Tráfico desde Namespace Específico

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-monitoring
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090
```

## Configurar Azure CNI con Network Policies

```bash
# Crear AKS con Azure CNI y Network Policies
az aks create \
  --resource-group rg-kubernetes-course \
  --name aks-network-policies \
  --network-plugin azure \
  --network-policy azure \
  --node-count 2
```

## Laboratorio 3.2: Implementar Network Policies

### Paso 1: Preparar Ambiente

```bash
# Crear namespaces
kubectl create namespace frontend
kubectl create namespace backend
kubectl create namespace database

# Label namespaces
kubectl label namespace frontend tier=frontend
kubectl label namespace backend tier=backend
kubectl label namespace database tier=database
```

### Paso 2: Desplegar Aplicaciones

```bash
# Frontend
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
EOF

# Backend
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
        tier: backend
    spec:
      containers:
      - name: backend
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
EOF

# Database
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
        tier: database
    spec:
      containers:
      - name: database
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: myapp
        - name: POSTGRES_USER
          value: user
        - name: POSTGRES_PASSWORD
          value: password
        ports:
        - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: database-service
  namespace: database
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
EOF
```

### Paso 3: Probar Conectividad Inicial

```bash
# Probar conectividad frontend → backend
kubectl exec -n frontend deployment/frontend -- curl -s backend-service.backend.svc.cluster.local

# Probar conectividad backend → database
kubectl exec -n backend deployment/backend -- nc -zv database-service.database.svc.cluster.local 5432
```

### Paso 4: Implementar Network Policies

```bash
# Política: Solo frontend puede acceder a backend
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
EOF

# Política: Solo backend puede acceder a database
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
  namespace: database
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
EOF

# Política: Frontend solo puede salir a backend
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 80
  # Permitir DNS
  - to: []
    ports:
    - protocol: UDP
      port: 53
EOF
```

### Paso 5: Verificar Políticas

```bash
# Verificar que frontend → backend funciona
kubectl exec -n frontend deployment/frontend -- curl -s backend-service.backend.svc.cluster.local

# Verificar que frontend → database está bloqueado
kubectl exec -n frontend deployment/frontend -- nc -zv database-service.database.svc.cluster.local 5432

# Verificar que backend → database funciona
kubectl exec -n backend deployment/backend -- nc -zv database-service.database.svc.cluster.local 5432
```

---

## Resumen del Capítulo

Las Network Policies implementan segmentación de red dentro del cluster. Aprendimos a crear políticas de ingress y egress, aplicar el patrón "deny all + allow specific", y configurar una arquitectura 3-tier donde frontend solo habla con backend y backend solo habla con database. Requieren un CNI compatible (Calico, Cilium o Azure CNI).
