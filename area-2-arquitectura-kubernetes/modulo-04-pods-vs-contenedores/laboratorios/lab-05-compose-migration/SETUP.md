# SETUP - Lab 05: Migracion de Docker Compose a Kubernetes

## Prerequisitos

### Conocimientos Previos

- Comprension basica de Docker Compose (`docker-compose.yml`)
- Conocimiento de Pods y Deployments de Kubernetes (modulos 03-04)
- Familiaridad con Services de Kubernetes (ClusterIP, NodePort)
- Conceptos de ConfigMap y Secret (modulos 08/13-14)

### Herramientas Necesarias

| Herramienta | Version minima | Requerida |
|-------------|----------------|-----------|
| kubectl | 1.25+ | Si |
| minikube | 1.28+ | Recomendado |
| docker | 20.10+ | Opcional (para comparacion) |
| docker-compose | 1.29+ / v2 | Opcional |

---

## Verificacion del Entorno

### 1. Verificar cluster activo

```bash
kubectl cluster-info
kubectl get nodes
```

**Salida esperada:**

```
Kubernetes control plane is running at https://192.168.49.2:8443
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1d    v1.28.x
```

### 2. Verificar que kubectl responde

```bash
kubectl version --client
kubectl get pods -A | head -10
```

### 3. Verificar StorageClass para PVCs

Este laboratorio crea un PersistentVolumeClaim. El cluster necesita un StorageClass
con un provisioner automatico.

```bash
kubectl get storageclass
```

**En Minikube, la salida esperada incluye:**

```
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate
```

Si no hay StorageClass por defecto, el PVC quedara en estado `Pending`. En ese caso:

```bash
# Habilitar el addon de storage en Minikube
minikube addons enable default-storageclass
minikube addons enable storage-provisioner
```

### 4. Verificar archivos YAML del laboratorio

```bash
ls /media/Data/Source/Courses/K8S/area-2-arquitectura-kubernetes/modulo-04-pods-vs-contenedores/laboratorios/lab-05-compose-migration/*.yaml
```

**Salida esperada:**

```
api-deployment.yaml  db-deployment.yaml  web-deployment.yaml
```

---

## Nota Importante: Acceso al Service NodePort en Minikube

El frontend web se expone como `Service` tipo `NodePort` en el puerto `30080`.
En Minikube, el cluster corre dentro de una VM o contenedor, por lo que
`localhost:30080` **no funciona directamente**.

Para obtener la URL correcta:

```bash
# Opcion 1: Obtener URL del service (recomendado)
minikube service web --url
# Salida: http://192.168.49.2:30080

# Opcion 2: Usar la IP del nodo directamente
curl http://$(minikube ip):30080

# Opcion 3: port-forward como alternativa universal
kubectl port-forward service/web 8080:80
# Luego: curl http://localhost:8080
```

---

## Limpieza Rapida

Si necesitas limpiar todos los recursos antes de empezar de nuevo:

```bash
cd /media/Data/Source/Courses/K8S/area-2-arquitectura-kubernetes/modulo-04-pods-vs-contenedores/laboratorios/lab-05-compose-migration
./cleanup.sh
```
