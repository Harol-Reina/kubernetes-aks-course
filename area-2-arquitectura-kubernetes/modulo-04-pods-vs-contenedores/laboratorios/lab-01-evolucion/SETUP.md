# SETUP: Lab 01 - Evolucion Historica

## Prerequisitos

### Conocimientos Previos

- Conceptos basicos de containerizacion (modulo anterior)
- Familiaridad con la linea de comandos Linux
- Nocion basica de redes (IP, puertos)

### Herramientas Necesarias

| Herramienta | Version Minima | Proposito |
|-------------|---------------|-----------|
| Docker | 20.x o superior | Pasos 2 y 3 (LXC y Docker demos) |
| kubectl | 1.25 o superior | Paso 4 (Kubernetes demo) |
| Cluster Kubernetes | 1.25 o superior | Minikube, kind, k3s o cloud |

## Verificacion del Entorno

### Verificar Docker

```bash
docker version --format '{{.Server.Version}}'
```

Salida esperada (ejemplo):
```
24.0.5
```

```bash
# Verificar que Docker esta corriendo
docker ps
```

Salida esperada (sin error):
```
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
```

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
ls -la /ruta/al/lab-01-evolucion/
```

Salida esperada:
```
-rw-rw-r-- README.md
-rw-rw-r-- README.md.backup
-rw-rw-r-- SETUP.md
-rw-rw-r-- evolution-pod.yaml
-rwxrwxr-x cleanup.sh
```

## Notas sobre Docker en este Lab

Los pasos 2 y 3 de este laboratorio requieren Docker directamente (no kubectl). Estos pasos simulan los enfoques LXC y Docker para establecer el contraste con el enfoque Kubernetes del paso 4.

Si solo tienes acceso a kubectl (sin Docker local), puedes omitir los pasos 2 y 3 y enfocarte en el paso 4 (Kubernetes), que es el objetivo principal del modulo.

## Inicio Rapido

Una vez verificados los prerequisitos, ve directamente al README.md del laboratorio y sigue los pasos en orden desde el Paso 1.
