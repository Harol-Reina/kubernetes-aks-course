# SETUP - Lab 02: Control Plane Practico

## Requisitos Previos

- Cluster Kubernetes funcional (Minikube recomendado)
- kubectl configurado y conectado al cluster
- minikube instalado con driver Docker
- `jq` instalado para parsing de JSON
- `curl` instalado para peticiones HTTP directas al API Server

> El ejercicio de API REST (Parte 1) requiere `curl` y acceso al API Server via `kubectl proxy`
> o con token de autenticacion. Todos los demas ejercicios usan solo `kubectl`.

## Instalacion de Dependencias

```bash
# Instalar jq (Ubuntu/Debian)
sudo apt-get install -y jq

# Verificar instalacion
jq --version
curl --version
```

## Verificacion del Entorno

```bash
# Verificar que el cluster esta activo
kubectl cluster-info

# Verificar nodos disponibles
kubectl get nodes

# Verificar componentes del Control Plane
kubectl get pods -n kube-system -l tier=control-plane

# Verificar acceso al API Server
kubectl get --raw /healthz
```

**Salida esperada de `kubectl get --raw /healthz`:**
```
ok
```

**Salida esperada de `kubectl get pods -n kube-system -l tier=control-plane`:**
```
NAME                               READY   STATUS    RESTARTS   AGE
etcd-minikube                      1/1     Running   0          Xd
kube-apiserver-minikube            1/1     Running   0          Xd
kube-controller-manager-minikube   1/1     Running   0          Xd
kube-scheduler-minikube            1/1     Running   0          Xd
```

## Recursos del Sistema Recomendados

| Recurso | Minimo | Recomendado |
|---------|--------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disco | 20 GB | 40 GB |

## Archivos del Laboratorio

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `scheduler-test.yaml` | Ejercicio 3.1 | Pod sin nodeSelector para observar scheduling |
| `ssd-pod.yaml` | Ejercicio 3.2 | Pod con nodeSelector disktype=ssd |
| `unschedulable-pod.yaml` | Ejercicio 3.2 | Pod con nodeSelector inexistente (Pending) |
| `huge-pod.yaml` | Ejercicio 3.3 | Pod con recursos imposibles (Pending) |
| `manual-schedule.yaml` | Ejercicio 3.4 | Pod con schedulerName inexistente para asignacion manual |
| `broken-pod.yaml` | Ejercicio 5.3 | Pod con imagen inexistente (ImagePullBackOff) |
| `pod-via-api.json` | Ejercicio 1.4 | Definicion JSON para crear Pod via REST API |

## Limpieza

```bash
./cleanup.sh
```
