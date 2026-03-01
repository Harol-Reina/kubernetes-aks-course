# Resumen Rapido: Cluster Setup con kubeadm

**Duracion:** 15 minutos | **Nivel:** Repaso | **Archivo:** `kubeadm-lab.yaml`

Este laboratorio resume los conceptos clave del Modulo 22: setup de clusters Kubernetes con kubeadm. Cubre las tres topologias principales (basico, HA stacked, HA external etcd) y proporciona una verificacion rapida del cluster.

---

## Resumen Conceptual

### Topologias de Cluster

| Topologia | Control Planes | etcd | Nodos Minimos | Uso |
|-----------|---------------|------|---------------|-----|
| **Single Master** | 1 | Stacked (local) | 1 + workers | Dev/Test |
| **HA Stacked** | 3+ | En cada CP | 3 + LB + workers | Produccion |
| **HA External** | 3+ | Cluster dedicado | 3 CP + 3 etcd + LB | Enterprise |

### Flujo de kubeadm init

```
1. Pre-flight checks
   ├── Swap deshabilitado
   ├── Puertos disponibles (6443, 2379-2380, 10250)
   ├── Container runtime (containerd)
   └── Modulos kernel (overlay, br_netfilter)

2. Generacion de certificados
   ├── CA del cluster
   ├── API Server certs
   ├── etcd certs
   └── Service Account keys

3. Static Pod manifests
   ├── kube-apiserver
   ├── kube-controller-manager
   ├── kube-scheduler
   └── etcd (solo en stacked)

4. kubeconfig files
   ├── admin.conf
   ├── kubelet.conf
   ├── controller-manager.conf
   └── scheduler.conf

5. Bootstrap tokens → Para worker join
6. Addons → CoreDNS + kube-proxy
```

### Comparativa de Configuraciones kubeadm

```
CLUSTER BASICO (Lab 01):
├── controlPlaneEndpoint: "<NODE_IP>:6443"
├── etcd: local
└── Calico CNI (podSubnet: 192.168.0.0/16)

CLUSTER HA STACKED (Lab 03):
├── controlPlaneEndpoint: "<LB_IP>:6443"  ← Load Balancer!
├── etcd: local (en cada control plane)
├── --upload-certs (compartir certificados)
└── HAProxy como Load Balancer

CLUSTER HA EXTERNAL ETCD (Lab 04):
├── controlPlaneEndpoint: "<LB_IP>:6443"
├── etcd: external
│   ├── endpoints: [etcd-01:2379, etcd-02:2379, etcd-03:2379]
│   ├── caFile, certFile, keyFile (TLS mutuo)
│   └── Cluster etcd dedicado con systemd
└── cfssl para generar certificados
```

---

## Tabla Comparativa: Comandos Clave

| Operacion | Comando |
|-----------|---------|
| Inicializar cluster | `sudo kubeadm init --config kubeadm-config.yaml` |
| Inicializar HA | `sudo kubeadm init --config config.yaml --upload-certs` |
| Configurar kubectl | `mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config` |
| Instalar CNI | `kubectl apply -f calico.yaml` |
| Generar join command | `kubeadm token create --print-join-command` |
| Join worker | `sudo kubeadm join <IP>:6443 --token <T> --discovery-token-ca-cert-hash sha256:<H>` |
| Join control plane | `sudo kubeadm join <LB>:6443 --token <T> --discovery-token-ca-cert-hash sha256:<H> --control-plane --certificate-key <K>` |
| Verificar cluster | `kubectl get nodes -o wide` |
| Verificar etcd | `etcdctl --endpoints=... member list` |
| Verificar certs | `sudo kubeadm certs check-expiration` |
| Reset cluster | `sudo kubeadm reset -f` |

---

## Ejercicio Practico (15 min)

### Paso 1: Verificar Cluster (2 min)

Asegurate de tener un cluster funcional (cualquier topologia):

```bash
# Verificar nodos
kubectl get nodes -o wide

# Verificar componentes del sistema
kubectl get pods -n kube-system

# Verificar API Server health
kubectl get --raw /healthz
```

### Paso 2: Desplegar Recursos de Verificacion (1 min)

```bash
# Aplicar recursos de prueba
kubectl apply -f kubeadm-lab.yaml

# Verificar namespace creado
kubectl get namespace lab-kubeadm-test
```

### Paso 3: Verificar Deployment y Service (3 min)

```bash
# Verificar pods distribuidos entre nodos
kubectl get pods -n lab-kubeadm-test -o wide

# Verificar que las 3 replicas estan Running
kubectl get deployment -n lab-kubeadm-test

# Verificar Service
kubectl get svc -n lab-kubeadm-test
```

### Paso 4: Test de DNS (2 min)

```bash
# Verificar resolucion DNS dentro del cluster
kubectl exec -n lab-kubeadm-test busybox-dns-test -- \
  nslookup nginx-verify-svc.lab-kubeadm-test.svc.cluster.local

# Verificar resolucion de servicio kubernetes
kubectl exec -n lab-kubeadm-test busybox-dns-test -- \
  nslookup kubernetes.default.svc.cluster.local
```

### Paso 5: Test de Conectividad Service (2 min)

```bash
# Probar conectividad al Service
kubectl exec -n lab-kubeadm-test curl-test -- \
  curl -s http://nginx-verify-svc.lab-kubeadm-test/

# Deberia mostrar la pagina default de nginx
```

### Paso 6: Verificar Certificados (2 min)

```bash
# Verificar expiracion de certificados
sudo kubeadm certs check-expiration

# Verificar certificados del API Server
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | \
  grep -E 'Subject:|Not After'
```

### Paso 7: Verificar etcd (2 min)

```bash
# Para stacked etcd:
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Verificar miembros
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

### Paso 8: Limpieza (1 min)

```bash
# Eliminar recursos de prueba
./cleanup.sh

# O manualmente:
kubectl delete namespace lab-kubeadm-test
```

---

## Resumen Visual: Arquitecturas

```
SINGLE MASTER (Lab 01)        HA STACKED (Lab 03)          HA EXTERNAL ETCD (Lab 04)

   ┌──────────┐                ┌──────────┐                ┌──────────────────┐
   │ Control  │                │   Load   │                │ etcd-01 etcd-02  │
   │  Plane   │                │ Balancer │                │     etcd-03      │
   │ + etcd   │                │ (HAProxy)│                │  (cluster TLS)   │
   └────┬─────┘                └────┬─────┘                └────────┬─────────┘
        │                           │                               │
   ┌────┴────┐           ┌─────────┼─────────┐             ┌──────┴──────┐
   │         │           │         │         │             │  Load       │
Worker-1  Worker-2    CP-1      CP-2      CP-3          Balancer     │
                      +etcd     +etcd     +etcd            │          │
                         │         │         │      ┌──────┼──────┐  │
                      Worker-1  Worker-2  Worker-3  CP-1  CP-2  CP-3 │
                                                   (sin etcd local)  │
                                                      Worker-1 Worker-2
```

---

## Decision: Que Topologia Usar

| Criterio | Single Master | HA Stacked | HA External |
|----------|:---:|:---:|:---:|
| **Complejidad** | Baja | Media | Alta |
| **Tolerancia a fallos** | Ninguna | 1 CP | Independiente |
| **Nodos minimos** | 1 | 4 (3 CP + 1 LB) | 7 (3 CP + 3 etcd + 1 LB) |
| **Costo** | Bajo | Medio | Alto |
| **Dev/Test** | Si | Overkill | No |
| **Produccion** | No | Si | Si (critico) |
| **CKA Exam** | Si | Si | Conocer conceptos |

---

## Preparacion CKA: Comandos Rapidos

```bash
# INIT BASICO (3 min)
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# AGREGAR WORKER (1 min)
kubeadm token create --print-join-command  # En control plane
sudo kubeadm join <IP>:6443 --token <T> --discovery-token-ca-cert-hash sha256:<H>  # En worker

# VERIFICAR (30 seg)
kubectl get nodes
kubectl get pods -n kube-system

# RESET (1 min)
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd ~/.kube
sudo iptables -F && sudo iptables -t nat -F
```
