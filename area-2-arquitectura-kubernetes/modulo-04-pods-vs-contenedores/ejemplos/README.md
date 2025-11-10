# 📁 Ejemplos - Módulo 04: Pods vs Contenedores

Esta carpeta contiene ejemplos prácticos organizados por concepto.

## 📂 Estructura

```
ejemplos/
├── 01-evolucion/          # Evolución LXC → Docker → Kubernetes
├── 02-namespaces/         # Exploración de namespace sharing
├── 03-multi-container/    # Patrones multi-contenedor: Sidecar
├── 04-init-containers/    # Init containers para setup
├── 05-ambassador/         # Patrón Ambassador (proxy/intermediario)
├── 05-migracion-compose/  # Migración de Docker Compose
└── 09-antipatrones/       # Antipatrones comunes y soluciones
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

## 🎨 03-multi-container/

**Implementa el patrón Sidecar para extender funcionalidad sin modificar la app.**

Esta carpeta contiene ejemplos prácticos del patrón Sidecar con diferentes casos de uso.

### **📋 Contenido:**

| Archivo | Patrón | Tecnología | Propósito |
|---------|--------|------------|-----------|
| `01-sidecar-logging.yaml` | Sidecar | Fluent Bit | Procesamiento de logs |
| `02-sidecar-monitoring.yaml` | Sidecar | Prometheus Exporter | Exportar métricas |
| `03-sidecar-service-mesh.yaml` | Sidecar | Envoy Proxy | Service mesh proxy |
| `sidecar-pod.yaml` | Sidecar | Simple | Demo básica (legacy) |

---

### **📊 01-sidecar-logging.yaml**
- **Propósito**: Procesar logs de Nginx con Fluent Bit
- **Demuestra**:
  - Shared volumes entre contenedores
  - Procesamiento de logs sin modificar la app
  - Configuración de Fluent Bit con ConfigMap
- **Uso**:
  ```bash
  kubectl apply -f 03-multi-container/01-sidecar-logging.yaml
  
  # Ver logs procesados
  kubectl logs web-with-logging -c log-processor
  
  # Generar tráfico
  kubectl exec web-with-logging -c web-app -- curl localhost
  
  # Cleanup
  kubectl delete pod web-with-logging
  kubectl delete configmap fluent-config
  kubectl delete service web-logging-svc
  ```

---

### **📈 02-sidecar-monitoring.yaml**
- **Propósito**: Exportar métricas de Nginx para Prometheus
- **Demuestra**:
  - Comunicación localhost entre contenedores
  - Prometheus exporter pattern
  - Annotations para Prometheus scraping
- **Uso**:
  ```bash
  kubectl apply -f 03-multi-container/02-sidecar-monitoring.yaml
  
  # Port forward para métricas
  kubectl port-forward pod/app-with-monitoring 9113:9113
  
  # Ver métricas
  curl localhost:9113/metrics
  
  # Cleanup
  kubectl delete pod app-with-monitoring
  kubectl delete configmap nginx-monitoring-config
  kubectl delete service app-monitoring-svc
  ```

---

### **🌐 03-sidecar-service-mesh.yaml**
- **Propósito**: Proxy transparente con Envoy
- **Demuestra**:
  - Service mesh pattern
  - Traffic routing y observability
  - Envoy admin interface
- **Uso**:
  ```bash
  kubectl apply -f 03-multi-container/03-sidecar-service-mesh.yaml
  
  # Acceder a la app vía proxy
  kubectl port-forward pod/app-with-proxy 8080:10000
  curl localhost:8080
  
  # Ver admin interface de Envoy
  kubectl port-forward pod/app-with-proxy 9901:9901
  curl localhost:9901/stats
  
  # Cleanup
  kubectl delete pod app-with-proxy
  kubectl delete configmap envoy-config
  kubectl delete service service-mesh-svc
  ```

📚 **Guía completa:** Ver [`03-multi-container/README.md`](./03-multi-container/README.md)

---

## � 04-init-containers/

**Demuestra el uso de init containers para setup antes de iniciar la app.**

Esta carpeta contiene ejemplos prácticos de Init Containers con diferentes estrategias de preparación.

### **📋 Contenido:**

| Archivo | Propósito | Init Containers |
|---------|-----------|-----------------|
| `01-init-db-migration.yaml` | Migraciones DB | wait-for-db, database-migration |
| `02-init-wait-for-deps.yaml` | Wait for dependencies | wait-for-redis, wait-for-db, wait-for-api |
| `03-init-config-setup.yaml` | Setup completo | generate-config, download-assets, setup-permissions |
| `init-pod.yaml` | Demo básica | wait-for-db, db-migration, config-setup (legacy) |
| `postgres-pod.yaml` | Database | - (para testing) |

---

### **🗄️ 01-init-db-migration.yaml**
- **Propósito**: Ejecutar migraciones SQL antes de iniciar la app
- **Demuestra**:
  - Ejecución secuencial de init containers
  - Wait for database pattern
  - SQL migrations desde ConfigMap
- **Uso**:
  ```bash
  kubectl apply -f 04-init-containers/01-init-db-migration.yaml
  
  # Ver progreso
  kubectl get pods -w
  
  # Ver logs de cada init
  kubectl logs web-with-init -c wait-for-db
  kubectl logs web-with-init -c database-migration
  
  # Cleanup
  kubectl delete pod web-with-init
  kubectl delete configmap db-migrations
  kubectl delete secret db-credentials
  ```

---

### **⏳ 02-init-wait-for-deps.yaml**
- **Propósito**: Esperar múltiples servicios externos
- **Demuestra**:
  - TCP check con netcat
  - PostgreSQL check con pg_isready
  - HTTP check con curl y retry logic
- **Uso**:
  ```bash
  kubectl apply -f 04-init-containers/02-init-wait-for-deps.yaml
  
  # Ver logs de cada wait
  kubectl logs app-wait-deps -c wait-for-redis
  kubectl logs app-wait-deps -c wait-for-db
  kubectl logs app-wait-deps -c wait-for-api
  
  # Cleanup
  kubectl delete pod app-wait-deps
  kubectl delete service app-wait-deps-svc
  ```

---

### **🔧 03-init-config-setup.yaml**
- **Propósito**: Setup completo de ambiente
- **Demuestra**:
  - Template rendering dinámico
  - Download de assets externos
  - Setup de permisos y directorios
- **Uso**:
  ```bash
  kubectl apply -f 04-init-containers/03-init-config-setup.yaml
  
  # Ver configuración generada
  kubectl exec app-config-setup -- cat /app/config/app.conf
  
  # Ver assets descargados
  kubectl exec app-config-setup -- ls -la /app/assets/
  
  # Cleanup
  kubectl delete pod app-config-setup
  kubectl delete configmap config-template assets-list
  kubectl delete service app-config-svc
  ```

📚 **Guía completa:** Ver [`04-init-containers/README.md`](./04-init-containers/README.md)

---

## 🔗 05-ambassador/

**Implementa el patrón Ambassador para actuar como proxy/intermediario.**

Esta carpeta contiene ejemplos prácticos del patrón Ambassador con diferentes casos de uso.

### **📋 Contenido:**

| Archivo | Tecnología | Propósito |
|---------|------------|-----------|
| `01-ambassador-db-pool.yaml` | PgBouncer | Connection pooling a PostgreSQL |
| `02-ambassador-loadbalancer.yaml` | HAProxy | Load balancing entre réplicas |
| `03-ambassador-ssl.yaml` | Nginx | SSL/TLS termination |

---

### **🗄️ 01-ambassador-db-pool.yaml**
- **Propósito**: Connection pooling transparente con PgBouncer
- **Demuestra**:
  - Connection pooling automático
  - App conecta a localhost:5432
  - Reducción de overhead de conexiones
- **Uso**:
  ```bash
  kubectl apply -f 05-ambassador/01-ambassador-db-pool.yaml
  
  # Ver logs de PgBouncer
  kubectl logs app-with-pooling -c db-ambassador
  
  # Ver consultas de la app
  kubectl logs app-with-pooling -c app
  
  # Cleanup
  kubectl delete pod app-with-pooling
  kubectl delete configmap pgbouncer-config
  ```

**Nota:** Requiere un PostgreSQL service (ver comentarios en el YAML).

---

### **🔄 02-ambassador-loadbalancer.yaml**
- **Propósito**: Load balancing con HAProxy
- **Demuestra**:
  - Round-robin load balancing
  - Health checking automático
  - Circuit breaking
  - Stats en tiempo real
- **Uso**:
  ```bash
  kubectl apply -f 05-ambassador/02-ambassador-loadbalancer.yaml
  
  # Ver stats de HAProxy
  kubectl port-forward pod/app-with-lb 8404:8404
  # http://localhost:8404/stats
  
  # Ver distribución de carga
  kubectl logs app-with-lb -c haproxy-ambassador
  
  # Cleanup
  kubectl delete pod app-with-lb
  kubectl delete configmap haproxy-config
  kubectl delete service app-lb-svc
  ```

**Nota:** Ver comentarios en el YAML para crear réplicas de PostgreSQL.

---

### **🔐 03-ambassador-ssl.yaml**
- **Propósito**: SSL/TLS termination con Nginx
- **Demuestra**:
  - Encryption/decryption transparente
  - App usa HTTP simple
  - Centralización de certificados
  - Security headers
- **Uso**:
  ```bash
  kubectl apply -f 05-ambassador/03-ambassador-ssl.yaml
  
  # Acceder vía HTTPS
  kubectl port-forward pod/app-with-ssl 8443:443
  curl -k https://localhost:8443
  
  # Ver health endpoint
  curl -k https://localhost:8443/health
  
  # Cleanup
  kubectl delete pod app-with-ssl
  kubectl delete configmap nginx-ssl-config
  kubectl delete secret tls-cert
  kubectl delete service app-ssl-svc
  ```

📚 **Guía completa:** Ver [`05-ambassador/README.md`](./05-ambassador/README.md)

---

## � 09-antipatrones/

**Antipatrones comunes en diseño de Pods y sus soluciones correctas.**

Esta carpeta contiene ejemplos de qué NO hacer y cómo hacerlo correctamente.

### **📋 Contenido:**

| Archivo | Antipatrón | Problema | Solución |
|---------|-----------|----------|----------|
| `01-fat-pods.yaml` | Fat Pods | Demasiados contenedores | Separar responsabilidades |
| `02-singleton-services.yaml` | Singleton | Pod único | Usar Deployments con réplicas |
| `03-volume-abuse.yaml` | Volume Abuse | Filesystem para comunicación | Usar HTTP/gRPC APIs |

---

### **❌ 01-fat-pods.yaml**
- **Problema**: Pod con muchos contenedores no relacionados
- **Consecuencias**: Difícil debugear, alto acoplamiento, no escalable
- **Solución**: Un Pod por servicio + solo sidecars relacionados
- **Uso**:
  ```bash
  # Ver el antipatrón (primer manifest)
  kubectl apply -f 09-antipatrones/01-fat-pods.yaml
  kubectl describe pod fat-pod-antipattern
  
  # Aplicar la solución (manifests siguientes)
  # web-pod y api-pod separados
  ```

---

### **❌ 02-singleton-services.yaml**
- **Problema**: Usar un Pod único sin réplicas
- **Consecuencias**: Single point of failure, no alta disponibilidad
- **Solución**: Deployment con 3+ réplicas
- **Uso**:
  ```bash
  # Ver el antipatrón
  kubectl apply -f 09-antipatrones/02-singleton-services.yaml
  kubectl get pod monolith-pod
  # Si el Pod muere, todo el servicio cae
  
  # Aplicar la solución: Deployment con réplicas
  kubectl get deployment web-deployment
  kubectl get pods -l app=web
  # ✅ 3 réplicas para alta disponibilidad
  ```

---

### **❌ 03-volume-abuse.yaml**
- **Problema**: Usar filesystem compartido para comunicación entre servicios
- **Consecuencias**: Alto acoplamiento, sincronización manual, no escalable
- **Solución**: HTTP/gRPC para comunicación + volumes solo para logs/archivos
- **Uso**:
  ```bash
  # Ver el antipatrón
  kubectl apply -f 09-antipatrones/03-volume-abuse.yaml
  kubectl logs volume-abuse-antipattern -c producer
  kubectl logs volume-abuse-antipattern -c consumer
  
  # Aplicar la solución: HTTP communication
  kubectl logs http-communication-correct -c producer
  kubectl logs http-communication-correct -c consumer
  
  # Ver excepción válida: log processing
  kubectl logs valid-shared-volume-use -c log-shipper
  ```

📚 **Guía completa:** Ver [`09-antipatrones/README.md`](./09-antipatrones/README.md)

---

## �🔄 06-migracion-compose/

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
