# Laboratorio 02: NodePort y LoadBalancer - Acceso Externo

**Duración estimada:** 50 minutos  
**Nivel:** Intermedio  
**Objetivo:** Dominar acceso externo con NodePort y LoadBalancer, comparar tipos de Services

---

## 📋 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

- ✅ Crear Services tipo NodePort para acceso externo
- ✅ Entender el rango de puertos NodePort (30000-32767)
- ✅ Configurar LoadBalancer Services en cloud
- ✅ Comparar externalTrafficPolicy: Cluster vs Local
- ✅ Troubleshoot problemas de acceso externo
- ✅ Decidir cuándo usar cada tipo de Service

---

## 🔧 Requisitos Previos

- Laboratorio 01 completado
- Cluster de Kubernetes con acceso a nodos
- (Opcional) Cluster en cloud (AWS EKS, GCP GKE, Azure AKS) para LoadBalancer
- kubectl configurado

### Verificación del entorno

```bash
# Verificar acceso a nodos
kubectl get nodes -o wide

# Anotar EXTERNAL-IP de los nodos (usaremos esto más tarde)
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'
echo

# Si no hay EXTERNAL-IP, usar INTERNAL-IP
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'
echo
```

---

## 📚 Parte 1: Service NodePort Básico

### Paso 1: Crear Deployment de Testing

```bash
# Deployment con identificación de Pods
cat > webapp-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
      tier: frontend
  template:
    metadata:
      labels:
        app: webapp
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - name: http
          containerPort: 80
        
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        
        command:
        - /bin/sh
        - -c
        - |
          cat > /usr/share/nginx/html/index.html <<'HTML'
          <!DOCTYPE html>
          <html>
          <head><title>WebApp Demo</title></head>
          <body>
          <h1>NodePort Demo</h1>
          <table border="1">
            <tr><td><strong>Pod:</strong></td><td>POD_NAME_VAL</td></tr>
            <tr><td><strong>Pod IP:</strong></td><td>POD_IP_VAL</td></tr>
            <tr><td><strong>Node:</strong></td><td>NODE_NAME_VAL</td></tr>
          </table>
          </body>
          </html>
          HTML
          sed -i "s/POD_NAME_VAL/$POD_NAME/g" /usr/share/nginx/html/index.html
          sed -i "s/POD_IP_VAL/$POD_IP/g" /usr/share/nginx/html/index.html
          sed -i "s/NODE_NAME_VAL/$NODE_NAME/g" /usr/share/nginx/html/index.html
          exec nginx -g 'daemon off;'
        
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF

kubectl apply -f webapp-deployment.yaml

# Verificar Pods en diferentes nodos
kubectl get pods -l app=webapp -o wide
```

---

### Paso 2: Crear NodePort Service (Auto-assigned Port)

```bash
# Service con puerto auto-asignado
cat > webapp-nodeport-auto.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: webapp-nodeport-auto
  labels:
    app: webapp
spec:
  type: NodePort
  selector:
    app: webapp
    tier: frontend
  ports:
  - name: http
    port: 80
    targetPort: http
    # nodePort: omitido → Kubernetes asigna automáticamente
EOF

kubectl apply -f webapp-nodeport-auto.yaml

# Ver Service
kubectl get service webapp-nodeport-auto

# Obtener NodePort asignado
NODEPORT=$(kubectl get service webapp-nodeport-auto -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort asignado: $NODEPORT"
```

**Salida esperada:**
```
NAME                    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
webapp-nodeport-auto    NodePort   10.96.123.45    <none>        80:31234/TCP   10s

NodePort asignado: 31234
```

**🎯 Observa:**
- `PORT(S)`: `80:31234/TCP` → puerto 80 del Service mapeado a puerto 31234 del nodo
- `EXTERNAL-IP`: `<none>` → NodePort no crea IP externa (usa IP del nodo)

---

### Paso 3: Acceder vía NodePort

```bash
# Obtener IP de un nodo
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Node IP: $NODE_IP"
echo "Accede en: http://$NODE_IP:$NODEPORT"

# Test desde dentro del cluster (si tienes acceso SSH al nodo)
# ssh $NODE_IP
# curl http://localhost:$NODEPORT

# Alternativamente, desde un Pod
kubectl run test-nodeport --rm -it --image=curlimages/curl --restart=Never -- \
  curl http://$NODE_IP:$NODEPORT

# Múltiples requests para ver balanceo
for i in {1..5}; do
  echo "Request $i:"
  kubectl run test-np-$i --rm --image=curlimages/curl --restart=Never -- \
    curl -s http://$NODE_IP:$NODEPORT | grep -E "Pod:|Node:" &
done
wait
```

**🎯 Observa:**
- Puedes acceder usando IP de CUALQUIER nodo (incluso si el Pod no está en ese nodo)
- Balanceo funciona igual que ClusterIP

---

### Paso 4: NodePort con Puerto Personalizado

```bash
# Service con puerto específico
cat > webapp-nodeport-custom.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: webapp-nodeport-custom
spec:
  type: NodePort
  selector:
    app: webapp
    tier: frontend
  ports:
  - name: http
    port: 80
    targetPort: http
    nodePort: 30080  # Puerto fijo (debe estar en range 30000-32767)
EOF

kubectl apply -f webapp-nodeport-custom.yaml

# Verificar
kubectl get service webapp-nodeport-custom
```

**Salida:**
```
NAME                      TYPE       CLUSTER-IP      PORT(S)        AGE
webapp-nodeport-custom    NodePort   10.96.234.56    80:30080/TCP   5s
```

**🎯 Ventaja:** Puerto conocido y predecible (`30080`)  
**⚠️ Desventaja:** Puede conflictuar si ya está en uso

---

## 📚 Parte 2: ExternalTrafficPolicy

### Paso 5: Cluster Policy (Default)

```bash
# Service con externalTrafficPolicy: Cluster
cat > webapp-cluster-policy.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: webapp-cluster-policy
  labels:
    policy: cluster
spec:
  type: NodePort
  selector:
    app: webapp
    tier: frontend
  ports:
  - name: http
    port: 80
    targetPort: http
    nodePort: 30081
  externalTrafficPolicy: Cluster  # Default
EOF

kubectl apply -f webapp-cluster-policy.yaml
```

**Test:**
```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Ver si preserva IP origen
kubectl run test-cluster --rm -it --image=curlimages/curl --restart=Never -- \
  curl -s http://$NODE_IP:30081 | grep -E "Pod:|Node:"
```

**🎯 Cluster Policy:**
- ✅ Balancea a TODOS los Pods (incluso en otros nodos)
- ❌ Pierde IP origen del cliente (SNAT)
- ✅ Funciona siempre (incluso si nodo no tiene Pods)

---

### Paso 6: Local Policy

```bash
# Service con externalTrafficPolicy: Local
cat > webapp-local-policy.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: webapp-local-policy
  labels:
    policy: local
spec:
  type: NodePort
  selector:
    app: webapp
    tier: frontend
  ports:
  - name: http
    port: 80
    targetPort: http
    nodePort: 30082
  externalTrafficPolicy: Local  # Solo Pods locales
EOF

kubectl apply -f webapp-local-policy.yaml

# Verificar health check port (solo con Local)
kubectl get service webapp-local-policy -o yaml | grep healthCheckNodePort
```

**Test desde DIFERENTES nodos:**
```bash
# Listar nodos con Pods
echo "Pods distribution:"
kubectl get pods -l app=webapp -o wide

# Guardar IPs de nodos
NODES=($(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'))

# Test en cada nodo
for NODE in "${NODES[@]}"; do
  echo "Testing node: $NODE"
  kubectl run test-node-$RANDOM --rm --image=curlimages/curl --restart=Never -- \
    curl -s -m 2 http://$NODE:30082 2>&1 | head -n 3 &
done
wait
```

**🎯 Local Policy:**
- ✅ Preserva IP origen del cliente
- ✅ Sin hop extra (siempre local)
- ❌ Solo balancea a Pods en el MISMO nodo
- ⚠️ Si nodo no tiene Pods, conexión falla

---

### Paso 7: Comparar Ambas Policies

```bash
# Script de comparación
cat > compare-policies.sh <<'EOF'
# !/bin/bash
echo "=== externalTrafficPolicy Comparison ==="
echo ""

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "1. Cluster Policy (port 30081):"
for i in {1..5}; do
  kubectl run test-c-$RANDOM --rm --image=curlimages/curl --restart=Never -- \
    curl -s http://$NODE_IP:30081 | grep "Node:" &
done
wait

echo ""
echo "2. Local Policy (port 30082):"
for i in {1..5}; do
  kubectl run test-l-$RANDOM --rm --image=curlimages/curl --restart=Never -- \
    curl -s http://$NODE_IP:30082 2>&1 | grep -E "Node:|timeout" &
done
wait

echo ""
echo "Cluster Policy: Puede ir a Pods en cualquier nodo"
echo "Local Policy: Solo Pods en el nodo $NODE_IP"
EOF

chmod +x compare-policies.sh
./compare-policies.sh
```

---

## 📚 Parte 3: LoadBalancer Service (Cloud)

**⚠️ Esta sección requiere cluster en cloud (AWS, GCP, Azure).  
Si usas minikube/kind, salta a Parte 4.**

### Paso 8: Crear LoadBalancer Service

```bash
# Service tipo LoadBalancer
cat > webapp-loadbalancer.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: webapp-lb
  labels:
    app: webapp
spec:
  type: LoadBalancer
  selector:
    app: webapp
    tier: frontend
  ports:
  - name: http
    port: 80
    targetPort: http
  
  # Opcional: Preservar IP origen
  externalTrafficPolicy: Local
  
  # Opcional: Restringir IPs permitidas
  # loadBalancerSourceRanges:
  #   - "0.0.0.0/0"  # Todo el mundo (cambiar en prod)
EOF

kubectl apply -f webapp-loadbalancer.yaml

# Ver Service (EXTERNAL-IP en <pending> inicialmente)
kubectl get service webapp-lb -w
```

**Salida esperada:**
```
NAME        TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
webapp-lb   LoadBalancer   10.96.45.67    <pending>       80:31456/TCP   10s
webapp-lb   LoadBalancer   10.96.45.67    203.0.113.50    80:31456/TCP   90s
                                          ↑ IP pública asignada
```

**🎯 Observa:**
- Toma ~1-3 minutos en asignar IP pública
- Cloud provider crea balanceador automáticamente
- También crea NodePort (31456) automáticamente

---

### Paso 9: Acceder vía LoadBalancer

```bash
# Obtener IP pública
LB_IP=$(kubectl get service webapp-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "LoadBalancer IP: $LB_IP"

# Test desde tu laptop
curl http://$LB_IP

# Múltiples requests
for i in {1..10}; do
  curl -s http://$LB_IP | grep "Pod:"
done
```

**🎯 Acceso público:** Cualquiera en Internet puede acceder (si firewall lo permite).

---

### Paso 10: Ver LoadBalancer en Cloud Console

**AWS:**
```bash
# Listar Load Balancers creados por Kubernetes
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(LoadBalancerName, 'webapp')]"

# Ver target groups
aws elbv2 describe-target-groups \
  --load-balancer-arn <arn-from-above>
```

**GCP:**
```bash
# Listar Load Balancers
gcloud compute forwarding-rules list

# Ver detalles
gcloud compute forwarding-rules describe <nombre>
```

**Azure:**
```bash
# Listar Load Balancers
az network lb list --output table

# Ver backend pools
az network lb address-pool list --lb-name <nombre> --resource-group <rg>
```

---

## 📚 Parte 4: Comparación de Tipos de Service

### Paso 11: Comparar los 3 Tipos Simultáneamente

```bash
# Crear tabla comparativa
cat > comparison-table.sh <<'EOF'
# !/bin/bash
echo "=========================================="
echo "Service Types Comparison"
echo "=========================================="
printf "%-25s %-15s %-20s %-15s\n" "Service Name" "Type" "ClusterIP" "External Access"
echo "------------------------------------------"

SERVICES="backend-service webapp-nodeport-auto webapp-nodeport-custom webapp-lb"

for SVC in $SERVICES; do
  if kubectl get service $SVC &>/dev/null; then
    TYPE=$(kubectl get service $SVC -o jsonpath='{.spec.type}')
    CLUSTER_IP=$(kubectl get service $SVC -o jsonpath='{.spec.clusterIP}')
    
    case $TYPE in
      ClusterIP)
        ACCESS="Internal only"
        ;;
      NodePort)
        NODEPORT=$(kubectl get service $SVC -o jsonpath='{.spec.ports[0].nodePort}')
        ACCESS="<node-ip>:$NODEPORT"
        ;;
      LoadBalancer)
        LB_IP=$(kubectl get service $SVC -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        ACCESS="${LB_IP:-<pending>}:80"
        ;;
    esac
    
    printf "%-25s %-15s %-20s %-15s\n" "$SVC" "$TYPE" "$CLUSTER_IP" "$ACCESS"
  fi
done
EOF

chmod +x comparison-table.sh
./comparison-table.sh
```

**Salida esperada:**
```
==========================================
Service Types Comparison
==========================================
Service Name              Type            ClusterIP            External Access
------------------------------------------
backend-service           ClusterIP       10.96.15.123         Internal only
webapp-nodeport-auto      NodePort        10.96.123.45         <node-ip>:31234
webapp-nodeport-custom    NodePort        10.96.234.56         <node-ip>:30080
webapp-lb                 LoadBalancer    10.96.45.67          203.0.113.50:80
```

---

## 📚 Parte 5: Troubleshooting

### Paso 12: Problema - NodePort No Accesible

Simular problema de firewall.

```bash
# Verificar NodePort asignado
kubectl get service webapp-nodeport-auto

# Verificar Pods running
kubectl get pods -l app=webapp

# Verificar Endpoints
kubectl get endpoints webapp-nodeport-auto

# Test conectividad desde dentro del cluster
kubectl run test-internal --rm -it --image=curlimages/curl --restart=Never -- \
  curl http://webapp-nodeport-auto

# Si falla desde fuera:
# 1. Verificar firewall del nodo permite puerto NodePort
# 2. En cloud: Security Groups / Firewall Rules
# 3. On-premise: iptables rules
```

**Checklist de diagnóstico:**
- [ ] Service existe y tiene tipo NodePort
- [ ] Endpoints no vacíos (hay Pods ready)
- [ ] Firewall permite puerto NodePort (30000-32767)
- [ ] kube-proxy running en nodos

---

### Paso 13: Problema - LoadBalancer en <pending>

```bash
# Ver si está stuck en pending
kubectl get service webapp-lb

# Ver eventos
kubectl describe service webapp-lb | grep -A 10 Events

# Posibles causas:
# 1. Cloud provider no configurado
kubectl get nodes -o yaml | grep providerID

# 2. Quotas excedidas
# AWS: Verificar ELB quota
# GCP: Verificar forwarding rules quota

# 3. Permisos IAM insuficientes
# Cluster necesita permisos para crear LB

# 4. No es cluster de cloud (minikube, kind)
# → Usar NodePort o MetalLB
```

---

## 🎓 Desafíos Adicionales

### Desafío 1: Multi-Port NodePort

Crea un NodePort Service con puertos HTTP (80) y HTTPS (443).

<details>
<summary>✅ Solución</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-multi-port
spec:
  type: NodePort
  selector:
    app: webapp
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30080
  - name: https
    port: 443
    targetPort: 443
    nodePort: 30443
```
</details>

---

### Desafío 2: LoadBalancer Interno (Cloud)

Crea un LoadBalancer que solo sea accesible dentro de la VPC (no público).

<details>
<summary>💡 Pista</summary>

Usa annotations específicas del cloud provider.
</details>

<details>
<summary>✅ Solución AWS</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-internal-lb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 80
```
</details>

---

## 🧹 Limpieza

```bash
# Eliminar Services
kubectl delete service webapp-nodeport-auto
kubectl delete service webapp-nodeport-custom
kubectl delete service webapp-cluster-policy
kubectl delete service webapp-local-policy
kubectl delete service webapp-lb

# Eliminar Deployment
kubectl delete deployment webapp

# Eliminar archivos
rm -f webapp-deployment.yaml webapp-*.yaml compare-policies.sh comparison-table.sh
```

---

## 📝 Resumen y Conceptos Clave

### NodePort

✅ **Características:**
- Expone puerto en TODOS los nodos (range 30000-32767)
- Accesible vía `<node-ip>:<nodePort>`
- Crea ClusterIP también (acceso interno)

✅ **Cuándo usar:**
- Desarrollo/testing
- Bare-metal clusters sin LoadBalancer
- Detrás de LB externo (HAProxy, nginx)

❌ **NO usar para:**
- Producción pública directa
- Múltiples servicios (range limitado)

---

### LoadBalancer

✅ **Características:**
- Crea balanceador externo automáticamente
- IP pública asignada
- Integración con cloud provider

✅ **Cuándo usar:**
- Producción en cloud (AWS, GCP, Azure)
- Necesitas IP pública estable

❌ **NO usar para:**
- Múltiples servicios HTTP (costoso, usar Ingress)
- Desarrollo local (sin cloud provider)

---

### externalTrafficPolicy

**Cluster (default):**
- Balancea a TODOS los Pods
- Pierde IP origen (SNAT)
- Hop extra posible

**Local:**
- Solo Pods locales (mismo nodo)
- Preserva IP origen
- Balanceo desigual

---

## 🔗 Siguientes Pasos

1. **[Laboratorio 03: Services Avanzados](lab-03-advanced-services.md)**
   - ExternalName
   - Headless Services
   - Endpoints manuales
   - Best practices de producción

2. **[Ejemplos Avanzados](../ejemplos/README.md)**
   - LoadBalancer con annotations
   - ExternalTrafficPolicy en detalle
   - Producción ready

---

## ✅ Checklist de Verificación

- [ ] Puedes crear NodePort Services
- [ ] Entiendes el range de puertos (30000-32767)
- [ ] Sabes la diferencia entre Cluster y Local policy
- [ ] (Opcional) Creaste LoadBalancer en cloud
- [ ] Puedes diagnosticar problemas de acceso externo
- [ ] Sabes cuándo usar cada tipo de Service

---

**¡Excelente trabajo!** 🎉 Dominas acceso externo en Kubernetes.
