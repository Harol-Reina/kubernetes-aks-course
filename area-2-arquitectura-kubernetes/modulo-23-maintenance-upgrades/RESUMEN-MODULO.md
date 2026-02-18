# 📋 Cheatsheet: Cluster Maintenance & Upgrades

**Referencia rápida para CKA** - Todos los comandos esenciales de mantenimiento y upgrades

---

## 🔍 Verificación Pre-Upgrade

```bash
# Ver versión actual
kubectl version --short
kubeadm version

# Health check del cluster
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Ver versiones disponibles
sudo apt-cache madison kubeadm | head -10

# Verificar espacio en disco
df -h /var/lib/etcd
df -h /var/lib/kubelet
```

---

## ⬆️ Upgrade - Control Plane (Primer Master)

```bash
# 1. Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.4-00
sudo apt-mark hold kubeadm

# 2. Planificar upgrade (dry-run)
sudo kubeadm upgrade plan

# 3. Aplicar upgrade
sudo kubeadm upgrade apply v1.28.4

# 4. Drain del nodo
kubectl drain <control-plane-node> --ignore-daemonsets

# 5. Upgrade kubelet y kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.4-00 kubectl=1.28.4-00
sudo apt-mark hold kubelet kubectl

# 6. Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 7. Uncordon
kubectl uncordon <control-plane-node>

# 8. Verificar
kubectl get nodes
```

---

## ⬆️ Upgrade - Control Planes Adicionales (HA)

```bash
# En cada master ADICIONAL (no el primero)

# 1. Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.4-00
sudo apt-mark hold kubeadm

# 2. Upgrade del nodo (usar 'node', no 'apply')
sudo kubeadm upgrade node

# 3. Drain
kubectl drain <control-plane-node> --ignore-daemonsets

# 4. Upgrade kubelet y kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.4-00 kubectl=1.28.4-00
sudo apt-mark hold kubelet kubectl

# 5. Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 6. Uncordon
kubectl uncordon <control-plane-node>
```

---

## ⬆️ Upgrade - Worker Nodes

```bash
# EN EL CONTROL PLANE:

# 1. Drain del worker
kubectl drain <worker-node> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force

# EN EL WORKER NODE (SSH):

# 2. Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.4-00
sudo apt-mark hold kubeadm

# 3. Upgrade configuración
sudo kubeadm upgrade node

# 4. Upgrade kubelet y kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.4-00 kubectl=1.28.4-00
sudo apt-mark hold kubelet kubectl

# 5. Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# DE VUELTA EN CONTROL PLANE:

# 6. Uncordon
kubectl uncordon <worker-node>

# 7. Verificar
kubectl get nodes
```

---

## 🔧 Node Maintenance

### Drain (Evacuar Pods)

```bash
# Drain básico
kubectl drain <node-name> --ignore-daemonsets

# Drain con todas las opciones
kubectl drain <node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force \
  --grace-period=300 \
  --timeout=600s

# Dry-run (ver qué pasaría)
kubectl drain <node-name> --dry-run=client

# Filtrar pods específicos
kubectl drain <node-name> --pod-selector='app!=critical'
```

### Cordon (Marcar Unschedulable)

```bash
# Marcar como no schedulable
kubectl cordon <node-name>

# Verificar
kubectl get nodes
# STATUS: Ready,SchedulingDisabled

# Reactivar
kubectl uncordon <node-name>
```

### Uncordon (Reactivar)

```bash
# Reactivar scheduling
kubectl uncordon <node-name>

# Verificar
kubectl get nodes
```

### Reboot de Nodo

```bash
# 1. Drain
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data

# 2. Reboot
ssh worker-01 'sudo reboot'

# 3. Esperar a que vuelva
kubectl get nodes -w

# 4. Uncordon
kubectl uncordon worker-01
```

---

## 🔐 Certificate Management

### Verificar Expiración

```bash
# Ver todos los certificados
sudo kubeadm certs check-expiration

# Verificar certificado específico
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt \
  -noout -text | grep -A 2 Validity
```

### Renovar Certificados

```bash
# Renovar todos
sudo kubeadm certs renew all

# Renovar específico
sudo kubeadm certs renew apiserver
sudo kubeadm certs renew apiserver-kubelet-client
sudo kubeadm certs renew front-proxy-client
sudo kubeadm certs renew etcd-server

# Actualizar kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config

# Reiniciar kubelet
sudo systemctl restart kubelet

# Verificar
sudo kubeadm certs check-expiration
```

### Rotación Automática de kubelet

```bash
# En /var/lib/kubelet/config.yaml
rotateCertificates: true
serverTLSBootstrap: true

# Reiniciar
sudo systemctl restart kubelet

# Ver CSRs
kubectl get csr

# Aprobar CSR
kubectl certificate approve <csr-name>
```

---

## 💾 Backup Pre-Upgrade

### Backup de etcd

```bash
# Crear snapshot
ETCDCTL_API=3 etcdctl snapshot save \
  /backup/etcd-$(date +%Y%m%d-%H%M%S).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verificar snapshot
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-*.db --write-out=table
```

### Backup de Configuraciones

```bash
# /etc/kubernetes
sudo tar -czf /backup/k8s-configs-$(date +%Y%m%d).tar.gz \
  /etc/kubernetes

# Manifiestos
sudo tar -czf /backup/manifests-$(date +%Y%m%d).tar.gz \
  /etc/kubernetes/manifests

# kubelet config
sudo cp /var/lib/kubelet/config.yaml \
  /backup/kubelet-config-$(date +%Y%m%d).yaml
```

### Backup de Recursos

```bash
# Todos los recursos
kubectl get all --all-namespaces -o yaml > \
  /backup/all-resources-$(date +%Y%m%d).yaml

# Por namespace
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
  kubectl get all -n $ns -o yaml > \
    /backup/ns-${ns}-$(date +%Y%m%d).yaml
done

# CRDs
kubectl get crd -o yaml > /backup/crds-$(date +%Y%m%d).yaml
```

---

## 🔄 Rollback

### Restore de etcd

```bash
# 1. Detener kubelet
sudo systemctl stop kubelet

# 2. Mover etcd actual
sudo mv /var/lib/etcd /var/lib/etcd.backup

# 3. Restaurar snapshot
sudo ETCDCTL_API=3 etcdctl snapshot restore \
  /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd

# 4. Fix permisos
sudo chown -R etcd:etcd /var/lib/etcd

# 5. Reiniciar kubelet
sudo systemctl start kubelet

# 6. Verificar
kubectl get nodes
kubectl get pods --all-namespaces
```

---

## 🐛 Troubleshooting Rápido

### Upgrade Fallido

```bash
# Ver logs detallados
sudo kubeadm upgrade apply v1.28.4 -v=5

# Verificar etcd
sudo ETCDCTL_API=3 etcdctl endpoint health

# Verificar API server
kubectl get --raw /healthz

# Verificar certificados
sudo kubeadm certs check-expiration

# Espacio en disco
df -h /var/lib/etcd
```

### Drain Stuck

```bash
# Ver pods que no se evacuan
kubectl get pods -o wide --all-namespaces | grep <node>

# Ver PDBs
kubectl get pdb --all-namespaces

# Describir PDB
kubectl describe pdb <pdb-name>

# Forzar drain
kubectl drain <node> --force --delete-emptydir-data
```

### Pods No Schedulan

```bash
# Verificar cordon
kubectl get nodes

# Uncordon si necesario
kubectl uncordon <node>

# Ver taints
kubectl describe node <node> | grep Taint

# Ver events
kubectl get events --sort-by='.lastTimestamp' | grep -i schedule
```

### Certificados Expirados

```bash
# Error: x509: certificate has expired

# Renovar
sudo kubeadm certs renew all

# Actualizar kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config

# Reiniciar kubelet
sudo systemctl restart kubelet
```

---

## 📏 Version Skew Policy

```
Componente              Compatible con API Server
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
kube-apiserver          n (base version)
controller-manager      n - 1
kube-scheduler          n - 1
kubelet                 n - 2
kube-proxy              n - 2
kubectl                 n - 1 to n + 1
```

**Reglas:**
- ✅ Upgrade secuencial: 1.27 → 1.28 → 1.29
- ❌ Saltar versiones: 1.27 → 1.29
- ✅ Patches: 1.28.0 → 1.28.5 (sin restricciones)
- ❌ Downgrade: NO soportado

---

## 📊 PodDisruptionBudgets

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2      # O maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
```

```bash
# Crear
kubectl apply -f pdb.yaml

# Ver
kubectl get pdb

# Describir
kubectl describe pdb app-pdb
```

---

## ✅ Checklist de Upgrade

```
PRE-UPGRADE:
□ Backup de etcd
□ Backup de /etc/kubernetes
□ Backup de recursos (kubectl get all)
□ Verificar release notes
□ Test en staging
□ Planificar maintenance window
□ Comunicar a stakeholders

DURANTE UPGRADE:
□ Upgrade control plane primero
□ Verificar health después de cada nodo
□ Monitorear logs continuamente
□ Upgrade workers uno por uno
□ Esperar pods reschedulen antes de siguiente nodo

POST-UPGRADE:
□ Verificar versiones (kubectl get nodes)
□ Verificar pods sistema (kubectl get pods -n kube-system)
□ Verificar certificados (kubeadm certs check-expiration)
□ Smoke tests (desplegar test pod)
□ Monitoring y alertas OK
□ Documentar cambios
```

---

## 🚀 Comandos de Emergencia

```bash
# Cluster no responde
sudo systemctl status kubelet
sudo systemctl status containerd
kubectl cluster-info dump

# Ver logs de kubelet
sudo journalctl -u kubelet -f

# Ver logs de containerd
sudo journalctl -u containerd -f

# Restart de servicios
sudo systemctl restart kubelet
sudo systemctl restart containerd

# Force delete de pod
kubectl delete pod <pod> --grace-period=0 --force

# Ver certificados
sudo kubeadm certs check-expiration

# Health de etcd
sudo ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

---

## 📚 Referencias Rápidas

- **Upgrade guide**: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
- **Version skew**: https://kubernetes.io/releases/version-skew-policy/
- **Certificates**: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/
- **Drain node**: https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
- **Release notes**: https://kubernetes.io/docs/setup/release/notes/

---

## 💡 Tips CKA

1. **Memoriza el orden de upgrade**: Control plane → CNI → Workers
2. **Practica drain con opciones**: `--ignore-daemonsets --delete-emptydir-data`
3. **Conoce diferencia**: `kubeadm upgrade apply` (primer master) vs `kubeadm upgrade node` (otros)
4. **Backup antes de todo**: etcd snapshot es tu salvavidas
5. **Un nodo a la vez**: Nunca draines múltiples workers simultáneamente sin capacidad
6. **Verifica version skew**: No saltes minor versions
7. **Certificados expiran**: Revisa con `kubeadm certs check-expiration`
8. **uncordon después de todo**: No olvides reactivar nodo después de mantenimiento

---

**🎯 Objetivo CKA**: ~15% del examen cubre estos temas. Domina drain, upgrade y certificados.
