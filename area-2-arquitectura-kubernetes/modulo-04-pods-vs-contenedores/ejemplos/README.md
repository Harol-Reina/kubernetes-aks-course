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

**Explora en detalle los 7 tipos de Linux Namespaces en Kubernetes.**

Esta carpeta contiene ejemplos prácticos para CADA tipo de namespace, demostrando cuáles se comparten y cuáles no.

### **📋 Contenido:**

| Archivo | Namespace | Compartido | Demo |
|---------|-----------|------------|------|
| `01-network-namespace.yaml` | 🌐 Network (net) | ✅ Sí | Misma IP, comunicación localhost |
| `02-pid-namespace.yaml` | 🔄 PID (pid) | ⚙️ Opcional | Con/sin `shareProcessNamespace` |
| `03-ipc-namespace.yaml` | 💬 IPC (ipc) | ✅ Sí | Shared memory, semaphores |
| `04-uts-namespace.yaml` | 🏷️ UTS (uts) | ✅ Sí | Mismo hostname |
| `05-mount-namespace.yaml` | 📁 Mount (mnt) | 🚫 No | Filesystem independiente + volúmenes |
| `06-user-namespace.yaml` | 👤 User (user) | 🚫 No | Diferentes UIDs/GIDs |
| `07-cgroup-namespace.yaml` | ⚙️ Cgroup | 🚫 No | Control de recursos independiente |
| `namespace-pod.yaml` | General | - | Demo básica (legacy) |

---

### **🌐 01-network-namespace.yaml**
- **Propósito**: Demostrar Network Namespace compartido
- **Demuestra**:
  - Contenedores con la misma IP
  - Comunicación vía `localhost`
  - Mismo stack de red
- **Uso**:
  ```bash
  kubectl apply -f 02-namespaces/01-network-namespace.yaml
  
  # Verificar misma IP
  kubectl exec network-namespace-demo -c web-server -- ip addr show eth0
  kubectl exec network-namespace-demo -c web-client -- ip addr show eth0
  
  # Probar comunicación localhost
  kubectl exec network-namespace-demo -c web-client -- curl localhost:8080
  
  # Ver logs
  kubectl logs network-namespace-demo -c web-client
  ```

---

### **🔄 02-pid-namespace.yaml**
- **Propósito**: Comparar PID Namespace con y sin `shareProcessNamespace`
- **Demuestra**:
  - 2 Pods: uno con PID aislado, otro con PID compartido
  - Visibilidad de procesos entre contenedores
- **Uso**:
  ```bash
  kubectl apply -f 02-namespaces/02-pid-namespace.yaml
  
  # Comparar procesos visibles
  echo "=== SIN shareProcessNamespace ==="
  kubectl exec pid-namespace-isolated -c debug -- ps aux
  
  echo "=== CON shareProcessNamespace ==="
  kubectl exec pid-namespace-shared -c debug -- ps aux
  
  # Ver logs
  kubectl logs pid-namespace-isolated -c debug
  kubectl logs pid-namespace-shared -c debug
  ```

---

### **💬 03-ipc-namespace.yaml**
- **Propósito**: Demostrar IPC Namespace compartido
- **Demuestra**:
  - Shared memory (`/dev/shm`)
  - Producer-Consumer pattern
  - Comunicación ultra-rápida
- **Uso**:
  ```bash
  kubectl apply -f 02-namespaces/03-ipc-namespace.yaml
  
  # Ver logs del producer escribiendo datos
  kubectl logs ipc-namespace-demo -c producer
  
  # Ver logs del consumer leyendo datos
  kubectl logs ipc-namespace-demo -c consumer -f
  
  # Verificar shared memory desde ambos
  kubectl exec ipc-namespace-demo -c producer -- cat /dev/shm/data.txt
  kubectl exec ipc-namespace-demo -c consumer -- cat /dev/shm/data.txt
  
  # Escribir desde un contenedor, leer desde otro
  kubectl exec ipc-namespace-demo -c consumer -- sh -c "echo 'Test' > /dev/shm/test.txt"
  kubectl exec ipc-namespace-demo -c producer -- cat /dev/shm/test.txt
  ```

---

### **🏷️ 04-uts-namespace.yaml**
- **Propósito**: Demostrar UTS Namespace compartido
- **Demuestra**:
  - Mismo hostname entre contenedores
  - Mismo domainname
- **Uso**:
  ```bash
  kubectl apply -f 02-namespaces/04-uts-namespace.yaml
  
  # Verificar hostname desde ambos contenedores
  kubectl exec uts-namespace-demo -c container1 -- hostname
  kubectl exec uts-namespace-demo -c container2 -- hostname
  
  # Ver FQDN
  kubectl exec uts-namespace-demo -c container1 -- hostname -f
  
  # Ver logs
  kubectl logs uts-namespace-demo -c container1
  kubectl logs uts-namespace-demo -c container2
  ```

---

### **📁 05-mount-namespace.yaml**
- **Propósito**: Demostrar Mount Namespace NO compartido
- **Demuestra**:
  - Cada contenedor tiene su propio filesystem
  - Archivos privados NO visibles entre contenedores
  - Volúmenes SÍ compartidos cuando se montan explícitamente
  - Un tercer contenedor sin acceso al volumen
- **Uso**:
  ```bash
  kubectl apply -f 02-namespaces/05-mount-namespace.yaml
  
  # Ver logs explicativos
  kubectl logs mount-namespace-demo -c writer
  kubectl logs mount-namespace-demo -c reader
  kubectl logs mount-namespace-demo -c isolated
  
  # Verificar archivos privados NO visibles
  kubectl exec mount-namespace-demo -c writer -- ls /tmp/
  kubectl exec mount-namespace-demo -c reader -- ls /tmp/private-writer.txt
  # ↑ Error esperado: No such file
  
  # Verificar volumen compartido SÍ accesible
  kubectl exec mount-namespace-demo -c writer -- cat /shared/data.txt
  kubectl exec mount-namespace-demo -c reader -- cat /shared/data.txt
  
  # Verificar contenedor aislado sin acceso
  kubectl exec mount-namespace-demo -c isolated -- ls /shared/
  # ↑ Error esperado: No such file or directory
  ```

---

### **👤 06-user-namespace.yaml**
- **Propósito**: Demostrar User Namespace NO compartido
- **Demuestra**:
  - Contenedores con diferentes UIDs/GIDs
  - Root vs usuario sin privilegios
  - Usuario personalizado
  - Seguridad y permisos
- **Uso**:
  ```bash
  kubectl apply -f 02-namespaces/06-user-namespace.yaml
  
  # Comparar UIDs de cada contenedor
  kubectl exec user-namespace-demo -c root-container -- id
  # UID=0 (root)
  
  kubectl exec user-namespace-demo -c user-container -- id
  # UID=1000
  
  kubectl exec user-namespace-demo -c custom-user-container -- id
  # UID=2000, GID=3000
  
  # Ver logs con análisis de permisos
  kubectl logs user-namespace-demo -c root-container
  kubectl logs user-namespace-demo -c user-container
  kubectl logs user-namespace-demo -c custom-user-container
  
  # Intentar operación privilegiada desde user-container
  kubectl exec user-namespace-demo -c user-container -- apk add curl
  # ↑ Fallará por falta de permisos
  ```

---

### **⚙️ 07-cgroup-namespace.yaml**
- **Propósito**: Demostrar Cgroup Namespace NO compartido
- **Demuestra**:
  - Control independiente de CPU/Memory
  - Contenedores con diferentes límites de recursos
  - Aislamiento de recursos
- **Uso**:
  ```bash
  kubectl apply -f 02-namespaces/07-cgroup-namespace.yaml
  
  # Ver uso de recursos en tiempo real
  kubectl top pod cgroup-namespace-demo --containers
  
  # Ver logs con información de cgroups
  kubectl logs cgroup-namespace-demo -c cpu-intensive
  kubectl logs cgroup-namespace-demo -c memory-intensive
  kubectl logs cgroup-namespace-demo -c unlimited
  
  # Generar carga y observar throttling
  kubectl exec cgroup-namespace-demo -c cpu-intensive -- sh -c "dd if=/dev/zero of=/dev/null &"
  kubectl top pod cgroup-namespace-demo --containers
  
  # Ver eventos (OOMKilled si excede memoria)
  kubectl get events --field-selector involvedObject.name=cgroup-namespace-demo
  ```

---

### **📊 Tabla Resumen de Namespaces**

| Namespace | Archivo | Compartido | Qué demuestra |
|-----------|---------|------------|---------------|
| Network | 01-network-namespace.yaml | ✅ Sí | Misma IP, localhost |
| PID | 02-pid-namespace.yaml | ⚙️ Opcional | Procesos visibles |
| IPC | 03-ipc-namespace.yaml | ✅ Sí | Shared memory |
| UTS | 04-uts-namespace.yaml | ✅ Sí | Mismo hostname |
| Mount | 05-mount-namespace.yaml | 🚫 No | Filesystem independiente |
| User | 06-user-namespace.yaml | 🚫 No | Diferentes UIDs |
| Cgroup | 07-cgroup-namespace.yaml | 🚫 No | Recursos independientes |

---

### **🧪 Probar todos los ejemplos**

```bash
# Aplicar todos los ejemplos de namespaces
cd 02-namespaces/

# Network namespace
kubectl apply -f 01-network-namespace.yaml

# PID namespace (2 Pods)
kubectl apply -f 02-pid-namespace.yaml

# IPC namespace
kubectl apply -f 03-ipc-namespace.yaml

# UTS namespace
kubectl apply -f 04-uts-namespace.yaml

# Mount namespace
kubectl apply -f 05-mount-namespace.yaml

# User namespace
kubectl apply -f 06-user-namespace.yaml

# Cgroup namespace
kubectl apply -f 07-cgroup-namespace.yaml

# Esperar a que todos estén listos
kubectl wait --for=condition=Ready pod --all --timeout=120s

# Ver todos los Pods
kubectl get pods -l category=namespaces

# Cleanup todos
kubectl delete -f .
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
