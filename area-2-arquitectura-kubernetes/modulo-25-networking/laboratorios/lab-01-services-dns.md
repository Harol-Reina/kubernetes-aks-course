# Laboratorio 01: Services y DNS en Kubernetes

## 📋 Metadata

- **Módulo**: 25 - Networking
- **Laboratorio**: 01
- **Título**: Services y DNS
- **Duración estimada**: 45-60 minutos
- **Dificultad**: ⭐⭐ (Intermedio)
- **Objetivos CKA**: Services (10%), DNS (5%)

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio serás capaz de:

1. Crear y configurar diferentes tipos de Services (ClusterIP, NodePort, LoadBalancer, Headless)
2. Entender el funcionamiento de DNS en Kubernetes
3. Probar resolución DNS de Services y Pods
4. Troubleshoot problemas comunes de conectividad de Services
5. Trabajar con Endpoints y su relación con Services

## 📚 Prerequisitos

- Cluster de Kubernetes funcional (minikube, kind, o cluster real)
- kubectl configurado y funcionando
- Conocimientos básicos de networking
- Comprensión de conceptos de DNS

## 🔧 Preparación del Entorno

### Verificar cluster

```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -n kube-system | grep -E 'coredns|kube-dns'
```

### Crear namespace para el laboratorio

```bash
kubectl create namespace lab-services
kubectl config set-context --current --namespace=lab-services
```

### Verificar namespace activo

```bash
kubectl config view --minify | grep namespace
```

---

## 📝 Ejercicio 1: ClusterIP Service (Internal Communication)

### 1.1 Crear un Deployment de Backend

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: lab-services
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh"]
        args:
          - -c
          - |
            echo "Backend Pod: \$(hostname)" > /usr/share/nginx/html/index.html
            nginx -g 'daemon off;'
EOF
```

**Verificar deployment:**

```bash
kubectl get deployment backend
kubectl get pods -l app=backend -o wide
```

### 1.2 Crear ClusterIP Service

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: lab-services
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
EOF
```

**Verificar service:**

```bash
kubectl get svc backend-service
kubectl describe svc backend-service
```

### 1.3 Verificar Endpoints

```bash
# Ver endpoints creados automáticamente
kubectl get endpoints backend-service

# Comparar con las IPs de los pods
kubectl get pods -l app=backend -o wide
```

**❓ Pregunta:** ¿Por qué el número de endpoints coincide con el número de pods?

### 1.4 Probar Conectividad desde otro Pod

```bash
# Crear pod de prueba
kubectl run test-pod --image=busybox:1.35 --rm -it --restart=Never -- /bin/sh

# Dentro del pod, ejecutar:
# wget -qO- http://backend-service
# wget -qO- http://backend-service.lab-services
# wget -qO- http://backend-service.lab-services.svc.cluster.local
# exit
```

**Ejecutar en una sola línea:**

```bash
kubectl run test-pod --image=busybox:1.35 --rm -it --restart=Never -- wget -qO- http://backend-service
```

**Verificar balanceo de carga:**

```bash
for i in {1..10}; do
  kubectl run test-$i --image=busybox:1.35 --rm --restart=Never -- wget -qO- http://backend-service
done
```

**❓ Pregunta:** ¿Ves diferentes hostnames? ¿Cómo balancea la carga el Service?

### 1.5 Obtener ClusterIP

```bash
# Método 1: kubectl get
kubectl get svc backend-service -o wide

# Método 2: jsonpath
kubectl get svc backend-service -o jsonpath='{.spec.clusterIP}'

# Método 3: describe
kubectl describe svc backend-service | grep "IP:"
```

---

## 📝 Ejercicio 2: NodePort Service (External Access)

### 2.1 Crear NodePort Service

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: frontend-nodeport
  namespace: lab-services
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080  # Puerto en el rango 30000-32767
      protocol: TCP
EOF
```

### 2.2 Crear Deployment Frontend

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: lab-services
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh"]
        args:
          - -c
          - |
            cat > /usr/share/nginx/html/index.html <<HTML
            <!DOCTYPE html>
            <html>
            <head><title>Frontend</title></head>
            <body>
              <h1>Frontend Pod: \$(hostname)</h1>
              <p>NodePort Service Test</p>
            </body>
            </html>
            HTML
            nginx -g 'daemon off;'
EOF
```

### 2.3 Verificar NodePort

```bash
# Ver el NodePort asignado
kubectl get svc frontend-nodeport

# Obtener solo el NodePort
kubectl get svc frontend-nodeport -o jsonpath='{.spec.ports[0].nodePort}'
echo
```

### 2.4 Obtener IP del Nodo

```bash
# Método 1: Para minikube
minikube ip

# Método 2: Para clusters reales
kubectl get nodes -o wide

# Método 3: Describir nodo
kubectl describe node | grep InternalIP
```

### 2.5 Probar Acceso desde Fuera del Cluster

```bash
# Obtener IP del nodo
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Para minikube
NODE_IP=$(minikube ip)

# Probar el NodePort
curl http://$NODE_IP:30080

# Múltiples requests para ver balanceo
for i in {1..5}; do
  curl http://$NODE_IP:30080 2>/dev/null | grep "Frontend Pod"
done
```

**❓ Pregunta:** ¿Qué diferencia hay entre ClusterIP y NodePort en términos de accesibilidad?

---

## 📝 Ejercicio 3: Headless Service (Direct Pod Access)

### 3.1 Crear StatefulSet con Headless Service

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: database-headless
  namespace: lab-services
spec:
  clusterIP: None  # Headless service
  selector:
    app: database
  ports:
    - port: 5432
      targetPort: 5432
      name: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
  namespace: lab-services
spec:
  serviceName: database-headless
  replicas: 3
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_PASSWORD
          value: testpassword
        - name: POSTGRES_DB
          value: testdb
EOF
```

### 3.2 Verificar StatefulSet y Headless Service

```bash
# Ver StatefulSet
kubectl get statefulset database

# Ver pods con nombres estables
kubectl get pods -l app=database

# Ver service (nota: no tiene CLUSTER-IP)
kubectl get svc database-headless
```

**❓ Pregunta:** ¿Por qué el service no tiene ClusterIP?

### 3.3 Verificar Endpoints del Headless Service

```bash
# Ver endpoints (debe mostrar todos los pods)
kubectl get endpoints database-headless

# Comparar con IPs de los pods
kubectl get pods -l app=database -o wide
```

### 3.4 Probar Resolución DNS de Headless Service

```bash
# Crear pod de utilidades DNS
kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 --rm -it --restart=Never -- /bin/bash

# Dentro del pod, ejecutar:
# nslookup database-headless
# nslookup database-headless.lab-services.svc.cluster.local
# exit
```

**Ejecutar desde fuera:**

```bash
kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 --rm -it --restart=Never -- nslookup database-headless.lab-services.svc.cluster.local
```

**❓ Pregunta:** ¿Cuántas direcciones IP devuelve el DNS? ¿Por qué?

### 3.5 Resolver Pods Individuales (DNS Estable)

```bash
# Formato DNS para pods en StatefulSet:
# <pod-name>.<service-name>.<namespace>.svc.cluster.local

# Resolver cada pod individualmente
kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 --rm -it --restart=Never -- nslookup database-0.database-headless.lab-services.svc.cluster.local

kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 --rm -it --restart=Never -- nslookup database-1.database-headless.lab-services.svc.cluster.local

kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 --rm -it --restart=Never -- nslookup database-2.database-headless.lab-services.svc.cluster.local
```

**❓ Pregunta:** ¿Qué ventaja tiene poder resolver pods individuales por nombre?

---

## 📝 Ejercicio 4: DNS Resolution Deep Dive

### 4.1 Verificar Configuración DNS en un Pod

```bash
# Ver /etc/resolv.conf
kubectl run test-dns --image=busybox:1.35 --rm -it --restart=Never -- cat /etc/resolv.conf
```

**Salida esperada:**

```
nameserver 10.96.0.10
search lab-services.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

### 4.2 Entender Search Domains

```bash
# Crear pod para probar DNS
kubectl run dns-test --image=busybox:1.35 --rm -it --restart=Never -- /bin/sh

# Dentro del pod, probar diferentes formatos:
# nslookup backend-service
# nslookup backend-service.lab-services
# nslookup backend-service.lab-services.svc
# nslookup backend-service.lab-services.svc.cluster.local
# exit
```

**❓ Pregunta:** ¿Por qué funciona solo `backend-service` sin el FQDN completo?

### 4.3 Probar Resolución Cross-Namespace

```bash
# Crear otro namespace con un service
kubectl create namespace other-namespace

kubectl run test-pod --image=nginx:alpine --port=80 -n other-namespace

kubectl expose pod test-pod --name=test-service --port=80 -n other-namespace

# Desde lab-services, resolver el service del otro namespace
kubectl run dns-cross-ns --image=busybox:1.35 --rm -it --restart=Never -n lab-services -- nslookup test-service.other-namespace.svc.cluster.local
```

**❓ Pregunta:** ¿Se puede acceder a services de otros namespaces?

### 4.4 Verificar CoreDNS

```bash
# Ver pods de CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Ver logs de CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

# Ver ConfigMap de CoreDNS
kubectl get configmap coredns -n kube-system -o yaml
```

### 4.5 Test de Latencia DNS

```bash
kubectl run dns-perf --image=busybox:1.35 --rm -it --restart=Never -- /bin/sh

# Dentro del pod:
# time nslookup backend-service
# time nslookup backend-service
# time nslookup backend-service
# (La segunda y tercera deberían ser más rápidas por cache)
# exit
```

---

## 📝 Ejercicio 5: Troubleshooting Services

### 5.1 Service sin Endpoints (Pod sin Labels Correctos)

```bash
# Crear deployment con label INCORRECTA
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-app
  namespace: lab-services
spec:
  replicas: 2
  selector:
    matchLabels:
      app: broken
  template:
    metadata:
      labels:
        app: wrong-label  # Label NO coincide con service
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# Crear service que NO coincide
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: broken-service
  namespace: lab-services
spec:
  selector:
    app: broken  # Busca label "app: broken"
  ports:
    - port: 80
      targetPort: 80
EOF
```

**Diagnosticar:**

```bash
# Ver service
kubectl get svc broken-service

# Ver endpoints (debería estar vacío)
kubectl get endpoints broken-service

# Ver pods
kubectl get pods -l app=wrong-label
kubectl get pods -l app=broken
```

**❓ Pregunta:** ¿Por qué el service no tiene endpoints?

**Solución:**

```bash
# Opción 1: Corregir el deployment
kubectl patch deployment broken-app -p '{"spec":{"template":{"metadata":{"labels":{"app":"broken"}}}}}'

# Opción 2: Corregir el service
kubectl patch service broken-service -p '{"spec":{"selector":{"app":"wrong-label"}}}'

# Verificar que ahora hay endpoints
kubectl get endpoints broken-service
```

### 5.2 Port Mismatch

```bash
# Crear deployment en puerto 8080
kubectl create deployment port-mismatch --image=nginx:alpine --port=8080

# Crear service apuntando a puerto INCORRECTO
kubectl expose deployment port-mismatch --port=80 --target-port=80

# Intentar acceder (fallará)
kubectl run test --image=busybox:1.35 --rm --restart=Never -- wget -O- http://port-mismatch:80

# Diagnosticar
kubectl describe svc port-mismatch
kubectl get pods -l app=port-mismatch -o jsonpath='{.items[0].spec.containers[0].ports[0].containerPort}'

# Corregir
kubectl patch service port-mismatch -p '{"spec":{"ports":[{"port":80,"targetPort":8080}]}}'
```

### 5.3 Pod Not Ready

```bash
# Crear deployment con readiness probe que falla
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: not-ready-app
  namespace: lab-services
spec:
  replicas: 2
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
            path: /nonexistent  # Path que no existe
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

# Crear service
kubectl expose deployment not-ready-app --name=not-ready-service --port=80

# Ver pods (READY será 0/1)
kubectl get pods -l app=not-ready

# Ver endpoints (estará vacío porque pods no están ready)
kubectl get endpoints not-ready-service
```

**❓ Pregunta:** ¿Por qué pods no-ready no aparecen en endpoints?

**Corregir:**

```bash
kubectl patch deployment not-ready-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","readinessProbe":{"httpGet":{"path":"/"}}}]}}}}'

# Esperar y verificar
kubectl get pods -l app=not-ready
kubectl get endpoints not-ready-service
```

---

## 📝 Ejercicio 6: Session Affinity

### 6.1 Service sin Session Affinity

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stateful-app
  namespace: lab-services
spec:
  replicas: 3
  selector:
    matchLabels:
      app: stateful
  template:
    metadata:
      labels:
        app: stateful
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh"]
        args:
          - -c
          - |
            echo "Pod: \$(hostname) - Session: \$RANDOM" > /usr/share/nginx/html/index.html
            nginx -g 'daemon off;'
---
apiVersion: v1
kind: Service
metadata:
  name: stateful-service
  namespace: lab-services
spec:
  selector:
    app: stateful
  sessionAffinity: None  # Sin sticky sessions
  ports:
    - port: 80
      targetPort: 80
EOF
```

**Probar sin affinity:**

```bash
# Múltiples requests - irán a diferentes pods
for i in {1..10}; do
  kubectl run test-$i --image=busybox:1.35 --rm --restart=Never -- wget -qO- http://stateful-service
done
```

### 6.2 Habilitar Session Affinity

```bash
kubectl patch service stateful-service -p '{"spec":{"sessionAffinity":"ClientIP"}}'

# Verificar
kubectl describe svc stateful-service | grep "Session Affinity"
```

**Probar con affinity:**

```bash
# Ahora todas las requests desde el mismo pod van al mismo backend
kubectl run persistent-client --image=busybox:1.35 --rm -it --restart=Never -- /bin/sh

# Dentro del pod:
# for i in {1..10}; do wget -qO- http://stateful-service; done
# (Deberías ver siempre el mismo Pod)
# exit
```

---

## 🎓 Verificación Final

### Checklist de Aprendizaje

Verifica que puedes hacer todas estas tareas:

- [ ] Crear un ClusterIP service y accederlo desde un pod
- [ ] Crear un NodePort service y accederlo desde fuera del cluster
- [ ] Crear un Headless service para StatefulSet
- [ ] Resolver DNS de services (short name y FQDN)
- [ ] Resolver DNS de pods individuales en StatefulSet
- [ ] Diagnosticar service sin endpoints
- [ ] Verificar configuración DNS de un pod (/etc/resolv.conf)
- [ ] Probar resolución DNS cross-namespace
- [ ] Configurar session affinity en un service
- [ ] Ver logs de CoreDNS

### Comandos de Validación

```bash
# Verificar todos los services creados
kubectl get svc -n lab-services

# Verificar todos los endpoints
kubectl get endpoints -n lab-services

# Verificar que DNS funciona
kubectl run final-test --image=busybox:1.35 --rm --restart=Never -- nslookup backend-service.lab-services.svc.cluster.local
```

---

## 🧹 Limpieza

```bash
# Eliminar namespace completo
kubectl delete namespace lab-services

# Eliminar namespace auxiliar
kubectl delete namespace other-namespace

# Volver al namespace default
kubectl config set-context --current --namespace=default
```

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Debugging DNS Resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)

### Comandos de Referencia Rápida

```bash
# Services
kubectl expose deployment <name> --port=80 --target-port=8080
kubectl get svc
kubectl describe svc <name>
kubectl get endpoints <name>

# DNS
kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 --rm -it -- nslookup <service-name>
kubectl exec <pod> -- cat /etc/resolv.conf

# Troubleshooting
kubectl get endpoints <service>
kubectl describe svc <service>
kubectl logs -n kube-system -l k8s-app=kube-dns
```

---

## ✅ Criterios de Éxito

Has completado exitosamente este laboratorio si:

1. ✅ Creaste y probaste ClusterIP, NodePort y Headless services
2. ✅ Resolviste nombres DNS usando diferentes formatos
3. ✅ Diagnosticaste y corregiste problemas de conectividad
4. ✅ Entendiste la relación entre Services, Endpoints y Pods
5. ✅ Comprobaste el funcionamiento de CoreDNS
6. ✅ Aplicaste session affinity a un service

**¡Felicitaciones! 🎉 Has completado el Laboratorio 01 de Networking.**
