# Lab 03: High Availability Control Plane con kubeadm

## Información del Laboratorio

**Duración estimada**: 90-120 minutos  
**Nivel de dificultad**: Avanzado  
**Prerequisitos**: Lab 01 (kubeadm init), Lab 02 (Worker Nodes)

---

## Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

1. ✅ Configurar un **Load Balancer** (HAProxy) para múltiples control planes
2. ✅ Desplegar un **cluster HA con 3 control planes** usando kubeadm
3. ✅ Unir **control planes adicionales** al cluster existente
4. ✅ Implementar **alta disponibilidad del API Server** con verificación
5. ✅ Validar **failover automático** de componentes del control plane
6. ✅ Gestionar **certificados compartidos** entre control planes

---

## Arquitectura HA Control Plane

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                      CLUSTER HA (3 Control Planes)              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │               LOAD BALANCER (HAProxy)                     │  │
│  │                                                            │  │
│  │  Virtual IP: 192.168.1.100:6443                          │  │
│  │  Backend: cp1:6443, cp2:6443, cp3:6443                   │  │
│  │  Health Check: GET /healthz                              │  │
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
│  │ 192.168.1. │  │ 192.168.1. │  │ 192.168.1. │              │
│  │ 101:6443   │  │ 102:6443   │  │ 103:6443   │              │
│  └────────────┘  └────────────┘  └────────────┘              │
│       │               │               │                       │
│       │   ┌───────────┴───────────┐   │                       │
│       │   │                       │   │                       │
│       ▼   ▼                       ▼   ▼                       │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              STACKED ETCD CLUSTER                     │    │
│  │  (etcd ejecutándose en cada control plane)           │    │
│  │                                                        │    │
│  │  etcd-1 (master-01) ←→ etcd-2 (master-02) ←→ etcd-3  │    │
│  │  Leader Election + Quorum (2/3 nodes)                │    │
│  └──────────────────────────────────────────────────────┘    │
│                          │                                    │
│                          ▼                                    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              WORKER NODES (Opcionales)                │    │
│  │                                                        │    │
│  │  worker-01  worker-02  worker-03  ...                │    │
│  │  (conectan al Load Balancer:6443)                    │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                               │
└───────────────────────────────────────────────────────────────┘

COMPONENTES POR CONTROL PLANE:
├── kube-apiserver (expuesto en :6443)
├── kube-controller-manager (leader election)
├── kube-scheduler (leader election)
├── etcd (stacked, raft consensus)
└── kubelet + kube-proxy
```

---

## Conceptos Clave

### 1. Stacked etcd vs External etcd

| Característica | Stacked etcd | External etcd |
|----------------|--------------|---------------|
| **Topología** | etcd corre en cada control plane | etcd cluster separado |
| **Nodos mínimos** | 3 control planes | 3 control planes + 3 etcd nodes |
| **Complejidad** | Media | Alta |
| **Tolerancia a fallos** | Si falla 1 control plane, pierdes 1 etcd | Fallos independientes |
| **Recursos** | Menor consumo total | Mayor consumo (más nodos) |
| **Recomendado para** | Producción pequeña/media | Producción crítica |
| **Este Lab** | ✅ Stacked etcd | ❌ (ver Lab 04) |

### 2. Load Balancer para API Server

**Opciones disponibles**:

| Software | Pros | Contras | Uso en este Lab |
|----------|------|---------|-----------------|
| **HAProxy** | Gratis, ligero, simple | Requiere VIP o DNS | ✅ Recomendado |
| **nginx** | Muy popular, flexible | Configuración más verbosa | ✅ Alternativa |
| **keepalived** | VIP automática (VRRP) | Complejidad adicional | ⚠️ Opcional |
| **Cloud LB** | Gestionado, escalable | Solo para cloud providers | ❌ No aplica |

**En este lab usaremos HAProxy** por su simplicidad y eficiencia.

### 3. kubeadm HA Workflow

```
PASO 1: Configurar Load Balancer
├── Instalar HAProxy en nodo dedicado (o compartido)
├── Configurar backend con 3 control planes
├── Health check: GET /healthz cada 2s
└── Exponer en VIP:6443

PASO 2: Inicializar PRIMER control plane
├── kubeadm init --control-plane-endpoint "LB_IP:6443"
├──   --upload-certs (genera certificados compartidos)
├──   --pod-network-cidr "10.244.0.0/16"
└── Obtener: join command + certificate-key

PASO 3: Unir SEGUNDO y TERCER control plane
├── kubeadm join LB_IP:6443 --token <token>
├──   --discovery-token-ca-cert-hash sha256:<hash>
├──   --control-plane
└──   --certificate-key <cert-key>

PASO 4: Verificar HA
├── kubectl get nodes (3 control planes en Ready)
├── kubectl get pods -n kube-system (componentes x3)
├── Test failover: apagar 1 control plane
└── Verificar cluster sigue operativo
```

---

## Componentes del Laboratorio

### Archivos Incluidos

```
lab-03-ha-control-plane/
├── README.md                    # Esta guía completa (820 líneas)
├── SETUP.md                     # Prerequisites y preparación (540 líneas)
├── haproxy-config.cfg           # Configuración HAProxy lista para usar
├── setup-ha.sh                  # Automatización completa HA setup
├── verify-ha.sh                 # Verificación de HA y failover tests
└── cleanup.sh                   # Limpieza completa del cluster HA
```

---

## Parte 1: Preparación del Load Balancer (25 minutos)

### 1.1 Instalar HAProxy

**En el nodo del Load Balancer** (puede ser un nodo separado o uno de los control planes):

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y haproxy

# Verificar instalación
haproxy -v
# Debería mostrar: HAProxy version 2.x.x
```

### 1.2 Configurar HAProxy

Copia el archivo `haproxy-config.cfg` de este lab a `/etc/haproxy/haproxy.cfg`:

```bash
# Backup de configuración original
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup

# Copiar nueva configuración
sudo cp haproxy-config.cfg /etc/haproxy/haproxy.cfg

# IMPORTANTE: Editar IPs de los control planes
sudo nano /etc/haproxy/haproxy.cfg
# Cambiar:
#   - server master-01 192.168.1.101:6443 ...
#   - server master-02 192.168.1.102:6443 ...
#   - server master-03 192.168.1.103:6443 ...
# Por las IPs reales de tus nodos
```

**Contenido de `haproxy-config.cfg`** (ver archivo completo en el lab):

```haproxy
# Backend para Kubernetes API Server
backend kubernetes-apiserver
    mode tcp
    balance roundrobin
    option tcp-check
    
    # Health check cada 2 segundos
    tcp-check connect
    
    # Tres control planes
    server master-01 192.168.1.101:6443 check fall 3 rise 2
    server master-02 192.168.1.102:6443 check fall 3 rise 2
    server master-03 192.168.1.103:6443 check fall 3 rise 2
```

### 1.3 Iniciar HAProxy

```bash
# Habilitar en boot
sudo systemctl enable haproxy

# Iniciar servicio
sudo systemctl start haproxy

# Verificar estado
sudo systemctl status haproxy

# Ver logs en tiempo real
sudo journalctl -u haproxy -f
```

### 1.4 Verificar Load Balancer

```bash
# Verificar puerto escuchando
sudo netstat -tulpn | grep :6443
# Debería mostrar: tcp  0  0  0.0.0.0:6443  LISTEN  haproxy

# Verificar conectividad (aún sin backends activos, fallará)
curl -k https://<LB_IP>:6443
# Esperado: connection refused (normal, API Server aún no existe)
```

---

## Parte 2: Inicializar Primer Control Plane (30 minutos)

### 2.1 Preparar Configuración kubeadm

Crea archivo `kubeadm-config-ha.yaml` en **master-01**:

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
# CRÍTICO: Apuntar al Load Balancer, no a la IP local
controlPlaneEndpoint: "192.168.1.100:6443"  # ← IP del Load Balancer

networking:
  podSubnet: "10.244.0.0/16"  # Para Calico/Flannel
  serviceSubnet: "10.96.0.0/12"

# Configuración etcd (stacked)
etcd:
  local:
    dataDir: /var/lib/etcd
    
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  # IP local del master-01 (NO el Load Balancer)
  advertiseAddress: "192.168.1.101"
  bindPort: 6443

# CRÍTICO para HA: upload-certs permite compartir certificados
certificateKey: "your-random-certificate-key-here-64-chars-exactly-12345"

---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
```

### 2.2 Ejecutar kubeadm init

```bash
# En master-01
sudo kubeadm init \
  --config kubeadm-config-ha.yaml \
  --upload-certs

# ⏱️ Duración: 3-5 minutos
```

**Salida esperada**:

```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, run:
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You can now join multiple control-plane nodes:
  
  kubeadm join 192.168.1.100:6443 --token abc123.xyz789 \
    --discovery-token-ca-cert-hash sha256:abc123... \
    --control-plane --certificate-key 1234567890abcdef...

Then you can join worker nodes:
  
  kubeadm join 192.168.1.100:6443 --token abc123.xyz789 \
    --discovery-token-ca-cert-hash sha256:abc123...
```

**⚠️ IMPORTANTE**: Guarda ambos comandos `kubeadm join`:
- **Control plane join**: incluye `--control-plane --certificate-key`
- **Worker join**: sin `--control-plane`

### 2.3 Configurar kubectl en master-01

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verificar acceso
kubectl get nodes
# NAME        STATUS     ROLES           AGE   VERSION
# master-01   NotReady   control-plane   1m    v1.28.0
```

### 2.4 Instalar CNI (Calico)

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Esperar a que master-01 pase a Ready
kubectl get nodes --watch
# (Ctrl+C cuando veas STATUS = Ready)
```

---

## Parte 3: Unir Segundo Control Plane (20 minutos)

### 3.1 Validar Prerequisites en master-02

```bash
# Ejecutar en master-02
./validate-prerequisites.sh  # Del Lab 01

# Verificar conectividad al Load Balancer
curl -k https://192.168.1.100:6443
# Debería responder con certificado del API Server
```

### 3.2 Ejecutar kubeadm join

```bash
# En master-02 (usar el comando guardado del paso 2.2)
sudo kubeadm join 192.168.1.100:6443 \
  --token abc123.xyz789 \
  --discovery-token-ca-cert-hash sha256:abc123... \
  --control-plane \
  --certificate-key 1234567890abcdef...

# ⏱️ Duración: 2-3 minutos
```

**Salida esperada**:

```
This node has joined the cluster and a new control plane instance was created:

* Certificate signing request sent to apiserver and approved.
* The Kubelet was informed of the new secure connection details.
* Control plane label and taint applied to the new node.
* The Kubernetes control plane instances are now available.

Run 'kubectl get nodes' to see this node join the cluster.
```

### 3.3 Configurar kubectl en master-02

```bash
# En master-02
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verificar desde master-02
kubectl get nodes
# NAME        STATUS   ROLES           AGE   VERSION
# master-01   Ready    control-plane   15m   v1.28.0
# master-02   Ready    control-plane   2m    v1.28.0
```

---

## Parte 4: Unir Tercer Control Plane (20 minutos)

### 4.1 Regenerar certificate-key (si expiró)

Si pasaron **más de 2 horas** desde el `kubeadm init`, el certificate-key expira:

```bash
# En master-01 o master-02
sudo kubeadm init phase upload-certs --upload-certs

# Salida:
# [upload-certs] Storing the certificates in Secret "kubeadm-certs"
# [upload-certs] Using certificate key:
# 1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

### 4.2 Regenerar token (si expiró)

Los tokens expiran en **24 horas** por defecto:

```bash
# En master-01 o master-02
kubeadm token create --print-join-command

# Salida (join para workers):
# kubeadm join 192.168.1.100:6443 --token new123.token456 \
#   --discovery-token-ca-cert-hash sha256:new789...

# Para control plane, agregar manualmente:
# --control-plane --certificate-key <cert-key-del-paso-4.1>
```

### 4.3 Unir master-03

```bash
# En master-03
sudo kubeadm join 192.168.1.100:6443 \
  --token new123.token456 \
  --discovery-token-ca-cert-hash sha256:new789... \
  --control-plane \
  --certificate-key 1234567890abcdef...

# Configurar kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 4.4 Verificar Cluster Completo

```bash
# Desde cualquier control plane
kubectl get nodes
# NAME        STATUS   ROLES           AGE   VERSION
# master-01   Ready    control-plane   30m   v1.28.0
# master-02   Ready    control-plane   17m   v1.28.0
# master-03   Ready    control-plane   2m    v1.28.0

# Verificar componentes
kubectl get pods -n kube-system -o wide | grep -E "apiserver|controller|scheduler|etcd"
# Debería mostrar 3 de cada componente
```

---

## Parte 5: Verificación de Alta Disponibilidad (25 minutos)

### 5.1 Verificar Distribución de Componentes

```bash
# kube-apiserver (3 réplicas)
kubectl get pods -n kube-system -l component=kube-apiserver -o wide
# NAME                        NODE        STATUS
# kube-apiserver-master-01    master-01   Running
# kube-apiserver-master-02    master-02   Running
# kube-apiserver-master-03    master-03   Running

# etcd (3 miembros)
kubectl get pods -n kube-system -l component=etcd -o wide

# Controller Manager (1 líder + 2 standby)
kubectl get pods -n kube-system -l component=kube-controller-manager -o wide
```

### 5.2 Verificar etcd Cluster

```bash
# Desde cualquier control plane
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# Salida esperada:
# 1234abcd, started, master-01, https://192.168.1.101:2380, https://192.168.1.101:2379
# 5678efgh, started, master-02, https://192.168.1.102:2380, https://192.168.1.102:2379
# 90ijklmn, started, master-03, https://192.168.1.103:2380, https://192.168.1.103:2379
```

### 5.3 Test Failover Automático

**Escenario**: Apagar master-01 y verificar que el cluster sigue operativo.

```bash
# PASO 1: Crear deployment de prueba
kubectl create deployment nginx-ha --image=nginx --replicas=3
kubectl expose deployment nginx-ha --port=80 --type=ClusterIP

# PASO 2: Verificar pods
kubectl get pods -l app=nginx-ha -o wide
# 3 pods en Running

# PASO 3: Apagar master-01 (simular fallo)
# En master-01:
sudo shutdown -h now

# PASO 4: Desde master-02 o master-03
kubectl get nodes
# NAME        STATUS     ROLES           AGE   VERSION
# master-01   NotReady   control-plane   45m   v1.28.0  ← NotReady!
# master-02   Ready      control-plane   32m   v1.28.0
# master-03   Ready      control-plane   17m   v1.28.0

# PASO 5: Verificar que nginx-ha sigue funcionando
kubectl get pods -l app=nginx-ha
# Los 3 pods deberían seguir en Running

# PASO 6: Crear nuevo pod (test API Server)
kubectl run test-pod --image=busybox --restart=Never -- sleep 3600
# Debería crearse exitosamente ← HA funciona!

# PASO 7: Verificar etcd quorum
# Desde master-02
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Salida:
# https://192.168.1.102:2379 is healthy: ... (master-02) ✅
# https://192.168.1.103:2379 is healthy: ... (master-03) ✅
# https://192.168.1.101:2379 is unhealthy: ... (master-01) ❌
# ← 2/3 nodes = Quorum OK!
```

### 5.4 Recuperar master-01

```bash
# Encender master-01
# Esperar 2-3 minutos para que kubelet se reconecte

# Verificar desde master-02
kubectl get nodes
# master-01 debería volver a Ready

# Verificar etcd
sudo ETCDCTL_API=3 etcdctl ... endpoint health
# Las 3 endpoints deberían estar healthy
```

---

## Parte 6: Gestión de Certificados (15 minutos)

### 6.1 Verificar Certificados Compartidos

```bash
# Los certificados se comparten automáticamente vía kubeadm
# durante el join con --upload-certs

# Verificar en cada control plane
for node in master-01 master-02 master-03; do
  echo "=== $node ==="
  ssh $node "sudo ls -lh /etc/kubernetes/pki/*.crt"
done

# Todos deberían tener los mismos certificados:
# - ca.crt (CA del cluster)
# - apiserver.crt (API Server)
# - apiserver-kubelet-client.crt
# - front-proxy-ca.crt
# - front-proxy-client.crt
# - sa.pub (Service Account public key)
```

### 6.2 Verificar Expiración de Certificados

```bash
# Desde cualquier control plane
sudo kubeadm certs check-expiration

# Salida:
# CERTIFICATE                EXPIRES                  RESIDUAL TIME   ...
# admin.conf                 Nov 14, 2026 12:00 UTC   364d            ...
# apiserver                  Nov 14, 2026 12:00 UTC   364d            ...
# apiserver-kubelet-client   Nov 14, 2026 12:00 UTC   364d            ...
# ...
```

---

## Scripts de Automatización

### setup-ha.sh

Automatiza todo el proceso de configuración HA:

```bash
# Uso:
./setup-ha.sh --lb-ip 192.168.1.100 \
              --master1-ip 192.168.1.101 \
              --master2-ip 192.168.1.102 \
              --master3-ip 192.168.1.103

# Pasos automáticos:
# 1. Validar prerequisites en todos los nodos
# 2. Configurar HAProxy
# 3. Ejecutar kubeadm init en master-01
# 4. Instalar CNI
# 5. Unir master-02 y master-03
# 6. Verificar cluster HA
```

### verify-ha.sh

Ejecuta todas las verificaciones de HA:

```bash
./verify-ha.sh

# Tests incluidos:
# 1. Verificar 3 control planes en Ready
# 2. Verificar 3 API Servers corriendo
# 3. Verificar etcd cluster (3 miembros)
# 4. Test failover simulado
# 5. Verificar Load Balancer health
# 6. Test creación de pods vía LB
```

---

## Troubleshooting

### Problema 1: Control Plane no puede unirse

**Síntoma**:
```
error execution phase preflight: couldn't validate the identity of the API Server
```

**Diagnóstico**:
```bash
# Verificar conectividad al LB
curl -k https://192.168.1.100:6443

# Verificar HAProxy
sudo systemctl status haproxy
sudo tail -f /var/log/haproxy.log
```

**Solución**:
```bash
# Verificar que HAProxy tenga backend correcto
sudo cat /etc/haproxy/haproxy.cfg | grep "server master"

# Reiniciar HAProxy
sudo systemctl restart haproxy
```

---

### Problema 2: certificate-key inválido

**Síntoma**:
```
error execution phase control-plane-join: error uploading certs: 
  the secret "kubeadm-certs" was not found in the "kube-system" namespace
```

**Diagnóstico**:
```bash
# El certificate-key expira en 2 horas
kubectl get secret kubeadm-certs -n kube-system
# Error: secrets "kubeadm-certs" not found ← Expirado
```

**Solución**:
```bash
# Regenerar certificate-key
sudo kubeadm init phase upload-certs --upload-certs

# Usar nuevo certificate-key en el join
```

---

### Problema 3: etcd cluster no forma quorum

**Síntoma**:
```bash
etcdctl endpoint health
# https://192.168.1.101:2379 is unhealthy
```

**Diagnóstico**:
```bash
# Verificar miembros etcd
sudo ETCDCTL_API=3 etcdctl member list

# Verificar logs
sudo journalctl -u kubelet -f | grep etcd
```

**Solución**:
```bash
# Si un nodo etcd está corrupto, removerlo y re-unir
sudo kubeadm reset -f
# Luego re-unir con kubeadm join
```

---

### Problema 4: HAProxy no balancea tráfico

**Síntoma**: Todos los requests van a un solo control plane.

**Diagnóstico**:
```bash
# Ver estadísticas HAProxy
echo "show stat" | sudo socat stdio /var/lib/haproxy/stats

# Verificar algoritmo de balanceo
sudo grep "balance" /etc/haproxy/haproxy.cfg
```

**Solución**:
```bash
# Cambiar a roundrobin
sudo nano /etc/haproxy/haproxy.cfg
# balance roundrobin

sudo systemctl restart haproxy
```

---

### Problema 5: Worker nodes no pueden conectar al cluster

**Síntoma**: Workers se unen pero quedan en NotReady.

**Diagnóstico**:
```bash
# Desde worker
sudo journalctl -u kubelet -f

# Verificar conectividad al LB
curl -k https://192.168.1.100:6443
```

**Solución**:
```bash
# Verificar que workers apunten al LB (no a IP específica)
kubectl get nodes -o yaml | grep server:
# server: https://192.168.1.100:6443 ← Correcto
```

---

## Preparación para CKA

### Escenario de Examen (Tiempo: 8-10 minutos)

**Tarea**: Configurar un cluster HA con 2 control planes usando HAProxy.

**Entorno proporcionado**:
- 3 nodos: lb-node, master-01, master-02
- HAProxy ya instalado en lb-node
- IPs: lb-node=10.0.1.10, master-01=10.0.1.11, master-02=10.0.1.12

**Pasos rápidos**:

```bash
# 1. Configurar HAProxy (2 min)
ssh lb-node
sudo cat > /etc/haproxy/haproxy.cfg <<EOF
backend kubernetes
    mode tcp
    balance roundrobin
    server m1 10.0.1.11:6443 check
    server m2 10.0.1.12:6443 check
EOF
sudo systemctl restart haproxy

# 2. Init primer control plane (3 min)
ssh master-01
sudo kubeadm init \
  --control-plane-endpoint "10.0.1.10:6443" \
  --upload-certs \
  --pod-network-cidr "10.244.0.0/16"
# Guardar join command

mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config

# 3. Instalar CNI (1 min)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# 4. Unir segundo control plane (2 min)
ssh master-02
sudo kubeadm join 10.0.1.10:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <cert-key>

# 5. Verificar (1 min)
kubectl get nodes
# Ambos en Ready = ✅
```

---

## Comandos de Referencia Rápida

```bash
# Inicializar cluster HA
sudo kubeadm init --control-plane-endpoint "LB_IP:6443" --upload-certs

# Unir control plane adicional
sudo kubeadm join LB_IP:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane --certificate-key <cert-key>

# Regenerar certificate-key
sudo kubeadm init phase upload-certs --upload-certs

# Regenerar token
kubeadm token create --print-join-command

# Verificar etcd cluster
sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# Verificar health etcd
sudo ETCDCTL_API=3 etcdctl ... endpoint health

# Verificar certificados
sudo kubeadm certs check-expiration

# Ver logs HAProxy
sudo journalctl -u haproxy -f

# Remover control plane del cluster
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
kubectl delete node <node>
ssh <node> "sudo kubeadm reset -f"
```

---

## Recursos Adicionales

- [Kubernetes HA Topology](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/)
- [kubeadm HA Setup](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)
- [HAProxy Configuration](http://www.haproxy.org/download/2.4/doc/configuration.txt)
- [etcd Clustering Guide](https://etcd.io/docs/v3.5/op-guide/clustering/)

---

## Conclusión

Has completado el laboratorio de **High Availability Control Plane**. Ahora puedes:

✅ Configurar Load Balancers para Kubernetes API  
✅ Desplegar clusters con múltiples control planes  
✅ Implementar alta disponibilidad con etcd stacked  
✅ Manejar failover y recuperación de control planes  
✅ Gestionar certificados compartidos en HA

**Próximo lab**: Lab 04 - External etcd Cluster (topología avanzada)

---

**Documentación**: Módulo 22 - Cluster Setup con kubeadm  
**Versión**: 1.0  
**Última actualización**: 2025-01-14
