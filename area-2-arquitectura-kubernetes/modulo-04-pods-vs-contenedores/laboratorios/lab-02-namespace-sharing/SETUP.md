# SETUP: Lab 02 - Namespace Sharing Deep Dive

## Prerequisitos

### Conocimientos Previos

- Conceptos basicos de Linux namespaces (network, PID, mount)
- Familiaridad con kubectl y Pods de Kubernetes
- Haber completado el Lab 01 (Evolucion Historica) del mismo modulo

### Herramientas Necesarias

| Herramienta | Version Minima | Proposito |
|-------------|---------------|-----------|
| kubectl | 1.25 o superior | Todas las operaciones del laboratorio |
| Cluster Kubernetes | 1.25 o superior | Minikube, kind, k3s o cloud |

A diferencia del Lab 01, este laboratorio no requiere Docker instalado localmente.

## Verificacion del Entorno

### Verificar kubectl y Cluster

```bash
kubectl cluster-info
```

Salida esperada:
```
Kubernetes control plane is running at https://127.0.0.1:PORT
CoreDNS is running at https://127.0.0.1:PORT/api/v1/...
```

```bash
kubectl get nodes
```

Salida esperada:
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   Xd    v1.27.X
```

```bash
# Verificar permisos para crear Pods
kubectl auth can-i create pods
```

Salida esperada:
```
yes
```

### Verificar Archivos del Laboratorio

```bash
ls -la /ruta/al/lab-02-namespace-sharing/
```

Salida esperada:
```
-rw-rw-r-- README.md
-rw-rw-r-- README.md.backup
-rw-rw-r-- SETUP.md
-rw-rw-r-- namespace-pod.yaml
-rw-rw-r-- shared-pid-pod.yaml
-rw-rw-r-- shared-volume-pod.yaml
-rwxrwxr-x cleanup.sh
```

### Verificar imagen busybox disponible

```bash
# Confirmar que el cluster puede descargar la imagen busybox
kubectl run test-busybox --image=busybox --restart=Never --rm -it -- echo "imagen ok" 2>/dev/null || true
```

## Descripcion de los Archivos YAML

| Archivo | Pod creado | Namespaces analizados |
|---------|-----------|----------------------|
| `namespace-pod.yaml` | `namespace-demo` | Network, UTS, IPC, Mount, User |
| `shared-pid-pod.yaml` | `shared-pid-demo` | PID (con shareProcessNamespace: true) |
| `shared-volume-pod.yaml` | `shared-volume-demo` | Mount (con emptyDir volume) |

## Inicio Rapido

Una vez verificados los prerequisitos, ve directamente al README.md del laboratorio y sigue los pasos en orden desde el Paso 1.

El laboratorio puede completarse en un unico cluster de un nodo (minikube es suficiente).
