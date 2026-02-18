# Laboratorio 02: Control Plane & Worker Nodes Troubleshooting

> **Duración estimada**: 75-90 minutos  
> **Dificultad**: ⭐⭐⭐⭐ (Experto)  
> **Objetivos CKA**: Cluster Architecture (25%), Troubleshooting (25-30%)

## 📋 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:
- ✅ Diagnosticar problemas del API Server
- ✅ Troubleshoot etcd (backup, restore, certificados)
- ✅ Resolver problemas del Scheduler
- ✅ Diagnosticar Controller Manager
- ✅ Troubleshoot kubelet en worker nodes
- ✅ Resolver problemas de kube-proxy
- ✅ Diagnosticar nodes en estado NotReady
- ✅ Trabajar con logs de componentes del sistema

## ⚠️ Prerequisitos

- Cluster con acceso a control plane (minikube, kubeadm, o kind)
- Acceso SSH a nodes (si aplica)
- Permisos sudo en los nodes

## 🎯 Escenarios

### Escenario 1: API Server No Responde
**Situación**: El API server no está respondiendo a kubectl commands.

**Síntomas**:
```bash
kubectl get nodes
# Error: The connection to the server localhost:8080 was refused
```

**Tareas**:
1. Verificar que el API server está corriendo
2. Revisar logs del API server
3. Identificar y resolver el problema

<details>
<summary>💡 Pistas de Diagnóstico</summary>

```bash
# En el control plane node:

# 1. Verificar contenedor del API server
sudo crictl ps -a | grep kube-apiserver

# 2. Ver logs del API server
sudo crictl logs <container-id>

# 3. Verificar configuración
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml

# 4. Verificar certificados
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# 5. Ver logs de kubelet (maneja static pods)
sudo journalctl -u kubelet -n 100 --no-pager
```

</details>

<details>
<summary>🔧 Problemas Comunes y Soluciones</summary>

**Problema 1: Certificados expirados**
```bash
# Verificar expiración
sudo kubeadm certs check-expiration

# Renovar certificados
sudo kubeadm certs renew all

# Reiniciar kubelet
sudo systemctl restart kubelet
```

**Problema 2: Puerto en uso**
```bash
# Verificar que el puerto 6443 está disponible
sudo netstat -tulpn | grep 6443

# Si hay otro proceso usando el puerto
sudo kill <PID>
```

**Problema 3: YAML manifiesto corrupto**
```bash
# Verificar sintaxis YAML
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -v "^#" | grep -v "^$"

# Validar YAML
sudo apt-get install -y yamllint
sudo yamllint /etc/kubernetes/manifests/kube-apiserver.yaml

# Restaurar desde backup
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml.backup \
   /etc/kubernetes/manifests/kube-apiserver.yaml
```

**Problema 4: etcd no accesible**
```bash
# Verificar conectividad a etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Si etcd está down, revisar logs
sudo crictl logs <etcd-container-id>
```

</details>

---

### Escenario 2: etcd Troubleshooting
**Situación**: Necesitas diagnosticar y recuperar un cluster con problemas de etcd.

#### Parte A: Health Check

**Tareas**:
```bash
# 1. Verificar salud de etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# 2. Ver miembros del cluster
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# 3. Ver status detallado
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status --write-out=table
```

#### Parte B: Backup y Restore

**Escenario**: Necesitas hacer backup de etcd antes de un upgrade.

<details>
<summary>✅ Solución Completa</summary>

**Backup**:
```bash
# Crear directorio para backups
sudo mkdir -p /backup/etcd

# Hacer backup
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /backup/etcd/snapshot-$(date +%Y%m%d-%H%M%S).db

# Verificar backup
sudo ETCDCTL_API=3 etcdctl \
  --write-out=table \
  snapshot status /backup/etcd/snapshot-*.db
```

**Simular Desastre** (SOLO EN LAB):
```bash
# Eliminar todos los pods (simulación)
kubectl delete pods --all -n default

# Ver que se eliminaron
kubectl get pods
```

**Restore**:
```bash
# 1. Detener API server (mover manifest fuera)
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# 2. Restore desde snapshot
sudo ETCDCTL_API=3 etcdctl \
  --data-dir=/var/lib/etcd-restore \
  snapshot restore /backup/etcd/snapshot-*.db

# 3. Actualizar etcd manifest
sudo cp /etc/kubernetes/manifests/etcd.yaml /tmp/etcd.yaml.backup

# Editar para usar nuevo data-dir
sudo vi /etc/kubernetes/manifests/etcd.yaml
# Cambiar:
# - hostPath:
#     path: /var/lib/etcd
# Por:
# - hostPath:
#     path: /var/lib/etcd-restore

# 4. Restaurar API server
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# 5. Esperar a que el cluster se recupere
kubectl get pods --all-namespaces -w

# 6. Verificar datos restaurados
kubectl get pods
```

</details>

---

### Escenario 3: Scheduler No Asigna Pods
**Situación**: Los pods se quedan en estado Pending indefinidamente.

**Setup del Problema**:
```bash
# Simular scheduler down
kubectl -n kube-system scale deployment coredns --replicas=3
```

**Síntomas**:
```bash
kubectl get pods
# NAME                    READY   STATUS    RESTARTS   AGE
# coredns-xxx-yyy         0/1     Pending   0          2m
```

<details>
<summary>🔍 Diagnóstico</summary>

```bash
# 1. Verificar que el scheduler está corriendo
kubectl get pods -n kube-system | grep scheduler

# 2. Ver logs del scheduler
kubectl logs -n kube-system kube-scheduler-<control-plane-node>

# 3. Verificar eventos del pod pending
kubectl describe pod <pending-pod> | grep -A 10 Events
# Output: "0/1 nodes are available: 1 node(s) had taint..."

# 4. En control plane: verificar scheduler manualmente
sudo crictl ps | grep kube-scheduler

# 5. Ver logs de kubelet
sudo journalctl -u kubelet | grep scheduler
```

</details>

<details>
<summary>✅ Soluciones Comunes</summary>

**Problema 1: Scheduler no está corriendo**
```bash
# Verificar manifest
sudo cat /etc/kubernetes/manifests/kube-scheduler.yaml

# Ver logs de kubelet
sudo journalctl -u kubelet -n 50

# Reiniciar kubelet
sudo systemctl restart kubelet

# Verificar que scheduler inició
kubectl get pods -n kube-system -l component=kube-scheduler
```

**Problema 2: Scheduler con config incorrecta**
```bash
# Verificar flags del scheduler
kubectl get pod -n kube-system kube-scheduler-<node> -o yaml | grep command -A 20

# Si hay error en config, editar manifest
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml

# kubelet automáticamente reiniciará el pod
```

**Problema 3: No hay recursos disponibles**
```bash
# Ver recursos de los nodes
kubectl top nodes
kubectl describe nodes | grep -A 10 "Allocated resources"

# Escalar o eliminar pods para liberar recursos
kubectl delete pod <pod-name>
```

</details>

---

### Escenario 4: Controller Manager Issues
**Situación**: Los ReplicaSets no crean pods, Deployments no funcionan.

**Setup**:
```bash
# Crear un deployment
kubectl create deployment test-nginx --image=nginx --replicas=3

# Ver que los pods NO se crean
kubectl get deployment test-nginx
# DESIRED: 3, CURRENT: 0, READY: 0
```

<details>
<summary>🔍 Diagnóstico</summary>

```bash
# 1. Verificar controller-manager
kubectl get pods -n kube-system | grep controller-manager

# 2. Ver logs
kubectl logs -n kube-system kube-controller-manager-<control-plane-node>

# 3. Verificar en control plane
sudo crictl ps | grep controller-manager

# 4. Ver logs de kubelet
sudo journalctl -u kubelet | grep controller-manager | tail -20
```

</details>

<details>
<summary>✅ Solución</summary>

**Problema: Controller Manager no está corriendo**
```bash
# Ver manifest
sudo cat /etc/kubernetes/manifests/kube-controller-manager.yaml

# Buscar errores de configuración comunes:
# - Certificados incorrectos
# - Flags mal formateados
# - Paths incorrectos

# Verificar logs detallados
sudo crictl logs <controller-manager-container-id>

# Si hay error en manifest, corregir
sudo vi /etc/kubernetes/manifests/kube-controller-manager.yaml

# kubelet reiniciará automáticamente

# Verificar que funciona
kubectl get pods -n kube-system -l component=kube-controller-manager

# Verificar que el deployment ahora crea pods
kubectl get deployment test-nginx
kubectl get pods -l app=test-nginx
```

</details>

---

### Escenario 5: Node NotReady - kubelet Issues
**Situación**: Un worker node está en estado NotReady.

**Simular** (en worker node):
```bash
# Detener kubelet
sudo systemctl stop kubelet
```

**Ver en master**:
```bash
kubectl get nodes
# NAME         STATUS     ROLES    AGE   VERSION
# worker-01    NotReady   <none>   10d   v1.28.0
```

<details>
<summary>🔍 Diagnóstico Completo</summary>

```bash
# 1. Describir el node
kubectl describe node worker-01
# Buscar en Conditions y Events

# 2. SSH al node afectado
ssh worker-01

# 3. Verificar estado de kubelet
sudo systemctl status kubelet

# 4. Ver logs de kubelet
sudo journalctl -u kubelet -n 100 --no-pager

# 5. Verificar configuración
sudo cat /var/lib/kubelet/config.yaml

# 6. Verificar certificados
sudo openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -text -noout

# 7. Verificar conectividad al API server
curl -k https://<api-server>:6443/healthz

# 8. Ver procesos de contenedores
sudo crictl ps
```

</details>

<details>
<summary>✅ Soluciones por Causa</summary>

**Causa 1: kubelet stopped**
```bash
# Iniciar kubelet
sudo systemctl start kubelet

# Habilitar al boot
sudo systemctl enable kubelet

# Verificar
sudo systemctl status kubelet
```

**Causa 2: Certificados expirados**
```bash
# Ver expiración
sudo openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem \
  -text -noout | grep "Not After"

# Si expiró, regenerar en el master
kubectl certificate approve <csr-name>

# Reiniciar kubelet
sudo systemctl restart kubelet
```

**Causa 3: Disk pressure**
```bash
# Verificar espacio en disco
df -h

# Limpiar imágenes no usadas
sudo crictl rmi --prune

# Limpiar contenedores stopped
sudo crictl rm $(sudo crictl ps -a -q)

# Reiniciar kubelet
sudo systemctl restart kubelet
```

**Causa 4: Configuración incorrecta**
```bash
# Verificar config
sudo cat /var/lib/kubelet/config.yaml

# Comparar con config correcta de otro node
# Corregir errores

# Reiniciar kubelet
sudo systemctl restart kubelet
```

**Causa 5: Network plugin issues**
```bash
# Verificar CNI
ls -la /etc/cni/net.d/

# Ver logs de CNI
sudo journalctl -u kubelet | grep cni

# Reinstalar CNI si es necesario (ejemplo: Calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

</details>

---

### Escenario 6: kube-proxy Issues
**Situación**: Los Services no funcionan, pods no pueden comunicarse entre sí.

**Síntomas**:
```bash
# Crear test
kubectl run test-1 --image=nginx
kubectl expose pod test-1 --port=80
kubectl run test-2 --image=busybox:1.28 -it --rm -- wget -O- http://test-1
# Output: connection refused o timeout
```

<details>
<summary>🔍 Diagnóstico</summary>

```bash
# 1. Verificar kube-proxy está corriendo
kubectl get pods -n kube-system | grep kube-proxy

# 2. Ver logs de kube-proxy
kubectl logs -n kube-system kube-proxy-<xxxxx>

# 3. Verificar configuración
kubectl get configmap kube-proxy -n kube-system -o yaml

# 4. En worker node: verificar iptables rules
sudo iptables-save | grep <service-ip>

# 5. Verificar modo de kube-proxy (iptables o ipvs)
kubectl logs -n kube-system kube-proxy-<xxxxx> | grep "Using"
```

</details>

<details>
<summary>✅ Soluciones</summary>

**Problema 1: kube-proxy pods no running**
```bash
# Ver estado
kubectl get pods -n kube-system -l k8s-app=kube-proxy

# Ver eventos
kubectl describe pod -n kube-system kube-proxy-<xxxxx>

# Si es DaemonSet issue:
kubectl get ds -n kube-system kube-proxy

# Recrear pods
kubectl delete pod -n kube-system -l k8s-app=kube-proxy
```

**Problema 2: Configuración incorrecta**
```bash
# Ver config
kubectl get cm kube-proxy -n kube-system -o yaml

# Editar si es necesario
kubectl edit cm kube-proxy -n kube-system

# Reiniciar kube-proxy pods
kubectl delete pod -n kube-system -l k8s-app=kube-proxy
```

**Problema 3: iptables corrupto**
```bash
# En worker node
# Flush iptables (CUIDADO en producción!)
sudo iptables -F
sudo iptables -t nat -F

# Reiniciar kube-proxy en ese node
kubectl delete pod -n kube-system kube-proxy-<node-specific-pod>

# kube-proxy recreará las reglas
```

**Verificación**:
```bash
# Test conectividad
kubectl run test-1 --image=nginx
kubectl expose pod test-1 --port=80
kubectl run test-2 --image=busybox:1.28 -it --rm -- wget -O- http://test-1

# Debe funcionar
```

</details>

---

### Escenario 7: Node Disk Pressure
**Situación**: Node reporta DiskPressure, pods son evicted.

**Simular** (NO en producción):
```bash
# En worker node, crear archivo grande
sudo dd if=/dev/zero of=/tmp/bigfile bs=1G count=10
```

**Ver efectos**:
```bash
kubectl get nodes
# NAME         STATUS                     ROLES    AGE
# worker-01    Ready,SchedulingDisabled   <none>   10d

kubectl describe node worker-01 | grep -A 5 "Conditions"
# Type             Status
# DiskPressure     True
```

<details>
<summary>✅ Solución</summary>

```bash
# 1. SSH al node
ssh worker-01

# 2. Identificar uso de disco
df -h

# 3. Ver qué consume espacio
sudo du -sh /* | sort -rh | head -20

# 4. Limpiar según sea necesario

# Opción A: Limpiar imágenes Docker/containerd
sudo crictl rmi --prune

# Opción B: Limpiar logs
sudo journalctl --vacuum-size=100M
sudo find /var/log -name "*.log" -exec truncate -s 0 {} \;

# Opción C: Limpiar contenedores stopped
sudo crictl rm $(sudo crictl ps -a -q --state=exited)

# Opción D: Limpiar cache de paquetes
sudo apt-get clean
sudo rm -rf /var/cache/apt/archives/*

# 5. Verificar espacio liberado
df -h

# 6. Reiniciar kubelet para re-evaluar
sudo systemctl restart kubelet

# 7. Verificar en master
kubectl describe node worker-01 | grep DiskPressure
# DiskPressure     False
```

</details>

---

### Escenario 8: Static Pod Not Starting
**Situación**: Un static pod definido en `/etc/kubernetes/manifests/` no está corriendo.

**Setup**:
```bash
# En control plane, crear static pod con error
sudo tee /etc/kubernetes/manifests/static-web.yaml > /dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: static-web
spec:
  containers:
  - name: web
    image: nginx:invalid-tag-xyz
    ports:
    - containerPort: 80
EOF
```

<details>
<summary>🔍 Diagnóstico y Solución</summary>

```bash
# 1. Verificar si kubelet ve el pod
kubectl get pods --all-namespaces | grep static-web

# 2. Ver estado
kubectl describe pod static-web-<node-name> -n default

# 3. Ver logs de kubelet
sudo journalctl -u kubelet -f

# 4. Verificar directorio de manifests
ls -la /etc/kubernetes/manifests/

# 5. Verificar sintaxis YAML
sudo cat /etc/kubernetes/manifests/static-web.yaml | yamllint -

# 6. Ver en crictl directamente
sudo crictl ps -a | grep static-web

# Solución: Corregir el manifest
sudo vi /etc/kubernetes/manifests/static-web.yaml
# Cambiar image: nginx:invalid-tag-xyz → nginx:1.21

# kubelet detectará el cambio automáticamente en ~20 segundos

# Verificar
kubectl get pods | grep static-web
```

</details>

---

## 🧹 Limpieza

```bash
# Eliminar recursos de prueba
kubectl delete deployment test-nginx
kubectl delete pod test-1 test-2 --ignore-not-found

# En worker node (si aplicaste el disk pressure test)
ssh worker-01 "sudo rm -f /tmp/bigfile"

# En control plane (si creaste static pod)
sudo rm -f /etc/kubernetes/manifests/static-web.yaml

# Asegurar kubelet corriendo en todos los nodes
sudo systemctl start kubelet
sudo systemctl enable kubelet
```

---

## 📊 Evaluación

- [ ] Escenario 1: API Server diagnosticado y reparado
- [ ] Escenario 2: etcd backup/restore completado
- [ ] Escenario 3: Scheduler troubleshooting completado
- [ ] Escenario 4: Controller Manager reparado
- [ ] Escenario 5: Node NotReady resuelto
- [ ] Escenario 6: kube-proxy reparado
- [ ] Escenario 7: Disk Pressure resuelto
- [ ] Escenario 8: Static Pod reparado

---

## 🎯 Comandos Críticos para CKA

### Control Plane Components
```bash
# Ver todos los componentes
kubectl get pods -n kube-system

# Logs de componentes estáticos
sudo crictl logs <container-id>
sudo journalctl -u kubelet -n 100

# Manifests de static pods
ls -la /etc/kubernetes/manifests/
```

### etcd
```bash
# Health check
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=<ca> --cert=<cert> --key=<key> endpoint health

# Backup
ETCDCTL_API=3 etcdctl snapshot save /backup/snapshot.db

# Restore
ETCDCTL_API=3 etcdctl snapshot restore /backup/snapshot.db --data-dir=/var/lib/etcd-restore
```

### Nodes
```bash
# Node status
kubectl get nodes
kubectl describe node <node-name>

# kubelet
sudo systemctl status kubelet
sudo journalctl -u kubelet -f
```

---

## 💡 Tips para el Examen

1. **Memoriza paths críticos**:
   - `/etc/kubernetes/manifests/` - Static pods
   - `/var/lib/kubelet/config.yaml` - kubelet config
   - `/etc/kubernetes/pki/` - Certificados

2. **journalctl es tu amigo**:
   ```bash
   sudo journalctl -u kubelet -n 100 --no-pager
   sudo journalctl -u kubelet -f  # follow mode
   ```

3. **crictl para debugging de bajo nivel**:
   ```bash
   sudo crictl ps    # containers running
   sudo crictl logs <id>
   sudo crictl inspect <id>
   ```

4. **Siempre verifica certificados en issues de autenticación**

5. **etcd backup/restore es CRÍTICO** - practica múltiples veces

---

**Tiempo objetivo**: 8-12 minutos por escenario  
**Siguiente**: [Lab 03 - Network & Storage](./lab-03-network-storage.md)
