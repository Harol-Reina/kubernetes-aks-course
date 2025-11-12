# Python API Client - Ejemplo Completo

Este directorio contiene un ejemplo completo de una aplicación Python que interactúa con la API de Kubernetes usando Service Accounts.

## 📁 Archivos

- **deployment.yaml** - Manifiestos de Kubernetes completos
- **app.py** - Script Python con el cliente de Kubernetes

## 🎯 Objetivo

Demostrar cómo una aplicación Python corriendo en Kubernetes puede:
- Autenticarse usando el Service Account del pod
- Listar pods en su namespace
- Leer logs de pods
- Observar cambios en tiempo real

## 🚀 Despliegue Rápido

```bash
# Aplicar todos los manifiestos
kubectl apply -f deployment.yaml

# Ver el deployment
kubectl get deployment python-api-client -n desarrollo

# Ver los logs (la aplicación lista pods cada 30 segundos)
kubectl logs -f deployment/python-api-client -n desarrollo
```

## 📖 Uso del Script Python

### Dentro de un Pod

```bash
# Obtener el nombre del pod
POD=$(kubectl get pods -n desarrollo -l app=python-client -o jsonpath='{.items[0].metadata.name}')

# Ejecutar el script
kubectl exec -it $POD -n desarrollo -- python /app/list_pods.py

# O entrar al pod y experimentar
kubectl exec -it $POD -n desarrollo -- bash
python /app/list_pods.py
```

### Desarrollo Local

Si quieres probar el script localmente:

```bash
# Instalar dependencias
pip install kubernetes

# Ejecutar con tu kubeconfig local
python app.py --kubeconfig ~/.kube/config

# Ver logs de un pod específico
python app.py --logs pod-name --namespace desarrollo

# Observar cambios en tiempo real
python app.py --watch --namespace desarrollo
```

## 🔑 Cómo Funciona

### 1. Configuración del Cliente

```python
from kubernetes import client, config

# Dentro de un pod de Kubernetes
config.load_incluster_config()

# Fuera del cluster (desarrollo local)
config.load_kube_config()
```

### 2. Autenticación Automática

Cuando `load_incluster_config()` se ejecuta:

1. Lee el token desde `/var/run/secrets/kubernetes.io/serviceaccount/token`
2. Lee el CA certificate desde `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`
3. Lee el namespace desde `/var/run/secrets/kubernetes.io/serviceaccount/namespace`
4. Configura el cliente para autenticarse con la API

### 3. Uso de la API

```python
# Crear cliente
v1 = client.CoreV1Api()

# Listar pods
pods = v1.list_namespaced_pod(namespace="desarrollo")

# Iterar sobre los pods
for pod in pods.items:
    print(f"Pod: {pod.metadata.name}")
    print(f"Estado: {pod.status.phase}")
```

## 🛡️ Permisos RBAC

El Service Account tiene estos permisos (definidos en `deployment.yaml`):

```yaml
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["list", "get"]
  
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
```

Esto significa que la aplicación puede:
- ✅ Listar pods en el namespace `desarrollo`
- ✅ Obtener detalles de pods específicos
- ✅ Leer logs de pods

Pero NO puede:
- ❌ Crear, actualizar o eliminar pods
- ❌ Acceder a otros namespaces
- ❌ Acceder a secrets
- ❌ Modificar configuraciones

## 🔬 Experimentación Interactiva

```bash
# Entrar al pod
kubectl exec -it $POD -n desarrollo -- python3

# En el REPL de Python:
from kubernetes import client, config

# Cargar configuración
config.load_incluster_config()

# Crear clientes
v1 = client.CoreV1Api()
apps_v1 = client.AppsV1Api()

# Listar pods
pods = v1.list_namespaced_pod(namespace="desarrollo")
for pod in pods.items:
    print(pod.metadata.name)

# Obtener un pod específico
pod = v1.read_namespaced_pod(name="python-api-client-xxx", namespace="desarrollo")
print(f"Estado: {pod.status.phase}")
print(f"IP: {pod.status.pod_ip}")

# Leer logs
logs = v1.read_namespaced_pod_log(name="python-api-client-xxx", namespace="desarrollo", tail_lines=10)
print(logs)

# Intentar algo sin permisos (fallará)
try:
    v1.create_namespaced_pod(namespace="desarrollo", body={})
except client.exceptions.ApiException as e:
    print(f"Error {e.status}: {e.reason}")
```

## 📚 Documentación de la API

### Recursos Principales

```python
# Core API (pods, services, configmaps, secrets, etc.)
v1 = client.CoreV1Api()

# Apps API (deployments, statefulsets, daemonsets)
apps_v1 = client.AppsV1Api()

# Batch API (jobs, cronjobs)
batch_v1 = client.BatchV1Api()

# RBAC API (roles, rolebindings)
rbac_v1 = client.RbacAuthorizationV1Api()
```

### Operaciones Comunes

```python
# Listar recursos
pods = v1.list_namespaced_pod(namespace="default")
deployments = apps_v1.list_namespaced_deployment(namespace="default")

# Obtener un recurso específico
pod = v1.read_namespaced_pod(name="my-pod", namespace="default")

# Crear un recurso
pod_manifest = client.V1Pod(...)
v1.create_namespaced_pod(namespace="default", body=pod_manifest)

# Actualizar un recurso
v1.patch_namespaced_pod(name="my-pod", namespace="default", body=patch)

# Eliminar un recurso
v1.delete_namespaced_pod(name="my-pod", namespace="default")

# Observar cambios (watch)
from kubernetes import watch
w = watch.Watch()
for event in w.stream(v1.list_namespaced_pod, namespace="default"):
    print(f"{event['type']}: {event['object'].metadata.name}")
```

## 🧹 Limpieza

```bash
kubectl delete -f deployment.yaml
```

## 🔗 Referencias

- [Python Kubernetes Client](https://github.com/kubernetes-client/python)
- [Documentación oficial](https://github.com/kubernetes-client/python/blob/master/kubernetes/README.md)
- [Ejemplos](https://github.com/kubernetes-client/python/tree/master/examples)
