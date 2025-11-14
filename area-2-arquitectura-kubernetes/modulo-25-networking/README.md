# Módulo 25: Networking Deep Dive

## Información del Módulo

- **Duración estimada**: 6-8 horas
- **Nivel**: Avanzado
- **Cobertura CKA**: ~20% del examen
- **Prerequisitos**: Módulos 1-24 completados

## Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:

1. Comprender el modelo de networking de Kubernetes
2. Configurar y troubleshoot CNI plugins
3. Implementar y gestionar Services (ClusterIP, NodePort, LoadBalancer)
4. Configurar DNS en Kubernetes (CoreDNS)
5. Implementar Network Policies para seguridad
6. Configurar Ingress controllers y rules
7. Diagnosticar y resolver problemas de red
8. Optimizar comunicación entre pods y servicios

---

## Índice

1. [Introducción al Networking de Kubernetes](#1-introducción-al-networking-de-kubernetes)
2. [CNI - Container Network Interface](#2-cni---container-network-interface)
3. [Services - Tipos y Casos de Uso](#3-services---tipos-y-casos-de-uso)
4. [DNS en Kubernetes (CoreDNS)](#4-dns-en-kubernetes-coredns)
5. [Network Policies](#5-network-policies)
6. [Ingress Controllers y Rules](#6-ingress-controllers-y-rules)
7. [Service Mesh Basics](#7-service-mesh-basics)
8. [Network Troubleshooting](#8-network-troubleshooting)
9. [Performance y Optimización](#9-performance-y-optimización)
10. [Best Practices](#10-best-practices)

---

## 1. Introducción al Networking de Kubernetes

### 1.1 Modelo de Red de Kubernetes

Kubernetes implementa un modelo de red plana donde:

- **Todos los Pods pueden comunicarse** entre sí sin NAT
- **Todos los Nodos pueden comunicarse** con todos los Pods sin NAT
- **El IP que ve un Pod** es el mismo que ven otros Pods

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
│                                                          │
│  ┌──────────────┐         ┌──────────────┐             │
│  │   Node 01    │         │   Node 02    │             │
│  │              │         │              │             │
│  │  ┌────────┐  │         │  ┌────────┐  │             │
│  │  │ Pod A  │──┼─────────┼──│ Pod B  │  │             │
│  │  │10.1.1.1│  │  Direct │  │10.1.2.1│  │             │
│  │  └────────┘  │  Comm.  │  └────────┘  │             │
│  │              │         │              │             │
│  │  Pod Network │         │  Pod Network │             │
│  │  10.1.1.0/24 │         │  10.1.2.0/24 │             │
│  └──────────────┘         └──────────────┘             │
│         │                        │                      │
│         └────────┬───────────────┘                      │
│                  │                                       │
│          ┌───────▼────────┐                            │
│          │  Cluster CIDR  │                            │
│          │   10.1.0.0/16  │                            │
│          └────────────────┘                            │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Espacios de Red

Kubernetes maneja varios rangos de IPs:

| Tipo | CIDR Ejemplo | Descripción | Configurable |
|------|--------------|-------------|--------------|
| **Pod Network** | 10.244.0.0/16 | IPs asignadas a Pods | CNI Plugin |
| **Service Network** | 10.96.0.0/12 | IPs virtuales de Services | kube-apiserver |
| **Node Network** | 192.168.1.0/24 | IPs de los nodos físicos | Infraestructura |

**Ejemplo de configuración:**

```yaml
# kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  podSubnet: "10.244.0.0/16"    # Pod CIDR
  serviceSubnet: "10.96.0.0/12" # Service CIDR
```

### 1.3 Componentes de Red

```
┌─────────────────────────────────────────────────────┐
│           Kubernetes Networking Stack               │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐    ┌──────────────┐             │
│  │   Ingress    │◄───│   External   │             │
│  │  Controller  │    │   Traffic    │             │
│  └──────┬───────┘    └──────────────┘             │
│         │                                           │
│         ▼                                           │
│  ┌──────────────┐                                  │
│  │   Services   │  (ClusterIP, NodePort, LB)      │
│  └──────┬───────┘                                  │
│         │                                           │
│         ▼                                           │
│  ┌──────────────┐                                  │
│  │   Endpoints  │  (Pod IPs + Ports)              │
│  └──────┬───────┘                                  │
│         │                                           │
│         ▼                                           │
│  ┌──────────────┐    ┌──────────────┐             │
│  │  kube-proxy  │◄───│NetworkPolicy │             │
│  │   (iptables) │    │   Engine     │             │
│  └──────┬───────┘    └──────────────┘             │
│         │                                           │
│         ▼                                           │
│  ┌──────────────┐                                  │
│  │  CNI Plugin  │  (Calico, Flannel, Cilium)      │
│  │  (veth pairs)│                                  │
│  └──────┬───────┘                                  │
│         │                                           │
│         ▼                                           │
│  ┌──────────────┐                                  │
│  │     Pods     │                                  │
│  └──────────────┘                                  │
└─────────────────────────────────────────────────────┘
```

---

## 2. CNI - Container Network Interface

### 2.1 ¿Qué es CNI?

CNI (Container Network Interface) es una especificación para configurar interfaces de red en contenedores Linux.

**Responsabilidades del CNI:**

1. Asignar IP a pods
2. Configurar rutas de red
3. Configurar interfaces (veth pairs)
4. Implementar Network Policies (algunos plugins)

### 2.2 Plugins CNI Populares

| Plugin | Tipo | Network Policies | Performance | Complejidad |
|--------|------|------------------|-------------|-------------|
| **Flannel** | Overlay | ❌ No | ⭐⭐⭐ | Baja |
| **Calico** | Overlay/BGP | ✅ Sí | ⭐⭐⭐⭐ | Media |
| **Cilium** | eBPF | ✅ Sí | ⭐⭐⭐⭐⭐ | Alta |
| **Weave** | Overlay | ✅ Sí | ⭐⭐⭐ | Media |
| **Canal** | Flannel + Calico | ✅ Sí | ⭐⭐⭐ | Media |

### 2.3 Instalación de CNI - Calico

```bash
# Descargar manifest de Calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Verificar instalación
kubectl get pods -n kube-system | grep calico

# Debe mostrar:
# calico-kube-controllers-xxx   1/1   Running
# calico-node-xxx               1/1   Running (en cada nodo)

# Ver configuración de CNI
cat /etc/cni/net.d/10-calico.conflist
```

**Configuración típica de CNI:**

```json
{
  "name": "k8s-pod-network",
  "cniVersion": "0.3.1",
  "plugins": [
    {
      "type": "calico",
      "log_level": "info",
      "datastore_type": "kubernetes",
      "nodename": "node01",
      "ipam": {
        "type": "calico-ipam"
      },
      "policy": {
        "type": "k8s"
      },
      "kubernetes": {
        "kubeconfig": "/etc/cni/net.d/calico-kubeconfig"
      }
    },
    {
      "type": "portmap",
      "capabilities": {"portMappings": true}
    }
  ]
}
```

### 2.4 Troubleshooting CNI

```bash
# Ver logs de CNI
journalctl -u kubelet | grep -i cni

# Ver configuración actual
ls -la /etc/cni/net.d/

# Ver interfaces de red en un pod
kubectl exec -it <pod-name> -- ip addr

# Debe mostrar:
# 1: lo: <LOOPBACK,UP,LOWER_UP>
# 3: eth0@if12: <BROADCAST,MULTICAST,UP,LOWER_UP>
#    inet 10.244.1.5/32 scope global eth0

# Ver rutas en el nodo
ip route | grep cali  # Para Calico
ip route | grep flannel  # Para Flannel

# Ver pods de CNI
kubectl get pods -n kube-system -l k8s-app=calico-node
```

---

## 3. Services - Tipos y Casos de Uso

### 3.1 ClusterIP (Default)

**Propósito**: Comunicación interna dentro del cluster

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP  # Default, puede omitirse
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 8080        # Puerto del Service
    targetPort: 8080  # Puerto del Pod
```

**Características:**
- IP virtual interna (10.96.x.x)
- Accesible solo dentro del cluster
- DNS: `backend-service.default.svc.cluster.local`
- Load balancing automático entre pods

**Flujo de tráfico:**

```
Pod A (10.244.1.5)
    │
    │ curl backend-service:8080
    ▼
ClusterIP (10.96.10.20:8080)  ← Virtual IP
    │
    │ kube-proxy (iptables rules)
    ▼
┌───────────┬───────────┬───────────┐
│ Pod B     │ Pod C     │ Pod D     │  ← Backends
│ 10.244.2.3│ 10.244.2.4│ 10.244.3.5│
│ :8080     │ :8080     │ :8080     │
└───────────┴───────────┴───────────┘
```

### 3.2 NodePort

**Propósito**: Acceso externo usando puerto en cada nodo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80           # Puerto del Service
    targetPort: 80     # Puerto del Pod
    nodePort: 30080    # Puerto en cada nodo (30000-32767)
```

**Características:**
- Expone servicio en `<NodeIP>:<NodePort>`
- Rango de puertos: 30000-32767 (configurable)
- Crea automáticamente un ClusterIP
- Tráfico puede llegar a cualquier nodo

**Flujo de tráfico:**

```
Internet / External Client
    │
    │ http://node01:30080
    ▼
┌────────────────────────────────┐
│   Any Node (192.168.1.10)      │
│   iptables rule: 30080 → ClusterIP │
└────────────┬───────────────────┘
             │
             ▼
    ClusterIP (10.96.20.30:80)
             │
             ▼
       Backend Pods
```

### 3.3 LoadBalancer

**Propósito**: Provisionar load balancer externo (cloud providers)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

**Características:**
- Requiere integración con cloud provider (AWS ELB, GCP LB, Azure LB)
- Crea automáticamente NodePort y ClusterIP
- Asigna IP externa pública
- Ideal para producción en cloud

**En AWS:**

```bash
kubectl get svc web-loadbalancer

# NAME                TYPE           CLUSTER-IP      EXTERNAL-IP
# web-loadbalancer    LoadBalancer   10.96.30.40     a1b2c3-123.elb.amazonaws.com
```

### 3.4 ExternalName

**Propósito**: Mapear servicio a nombre DNS externo

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: db.example.com  # CNAME DNS
```

**Uso:**

```bash
# Desde un pod:
nslookup external-db

# Retorna: db.example.com (CNAME record)
```

### 3.5 Headless Service

**Propósito**: Acceso directo a IPs de pods (sin load balancing)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: database-headless
spec:
  clusterIP: None  # Headless!
  selector:
    app: database
  ports:
  - port: 5432
```

**DNS devuelve IPs de pods directamente:**

```bash
nslookup database-headless.default.svc.cluster.local

# Retorna:
# Name: database-headless.default.svc.cluster.local
# Address: 10.244.1.10  (Pod 1)
# Address: 10.244.2.15  (Pod 2)
# Address: 10.244.3.20  (Pod 3)
```

**Casos de uso:**
- StatefulSets (identificación de pods estables)
- Databases con réplicas
- Comunicación peer-to-peer

---

## 4. DNS en Kubernetes (CoreDNS)

### 4.1 Arquitectura de CoreDNS

```
┌────────────────────────────────────────────────┐
│              Pod (10.244.1.5)                  │
│                                                │
│  Application                                   │
│      │                                         │
│      │ nslookup backend.default.svc.cluster.local
│      ▼                                         │
│  /etc/resolv.conf                              │
│  nameserver 10.96.0.10  ← ClusterIP de CoreDNS│
└────────────┬───────────────────────────────────┘
             │
             ▼
    ┌────────────────┐
    │  CoreDNS Pod   │
    │  (kube-system) │
    └────────┬───────┘
             │
      ┌──────┴──────┐
      │             │
      ▼             ▼
  Watch API     Cache DNS
  Server for    Records
  Services/
  Endpoints
```

### 4.2 Formatos de DNS

| Tipo | Formato | Ejemplo |
|------|---------|---------|
| **Service** | `<service>.<namespace>.svc.<domain>` | `backend.default.svc.cluster.local` |
| **Pod** | `<ip-with-dashes>.<namespace>.pod.<domain>` | `10-244-1-5.default.pod.cluster.local` |
| **Headless Pod** | `<hostname>.<service>.<namespace>.svc.<domain>` | `web-0.nginx.default.svc.cluster.local` |

**Búsquedas abreviadas (search domains):**

```bash
# /etc/resolv.conf en un pod del namespace "default"
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5

# Búsquedas permitidas:
# 1. backend              → backend.default.svc.cluster.local
# 2. backend.default      → backend.default.svc.cluster.local
# 3. backend.kube-system  → backend.kube-system.svc.cluster.local
```

### 4.3 Configuración de CoreDNS

```bash
# Ver ConfigMap de CoreDNS
kubectl get configmap coredns -n kube-system -o yaml
```

**Ejemplo de Corefile:**

```
.:53 {
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf {
       max_concurrent 1000
    }
    cache 30
    loop
    reload
    loadbalance
}
```

**Plugins importantes:**

- **errors**: Log de errores
- **health**: Health check endpoint
- **kubernetes**: Resolver de K8s
- **forward**: Forward a DNS upstream
- **cache**: Cache de respuestas
- **prometheus**: Métricas

### 4.4 Custom DNS

**Añadir DNS personalizado:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
        }
        # Custom DNS entries
        hosts {
          192.168.100.10 custom.example.com
          fallthrough
        }
        forward . 8.8.8.8 8.8.4.4
        cache 30
        reload
    }
```

### 4.5 Troubleshooting DNS

```bash
# Verificar CoreDNS está corriendo
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Ver logs de CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns

# Crear pod de debug
kubectl run dnsutils --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 \
  --command -- sleep 3600

# Probar DNS desde el pod
kubectl exec -it dnsutils -- nslookup kubernetes.default
kubectl exec -it dnsutils -- nslookup google.com

# Ver resolv.conf del pod
kubectl exec -it dnsutils -- cat /etc/resolv.conf

# Verificar Service de CoreDNS
kubectl get svc -n kube-system kube-dns

# Debe tener ClusterIP (ej: 10.96.0.10)
```

---

## 5. Network Policies

### 5.1 Concepto de Network Policies

Network Policies son reglas de firewall a nivel de pod que controlan:

- **Ingress**: Tráfico entrante al pod
- **Egress**: Tráfico saliente del pod

**Modelo de seguridad:**

```
┌─────────────────────────────────────────────────┐
│        Sin Network Policies (Default)           │
│  ┌─────┐    ┌─────┐    ┌─────┐                │
│  │Pod A│◄──►│Pod B│◄──►│Pod C│  All-to-All   │
│  └─────┘    └─────┘    └─────┘  Communication  │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│        Con Network Policies (Whitelist)         │
│  ┌─────┐    ┌─────┐    ┌─────┐                │
│  │Pod A│───►│Pod B│ ✗  │Pod C│  Explicit      │
│  └─────┘    └─────┘    └─────┘  Allow Rules   │
│     ✗          │          ▲                     │
│                └──────────┘ Allow               │
└─────────────────────────────────────────────────┘
```

**IMPORTANTE**: 
- Network Policies son **whitelist** (deny all by default una vez aplicada)
- Requieren CNI plugin que las soporte (Calico, Cilium, Weave)
- Flannel NO soporta Network Policies

### 5.2 Sintaxis Básica

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:  # A qué pods aplica
    matchLabels:
      app: backend
  
  policyTypes:  # Tipos de reglas
  - Ingress
  - Egress
  
  ingress:  # Tráfico entrante permitido
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  
  egress:  # Tráfico saliente permitido
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

### 5.3 Selectores de Tráfico

**Pod Selector** (mismo namespace):

```yaml
ingress:
- from:
  - podSelector:
      matchLabels:
        role: frontend
```

**Namespace Selector** (todos los pods de ciertos namespaces):

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        environment: production
```

**IP Block** (rangos CIDR):

```yaml
ingress:
- from:
  - ipBlock:
      cidr: 192.168.1.0/24
      except:
      - 192.168.1.100/32  # Bloquear IP específica
```

**Combinar selectores** (AND lógico):

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        environment: prod
    podSelector:
      matchLabels:
        app: frontend  # Pods frontend EN namespaces prod
```

### 5.4 Ejemplos Comunes

**Deny All Ingress:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}  # Aplica a TODOS los pods
  policyTypes:
  - Ingress
  # Sin reglas ingress = deny all
```

**Allow All Egress:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - {}  # Regla vacía = allow all
```

**Permitir DNS (CoreDNS):**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

### 5.5 Patrón Multi-Tier

```yaml
---
# Frontend puede recibir de ingress-nginx
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-to-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80

---
# Backend solo acepta de frontend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  - to:  # DNS
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53

---
# Database solo acepta de backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-to-database
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
```

---

## 6. Ingress Controllers y Rules

### 6.1 Arquitectura de Ingress

```
Internet
   │
   │ HTTP/HTTPS
   ▼
┌─────────────────────────────────────┐
│      Ingress Controller             │
│  (nginx, traefik, haproxy, etc.)    │
│                                     │
│  ┌───────────────────────────────┐ │
│  │     Ingress Rules             │ │
│  │  - Host routing               │ │
│  │  - Path routing               │ │
│  │  - TLS termination            │ │
│  └───────────────────────────────┘ │
└────────┬──────────┬─────────┬──────┘
         │          │         │
         ▼          ▼         ▼
   ┌─────────┐ ┌────────┐ ┌────────┐
   │Service A│ │Service │ │Service │
   │ClusterIP│ │   B    │ │   C    │
   └─────────┘ └────────┘ └────────┘
         │          │         │
         ▼          ▼         ▼
     Backend    Backend   Backend
      Pods       Pods      Pods
```

### 6.2 Instalación de Ingress-Nginx

```bash
# Instalar ingress-nginx controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Verificar instalación
kubectl get pods -n ingress-nginx

# Debe mostrar:
# ingress-nginx-controller-xxx   1/1   Running

# Ver servicio (tipo LoadBalancer en cloud)
kubectl get svc -n ingress-nginx

# NAME                    TYPE           EXTERNAL-IP
# ingress-nginx-controller LoadBalancer  a1b2c3.elb.amazonaws.com
```

### 6.3 Ingress Simple

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

**Flujo:**
```
http://example.com
       ↓
Ingress Controller
       ↓
web-service:80
       ↓
Backend Pods
```

### 6.4 Path-Based Routing

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-routing
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 9000
```

**Resultado:**
- `http://myapp.com/api/*` → api-service
- `http://myapp.com/web/*` → web-service
- `http://myapp.com/admin/*` → admin-service

### 6.5 Host-Based Routing

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-based-routing
spec:
  ingressClassName: nginx
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
  
  - host: web.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
  
  - host: admin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 9000
```

### 6.6 TLS/HTTPS

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - secure.example.com
    secretName: tls-secret  # Secret con cert + key
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

**Crear TLS Secret:**

```bash
# Crear secret con certificado
kubectl create secret tls tls-secret \
  --cert=path/to/cert.crt \
  --key=path/to/cert.key

# O usar cert-manager para auto-provisioning
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### 6.7 Annotations Útiles

```yaml
metadata:
  annotations:
    # Rewrite target
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    
    # SSL redirect
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-methods: "PUT, GET, POST, OPTIONS"
    
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "10"
    
    # Authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    
    # Custom headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Custom-Header: value";
    
    # Whitelist IPs
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8,192.168.1.0/24"
```

---

## 7. Service Mesh Basics

### 7.1 ¿Qué es un Service Mesh?

Un service mesh es una capa de infraestructura dedicada para manejar comunicación service-to-service.

**Características:**

- **Traffic Management**: Load balancing, circuit breaking, retries
- **Security**: mTLS automático, autenticación, autorización
- **Observability**: Métricas, logs, tracing distribuido
- **Resilience**: Timeouts, retries, circuit breakers

**Arquitectura típica (Istio):**

```
┌────────────────────────────────────────────┐
│           Control Plane (istiod)           │
│  - Pilot (config distribution)             │
│  - Citadel (certificate management)        │
│  - Galley (config validation)              │
└──────────────┬─────────────────────────────┘
               │ Config push
               ▼
┌──────────────────────────────────────────────┐
│              Data Plane                      │
│                                              │
│  ┌────────────┐         ┌────────────┐      │
│  │   Pod A    │         │   Pod B    │      │
│  │            │         │            │      │
│  │ ┌────────┐ │         │ ┌────────┐ │      │
│  │ │  App   │ │         │ │  App   │ │      │
│  │ └───┬────┘ │         │ └───┬────┘ │      │
│  │     │      │         │     │      │      │
│  │ ┌───▼────┐ │         │ ┌───▼────┐ │      │
│  │ │ Envoy  │◄┼─────────┼─│ Envoy  │ │      │
│  │ │Sidecar │ │  mTLS   │ │Sidecar │ │      │
│  │ └────────┘ │         │ └────────┘ │      │
│  └────────────┘         └────────────┘      │
└──────────────────────────────────────────────┘
```

### 7.2 Service Mesh Populares

| Service Mesh | Complejidad | Features | Performance |
|--------------|-------------|----------|-------------|
| **Istio** | Alta | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Linkerd** | Media | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Consul Connect** | Media | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **AWS App Mesh** | Media | ⭐⭐⭐ | ⭐⭐⭐⭐ |

### 7.3 Cuándo Usar Service Mesh

**Usar cuando:**
- Microservicios > 20-30 services
- Necesitas mTLS entre todos los servicios
- Requieres observability avanzada
- Políticas de retry/timeout complejas
- Canary deployments / traffic splitting

**NO usar cuando:**
- Aplicación monolítica o < 10 services
- Cluster pequeño con pocos recursos
- Equipo sin experiencia (curva de aprendizaje)
- Latencia crítica (overhead de proxy)

---

## 8. Network Troubleshooting

### 8.1 Herramientas Esenciales

```bash
# Pod de debug con herramientas de red
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# Dentro del pod:
# - ping, curl, wget, nc (netcat)
# - dig, nslookup, host
# - traceroute, mtr
# - tcpdump, iperf3
# - iftop, nethogs
```

### 8.2 Diagnóstico Por Capas

**Capa 1: Conectividad Básica**

```bash
# Verificar pod tiene IP
kubectl get pod <pod-name> -o wide

# Ping entre pods (mismo nodo)
kubectl exec -it pod-a -- ping <ip-pod-b>

# Ping entre pods (diferente nodo)
kubectl exec -it pod-a -- ping <ip-pod-c>

# Verificar rutas
kubectl exec -it pod-a -- ip route
```

**Capa 2: DNS**

```bash
# Test DNS lookup
kubectl exec -it pod-a -- nslookup kubernetes.default

# Verificar resolv.conf
kubectl exec -it pod-a -- cat /etc/resolv.conf

# Test resolución de service
kubectl exec -it pod-a -- nslookup backend-service.default.svc.cluster.local

# Test DNS externo
kubectl exec -it pod-a -- nslookup google.com
```

**Capa 3: Services**

```bash
# Verificar service existe
kubectl get svc backend-service

# Ver endpoints (pods detrás del service)
kubectl get endpoints backend-service

# Debe listar IPs de pods:
# NAME              ENDPOINTS
# backend-service   10.244.1.5:8080,10.244.2.3:8080

# Test conectividad a service
kubectl exec -it pod-a -- curl backend-service:8080

# Test desde host con port-forward
kubectl port-forward svc/backend-service 8080:8080
curl localhost:8080
```

**Capa 4: Network Policies**

```bash
# Listar network policies
kubectl get networkpolicies

# Ver detalles
kubectl describe networkpolicy allow-frontend-to-backend

# Test conectividad (debe fallar si bloqueado)
kubectl exec -it unauthorized-pod -- curl backend-service:8080

# Ver logs de CNI (Calico example)
kubectl logs -n kube-system -l k8s-app=calico-node | grep -i deny
```

**Capa 5: Ingress**

```bash
# Verificar ingress
kubectl get ingress

# Ver eventos
kubectl describe ingress myapp-ingress

# Test desde fuera (usando external IP)
curl -H "Host: myapp.com" http://<external-ip>/api

# Ver logs del ingress controller
kubectl logs -n ingress-nginx <ingress-controller-pod>
```

### 8.3 Problemas Comunes

**Problema: Pod no puede resolver DNS**

```bash
# Síntomas:
kubectl exec -it pod-a -- nslookup google.com
# Error: server can't find google.com

# Diagnóstico:
# 1. Verificar CoreDNS corriendo
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 2. Verificar service de CoreDNS
kubectl get svc -n kube-system kube-dns

# 3. Ver logs de CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns

# 4. Verificar /etc/resolv.conf del pod
kubectl exec -it pod-a -- cat /etc/resolv.conf
# Debe tener: nameserver 10.96.0.10 (ClusterIP de kube-dns)
```

**Problema: Service no tiene endpoints**

```bash
# Síntomas:
kubectl get endpoints backend-service
# NAME              ENDPOINTS
# backend-service   <none>

# Diagnóstico:
# 1. Verificar selector del service coincide con labels de pods
kubectl get svc backend-service -o yaml | grep selector
kubectl get pods --show-labels

# 2. Verificar pods están Ready
kubectl get pods -l app=backend

# 3. Verificar readinessProbe pasa
kubectl describe pod <backend-pod> | grep -A 10 Readiness
```

**Problema: Ingress no funciona**

```bash
# 1. Verificar ingress controller corriendo
kubectl get pods -n ingress-nginx

# 2. Verificar ingress rules
kubectl get ingress myapp-ingress -o yaml

# 3. Verificar backend service existe
kubectl get svc web-service

# 4. Test directo al service (bypass ingress)
kubectl port-forward svc/web-service 8080:80
curl localhost:8080

# 5. Ver logs del ingress controller
kubectl logs -n ingress-nginx <controller-pod> | grep myapp
```

### 8.4 Captura de Tráfico (tcpdump)

```bash
# Capturar tráfico en pod
kubectl exec -it <pod-name> -- tcpdump -i any -n -A port 8080

# Capturar y guardar a archivo
kubectl exec -it <pod-name> -- tcpdump -i any -w /tmp/capture.pcap port 8080

# Copiar archivo del pod
kubectl cp <pod-name>:/tmp/capture.pcap ./capture.pcap

# Analizar con Wireshark localmente
wireshark capture.pcap
```

---

## 9. Performance y Optimización

### 9.1 Métricas de Red

```bash
# CPU/Memory de pods de red
kubectl top pods -n kube-system

# Conexiones activas en kube-proxy
kubectl exec -it <kube-proxy-pod> -n kube-system -- \
  conntrack -L | wc -l

# Ver reglas iptables (puede ser largo)
kubectl exec -it <kube-proxy-pod> -n kube-system -- \
  iptables-save | grep -c KUBE-SVC

# Latencia entre pods (iperf3)
# Server pod:
kubectl exec -it pod-a -- iperf3 -s

# Client pod:
kubectl exec -it pod-b -- iperf3 -c <ip-pod-a>
```

### 9.2 Optimizaciones

**kube-proxy mode:**

```yaml
# ConfigMap kube-proxy
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-proxy
  namespace: kube-system
data:
  config.conf: |
    mode: "ipvs"  # ipvs es más eficiente que iptables
    ipvs:
      scheduler: "rr"  # round-robin
```

**DNS caching:**

```yaml
# NodeLocal DNSCache
kubectl apply -f https://k8s.io/examples/admin/dns/nodelocaldns.yaml
```

**Service topology:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  topologyKeys:
  - "kubernetes.io/hostname"  # Preferir mismo nodo
  - "topology.kubernetes.io/zone"  # Luego misma zona
  - "*"  # Finalmente cualquier nodo
  selector:
    app: backend
  ports:
  - port: 8080
```

---

## 10. Best Practices

### 10.1 Seguridad

✅ **DO:**
- Implementar Network Policies en producción
- Usar RBAC para limitar creación de Services tipo LoadBalancer
- TLS en todos los Ingress de producción
- mTLS entre servicios (service mesh)
- Whitelist IPs en Ingress cuando sea posible

❌ **DON'T:**
- Exponer pods directamente con HostNetwork
- Usar puertos privilegiados (< 1024) sin necesidad
- Permitir tráfico all-to-all sin Network Policies
- Servicios tipo LoadBalancer sin restricciones de IP

### 10.2 Performance

✅ **DO:**
- Usar ipvs mode en kube-proxy para clusters grandes
- Implementar NodeLocal DNSCache
- Usar headless services para databases
- Configurar topology-aware routing
- Limitar endpoints por service (< 1000)

❌ **DON'T:**
- Services con miles de endpoints
- DNS queries innecesarias (cache en aplicación)
- Crear servicios para cada pod individual

### 10.3 Observability

✅ **DO:**
- Logs centralizados de CNI, CoreDNS, Ingress
- Métricas de latencia de red
- Alertas en errores de DNS
- Tracing distribuido (Jaeger, Zipkin)

### 10.4 Alta Disponibilidad

✅ **DO:**
- CoreDNS con múltiples replicas (3+)
- Ingress controllers en múltiples nodos
- Anti-affinity para pods de red críticos
- Health checks en services
- Circuit breakers y retries (service mesh)

---

## Recursos Adicionales

### Documentación Oficial

- [Kubernetes Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [CoreDNS](https://coredns.io/plugins/kubernetes/)

### Tools

- [Calico](https://www.tigera.io/project-calico/)
- [Cilium](https://cilium.io/)
- [Ingress-Nginx](https://kubernetes.github.io/ingress-nginx/)
- [Istio](https://istio.io/)
- [Linkerd](https://linkerd.io/)

### Labs y Tutoriales

- Ver directorio `laboratorios/` para prácticas hands-on
- Ver directorio `ejemplos/` para YAML de referencia

---

## Siguientes Pasos

1. Completar laboratorios 01-04 en orden
2. Practicar troubleshooting en cluster de prueba
3. Implementar Network Policies en ambiente dev
4. Explorar service mesh (Istio/Linkerd)
5. Preparar para CKA: troubleshooting de red es ~20% del examen

---

**Última actualización**: Noviembre 2025
**Versión de Kubernetes**: 1.28+
**Autor**: Curso Kubernetes CKA/CKAD
