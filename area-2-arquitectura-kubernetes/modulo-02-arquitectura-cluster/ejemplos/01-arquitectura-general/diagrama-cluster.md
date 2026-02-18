# Diagrama Completo del Cluster Kubernetes

Este documento proporciona diagramas visuales detallados de la arquitectura completa de un cluster Kubernetes.

## Arquitectura de Alto Nivel

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                         KUBERNETES CLUSTER (Producción)                          │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │                          CONTROL PLANE (HA)                                │  │
│  │                                                                            │  │
│  │  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐                    │  │
│  │  │ Master 1     │   │ Master 2     │   │ Master 3     │                    │  │
│  │  │              │   │              │   │              │                    │  │
│  │  │ API Server   │   │ API Server   │   │ API Server   │                    │  │
│  │  │ Scheduler    │   │ Scheduler    │   │ Scheduler    │                    │  │
│  │  │ Controller   │   │ Controller   │   │ Controller   │                    │  │
│  │  │ Manager      │   │ Manager      │   │ Manager      │                    │  │
│  │  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘                    │  │
│  │         │                  │                  │                            │  │
│  │         └──────────────────┼──────────────────┘                            │  │
│  │                            │                                               │  │
│  │         ┌──────────────────┴──────────────────┐                            │  │
│  │         │                                     │                            │  │
│  │  ┌──────▼───────┐   ┌──────────────┐   ┌────▼─────────┐                    │  │
│  │  │  etcd-1      │◄──┤  etcd-2      │──►│  etcd-3      │                    │  │
│  │  │  LEADER      │   │  FOLLOWER    │   │  FOLLOWER    │                    │  │
│  │  └──────────────┘   └──────────────┘   └──────────────┘                    │  │
│  │       (RAFT Consensus - Quorum: 2/3)                                       │  │
│  └────────────────────────────────────────────────────────────────────────────┘  │
│                                   │                                              │
│                                   │ (Secure TLS Connection)                      │
│                                   │                                              │
│  ┌────────────────────────────────┴────────────────────────────────────────┐     │
│  │                          WORKER NODES                                   │     │
│  │                                                                         │     │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐             │     │
│  │  │  Worker 1      │  │  Worker 2      │  │  Worker 3      │  ...        │     │
│  │  │                │  │                │  │                │             │     │
│  │  │ ┌────────────┐ │  │ ┌────────────┐ │  │ ┌────────────┐ │             │     │
│  │  │ │  kubelet   │ │  │ │  kubelet   │ │  │ │  kubelet   │ │             │     │
│  │  │ └────────────┘ │  │ └────────────┘ │  │ └────────────┘ │             │     │
│  │  │ ┌────────────┐ │  │ ┌────────────┐ │  │ ┌────────────┐ │             │     │
│  │  │ │ kube-proxy │ │  │ │ kube-proxy │ │  │ │ kube-proxy │ │             │     │
│  │  │ └────────────┘ │  │ └────────────┘ │  │ └────────────┘ │             │     │
│  │  │ ┌────────────┐ │  │ ┌────────────┐ │  │ ┌────────────┐ │             │     │
│  │  │ │containerd  │ │  │ │containerd  │ │  │ │containerd  │ │             │     │
│  │  │ └────────────┘ │  │ └────────────┘ │  │ └────────────┘ │             │     │
│  │  │                │  │                │  │                │             │     │
│  │  │ [Pods 1-10]    │  │ [Pods 11-20]   │  │ [Pods 21-30]   │             │     │
│  │  └────────────────┘  └────────────────┘  └────────────────┘             │     │
│  └─────────────────────────────────────────────────────────────────────────┘     │
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐     │
│  │                        NETWORKING & INGRESS                             │     │
│  │                                                                         │     │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐             │     │
│  │  │ Load Balancer  │  │ Ingress Ctrl   │  │  CoreDNS       │             │     │
│  │  │ (External)     │  │ (nginx/traefik)│  │  (DNS)         │             │     │
│  │  └────────────────┘  └────────────────┘  └────────────────┘             │     │
│  └─────────────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────────────────┘
```

## Flujo de Comunicación

### 1. Creación de un Deployment

```
Usuario                API Server          etcd            Scheduler         kubelet
  │                        │                │                 │                 │
  │ kubectl create deploy  │                │                 │                 │
  ├───────────────────────►│                │                 │                 │
  │                        │ Persist        │                 │                 │
  │                        ├───────────────►│                 │                 │
  │                        │                │                 │                 │
  │                        │ Watch: New Pod │                 │                 │
  │                        │◄───────────────┼─────────────────┤                 │
  │                        │                │                 │                 │
  │                        │                │ Assign to Node  │                 │
  │                        │◄───────────────┴─────────────────┤                 │
  │                        │                                  │                 │
  │                        │ Update Pod.spec.nodeName         │                 │
  │                        ├───────────────────────────────────────────────────►│
  │                        │                                  │                 │
  │                        │                                  │ Pull Image      │
  │                        │                                  │ Create Container│
  │                        │                                  │ Start Pod       │
  │                        │◄───────────────────────────────────────────────────┤
  │                        │ Update Pod.status = Running      │                 │
  │◄───────────────────────┤                                  │                 │
  │ Response: Created      │                                  │                 │
```

### 2. Servicio de Red (Service)

```
Pod A (10.244.1.5)      Service (10.96.0.10)     Pod B (10.244.2.3)
      │                        │                        │
      │ Request to service     │                        │
      │ GET /api               │                        │
      ├───────────────────────►│                        │
      │                        │                        │
      │                        │ kube-proxy routes      │
      │                        │ (iptables/IPVS)        │
      │                        ├───────────────────────►│
      │                        │                        │
      │                        │◄───────────────────────┤
      │◄───────────────────────┤ Response               │
      │                        │                        │
```

## Componentes Detallados

### Control Plane Components

| Componente | Puerto | Protocolo | Función |
|-----------|--------|-----------|---------|
| API Server | 6443 | HTTPS | API REST principal |
| etcd | 2379 | HTTPS | Client connections |
| etcd | 2380 | HTTPS | Peer communication |
| Scheduler | 10251 | HTTP | Health checks |
| Controller Manager | 10252 | HTTP | Health checks |

### Worker Node Components

| Componente | Puerto | Protocolo | Función |
|-----------|--------|-----------|---------|
| kubelet | 10250 | HTTPS | API de kubelet |
| kube-proxy | 10256 | HTTP | Health checks |
| NodePort Services | 30000-32767 | TCP/UDP | External access |

## Verificación de Componentes

```bash
# Ver estado de componentes del Control Plane
kubectl get pods -n kube-system

# Ver nodos del cluster
kubectl get nodes -o wide

# Ver servicios de sistema
kubectl get svc -n kube-system

# Verificar etcd cluster
kubectl exec -it etcd-master -n kube-system -- etcdctl member list

# Ver métricas de componentes
kubectl top nodes
kubectl top pods -n kube-system
```

## Configuración de Alta Disponibilidad

Para producción, se recomienda:

- **Control Plane**: Mínimo 3 masters (odd number para quorum)
- **etcd**: Cluster de 3 o 5 nodos (separado de masters en producción)
- **Worker Nodes**: Basado en carga de trabajo (mínimo 3 para HA)
- **Load Balancer**: Frontend para API servers
- **Networking**: CNI plugin (Calico, Flannel, Cilium)

## Recursos Adicionales

- [Arquitectura oficial de Kubernetes](https://kubernetes.io/docs/concepts/architecture/)
- [Componentes de Kubernetes](https://kubernetes.io/docs/concepts/overview/components/)
- [etcd clustering](https://etcd.io/docs/latest/op-guide/clustering/)
