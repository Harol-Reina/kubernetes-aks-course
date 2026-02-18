# Laboratorio 03: Network & Storage Advanced Troubleshooting

> **Duración estimada**: 75-90 minutos  
> **Dificultad**: ⭐⭐⭐⭐ (Experto)  
> **Objetivos CKA**: Services & Networking (20%), Storage (10%), Troubleshooting (25-30%)

## 📋 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:
- ✅ Troubleshoot DNS (CoreDNS) issues
- ✅ Diagnosticar Services sin endpoints
- ✅ Resolver problemas de Network Policies
- ✅ Troubleshoot Ingress Controllers
- ✅ Diagnosticar PersistentVolumeClaims Pending
- ✅ Resolver problemas con StatefulSets y storage
- ✅ Troubleshoot volume mounts y permisos
- ✅ Diagnosticar problemas de conectividad entre pods

## 🎯 Escenarios

### Escenario 1: DNS Resolution Failure
**Situación**: Los pods no pueden resolver nombres DNS.

**Setup del Problema**:
```bash
# Crear pod de prueba
kubectl run test-dns --image=busybox:1.28 -it --rm -- nslookup kubernetes.default
# Output: Server misbehaving o timeout
```

<details>
<summary>🔍 Diagnóstico Completo</summary>

```bash
# 1. Verificar CoreDNS está corriendo
kubectl get pods -n kube-system -l k8s-app=kube-dns
# NAME                       READY   STATUS    RESTARTS   AGE
# coredns-xxxxxxxxxx-xxxxx   1/1     Running   0          10d

# 2. Si no está running, ver logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# 3. Verificar Service de DNS
kubectl get svc -n kube-system kube-dns
# NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)         AGE
# kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP   10d

# 4. Verificar endpoints del DNS service
kubectl get endpoints -n kube-system kube-dns
# Debe tener IPs de los pods de CoreDNS

# 5. Verificar configuración de CoreDNS
kubectl get configmap -n kube-system coredns -o yaml

# 6. Test manual desde un pod
kubectl run test-dns --image=busybox:1.28 -it --rm -- sh
# Dentro del pod:
cat /etc/resolv.conf
# Debe apuntar a la IP del kube-dns service (típicamente 10.96.0.10)

nslookup kubernetes.default
nslookup google.com  # Test DNS externo
```

</details>

<details>
<summary>✅ Soluciones por Problema</summary>

**Problema 1: CoreDNS pods no están Running**
```bash
# Ver estado
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Si están Pending, ver recursos
kubectl describe pod -n kube-system -l k8s-app=kube-dns

# Escalar deployment si es necesario
kubectl scale deployment coredns -n kube-system --replicas=2

# Ver logs de errores
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50
```

**Problema 2: CoreDNS sin endpoints**
```bash
# Verificar
kubectl get endpoints -n kube-system kube-dns
# ENDPOINTS: <none>

# El problema es que los pods no son seleccionados
kubectl get pods -n kube-system -l k8s-app=kube-dns --show-labels

# Ver selector del servicio
kubectl get svc -n kube-system kube-dns -o yaml | grep -A 3 selector

# Si no coinciden, editar el servicio
kubectl edit svc -n kube-system kube-dns
# Ajustar selector para que coincida con labels de pods
```

**Problema 3: ConfigMap de CoreDNS corrupto**
```bash
# Backup del ConfigMap actual
kubectl get cm -n kube-system coredns -o yaml > /tmp/coredns-cm-backup.yaml

# Ver configuración
kubectl get cm -n kube-system coredns -o yaml

# ConfigMap correcto básico:
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
EOF

# Reiniciar CoreDNS pods
kubectl delete pod -n kube-system -l k8s-app=kube-dns
```

**Problema 4: kubelet no configura DNS en pods**
```bash
# En cada node, verificar kubelet config
sudo cat /var/lib/kubelet/config.yaml | grep -A 5 clusterDNS

# Debe tener:
# clusterDNS:
# - 10.96.0.10  # IP del kube-dns service

# Si no está, agregar y reiniciar kubelet
sudo vi /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet
```

**Verificación Final**:
```bash
# Test resolución
kubectl run test-dns --image=busybox:1.28 -it --rm -- nslookup kubernetes.default
# Debe funcionar

# Test desde dentro del cluster
kubectl run nginx-test --image=nginx
kubectl expose pod nginx-test --port=80
kubectl run test --image=busybox:1.28 -it --rm -- nslookup nginx-test.default.svc.cluster.local
# Debe resolver
```

</details>

---

### Escenario 2: Service Without Endpoints
**Situación**: Un Service existe pero no tiene endpoints, las requests fallan.

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  labels:
    app: web
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: webapp  # ← Label mismatch!
    tier: frontend
  ports:
  - port: 80
    targetPort: 80
EOF
```

<details>
<summary>🔍 Diagnóstico</summary>

```bash
# 1. Verificar service
kubectl get svc web-service
# TYPE: ClusterIP, CLUSTER-IP: 10.x.x.x, PORT(S): 80/TCP

# 2. Verificar endpoints
kubectl get endpoints web-service
# ENDPOINTS: <none>  ← PROBLEMA!

# 3. Ver selector del service
kubectl describe svc web-service
# Selector: app=webapp,tier=frontend

# 4. Ver labels de los pods
kubectl get pods --show-labels | grep web-pod
# Labels: app=web,tier=frontend  ← Mismatch en 'app'

# 5. Comparar selectores
kubectl get svc web-service -o yaml | grep -A 3 selector
kubectl get pod web-pod -o yaml | grep -A 3 labels
```

</details>

<details>
<summary>✅ Solución</summary>

**Opción 1: Corregir labels del pod**
```bash
kubectl label pod web-pod app=webapp --overwrite

# Verificar endpoints ahora existen
kubectl get endpoints web-service
# ENDPOINTS: 10.244.x.x:80
```

**Opción 2: Corregir selector del service**
```bash
kubectl patch svc web-service -p '{"spec":{"selector":{"app":"web","tier":"frontend"}}}'

# Verificar
kubectl get endpoints web-service
```

**Opción 3: Recrear el service**
```bash
kubectl delete svc web-service

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
    tier: frontend
  ports:
  - port: 80
    targetPort: 80
EOF
```

**Verificación**:
```bash
# Endpoints debe tener IP
kubectl get endpoints web-service

# Test conectividad
kubectl run test --image=busybox:1.28 -it --rm -- wget -O- http://web-service
```

</details>

---

### Escenario 3: Network Policy Blocking Traffic
**Situación**: Después de aplicar Network Policies, los pods no pueden comunicarse.

**Setup**:
```bash
# Crear dos pods
kubectl run frontend --image=nginx --labels=app=frontend
kubectl run backend --image=nginx --labels=app=backend

# Aplicar Network Policy muy restrictiva
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Test - debe fallar
kubectl exec frontend -- curl -m 5 backend
# Timeout
```

<details>
<summary>🔍 Diagnóstico</summary>

```bash
# 1. Listar Network Policies
kubectl get networkpolicies
kubectl describe networkpolicy deny-all

# 2. Ver qué pods están afectados
kubectl get pods --show-labels

# 3. Ver reglas de la policy
kubectl get networkpolicy deny-all -o yaml

# 4. Verificar que el CNI soporta Network Policies
kubectl get pods -n kube-system | grep -E "calico|cilium|weave"
# Si no hay CNI que soporte policies, no funcionarán

# 5. Test conectividad
kubectl exec frontend -- curl -m 5 backend
# connection timeout
```

</details>

<details>
<summary>✅ Solución</summary>

**Solución 1: Crear policy permisiva**
```bash
# Permitir egress desde frontend a backend
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-egress
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 80
  - to:  # Permitir DNS
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
EOF
```

**Solución 2: Eliminar policy restrictiva** (temporal):
```bash
kubectl delete networkpolicy deny-all
```

**Verificación**:
```bash
# Test conectividad
kubectl exec frontend -- curl -m 5 backend
# Debe funcionar ahora

# Ver políticas aplicadas
kubectl get networkpolicies
kubectl describe networkpolicy allow-frontend-to-backend
```

</details>

---

### Escenario 4: PersistentVolumeClaim Pending
**Situación**: Un PVC se queda en estado Pending indefinidamente.

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: nonexistent-storage-class
EOF
```

<details>
<summary>🔍 Diagnóstico</summary>

```bash
# 1. Ver estado del PVC
kubectl get pvc my-pvc
# STATUS: Pending

# 2. Describir para ver eventos
kubectl describe pvc my-pvc
# Events: no persistent volumes available for this claim and no storage class is set

# 3. Ver StorageClasses disponibles
kubectl get storageclass
kubectl get sc

# 4. Ver PersistentVolumes disponibles
kubectl get pv

# 5. Ver detalles del StorageClass solicitado
kubectl get sc nonexistent-storage-class
# Error: not found
```

</details>

<details>
<summary>✅ Soluciones</summary>

**Problema 1: StorageClass no existe**
```bash
# Ver SC disponibles
kubectl get sc

# Recrear PVC con SC válido
kubectl delete pvc my-pvc

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard  # o el SC default del cluster
EOF

# Verificar
kubectl get pvc my-pvc
# STATUS: Bound
```

**Problema 2: No hay PV disponible (sin dynamic provisioning)**
```bash
# Crear PV manualmente
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /mnt/data
  persistentVolumeReclaimPolicy: Retain
EOF

# El PVC debe bind automáticamente si es compatible
kubectl get pvc my-pvc
```

**Problema 3: Access Mode incompatible**
```bash
# Si hay PVs pero con access modes diferentes
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,ACCESS:.spec.accessModes

# Ajustar PVC al access mode disponible
kubectl delete pvc my-pvc

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteMany  # Ajustar según PVs disponibles
  resources:
    requests:
      storage: 5Gi
EOF
```

**Problema 4: Tamaño solicitado mayor al disponible**
```bash
# Ver capacidades disponibles
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,STATUS:.status.phase

# Ajustar size en PVC
kubectl delete pvc my-pvc

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi  # Menor tamaño
EOF
```

</details>

---

### Escenario 5: StatefulSet Volume Mount Issues
**Situación**: Un StatefulSet no puede iniciar porque falla el volume mount.

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "web"
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
      storageClassName: nonexistent-sc
EOF
```

<details>
<summary>🔍 Diagnóstico</summary>

```bash
# 1. Ver estado del StatefulSet
kubectl get statefulset web
# READY: 0/2

# 2. Ver pods
kubectl get pods -l app=web
# STATUS: Pending

# 3. Describir pods
kubectl describe pod web-0
# Events: persistentvolumeclaim "data-web-0" not found

# 4. Ver PVCs creados
kubectl get pvc
# STATUS: Pending (para data-web-0, data-web-1)

# 5. Ver por qué están Pending
kubectl describe pvc data-web-0
# StorageClass not found
```

</details>

<details>
<summary>✅ Solución</summary>

```bash
# El problema es el StorageClass

# Opción 1: Usar StorageClass válido
kubectl delete statefulset web
kubectl delete pvc data-web-0 data-web-1

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "web"
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
      storageClassName: standard  # SC válido
EOF

# Verificar
kubectl get statefulset web
kubectl get pods -l app=web
kubectl get pvc
```

**Opción 2: Crear PVs manualmente (sin dynamic provisioning)**
```bash
# Crear PVs para cada replica
for i in 0 1; do
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-web-$i
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /mnt/data-$i
  persistentVolumeReclaimPolicy: Retain
EOF
done

# Los PVCs deben bind automáticamente
kubectl get pvc
kubectl get pods -l app=web
```

</details>

---

### Escenario 6: Volume Permission Issues
**Situación**: Un pod está Running pero la aplicación no puede escribir en el volume.

**Setup**:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: writer-pod
spec:
  securityContext:
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: writer
    image: busybox:1.28
    command: ["sh", "-c", "while true; do echo $(date) >> /data/log.txt; sleep 5; done"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    hostPath:
      path: /mnt/readonly-dir  # Directorio con permisos restrictivos
EOF
```

<details>
<summary>🔍 Diagnóstico</summary>

```bash
# 1. Ver estado del pod
kubectl get pod writer-pod
# STATUS: Running pero logs mostrarán errores

# 2. Ver logs
kubectl logs writer-pod
# sh: can't create /data/log.txt: Permission denied

# 3. Exec al pod y verificar permisos
kubectl exec writer-pod -- ls -la /data
# drwxr-xr-x root root ...

# 4. Verificar user/group del container
kubectl exec writer-pod -- id
# uid=1000 gid=2000

# 5. Verificar SecurityContext
kubectl get pod writer-pod -o yaml | grep -A 10 securityContext
```

</details>

<details>
<summary>✅ Soluciones</summary>

**Solución 1: Ajustar permisos en el node** (hostPath):
```bash
# SSH al node donde corre el pod
NODE=$(kubectl get pod writer-pod -o jsonpath='{.spec.nodeName}')
ssh $NODE

# Cambiar permisos del directorio
sudo chown -R 1000:2000 /mnt/readonly-dir
sudo chmod -R 775 /mnt/readonly-dir

# Verificar
ls -la /mnt/readonly-dir
```

**Solución 2: Usar initContainer para arreglar permisos**:
```bash
kubectl delete pod writer-pod

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: writer-pod
spec:
  securityContext:
    fsGroup: 2000
  initContainers:
  - name: fix-perms
    image: busybox:1.28
    command: ["sh", "-c", "chmod -R 777 /data"]
    volumeMounts:
    - name: data
      mountPath: /data
  containers:
  - name: writer
    image: busybox:1.28
    securityContext:
      runAsUser: 1000
    command: ["sh", "-c", "while true; do echo $(date) >> /data/log.txt; sleep 5; done"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    hostPath:
      path: /mnt/readonly-dir
EOF
```

**Solución 3: Usar emptyDir (temporal)**:
```bash
kubectl delete pod writer-pod

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: writer-pod
spec:
  securityContext:
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: writer
    image: busybox:1.28
    command: ["sh", "-c", "while true; do echo $(date) >> /data/log.txt; sleep 5; done"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    emptyDir: {}  # emptyDir respeta fsGroup automáticamente
EOF
```

**Verificación**:
```bash
# Ver logs - no debe haber errores de permisos
kubectl logs writer-pod

# Verificar archivo creado
kubectl exec writer-pod -- cat /data/log.txt
```

</details>

---

### Escenario 7: Ingress Not Working
**Situación**: Ingress configurado pero no enruta tráfico.

**Setup** (requiere Ingress Controller instalado):
```bash
# Crear recursos
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  labels:
    app: myapp
spec:
  containers:
  - name: nginx
    image: nginx:1.21
---
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service-wrong  # ← Error: nombre incorrecto
            port:
              number: 80
EOF
```

<details>
<summary>🔍 Diagnóstico</summary>

```bash
# 1. Verificar Ingress Controller está corriendo
kubectl get pods -n ingress-nginx  # o el namespace correcto
# O para minikube
minikube addons list | grep ingress

# 2. Ver Ingress
kubectl get ingress app-ingress
kubectl describe ingress app-ingress
# Buscar en Events: Service "app-service-wrong" does not exist

# 3. Verificar Service existe
kubectl get svc app-service
kubectl get svc app-service-wrong
# Error: not found

# 4. Ver endpoints del Ingress
kubectl get ingress app-ingress -o yaml | grep -A 10 status

# 5. Test con curl (si tienes LoadBalancer IP)
INGRESS_IP=$(kubectl get ingress app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -H "Host: myapp.example.com" http://$INGRESS_IP
# 503 Service Temporarily Unavailable
```

</details>

<details>
<summary>✅ Solución</summary>

```bash
# Corregir nombre del service en Ingress
kubectl edit ingress app-ingress
# Cambiar:
#   backend:
#     service:
#       name: app-service-wrong
# Por:
#   backend:
#     service:
#       name: app-service

# O con patch
kubectl patch ingress app-ingress --type='json' -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/name", "value":"app-service"}]'

# Verificar
kubectl describe ingress app-ingress
# No debe haber errores en Events

# Test
INGRESS_IP=$(kubectl get ingress app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -H "Host: myapp.example.com" http://$INGRESS_IP
# Debe mostrar página de nginx
```

**Troubleshooting adicional del Ingress Controller**:
```bash
# Ver logs del controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Verificar configuración generada por el controller
kubectl exec -n ingress-nginx <ingress-controller-pod> -- cat /etc/nginx/nginx.conf | grep -A 20 myapp.example.com
```

</details>

---

### Escenario 8: Pod-to-Pod Communication Failure
**Situación**: Pods no pueden comunicarse entre sí por IP.

**Setup**:
```bash
kubectl run pod1 --image=nginx
kubectl run pod2 --image=busybox:1.28 -- sleep 3600

# Get IP de pod1
POD1_IP=$(kubectl get pod pod1 -o jsonpath='{.status.podIP}')

# Test desde pod2
kubectl exec pod2 -- wget -T 5 -O- http://$POD1_IP
# Timeout
```

<details>
<summary>🔍 Diagnóstico</summary>

```bash
# 1. Verificar CNI plugin está corriendo
kubectl get pods -n kube-system | grep -E "calico|flannel|weave|cilium"

# 2. Ver logs de CNI
kubectl logs -n kube-system -l k8s-app=calico-node  # o el CNI que uses

# 3. Verificar Network Policies
kubectl get networkpolicies --all-namespaces

# 4. Verificar routing en los nodes
# SSH a un node
ip route
# Debe haber rutas para los pod CIDR ranges

# 5. Verificar kube-proxy
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system -l k8s-app=kube-proxy | tail -50

# 6. Test básico de conectividad
kubectl exec pod2 -- ping -c 3 $POD1_IP
```

</details>

<details>
<summary>✅ Solución según causa</summary>

**Causa 1: CNI plugin no está corriendo**
```bash
# Reinstalar CNI (ejemplo: Calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Esperar a que los pods estén Ready
kubectl get pods -n kube-system -l k8s-app=calico-node -w
```

**Causa 2: Network Policy bloqueando**
```bash
# Temporalmente eliminar todas las policies
kubectl delete networkpolicies --all

# Test
kubectl exec pod2 -- wget -T 5 -O- http://$POD1_IP
```

**Causa 3: kube-proxy con problemas**
```bash
# Recrear kube-proxy pods
kubectl delete pods -n kube-system -l k8s-app=kube-proxy

# Verificar logs después de recrear
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

</details>

---

## 🧹 Limpieza

```bash
# Eliminar recursos de prueba
kubectl delete pod test-dns nginx-test test web-pod frontend backend app-pod pod1 pod2 writer-pod --ignore-not-found
kubectl delete svc web-service nginx-test app-service --ignore-not-found
kubectl delete networkpolicy deny-all allow-frontend-to-backend allow-frontend-egress --ignore-not-found
kubectl delete pvc my-pvc data-web-0 data-web-1 --ignore-not-found
kubectl delete statefulset web --ignore-not-found
kubectl delete ingress app-ingress --ignore-not-found
```

---

## 📊 Evaluación

- [ ] Escenario 1: DNS troubleshooting completado
- [ ] Escenario 2: Service endpoints resuelto
- [ ] Escenario 3: Network Policy diagnosticado
- [ ] Escenario 4: PVC Pending resuelto
- [ ] Escenario 5: StatefulSet storage resuelto
- [ ] Escenario 6: Volume permissions corregido
- [ ] Escenario 7: Ingress reparado
- [ ] Escenario 8: Pod comunicación resuelta

---

## 🎯 Comandos Críticos para CKA

### DNS
```bash
# Test DNS
kubectl run test-dns --image=busybox:1.28 -it --rm -- nslookup kubernetes.default
kubectl logs -n kube-system -l k8s-app=kube-dns
kubectl get cm -n kube-system coredns -o yaml
```

### Networking
```bash
# Services & Endpoints
kubectl get svc,endpoints
kubectl describe svc <name>

# Network Policies
kubectl get networkpolicies
kubectl describe networkpolicy <name>
```

### Storage
```bash
# PV/PVC
kubectl get pv,pvc
kubectl describe pvc <name>

# StorageClasses
kubectl get sc
```

---

## 💡 Tips para el Examen

1. **DNS siempre primero**: Si hay problemas de conectividad, verifica DNS
2. **Endpoints = conexión Service-Pod**: Si está vacío, el selector está mal
3. **Network Policies**: Recuerda que son whitelist, por defecto permiten todo
4. **PVC Pending**: Busca StorageClass, capacidad, access modes
5. **StatefulSets**: Los PVCs se crean automáticamente, uno por replica
6. **Permisos de volumes**: fsGroup y initContainers son tus amigos

---

**Tiempo objetivo**: 8-12 minutos por escenario  
**Siguiente**: [Lab 04 - Complete Cluster](./lab-04-complete-cluster.md)
