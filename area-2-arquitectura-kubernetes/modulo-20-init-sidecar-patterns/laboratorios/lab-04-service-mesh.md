# 🧪 Lab 4: Service Mesh Sidecar (Envoy)

> **Duración**: 45 minutos | **Nivel**: 🔴 Avanzado

---

## 🎯 Objetivos

1. ✅ Configurar Envoy proxy como sidecar
2. ✅ Implementar traffic routing
3. ✅ Exponer métricas Prometheus
4. ✅ Entender service mesh basics

---

## 📋 Prerequisites

```bash
kubectl delete pod --all --force 2>/dev/null || true

# Crear backend services
kubectl run backend-v1 --image=nginx:1.25-alpine --port=80 \
  --labels="app=backend,version=v1"
kubectl expose pod backend-v1 --port=80

kubectl run backend-v2 --image=httpd:2.4-alpine --port=80 \
  --labels="app=backend,version=v2"
kubectl expose pod backend-v2 --port=80
```

---

## 🔨 Parte 1: Envoy Básico (15 min)

### Paso 1.1: Configuración Envoy

`envoy-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: envoy-config
data:
  envoy.yaml: |
    static_resources:
      listeners:
      - name: listener_0
        address:
          socket_address:
            address: 0.0.0.0
            port_value: 10000
        filter_chains:
        - filters:
          - name: envoy.filters.network.http_connection_manager
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
              stat_prefix: ingress_http
              access_log:
              - name: envoy.access_loggers.stdout
                typed_config:
                  "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
              http_filters:
              - name: envoy.filters.http.router
                typed_config:
                  "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
              route_config:
                name: local_route
                virtual_hosts:
                - name: backend
                  domains: ["*"]
                  routes:
                  - match:
                      prefix: "/"
                    route:
                      weighted_clusters:
                        clusters:
                        - name: backend_v1
                          weight: 80
                        - name: backend_v2
                          weight: 20
      
      clusters:
      - name: backend_v1
        connect_timeout: 0.25s
        type: STRICT_DNS
        lb_policy: ROUND_ROBIN
        load_assignment:
          cluster_name: backend_v1
          endpoints:
          - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: backend-v1.default.svc.cluster.local
                    port_value: 80
      
      - name: backend_v2
        connect_timeout: 0.25s
        type: STRICT_DNS
        lb_policy: ROUND_ROBIN
        load_assignment:
          cluster_name: backend_v2
          endpoints:
          - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: backend-v2.default.svc.cluster.local
                    port_value: 80
    
    admin:
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 9901
```

```bash
kubectl apply -f envoy-config.yaml
```

---

### Paso 1.2: Pod con Envoy Sidecar

`app-envoy.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-envoy
  labels:
    app: frontend
spec:
  containers:
  
  # Main App (conecta a Envoy en localhost:10000)
  - name: app
    image: curlimages/curl:8.4.0
    command:
    - sh
    - -c
    - |
      echo "App iniciada"
      sleep 10
      
      echo "Testing traffic routing via Envoy..."
      for i in $(seq 1 10); do
        RESPONSE=$(curl -s localhost:10000)
        echo "$i: $RESPONSE" | head -c 50
      done
      
      tail -f /dev/null
    resources:
      requests:
        cpu: "100m"
        memory: "64Mi"
  
  # Envoy Sidecar
  - name: envoy
    image: envoyproxy/envoy:v1.28-latest
    ports:
    - containerPort: 10000
      name: http
    - containerPort: 9901
      name: admin
    volumeMounts:
    - name: envoy-config
      mountPath: /etc/envoy
    command:
    - /usr/local/bin/envoy
    - -c
    - /etc/envoy/envoy.yaml
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
  
  volumes:
  - name: envoy-config
    configMap:
      name: envoy-config
```

```bash
kubectl apply -f app-envoy.yaml

# Esperar a que inicie
kubectl wait --for=condition=Ready pod/app-with-envoy --timeout=60s

# Ver logs de app (80% v1, 20% v2)
kubectl logs app-with-envoy -c app
```

---

### Paso 1.3: Verificar Routing

```bash
# Hacer requests via Envoy
kubectl exec app-with-envoy -c app -- sh -c \
  'for i in $(seq 1 20); do curl -s localhost:10000 | head -c 30; echo ""; done'

# Deberías ver ~80% nginx, ~20% httpd

# Ver Envoy admin interface
kubectl port-forward app-with-envoy 9901:9901 &
curl localhost:9901/stats
curl localhost:9901/clusters
```

---

### ✅ Checkpoint 1: Envoy Basics

- [ ] Envoy escucha en puerto 10000
- [ ] App conecta a localhost:10000
- [ ] Traffic routing 80/20 funciona
- [ ] Admin interface en :9901

---

## 📊 Parte 2: Métricas Prometheus (12 min)

### Paso 2.1: Exponer Métricas

```bash
# Ver métricas de Envoy
kubectl port-forward app-with-envoy 9901:9901
curl localhost:9901/stats/prometheus
```

### Paso 2.2: Annotations para Scraping

Agrega annotations al Pod:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9901"
    prometheus.io/path: "/stats/prometheus"
```

### Paso 2.3: Métricas Clave

```bash
# Request count
curl -s localhost:9901/stats/prometheus | grep http_downstream_rq_total

# Response time
curl -s localhost:9901/stats/prometheus | grep http_downstream_rq_time

# Cluster health
curl -s localhost:9901/stats/prometheus | grep cluster_membership_healthy
```

---

## 🔄 Parte 3: Traffic Management (10 min)

### Paso 3.1: Cambiar Weights

Modifica ConfigMap para 50/50:

```yaml
weighted_clusters:
  clusters:
  - name: backend_v1
    weight: 50
  - name: backend_v2
    weight: 50
```

```bash
# Actualizar ConfigMap
kubectl apply -f envoy-config.yaml

# Restart Envoy para aplicar cambios
kubectl delete pod app-with-envoy --force
kubectl apply -f app-envoy.yaml

# Verificar nuevo routing
kubectl logs app-with-envoy -c app
```

---

### Paso 3.2: Circuit Breaker

Agrega circuit breaker config:

```yaml
clusters:
- name: backend_v1
  connect_timeout: 0.25s
  circuit_breakers:
    thresholds:
    - priority: DEFAULT
      max_connections: 100
      max_pending_requests: 50
      max_requests: 100
```

---

## 🐛 Parte 4: Troubleshooting (8 min)

### Problema 1: Envoy No Inicia

```bash
# Ver logs de Envoy
kubectl logs app-with-envoy -c envoy

# Verificar config syntax
kubectl exec app-with-envoy -c envoy -- \
  /usr/local/bin/envoy --mode validate -c /etc/envoy/envoy.yaml
```

### Problema 2: Backend Unreachable

```bash
# Ver clusters status
curl localhost:9901/clusters | grep health_flags

# Verificar DNS
kubectl exec app-with-envoy -c envoy -- \
  nslookup backend-v1.default.svc.cluster.local
```

---

## 🎯 Desafíos

### Desafío 1: Retry Policy

Agrega retry logic:

```yaml
routes:
- match:
    prefix: "/"
  route:
    cluster: backend_v1
    retry_policy:
      retry_on: "5xx"
      num_retries: 3
```

### Desafío 2: Timeout

Implementa timeouts:

```yaml
route:
  timeout: 3s
  idle_timeout: 30s
```

### Desafío 3: mTLS

Configura TLS entre Envoy y backend:

```yaml
tls_context:
  common_tls_context:
    validation_context:
      trusted_ca:
        filename: /certs/ca.crt
```

---

## 📝 Limpieza

```bash
kubectl delete pod app-with-envoy backend-v1 backend-v2 --force
kubectl delete service backend-v1 backend-v2
kubectl delete configmap envoy-config
```

---

## ✅ Auto-Evaluación

- [ ] Configuré Envoy como sidecar
- [ ] Implementé weighted routing (80/20)
- [ ] Expuse métricas Prometheus
- [ ] Accedí a admin interface
- [ ] Modifiqué routing dinámicamente
- [ ] Troubleshoot problemas de conectividad
- [ ] Entendí basics de service mesh

---

## 🎓 Service Mesh Concepts

```
ENVOY SIDECAR
├─ Proxy transparente
├─ Traffic management
├─ Observability (metrics, logs, traces)
└─ Security (mTLS, RBAC)

FEATURES
├─ Load balancing
├─ Circuit breaking
├─ Retries & timeouts
├─ Health checks
└─ Traffic routing

PRODUCTION MESH
├─ Istio: Envoy + control plane
├─ Linkerd: Rust proxy
└─ Consul Connect: Envoy + Consul
```

---

## 🚀 Next Steps

1. ✅ Revisar **RESUMEN-MODULO.md**
2. ✅ Practicar CKAD scenarios
3. ✅ Explorar Istio/Linkerd
4. ✅ Continuar a **Módulo 21: Helm**

---

**¡Módulo 20 completado!** 🎉🎉🎉

*Total labs*: 4  
*Total time*: ~2.5 hours  
*CKAD ready*: ✅