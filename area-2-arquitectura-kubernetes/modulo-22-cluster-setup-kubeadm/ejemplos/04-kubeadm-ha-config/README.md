# Ejemplo 04: Kubeadm HA Configuration

## 🎯 Objetivo
Configuración para cluster Kubernetes de Alta Disponibilidad (multi-master).

## 📝 Descripción
Kubeadm config para HA cluster con:
- Múltiples control plane nodes
- Load balancer endpoint
- etcd externo o stacked
- Certificados compartidos

## 🚀 Uso

```bash
# En el PRIMER control plane node
sudo kubeadm init --config kubeadm-ha-config.yaml --upload-certs

# Guardar el comando de join que se muestra para:
# - Otros control plane nodes (con --control-plane flag)
# - Worker nodes

# En OTROS control plane nodes
sudo kubeadm join <lb-endpoint>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane --certificate-key <cert-key>

# En worker nodes
sudo kubeadm join <lb-endpoint>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

## 📊 Configuraciones HA

- `controlPlaneEndpoint`: Load balancer VIP/DNS
- `certificateKey`: Para compartir certs entre masters
- `uploadCerts: true`: Sube certs a cluster
- etcd stacked o externo

## 🏗️ Arquitectura HA

```
          Load Balancer (VIP)
                |
    +-----------+-----------+
    |           |           |
  Master1    Master2    Master3
    |           |           |
    +-----etcd cluster------+
                |
        +--------------+
        |              |
     Worker1       Worker2
```

## ⚠️ Prerequisitos HA

- Load balancer configurado (HAProxy, NGINX, cloud LB)
- Mínimo 3 control plane nodes (quorum de etcd)
- Shared storage o NFS para HA (opcional)

[Volver a ejemplos](../README.md)
