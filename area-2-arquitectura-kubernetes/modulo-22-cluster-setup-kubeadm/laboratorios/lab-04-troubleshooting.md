# Lab 04: Troubleshooting de Cluster Kubernetes

**Duración estimada:** 60-90 minutos  
**Dificultad:** ⭐⭐⭐⭐ Avanzado

## 🎯 Objetivos

Al completar este laboratorio, serás capaz de:
- ✅ Diagnosticar problemas comunes de cluster setup
- ✅ Troubleshoot componentes del control plane
- ✅ Debug de networking y CNI issues
- ✅ Resolver problemas de certificados
- ✅ Fix de problemas de kubelet y containerd
- ✅ Usar herramientas de diagnóstico efectivamente

## 🏗️ Escenarios de Troubleshooting

Este lab cubre 10 escenarios reales de problemas:

1. Nodo en NotReady
2. Pods en Pending indefinidamente
3. Fallo de CNI plugin
4. Certificados expirados
5. etcd no saludable
6. API server no responde
7. Swap habilitado (error común)
8. Problemas de DNS
9. Worker no se puede unir
10. Container runtime falla

---

## 📋 Prerequisites

- Cluster Kubernetes (puede estar roto - eso es intencional)
- Acceso root a todos los nodos
- Herramientas básicas de troubleshooting instaladas

---

## 🔧 Escenario 1: Nodo en NotReady

### Síntomas

```bash
kubectl get nodes

# Output:
NAME            STATUS     ROLES           AGE   VERSION
k8s-master-01   Ready      control-plane   10d   v1.28.0
k8s-worker-01   NotReady   <none>          10d   v1.28.0  # ❌ PROBLEMA
```

### Diagnóstico

```bash
# 1. Describir nodo para ver condiciones
kubectl describe node k8s-worker-01

# Buscar en output:
# Conditions:
#   Type             Status  Reason
#   MemoryPressure   False   KubeletHasSufficientMemory
#   DiskPressure     False   KubeletHasNoDiskPressure
#   PIDPressure      False   KubeletHasSufficientPID
#   Ready            False   KubeletNotReady  # ❌ PROBLEMA AQUÍ

# 2. En el worker node, verificar kubelet
ssh k8s-worker-01
sudo systemctl status kubelet

# 3. Ver logs de kubelet
sudo journalctl -u kubelet -f --since "10 minutes ago"

# Errores comunes:
# - "failed to run Kubelet: misconfiguration: kubelet cgroup driver"
# - "Failed to create pod sandbox"
# - "CNI plugin not initialized"
```

### Soluciones Comunes

#### Problema: kubelet no está corriendo

```bash
# Reiniciar kubelet
sudo systemctl restart kubelet

# Verificar status
sudo systemctl status kubelet

# Si falla al iniciar, ver logs
sudo journalctl -u kubelet --no-pager | tail -50
```

#### Problema: Cgroup driver mismatch

```bash
# Verificar cgroup driver de kubelet
sudo cat /var/lib/kubelet/config.yaml | grep cgroupDriver

# Verificar cgroup driver de containerd
sudo cat /etc/containerd/config.toml | grep SystemdCgroup

# Deben coincidir (ambos systemd)

# Fix: Configurar SystemdCgroup en containerd
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl restart kubelet
```

#### Problema: CNI plugin no inicializado

```bash
# Verificar que Calico/CNI está instalado
kubectl get pods -n kube-system -l k8s-app=calico-node

# Si no hay pods de Calico, instalar CNI
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Esperar a que Calico esté Ready
watch kubectl get pods -n kube-system
```

### Verificación

```bash
# Nodo debe pasar a Ready en 1-2 minutos
watch kubectl get nodes

# ✅ Success cuando:
# k8s-worker-01   Ready    <none>   10d   v1.28.0
```

---

## 🧪 Escenario 2: Pods en Pending Indefinidamente

### Síntomas

```bash
kubectl get pods

# Output:
NAME                    READY   STATUS    RESTARTS   AGE
nginx-7c6f5b9c8-abcde   0/1     Pending   0          5m  # ❌ PROBLEMA
```

### Diagnóstico

```bash
# 1. Describir pod para ver eventos
kubectl describe pod nginx-7c6f5b9c8-abcde

# Buscar Events al final:
# Events:
#   Type     Reason            Message
#   Warning  FailedScheduling  0/2 nodes are available: 1 node(s) had taints that the pod didn't tolerate

# 2. Ver razones de pending
kubectl get events --sort-by='.lastTimestamp' | grep nginx

# Razones comunes:
# - Insufficient cpu/memory
# - Taints en todos los nodos
# - NodeSelector no coincide
# - Pod affinity no satisfecho
```

### Soluciones Comunes

#### Problema: Taints en master impiden scheduling

```bash
# Ver taints en nodos
kubectl describe nodes | grep -i taint

# Master típicamente tiene:
# Taints: node-role.kubernetes.io/control-plane:NoSchedule

# Opción 1: Remover taint (NO RECOMENDADO en producción)
kubectl taint nodes k8s-master-01 node-role.kubernetes.io/control-plane:NoSchedule-

# Opción 2: Agregar toleration al pod
# Ver sección de tolerations en pod spec

# Opción 3: Agregar worker nodes
# Ver Lab 01 para agregar workers
```

#### Problema: Recursos insuficientes

```bash
# Ver recursos de nodos
kubectl describe nodes | grep -A 5 "Allocated resources"

# Ver requests/limits de pods
kubectl describe node k8s-worker-01 | grep -A 10 "Non-terminated Pods"

# Fix: Agregar más recursos o reducir requests
# Editar deployment para reducir resources
kubectl edit deployment nginx
```

#### Problema: ImagePullBackOff después de pending

```bash
# Describir pod
kubectl describe pod nginx-7c6f5b9c8-abcde

# Ver eventos:
# Failed to pull image "nginx:typo": rpc error: code = Unknown desc = Error response from daemon: manifest for nginx:typo not found

# Fix: Corregir imagen en deployment
kubectl set image deployment/nginx nginx=nginx:latest
```

### Verificación

```bash
# Pod debe pasar a Running
watch kubectl get pods

# ✅ Success cuando:
# nginx-7c6f5b9c8-abcde   1/1     Running   0   1m
```

---

## 🌐 Escenario 3: Fallo de CNI Plugin (Networking)

### Síntomas

```bash
# Nodos en NotReady
kubectl get nodes  # NotReady

# Pods de Calico en CrashLoopBackOff
kubectl get pods -n kube-system -l k8s-app=calico-node

# No hay conectividad entre pods
kubectl exec test-pod -- ping <otro-pod-ip>  # Falla
```

### Diagnóstico

```bash
# 1. Ver logs de Calico
kubectl logs -n kube-system -l k8s-app=calico-node --tail=50

# Errores comunes:
# - "error getting ClusterInformation: connection refused"
# - "Failed to create Calico node"
# - "Bird routing daemon failed to start"

# 2. Verificar configuración de CNI
ls -la /etc/cni/net.d/

# Debe existir: 10-calico.conflist o similar

# 3. Verificar que MTU es correcto
kubectl get cm -n kube-system calico-config -o yaml | grep mtu
```

### Soluciones Comunes

#### Problema: Calico no instalado o corrupto

```bash
# Eliminar Calico corrupto
kubectl delete -f https://docs.projectcalico.org/manifests/calico.yaml

# Reinstalar Calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Esperar a que todos los pods estén Running
watch kubectl get pods -n kube-system
```

#### Problema: MTU mismatch

```bash
# Verificar MTU de interfaz de red
ip link show | grep mtu

# Ajustar MTU en Calico ConfigMap
kubectl edit cm calico-config -n kube-system

# Cambiar:
# veth_mtu: "1440"  # Para overlays
# veth_mtu: "1500"  # Para flat networks

# Reiniciar pods de Calico
kubectl delete pods -n kube-system -l k8s-app=calico-node
```

#### Problema: /etc/cni/net.d corrupto

```bash
# En cada nodo, limpiar CNI config
sudo rm -rf /etc/cni/net.d/*

# Reiniciar kubelet para que CNI se reconfigure
sudo systemctl restart kubelet

# Verificar que CNI config se regenera
ls -la /etc/cni/net.d/
```

### Verificación

```bash
# Test de conectividad entre pods
kubectl run test1 --image=busybox --restart=Never -- sleep 3600
kubectl run test2 --image=busybox --restart=Never -- sleep 3600

# Obtener IP de test2
TEST2_IP=$(kubectl get pod test2 -o jsonpath='{.status.podIP}')

# Ping desde test1 a test2
kubectl exec test1 -- ping -c 3 $TEST2_IP

# ✅ Success cuando ping funciona

# Cleanup
kubectl delete pod test1 test2
```

---

## 🔐 Escenario 4: Certificados Expirados

### Síntomas

```bash
# kubectl falla con error de certificado
kubectl get nodes

# Error:
# Unable to connect to the server: x509: certificate has expired or is not yet valid

# API server logs muestran errores TLS
kubectl logs -n kube-system -l component=kube-apiserver
```

### Diagnóstico

```bash
# 1. Verificar expiración de certificados
sudo kubeadm certs check-expiration

# Output muestra certificados y fechas de expiración:
# CERTIFICATE                EXPIRES                  RESIDUAL TIME
# admin.conf                 Jan 13, 2024 12:00 UTC   <invalid>  # ❌

# 2. Ver certificados individuales
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -A 2 Validity
```

### Soluciones Comunes

#### Problema: Certificados CA expirados

```bash
# Renovar todos los certificados
sudo kubeadm certs renew all

# Verificar renovación
sudo kubeadm certs check-expiration

# Reiniciar componentes del control plane
sudo systemctl restart kubelet

# Actualizar kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config

# Verificar
kubectl get nodes
```

#### Problema: Solo algunos certificados expirados

```bash
# Renovar certificados específicos
sudo kubeadm certs renew apiserver
sudo kubeadm certs renew apiserver-kubelet-client

# Reiniciar componentes
sudo systemctl restart kubelet
```

### Verificación

```bash
# Verificar que certificados son válidos
sudo kubeadm certs check-expiration

# Todos deben mostrar RESIDUAL TIME > 0

# kubectl debe funcionar
kubectl get nodes

# ✅ Success cuando kubectl funciona sin errores
```

---

## 💾 Escenario 5: etcd No Saludable

### Síntomas

```bash
# API server no responde o muy lento
kubectl get nodes  # Timeout o muy lento

# Pod de etcd en CrashLoopBackOff
kubectl get pods -n kube-system -l component=etcd

# etcd health check falla
sudo ETCDCTL_API=3 etcdctl endpoint health  # Unhealthy
```

### Diagnóstico

```bash
# 1. Ver logs de etcd
kubectl logs -n kube-system -l component=etcd

# Errores comunes:
# - "failed to detect etcd version: dial tcp 127.0.0.1:2379: connect: connection refused"
# - "mvcc: database space exceeded"
# - "etcdserver: request timed out"

# 2. Verificar espacio en disco
df -h /var/lib/etcd

# 3. Verificar permisos
ls -la /var/lib/etcd/

# 4. Verificar tamaño de DB
sudo du -sh /var/lib/etcd/
```

### Soluciones Comunes

#### Problema: etcd DB demasiado grande

```bash
# Compactar etcd
sudo ETCDCTL_API=3 etcdctl compact $(sudo ETCDCTL_API=3 etcdctl endpoint status --write-out="json" | grep -oP '(?<="revision":)\d+')

# Defragmentar
sudo ETCDCTL_API=3 etcdctl defrag

# Verificar tamaño reducido
sudo du -sh /var/lib/etcd/
```

#### Problema: Permisos incorrectos

```bash
# Fix permisos
sudo chown -R root:root /var/lib/etcd
sudo chmod 700 /var/lib/etcd

# Reiniciar kubelet
sudo systemctl restart kubelet
```

#### Problema: etcd corrupto - Restaurar desde backup

```bash
# Ver Lab 03 para procedimiento completo de restore

# Resumen:
# 1. Detener kubelet
sudo systemctl stop kubelet

# 2. Mover etcd corrupto
sudo mv /var/lib/etcd /var/lib/etcd.corrupted

# 3. Restaurar desde snapshot
sudo -E etcdctl snapshot restore /var/backups/etcd/snapshot.db \
  --data-dir=/var/lib/etcd

# 4. Reiniciar kubelet
sudo systemctl start kubelet
```

### Verificación

```bash
# etcd debe estar saludable
sudo -E etcdctl endpoint health

# Output: 127.0.0.1:2379 is healthy: successfully committed proposal

# Pods del sistema Running
kubectl get pods -n kube-system

# ✅ Success cuando etcd healthy y API server responde
```

---

## 🚨 Escenario 6: API Server No Responde

### Síntomas

```bash
# kubectl no puede conectar
kubectl get nodes

# Error:
# The connection to the server localhost:8080 was refused

# O timeout:
# Unable to connect to the server: net/http: TLS handshake timeout
```

### Diagnóstico

```bash
# 1. Verificar que API server está corriendo
sudo systemctl status kubelet

# 2. Ver pod de API server
sudo crictl ps | grep kube-apiserver

# 3. Ver logs de API server
sudo crictl logs <apiserver-container-id>

# 4. Verificar puerto 6443 abierto
sudo ss -tlnp | grep 6443

# 5. Verificar kubeconfig
cat ~/.kube/config | grep server
```

### Soluciones Comunes

#### Problema: kubeconfig apunta a localhost

```bash
# Ver configuración actual
kubectl config view

# Cambiar server URL
kubectl config set-cluster kubernetes --server=https://k8s-master-01:6443

# O copiar admin.conf nuevamente
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
```

#### Problema: API server pod crasheando

```bash
# Ver manifesto estático
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml

# Ver logs del container anterior
sudo crictl logs --previous <container-id>

# Errores comunes en manifesto:
# - Certificado path incorrecto
# - etcd endpoint incorrecto
# - Puerto bind en uso

# Fix: Editar manifesto
sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml

# kubelet automáticamente reinicia el pod
```

#### Problema: Firewall bloqueando puerto 6443

```bash
# Verificar firewall
sudo iptables -L -n | grep 6443

# Permitir puerto 6443
sudo iptables -A INPUT -p tcp --dport 6443 -j ACCEPT

# O deshabilitar firewall (testing)
sudo systemctl stop ufw
sudo systemctl disable ufw
```

### Verificación

```bash
# API server debe responder
kubectl get nodes

# Ver componentes saludables
kubectl get --raw='/readyz?verbose'

# ✅ Success cuando kubectl funciona
```

---

## 💧 Escenario 7: Swap Habilitado (Error Común)

### Síntomas

```bash
# kubeadm init falla
sudo kubeadm init

# Error:
# [ERROR Swap]: running with swap on is not supported. Please disable swap

# O kubelet falla
sudo journalctl -u kubelet | grep swap
# swap is on; production deployments should disable swap
```

### Diagnóstico

```bash
# Verificar si swap está habilitado
free -h

# Output:
#               total        used        free      shared  buff/cache   available
# Swap:          2.0Gi          0B       2.0Gi  # ❌ PROBLEMA si no es 0
```

### Soluciones

```bash
# Deshabilitar swap temporalmente
sudo swapoff -a

# Deshabilitar swap permanentemente
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Verificar /etc/fstab
cat /etc/fstab | grep swap
# Líneas con swap deben estar comentadas con #

# Verificar que swap está off
free -h
# Swap debe mostrar 0
```

### Verificación

```bash
# free debe mostrar 0 swap
free -h

# kubeadm debe proceder sin errores
sudo kubeadm reset -f
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# ✅ Success cuando swap = 0
```

---

## 🔍 Escenario 8: Problemas de DNS

### Síntomas

```bash
# Pods no pueden resolver nombres
kubectl run test --image=busybox --restart=Never -it -- nslookup kubernetes.default

# Error:
# Server:    10.96.0.10
# Address 1: 10.96.0.10
# nslookup: can't resolve 'kubernetes.default'  # ❌

# CoreDNS pods en CrashLoopBackOff
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

### Diagnóstico

```bash
# 1. Verificar CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 2. Ver logs de CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns

# Errores comunes:
# - "plugin/loop: Loop detected"
# - "read udp: i/o timeout"

# 3. Verificar ConfigMap de CoreDNS
kubectl get cm -n kube-system coredns -o yaml

# 4. Verificar service de kube-dns
kubectl get svc -n kube-system kube-dns
```

### Soluciones Comunes

#### Problema: Loop de DNS detectado

```bash
# Editar ConfigMap de CoreDNS
kubectl edit cm coredns -n kube-system

# Comentar o remover línea de loop plugin:
# .:53 {
#     errors
#     health {
#        lameduck 5s
#     }
#     ready
#     kubernetes cluster.local in-addr.arpa ip6.arpa {
#        pods insecure
#        fallthrough in-addr.arpa ip6.arpa
#        ttl 30
#     }
#     prometheus :9153
#     forward . /etc/resolv.conf  # ⚠️ Puede causar loop
#     cache 30
#     # loop  # ❌ COMENTAR ESTA LÍNEA
#     reload
#     loadbalance
# }

# Reiniciar CoreDNS
kubectl rollout restart deployment coredns -n kube-system
```

#### Problema: CoreDNS no tiene endpoints

```bash
# Verificar endpoints
kubectl get endpoints -n kube-system kube-dns

# Si no hay endpoints, verificar que CoreDNS pods están Running
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Recrear deployment si es necesario
kubectl delete deployment coredns -n kube-system
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml
```

### Verificación

```bash
# Test de DNS
kubectl run dns-test --image=busybox --restart=Never --rm -it -- nslookup kubernetes.default

# Debe resolver:
# Server:    10.96.0.10
# Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
# Name:      kubernetes.default
# Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local

# ✅ Success cuando resuelve correctamente
```

---

## 🔗 Escenario 9: Worker No Se Puede Unir

### Síntomas

```bash
# kubeadm join falla en worker
sudo kubeadm join k8s-master-01:6443 --token abc123.xyz789 \
  --discovery-token-ca-cert-hash sha256:123...

# Error:
# error execution phase preflight: couldn't validate the identity of the API Server
```

### Diagnóstico

```bash
# 1. Verificar conectividad a master
ping k8s-master-01
telnet k8s-master-01 6443

# 2. Verificar que token es válido
# En master:
kubeadm token list

# 3. Verificar discovery-token-ca-cert-hash
# En master:
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | sed 's/^.* //'
```

### Soluciones Comunes

#### Problema: Token expirado

```bash
# En master, generar nuevo token
kubeadm token create --print-join-command

# Usar nuevo comando en worker
sudo kubeadm join k8s-master-01:6443 --token NEW_TOKEN \
  --discovery-token-ca-cert-hash sha256:NEW_HASH
```

#### Problema: Firewall bloqueando

```bash
# En master, permitir puerto 6443
sudo iptables -A INPUT -p tcp --dport 6443 -j ACCEPT

# En worker, verificar conectividad
telnet k8s-master-01 6443
```

#### Problema: Worker ya unido previamente

```bash
# Reset worker primero
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo rm -rf $HOME/.kube/config

# Luego unir nuevamente
sudo kubeadm join ...
```

### Verificación

```bash
# En master, ver nuevo worker
watch kubectl get nodes

# Worker debe aparecer y pasar a Ready
# ✅ Success cuando worker está Ready
```

---

## 🐳 Escenario 10: Container Runtime Falla

### Síntomas

```bash
# Pods no pueden iniciar
kubectl get pods

# Output:
# NAME    READY   STATUS                  RESTARTS   AGE
# nginx   0/1     ContainerCreating       0          5m  # ❌ Stuck

# kubelet logs muestran errores de runtime
sudo journalctl -u kubelet | grep runtime

# Error:
# failed to create containerd task: context deadline exceeded
```

### Diagnóstico

```bash
# 1. Verificar containerd
sudo systemctl status containerd

# 2. Ver logs de containerd
sudo journalctl -u containerd -f

# 3. Listar containers (debe funcionar)
sudo crictl ps

# 4. Verificar socket
ls -la /var/run/containerd/containerd.sock
```

### Soluciones Comunes

#### Problema: containerd no está corriendo

```bash
# Reiniciar containerd
sudo systemctl restart containerd

# Habilitar al boot
sudo systemctl enable containerd

# Verificar status
sudo systemctl status containerd
```

#### Problema: Socket no existe o permisos incorrectos

```bash
# Verificar socket
ls -la /var/run/containerd/containerd.sock

# Recrear si no existe
sudo systemctl restart containerd

# Ajustar permisos si es necesario
sudo chmod 666 /var/run/containerd/containerd.sock
```

#### Problema: Configuración de containerd corrupta

```bash
# Backup configuración actual
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup

# Regenerar configuración por defecto
sudo rm /etc/containerd/config.toml
containerd config default | sudo tee /etc/containerd/config.toml

# IMPORTANTE: Configurar SystemdCgroup = true
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Reiniciar containerd y kubelet
sudo systemctl restart containerd
sudo systemctl restart kubelet
```

### Verificación

```bash
# crictl debe funcionar
sudo crictl ps
sudo crictl images

# Pods deben poder iniciar
kubectl run test --image=nginx
watch kubectl get pods

# ✅ Success cuando pods pasan a Running
```

---

## 🛠️ Herramientas de Troubleshooting

### Comandos Esenciales

```bash
# Cluster-level
kubectl cluster-info
kubectl get nodes -o wide
kubectl get componentstatuses  # Deprecated en 1.28+
kubectl get --raw='/readyz?verbose'
kubectl get events --sort-by='.lastTimestamp'

# Nodes
kubectl describe node <node-name>
kubectl top nodes  # Requiere metrics-server

# Pods
kubectl describe pod <pod-name>
kubectl logs <pod-name> -f
kubectl logs <pod-name> --previous  # Logs del container anterior
kubectl exec -it <pod-name> -- /bin/sh

# System pods
kubectl get pods -n kube-system
kubectl logs -n kube-system -l component=kube-apiserver
kubectl logs -n kube-system -l component=etcd

# On nodes
sudo systemctl status kubelet
sudo systemctl status containerd
sudo journalctl -u kubelet -f
sudo journalctl -u containerd -f
sudo crictl ps
sudo crictl logs <container-id>
```

### Checklist de Troubleshooting

1. **Verificar nodos**
   ```bash
   kubectl get nodes
   kubectl describe nodes
   ```

2. **Verificar pods del sistema**
   ```bash
   kubectl get pods -n kube-system
   ```

3. **Verificar logs de kubelet**
   ```bash
   sudo journalctl -u kubelet --since "10 minutes ago"
   ```

4. **Verificar container runtime**
   ```bash
   sudo systemctl status containerd
   sudo crictl info
   ```

5. **Verificar networking**
   ```bash
   kubectl get pods -n kube-system -l k8s-app=calico-node
   ```

6. **Verificar certificados**
   ```bash
   sudo kubeadm certs check-expiration
   ```

7. **Verificar etcd**
   ```bash
   sudo -E etcdctl endpoint health
   ```

---

## ✅ Criterios de Completitud

Has completado exitosamente este lab si:
- [ ] Puedes diagnosticar nodos en NotReady
- [ ] Puedes resolver pods en Pending
- [ ] Entiendes troubleshooting de CNI
- [ ] Puedes renovar certificados
- [ ] Sabes recuperar etcd corrupto
- [ ] Puedes fix API server issues
- [ ] Conoces herramientas de diagnóstico
- [ ] Puedes troubleshoot container runtime

**¡Felicitaciones!** 🎉 Eres un troubleshooter de Kubernetes.

**Próximo paso:** Practicar en escenarios reales y prepararte para CKA exam.
