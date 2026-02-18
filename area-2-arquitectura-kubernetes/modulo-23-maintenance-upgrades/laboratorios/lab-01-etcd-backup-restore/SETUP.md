# ⚙️ Setup - Lab 01: etcd Backup y Restore

**Tiempo estimado de setup:** 10-15 minutos

---

## 📋 Prerequisitos del Sistema

### Hardware Mínimo

| Recurso | Control Plane | Worker Nodes |
|---------|---------------|--------------|
| **CPU** | 2 cores | 1 core |
| **RAM** | 2 GB | 1 GB |
| **Disco** | 20 GB libre | 10 GB libre |
| **Red** | Conectividad entre nodos | - |

### Software Requerido

- ✅ **Sistema Operativo**: Ubuntu 20.04/22.04 LTS o CentOS 8+
- ✅ **Kubernetes**: v1.27+ instalado con kubeadm
- ✅ **Container Runtime**: containerd o Docker
- ✅ **etcdctl**: v3.5+ (incluido en binarios de K8s)
- ✅ **Acceso**: SSH y sudo al nodo control plane

---

## 🔍 Verificación de Prerequisitos

### Paso 1: Verificar Cluster Kubernetes

```bash
# Verificar nodos
kubectl get nodes
```

**✅ Output esperado:**
```
NAME               STATUS   ROLES           AGE   VERSION
k8s-control-plane  Ready    control-plane   10d   v1.28.0
k8s-worker-01      Ready    <none>          10d   v1.28.0
```

### Paso 2: Verificar Acceso a Control Plane

```bash
# SSH al control plane (si es remoto)
ssh user@<control-plane-ip>

# Verificar permisos sudo
sudo whoami
# root
```

### Paso 3: Verificar etcd está corriendo

```bash
# Método 1: Verificar pod de etcd
kubectl get pods -n kube-system | grep etcd

# Método 2: Verificar proceso etcd (en control plane)
ps aux | grep etcd | grep -v grep

# Método 3: Verificar con crictl (en control plane)
sudo crictl ps | grep etcd
```

**✅ Output esperado:**
```
CONTAINER           IMAGE               CREATED             STATE               NAME
1a2b3c4d5e6f        etcd:3.5.9-0        10 days ago         Running             etcd
```

### Paso 4: Verificar etcdctl instalado

```bash
# Verificar versión de etcdctl
ETCDCTL_API=3 etcdctl version
```

**✅ Output esperado:**
```
etcdctl version: 3.5.9
API version: 3.5
```

**Si no está instalado:**

```bash
# Ubuntu/Debian
ETCD_VER=v3.5.10
wget https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzf etcd-${ETCD_VER}-linux-amd64.tar.gz
sudo mv etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/
sudo chmod +x /usr/local/bin/etcdctl
rm -rf etcd-${ETCD_VER}-linux-amd64*
```

### Paso 5: Verificar Certificados de etcd

```bash
# Listar certificados
sudo ls -l /etc/kubernetes/pki/etcd/
```

**✅ Output esperado:**
```
-rw-r--r-- 1 root root 1139 Nov  3 10:00 ca.crt
-rw------- 1 root root 1675 Nov  3 10:00 ca.key
-rw-r--r-- 1 root root 1172 Nov  3 10:00 peer.crt
-rw------- 1 root root 1679 Nov  3 10:00 peer.key
-rw-r--r-- 1 root root 1172 Nov  3 10:00 server.crt
-rw------- 1 root root 1679 Nov  3 10:00 server.key
```

**Archivos críticos:**
- `ca.crt` - Certificate Authority
- `server.crt` - Certificado del servidor etcd
- `server.key` - Llave privada del servidor

### Paso 6: Verificar Conectividad a etcd

```bash
# Exportar variables de entorno
export ETCDCTL_API=3
export ETCD_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCD_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCD_KEY=/etc/kubernetes/pki/etcd/server.key
export ETCD_ENDPOINTS=https://127.0.0.1:2379

# Verificar salud de etcd
sudo etcdctl endpoint health \
  --cacert=$ETCD_CACERT \
  --cert=$ETCD_CERT \
  --key=$ETCD_KEY \
  --endpoints=$ETCD_ENDPOINTS
```

**✅ Output esperado:**
```
https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.345ms
```

### Paso 7: Verificar Espacio en Disco

```bash
# Verificar espacio disponible para backups
df -h /var/lib

# Verificar tamaño actual de etcd
sudo du -sh /var/lib/etcd
```

**✅ Requisitos:**
- Al menos **500 MB libres** en `/var/lib` para backups
- Tamaño de etcd varía (típicamente 50-200 MB en clusters pequeños)

---

## 🛠️ Configuración del Entorno

### Paso 1: Crear Directorio de Backups

```bash
# Crear directorio con permisos restrictivos
sudo mkdir -p /var/lib/etcd-backup
sudo chmod 700 /var/lib/etcd-backup
sudo chown root:root /var/lib/etcd-backup

# Verificar
ls -ld /var/lib/etcd-backup
# drwx------ 2 root root 4096 Nov 13 10:00 /var/lib/etcd-backup
```

### Paso 2: Configurar Variables de Entorno Permanentes

```bash
# Agregar al perfil de bash (opcional pero recomendado)
cat << 'EOF' | sudo tee -a /root/.bashrc
# etcd configuration
export ETCDCTL_API=3
export ETCD_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCD_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCD_KEY=/etc/kubernetes/pki/etcd/server.key
export ETCD_ENDPOINTS=https://127.0.0.1:2379
EOF

# Recargar configuración
sudo bash -c "source /root/.bashrc"
```

### Paso 3: Crear Script de Helper

```bash
# Script para facilitar comandos etcdctl
cat << 'EOF' | sudo tee /usr/local/bin/etcdctl-helper
#!/bin/bash
export ETCDCTL_API=3
etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379 \
  "$@"
EOF

sudo chmod +x /usr/local/bin/etcdctl-helper

# Uso del helper
# sudo etcdctl-helper endpoint health
# sudo etcdctl-helper snapshot save /backup/test.db
```

---

## 📊 Obtener Información del Cluster etcd

### Información Básica

```bash
# Obtener endpoint status
sudo etcdctl-helper endpoint status --write-out=table

# Listar miembros del cluster etcd
sudo etcdctl-helper member list --write-out=table

# Ver configuración de etcd desde manifest
sudo cat /etc/kubernetes/manifests/etcd.yaml
```

### Variables Importantes a Documentar

**Guarda esta información para uso durante el lab:**

```bash
# Ejecutar en el control plane
echo "=== ETCD CONFIGURATION ==="
echo "Endpoint: $(grep -A1 'advertise-client-urls' /etc/kubernetes/manifests/etcd.yaml | tail -1 | awk '{print $2}')"
echo "Data Dir: $(grep -A1 'data-dir' /etc/kubernetes/manifests/etcd.yaml | tail -1 | awk '{print $2}')"
echo "CA Cert: /etc/kubernetes/pki/etcd/ca.crt"
echo "Server Cert: /etc/kubernetes/pki/etcd/server.crt"
echo "Server Key: /etc/kubernetes/pki/etcd/server.key"
echo ""
echo "=== ETCD STATUS ==="
sudo etcdctl-helper endpoint status --write-out=table
```

---

## 🔒 Consideraciones de Seguridad

### Permisos de Archivos

```bash
# Verificar que los certificados tienen permisos restrictivos
sudo chmod 600 /etc/kubernetes/pki/etcd/*.key
sudo chmod 644 /etc/kubernetes/pki/etcd/*.crt

# Verificar permisos
sudo ls -l /etc/kubernetes/pki/etcd/
```

### Acceso SSH

```bash
# Si usas cluster remoto, configurar SSH key-based auth
ssh-copy-id user@control-plane-ip

# Verificar acceso sin password
ssh user@control-plane-ip "hostname"
```

### Backup de Manifest Original

```bash
# IMPORTANTE: Backup del manifest de etcd antes de modificar
sudo cp /etc/kubernetes/manifests/etcd.yaml \
       /root/etcd-manifest-backup-$(date +%Y%m%d).yaml

# Verificar backup
sudo ls -l /root/etcd-manifest-backup-*.yaml
```

---

## 🧪 Tests de Validación Pre-Lab

### Test 1: Conectividad etcd

```bash
# Debe retornar "healthy"
sudo etcdctl-helper endpoint health
```

### Test 2: Permisos de escritura

```bash
# Debe crear archivo sin errores
sudo touch /var/lib/etcd-backup/test.tmp
sudo rm /var/lib/etcd-backup/test.tmp
```

### Test 3: Snapshot de prueba

```bash
# Crear snapshot de prueba pequeño
sudo etcdctl-helper snapshot save /var/lib/etcd-backup/test-snapshot.db

# Verificar que se creó
ls -lh /var/lib/etcd-backup/test-snapshot.db

# Verificar integridad
sudo etcdctl-helper snapshot status /var/lib/etcd-backup/test-snapshot.db

# Limpiar
sudo rm /var/lib/etcd-backup/test-snapshot.db
```

---

## 🚨 Troubleshooting de Setup

### Problema: etcdctl no encontrado

```bash
# Verificar instalación
which etcdctl

# Si no existe, instalar desde binarios de K8s
sudo cp /var/lib/minikube/binaries/v1.28.0/etcdctl /usr/local/bin/
# O descargar desde GitHub (ver Paso 4 arriba)
```

### Problema: Permission denied en certificados

```bash
# Ejecutar con sudo
sudo etcdctl-helper endpoint health

# O agregar usuario actual al grupo root (NO recomendado en producción)
```

### Problema: "connection refused" a etcd

```bash
# Verificar que etcd está corriendo
sudo crictl ps | grep etcd

# Verificar endpoint correcto
sudo grep advertise-client-urls /etc/kubernetes/manifests/etcd.yaml

# Verificar firewall (si aplica)
sudo ufw status
```

### Problema: Espacio insuficiente en disco

```bash
# Limpiar espacio si es necesario
sudo apt-get clean  # Ubuntu/Debian
sudo yum clean all  # CentOS/RHEL

# Eliminar logs antiguos
sudo journalctl --vacuum-time=7d

# Verificar espacio de nuevo
df -h /var/lib
```

---

## ✅ Checklist Final de Setup

Antes de comenzar el laboratorio, verifica:

- [ ] Cluster Kubernetes funcional (kubectl get nodes)
- [ ] Acceso SSH al control plane con sudo
- [ ] etcd corriendo (kubectl get pods -n kube-system | grep etcd)
- [ ] etcdctl instalado y funcional (etcdctl version)
- [ ] Certificados presentes en `/etc/kubernetes/pki/etcd/`
- [ ] Conectividad a etcd (etcdctl endpoint health)
- [ ] Directorio `/var/lib/etcd-backup` creado con permisos 700
- [ ] Al menos 500 MB libres en `/var/lib`
- [ ] Variables de entorno configuradas
- [ ] Backup del manifest original de etcd creado

---

## 📚 Información Adicional del Cluster

### Para Minikube (Lab Local)

```bash
# Acceder al nodo de Minikube
minikube ssh

# Dentro del nodo, convertirse en root
sudo su -

# Los certificados están en:
ls /var/lib/minikube/certs/etcd/
```

### Para kubeadm (Cluster Real)

```bash
# Los certificados están en:
ls /etc/kubernetes/pki/etcd/

# El manifest de etcd está en:
cat /etc/kubernetes/manifests/etcd.yaml

# Data dir de etcd (típicamente):
/var/lib/etcd
```

### Para Clusters Managed (EKS, GKE, AKS)

⚠️ **IMPORTANTE**: En clusters managed, **no tienes acceso directo a etcd**.

- Los backups se realizan automáticamente por el provider
- Para practicar este lab, usa kubeadm o minikube
- Para el examen CKA, solo pregunta sobre clusters self-managed

---

## 🎯 Siguiente Paso

Una vez completado este setup exitosamente:

➡️ **[Continuar al Lab 01: README.md principal](./README.md)**

---

**⏱️ Tiempo de setup:** 10-15 minutos  
**🔧 Dificultad:** ⭐⭐ Intermedia  
**✅ Prerequisito para:** Lab 01 etcd backup/restore

---

*Setup guide creado para Módulo 23: Maintenance & Upgrades*  
*Versión: 1.0 | Fecha: 2025-11-13*
