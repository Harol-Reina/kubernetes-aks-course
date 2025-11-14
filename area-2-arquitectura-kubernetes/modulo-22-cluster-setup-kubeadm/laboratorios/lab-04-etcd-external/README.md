# Lab 04: External etcd Cluster para Alta Disponibilidad

## Información del Laboratorio

**Duración estimada**: 90-120 minutos  
**Nivel de dificultad**: Avanzado  
**Prerequisitos**: Lab 01 (kubeadm init), Lab 03 (HA Control Plane)

---

## Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

1. ✅ Configurar un **cluster etcd externo** de 3 nodos
2. ✅ Desplegar **control planes con etcd externo** usando kubeadm
3. ✅ Implementar **separación de concerns** (etcd vs control plane)
4. ✅ Gestionar **certificados TLS para etcd externo**
5. ✅ Validar **quorum y high availability** del etcd externo
6. ✅ Realizar **backup y restore** en topología externa

---

## Arquitectura External etcd

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│          CLUSTER HA CON ETCD EXTERNO (Topología Óptima)         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │               LOAD BALANCER (HAProxy)                     │  │
│  │  Virtual IP: 192.168.1.100:6443                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│           ┌──────────────┼──────────────┐                      │
│           │              │              │                      │
│           ▼              ▼              ▼                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐              │
│  │ Control    │  │ Control    │  │ Control    │              │
│  │ Plane 1    │  │ Plane 2    │  │ Plane 3    │              │
│  │            │  │            │  │            │              │
│  │ master-01  │  │ master-02  │  │ master-03  │              │
│  │ (sin etcd) │  │ (sin etcd) │  │ (sin etcd) │              │
│  │            │  │            │  │            │              │
│  │ API Server │  │ API Server │  │ API Server │              │
│  │ Controller │  │ Controller │  │ Controller │              │
│  │ Scheduler  │  │ Scheduler  │  │ Scheduler  │              │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘              │
│        │               │               │                      │
│        │   Conexión a etcd externo     │                      │
│        └───────────────┼───────────────┘                      │
│                        │                                      │
│                        ▼                                      │
│  ┌──────────────────────────────────────────────────────┐    │
│  │           EXTERNAL etcd CLUSTER                       │    │
│  │        (Cluster independiente y dedicado)            │    │
│  │                                                        │    │
│  │  ┌──────────┐     ┌──────────┐     ┌──────────┐     │    │
│  │  │  etcd-1  │◄───►│  etcd-2  │◄───►│  etcd-3  │     │    │
│  │  │          │     │          │     │          │     │    │
│  │  │ 192.168  │     │ 192.168  │     │ 192.168  │     │    │
│  │  │ .1.201   │     │ .1.202   │     │ .1.203   │     │    │
│  │  │ :2379    │     │ :2379    │     │ :2379    │     │    │
│  │  │ :2380    │     │ :2380    │     │ :2380    │     │    │
│  │  └──────────┘     └──────────┘     └──────────┘     │    │
│  │                                                        │    │
│  │  • Raft Consensus Protocol                           │    │
│  │  • Leader Election                                    │    │
│  │  • Quorum: 2/3 nodes mínimo                          │    │
│  │  • TLS mutuo entre miembros                          │    │
│  │  • TLS desde control planes                          │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                               │
└───────────────────────────────────────────────────────────────┘

VENTAJAS DE ETCD EXTERNO:
✅ Tolerancia a fallos independiente (etcd vs control plane)
✅ Escalabilidad separada (más control planes sin más etcd)
✅ Mantenimiento sin impacto (actualizar etcd sin tocar K8s)
✅ Aislamiento de recursos (etcd puede tener SSD dedicado)
✅ Debugging más fácil (logs y métricas separados)
```

---

## Conceptos Clave

### 1. Stacked vs External etcd

| Aspecto | Stacked etcd (Lab 03) | External etcd (Este Lab) |
|---------|----------------------|--------------------------|
| **Topología** | etcd en cada control plane | etcd cluster separado |
| **Nodos totales** | 3 (control plane + etcd) | 6 (3 control + 3 etcd) |
| **Failover** | Si falla CP, pierdes etcd | Fallos independientes |
| **Complejidad** | Media | Alta |
| **Recursos** | 3 nodos mínimo | 6 nodos mínimo |
| **Mantenimiento** | Acoplado | Desacoplado |
| **Producción** | Pequeña/Media | Crítica/Enterprise |
| **Costo** | Menor (menos nodos) | Mayor (más nodos) |
| **Rendimiento etcd** | Compartido con K8s | Dedicado (mejor) |

### 2. Puertos etcd

| Puerto | Propósito | Fuente Permitida |
|--------|-----------|------------------|
| **2379** | Client API | Control planes (API Server) |
| **2380** | Peer communication | Otros miembros etcd |

### 3. Certificados TLS para etcd Externo

```
CERTIFICADOS REQUERIDOS:

etcd Cluster (peer communication):
├── ca.crt              # CA del cluster etcd
├── etcd-peer.crt       # Certificado peer (cada nodo)
├── etcd-peer.key       # Private key peer
└── etcd-peer-ca.crt    # CA para validar peers

etcd Client (API Server → etcd):
├── etcd-client.crt     # Certificado client (control planes)
├── etcd-client.key     # Private key client
└── ca.crt              # CA para validar servidor

etcd Server:
├── etcd-server.crt     # Certificado servidor
├── etcd-server.key     # Private key servidor
└── ca.crt              # CA
```

---

## Componentes del Laboratorio

### Archivos Incluidos

```
lab-04-etcd-external/
├── README.md                      # Esta guía completa
├── SETUP.md                       # Prerequisites y preparación
├── etcd-cluster-config.yaml       # Configuración systemd para etcd
├── setup-etcd.sh                  # Script automatización etcd cluster
├── verify-etcd.sh                 # Verificación de etcd externo
└── cleanup.sh                     # Limpieza completa
```

---

## Parte 1: Preparar Nodos etcd (30 minutos)

### 1.1 Instalar etcd en los 3 nodos

**En cada nodo etcd** (etcd-01, etcd-02, etcd-03):

```bash
# Versión de etcd recomendada
ETCD_VER=v3.5.10

# Descargar etcd
wget -q --https-only \
  "https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz"

# Extraer binarios
tar xzf etcd-${ETCD_VER}-linux-amd64.tar.gz
sudo mv etcd-${ETCD_VER}-linux-amd64/etcd* /usr/local/bin/

# Verificar instalación
etcd --version
etcdctl version
```

**Salida esperada**:
```
etcd Version: 3.5.10
Git SHA: 1234567
Go Version: go1.20.x
```

### 1.2 Crear Directorios

```bash
# En cada nodo etcd
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd
```

---

## Parte 2: Generar Certificados TLS (25 minutos)

### 2.1 Instalar cfssl

```bash
# Herramienta de CloudFlare para generar certificados
wget -q --https-only \
  https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssl_1.6.4_linux_amd64
wget -q --https-only \
  https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssljson_1.6.4_linux_amd64

chmod +x cfssl_1.6.4_linux_amd64 cfssljson_1.6.4_linux_amd64
sudo mv cfssl_1.6.4_linux_amd64 /usr/local/bin/cfssl
sudo mv cfssljson_1.6.4_linux_amd64 /usr/local/bin/cfssljson
```

### 2.2 Crear CA para etcd

```bash
# Crear directorio temporal
mkdir -p ~/etcd-certs && cd ~/etcd-certs

# 1. Configuración de CA
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "etcd": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

# 2. CSR de CA
cat > ca-csr.json <<EOF
{
  "CN": "etcd-cluster-ca",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "etcd-cluster",
      "ST": "Oregon"
    }
  ]
}
EOF

# 3. Generar CA
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
# Genera: ca.pem, ca-key.pem
```

### 2.3 Generar Certificados de Servidor

```bash
# IMPORTANTE: Cambiar IPs por las de tus nodos etcd

cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "etcd-cluster",
      "ST": "Oregon"
    }
  ]
}
EOF

# Generar certificado servidor
# hosts: IPs de los 3 nodos etcd + localhost
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=192.168.1.201,192.168.1.202,192.168.1.203,127.0.0.1,localhost \
  -profile=etcd \
  etcd-csr.json | cfssljson -bare etcd

# Genera: etcd.pem, etcd-key.pem
```

### 2.4 Distribuir Certificados

```bash
# Copiar certificados a cada nodo etcd
for instance in etcd-01 etcd-02 etcd-03; do
  scp ca.pem etcd.pem etcd-key.pem ${instance}:/tmp/
  ssh ${instance} "sudo mv /tmp/*.pem /etc/etcd/ && \
                   sudo chmod 600 /etc/etcd/etcd-key.pem"
done
```

---

## Parte 3: Configurar Cluster etcd (30 minutos)

### 3.1 Crear Servicio systemd para etcd-01

**En etcd-01** (192.168.1.201):

```bash
# Variables (CAMBIAR SEGÚN TU RED)
ETCD_NAME="etcd-01"
INTERNAL_IP="192.168.1.201"
INITIAL_CLUSTER="etcd-01=https://192.168.1.201:2380,etcd-02=https://192.168.1.202:2380,etcd-03=https://192.168.1.203:2380"

# Crear archivo de servicio
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --data-dir=/var/lib/etcd \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --initial-cluster ${INITIAL_CLUSTER} \\
  --initial-cluster-state new \\
  --initial-cluster-token etcd-cluster-1 \\
  --client-cert-auth \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --cert-file=/etc/etcd/etcd.pem \\
  --key-file=/etc/etcd/etcd-key.pem \\
  --peer-client-cert-auth \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-cert-file=/etc/etcd/etcd.pem \\
  --peer-key-file=/etc/etcd/etcd-key.pem

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### 3.2 Configurar etcd-02 y etcd-03

Repetir el paso 3.1 en **etcd-02** (192.168.1.202) y **etcd-03** (192.168.1.203), cambiando:
- `ETCD_NAME` → "etcd-02" y "etcd-03"
- `INTERNAL_IP` → 192.168.1.202 y 192.168.1.203

### 3.3 Iniciar Cluster etcd

```bash
# En cada nodo etcd (SIMULTÁNEAMENTE o con segundos de diferencia)
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd

# Verificar estado
sudo systemctl status etcd
```

### 3.4 Verificar Cluster

```bash
# Desde cualquier nodo etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/etcd.pem \
  --key=/etc/etcd/etcd-key.pem \
  member list

# Salida esperada:
# 1234abcd, started, etcd-01, https://192.168.1.201:2380, https://192.168.1.201:2379, false
# 5678efgh, started, etcd-02, https://192.168.1.202:2380, https://192.168.1.202:2379, false
# 90ijklmn, started, etcd-03, https://192.168.1.203:2380, https://192.168.1.203:2379, false
```

---

## Parte 4: Configurar Control Planes con etcd Externo (35 minutos)

### 4.1 Distribuir Certificados a Control Planes

```bash
# Desde el nodo donde generaste certificados
for instance in master-01 master-02 master-03; do
  scp ca.pem etcd.pem etcd-key.pem ${instance}:/tmp/
  ssh ${instance} "sudo mkdir -p /etc/kubernetes/pki/etcd && \
                   sudo mv /tmp/ca.pem /etc/kubernetes/pki/etcd/ && \
                   sudo mv /tmp/etcd.pem /etc/kubernetes/pki/etcd/client.crt && \
                   sudo mv /tmp/etcd-key.pem /etc/kubernetes/pki/etcd/client.key"
done
```

### 4.2 Configuración kubeadm para Primer Control Plane

**En master-01**:

```yaml
# Archivo: kubeadm-config-external-etcd.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
controlPlaneEndpoint: "192.168.1.100:6443"  # Load Balancer

# CONFIGURACIÓN CRÍTICA: etcd externo
etcd:
  external:
    endpoints:
      - https://192.168.1.201:2379
      - https://192.168.1.202:2379
      - https://192.168.1.203:2379
    caFile: /etc/kubernetes/pki/etcd/ca.pem
    certFile: /etc/kubernetes/pki/etcd/client.crt
    keyFile: /etc/kubernetes/pki/etcd/client.key

networking:
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/12"

---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "192.168.1.101"  # IP de master-01
  bindPort: 6443
certificateKey: "your-random-certificate-key-here-64-chars"

---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
```

### 4.3 Inicializar Primer Control Plane

```bash
# En master-01
sudo kubeadm init \
  --config kubeadm-config-external-etcd.yaml \
  --upload-certs

# ⏱️ Duración: 3-5 minutos
```

**Salida esperada**:
```
[init] Using Kubernetes version: v1.28.0
[preflight] Running pre-flight checks
[kubelet-start] Writing kubelet environment file
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating certificates and keys
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"

Your Kubernetes control-plane has initialized successfully!

⚠️ NOTA: NO se creará pod de etcd en este nodo
         (etcd está externo)
```

### 4.4 Configurar kubectl

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 4.5 Instalar CNI (Calico)

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Esperar a Ready
kubectl get nodes --watch
```

### 4.6 Unir Control Planes Adicionales

**En master-02 y master-03**:

```bash
# Usar el comando join del output de kubeadm init
sudo kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <cert-key>

# Configurar kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

## Parte 5: Verificación del Cluster (20 minutos)

### 5.1 Verificar Nodos

```bash
kubectl get nodes -o wide
# NAME        STATUS   ROLES           AGE   VERSION
# master-01   Ready    control-plane   10m   v1.28.0
# master-02   Ready    control-plane   5m    v1.28.0
# master-03   Ready    control-plane   3m    v1.28.0
```

### 5.2 Verificar que NO hay pods de etcd en K8s

```bash
kubectl get pods -n kube-system -l component=etcd

# Salida: No resources found
# ✅ Correcto: etcd está externo
```

### 5.3 Verificar Conectividad etcd desde Control Planes

```bash
# Desde cualquier control plane
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.1.201:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.pem \
  --cert=/etc/kubernetes/pki/etcd/client.crt \
  --key=/etc/kubernetes/pki/etcd/client.key \
  endpoint health

# Salida esperada (3 endpoints healthy):
# https://192.168.1.201:2379 is healthy: ... ✅
# https://192.168.1.202:2379 is healthy: ... ✅
# https://192.168.1.203:2379 is healthy: ... ✅
```

### 5.4 Test de Persistencia

```bash
# Crear namespace de prueba
kubectl create namespace external-etcd-test

# Verificar que se guarda en etcd externo
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.1.201:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/etcd.pem \
  --key=/etc/etcd/etcd-key.pem \
  get /registry/namespaces/external-etcd-test

# Debería mostrar datos en formato protobuf ✅
```

---

## Troubleshooting

### Problema 1: etcd cluster no forma quorum

**Síntoma**:
```
etcdctl member list
Error: context deadline exceeded
```

**Diagnóstico**:
```bash
# Verificar logs de etcd
sudo journalctl -u etcd -f

# Buscar errores de certificados o conectividad
```

**Solución**:
```bash
# Verificar certificados
ls -l /etc/etcd/
# Deben existir: ca.pem, etcd.pem, etcd-key.pem

# Verificar puertos
sudo netstat -tulpn | grep etcd
# Debe escuchar en 2379 y 2380

# Verificar firewall
sudo firewall-cmd --list-all
# Deben estar abiertos: 2379, 2380
```

---

### Problema 2: Control plane no puede conectar a etcd

**Síntoma**:
```bash
kubectl get nodes
# Error: connection refused
```

**Diagnóstico**:
```bash
# Ver logs API Server
sudo crictl logs <kube-apiserver-pod-id>

# Buscar errores de conexión a etcd
```

**Solución**:
```bash
# Verificar certificados en control plane
ls -l /etc/kubernetes/pki/etcd/
# Deben existir: ca.pem, client.crt, client.key

# Test manual de conectividad
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.1.201:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.pem \
  --cert=/etc/kubernetes/pki/etcd/client.crt \
  --key=/etc/kubernetes/pki/etcd/client.key \
  endpoint health
```

---

## Preparación para CKA

### Escenario de Examen (Tiempo: 10-12 minutos)

**Tarea**: Configurar cluster con etcd externo (3 nodos etcd + 2 control planes)

**Entorno proporcionado**:
- etcd-01, etcd-02, etcd-03 (etcd ya instalado)
- master-01, master-02 (Kubernetes no configurado)
- Certificados ya generados en `/root/certs/`

**Pasos rápidos**:

```bash
# 1. Distribuir certificados a control planes (2 min)
for node in master-01 master-02; do
  scp /root/certs/* ${node}:/etc/kubernetes/pki/etcd/
done

# 2. Configurar kubeadm en master-01 (3 min)
cat > kubeadm.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
etcd:
  external:
    endpoints:
      - https://etcd-01:2379
      - https://etcd-02:2379
      - https://etcd-03:2379
    caFile: /etc/kubernetes/pki/etcd/ca.pem
    certFile: /etc/kubernetes/pki/etcd/client.crt
    keyFile: /etc/kubernetes/pki/etcd/client.key
EOF

# 3. Init (3 min)
sudo kubeadm init --config kubeadm.yaml --upload-certs
mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config

# 4. CNI (1 min)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# 5. Join master-02 (2 min)
# Usar comando del output de kubeadm init

# 6. Verificar (1 min)
kubectl get nodes  # 2 control planes Ready ✅
```

---

## Comandos de Referencia Rápida

```bash
# Verificar miembros etcd
ETCDCTL_API=3 etcdctl --endpoints=https://IP:2379 \
  --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/etcd.pem \
  --key=/etc/etcd/etcd-key.pem member list

# Health check etcd
ETCDCTL_API=3 etcdctl --endpoints=https://IP:2379 \
  --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/etcd.pem \
  --key=/etc/etcd/etcd-key.pem endpoint health

# Backup etcd externo
ETCDCTL_API=3 etcdctl --endpoints=https://IP:2379 \
  --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/etcd.pem \
  --key=/etc/etcd/etcd-key.pem \
  snapshot save /backup/etcd-snapshot.db

# Restore etcd externo
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restore

# Ver logs etcd
sudo journalctl -u etcd -f

# Restart etcd
sudo systemctl restart etcd
```

---

## Recursos Adicionales

- [etcd Documentation](https://etcd.io/docs/)
- [Kubernetes External etcd](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/setup-ha-etcd-with-kubeadm/)
- [etcd TLS Setup](https://etcd.io/docs/v3.5/op-guide/security/)

---

## Conclusión

Has completado el laboratorio de **External etcd Cluster**. Ahora dominas:

✅ Configuración de cluster etcd dedicado  
✅ Generación de certificados TLS para etcd  
✅ Integración de Kubernetes con etcd externo  
✅ Troubleshooting de topología externa  
✅ Best practices para producción enterprise

**Comparación final Stacked vs External**:
- **Stacked**: Más simple, menos nodos, bueno para dev/test
- **External**: Más robusto, mejor aislamiento, ideal para producción crítica

---

**Documentación**: Módulo 22 - Cluster Setup con kubeadm  
**Versión**: 1.0  
**Última actualización**: 2025-01-14
