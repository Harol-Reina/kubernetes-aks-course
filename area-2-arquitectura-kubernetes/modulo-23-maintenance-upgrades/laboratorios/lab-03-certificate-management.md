# Lab 03: Certificate Management

**Duración:** 45-60 min | **Dificultad:** ⭐⭐⭐ (Intermedio-Avanzado) | **CKA Coverage:** ~5%

## 🎯 Objetivos

- Verificar expiración de certificados
- Renovar certificados con kubeadm
- Entender certificate rotation
- Configurar automatic certificate renewal

## 📋 Exercises

### Exercise 1: Check Certificate Expiration (10 min)

```bash
# Ver todos los certificados
sudo kubeadm certs check-expiration

# Output muestra:
# - CERTIFICATE: nombre del cert
# - EXPIRES: fecha de expiración
# - RESIDUAL TIME: tiempo restante
# - CERTIFICATE AUTHORITY: CA que lo firmó

# Verificar certificado específico con openssl
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -A 2 Validity

# Ver todos los certificados en /etc/kubernetes/pki
sudo find /etc/kubernetes/pki -name "*.crt" -exec openssl x509 -noout -subject -enddate -in {} \;
```

### Exercise 2: Manual Certificate Renewal (15 min)

```bash
# Backup antes de renovar
sudo cp -r /etc/kubernetes/pki /backup/pki-$(date +%Y%m%d)

# Renovar TODOS los certificados
sudo kubeadm certs renew all

# Output mostrará:
# certificate embedded in the kubeconfig file for the admin to use and for kubeadm itself renewed
# certificate for serving the Kubernetes API renewed
# certificate the apiserver uses to access etcd renewed
# ... etc

# Verificar renovación
sudo kubeadm certs check-expiration

# Actualizar kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Reiniciar kubelet
sudo systemctl restart kubelet

# Verificar que todo funciona
kubectl get nodes
kubectl get pods -n kube-system
```

### Exercise 3: Selective Certificate Renewal (10 min)

```bash
# Renovar solo API server cert
sudo kubeadm certs renew apiserver

# Renovar solo certificados de etcd
sudo kubeadm certs renew etcd-server
sudo kubeadm certs renew etcd-peer
sudo kubeadm certs renew etcd-healthcheck-client

# Verificar
sudo kubeadm certs check-expiration | grep etcd
```

### Exercise 4: kubelet Certificate Rotation (15 min)

```bash
# Configurar rotación automática de kubelet certs
# Editar /var/lib/kubelet/config.yaml
sudo nano /var/lib/kubelet/config.yaml

# Agregar (si no existe):
# rotateCertificates: true
# serverTLSBootstrap: true

# Alternativamente, añadir al ClusterConfiguration:
cat <<EOF | sudo tee /tmp/kubelet-rotation.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
rotateCertificates: true
serverTLSBootstrap: true
EOF

# Reiniciar kubelet
sudo systemctl restart kubelet

# Verificar CSRs (Certificate Signing Requests)
kubectl get csr

# Output puede mostrar CSRs pendientes:
# NAME        AGE   SIGNERNAME                      REQUESTOR           CONDITION
# csr-xxxx    1m    kubernetes.io/kubelet-serving   system:node:worker  Pending

# Aprobar CSR
kubectl certificate approve <csr-name>

# O aprobar todos (SOLO en entorno de prueba)
kubectl get csr -o name | xargs kubectl certificate approve

# Verificar aprobados
kubectl get csr
```

### Exercise 5: Monitoring Certificate Expiration (10 min)

```bash
# Usar script de monitoreo
sudo ../scripts/cert-monitor.sh

# Ver report generado
cat /tmp/k8s-cert-report-*.txt

# Setup cron job para verificación diaria
sudo crontab -e

# Añadir:
# 0 2 * * * /path/to/cert-monitor.sh --alert-days 90 >> /var/log/cert-monitor.log 2>&1
```

## 🐛 Troubleshooting

### Problema: kubectl falla después de renovar

```bash
# Error: x509: certificate has expired or is not yet valid

# Solución: Actualizar kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
```

### Problema: API server no responde después de renovación

```bash
# Ver logs de API server
kubectl logs -n kube-system kube-apiserver-<node> --tail=50

# O con journalctl
sudo journalctl -u kubelet | grep -i cert

# Restaurar backup si es necesario
sudo cp -r /backup/pki-YYYYMMDD/* /etc/kubernetes/pki/
sudo systemctl restart kubelet
```

## ✅ Completion Criteria

- [ ] Check-expiration ejecutado exitosamente
- [ ] Todos los certificados renovados
- [ ] kubeconfig actualizado
- [ ] kubelet reiniciado sin errores
- [ ] Rotación automática configurada
- [ ] CSRs generados y aprobados
- [ ] Cluster funcional post-renovación

## 📚 Key Commands

```bash
# Check expiration
sudo kubeadm certs check-expiration

# Renew all
sudo kubeadm certs renew all

# Renew specific
sudo kubeadm certs renew apiserver

# Update kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config

# Restart kubelet
sudo systemctl restart kubelet

# View CSRs
kubectl get csr

# Approve CSR
kubectl certificate approve <csr-name>
```

**🎯 CKA Exam Tip:** Memoriza `kubeadm certs renew all` y el workflow de actualizar kubeconfig + reiniciar kubelet.
