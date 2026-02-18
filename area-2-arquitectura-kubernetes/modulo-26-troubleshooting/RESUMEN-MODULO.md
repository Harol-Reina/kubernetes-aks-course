# Resumen: Troubleshooting Avanzado - Cheatsheet CKA

> 📋 **Guía rápida de troubleshooting para el examen CKA**  
> ⏱️ **25-30% del examen** - El dominio más importante  
> 🎯 **Objetivo**: Diagnosticar y resolver problemas bajo presión de tiempo

---

## 🚨 Comandos Esenciales (Memorizar)

### Información General

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
kubectl get events --sort-by='.lastTimestamp'

# Componentes del sistema
kubectl get pods -n kube-system
kubectl get cs  # component status (deprecated but useful)

# Versión
kubectl version --short
```

### Pods y Containers

```bash
# Estado de pods
kubectl get pods
kubectl get pods -o wide
kubectl get pods --all-namespaces
kubectl describe pod <pod-name>

# Logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous  # Container anterior (crashed)
kubectl logs <pod-name> --tail=100
kubectl logs <pod-name> -f  # Follow

# Ejecutar comandos
kubectl exec <pod-name> -- <command>
kubectl exec -it <pod-name> -- sh
kubectl exec -it <pod-name> -c <container-name> -- sh

# Debug (Kubernetes 1.23+)
kubectl debug <pod-name> -it --image=busybox
kubectl debug node/<node-name> -it --image=ubuntu
```

### Nodes

```bash
# Estado de nodos
kubectl get nodes
kubectl describe node <node-name>
kubectl top nodes  # Requiere metrics-server

# Taints y cordoning
kubectl describe nodes | grep Taints
kubectl cordon <node-name>
kubectl uncordon <node-name>
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

### Services y Networking

```bash
# Services
kubectl get svc
kubectl describe svc <service-name>
kubectl get endpoints <service-name>

# DNS
kubectl run dnstest --image=busybox:1.28 -it --rm -- nslookup kubernetes.default

# Network Policies
kubectl get networkpolicy
kubectl describe networkpolicy <policy-name>

# Ingress
kubectl get ingress
kubectl describe ingress <ingress-name>
```

### Storage

```bash
# PV y PVC
kubectl get pv
kubectl get pvc
kubectl describe pvc <pvc-name>
kubectl describe pv <pv-name>

# StorageClasses
kubectl get sc
kubectl describe sc <storage-class-name>
```

### RBAC

```bash
# Verificar permisos
kubectl auth can-i create pods
kubectl auth can-i get secrets --as=user@example.com
kubectl auth can-i --list --as=system:serviceaccount:default:my-sa

# Roles
kubectl get roles,rolebindings
kubectl get clusterroles,clusterrolebindings
kubectl describe role <role-name>
```

### Events y Logs

```bash
# Events
kubectl get events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events --field-selector type=Warning
kubectl get events --field-selector involvedObject.name=<pod-name>
kubectl get events -w  # Watch

# Logs de componentes (kubeadm)
kubectl logs -n kube-system kube-apiserver-<node-name>
kubectl logs -n kube-system kube-scheduler-<node-name>
kubectl logs -n kube-system kube-controller-manager-<node-name>
kubectl logs -n kube-system etcd-<node-name>

# En nodo (systemd)
sudo journalctl -u kubelet -f
sudo journalctl -u docker -f
sudo journalctl -u containerd -f
```

---

## 🔍 Árboles de Decisión por Síntoma

### Pod en "Pending"

```
PENDING
│
├─ kubectl describe pod <name>
│
└─ Posibles Causas:
   │
   ├─ Recursos Insuficientes
   │  ├─ Check: kubectl describe nodes | grep -A 5 "Allocated"
   │  └─ Fix: Escalar cluster O reducir requests
   │
   ├─ Node Selector/Affinity
   │  ├─ Check: kubectl get nodes --show-labels
   │  └─ Fix: Agregar labels a nodes O cambiar pod spec
   │
   ├─ Taints
   │  ├─ Check: kubectl describe nodes | grep Taints
   │  └─ Fix: Agregar tolerations O quitar taints
   │
   └─ PVC no bound
      ├─ Check: kubectl get pvc
      └─ Fix: Crear PV O fix StorageClass
```

### Pod en "CrashLoopBackOff"

```
CrashLoopBackOff
│
├─ kubectl logs <pod> --previous
│
└─ Posibles Causas:
   │
   ├─ Application Error
   │  ├─ Check: Logs
   │  └─ Fix: Debug código
   │
   ├─ Missing ConfigMap/Secret
   │  ├─ Check: kubectl get cm,secret
   │  └─ Fix: Crear recursos
   │
   ├─ Liveness Probe Failing
   │  ├─ Check: kubectl describe pod | grep Liveness
   │  └─ Fix: Ajustar probe O fix endpoint
   │
   ├─ OOMKilled
   │  ├─ Check: kubectl describe pod | grep "Last State"
   │  └─ Fix: Aumentar memory limits
   │
   └─ Command/Args Incorrectos
      ├─ Check: kubectl get pod <name> -o yaml | grep command
      └─ Fix: Corregir deployment
```

### Pod en "ImagePullBackOff"

```
ImagePullBackOff
│
├─ kubectl describe pod <name>
│
└─ Posibles Causas:
   │
   ├─ Image No Existe
   │  ├─ Check: Verificar en registry
   │  └─ Fix: Corregir image name/tag
   │
   ├─ Requiere Autenticación
   │  ├─ Check: kubectl get secret
   │  └─ Fix: Crear imagePullSecrets
   │
   ├─ Network Issues
   │  ├─ Check: DNS, firewall
   │  └─ Fix: Configurar acceso
   │
   └─ Rate Limiting
      └─ Fix: Usar auth O mirror
```

### Service No Funciona

```
Service not working
│
├─ kubectl get svc <name>
├─ kubectl get endpoints <name>
│
└─ Posibles Causas:
   │
   ├─ No Endpoints
   │  ├─ Check: kubectl get pods -l <selector>
   │  └─ Fix: Labels mismatch O pods no ready
   │
   ├─ Port Incorrecto
   │  ├─ Check: targetPort vs containerPort
   │  └─ Fix: Corregir service spec
   │
   ├─ Network Policy
   │  ├─ Check: kubectl get netpol
   │  └─ Fix: Ajustar policy
   │
   └─ kube-proxy Issues
      ├─ Check: kubectl logs -n kube-system <kube-proxy-pod>
      └─ Fix: Restart kube-proxy
```

### Node "NotReady"

```
Node NotReady
│
├─ kubectl describe node <name>
│
└─ Posibles Causas:
   │
   ├─ kubelet not running
   │  ├─ SSH: sudo systemctl status kubelet
   │  └─ Fix: sudo systemctl restart kubelet
   │
   ├─ CNI Plugin Failed
   │  ├─ Check: kubectl get pods -n kube-system | grep cni
   │  └─ Fix: Re-apply CNI manifest
   │
   ├─ Disk Pressure
   │  ├─ Check: df -h
   │  └─ Fix: Limpiar espacio
   │
   └─ Certificate Expired
      ├─ Check: sudo kubeadm certs check-expiration
      └─ Fix: sudo kubeadm certs renew all
```

### DNS No Funciona

```
DNS Issues
│
├─ kubectl run test --image=busybox:1.28 -it --rm -- nslookup kubernetes.default
│
└─ Posibles Causas:
   │
   ├─ CoreDNS Not Running
   │  ├─ Check: kubectl get pods -n kube-system -l k8s-app=kube-dns
   │  └─ Fix: kubectl scale deployment coredns -n kube-system --replicas=2
   │
   ├─ CoreDNS Crashes
   │  ├─ Check: kubectl logs -n kube-system -l k8s-app=kube-dns
   │  └─ Fix: Check loop detection, resources
   │
   ├─ Service ClusterIP Wrong
   │  ├─ Check: kubectl get svc -n kube-system kube-dns
   │  └─ Fix: Verify 10.96.0.10 (default)
   │
   └─ Pod DNS Config Wrong
      ├─ Check: kubectl exec <pod> -- cat /etc/resolv.conf
      └─ Fix: Verify nameserver points to CoreDNS
```

---

## ⚡ Troubleshooting Rápido

### Workflow de 60 Segundos

```bash
# 1. Identificar el problema (10 segundos)
kubectl get pods
kubectl get nodes

# 2. Describir el recurso (20 segundos)
kubectl describe pod <pod-name>
# Leer Events section al final

# 3. Ver logs (20 segundos)
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# 4. Verificar configuración (10 segundos)
kubectl get pod <pod-name> -o yaml | grep -A 10 "containers:\|volumes:\|env:"
```

### Checklist Layer-by-Layer

**Layer 1: Pod/Container**
```bash
□ kubectl get pod <name>                    # Estado?
□ kubectl describe pod <name>               # Events?
□ kubectl logs <name>                       # Application errors?
□ kubectl get pod <name> -o yaml            # Config correcta?
```

**Layer 2: Service/Network**
```bash
□ kubectl get svc <name>                    # Service existe?
□ kubectl get endpoints <name>              # Tiene endpoints?
□ kubectl get pods -l <selector>            # Pods con labels?
□ kubectl exec <pod> -- curl <svc>          # Conectividad?
```

**Layer 3: Node**
```bash
□ kubectl get nodes                         # Node Ready?
□ kubectl describe node <name>              # Conditions OK?
□ kubectl top node <name>                   # Resources disponibles?
□ ssh <node> && sudo systemctl status kubelet  # kubelet running?
```

**Layer 4: Control Plane**
```bash
□ kubectl get pods -n kube-system           # Componentes running?
□ kubectl logs -n kube-system <component>   # Errors en logs?
□ kubectl get cs                            # Component status?
□ kubectl cluster-info                      # API accesible?
```

---

## 🛠️ Comandos por Categoría

### Debugging Pods

```bash
# Pod debug pod
kubectl run netshoot --image=nicolaka/netshoot -it --rm -- bash
kubectl run busybox --image=busybox:1.28 -it --rm -- sh

# Port forward para testing
kubectl port-forward pod/<pod> 8080:80
kubectl port-forward svc/<svc> 8080:80

# Copiar archivos
kubectl cp <pod>:/path/to/file ./local-file
kubectl cp ./local-file <pod>:/path/to/file

# Ver variables de entorno
kubectl exec <pod> -- env

# Ver filesystem
kubectl exec <pod> -- ls -la /app
kubectl exec <pod> -- cat /etc/config/app.conf
```

### Debugging Network

```bash
# Test DNS
kubectl run dnstest --image=busybox:1.28 -it --rm -- nslookup kubernetes.default
kubectl run dnstest --image=busybox:1.28 -it --rm -- nslookup <service>.<namespace>.svc.cluster.local

# Test conectividad pod-to-pod
kubectl exec <pod-a> -- ping <pod-b-ip>
kubectl exec <pod-a> -- wget -O- http://<pod-b-ip>:8080

# Test service
kubectl exec <pod> -- curl http://<service-name>:<port>

# Ver iptables (en nodo)
sudo iptables-save | grep <service-name>
sudo ipvsadm -ln  # Si kube-proxy usa ipvs
```

### Debugging Storage

```bash
# PVC status
kubectl get pvc
kubectl describe pvc <pvc-name>

# PV status
kubectl get pv
kubectl describe pv <pv-name>

# Ver mounts en pod
kubectl exec <pod> -- df -h
kubectl exec <pod> -- mount | grep /data

# Ver en nodo
ssh <node>
sudo lsblk
sudo mount | grep <volume-id>
```

### Debugging RBAC

```bash
# Test permissions
kubectl auth can-i create pods
kubectl auth can-i create pods --as=user@example.com
kubectl auth can-i create pods --as=system:serviceaccount:default:mysa

# List all permissions
kubectl auth can-i --list
kubectl auth can-i --list --as=system:serviceaccount:default:mysa

# Ver roles
kubectl get roles,rolebindings -n <namespace>
kubectl describe role <role-name>
kubectl describe rolebinding <binding-name>

# Ver service account
kubectl get sa
kubectl describe sa <sa-name>
kubectl get secret | grep <sa-name>
```

---

## 🚑 Errores Comunes y Soluciones

### CrashLoopBackOff

**Causas:**
- Application crash
- Missing dependencies (CM, Secret)
- Liveness probe too aggressive
- OOMKilled

**Diagnóstico:**
```bash
kubectl logs <pod> --previous
kubectl describe pod <pod> | grep -A 10 "Last State"
kubectl get pod <pod> -o yaml | grep -A 10 livenessProbe
```

**Fix:**
```yaml
# Aumentar initialDelaySeconds
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30  # Era 5
  periodSeconds: 10
  failureThreshold: 3
```

### ImagePullBackOff

**Causas:**
- Image no existe
- Typo en image name/tag
- Private registry sin credentials
- Network issues

**Diagnóstico:**
```bash
kubectl describe pod <pod> | grep -A 5 "Events"
# "Failed to pull image" o "manifest unknown"
```

**Fix:**
```bash
# Verificar image
docker pull <image>

# Para private registry
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<user> \
  --docker-password=<pass> \
  --docker-email=<email>

# En pod spec
spec:
  imagePullSecrets:
  - name: regcred
```

### OOMKilled (Exit Code 137)

**Diagnóstico:**
```bash
kubectl describe pod <pod> | grep -A 5 "Last State"
# Reason: OOMKilled
# Exit Code: 137

kubectl top pod <pod> --containers
```

**Fix:**
```yaml
resources:
  limits:
    memory: "512Mi"  # Aumentar de 128Mi
  requests:
    memory: "256Mi"
```

### Service Sin Endpoints

**Causas:**
- Label selector no coincide
- Pods no están ready
- Pods no existen

**Diagnóstico:**
```bash
kubectl get endpoints <service>
# Si está vacío:

kubectl get svc <service> -o jsonpath='{.spec.selector}'
kubectl get pods --show-labels
```

**Fix:**
```bash
# Corregir labels del pod para que coincidan con selector
kubectl label pod <pod> app=myapp
```

### Node NotReady

**Diagnóstico:**
```bash
kubectl describe node <node> | grep -A 10 Conditions

# SSH al nodo
ssh <node>
sudo systemctl status kubelet
sudo journalctl -u kubelet | tail -50
```

**Fix comunes:**
```bash
# Restart kubelet
sudo systemctl restart kubelet

# Disk pressure - limpiar
sudo crictl rmi --prune
sudo journalctl --vacuum-time=1d

# Certificate expired
sudo kubeadm certs check-expiration
sudo kubeadm certs renew all
sudo systemctl restart kubelet
```

### PVC en Pending

**Causas:**
- No hay PV disponible
- StorageClass no existe
- Access modes no coinciden

**Diagnóstico:**
```bash
kubectl describe pvc <pvc>
kubectl get pv
kubectl get sc
```

**Fix:**
```bash
# Crear PV manual
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-manual
spec:
  capacity:
    storage: 5Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /data/pv
EOF
```

### DNS No Funciona

**Diagnóstico:**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
kubectl run test --image=busybox:1.28 -it --rm -- nslookup kubernetes.default
```

**Fix:**
```bash
# Si CoreDNS está crashed
kubectl scale deployment coredns -n kube-system --replicas=0
kubectl scale deployment coredns -n kube-system --replicas=2

# Si hay loop detection
kubectl edit cm coredns -n kube-system
# Cambiar forward . /etc/resolv.conf
# Por:     forward . 8.8.8.8
```

---

## 📊 Exit Codes y Sus Significados

| Exit Code | Significado | Causa Común |
|-----------|-------------|-------------|
| 0 | Success | Container terminó correctamente |
| 1 | Application Error | Error genérico en aplicación |
| 2 | Misuse of shell builtin | Comando shell incorrecto |
| 126 | Command cannot execute | Permisos o comando no ejecutable |
| 127 | Command not found | Comando no existe |
| 128 | Invalid exit code | Exit code fuera de rango |
| 130 | Terminated by Ctrl+C | SIGINT (2) |
| 137 | **OOMKilled** | Out of Memory (SIGKILL 9) |
| 139 | Segmentation Fault | SIGSEGV (11) |
| 143 | Graceful Termination | SIGTERM (15) |
| 255 | Exit status out of range | - |

**Uso:**
```bash
kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'
```

---

## 🎯 Tips para el Examen CKA

### Time Management

- ⏱️ **2 horas** para ~15-20 preguntas
- ⏱️ Troubleshooting: **6-8 minutos** por pregunta
- ⏱️ Si te atascas **>5 minutos**: marca y continúa
- ⏱️ Las preguntas valen diferente: prioriza las de más puntos

### Estrategia General

1. **Lee completo** antes de empezar
2. **Identifica el layer** rápidamente
3. **kubectl describe/logs** siempre primero
4. **Verifica lo obvio**: typos, labels, ports
5. **No asumas**: verifica todo
6. **Documenta cambios** si necesitas volver

### Alias Útiles (Configurar al inicio)

```bash
# En el examen, configura esto primero
alias k=kubectl
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kex='kubectl exec -it'

export do="--dry-run=client -o yaml"
export now="--force --grace-period=0"
```

### Comandos Must-Know

**Top 10 para troubleshooting:**
```bash
1. kubectl get pods -A
2. kubectl describe pod <name>
3. kubectl logs <name> --previous
4. kubectl get events --sort-by='.lastTimestamp'
5. kubectl exec -it <name> -- sh
6. kubectl get nodes
7. kubectl describe node <name>
8. kubectl get svc
9. kubectl get endpoints <name>
10. kubectl top pods/nodes
```

### Verificación Rápida

Después de cada fix:
```bash
# 1. Verificar recurso está OK
kubectl get pod <name>

# 2. Verificar no hay errors en events
kubectl describe pod <name> | tail -20

# 3. Verificar logs si es aplicación
kubectl logs <name>

# 4. Test funcionalidad si es posible
kubectl exec <pod> -- curl http://service
```

### Common Mistakes en Examen

❌ **NO HACER:**
- Editar YAML manualmente sin backup
- Borrar recursos sin verificar
- Asumir que el problema es lo que parece
- Gastar >5 min en una pregunta difícil
- Olvidar verificar namespace (-n flag)

✅ **SÍ HACER:**
- Usar `--dry-run=client -o yaml` para ver antes de aplicar
- Usar `kubectl diff -f file.yaml` antes de apply
- Leer TODOS los events en `kubectl describe`
- Verificar múltiples veces labels/selectors
- Usar `-A` (all namespaces) cuando buscas recursos

---

## 🔧 Debugging Tools

### netshoot (TODO EN UNO)

```bash
kubectl run netshoot --image=nicolaka/netshoot -it --rm -- bash

# Dentro tienes:
# - ping, traceroute, mtr
# - nslookup, dig, host
# - curl, wget, httpie
# - netstat, ss, lsof
# - tcpdump, ngrep
# - iperf, ab (benchmarking)
```

### busybox (LIGERO)

```bash
kubectl run busybox --image=busybox:1.28 -it --rm -- sh

# Útil para:
# - nslookup
# - wget
# - ping
# - telnet
# - nc (netcat)
```

### dnsutils (DNS ESPECÍFICO)

```bash
kubectl run dnsutils --image=tutum/dnsutils -it --rm -- bash

# Herramientas DNS:
# - nslookup
# - dig
# - host
```

### curl (HTTP TESTING)

```bash
kubectl run curl --image=curlimages/curl -it --rm -- sh

# Solo curl, muy ligero
```

---

## 📝 YAML Templates Rápidos

### Debug Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command: ["sleep", "3600"]
  restartPolicy: Never
```

### Service Test

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  labels:
    app: test
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: test-svc
spec:
  selector:
    app: test
  ports:
  - port: 80
    targetPort: 80
```

### Resources con Limits

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-test
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

---

## 🎓 Procedimientos de Emergencia

### Cluster API Server Caído

```bash
# 1. Verificar si responde
kubectl cluster-info

# 2. SSH al master node
ssh master-node

# 3. Check API server logs
sudo docker ps | grep kube-apiserver
sudo docker logs <api-server-container>

# O si es static pod:
sudo cat /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log

# 4. Verificar manifest
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml

# 5. Check etcd connectivity
sudo docker ps | grep etcd
```

### etcd Corruption

```bash
# 1. Backup actual
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-$(date +%Y%m%d).db

# 2. Verificar snapshot
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-*.db

# 3. Si necesitas restore
sudo systemctl stop kube-apiserver

ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-*.db \
  --data-dir=/var/lib/etcd-restored

# 4. Update etcd manifest
sudo vi /etc/kubernetes/manifests/etcd.yaml
# Cambiar data-dir

# 5. Restart
sudo systemctl start kube-apiserver
```

### All Nodes NotReady

```bash
# 1. Check control plane
kubectl get pods -n kube-system

# 2. Check CNI
kubectl get pods -n kube-system | grep -E 'calico|flannel|weave'

# 3. Re-apply CNI
kubectl apply -f <cni-manifest-url>

# 4. En cada nodo
ssh <node>
sudo systemctl restart kubelet
```

### Certificate Expiration

```bash
# Check expiration
sudo kubeadm certs check-expiration

# Renew all
sudo kubeadm certs renew all

# Restart components
sudo systemctl restart kubelet
sudo docker restart $(sudo docker ps -q --filter name=k8s_kube-apiserver)
```

---

## 🎯 CKA Troubleshooting Checklist

### Antes del Examen

- [ ] Practicar crear debug pods en <30 segundos
- [ ] Memorizar formatos de logs: `kubectl logs <pod> --previous`
- [ ] Practicar troubleshooting en clusters rotos
- [ ] Conocer todos los estados de pods
- [ ] Saber interpretar Events rápidamente
- [ ] Practicar SSH a nodos y revisar logs del sistema
- [ ] Conocer ubicaciones de manifests: `/etc/kubernetes/manifests/`
- [ ] Practicar etcd backup/restore

### Durante el Examen

- [ ] Configurar alias al inicio
- [ ] Leer pregunta COMPLETA antes de actuar
- [ ] Identificar el layer del problema
- [ ] Usar `kubectl describe` SIEMPRE primero
- [ ] Verificar Events section
- [ ] Check logs si hay crash
- [ ] Verificar configuración (labels, selectors, ports)
- [ ] Test después de cada fix
- [ ] Si >5 min atascado: NEXT (flag y continuar)
- [ ] Últimos 15 min: revisar flagged questions

### Después de Resolver

- [ ] Verificar recurso está en estado esperado
- [ ] Check events: no errors nuevos
- [ ] Test funcionalidad si es aplicación
- [ ] Leer pregunta: ¿pedía algo más?

---

## 📚 Recursos Adicionales

### Documentación Oficial (Permitida en Examen)

- kubernetes.io/docs
- github.com/kubernetes
- kubernetes.io/blog

### Labs de Práctica

- killer.sh (CKA simulator)
- katacoda.com/courses/kubernetes
- play-with-k8s.com

### Troubleshooting Practice

Los labs de este módulo:
- Lab 01: Application Troubleshooting
- Lab 02: Control Plane & Nodes  
- Lab 03: Network & Storage
- Lab 04: Complete Cluster Troubleshooting (Simulación CKA)

---

## ✅ Resumen Final

**Troubleshooting en 3 Pasos:**

1. **IDENTIFY** (Identificar)
   - `kubectl get pods/nodes/svc`
   - Estado del recurso

2. **GATHER** (Recopilar)
   - `kubectl describe`
   - `kubectl logs`
   - `kubectl get events`

3. **RESOLVE** (Resolver)
   - Fix configuración
   - Verificar solución
   - Test funcionalidad

**Comandos Críticos:**
```bash
kubectl describe pod <name>
kubectl logs <name> --previous
kubectl get events --sort-by='.lastTimestamp'
kubectl exec -it <name> -- sh
```

**Recuerda:**
- 🎯 Troubleshooting es 25-30% del CKA
- ⏱️ Time management es crítico
- 🔍 Layer-by-layer approach
- ✅ Verificar SIEMPRE después de fix

---

**¡Buena suerte en el examen CKA!** 🚀

[← Volver al README](./README.md) | [Ir a Laboratorios →](./laboratorios/README.md)
