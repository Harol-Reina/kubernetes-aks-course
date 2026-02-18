# Laboratorio 04: Network Troubleshooting Avanzado

## 📋 Metadata

- **Módulo**: 25 - Networking
- **Laboratorio**: 04
- **Título**: Troubleshooting de Red Avanzado
- **Duración estimada**: 75-90 minutos
- **Dificultad**: ⭐⭐⭐⭐ (Experto - Nivel CKA)
- **Objetivos CKA**: Troubleshooting (15-20%)

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio serás capaz de:

1. Diagnosticar problemas de conectividad pod-to-pod
2. Troubleshoot problemas de Services y Endpoints
3. Resolver problemas de DNS resolution
4. Debuggear Network Policies que bloquean tráfico
5. Diagnosticar problemas de Ingress
6. Usar herramientas avanzadas de networking (tcpdump, netshoot)
7. Aplicar metodología sistemática de troubleshooting

## 📚 Prerequisitos

- Cluster de Kubernetes funcional
- kubectl configurado
- Laboratorios 01, 02 y 03 completados
- Conocimientos sólidos de networking
- Familiaridad con herramientas de red (ping, curl, nc, nslookup)

## 🔧 Preparación del Entorno

### Crear namespace

```bash
kubectl create namespace lab-troubleshoot
kubectl config set-context --current --namespace=lab-troubleshoot
```

### Instalar herramientas de debugging

```bash
# Netshoot - pod con todas las herramientas de red
kubectl run netshoot --image=nicolaka/netshoot --rm -it --restart=Never -- /bin/bash
# (exit para salir)

# DNSUtils
kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml
```

---

## 📝 Escenario 1: Pod Cannot Connect to Another Pod

### 1.1 Setup del Escenario

```bash
# Crear dos pods
kubectl run source-pod --image=nginx:alpine -n lab-troubleshoot
kubectl run target-pod --image=nginx:alpine -n lab-troubleshoot

# Esperar que estén running
kubectl wait --for=condition=Ready pod/source-pod -n lab-troubleshoot --timeout=60s
kubectl wait --for=condition=Ready pod/target-pod -n lab-troubleshoot --timeout=60s
```

### 1.2 Simular Problema: Network Policy Bloqueando

```bash
# Aplicar default deny
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: lab-troubleshoot
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```

### 1.3 Diagnosticar Paso a Paso

**Paso 1: Verificar conectividad básica**

```bash
# Obtener IP del target pod
TARGET_IP=$(kubectl get pod target-pod -o jsonpath='{.status.podIP}')
echo "Target Pod IP: $TARGET_IP"

# Intentar ping (fallará)
kubectl exec source-pod -- ping -c 3 $TARGET_IP
# Timeout - no response
```

**Paso 2: Verificar que los pods están running**

```bash
kubectl get pods -o wide -n lab-troubleshoot
# Ambos deben estar Running y Ready 1/1
```

**Paso 3: Verificar Network Policies**

```bash
# Listar network policies
kubectl get networkpolicies -n lab-troubleshoot

# Describir la policy
kubectl describe networkpolicy deny-all -n lab-troubleshoot
```

**❓ Pregunta:** ¿Qué indica la policy? ¿Permite o bloquea tráfico?

**Paso 4: Verificar logs del CNI**

```bash
# Ver logs de calico/cilium/weave
kubectl logs -n kube-system -l k8s-app=calico-node --tail=50 | grep -i denied
```

**Paso 5: Solucionar - Permitir Comunicación**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-internal
  namespace: lab-troubleshoot
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}
  egress:
  - to:
    - podSelector: {}
  - ports:
    - protocol: UDP
      port: 53
EOF
```

**Paso 6: Verificar que funciona**

```bash
kubectl exec source-pod -- ping -c 3 $TARGET_IP
# Ahora debería funcionar ✅
```

---

## 📝 Escenario 2: Service Not Working (No Endpoints)

### 2.1 Setup del Escenario

```bash
# Crear deployment con labels INCORRECTOS
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-deployment
  namespace: lab-troubleshoot
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: wrong-label  # ❌ No coincide con el selector del deployment
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# Crear service que busca labels correctos
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: broken-service
  namespace: lab-troubleshoot
spec:
  selector:
    app: myapp  # Busca "app: myapp"
  ports:
  - port: 80
    targetPort: 80
EOF
```

### 2.2 Diagnosticar

**Paso 1: Test de conectividad (fallará)**

```bash
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -n lab-troubleshoot -- curl -m 5 http://broken-service
# Error: Could not resolve host
```

**Paso 2: Verificar Service**

```bash
kubectl get svc broken-service -n lab-troubleshoot
kubectl describe svc broken-service -n lab-troubleshoot
```

**Paso 3: Verificar Endpoints (clave del problema)**

```bash
kubectl get endpoints broken-service -n lab-troubleshoot
# ENDPOINTS: <none>  ❌ Problema aquí!
```

**❓ Pregunta:** ¿Por qué no hay endpoints?

**Paso 4: Comparar Labels**

```bash
# Labels del service selector
kubectl get svc broken-service -o jsonpath='{.spec.selector}' -n lab-troubleshoot
# {"app":"myapp"}

# Labels de los pods
kubectl get pods -n lab-troubleshoot --show-labels | grep broken-deployment
# app=wrong-label  ❌ No coincide!
```

**Paso 5: Solucionar**

```bash
# Opción 1: Corregir deployment
kubectl patch deployment broken-deployment -n lab-troubleshoot -p '{"spec":{"template":{"metadata":{"labels":{"app":"myapp"}}}}}'

# Esperar rollout
kubectl rollout status deployment broken-deployment -n lab-troubleshoot

# Opción 2: Corregir service
# kubectl patch svc broken-service -n lab-troubleshoot -p '{"spec":{"selector":{"app":"wrong-label"}}}'
```

**Paso 6: Verificar**

```bash
# Ver endpoints ahora
kubectl get endpoints broken-service -n lab-troubleshoot
# Ahora debe tener IPs ✅

# Test
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -n lab-troubleshoot -- curl -m 5 http://broken-service
# ✅ Funciona
```

---

## 📝 Escenario 3: DNS Resolution Failing

### 3.1 Setup del Escenario

```bash
# Crear deployment y service funcionando
kubectl create deployment web --image=nginx:alpine -n lab-troubleshoot
kubectl expose deployment web --port=80 -n lab-troubleshoot

# Simular problema: Escalar CoreDNS a 0 (NO hacer en producción!)
kubectl scale deployment coredns --replicas=0 -n kube-system
```

### 3.2 Diagnosticar

**Paso 1: Test DNS (fallará)**

```bash
kubectl run dns-test --image=busybox:1.35 --rm -it --restart=Never -n lab-troubleshoot -- nslookup web
# Error: can't resolve 'web'
```

**Paso 2: Verificar /etc/resolv.conf**

```bash
kubectl run resolv-check --image=busybox:1.35 --rm -it --restart=Never -n lab-troubleshoot -- cat /etc/resolv.conf

# Salida esperada:
# nameserver 10.96.0.10
# search lab-troubleshoot.svc.cluster.local svc.cluster.local cluster.local
# options ndots:5
```

**Paso 3: Verificar kube-dns Service**

```bash
kubectl get svc kube-dns -n kube-system
# Debe existir y tener ClusterIP (típicamente 10.96.0.10)
```

**Paso 4: Verificar CoreDNS Pods**

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
# ❌ No hay pods (porque escalamos a 0)
```

**❓ Pregunta:** ¿Qué componente es responsable de DNS en Kubernetes?

**Paso 5: Verificar Endpoints de kube-dns**

```bash
kubectl get endpoints kube-dns -n kube-system
# ENDPOINTS: <none>  ❌ Sin pods, sin endpoints
```

**Paso 6: Solucionar - Restaurar CoreDNS**

```bash
kubectl scale deployment coredns --replicas=2 -n kube-system

# Esperar que estén ready
kubectl wait --for=condition=Ready pod -l k8s-app=kube-dns -n kube-system --timeout=60s
```

**Paso 7: Verificar DNS funciona**

```bash
kubectl run dns-test --image=busybox:1.35 --rm -it --restart=Never -n lab-troubleshoot -- nslookup web
# ✅ Ahora resuelve correctamente
```

---

## 📝 Escenario 4: Service Accessible but Pods Not Ready

### 4.1 Setup del Escenario

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: not-ready-app
  namespace: lab-troubleshoot
spec:
  replicas: 3
  selector:
    matchLabels:
      app: not-ready
  template:
    metadata:
      labels:
        app: not-ready
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /healthz  # ❌ Path que no existe
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: not-ready-service
  namespace: lab-troubleshoot
spec:
  selector:
    app: not-ready
  ports:
  - port: 80
    targetPort: 80
EOF
```

### 4.2 Diagnosticar

**Paso 1: Ver estado de pods**

```bash
kubectl get pods -l app=not-ready -n lab-troubleshoot
# READY: 0/1 ❌ Pods no están ready
```

**Paso 2: Describir pod**

```bash
POD_NAME=$(kubectl get pod -l app=not-ready -o jsonpath='{.items[0].metadata.name}' -n lab-troubleshoot)
kubectl describe pod $POD_NAME -n lab-troubleshoot | grep -A 10 "Readiness:"

# Verás: Readiness probe failed: HTTP probe failed with statuscode: 404
```

**Paso 3: Verificar Endpoints del Service**

```bash
kubectl get endpoints not-ready-service -n lab-troubleshoot
# ENDPOINTS: <none>  ❌ Pods no-ready no aparecen
```

**Paso 4: Ver logs del pod**

```bash
kubectl logs $POD_NAME -n lab-troubleshoot
# Nginx está corriendo, pero readiness probe falla
```

**Paso 5: Solucionar - Corregir Readiness Probe**

```bash
kubectl patch deployment not-ready-app -n lab-troubleshoot -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","readinessProbe":{"httpGet":{"path":"/"}}}]}}}}'

# Esperar rollout
kubectl rollout status deployment not-ready-app -n lab-troubleshoot
```

**Paso 6: Verificar**

```bash
# Pods ahora ready
kubectl get pods -l app=not-ready -n lab-troubleshoot
# READY: 1/1 ✅

# Endpoints poblados
kubectl get endpoints not-ready-service -n lab-troubleshoot
# Ahora tiene IPs ✅
```

---

## 📝 Escenario 5: Ingress Returns 404

### 5.1 Setup del Escenario

**Prerequisito: Ingress controller instalado** (ver Lab 03)

```bash
# Verificar ingress controller
kubectl get pods -n ingress-nginx

# Crear deployment y service
kubectl create deployment web-app --image=nginx:alpine -n lab-troubleshoot
kubectl expose deployment web-app --port=80 -n lab-troubleshoot

# Crear ingress con path INCORRECTO
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: broken-ingress
  namespace: lab-troubleshoot
spec:
  ingressClassName: nginx
  rules:
  - host: test.example.com
    http:
      paths:
      - path: /wrong-path  # ❌ Path que no coincide con requests
        pathType: Prefix
        backend:
          service:
            name: web-app
            port:
              number: 80
EOF
```

### 5.2 Diagnosticar

**Paso 1: Test (dará 404)**

```bash
INGRESS_IP=$(minikube ip)  # o tu IP del ingress
curl -v -H "Host: test.example.com" http://$INGRESS_IP/ 2>&1 | grep "< HTTP"
# HTTP/1.1 404 Not Found ❌
```

**Paso 2: Verificar Ingress**

```bash
kubectl get ingress broken-ingress -n lab-troubleshoot
kubectl describe ingress broken-ingress -n lab-troubleshoot
```

**Paso 3: Verificar que el Service funciona internamente**

```bash
kubectl run test --image=curlimages/curl --rm -it --restart=Never -n lab-troubleshoot -- curl http://web-app
# ✅ Funciona internamente
```

**Paso 4: Ver logs del Ingress Controller**

```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=100 | grep test.example.com
```

**Paso 5: Verificar Configuración Nginx**

```bash
CONTROLLER_POD=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n ingress-nginx $CONTROLLER_POD -- cat /etc/nginx/nginx.conf | grep -A 30 "server_name test.example.com"

# Verás que solo está configurado /wrong-path
```

**Paso 6: Solucionar - Corregir Path**

```bash
kubectl patch ingress broken-ingress -n lab-troubleshoot --type='json' -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/path", "value":"/"}]'
```

**Paso 7: Verificar**

```bash
# Esperar unos segundos para que se reconfigure nginx
sleep 5

# Test
curl -H "Host: test.example.com" http://$INGRESS_IP/
# ✅ Ahora funciona
```

---

## 📝 Escenario 6: Port Mismatch

### 6.1 Setup del Escenario

```bash
# Deployment escuchando en puerto 8080
kubectl create deployment port-app --image=hashicorp/http-echo --port=8080 -n lab-troubleshoot -- -text="Hello from port 8080"

# Service apuntando al puerto INCORRECTO
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: port-service
  namespace: lab-troubleshoot
spec:
  selector:
    app: port-app
  ports:
  - port: 80
    targetPort: 80  # ❌ Debería ser 8080
EOF
```

### 6.2 Diagnosticar

**Paso 1: Test (fallará o timeout)**

```bash
kubectl run test --image=curlimages/curl --rm -it --restart=Never -n lab-troubleshoot -- curl -m 5 http://port-service
# Error: Empty reply from server o timeout
```

**Paso 2: Verificar Endpoints**

```bash
kubectl get endpoints port-service -n lab-troubleshoot
# Tiene IPs ✅ Entonces no es problema de labels
```

**Paso 3: Test directo a Pod IP**

```bash
POD_IP=$(kubectl get pod -l app=port-app -o jsonpath='{.items[0].status.podIP}' -n lab-troubleshoot)

# Test puerto incorrecto
kubectl run test --image=curlimages/curl --rm --restart=Never -n lab-troubleshoot -- curl -m 2 http://$POD_IP:80
# Error ❌

# Test puerto correcto
kubectl run test --image=curlimages/curl --rm --restart=Never -n lab-troubleshoot -- curl -m 2 http://$POD_IP:8080
# Funciona ✅
```

**Paso 4: Verificar Puerto del Contenedor**

```bash
kubectl get deployment port-app -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}' -n lab-troubleshoot
# 8080 ✅

kubectl get svc port-service -o jsonpath='{.spec.ports[0].targetPort}' -n lab-troubleshoot
# 80 ❌ Aquí está el problema
```

**Paso 5: Solucionar**

```bash
kubectl patch svc port-service -n lab-troubleshoot -p '{"spec":{"ports":[{"port":80,"targetPort":8080}]}}'
```

**Paso 6: Verificar**

```bash
kubectl run test --image=curlimages/curl --rm -it --restart=Never -n lab-troubleshoot -- curl http://port-service
# ✅ Ahora funciona
```

---

## 📝 Escenario 7: Network Performance Issues

### 7.1 Setup y Diagnóstico Avanzado

```bash
# Crear pods para testing
kubectl create deployment perf-test --image=nginx:alpine --replicas=2 -n lab-troubleshoot
kubectl expose deployment perf-test --port=80 -n lab-troubleshoot

# Usar netshoot para debugging avanzado
kubectl run netshoot --rm -it --image=nicolaka/netshoot -n lab-troubleshoot -- /bin/bash
```

**Dentro de netshoot:**

```bash
# Test 1: Latencia DNS
time nslookup perf-test

# Test 2: Conectividad con netcat
nc -zv perf-test 80

# Test 3: Trace route
traceroute perf-test

# Test 4: Captura de tráfico (tcpdump)
# Nota: Requiere privilegios
tcpdump -i any -n host perf-test -c 10

# Test 5: HTTP performance con curl
time curl http://perf-test

# Test 6: Ver routing table
ip route

# Test 7: Ver interfaces de red
ip addr

# Test 8: Estadísticas de red
netstat -s | grep -i error

# Test 9: Ver conexiones activas
ss -tuln

# exit
```

---

## 📝 Escenario 8: Troubleshooting Completo Checklist

### Metodología Sistemática (Capa por Capa)

**Capa 1: Pod/Container**

```bash
# ¿Está el pod running?
kubectl get pods -n lab-troubleshoot

# ¿Está ready?
kubectl get pods -o wide -n lab-troubleshoot

# Ver eventos
kubectl describe pod <pod-name> -n lab-troubleshoot

# Ver logs
kubectl logs <pod-name> -n lab-troubleshoot

# Entrar al pod
kubectl exec -it <pod-name> -n lab-troubleshoot -- /bin/sh
```

**Capa 2: Service**

```bash
# ¿Existe el service?
kubectl get svc <service-name> -n lab-troubleshoot

# ¿Tiene endpoints?
kubectl get endpoints <service-name> -n lab-troubleshoot

# ¿Labels coinciden?
kubectl describe svc <service-name> -n lab-troubleshoot | grep Selector
kubectl get pods --show-labels -n lab-troubleshoot

# ¿Puerto correcto?
kubectl describe svc <service-name> -n lab-troubleshoot | grep -E "Port|TargetPort"
```

**Capa 3: DNS**

```bash
# ¿CoreDNS running?
kubectl get pods -n kube-system -l k8s-app=kube-dns

# ¿kube-dns service existe?
kubectl get svc kube-dns -n kube-system

# Test resolución
kubectl run test --image=busybox:1.35 --rm -it --restart=Never -- nslookup <service-name>
```

**Capa 4: Network Policies**

```bash
# ¿Hay network policies?
kubectl get networkpolicy -n lab-troubleshoot

# Describir policies
kubectl describe networkpolicy -n lab-troubleshoot

# Ver si bloquean tráfico
kubectl logs -n kube-system -l k8s-app=calico-node | grep -i denied
```

**Capa 5: Ingress**

```bash
# ¿Ingress controller running?
kubectl get pods -n ingress-nginx

# ¿Ingress resource existe?
kubectl get ingress -n lab-troubleshoot

# Verificar backend
kubectl describe ingress <ingress-name> -n lab-troubleshoot

# Ver logs del controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

---

## 🎓 Verificación Final

### Challenge: Resolver Múltiples Problemas

```bash
# Crear escenario con múltiples problemas
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: challenge-app
  namespace: lab-troubleshoot
spec:
  replicas: 2
  selector:
    matchLabels:
      app: challenge
  template:
    metadata:
      labels:
        app: wrong-challenge  # ❌ Problema 1: Label incorrecto
    spec:
      containers:
      - name: web
        image: nginx:alpine
        ports:
        - containerPort: 8080  # ❌ Problema 2: Puerto incorrecto (nginx usa 80)
        readinessProbe:
          httpGet:
            path: /health  # ❌ Problema 3: Path inexistente
            port: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: challenge-service
  namespace: lab-troubleshoot
spec:
  selector:
    app: challenge
  ports:
  - port: 80
    targetPort: 8080
EOF

# Aplicar network policy que bloquea
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-challenge
  namespace: lab-troubleshoot
spec:
  podSelector:
    matchLabels:
      app: challenge
  policyTypes:
  - Ingress
  # ❌ Problema 4: Sin reglas = bloquear todo
EOF
```

**Tu tarea:**

1. Identificar TODOS los problemas (hay 4)
2. Corregir cada uno
3. Verificar que el servicio funciona

**Hints:**

```bash
kubectl get pods -n lab-troubleshoot
kubectl get endpoints challenge-service -n lab-troubleshoot
kubectl describe networkpolicy -n lab-troubleshoot
```

---

## 🧹 Limpieza

```bash
# Eliminar namespace
kubectl delete namespace lab-troubleshoot

# Restaurar CoreDNS si lo escalaste
kubectl scale deployment coredns --replicas=2 -n kube-system

# Volver a default
kubectl config set-context --current --namespace=default
```

---

## 📚 Recursos Adicionales

### Herramientas de Debugging

- **netshoot**: `docker.io/nicolaka/netshoot`
- **dnsutils**: `registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3`
- **curl**: `curlimages/curl`
- **busybox**: `busybox:1.35`

### Comandos de Referencia

```bash
# Debugging rápido
kubectl run debug --rm -it --image=nicolaka/netshoot -- /bin/bash

# DNS test
kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 --rm -it -- nslookup kubernetes

# Port test
kubectl run test --image=busybox --rm -it -- nc -zv service-name 80

# HTTP test
kubectl run test --image=curlimages/curl --rm -it -- curl http://service-name
```

---

## ✅ Criterios de Éxito

Has completado exitosamente este laboratorio si:

1. ✅ Diagnosticaste problemas de conectividad pod-to-pod
2. ✅ Resolviste problemas de Services sin endpoints
3. ✅ Troubleshooteaste problemas de DNS
4. ✅ Identificaste pods not-ready y su impacto
5. ✅ Debuggeaste problemas de Ingress
6. ✅ Resolviste port mismatch
7. ✅ Aplicaste metodología sistemática layer-by-layer
8. ✅ Completaste el challenge final con múltiples problemas

**¡Felicitaciones! 🎉 Has completado el Laboratorio 04 de Network Troubleshooting Avanzado.**

**Nota CKA**: Este laboratorio refleja el tipo de problemas que verás en el examen CKA. Practica la metodología sistemática para resolver problemas rápidamente bajo presión de tiempo.
