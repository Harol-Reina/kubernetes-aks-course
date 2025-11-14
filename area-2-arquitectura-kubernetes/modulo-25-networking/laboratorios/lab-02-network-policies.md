# Laboratorio 02: Network Policies en Kubernetes

## 📋 Metadata

- **Módulo**: 25 - Networking
- **Laboratorio**: 02
- **Título**: Network Policies y Seguridad de Red
- **Duración estimada**: 60-75 minutos
- **Dificultad**: ⭐⭐⭐ (Avanzado)
- **Objetivos CKA**: Network Policies (5-10%)

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio serás capaz de:

1. Crear Network Policies para controlar tráfico ingress y egress
2. Implementar políticas de default deny
3. Configurar aislamiento de red multi-tier
4. Usar selectores (podSelector, namespaceSelector, ipBlock)
5. Troubleshoot problemas de conectividad causados por Network Policies
6. Implementar patrones de seguridad de red comunes

## 📚 Prerequisitos

- Cluster de Kubernetes con CNI que soporte Network Policies (Calico, Cilium, Weave)
- kubectl configurado
- Laboratorio 01 completado (Services y DNS)
- Conocimientos de networking básico

## ⚠️ Importante: Verificar Soporte de Network Policies

```bash
# Verificar que el CNI soporta Network Policies
# Para Calico:
kubectl get pods -n kube-system | grep calico

# Para Cilium:
kubectl get pods -n kube-system | grep cilium

# Para Weave:
kubectl get pods -n kube-system | grep weave

# Si usas minikube, habilitar Calico:
# minikube start --cni=calico
```

**⚠️ NOTA:** Si tu cluster NO tiene un CNI con soporte de Network Policies, las policies se crearán pero NO se aplicarán.

---

## 🔧 Preparación del Entorno

### Crear namespace y aplicaciones de prueba

```bash
# Crear namespace
kubectl create namespace lab-netpol

# Contexto al namespace
kubectl config set-context --current --namespace=lab-netpol
```

### Desplegar aplicación three-tier

```bash
cat <<EOF | kubectl apply -f -
# Frontend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: lab-netpol
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
      tier: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: lab-netpol
spec:
  selector:
    app: frontend
    tier: frontend
  ports:
  - port: 80
    targetPort: 80
---
# Backend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: lab-netpol
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
      tier: backend
  template:
    metadata:
      labels:
        app: backend
        tier: backend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: lab-netpol
spec:
  selector:
    app: backend
    tier: backend
  ports:
  - port: 80
    targetPort: 80
---
# Database
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: lab-netpol
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
      tier: database
  template:
    metadata:
      labels:
        app: database
        tier: database
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          value: testpass
---
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: lab-netpol
spec:
  selector:
    app: database
    tier: database
  ports:
  - port: 5432
    targetPort: 5432
EOF
```

### Verificar deployments

```bash
kubectl get pods -n lab-netpol -o wide
kubectl get svc -n lab-netpol
```

### Test de conectividad ANTES de Network Policies

```bash
# Obtener nombre de pod frontend
FRONTEND_POD=$(kubectl get pod -l tier=frontend -o jsonpath='{.items[0].metadata.name}')
BACKEND_POD=$(kubectl get pod -l tier=backend -o jsonpath='{.items[0].metadata.name}')

# Frontend -> Backend (debería funcionar)
kubectl exec $FRONTEND_POD -- wget -qO- --timeout=2 http://backend

# Backend -> Database (debería funcionar)
kubectl exec $BACKEND_POD -- nc -zv database 5432

# Frontend -> Database (debería funcionar, pero NO debería en producción)
kubectl exec $FRONTEND_POD -- nc -zv database 5432
```

**❓ Pregunta:** ¿Por qué el frontend puede acceder directamente a la database? ¿Es esto seguro?

---

## 📝 Ejercicio 1: Default Deny All Ingress

### 1.1 Crear Policy de Deny All

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: lab-netpol
spec:
  podSelector: {}  # Aplica a TODOS los pods
  policyTypes:
  - Ingress
  # Sin reglas 'ingress' = denegar todo
EOF
```

### 1.2 Verificar la Policy

```bash
kubectl get networkpolicy -n lab-netpol
kubectl describe networkpolicy default-deny-ingress -n lab-netpol
```

### 1.3 Test de Conectividad (Todo debería fallar)

```bash
# Frontend -> Backend (debería FALLAR ahora)
kubectl exec $FRONTEND_POD -- wget -qO- --timeout=2 http://backend
# Error: wget: download timed out

# Backend -> Database (debería FALLAR)
kubectl exec $BACKEND_POD -- nc -zv -w 2 database 5432
# Error: connection timed out
```

**❓ Pregunta:** ¿Por qué ahora falla toda la conectividad?

### 1.4 Permitir Tráfico Frontend -> Backend

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: lab-netpol
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
EOF
```

### 1.5 Test (Ahora Frontend -> Backend funciona)

```bash
# Frontend -> Backend (debería FUNCIONAR)
kubectl exec $FRONTEND_POD -- wget -qO- --timeout=2 http://backend

# Backend -> Database (aún FALLA - todavía no hay policy)
kubectl exec $BACKEND_POD -- nc -zv -w 2 database 5432
```

---

## 📝 Ejercicio 2: Three-Tier Application Isolation

### 2.1 Policy: Backend -> Database

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: lab-netpol
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
EOF
```

### 2.2 Test Completo de Three-Tier

```bash
# ✅ Frontend -> Backend (permitido)
kubectl exec $FRONTEND_POD -- wget -qO- --timeout=2 http://backend

# ✅ Backend -> Database (permitido)
kubectl exec $BACKEND_POD -- nc -zv -w 2 database 5432

# ❌ Frontend -> Database (bloqueado - seguridad correcta)
kubectl exec $FRONTEND_POD -- nc -zv -w 2 database 5432
```

**✅ Resultado Esperado:**
- Frontend puede comunicarse con Backend
- Backend puede comunicarse con Database
- Frontend NO puede comunicarse directamente con Database (seguridad)

### 2.3 Visualizar Políticas Activas

```bash
# Listar todas las Network Policies
kubectl get networkpolicies -n lab-netpol

# Describir cada policy
kubectl describe networkpolicy default-deny-ingress -n lab-netpol
kubectl describe networkpolicy allow-frontend-to-backend -n lab-netpol
kubectl describe networkpolicy allow-backend-to-database -n lab-netpol
```

---

## 📝 Ejercicio 3: Egress Policies (Control de Salida)

### 3.1 Default Deny Egress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: lab-netpol
spec:
  podSelector: {}
  policyTypes:
  - Egress
  # Sin reglas 'egress' = denegar todo
EOF
```

### 3.2 Test (Ahora TODO falla, incluso DNS)

```bash
# Intentar acceder a backend (FALLA - no puede hacer DNS lookup)
kubectl exec $FRONTEND_POD -- wget -qO- --timeout=2 http://backend
# Error: bad address 'backend'

# Intentar ping a Google (FALLA)
kubectl exec $FRONTEND_POD -- ping -c 1 8.8.8.8
```

**❓ Pregunta:** ¿Por qué falla incluso el DNS?

### 3.3 Permitir DNS (kube-system)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-access
  namespace: lab-netpol
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  # Permitir DNS
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF
```

**NOTA:** Si el label del namespace no funciona, usar:

```bash
# Ver labels del namespace kube-system
kubectl get namespace kube-system --show-labels

# Alternativa sin namespaceSelector (menos seguro):
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-access
  namespace: lab-netpol
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - ports:
    - protocol: UDP
      port: 53
EOF
```

### 3.4 Permitir Egress: Frontend -> Backend

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress-to-backend
  namespace: lab-netpol
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Egress
  egress:
  # DNS
  - ports:
    - protocol: UDP
      port: 53
  # Backend
  - to:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 80
EOF
```

### 3.5 Permitir Egress: Backend -> Database

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-egress-to-database
  namespace: lab-netpol
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Egress
  egress:
  # DNS
  - ports:
    - protocol: UDP
      port: 53
  # Database
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
EOF
```

### 3.6 Test Final con Ingress + Egress

```bash
# ✅ Frontend -> Backend
kubectl exec $FRONTEND_POD -- wget -qO- --timeout=2 http://backend

# ✅ Backend -> Database
kubectl exec $BACKEND_POD -- nc -zv -w 2 database 5432

# ❌ Frontend -> Database (bloqueado)
kubectl exec $FRONTEND_POD -- nc -zv -w 2 database 5432

# ❌ Frontend -> Internet (bloqueado)
kubectl exec $FRONTEND_POD -- ping -c 1 8.8.8.8
```

---

## 📝 Ejercicio 4: Namespace Isolation

### 4.1 Crear Segundo Namespace

```bash
# Crear namespace "production"
kubectl create namespace production

# Etiquetar namespace
kubectl label namespace production name=production

# Crear pod de prueba en production
kubectl run test-pod --image=nginx:alpine -n production
kubectl expose pod test-pod --name=test-service --port=80 -n production
```

### 4.2 Test Cross-Namespace (Sin Restricciones)

```bash
# Desde lab-netpol, acceder a production (actualmente BLOQUEADO por default-deny-egress)
kubectl exec $FRONTEND_POD -n lab-netpol -- wget -qO- --timeout=2 http://test-service.production.svc.cluster.local
```

### 4.3 Permitir Acceso Cross-Namespace Específico

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-lab-netpol
  namespace: production
spec:
  podSelector:
    matchLabels:
      run: test-pod
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: lab-netpol
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
EOF
```

### 4.4 Actualizar Egress de Frontend

```bash
kubectl delete networkpolicy frontend-egress-to-backend -n lab-netpol

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress-updated
  namespace: lab-netpol
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Egress
  egress:
  # DNS
  - ports:
    - protocol: UDP
      port: 53
  # Backend (mismo namespace)
  - to:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 80
  # Production namespace
  - to:
    - namespaceSelector:
        matchLabels:
          name: production
    ports:
    - protocol: TCP
      port: 80
EOF
```

### 4.5 Test Cross-Namespace

```bash
# Ahora debería funcionar
kubectl exec $FRONTEND_POD -n lab-netpol -- wget -qO- --timeout=2 http://test-service.production.svc.cluster.local
```

---

## 📝 Ejercicio 5: IP Block (CIDR) Restrictions

### 5.1 Permitir Egress a IPs Específicas

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-ips
  namespace: lab-netpol
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Egress
  egress:
  # DNS
  - ports:
    - protocol: UDP
      port: 53
  # Database interna
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  # Permitir solo ciertos rangos externos
  - to:
    - ipBlock:
        cidr: 8.8.8.8/32  # Solo Google DNS
    ports:
    - protocol: TCP
      port: 53
  # Permitir HTTPS a internet, excepto redes privadas
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16
        - 169.254.169.254/32  # Metadata service
    ports:
    - protocol: TCP
      port: 443
EOF
```

### 5.2 Test IP Block

```bash
# ✅ Ping a Google DNS (permitido)
kubectl exec $BACKEND_POD -- ping -c 1 8.8.8.8

# ❌ Ping a Cloudflare DNS (bloqueado)
kubectl exec $BACKEND_POD -- ping -c 1 1.1.1.1
```

---

## 📝 Ejercicio 6: Troubleshooting Network Policies

### 6.1 Escenario: Conectividad Rota

```bash
# Crear policy problemática (bloquea TODO sin darse cuenta)
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: broken-policy
  namespace: lab-netpol
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  - Egress
  # Ingress vacío = bloquear todo
  # Egress vacío = bloquear todo
EOF
```

### 6.2 Diagnosticar

```bash
# Test (fallará)
kubectl exec $FRONTEND_POD -- wget -qO- --timeout=2 http://backend

# Ver todas las policies aplicadas al backend
kubectl get networkpolicy -n lab-netpol

# Describir la policy problemática
kubectl describe networkpolicy broken-policy -n lab-netpol

# Ver qué policies afectan a un pod
kubectl get networkpolicy -n lab-netpol -o yaml | grep -A 20 "tier: backend"
```

**❓ Pregunta:** ¿Cómo identificar qué policy está bloqueando el tráfico?

### 6.3 Solución

```bash
# Eliminar policy problemática
kubectl delete networkpolicy broken-policy -n lab-netpol

# Verificar que funciona de nuevo
kubectl exec $FRONTEND_POD -- wget -qO- --timeout=2 http://backend
```

### 6.4 Debugging Avanzado

```bash
# Ver logs del CNI plugin (Calico example)
kubectl logs -n kube-system -l k8s-app=calico-node --tail=100

# Ver todas las policies y sus selectores
kubectl get networkpolicy -n lab-netpol -o yaml

# Usar herramientas de debugging
kubectl run netshoot --rm -it --image=nicolaka/netshoot -n lab-netpol -- /bin/bash

# Dentro de netshoot:
# curl http://backend
# nslookup backend
# nc -zv backend 80
# traceroute backend
```

---

## 📝 Ejercicio 7: Políticas Combinadas (Ingress + Egress)

### 7.1 Policy Completa para Backend

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-complete-policy
  namespace: lab-netpol
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Acepta del Frontend
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
  # Acepta de Monitoring (ejemplo)
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090  # Prometheus metrics
  egress:
  # DNS
  - ports:
    - protocol: UDP
      port: 53
  # Database
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  # APIs externas (HTTPS)
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16
    ports:
    - protocol: TCP
      port: 443
EOF
```

### 7.2 Eliminar Policies Anteriores

```bash
# Limpiar policies viejas del backend
kubectl delete networkpolicy allow-backend-to-database -n lab-netpol
kubectl delete networkpolicy backend-egress-to-database -n lab-netpol

# La nueva policy "backend-complete-policy" las reemplaza
```

### 7.3 Test Final Completo

```bash
# ✅ Frontend -> Backend
kubectl exec $FRONTEND_POD -- wget -qO- --timeout=2 http://backend

# ✅ Backend -> Database
kubectl exec $BACKEND_POD -- nc -zv -w 2 database 5432

# ✅ Backend -> External HTTPS
kubectl exec $BACKEND_POD -- wget -qO- --timeout=2 https://www.google.com | head -10
```

---

## 🎓 Verificación Final

### Checklist de Aprendizaje

- [ ] Crear default deny policy (ingress y egress)
- [ ] Permitir tráfico específico entre pods con podSelector
- [ ] Configurar aislamiento three-tier (Frontend -> Backend -> Database)
- [ ] Permitir DNS (namespaceSelector a kube-system)
- [ ] Crear policies cross-namespace
- [ ] Usar ipBlock para restringir acceso externo
- [ ] Combinar ingress y egress en una policy
- [ ] Diagnosticar problemas de conectividad
- [ ] Listar y describir network policies

### Comandos de Validación

```bash
# Ver todas las policies
kubectl get networkpolicy -n lab-netpol

# Contar policies
kubectl get networkpolicy -n lab-netpol --no-headers | wc -l

# Test final de conectividad
FRONTEND_POD=$(kubectl get pod -l tier=frontend -n lab-netpol -o jsonpath='{.items[0].metadata.name}')
BACKEND_POD=$(kubectl get pod -l tier=backend -n lab-netpol -o jsonpath='{.items[0].metadata.name}')

echo "Test 1: Frontend -> Backend (debe funcionar)"
kubectl exec $FRONTEND_POD -n lab-netpol -- wget -qO- --timeout=2 http://backend && echo "✅ OK" || echo "❌ FAILED"

echo "Test 2: Backend -> Database (debe funcionar)"
kubectl exec $BACKEND_POD -n lab-netpol -- nc -zv -w 2 database 5432 2>&1 | grep -q "open" && echo "✅ OK" || echo "❌ FAILED"

echo "Test 3: Frontend -> Database (debe fallar)"
kubectl exec $FRONTEND_POD -n lab-netpol -- nc -zv -w 2 database 5432 2>&1 | grep -q "timed out" && echo "✅ OK (bloqueado correctamente)" || echo "❌ FAILED (no está bloqueado!)"
```

---

## 🧹 Limpieza

```bash
# Eliminar namespaces completos
kubectl delete namespace lab-netpol
kubectl delete namespace production

# Volver a default
kubectl config set-context --current --namespace=default
```

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Declare Network Policy](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)

### Herramientas

- [Network Policy Editor](https://editor.cilium.io/) - Visualizar y generar policies
- [Network Policy Viewer](https://github.com/runoncloud/kubectl-np-viewer) - Plugin kubectl

### Comandos de Referencia

```bash
# Listar policies
kubectl get networkpolicies -A

# Describir policy
kubectl describe networkpolicy <name>

# Aplicar policy
kubectl apply -f policy.yaml

# Eliminar policy
kubectl delete networkpolicy <name>

# Ver YAML de policy
kubectl get networkpolicy <name> -o yaml

# Logs CNI (Calico)
kubectl logs -n kube-system -l k8s-app=calico-node
```

---

## ✅ Criterios de Éxito

Has completado exitosamente este laboratorio si:

1. ✅ Implementaste default deny policies (ingress y egress)
2. ✅ Configuraste aislamiento three-tier correctamente
3. ✅ Permitiste DNS y verificaste su funcionamiento
4. ✅ Creaste policies cross-namespace
5. ✅ Usaste ipBlock para restringir acceso externo
6. ✅ Diagnosticaste y resolviste problemas de conectividad
7. ✅ Entendiste el modelo whitelist de Network Policies

**¡Felicitaciones! 🎉 Has completado el Laboratorio 02 de Network Policies.**
