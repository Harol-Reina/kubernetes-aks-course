# 📁 Ejemplos - Módulo 04: Pods vs Contenedores

Esta carpeta contiene ejemplos prácticos organizados por concepto.

## 📂 Estructura

```
ejemplos/
├── 01-evolucion/          # Evolución LXC → Docker → Kubernetes
├── 02-namespaces/         # Exploración de namespace sharing
├── 03-multi-container/    # Patrones multi-contenedor
├── 04-init-containers/    # Init containers para setup
└── 05-migracion-compose/  # Migración de Docker Compose
```

---

## 🚀 01-evolucion/

Demuestra la evolución de la tecnología de contenedores.

### `evolution-pod.yaml`
- **Propósito**: Mostrar networking compartido en Pods vs Docker bridge
- **Uso**:
  ```bash
  kubectl apply -f 01-evolucion/evolution-pod.yaml
  kubectl wait --for=condition=Ready pod/evolution-demo
  
  # Probar comunicación localhost
  kubectl exec evolution-demo -c web -- wget -qO- http://localhost:8080
  kubectl exec evolution-demo -c api -- wget -qO- http://localhost:80
  ```

---

## 🔬 02-namespaces/

Explora qué namespaces Linux comparten los contenedores en un Pod.

### `namespace-pod.yaml`
- **Propósito**: Análisis de namespace sharing (Network, PID, IPC, UTS)
- **Uso**:
  ```bash
  kubectl apply -f 02-namespaces/namespace-pod.yaml
  
  # Verificar Network namespace (misma IP)
  kubectl exec namespace-demo -c container1 -- ip addr
  kubectl exec namespace-demo -c container2 -- ip addr
  
  # Verificar PID namespace (procesos compartidos)
  kubectl exec namespace-demo -c container1 -- ps aux
  kubectl exec namespace-demo -c container2 -- ps aux
  
  # Verificar hostname (UTS namespace compartido)
  kubectl exec namespace-demo -c container1 -- hostname
  kubectl exec namespace-demo -c container2 -- hostname
  ```

---

## 🧩 03-multi-container/

Implementa el patrón Sidecar para procesamiento de logs.

### `sidecar-pod.yaml`
- **Propósito**: Aplicación web + Log processor sidecar
- **Uso**:
  ```bash
  kubectl apply -f 03-multi-container/sidecar-pod.yaml
  kubectl wait --for=condition=Ready pod/webapp-sidecar
  
  # Generar tráfico
  kubectl port-forward pod/webapp-sidecar 8080:5000 &
  curl http://localhost:8080/
  
  # Ver logs procesados
  kubectl logs webapp-sidecar -c log-processor -f
  kubectl logs webapp-sidecar -c webapp
  ```

---

## 🔧 04-init-containers/

Demuestra el uso de init containers para setup de aplicaciones.

### `postgres-pod.yaml`
- **Propósito**: Base de datos PostgreSQL para la demo
- **Uso**:
  ```bash
  kubectl apply -f 04-init-containers/postgres-pod.yaml
  kubectl wait --for=condition=Ready pod/db
  ```

### `init-pod.yaml`
- **Propósito**: App con 3 init containers (wait-db, migrations, config)
- **Uso**:
  ```bash
  # Primero desplegar la base de datos
  kubectl apply -f 04-init-containers/postgres-pod.yaml
  
  # Luego la app con init containers
  kubectl apply -f 04-init-containers/init-pod.yaml
  
  # Observar la secuencia de inicialización
  kubectl get pods app-with-init --watch
  
  # Ver logs de cada init container
  kubectl logs app-with-init -c wait-for-db
  kubectl logs app-with-init -c db-migration
  kubectl logs app-with-init -c config-setup
  
  # Ver logs del contenedor principal
  kubectl logs app-with-init -c app
  ```

---

## 🔄 05-migracion-compose/

Ejemplos de migración de Docker Compose a Kubernetes.

### Archivos

1. **`docker-compose.yml`** - Configuración original
2. **`web-deployment.yaml`** - Frontend Nginx (Deployment + Service)
3. **`api-deployment.yaml`** - Backend Node.js (Deployment + Service)
4. **`db-deployment.yaml`** - Database PostgreSQL (Deployment + Service)

### Uso

```bash
# Desplegar todos los componentes
kubectl apply -f 05-migracion-compose/db-deployment.yaml
kubectl apply -f 05-migracion-compose/api-deployment.yaml
kubectl apply -f 05-migracion-compose/web-deployment.yaml

# Verificar despliegue
kubectl get all

# Acceder al servicio web
kubectl port-forward service/web-service 8080:80
# Abrir: http://localhost:8080
```

### Comparación Docker Compose vs Kubernetes

| Docker Compose | Kubernetes Equivalent |
|----------------|----------------------|
| `services` | Deployments |
| `depends_on` | Init containers o readiness probes |
| `networks` | Services (ClusterIP networking automático) |
| `volumes` | PersistentVolumeClaims |
| `ports` | Service type: LoadBalancer |
| `environment` | env o ConfigMaps |
| `scale` | replicas en Deployment |

---

## 🧹 Limpieza

Para eliminar todos los recursos creados:

```bash
# Limpiar ejemplos individuales
kubectl delete pod evolution-demo
kubectl delete pod namespace-demo
kubectl delete pod webapp-sidecar
kubectl delete pod app-with-init db
kubectl delete service db-service

# Limpiar migración compose
kubectl delete -f 05-migracion-compose/

# O eliminar todo de una vez
kubectl delete pods --all
kubectl delete services --all
kubectl delete deployments --all
```

---

## 📚 Conceptos Clave

Estos ejemplos demuestran:

1. **Evolución tecnológica**: LXC → Docker → Kubernetes
2. **Namespace sharing**: Cómo los contenedores en un Pod comparten recursos
3. **Patrones multi-contenedor**: Sidecar para cross-cutting concerns
4. **Init containers**: Setup antes de la aplicación principal
5. **Migración**: De Docker Compose a Kubernetes declarativo

---

## 🔗 Recursos Adicionales

- **[README Principal](../README.md)** - Teoría completa del módulo
- **[Documentación Oficial Pods](https://kubernetes.io/docs/concepts/workloads/pods/)**
- **[Patrones Multi-Contenedor](https://kubernetes.io/blog/2015/06/the-distributed-system-toolkit-patterns/)**
- **[Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)**
