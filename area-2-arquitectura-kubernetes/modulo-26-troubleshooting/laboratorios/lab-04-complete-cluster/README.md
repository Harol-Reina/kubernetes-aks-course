# Laboratorio 04: Complete Cluster Troubleshooting - CKA Simulation

> **Duración estimada**: 90-120 minutos  
> **Dificultad**: ⭐⭐⭐⭐ (CKA Exam Level)  
> **Objetivos CKA**: All domains - Exam Simulation

## 📋 Objetivos de Aprendizaje

Este laboratorio simula escenarios complejos del examen CKA donde:
- ✅ Múltiples componentes fallan simultáneamente
- ✅ Los problemas están interrelacionados
- ✅ Debes priorizar bajo presión de tiempo
- ✅ Aplicar metodología sistemática
- ✅ Documentar soluciones

## ⚠️ Formato del Examen CKA

- **Duración**: 2 horas
- **Passing score**: 66%
- **Distribución aproximada**:
  - 25% Cluster Architecture, Installation & Configuration
  - 15% Workloads & Scheduling
  - 20% Services & Networking
  - 10% Storage
  - 30% Troubleshooting ← **Este lab**

## 🎯 Escenarios Complejos

### Escenario 1: Cluster Upgrade Failed - Multi-Component Failure
**Contexto**: Un upgrade del cluster falló a medias, dejando el cluster en estado inconsistente.

**Estado Inicial**:
- Control plane node: API server no responde
- Worker node 1: NotReady
- Worker node 2: Pods en CrashLoopBackOff
- DNS no funciona
- Deployments no escalan

**Tiempo estimado**: 25-30 minutos

<details>
<summary>🎯 Tareas Priorizadas</summary>

**Prioridad 1: Restaurar API Server** (8 min)
```bash
# 1. SSH al control plane
ssh control-plane

# 2. Verificar kubelet
sudo systemctl status kubelet
sudo journalctl -u kubelet -n 50 --no-pager

# 3. Verificar static pods
sudo ls -la /etc/kubernetes/manifests/
sudo crictl ps -a | grep kube-apiserver

# 4. Ver logs del API server (si existe container)
sudo crictl logs <apiserver-container-id> 2>&1 | tail -50

# 5. Verificar certificados
sudo kubeadm certs check-expiration

# Common issues:
# - Certificado expirado → kubeadm certs renew all
# - Manifest corrupto → restaurar desde backup
# - etcd no accesible → verificar etcd health
```

**Prioridad 2: Resolver Worker Node NotReady** (7 min)
```bash
# Desde master (una vez API funciona)
kubectl describe node worker-01 | grep -A 10 Conditions

# SSH al worker
ssh worker-01

# Verificar kubelet
sudo systemctl status kubelet
sudo systemctl start kubelet  # si está stopped

# Ver logs
sudo journalctl -u kubelet -n 100 | grep -i error

# Verificar CNI
ls -la /opt/cni/bin/
ls -la /etc/cni/net.d/

# Si falta CNI config, reinstalar desde master
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

**Prioridad 3: Resolver DNS** (5 min)
```bash
# Verificar CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Si no están corriendo
kubectl logs -n kube-system -l k8s-app=kube-dns

# Escalar si es necesario
kubectl scale deployment coredns -n kube-system --replicas=2

# Test
kubectl run test --image=busybox:1.28 -it --rm -- nslookup kubernetes.default
```

**Prioridad 4: Resolver CrashLoopBackOff en worker-02** (5 min)
```bash
# Listar pods con problema
kubectl get pods --all-namespaces | grep CrashLoopBackOff

# Para cada pod
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous

# Soluciones comunes:
# - Imagen incorrecta → kubectl set image
# - ConfigMap faltante → kubectl create configmap
# - Resource limits → ajustar resources
```

</details>

<details>
<summary>✅ Procedimiento Completo</summary>

**Paso 1: Diagnóstico rápido (2 min)**
```bash
# Intentar kubectl
kubectl get nodes
# Si falla → API server issue

# Si funciona, ver estado general
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running
kubectl get componentstatuses  # deprecated pero útil
```

**Paso 2: Restaurar API Server (6 min)**
```bash
# SSH al control plane
ssh control-plane

# Verificar kubelet primero (maneja static pods)
sudo systemctl status kubelet

# Si está failed
sudo systemctl start kubelet
sudo journalctl -u kubelet -n 50

# Verificar manifests de static pods
sudo ls -la /etc/kubernetes/manifests/
# Debe tener: etcd.yaml, kube-apiserver.yaml, kube-controller-manager.yaml, kube-scheduler.yaml

# Ver si hay archivos .yaml.backup
sudo ls -la /etc/kubernetes/manifests/*.backup

# Si kube-apiserver.yaml tiene errores
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml.broken
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Revisar syntax, indentación, certificados

# Verificar certificados
sudo kubeadm certs check-expiration
# Si expiró
sudo kubeadm certs renew all
sudo systemctl restart kubelet

# Esperar a que API server levante
kubectl get nodes -w
```

**Paso 3: Resolver Node NotReady (5 min)**
```bash
# Ver detalles
kubectl describe node worker-01

# SSH al node
ssh worker-01

# Verificar kubelet
sudo systemctl status kubelet
sudo systemctl start kubelet

# Ver logs
sudo journalctl -u kubelet -f

# Problemas comunes:
# 1. CNI faltante
sudo ls /opt/cni/bin/
sudo ls /etc/cni/net.d/
# Reinstalar CNI desde master si falta

# 2. Certificados
sudo ls -la /var/lib/kubelet/pki/
# Regenerar si es necesario

# 3. Disk pressure
df -h
sudo crictl rmi --prune  # limpiar imágenes

# Verificar en master
kubectl get nodes  # Debe estar Ready
```

**Paso 4: Resolver DNS (4 min)**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Si Pending o CrashLoopBackOff
kubectl describe pod -n kube-system -l k8s-app=kube-dns

# Ver logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Escalar si es necesario
kubectl scale deployment coredns -n kube-system --replicas=2

# Verificar ConfigMap
kubectl get cm coredns -n kube-system -o yaml

# Test
kubectl run test-dns --image=busybox:1.28 --rm -it -- nslookup kubernetes.default
```

**Paso 5: Resolver Pods en CrashLoopBackOff (8 min)**
```bash
# Listar todos
kubectl get pods --all-namespaces -o wide | grep -E "CrashLoopBackOff|Error"

# Para cada pod problemático
POD_NAME=<pod-name>
NAMESPACE=<namespace>

kubectl describe pod $POD_NAME -n $NAMESPACE
kubectl logs $POD_NAME -n $NAMESPACE
kubectl logs $POD_NAME -n $NAMESPACE --previous

# Diagnóstico según logs:
# - Exit code 137 → OOMKilled → aumentar memory limits
# - Exit code 1 → error de aplicación → revisar config/secrets/configmaps
# - ImagePullBackOff → corregir imagen

# Ejemplo: Si falta ConfigMap
kubectl create configmap app-config --from-literal=KEY=VALUE -n $NAMESPACE

# Ejemplo: Si OOMKilled
kubectl set resources deployment/<name> -n $NAMESPACE --limits=memory=512Mi
```

**Verificación Final (5 min)**
```bash
# 1. Todos los nodes Ready
kubectl get nodes
# STATUS: Ready para todos

# 2. Pods del sistema corriendo
kubectl get pods -n kube-system
# All Running

# 3. DNS funciona
kubectl run test --image=busybox:1.28 --rm -it -- nslookup kubernetes.default

# 4. Deployments escalan
kubectl create deployment test-nginx --image=nginx --replicas=3
kubectl get deployment test-nginx
# READY: 3/3

# 5. Limpiar test
kubectl delete deployment test-nginx
```

</details>

---

### Escenario 2: Security Breach - RBAC & Network Isolation
**Contexto**: Se detectó acceso no autorizado. Debes implementar seguridad estricta.

**Tareas**:
1. Auditar permisos actuales
2. Revocar acceso excesivo
3. Implementar Network Policies
4. Verificar no hay privilege escalation

**Tiempo estimado**: 20-25 minutos

<details>
<summary>✅ Solución Completa</summary>

**Paso 1: Auditar ServiceAccounts y permisos (5 min)**
```bash
# Listar todos los ServiceAccounts
kubectl get serviceaccounts --all-namespaces

# Ver bindings peligrosos
kubectl get clusterrolebindings -o json | \
  jq '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name'

# Auditar un SA específico
SA_NAME=<suspicious-sa>
NAMESPACE=<namespace>

# Ver qué puede hacer
kubectl auth can-i --list --as=system:serviceaccount:$NAMESPACE:$SA_NAME

# Ver bindings de este SA
kubectl get rolebindings,clusterrolebindings --all-namespaces -o json | \
  jq --arg sa "$SA_NAME" '.items[] | select(.subjects[]?.name==$sa)'
```

**Paso 2: Revocar permisos excesivos (5 min)**
```bash
# Eliminar ClusterRoleBinding peligroso
kubectl delete clusterrolebinding <dangerous-binding>

# Crear Role limitado
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: $NAMESPACE
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
EOF

# Crear RoleBinding
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: $SA_NAME
  namespace: $NAMESPACE
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF

# Verificar
kubectl auth can-i create pods --as=system:serviceaccount:$NAMESPACE:$SA_NAME
# Output: no
```

**Paso 3: Implementar Network Policies (10 min)**
```bash
# Default deny all
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Permitir solo tráfico necesario: frontend → backend
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
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
      port: 8080
EOF

# Permitir egress a DNS
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
EOF
```

**Paso 4: Verificar SecurityContext (5 min)**
```bash
# Buscar pods con privileged=true
kubectl get pods --all-namespaces -o json | \
  jq '.items[] | select(.spec.containers[]?.securityContext?.privileged==true) | .metadata.name'

# Buscar pods corriendo como root (sin runAsNonRoot)
kubectl get pods --all-namespaces -o json | \
  jq '.items[] | select(.spec.securityContext?.runAsNonRoot!=true) | .metadata.name'

# Corregir pod problemático
kubectl delete pod <privileged-pod>

# Recrear con SecurityContext apropiado
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    image: nginx:1.21
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
EOF
```

**Verificación**:
```bash
# Test RBAC
kubectl auth can-i create pods --as=system:serviceaccount:production:app-sa
# Should be: no

# Test Network Policy
kubectl run test-outside -n default --image=busybox:1.28 --rm -it -- \
  wget -T 5 -O- http://backend-service.production
# Should timeout

kubectl run test-inside -n production --labels=app=frontend --image=busybox:1.28 --rm -it -- \
  wget -T 5 -O- http://backend-service
# Should work
```

</details>

---

### Escenario 3: Performance Degradation - Resource Exhaustion
**Contexto**: El cluster está lento, algunos pods son evicted, nodes bajo presión.

**Síntomas**:
- Pods en Pending (insufficient resources)
- Pods evicted (DiskPressure, MemoryPressure)
- API server slow
- High CPU usage

**Tiempo estimado**: 20-25 minutos

<details>
<summary>✅ Solución Completa</summary>

**Paso 1: Identificar recursos más consumidos (5 min)**
```bash
# Top nodes
kubectl top nodes
# Ver CPU% y MEMORY%

# Top pods
kubectl top pods --all-namespaces --sort-by=memory
kubectl top pods --all-namespaces --sort-by=cpu

# Ver pods evicted
kubectl get pods --all-namespaces | grep Evicted

# Describir pods evicted para ver causa
kubectl describe pod <evicted-pod> -n <namespace>
# Ver Reason: Evicted, Message: ... DiskPressure o MemoryPressure
```

**Paso 2: Analizar requests vs limits (5 min)**
```bash
# Ver todos los resources del cluster
kubectl describe nodes | grep -A 10 "Allocated resources"

# Pods sin limits (peligrosos - pueden consumir todo)
kubectl get pods --all-namespaces -o json | \
  jq '.items[] | select(.spec.containers[].resources.limits==null) | .metadata.name'

# Deployments sin resource requests/limits
kubectl get deployments --all-namespaces -o json | \
  jq '.items[] | select(.spec.template.spec.containers[].resources==null) | .metadata.name'
```

**Paso 3: Implementar ResourceQuotas y LimitRanges (5 min)**
```bash
# ResourceQuota para namespace
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
  namespace: production
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    pods: "50"
EOF

# LimitRange para defaults
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: production
spec:
  limits:
  - default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
EOF

# Verificar
kubectl describe resourcequota -n production
kubectl describe limitrange -n production
```

**Paso 4: Escalar o eliminar pods problemáticos (5 min)**
```bash
# Identificar deployment que consume mucho
TOP_CONSUMER=$(kubectl top pods --all-namespaces --sort-by=memory | head -2 | tail -1 | awk '{print $2}')

# Ver deployment de ese pod
kubectl get pod $TOP_CONSUMER -o jsonpath='{.metadata.ownerReferences[0].name}'

# Escalar down si es necesario
kubectl scale deployment <high-consumer> --replicas=1

# O ajustar resources
kubectl set resources deployment <name> \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=512Mi
```

**Paso 5: Limpiar disco en nodes (5 min)**
```bash
# SSH a node con DiskPressure
NODE=$(kubectl get nodes -o json | jq -r '.items[] | select(.status.conditions[] | select(.type=="DiskPressure" and .status=="True")) | .metadata.name')
ssh $NODE

# Ver uso de disco
df -h

# Limpiar imágenes no usadas
sudo crictl rmi --prune

# Limpiar contenedores stopped
sudo crictl rm $(sudo crictl ps -a -q --state=exited)

# Limpiar logs grandes
sudo journalctl --vacuum-size=100M
sudo find /var/log/pods -name "*.log" -size +100M -delete

# Verificar espacio liberado
df -h

# En master, verificar node
kubectl describe node $NODE | grep DiskPressure
# DiskPressure: False
```

**Paso 6: Implementar PriorityClasses (5 min)**
```bash
# Crear PriorityClasses
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "High priority for critical apps"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100
globalDefault: true
description: "Low priority for non-critical apps"
EOF

# Asignar a deployments críticos
kubectl patch deployment critical-app -p \
  '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
```

**Verificación**:
```bash
# Todos los nodes sin pressure
kubectl get nodes -o json | \
  jq '.items[] | {name: .metadata.name, conditions: [.status.conditions[] | select(.type | contains("Pressure"))]}'

# No hay pods evicted
kubectl get pods --all-namespaces | grep -c Evicted
# Output: 0

# ResourceQuotas activos
kubectl get resourcequotas --all-namespaces
```

</details>

---

### Escenario 4: StatefulSet Data Loss - Recovery
**Contexto**: Un StatefulSet crítico (base de datos) tiene pods que no inician después de un reinicio del node.

**Síntomas**:
- Pods en Pending (waiting for volume to be attached)
- PVCs en estado Bound pero pods no inician
- Data directory mount failures

**Tiempo estimado**: 15-20 minutos

<details>
<summary>✅ Solución Completa</summary>

**Paso 1: Diagnóstico (5 min)**
```bash
# Ver StatefulSet
kubectl get statefulset postgres-db
# READY: 0/3

# Ver pods
kubectl get pods -l app=postgres-db
# STATUS: Pending o ContainerCreating

# Describir pod
kubectl describe pod postgres-db-0
# Events: FailedAttachVolume, FailedMount, etc.

# Ver PVCs
kubectl get pvc -l app=postgres-db
# STATUS: Bound (pero pod no puede usar)

# Ver PVs
kubectl get pv

# Ver StorageClass
kubectl get sc
```

**Paso 2: Identificar problema (5 min)**
```bash
# Problema común 1: Volume stuck attached a node down
kubectl describe pv <pv-name>
# Ver Node Affinity

# Ver eventos del namespace
kubectl get events --sort-by='.lastTimestamp' | grep postgres-db

# Problema común 2: CSI driver issues
kubectl get pods -n kube-system | grep csi

# Logs del CSI driver
kubectl logs -n kube-system <csi-driver-pod>
```

**Paso 3: Forzar detach del volume (si aplica)**
```bash
# Si el volume está stuck en un node que ya no existe
kubectl get pv <pv-name> -o yaml | grep claimRef -A 10

# Eliminar el pod (será recreado por StatefulSet)
kubectl delete pod postgres-db-0 --force --grace-period=0

# Si sigue stuck, patch el PV para remover node affinity
kubectl patch pv <pv-name> -p '{"spec":{"nodeAffinity":null}}'
```

**Paso 4: Resolver permisos de montaje (si aplica)**
```bash
# Ver logs del pod si llega a crear
kubectl logs postgres-db-0

# Si hay error de permisos (Permission denied en data dir)
# Usar initContainer para fix
kubectl edit statefulset postgres-db

# Agregar:
spec:
  template:
    spec:
      initContainers:
      - name: fix-perms
        image: busybox:1.28
        command: ["sh", "-c", "chown -R 999:999 /var/lib/postgresql/data && chmod -R 700 /var/lib/postgresql/data"]
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
```

**Paso 5: Recrear StatefulSet si es necesario**
```bash
# Backup de datos (si es posible acceder al PV)
# Esto requiere acceso al storage backend

# Scale down a 0
kubectl scale statefulset postgres-db --replicas=0

# Esperar a que todos terminen
kubectl get pods -l app=postgres-db -w

# Eliminar PVCs problemáticos (CUIDADO - solo si tienes backup)
# kubectl delete pvc data-postgres-db-0

# Scale up
kubectl scale statefulset postgres-db --replicas=3

# Verificar que pods inician
kubectl get pods -l app=postgres-db -w
```

**Verificación**:
```bash
# Todos los pods Running
kubectl get pods -l app=postgres-db
# STATUS: Running para todos

# Todos los PVCs Bound
kubectl get pvc -l app=postgres-db
# STATUS: Bound para todos

# Test conectividad a DB
kubectl run psql-client --image=postgres:13 --rm -it -- \
  psql -h postgres-db-0.postgres-db -U postgres -c "SELECT 1;"
```

</details>

---

### Escenario 5: Complete Disaster Recovery
**Contexto**: etcd corrupto, necesitas restore desde backup.

**Tiempo estimado**: 20-25 minutos

<details>
<summary>✅ Solución Completa</summary>

**Prerequisito: Tener backup de etcd**
```bash
# En control plane, hacer backup primero (si es posible)
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /backup/etcd-snapshot-$(date +%Y%m%d).db

# Verificar snapshot
sudo ETCDCTL_API=3 etcdctl --write-out=table \
  snapshot status /backup/etcd-snapshot-*.db
```

**Paso 1: Detener todos los componentes del control plane (3 min)**
```bash
# Mover manifests fuera
sudo mv /etc/kubernetes/manifests/*.yaml /tmp/

# Verificar que los static pods se detuvieron
sudo crictl ps
# No debe haber kube-apiserver, etcd, etc.

# Alternativamente (más drástico)
sudo systemctl stop kubelet
```

**Paso 2: Restore etcd (5 min)**
```bash
# Restore desde snapshot
sudo ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot-*.db \
  --data-dir=/var/lib/etcd-restore \
  --name=master \
  --initial-cluster=master=https://127.0.0.1:2380 \
  --initial-advertise-peer-urls=https://127.0.0.1:2380

# Backup del etcd data dir actual
sudo mv /var/lib/etcd /var/lib/etcd-old-$(date +%Y%m%d)

# Mover restored data al lugar correcto
sudo mv /var/lib/etcd-restore /var/lib/etcd

# Ajustar permisos
sudo chown -R root:root /var/lib/etcd
```

**Paso 3: Actualizar manifest de etcd (si es necesario)**
```bash
# Verificar que el data dir en el manifest es correcto
sudo cat /tmp/etcd.yaml | grep -A 2 "hostPath"
# path: /var/lib/etcd

# Si cambiaste el path, editar
sudo vi /tmp/etcd.yaml
```

**Paso 4: Iniciar componentes del control plane (5 min)**
```bash
# Mover manifests de vuelta
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-controller-manager.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/

# Si detuviste kubelet, iniciarlo
sudo systemctl start kubelet

# Verificar que los static pods inician
watch sudo crictl ps
```

**Paso 5: Verificar cluster (7 min)**
```bash
# Esperar a que API server esté disponible (puede tomar 1-2 min)
kubectl get nodes
# Si da error de conexión, esperar más

# Verificar componentes
kubectl get pods -n kube-system
# Todos deben estar Running

# Verificar nodes
kubectl get nodes
# Todos Ready

# Verificar datos restaurados
kubectl get deployments --all-namespaces
kubectl get pods --all-namespaces
kubectl get pv,pvc

# Si hay pods en estado problemático después del restore
kubectl delete pod --all-namespaces --field-selector=status.phase!=Running --force --grace-period=0
```

**Paso 6: Verificar integridad (5 min)**
```bash
# Test API funciona
kubectl api-resources

# Test creación de recursos
kubectl run test-restore --image=nginx
kubectl get pod test-restore
kubectl delete pod test-restore

# Verificar etcd health
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Verificar member list
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

</details>

---

## 📊 CKA Exam Simulation - Full Practice

**Tiempo total**: 120 minutos  
**Passing score**: 4/5 escenarios completos

### Scoring Rubric

| Escenario | Puntos | Criterios de Éxito |
|-----------|--------|--------------------|
| 1. Multi-Component Failure | 25 | API funcionando, nodes Ready, DNS OK, pods no crashing |
| 2. Security Breach | 20 | RBAC limitado, Network Policies activas, no privileged pods |
| 3. Performance Issues | 20 | No evictions, ResourceQuotas activos, disk pressure resuelto |
| 4. StatefulSet Recovery | 15 | Pods Running, PVCs Bound, data accesible |
| 5. Disaster Recovery | 20 | etcd restaurado, cluster funcional, datos recuperados |

**Total**: 100 puntos  
**Passing**: 66+ puntos

---

## 🎯 Checklist Final - Pre-Exam

Antes del examen CKA, asegúrate de poder hacer sin documentación:

**Control Plane**:
- [ ] Diagnosticar API server down
- [ ] Renovar certificados con kubeadm
- [ ] Backup y restore de etcd
- [ ] Ver logs de kubelet con journalctl

**Nodes**:
- [ ] Resolver node NotReady
- [ ] Diagnosticar kubelet issues
- [ ] Limpiar disk pressure
- [ ] Reinstalar CNI plugin

**Pods**:
- [ ] Diagnosticar CrashLoopBackOff (logs, describe, events)
- [ ] Resolver ImagePullBackOff
- [ ] Fix OOMKilled (adjust limits)
- [ ] Resolver init container failures

**Networking**:
- [ ] Troubleshoot DNS (CoreDNS)
- [ ] Fix service without endpoints
- [ ] Create/debug Network Policies
- [ ] Test pod-to-pod connectivity

**Storage**:
- [ ] Resolver PVC Pending
- [ ] Fix volume mount issues
- [ ] Troubleshoot StatefulSet storage
- [ ] Adjust volume permissions

**RBAC**:
- [ ] Audit ServiceAccount permissions
- [ ] Create Role/RoleBinding
- [ ] Test with kubectl auth can-i
- [ ] Fix privilege escalation

**Performance**:
- [ ] Use kubectl top (nodes, pods)
- [ ] Create ResourceQuota
- [ ] Create LimitRange
- [ ] Set resource requests/limits

---

## 💡 Time Management Tips

**Si tienes 30 min para un problema complejo**:
- 2 min: Read and understand the problem
- 3 min: Quick diagnosis (kubectl get, describe)
- 20 min: Implement solution
- 5 min: Verify and test

**Priorización en el examen**:
1. **Quick wins primero**: Problemas simples que conoces bien
2. **Alto valor**: Problemas con muchos puntos
3. **Skip temporalmente**: Si estás stuck >10 min, marca y continúa

**Comandos que DEBES memorizar**:
```bash
# Shortcuts
alias k=kubectl
alias kgp='kubectl get pods'
alias kd='kubectl describe'
alias kg='kubectl get'

# Essential commands
kubectl get nodes
kubectl describe node <name>
kubectl get pods -A
kubectl describe pod <name> -n <namespace>
kubectl logs <pod> -n <namespace> --previous
kubectl top nodes
kubectl top pods -A --sort-by=memory
sudo journalctl -u kubelet -n 100
sudo crictl ps
sudo crictl logs <id>
```

---

**Siguiente**: [Volver al README principal](../README.md)
