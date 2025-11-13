# Lab 03: Backup y Restore de etcd en Kubernetes

**Duración estimada:** 45-60 minutos  
**Dificultad:** ⭐⭐⭐ Intermedio-Avanzado

## 🎯 Objetivos

Al completar este laboratorio, serás capaz de:
- ✅ Entender la importancia de backups de etcd
- ✅ Realizar backups manuales de etcd con etcdctl
- ✅ Automatizar backups con scripts y cron
- ✅ Restaurar cluster desde snapshot de etcd
- ✅ Verificar integridad de snapshots
- ✅ Implementar estrategia de DR (Disaster Recovery)

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────┐
│         Control Plane Node               │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  etcd                               │ │
│  │  /var/lib/etcd/                     │ │
│  │  ┌──────────────────────────────┐  │ │
│  │  │  Key-Value Store             │  │ │
│  │  │  - Cluster State             │  │ │
│  │  │  - ConfigMaps, Secrets       │  │ │
│  │  │  - Deployments, Services     │  │ │
│  │  │  - ALL Kubernetes Objects    │  │ │
│  │  └──────────────────────────────┘  │ │
│  └────────────────────────────────────┘ │
│           │                              │
│           │ Snapshot                     │
│           ▼                              │
│  ┌────────────────────────────────────┐ │
│  │  /var/backups/etcd/                 │ │
│  │  ├── snapshot-20250101-120000.db   │ │
│  │  ├── snapshot-20250101-180000.db   │ │
│  │  └── snapshot-20250102-000000.db   │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## 📋 Prerequisites

- Cluster Kubernetes funcional (single master o HA)
- Acceso root al control plane node
- etcdctl instalado (o instalar durante lab)
- Al menos 10GB espacio libre en /var/backups

---

## 🔧 Paso 1: Preparación y Verificación de etcd

### 1.1 Verificar Estado de etcd

```bash
# Ver pod de etcd
kubectl get pods -n kube-system -l component=etcd

# Ver logs de etcd
kubectl logs -n kube-system -l component=etcd --tail=50

# Ver configuración de etcd
kubectl describe pod -n kube-system -l component=etcd
```

### 1.2 Instalar etcdctl (si no está instalado)

```bash
# Verificar si etcdctl ya existe
which etcdctl

# Si no existe, instalar
ETCD_VERSION="v3.5.9"
wget https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
tar xzf etcd-${ETCD_VERSION}-linux-amd64.tar.gz
sudo mv etcd-${ETCD_VERSION}-linux-amd64/etcdctl /usr/local/bin/
sudo chmod +x /usr/local/bin/etcdctl

# Verificar instalación
etcdctl version
```

### 1.3 Configurar Variables de Entorno

```bash
# Crear archivo con variables para etcdctl
cat <<EOF | sudo tee /etc/profile.d/etcd.sh
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
EOF

# Cargar variables
source /etc/profile.d/etcd.sh

# Verificar acceso a etcd
sudo -E etcdctl endpoint health
sudo -E etcdctl endpoint status --write-out=table
```

**Salida esperada:**
```
127.0.0.1:2379 is healthy: successfully committed proposal
```

**✅ Checkpoint**: etcd accesible y saludable.

---

## 💾 Paso 2: Backup Manual de etcd

### 2.1 Crear Directorio de Backups

```bash
# Crear directorio
sudo mkdir -p /var/backups/etcd
sudo chmod 700 /var/backups/etcd

# Verificar espacio disponible
df -h /var/backups
```

### 2.2 Realizar Snapshot Manual

```bash
# Generar timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Crear snapshot
sudo -E etcdctl snapshot save /var/backups/etcd/snapshot-${TIMESTAMP}.db

# Verificar que se creó
ls -lh /var/backups/etcd/

# Ver tamaño del snapshot
du -h /var/backups/etcd/snapshot-${TIMESTAMP}.db
```

**Salida esperada:**
```
Snapshot saved at /var/backups/etcd/snapshot-20250113-120000.db
```

### 2.3 Verificar Integridad del Snapshot

```bash
# Verificar snapshot
sudo -E etcdctl snapshot status /var/backups/etcd/snapshot-${TIMESTAMP}.db \
  --write-out=table

# Salida esperada muestra:
# - Hash del snapshot
# - Revision number
# - Total keys
# - Total size
```

### 2.4 Comprimir Snapshot (Opcional)

```bash
# Comprimir para ahorrar espacio
sudo gzip /var/backups/etcd/snapshot-${TIMESTAMP}.db

# Verificar compresión
ls -lh /var/backups/etcd/
```

**✅ Checkpoint**: Snapshot creado y verificado.

---

## 🤖 Paso 3: Automatizar Backups con Script

### 3.1 Usar Script de Backup

```bash
# Copiar script de backup (del repositorio)
sudo cp ../scripts/etcd-backup.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/etcd-backup.sh

# Ejecutar backup manual
sudo /usr/local/bin/etcd-backup.sh backup

# Listar backups existentes
sudo /usr/local/bin/etcd-backup.sh list

# Verificar salud de etcd
sudo /usr/local/bin/etcd-backup.sh health
```

### 3.2 Configurar Cron para Backups Automáticos

```bash
# Editar crontab de root
sudo crontab -e

# Agregar líneas para backup automático

# Backup cada 6 horas
0 */6 * * * /usr/local/bin/etcd-backup.sh backup >> /var/log/etcd-backup.log 2>&1

# Backup diario a medianoche
0 0 * * * /usr/local/bin/etcd-backup.sh backup >> /var/log/etcd-backup.log 2>&1

# Cleanup semanal (domingos a las 2am)
0 2 * * 0 /usr/local/bin/etcd-backup.sh cleanup >> /var/log/etcd-backup.log 2>&1
```

### 3.3 Verificar Cron

```bash
# Ver cron jobs configurados
sudo crontab -l

# Verificar archivo de logs
sudo tail -f /var/log/etcd-backup.log

# Forzar ejecución de cron manualmente (para testing)
sudo run-parts /etc/cron.daily
```

**✅ Checkpoint**: Cron configurado para backups automáticos.

---

## 🧪 Paso 4: Crear Estado de Prueba en el Cluster

Antes de hacer restore, vamos a crear datos de prueba:

### 4.1 Crear Recursos de Prueba

```bash
# Crear namespace
kubectl create namespace backup-test

# Crear configmap con datos
kubectl create configmap test-config \
  --from-literal=key1=value1 \
  --from-literal=key2=value2 \
  -n backup-test

# Crear secret
kubectl create secret generic test-secret \
  --from-literal=password=supersecret123 \
  -n backup-test

# Crear deployment
kubectl create deployment test-app \
  --image=nginx \
  --replicas=3 \
  -n backup-test

# Crear service
kubectl expose deployment test-app \
  --port=80 \
  --type=NodePort \
  -n backup-test

# Esperar a que pods estén Ready
kubectl wait --for=condition=Ready pods --all -n backup-test --timeout=60s

# Verificar recursos
kubectl get all,cm,secret -n backup-test
```

### 4.2 Tomar Snapshot "Bueno"

```bash
# Crear snapshot ANTES de corrupción
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
sudo -E etcdctl snapshot save /var/backups/etcd/before-corruption-${TIMESTAMP}.db

# Verificar snapshot
sudo -E etcdctl snapshot status /var/backups/etcd/before-corruption-${TIMESTAMP}.db \
  --write-out=table

echo "✅ Snapshot guardado: before-corruption-${TIMESTAMP}.db"
```

### 4.3 "Corromper" el Cluster

Simularemos un desastre eliminando recursos:

```bash
# Eliminar namespace completo (¡desastre!)
kubectl delete namespace backup-test --force --grace-period=0

# Eliminar otros recursos importantes
kubectl delete ns kube-public --force --grace-period=0

# Verificar que se eliminó
kubectl get ns
kubectl get pods -n backup-test  # Debe fallar
```

**✅ Checkpoint**: Datos de prueba eliminados (desastre simulado).

---

## 🔄 Paso 5: Restaurar etcd desde Snapshot

⚠️ **ADVERTENCIA**: Este proceso detendrá temporalmente el cluster.

### 5.1 Preparación para Restore

```bash
# Detener kubelet (para evitar conflictos)
sudo systemctl stop kubelet

# Verificar que kubelet está detenido
sudo systemctl status kubelet

# Mover directorio etcd actual (backup de seguridad)
sudo mv /var/lib/etcd /var/lib/etcd.backup.$(date +%Y%m%d-%H%M%S)

# Verificar que se movió
ls -la /var/lib/ | grep etcd
```

### 5.2 Restaurar Snapshot

```bash
# Identificar snapshot a restaurar
ls -lh /var/backups/etcd/

# Descomprimir si está comprimido
# sudo gunzip /var/backups/etcd/before-corruption-*.db.gz

# Restaurar snapshot
sudo -E etcdctl snapshot restore /var/backups/etcd/before-corruption-*.db \
  --data-dir=/var/lib/etcd-restore \
  --name=k8s-master-01 \
  --initial-cluster=k8s-master-01=https://192.168.1.10:2380 \
  --initial-advertise-peer-urls=https://192.168.1.10:2380

# ⚠️ Para cluster HA con 3 masters, ajustar:
# --initial-cluster=k8s-master-01=https://192.168.1.10:2380,k8s-master-02=https://192.168.1.11:2380,k8s-master-03=https://192.168.1.12:2380
```

**Salida esperada:**
```
2025-01-13 12:00:00.123456 I | mvcc: restore compact to 12345
2025-01-13 12:00:00.234567 I | etcdserver/membership: added member abc123 [https://192.168.1.10:2380]
```

### 5.3 Mover Datos Restaurados

```bash
# Mover datos restaurados a ubicación correcta
sudo mv /var/lib/etcd-restore /var/lib/etcd

# Verificar permisos
sudo chown -R root:root /var/lib/etcd
sudo chmod 700 /var/lib/etcd

# Verificar contenido
ls -la /var/lib/etcd/member/
```

### 5.4 Reiniciar Servicios

```bash
# Reiniciar kubelet
sudo systemctl start kubelet

# Verificar que kubelet está running
sudo systemctl status kubelet

# Ver logs de kubelet
sudo journalctl -u kubelet -f
```

**✅ Checkpoint**: kubelet reiniciado sin errores.

---

## ✅ Paso 6: Verificar Restauración

### 6.1 Verificar Componentes del Sistema

```bash
# Esperar a que pods del sistema estén Ready (2-3 minutos)
watch kubectl get pods -n kube-system

# Verificar nodos
kubectl get nodes

# Verificar endpoints
kubectl get endpoints -n kube-system
```

### 6.2 Verificar Datos Restaurados

```bash
# Verificar namespace backup-test restaurado
kubectl get ns | grep backup-test

# Verificar recursos en backup-test
kubectl get all,cm,secret -n backup-test

# Verificar configmap
kubectl get configmap test-config -n backup-test -o yaml

# Verificar secret
kubectl get secret test-secret -n backup-test -o yaml

# Verificar pods running
kubectl get pods -n backup-test -o wide
```

**Salida esperada:**
- Namespace `backup-test` existe
- ConfigMap `test-config` con key1=value1, key2=value2
- Secret `test-secret` existe
- Deployment con 3 réplicas Running
- Service tipo NodePort

### 6.3 Test Funcional

```bash
# Probar acceso a la aplicación
kubectl get svc test-app -n backup-test

# Port-forward para probar
kubectl port-forward -n backup-test svc/test-app 8080:80 &

# Probar con curl
curl http://localhost:8080

# Matar port-forward
pkill -f "port-forward"
```

**✅ Checkpoint**: Todos los recursos restaurados correctamente.

---

## 📊 Paso 7: Validaciones y Best Practices

### 7.1 Verificar Integridad Post-Restore

```bash
# Ver estado de etcd
sudo -E etcdctl endpoint health
sudo -E etcdctl endpoint status --write-out=table

# Ver todos los keys en etcd (solo sample)
sudo -E etcdctl get / --prefix --keys-only | head -20

# Contar total de keys
sudo -E etcdctl get / --prefix --keys-only | wc -l

# Ver tamaño de etcd
du -sh /var/lib/etcd/
```

### 7.2 Comparar Snapshots

```bash
# Listar todos los snapshots
ls -lh /var/backups/etcd/

# Comparar status de dos snapshots
sudo -E etcdctl snapshot status /var/backups/etcd/snapshot-1.db --write-out=json > snap1.json
sudo -E etcdctl snapshot status /var/backups/etcd/snapshot-2.db --write-out=json > snap2.json

# Ver diferencias
diff snap1.json snap2.json
```

### 7.3 Test de Backup Completo (End-to-End)

```bash
# 1. Tomar snapshot inicial
sudo /usr/local/bin/etcd-backup.sh backup

# 2. Crear nuevo recurso
kubectl create namespace test-e2e
kubectl create configmap test-e2e-cm --from-literal=test=e2e -n test-e2e

# 3. Tomar snapshot con nuevo recurso
sudo /usr/local/bin/etcd-backup.sh backup

# 4. Eliminar recurso
kubectl delete ns test-e2e

# 5. Restaurar snapshot (ver Paso 5)

# 6. Verificar que recurso está de vuelta
kubectl get ns test-e2e
kubectl get cm -n test-e2e
```

---

## 🎓 Desafíos Opcionales

### Desafío 1: Backup Remoto

Enviar backups a storage remoto (S3, NFS, etc.):

```bash
# Ejemplo con rsync a servidor remoto
rsync -avz /var/backups/etcd/ backup-server:/backups/k8s-etcd/

# Ejemplo con AWS S3
aws s3 sync /var/backups/etcd/ s3://my-bucket/k8s-backups/etcd/
```

### Desafío 2: Backup en Cluster HA

Restaurar en cluster con múltiples control planes:

```bash
# En CADA control plane, restaurar con configuración de cluster
sudo -E etcdctl snapshot restore /path/to/snapshot.db \
  --data-dir=/var/lib/etcd-restore \
  --name=k8s-master-0X \
  --initial-cluster=k8s-master-01=https://192.168.1.10:2380,k8s-master-02=https://192.168.1.11:2380,k8s-master-03=https://192.168.1.12:2380 \
  --initial-advertise-peer-urls=https://192.168.1.1X:2380
```

### Desafío 3: Monitoreo de Backups

Configurar alertas para fallos de backup:

```bash
# Crear script de verificación
cat <<'EOF' > /usr/local/bin/check-backup-age.sh
#!/bin/bash
LAST_BACKUP=$(ls -t /var/backups/etcd/*.db.gz | head -1)
AGE=$(( $(date +%s) - $(stat -c %Y "$LAST_BACKUP") ))
MAX_AGE=21600  # 6 horas

if [ $AGE -gt $MAX_AGE ]; then
  echo "CRITICAL: Last backup is $(($AGE/3600)) hours old"
  exit 2
fi
echo "OK: Last backup is $(($AGE/3600)) hours old"
EOF

chmod +x /usr/local/bin/check-backup-age.sh

# Ejecutar check
/usr/local/bin/check-backup-age.sh
```

---

## 🧹 Limpieza

```bash
# Eliminar namespace de prueba
kubectl delete namespace backup-test

# Limpiar backups antiguos (mantener últimos 3)
sudo /usr/local/bin/etcd-backup.sh cleanup

# O manualmente
sudo find /var/backups/etcd/ -name "*.db.gz" -mtime +7 -delete

# Eliminar backup de etcd anterior
sudo rm -rf /var/lib/etcd.backup.*
```

---

## 🐛 Troubleshooting

### Problema: Snapshot falla con "permission denied"

```bash
# Verificar permisos
ls -la /var/backups/etcd/

# Ajustar permisos
sudo chmod 700 /var/backups/etcd
sudo chown -R root:root /var/backups/etcd
```

### Problema: Restore falla con "cluster mismatch"

```bash
# Verificar que --initial-cluster coincide con configuración actual
cat /etc/kubernetes/manifests/etcd.yaml | grep initial-cluster

# Ajustar comando de restore con valores correctos
```

### Problema: Cluster no arranca después de restore

```bash
# Ver logs de etcd
sudo journalctl -u kubelet -f | grep etcd

# Ver logs de pod etcd
kubectl logs -n kube-system -l component=etcd --previous

# Verificar permisos de /var/lib/etcd
ls -la /var/lib/etcd/

# Si falla, restaurar backup original
sudo rm -rf /var/lib/etcd
sudo mv /var/lib/etcd.backup.TIMESTAMP /var/lib/etcd
sudo systemctl restart kubelet
```

---

## 📚 Recursos Adicionales

- [etcd Disaster Recovery](https://etcd.io/docs/v3.5/op-guide/recovery/)
- [Kubernetes etcd Backup](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)
- [etcdctl Documentation](https://etcd.io/docs/v3.5/dev-guide/interacting_v3/)

---

## ✅ Criterios de Completitud

Has completado exitosamente este lab si:
- [ ] Puedes crear snapshots manualmente con etcdctl
- [ ] Script de backup automatizado funciona
- [ ] Cron job configurado para backups periódicos
- [ ] Puedes restaurar cluster desde snapshot
- [ ] Datos restaurados coinciden con estado original
- [ ] Entiendes el proceso de DR de Kubernetes

**¡Felicitaciones!** 🎉 Tienes estrategia de backup/restore implementada.

**Próximo paso:** [Lab 04: Troubleshooting Common Issues](./lab-04-troubleshooting.md)
