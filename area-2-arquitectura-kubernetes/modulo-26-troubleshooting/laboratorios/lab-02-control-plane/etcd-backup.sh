#!/bin/bash
# etcd backup script for Lab 02

echo "💾 Creando backup de etcd..."

# Create backup directory
sudo mkdir -p /backup/etcd

# Backup etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /backup/etcd/snapshot-$(date +%Y%m%d-%H%M%S).db

# Verify backup
echo "📊 Verificando backup..."
sudo ETCDCTL_API=3 etcdctl --write-out=table \
  snapshot status /backup/etcd/snapshot-*.db | tail -1

echo "✅ Backup completado en /backup/etcd/"
ls -lh /backup/etcd/
