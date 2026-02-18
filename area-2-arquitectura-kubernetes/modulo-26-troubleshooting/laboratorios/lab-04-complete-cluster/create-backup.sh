#!/bin/bash
# Create complete backup before Lab 04

echo "💾 Creando backup completo del cluster..."
echo ""

BACKUP_DIR="/backup/lab04-$(date +%Y%m%d-%H%M%S)"
sudo mkdir -p "$BACKUP_DIR"

echo "📁 Backup directory: $BACKUP_DIR"
echo ""

# 1. etcd backup
echo "1. Backing up etcd..."
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save "$BACKUP_DIR/etcd-snapshot.db"

if [ $? -eq 0 ]; then
  echo "   ✅ etcd backup created"
else
  echo "   ❌ etcd backup failed"
  exit 1
fi

# 2. Kubernetes manifests
echo "2. Backing up manifests..."
sudo cp -r /etc/kubernetes/manifests "$BACKUP_DIR/"
echo "   ✅ Manifests backed up"

# 3. Export all resources
echo "3. Exporting all Kubernetes resources..."
kubectl get all --all-namespaces -o yaml > "$BACKUP_DIR/all-resources.yaml"
kubectl get pv,pvc,sc --all-namespaces -o yaml > "$BACKUP_DIR/storage.yaml"
kubectl get configmaps,secrets --all-namespaces -o yaml > "$BACKUP_DIR/configs.yaml"
kubectl get networkpolicies,ingress --all-namespaces -o yaml > "$BACKUP_DIR/network.yaml"
echo "   ✅ Resources exported"

# 4. Cluster info
echo "4. Saving cluster info..."
kubectl cluster-info dump > "$BACKUP_DIR/cluster-info.txt"
kubectl get nodes -o yaml > "$BACKUP_DIR/nodes.yaml"
echo "   ✅ Cluster info saved"

echo ""
echo "✅ Backup completado!"
echo ""
echo "📊 Backup contents:"
sudo ls -lh "$BACKUP_DIR"
echo ""
echo "💡 Para restaurar:"
echo "   sudo ETCDCTL_API=3 etcdctl snapshot restore $BACKUP_DIR/etcd-snapshot.db --data-dir=/var/lib/etcd-restore"
echo ""
echo "Listo para iniciar Lab 04!"
