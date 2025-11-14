# Lab 02: Worker Node Join

## 📋 Información del Laboratorio

- **Nombre**: Agregar Worker Nodes al Cluster
- **Módulo**: 22 - Cluster Setup with kubeadm
- **Área**: 2 - Arquitectura Kubernetes
- **Duración**: 1-2 horas
- **Dificultad**: ⭐⭐⭐ Avanzado
- **CKA relevance**: ⭐⭐⭐⭐⭐ (25% del examen - Cluster Architecture, Installation & Configuration)

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

1. **Preparar** un nodo worker para unirse al cluster de Kubernetes
2. **Generar** y usar tokens de bootstrap para `kubeadm join`
3. **Ejecutar** `kubeadm join` en nodos worker
4. **Verificar** la incorporación exitosa del worker al cluster
5. **Troubleshoot** problemas comunes de join
6. **Remover** nodos worker del cluster correctamente

## 📐 Arquitectura del Cluster Multi-Nodo

```
┌─────────────────────────────────────────────────────────────┐
│                    CONTROL PLANE NODE                       │
│                     (192.168.1.100)                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Control Plane Components                 │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐             │  │
│  │  │   etcd   │  │ API      │  │ Scheduler│             │  │
│  │  │          │  │ Server   │  │          │             │  │
│  │  │          │  │ :6443    │  │          │             │  │
│  │  └──────────┘  └──────────┘  └──────────┘             │  │
│  │  ┌──────────┐                                         │  │
│  │  │Controller│                                         │  │
│  │  │ Manager  │                                         │  │
│  │  └──────────┘                                         │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  kubelet + kube-proxy + CNI                           │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ kubeadm join
                              │ (bootstrap token)
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  WORKER NODE 1  │  │  WORKER NODE 2  │  │  WORKER NODE 3  │
│ (192.168.1.101) │  │ (192.168.1.102) │  │ (192.168.1.103) │
│                 │  │                 │  │                 │
│ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │
│ │   kubelet   │ │  │ │   kubelet   │ │  │ │   kubelet   │ │
│ │ kube-proxy  │ │  │ │ kube-proxy  │ │  │ │ kube-proxy  │ │
│ │ containerd  │ │  │ │ containerd  │ │  │ │ containerd  │ │
│ │     CNI     │ │  │ │     CNI     │ │  │ │     CNI     │ │
│ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │
│                 │  │                 │  │                 │
│   Pod Workloads │  │   Pod Workloads │  │   Pod Workloads │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## 🔑 Conceptos Clave

### kubeadm join Workflow

```
1. Token validation
   ├── Retrieve bootstrap token from control plane
   ├── Validate token hasn't expired
   └── Check token format (6 chars.16 chars)

2. TLS bootstrap
   ├── Download cluster CA certificate
   ├── Validate CA cert hash (--discovery-token-ca-cert-hash)
   ├── Generate kubelet certificate request
   └── Auto-approve certificate (via bootstrap token)

3. Node registration
   ├── kubelet starts
   ├── Register node with API server
   ├── Apply node labels
   └── Apply taints if specified

4. Component deployment
   ├── kube-proxy DaemonSet pod
   ├── CNI plugin pod (Calico/Flannel)
   └── Other DaemonSet pods

5. Node becomes Ready
   ├── All components healthy
   ├── Network configured
   └── Ready to schedule pods
```

### Bootstrap Tokens

**Formato**: `[a-z0-9]{6}.[a-z0-9]{16}`
**Ejemplo**: `abcdef.0123456789abcdef`

**Componentes**:
- **Token ID**: Primeros 6 caracteres (público)
- **Token Secret**: Últimos 16 caracteres (privado)

**Almacenamiento**:
```bash
# Los tokens se guardan como Secrets en kube-system
kubectl get secrets -n kube-system | grep bootstrap-token
```

**Duración por defecto**: 24 horas

### Discovery Modes

| Modo | Comando | Seguridad | Uso |
|------|---------|-----------|-----|
| **Token-based** | `--token` + `--discovery-token-ca-cert-hash` | ✅ Seguro | Producción |
| **File-based** | `--discovery-file` | ✅ Seguro | Automatización |
| **Token unsafe** | `--token` + `--discovery-token-unsafe-skip-ca-verification` | ❌ Inseguro | Labs only |

## 📋 Prerequisitos

Ver [SETUP.md](./SETUP.md) para:
- Control plane node ya inicializado (Lab 01)
- Worker node con mismo OS y versiones de K8s
- Conectividad de red entre nodos
- Puertos abiertos (10250, 30000-32767)
- Mismo container runtime (containerd)

## 🔬 Procedimiento del Laboratorio

### Parte 1: Preparar Worker Node (20 min)

#### 1.1 Verificar prerequisitos en worker node

```bash
# En el WORKER NODE, ejecutar script de validación
./validate-prerequisites.sh

# O verificar manualmente:
# 1. Swap deshabilitado
free -h | grep Swap

# 2. Container runtime instalado
systemctl status containerd

# 3. kubeadm, kubelet, kubectl instalados
kubeadm version
kubelet --version

# 4. Puertos necesarios disponibles
sudo netstat -tulpn | grep -E ':10250|:30000'
```

#### 1.2 Verificar conectividad con control plane

```bash
# Desde WORKER NODE, verificar que puede alcanzar el control plane
CONTROL_PLANE_IP="192.168.1.100"

# Ping al control plane
ping -c 3 $CONTROL_PLANE_IP

# Verificar API server (puerto 6443)
nc -zv $CONTROL_PLANE_IP 6443

# O con curl
curl -k https://$CONTROL_PLANE_IP:6443/version

# Debe retornar JSON con versión de K8s
```

#### 1.3 Sincronizar hora (NTP)

```bash
# Verificar que la hora esté sincronizada entre nodos
date

# En ambos nodos (control plane y worker)
sudo timedatectl set-ntp true
timedatectl status

# Verificar diferencia de tiempo
# Debe ser < 5 segundos entre nodos
```

### Parte 2: Generar Join Command (10 min)

#### 2.1 Método 1: Usar token existente (si no ha expirado)

```bash
# En el CONTROL PLANE NODE:
# Listar tokens existentes
kubeadm token list

# Si hay un token válido (created < 24h):
# TOKEN=<token-from-list>
# Anotar el token para usar en join command
```

#### 2.2 Método 2: Crear nuevo token

```bash
# En el CONTROL PLANE NODE:
# Crear nuevo bootstrap token
kubeadm token create

# OUTPUT:
# abcdef.0123456789abcdef

# Verificar que se creó
kubeadm token list

# TOKEN   TTL         EXPIRES               USAGES                   DESCRIPTION   EXTRA GROUPS
# abcdef  23h         2025-11-15T01:00:00Z  authentication,signing   <none>        system:bootstrappers:kubeadm:default-node-token
```

#### 2.3 Obtener CA certificate hash

```bash
# En el CONTROL PLANE NODE:
# Calcular hash del CA cert
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | sed 's/^.* //'

# OUTPUT (ejemplo):
# 8cb2de97839780a412b93877f8507ad6c94f73add17d5d7058e91741c9d5ec78

# O usar comando kubeadm (más simple):
kubeadm token create --print-join-command

# OUTPUT:
# kubeadm join 192.168.1.100:6443 --token abcdef.0123456789abcdef \
#     --discovery-token-ca-cert-hash sha256:8cb2de97839780a412b93877f8507ad6c94f73add17d5d7058e91741c9d5ec78
```

**⚠️ IMPORTANTE**: Guarda el join command completo, lo necesitarás en el worker node.

### Parte 3: Join Worker Node (15 min)

#### 3.1 Ejecutar kubeadm join

```bash
# En el WORKER NODE:
# Ejecutar el join command obtenido del control plane
sudo kubeadm join 192.168.1.100:6443 \
  --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:8cb2de97839780a412b93877f8507ad6c94f73add17d5d7058e91741c9d5ec78

# OUTPUT ESPERADO:
# [preflight] Running pre-flight checks
# [preflight] Reading configuration from the cluster...
# [preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
# [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
# [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
# [kubelet-start] Starting the kubelet
# [kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...
# 
# This node has joined the cluster:
# * Certificate signing request was sent to apiserver and a response was received.
# * The Kubelet was informed of the new secure connection details.
# 
# Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

#### 3.2 Join con opciones adicionales

```bash
# Join con nombre de nodo personalizado
sudo kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --node-name worker-01

# Join con configuración de kubelet personalizada
cat <<EOF > kubelet-config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
maxPods: 110
EOF

sudo kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --config kubelet-config.yaml

# Join con CRI socket específico
sudo kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --cri-socket unix:///var/run/containerd/containerd.sock
```

### Parte 4: Verificar Worker Node (20 min)

#### 4.1 Verificar desde control plane

```bash
# En el CONTROL PLANE NODE:
# Listar todos los nodos
kubectl get nodes

# OUTPUT:
# NAME            STATUS   ROLES           AGE   VERSION
# control-plane   Ready    control-plane   2h    v1.28.0
# worker-01       Ready    <none>          2m    v1.28.0

# Ver detalles del worker node
kubectl get nodes -o wide

# Describir el worker node
kubectl describe node worker-01

# Verificar labels del nodo
kubectl get nodes --show-labels

# Verificar capacidad y allocatable
kubectl describe node worker-01 | grep -A 10 "Capacity:"
```

#### 4.2 Verificar componentes en worker node

```bash
# En el WORKER NODE:
# Verificar kubelet
systemctl status kubelet

# Ver logs de kubelet
sudo journalctl -u kubelet -n 50 --no-pager

# Verificar pods del sistema en este nodo
# (ejecutar desde control plane)
kubectl get pods -A -o wide --field-selector spec.nodeName=worker-01

# Deberías ver:
# - kube-proxy pod
# - calico-node pod (CNI)
# - Otros DaemonSet pods
```

#### 4.3 Verificar conectividad de red

```bash
# Desde CONTROL PLANE:
# Crear pod de prueba en worker node
kubectl run test-worker --image=nginx:alpine \
  --overrides='{"spec":{"nodeName":"worker-01"}}'

# Verificar que el pod está Running
kubectl get pod test-worker -o wide

# Probar conectividad al pod
POD_IP=$(kubectl get pod test-worker -o jsonpath='{.status.podIP}')
curl http://$POD_IP

# Verificar DNS dentro del pod
kubectl exec test-worker -- nslookup kubernetes.default

# Limpiar
kubectl delete pod test-worker
```

#### 4.4 Verificar certificados del worker

```bash
# En el WORKER NODE:
# Verificar kubelet certificate
sudo ls -la /var/lib/kubelet/pki/

# Debería ver:
# kubelet-client-current.pem -> kubelet-client-2025-11-14-00-00-00.pem
# kubelet.crt
# kubelet.key

# Verificar detalles del certificado
sudo openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -text -noout | grep -A 2 Subject

# Verificar kubeconfig del kubelet
sudo cat /etc/kubernetes/kubelet.conf | grep server

# Debe apuntar al control plane API server
```

### Parte 5: Gestión de Workers (15 min)

#### 5.1 Agregar labels a worker nodes

```bash
# Desde CONTROL PLANE:
# Agregar label de environment
kubectl label node worker-01 environment=production

# Agregar label de zone
kubectl label node worker-01 topology.kubernetes.io/zone=us-east-1a

# Agregar label custom
kubectl label node worker-01 workload-type=compute-intensive

# Verificar labels
kubectl get nodes --show-labels
kubectl get nodes -l environment=production
```

#### 5.2 Agregar taints a worker nodes

```bash
# Agregar taint para workloads específicos
kubectl taint nodes worker-01 dedicated=gpu:NoSchedule

# Agregar taint para mantenimiento
kubectl taint nodes worker-01 maintenance=true:NoExecute

# Verificar taints
kubectl describe node worker-01 | grep Taints

# Remover taint
kubectl taint nodes worker-01 maintenance:NoExecute-
```

#### 5.3 Drain worker node (mantenimiento)

```bash
# Drenar nodo para mantenimiento
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data

# Verificar que está cordoned
kubectl get nodes

# NAME            STATUS                     ROLES           AGE   VERSION
# worker-01       Ready,SchedulingDisabled   <none>          1h    v1.28.0

# Volver a habilitar scheduling
kubectl uncordon worker-01
```

#### 5.4 Remover worker del cluster

```bash
# Desde CONTROL PLANE:
# 1. Drenar el nodo
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data --force

# 2. Eliminar el nodo del cluster
kubectl delete node worker-01

# En el WORKER NODE:
# 3. Reset kubeadm
sudo kubeadm reset -f

# 4. Limpiar directorios
sudo rm -rf /etc/kubernetes
sudo rm -rf /var/lib/kubelet
sudo rm -rf $HOME/.kube

# 5. Reiniciar kubelet
sudo systemctl restart kubelet
```

## 🔍 Troubleshooting

### Problema 1: Join falla con "connection refused"

**Síntoma:**
```
[ERROR FileAvailable--etc-kubernetes-kubelet.conf]: /etc/kubernetes/kubelet.conf already exists
[ERROR Port-10250]: Port 10250 is in use
```

**Solución:**
```bash
# En WORKER NODE:
# Limpiar instalación previa
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes

# Verificar puertos
sudo netstat -tulpn | grep 10250

# Si hay proceso, detener kubelet
sudo systemctl stop kubelet

# Reintentar join
```

### Problema 2: Token expirado

**Síntoma:**
```
error execution phase preflight: couldn't validate the identity of the API Server: 
token id "abcdef" is invalid for this cluster
```

**Solución:**
```bash
# En CONTROL PLANE:
# Crear nuevo token
kubeadm token create --print-join-command

# Usar el nuevo comando en worker node
```

### Problema 3: Node en NotReady state

**Síntoma:**
```bash
kubectl get nodes
# NAME       STATUS     ROLES    AGE   VERSION
# worker-01  NotReady   <none>   5m    v1.28.0
```

**Solución:**
```bash
# Verificar CNI plugin
kubectl get pods -n kube-system -l k8s-app=calico-node

# Si no hay pod de Calico en worker, verificar logs
kubectl logs -n kube-system -l k8s-app=calico-node --all-containers

# Verificar logs de kubelet en worker
sudo journalctl -u kubelet -f

# Verificar networking
# En worker node:
ip route
ip addr
```

### Problema 4: CA certificate hash mismatch

**Síntoma:**
```
error execution phase preflight: couldn't validate the identity of the API Server: 
hash "sha256:xxx" doesn't match cluster CA hash "sha256:yyy"
```

**Solución:**
```bash
# En CONTROL PLANE:
# Re-calcular el hash correcto
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | sed 's/^.* //'

# O usar:
kubeadm token create --print-join-command

# Usar el comando completo con hash correcto
```

### Problema 5: Kubelet no inicia después de join

**Síntoma:**
```bash
systemctl status kubelet
# kubelet.service - kubelet: The Kubernetes Node Agent
# Active: activating (auto-restart)
```

**Solución:**
```bash
# Ver logs detallados
sudo journalctl -u kubelet -n 100 --no-pager

# Verificar configuración de kubelet
sudo cat /var/lib/kubelet/config.yaml

# Verificar que containerd está corriendo
systemctl status containerd

# Verificar cgroup driver coincide
sudo crictl info | grep -i cgroup
# Debe ser 'systemd'

# Si es necesario, reconfigurar containerd
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl restart kubelet
```

## 📚 Comandos Útiles para CKA

### Gestión de Tokens

```bash
# Listar tokens
kubeadm token list

# Crear nuevo token
kubeadm token create

# Crear token con TTL específico
kubeadm token create --ttl 2h

# Crear token que no expira
kubeadm token create --ttl 0

# Eliminar token
kubeadm token delete <token>

# Generar join command completo
kubeadm token create --print-join-command
```

### Gestión de Nodos

```bash
# Listar nodos
kubectl get nodes
kubectl get nodes -o wide
kubectl get nodes --show-labels

# Describir nodo
kubectl describe node <node-name>

# Agregar label
kubectl label node <node-name> key=value

# Remover label
kubectl label node <node-name> key-

# Agregar taint
kubectl taint nodes <node-name> key=value:NoSchedule

# Remover taint
kubectl taint nodes <node-name> key:NoSchedule-

# Cordon (deshabilitar scheduling)
kubectl cordon <node-name>

# Uncordon (habilitar scheduling)
kubectl uncordon <node-name>

# Drain (vaciar nodo)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Eliminar nodo
kubectl delete node <node-name>
```

### Verificación

```bash
# Pods por nodo
kubectl get pods -A -o wide --field-selector spec.nodeName=<node-name>

# Recursos del nodo
kubectl top node <node-name>

# Eventos del nodo
kubectl get events --field-selector involvedObject.name=<node-name>

# Condiciones del nodo
kubectl get node <node-name> -o jsonpath='{.status.conditions[*].type}'
```

## 🎓 Preparación para el Examen CKA

### Escenario Típico del Examen

**Tarea**: "Un nuevo servidor worker está disponible. Únelo al cluster existente usando kubeadm. El control plane está en 192.168.1.100:6443."

**Solución en 3 minutos:**

```bash
# 1. En CONTROL PLANE: Generar join command (30 seg)
kubeadm token create --print-join-command

# OUTPUT (copiar):
# kubeadm join 192.168.1.100:6443 --token xxx --discovery-token-ca-cert-hash sha256:yyy

# 2. En WORKER: Ejecutar join (1 min)
sudo kubeadm join 192.168.1.100:6443 \
  --token xxx \
  --discovery-token-ca-cert-hash sha256:yyy

# 3. En CONTROL PLANE: Verificar (30 seg)
kubectl get nodes
kubectl get pods -A -o wide

# 4. Verificar que el nodo está Ready (1 min)
kubectl wait --for=condition=Ready node/<worker-name> --timeout=60s
```

### Comandos Críticos para Memorizar

```bash
# Generar join command
kubeadm token create --print-join-command

# Join básico
kubeadm join <ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# Verificar nodos
kubectl get nodes

# Drenar nodo
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data

# Eliminar nodo
kubectl delete node <node>

# Reset worker
sudo kubeadm reset -f
```

### Tiempo Estimado en Examen

- **Generar join command**: ~30 segundos
- **Join worker node**: ~1 minuto
- **Verificación**: ~1 minuto
- **Total**: ~3 minutos (de 120 minutos totales del examen)

## 🧹 Limpieza

Para remover el worker node del cluster:

```bash
# Usar script de cleanup
./cleanup.sh

# O manual:
# 1. Desde CONTROL PLANE: Drenar el nodo
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data --force

# 2. Eliminar el nodo
kubectl delete node worker-01

# 3. En WORKER NODE: Reset
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd
sudo systemctl restart kubelet containerd
```

## 📖 Referencias

- [kubeadm join Documentation](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/)
- [TLS Bootstrapping](https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/)
- [Node Management](https://kubernetes.io/docs/concepts/architecture/nodes/)
- [Managing Nodes](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)

## ✅ Verificación de Conocimientos

- [ ] Entiendes el proceso de TLS bootstrapping
- [ ] Sabes generar y gestionar bootstrap tokens
- [ ] Puedes calcular el CA certificate hash
- [ ] Entiendes los diferentes discovery modes
- [ ] Sabes ejecutar `kubeadm join` con opciones
- [ ] Puedes verificar la salud del worker node
- [ ] Sabes agregar labels y taints a nodos
- [ ] Entiendes cómo drenar y remover nodos
- [ ] Puedes troubleshoot problemas comunes de join
- [ ] Puedes completar worker join en menos de 3 minutos (CKA)

---

**Anterior Lab**: [Lab 01 - kubeadm init Básico](../lab-01-kubeadm-init-basic/README.md)  
**Próximo Lab**: [Lab 03 - HA Control Plane](../lab-03-ha-control-plane/README.md)
