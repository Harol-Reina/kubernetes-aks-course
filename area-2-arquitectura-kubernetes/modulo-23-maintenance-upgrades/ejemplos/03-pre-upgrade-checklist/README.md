# Pre-Upgrade Checklist

## 📋 Planning Phase

### 1. Documentation Review
- [ ] Read release notes for target version
- [ ] Review breaking changes and deprecations
- [ ] Check upgrade guide for specific version
- [ ] Identify component changes (API versions, etc.)
- [ ] Document current cluster state

### 2. Version Verification
- [ ] Verify current Kubernetes version: `kubectl version --short`
- [ ] Verify current kubeadm version: `kubeadm version`
- [ ] Confirm target version is valid (no skipped minor versions)
- [ ] Check version skew policy compatibility
- [ ] Verify OS and kernel compatibility

### 3. Cluster Health Check
- [ ] All nodes Ready: `kubectl get nodes`
- [ ] All system pods Running: `kubectl get pods -n kube-system`
- [ ] No pods in Pending/Error state
- [ ] etcd healthy: `etcdctl endpoint health`
- [ ] API server responding: `kubectl get --raw /healthz`
- [ ] CoreDNS functioning: Test DNS resolution
- [ ] No active alerts in monitoring system

### 4. Capacity Planning
- [ ] Sufficient disk space on all nodes (min 10GB free)
- [ ] Adequate memory available (check node pressure)
- [ ] Verify worker capacity for draining (N-1 capacity)
- [ ] Check PodDisruptionBudgets won't block drain
- [ ] Plan node drain order

---

## 💾 Backup Phase

### 5. etcd Backup
```bash
ETCDCTL_API=3 etcdctl snapshot save \
  /backup/etcd-pre-upgrade-$(date +%Y%m%d-%H%M%S).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

- [ ] etcd snapshot created
- [ ] Snapshot integrity verified: `etcdctl snapshot status`
- [ ] Snapshot copied to safe location (off-server)
- [ ] Backup size verified (> 0 bytes)

### 6. Configuration Backup
```bash
sudo tar -czf /backup/k8s-configs-$(date +%Y%m%d).tar.gz /etc/kubernetes
sudo cp /var/lib/kubelet/config.yaml /backup/kubelet-config-$(date +%Y%m%d).yaml
```

- [ ] /etc/kubernetes backed up
- [ ] /etc/kubernetes/manifests backed up
- [ ] kubelet config backed up
- [ ] CNI config backed up (/etc/cni/net.d/)
- [ ] containerd/Docker config backed up

### 7. Resource Backup
```bash
kubectl get all --all-namespaces -o yaml > /backup/all-resources-$(date +%Y%m%d).yaml
kubectl get crd -o yaml > /backup/crds-$(date +%Y%m%d).yaml
```

- [ ] All resources exported
- [ ] CRDs exported
- [ ] ConfigMaps backed up
- [ ] Secrets backed up (if necessary)
- [ ] PersistentVolumes noted

---

## 🧪 Testing Phase

### 8. Staging Environment Test
- [ ] Staging cluster matches production (version, config, workloads)
- [ ] Upgrade performed successfully in staging
- [ ] Applications tested post-upgrade
- [ ] Performance metrics verified
- [ ] Rollback tested in staging
- [ ] Issues documented and resolved

### 9. Communication
- [ ] Stakeholders notified of maintenance window
- [ ] On-call team alerted
- [ ] Rollback plan communicated
- [ ] Expected downtime communicated (if any)
- [ ] Status page updated

---

## ⬆️ Upgrade Phase

### 10. Pre-Upgrade Actions
- [ ] Maintenance mode enabled (if applicable)
- [ ] Monitoring dashboards prepared
- [ ] Terminal multiplexer started (tmux/screen)
- [ ] Logs being collected: `kubectl get events -w`
- [ ] Second terminal ready for troubleshooting

### 11. Control Plane Upgrade (First Master)
```bash
# Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.4-00
sudo apt-mark hold kubeadm

# Plan upgrade
sudo kubeadm upgrade plan

# Apply upgrade
sudo kubeadm upgrade apply v1.28.4

# Drain node
kubectl drain <control-plane> --ignore-daemonsets

# Upgrade kubelet & kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.28.4-00 kubectl=1.28.4-00
sudo apt-mark hold kubelet kubectl

# Restart & uncordon
sudo systemctl daemon-reload
sudo systemctl restart kubelet
kubectl uncordon <control-plane>
```

- [ ] kubeadm upgraded
- [ ] `kubeadm upgrade plan` reviewed
- [ ] Control plane upgraded successfully
- [ ] Node drained
- [ ] kubelet/kubectl upgraded
- [ ] kubelet restarted
- [ ] Node uncordoned
- [ ] All control plane pods Running
- [ ] API server accessible

### 12. Additional Control Planes (HA only)
For each additional control plane:
```bash
# On additional master
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.28.4-00
sudo apt-mark hold kubeadm
sudo kubeadm upgrade node

# From first master
kubectl drain <additional-master> --ignore-daemonsets

# On additional master
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.28.4-00 kubectl=1.28.4-00
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# From first master
kubectl uncordon <additional-master>
```

- [ ] Master 2 upgraded
- [ ] Master 3 upgraded (if applicable)
- [ ] etcd quorum maintained throughout
- [ ] Leader election working

### 13. CNI Plugin Upgrade (if needed)
- [ ] CNI plugin version compatibility checked
- [ ] CNI manifests updated
- [ ] CNI pods restarted
- [ ] Network connectivity verified

### 14. Worker Nodes Upgrade
For each worker:
```bash
# From control plane
kubectl drain <worker> --ignore-daemonsets --delete-emptydir-data

# On worker
sudo apt-mark unhold kubeadm kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.4-00 kubelet=1.28.4-00 kubectl=1.28.4-00
sudo apt-mark hold kubeadm kubelet kubectl
sudo kubeadm upgrade node
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# From control plane
kubectl uncordon <worker>
```

- [ ] Worker 1 upgraded and verified
- [ ] Worker 2 upgraded and verified
- [ ] Worker 3 upgraded and verified
- [ ] (Continue for all workers)
- [ ] Pods rescheduled correctly
- [ ] No pods in ImagePullBackOff or CrashLoopBackOff

---

## ✅ Post-Upgrade Verification

### 15. Cluster Verification
```bash
# Version check
kubectl get nodes -o wide

# System pods
kubectl get pods -n kube-system

# All pods
kubectl get pods --all-namespaces | grep -v Running

# Component health
kubectl get componentstatuses  # Deprecated 1.28+

# Events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -50
```

- [ ] All nodes showing new version
- [ ] All nodes in Ready state
- [ ] All kube-system pods Running
- [ ] No unexpected pod restarts
- [ ] No error events
- [ ] etcd healthy

### 16. Application Verification
- [ ] Sample deployment created and deleted
- [ ] Service discovery working
- [ ] Ingress routing working
- [ ] Persistent volumes accessible
- [ ] Application endpoints responding
- [ ] Application logs normal

### 17. Smoke Tests
```bash
# Create test deployment
kubectl create deployment test-upgrade --image=nginx
kubectl expose deployment test-upgrade --port=80

# Verify
kubectl get deployment test-upgrade
kubectl get pods -l app=test-upgrade
kubectl get svc test-upgrade

# Cleanup
kubectl delete deployment test-upgrade
kubectl delete svc test-upgrade
```

- [ ] Deployment creation successful
- [ ] Pods scheduled and running
- [ ] Service created
- [ ] Cleanup successful

### 18. Certificate Check
```bash
sudo kubeadm certs check-expiration
```

- [ ] No certificates expired
- [ ] All certificates valid for >90 days
- [ ] CA certificates valid

### 19. Monitoring & Metrics
- [ ] Prometheus scraping all targets
- [ ] Grafana dashboards showing data
- [ ] Metrics-server working: `kubectl top nodes`
- [ ] Custom metrics available
- [ ] Alerting rules functioning

---

## 📝 Documentation & Cleanup

### 20. Post-Upgrade Tasks
- [ ] Update cluster documentation with new version
- [ ] Update runbooks if procedures changed
- [ ] Document any issues encountered
- [ ] Document solutions applied
- [ ] Update disaster recovery procedures

### 21. Backup Retention
- [ ] Pre-upgrade backups verified and retained
- [ ] Backup retention policy applied
- [ ] Old backups cleaned up (if policy allows)

### 22. Communication
- [ ] Stakeholders notified of successful upgrade
- [ ] On-call team updated
- [ ] Status page updated (maintenance complete)
- [ ] Post-mortem scheduled (if issues occurred)

---

## 🚨 Rollback Plan

If upgrade fails:

### Option 1: Restore etcd
```bash
sudo systemctl stop kubelet
sudo mv /var/lib/etcd /var/lib/etcd.failed
sudo ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd
sudo systemctl start kubelet
```

### Option 2: Package Rollback (NOT RECOMMENDED)
```bash
# Only if etcd restore not possible
sudo apt-get install -y kubeadm=1.27.x-00 kubelet=1.27.x-00 kubectl=1.27.x-00
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### Rollback Checklist
- [ ] Rollback decision made
- [ ] Stakeholders notified
- [ ] etcd snapshot restored
- [ ] Cluster verified after rollback
- [ ] Applications verified
- [ ] Incident documented

---

## 📊 Checklist Summary

**Total Items:** 100+

**Completion:**
- Planning: ___ / 15
- Backup: ___ / 12
- Testing: ___ / 7
- Upgrade: ___ / 35
- Verification: ___ / 25
- Documentation: ___ / 6

**Sign-off:**
- Prepared by: _________________ Date: _______
- Reviewed by: _________________ Date: _______
- Executed by: _________________ Date: _______
