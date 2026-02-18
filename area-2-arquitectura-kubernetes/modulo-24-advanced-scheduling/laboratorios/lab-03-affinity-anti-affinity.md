# Laboratorio 03: Node y Pod Affinity/Anti-Affinity

## Información del Laboratorio

- **Duración estimada**: 45-60 minutos
- **Dificultad**: ⭐⭐⭐ (Intermedio-Avanzado)
- **Requisitos**: Cluster con mínimo 3 nodos worker
- **Cobertura CKA**: ~3% del examen

## Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

1. Implementar Node Affinity (required y preferred)
2. Configurar Pod Affinity para co-location
3. Implementar Pod Anti-Affinity para alta disponibilidad
4. Combinar múltiples reglas de affinity
5. Depurar problemas de scheduling con affinity

## Pre-requisitos

```bash
# Verificar nodos disponibles (mínimo 3)
kubectl get nodes

# Limpiar labels previos (si existen)
kubectl label nodes --all disktype- environment- zone- --overwrite 2>/dev/null || true
```

---

## Ejercicio 1: Node Affinity - Required vs Preferred (15 minutos)

### Objetivo
Entender la diferencia entre reglas required (obligatorias) y preferred (preferencias).

### Paso 1: Preparar nodos con labels

```bash
# Listar nodos disponibles
kubectl get nodes

# Etiquetar nodos (ajusta nombres según tu cluster)
kubectl label nodes worker-01 disktype=ssd environment=production zone=us-east-1a
kubectl label nodes worker-02 disktype=hdd environment=production zone=us-east-1b
kubectl label nodes worker-03 disktype=ssd environment=development zone=us-east-1a

# Verificar labels
kubectl get nodes --show-labels | grep -E 'disktype|environment|zone'
```

### Paso 2: Node Affinity Required (Hard Constraint)

Crear pod que SOLO puede correr en nodos con SSD:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-required-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
EOF
```

**Verificar:**

```bash
# Ver en qué nodo se programó
kubectl get pod pod-required-affinity -o wide

# Debe estar en worker-01 o worker-03 (los que tienen disktype=ssd)

# Ver eventos de scheduling
kubectl describe pod pod-required-affinity | grep -A 5 Events
```

### Paso 3: Node Affinity Preferred (Soft Constraint)

Crear pod que PREFIERE nodos de producción, pero puede ir a otros:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-preferred-affinity
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: environment
            operator: In
            values:
            - production
      - weight: 50
        preference:
          matchExpressions:
          - key: zone
            operator: In
            values:
            - us-east-1a
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
EOF
```

**Verificar:**

```bash
# Ver nodo asignado
kubectl get pod pod-preferred-affinity -o wide

# Preferirá worker-01 (production + us-east-1a = 150 puntos)
# Pero puede ir a cualquier nodo si no hay recursos en worker-01

# Ver scoring del scheduler
kubectl describe pod pod-preferred-affinity
```

### Paso 4: Combinar Required + Preferred

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-combined-affinity
spec:
  affinity:
    nodeAffinity:
      # DEBE tener disktype=ssd (obligatorio)
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
      # PREFIERE environment=production (opcional)
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: environment
            operator: In
            values:
            - production
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
EOF
```

**Verificar:**

```bash
kubectl get pod pod-combined-affinity -o wide

# DEBE estar en worker-01 o worker-03 (tienen disktype=ssd)
# Preferirá worker-01 (también tiene environment=production)
```

### Paso 5: Probar scheduling failure

```bash
# Crear pod con affinity imposible de satisfacer
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-impossible-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - nvme  # NO existe ningún nodo con este label
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
EOF
```

**Debugging:**

```bash
# Pod quedará en Pending
kubectl get pod pod-impossible-affinity

# Ver por qué está Pending
kubectl describe pod pod-impossible-affinity | grep -A 10 Events

# Debe mostrar: "0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector"

# Limpiar
kubectl delete pod pod-impossible-affinity
```

### ✅ Criterios de Éxito - Ejercicio 1

- [ ] Pod con required affinity se programa SOLO en nodos con label correcto
- [ ] Pod con preferred affinity se programa preferentemente pero no exclusivamente
- [ ] Pod con affinity imposible queda en estado Pending
- [ ] Puedes explicar la diferencia entre required y preferred

---

## Ejercicio 2: Pod Affinity - Co-location Patterns (20 minutos)

### Objetivo
Implementar patrones de co-location donde pods deben estar cerca de otros pods.

### Paso 1: Crear deployment de cache (Redis)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cache
      tier: data
  template:
    metadata:
      labels:
        app: cache
        tier: data
        component: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
EOF
```

**Verificar:**

```bash
kubectl get pods -l app=cache -o wide

# Anotar en qué nodos están los pods de Redis
```

### Paso 2: Deployment de API con Pod Affinity

Crear API que DEBE estar en el mismo nodo que Redis (co-location):

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
      tier: backend
  template:
    metadata:
      labels:
        app: api
        tier: backend
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - cache
            topologyKey: kubernetes.io/hostname  # Mismo nodo
      containers:
      - name: api
        image: nginx:1.25-alpine
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        env:
        - name: CACHE_TYPE
          value: "redis-colocated"
EOF
```

**Verificar co-location:**

```bash
# Ver distribución de pods
kubectl get pods -l 'app in (cache,api)' -o wide --sort-by=.spec.nodeName

# Los pods de api DEBEN estar en los mismos nodos que los pods de cache

# Verificar con script
echo "=== Pod Distribution ==="
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  echo "Node: $node"
  echo "  Cache pods: $(kubectl get pods -l app=cache -o wide | grep $node | wc -l)"
  echo "  API pods: $(kubectl get pods -l app=api -o wide | grep $node | wc -l)"
done
```

### Paso 3: Pod Affinity con topologyKey de zona

Crear deployment que debe estar en la misma ZONA que Redis (no necesariamente mismo nodo):

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker-same-zone
spec:
  replicas: 2
  selector:
    matchLabels:
      app: worker
      tier: processing
  template:
    metadata:
      labels:
        app: worker
        tier: processing
    spec:
      affinity:
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: component
                  operator: In
                  values:
                  - redis
              topologyKey: zone  # Misma zona (más flexible)
      containers:
      - name: worker
        image: busybox
        command: ["sh", "-c", "echo Worker started; sleep 3600"]
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
EOF
```

**Verificar:**

```bash
kubectl get pods -l app=worker -o wide
```

### Paso 4: Probar escalado y comportamiento

```bash
# Escalar Redis
kubectl scale deployment redis-cache --replicas=3

# Esperar a que se creen los pods
kubectl wait --for=condition=Ready pod -l app=cache --timeout=60s

# Los pods de API se redistribuirán para mantener co-location
kubectl get pods -l 'app in (cache,api)' -o wide --sort-by=.spec.nodeName

# Escalar API
kubectl scale deployment api-server --replicas=4

# Ver cómo se distribuyen
kubectl get pods -l app=api -o wide
```

### ✅ Criterios de Éxito - Ejercicio 2

- [ ] Pods de API están en los mismos nodos que pods de Redis
- [ ] topologyKey: kubernetes.io/hostname fuerza mismo nodo
- [ ] topologyKey: zone permite flexibilidad de nodos en misma zona
- [ ] Escalado mantiene las reglas de affinity

---

## Ejercicio 3: Pod Anti-Affinity - Alta Disponibilidad (20 minutos)

### Objetivo
Implementar Pod Anti-Affinity para distribuir pods y garantizar alta disponibilidad.

### Paso 1: Deployment con Anti-Affinity Hard

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-ha-hard
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      ha: hard
  template:
    metadata:
      labels:
        app: web
        ha: hard
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web
              - key: ha
                operator: In
                values:
                - hard
            topologyKey: kubernetes.io/hostname
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
EOF
```

**Verificar distribución:**

```bash
# Ver distribución (cada pod en nodo diferente)
kubectl get pods -l app=web,ha=hard -o wide

# Contar pods por nodo
echo "=== Pods por Nodo ==="
kubectl get pods -l app=web,ha=hard -o wide | awk 'NR>1 {print $7}' | sort | uniq -c

# Debe mostrar máximo 1 pod por nodo
```

### Paso 2: Probar límite de anti-affinity

```bash
# Intentar escalar a más replicas que nodos
NODOS=$(kubectl get nodes --no-headers | wc -l)
echo "Nodos disponibles: $NODOS"

# Escalar a más replicas que nodos
kubectl scale deployment web-ha-hard --replicas=5

# Ver estado de los pods
kubectl get pods -l app=web,ha=hard

# Algunos pods quedarán en Pending porque no hay suficientes nodos
# para satisfacer la regla de anti-affinity

# Ver por qué están Pending
kubectl describe pod -l app=web,ha=hard | grep -A 5 "Events:"

# Ver específicamente pods Pending
kubectl get pods -l app=web,ha=hard --field-selector=status.phase=Pending -o name | \
  xargs -I {} kubectl describe {} | grep -A 3 "Warning.*FailedScheduling"
```

### Paso 3: Anti-Affinity Soft (Preferencia)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-ha-soft
spec:
  replicas: 6
  selector:
    matchLabels:
      app: web
      ha: soft
  template:
    metadata:
      labels:
        app: web
        ha: soft
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
                  - web
                - key: ha
                  operator: In
                  values:
                  - soft
              topologyKey: kubernetes.io/hostname
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
EOF
```

**Verificar:**

```bash
# Ver distribución
kubectl get pods -l app=web,ha=soft -o wide

# Contar pods por nodo
kubectl get pods -l app=web,ha=soft -o wide | awk 'NR>1 {print $7}' | sort | uniq -c

# Con preferredDuring..., el scheduler INTENTA distribuir
# pero permite múltiples pods por nodo si es necesario

# Comparar con hard anti-affinity
echo "=== Hard Anti-Affinity ==="
kubectl get pods -l ha=hard -o wide

echo "=== Soft Anti-Affinity ==="
kubectl get pods -l ha=soft -o wide
```

### Paso 4: Anti-Affinity por Zona (Multi-AZ)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-multi-az
spec:
  replicas: 3
  selector:
    matchLabels:
      app: database
      tier: data
  template:
    metadata:
      labels:
        app: database
        tier: data
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - database
            topologyKey: zone  # Diferentes zonas
        
        # Opcional: también distribuir en nodos dentro de la zona
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - database
              topologyKey: kubernetes.io/hostname
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "demo123"
        resources:
          requests:
            cpu: "200m"
            memory: "512Mi"
          limits:
            cpu: "500m"
            memory: "1Gi"
EOF
```

**Verificar distribución multi-AZ:**

```bash
# Ver pods con zona
kubectl get pods -l app=database -o custom-columns=\
NAME:.metadata.name,\
NODE:.spec.nodeName,\
ZONE:.spec.nodeSelector.zone

# Deben estar en diferentes zonas (us-east-1a, us-east-1b, etc.)
```

### Paso 5: Combinación Affinity + Anti-Affinity

Escenario real: API que debe estar cerca de cache pero distribuida para HA:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-ha-colocated
spec:
  replicas: 4
  selector:
    matchLabels:
      app: api
      version: v2
  template:
    metadata:
      labels:
        app: api
        version: v2
    spec:
      affinity:
        # Pod Affinity: Estar en misma zona que Redis
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 80
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: component
                  operator: In
                  values:
                  - redis
              topologyKey: zone
        
        # Pod Anti-Affinity: Distribuir entre nodos para HA
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - api
                - key: version
                  operator: In
                  values:
                  - v2
              topologyKey: kubernetes.io/hostname
      containers:
      - name: api
        image: nginx:1.25-alpine
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
EOF
```

**Analizar balanceo:**

```bash
# Ver distribución completa
kubectl get pods -l 'app in (cache,api)' -o wide --sort-by=.spec.nodeName

# Verificar:
# 1. Pods de API v2 en misma zona que Redis (affinity)
# 2. Pods de API v2 distribuidos entre nodos (anti-affinity)
```

### ✅ Criterios de Éxito - Ejercicio 3

- [ ] Hard anti-affinity garantiza 1 pod por nodo máximo
- [ ] Soft anti-affinity intenta distribuir pero permite excepciones
- [ ] Pods en Pending si no hay suficientes nodos para hard anti-affinity
- [ ] Combinación affinity + anti-affinity funciona correctamente

---

## Limpieza del Laboratorio

```bash
# Eliminar todos los recursos creados
kubectl delete deployment redis-cache api-server worker-same-zone \
  web-ha-hard web-ha-soft db-multi-az api-ha-colocated

kubectl delete pod pod-required-affinity pod-preferred-affinity \
  pod-combined-affinity 2>/dev/null || true

# Limpiar labels de nodos
kubectl label nodes --all disktype- environment- zone- --overwrite

# Verificar limpieza
kubectl get pods
kubectl get nodes --show-labels | grep -E 'disktype|environment|zone'
```

---

## Resumen de Comandos Útiles

```bash
# Ver affinity/anti-affinity de un pod
kubectl get pod <pod-name> -o jsonpath='{.spec.affinity}' | jq

# Ver distribución de pods por nodo
kubectl get pods -o wide --sort-by=.spec.nodeName

# Contar pods por nodo
kubectl get pods -o wide | awk 'NR>1 {print $7}' | sort | uniq -c

# Ver pods Pending con razón
kubectl get pods --field-selector=status.phase=Pending -o wide

# Describe para ver eventos de scheduling
kubectl describe pod <pod-name> | grep -A 10 Events

# Ver labels de nodos
kubectl get nodes --show-labels

# Ver topology keys disponibles
kubectl get nodes -o json | jq '.items[].metadata.labels | keys[]' | sort -u
```

---

## Troubleshooting Tips

### Pod stuck en Pending

```bash
# Ver razón específica
kubectl describe pod <pod-name>

# Causas comunes:
# - "didn't match Pod's node affinity" → Ningún nodo cumple required affinity
# - "didn't match pod affinity rules" → No hay pods target para pod affinity
# - "didn't match pod anti-affinity rules" → Todos los nodos tienen pods que violan anti-affinity
```

### Verificar si affinity es el problema

```bash
# Temporal: Eliminar affinity para probar
kubectl get pod <pod-name> -o yaml | \
  grep -v -A 100 "affinity:" | \
  kubectl apply -f -

# Si ahora se programa, el problema es la configuración de affinity
```

### Ver scoring del scheduler

```bash
# Habilitar logs verbosos del scheduler (solo en clusters de prueba)
kubectl logs -n kube-system kube-scheduler-<master-node> | grep -i score
```

---

## Conceptos Clave Aprendidos

1. **Node Affinity**
   - `requiredDuring...`: Hard constraint (DEBE cumplirse)
   - `preferredDuring...`: Soft constraint (scoring)
   - Operators: In, NotIn, Exists, DoesNotExist, Gt, Lt

2. **Pod Affinity**
   - Co-location de pods relacionados
   - topologyKey: determina el nivel de co-location
   - Útil para latencia, shared volumes, performance

3. **Pod Anti-Affinity**
   - Distribución para alta disponibilidad
   - Evita single points of failure
   - Balance entre disponibilidad y eficiencia de recursos

4. **Topology Keys Comunes**
   - `kubernetes.io/hostname`: Nivel de nodo
   - `topology.kubernetes.io/zone`: Nivel de zona/AZ
   - `topology.kubernetes.io/region`: Nivel de región
   - Custom labels para topologías personalizadas

---

**¡Laboratorio completado!** ✅

Has aprendido a controlar la ubicación de pods usando affinity y anti-affinity, técnicas esenciales para aplicaciones de producción con requisitos de alta disponibilidad, performance y tolerancia a fallos.
