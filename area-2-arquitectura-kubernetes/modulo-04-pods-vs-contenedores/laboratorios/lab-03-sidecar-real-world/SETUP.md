# Setup - Lab 03: Sidecar Pattern Real-World

## Prerequisitos

### Conocimientos Requeridos

- Conceptos basicos de Pods y multi-container Pods
- Fundamentos de Docker (build de imagenes)
- Nociones de Python/Flask (para entender la app de ejemplo)
- Comprension de ConfigMaps (modulo anterior)

### Herramientas Necesarias

| Herramienta | Version Minima | Proposito |
|-------------|---------------|-----------|
| `kubectl` | >= 1.24 | Gestion del cluster |
| `docker` | >= 20.10 | Build de la imagen Flask (web-app.py) |
| `minikube` o cluster K8s | >= 1.24 | Entorno de ejecucion |
| `curl` | cualquiera | Generacion de trafico de prueba |
| `jq` | cualquiera | Formateo de respuestas JSON |

> **Nota sobre Docker**: Este laboratorio requiere Docker para construir la imagen `sidecar-webapp:v1` desde el `Dockerfile` proporcionado. Si usas Minikube, puedes cargar la imagen con `minikube image load sidecar-webapp:v1`.

### Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `web-app.py` | Aplicacion Flask con logging JSON estructurado |
| `Dockerfile` | Imagen python:3.9-slim para la app Flask |
| `fluent-bit.conf` | Configuracion del sidecar Fluent Bit |
| `sidecar-pod.yaml` | Manifiesto del Pod multi-container |
| `cleanup.sh` | Script de limpieza de recursos |

## Verificacion del Entorno

### 1. Verificar cluster

```bash
kubectl cluster-info
kubectl get nodes
```

Salida esperada:
```
Kubernetes control plane is running at https://192.168.49.2:8443
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   5d    v1.28.0
```

### 2. Verificar Docker

```bash
docker version --format '{{.Client.Version}}'
```

### 3. Verificar permisos

```bash
kubectl auth can-i create pods
kubectl auth can-i create configmaps
```

### 4. Verificar archivos del laboratorio

```bash
ls -la /ruta/al/lab-03-sidecar-real-world/
# Deben estar: web-app.py, Dockerfile, fluent-bit.conf, sidecar-pod.yaml, cleanup.sh
```

## Notas de Configuracion

- El Pod usa `imagePullPolicy: Never`, lo que requiere que la imagen `sidecar-webapp:v1` este disponible localmente en el nodo
- En Minikube, ejecuta el build dentro del contexto Docker de Minikube o usa `minikube image load` despues del build local
- El sidecar Fluent Bit usa la imagen publica `fluent/fluent-bit:2.0`, que se descarga automaticamente del registry
