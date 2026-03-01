# SETUP - Lab 01: Exploracion de Arquitectura

## Requisitos Previos

- Cluster Kubernetes funcional (Minikube recomendado)
- kubectl configurado y conectado al cluster
- minikube instalado con driver Docker

> Este laboratorio funciona con la configuracion por defecto de Minikube.
> No requiere herramientas adicionales ni CNI especifico.

## Verificacion del Entorno

```bash
# Verificar que el cluster esta activo
kubectl cluster-info

# Verificar nodos disponibles
kubectl get nodes

# Verificar que los componentes del sistema estan corriendo
kubectl get pods -n kube-system
```

**Salida esperada de `kubectl get nodes`:**
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   Xd    v1.28.x
```

**Salida esperada de `kubectl get pods -n kube-system`:**
```
NAME                               READY   STATUS    RESTARTS   AGE
coredns-xxx                        1/1     Running   0          Xd
etcd-minikube                      1/1     Running   0          Xd
kube-apiserver-minikube            1/1     Running   0          Xd
kube-controller-manager-minikube   1/1     Running   0          Xd
kube-proxy-xxx                     1/1     Running   0          Xd
kube-scheduler-minikube            1/1     Running   0          Xd
storage-provisioner                1/1     Running   0          Xd
```

## Recursos del Sistema Recomendados

| Recurso | Minimo | Recomendado |
|---------|--------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disco | 20 GB | 40 GB |

## Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de recursos creados imperativamente |

> Este laboratorio usa exclusivamente comandos imperativos (`kubectl run`, `kubectl create`, etc.).
> No hay archivos YAML que aplicar.

## Limpieza

```bash
./cleanup.sh
```
